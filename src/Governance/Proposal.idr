||| TextDAO Proposal State Machine and Storage Layout
||| Defines the proposal lifecycle: Pending -> Active -> {Approved, Cancelled, Expired}
|||
||| This module re-exports the storage schema and access control primitives
||| used by all governance functions (Cancel, Tally, Vote, Execute).
module Governance.Proposal

import public TextDAO.Storages.Schema
import public TextDAO.Security.AccessControl

%default covering

-- =============================================================================
-- Proposal State Machine
-- =============================================================================

||| Proposal states in the governance lifecycle
||| Pending  — Created, awaiting representative assignment
||| Active   — Voting period open, reps can vote
||| Approved — Tally completed with a winner
||| Cancelled — Author retracted the proposal (REQ_CANCEL_003)
||| Executed — Approved command has been executed
||| Expired  — Voting period ended without approval (may be extended on tie)
public export
data ProposalState = Pending | Active | Approved | Cancelled | Executed | Expired

||| Derive the current state of a proposal from storage flags
||| This is a view function — state is not stored explicitly but derived
||| from the combination of flags (cancelled, executed, approved, expiration).
export
getProposalState : ProposalId -> IO ProposalState
getProposalState pid = do
  cancelled <- isProposalCancelled pid
  if cancelled then pure Cancelled
  else do
    executed <- isFullyExecuted pid
    if executed then pure Executed
    else do
      approvedHeader <- getApprovedHeaderId pid
      if approvedHeader > 0 then pure Approved
      else do
        expired <- isProposalExpired pid
        if expired then pure Expired
        else do
          createdAt <- getProposalCreatedAt pid
          if createdAt == 0 then pure Pending
          else pure Active

||| Check if a proposal is in a cancellable state (Active or Pending)
||| REQ_CANCEL_003: Only active/pending proposals can be cancelled
export
isCancellable : ProposalId -> IO Bool
isCancellable pid = do
  state <- getProposalState pid
  pure $ case state of
    Pending => True
    Active  => True
    _       => False

-- =============================================================================
-- Proposal Expiration Check (shared by Tally and Cancel)
-- =============================================================================

||| Check if proposal voting period has expired
||| Used by tally to determine if final counting should occur
export
isProposalExpired : ProposalId -> IO Bool
isProposalExpired pid = do
  expiration <- getProposalExpiration pid
  now <- timestamp
  pure (now >= expiration && expiration > 0)
