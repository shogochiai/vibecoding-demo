||| Delegation Event Definitions — td.onthe.eth
||| REQ_DELEG_001: DelegateChanged event
||| REQ_DELEG_003: DelegateRevoked event
module Delegation.Events

%default total

-- =============================================================================
-- Delegation Events
-- =============================================================================

||| DelegateChanged(address indexed delegator, address indexed delegatee, uint256 votingPower)
||| Emitted when a shareholder delegates voting power.
||| Topic[0] = keccak256("DelegateChanged(address,address,uint256)")
public export
EVENT_DELEGATE_CHANGED : Integer
EVENT_DELEGATE_CHANGED = 0x3134e8a2e6d97e929a7e54011ea5485d7d196dd5f0ba4d4ef95803e8e3fc257f

||| DelegateRevoked(address indexed delegator, address indexed previousDelegatee, uint256 votingPower)
||| Emitted when a shareholder revokes their delegation.
||| Topic[0] = keccak256("DelegateRevoked(address,address,uint256)")
public export
EVENT_DELEGATE_REVOKED : Integer
EVENT_DELEGATE_REVOKED = 0x9b1a5d82f45e4aa0cf9b5c3b1a4c0b6e2d8f7a3e6c9d0b4a7f2e5d8c1b3a6f90
