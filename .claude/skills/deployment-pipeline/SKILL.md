---
name: deployment-pipeline
description: EVM/ICP デプロイの安全手順とロールバック — InstanceFactory/TheWorld デプロイ、canister install、コントラクトデプロイ
triggers:
  - deploy
  - デプロイ
  - mainnet deployment
  - canister install
  - dfx deploy
  - cast send --create
  - contract deployment
  - rollback
  - ロールバック
  - upgrade
  - InstanceFactory deploy
  - TheWorld deploy
---
# Deployment Pipeline Skill

EVM/ICPデプロイの安全手順とロールバック

## Triggers

- `deploy`, `デプロイ`, `mainnet deployment`
- `canister install`, `dfx deploy`
- `cast send --create`, `contract deployment`
- `rollback`, `ロールバック`, `upgrade`
- `InstanceFactory deploy`, `TheWorld deploy`

## Overview

A-Lifeはマルチチェーン (EVM + ICP) にデプロイされる。
このSkillは、安全なデプロイ手順と障害時のロールバックを定義する。

## Pre-Deployment Checklist

デプロイ前に必ず確認:

```
[ ] lazy core ask 結果がURGENT空
[ ] E2E tests passing (etherclaw e2e standalone && etherclaw e2e governed)
[ ] Colony environment hash recorded
[ ] Previous version snapshot saved
[ ] RPC/Canister接続確認済み
[ ] 署名鍵アクセス確認済み
[ ] Gas/Cycles残高確認済み
```

## EVM Deployment (InstanceFactory)

### 1. Build

```bash
cd /Users/bob/a-life/pkgs/Idris2Ouf

# Yulコード生成
IDRIS2_PACKAGE_PATH=$(pack package-path) \
  idris2-yul --codegen yul \
  -p idris2-evm \
  -p idris2-subcontract \
  -o idris2-ouf \
  src/Main.idr

# 確認
ls -la build/exec/idris2-ouf.yul
```

### 2. Compile

```bash
# Solcでバイトコード生成
solc --strict-assembly --optimize \
  build/exec/idris2-ouf.yul \
  --bin > /tmp/ouf.bin

# バイトコードサイズ確認 (24KB制限)
wc -c /tmp/ouf.bin
# 48KB以下であること (hex表記なので実際の半分)
```

### 3. Simulate (Dry Run)

```bash
# ローカルAnvilでテスト
anvil &
ANVIL_PID=$!

cast send --create "0x$(cat /tmp/ouf.bin)" \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# 成功したらAnvil停止
kill $ANVIL_PID
```

### 4. Deploy

```bash
# Base Mainnetにデプロイ
cast send --create "0x$(cat /tmp/ouf.bin)" \
  --rpc-url https://mainnet.base.org \
  --private-key $DEPLOYER_KEY

# 出力からcontractAddressを記録
# contractAddress: 0x...
```

### 5. Verify

```bash
# コード存在確認
cast code <deployed_address> --rpc-url https://mainnet.base.org

# 0x以外が返ればOK
# 0xのみなら失敗
```

### 6. Register

```bash
# TheWorldに新アドレスを登録
dfx canister call theworld 'registerContract("0x<address>", 8453)'
```

## ICP Deployment (TheWorld)

### 1. Build

```bash
cd /Users/bob/a-life/pkgs/Idris2TheWorld

# ビルドスクリプト実行
./scripts/build-canister.sh

# 出力確認
ls -la build/theworld_stubbed.wasm
```

### 2. Test (Local)

```bash
# ローカルレプリカ起動
dfx start --clean --background

# ローカルデプロイ
dfx deploy theworld --mode reinstall

# 基本動作確認
dfx canister call theworld getVersion
dfx canister call theworld getProposalCount
```

### 3. Deploy (IC Mainnet)

```bash
# メインネットデプロイ
dfx deploy theworld --network ic --mode upgrade

# 注意: --mode reinstall は状態を消去する
# 通常は upgrade を使用
```

### 4. Verify

```bash
# Canister状態確認
dfx canister status theworld --network ic

# メソッド呼び出し確認
dfx canister call theworld getVersion --network ic
```

## Rollback Procedure

### EVM Rollback

EVMコントラクトは不変。ロールバック = 前バージョンを再デプロイ。

```bash
# 1. 前バージョンのバイトコード取得
# (事前にsnapshot保存が必要)
cat snapshots/ouf-v7.bin

# 2. 再デプロイ (新アドレス)
cast send --create "0x$(cat snapshots/ouf-v7.bin)" \
  --rpc-url https://mainnet.base.org \
  --private-key $DEPLOYER_KEY

# 3. TheWorldのコントラクト登録を更新
dfx canister call theworld 'registerContract("0x<new_address>", 8453)'

# 4. 旧アドレスを非推奨化 (Optional)
# ERC-7546: Dictionary更新で全selector無効化
```

### ICP Rollback

```bash
# Option A: upgrade (状態保持)
# 前バージョンのWASMで上書き
dfx canister install theworld --network ic --mode upgrade \
  --wasm snapshots/theworld-v2.wasm

# Option B: reinstall (状態消去)
# 注意: 全状態が失われる
dfx canister install theworld --network ic --mode reinstall \
  --wasm snapshots/theworld-v2.wasm

# 状態復元が必要な場合
# StableMemory export/import を使用
```

## Version Management

### InstanceFactory Versions (Base Mainnet)

| Version | Address | Block | Status |
|---------|---------|-------|--------|
| v8 | `0xb094b55924a790c4c9f86e16beb93d1261ed9891` | 41270838 | Active |
| v7 | `0x58abBd4b6dF53f3DDb335Ac45437a467c854Ad1d` | 41270046 | Deprecated |
| v3 | `0xC7Efeca27d2e4D16e6354f2a23cd692210BbB19b` | 41268931 | Deprecated |

### TheWorld Versions (ICP)

| Version | Canister ID | Status |
|---------|-------------|--------|
| Current | `nrkou-hqaaa-aaaah-qq6qa-cai` | Active |

## Snapshot Management

### デプロイ前にSnapshot作成

```bash
# EVM
mkdir -p snapshots
cp /tmp/ouf.bin snapshots/ouf-v$(date +%Y%m%d).bin
echo "Deployed at block $(cast block-number)" >> snapshots/ouf-v$(date +%Y%m%d).meta

# ICP
cp build/theworld_stubbed.wasm snapshots/theworld-v$(date +%Y%m%d).wasm
dfx canister call theworld getVersion >> snapshots/theworld-v$(date +%Y%m%d).meta
```

### Snapshot一覧確認

```bash
ls -la snapshots/
```

## Gas/Cycles Management

### EVM Gas Estimation

```bash
# デプロイコスト見積もり
cast estimate --create "0x$(cat /tmp/ouf.bin)" \
  --rpc-url https://mainnet.base.org

# 現在のガス価格
cast gas-price --rpc-url https://mainnet.base.org
```

### ICP Cycles Estimation

```bash
# Canisterサイクル残高
dfx canister status theworld --network ic | grep Balance

# 必要サイクル見積もり
# upgrade: ~1-10B cycles
# reinstall: ~1-10B cycles
```

## Error Handling

### デプロイ失敗時

```bash
# EVM: トランザクション確認
cast tx <tx_hash> --rpc-url https://mainnet.base.org

# ICP: エラーログ確認
dfx canister logs theworld --network ic
```

### 共通エラーと対処

| エラー | 原因 | 対処 |
|--------|------|------|
| Out of gas | Gas不足 | Gas limit増加 |
| Contract too large | 24KB超過 | コード分割 |
| Cycles exhausted | Cycles不足 | Cycles補充 |
| Canister trapped | WASMエラー | ログ確認、ロールバック |

## Skill連鎖

| 状況 | 連鎖先Skill |
|------|-------------|
| ビルドエラー | idris2-dev |
| デプロイ後検証 | theworld-onchain |
| 障害検知 | theworld-monitor |
| 失敗回復 | failure-recovery |

## 例: InstanceFactory v9 デプロイ

```
Agent: InstanceFactory v9をBase Mainnetにデプロイします

[Pre-Deployment Checklist]
✓ lazy core ask: URGENT空
✓ E2E tests: passing
✓ Snapshot: snapshots/ouf-v8.bin saved
✓ RPC: https://mainnet.base.org responding
✓ Gas: 0.1 ETH available

[Build]
Agent: idris2-yul --codegen yul 実行中...
  → build/exec/idris2-ouf.yul 生成完了

[Compile]
Agent: solc --strict-assembly 実行中...
  → /tmp/ouf.bin 生成完了 (36KB)

[Simulate]
Agent: Anvilでdry run...
  → Success: 0x1234... deployed

[Deploy]
Agent: Base Mainnetにデプロイ中...
  → TX: 0xabcd...
  → Contract: 0x9876...
  → Block: 41271000

[Verify]
Agent: cast code確認...
  → Code exists (18432 bytes)

[Register]
Agent: TheWorldに登録...
  → dfx canister call theworld 'registerContract(...)'

デプロイ完了。
New InstanceFactory v9: 0x9876...
```
