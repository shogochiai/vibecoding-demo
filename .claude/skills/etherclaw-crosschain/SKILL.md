---
name: etherclaw-crosschain
description: EtherClaw InstanceFactory/TheWorld cross-chain architecture - Optimistic Upgrader system spanning EVM (Base Mainnet) and ICP, ERC-7546, auditor approval flow
triggers:
  - InstanceFactory
  - TheWorld
  - Optimistic Upgrader
  - cross-chain
  - etherclaw
  - ERC-7546
  - Base Mainnet
  - ICP canister
  - auditor approval
  - proposeUpgrade
  - fetchEvmLogs
---

# EtherClaw Cross-Chain Architecture

## Overview

EtherClaw is a cross-chain system where:
- **InstanceFactory** (EVM factory contract) runs on **EVM** (Base Mainnet)
- **TheWorld** (Optimistic Upgrader Canister) runs on **ICP** (Internet Computer)

Both are implemented in **Idris2** using different backends:
- InstanceFactory: idris2-evm (Yul codegen)
- TheWorld: idris2-icwasm (RefC -> WASM)

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         EtherClaw Architecture                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Base Mainnet (EVM)                    ICP Mainnet                       │
│  ─────────────────                     ───────────                       │
│                                                                          │
│  ┌──────────────┐                     ┌──────────────┐                   │
│  │ Instance     │                     │  TheWorld    │                   │
│  │  Factory     │                     │  (Canister)  │                   │
│  │ idris2-ouf   │                     │  idris2-ouc  │                   │
│  └──────┬───────┘                     └──────┬───────┘                   │
│         │                                    │                           │
│         │ createOU()                         │ fetchEvmLogs()            │
│         ▼                                    │                           │
│  ┌──────────────┐                            │                           │
│  │    OU        │ ─── Event (UpgradeProposed) ───▶ Detect               │
│  │ (Upgrader)   │                            │                           │
│  │              │ ◀── Approval (via signing) ─── submitReview()         │
│  └──────────────┘                            │                           │
│                                              │                           │
│  ┌──────────────┐                            │                           │
│  │ Target       │ ← Owner is OU (not EOA)    │                           │
│  │ (TextDAO etc)│   Upgrades only via OU     │                           │
│  └──────────────┘                            │                           │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Key Concept: Ownership Transfer

**Target contracts (e.g., TextDAO) transfer ownership to OU, NOT to an EOA.**

This means:
1. Original deployer deploys TextDAO
2. Deployer calls `TextDAO.transferOwnership(OU_ADDRESS)`
3. Now only OU can upgrade TextDAO
4. OU requires Auditor approval before executing upgrades
5. → Multi-sig + Optimistic approval for safe upgrades

## E2E Flow

### 1. Deploy InstanceFactory (Base Mainnet)
```bash
cd /Users/bob/code/etherclaw/pkgs/Idris2Ouf
solc --strict-assembly --optimize build/exec/idris2-ouf.yul --bin > /tmp/ouf.bin
cast send --rpc-url https://mainnet.base.org \
  --private-key $ETH_EOA_PRIVATE_KEY \
  --create "0x$(cat /tmp/ouf.bin)"
```

### 2. Create OU Instance & Transfer Ownership
```bash
# Create OU from factory
cast send $INSTANCE_FACTORY_ADDRESS "createOU()" --rpc-url https://mainnet.base.org --private-key $KEY

# Transfer target contract ownership to OU
cast send $TARGET_CONTRACT "transferOwnership(address)" $OU_ADDRESS --rpc-url https://mainnet.base.org --private-key $KEY
```

### 3. Propose Upgrade (EVM)
```bash
cast send $OU_ADDRESS "proposeUpgrade(address,address,bytes)" \
  $TARGET $NEW_IMPL 0x \
  --rpc-url https://mainnet.base.org --private-key $KEY
# Emits UpgradeProposed event
```

### 4. Detect Event (ICP)
```bash
dfx canister call --network ic nrkou-hqaaa-aaaah-qq6qa-cai fetchEvmLogs \
  '(41265820 : nat64, 41265840 : nat64, opt "0x<INSTANCE_FACTORY_ADDRESS>")'
# TheWorld scans Base Mainnet logs via EVM RPC canister
```

### 5. Auditor Review (ICP)
```bash
dfx canister call --network ic nrkou-hqaaa-aaaah-qq6qa-cai submitReview \
  '(proposalId, "approve")'
# When threshold reached, proposal is approved
```

### 6. Execute Upgrade (EVM)
```bash
cast send $OU_ADDRESS "executeUpgrade(uint256)" $PROPOSAL_ID \
  --rpc-url https://mainnet.base.org --private-key $KEY
# Only succeeds if approved by Auditors
```

## Deployed Addresses

### TheWorld (ICP Mainnet)
- **Canister ID**: `nrkou-hqaaa-aaaah-qq6qa-cai`

### InstanceFactory (Base Mainnet, Chain ID: 8453)

**バージョン管理:** 実運用では各 InstanceFactory バージョンに紐づく OU インスタンスがあるため、TheWorld 側でバージョン管理が必要。

| Version | Contract Address | Block | Status | Features |
|---------|-----------------|-------|--------|----------|
| **v8** | `0xb094b55924a790c4c9f86e16beb93d1261ed9891` | 41270838 | **Active** | idris2-yul Codegen修正済み |
| v7 | `0x58abBd4b6dF53f3DDb335Ac45437a467c854Ad1d` | 41270046 | Deprecated | 手動バグ回避版 |
| v3 | `0xC7Efeca27d2e4D16e6354f2a23cd692210BbB19b` | 41268931 | Deprecated | keccak256 event sigs |
| v2 | `0x03A460DC91A4606317C90679D4058c8250568eCd` | 41267491 | Deprecated | Full dispatcher |
| v1 | `0xFB636FF84752A918F6962Fa40a56697Ed61b7459` | 41265830 | Deprecated | Initial test |

**新規 OU 作成時:** 常に最新の Active バージョンを使用。
**既存 OU 管理:** OU が紐づく InstanceFactory バージョンを確認して適切な ABI で操作。

### RPC & Keys
- **RPC**: `https://mainnet.base.org`
- **Keys file**: `/Users/bob/code/idris2-ouc/.env`
  - `ETH_EOA_ADDRESS`
  - `ETH_EOA_PRIVATE_KEY`

## TheWorld Methods

```bash
# Query methods
dfx canister call --network ic $CANISTER_ID getVersion '()'
dfx canister call --network ic $CANISTER_ID getProposalCount '()'
dfx canister call --network ic $CANISTER_ID getProposal '(0)'
dfx canister call --network ic $CANISTER_ID testEvmRpc  # Test Base RPC

# Update methods
dfx canister call --network ic $CANISTER_ID submitProposal '("{...}")'
dfx canister call --network ic $CANISTER_ID submitReview '(proposalId, "approve")'
dfx canister call --network ic $CANISTER_ID fetchEvmLogs '(from, to, opt address)'
```

## ERC-7546 (NOT ERC-2535)

InstanceFactory uses **ERC-7546 Upgradeable Clone**, NOT ERC-2535 Diamond Standard.

| Standard | Function | Selector |
|----------|----------|----------|
| ERC-7546 | `getImplementation(bytes4)` | `0xdc9cc645` |
| ERC-2535 | `facetAddress(bytes4)` | `0xcdffacc6` |

When monitoring OU from TheWorld, use `getImplementation` (0xdc9cc645).

## Project Locations

```
/Users/bob/code/etherclaw/pkgs/
├── Idris2TheWorld/     # ICP Canister (idris2-icwasm)
│   ├── CLAUDE.md       # Detailed E2E docs
│   ├── can.did         # Candid interface
│   └── lib/ic0/canister_entry.c
├── Idris2Ouf/          # EVM Contract (idris2-evm)
│   ├── CLAUDE.md
│   └── build/exec/idris2-ouf.yul
├── Idris2TextDao/      # Example target contract
└── Idris2IcpIndexer/   # SQLite WASI for TheWorld
```

## Build Commands

### TheWorld (ICP)
```bash
cd /Users/bob/code/etherclaw/pkgs/Idris2TheWorld
./scripts/build-canister.sh
dfx canister --network ic install theworld --mode upgrade --wasm build/theworld_stubbed.wasm --yes
```

### InstanceFactory (EVM) - idris2-yul によるビルド

**重要**: InstanceFactory は `pack build` ではなく `idris2-yul` (カスタム Idris2) でビルドする。

#### バックエンド検出ルール
| import 文 | バックエンド | ツール |
|-----------|-------------|--------|
| `EVM.Primitives` | EVM/Yul | `idris2-yul --codegen yul` |
| `IC0.*` / `Candid.*` | ICP WASM | `./scripts/build-canister.sh` (RefC→emcc) |
| なし (標準ライブラリのみ) | Chez Scheme | `pack build` |

#### ビルド手順
```bash
cd /Users/bob/code/etherclaw/pkgs/Idris2Ouf

# 1. idris2-yul でYul生成 (pack経由でパッケージパス取得)
#    idris2-yul は mainWithCodegens で evm/yul バックエンドを追加したカスタムIdris2
IDRIS2_PACKAGE_PATH=$(pack package-path) idris2-yul \
  --codegen yul \
  -p base -p contrib -p idris2-evm -p idris2-subcontract \
  --source-dir src \
  -o idris2-ouf \
  src/Main.idr

# 2. Yul → EVM bytecode (solc)
solc --strict-assembly --optimize build/exec/idris2-ouf.yul --bin > /tmp/ouf.bin

# 3. デプロイ
cast send --rpc-url https://mainnet.base.org \
  --private-key $ETH_EOA_PRIVATE_KEY \
  --create "0x$(cat /tmp/ouf.bin)"
```

#### idris2-yul のインストール
```bash
cd /Users/bob/code/idris2-magical-utils/pkgs/Idris2Evm
pack install idris2-evm.ipkg
# ~/.local/bin/idris2-yul が生成される
```

## EVM Precompiled Contracts & keccak256

### Precompiled Contracts (0x01-0x0a)

EVMには事前コンパイル済みコントラクトがあり、低コストで暗号操作が可能:

| Address | Name | Gas | Idris2 呼び出し |
|---------|------|-----|----------------|
| 0x01 | ecrecover | 3000 | `staticcall gas 0x01 inOff inSize outOff outSize` |
| 0x02 | SHA256 | 60+12/word | `staticcall gas 0x02 ...` |
| 0x03 | RIPEMD160 | 600+120/word | `staticcall gas 0x03 ...` |
| 0x04 | identity | 15+3/word | `staticcall gas 0x04 ...` (memcpy) |
| 0x05 | modexp | 複雑 | `staticcall gas 0x05 ...` (RSA等) |
| 0x06 | ecAdd | 150 | `staticcall gas 0x06 ...` (BN256) |
| 0x07 | ecMul | 6000 | `staticcall gas 0x07 ...` (BN256) |
| 0x08 | ecPairing | 45000+34000*k | `staticcall gas 0x08 ...` (zkSNARK検証) |
| 0x09 | blake2f | 1/round | `staticcall gas 0x09 ...` |
| 0x0a | point evaluation | 50000 | `staticcall gas 0x0a ...` (EIP-4844 KZG) |

**注意**: keccak256 は Precompiled ではなく **opcode (0x20)** として実装。

### Precompiled 呼び出し実装例 (ecrecover)

```idris
-- EVM.Primitives
import EVM.Primitives

||| ECDSA署名からアドレスを復元
||| ecrecover(hash, v, r, s) -> address
ecrecover : Integer -> Integer -> Integer -> Integer -> IO Integer
ecrecover hash v r s = do
  -- 入力をメモリに配置
  mstore 0 hash      -- 0-31: message hash
  mstore 32 v        -- 32-63: v
  mstore 64 r        -- 64-95: r
  mstore 96 s        -- 96-127: s
  -- Precompiled contract 0x01 を呼び出し
  success <- staticcall 3000 0x01 0 128 128 32
  if success == 1
    then mload 128   -- 出力から読み取り
    else pure 0      -- 失敗

||| SHA256ハッシュ (Precompiled 0x02)
sha256 : Integer -> Integer -> IO Integer
sha256 offset size = do
  success <- staticcall 100 0x02 offset size 0 32
  if success == 1 then mload 0 else pure 0
```

### keccak256 の2つの利用方法

#### 1. ランタイム (EVM opcode 0x20)
```idris
import EVM.Primitives

-- EVM.Primitives からエクスポート済み
keccak256 : Integer -> Integer -> IO Integer

-- 使用例: ストレージスロット計算 (mapping)
computeMappingSlot : Integer -> Integer -> IO Integer
computeMappingSlot key base = do
  mstore 0 key
  mstore 32 base
  keccak256 0 64  -- keccak256(key . base)
```

#### 2. コンパイル時 (%runElab + cast)
```idris
import Language.Reflection

||| コンパイル時にセレクタを計算
%macro
computeSelector : String -> Elab Integer
computeSelector sig = do
  -- cast keccak を呼び出して結果をパース
  -- cast keccak "transfer(address,uint256)" => 0xa9059cbb...
  result <- runIO $ popen "cast keccak" sig
  let selector = parseHex (take 10 result)  -- 先頭4バイト
  pure selector

-- 使用例
SEL_TRANSFER : Integer
SEL_TRANSFER = %runElab computeSelector "transfer(address,uint256)"
-- コンパイル時に 0xa9059cbb が埋め込まれる
```

#### 3. 純粋 Idris2 実装 (ポータブル)
```idris
-- Keccak-256 アルゴリズムをIdris2で実装
-- (SHA-3 の前身、sponge construction)
keccak256Pure : List Bits8 -> Bits256
keccak256Pure input =
  let padded = pad input 136  -- rate = 1088 bits = 136 bytes
      absorbed = foldl absorb initialState (chunk 136 padded)
  in squeeze absorbed

-- セレクタ計算
selectorOf : String -> Integer
selectorOf sig =
  let hash = keccak256Pure (utf8Encode sig)
  in extractFirst4Bytes hash
```

### 型安全セレクタ (Dependent Types)

```idris
||| 関数シグネチャと計算されたセレクタ値のペア
||| 型レベルでシグネチャとセレクタの対応を保証
record Selector where
  constructor MkSelector
  signature : String
  value : Integer
  0 proof : value = selectorOf signature  -- 証明 (erased)

||| コンパイル時にセレクタを生成
mkSelector : (sig : String) -> Selector
mkSelector sig = MkSelector sig (selectorOf sig) Refl

-- 使用例
SEL_TRANSFER : Selector
SEL_TRANSFER = mkSelector "transfer(address,uint256)"

-- ディスパッチャで使用
dispatch : IO ()
dispatch = do
  sel <- readSelector
  if sel == SEL_TRANSFER.value
    then handleTransfer
    else ...
```

### 関連ファイル
- `/Users/bob/code/idris2-magical-utils/pkgs/Idris2Evm/src/EVM/Primitives.idr` - keccak256 opcode, staticcall
- `/Users/bob/code/idris2-magical-utils/pkgs/Idris2Evm/src/YulMain.idr` - idris2-yul エントリポイント
- `/Users/bob/code/idris2-magical-utils/pkgs/Idris2Evm/src/Compiler/EVM/ABI.idr` - セレクタ計算 (スタブ)
- `/Users/bob/code/idris2-magical-utils/pkgs/Idris2Subcontract/` - 型安全セレクタ追加先

## idris2-yul コード生成バグ（修正済み）

以下のバグは **Codegen.idr で修正済み**。`pack install idris2-evm` で最新版を使用すること。

### 修正1: switch default 欠落 (2025-01-25 修正)

**問題**: `mdef = Nothing` の case 式で default ブランチが生成されず、マッチしない値で未定義動作。

**修正**: `Compiler/EVM/Codegen.idr` の AConCase/AConstCase で常に default ブランチを生成。

```idris
-- 修正前: switch v; case 1: ... (case 0 なし)
-- 修正後: switch v; case 1: ... default {} (空でも必ず生成)
```

### 修正2: コンストラクタ引数無視 (2025-01-25 修正)

**問題**: `ACon` でコンストラクタ引数がヒープに書き込まれず、タグのみ返される。

**修正**: `Compiler/EVM/Codegen.idr` で `allocWords` + `writeTaggedValue` を使用。

```idris
-- 修正前: [x, y] → 定数 1 (タグのみ)
-- 修正後: [x, y] → ヒープポインタ (tag + fields)
```

### 現在の動作確認済みパターン

```idris
-- /= は正常動作（case 0/1 両方生成）
if x /= 0 then doA else doB  -- OK

-- if-then-else は正常動作
if isValid then proceed else revert  -- OK

-- リストコンストラクタはヒープ割り当て
[x, y, z]  -- OK (ただしEVMではガス効率悪い、可能なら避ける)
```

### レガシー回避策（不要だが互換性のため残存）

InstanceFactory コードには古い回避策コメントが残っているが、修正済みのため不要:

```idris
-- NOTE: Using == 0 instead of /= 0 due to idris2-yul codegen bug with /=
-- ↑ このコメントは obsolete、/= は正常動作する
```
initSingle : Integer -> IO ()
```

### 確認方法

Yul 出力を確認して switch 文に case 0 があるか確認:

```bash
grep -A5 "switch" build/exec/idris2-ouf.yul
```

## InstanceFactory/TheWorld バージョン管理

### InstanceFactory (Base Mainnet, Chain ID: 8453)

| Version | Contract Address | Block | Status | Notes |
|---------|-----------------|-------|--------|-------|
| **v8** | `0xb094b55924a790c4c9f86e16beb93d1261ed9891` | 41270838 | **Active** | idris2-yul Codegen修正済み |
| v7 | `0x58abBd4b6dF53f3DDb335Ac45437a467c854Ad1d` | 41270046 | Deprecated | 手動バグ回避版 |
| v3 | `0xC7Efeca27d2e4D16e6354f2a23cd692210BbB19b` | 41268931 | Deprecated | keccak256 event sigs |
| v2 | `0x03A460DC91A4606317C90679D4058c8250568eCd` | 41267491 | Deprecated | Full dispatcher |
| v1 | `0xFB636FF84752A918F6962Fa40a56697Ed61b7459` | 41265830 | Deprecated | Initial test |

### イベントトピック

```
EVENT_UPGRADE_PROPOSED = 0xf34129fccd3678779a7cae31d1189c93038ab2834690d15f21bc6020833084b6
```

TheWorld の `OucIndexerAdapter.idr` の `upgradeProposedTopic` と一致させること。

## E2E Testing

### OpenClaw Lifecycle E2E (Integrated)

```bash
# Standalone: Colony daemon 8 ステージ
etherclaw e2e standalone

# Governed: 12 ステージ (check-run + TheWorld voting + mmnt bus + liveness + attraction + cluster + submit + MCP)
etherclaw e2e governed

# EVM: 5 ステージ (Tokenomics build + Yul + Anvil deploy + interaction + ERC-7546)
etherclaw e2e evm
```

実装: `pkgs/EtherClaw/src/EtherClaw/E2E/Runner.idr` (standalone), `GovernedRunner.idr` (governed)
詳細: `docs/production/openclaw-e2e-lifecycle.md`

### Cross-Chain Test Package

```
/Users/bob/code/etherclaw/pkgs/E2eTests/
├── e2e-tests.ipkg
└── src/
    ├── E2eTests.idr           # Main entry
    ├── E2eTests/Config.idr    # Configuration
    └── E2eTests/InstanceFactoryTheWorld.idr  # InstanceFactory→TheWorld test case
```

### Shared Harness
E2E tests use `idris2-e2e-harness` from idris2-magical-utils:
```
/Users/bob/code/idris2-magical-utils/pkgs/Idris2E2eHarness/
```

### Running Cross-Chain E2E Tests

```bash
cd /Users/bob/code/etherclaw/pkgs/E2eTests

# Generate CI script
idris2 --build e2e-tests.ipkg && ./build/exec/e2e-tests --generate > run-e2e.sh

# Execute
chmod +x run-e2e.sh && ./run-e2e.sh
```

### E2E Test: InstanceFactory → TheWorld Event Detection

1. Start Anvil (forking Base Mainnet at InstanceFactory deploy block)
2. Start DFX local replica
3. Deploy TheWorld canister locally
4. Call `proposeUpgrade` on InstanceFactory (via Anvil fork)
5. Call `fetchEvmLogs` on TheWorld
6. Assert `eventsStored > 0`

### CI Integration

E2Eテストは `lazy core ask` の責務ではなく、Agent Skills と Init Template の CI 最終関門として実行する。

```yaml
# .github/workflows/e2e.yml
jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Idris2
        run: ...
      - name: Setup Foundry
        uses: foundry-rs/foundry-toolchain@v1
      - name: Setup DFX
        run: ...
      - name: Run E2E Tests
        run: |
          cd pkgs/E2eTests
          idris2 --build e2e-tests.ipkg
          ./build/exec/e2e-tests --generate | bash
```
