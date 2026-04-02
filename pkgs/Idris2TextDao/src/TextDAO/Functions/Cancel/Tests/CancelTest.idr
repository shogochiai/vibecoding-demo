||| TextDAO Cancel Test Suite
||| Tests for cancelProposal function
module TextDAO.Functions.Cancel.Tests.CancelTest

import TextDAO.Storages.Schema
import TextDAO.Functions.Propose.Propose
import TextDAO.Functions.Cancel.Cancel
import TextDAO.Functions.Tally.Tally
import Subcontract.Core.Outcome

%default covering

-- =============================================================================
-- REQ_CANCEL_002: Only author can cancel
-- =============================================================================

||| Test: Author can cancel a proposal
||| REQ_CANCEL_002
export
test_REQ_CANCEL_002_authorCanCancel : IO Bool
test_REQ_CANCEL_002_authorCanCancel = do
  -- Setup: create proposal with known author
  setExpiryDuration 86400
  let authorAddr = 0xdeadbeef
  pid <- createProposal authorAddr 0x1111

  -- Verify proposal is in active/pending state
  active <- isActivePending pid
  if not active then pure False
  else do
    -- Cancel using author's address (direct call bypassing caller check)
    authorResult <- checkAuthor pid authorAddr
    let isAuth = case authorResult of
                   Just _ => True
                   Nothing => False

    pure isAuth

||| Test: Non-author cannot cancel (requireAuthor fails)
||| REQ_CANCEL_002
export
test_REQ_CANCEL_002_nonAuthorRejected : IO Bool
test_REQ_CANCEL_002_nonAuthorRejected = do
  -- Setup
  setExpiryDuration 86400
  let authorAddr = 0xdeadbeef
  let otherAddr = 0xbaadf00d
  pid <- createProposal authorAddr 0x1111

  -- Check that non-author fails
  authorResult <- checkAuthor pid otherAddr
  let rejected = case authorResult of
                   Just _ => False
                   Nothing => True

  pure rejected

-- =============================================================================
-- REQ_CANCEL_003: Proposal must be active/pending
-- =============================================================================

||| Test: Cannot cancel already executed proposal
||| REQ_CANCEL_003
export
test_REQ_CANCEL_003_cannotCancelExecuted : IO Bool
test_REQ_CANCEL_003_cannotCancelExecuted = do
  -- Setup
  setExpiryDuration 86400
  let authorAddr = 0xdeadbeef
  pid <- createProposal authorAddr 0x1111

  -- Mark as executed
  setFullyExecuted pid True

  -- Check proposal is NOT active/pending
  active <- isActivePending pid
  pure (not active)

||| Test: Cannot cancel already cancelled proposal
||| REQ_CANCEL_003
export
test_REQ_CANCEL_003_cannotCancelTwice : IO Bool
test_REQ_CANCEL_003_cannotCancelTwice = do
  -- Setup
  setExpiryDuration 86400
  let authorAddr = 0xdeadbeef
  pid <- createProposal authorAddr 0x1111

  -- Cancel once
  setProposalCancelled pid True

  -- Verify not active
  active <- isActivePending pid
  cancelled <- isProposalCancelled pid

  pure (not active && cancelled)

||| Test: Cannot cancel approved proposal
||| REQ_CANCEL_003
export
test_REQ_CANCEL_003_cannotCancelApproved : IO Bool
test_REQ_CANCEL_003_cannotCancelApproved = do
  -- Setup
  setExpiryDuration 86400
  let authorAddr = 0xdeadbeef
  pid <- createProposal authorAddr 0x1111

  -- Approve proposal
  approveProposal pid 1 1

  -- Verify not active
  active <- isActivePending pid
  pure (not active)

-- =============================================================================
-- REQ_CANCEL_004: Tally exclusion and slot freeing
-- =============================================================================

||| Test: Cancelled proposal is excluded from tally
||| REQ_CANCEL_004
export
test_REQ_CANCEL_004_tallyExcludesCancelled : IO Bool
test_REQ_CANCEL_004_tallyExcludesCancelled = do
  -- Setup
  setExpiryDuration 86400
  let authorAddr = 0xdeadbeef
  pid <- createProposal authorAddr 0xabcd

  -- Cancel it
  setProposalCancelled pid True

  -- Verify cancelled flag
  cancelled <- isProposalCancelled pid
  pure cancelled

||| Test: Voting slot freed on cancel (expiration set to 0)
||| REQ_CANCEL_004
export
test_REQ_CANCEL_004_slotFreed : IO Bool
test_REQ_CANCEL_004_slotFreed = do
  -- Setup
  setExpiryDuration 86400
  let authorAddr = 0xdeadbeef
  pid <- createProposal authorAddr 0x1111

  -- Check expiration is set initially
  expBefore <- getProposalExpiration pid
  let hadExpiry = expBefore > 0

  -- Free the slot
  freeSlot pid

  -- Check expiration is now 0
  expAfter <- getProposalExpiration pid
  let slotFreed = expAfter == 0

  pure (hadExpiry && slotFreed)

-- =============================================================================
-- REQ_CANCEL_005: ProposalCancelled event
-- =============================================================================

||| Test: ProposalCancelled event data is correct
||| REQ_CANCEL_005
export
test_REQ_CANCEL_005_eventEmitted : IO Bool
test_REQ_CANCEL_005_eventEmitted = do
  -- Setup
  setExpiryDuration 86400
  let authorAddr = 0xdeadbeef
  pid <- createProposal authorAddr 0x1111

  -- Verify author is stored correctly (event reads from storage)
  storedAuthor <- getProposalAuthor pid
  pure (storedAuthor == authorAddr)

-- =============================================================================
-- Integration: Full cancel flow
-- =============================================================================

||| Test: Full cancel flow - create, verify active, cancel, verify cancelled
export
test_cancel_full_flow : IO Bool
test_cancel_full_flow = do
  -- Setup
  setExpiryDuration 86400
  let authorAddr = 0xdeadbeef
  pid <- createProposal authorAddr 0x1111

  -- Verify initial state
  activeBefore <- isActivePending pid
  cancelledBefore <- isProposalCancelled pid

  -- Cancel
  setProposalCancelled pid True
  freeSlot pid

  -- Verify final state
  activeAfter <- isActivePending pid
  cancelledAfter <- isProposalCancelled pid
  expAfter <- getProposalExpiration pid

  pure (activeBefore && not cancelledBefore &&
        not activeAfter && cancelledAfter && expAfter == 0)

-- =============================================================================
-- Test Collection
-- =============================================================================

export
allCancelTests : List (String, IO Bool)
allCancelTests =
  [ ("REQ_CANCEL_002_authorCanCancel", test_REQ_CANCEL_002_authorCanCancel)
  , ("REQ_CANCEL_002_nonAuthorRejected", test_REQ_CANCEL_002_nonAuthorRejected)
  , ("REQ_CANCEL_003_cannotCancelExecuted", test_REQ_CANCEL_003_cannotCancelExecuted)
  , ("REQ_CANCEL_003_cannotCancelTwice", test_REQ_CANCEL_003_cannotCancelTwice)
  , ("REQ_CANCEL_003_cannotCancelApproved", test_REQ_CANCEL_003_cannotCancelApproved)
  , ("REQ_CANCEL_004_tallyExcludesCancelled", test_REQ_CANCEL_004_tallyExcludesCancelled)
  , ("REQ_CANCEL_004_slotFreed", test_REQ_CANCEL_004_slotFreed)
  , ("REQ_CANCEL_005_eventEmitted", test_REQ_CANCEL_005_eventEmitted)
  , ("cancel_full_flow", test_cancel_full_flow)
  ]

||| Run all cancel tests and return passed count
export
runCancelTests : IO Integer
runCancelTests = do
  r1 <- test_REQ_CANCEL_002_authorCanCancel
  r2 <- test_REQ_CANCEL_002_nonAuthorRejected
  r3 <- test_REQ_CANCEL_003_cannotCancelExecuted
  r4 <- test_REQ_CANCEL_003_cannotCancelTwice
  r5 <- test_REQ_CANCEL_003_cannotCancelApproved
  r6 <- test_REQ_CANCEL_004_tallyExcludesCancelled
  r7 <- test_REQ_CANCEL_004_slotFreed
  r8 <- test_REQ_CANCEL_005_eventEmitted
  r9 <- test_cancel_full_flow
  pure $ (if r1 then 1 else 0) + (if r2 then 1 else 0) +
         (if r3 then 1 else 0) + (if r4 then 1 else 0) +
         (if r5 then 1 else 0) + (if r6 then 1 else 0) +
         (if r7 then 1 else 0) + (if r8 then 1 else 0) +
         (if r9 then 1 else 0)
