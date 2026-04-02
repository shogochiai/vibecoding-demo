||| TextDAO Delegation View Functions
||| REQ_DELEG_003: Delegation state queryable on-chain
||| Provides delegateOf(address) and votingPowerOf(address) read functions
module TextDAO.Functions.Delegation.DelegationView

import public Subcontract.Core.Entry
import Subcontract.Core.ABI.Decoder
import public Subcontract.Core.Outcome
import public TextDAO.Storages.Schema

%default covering

-- =============================================================================
-- Function Signatures
-- =============================================================================

||| delegateOf(address) -> address
||| REQ_DELEG_003: Returns the delegatee for a given delegator
public export
delegateOfSig : Sig
delegateOfSig = MkSig "delegateOf" [TAddress] [TAddress]

public export
delegateOfSel : Sel delegateOfSig
delegateOfSel = MkSel 0xc58343ef

||| votingPowerOf(address) -> uint256
||| REQ_DELEG_003: Returns total accumulated voting power for an address
public export
votingPowerOfSig : Sig
votingPowerOfSig = MkSig "votingPowerOf" [TAddress] [TUint256]

public export
votingPowerOfSel : Sel votingPowerOfSig
votingPowerOfSel = MkSel 0x68e7e112

-- =============================================================================
-- Query Functions
-- =============================================================================

||| delegateOf(address) -> address
||| REQ_DELEG_003: Read the delegatee for a given delegator address
export
delegateOf : EvmAddr -> IO EvmAddr
delegateOf = getDelegatee

||| votingPowerOf(address) -> uint256
||| REQ_DELEG_003: Read the aggregated voting power for an address
export
votingPowerOf : EvmAddr -> IO Integer
votingPowerOf = getVotingPower

-- =============================================================================
-- Entry Points
-- =============================================================================

||| Entry: delegateOf(address) -> address
||| REQ_DELEG_003
export
delegateOfEntry : Entry delegateOfSig
delegateOfEntry = MkEntry delegateOfSel $ do
  addr <- runDecoder decodeAddress
  delegateeAddr <- delegateOf (addrValue addr)
  returnUint delegateeAddr

||| Entry: votingPowerOf(address) -> uint256
||| REQ_DELEG_003
export
votingPowerOfEntry : Entry votingPowerOfSig
votingPowerOfEntry = MkEntry votingPowerOfSel $ do
  addr <- runDecoder decodeAddress
  power <- votingPowerOf (addrValue addr)
  returnUint power
