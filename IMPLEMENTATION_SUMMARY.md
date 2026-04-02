# IP-38 Implementation Summary: Governance Event Timeline

## Overview
Implemented REQ_TIMELINE_001 through REQ_TIMELINE_005 for the governance event timeline query functionality in td.onthe.eth.

## Implementation Details

### REQ_TIMELINE_001-004: Event Structs and ABI Encoding
**Files:** `src/TimelineStorage.idr`, `src/Timeline.idr`

- `EventType` data type with variants: `Propose`, `Vote`, `Tally`, `Execute`
- `ProposalEvent` type: `(EventType, Integer)` - event with timestamp
- `ProposalTimeline` type: `(Integer, Integer, Integer, Integer)` - 4-tuple of timestamps
- `eventIndex` function maps event types to numeric indices (0-3)
- ABI encoding in `encodeTimeline` function stores events as (uint8, uint256) tuples

### REQ_TIMELINE_002: Storage Layout
**File:** `src/TimelineStorage.idr`

- `timelineBaseSlot`: Base namespace slot computed from keccak256("td.timeline.v1")
- `eventSlot`: Computes slot = timelineBaseSlot + (proposalId * 4) + eventIndex
- Linear layout: 4 slots per proposal (Propose=0, Vote=1, Tally=2, Execute=3)
- `slotsPerProposal`: Fixed at 4 slots per proposal

### REQ_TIMELINE_003: Event Recording Hooks
**Files:** `src/TimelineStorage.idr`, `src/TD/Governance/Yul/Tally.idr`

- `recordEvent : Integer -> EventType -> IO ()` - Stores block.timestamp at computed slot
- `hasEventRecorded : Integer -> EventType -> IO Bool` - Checks if event exists
- Hooks added to:
  - `finalTally` (line 189): Records `Tally` event when proposal is approved
  - `executeApproved` (line 211): Records `Execute` event when proposal is executed
- Note: Propose and Vote hooks to be added when those entry points are implemented

### REQ_TIMELINE_004: Query Function
**File:** `src/Timeline.idr`

- `getProposalTimeline : IO ()` - Main view function
- Selector: `0xb3a0a8d0` = keccak256("getProposalTimeline(uint256)")
- `buildTimeline : Integer -> IO ProposalTimeline` - Reads all 4 timestamps from storage
- `loadEventTimestamp : Integer -> EventType -> IO Integer` - Loads single event
- Pure read function (no state modifications)
- Returns ABI-encoded array of 4 (uint8, uint256) tuples

### REQ_TIMELINE_005: ERC-7546 Proxy Registration
**Files:** `src/TD/Proxy/Router.idr`, `src/Proxy/Registry.idr`, `src/Governance/Yul/Dispatch.idr`

- `SEL_GET_GOVERNANCE_TIMELINE = 0xb3a0a8d0` - Selector constant
- Added to `governanceSelectors` list in both Router and Registry
- `registerTimelineFacet : ImplAddr -> IO ()` - Registration helper
- `setImplementation SEL_GET_GOVERNANCE_TIMELINE facetAddr` - Maps selector to facet
- Dispatch table includes `getGovernanceTimeline` case

## Build Verification

```bash
$ idris2 --build td-timeline.ipkg
# 16 modules built successfully
```

## Acceptance Criteria Status

| Task | Criteria | Status |
|------|----------|--------|
| ip38-01 | GovernanceEvent type compiles | PASS |
| ip38-02 | Storage slots defined | PASS |
| ip38-03 | recordEvent hooks in tally/execute | PASS |
| ip38-04 | getGovernanceTimeline view function | PASS |
| ip38-05 | Selector registered in proxy | PASS |
| ip38-06 | Deployment via t-ECDSA | PENDING |

## Notes

- The existing Timeline.idr and TimelineStorage.idr modules already implemented most of the requirements
- Added missing hooks for Tally and Execute events
- Added proxy registration for getGovernanceTimeline selector
- Propose and Vote hooks are stubbed for when those entry points are fully implemented
- Deployment step (ip38-06) requires access to TheWorld t-ECDSA signing infrastructure
