||| TextDAO Delegation Function
||| REQ_DELEG_001: Shareholder can delegate voting power to another address
||| REQ_DELEG_002: 1:1 delegation only, re-delegation blocked, no chain delegation
module TextDAO.Functions.Delegation.Delegation

import public Subcontract.Core.Entry
import Subcontract.Core.ABI.Decoder
import public Subcontract.Core.Outcome
import public TextDAO.Storages.Schema
import TextDAO.Functions.Members.Members

%default covering

-- =============================================================================
-- Function Signatures
-- =============================================================================

||| delegate(address) — delegate voting power to another address
||| REQ_DELEG_001
public export
delegateSig : Sig
delegateSig = MkSig "delegate" [TAddress] []

public export
delegateSel : Sel delegateSig
delegateSel = MkSel 0x5c19a95c

-- =============================================================================
-- Delegation Core Logic
-- =============================================================================

||| Base voting power per member (1 share = 1 vote)
BASE_VOTING_POWER : Integer
BASE_VOTING_POWER = 1

||| REQ_DELEG_002: Block chain delegation — delegatee must not have delegated
||| NoDelegationChain: prevents A->B->C transitive delegation
export
noReDelegate : EvmAddr -> IO (Outcome ())
noReDelegate delegatee = do
  delegateeActive <- isDelegationActive delegatee
  if delegateeActive
    then pure (Fail InvalidTransition (tagEvidence "NoDelegationChain"))
    else pure (Ok ())

||| Delegate voting power from caller to delegatee
||| REQ_DELEG_001, REQ_DELEG_002
||| - Caller must be a member
||| - Cannot delegate to zero address
||| - Cannot delegate to self
||| - ALREADY_DELEGATED: revert if caller already delegated (no re-delegation)
||| - NoDelegationChain: revert if delegatee has already delegated to someone
export
delegateVotingPower : EvmAddr -> EvmAddr -> IO (Outcome ())
delegateVotingPower delegator delegatee = do
  -- Validate: delegatee is not zero address
  if delegatee == 0
    then pure (Fail InvalidTransition (tagEvidence "CannotDelegateToZero"))
    else if delegator == delegatee
    then pure (Fail InvalidTransition (tagEvidence "CannotDelegateToSelf"))
    else do
      -- Check caller is a member
      memberCheck <- requireMember delegator
      case memberCheck of
        Fail c e => pure (Fail c e)
        Ok () => do
          -- REQ_DELEG_002: revert if already delegated (1:1, no re-delegation)
          active <- isDelegationActive delegator
          if active
            then pure (Fail InvalidTransition (tagEvidence "ALREADY_DELEGATED"))
            else do
              -- REQ_DELEG_002: block chain delegation (delegatee must not have delegated)
              chainCheck <- noReDelegate delegatee
              case chainCheck of
                Fail c e => pure (Fail c e)
                Ok () => do
                  -- Set new delegation
                  setDelegation delegator delegatee True
                  -- Accumulate voting power on delegatee
                  addVotingPower delegatee BASE_VOTING_POWER
                  pure (Ok ())

-- =============================================================================
-- Entry Points
-- =============================================================================

||| Entry: delegate(address)
||| REQ_DELEG_001
export
delegateEntry : Entry delegateSig
delegateEntry = MkEntry delegateSel $ do
  delegateeAddr <- runDecoder decodeAddress
  callerAddr <- caller
  result <- delegateVotingPower callerAddr (addrValue delegateeAddr)
  case result of
    Ok () => stop
    Fail _ _ => evmRevert 0 0
