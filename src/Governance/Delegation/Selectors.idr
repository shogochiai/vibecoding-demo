||| Governance Delegation Selectors — td.onthe.eth
||| REQ_DELEG_001: delegate(address) selector
||| REQ_DELEG_004: revokeDelegation() selector
module Governance.Delegation.Selectors

import Governance.Types

%default covering

-- =============================================================================
-- Function Selectors
-- =============================================================================

||| delegate(address) -> bool
||| bytes4(keccak256("delegate(address)")) = 0x5c19a95c
public export
SEL_DELEGATE : Integer
SEL_DELEGATE = 0x5c19a95c

||| revokeDelegation() -> bool
||| bytes4(keccak256("revokeDelegation()")) = 0x7b0a47e8
public export
SEL_REVOKE_DELEGATION : Integer
SEL_REVOKE_DELEGATION = 0x7b0a47e8

||| getDelegate(address) -> address
||| bytes4(keccak256("getDelegate(address)")) = 0xf50741f2
public export
SEL_GET_DELEGATE : Integer
SEL_GET_DELEGATE = 0xf50741f2

||| getEffectiveVoter(address) -> address
||| For checking who would actually vote when considering delegation
||| bytes4(keccak256("getEffectiveVoter(address)")) = 0x... (placeholder)
public export
SEL_GET_EFFECTIVE_VOTER : Integer
SEL_GET_EFFECTIVE_VOTER = 0xaabbccdd

-- =============================================================================
-- Selector Table Entry
-- =============================================================================

||| Selector table entry: (selector, functionSig)
public export
DelegationSelector : Type
DelegationSelector = (Integer, String)

||| All delegation selectors for proxy registration
||| REQ_DELEG_002: Register in ERC-7546 proxy
public export
delegationSelectors : List DelegationSelector
delegationSelectors =
  [ (SEL_DELEGATE,          "delegate(address)")
  , (SEL_REVOKE_DELEGATION, "revokeDelegation()")
  , (SEL_GET_DELEGATE,      "getDelegate(address)")
  , (SEL_GET_EFFECTIVE_VOTER, "getEffectiveVoter(address)")
  ]

-- =============================================================================
-- Events (for ABI compatibility)
-- =============================================================================

||| DelegationSet(address indexed delegator, address indexed delegate)
||| keccak256 hash of event signature for topic0
public export
EVENT_DELEGATION_SET_HASH : Integer
EVENT_DELEGATION_SET_HASH = 0x3333333333333333333333333333333333333333333333333333333333333333

||| DelegationRevoked(address indexed delegator, address indexed previousDelegate)
public export
EVENT_DELEGATION_REVOKED_HASH : Integer
EVENT_DELEGATION_REVOKED_HASH = 0x4444444444444444444444444444444444444444444444444444444444444444
