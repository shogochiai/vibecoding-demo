||| TD Delegation — getDelegate() and getVotingPower() View Facets
||| REQ_DELEG_004: Delegation state queryable on-chain
module TD.Delegation.Yul.View

import public Subcontract.Core.Entry
import Subcontract.Core.ABI.Decoder
import public Subcontract.Core.Outcome
import TD.Delegation.Storage
import Delegation.Types

%default covering

-- =============================================================================
-- Function Signatures
-- =============================================================================

||| getDelegate(address) -> address
public export
getDelegateSig : Sig
getDelegateSig = MkSig "getDelegate" [TAddress] [TAddress]

||| Selector: bytes4(keccak256("getDelegate(address)")) = 0xb5b3ca2c
public export
getDelegateSel : Sel getDelegateSig
getDelegateSel = MkSel 0xb5b3ca2c

||| getVotingPower(address) -> uint256
public export
getVotingPowerSig : Sig
getVotingPowerSig = MkSig "getVotingPower" [TAddress] [TUint256]

||| Selector: bytes4(keccak256("getVotingPower(address)")) = 0x7ed4b27c
public export
getVotingPowerSel : Sel getVotingPowerSig
getVotingPowerSel = MkSel 0x7ed4b27c

-- =============================================================================
-- View Function Implementations — REQ_DELEG_004
-- =============================================================================

||| getDelegate: returns the delegatee address for a given delegator
||| Returns zero address if no active delegation
||| REQ_DELEG_004: Delegation state queryable on-chain
export
getDelegate : EvmAddr -> IO EvmAddr
getDelegate delegator = getDelegatee delegator

||| getVotingPower: returns accumulated voting power for an address
||| Includes own base power + any delegated power received
||| REQ_DELEG_004: Delegation state queryable on-chain
export
getVotingPowerOf : EvmAddr -> IO VotingPower
getVotingPowerOf addr = getVotingPower addr

-- =============================================================================
-- Entry Points
-- =============================================================================

||| Entry: getDelegate(address) -> address
||| Returns delegatee address (right-aligned in 32 bytes)
export
getDelegateEntry : Entry getDelegateSig
getDelegateEntry = MkEntry getDelegateSel $ do
  addr <- runDecoder decodeAddress
  delegatee <- getDelegate (addressValue addr)
  -- Return address: store in memory and return 32 bytes
  mstore 0 delegatee
  evmReturn 0 32

||| Entry: getVotingPower(address) -> uint256
||| Returns accumulated voting power as uint256
export
getVotingPowerEntry : Entry getVotingPowerSig
getVotingPowerEntry = MkEntry getVotingPowerSel $ do
  addr <- runDecoder decodeAddress
  power <- getVotingPowerOf (addressValue addr)
  -- Return uint256: store in memory and return 32 bytes
  mstore 0 power
  evmReturn 0 32

-- =============================================================================
-- Dispatch — REQ_DELEG_004
-- =============================================================================

||| Dispatch view functions by selector
||| 0xb5b3ca2c = getDelegate(address)
||| 0x7ed4b27c = getVotingPower(address)
export
dispatchView : IO ()
dispatchView = do
  sel <- calldataload 0
  selector <- shr 224 sel
  if selector == 0xb5b3ca2c
    then do
      addr <- calldataload 4
      delegatee <- getDelegate addr
      mstore 0 delegatee
      evmReturn 0 32
    else if selector == 0x7ed4b27c
      then do
        addr <- calldataload 4
        power <- getVotingPowerOf addr
        mstore 0 power
        evmReturn 0 32
      else evmRevert 0 0
