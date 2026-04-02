||| TextDAO Revoke Delegation Function
||| REQ_DELEG_004: Delegator can revoke delegation at any time
module TextDAO.Functions.Delegation.RevokeDelegation

import public Subcontract.Core.Entry
import Subcontract.Core.ABI.Decoder
import public Subcontract.Core.Outcome
import public TextDAO.Storages.Schema
import TextDAO.Functions.Members.Members

%default covering

-- =============================================================================
-- Function Signatures
-- =============================================================================

||| revokeDelegation() — revoke current delegation and restore voting power
||| REQ_DELEG_004
public export
revokeDelegationSig : Sig
revokeDelegationSig = MkSig "revokeDelegation" [] []

public export
revokeDelegationSel : Sel revokeDelegationSig
revokeDelegationSel = MkSel 0xc24a0cee

-- =============================================================================
-- Revoke Core Logic
-- =============================================================================

||| Base voting power per member (1 share = 1 vote)
BASE_VOTING_POWER : Integer
BASE_VOTING_POWER = 1

||| REQ_DELEG_004: Only the delegator (caller) can revoke their own delegation
||| Verifies caller eq delegator — only the original delegator may revoke
export
onlyDelegator : EvmAddr -> EvmAddr -> IO (Outcome ())
onlyDelegator callerAddr delegator =
  if callerAddr == delegator
    then pure (Ok ())
    else pure (Fail Unauthorized (tagEvidence "OnlyDelegatorCanRevoke"))

||| Revoke delegation and restore voting power to the original state
||| REQ_DELEG_004
||| - caller eq delegator (onlyDelegator check)
||| - Caller must have an active delegation
||| - Removes accumulated power from old delegatee
||| - Clears delegation record
export
revokeDelegation : EvmAddr -> IO (Outcome ())
revokeDelegation delegator = do
  -- REQ_DELEG_004: onlyDelegator — caller must be the delegator
  callerAddr <- caller
  authCheck <- onlyDelegator callerAddr delegator
  case authCheck of
    Fail c e => pure (Fail c e)
    Ok () => do
      -- Check caller has active delegation
      active <- isDelegationActive delegator
      if not active
        then pure (Fail InvalidTransition (tagEvidence "NoDelegationActive"))
        else do
          -- Get current delegatee
          currentDelegatee <- getDelegatee delegator
          -- Remove voting power from delegatee
          removeVotingPower currentDelegatee BASE_VOTING_POWER
          -- Clear delegation record
          setDelegation delegator 0 False
          pure (Ok ())

-- =============================================================================
-- Entry Points
-- =============================================================================

||| Entry: revokeDelegation()
||| REQ_DELEG_004
export
revokeDelegationEntry : Entry revokeDelegationSig
revokeDelegationEntry = MkEntry revokeDelegationSel $ do
  callerAddr <- caller
  result <- revokeDelegation callerAddr
  case result of
    Ok () => stop
    Fail _ _ => evmRevert 0 0
