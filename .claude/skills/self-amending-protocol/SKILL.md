---
name: self-amending-protocol
description: ERC-7546 (UCS) + TheWorld multi-chain self-amending smart contract architecture with InstanceFactory and Colony server
triggers:
  - Self-Amending Protocol
  - ERC-7546
  - UCS
  - TheWorld
  - InstanceFactory
  - Colony
  - idris2-subcontract
  - idris2-ouc
  - Proxy Dictionary
  - upgrade proposal
---

# Self-Amending Protocol

## Architecture Overview

```
ERC-7546 Contract (EVM - Base Mainnet etc.)
    |
InstanceFactory (EVM) -- deployed per chain by Colony server
    | CREATE2
OU (Upgradeable Object, EVM) -- per-user upgrader instance
    |
TheWorld (Onchain Upgrade Controller, ICP canister) -- governance
    |
Colony Server (this machine) -- operational executor
```

## Colony Flow

1. **TheWorld** decides "deploy InstanceFactory to chain X" through governance (propose -> vote -> approve)
2. **Colony server** watches TheWorld for approved proposals, executes `cast send --create` on target chain
3. **Colony server** reports deployed InstanceFactory address back to TheWorld
4. **New EVM chain**: Someone proposes on TheWorld, governance approves, Colony executes

## Key Components

| Component | Repository | Role |
|-----------|-----------|------|
| ERC-7546 Contract | idris2-subcontract | Proxy + Dictionary pattern, upgradeable |
| OU (Upgradeable Object) | idris2-yul/examples/OU.idr | Upgrade proposal management |
| InstanceFactory | idris2-yul/examples/OUF.idr | Factory for OU clones via CREATE2 |
| TheWorld Auditor | idris2-ouc | Proposal review, approval management (ICP) |

## ERC-7546 Pattern (idris2-subcontract)

- **Proxy**: DELEGATECALL to Dictionary
- **Dictionary**: selector -> implementation address mapping
- **Functions**: Stateless implementations, registered in Dictionary

```idris
-- Functions/<Feature>/<Feature>.idr
module MyContract.Functions.Core.Core
import MyContract.Storages.Schema

initialize : Integer -> MyContractState -> Maybe MyContractState
```

## Project Structure (idris2-textdao reference)

```
src/<Name>/
  Functions/
    Core/{Core.idr, SPEC.toml, Tests/CoreTest.idr}
    <Feature>/{...}
  Storages/Schema.idr
  Security/{Reentrancy.idr, AccessControl.idr}
  Tests/AllTests.idr
SPEC.toml
CLAUDE.md
pack.toml
```

## TheWorld Integration Flow

1. Deploy ERC-7546 Contract to EVM
2. Register with InstanceFactory
3. Send upgrade proposal to TheWorld Auditor
4. Auditor approves (multi-sig)
5. Execute Dictionary update on EVM

**HTTPS Outcall** for EVM <-> IC cross-chain communication.

## Project Initialization

```bash
# ERC-7546 Contract (EVM)
lazy evm init ~/code/my-subcontract
cd ~/code/my-subcontract
pack build mysubcontract

# IC Canister (TheWorld integration)
lazy dfx init ~/code/my-canister
```

## Deployed Contracts

### TheWorld (ICP Mainnet)
- **Canister ID**: `nrkou-hqaaa-aaaah-qq6qa-cai`

### InstanceFactory (Base Mainnet, Chain ID 8453)

| Version | Contract Address | Status |
|---------|------------------|--------|
| v8 | `0xb094b55924a790c4c9f86e16beb93d1261ed9891` | Active |
| v7 | `0x58abBd4b6dF53f3DDb335Ac45437a467c854Ad1d` | Deprecated |

### Legacy Test Contracts (Deprecated)
| Contract | Address | Note |
|----------|---------|------|
| Counter | 0x4884e7a3af7c346e125acf4b480d7000c4172703 | Test contract |
| OU | 0xe9cb7cdeb48fb1871120963abd05c1e69a8e660d | Test instance |
| InstanceFactory (old) | 0x3bf5fa480bc9804717bf452974a16939a95bf7a1 | Deprecated |
