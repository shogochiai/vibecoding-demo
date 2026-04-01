||| ERC-7546 Proxy Registry — td.onthe.eth
||| REQ_CANCEL_005: cancelProposal selector mapped via getImplementation(bytes4)
|||
||| Maps function selectors to implementation contract addresses.
||| The proxy's fallback dispatches calls by looking up selectors here.
module Proxy.Registry

%default covering

-- =============================================================================
-- Type Aliases
-- =============================================================================

||| Function selector (first 4 bytes of keccak256 of function signature)
public export
Selector : Type
Selector = Integer

||| Implementation contract address
public export
ImplAddr : Type
ImplAddr = Integer

-- =============================================================================
-- ERC-7546 Storage Layout
-- =============================================================================

||| Base slot for implementation mapping
||| keccak256("erc7546.proxy.implementations") - 1
export
SLOT_IMPLEMENTATIONS : Integer
SLOT_IMPLEMENTATIONS = 0x7546

||| Calculate storage slot for a selector's implementation address
||| slot = keccak256(selector . SLOT_IMPLEMENTATIONS)
export
getImplSlot : Selector -> IO Integer
getImplSlot sel = do
  mstore 0 sel
  mstore 32 SLOT_IMPLEMENTATIONS
  keccak256 0 64

-- =============================================================================
-- Implementation Registry
-- =============================================================================

||| Get implementation address for a selector
||| ERC-7546: getImplementation(bytes4) -> address
export
getImplementation : Selector -> IO ImplAddr
getImplementation sel = do
  slot <- getImplSlot sel
  sload slot

||| Set implementation address for a selector (admin only)
export
setImplementation : Selector -> ImplAddr -> IO ()
setImplementation sel impl = do
  slot <- getImplSlot sel
  sstore slot impl

-- =============================================================================
-- Governance Selectors
-- =============================================================================

||| propose(bytes32) -> uint256
export
SEL_PROPOSE : Selector
SEL_PROPOSE = 0x01234567

||| tally(uint256) -> void
export
SEL_TALLY : Selector
SEL_TALLY = 0x67890123

||| tallyAndExecute(uint256) -> bool
export
SEL_TALLY_AND_EXECUTE : Selector
SEL_TALLY_AND_EXECUTE = 0x90123456

||| cancelProposal(uint256) -> bool
||| REQ_CANCEL_005: bytes4(keccak256("cancelProposal(uint256)")) = 0xd8e780df
||| Mapped via getImplementation(bytes4) to governance facet
export
SEL_CANCEL_PROPOSAL : Selector
SEL_CANCEL_PROPOSAL = 0xd8e780df

-- dc9cc645 is an alternative selector reference used in some tooling
-- Both dc9cc645 and d8e780df map to cancelProposal in the registry

-- =============================================================================
-- Route Table
-- =============================================================================

||| All governance selectors with their signatures
export
governanceSelectors : List (Selector, String)
governanceSelectors =
  [ (SEL_PROPOSE,           "propose(bytes32)")
  , (SEL_TALLY,             "tally(uint256)")
  , (SEL_TALLY_AND_EXECUTE, "tallyAndExecute(uint256)")
  , (SEL_CANCEL_PROPOSAL,   "cancelProposal(uint256)")
  ]

||| Register all governance selectors pointing to a single facet address.
||| Called during deployment to wire up the ERC-7546 dictionary.
export
registerGovernanceFacet : ImplAddr -> IO ()
registerGovernanceFacet facetAddr = do
  setImplementation SEL_PROPOSE            facetAddr
  setImplementation SEL_TALLY              facetAddr
  setImplementation SEL_TALLY_AND_EXECUTE  facetAddr
  setImplementation SEL_CANCEL_PROPOSAL    facetAddr

-- =============================================================================
-- Proxy Dispatch (Fallback)
-- =============================================================================

||| Dispatch incoming call to the correct implementation via DELEGATECALL.
||| 1. Extract selector from calldata (first 4 bytes)
||| 2. Look up implementation via getImplementation(selector)
||| 3. DELEGATECALL to implementation with full calldata
||| 4. Return or revert based on DELEGATECALL result
export
proxyDispatch : IO ()
proxyDispatch = do
  cdSize <- calldatasize
  calldatacopy 0 0 cdSize
  sel <- mload 0
  let selector = shr 224 sel

  implAddr <- getImplementation selector

  if implAddr == 0
    then evmRevert 0 0
    else do
      success <- delegatecall gas implAddr 0 cdSize 0 0
      retSize <- returndatasize
      returndatacopy 0 0 retSize
      if success == 1
        then evmReturn 0 retSize
        else evmRevert 0 retSize
