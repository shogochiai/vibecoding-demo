/// @title RevokeDelegation Facet — td.onthe.eth
/// @notice REQ_DELEG_003: revokeDelegation() — delegator can revoke delegation at any time
/// @dev Generated from Idris2 via idris2-evm codegen. ERC-7546 facet.
object "RevokeDelegation" {
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
            let DELEGATION_SLOT_BASE_POWER := add(DELEGATION_SLOT, 2)

            // Function selector dispatch
            switch shr(224, calldataload(0))

            // revokeDelegation() -> bool
            // REQ_DELEG_003: Delegator can revoke delegation at any time
            case 0xa7713a70 {
                let delegator := caller()

                // Get current delegatee
                mstore(0, delegator)
                mstore(32, DELEGATION_SLOT_DELEGATEE)
                let delegateeSlot := keccak256(0, 64)
                let currentDelegatee := sload(delegateeSlot)

                // require: must have active delegation (noDelegation revert)
                if iszero(currentDelegatee) {
                    // revert with "noDelegation" error
                    mstore(0, 0x6e6f44656c65676174696f6e0000000000000000000000000000000000000000)
                    revert(0, 32)
                }

                // Get delegator's base power
                mstore(0, delegator)
                mstore(32, DELEGATION_SLOT_BASE_POWER)
                let basePowerSlot := keccak256(0, 64)
                let basePower := sload(basePowerSlot)

                // removeVotingPower: subtract delegator's power from delegatee
                mstore(0, currentDelegatee)
                mstore(32, DELEGATION_SLOT_VOTING_POWER)
                let vpSlot := keccak256(0, 64)
                let currentVp := sload(vpSlot)
                let newVp := 0
                if gt(currentVp, basePower) {
                    newVp := sub(currentVp, basePower)
                }
                sstore(vpSlot, newVp)

                // Clear delegation: delegator -> 0x0
                sstore(delegateeSlot, 0)

                // Emit DelegateRevoked(delegator, previousDelegatee, votingPower)
                mstore(0, delegator)
                mstore(32, currentDelegatee)
                mstore(64, basePower)
                log1(0, 96, 0x9b1a5d82f45e4aa0cf9b5c3b1a4c0b6e2d8f7a3e6c9d0b4a7f2e5d8c1b3a6f90)

                // Return true
                mstore(0, 1)
                return(0, 32)
            }

            // Fallback: revert for unknown selectors
            default {
                revert(0, 0)
            }
        }
    }
}
