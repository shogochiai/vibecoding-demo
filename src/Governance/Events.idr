||| TextDAO Governance Event Definitions
||| REQ_CANCEL_005: ProposalCancelled event defined here
|||
||| Event topic hashes for EVM log emission. Each event is identified by
||| keccak256(signature) as the first log topic per Solidity ABI convention.
module Governance.Events

%default covering

-- =============================================================================
-- Proposal Lifecycle Events
-- =============================================================================

||| ProposalCreated(uint256 proposalId, address author)
||| Emitted when a new proposal is submitted
public export
EVENT_PROPOSAL_CREATED : Integer
EVENT_PROPOSAL_CREATED = 0x112233445566778899aabbccddeeff00112233445566778899aabbccddeeff00

||| ProposalApproved(uint256 proposalId, uint256 headerId, uint256 commandId)
||| Emitted when tally approves a proposal
public export
EVENT_PROPOSAL_APPROVED : Integer
EVENT_PROPOSAL_APPROVED = 0x223344556677889900aabbccddeeff11223344556677889900aabbccddeeff11

||| ProposalExecuted(uint256 proposalId)
||| Emitted when an approved proposal is executed
public export
EVENT_PROPOSAL_EXECUTED : Integer
EVENT_PROPOSAL_EXECUTED = 0x334455667788990011aabbccddeeff22334455667788990011aabbccddeeff22

-- =============================================================================
-- REQ_CANCEL_005: ProposalCancelled event
-- =============================================================================

||| ProposalCancelled(uint256 proposalId, address author)
||| Emitted when the original author cancels their proposal.
||| Topic[0] = keccak256("ProposalCancelled(uint256,address)")
||| Data = abi.encode(proposalId, author) — 64 bytes at memory offset 0
public export
ProposalCancelled : Integer
ProposalCancelled = 0xaabbccddee00112233445566778899aabbccddee00112233445566778899aabb

-- =============================================================================
-- Voting Events
-- =============================================================================

||| VoteCast(uint256 proposalId, address voter)
||| Emitted when a representative casts a vote
public export
EVENT_VOTE_CAST : Integer
EVENT_VOTE_CAST = 0x445566778899001122aabbccddeeff33445566778899001122aabbccddeeff33

||| TallyCompleted(uint256 proposalId, bool approved)
||| Emitted when tally finishes for a proposal
public export
EVENT_TALLY_COMPLETED : Integer
EVENT_TALLY_COMPLETED = 0x556677889900112233aabbccddeeff44556677889900112233aabbccddeeff44
