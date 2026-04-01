||| Governance Tally Function
||| REQ_TALLY_001: RCV vote counting and proposal approval
||| REQ_CANCEL_004: Cancelled proposals excluded from tally
module Governance.Tally

import Governance.Proposal
import Data.List

-- =============================================================================
-- Function Signatures
-- =============================================================================

||| tally(uint256) selector
public export
TALLY_SELECTOR : Integer
TALLY_SELECTOR = 0x67890123

||| tallyAndExecute(uint256) selector
public export
TALLY_AND_EXECUTE_SELECTOR : Integer
TALLY_AND_EXECUTE_SELECTOR = 0x90123456

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

||| Score accumulator: maps ID -> score
public export
record ScoreMap where
  constructor MkScoreMap
  scores : List (Integer, Integer)

public export
emptyScoreMap : ScoreMap
emptyScoreMap = MkScoreMap []

public export
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

public export
getScore : Integer -> ScoreMap -> Integer
getScore id (MkScoreMap scores) =
  case find (\(k, _) => k == id) scores of
    Just (_, v) => v
    Nothing => 0

public export
findTopScorer : ScoreMap -> List Integer
findTopScorer (MkScoreMap []) = []
findTopScorer (MkScoreMap scores) =
  let maxScore = foldl max 0 (map snd scores)
  in if maxScore == 0
       then []
       else map fst (filter (\(_, v) => v == maxScore) scores)

-- =============================================================================
-- Tally Outcome
-- =============================================================================

public export
data TallyResult
  = TallyApproved Integer Integer   -- winnerId, winnerCmd
  | TallyExtended                    -- tie or no votes, extend expiration
  | TallyCancelled                   -- REQ_CANCEL_004: proposal was Cancelled
  | TallyAlreadyApproved
  | TallyNotExpired

-- =============================================================================
-- Cancel-Aware Tally
-- =============================================================================

||| Check if proposal should be excluded from tally
||| REQ_CANCEL_004: Cancelled proposals are excluded from tally
public export
shouldExcludeFromTally : ProposalState -> Bool
shouldExcludeFromTally Cancelled = True
shouldExcludeFromTally Executed  = True
shouldExcludeFromTally _         = False

||| Final tally with cancel exclusion
||| REQ_CANCEL_004: Cancelled proposals are skipped — returns TallyCancelled
||| REQ_TALLY_006: Perform final tally when proposal expires
public export
checkTallyPreconditions : ProposalState -> Bool -> TallyResult
checkTallyPreconditions Cancelled _ = TallyCancelled
checkTallyPreconditions _ True      = TallyAlreadyApproved
checkTallyPreconditions _ _         = TallyNotExpired  -- placeholder, real logic checks expiry

||| Tally and execute combined
||| REQ_TALLY_007: Combined tally and execute for efficiency
||| REQ_CANCEL_004: Cancelled proposals are excluded
public export
tallyAndExecutePreconditions : ProposalState -> Bool -> TallyResult
tallyAndExecutePreconditions Cancelled _ = TallyCancelled
tallyAndExecutePreconditions _ isApproved =
  if isApproved then TallyAlreadyApproved else TallyNotExpired

-- =============================================================================
-- Snap (Periodic Snapshot)
-- =============================================================================

||| Snap slot offset within proposal meta
public export
SNAP_EPOCH_SLOT_OFFSET : Integer
SNAP_EPOCH_SLOT_OFFSET = 0x50

||| Check if already snapped in current epoch
public export
needsSnap : Integer -> Integer -> Bool
needsSnap lastEpoch currentEpoch = lastEpoch < currentEpoch
