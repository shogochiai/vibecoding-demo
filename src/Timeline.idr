||| REQ_TIMELINE_001: Proposal lifecycle timeline query function
||| Returns proposal lifecycle events (propose, vote, tally, execute) with timestamps
||| REQ_TIMELINE_003: Yul codegen via idris2-evm, no Solidity
module Timeline

import TimelineStorage
import EVM.Primitives

%default total

----------------------------------------------------------------------
-- REQ_TIMELINE_001: ProposalEvent and timeline types
----------------------------------------------------------------------

||| A single lifecycle event: (eventType, timestamp)
public export
ProposalEvent : Type
ProposalEvent = (EventType, Integer)

||| Full timeline: fixed 4-element tuple of timestamps
public export
ProposalTimeline : Type
ProposalTimeline = (Integer, Integer, Integer, Integer)

----------------------------------------------------------------------
-- REQ_TIMELINE_003: getProposalTimeline view function
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
  pure (tPropose, tVote, tTally, tExecute)

||| ABI-encode a ProposalTimeline as 8 words and return
encodeTimeline : ProposalTimeline -> IO ()
encodeTimeline (tPropose, tVote, tTally, tExecute) = do
  -- Event 0: Propose
  mstore 0 (eventIndex Propose)
  mstore 32 tPropose
  -- Event 1: Vote
  mstore 64 (eventIndex Vote)
  mstore 96 tVote
  -- Event 2: Tally
  mstore 128 (eventIndex Tally)
  mstore 160 tTally
  -- Event 3: Execute
  mstore 192 (eventIndex Execute)
  mstore 224 tExecute
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
  sel <- calldataload 0
  selector <- shr 224 sel
  if selector == 0xb3a0a8d0
    then getProposalTimeline
    else evmRevert 0 0
