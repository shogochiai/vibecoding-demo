module Governance.Tally

import Governance.Proposal

||| Filter out cancelled proposals before tally aggregation.
||| Cancelled proposals must not influence vote counts or Borda ranking.
public export
filterCancelled : List Proposal -> List Proposal
filterCancelled = filter (\p => p.status /= Cancelled)

||| Run tally on a list of proposals, excluding cancelled ones.
||| Returns only proposals that should participate in Borda ranking.
public export
tallyEligible : List Proposal -> List Proposal
tallyEligible proposals =
  let active = filterCancelled proposals
  in filter (\p => p.status == Active) active

||| Check if a proposal should be skipped during tally.
public export
skipInTally : Proposal -> Bool
skipInTally p = case p.status of
  Cancelled => True
  Finalized => True
  Pending   => True
  Active    => False
