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
