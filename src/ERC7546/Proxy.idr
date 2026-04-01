module ERC7546.Proxy

import Governance.Selectors

||| ERC-7546 proxy routing table.
||| Maps function selectors (bytes4) to implementation contract addresses.
||| The proxy's fallback function dispatches calls based on this table.

||| A routing entry in the proxy's implementation table.
public export
record RouteEntry where
  constructor MkRouteEntry
  selectorHex    : String  -- bytes4 hex without 0x prefix
  implAddress    : String  -- implementation contract address
  functionSig    : String  -- human-readable signature

||| The proxy routing table including cancelProposal.
||| e0a8f6f5 → cancelProposal(uint256) implementation
public export
proxyRoutes : List RouteEntry
proxyRoutes =
  [ MkRouteEntry "e0a8f6f5" "0x0000000000000000000000000000000000000001" "cancelProposal(uint256)"
  , MkRouteEntry "b3af1d42" "0x0000000000000000000000000000000000000002" "postIpProposal(string)"
  , MkRouteEntry "c7f758a8" "0x0000000000000000000000000000000000000002" "getProposal(uint256)"
  ]

||| Look up the implementation address for a given selector.
||| Returns the address if found, Nothing otherwise.
public export
getImplementation : String -> Maybe String
getImplementation selector = map implAddress $ find (\r => r.selectorHex == selector) proxyRoutes

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
    routeCase r = "case 0x" ++ r.selectorHex
      ++ " { /* " ++ r.functionSig ++ " */ delegatecall(gas(), "
      ++ r.implAddress ++ ", 0, calldatasize(), 0, 0) }"
