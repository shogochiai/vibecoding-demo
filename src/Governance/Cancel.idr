||| TextDAO Cancel Proposal Function
||| REQ_CANCEL_001: cancelProposal selector dispatches via ERC-7546 proxy
||| REQ_CANCEL_002: Only original proposal author can cancel (onlyAuthor guard)
||| REQ_CANCEL_003: Proposal must be in active/pending state (not executed/cancelled)
||| REQ_CANCEL_004: Cancelled proposal excluded from tally and voting slot freed
||| REQ_CANCEL_005: ProposalCancelled event emitted with proposalId and author
module Governance.Cancel

import public Subcontract.Core.Entry
import Subcontract.Core.ABI.Decoder
import public Subcontract.Core.Outcome
import TextDAO.Storages.Schema
import TextDAO.Functions.Vote.Vote
import public TextDAO.Security.AccessControl
import Governance.Selectors
import Governance.Events

%default covering

-- =============================================================================
-- Cancel Core Logic
-- =============================================================================

||| Check if proposal is in Active or Pending state
||| REQ_CANCEL_003: Not executed, not cancelled, not already approved
export
isActivePending : ProposalId -> IO Bool
isActivePending pid = do
  executed <- isFullyExecuted pid
  cancelled <- isProposalCancelled pid
  approved <- getApprovedHeaderId pid
  pure (not executed && not cancelled && approved == 0)

||| Free voting slot on cancel
||| REQ_CANCEL_004: Decrement active proposal slot count by zeroing expiration
export
freeSlot : ProposalId -> IO ()
freeSlot pid = do
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
  -- REQ_CANCEL_003: Check proposal is in Active/Pending state (not already approved)
  approved <- getApprovedHeaderId pid
  if approved > 0
    then pure False
    else do
      -- Transition to Cancelled state
      setProposalCancelled pid True

      -- REQ_CANCEL_004: Free voting slot
      freeSlot pid

      -- Get author address for event
      author <- getProposalAuthor pid

      -- REQ_CANCEL_005: Emit ProposalCancelled(proposalId, author) event
      mstore 0 pid
      mstore 32 author
      log1 0 64 ProposalCancelled

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
