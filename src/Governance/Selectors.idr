module Governance.Selectors

||| EVM function selectors (bytes4) for governance operations.
||| Computed as first 4 bytes of keccak256(signature).

||| cancelProposal(uint256) selector.
||| keccak256("cancelProposal(uint256)") = 0xe0a8f6f5...
public export
cancelProposalSelector : String
cancelProposalSelector = "e0a8f6f5"

||| postIpProposal(string) selector.
public export
postIpProposalSelector : String
postIpProposalSelector = "b3af1d42"

||| getProposal(uint256) selector.
public export
getProposalSelector : String
getProposalSelector = "c7f758a8"

||| Selector routing table entry.
public export
record SelectorEntry where
  constructor MkSelectorEntry
  selector       : String
  functionName   : String
  implementation : String  -- address of implementation contract

||| All governance selectors for proxy registration.
public export
governanceSelectors : List SelectorEntry
governanceSelectors =
  [ MkSelectorEntry cancelProposalSelector "cancelProposal(uint256)" ""
  , MkSelectorEntry postIpProposalSelector "postIpProposal(string)" ""
  , MkSelectorEntry getProposalSelector "getProposal(uint256)" ""
  ]
