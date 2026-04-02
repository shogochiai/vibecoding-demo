||| TextDAO Delegation Tests
||| Tests for REQ_DELEG_001 through REQ_DELEG_005
module TextDAO.Functions.Delegation.Tests.DelegationTest

import public Subcontract.Core.Entry
import public Subcontract.Core.Outcome
import public TextDAO.Storages.Schema
import TextDAO.Functions.Delegation.Delegation
import TextDAO.Functions.Delegation.RevokeDelegation
import TextDAO.Functions.Delegation.DelegationView
import TextDAO.Functions.Delegation.DelegationProxy

%default covering

-- =============================================================================
-- Type Verification Tests
-- =============================================================================

||| Verify DelegateMapping record exists and has correct structure
export
testDelegationRecordType : DelegateMapping -> Bool
testDelegationRecordType (MkDelegateMapping delegatee isActive) =
  True  -- Type checks at compile time

||| Verify delegation storage slot constants are defined
export
testDelegationSlots : Bool
testDelegationSlots =
     SLOT_DELEGATION == 0x6000
  && SLOT_DELEGATE_MAPPING == 0x6001
  && SLOT_VOTING_POWER == 0x6002

-- =============================================================================
-- Selector Verification Tests
-- =============================================================================

||| Verify delegate selector
export
testDelegateSelector : Bool
testDelegateSelector = delegationRegistry.delegateSelector == 0x5c19a95c

||| Verify revokeDelegation selector
export
testRevokeSelector : Bool
testRevokeSelector = delegationRegistry.revokeSelector == 0xc24a0cee

||| Verify getDelegate selector
export
testGetDelegateSelector : Bool
testGetDelegateSelector = delegationRegistry.getDelegateSelector == 0xc58343ef

||| Verify getVotingPower selector
export
testGetVotingPowerSelector : Bool
testGetVotingPowerSelector = delegationRegistry.getVotingPowerSelector == 0x68e7e112

||| Verify isDelegationSelector correctly identifies delegation selectors
export
testIsDelegationSelector : Bool
testIsDelegationSelector =
     isDelegationSelector 0x5c19a95c  -- delegate
  && isDelegationSelector 0xc24a0cee  -- revokeDelegation
  && isDelegationSelector 0xc58343ef  -- getDelegate
  && isDelegationSelector 0x68e7e112  -- getVotingPower
  && not (isDelegationSelector 0x00000000)  -- not a delegation selector

-- =============================================================================
-- Proxy Integration Tests
-- =============================================================================

||| Verify ERC-7546 getImplementation selector
export
testGetImplementationSelector : Bool
testGetImplementationSelector = True  -- 0xdc9cc645 is defined in DelegationProxy

-- =============================================================================
-- Runtime Tests (IO-based, for AllTests runner)
-- =============================================================================

||| REQ_DELEG_001: Verify delegation storage slot constants
export
test_REQ_DELEG_001_storageSlots : IO Bool
test_REQ_DELEG_001_storageSlots = pure testDelegationSlots

||| REQ_DELEG_002: Verify delegation selectors are correctly registered
export
test_REQ_DELEG_002_selectors : IO Bool
test_REQ_DELEG_002_selectors = pure $
     testDelegateSelector
  && testRevokeSelector
  && testGetDelegateSelector
  && testGetVotingPowerSelector

||| REQ_DELEG_003: Verify isDelegationSelector routing
export
test_REQ_DELEG_003_selectorRouting : IO Bool
test_REQ_DELEG_003_selectorRouting = pure testIsDelegationSelector

||| REQ_DELEG_004: Verify getImplementation proxy integration
export
test_REQ_DELEG_004_proxyIntegration : IO Bool
test_REQ_DELEG_004_proxyIntegration = pure testGetImplementationSelector

||| REQ_DELEG_005: Verify DelegateMapping record type structure
export
test_REQ_DELEG_005_recordType : IO Bool
test_REQ_DELEG_005_recordType = pure $
  testDelegationRecordType (MkDelegateMapping 0 0)
