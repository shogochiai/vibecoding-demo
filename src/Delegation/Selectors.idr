||| Delegation Function Selectors — td.onthe.eth
||| REQ_DELEG_005: ERC-7546 proxy integration selectors
module Delegation.Selectors

%default total

||| delegate(address) selector
||| keccak256("delegate(address)") = 0x5c19a95c...
public export
delegateSelector : String
delegateSelector = "5c19a95c"

||| revokeDelegation() selector
||| keccak256("revokeDelegation()") = 0xa7713a70...
public export
revokeDelegationSelector : String
revokeDelegationSelector = "a7713a70"

||| getDelegate(address) selector
||| keccak256("getDelegate(address)") = 0xb5b3ca2c...
public export
getDelegateSelector : String
getDelegateSelector = "b5b3ca2c"

||| getVotingPower(address) selector
||| keccak256("getVotingPower(address)") = 0x7ed4b27c...
public export
getVotingPowerSelector : String
getVotingPowerSelector = "7ed4b27c"

||| Selector routing table entry: (selector, functionName, implementation)
public export
SelectorEntry : Type
SelectorEntry = (String, String, String)

||| All delegation selectors for proxy registration
public export
delegationSelectors : List SelectorEntry
delegationSelectors =
  [ (delegateSelector,          "delegate(address)",       "")
  , (revokeDelegationSelector,  "revokeDelegation()",      "")
  , (getDelegateSelector,       "getDelegate(address)",    "")
  , (getVotingPowerSelector,    "getVotingPower(address)", "")
  ]
