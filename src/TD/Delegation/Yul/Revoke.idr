||| TD Delegation — revokeDelegation() Yul Codegen
||| REQ_DELEG_003: Delegator can revoke delegation at any time
module TD.Delegation.Yul.Revoke

import public Subcontract.Core.Entry
import Subcontract.Core.ABI.Decoder
import public Subcontract.Core.Outcome
import TD.Delegation.Storage
import Delegation.Types
import Delegation.Events

%default covering

-- =============================================================================
-- Function Signature
-- =============================================================================

||| revokeDelegation() -> bool
public export
revokeDelegationSig : Sig
revokeDelegationSig = MkSig "revokeDelegation" [] [TBool]

||| Selector: bytes4(keccak256("revokeDelegation()")) = 0xa7713a70
public export
revokeDelegationSel : Sel revokeDelegationSig
revokeDelegationSel = MkSel 0xa7713a70

-- =============================================================================
-- Core Revocation Logic — REQ_DELEG_003
-- =============================================================================

||| Revoke an active delegation, restoring voting power to the delegator.
||| REQ_DELEG_003: Delegator can revoke delegation at any time
|||
||| Steps:
||| 1. Check caller has an active delegation (revert if none)
||| 2. Remove delegator's power from delegatee's accumulated total
||| 3. Clear delegation mapping: delegator -> 0x0
||| 4. Emit DelegateRevoked event
export
revokeDelegation : EvmAddr -> IO (Outcome Bool)
revokeDelegation delegator = do
  -- Check for active delegation
  currentDelegatee <- getDelegatee delegator
  -- REQ_DELEG_003: Cannot revoke without active delegation
  if currentDelegatee == ZERO_ADDR
    then pure (Fail InvalidTransition (tagEvidence "noDelegation"))
    else do
      -- Get delegator's base power to remove from delegatee
      basePower <- getBasePower delegator

      -- Remove delegator's power from delegatee
      removeVotingPower currentDelegatee basePower

      -- Clear delegation
      setDelegatee delegator ZERO_ADDR

      -- Emit DelegateRevoked(delegator, previousDelegatee, votingPower)
      mstore 0 delegator
      mstore 32 currentDelegatee
      mstore 64 basePower
      log1 0 96 EVENT_DELEGATE_REVOKED

      pure (Ok True)

-- =============================================================================
-- Entry Point
-- =============================================================================

||| Entry: revokeDelegation() -> bool
||| REQ_DELEG_003: Selector routed via ERC-7546 proxy
export
revokeDelegationEntry : Entry revokeDelegationSig
revokeDelegationEntry = MkEntry revokeDelegationSel $ do
  callerAddr <- caller
  result <- revokeDelegation callerAddr
  case result of
    Ok success => returnBool success
    Fail _ _ => evmRevert 0 0
