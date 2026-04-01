||| TextDAO Tally Function
||| REQ_TALLY_001: RCV vote counting and proposal approval
||| REQ_CANCEL_004: Cancelled proposals excluded from tally
module Governance.Tally

import public Subcontract.Core.Entry
import Subcontract.Core.ABI.Decoder
import public Subcontract.Core.Outcome
import TextDAO.Storages.Schema
import TextDAO.Functions.Vote.Vote
import Governance.Selectors

import Data.List

%default covering

-- =============================================================================
-- RCV Score Calculation
-- =============================================================================

||| RCV points: 1st choice = 3, 2nd = 2, 3rd = 1
public export
rcvPoints : Integer -> Integer
rcvPoints 0 = 3
rcvPoints 1 = 2
rcvPoints 2 = 1
rcvPoints _ = 0

||| Score accumulator for headers/commands
public export
record ScoreMap where
  constructor MkScoreMap
  scores : List (Integer, Integer)

export
emptyScoreMap : ScoreMap
emptyScoreMap = MkScoreMap []

export
addScore : Integer -> Integer -> ScoreMap -> ScoreMap
addScore id points (MkScoreMap scores) =
  MkScoreMap (updateOrInsert id points scores)
  where
    updateOrInsert : Integer -> Integer -> List (Integer, Integer) -> List (Integer, Integer)
    updateOrInsert i p [] = [(i, p)]
    updateOrInsert i p ((k, v) :: rest) =
      if k == i
        then (k, v + p) :: rest
        else (k, v) :: updateOrInsert i p rest

export
getScore : Integer -> ScoreMap -> Integer
getScore id (MkScoreMap scores) =
  case find (\(k, _) => k == id) scores of
    Just (_, v) => v
    Nothing => 0

export
findTopScorer : ScoreMap -> List Integer
findTopScorer (MkScoreMap []) = []
findTopScorer (MkScoreMap scores) =
  let maxScore = foldl max 0 (map snd scores)
  in if maxScore == 0
       then []
       else map fst (filter (\(_, v) => v == maxScore) scores)

-- =============================================================================
-- Vote Aggregation
-- =============================================================================

||| Accumulate votes from a single representative
export
accumulateVote : ProposalId -> EvmAddr -> (ScoreMap, ScoreMap) -> IO (ScoreMap, ScoreMap)
accumulateVote pid voter (headerScores, cmdScores) = do
  ((h0, h1, h2), (c0, c1, c2)) <- readVote pid voter

  let headerScores' = if h0 > 0 then addScore h0 (rcvPoints 0) headerScores else headerScores
  let headerScores'' = if h1 > 0 then addScore h1 (rcvPoints 1) headerScores' else headerScores'
  let headerScores''' = if h2 > 0 then addScore h2 (rcvPoints 2) headerScores'' else headerScores''

  let cmdScores' = if c0 > 0 then addScore c0 (rcvPoints 0) cmdScores else cmdScores
  let cmdScores'' = if c1 > 0 then addScore c1 (rcvPoints 1) cmdScores' else cmdScores'
  let cmdScores''' = if c2 > 0 then addScore c2 (rcvPoints 2) cmdScores'' else cmdScores''

  pure (headerScores''', cmdScores''')

||| Calculate RCV scores for all representatives
export
calcRCVScores : ProposalId -> IO (ScoreMap, ScoreMap)
calcRCVScores pid = do
  repCount <- getRepCount pid
  accumulateAll pid 0 repCount (emptyScoreMap, emptyScoreMap)
  where
    accumulateAll : ProposalId -> Integer -> Integer -> (ScoreMap, ScoreMap) -> IO (ScoreMap, ScoreMap)
    accumulateAll pid idx cnt acc =
      if idx >= cnt
        then pure acc
        else do
          repAddr <- getRepAddr pid idx
          acc' <- accumulateVote pid repAddr acc
          accumulateAll pid (idx + 1) cnt acc'

-- =============================================================================
-- Proposal State Checks
-- =============================================================================

||| Check if proposal is already approved
export
isApproved : ProposalId -> IO Bool
isApproved pid = do
  approvedHeader <- getApprovedHeaderId pid
  pure (approvedHeader > 0)

||| Approve header and command
export
approveProposal : ProposalId -> HeaderId -> CommandId -> IO ()
approveProposal pid headerId cmdId = do
  setApprovedHeaderId pid headerId
  setApprovedCmdId pid cmdId

-- =============================================================================
-- Snap (Periodic Snapshot)
-- =============================================================================

SNAP_EPOCH_SLOT_OFFSET : Integer
SNAP_EPOCH_SLOT_OFFSET = 0x50

export
getLastSnappedEpoch : ProposalId -> IO Integer
getLastSnappedEpoch pid = do
  metaSlot <- getProposalMetaSlot pid
  sload (metaSlot + SNAP_EPOCH_SLOT_OFFSET)

export
setLastSnappedEpoch : ProposalId -> Integer -> IO ()
setLastSnappedEpoch pid epoch = do
  metaSlot <- getProposalMetaSlot pid
  sstore (metaSlot + SNAP_EPOCH_SLOT_OFFSET) epoch

export
calcCurrentEpoch : ProposalId -> IO Integer
calcCurrentEpoch pid = do
  snapInterval <- getSnapInterval
  now <- timestamp
  pure (if snapInterval == 0 then 0 else now `div` snapInterval)

export
isSnappedInEpoch : ProposalId -> IO Bool
isSnappedInEpoch pid = do
  lastEpoch <- getLastSnappedEpoch pid
  currentEpoch <- calcCurrentEpoch pid
  pure (lastEpoch >= currentEpoch)

export
snap : ProposalId -> IO (Outcome ())
snap pid = do
  snapped <- isSnappedInEpoch pid
  if snapped
    then pure (Fail EpochMismatch (tagEvidence "AlreadySnapped"))
    else do
      (headerScores, cmdScores) <- calcRCVScores pid
      currentEpoch <- calcCurrentEpoch pid
      setLastSnappedEpoch pid currentEpoch
      pure (Ok ())

-- =============================================================================
-- Final Tally
-- =============================================================================

||| Perform final tally when proposal expires
||| REQ_CANCEL_004: Cancelled proposals are excluded from tally
export
finalTally : ProposalId -> IO (Outcome Bool)
finalTally pid = do
  -- REQ_CANCEL_004: Skip cancelled proposals
  cancelled <- isProposalCancelled pid
  if cancelled
    then pure (Fail InvalidTransition (tagEvidence "ProposalCancelled"))
    else do
  approved <- isApproved pid
  if approved
    then pure (Fail InvalidTransition (tagEvidence "ProposalAlreadyApproved"))
    else do
      (headerScores, cmdScores) <- calcRCVScores pid

      let topHeaders = findTopScorer headerScores
      let topCommands = findTopScorer cmdScores

      case (topHeaders, topCommands) of
        ([winnerId], [winnerCmd]) => do
          approveProposal pid winnerId winnerCmd
          pure (Ok True)

        _ => do
          expiryDuration <- getExpiryDuration
          currentExpiration <- getProposalExpiration pid
          setProposalExpiration pid (currentExpiration + expiryDuration)
          pure (Ok False)

-- =============================================================================
-- Tally and Execute
-- =============================================================================

executeApproved : ProposalId -> IO Bool
executeApproved pid = do
  executed <- isFullyExecuted pid
  if executed
    then pure False
    else do
      setFullyExecuted pid True
      pure True

||| REQ_CANCEL_004: Cancelled proposals are excluded
export
tallyAndExecute : ProposalId -> IO (Outcome Bool)
tallyAndExecute pid = do
  -- REQ_CANCEL_004: Skip cancelled proposals
  cancelled <- isProposalCancelled pid
  if cancelled
    then pure (Fail InvalidTransition (tagEvidence "ProposalCancelled"))
    else do
  expired <- isProposalExpired pid

  if not expired
    then pure (Fail InvalidTransition (tagEvidence "ProposalNotExpired"))
    else do
      result <- finalTally pid
      case result of
        Ok True => do
          executed <- executeApproved pid
          pure (Ok executed)
        Ok False => pure (Ok False)
        Fail c e => pure (Fail c e)

-- =============================================================================
-- Tally Core Logic
-- =============================================================================

||| REQ_CANCEL_004: Cancelled proposals are excluded from tally
export
tally : ProposalId -> IO (Outcome ())
tally pid = do
  -- REQ_CANCEL_004: Skip cancelled proposals
  cancelled <- isProposalCancelled pid
  if cancelled
    then pure (Fail InvalidTransition (tagEvidence "ProposalCancelled"))
    else do
  expired <- isProposalExpired pid

  if expired
    then do
      result <- finalTally pid
      case result of
        Ok _ => pure (Ok ())
        Fail c e => pure (Fail c e)
    else snap pid

-- =============================================================================
-- Entry Points
-- =============================================================================

export
tallyEntry : Entry tallySig
tallyEntry = MkEntry tallySel $ do
  pid <- runDecoder decodeUint256
  result <- tally (uint256Value pid)
  case result of
    Ok () => evmReturn 0 0
    Fail _ _ => evmRevert 0 0

export
isApprovedEntry : Entry isApprovedSig
isApprovedEntry = MkEntry isApprovedSel $ do
  pid <- runDecoder decodeUint256
  approved <- isApproved (uint256Value pid)
  returnBool approved
