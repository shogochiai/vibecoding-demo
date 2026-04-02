||| TextDAO Delegation Proxy Registration
||| REQ_DELEG_005: ERC-7546 proxy integration for delegation facet
|||
||| Registers delegation function selectors in the ERC-7546 diamond proxy
||| so that getImplementation (selector 0xdc9cc645) routes to the delegation facets.
module TextDAO.Functions.Delegation.DelegationProxy

import public Subcontract.Core.Entry
import Subcontract.Core.ABI.Decoder
import public Subcontract.Core.Outcome
import public TextDAO.Storages.Schema
import TextDAO.Functions.Delegation.Delegation
import TextDAO.Functions.Delegation.RevokeDelegation
import TextDAO.Functions.Delegation.DelegationView

%default covering

-- =============================================================================
-- ERC-7546 Proxy Selector Routing
-- =============================================================================

||| getImplementation(bytes4) -> address
||| ERC-7546 standard selector: 0xdc9cc645
||| Routes function selectors to their implementation contract addresses
public export
getImplementationSig : Sig
getImplementationSig = MkSig "getImplementation" [TBytes32] [TAddress]

public export
getImplementationSel : Sel getImplementationSig
getImplementationSel = MkSel 0xdc9cc645

-- =============================================================================
-- Delegation Facet Selector Registry
-- =============================================================================

||| All delegation-related function selectors
||| Used by the proxy to route calls to the correct facet implementation
|||
||| delegate(address)         = 0x5c19a95c
||| revokeDelegation()        = 0xc24a0cee
||| delegateOf(address)       = 0xc58343ef
||| votingPowerOf(address)    = 0x68e7e112
public export
record DelegationFacetRegistry where
  constructor MkDelegationFacetRegistry
  delegateSelector       : Integer
  revokeSelector         : Integer
  getDelegateSelector    : Integer
  getVotingPowerSelector : Integer

||| The delegation facet registry with all selectors
public export
delegationRegistry : DelegationFacetRegistry
delegationRegistry = MkDelegationFacetRegistry
  0x5c19a95c  -- delegate(address)
  0xc24a0cee  -- revokeDelegation()
  0xc58343ef  -- getDelegate(address)
  0x68e7e112  -- getVotingPower(address)

||| Check if a selector belongs to the delegation facet
export
isDelegationSelector : Integer -> Bool
isDelegationSelector sel =
     sel == delegationRegistry.delegateSelector
  || sel == delegationRegistry.revokeSelector
  || sel == delegationRegistry.getDelegateSelector
  || sel == delegationRegistry.getVotingPowerSelector
