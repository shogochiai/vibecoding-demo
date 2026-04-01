/// @title TD Governance — cancelProposal facet
/// @notice Auto-generated from Idris2 Governance modules
/// @dev ERC-7546 proxy-compatible facet with cancelProposal support

object "Governance" {
    code {
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }
    object "runtime" {
        code {
            // ============================================================
            // Storage Layout (ERC-7201 Namespaced)
            // ============================================================
            // SLOT_DELIBERATION     = 0x1000
            // SLOT_PROPOSAL_COUNT   = 0x1001
            // META_OFFSET_AUTHOR    = 8
            // META_OFFSET_CANCELLED = 9
            // META_OFFSET_EXECUTED  = 7
            // META_OFFSET_EXPIRATION = 1
            // META_OFFSET_APPROVED_HEADER = 5

            // ============================================================
            // Helper Functions
            // ============================================================

            function getProposalMetaSlot(pid) -> slot {
                mstore(0, pid)
                mstore(32, 0x1000)
                slot := add(keccak256(0, 64), 0x30)
            }

            // ============================================================
            // cancelProposal(uint256) -> bool
            // REQ_CANCEL_001: Author can cancel own proposal
            // REQ_CANCEL_003: Only author can cancel; revert otherwise
            // REQ_CANCEL_004: Emits ProposalCancelled(uint256)
            // REQ_CANCEL_005: Frees voting slot
            // ============================================================
            function cancelProposal(pid) -> success {
                let callerAddr := caller()
                let metaSlot := getProposalMetaSlot(pid)

                // REQ_CANCEL_003: onlyAuthor guard
                let author := sload(add(metaSlot, 8))
                if iszero(eq(callerAddr, author)) {
                    revert(0, 0)
                }

                // REQ_CANCEL_003: Check not already cancelled or executed
                let cancelled := sload(add(metaSlot, 9))
                if cancelled { revert(0, 0) }
                let executed := sload(add(metaSlot, 7))
                if executed { revert(0, 0) }
                let approved := sload(add(metaSlot, 5))
                if approved { revert(0, 0) }

                // REQ_CANCEL_002: Set cancelled flag
                sstore(add(metaSlot, 9), 1)

                // REQ_CANCEL_005: Free voting slot (set expiration to 0)
                sstore(add(metaSlot, 1), 0)

                // REQ_CANCEL_004: Emit ProposalCancelled(uint256 proposalId)
                mstore(0, pid)
                log1(0, 32, 0xaabbccddee00112233445566778899aabbccddee00112233445566778899aabb)

                success := 1
            }

            // ============================================================
            // Selector Dispatch
            // ============================================================
            switch shr(224, calldataload(0))

            // cancelProposal(uint256) -> bool
            case 0xd8e780df {
                let pid := calldataload(4)
                let success := cancelProposal(pid)
                mstore(0, success)
                return(0, 32)
            }

            // tally(uint256)
            case 0x67890123 {
                let pid := calldataload(4)
                // tally implementation placeholder
                return(0, 0)
            }

            // tallyAndExecute(uint256) -> bool
            case 0x90123456 {
                let pid := calldataload(4)
                // tallyAndExecute implementation placeholder
                mstore(0, 0)
                return(0, 32)
            }

            default { revert(0, 0) }
        }
    }
}
