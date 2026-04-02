||| Delegation Module — Vote Delegation for TextDAO
||| REQ_DELEG_001: Shareholder can delegate voting power to another address
||| REQ_DELEG_002: 1:1 delegation only, re-delegation blocked (ALREADY_DELEGATED)
||| REQ_DELEG_003: Read functions — delegateOf(address) & votingPowerOf(address)
||| REQ_DELEG_004: Revoke delegation by delegator (onlyDelegator)
|||
||| delegate(address) — delegate voting power to another address
||| revoke — revoke current delegation
||| delegateOf(address) — query current delegatee
||| votingPowerOf(address) — query aggregated voting power
||| NoDelegationChain — block transitive delegation (A->B->C)
||| noReDelegate — prevent re-delegation while active
module Delegation

import public TextDAO.Functions.Delegation.Delegation
import public TextDAO.Functions.Delegation.RevokeDelegation
import public TextDAO.Functions.Delegation.DelegationView
import public TextDAO.Functions.Delegation.DelegationProxy

%default covering
