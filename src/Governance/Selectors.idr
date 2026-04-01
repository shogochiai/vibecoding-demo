||| TextDAO Governance Selectors
||| REQ_CANCEL_001: Selector registry for ERC-7546 proxy dispatch
|||
||| Each governance function registers its 4-byte selector here so the
||| ERC-7546 diamond proxy can dispatch calldata to the correct implementation.
module Governance.Selectors

import public Subcontract.Core.Entry

%default covering

-- =============================================================================
-- Proposal Lifecycle Selectors
-- =============================================================================

||| propose(bytes32) -> uint256
public export
proposeSig : Sig
proposeSig = MkSig "propose" [TBytes32] [TUint256]

public export
proposeSel : Sel proposeSig
proposeSel = MkSel 0x01234567

||| vote(uint256, uint256[3], uint256[3]) -> bool
public export
voteSig : Sig
voteSig = MkSig "vote" [TUint256] [TBool]

public export
voteSel : Sel voteSig
voteSel = MkSel 0x34567890

||| tally(uint256) -> void
public export
tallySig : Sig
tallySig = MkSig "tally" [TUint256] []

public export
tallySel : Sel tallySig
tallySel = MkSel 0x67890123

||| execute(uint256) -> bool
public export
executeSig : Sig
executeSig = MkSig "execute" [TUint256] [TBool]

public export
executeSel : Sel executeSig
executeSel = MkSel 0x0badf00d

-- =============================================================================
-- REQ_CANCEL_001: cancelProposal selector registered for ERC-7546 dispatch
-- =============================================================================

||| cancelProposal(uint256) -> bool
||| Selector 0xd8e780df dispatches to Cancel implementation via ERC-7546 proxy
public export
cancelProposalSig : Sig
cancelProposalSig = MkSig "cancelProposal" [TUint256] [TBool]

||| cancelProposal selector for proxy dispatch
||| getImplementation(0xd8e780df) returns the Cancel facet address
public export
cancelProposalSel : Sel cancelProposalSig
cancelProposalSel = MkSel 0xd8e780df

-- =============================================================================
-- View Selectors
-- =============================================================================

||| isApproved(uint256) -> bool
public export
isApprovedSig : Sig
isApprovedSig = MkSig "isApproved" [TUint256] [TBool]

public export
isApprovedSel : Sel isApprovedSig
isApprovedSel = MkSel 0x89012345

||| getProposalCount() -> uint256
public export
getProposalCountSig : Sig
getProposalCountSig = MkSig "getProposalCount" [] [TUint256]

public export
getProposalCountSel : Sel getProposalCountSig
getProposalCountSel = MkSel 0xabcdef01

-- =============================================================================
-- Selector Registry (all governance selectors for proxy configuration)
-- =============================================================================

||| All governance selectors for ERC-7546 proxy registration
public export
governanceSelectors : List (String, Integer)
governanceSelectors =
  [ ("propose",          0x01234567)
  , ("vote",             0x34567890)
  , ("tally",            0x67890123)
  , ("execute",          0x0badf00d)
  , ("cancelProposal",   0xd8e780df)
  , ("isApproved",       0x89012345)
  , ("getProposalCount", 0xabcdef01)
  ]
