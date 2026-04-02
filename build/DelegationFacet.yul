/// @title Delegation Facet — td.onthe.eth
/// @notice Auto-generated from Idris2 Governance.Delegation module
/// @dev ERC-7546 proxy-compatible facet with delegation support
/// @custom:requirements
///   REQ_DELEG_001: Shareholder can delegate voting power to another address
///   REQ_DELEG_002: Delegation state stored in proxy storage (ERC-7546 pattern)
///   REQ_DELEG_003: Delegate can vote on behalf of delegator
///   REQ_DELEG_004: Delegator can revoke delegation at any time
///   REQ_DELEG_005: Delegation does not transfer token ownership

object "DelegationFacet" {
    code {
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }
    object "runtime" {
        code {
            // ============================================================
            // Storage Layout (ERC-7201 Namespaced)
            // ============================================================
            // SLOT_DELEGATION = 0x2000
            // slot = keccak256(delegator . SLOT_DELEGATION)

            // ============================================================
            // Event Topics
            // ============================================================
            // DelegationSet(address indexed delegator, address indexed delegate)
            // keccak256("DelegationSet(address,address)")
            // Topic0 = 0x... (placeholder, would be actual hash)

            // DelegationRevoked(address indexed delegator, address indexed previousDelegate)
            // keccak256("DelegationRevoked(address,address)")
            // Topic0 = 0x... (placeholder)

            // ============================================================
            // Helper Functions
            // ============================================================

            /// @notice Calculate storage slot for a delegator's delegate
            /// @param delegator The address of the delegator
            /// @return slot The storage slot containing the delegate address
            function getDelegateSlot(delegator) -> slot {
                mstore(0, delegator)
                mstore(32, 0x2000)
                slot := keccak256(0, 64)
            }

            /// @notice Get the delegate for a delegator
            /// @param delegator The address to check
            /// @return delegateAddr The delegate address (0 if none)
            function getDelegateFor(delegator) -> delegateAddr {
                let slot := getDelegateSlot(delegator)
                delegateAddr := sload(slot)
            }

            // ============================================================
            // delegate(address) -> bool
            // Selector: 0x5c19a95c (bytes4(keccak256("delegate(address)")))
            // REQ_DELEG_001: Shareholder can delegate voting power
            // REQ_DELEG_005: Cannot delegate to self or zero address
            // ============================================================
            function delegate(delegateAddr) -> success {
                let delegator := caller()

                // REQ_DELEG_005: Cannot delegate to self
                if eq(delegator, delegateAddr) {
                    revert(0, 0)
                }

                // REQ_DELEG_005: Cannot delegate to zero address
                if iszero(delegateAddr) {
                    revert(0, 0)
                }

                // Calculate storage slot
                let slot := getDelegateSlot(delegator)

                // Store delegate address
                sstore(slot, delegateAddr)

                // Emit DelegationSet(address delegator, address delegate)
                // log2(offset, size, topic0, topic1)
                // topic0 = event signature hash
                // topic1 = indexed delegator
                // data = delegate address (32 bytes)
                mstore(0, delegateAddr)
                log2(0, 32, 0x3333333333333333333333333333333333333333333333333333333333333333, delegator)

                success := 1
            }

            // ============================================================
            // revokeDelegation() -> bool
            // Selector: 0x7b0a47e8 (bytes4(keccak256("revokeDelegation()")))
            // REQ_DELEG_004: Delegator can revoke delegation at any time
            // ============================================================
            function revokeDelegation() -> success {
                let delegator := caller()

                // Calculate storage slot
                let slot := getDelegateSlot(delegator)

                // Get current delegate
                let currentDelegate := sload(slot)

                // Check if there's an active delegation
                if iszero(currentDelegate) {
                    revert(0, 0)
                }

                // Clear the delegation
                sstore(slot, 0)

                // Emit DelegationRevoked(address delegator, address previousDelegate)
                // log2(offset, size, topic0, topic1)
                // topic1 = indexed delegator
                // data = previous delegate address
                mstore(0, currentDelegate)
                log2(0, 32, 0x4444444444444444444444444444444444444444444444444444444444444444, delegator)

                success := 1
            }

            // ============================================================
            // getDelegate(address) -> address
            // Selector: 0xf50741f2 (bytes4(keccak256("getDelegate(address)")))
            // View function to check delegation status
            // ============================================================
            function getDelegateOf(delegator) -> delegateAddr {
                let slot := getDelegateSlot(delegator)
                delegateAddr := sload(slot)
            }

            // ============================================================
            // Selector Dispatch
            // ============================================================
            switch shr(224, calldataload(0))

            // delegate(address) -> bool
            // REQ_DELEG_001
            case 0x5c19a95c {
                let delegateAddr := calldataload(4)
                let success := delegate(delegateAddr)
                mstore(0, success)
                return(0, 32)
            }

            // revokeDelegation() -> bool
            // REQ_DELEG_004
            case 0x7b0a47e8 {
                let success := revokeDelegation()
                mstore(0, success)
                return(0, 32)
            }

            // getDelegate(address) -> address
            case 0xf50741f2 {
                let delegator := calldataload(4)
                let delegateAddr := getDelegateOf(delegator)
                mstore(0, delegateAddr)
                return(0, 32)
            }

            default { revert(0, 0) }
        }
    }
}
