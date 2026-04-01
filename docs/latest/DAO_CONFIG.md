# DAO Configuration — td.onthe.eth

## Canister IDs

| Service | Canister ID | Network |
|---------|-------------|---------|
| TextDAO | `xxxxx-xxxxx-cai` | ic-mainnet |
| mmnt | `xxxxx-xxxxx-cai` | ic-mainnet |

## Governance Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| quorum | 51% | Minimum voting participation for valid tally |
| tally_interval | 7 days | Time between consecutive Tally rounds |
| fork_deadline | 14 days | Maximum time for Fork submissions per round |
| max_active_forks | 3 | Number of Forks surviving each Tally |

## Treasury

| Field | Value |
|-------|-------|
| treasury_address | `0x...` (placeholder) |
| cycles_threshold | 1,000,000,000 cycles |
| cycles_refill_from | treasury (DAO treasury → CMC → cycles) |

## Auto-Proposals

Colony automatically generates CycleTopUp proposals when canister cycles
fall below `cycles_threshold`. This ensures continuous operation without
manual intervention.

## ENS Resolution

ENS name: `td.onthe.eth`
Resolve via: `etherclaw resolve td.onthe.eth`
