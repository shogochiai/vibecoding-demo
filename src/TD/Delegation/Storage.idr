||| TD Delegation Storage — td.onthe.eth
||| REQ_DELEG_001: Storage read/write for delegation mappings
||| REQ_DELEG_002: Voting power accumulation helpers
||| REQ_DELEG_003: Revocation storage operations
module TD.Delegation.Storage

import public Delegation.Types
import public EVM.Primitives

%default covering

-- =============================================================================
-- Storage Slot Calculation
-- =============================================================================

||| Calculate storage slot for a delegator's delegatee address
||| slot = keccak256(delegator . DELEGATION_SLOT_DELEGATEE)
export
getDelegateeSlot : EvmAddr -> IO Integer
getDelegateeSlot delegator = do
  mstore 0 delegator
  mstore 32 DELEGATION_SLOT_DELEGATEE
  keccak256 0 64

||| Calculate storage slot for a delegatee's accumulated voting power
||| slot = keccak256(delegatee . DELEGATION_SLOT_VOTING_POWER)
export
getVotingPowerSlot : EvmAddr -> IO Integer
getVotingPowerSlot delegatee = do
  mstore 0 delegatee
  mstore 32 DELEGATION_SLOT_VOTING_POWER
  keccak256 0 64

||| Calculate storage slot for an address's base (own) voting power
||| slot = keccak256(address . DELEGATION_SLOT_BASE_POWER)
export
getBasePowerSlot : EvmAddr -> IO Integer
getBasePowerSlot addr = do
  mstore 0 addr
  mstore 32 DELEGATION_SLOT_BASE_POWER
  keccak256 0 64

-- =============================================================================
-- Delegatee Read/Write — REQ_DELEG_001
-- =============================================================================

||| Get the current delegatee for a delegator (0 = no delegation)
export
getDelegatee : EvmAddr -> IO EvmAddr
getDelegatee delegator = do
  slot <- getDelegateeSlot delegator
  sload slot

||| Set the delegatee for a delegator
export
setDelegatee : EvmAddr -> EvmAddr -> IO ()
setDelegatee delegator delegatee = do
  slot <- getDelegateeSlot delegator
  sstore slot delegatee

-- =============================================================================
-- Voting Power Read/Write — REQ_DELEG_002
-- =============================================================================

||| Get accumulated voting power for an address (own + delegated)
export
getVotingPower : EvmAddr -> IO VotingPower
getVotingPower addr = do
  slot <- getVotingPowerSlot addr
  sload slot

||| Set accumulated voting power for an address
export
setVotingPower : EvmAddr -> VotingPower -> IO ()
setVotingPower addr power = do
  slot <- getVotingPowerSlot addr
  sstore slot power

||| Get base (own) voting power for an address
export
getBasePower : EvmAddr -> IO VotingPower
getBasePower addr = do
  slot <- getBasePowerSlot addr
  sload slot

||| Set base (own) voting power for an address
export
setBasePower : EvmAddr -> VotingPower -> IO ()
setBasePower addr power = do
  slot <- getBasePowerSlot addr
  sstore slot power

-- =============================================================================
-- Voting Power Accumulation — REQ_DELEG_002
-- =============================================================================

||| Add voting power to a delegatee's accumulated total
||| REQ_DELEG_002: delegatee accumulates delegator's voting power
export
addVotingPower : EvmAddr -> VotingPower -> IO ()
addVotingPower delegatee amount = do
  current <- getVotingPower delegatee
  setVotingPower delegatee (current + amount)

||| Remove voting power from a delegatee's accumulated total
||| REQ_DELEG_003: revocation restores original voting power
export
removeVotingPower : EvmAddr -> VotingPower -> IO ()
removeVotingPower delegatee amount = do
  current <- getVotingPower delegatee
  let newPower = if current >= amount then current - amount else 0
  setVotingPower delegatee newPower

-- =============================================================================
-- Delegation State Checks — REQ_DELEG_004
-- =============================================================================

||| Check if an address has an active delegation
export
hasActiveDelegation : EvmAddr -> IO Bool
hasActiveDelegation delegator = do
  delegatee <- getDelegatee delegator
  pure (delegatee /= ZERO_ADDR)
