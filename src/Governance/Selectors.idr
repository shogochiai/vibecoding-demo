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

||| Selector routing table entry: (selector, functionName, implementation).
public export
SelectorEntry : Type
SelectorEntry = (String, String, String)

||| All governance selectors for proxy registration.
public export
governanceSelectors : List SelectorEntry
governanceSelectors =
  [ (cancelProposalSelector, "cancelProposal(uint256)", "")
  , (postIpProposalSelector, "postIpProposal(string)", "")
  , (getProposalSelector, "getProposal(uint256)", "")
  ]
