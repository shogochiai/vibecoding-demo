---
name: etherclaw-workflow
description: EtherClaw TaskTree execution — standalone daemon mode, PR lifecycle, progress tracking
triggers:
  - etherclaw up
  - etherclaw status
  - etherclaw down
  - etherclaw daemon
  - autonomous mode
  - TaskTree execution
  - task completion
---

# EtherClaw Workflow Skill

## 現在の主要実行モード

### Standalone モード (推奨)

```bash
# dry-run: 次タスク確認
etherclaw daemon --standalone --dry-run

# 起動 (Claude Code セッション外から、または supervisor 経由)
etherclaw daemon --standalone

# 強制フォアグラウンド実行
etherclaw daemon --standalone --foreground

# 特定タスクから開始
etherclaw daemon --standalone --from EC-00200
```

詳細: `etherclaw-standalone` skill 参照。

### Governance モード (Colony インフラ必要)

```bash
# TaskTree を登録して実行
etherclaw up docs/tasktrees/20260207-my-task.toml

# キューから自動選択して連続実行
etherclaw up --autonomous

# 停止
etherclaw down
```

## TaskTree TOML フォーマット

```toml
version = "1.0"
id = "task-id"
title = "Human-readable title"
owner = "etherclaw-autonomous"

[metadata]
priority = "P2"
type = "feature"  # feature|bugfix|refactor|docs

[root]
id = "1"
name = "Root task"
estimate = { hours = 2 }
checkbox = "unchecked"

[[root.acceptance]]
description = "Builds successfully"
verification = "pack install-app etherclaw"

[[subtask]]
id = "1.1"
parent = "1"
name = "Implement X"
estimate = { hours = 1 }
checkbox = "unchecked"
acceptance = [
  { description = "Compiles", verification = "pack typecheck etherclaw" }
]
```

ファイル配置: `docs/tasktrees/YYYYMMDD-<id>.toml`

## ステータス確認

```bash
etherclaw status          # 実行中インスタンス + コスト
etherclaw validate        # ETHERCLAW.toml 整合性
```

## Idris2 プロジェクトでの acceptance verification

```toml
# ビルド確認
{ description = "Builds", verification = "pack install-app etherclaw" }

# 型検査のみ
{ description = "Type checks", verification = "pack typecheck etherclaw" }
```

## E2E テスト

```bash
# Standalone: Colony daemon 8 ステージ
etherclaw e2e standalone

# Governed: 12 ステージ (check-run + voting + attraction + cluster + submit + MCP)
etherclaw e2e governed

# EVM: 5 ステージ (Tokenomics build + Yul + Anvil + interaction + ERC-7546)
etherclaw e2e evm

# Help
etherclaw e2e
```

実装: `EtherClaw.E2E.Runner` (standalone), `EtherClaw.E2E.GovernedRunner` (governed)
詳細: `docs/production/openclaw-e2e-lifecycle.md`

## 関連 Skills

- `etherclaw-standalone` — standalone daemon の詳細、ETHERCLAW.toml フォーマット
- `task-tree-format` — TaskTree TOML 作成ルール
- `idris2-dev` — Idris2 実装時の OOM 回避・パターン
