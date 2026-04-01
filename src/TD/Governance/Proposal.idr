||| TD Governance Proposal State Machine
||| REQ_CANCEL_002 — ProposalStatus ADT includes Cancelled state
|||
||| Defines the proposal lifecycle states and storage layout for td governance.
||| Based on TextDAO.Storages.Schema with Cancelled state addition.
module TD.Governance.Proposal

import public Data.Vect
import public Subcontract.Core.Storable
import public Subcontract.Core.Schema

%default covering

-- =============================================================================
-- Type Aliases
-- =============================================================================

||| Ethereum address (20 bytes, stored as Integer)
public export
EvmAddr : Type
EvmAddr = Integer

||| Proposal ID
public export
ProposalId : Type
ProposalId = Integer

||| Header ID within a proposal
public export
HeaderId : Type
HeaderId = Integer

||| Command ID within a proposal
public export
CommandId : Type
CommandId = Integer

||| Timestamp (Unix epoch seconds)
public export
Timestamp : Type
Timestamp = Integer

||| IPFS Content Identifier
public export
MetadataCid : Type
MetadataCid = Integer

-- =============================================================================
-- ProposalStatus ADT
-- =============================================================================

||| Lifecycle states of a governance proposal.
||| REQ_CANCEL_002: Cancelled constructor added for author-initiated withdrawal.
public export
data ProposalStatus
  = Active        -- Proposal is open for voting
  | Passed        -- Proposal passed tally (approved header + command)
  | Failed        -- Proposal expired without reaching quorum / approval
  | Cancelled     -- Author withdrew proposal before voting ended

||| Convert ProposalStatus to on-chain integer representation
public export
proposalStatusToInt : ProposalStatus -> Integer
proposalStatusToInt Active    = 0
proposalStatusToInt Passed    = 1
proposalStatusToInt Failed    = 2
proposalStatusToInt Cancelled = 3

||| Decode on-chain integer to ProposalStatus
public export
intToProposalStatus : Integer -> ProposalStatus
intToProposalStatus 1 = Passed
intToProposalStatus 2 = Failed
intToProposalStatus 3 = Cancelled
intToProposalStatus _ = Active

-- =============================================================================
-- Storage Slot Layout (ERC-7201 Namespaced)
-- =============================================================================

||| Base storage slot for Deliberation
export
SLOT_DELIBERATION : Integer
SLOT_DELIBERATION = 0x1000

||| Storage slot for proposal count
export
SLOT_PROPOSAL_COUNT : Integer
SLOT_PROPOSAL_COUNT = 0x1001

||| Base storage slot for Members
export
SLOT_MEMBERS : Integer
SLOT_MEMBERS = 0x3000

||| Storage slot for member count
export
SLOT_MEMBER_COUNT : Integer
SLOT_MEMBER_COUNT = 0x3001

-- =============================================================================
-- Deliberation Config Slots
-- =============================================================================

export
SLOT_CONFIG_EXPIRY_DURATION : Integer
SLOT_CONFIG_EXPIRY_DURATION = 0x1100

export
SLOT_CONFIG_SNAP_INTERVAL : Integer
SLOT_CONFIG_SNAP_INTERVAL = 0x1101

export
SLOT_CONFIG_REPS_NUM : Integer
SLOT_CONFIG_REPS_NUM = 0x1102

export
SLOT_CONFIG_QUORUM_SCORE : Integer
SLOT_CONFIG_QUORUM_SCORE = 0x1103

-- =============================================================================
-- Proposal Meta Field Offsets
-- =============================================================================

export
META_OFFSET_CREATED_AT : Integer
META_OFFSET_CREATED_AT = 0

export
META_OFFSET_EXPIRATION : Integer
META_OFFSET_EXPIRATION = 1

export
META_OFFSET_SNAP_INTERVAL : Integer
META_OFFSET_SNAP_INTERVAL = 2

export
META_OFFSET_HEADER_COUNT : Integer
META_OFFSET_HEADER_COUNT = 3

export
META_OFFSET_CMD_COUNT : Integer
META_OFFSET_CMD_COUNT = 4

export
META_OFFSET_APPROVED_HEADER : Integer
META_OFFSET_APPROVED_HEADER = 5

export
META_OFFSET_APPROVED_CMD : Integer
META_OFFSET_APPROVED_CMD = 6

export
META_OFFSET_EXECUTED : Integer
META_OFFSET_EXECUTED = 7

||| Offset for proposal author address
export
META_OFFSET_AUTHOR : Integer
META_OFFSET_AUTHOR = 8

||| Offset for cancelled flag
||| REQ_CANCEL_002: Cancelled state stored at offset 9
export
META_OFFSET_CANCELLED : Integer
META_OFFSET_CANCELLED = 9

-- =============================================================================
-- Storage Slot Calculation Helpers
-- =============================================================================

||| Calculate storage slot for proposal by ID
export
getProposalSlot : ProposalId -> IO Integer
getProposalSlot pid = do
  mstore 0 pid
  mstore 32 SLOT_DELIBERATION
  keccak256 0 64

||| Calculate storage slot for proposal's meta
export
getProposalMetaSlot : ProposalId -> IO Integer
getProposalMetaSlot pid = do
  baseSlot <- getProposalSlot pid
  pure (baseSlot + 0x30)

||| Calculate storage slot for proposal's header array
export
getProposalHeadersSlot : ProposalId -> IO Integer
getProposalHeadersSlot pid = do
  baseSlot <- getProposalSlot pid
  pure (baseSlot + 0x10)

||| Calculate storage slot for specific header
export
getHeaderSlot : ProposalId -> HeaderId -> IO Integer
getHeaderSlot pid hid = do
  headersSlot <- getProposalHeadersSlot pid
  mstore 0 hid
  mstore 32 headersSlot
  keccak256 0 64

||| Calculate storage slot for proposal's command array
export
getProposalCommandsSlot : ProposalId -> IO Integer
getProposalCommandsSlot pid = do
  baseSlot <- getProposalSlot pid
  pure (baseSlot + 0x20)

-- =============================================================================
-- Storage Read/Write Helpers
-- =============================================================================

export
getProposalCount : IO Integer
getProposalCount = sload SLOT_PROPOSAL_COUNT

export
setProposalCount : Integer -> IO ()
setProposalCount = sstore SLOT_PROPOSAL_COUNT

export
getMemberCount : IO Integer
getMemberCount = sload SLOT_MEMBER_COUNT

export
setMemberCount : Integer -> IO ()
setMemberCount = sstore SLOT_MEMBER_COUNT

export
getExpiryDuration : IO Integer
getExpiryDuration = sload SLOT_CONFIG_EXPIRY_DURATION

export
setExpiryDuration : Integer -> IO ()
setExpiryDuration = sstore SLOT_CONFIG_EXPIRY_DURATION

export
getSnapInterval : IO Integer
getSnapInterval = sload SLOT_CONFIG_SNAP_INTERVAL

export
getRepsNum : IO Integer
getRepsNum = sload SLOT_CONFIG_REPS_NUM

export
getQuorumScore : IO Integer
getQuorumScore = sload SLOT_CONFIG_QUORUM_SCORE

-- =============================================================================
-- Proposal Meta Read/Write
-- =============================================================================

export
getProposalCreatedAt : ProposalId -> IO Timestamp
getProposalCreatedAt pid = do
  metaSlot <- getProposalMetaSlot pid
  sload (metaSlot + META_OFFSET_CREATED_AT)

export
setProposalCreatedAt : ProposalId -> Timestamp -> IO ()
setProposalCreatedAt pid ts = do
  metaSlot <- getProposalMetaSlot pid
  sstore (metaSlot + META_OFFSET_CREATED_AT) ts

export
getProposalExpiration : ProposalId -> IO Timestamp
getProposalExpiration pid = do
  metaSlot <- getProposalMetaSlot pid
  sload (metaSlot + META_OFFSET_EXPIRATION)

export
setProposalExpiration : ProposalId -> Timestamp -> IO ()
setProposalExpiration pid ts = do
  metaSlot <- getProposalMetaSlot pid
  sstore (metaSlot + META_OFFSET_EXPIRATION) ts

export
getProposalHeaderCount : ProposalId -> IO Integer
getProposalHeaderCount pid = do
  metaSlot <- getProposalMetaSlot pid
  sload (metaSlot + META_OFFSET_HEADER_COUNT)

export
setProposalHeaderCount : ProposalId -> Integer -> IO ()
setProposalHeaderCount pid count = do
  metaSlot <- getProposalMetaSlot pid
  sstore (metaSlot + META_OFFSET_HEADER_COUNT) count

export
getProposalCmdCount : ProposalId -> IO Integer
getProposalCmdCount pid = do
  metaSlot <- getProposalMetaSlot pid
  sload (metaSlot + META_OFFSET_CMD_COUNT)

export
setProposalCmdCount : ProposalId -> Integer -> IO ()
setProposalCmdCount pid count = do
  metaSlot <- getProposalMetaSlot pid
  sstore (metaSlot + META_OFFSET_CMD_COUNT) count

export
getApprovedHeaderId : ProposalId -> IO HeaderId
getApprovedHeaderId pid = do
  metaSlot <- getProposalMetaSlot pid
  sload (metaSlot + META_OFFSET_APPROVED_HEADER)

export
setApprovedHeaderId : ProposalId -> HeaderId -> IO ()
setApprovedHeaderId pid hid = do
  metaSlot <- getProposalMetaSlot pid
  sstore (metaSlot + META_OFFSET_APPROVED_HEADER) hid

export
getApprovedCmdId : ProposalId -> IO CommandId
getApprovedCmdId pid = do
  metaSlot <- getProposalMetaSlot pid
  sload (metaSlot + META_OFFSET_APPROVED_CMD)

export
setApprovedCmdId : ProposalId -> CommandId -> IO ()
setApprovedCmdId pid cid = do
  metaSlot <- getProposalMetaSlot pid
  sstore (metaSlot + META_OFFSET_APPROVED_CMD) cid

export
isFullyExecuted : ProposalId -> IO Bool
isFullyExecuted pid = do
  metaSlot <- getProposalMetaSlot pid
  val <- sload (metaSlot + META_OFFSET_EXECUTED)
  pure (val == 1)

export
setFullyExecuted : ProposalId -> Bool -> IO ()
setFullyExecuted pid executed = do
  metaSlot <- getProposalMetaSlot pid
  sstore (metaSlot + META_OFFSET_EXECUTED) (if executed then 1 else 0)

||| Get proposal author address
export
getProposalAuthor : ProposalId -> IO EvmAddr
getProposalAuthor pid = do
  metaSlot <- getProposalMetaSlot pid
  sload (metaSlot + META_OFFSET_AUTHOR)

||| Set proposal author address
export
setProposalAuthor : ProposalId -> EvmAddr -> IO ()
setProposalAuthor pid author = do
  metaSlot <- getProposalMetaSlot pid
  sstore (metaSlot + META_OFFSET_AUTHOR) author

||| Check if proposal is cancelled
||| REQ_CANCEL_002: Cancelled state check
export
isProposalCancelled : ProposalId -> IO Bool
isProposalCancelled pid = do
  metaSlot <- getProposalMetaSlot pid
  val <- sload (metaSlot + META_OFFSET_CANCELLED)
  pure (val == 1)

||| Set cancelled flag
||| REQ_CANCEL_002: Transition proposal to Cancelled state
export
setProposalCancelled : ProposalId -> Bool -> IO ()
setProposalCancelled pid cancelled = do
  metaSlot <- getProposalMetaSlot pid
  sstore (metaSlot + META_OFFSET_CANCELLED) (if cancelled then 1 else 0)

-- =============================================================================
-- Representative Storage
-- =============================================================================

export
getRepSlot : ProposalId -> Integer -> IO Integer
getRepSlot pid index = do
  metaSlot <- getProposalMetaSlot pid
  let repsBaseSlot = metaSlot + 0x40
  mstore 0 index
  mstore 32 repsBaseSlot
  keccak256 0 64

export
getRepCount : ProposalId -> IO Integer
getRepCount pid = do
  metaSlot <- getProposalMetaSlot pid
  sload (metaSlot + 0x40)

export
setRepCount : ProposalId -> Integer -> IO ()
setRepCount pid count = do
  metaSlot <- getProposalMetaSlot pid
  sstore (metaSlot + 0x40) count

export
getRepAddr : ProposalId -> Integer -> IO EvmAddr
getRepAddr pid index = do
  slot <- getRepSlot pid index
  sload slot

export
addRep : ProposalId -> EvmAddr -> IO ()
addRep pid addr = do
  count <- getRepCount pid
  slot <- getRepSlot pid count
  sstore slot addr
  setRepCount pid (count + 1)

export
getMemberSlot : Integer -> IO Integer
getMemberSlot index = do
  mstore 0 index
  mstore 32 SLOT_MEMBERS
  keccak256 0 64

-- =============================================================================
-- Proposal Approval Helper
-- =============================================================================

export
approveProposal : ProposalId -> HeaderId -> CommandId -> IO ()
approveProposal pid headerId cmdId = do
  setApprovedHeaderId pid headerId
  setApprovedCmdId pid cmdId
