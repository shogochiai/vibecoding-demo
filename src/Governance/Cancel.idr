module Governance.Cancel

import Governance.Proposal
import Governance.Events

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

||| onlyAuthor guard: assert that the caller is the proposal author.
||| REQ_CANCEL_002: Reverts if msg.sender != proposal.author.
public export
onlyAuthor : (caller : String) -> (proposal : Proposal) -> Either CancelResult ()
onlyAuthor caller proposal =
  if caller == proposal.author
     then Right ()
     else Left ErrNotAuthor

||| Alias for backwards compatibility.
public export
assertAuthor : (caller : String) -> (proposal : Proposal) -> Either CancelResult ()
assertAuthor = onlyAuthor

||| Free the voting slot occupied by a cancelled proposal.
||| REQ_CANCEL_004: slotCount is effectively decremented by marking the slot inactive.
||| In the pure layer this is a no-op marker; the Yul layer sets expiration to 0.
public export
freeSlot : Proposal -> Proposal
freeSlot p = p  -- slot freeing is a storage-level operation handled in Yul codegen

||| Cancel a proposal. Checks:
||| 1. onlyAuthor: caller == proposal.author (REQ_CANCEL_002)
||| 2. proposal.status is Active or Pending (REQ_CANCEL_003)
||| On success:
||| - Sets status to Cancelled (REQ_CANCEL_001)
||| - Frees voting slot via freeSlot (REQ_CANCEL_004)
||| - ProposalCancelled event emitted in Yul layer (REQ_CANCEL_005)
public export
cancelProposal : (caller : String) -> Proposal -> CancelResult
cancelProposal caller proposal =
  case onlyAuthor caller proposal of
    Left err => err
    Right () =>
      if isCancellable proposal.status
         then CancelSuccess (freeSlot ({ status := Cancelled } proposal))
         else ErrNotCancellable proposal.status
