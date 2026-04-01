||| Delegation Types — td.onthe.eth
||| REQ_DELEG_001: Delegation record type and storage slot constants
||| REQ_DELEG_004: Queryable delegation state types
module Delegation.Types

%default total

-- =============================================================================
-- Type Aliases
-- =============================================================================

||| Ethereum address (20 bytes, stored as Integer)
public export
EvmAddr : Type
EvmAddr = Integer

||| Voting power (uint256)
public export
VotingPower : Type
VotingPower = Integer

-- =============================================================================
-- DelegationRecord — REQ_DELEG_001
-- =============================================================================

||| On-chain delegation record.
||| Each shareholder can delegate voting power to exactly one delegatee.
public export
record DelegationRecord where
  constructor MkDelegationRecord
  delegator : EvmAddr
  delegatee : EvmAddr
  power     : VotingPower

||| Null address constant (no delegation)
public export
ZERO_ADDR : EvmAddr
ZERO_ADDR = 0

||| Check if a delegation is active (delegatee is non-zero)
public export
isActiveDelegation : DelegationRecord -> Bool
isActiveDelegation rec = rec.delegatee /= ZERO_ADDR

-- =============================================================================
-- DelegateMapping — REQ_DELEG_001
-- =============================================================================

||| Mapping structure: delegator -> delegatee
||| In EVM storage this is a mapping(address => address).
||| Represented here as a type alias for documentation.
public export
DelegateMapping : Type
DelegateMapping = List (EvmAddr, EvmAddr)

-- =============================================================================
-- Storage Slot Constants — REQ_DELEG_001
-- =============================================================================

||| Base storage namespace for delegation data.
||| Derived from keccak256("td.delegation.v1") to avoid collisions
||| with other ERC-7546 facets.
public export
DELEGATION_SLOT : Integer
DELEGATION_SLOT = 0x44656c65676174696f6e2e763100000000000000000000000000000000000000

||| Storage slot for delegatee mapping: delegator -> delegatee address
||| slot = keccak256(delegator . DELEGATION_SLOT)
public export
DELEGATION_SLOT_DELEGATEE : Integer
DELEGATION_SLOT_DELEGATEE = DELEGATION_SLOT

||| Storage slot for accumulated voting power: delegatee -> accumulated power
||| slot = keccak256(delegatee . (DELEGATION_SLOT + 1))
public export
DELEGATION_SLOT_VOTING_POWER : Integer
DELEGATION_SLOT_VOTING_POWER = DELEGATION_SLOT + 1

||| Storage slot for base voting power (shareholder's own power): address -> power
||| slot = keccak256(address . (DELEGATION_SLOT + 2))
public export
DELEGATION_SLOT_BASE_POWER : Integer
DELEGATION_SLOT_BASE_POWER = DELEGATION_SLOT + 2
