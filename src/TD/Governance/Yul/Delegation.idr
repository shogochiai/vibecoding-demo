||| TD Governance Delegation — Yul Codegen
||| REQ_DELEG_001: delegate(address) selector dispatches via ERC-7546 proxy
||| REQ_DELEG_002: Delegation state stored in proxy storage (ERC-7546 pattern)
||| REQ_DELEG_003: Delegate can vote on behalf of delegator
||| REQ_DELEG_004: Delegator can revoke delegation at any time
||| REQ_DELEG_005: Delegation does not transfer token ownership
module TD.Governance.Yul.Delegation

import public Subcontract.Core.Entry
import Subcontract.Core.ABI.Decoder
import public Subcontract.Core.Outcome
import TD.Governance.Proposal
import Governance.Delegation.Selectors

%default covering

-- =============================================================================
-- Function Signatures
-- =============================================================================

||| delegate(address) -> bool
public export
delegateSig : Sig
delegateSig = MkSig "delegate" [TAddress] [TBool]

public export
delegateSel : Sel delegateSig
delegateSel = MkSel SEL_DELEGATE  -- 0x5c19a95c

||| revokeDelegation() -> bool
public export
revokeDelegationSig : Sig
revokeDelegationSig = MkSig "revokeDelegation" [] [TBool]

public export
revokeDelegationSel : Sel revokeDelegationSig
revokeDelegationSel = MkSel SEL_REVOKE_DELEGATION  -- 0x7b0a47e8

||| getDelegate(address) -> address
public export
getDelegateSig : Sig
getDelegateSig = MkSig "getDelegate" [TAddress] [TAddress]

public export
getDelegateSel : Sel getDelegateSig
getDelegateSel = MkSel SEL_GET_DELEGATE  -- 0xf50741f2

-- =============================================================================
-- Storage Layout (ERC-7201 Namespaced)
-- =============================================================================

||| Base storage slot for delegation mapping
||| REQ_DELEG_002: Storage slot follows ERC-7546 namespaced layout
export
SLOT_DELEGATION : Integer
SLOT_DELEGATION = 0x2000

||| Calculate storage slot for delegator's delegate
||| slot = keccak256(delegator . SLOT_DELEGATION)
export
getDelegateSlot : Integer -> IO Integer
getDelegateSlot delegator = do
  mstore 0 delegator
  mstore 32 SLOT_DELEGATION
  keccak256 0 64

-- =============================================================================
-- Storage Read/Write
-- =============================================================================

||| Get the delegate address for a delegator
export
getDelegate : Integer -> IO Integer
getDelegate delegator = do
  slot <- getDelegateSlot delegator
  sload slot

||| Set delegate address for a delegator
export
setDelegate : Integer -> Integer -> IO ()
setDelegate delegator delegate = do
  slot <- getDelegateSlot delegator
  sstore slot delegate

||| Clear delegation for a delegator
export
clearDelegate : Integer -> IO ()
clearDelegate delegator = do
  slot <- getDelegateSlot delegator
  sstore slot 0

-- =============================================================================
-- Events
-- =============================================================================

||| DelegationSet(address indexed delegator, address indexed delegate)
export
EVENT_DELEGATION_SET : Integer
EVENT_DELEGATION_SET = 0x3333333333333333333333333333333333333333333333333333333333333333

||| DelegationRevoked(address indexed delegator, address indexed previousDelegate)
export
EVENT_DELEGATION_REVOKED : Integer
EVENT_DELEGATION_REVOKED = 0x4444444444444444444444444444444444444444444444444444444444444444

-- =============================================================================
-- Core Logic
-- =============================================================================

||| Set a delegate for the caller
||| REQ_DELEG_001: Shareholder can delegate voting power to another address
||| REQ_DELEG_005: Cannot delegate to self or zero address
export
delegate : Integer -> IO (Outcome Bool)
delegate delegateAddr = do
  callerAddr <- caller

  -- Cannot delegate to self
  if callerAddr == delegateAddr
    then pure (Fail InvalidTransition (tagEvidence "CannotDelegateToSelf"))
    else do
      -- Cannot delegate to zero address
      if delegateAddr == 0
        then pure (Fail InvalidTransition (tagEvidence "CannotDelegateToZero"))
        else do
          -- Set the delegation
          setDelegate callerAddr delegateAddr

          -- Emit event
          mstore 0 delegateAddr
          log2 0 32 EVENT_DELEGATION_SET callerAddr

          pure (Ok True)

||| Revoke delegation for the caller
||| REQ_DELEG_004: Delegator can revoke delegation at any time
export
revokeDelegation : IO (Outcome Bool)
revokeDelegation = do
  callerAddr <- caller

  -- Get current delegate
  currentDelegate <- getDelegate callerAddr

  -- Check if there's an active delegation
  if currentDelegate == 0
    then pure (Fail InvalidTransition (tagEvidence "NoActiveDelegation"))
    else do
      -- Clear the delegation
      clearDelegate callerAddr

      -- Emit event
      mstore 0 currentDelegate
      log2 0 32 EVENT_DELEGATION_REVOKED callerAddr

      pure (Ok True)

||| Get delegate for a given address (view function)
export
getDelegateFor : Integer -> IO Integer
getDelegateFor delegator = getDelegate delegator

-- =============================================================================
-- Entry Points
-- =============================================================================

||| Entry: delegate(address) -> bool
export
delegateEntry : Entry delegateSig
delegateEntry = MkEntry delegateSel $ do
  delegateAddr <- runDecoder decodeAddress
  result <- delegate (addressValue delegateAddr)
  case result of
    Ok success => returnBool success
    Fail _ _ => evmRevert 0 0

||| Entry: revokeDelegation() -> bool
export
revokeDelegationEntry : Entry revokeDelegationSig
revokeDelegationEntry = MkEntry revokeDelegationSel $ do
  result <- revokeDelegation
  case result of
    Ok success => returnBool success
    Fail _ _ => evmRevert 0 0

||| Entry: getDelegate(address) -> address
export
getDelegateEntry : Entry getDelegateSig
getDelegateEntry = MkEntry getDelegateSel $ do
  delegator <- runDecoder decodeAddress
  delegateAddr <- getDelegateFor (addressValue delegator)
  returnAddress delegateAddr
