||| ERC-7546 Proxy Registry
||| REQ_CANCEL_005 — Register cancelProposal selector in proxy
|||
||| This module manages the ERC-7546 Universal Contract Standard (UCS) selector
||| registry, mapping function selectors to their implementation addresses.
||| getImplementation(bytes4) resolves each selector to the correct facet.
module Proxy.Registry

import public Subcontract.Core.Entry
import public Subcontract.Core.Storable
import public Subcontract.Core.Outcome

%default covering

-- =============================================================================
-- ERC-7546 Selector Registry
-- =============================================================================

||| Storage slot for the implementation registry mapping
||| slot = keccak256("erc7546.proxy.implementations") - 1
SLOT_IMPLEMENTATIONS : Integer
SLOT_IMPLEMENTATIONS = 0x7000

||| Calculate storage slot for a function selector's implementation
||| slot = keccak256(selector . SLOT_IMPLEMENTATIONS)
getImplSlot : Integer -> IO Integer
getImplSlot selector = do
  mstore 0 selector
  mstore 32 SLOT_IMPLEMENTATIONS
  keccak256 0 64

-- =============================================================================
-- Implementation Registration
-- =============================================================================

||| Register a function selector to an implementation address
||| Used during deployment to wire up the ERC-7546 proxy
export
registerImplementation : Integer -> Integer -> IO ()
registerImplementation selector implAddr = do
  slot <- getImplSlot selector
  sstore slot implAddr

||| Get the implementation address for a function selector
||| getImplementation(bytes4) -> address
||| This is the core ERC-7546 dispatch mechanism
export
getImplementation : Integer -> IO Integer
getImplementation selector = do
  slot <- getImplSlot selector
  sload slot

-- =============================================================================
-- Function Selectors
-- =============================================================================

||| cancelProposal(uint256) selector = 0xd8e780df
||| REQ_CANCEL_005: Registered in proxy for ERC-7546 dispatch
export
SELECTOR_CANCEL_PROPOSAL : Integer
SELECTOR_CANCEL_PROPOSAL = 0xd8e780df

||| propose(bytes32) selector
export
SELECTOR_PROPOSE : Integer
SELECTOR_PROPOSE = 0x01234567

||| vote(uint256,uint256[3],uint256[3]) selector
export
SELECTOR_VOTE : Integer
SELECTOR_VOTE = 0x34567890

||| tally(uint256) selector
export
SELECTOR_TALLY : Integer
SELECTOR_TALLY = 0x67890123

||| isApproved(uint256) selector
export
SELECTOR_IS_APPROVED : Integer
SELECTOR_IS_APPROVED = 0x89012345

-- =============================================================================
-- Proxy Initialization
-- =============================================================================

||| Register all governance selectors in the ERC-7546 proxy
||| Called during deployment to configure the proxy routing table
|||
||| REQ_CANCEL_005: cancelProposal is registered here so that
||| getImplementation(0xd8e780df) resolves to the Cancel implementation
export
registerAllSelectors : Integer  -- proposeImpl
                    -> Integer  -- voteImpl
                    -> Integer  -- tallyImpl
                    -> Integer  -- cancelImpl (IP-25)
                    -> IO ()
registerAllSelectors proposeImpl voteImpl tallyImpl cancelImpl = do
  registerImplementation SELECTOR_PROPOSE proposeImpl
  registerImplementation SELECTOR_VOTE voteImpl
  registerImplementation SELECTOR_TALLY tallyImpl
  registerImplementation SELECTOR_IS_APPROVED tallyImpl
  -- IP-25: Register cancelProposal selector
  registerImplementation SELECTOR_CANCEL_PROPOSAL cancelImpl

-- =============================================================================
-- getImplementation Entry Point
-- =============================================================================

||| getImplementation(bytes4) -> address
||| ERC-7546 standard function: resolves selector to implementation
public export
getImplementationSig : Sig
getImplementationSig = MkSig "getImplementation" [TBytes4] [TAddress]

public export
getImplementationSel : Sel getImplementationSig
getImplementationSel = MkSel 0xfff1a302

||| Entry: getImplementation(bytes4) -> address
||| Dispatches to the registered implementation for the given selector
export
getImplementationEntry : Entry getImplementationSig
getImplementationEntry = MkEntry getImplementationSel $ do
  selector <- runDecoder decodeBytes4
  implAddr <- getImplementation (bytes4Value selector)
  returnAddress implAddr
