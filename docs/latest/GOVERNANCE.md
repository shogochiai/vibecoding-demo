# Governance — td.onthe.eth

## Proposal Types

TextDAO (G_token) uses Fork / Borda Rule as a general-purpose voting engine.
Each Proposal has a single purpose. Forks are alternative expressions of the same purpose.

| Type | Description | Finalize Hook |
|------|-------------|---------------|
| **IPAdoption** | Adopt an IP document | `finalize_ip` callback → IP status = final → Colony TaskTree generation |
| **TokenTransfer** | Treasury transfer (EVM or ICP ledger) | Execute EVM/ICP transfer |
| **CycleTopUp** | Canister cycles replenishment | CMC-mediated cycles top-up |
| **ParameterChange** | Governance parameter update | Update canister parameters (quorum, deadline, etc.) |

## Fork Cycle (Borda Rule)

The Fork cycle is the core deliberation mechanism:

1. **Proposal Creation** — Declare a single purpose
2. **Fork Submission** — Anyone can submit alternative implementations (Forks) for the same purpose
3. **Tally (Borda Rule)** — Top 3 Forks remain Active; others are eliminated
4. **Iterate** — New Forks can be submitted against Active set → next Tally
5. **Refinement** — Repeat until convergence
6. **Finalize** — Winner Fork triggers its type-specific execution hook

### Finalize Execution Hooks

| Proposal Type | Hook | Effect |
|---------------|------|--------|
| IPAdoption | `finalize_ip` | IP status → final; Colony generates TaskTree from finalized IP |
| TokenTransfer | `execute_transfer` | EVM or ICP ledger transfer executed |
| CycleTopUp | `execute_topup` | ICP → cycles via CMC (Cycle Minting Canister) |
| ParameterChange | `apply_param` | Canister parameter updated on-chain |

## Roles

- **Shareholder** — Holds G_token, votes on Proposals
- **Colony** — Autonomous agent executing finalized IPs as TaskTrees
- **Reviewer** — Reviews Colony submissions (PRs)
- **Auditor** — Verifies reproducible builds, votes on upgrade proposals

## TextDAO Canister

- Canister ID: `xxxxx-xxxxx-cai` (placeholder — replace after deployment)
- Voting engine: Borda Rule with Fork cycle
- Quorum: 51% (configurable via ParameterChange proposal)
