/// @title Delegation Facet — td.onthe.eth
/// @notice REQ_DELEG_001: delegate(address) and REQ_DELEG_002: voting power accumulation
/// @dev Generated from Idris2 via idris2-evm codegen. ERC-7546 facet.
object "Delegation" {
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

            // delegate(address) -> bool
            // REQ_DELEG_001: Shareholder can delegate voting power to another address
            case 0x5c19a95c {
                let delegatee := calldataload(4)
                let delegator := caller()

                // Guard: cannot delegate to zero address
                if iszero(delegatee) {
                    revert(0, 0)
                }

                // Guard: cannot delegate to self
                if eq(delegator, delegatee) {
                    revert(0, 0)
                }

                // Calculate delegatee slot for delegator
                mstore(0, delegator)
                mstore(32, DELEGATION_SLOT_DELEGATEE)
                let delegateeSlot := keccak256(0, 64)

                // Check existing delegation
                let currentDelegatee := sload(delegateeSlot)

                // Get delegator's base power
                mstore(0, delegator)
                mstore(32, DELEGATION_SLOT_BASE_POWER)
                let basePowerSlot := keccak256(0, 64)
                let basePower := sload(basePowerSlot)

                // Initialize base power if zero
                if iszero(basePower) {
                    mstore(0, delegator)
                    mstore(32, DELEGATION_SLOT_VOTING_POWER)
                    let vpSlot := keccak256(0, 64)
                    let vp := sload(vpSlot)
                    basePower := vp
                    if iszero(basePower) {
                        basePower := 1
                    }
                    sstore(basePowerSlot, basePower)
                }

                // Revoke existing delegation if any
                if currentDelegatee {
                    // removeVotingPower from old delegatee
                    mstore(0, currentDelegatee)
                    mstore(32, DELEGATION_SLOT_VOTING_POWER)
                    let oldVpSlot := keccak256(0, 64)
                    let oldVp := sload(oldVpSlot)
                    let newOldVp := 0
                    if gt(oldVp, basePower) {
                        newOldVp := sub(oldVp, basePower)
                    }
                    sstore(oldVpSlot, newOldVp)
                }

                // Set new delegation: delegator -> delegatee
                sstore(delegateeSlot, delegatee)

                // REQ_DELEG_002: addVotingPower — accumulate delegator's power to delegatee
                mstore(0, delegatee)
                mstore(32, DELEGATION_SLOT_VOTING_POWER)
                let newVpSlot := keccak256(0, 64)
                let currentVp := sload(newVpSlot)
                sstore(newVpSlot, add(currentVp, basePower))

                // Emit DelegateChanged(delegator, delegatee, votingPower)
                mstore(0, delegator)
                mstore(32, delegatee)
                mstore(64, basePower)
                log1(0, 96, 0x3134e8a2e6d97e929a7e54011ea5485d7d196dd5f0ba4d4ef95803e8e3fc257f)

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
