||| REQ_TIMELINE_001: Proposal lifecycle timeline query function
||| Returns proposal lifecycle events (propose, vote, tally, execute) with timestamps
||| REQ_TIMELINE_003: Yul codegen via idris2-evm, no Solidity
module Timeline

import TimelineStorage
import EVM.Primitives

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
  timestamp : Integer

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
loadEventTimestamp : Integer -> EventType -> IO Integer
loadEventTimestamp proposalId evt = do
  let slot = eventSlot proposalId evt
  sload slot

||| Build full timeline for a proposal by reading storage slots
buildTimeline : Integer -> IO ProposalTimeline
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
encodeTimeline : ProposalTimeline -> IO ()
encodeTimeline tl = do
  -- Event 0: Propose
  mstore 0 (eventIndex $ tl.proposeEvent.eventType)
  mstore 32 tl.proposeEvent.timestamp
  -- Event 1: Vote
  mstore 64 (eventIndex $ tl.voteEvent.eventType)
  mstore 96 tl.voteEvent.timestamp
  -- Event 2: Tally
  mstore 128 (eventIndex $ tl.tallyEvent.eventType)
  mstore 160 tl.tallyEvent.timestamp
  -- Event 3: Execute
  mstore 192 (eventIndex $ tl.executeEvent.eventType)
  mstore 224 tl.executeEvent.timestamp
  -- Return 256 bytes from memory offset 0
  evmReturn 0 256

||| getProposalTimeline(uint256 proposalId) view returns ((uint8,uint256)[4])
||| Selector: 0xb3a0a8d0 = keccak256("getProposalTimeline(uint256)")
export
getProposalTimeline : IO ()
getProposalTimeline = do
  proposalId <- calldataload 4
  tl <- buildTimeline proposalId
  encodeTimeline tl

----------------------------------------------------------------------
-- Entry point for Yul codegen
----------------------------------------------------------------------

||| Function selector dispatch
||| 0xb3a0a8d0 = getProposalTimeline(uint256)
export
dispatch : IO ()
dispatch = do
  selector <- getSelector
  if selector == 0xb3a0a8d0
    then getProposalTimeline
    else evmRevert 0 0

||| Main entry — EVM contract entry point for Yul codegen
export
main : IO ()
main = dispatch
