---
name: etherclaw-tier-system
description: EtherClaw Tier-based hierarchical agent system - TaskTree depth から自動生成される Manager/Worker 階層
triggers:
  - tier
  - tier1
  - tier2
  - manager
  - worker
  - delegation
  - SessionProtocol
  - TaskTree
---

# EtherClaw Tier System Skill

EtherClawの **Tier ベース階層システム** の実装ガイド。TaskTree の depth から自動生成される Manager/Worker 階層を理解し、適切に実装する。

## Overview

### アーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│                         EtherClaw Stack                          │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Clock (独立 tmux session) ← State observer (100ms/30s)     │
│    │                                                          │
│    ├─► EventBus          ← Central event distribution        │
│    │                                                          │
│    └─► Reactor           ← Event handler (auto-merge, etc)   │
│                                                               │
│  ─────────────────────────────────────────────────────────   │
│                                                               │
│  Tier Hierarchy (TaskTree depth から自動生成)                │
│                                                               │
│    Tier 1 (Manager)      ← 最上位 supervisor                 │
│      ├─ Role: Manager                                         │
│      ├─ Delegates to: Tier 2                                 │
│      └─ Monitors: Subordinate completion                     │
│                                                               │
│    Tier 2 (Manager/Worker) ← 中間管理 or 実装層              │
│      ├─ Role: Manager (if depth > 2) / Worker (if leaf)     │
│      ├─ Supervisor: Tier 1                                   │
│      └─ Delegates to: Tier 3 (if Manager)                   │
│                                                               │
│    Tier N (Worker)       ← 実装実行層                         │
│      ├─ Role: Worker                                         │
│      ├─ Supervisor: Tier N-1                                 │
│      ├─ Executes: Actual implementation                      │
│      └─ Reports: Completion to supervisor                    │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Core Concepts

### 1. Tier = TaskTree Depth

**重要**: Tier 番号は TaskTree の深さから自動決定される。

```
TaskTree depth = 1 → Tier 1 (Worker のみ)
TaskTree depth = 2 → Tier 1 (Manager) + Tier 2 (Worker)
TaskTree depth = 3 → Tier 1, 2 (Manager) + Tier 3 (Worker)
```

**例:**
```toml
[root]
id = "1"
name = "Root task"

[[subtask]]
id = "1.1"
parent = "1"

[[subtask]]
id = "1.1.1"
parent = "1.1"
```

この場合 depth = 3 → **3 tiers 生成**

### 2. SessionProtocol

各 Tier は `SessionProtocol` を受け取り、役割と責務が明確化される。

```idris
record SessionProtocol where
  constructor MkProtocol
  sessionId     : String           -- "etherclaw-tier1-0"
  tier          : Nat              -- 1, 2, 3, ...
  role          : RoleType         -- Manager | Worker
  tasks         : List TaskNode    -- 担当タスク
  supervisor    : Maybe String     -- 上位 tier (None for tier1)
  subordinates  : List SupervisionProtocol  -- 下位 tier
  delegation    : DelegationRule   -- MustDelegateAll | CannotDelegate
```

### 3. Role: Manager vs Worker

**Manager**:
- `delegation = MustDelegateAll "tier{N+1}"`
- 全タスクを subordinate に委譲
- subordinate の完了を監視
- supervisor に報告

**Worker**:
- `delegation = CannotDelegate`
- 自分で実装実行
- 委譲不可
- supervisor に完了報告

## Tier 1 (Manager) の責務

### あなたが Tier 1 の場合

**役割**: 最上位 supervisor

**受け取る SessionProtocol**:
```
sessionId: "etherclaw-tier1-0"
tier: 1
role: Manager
supervisor: None
subordinates: [SupervisionProtocol for tier2]
delegation: MustDelegateAll "etherclaw-tier2-0"
```

**あなたのタスク**:

1. **Tier 2 への委譲**
   ```bash
   etherclaw inject tier2 "以下のタスクを実行してください: [Task 1.1, 1.2, 1.3, ...]"
   ```

2. **Tier 2 の監視**
   ```bash
   # 30秒ごとに状態確認
   etherclaw view tier2 --lines 20

   # .tier-status/etherclaw-tier2-0.status ファイルを確認
   cat .tier-status/etherclaw-tier2-0.status
   ```

3. **完了検知**
   - `.tier-status/etherclaw-tier2-0.status` に `[COMPLETED]` マーカーが書かれたら完了
   - 自分も完了を `.tier-status/etherclaw-tier1-0.status` に記録

4. **アイドル検知と介入**
   - Tier 2 が 60秒以上アイドル → `etherclaw inject tier2 "進捗を教えてください"`
   - エラー検知 → `etherclaw inject tier2 "エラーを確認して対処してください"`

## Tier 2+ (Manager/Worker) の責務

### あなたが Tier 2 (Manager) の場合

**役割**: 中間管理者

**受け取る SessionProtocol**:
```
sessionId: "etherclaw-tier2-0"
tier: 2
role: Manager
supervisor: "etherclaw-tier1-0"
subordinates: [SupervisionProtocol for tier3]
delegation: MustDelegateAll "etherclaw-tier3-0"
```

**あなたのタスク**:
1. Tier 1 から委譲されたタスクを受け取る
2. 全タスクを Tier 3 に委譲
3. Tier 3 を監視
4. 完了を Tier 1 に報告

### あなたが Tier N (Worker) の場合

**役割**: 実装実行者

**受け取る SessionProtocol**:
```
sessionId: "etherclaw-tierN-0"
tier: N
role: Worker
supervisor: "etherclaw-tier{N-1}-0"
subordinates: []
delegation: CannotDelegate
```

**あなたのタスク**:
1. 上位 tier から委譲されたタスクを受け取る
2. **実際の実装を実行**
   - コード編集
   - テスト実行
   - コミット作成
3. 完了を `.tier-status/etherclaw-tierN-0.status` に記録
   ```bash
   echo "[COMPLETED] etherclaw-tierN-0" > .tier-status/etherclaw-tierN-0.status
   echo "Tasks: 1.1, 1.2, 1.3" >> .tier-status/etherclaw-tierN-0.status
   echo "Evidence: commit SHA, test results" >> .tier-status/etherclaw-tierN-0.status
   ```

## Clock による監視

**重要**: あなたは状態報告の義務がありません。Clock が自動的に監視します。

### Clock の動作

```
Clock (100ms tick)
  ├─► observeAgentState (tmux capture-pane)
  │   └─► 全 tier の tmux 出力を読む
  ├─► checkStatusFiles (.tier-status/*.status)
  │   └─► [COMPLETED] マーカーを検知
  ├─► detectTransition (pure function)
  │   └─► Completed / Failed / Waiting を判定
  └─► emit(EventBus) → Reactor で処理
```

### あなたがすべきこと

1. **作業を進める**
   - 委譲されたタスクを実行（Worker の場合）
   - subordinate を監視（Manager の場合）

2. **完了をマーク**
   - `.tier-status/{sessionId}.status` に `[COMPLETED]` を書く
   - Clock が自動検知 → EventBus → Reactor

3. **状態報告は不要**
   - Clock が tmux pane を直接読む
   - あなたは自律的に作業を続ける

## 実行例

### Depth 2 の TaskTree

```toml
[root]
id = "1"
name = "Implement Feature X"

[[subtask]]
id = "1.1"
parent = "1"
name = "Add implementation"

[[subtask]]
id = "1.2"
parent = "1"
name = "Add tests"
```

**生成される Tier**:
- Tier 1 (Manager)
- Tier 2 (Worker)

**実行フロー**:

1. `etherclaw up task-tree.toml`
2. Tier 1 が起動 → Tier 2 に委譲
   ```
   etherclaw inject tier2 "以下のタスクを実行してください: 1.1, 1.2"
   ```
3. Tier 2 が実装実行
   - Task 1.1: コード追加
   - Task 1.2: テスト追加
4. Tier 2 が完了をマーク
   ```bash
   echo "[COMPLETED] etherclaw-tier2-0" > .tier-status/etherclaw-tier2-0.status
   ```
5. Clock が検知 → EventBus → Reactor
6. Tier 1 が完了を確認 → 自分も完了マーク
7. Clock が全完了を検知 → Auto-PR 作成

## TierMessage による通信

Tier 間の通信は `TierMessage` を使用:

```idris
data TierMessage
  = TaskDelegation (List String)    -- タスク ID リスト
  | ProgressReport Nat String       -- 進捗 %, メッセージ
  | CompletionNotice String         -- 完了セッション ID
  | ErrorReport String String       -- エラー種別, 詳細
```

**使用例**:

```bash
# Tier 1 → Tier 2: タスク委譲
etherclaw inject tier2 "タスク委譲: 1.1, 1.2, 1.3"

# Tier 2 → Tier 1: 進捗報告
# (不要 - Clock が自動監視)

# Tier 2 → Tier 1: 完了通知
# (不要 - .tier-status/*.status で自動検知)
```

## トラブルシューティング

### Q: Tier 2 が応答しない

**確認**:
```bash
# Tier 2 の状態を確認
etherclaw view tier2 --lines 20

# セッションが存在するか
tmux list-sessions | grep tier2

# .tier-status ファイルを確認
ls -l .tier-status/etherclaw-tier2-*
```

**対処**:
```bash
# 再起動
etherclaw down
etherclaw up task-tree.toml
```

### Q: 委譲したタスクが実行されない

**原因**: Tier 2 が Worker role を理解していない

**対処**:
```bash
# SessionProtocol を再注入
etherclaw inject tier2 "あなたは Worker です。以下のタスクを実行してください: [...]"
```

### Q: Clock がティア完了を検知しない

**原因**: `.tier-status/*.status` ファイルに `[COMPLETED]` マーカーがない

**対処**:
```bash
# 手動でマーク
echo "[COMPLETED] etherclaw-tier2-0" > .tier-status/etherclaw-tier2-0.status
```

## 参照

- **実装**: `pkgs/EtherClaw/src/ALife/TierProtocol.idr`
- **タイプ定義**: `pkgs/EtherClaw/src/ALife/TaskTree/Types.idr`
- **Clock**: `pkgs/EtherClaw/src/ALife/Clock/Loops.idr`
- **ドキュメント**: `docs/clock-comprehensive-guide.md`
