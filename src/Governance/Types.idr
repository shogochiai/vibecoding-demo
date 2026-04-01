||| Governance Types — td.onthe.eth
||| REQ_CANCEL_002: ProposalState enum includes Cancelled variant
module Governance.Types

%default total

-- =============================================================================
-- ProposalState ADT
-- =============================================================================

||| Lifecycle states of a governance proposal.
||| Pending -> Active -> (Finalized | Cancelled)
||| REQ_CANCEL_002: Cancelled variant for author-initiated withdrawal.
public export
data ProposalState
  = Pending     -- Proposal submitted, not yet in voting period
  | Active      -- Proposal open for voting
  | Finalized   -- Proposal passed tally and executed
  | Cancelled   -- Author withdrew proposal before voting ended

public export
Eq ProposalState where
  Pending   == Pending   = True
  Active    == Active    = True
  Finalized == Finalized = True
  Cancelled == Cancelled = True
  _         == _         = False

public export
Show ProposalState where
  show Pending   = "Pending"
  show Active    = "Active"
  show Finalized = "Finalized"
  show Cancelled = "Cancelled"

||| Encode state as uint8 for EVM storage.
public export
stateToUint8 : ProposalState -> Int
stateToUint8 Pending   = 0
stateToUint8 Active    = 1
stateToUint8 Finalized = 2
stateToUint8 Cancelled = 3

||| Decode uint8 from EVM storage to state.
public export
uint8ToState : Int -> Maybe ProposalState
uint8ToState 0 = Just Pending
uint8ToState 1 = Just Active
uint8ToState 2 = Just Finalized
uint8ToState 3 = Just Cancelled
uint8ToState _ = Nothing

-- =============================================================================
-- Type Aliases
-- =============================================================================

||| Ethereum address (20 bytes, stored as Integer)
public export
EvmAddr : Type
EvmAddr = Integer

||| Proposal ID
public export
ProposalId : Type
ProposalId = Integer

||| Timestamp (Unix epoch seconds)
public export
Timestamp : Type
Timestamp = Integer

-- =============================================================================
-- Proposal Record
-- =============================================================================

||| A proposal record stored on-chain.
public export
record Proposal where
  constructor MkProposal
  proposalId : ProposalId
  author     : EvmAddr
  status     : ProposalState
  slotIndex  : Nat

||| Check if a proposal is in a cancellable state.
||| Only Pending and Active proposals can be cancelled.
public export
isCancellable : ProposalState -> Bool
isCancellable Pending = True
isCancellable Active  = True
isCancellable _       = False
