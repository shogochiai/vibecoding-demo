/// @title DelegationView Facet — td.onthe.eth
/// @notice REQ_DELEG_004: Delegation view functions (query delegate and voting power)
/// @dev Generated from Idris2 via idris2-evm codegen. ERC-7546 facet.
object "DelegationView" {
    code {
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }
    object "runtime" {
        code {
            // Storage slot constants (td.delegation.v1 namespace)
            let DELEGATION_SLOT := 0x44656c65676174696f6e2e763100000000000000000000000000000000000000
            let DELEGATION_SLOT_DELEGATEE := DELEGATION_SLOT
            let DELEGATION_SLOT_VOTING_POWER := add(DELEGATION_SLOT, 1)

            // Function selector dispatch
            switch shr(224, calldataload(0))

            // getDelegate(address) -> address
            // REQ_DELEG_004: Query delegation state on-chain
            case 0xb5b3ca2c {
                let addr := calldataload(4)

                // Look up delegatee for this address
                mstore(0, addr)
                mstore(32, DELEGATION_SLOT_DELEGATEE)
                let delegateeSlot := keccak256(0, 64)
                let delegatee := sload(delegateeSlot)

                // mstore address: Return address (right-aligned in 32 bytes)
                mstore(0, delegatee)
                return(0, 32)
            }

            // getVotingPower(address) -> uint256
            // REQ_DELEG_004: Query accumulated voting power on-chain
            case 0x7ed4b27c {
                let addr := calldataload(4)

                // Look up accumulated voting power
                mstore(0, addr)
                mstore(32, DELEGATION_SLOT_VOTING_POWER)
                let vpSlot := keccak256(0, 64)
                let power := sload(vpSlot)

                // mstore uint256: Return accumulated voting power
                mstore(0, power)
                return(0, 32)
            }

            // Fallback: revert for unknown selectors
            default {
                revert(0, 0)
            }
        }
    }
}
