---
name: autonomous-dev
description: A-Life 自律開発システムの監視者ガイド — ガバナンス優先介入原則、TMUX直接操作の緊急手順
triggers:
  - 自律開発
  - autonomous development
  - Meta-Agent 監視
  - TMUX 監視
  - 介入
  - intervention
  - 監視者
---
# Autonomous Development Observer Skill

A-Life 自律開発システムの **監視者** 用 Skill です。

## ガバナンス優先原則

**重要**: 介入は原則としてガバナンス経由で行う。

```
┌─────────────────────────────────────────────────────────────┐
│ 正当な介入経路                                              │
│                                                             │
│   人間 → ICP TextDAO → TheWorld → Meta-Agent → Worker        │
│                                                             │
│ 直接介入は緊急時のみ                                        │
│                                                             │
│   人間 → TMUX 直接操作 (システム障害/セキュリティ緊急時)    │
└─────────────────────────────────────────────────────────────┘
```

### tmux 操作ルール

**デモ起動 (tmux session 作成) は人間が素のターミナルで実行する。**

Agent が tmux session を `new-session` で作ると、人間がビデオ通話で画面共有できない。
デモのワンライナーは人間が打つことで、人間の画面に 4 ペインが表示される。

Agent に許可されている tmux 操作:
- `tmux send-keys`: ペインにコマンドを送信 (Agent が各ロールを操作)
- `tmux capture-pane`: ペインの出力を読み取り (進捗確認)
- `tmux kill-session` / `kill-pane`: 必要に応じてセッション/ペイン終了

Agent に禁止されている tmux 操作:
- `tmux new-session` / `demo-tmux.sh` の実行 (人間の画面に表示されない)
- `script` コマンド (pseudo-TTY 生成 → claude が `Not logged in` で死ぬ)

### オーナーの役割

| 役割 | 説明 |
|------|------|
| 観察 | システムが正常に動作しているか監視 |
| ガバナンス参加 | TextDAO で提案・投票 |
| 緊急対応 | システム障害時のみ直接介入 |
| **介入しない** | 正常動作中は見守るだけ |

## アーキテクチャ

```
┌──────────────────────────────────────────────────────────┐
│ TheWorld (ICP TextDAO)     ← ガバナンス                   │
└────────────────┬─────────────────────────────────────────┘
                 │ Directive
                 ▼
┌──────────────────────────────┐   ┌──────────────────────┐
│ Meta-Agent (Claude Code)     │ ← │ Waker (Idris2)       │
│ TMUX: meta-agent             │   │ 死活監視             │
└────────────────┬─────────────┘   └──────────────────────┘
                 │ 監視・注入
                 ▼
┌──────────────────────────────┐
│ Worker (Claude Code)         │
│ TMUX: claude-dev             │
└──────────────────────────────┘
```

## 監視コマンド

### 基本状況

```bash
# セッション一覧
tmux ls

# Worker 出力 (最新30行)
tmux capture-pane -t claude-dev -p | tail -30

# Meta-Agent 出力 (最新30行)
tmux capture-pane -t meta-agent -p | tail -30

# Waker ログ
tail -20 /tmp/waker.log

# Waker プロセス
ps aux | grep waker | grep -v grep
```

### リアルタイム監視

```bash
# 10秒間隔で両方を監視
watch -n 10 'echo "=== Meta-Agent ===" && tmux capture-pane -t meta-agent -p | tail -10 && echo "" && echo "=== Worker ===" && tmux capture-pane -t claude-dev -p | tail -10'
```

### 詳細状況

```bash
# Worker の全出力
tmux capture-pane -t claude-dev -p -S -500

# Meta-Agent の全出力
tmux capture-pane -t meta-agent -p -S -500
```

## 起動・停止

### 起動

```bash
# 1. Worker
tmux new-session -d -s claude-dev -c /Users/bob/a-life
tmux send-keys -t claude-dev 'claude' Enter

# 2. Meta-Agent
tmux new-session -d -s meta-agent -c /Users/bob/a-life
tmux send-keys -t meta-agent 'claude' Enter
sleep 5
tmux send-keys -t meta-agent 'meta-agent Skillを読み込んで、claude-dev の監視を開始してください。' Enter

# 3. Waker (integrated into etherclaw CLI)
# Waker functionality is now part of pkgs/ALife/src/ALife/Waker.idr
# Run via: etherclaw watch (or use launchd/systemd for daemon mode)
```

### 停止

```bash
# Waker
pkill -f waker

# Meta-Agent
tmux send-keys -t meta-agent C-c
tmux send-keys -t meta-agent '/exit' Enter
tmux kill-session -t meta-agent

# Worker
tmux send-keys -t claude-dev C-c
tmux send-keys -t claude-dev '/exit' Enter
tmux kill-session -t claude-dev
```

## ガバナンス経由の介入 (推奨)

### Directive 設定

```bash
# タスク指示 (要 Proposer 権限)
dfx canister call --network ic nrkou-hqaaa-aaaah-qq6qa-cai \
  proposeDirective '(record {
    task = "pkgs/Idris2TheWorld のテストカバレッジを80%以上にする";
    priority = 1;
    constraints = vec { "破壊的変更禁止" }
  })'
```

### クリティカル操作承認

```bash
# 承認 (要 Auditor 権限)
dfx canister call --network ic nrkou-hqaaa-aaaah-qq6qa-cai \
  approveCriticalAction '("action-id")'

# 拒否
dfx canister call --network ic nrkou-hqaaa-aaaah-qq6qa-cai \
  rejectCriticalAction '("action-id", "理由")'
```

### 状態確認

```bash
# 現在の Directive
dfx canister call --network ic nrkou-hqaaa-aaaah-qq6qa-cai \
  getAgentDirective '()'

# 保留中のクリティカル操作
dfx canister call --network ic nrkou-hqaaa-aaaah-qq6qa-cai \
  getPendingCriticalActions '()'
```

## 緊急時の直接介入

以下の場合 **のみ** 直接介入を許可:

### 1. システム障害

```bash
# Meta-Agent が完全停止
tmux send-keys -t meta-agent 'claude' Enter

# Worker が完全停止
tmux send-keys -t claude-dev 'claude' Enter
```

### 2. 無限ループ・暴走

```bash
# Worker を強制停止
tmux send-keys -t claude-dev C-c

# Meta-Agent を強制停止
tmux send-keys -t meta-agent C-c
```

### 3. セキュリティ緊急事態

```bash
# 全プロセス停止
pkill -f waker
tmux kill-server
```

## トラブルシューティング

### Q: Meta-Agent が応答しない

```bash
# Waker が ping しているか確認
tail -20 /tmp/waker.log

# 手動で ping
tmux send-keys -t meta-agent '監視を続けてください。' Enter
```

### Q: Worker が stuck している

```bash
# 状態確認
tmux capture-pane -t claude-dev -p | tail -30

# Meta-Agent に任せる (推奨)
# → Meta-Agent が自動で検出・対応するはず

# 緊急時のみ直接介入
tmux send-keys -t claude-dev C-c
```

### Q: 両方停止した

```bash
# 起動スクリプトを再実行
# (上記「起動」セクション参照)
```

### Q: TheWorld に接続できない

```bash
# ネットワーク確認
dfx ping ic

# フォールバック: Meta-Agent は lazy core ask で自律継続
```

## 関連ドキュメント

- `docs/autonomous-stack.md` - アーキテクチャ詳細
- `pkgs/ALife/src/ALife/Waker.idr` - Waker 実装 (etherclaw CLI に統合)
