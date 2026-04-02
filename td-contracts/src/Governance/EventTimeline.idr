||| Governance Event Timeline — Read-only view function
||| REQ_GEVT_001: GovernanceEvent types with on-chain timestamps
||| REQ_GEVT_002: getProposalTimeline(uint256) → (uint8,uint256)[]
||| REQ_GEVT_003: Yul codegen, ERC-7546 compatible (no sstore)
|||
||| Storage Layout (managed by governance write contracts):
|||   slot(keccak256(abi.encode(proposalId, EVENTS_BASE_SLOT))) = eventCount
|||   slot(keccak256(abi.encode(proposalId, EVENTS_BASE_SLOT)) + 1 + i*2) = eventType
|||   slot(keccak256(abi.encode(proposalId, EVENTS_BASE_SLOT)) + 1 + i*2 + 1) = timestamp
module Governance.EventTimeline

import Data.Vect
import Data.Bits

-- ============================================================
-- REQ_GEVT_001 — Event types and storage layout
-- ============================================================

||| Governance event types matching on-chain uint8 encoding
public export
data EventType
  = Propose   -- 0
  | Vote      -- 1
  | Tally     -- 2
  | Execute   -- 3

||| Encode EventType to uint8 for ABI
public export
eventTypeToUint8 : EventType -> Bits8
eventTypeToUint8 Propose  = 0
eventTypeToUint8 Vote     = 1
eventTypeToUint8 Tally    = 2
eventTypeToUint8 Execute  = 3

||| GovernanceEvent record: (eventType, timestamp) tuple stored on-chain
public export
record GovernanceEvent where
  constructor MkGovernanceEvent
  eventType : EventType
  timestamp : Integer  -- uint256 block.timestamp

||| Storage base slot for governance events mapping
||| keccak256("governance.events.timeline") truncated
public export
EventSlot : Integer
EventSlot = 0x47f8b08c2e5aa3cd7df8e5988e2cb00bfe3a1e5d7ce6d3eaa2b0f6c8d4a917e3

-- ============================================================
-- Yul Primitives (idris2-evm FFI stubs)
-- ============================================================

||| Read a 256-bit word from storage
sload : Integer -> Integer
sload slot = prim__sload slot
  where
    %foreign "yul:sload"
    prim__sload : Integer -> Integer

||| Compute keccak256 of two concatenated 256-bit words
keccak256_2 : Integer -> Integer -> Integer
keccak256_2 a b = prim__keccak256_2 a b
  where
    %foreign "yul:keccak256_concat"
    prim__keccak256_2 : Integer -> Integer -> Integer

||| ABI calldataload at byte offset
calldataload : Integer -> Integer
calldataload offset = prim__calldataload offset
  where
    %foreign "yul:calldataload"
    prim__calldataload : Integer -> Integer

||| Return memory region to caller
returnData : Integer -> Integer -> ()
returnData offset len = prim__return offset len
  where
    %foreign "yul:return"
    prim__return : Integer -> Integer -> ()

||| Store 256-bit word to memory
mstore : Integer -> Integer -> ()
mstore offset val = prim__mstore offset val
  where
    %foreign "yul:mstore"
    prim__mstore : Integer -> Integer -> ()

-- ============================================================
-- REQ_GEVT_002 — getProposalTimeline view function
-- ============================================================

||| Compute the storage base for a proposal's event array
||| Returns slot where eventCount is stored; events start at slot+1
proposalEventBase : Integer -> Integer
proposalEventBase proposalId = keccak256_2 proposalId EventSlot

||| Read event count for a proposal from storage
readEventCount : Integer -> Integer
readEventCount proposalId = sload (proposalEventBase proposalId)

||| Read a single GovernanceEvent from storage
||| Events stored as: base + 1 + i*2 = eventType, base + 1 + i*2 + 1 = timestamp
readEvent : Integer -> Integer -> GovernanceEvent
readEvent proposalId idx =
  let base = proposalEventBase proposalId
      typeSlot = base + 1 + idx * 2
      tsSlot   = base + 1 + idx * 2 + 1
      evtType  = sload typeSlot
      ts       = sload tsSlot
  in MkGovernanceEvent (uint8ToEventType evtType) ts
  where
    uint8ToEventType : Integer -> EventType
    uint8ToEventType 0 = Propose
    uint8ToEventType 1 = Vote
    uint8ToEventType 2 = Tally
    uint8ToEventType _ = Execute

||| Encode a dynamic array of (uint8, uint256) tuples into ABI format
||| Layout: offset(0x20) | length | (type_i, timestamp_i)*
||| REQ_GEVT_002: ABI encoding handles dynamic array of tuples
encodeDynArray : Integer -> List GovernanceEvent -> ()
encodeDynArray memPtr events =
  let len = cast {to=Integer} (length events)
      -- ABI: first word = offset to array data (0x20 for single return)
      _ = mstore memPtr 0x20
      -- ABI: array length
      _ = mstore (memPtr + 0x20) len
      -- ABI: array elements — each tuple is 2 words (type, timestamp)
      _ = encodeElements (memPtr + 0x40) events
      -- Total size: 0x20 (offset) + 0x20 (length) + len * 0x40 (elements)
      totalSize = 0x40 + len * 0x40
  in returnData memPtr totalSize
  where
    encodeElements : Integer -> List GovernanceEvent -> ()
    encodeElements _ [] = ()
    encodeElements ptr (ev :: rest) =
      let _ = mstore ptr (cast (eventTypeToUint8 (eventType ev)))
          _ = mstore (ptr + 0x20) (timestamp ev)
      in encodeElements (ptr + 0x40) rest

||| Read all events for a proposal from storage into a list
readAllEvents : Integer -> Integer -> Integer -> List GovernanceEvent
readAllEvents proposalId count idx =
  if idx >= count
    then []
    else readEvent proposalId idx :: readAllEvents proposalId count (idx + 1)

||| getProposalTimeline(uint256 proposalId) → (uint8 eventType, uint256 timestamp)[]
||| Function selector: 0xdc9cc645 = bytes4(keccak256("getProposalTimeline(uint256)"))
||| REQ_GEVT_002: View function returns event timeline for a given proposal
export
getProposalTimeline : Integer -> ()
getProposalTimeline proposalId =
  let count  = readEventCount proposalId
      events = readAllEvents proposalId count 0
  in encodeDynArray 0x80 events

-- ============================================================
-- REQ_GEVT_003 — ERC-7546 selector dispatch
-- ============================================================

||| Function selector for getProposalTimeline(uint256)
||| keccak256("getProposalTimeline(uint256)") = 0xdc9cc645...
||| ERC-7546: registered under proxy via getImplementation(0xdc9cc645)
export
selector_getProposalTimeline : Integer
selector_getProposalTimeline = 0xdc9cc645

||| Main dispatcher — matches selector and routes to implementation
||| ERC-7546: This contract is a pure logic implementation (no sstore)
export
dispatch : ()
dispatch =
  let sel = calldataload 0 `div` (prim__shl_Integer 224 1)
      proposalId = calldataload 4
  in if sel == selector_getProposalTimeline
       then getProposalTimeline proposalId
       else revert 0 0
  where
    prim__shl_Integer : Integer -> Integer -> Integer
    prim__shl_Integer n s = n * (pow 2 (cast s))
    revert : Integer -> Integer -> ()
    revert offset len = prim__revert offset len
      where
        %foreign "yul:revert"
        prim__revert : Integer -> Integer -> ()
