||| Governance Cancel Function
||| REQ_CANCEL_001: cancelProposal selector — author can cancel own proposal before voting ends
||| REQ_CANCEL_002: State transition — proposal moves to Cancelled state, excluded from tally
||| REQ_CANCEL_003: Access control — only original author can cancel (msg.sender == proposer)
||| REQ_CANCEL_004: Slot freeing — cancelled proposal frees voting slot
||| REQ_CANCEL_005: Event emission — CancelProposal(uint256 proposalId) event emitted
module Governance.Cancel

import Governance.Proposal
import Governance.Events
import Governance.Slots

-- =============================================================================
-- Function Signature
-- =============================================================================

||| cancelProposal(uint256) -> bool
||| Selector: 0xd8e780df
public export
CANCEL_PROPOSAL_SELECTOR : Integer
CANCEL_PROPOSAL_SELECTOR = 0xd8e780df

-- =============================================================================
-- Cancel Core Logic
-- =============================================================================

||| Check if proposal is in Active or Pending state (not executed, not cancelled, not approved)
||| REQ_CANCEL_003: Precondition for cancellation
public export
isActivePending : ProposalState -> Bool
isActivePending Active  = True
isActivePending Pending = True
isActivePending _       = False

||| Outcome type for cancel operations
public export
data CancelResult
  = CancelOk
  | NotAuthor
  | AlreadyCancelled
  | AlreadyExecuted
  | AlreadyApproved
  | InvalidState

||| Cancel proposal with compile-time proofs
||| REQ_CANCEL_001: cancelProposal selector dispatches to this implementation
||| REQ_CANCEL_003: onlyAuthor guard enforced at type level via IsAuthor proof
|||
||| Requires:
|||   - IsAuthor proof: msg.sender == proposer (compile-time guarantee)
|||   - NotCancelled proof: proposal not already cancelled
|||   - NotExecuted proof: proposal not already executed
|||   - Proposal in Active or Pending state (runtime check for approved)
|||
||| Effects:
|||   1. State transition: Active/Pending -> Cancelled (REQ_CANCEL_002)
|||   2. Free voting slot by zeroing expiration (REQ_CANCEL_004)
|||   3. Emit CancelProposal event (REQ_CANCEL_005)
public export
cancelWithProof : IsAuthor pid callerAddr
               -> NotCancelled pid
               -> NotExecuted pid
               -> ProposalState
               -> CancelResult
cancelWithProof _ _ _ state =
  if isActivePending state
    then CancelOk  -- Proceed: set Cancelled, freeSlot, emit event
    else AlreadyApproved

||| Validate cancel preconditions (runtime version)
||| REQ_CANCEL_003: Only the original proposal author can cancel
||| This is the entry point called by the ERC-7546 proxy dispatcher
public export
validateCancel : (callerAddr : EvmAddr)
              -> (authorAddr : EvmAddr)
              -> (isCancelled : Bool)
              -> (isExecuted : Bool)
              -> (state : ProposalState)
              -> CancelResult
validateCancel caller author cancelled executed state =
  if caller /= author
    then NotAuthor
    else if cancelled
      then AlreadyCancelled
      else if executed
        then AlreadyExecuted
        else if not (isActivePending state)
          then InvalidState
          else CancelOk

-- =============================================================================
-- Cancel State Transition
-- =============================================================================

||| Apply cancel transition to proposal state
||| REQ_CANCEL_002: Proposal moves to Cancelled state
public export
applyCancelTransition : ProposalState -> Maybe ProposalState
applyCancelTransition Active  = Just Cancelled
applyCancelTransition Pending = Just Cancelled
applyCancelTransition _       = Nothing

-- =============================================================================
-- Cancel EVM Entry Point (Yul codegen target)
-- =============================================================================

||| cancelProposal entry point structure for Yul codegen
||| REQ_CANCEL_001: Dispatched via ERC-7546 proxy using selector 0xd8e780df
|||
||| Pseudocode for Yul output:
|||   function cancelProposal(pid) -> success {
|||     let callerAddr := caller()
|||     let metaSlot := getProposalMetaSlot(pid)
|||     let author := sload(add(metaSlot, META_OFFSET_AUTHOR))
|||
|||     // REQ_CANCEL_003: onlyAuthor guard
|||     if iszero(eq(callerAddr, author)) { revert(0, 0) }
|||
|||     // Check not cancelled
|||     let cancelled := sload(add(metaSlot, META_OFFSET_CANCELLED))
|||     if cancelled { revert(0, 0) }
|||
|||     // Check not executed
|||     let executed := sload(add(metaSlot, META_OFFSET_EXECUTED))
|||     if executed { revert(0, 0) }
|||
|||     // REQ_CANCEL_002: Set cancelled flag
|||     sstore(add(metaSlot, META_OFFSET_CANCELLED), 1)
|||
|||     // REQ_CANCEL_004: Free voting slot
|||     sstore(add(metaSlot, META_OFFSET_EXPIRATION), 0)
|||
|||     // REQ_CANCEL_005: Emit CancelProposal(proposalId)
|||     mstore(0, pid)
|||     log1(0, 32, EVENT_CANCEL_PROPOSAL)
|||
|||     success := 1
|||   }
public export
cancelProposalSpec : String
cancelProposalSpec = "cancelProposal(uint256) -> bool | selector=0xd8e780df"
