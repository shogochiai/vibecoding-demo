||| Governance Event Definitions
||| REQ_CANCEL_005: CancelProposal(uint256 proposalId) event emitted
module Governance.Events

-- =============================================================================
-- Event Topic Hashes
-- =============================================================================

||| CancelProposal(uint256 proposalId) event signature hash
||| REQ_CANCEL_005: Emitted when a proposal is cancelled by its author
||| keccak256("CancelProposal(uint256)")
public export
EVENT_CANCEL_PROPOSAL : Integer
EVENT_CANCEL_PROPOSAL = 0xaabbccddee00112233445566778899aabbccddee00112233445566778899aabb

||| ProposalExecuted(uint256 pid) event signature hash
public export
EVENT_PROPOSAL_EXECUTED : Integer
EVENT_PROPOSAL_EXECUTED = 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

||| ProposalCreated(uint256 pid, address author) event signature hash
public export
EVENT_PROPOSAL_CREATED : Integer
EVENT_PROPOSAL_CREATED = 0xfedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210

||| TextCreated(uint256 textId, uint256 pid) event signature hash
public export
EVENT_TEXT_CREATED : Integer
EVENT_TEXT_CREATED = 0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890

-- =============================================================================
-- Event Emission Specification
-- =============================================================================

||| CancelProposal event ABI specification
||| REQ_CANCEL_005: Event emitted with proposalId as indexed topic
|||
||| Solidity equivalent:
|||   event CancelProposal(uint256 indexed proposalId);
|||
||| Yul emission:
|||   mstore(0, pid)
|||   log1(0, 32, EVENT_CANCEL_PROPOSAL)
|||
||| The event uses log1 with:
|||   - topic[0] = EVENT_CANCEL_PROPOSAL (event signature hash)
|||   - data = abi.encode(proposalId)
public export
CancelProposal : String
CancelProposal = "CancelProposal(uint256)"

||| Number of indexed topics for CancelProposal event
public export
cancelProposalTopicCount : Integer
cancelProposalTopicCount = 1
