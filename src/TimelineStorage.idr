||| REQ_TIMELINE_002: Storage slot layout for proposal lifecycle event timestamps
||| Storage layout follows ERC-7546 convention: pure logic, no storage in implementation.
||| Slots are computed deterministically from proposal ID and event type.
module TimelineStorage

import EVM.Primitives

%default total

----------------------------------------------------------------------
-- REQ_TIMELINE_002: Event types for storage slot computation
----------------------------------------------------------------------

||| Event types in a proposal lifecycle (re-exported for storage layer)
public export
data EventType = Propose | Vote | Tally | Execute

||| Numeric index for each event type used in slot computation
public export
eventIndex : EventType -> Integer
eventIndex Propose = 0
eventIndex Vote    = 1
eventIndex Tally   = 2
eventIndex Execute = 3

----------------------------------------------------------------------
-- Storage slot layout
----------------------------------------------------------------------

||| Base storage namespace for timeline data.
||| Derived from keccak256("td.timeline.v1") to avoid collisions
||| with other ERC-7546 facets.
public export
timelineBaseSlot : Integer
timelineBaseSlot = 0x8a35acfbc15ff81a39ae7d344fd709f28e8600b4aa8c65c6b64bfe7fe36bd19b

||| Compute the storage slot for a specific event timestamp.
|||
||| Layout: slot = timelineBaseSlot + (proposalId * 4) + eventIndex
||| This linear layout is gas-efficient for sequential reads of all 4 events.
|||
||| @proposalId The proposal identifier
||| @evt The lifecycle event type
public export
eventSlot : Integer -> EventType -> Integer
eventSlot proposalId evt =
  timelineBaseSlot + (proposalId * 4) + eventIndex evt

||| Number of storage slots per proposal (one per event type)
public export
slotsPerProposal : Integer
slotsPerProposal = 4
