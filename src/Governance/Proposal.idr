||| Governance Proposal — td.onthe.eth
||| REQ_CANCEL_001: cancelProposal selector — author can cancel own proposal
||| REQ_CANCEL_003: Access control — only original author can cancel; revert otherwise
||| REQ_CANCEL_005: Slot freeing — cancelled proposal frees voting slot
module Governance.Proposal

import Governance.Types

%default total

-- =============================================================================
-- Cancel Result Type
-- =============================================================================

||| Result of a cancel attempt.
public export
data CancelResult
  = CancelSuccess Proposal
  | ErrNotAuthor
  | ErrNotCancellable ProposalState

public export
Show CancelResult where
  show (CancelSuccess p) = "Cancelled proposal #" ++ show p.proposalId
  show ErrNotAuthor = "revert: caller is not proposal author"
  show (ErrNotCancellable s) = "revert: proposal status " ++ show s ++ " is not cancellable, require Active or Pending"

-- =============================================================================
-- Slot Management
-- =============================================================================

||| Active voting slot counter.
||| REQ_CANCEL_005: Tracks how many proposals occupy voting slots.
public export
record SlotCounter where
  constructor MkSlotCounter
  slotCount : Nat

||| Free a voting slot when a proposal is cancelled.
||| REQ_CANCEL_005: Decrements slot count so new proposals can be created.
public export
freeSlot : SlotCounter -> SlotCounter
freeSlot (MkSlotCounter Z)     = MkSlotCounter Z
freeSlot (MkSlotCounter (S n)) = MkSlotCounter n

-- =============================================================================
-- Author Guard
-- =============================================================================

||| Assert that the caller is the proposal author.
||| REQ_CANCEL_003: Reverts if msg.sender != proposal.author.
public export
assertAuthor : (caller : EvmAddr) -> (proposal : Proposal) -> Either CancelResult ()
assertAuthor caller proposal =
  if caller == proposal.author
     then Right ()
     else Left ErrNotAuthor

-- =============================================================================
-- Cancel Logic
-- =============================================================================

||| Cancel a proposal. Checks:
||| 1. caller == proposal.author (REQ_CANCEL_003)
||| 2. proposal.status is Active or Pending (REQ_CANCEL_002)
||| On success, sets status to Cancelled (REQ_CANCEL_001).
||| Returns updated proposal for slot freeing (REQ_CANCEL_005).
public export
cancelProposal : (caller : EvmAddr) -> Proposal -> CancelResult
cancelProposal caller proposal =
  case assertAuthor caller proposal of
    Left err => err
    Right () =>
      if isCancellable proposal.status
         then CancelSuccess ({ status := Cancelled } proposal)
         else ErrNotCancellable proposal.status

||| Cancel proposal and free the voting slot.
||| REQ_CANCEL_001 + REQ_CANCEL_005: Combined cancel + slot free operation.
public export
cancelAndFreeSlot : (caller : EvmAddr) -> Proposal -> SlotCounter -> (CancelResult, SlotCounter)
cancelAndFreeSlot caller proposal slots =
  case cancelProposal caller proposal of
    CancelSuccess p => (CancelSuccess p, freeSlot slots)
    err             => (err, slots)
