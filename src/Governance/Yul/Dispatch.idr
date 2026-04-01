||| Governance Yul Dispatch Table
||| Maps EVM function selectors to implementation functions.
||| REQ_CANCEL_001: cancelProposal selector registered in dispatch table.
module Governance.Yul.Dispatch

import Governance.Yul.Proposal

%default covering

-- =============================================================================
-- Selector Constants
-- =============================================================================

||| propose(bytes32) -> uint256
export
SEL_PROPOSE : Integer
SEL_PROPOSE = 0x01234567

||| tally(uint256) -> void
export
SEL_TALLY : Integer
SEL_TALLY = 0x67890123

||| tallyAndExecute(uint256) -> bool
export
SEL_TALLY_AND_EXECUTE : Integer
SEL_TALLY_AND_EXECUTE = 0x90123456

||| cancelProposal(uint256) -> bool
||| REQ_CANCEL_001: Registered in dispatch table
export
SEL_CANCEL_PROPOSAL : Integer
SEL_CANCEL_PROPOSAL = SELECTOR_CANCEL_PROPOSAL  -- 0xd8e780df

-- =============================================================================
-- Dispatch Entry
-- =============================================================================

||| A dispatch table entry mapping selector to function name.
public export
record DispatchEntry where
  constructor MkDispatchEntry
  selector     : Integer
  functionName : String
  functionSig  : String

||| All governance dispatch entries including cancelProposal.
export
governanceDispatchTable : List DispatchEntry
governanceDispatchTable =
  [ MkDispatchEntry SEL_PROPOSE           "propose"          "propose(bytes32)"
  , MkDispatchEntry SEL_TALLY             "tally"            "tally(uint256)"
  , MkDispatchEntry SEL_TALLY_AND_EXECUTE "tallyAndExecute"  "tallyAndExecute(uint256)"
  , MkDispatchEntry SEL_CANCEL_PROPOSAL   "cancelProposal"   "cancelProposal(uint256)"
  ]

-- =============================================================================
-- Yul Dispatch Codegen
-- =============================================================================

||| Generate Yul switch statement for selector dispatch.
||| Includes cancelProposal case routing to cancel logic.
export
generateDispatchYul : List DispatchEntry -> String
generateDispatchYul entries =
  let cases = map dispatchCase entries
  in unlines
    [ "// Governance Selector Dispatch (auto-generated)"
    , "switch shr(224, calldataload(0))"
    , unlines cases
    , "default { revert(0, 0) }"
    ]
  where
    dispatchCase : DispatchEntry -> String
    dispatchCase e = "case 0x" ++ showHex e.selector
      ++ " { /* " ++ e.functionSig ++ " */ "
      ++ e.functionName ++ "(decodeUint256()) }"

    showHex : Integer -> String
    showHex n = pack (toHexChars n [])
      where
        hexDigit : Integer -> Char
        hexDigit i = if i < 10
          then chr (cast i + 48)
          else chr (cast i - 10 + 97)

        toHexChars : Integer -> List Char -> List Char
        toHexChars 0 [] = ['0']
        toHexChars 0 acc = acc
        toHexChars n acc = toHexChars (n `div` 16) (hexDigit (n `mod` 16) :: acc)
