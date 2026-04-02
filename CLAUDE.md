# td — Project Instructions

## Instance

- ENS: `td.onthe.eth`
- Managed by EtherClaw

## Demo Governance Rules

このデモでは以下の制約を設ける：

### 1. ブランチ保護
- `enforce_admins: true` — 管理者もブランチ保護をバイパスできない
- 直接pushは禁止、PR必須

### 2. レビュー・投票フロー
- **Claude自身が** TheWorld canister経由でレビュー作成・投票を実行
- GitHub UI上の承認ではなく、`etherclaw review approve --pr <N>` を使用
- マージも手動ではなく、TheWorldガバナンス経由またはGitHub Actionsに委任

### 3. tmux 6-Pane構成
```
+--------+--------+--------+
| 0 Flow | 1 Rev  | 2 Col  |
|   Mon  |  (Cl)  |  (EC)  |
+--------+--------+--------+
| 3 Rel  | 4 IP   | 5 Aud  |
|  Prop  |  Prop  |  (Cl)  |
+--------+--------+--------+
```
- 各Paneが自律的に役割をこなす
- Flow Monitor (0) は常時監視
- Colony (2) はstandalone daemonとして動作
- IP Proposer (4) が新規IPを提案
- Reviewer (1) / Auditor (5) はClaudeが担当

## Init-Time Skills

### Required Skills
- `idris2-dev` - Idris2 development (OOM avoidance, project conventions)

## Quick Start

```bash
etherclaw status          # Show task status
etherclaw daemon --standalone --dry-run  # Preview
etherclaw daemon --standalone            # Run
```

## ICP Cycles コスト

- query call も canister の compute cycles を消費する (caller は無料だが canister は有料)
- ポーリングは最小頻度で (30s 以上の間隔を厳守)
- `proximity_get` は instruction limit に注意 (IC0522 リスク) — ポーリングループ内で使用禁止
- TheWorld / mmnt の cycles 残高を定期確認: `dfx canister status <id> --network ic`

## SQLite API (idris2-icwasm)

idris2-icwasm の SQLite API は **SqliteHandle 必須**。handle なしの旧 API は廃止済み。

```idris
-- 初期化: StableConfig → SqliteHandle (これ以外に handle を得る方法はない)
handle <- initSqlite (MkStableConfig 1 0 1024)

-- 全操作に handle が必須
sqlExec handle "CREATE TABLE IF NOT EXISTS foo (id INTEGER PRIMARY KEY)"
sqlPrepare handle "SELECT * FROM foo WHERE id = ?"
sqlStep handle
```

### ルール
- `initSqlite : StableConfig -> IO SqliteHandle` でのみ handle を取得
- `sqlExec : SqliteHandle -> String -> IO SqlResult`
- `sqlPrepare : SqliteHandle -> String -> IO SqlResult`
- `sqlStep : SqliteHandle -> IO SqlResult`
- `sqlOpen` は private — 直接呼べない
- `canister_pre_upgrade` で `sqlite_stable_save` が gen-entry により自動挿入される
- 旧 API (`sqlExec "SQL"` — handle なし) は廃止。コンパイルエラーになる
