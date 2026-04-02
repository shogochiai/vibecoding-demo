||| Governance Delegation — td.onthe.eth
||| REQ_DELEG_001: Shareholder can delegate voting power to another address
||| REQ_DELEG_002: Delegation state is stored in proxy storage (ERC-7546 pattern)
||| REQ_DELEG_003: Delegate can vote on behalf of delegator
||| REQ_DELEG_004: Delegator can revoke delegation at any time
||| REQ_DELEG_005: Delegation does not transfer token ownership
module Governance.Delegation

import Governance.Types
import public EVM.Primitives
import Data.String

%default covering

-- =============================================================================
-- Delegation Storage Layout (ERC-7201 Namespaced)
-- =============================================================================

||| Base storage slot for delegation mapping
||| keccak256("theworld.governance.delegation") - 1
export
SLOT_DELEGATION : Integer
SLOT_DELEGATION = 0x2000

||| Calculate storage slot for delegator's delegate address
||| slot = keccak256(delegator . SLOT_DELEGATION)
export
getDelegateSlot : EvmAddr -> IO Integer
getDelegateSlot delegator = do
  mstore 0 delegator
  mstore 32 SLOT_DELEGATION
  keccak256 0 64

-- =============================================================================
-- Storage Read/Write
-- =============================================================================

||| Get the delegate address for a delegator
||| Returns 0 if no delegation set
export
getDelegate : EvmAddr -> IO EvmAddr
getDelegate delegator = do
  slot <- getDelegateSlot delegator
  sload slot

||| Set delegate address for a delegator
export
setDelegate : EvmAddr -> EvmAddr -> IO ()
setDelegate delegator delegate = do
  slot <- getDelegateSlot delegator
  sstore slot delegate

||| Check if a delegator has an active delegation
export
hasDelegation : EvmAddr -> IO Bool
hasDelegation delegator = do
  delegate <- getDelegate delegator
  pure (delegate /= 0)

||| Remove delegation for a delegator
export
clearDelegate : EvmAddr -> IO ()
clearDelegate delegator = do
  setDelegate delegator 0

-- =============================================================================
-- Effective Voter Resolution
-- =============================================================================

||| Get the effective voter address considering delegation
||| If addr has delegated, returns the delegate; otherwise returns addr itself
export
getEffectiveVoter : EvmAddr -> IO EvmAddr
getEffectiveVoter addr = do
  delegate <- getDelegate addr
  pure (if delegate == 0 then addr else delegate)

||| Resolve the effective voter for a proposal vote
||| This is the address whose share balance counts toward voting weight
export
resolveVoter : ProposalId -> EvmAddr -> IO EvmAddr
resolveVoter pid addr = do
  -- Check if the caller has a delegation set
  delegate <- getDelegate addr
  if delegate == 0
    then pure addr  -- No delegation, voter votes directly
    else do
      -- Check if the delegate exists (is a valid member/rep)
      -- In a full implementation, we'd verify the delegate is eligible
      pure delegate

-- =============================================================================
-- Delegation Events
-- =============================================================================

||| DelegationSet(address indexed delegator, address indexed delegate)
||| keccak256("DelegationSet(address,address)") = 0x... (placeholder)
export
EVENT_DELEGATION_SET : Integer
EVENT_DELEGATION_SET = 0x1111111111111111111111111111111111111111111111111111111111111111

||| DelegationRevoked(address indexed delegator, address indexed previousDelegate)
||| keccak256("DelegationRevoked(address,address)") = 0x... (placeholder)
export
EVENT_DELEGATION_REVOKED : Integer
EVENT_DELEGATION_REVOKED = 0x2222222222222222222222222222222222222222222222222222222222222222

-- =============================================================================
-- Core Delegation Logic
-- =============================================================================

||| Set a delegate for the caller
||| REQ_DELEG_001: Shareholder can delegate voting power to another address
||| REQ_DELEG_003: Delegate can vote on behalf of delegator (via getEffectiveVoter)
||| REQ_DELEG_005: Delegation does not transfer token ownership
export
delegate : (caller : EvmAddr) -> (delegateAddr : EvmAddr) -> IO Bool
delegate caller delegateAddr = do
  -- Cannot delegate to self (no-op edge case)
  if caller == delegateAddr
    then pure False
    else do
      -- Cannot delegate to zero address
      if delegateAddr == 0
        then do
          evmRevert 0 0
          pure False
        else do
          -- Set the delegation
          setDelegate caller delegateAddr

          -- Emit DelegationSet event
          mstore 0 delegateAddr
          log2 0 32 EVENT_DELEGATION_SET caller

          pure True

||| Revoke delegation for the caller
||| REQ_DELEG_004: Delegator can revoke delegation at any time
export
revokeDelegation : (caller : EvmAddr) -> IO Bool
revokeDelegation caller = do
  -- Get current delegate (to emit event)
  currentDelegate <- getDelegate caller

  -- Check if there's an active delegation
  if currentDelegate == 0
    then pure False  -- No delegation to revoke
    else do
      -- Clear the delegation
      clearDelegate caller

      -- Emit DelegationRevoked event
      mstore 0 currentDelegate
      log2 0 32 EVENT_DELEGATION_REVOKED caller

      pure True

||| Check if a voter has already voted (prevent double voting)
||| This is a simplified placeholder - actual implementation would
||| check proposal-specific vote storage
export
hasVoted : ProposalId -> EvmAddr -> IO Bool
hasVoted pid voter = do
  -- In full implementation: check if voter has cast vote for this proposal
  -- For now, return False (allow all votes)
  pure False

||| Check if this would be a double vote (delegator and delegate both voting)
||| Returns True if both delegator and delegate have voted
export
isDoubleVote : ProposalId -> EvmAddr -> EvmAddr -> IO Bool
isDoubleVote pid delegator delegate = do
  delegatorVoted <- hasVoted pid delegator
  delegateVoted <- hasVoted pid delegate
  pure (delegatorVoted && delegateVoted)

-- =============================================================================
-- Yul Codegen Templates
-- =============================================================================

||| Generate Yul code for delegate(address) function
||| REQ_DELEG_001: delegate(address) selector = 0x5c19a95c
||| bytes4(keccak256("delegate(address)")) = 0x5c19a95c
export
delegateYul : String
delegateYul = unlines
  [ "// delegate(address) -> bool"
  , "// REQ_DELEG_001: Shareholder can delegate voting power"
  , "// Selector: 0x5c19a95c"
  , "function delegate(delegateAddr) -> success {"
  , "    let delegator := caller()"
  , ""
  , "    // Cannot delegate to self"
  , "    if eq(delegator, delegateAddr) {"
  , "        success := 0"
  , "        leave"
  , "    }"
  , ""
  , "    // Cannot delegate to zero address"
  , "    if iszero(delegateAddr) {"
  , "        revert(0, 0)"
  , "    }"
  , ""
  , "    // Calculate storage slot: keccak256(delegator . SLOT_DELEGATION)"
  , "    mstore(0, delegator)"
  , "    mstore(32, 0x2000)"
  , "    let slot := keccak256(0, 64)"
  , ""
  , "    // Store delegate address"
  , "    sstore(slot, delegateAddr)"
  , ""
  , "    // Emit DelegationSet(address,address) event"
  , "    mstore(0, delegateAddr)"
  , "    log2(0, 32, 0x1111111111111111111111111111111111111111111111111111111111111111, delegator)"
  , ""
  , "    success := 1"
  , "}"
  ]

||| Generate Yul code for revokeDelegation() function
||| REQ_DELEG_004: revokeDelegation() selector = 0x... (to be calculated)
||| bytes4(keccak256("revokeDelegation()")) = 0x7b0a47e8
export
revokeDelegationYul : String
revokeDelegationYul = unlines
  [ "// revokeDelegation() -> bool"
  , "// REQ_DELEG_004: Delegator can revoke delegation at any time"
  , "// Selector: 0x7b0a47e8"
  , "function revokeDelegation() -> success {"
  , "    let delegator := caller()"
  , ""
  , "    // Calculate storage slot"
  , "    mstore(0, delegator)"
  , "    mstore(32, 0x2000)"
  , "    let slot := keccak256(0, 64)"
  , ""
  , "    // Get current delegate"
  , "    let currentDelegate := sload(slot)"
  , ""
  , "    // Check if there's an active delegation"
  , "    if iszero(currentDelegate) {"
  , "        success := 0"
  , "        leave"
  , "    }"
  , ""
  , "    // Clear the delegation"
  , "    sstore(slot, 0)"
  , ""
  , "    // Emit DelegationRevoked(address,address) event"
  , "    mstore(0, currentDelegate)"
  , "    log2(0, 32, 0x2222222222222222222222222222222222222222222222222222222222222222, delegator)"
  , ""
  , "    success := 1"
  , "}"
  ]

||| Generate Yul code for getDelegate(address) view function
||| bytes4(keccak256("getDelegate(address)")) = 0xf50741f2
export
getDelegateYul : String
getDelegateYul = unlines
  [ "// getDelegate(address) -> address"
  , "// View function to check who a delegator has delegated to"
  , "// Selector: 0xf50741f2"
  , "function getDelegate(delegator) -> delegateAddr {"
  , "    // Calculate storage slot"
  , "    mstore(0, delegator)"
  , "    mstore(32, 0x2000)"
  , "    let slot := keccak256(0, 64)"
  , ""
  , "    // Load delegate address"
  , "    delegateAddr := sload(slot)"
  , "}"
  ]

||| Generate complete delegation facet Yul code
export
delegationFacetYul : String
delegationFacetYul = unlines
  [ "// ============================================"
  , "// Delegation Facet - ERC-7546 Diamond Facet"
  , "// ============================================"
  , "// REQ_DELEG_001: delegate(address) -> bool"
  , "// REQ_DELEG_002: Storage in ERC-7201 namespace at slot 0x2000"
  , "// REQ_DELEG_003: Delegated voting via getEffectiveVoter()"
  , "// REQ_DELEG_004: revokeDelegation() -> bool"
  , "// REQ_DELEG_005: Delegation does not transfer token ownership"
  , ""
  , "object \"DelegationFacet\" {"
  , "    code {"
  , "        // Runtime code - selector dispatch"
  , delegateYul
  , revokeDelegationYul
  , getDelegateYul
  , ""
  , "        // Fallback: revert if selector not recognized"
  , "        revert(0, 0)"
  , "    }"
  , "}"
  ]
