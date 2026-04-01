||| REQ_TIMELINE_004: ERC-7546 proxy selector registration for Timeline facet
||| Registers getProposalTimeline selector in the UCS function registry
module FunctionRegistry

import EVM.Primitives

%default total

----------------------------------------------------------------------
-- ERC-7546 Selector Constants
----------------------------------------------------------------------

||| getProposalTimeline(uint256) function selector
||| keccak256("getProposalTimeline(uint256)") >> 224
public export
selectorGetProposalTimeline : Integer
selectorGetProposalTimeline = 0xb3a0a8d0

----------------------------------------------------------------------
-- ERC-7546 Registry Storage Layout
----------------------------------------------------------------------

||| ERC-7546 UCS registry base slot
||| keccak256("erc7546.proxy.registry") — standard namespace
public export
registryBaseSlot : Integer
registryBaseSlot = 0x2f7ed27098ecb1f9c2f5a3d07ac4d1e1fa06d1a3e7c1d2b8f9a0e3c4d5b6a7f8

||| Compute registry slot for a given function selector
||| Maps bytes4 selector -> address (implementation contract)
public export
registrySlot : Integer -> Integer
registrySlot selector = registryBaseSlot + selector

----------------------------------------------------------------------
-- REQ_TIMELINE_004: Registration entry
----------------------------------------------------------------------

||| Register getProposalTimeline in the ERC-7546 proxy function registry.
||| Called by the admin/deployer during facet installation.
|||
||| @implAddr Address of the deployed Timeline facet contract
export
registerTimeline : Integer -> IO ()
registerTimeline implAddr = do
  let slot = registrySlot selectorGetProposalTimeline
  sstore slot implAddr

||| Read the implementation address for getProposalTimeline
export
getTimelineImpl : IO Integer
getTimelineImpl = do
  let slot = registrySlot selectorGetProposalTimeline
  sload slot

----------------------------------------------------------------------
-- Selector dispatch integration point
----------------------------------------------------------------------

||| Selector table entry for proxy dispatch integration.
||| The proxy's fallback reads: getImplementation(bytes4 selector) -> address
||| and delegatecalls to the returned address.
|||
||| This module provides the mapping:
|||   0xb3a0a8d0 -> Timeline facet address
export
getImplementation : IO ()
getImplementation = do
  selector <- calldataload 4
  let slot = registrySlot selector
  impl <- sload slot
  -- Return address (right-aligned in 32 bytes)
  mstore 0 impl
  evmReturn 0 32
