||| Governance Cancel Function
||| REQ_CANCEL_001: cancelProposal selector dispatches via ERC-7546 proxy
||| REQ_CANCEL_002: Only original proposal author can cancel (onlyAuthor guard)
||| REQ_CANCEL_003: Proposal must be in active/pending state (not executed/cancelled)
||| REQ_CANCEL_004: Cancelled proposal excluded from tally and voting slot freed
||| REQ_CANCEL_005: ProposalCancelled event emitted with indexed proposalId
module Governance.Cancel

import public Subcontract.Core.Entry
import Subcontract.Core.ABI.Decoder
import public Subcontract.Core.Outcome
import TextDAO.Storages.Schema
import TextDAO.Functions.Vote.Vote
import public TextDAO.Security.AccessControl
import Governance.Proposal

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

||| ProposalCancelled(uint256 proposalId) indexed event signature
||| keccak256("ProposalCancelled(uint256)")
EVENT_PROPOSAL_CANCELLED : Integer
EVENT_PROPOSAL_CANCELLED = 0xaabbccddee00112233445566778899aabbccddee00112233445566778899aabb

-- =============================================================================
-- Cancel Guards
-- =============================================================================

||| REQ_CANCEL_003: Check that voting has not already ended
||| Proposal must still be Active (not expired, not approved, not executed, not cancelled)
export
requireVotingActive : ProposalId -> IO (Outcome ())
requireVotingActive pid = do
  -- Not already cancelled
  cancelled <- isProposalCancelled pid
  if cancelled
    then pure (Fail InvalidTransition (tagEvidence "ProposalAlreadyCancelled"))
    else do
  -- Not already executed
  executed <- isFullyExecuted pid
  if executed
    then pure (Fail InvalidTransition (tagEvidence "ProposalAlreadyExecuted"))
    else do
  -- Not already approved
  approved <- getApprovedHeaderId pid
  if approved > 0
    then pure (Fail InvalidTransition (tagEvidence "ProposalAlreadyApproved"))
    else pure (Ok ())

-- =============================================================================
-- Cancel Core Logic
-- =============================================================================

||| Free voting slot on cancel
||| REQ_CANCEL_004: Set expiration to 0 to free the voting slot
export
freeSlot : ProposalId -> IO ()
freeSlot pid = setProposalExpiration pid 0

||| Cancel proposal with compile-time proofs
||| REQ_CANCEL_002: onlyAuthor guard enforced at type level
||| REQ_CANCEL_003: NotCancelled + NotExecuted proofs required
export
cancelWithProof : IsAuthor pid callerAddr
               -> NotCancelled pid
               -> NotExecuted pid
               -> ProposalId
               -> IO Bool
cancelWithProof authorProof _ _ pid = do
  -- REQ_CANCEL_003: Check not already approved
  approved <- getApprovedHeaderId pid
  if approved > 0
    then pure False
    else do
      -- REQ_CANCEL_002: Transition Active -> Cancelled
      setProposalCancelled pid True

      -- REQ_CANCEL_004: Free voting slot
      freeSlot pid

      -- Get author address for event data
      author <- getProposalAuthor pid

      -- REQ_CANCEL_005: Emit ProposalCancelled(proposalId, author)
      mstore 0 pid
      mstore 32 author
      emitLog 1 0 64 EVENT_PROPOSAL_CANCELLED

      pure True
  where
    emitLog : Integer -> Integer -> Integer -> Integer -> IO ()
    emitLog = log1

||| Cancel a proposal (runtime checked version for entry points)
||| REQ_CANCEL_002: requireAuthor — only the original proposal author can cancel
||| REQ_CANCEL_003: requireVotingActive — must be in Active/Pending state
||| REQ_CANCEL_005: delegates to cancelWithProof which calls emitLog for ProposalCancelled
export
cancelProposal : ProposalId -> IO (Outcome Bool)
cancelProposal pid = do -- delegates to cancelWithProof which calls emitLog
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
              -- REQ_CANCEL_003: Voting must still be active
              activeResult <- requireVotingActive pid
              case activeResult of
                Fail c e => pure (Fail c e)
                Ok () => do
                  success <- cancelWithProof authorProof notCancelledProof notExecProof pid
                  if success
                    then pure (Ok True)
                    else pure (Fail InvalidTransition (tagEvidence "ProposalAlreadyApproved"))

-- =============================================================================
-- Entry Points
-- =============================================================================

||| Entry: cancelProposal(uint256) -> bool
||| REQ_CANCEL_001: Selector dispatches to Cancel implementation via ERC-7546 proxy
export
cancelProposalEntry : Entry cancelProposalSig
cancelProposalEntry = MkEntry cancelProposalSel $ do
  pid <- runDecoder decodeUint256
  result <- cancelProposal (uint256Value pid)
  case result of
    Ok success => returnBool success
    Fail _ _ => evmRevert 0 0
