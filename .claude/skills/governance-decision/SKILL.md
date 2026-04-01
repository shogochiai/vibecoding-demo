---
name: governance-decision
description: TheWorldガバナンス判断の基準と閾値 — auditor approval、voting threshold、risk level分類
triggers:
  - auditor approval
  - voting threshold
  - 承認閾値
  - governance
  - ガバナンス
  - proposal decision
  - risk level
  - auditor count
  - リスクレベル
  - AutoAssign
  - auditor selection
  - 投票
  - 提案
---
# Governance Decision Skill

TheWorldガバナンス判断の基準と閾値

## Triggers

- `auditor approval`, `voting threshold`, `承認閾値`
- `governance`, `ガバナンス`, `proposal decision`
- `risk level`, `auditor count`, `リスクレベル`
- `AutoAssign`, `auditor selection`

## Overview

TheWorld (Optimistic Upgrader Canister) は、コントラクトアップグレードの承認をAuditor投票で決定する。
このSkillは、リスクレベルに応じた判断基準を定義する。

## Risk Level → Auditor Count Mapping

| Risk Level | Auditor Count | Threshold | Timeout | 用途 |
|------------|---------------|-----------|---------|------|
| CRITICAL | 5 | 5/5 (全員一致) | 7 days | コア機能変更、資金移動ロジック |
| HIGH | 3 | 3/3 | 5 days | セキュリティ関連、権限変更 |
| MEDIUM | 2 | 2/2 | 3 days | 機能追加、バグ修正 |
| LOW | 1 | 1/1 | 1 day | コメント修正、ドキュメント |
| NONE | 0 | auto-approve | immediate | 自動承認可能な変更 |

## Risk Assessment Criteria

### CRITICAL (最高リスク)

以下のいずれかに該当:

- `selfdestruct` / `delegatecall` の追加・変更
- Owner/Admin権限の変更
- 資金移動ロジック (`transfer`, `send`, `call{value:}`)
- Proxy実装アドレスの変更
- Multi-sig閾値の変更

```idris
isCritical : ProposalDiff -> Bool
isCritical diff =
  hasSelfdestruct diff ||
  hasDelegatecall diff ||
  hasOwnerChange diff ||
  hasFundTransfer diff ||
  hasProxyChange diff
```

### HIGH (高リスク)

- 外部コントラクト呼び出しの追加
- ストレージスロットの変更
- アクセス制御修飾子の変更
- イベント署名の変更

### MEDIUM (中リスク)

- 新規関数の追加
- 既存関数のロジック変更
- ビュー関数の変更
- 内部ヘルパーの変更

### LOW (低リスク)

- コメントのみの変更
- NatSpecドキュメント更新
- エラーメッセージ変更
- ログ文字列変更

### NONE (リスクなし)

- 空白・フォーマットのみ
- テストファイルのみ
- ドキュメントファイルのみ

## Auditor Selection Criteria

### 1. Reputation Threshold

```
minReputation = risk_weight * 100

risk_weight:
  CRITICAL = 5
  HIGH     = 3
  MEDIUM   = 2
  LOW      = 1
  NONE     = 0
```

例: CRITICAL提案 → minReputation >= 500

### 2. Selection Algorithm

```idris
selectAuditors : AuditorPool -> AssignmentRequest -> FR AuditorPool (List Auditor)
selectAuditors pool req = do
  -- 1. Reputation filter
  qualified <- filter (\a => a.reputation >= req.minReputation) pool.auditors

  -- 2. Conflict of interest check
  eligible <- filter (\a => not (isConflicted a req.proposer)) qualified

  -- 3. VRF-based random selection
  selected <- vrfSelect eligible req.auditorCount req.vrfSeed

  pure selected
```

### 3. Conflict of Interest Rules

以下は審査不可:

- Proposer本人
- Proposerと同一組織 (ドメイン一致)
- 過去30日以内に同一コントラクトを審査

## Approval Workflow

```
┌─────────────┐
│  Proposal   │
│  Submitted  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ AutoAssign  │ ← lazy evm-lifecycle ask からリスクレベル取得
│  Triggered  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Auditors   │ ← VRF選出
│  Assigned   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Review    │ ← submitReview() でApprove/Reject
│   Period    │
└──────┬──────┘
       │
       ├── Threshold達成 ───▶ ┌─────────────┐
       │                      │ Executable  │
       │                      └─────────────┘
       │
       ├── Threshold未達 ───▶ ┌─────────────┐
       │   (Timeout)          │  Expired    │
       │                      └─────────────┘
       │
       └── Reject多数 ──────▶ ┌─────────────┐
                              │  Rejected   │
                              └─────────────┘
```

## TheWorld API Reference

### Query Methods

```candid
// 提案取得
getProposal : (Nat) -> ProposalView query;

// 提案数
getProposalCount : () -> Nat query;

// Auditor一覧
getAuditors : () -> vec Auditor query;
```

### Update Methods

```candid
// 提案提出
submitProposal : (ProposalInput) -> Result;

// レビュー提出 (Auditorのみ)
submitReview : (ProposalId, Decision, SigHash) -> Result;

// 実行記録 (承認後)
recordExecution : (ProposalId, TxHash) -> Result;
```

## Decision Criteria for Auditors

### Approve条件

- コード変更が説明と一致
- セキュリティ脆弱性なし
- ガス最適化が適切
- 後方互換性維持 (または明示的な破壊的変更)

### Reject条件

- 説明と実装の不一致
- 既知の脆弱性パターン検出
- ストレージ衝突リスク
- 不適切な権限昇格

### 保留条件

- 追加情報が必要
- テスト不足
- ドキュメント不足

## lazy Integration

```bash
# リスクレベル取得
lazy evm-lifecycle ask <contract_dir> --steps=1,2,3

# 出力例:
# Risk: HIGH
# Recommendation: Assign 3 auditors
# Reason: External call added to untrusted address
```

## E2E 検証

Governed ガバナンスフローは `etherclaw e2e governed` で E2E 検証可能:
- Stage 4G: check-run 作成 → registerReviewer → createGithubProposal → readyForVote → castVote → merge
- Stage 5G: mmnt message bus にガバナンスイベント伝播確認
- 詳細: `docs/production/openclaw-e2e-lifecycle.md`

## Skill連鎖

| 状況 | 連鎖先Skill |
|------|-------------|
| 提案状態確認 | theworld-onchain |
| 承認失敗 | failure-recovery (F_Audit) |
| health異常 | theworld-monitor |
| リスク分析 | etherclaw-crosschain |

## 例: CRITICAL提案の処理

```
Agent: 新規Proposalを検出
  - Target: 0x1234...
  - Change: Owner権限移譲

Agent: リスク分析...
  - hasOwnerChange = true
  - Risk Level: CRITICAL

Agent: AutoAssign実行
  - Required Auditors: 5
  - Threshold: 5/5 (全員一致)
  - Timeout: 7 days

Agent: Auditor選出
  - minReputation >= 500
  - VRF seed: 0xabcd...
  - Selected: [Auditor1, Auditor2, ..., Auditor5]

Agent: レビュー期間開始
  - Deadline: 2025-02-02T00:00:00Z
  - Status: Pending (0/5 approved)
```
