||| TD Governance Tally — Yul Codegen
||| REQ_TALLY_001: RCV vote counting and proposal approval
||| REQ_CANCEL_002: Cancelled proposals excluded from tally aggregation
module TD.Governance.Yul.Tally

import public Subcontract.Core.Entry
import Subcontract.Core.ABI.Decoder
import public Subcontract.Core.Outcome
import TD.Governance.Proposal

import Data.List

%default covering

-- =============================================================================
-- Function Signatures
-- =============================================================================

||| tally(uint256) -> void
public export
tallySig : Sig
tallySig = MkSig "tally" [TUint256] []

public export
tallySel : Sel tallySig
tallySel = MkSel 0x67890123

||| tallyAndExecute(uint256) -> bool
public export
tallyAndExecuteSig : Sig
tallyAndExecuteSig = MkSig "tallyAndExecute" [TUint256] [TBool]

public export
tallyAndExecuteSel : Sel tallyAndExecuteSig
tallyAndExecuteSel = MkSel 0x90123456

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

||| Score accumulator
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
      if k == i then (k, v + p) :: rest
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
-- Vote Reading (simplified — reads from storage)
-- =============================================================================

||| Read a representative's vote for a proposal
export
readVote : ProposalId -> EvmAddr -> IO ((Integer, Integer, Integer), (Integer, Integer, Integer))
readVote pid voter = do
  metaSlot <- getProposalMetaSlot pid
  let votesBaseSlot = metaSlot + 0x10
  mstore 0 voter
  mstore 32 votesBaseSlot
  voteSlot <- keccak256 0 64
  h0 <- sload voteSlot
  h1 <- sload (voteSlot + 1)
  h2 <- sload (voteSlot + 2)
  c0 <- sload (voteSlot + 3)
  c1 <- sload (voteSlot + 4)
  c2 <- sload (voteSlot + 5)
  pure ((h0, h1, h2), (c0, c1, c2))

-- =============================================================================
-- Vote Aggregation
-- =============================================================================

||| Accumulate votes from a single representative
export
accumulateVote : ProposalId -> EvmAddr -> (ScoreMap, ScoreMap) -> IO (ScoreMap, ScoreMap)
accumulateVote pid voter (headerScores, cmdScores) = do
  ((h0, h1, h2), (c0, c1, c2)) <- readVote pid voter

  let hs1 = if h0 > 0 then addScore h0 (rcvPoints 0) headerScores else headerScores
  let hs2 = if h1 > 0 then addScore h1 (rcvPoints 1) hs1 else hs1
  let hs3 = if h2 > 0 then addScore h2 (rcvPoints 2) hs2 else hs2

  let cs1 = if c0 > 0 then addScore c0 (rcvPoints 0) cmdScores else cmdScores
  let cs2 = if c1 > 0 then addScore c1 (rcvPoints 1) cs1 else cs1
  let cs3 = if c2 > 0 then addScore c2 (rcvPoints 2) cs2 else cs2

  pure (hs3, cs3)

||| Calculate RCV scores for all representatives
export
calcRCVScores : ProposalId -> IO (ScoreMap, ScoreMap)
calcRCVScores pid = do
  repCount <- getRepCount pid
  accumulateAll pid 0 repCount (emptyScoreMap, emptyScoreMap)
  where
    accumulateAll : ProposalId -> Integer -> Integer -> (ScoreMap, ScoreMap) -> IO (ScoreMap, ScoreMap)
    accumulateAll pid idx cnt acc =
      if idx >= cnt then pure acc
      else do
        repAddr <- getRepAddr pid idx
        acc' <- accumulateVote pid repAddr acc
        accumulateAll pid (idx + 1) cnt acc'

-- =============================================================================
-- Proposal State Checks
-- =============================================================================

export
isApproved : ProposalId -> IO Bool
isApproved pid = do
  approvedHeader <- getApprovedHeaderId pid
  pure (approvedHeader > 0)

export
isProposalExpired : ProposalId -> IO Bool
isProposalExpired pid = do
  expiration <- getProposalExpiration pid
  now <- timestamp
  pure (now >= expiration)

-- =============================================================================
-- Final Tally
-- =============================================================================

||| Perform final tally when proposal expires
||| REQ_CANCEL_002: Cancelled proposals are excluded from tally — revert if cancelled
export
finalTally : ProposalId -> IO (Outcome Bool)
finalTally pid = do
  -- REQ_CANCEL_002: Skip Cancelled proposals
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

||| Execute the approved command
executeApproved : ProposalId -> IO Bool
executeApproved pid = do
  executed <- isFullyExecuted pid
  if executed then pure False
  else do
    setFullyExecuted pid True
    pure True

||| Tally and immediately execute if approved
||| REQ_CANCEL_002: Cancelled proposals are excluded
export
tallyAndExecute : ProposalId -> IO (Outcome Bool)
tallyAndExecute pid = do
  -- REQ_CANCEL_002: Skip Cancelled proposals
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
-- Tally Core
-- =============================================================================

||| Tally function (core logic)
||| REQ_CANCEL_002: Cancelled proposals are excluded from tally aggregation
export
tally : ProposalId -> IO (Outcome ())
tally pid = do
  -- REQ_CANCEL_002: Skip Cancelled proposals
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
    else pure (Ok ())  -- Not expired yet, no-op

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
tallyAndExecuteEntry : Entry tallyAndExecuteSig
tallyAndExecuteEntry = MkEntry tallyAndExecuteSel $ do
  pid <- runDecoder decodeUint256
  result <- tallyAndExecute (uint256Value pid)
  case result of
    Ok success => returnBool success
    Fail _ _ => evmRevert 0 0
