---
name: task-tree-format
description: TaskTree TOML フォーマット — ファイル命名規則、TOML構造、acceptance criteria、checkbox、estimate
triggers:
  - TaskTree 作成
  - task tree
  - tasktree
  - docs/tasktrees
  - TOML 書く
  - タスクツリー
  - YYYYMMDD
  - acceptance criteria
  - checkbox
  - estimate
  - subtask
  - verification
---
# TaskTree Format Skill

## 概要

A-Life プロジェクトの TaskTree ドキュメント作成時の必須フォーマット。

## 必須ルール

### 1. ファイル名

**形式**: `YYYYMMDD-<task-tree-id>.toml`

**例**:
- `20260204-github-pr-action-handler.toml`
- `20260130-task-tree-minimal.toml`

### 2. 配置場所

**ディレクトリ**: `docs/tasktrees/`

### 3. TOML 構造

```toml
version = "1.0"
id = "task-tree-id"
title = "Human-readable title"
owner = "email@example.com"
created_at = 1738627200  # Unix timestamp (optional)

[metadata]
priority = "low" | "medium" | "high" | "critical"
type = "feature" | "bugfix" | "refactor" | "docs"

[root]
id = "1"
name = "Root task name"
description = "Optional description"
estimate = { hours = 2, minutes = 30 }
checkbox = "unchecked"

[[root.acceptance]]
description = "Acceptance criteria"
verification = "shell command to verify"

[[subtask]]
id = "1.1"
parent = "1"
name = "Subtask name"
deliverable = "file.txt" # Optional
dependencies = ["1.2", "1.3"] # Optional
estimate = { minutes = 30 }
checkbox = "unchecked"
acceptance = [
  { description = "Criteria", verification = "test command" }
]
```

### 4. Checkbox 値

- `"unchecked"` - 未完了
- `"checked"` - 完了

### 5. Estimate フォーマット

```toml
estimate = { hours = 2 }
estimate = { minutes = 30 }
estimate = { hours = 1, minutes = 15 }
```

### 6. Acceptance 配列

各タスクは必ず `acceptance` フィールドを持つべき：

```toml
acceptance = [
  { description = "説明", verification = "コマンド" }
]
```

### 7. Codebase References (Optional)

外部コードベースのパターンを参照する場合、`[[codebase_ref]]` で明示する。
daemon が指定ファイルを読み取り、agent のプロンプトに注入する。

```toml
[[codebase_ref]]
path = "~/code/idris2-magical-utils/pkgs/Idris2Subcontract"
files = ["src/Subcontract/Core/Schema.idr", "src/Subcontract/Core/Entry.idr"]
summary = "ERC-7546 contract framework patterns"
```

- `path`: コードベースルート (`~` 展開可)
- `files`: 読み取るファイル (明示リスト、3-6 ファイル推奨)
- `summary`: agent に表示されるヘッダー
- daemon は合計 50K 文字上限で切り捨て、ファイル不在は WARN skip

## Dry Run 検査

TaskTree を作成したら必ず dry-run 検査：

```bash
etherclaw up docs/tasktrees/20260204-your-task.toml --dry-run
```

## よくある間違い

### ❌ 間違い: Markdown ファイル

```
docs/tasktrees/github-pr-action-handler.md  # NG
```

### ✅ 正解: 日付付き TOML

```
docs/tasktrees/20260204-github-pr-action-handler.toml
```

### ❌ 間違い: 日付なし

```
docs/tasktrees/task-tree-minimal.toml  # NG
```

### ✅ 正解: YYYYMMDD 日付

```
docs/tasktrees/20260204-task-tree-minimal.toml
```

## 参考例

最小構成:
```bash
cat docs/tasktrees/20260130-task-tree-minimal.toml
```

複雑な例:
```bash
cat docs/tasktrees/20260203-unified-workflow-state-machine.toml
```

## Standalone モードとの連携

TaskTree TOML を `docs/tasktrees/` に置いた後、`.etherclaw/tasks.toml` に `[[task]]` を登録すると
`etherclaw daemon --standalone` (or `--governed`) が自動で実行する。

**重要: `[[task]]` は ETHERCLAW.toml ではなく `.etherclaw/tasks.toml` に書く。**
`.etherclaw/tasks.toml` は `.gitignore` 対象 — ローカルのみ、git push しない。

```toml
# .etherclaw/tasks.toml に追記
[[task]]
id    = "EC-00999"
toml  = "docs/tasktrees/20260307-my-new-task.toml"
title = "新機能実装"
status = "pending"
```

詳細: `etherclaw-standalone` skill 参照。
