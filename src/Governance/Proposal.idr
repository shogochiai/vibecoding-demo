||| Governance Proposal State Machine
||| REQ_CANCEL_002 — Cancelled state and transition logic
|||
||| Defines ProposalState sum type with state transitions for the td governance system.
||| Ported from TextDAO.Storages.Schema and TextDAO.Security.AccessControl patterns.
module Governance.Proposal

-- =============================================================================
-- Proposal State Sum Type
-- =============================================================================

||| All possible states a proposal can be in
public export
data ProposalState
  = Active        -- Proposal is open for voting
  | Pending       -- Proposal submitted, awaiting activation
  | Approved      -- Tally completed, proposal approved
  | Executed      -- Approved command has been executed
  | Cancelled     -- Author cancelled before voting ends (REQ_CANCEL_002)
  | Expired       -- Voting period ended without approval

||| Convert ProposalState to integer for storage
public export
stateToInt : ProposalState -> Integer
stateToInt Active    = 0
stateToInt Pending   = 1
stateToInt Approved  = 2
stateToInt Executed  = 3
stateToInt Cancelled = 4
stateToInt Expired   = 5

||| Convert integer from storage to ProposalState
public export
intToState : Integer -> ProposalState
intToState 0 = Active
intToState 1 = Pending
intToState 2 = Approved
intToState 3 = Executed
intToState 4 = Cancelled
intToState 5 = Expired
intToState _ = Active  -- default fallback

-- =============================================================================
-- State Transition Validation
-- =============================================================================

||| Valid state transitions for proposals
||| REQ_CANCEL_002: Active -> Cancelled and Pending -> Cancelled are valid
public export
data ValidTransition : ProposalState -> ProposalState -> Type where
  ||| Active proposal can be approved via tally
  ActiveToApproved   : ValidTransition Active Approved
  ||| Active proposal can be cancelled by author
  ActiveToCancelled  : ValidTransition Active Cancelled
  ||| Active proposal can expire
  ActiveToExpired    : ValidTransition Active Expired
  ||| Pending proposal can become active
  PendingToActive    : ValidTransition Pending Active
  ||| Pending proposal can be cancelled by author
  PendingToCancelled : ValidTransition Pending Cancelled
  ||| Approved proposal can be executed
  ApprovedToExecuted : ValidTransition Approved Executed

||| Check if a transition from one state to another is valid
public export
isValidTransition : ProposalState -> ProposalState -> Bool
isValidTransition Active Approved     = True
isValidTransition Active Cancelled    = True
isValidTransition Active Expired      = True
isValidTransition Pending Active      = True
isValidTransition Pending Cancelled   = True
isValidTransition Approved Executed   = True
isValidTransition _ _                 = False

-- =============================================================================
-- State Predicates
-- =============================================================================

||| Check if proposal is in a cancellable state
||| REQ_CANCEL_002: Only Active or Pending proposals can be cancelled
public export
isCancellable : ProposalState -> Bool
isCancellable Active  = True
isCancellable Pending = True
isCancellable _       = False

||| Check if proposal is in a terminal state
public export
isTerminal : ProposalState -> Bool
isTerminal Executed  = True
isTerminal Cancelled = True
isTerminal Expired   = True
isTerminal _         = False

||| Check if proposal is active (participating in tally)
public export
isActive : ProposalState -> Bool
isActive Active = True
isActive _      = False

-- =============================================================================
-- Storage Layout Constants
-- =============================================================================

||| Base storage slot for deliberation (ERC-7201 namespaced)
public export
SLOT_DELIBERATION : Integer
SLOT_DELIBERATION = 0x1000

||| Proposal count storage slot
public export
SLOT_PROPOSAL_COUNT : Integer
SLOT_PROPOSAL_COUNT = 0x1001

||| Meta field offsets within proposal storage
public export
META_OFFSET_CREATED_AT : Integer
META_OFFSET_CREATED_AT = 0

public export
META_OFFSET_EXPIRATION : Integer
META_OFFSET_EXPIRATION = 1

public export
META_OFFSET_HEADER_COUNT : Integer
META_OFFSET_HEADER_COUNT = 3

public export
META_OFFSET_CMD_COUNT : Integer
META_OFFSET_CMD_COUNT = 4

public export
META_OFFSET_APPROVED_HEADER : Integer
META_OFFSET_APPROVED_HEADER = 5

public export
META_OFFSET_APPROVED_CMD : Integer
META_OFFSET_APPROVED_CMD = 6

public export
META_OFFSET_EXECUTED : Integer
META_OFFSET_EXECUTED = 7

public export
META_OFFSET_AUTHOR : Integer
META_OFFSET_AUTHOR = 8

||| Offset for cancelled flag within proposal meta
||| REQ_CANCEL_002: Cancelled state stored at meta offset 9
public export
META_OFFSET_CANCELLED : Integer
META_OFFSET_CANCELLED = 9

-- =============================================================================
-- Type Aliases
-- =============================================================================

public export
ProposalId : Type
ProposalId = Integer

public export
EvmAddr : Type
EvmAddr = Integer

public export
Timestamp : Type
Timestamp = Integer

-- =============================================================================
-- Access Control Proofs
-- =============================================================================

||| Proof that caller is the original author of a proposal
||| REQ_CANCEL_003: Only original author can cancel (msg.sender == proposer)
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
