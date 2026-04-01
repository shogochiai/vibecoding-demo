module CancelTest

import Governance.Proposal
import Governance.Cancel
import Governance.Tally

||| Test helpers
authorAddr : String
authorAddr = "0xAliceAuthor"

otherAddr : String
otherAddr = "0xBobNotAuthor"

mkTestProposal : ProposalStatus -> Proposal
mkTestProposal status = MkProposal 42 authorAddr status "Test Proposal"

||| REQ_CANCEL_001: Author can cancel own active proposal
testCancelProposal : Bool
testCancelProposal =
  case cancelProposal authorAddr (mkTestProposal Active) of
    CancelSuccess p => p.status == Cancelled
    _ => False

||| REQ_CANCEL_001: Author can cancel own pending proposal
testCancelPendingProposal : Bool
testCancelPendingProposal =
  case cancelProposal authorAddr (mkTestProposal Pending) of
    CancelSuccess p => p.status == Cancelled
    _ => False

||| REQ_CANCEL_003: Non-author cancel reverts
testCancelProposalUnauthorized : Bool
testCancelProposalUnauthorized =
  case cancelProposal otherAddr (mkTestProposal Active) of
    ErrNotAuthor => True
    _ => False

||| REQ_CANCEL_002: Cannot cancel already finalized proposal
testCancelFinalizedReverts : Bool
testCancelFinalizedReverts =
  case cancelProposal authorAddr (mkTestProposal Finalized) of
    ErrNotCancellable Finalized => True
    _ => False

||| REQ_CANCEL_002: Cannot cancel already cancelled proposal
testCancelCancelledReverts : Bool
testCancelCancelledReverts =
  case cancelProposal authorAddr (mkTestProposal Cancelled) of
    ErrNotCancellable Cancelled => True
    _ => False

||| REQ_CANCEL_002: Cancelled proposal excluded from tally
testCancelledExcludedFromTally : Bool
testCancelledExcludedFromTally =
  let proposals = [ mkTestProposal Active
                  , { status := Cancelled } (mkTestProposal Active)
                  , mkTestProposal Pending
                  ]
      eligible = tallyEligible proposals
  in length eligible == 1  -- only the Active one remains

||| Run all tests, return (passed, failed) counts.
public export
runAllTests : (Nat, Nat)
runAllTests =
  let tests = [ ("cancelProposal", testCancelProposal)
              , ("cancelPendingProposal", testCancelPendingProposal)
              , ("cancelProposalUnauthorized", testCancelProposalUnauthorized)
              , ("cancelFinalizedReverts", testCancelFinalizedReverts)
              , ("cancelCancelledReverts", testCancelCancelledReverts)
              , ("cancelledExcludedFromTally", testCancelledExcludedFromTally)
              ]
      results = map snd tests
      passed = length (filter id results)
      failed = length (filter (not . id) results)
  in (passed, failed)
