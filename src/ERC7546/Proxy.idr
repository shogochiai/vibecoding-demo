module ERC7546.Proxy

import Governance.Selectors
import Delegation.Selectors
import Data.List
import Data.String

||| ERC-7546 proxy routing table.
||| Maps function selectors (bytes4) to implementation contract addresses.
||| The proxy's fallback function dispatches calls based on this table.

||| A routing entry: (selectorHex, implAddress, functionSig).
public export
RouteEntry : Type
RouteEntry = (String, String, String)

selectorHex : RouteEntry -> String
selectorHex (s, _, _) = s

implAddress : RouteEntry -> String
implAddress (_, a, _) = a

functionSig : RouteEntry -> String
functionSig (_, _, f) = f

||| The proxy routing table including cancelProposal and delegation facets.
||| REQ_DELEG_005: delegation selectors routed to delegation facet
public export
proxyRoutes : List RouteEntry
proxyRoutes =
  [ ("e0a8f6f5", "0x0000000000000000000000000000000000000001", "cancelProposal(uint256)")
  , ("b3af1d42", "0x0000000000000000000000000000000000000002", "postIpProposal(string)")
  , ("c7f758a8", "0x0000000000000000000000000000000000000002", "getProposal(uint256)")
  , ("5c19a95c", "0x0000000000000000000000000000000000000003", "delegate(address)")
  , ("a7713a70", "0x0000000000000000000000000000000000000003", "revokeDelegation()")
  , ("b5b3ca2c", "0x0000000000000000000000000000000000000003", "getDelegate(address)")
  , ("7ed4b27c", "0x0000000000000000000000000000000000000003", "getVotingPower(address)")
  ]

||| Look up the implementation address for a given selector.
||| Returns the address if found, Nothing otherwise.
public export
getImplementation : String -> Maybe String
getImplementation selector = map implAddress $ find (\r => selectorHex r == selector) proxyRoutes

||| Generate Yul code for the proxy's selector dispatch.
||| Produces a switch statement routing calldata selector to delegatecall targets.
public export
generateProxyDispatchYul : List RouteEntry -> String
generateProxyDispatchYul routes =
  let cases = map routeCase routes
  in unlines
    [ "// ERC-7546 Proxy Dispatch (auto-generated)"
    , "switch shr(224, calldataload(0))"
    , unlines cases
    , "default { revert(0, 0) }"
    ]
  where
    routeCase : RouteEntry -> String
    routeCase r = "case 0x" ++ selectorHex r
      ++ " { /* " ++ functionSig r ++ " */ delegatecall(gas(), "
      ++ implAddress r ++ ", 0, calldatasize(), 0, 0) }"
