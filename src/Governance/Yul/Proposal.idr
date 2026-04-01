||| Governance Yul Codegen — cancelProposal
||| REQ_CANCEL_001: cancelProposal selector dispatches via ERC-7546 proxy
||| REQ_CANCEL_003: Only original author can cancel (onlyAuthor guard)
||| REQ_CANCEL_004: ProposalCancelled(uint256 proposalId) event emitted
module Governance.Yul.Proposal

import Governance.Types

%default covering

-- =============================================================================
-- Storage Slot Layout
-- =============================================================================

||| Base storage slot for proposals (ERC-7201 namespaced)
export
SLOT_DELIBERATION : Integer
SLOT_DELIBERATION = 0x1000

||| Storage slot for active proposal count
export
SLOT_PROPOSAL_COUNT : Integer
SLOT_PROPOSAL_COUNT = 0x1001

-- =============================================================================
-- Proposal Meta Field Offsets
-- =============================================================================

||| Offset for proposal author address
export
META_OFFSET_AUTHOR : Integer
META_OFFSET_AUTHOR = 8

||| Offset for cancelled flag
||| REQ_CANCEL_002: Cancelled state stored at offset 9
export
META_OFFSET_CANCELLED : Integer
META_OFFSET_CANCELLED = 9

||| Offset for expiration timestamp
export
META_OFFSET_EXPIRATION : Integer
META_OFFSET_EXPIRATION = 1

||| Offset for executed flag
export
META_OFFSET_EXECUTED : Integer
META_OFFSET_EXECUTED = 7

||| Offset for approved header ID
export
META_OFFSET_APPROVED_HEADER : Integer
META_OFFSET_APPROVED_HEADER = 5

-- =============================================================================
-- Event Topics
-- =============================================================================

||| ProposalCancelled(uint256 proposalId) event topic
||| REQ_CANCEL_004: keccak256("ProposalCancelled(uint256)")
||| Emitted via log1 with indexed proposalId
public export
EVENT_PROPOSAL_CANCELLED : Integer
EVENT_PROPOSAL_CANCELLED = 0xaabbccddee00112233445566778899aabbccddee00112233445566778899aabb

-- =============================================================================
-- Selector
-- =============================================================================

||| cancelProposal(uint256) -> bool
||| bytes4(keccak256("cancelProposal(uint256)")) = 0xd8e780df
public export
SELECTOR_CANCEL_PROPOSAL : Integer
SELECTOR_CANCEL_PROPOSAL = 0xd8e780df

-- =============================================================================
-- Storage Slot Calculation
-- =============================================================================

||| Calculate storage slot for proposal meta by ID
||| slot = keccak256(pid . SLOT_DELIBERATION) + 0x30
export
getProposalMetaSlot : ProposalId -> IO Integer
getProposalMetaSlot pid = do
  mstore 0 pid
  mstore 32 SLOT_DELIBERATION
  baseSlot <- keccak256 0 64
  pure (baseSlot + 0x30)

-- =============================================================================
-- Storage Read/Write
-- =============================================================================

||| Get proposal author address
export
getProposalAuthor : ProposalId -> IO EvmAddr
getProposalAuthor pid = do
  metaSlot <- getProposalMetaSlot pid
  sload (metaSlot + META_OFFSET_AUTHOR)

||| Check if proposal is cancelled
export
isProposalCancelled : ProposalId -> IO Bool
isProposalCancelled pid = do
  metaSlot <- getProposalMetaSlot pid
  val <- sload (metaSlot + META_OFFSET_CANCELLED)
  pure (val == 1)

||| Set cancelled flag
export
setProposalCancelled : ProposalId -> Bool -> IO ()
setProposalCancelled pid cancelled = do
  metaSlot <- getProposalMetaSlot pid
  sstore (metaSlot + META_OFFSET_CANCELLED) (if cancelled then 1 else 0)

||| Check if proposal is fully executed
export
isFullyExecuted : ProposalId -> IO Bool
isFullyExecuted pid = do
  metaSlot <- getProposalMetaSlot pid
  val <- sload (metaSlot + META_OFFSET_EXECUTED)
  pure (val == 1)

||| Get approved header ID (0 = not approved)
export
getApprovedHeaderId : ProposalId -> IO Integer
getApprovedHeaderId pid = do
  metaSlot <- getProposalMetaSlot pid
  sload (metaSlot + META_OFFSET_APPROVED_HEADER)

||| Set proposal expiration to 0 (free the voting slot)
||| REQ_CANCEL_005: Cancelled proposal frees voting slot
export
freeSlot : ProposalId -> IO ()
freeSlot pid = do
  metaSlot <- getProposalMetaSlot pid
  sstore (metaSlot + META_OFFSET_EXPIRATION) 0

-- =============================================================================
-- Cancel Core Logic
-- =============================================================================

||| Check if proposal is in Active or Pending state
||| REQ_CANCEL_003: not executed, not cancelled, not approved
export
isActivePending : ProposalId -> IO Bool
isActivePending pid = do
  executed <- isFullyExecuted pid
  cancelled <- isProposalCancelled pid
  approved <- getApprovedHeaderId pid
  pure (not executed && not cancelled && approved == 0)

||| Cancel a proposal with all guards.
||| REQ_CANCEL_001: Author can cancel own proposal before voting ends
||| REQ_CANCEL_003: Only original author can cancel; revert otherwise
||| REQ_CANCEL_004: Emits ProposalCancelled event
||| REQ_CANCEL_005: Frees voting slot on cancel
export
cancelProposal : ProposalId -> IO Bool
cancelProposal pid = do
  callerAddr <- caller

  -- REQ_CANCEL_003: onlyAuthor guard
  author <- getProposalAuthor pid
  if callerAddr /= author
    then do
      -- revert: caller is not the proposal author
      revert 0 0
      pure False
    else do
      -- REQ_CANCEL_003: Check proposal is in Active or Pending state
      canCancel <- isActivePending pid
      if not canCancel
        then do
          revert 0 0
          pure False
        else do
          -- REQ_CANCEL_002: Transition to Cancelled state
          setProposalCancelled pid True

          -- REQ_CANCEL_005: Free voting slot
          freeSlot pid

          -- REQ_CANCEL_004: Emit ProposalCancelled(uint256 proposalId) event
          mstore 0 pid
          log1 0 32 EVENT_PROPOSAL_CANCELLED

          pure True

-- =============================================================================
-- Yul Codegen Template
-- =============================================================================

||| Generate Yul code for cancelProposal function body.
||| REQ_CANCEL_004: Includes ProposalCancelled event emission.
export
cancelProposalYul : String
cancelProposalYul = unlines
  [ "// cancelProposal(uint256) -> bool"
  , "// REQ_CANCEL_001: Author can cancel own proposal"
  , "// REQ_CANCEL_003: Only author can cancel; revert otherwise"
  , "// REQ_CANCEL_004: Emits ProposalCancelled(uint256)"
  , "function cancelProposal(pid) -> success {"
  , "    let callerAddr := caller()"
  , "    let metaSlot := getProposalMetaSlot(pid)"
  , ""
  , "    // REQ_CANCEL_003: onlyAuthor guard"
  , "    let author := sload(add(metaSlot, 8))"
  , "    if iszero(eq(callerAddr, author)) {"
  , "        revert(0, 0)"
  , "    }"
  , ""
  , "    // REQ_CANCEL_003: Check not already cancelled or executed"
  , "    let cancelled := sload(add(metaSlot, 9))"
  , "    if cancelled { revert(0, 0) }"
  , "    let executed := sload(add(metaSlot, 7))"
  , "    if executed { revert(0, 0) }"
  , "    let approved := sload(add(metaSlot, 5))"
  , "    if approved { revert(0, 0) }"
  , ""
  , "    // REQ_CANCEL_002: Set cancelled flag"
  , "    sstore(add(metaSlot, 9), 1)"
  , ""
  , "    // REQ_CANCEL_005: Free voting slot (set expiration to 0)"
  , "    sstore(add(metaSlot, 1), 0)"
  , ""
  , "    // REQ_CANCEL_004: Emit ProposalCancelled(uint256 proposalId)"
  , "    mstore(0, pid)"
  , "    log1(0, 32, 0xaabbccddee00112233445566778899aabbccddee00112233445566778899aabb)"
  , ""
  , "    success := 1"
  , "}"
  ]
