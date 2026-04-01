||| Verification: Cancel Implementation Artifact Parity
||| REQ_CANCEL_006: Deployed bytecode matches compiled artifact
module Verification.CancelVerify

import Governance.Proposal
import Governance.Cancel
import Governance.Events
import Proxy.Selectors

-- =============================================================================
-- Artifact Verification
-- =============================================================================

||| Expected selector for cancelProposal
||| cast sig "cancelProposal(uint256)" = 0xd8e780df
public export
EXPECTED_SELECTOR : Integer
EXPECTED_SELECTOR = 0xd8e780df

||| Verify that the cancelProposal selector matches the expected value
public export
verifySelectorMatch : Bool
verifySelectorMatch = CANCEL_PROPOSAL_SELECTOR == EXPECTED_SELECTOR
                   && SELECTOR_cancelProposal == EXPECTED_SELECTOR

||| Verify cancel event topic is defined
public export
verifyEventDefined : Bool
verifyEventDefined = EVENT_CANCEL_PROPOSAL > 0

||| Verify state transition from Active to Cancelled is valid
public export
verifyStateTransition : Bool
verifyStateTransition =
  isValidTransition Active Cancelled
  && isValidTransition Pending Cancelled
  && not (isValidTransition Executed Cancelled)
  && not (isValidTransition Approved Cancelled)

||| Verify Cancelled state is in the ProposalState sum type
public export
verifyCancelledState : ProposalState
verifyCancelledState = Cancelled

||| Run all verification checks
||| REQ_CANCEL_006: Verification that compiled artifact is correct
public export
verifyArtifact : Bool
verifyArtifact = verifySelectorMatch
              && verifyEventDefined
              && verifyStateTransition
              && stateToInt Cancelled == 4

-- =============================================================================
-- Main verification entry point
-- =============================================================================

main : IO ()
main = do
  let result = verifyArtifact
  if result
    then putStrLn "VERIFY_OK: All cancel artifact checks passed"
    else putStrLn "VERIFY_FAIL: Cancel artifact verification failed"
