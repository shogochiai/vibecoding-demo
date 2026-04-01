module Governance.Proposal

||| Proposal status lifecycle for TextDAO governance.
||| A proposal moves through: Pending → Active → (Finalized | Cancelled).
public export
data ProposalStatus
  = Pending
  | Active
  | Finalized
  | Cancelled

public export
Eq ProposalStatus where
  Pending   == Pending   = True
  Active    == Active    = True
  Finalized == Finalized = True
  Cancelled == Cancelled = True
  _         == _         = False

public export
Show ProposalStatus where
  show Pending   = "Pending"
  show Active    = "Active"
  show Finalized = "Finalized"
  show Cancelled = "Cancelled"

||| Encode status as uint8 for EVM storage.
public export
statusToUint8 : ProposalStatus -> Int
statusToUint8 Pending   = 0
statusToUint8 Active    = 1
statusToUint8 Finalized = 2
statusToUint8 Cancelled = 3

||| Decode uint8 from EVM storage to status.
public export
uint8ToStatus : Int -> Maybe ProposalStatus
uint8ToStatus 0 = Just Pending
uint8ToStatus 1 = Just Active
uint8ToStatus 2 = Just Finalized
uint8ToStatus 3 = Just Cancelled
uint8ToStatus _ = Nothing

||| A proposal record stored on-chain.
public export
record Proposal where
  constructor MkProposal
  proposalId : Nat
  author     : String  -- address as hex string (0x...)
  status     : ProposalStatus
  title      : String

||| Check if a proposal is in a cancellable state.
||| Only Pending and Active proposals can be cancelled.
public export
isCancellable : ProposalStatus -> Bool
isCancellable Pending = True
isCancellable Active  = True
isCancellable _       = False

-- =============================================================================
-- Cancel Logic (REQ_CANCEL_001, REQ_CANCEL_003)
-- =============================================================================

||| Result of a cancel attempt.
public export
data CancelResult
  = CancelOk Proposal
  | CancelRevertNotAuthor
  | CancelRevertNotCancellable ProposalStatus

public export
Show CancelResult where
  show (CancelOk p) = "Cancelled proposal #" ++ show p.proposalId
  show CancelRevertNotAuthor = "revert: caller is not proposal author"
  show (CancelRevertNotCancellable s) = "revert: proposal status " ++ show s ++ " not Active or Pending"

||| Cancel a proposal. Author-only guard with revert semantics.
||| REQ_CANCEL_001: author can cancel own proposal before voting ends
||| REQ_CANCEL_003: only original author can cancel; revert otherwise
public export
cancelProposal : (caller : String) -> Proposal -> CancelResult
cancelProposal caller proposal =
  if caller /= proposal.author
     then CancelRevertNotAuthor  -- revert if not author
     else if isCancellable proposal.status
       then CancelOk ({ status := Cancelled } proposal)
       else CancelRevertNotCancellable proposal.status

-- =============================================================================
-- Slot Management (REQ_CANCEL_005)
-- =============================================================================

||| Track active slot count for voting slot management.
||| REQ_CANCEL_005: cancelled proposal frees voting slot for new proposals.
public export
record SlotTracker where
  constructor MkSlotTracker
  slotCount : Nat

||| Decrement active slot count when a proposal is cancelled (freeSlot).
public export
freeSlot : SlotTracker -> SlotTracker
freeSlot tracker =
  case tracker.slotCount of
    Z   => tracker
    S n => { slotCount := n } tracker
