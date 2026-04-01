module Governance.Cancel

import Governance.Proposal

||| Result of a cancel attempt.
public export
data CancelResult
  = CancelSuccess Proposal
  | ErrNotAuthor
  | ErrNotCancellable ProposalStatus

public export
Show CancelResult where
  show (CancelSuccess p) = "Cancelled proposal #" ++ show p.proposalId
  show ErrNotAuthor = "revert: caller is not proposal author"
  show (ErrNotCancellable s) = "revert: proposal status " ++ show s ++ " is not cancellable, require Active or Pending"

||| Assert that the caller is the proposal author.
||| Reverts if msg.sender != proposal.author.
public export
assertAuthor : (caller : String) -> (proposal : Proposal) -> Either CancelResult ()
assertAuthor caller proposal =
  if caller == proposal.author
     then Right ()
     else Left ErrNotAuthor

||| Cancel a proposal. Checks:
||| 1. caller == proposal.author (REQ_CANCEL_003)
||| 2. proposal.status is Active or Pending (REQ_CANCEL_002)
||| On success, sets status to Cancelled (REQ_CANCEL_001).
public export
cancelProposal : (caller : String) -> Proposal -> CancelResult
cancelProposal caller proposal =
  case assertAuthor caller proposal of
    Left err => err
    Right () =>
      if isCancellable proposal.status
         then CancelSuccess ({ status := Cancelled } proposal)
         else ErrNotCancellable proposal.status
