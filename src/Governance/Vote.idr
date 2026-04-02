||| Governance Vote and Tally Integration
||| REQ_CANCEL_002 REQ_CANCEL_004 — Cancelled proposals excluded from tally
|||
||| This module bridges the voting/tally system with proposal state awareness,
||| ensuring cancelled proposals are properly excluded from vote counting.
module Governance.Vote

import public Subcontract.Core.Entry
import public Subcontract.Core.Outcome
import TextDAO.Storages.Schema
import TextDAO.Functions.Vote.Vote
import TextDAO.Functions.Tally.Tally
import Governance.Proposal

%default covering

-- =============================================================================
-- Tally Exclusion for Cancelled Proposals
-- =============================================================================

||| REQ_CANCEL_004: Map ProposalState to tally weight
||| Cancelled proposals contribute zero (neutral) to tally
||| Active/Expired proposals contribute normally
export
tallyWeight : ProposalState -> Integer
tallyWeight Active    = 1
tallyWeight Expired   = 1
tallyWeight Approved  = 0  -- already resolved
tallyWeight Executed  = 0  -- already resolved
tallyWeight Cancelled = 0  -- IP-25: excluded from tally

||| REQ_CANCEL_004: Check if a proposal should be included in tally
||| Cancelled => neutral (excluded), all others handled by existing logic
export
shouldTally : ProposalState -> Bool
shouldTally Cancelled = False  -- Cancelled => neutral
shouldTally Executed  = False
shouldTally _         = True

||| REQ_CANCEL_004: Guard tally execution against cancelled proposals
||| Returns neutral outcome for cancelled proposals
export
guardTally : ProposalId -> IO (Outcome ())
guardTally pid = do
  cancelled <- isProposalCancelled pid
  if cancelled
    then pure (Fail InvalidTransition (tagEvidence "Cancelled => neutral"))
    else pure (Ok ())

-- =============================================================================
-- Vote Validation with Cancel Awareness
-- =============================================================================

||| Check if proposal accepts votes (not cancelled, not expired)
||| REQ_CANCEL_004: Cancelled proposals cannot receive new votes
export
canReceiveVotes : ProposalId -> IO Bool
canReceiveVotes pid = do
  cancelled <- isProposalCancelled pid
  if cancelled then pure False
  else do
    expired <- isProposalExpired pid
    pure (not expired)

-- =============================================================================
-- Tally with Cancel Filter
-- =============================================================================

||| Perform tally with cancellation check
||| REQ_CANCEL_004: Cancelled proposals are skipped (neutral contribution)
export
tallyWithCancelCheck : ProposalId -> IO (Outcome ())
tallyWithCancelCheck pid = do
  -- Guard: Cancelled => neutral (no tally)
  guard <- guardTally pid
  case guard of
    Fail c e => pure (Fail c e)
    Ok () => tally pid
