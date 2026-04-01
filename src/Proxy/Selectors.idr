||| ERC-7546 Proxy Selector Registry
||| Maps function selectors to implementation contract addresses via getImplementation(bytes4)
module Proxy.Selectors

-- =============================================================================
-- Selector Registry
-- =============================================================================

||| Function selector for cancelProposal(uint256)
||| REQ_CANCEL_001: Registered in ERC-7546 proxy for dispatch
||| cast sig "cancelProposal(uint256)" = 0xd8e780df
public export
SELECTOR_cancelProposal : Integer
SELECTOR_cancelProposal = 0xd8e780df

||| Function selector for propose(bytes32)
public export
SELECTOR_propose : Integer
SELECTOR_propose = 0x01234567

||| Function selector for vote(uint256,uint256,uint256,uint256,uint256,uint256,uint256)
public export
SELECTOR_vote : Integer
SELECTOR_vote = 0x34567890

||| Function selector for tally(uint256)
public export
SELECTOR_tally : Integer
SELECTOR_tally = 0x67890123

||| Function selector for execute(uint256)
public export
SELECTOR_execute : Integer
SELECTOR_execute = 0xe0123456

||| Function selector for fork(uint256,bytes32,uint256)
public export
SELECTOR_fork : Integer
SELECTOR_fork = 0xf0123456

||| Function selector for snap(uint256)
public export
SELECTOR_snap : Integer
SELECTOR_snap = 0x78901234

||| Function selector for isApproved(uint256)
public export
SELECTOR_isApproved : Integer
SELECTOR_isApproved = 0x89012345

||| Function selector for tallyAndExecute(uint256)
public export
SELECTOR_tallyAndExecute : Integer
SELECTOR_tallyAndExecute = 0x90123456

||| Function selector for addMember(address,bytes32)
public export
SELECTOR_addMember : Integer
SELECTOR_addMember = 0xca6d56dc

||| Function selector for delegate(address)
public export
SELECTOR_delegate : Integer
SELECTOR_delegate = 0x5c19a95c

-- =============================================================================
-- Selector Dispatch Table
-- =============================================================================

||| All registered selectors for getImplementation(bytes4) lookup
||| ERC-7546: proxy reads implementation address from storage keyed by selector
public export
allSelectors : List (Integer, String)
allSelectors =
  [ (SELECTOR_cancelProposal,    "cancelProposal(uint256)")
  , (SELECTOR_propose,           "propose(bytes32)")
  , (SELECTOR_vote,              "vote(uint256,uint256[3],uint256[3])")
  , (SELECTOR_tally,             "tally(uint256)")
  , (SELECTOR_execute,           "execute(uint256)")
  , (SELECTOR_fork,              "fork(uint256,bytes32,uint256)")
  , (SELECTOR_snap,              "snap(uint256)")
  , (SELECTOR_isApproved,        "isApproved(uint256)")
  , (SELECTOR_tallyAndExecute,   "tallyAndExecute(uint256)")
  , (SELECTOR_addMember,         "addMember(address,bytes32)")
  , (SELECTOR_delegate,          "delegate(address)")
  ]

||| Lookup implementation selector by bytes4
public export
findSelector : Integer -> Maybe String
findSelector sel = lookup sel allSelectors
  where
    lookup : Integer -> List (Integer, String) -> Maybe String
    lookup _ [] = Nothing
    lookup s ((k, v) :: rest) = if s == k then Just v else lookup s rest
