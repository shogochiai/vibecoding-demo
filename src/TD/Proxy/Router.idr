||| TD ERC-7546 Proxy Router
||| REQ_CANCEL_005: cancelProposal selector routed via proxy getImplementation(bytes4)
||| REQ_DELEG_005: delegation facet selectors routed via proxy
|||
||| ERC-7546 Dictionary-based proxy pattern: the proxy delegates calls to
||| implementation contracts by looking up selectors in a routing table.
||| Each selector maps to an implementation address via getImplementation(bytes4).
module TD.Proxy.Router

import public Subcontract.Core.Entry
import public Subcontract.Core.Storable

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
-- Governance Function Selectors
-- =============================================================================

||| propose(bytes32) -> uint256
export
SEL_PROPOSE : Selector
SEL_PROPOSE = 0x01234567

||| getHeader(uint256,uint256) -> bytes32
export
SEL_GET_HEADER : Selector
SEL_GET_HEADER = 0x12345678

||| getProposalCount() -> uint256
export
SEL_GET_PROPOSAL_COUNT : Selector
SEL_GET_PROPOSAL_COUNT = 0x23456789

||| vote(uint256,uint256[3],uint256[3]) -> bool
export
SEL_VOTE : Selector
SEL_VOTE = 0x34567890

||| isRep(uint256,address) -> bool
export
SEL_IS_REP : Selector
SEL_IS_REP = 0x56789012

||| tally(uint256) -> void
export
SEL_TALLY : Selector
SEL_TALLY = 0x67890123

||| snap(uint256) -> void
export
SEL_SNAP : Selector
SEL_SNAP = 0x78901234

||| isApproved(uint256) -> bool
export
SEL_IS_APPROVED : Selector
SEL_IS_APPROVED = 0x89012345

||| tallyAndExecute(uint256) -> bool
export
SEL_TALLY_AND_EXECUTE : Selector
SEL_TALLY_AND_EXECUTE = 0x90123456

||| cancelProposal(uint256) -> bool
||| REQ_CANCEL_005: bytes4(keccak256("cancelProposal(uint256)")) = 0xd8e780df
export
SEL_CANCEL_PROPOSAL : Selector
SEL_CANCEL_PROPOSAL = 0xd8e780df

-- =============================================================================
-- Delegation Function Selectors — REQ_DELEG_005
-- =============================================================================

||| delegate(address) -> bool
||| REQ_DELEG_005: bytes4(keccak256("delegate(address)")) = 0x5c19a95c
export
SEL_DELEGATE : Selector
SEL_DELEGATE = 0x5c19a95c

||| revokeDelegation() -> bool
||| REQ_DELEG_005: bytes4(keccak256("revokeDelegation()")) = 0xa7713a70
export
SEL_REVOKE_DELEGATION : Selector
SEL_REVOKE_DELEGATION = 0xa7713a70

||| getDelegate(address) -> address
||| REQ_DELEG_005: bytes4(keccak256("getDelegate(address)")) = 0xb5b3ca2c
export
SEL_GET_DELEGATE : Selector
SEL_GET_DELEGATE = 0xb5b3ca2c

||| getVotingPower(address) -> uint256
||| REQ_DELEG_005: bytes4(keccak256("getVotingPower(address)")) = 0x7ed4b27c
export
SEL_GET_VOTING_POWER : Selector
SEL_GET_VOTING_POWER = 0x7ed4b27c

-- =============================================================================
-- Route Table Initialization
-- =============================================================================

||| All governance selectors with their logical groupings
export
governanceSelectors : List (Selector, String)
governanceSelectors =
  [ (SEL_PROPOSE,           "propose(bytes32)")
  , (SEL_GET_HEADER,        "getHeader(uint256,uint256)")
  , (SEL_GET_PROPOSAL_COUNT,"getProposalCount()")
  , (SEL_VOTE,              "vote(uint256,uint256[3],uint256[3])")
  , (SEL_IS_REP,            "isRep(uint256,address)")
  , (SEL_TALLY,             "tally(uint256)")
  , (SEL_SNAP,              "snap(uint256)")
  , (SEL_IS_APPROVED,       "isApproved(uint256)")
  , (SEL_TALLY_AND_EXECUTE, "tallyAndExecute(uint256)")
  , (SEL_CANCEL_PROPOSAL,   "cancelProposal(uint256)")
  ]

||| All delegation selectors — REQ_DELEG_005
export
delegationSelectors : List (Selector, String)
delegationSelectors =
  [ (SEL_DELEGATE,           "delegate(address)")
  , (SEL_REVOKE_DELEGATION,  "revokeDelegation()")
  , (SEL_GET_DELEGATE,       "getDelegate(address)")
  , (SEL_GET_VOTING_POWER,   "getVotingPower(address)")
  ]

||| Register all governance selectors pointing to a single facet address
||| Used during deployment to wire up the ERC-7546 dictionary
export
registerGovernanceFacet : ImplAddr -> IO ()
registerGovernanceFacet facetAddr = do
  setImplementation SEL_PROPOSE            facetAddr
  setImplementation SEL_GET_HEADER         facetAddr
  setImplementation SEL_GET_PROPOSAL_COUNT facetAddr
  setImplementation SEL_VOTE               facetAddr
  setImplementation SEL_IS_REP             facetAddr
  setImplementation SEL_TALLY              facetAddr
  setImplementation SEL_SNAP               facetAddr
  setImplementation SEL_IS_APPROVED        facetAddr
  setImplementation SEL_TALLY_AND_EXECUTE  facetAddr
  setImplementation SEL_CANCEL_PROPOSAL    facetAddr

||| Register all delegation selectors pointing to the delegation facet address
||| REQ_DELEG_005: ERC-7546 proxy integration for delegation facet
export
registerDelegationFacet : ImplAddr -> IO ()
registerDelegationFacet facetAddr = do
  setImplementation SEL_DELEGATE          facetAddr
  setImplementation SEL_REVOKE_DELEGATION facetAddr
  setImplementation SEL_GET_DELEGATE      facetAddr
  setImplementation SEL_GET_VOTING_POWER  facetAddr

-- =============================================================================
-- Proxy Dispatch (Fallback Function)
-- =============================================================================

||| Dispatch incoming call to the correct implementation via DELEGATECALL
||| This is the proxy fallback function:
|||   1. Extract selector from calldata (first 4 bytes)
|||   2. Look up implementation via getImplementation(selector)
|||   3. DELEGATECALL to implementation with full calldata
|||   4. Return or revert based on DELEGATECALL result
export
proxyDispatch : IO ()
proxyDispatch = do
  -- Extract selector from calldata
  calldataSize <- EVM.Primitives.calldatasize
  calldatacopy 0 0 calldataSize
  sel <- mload 0
  selector <- shr 224 sel  -- right-shift 224 bits to get first 4 bytes

  -- Look up implementation
  implAddr <- getImplementation selector

  -- If no implementation registered, revert
  if implAddr == 0
    then evmRevert 0 0
    else do
      -- DELEGATECALL to implementation
      gasAvail <- gas
      success <- delegatecall gasAvail implAddr 0 calldataSize 0 0

      -- Copy return data
      retSize <- returndatasize
      returndatacopy 0 0 retSize

      -- Return or revert based on success
      if success == 1
        then evmReturn 0 retSize
        else evmRevert 0 retSize
