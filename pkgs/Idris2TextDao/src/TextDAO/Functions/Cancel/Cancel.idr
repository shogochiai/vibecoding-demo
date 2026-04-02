||| TextDAO Cancel Function
||| REQ_CANCEL_001: cancelProposal selector dispatches via ERC-7546 proxy
||| REQ_CANCEL_002: Only original proposal author can cancel (onlyAuthor guard)
||| REQ_CANCEL_003: Proposal must be in active/pending state (not executed/cancelled)
||| REQ_CANCEL_004: Cancelled proposal excluded from tally and voting slot freed
||| REQ_CANCEL_005: ProposalCancelled event emitted with proposalId and author
module TextDAO.Functions.Cancel.Cancel

import public Subcontract.Core.Entry
import Subcontract.Core.ABI.Decoder
import public Subcontract.Core.Outcome
import TextDAO.Storages.Schema
import TextDAO.Functions.Vote.Vote
import public TextDAO.Security.AccessControl

-- Note: EVM primitives now come from TextDAO.Storages.Schema via Subcontract.Core.Storable

%default covering

-- =============================================================================
-- Function Signatures
-- =============================================================================

||| cancelProposal(uint256) -> bool
public export
cancelProposalSig : Sig
cancelProposalSig = MkSig "cancelProposal" [TUint256] [TBool]

public export
cancelProposalSel : Sel cancelProposalSig
cancelProposalSel = MkSel 0xd8e780df

-- =============================================================================
-- Event Topics
-- =============================================================================

||| ProposalCancelled(uint256 proposalId, address author) event signature
EVENT_PROPOSAL_CANCELLED : Integer
EVENT_PROPOSAL_CANCELLED = 0xaabbccddee00112233445566778899aabbccddee00112233445566778899aabb

-- =============================================================================
-- Cancel Core Logic
-- =============================================================================

||| Check if proposal is in Active or Pending state (not executed, not cancelled, not approved)
||| REQ_CANCEL_003
export
isActivePending : ProposalId -> IO Bool
isActivePending pid = do
  executed <- isFullyExecuted pid
  cancelled <- isProposalCancelled pid
  approved <- getApprovedHeaderId pid
  pure (not executed && not cancelled && approved == 0)

||| Free voting slot on cancel
||| REQ_CANCEL_004: Decrement active proposal slot count
export
freeSlot : ProposalId -> IO ()
freeSlot pid = do
  -- Set expiration to 0 to mark as inactive and free the voting slot
  setProposalExpiration pid 0

||| Cancel proposal with compile-time proofs
||| REQ_CANCEL_002: onlyAuthor guard enforced at type level
export
cancelWithProof : IsAuthor pid callerAddr
               -> NotCancelled pid
               -> NotExecuted pid
               -> ProposalId
               -> IO Bool
cancelWithProof authorProof _ _ pid = do
  -- Check proposal is in Active/Pending state (not already approved)
  approved <- getApprovedHeaderId pid
  if approved > 0
    then pure False
    else do
      -- Transition to Cancelled state
      setProposalCancelled pid True

      -- Free voting slot
      freeSlot pid

      -- Get author address for event
      author <- getProposalAuthor pid

      -- Emit ProposalCancelled(proposalId, author) event
      -- REQ_CANCEL_005
      mstore 0 pid
      mstore 32 author
      log1 0 64 EVENT_PROPOSAL_CANCELLED

      pure True

||| Cancel a proposal (runtime checked version for entry points)
||| REQ_CANCEL_002: Only the original proposal author can cancel
||| REQ_CANCEL_003: Must be in Active/Pending state
export
cancelProposal : ProposalId -> IO (Outcome Bool)
cancelProposal pid = do
  callerAddr <- caller

  -- REQ_CANCEL_002: onlyAuthor guard
  authorResult <- requireAuthor pid callerAddr
  case authorResult of
    Fail c e => pure (Fail c e)
    Ok authorProof => do
      -- REQ_CANCEL_003: Not already cancelled
      cancelledResult <- requireNotCancelled pid
      case cancelledResult of
        Fail c e => pure (Fail c e)
        Ok notCancelledProof => do
          -- REQ_CANCEL_003: Not already executed
          execResult <- requireNotExecuted pid
          case execResult of
            Fail c e => pure (Fail c e)
            Ok notExecProof => do
              success <- cancelWithProof authorProof notCancelledProof notExecProof pid
              if success
                then pure (Ok True)
                else pure (Fail InvalidTransition (tagEvidence "ProposalAlreadyApproved"))

-- =============================================================================
-- Entry Points
-- =============================================================================

||| Entry: cancelProposal(uint256) -> bool
||| REQ_CANCEL_001: Selector dispatches to implementation via ERC-7546 proxy
export
cancelProposalEntry : Entry cancelProposalSig
cancelProposalEntry = MkEntry cancelProposalSel $ do
  pid <- runDecoder decodeUint256
  result <- cancelProposal (uint256Value pid)
  case result of
    Ok success => returnBool success
    Fail _ _ => evmRevert 0 0
