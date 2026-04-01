---
name: etherclaw-standalone
description: etherclaw daemon --standalone mode — ETHERCLAW.toml format, Architect/Executor role split, DogFeeding workflow
triggers:
  - etherclaw daemon --standalone
  - ETHERCLAW.toml
  - etherclaw init
  - etherclaw validate
  - standalone mode
  - DogFeeding
  - TaskTree設計
  - pending task
  - in_progress task
---

# EtherClaw Standalone Mode Skill

## 概要

`etherclaw daemon --standalone` は ETHERCLAW.toml に登録されたタスクをローカルで順次実装し、
PR を自動提出するモード。ガバナンス (c^i_share) 不要の DogFeeding 経路。

## ETHERCLAW.toml フォーマット

```toml
# ETHERCLAW.toml — project root に配置、git 管理対象
[instance]
ticker    = "EC"                        # 2-8 大文字英字、ENS subdomain と一致推奨
name      = "EtherClaw"
ens       = "etherclaw.onthe.eth"       # optional
version   = 1                           # schema version (現在は 1 固定)
executor  = "claude"                    # CLI tool: claude|codex|gemini|kimi
architect = "claude-opus-4-6"           # Architect が使うモデル
local_model = "qwen3.5:2b"             # ollama ローカルモデル (SemanticAudit 等)
build     = "pack install-app etherclaw" # ビルドコマンド
project   = "/Users/bob/code/etherclaw" # プロジェクト絶対パス

# NOTE: [[task]] entries are stored in .etherclaw/tasks.toml (NOT in ETHERCLAW.toml)
# .etherclaw/tasks.toml is .gitignore'd — local only, never pushed to main.
# Example .etherclaw/tasks.toml:

# [[task]]
# id     = "EC-00200"
# toml   = "docs/tasktrees/my-task.toml"
# title  = "My Task"
# status = "pending"
pr_sha       = "737b4ef"
completed_at = 1741392000
```

## [[lazy]] 登録義務

**pkgs/ に SPEC.toml を持つパッケージは必ず `[[lazy]]` に登録すること。**
未登録パッケージは dump-s に出ず、daemon の AGA Loop quality gate の対象外になる。

```toml
[[lazy]]
target     = "pkgs/NewPackage"
family     = "core"       # core | evm | dfx | web
step3_sync = false         # Step3 Semantic は手動実行 (コスト制約)
```

パッケージ新規作成時は `etherclaw dump-s` で出力を確認。

## status 遷移

```
pending → in_progress → done
                      → skipped  (手動設定のみ)
done    → pending      (再実行時。pr_sha 検証が走る)
```

## タスク ID 命名規則

```
{ticker}-{5桁seq}
例: EC-00200, LC-00100, MMNT-00010
```

## Architect / Executor ロール分離

| | Architect | Executor |
|--|-----------|----------|
| **役割** | TaskTree TOML 設計・レビュー | コード実装 |
| **モデル** | `architect` フィールド (opus 等) | `executor` CLI + executor_model |
| **Skills** | etherclaw-standalone, task-tree-format, idris2-dev | idris2-dev, etherclaw-workflow |
| **入力** | ETHERCLAW.toml の task エントリ | TaskTree TOML |
| **成果物** | `docs/tasktrees/YYYYMMDD-*.toml` | PR |

## Architect が TaskTree を書くときのドメイン知識

### 必須コマンド参照
- `etherclaw init` — 新プロジェクト用 ETHERCLAW.toml を対話生成
- `etherclaw validate` — ETHERCLAW.toml 整合性検証
- `etherclaw daemon --standalone --dry-run` — 次タスクプレビュー
- `etherclaw daemon --standalone --foreground` — ループ実行 (supervisor 内)

### TaskTree TOML 配置場所
```
docs/tasktrees/YYYYMMDD-<task-id>.toml
例: docs/tasktrees/20260304-submission-queue-persistence.toml
```

### TaskTree で使うビルドコマンド (Idris2 プロジェクト)
```bash
pack install-app etherclaw   # ビルド + インストール
pack typecheck etherclaw     # 型検査のみ
```

### マルチリポジトリ構成
```
各リポジトリに独立した ETHERCLAW.toml を置く:
  ~/code/etherclaw/  → ticker = "EC"
  ~/code/lazy/       → ticker = "LC"
  ~/code/mmnt/       → ticker = "MMNT"

etherclaw daemon --standalone は project フィールドのリポジトリで動作。
他プロジェクトの ETHERCLAW.toml 生成は etherclaw init または TaskTree で対応。
```

## daemon ループフロー

```
standaloneLoop:
  1. ETHERCLAW.toml 読み込み
  2. 整合性検証 (CRITICAL → 停止, ERROR → 自動修復)
  3. pending タスクを ID 昇順で選択
  4. toml ファイル存在確認 (なければスキップ)
  5. git worktree add /tmp/etherclaw-{id} -b feat/{ticker-lower}-{id}
  6. ETHERCLAW.toml: status → in_progress, branch, started_at を記録
  7. Executor CLI を worktree で起動 (unset CLAUDECODE)
  8. git push + gh pr create
  9. PR マージ待機 (30秒ポーリング、最大 24h)
  10. ETHERCLAW.toml: status → done, pr, pr_sha, completed_at を記録
  11. 次タスクへ
```

## 整合性検証ルール

| レベル | 条件 |
|--------|------|
| CRITICAL | ticker 変更・version 不一致 |
| ERROR | id prefix 不一致・pr_sha が git history にない (done 詐称) |
| WARN | done なのに pr_sha 未設定 |

`pr_sha = "manual"` または `"skipped"` は git 検証をスキップ。

## 起動方法

`etherclaw daemon --standalone` は **nohup** 経由でデーモンを起動する。
`CLAUDECODE` を unset した完全に独立したプロセスとして動作するため、
Claude Code セッション内からも安全に呼び出せる。

```
etherclaw daemon --standalone
  └─ nohup env -u CLAUDECODE etherclaw daemon --standalone --foreground
       </dev/null >> ~/.etherclaw/logs/standalone.log 2>&1 &
       PID → ~/.etherclaw/logs/standalone.pid
```

**CLAUDECODE の扱い**:
- `nohup env -u CLAUDECODE` で完全にアンセット
- 子プロセス内 (`runStandaloneTask`) でも `unset CLAUDECODE &&` を前置
- これにより Claude Code セッション内からネスト起動が可能

## 進捗確認方法

```bash
# ログをリアルタイム追跡
tail -f ~/.etherclaw/logs/standalone.log

# デーモン生死確認
kill -0 $(cat ~/.etherclaw/logs/standalone.pid) 2>/dev/null && echo alive || echo dead

# タスク状態確認 (ETHERCLAW.toml)
etherclaw validate

# 次タスク確認
etherclaw daemon --standalone --dry-run

# 停止
kill $(cat ~/.etherclaw/logs/standalone.pid)
```

## よくある操作

```bash
# 新プロジェクト初期化
etherclaw init

# 整合性確認
etherclaw validate

# 次タスク確認 (dry-run)
etherclaw daemon --standalone --dry-run

# Claude Code セッション内から起動する場合:
# etherclaw daemon --standalone でも内部 launchNohup が働くが、
# Bash ツールがプロセス終了を待ってタイムアウトする場合は以下を使う:
nohup env -u CLAUDECODE etherclaw daemon --standalone --foreground > .etherclaw/logs/standalone.log 2>&1 &

# 別ターミナルからなら単純に:
etherclaw daemon --standalone

# 直接実行 (foreground、デバッグ用)
etherclaw daemon --standalone --foreground

# 特定タスクから再開
etherclaw daemon --standalone --from EC-00300

# E2E テスト
etherclaw e2e standalone       # Colony daemon 8 ステージ lifecycle
etherclaw e2e governed         # 12 ステージ Governed Repo
etherclaw e2e evm              # 5 ステージ EVM pipeline
```
