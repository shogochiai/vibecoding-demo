||| Governance Voting Slot Management
||| REQ_CANCEL_004: Cancelled proposal frees voting slot
module Governance.Slots

import Governance.Proposal

-- =============================================================================
-- Voting Slot Management
-- =============================================================================

||| Slot freeing strategy for cancelled proposals
||| REQ_CANCEL_004: Set expiration to 0 to mark as inactive and free the voting slot
|||
||| When a proposal is cancelled, its voting slot is freed by zeroing the expiration.
||| This allows the governance system to reclaim the slot for new proposals.
|||
||| Storage effect: sstore(metaSlot + META_OFFSET_EXPIRATION, 0)
public export
data SlotAction
  = FreeSlot     -- Zero expiration to release slot
  | KeepSlot     -- No change to slot

||| Determine slot action based on state transition
||| REQ_CANCEL_004: Cancel transitions free the voting slot
public export
slotActionForTransition : ProposalState -> ProposalState -> SlotAction
slotActionForTransition Active  Cancelled = FreeSlot
slotActionForTransition Pending Cancelled = FreeSlot
slotActionForTransition _       _         = KeepSlot

||| Check if a state transition frees a slot
public export
freesSlot : ProposalState -> ProposalState -> Bool
freesSlot from to = case slotActionForTransition from to of
  FreeSlot => True
  KeepSlot => False

-- =============================================================================
-- Active Slot Counting
-- =============================================================================

||| Count active proposals (excluding cancelled/executed/expired)
||| Used to determine if new proposals can be created (slot limit check)
public export
isSlotOccupied : ProposalState -> Bool
isSlotOccupied Active  = True
isSlotOccupied Pending = True
isSlotOccupied _       = False

||| After cancel, the slot count should decrement
||| REQ_CANCEL_004: Voting slot count decrements on cancel
public export
adjustSlotCount : Integer -> ProposalState -> ProposalState -> Integer
adjustSlotCount currentCount from to =
  if freesSlot from to
    then if currentCount > 0 then currentCount - 1 else 0
    else currentCount
