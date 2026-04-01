||| TD Delegation — delegate() Yul Codegen
||| REQ_DELEG_001: Shareholder can delegate voting power to another address
||| REQ_DELEG_002: Delegatee accumulates delegator's voting power
module TD.Delegation.Yul.Delegate

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

||| delegate(address) -> bool
public export
delegateSig : Sig
delegateSig = MkSig "delegate" [TAddress] [TBool]

||| Selector: bytes4(keccak256("delegate(address)")) = 0x5c19a95c
public export
delegateSel : Sel delegateSig
delegateSel = MkSel 0x5c19a95c

-- =============================================================================
-- Core Delegation Logic — REQ_DELEG_001, REQ_DELEG_002
-- =============================================================================

||| Delegate voting power from caller to delegatee.
||| REQ_DELEG_001: Shareholder can delegate voting power
||| REQ_DELEG_002: Delegatee accumulates delegator's voting power
|||
||| Steps:
||| 1. Cannot delegate to self or zero address
||| 2. If already delegated, revoke previous delegation first
||| 3. Record new delegation: delegator -> delegatee
||| 4. Transfer voting power: add delegator's base power to delegatee
||| 5. Emit DelegateChanged event
export
delegateVotingPower : EvmAddr -> EvmAddr -> IO (Outcome Bool)
delegateVotingPower delegator delegatee = do
  -- Guard: cannot delegate to zero address
  if delegatee == ZERO_ADDR
    then pure (Fail InvalidInput (tagEvidence "CannotDelegateToZeroAddress"))
    else do
      -- Guard: cannot delegate to self
      if delegator == delegatee
        then pure (Fail InvalidInput (tagEvidence "CannotDelegateToSelf"))
        else do
          -- Check for existing delegation and revoke it first
          currentDelegatee <- getDelegatee delegator
          delegatorPower <- getBasePower delegator
          -- If no base power recorded yet, initialize it from voting power
          basePower <- if delegatorPower == 0
            then do
              vp <- getVotingPower delegator
              let bp = if vp == 0 then 1 else vp
              setBasePower delegator bp
              pure bp
            else pure delegatorPower

          -- Revoke existing delegation if any
          if currentDelegatee /= ZERO_ADDR
            then removeVotingPower currentDelegatee basePower
            else pure ()

          -- Set new delegation
          setDelegatee delegator delegatee

          -- REQ_DELEG_002: Accumulate delegator's power to delegatee
          addVotingPower delegatee basePower

          -- Emit DelegateChanged(delegator, delegatee, votingPower)
          mstore 0 delegator
          mstore 32 delegatee
          mstore 64 basePower
          log1 0 96 EVENT_DELEGATE_CHANGED

          pure (Ok True)

-- =============================================================================
-- Entry Point
-- =============================================================================

||| Entry: delegate(address) -> bool
||| REQ_DELEG_001: Selector routed via ERC-7546 proxy
export
delegateEntry : Entry delegateSig
delegateEntry = MkEntry delegateSel $ do
  delegateeAddr <- runDecoder decodeAddress
  callerAddr <- caller
  result <- delegateVotingPower callerAddr (addressValue delegateeAddr)
  case result of
    Ok success => returnBool success
    Fail _ _ => evmRevert 0 0
