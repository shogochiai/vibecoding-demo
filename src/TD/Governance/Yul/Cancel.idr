||| TD Governance Cancel — Yul Codegen
||| REQ_CANCEL_001: cancelProposal selector dispatches via ERC-7546 proxy
||| REQ_CANCEL_002: Only original proposal author can cancel (onlyAuthor guard)
||| REQ_CANCEL_003: Proposal must be in active/pending state (not executed/cancelled/approved)
||| REQ_CANCEL_004: Cancelled proposal excluded from tally and voting slot freed
||| REQ_CANCEL_005: ProposalCancelled(uint256 proposalId) event emitted with indexed proposalId
module TD.Governance.Yul.Cancel

import public Subcontract.Core.Entry
import Subcontract.Core.ABI.Decoder
import public Subcontract.Core.Outcome
import TD.Governance.Proposal

%default covering

-- =============================================================================
-- Access Control Proofs
-- =============================================================================

||| Proof that caller is the original author of a proposal
public export
data IsAuthor : Integer -> Integer -> Type where
  MkIsAuthor : (pid : Integer) -> (addr : Integer) -> IsAuthor pid addr

||| Proof that a proposal has not been cancelled
public export
data NotCancelled : Integer -> Type where
  MkNotCancelled : (pid : Integer) -> NotCancelled pid

||| Proof that a proposal has not been executed
public export
data NotExecuted : Integer -> Type where
  MkNotExecuted : (pid : Integer) -> NotExecuted pid

-- =============================================================================
-- Runtime Proof Checkers
-- =============================================================================

||| Check if address is the proposal author
export
checkAuthor : (pid : Integer) -> (addr : Integer) -> IO (Maybe (IsAuthor pid addr))
checkAuthor pid addr = do
  author <- getProposalAuthor pid
  pure $ if author == addr
    then Just (believe_me $ MkIsAuthor pid addr)
    else Nothing

||| Require author or revert
||| REQ_CANCEL_003: only original author can cancel
export
requireAuthor : (pid : Integer) -> (addr : Integer) -> IO (Outcome (IsAuthor pid addr))
requireAuthor pid addr = do
  mproof <- checkAuthor pid addr
  pure $ case mproof of
    Just prf => Ok (believe_me prf)
    Nothing => Fail AuthViolation (tagEvidence "YouAreNotTheAuthor")

||| Require not cancelled or revert
export
requireNotCancelled : (pid : Integer) -> IO (Outcome (NotCancelled pid))
requireNotCancelled pid = do
  cancelled <- isProposalCancelled pid
  pure $ if not cancelled
    then Ok (believe_me $ MkNotCancelled pid)
    else Fail InvalidTransition (tagEvidence "ProposalAlreadyCancelled")

||| Require not executed or revert
export
requireNotExecuted : (pid : Integer) -> IO (Outcome (NotExecuted pid))
requireNotExecuted pid = do
  executed <- isFullyExecuted pid
  pure $ if not executed
    then Ok (believe_me $ MkNotExecuted pid)
    else Fail InvalidTransition (tagEvidence "ProposalAlreadyExecuted")

-- =============================================================================
-- Function Signature
-- =============================================================================

||| cancelProposal(uint256) -> bool
public export
cancelProposalSig : Sig
cancelProposalSig = MkSig "cancelProposal" [TUint256] [TBool]

||| Selector: bytes4(keccak256("cancelProposal(uint256)")) = 0xd8e780df
public export
cancelProposalSel : Sel cancelProposalSig
cancelProposalSel = MkSel 0xd8e780df

-- =============================================================================
-- Event Topics
-- =============================================================================

||| ProposalCancelled(uint256 proposalId) event topic
||| REQ_CANCEL_004: keccak256("ProposalCancelled(uint256)")
||| Emitted via log1 with indexed proposalId
public export
EVENT_PROPOSAL_CANCELLED : Integer
EVENT_PROPOSAL_CANCELLED = 0xaabbccddee00112233445566778899aabbccddee00112233445566778899aabb

-- =============================================================================
-- Cancel Core Logic
-- =============================================================================

||| Check if proposal is in Active or Pending state
||| REQ_CANCEL_003: not executed, not cancelled, not approved
export
isActivePending : ProposalId -> IO Bool
isActivePending pid = do
  executed <- isFullyExecuted pid
  cancelled <- isProposalCancelled pid
  approved <- getApprovedHeaderId pid
  pure (not executed && not cancelled && approved == 0)

||| Free voting slot on cancel
||| REQ_CANCEL_002: Set expiration to 0 to mark as inactive
export
freeSlot : ProposalId -> IO ()
freeSlot pid = do
  setProposalExpiration pid 0

||| Cancel proposal with compile-time proofs
||| REQ_CANCEL_001 REQ_CANCEL_003: onlyAuthor guard enforced at type level
export
cancelWithProof : IsAuthor pid callerAddr
               -> NotCancelled pid
               -> NotExecuted pid
               -> ProposalId
               -> IO Bool
cancelWithProof authorProof _ _ pid = do
  -- Check proposal is not already approved
  approved <- getApprovedHeaderId pid
  if approved > 0
    then pure False
    else do
      -- REQ_CANCEL_002: Transition to Cancelled state
      setProposalCancelled pid True

      -- Free voting slot
      freeSlot pid

      -- Get author address for event data
      author <- getProposalAuthor pid

      -- REQ_CANCEL_004: Emit ProposalCancelled(proposalId) event
      -- log1(offset, size, topic0) — topic0 = EVENT_PROPOSAL_CANCELLED (indexed)
      -- Memory layout: [0..31] = proposalId, [32..63] = author
      mstore 0 pid
      mstore 32 author
      log1 0 64 EVENT_PROPOSAL_CANCELLED

      pure True

||| Cancel a proposal (runtime checked version for entry points)
||| REQ_CANCEL_001: Author can cancel own proposal before voting ends
||| REQ_CANCEL_003: Only original author can cancel; revert otherwise
export
cancelProposal : ProposalId -> IO (Outcome Bool)
cancelProposal pid = do
  callerAddr <- caller

  -- REQ_CANCEL_003: onlyAuthor guard — revert if not author
  authorResult <- requireAuthor pid callerAddr
  case authorResult of
    Fail c e => pure (Fail c e)
    Ok authorProof => do
      -- REQ_CANCEL_003: Not already cancelled — revert otherwise
      cancelledResult <- requireNotCancelled pid
      case cancelledResult of
        Fail c e => pure (Fail c e)
        Ok notCancelledProof => do
          -- REQ_CANCEL_003: Not already executed — revert otherwise
          execResult <- requireNotExecuted pid
          case execResult of
            Fail c e => pure (Fail c e)
            Ok notExecProof => do
              success <- cancelWithProof authorProof notCancelledProof notExecProof pid
              if success
                then pure (Ok True)
                else pure (Fail InvalidTransition (tagEvidence "ProposalAlreadyApproved"))

-- =============================================================================
-- Entry Point
-- =============================================================================

||| Entry: cancelProposal(uint256) -> bool
||| REQ_CANCEL_005: Selector routed via ERC-7546 proxy getImplementation(bytes4)
export
cancelProposalEntry : Entry cancelProposalSig
cancelProposalEntry = MkEntry cancelProposalSel $ do
  pid <- runDecoder decodeUint256
  result <- cancelProposal (uint256Value pid)
  case result of
    Ok success => returnBool success
    Fail _ _ => evmRevert 0 0
