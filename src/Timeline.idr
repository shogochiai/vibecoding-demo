||| REQ_TIMELINE_001: Proposal lifecycle timeline query function
||| Returns proposal lifecycle events (propose, vote, tally, execute) with timestamps
||| REQ_TIMELINE_003: Yul codegen via idris2-evm, no Solidity
module Timeline

import TimelineStorage
import EVM
import EVM.Primitives
import EVM.Storage
import EVM.ABI

%default total

----------------------------------------------------------------------
-- REQ_TIMELINE_001: ProposalEvent struct and timeline return type
----------------------------------------------------------------------

||| A single lifecycle event: (eventType, timestamp)
||| Encoded as two uint256 values in ABI return
public export
record ProposalEvent where
  constructor MkProposalEvent
  eventType : EventType
  timestamp : Bits256

||| Full timeline: fixed 4-element array of ProposalEvent
||| A zero timestamp means the event has not occurred yet
public export
record ProposalTimeline where
  constructor MkProposalTimeline
  proposeEvent  : ProposalEvent
  voteEvent     : ProposalEvent
  tallyEvent    : ProposalEvent
  executeEvent  : ProposalEvent

----------------------------------------------------------------------
-- REQ_TIMELINE_003: getProposalTimeline view function (Yul codegen)
----------------------------------------------------------------------

||| Load a single event timestamp from storage
loadEventTimestamp : Bits256 -> EventType -> EVM Bits256
loadEventTimestamp proposalId evt = do
  let slot = eventSlot proposalId evt
  sload slot

||| Build full timeline for a proposal by reading storage slots
buildTimeline : Bits256 -> EVM ProposalTimeline
buildTimeline proposalId = do
  tPropose <- loadEventTimestamp proposalId Propose
  tVote    <- loadEventTimestamp proposalId Vote
  tTally   <- loadEventTimestamp proposalId Tally
  tExecute <- loadEventTimestamp proposalId Execute
  pure $ MkProposalTimeline
    (MkProposalEvent Propose tPropose)
    (MkProposalEvent Vote    tVote)
    (MkProposalEvent Tally   tTally)
    (MkProposalEvent Execute tExecute)

||| ABI-encode a ProposalTimeline as 8 words:
||| (eventType0, timestamp0, eventType1, timestamp1, ..., eventType3, timestamp3)
encodeTimeline : ProposalTimeline -> EVM ()
encodeTimeline tl = do
  let base = the Bits256 0
  -- Event 0: Propose
  mstore base (eventIndex $ tl.proposeEvent.eventType)
  mstore (base + 32) tl.proposeEvent.timestamp
  -- Event 1: Vote
  mstore (base + 64) (eventIndex $ tl.voteEvent.eventType)
  mstore (base + 96) tl.voteEvent.timestamp
  -- Event 2: Tally
  mstore (base + 128) (eventIndex $ tl.tallyEvent.eventType)
  mstore (base + 160) tl.tallyEvent.timestamp
  -- Event 3: Execute
  mstore (base + 192) (eventIndex $ tl.executeEvent.eventType)
  mstore (base + 224) tl.executeEvent.timestamp
  -- Return 256 bytes from memory offset 0
  evm_return base 256

||| getProposalTimeline(uint256 proposalId) view returns ((uint8,uint256)[4])
||| Selector: 0xb3a0a8d0 = keccak256("getProposalTimeline(uint256)")
export
getProposalTimeline : EVM ()
getProposalTimeline = do
  let proposalId = calldataload 4
  tl <- buildTimeline proposalId
  encodeTimeline tl

----------------------------------------------------------------------
-- Entry point for Yul codegen
----------------------------------------------------------------------

||| Function selector dispatch
||| 0xb3a0a8d0 = getProposalTimeline(uint256)
export
dispatch : EVM ()
dispatch = do
  let selector = shr 224 (calldataload 0)
  if selector == 0xb3a0a8d0
    then getProposalTimeline
    else revert 0 0

||| Main entry — EVM contract entry point for Yul codegen
%foreign "evm:main"
export
main : EVM ()
main = dispatch
