||| Governance Proposal State Machine
||| REQ_CANCEL_001 REQ_CANCEL_002 — Proposal lifecycle states including Cancelled
|||
||| This module defines the proposal state enum and state transition rules
||| for the td governance system. Cancelled was added for IP-25.
module Governance.Proposal

import public Subcontract.Core.Storable

%default covering

-- =============================================================================
-- Proposal State Enum
-- =============================================================================

||| All possible states of a governance proposal
||| IP-25: Added Cancelled state for author-initiated cancellation
public export
data ProposalState
  = Active       -- Proposal is open for voting
  | Expired      -- Voting period has ended, awaiting tally
  | Approved     -- Tally completed, header/command approved
  | Executed     -- Approved actions have been executed
  | Cancelled    -- Author cancelled before voting ended (IP-25)

||| Convert ProposalState to on-chain integer representation
export
proposalStateToInt : ProposalState -> Integer
proposalStateToInt Active    = 0
proposalStateToInt Expired   = 1
proposalStateToInt Approved  = 2
proposalStateToInt Executed  = 3
proposalStateToInt Cancelled = 4

||| Convert on-chain integer to ProposalState
export
intToProposalState : Integer -> ProposalState
intToProposalState 0 = Active
intToProposalState 1 = Expired
intToProposalState 2 = Approved
intToProposalState 3 = Executed
intToProposalState 4 = Cancelled
intToProposalState _ = Active  -- default fallback

-- =============================================================================
-- State Transition Rules
-- =============================================================================

||| Valid state transitions for proposals
||| IP-25: Active -> Cancelled is valid only for the original author
public export
isValidTransition : ProposalState -> ProposalState -> Bool
isValidTransition Active Expired   = True
isValidTransition Active Cancelled = True   -- IP-25: author cancellation
isValidTransition Expired Approved = True
isValidTransition Approved Executed = True
isValidTransition _ _ = False

||| Check if a proposal state is terminal (no further transitions)
public export
isTerminal : ProposalState -> Bool
isTerminal Executed  = True
isTerminal Cancelled = True
isTerminal _         = False

||| Check if proposal is in a votable state
public export
isVotable : ProposalState -> Bool
isVotable Active = True
isVotable _      = False

||| Check if proposal can be tallied
public export
isTallyable : ProposalState -> Bool
isTallyable Active    = False
isTallyable Expired   = True
isTallyable Approved  = False
isTallyable Executed  = False
isTallyable Cancelled = False  -- IP-25: Cancelled proposals excluded from tally
