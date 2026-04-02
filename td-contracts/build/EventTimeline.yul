/// @title Governance Event Timeline — Read-only View Function
/// @notice Generated from Governance.EventTimeline (idris2-evm Yul codegen)
/// @dev ERC-7546 compatible: read-only, pure logic implementation (no storage writes)
/// Selector: getProposalTimeline(uint256) = 0xdc9cc645

object "EventTimeline" {
    code {
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }
    object "runtime" {
        code {
            // ============================================================
            // Dispatcher
            // ============================================================
            let selector := shr(224, calldataload(0))

            switch selector
            case 0xdc9cc645 /* getProposalTimeline(uint256) */ {
                let proposalId := calldataload(4)
                getProposalTimeline(proposalId)
            }
            default {
                revert(0, 0)
            }

            // ============================================================
            // REQ_GEVT_001 — Storage Layout Constants
            // ============================================================
            // EventSlot = keccak256("governance.events.timeline") truncated
            // 0x47f8b08c2e5aa3cd7df8e5988e2cb00bfe3a1e5d7ce6d3eaa2b0f6c8d4a917e3

            // ============================================================
            // REQ_GEVT_002 — getProposalTimeline(uint256) view
            // Returns: (uint8 eventType, uint256 timestamp)[]
            // ABI: offset | length | (type_0, ts_0) | (type_1, ts_1) | ...
            // ============================================================
            function getProposalTimeline(proposalId) {
                let baseSlot := computeEventBase(proposalId)
                let count := sload(baseSlot)

                // ABI encode dynamic array of tuples
                let memPtr := 0x80

                // Offset to array data (0x20 = one word)
                mstore(memPtr, 0x20)
                // Array length
                mstore(add(memPtr, 0x20), count)

                // Encode each (eventType, timestamp) tuple
                let dataPtr := add(memPtr, 0x40)
                for { let i := 0 } lt(i, count) { i := add(i, 1) }
                {
                    let typeSlot := add(add(baseSlot, 1), mul(i, 2))
                    let tsSlot := add(typeSlot, 1)

                    let evtType := sload(typeSlot)
                    let ts := sload(tsSlot)

                    mstore(dataPtr, evtType)
                    mstore(add(dataPtr, 0x20), ts)

                    dataPtr := add(dataPtr, 0x40)
                }

                // Return: offset(0x20) + length(0x20) + count * 0x40
                let totalSize := add(0x40, mul(count, 0x40))
                return(memPtr, totalSize)
            }

            // ============================================================
            // Storage Helpers
            // ============================================================

            /// @dev Compute storage base slot for proposal's event array
            /// keccak256(abi.encode(proposalId, EventSlot))
            function computeEventBase(proposalId) -> base {
                mstore(0x00, proposalId)
                mstore(0x20, 0x47f8b08c2e5aa3cd7df8e5988e2cb00bfe3a1e5d7ce6d3eaa2b0f6c8d4a917e3)
                base := keccak256(0x00, 0x40)
            }
        }
    }
}
