# 1. Intro & Goal

**Title:** td CLI Auto-Generation

**Goal:** Generate a complete CLI tool that exposes all td on-chain functions
as local commands, packaged as `pkgs/Idris2TextDaoCli` (family=core) in the monorepo.

# 2. Concept / Value Proposition

Interacting with td currently requires raw `cast call` / `dfx` invocations
with manually encoded calldata. A dedicated CLI removes this friction, letting
shareholders and colony operators propose, vote, tally, and query proposals with
simple commands. The CLI is auto-generated from the ABI / can.did definitions,
ensuring it stays in sync with the contract.

# 3. Product Vision

- Auto-generated CLI from on-chain ABI and can.did definitions
- Downloadable via `curl` from GitHub Releases
- Includes `swap` command added by Scene A (AMM integration)
- Future: `textdao completions` for shell auto-complete

# 4. Who's it for?

- **Shareholders** who want to propose and vote without raw calldata
- **Colony operators** who script governance actions
- **Reviewers** who need quick status checks on proposals

# 5. Why build it?

`cast call` with ABI-encoded arguments is error-prone and undiscoverable.
A typed CLI catches argument errors at parse time, provides `--help` for each
subcommand, and integrates with `etherclaw flow` for pipeline visibility.
Release via `gh release` makes the binary accessible without building from source.

---

# 6. What is it?

## Package

- **Location:** `pkgs/Idris2TextDaoCli` (monorepo)
- **Family:** `core` (pure Idris2 CLI, built with `pack`)
- **ETHERCLAW.toml entry:**
  ```toml
  [[lazy]]
  target     = "pkgs/Idris2TextDaoCli"
  family     = "core"
  step3_sync = false
  ```

## Commands

| Command | Description |
|---------|------------|
| `textdao propose <title> <body>` | Submit a new governance proposal |
| `textdao vote <proposalId> <yes\|no>` | Cast vote on a proposal |
| `textdao tally <proposalId>` | Trigger tally for a proposal |
| `textdao getProposal <proposalId>` | Query proposal details and status |
| `textdao swap <tokenIn> <tokenOut> <amount> <minOut>` | AMM swap via Uniswap V3 (Scene A) |
| `textdao status` | Show contract info, owner, implementation address |

## User Types

| Type | Description |
|------|-------------|
| Shareholder | Uses propose, vote, getProposal, status |
| Colony | Uses all commands in automated pipelines |
| Reviewer | Uses getProposal, status for verification |

# 7. Brainstormed Ideas

- Generate CLI from ABI JSON (EVM) and can.did (ICP) with shared argument parser
- Include `--rpc-url` and `--chain-id` flags for multi-chain support
- `textdao abi` subcommand to dump the contract ABI for debugging

# 8. Competitors & Product Inspiration

- Foundry `cast`: powerful but generic, no project-specific subcommands
- Hardhat tasks: JS-based, requires Node runtime
- `dfx`: ICP-native but no EVM support

# 11. Tech Notes

## Build & Release Pipeline

1. Colony implements CLI source in `pkgs/Idris2TextDaoCli/`
2. `pack build` compiles to native binary
3. `gh release create v<version> --attach build/exec/textdao` publishes release
4. Users install: `curl -L https://github.com/<owner>/<repo>/releases/latest/download/textdao -o textdao && chmod +x textdao`
5. `registerVerification` records binary SHA256 hash on TheWorld

## Implementation Path

- Parse ABI JSON to extract function signatures and argument types
- Generate Idris2 CLI module per function (propose.idr, vote.idr, etc.)
- Main dispatcher: `textdao <subcommand> [args...]`
- EVM calls via `cast send` / `cast call` subprocess
- Release execution: `cmdReleaseExecute family=core` (Queue.idr)
