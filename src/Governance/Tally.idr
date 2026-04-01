||| Governance Tally — td.onthe.eth
||| REQ_CANCEL_002: Cancelled proposals excluded from tally aggregation
||| REQ_CANCEL_005: Cancelled proposals do not occupy voting slots
module Governance.Tally

import Governance.Types

%default total

-- =============================================================================
-- Tally Filtering
-- =============================================================================

||| Filter out Cancelled proposals before tally aggregation.
||| REQ_CANCEL_002: Cancelled proposals must not influence vote counts or Borda ranking.
public export
filterCancelled : List Proposal -> List Proposal
filterCancelled = filter (\p => p.status /= Cancelled)

||| Return only proposals eligible for Borda tally (Active, not Cancelled).
||| REQ_CANCEL_002: Cancelled and other non-Active proposals excluded.
public export
tallyEligible : List Proposal -> List Proposal
tallyEligible proposals =
  let active = filterCancelled proposals
  in filter (\p => p.status == Active) active

||| Check if a proposal should be skipped during tally.
||| REQ_CANCEL_002: Cancelled proposals return True (skipped).
public export
skipInTally : Proposal -> Bool
skipInTally p = case p.status of
  Cancelled => True
  Finalized => True
  Pending   => True
  Active    => False

-- =============================================================================
-- Slot Counting
-- =============================================================================

||| Count active voting slots (excludes Cancelled proposals).
||| REQ_CANCEL_005: Cancelled proposals do not count toward slot limit.
public export
activeSlotCount : List Proposal -> Nat
activeSlotCount = length . filter (\p => p.status == Active || p.status == Pending)
