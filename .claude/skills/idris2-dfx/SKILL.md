---
name: idris2-dfx
description: IC Canister development with idris2-icwasm, canister_entry.c generation, FFI bridge, and DFX deployment
triggers:
  - IC canister
  - ICP
  - dfx
  - idris2-icwasm
  - canister_entry
  - gen-entry
  - can.did
  - Candid
  - WASM canister
  - idris2-cdk
  - sqlite_stable
  - stable memory
  - canister_pre_upgrade
  - canister_post_upgrade
  - canister_heartbeat
---

# IC Canister Development (idris2-icwasm)

## 必須ルール: canister_entry.c は手書き禁止

**全 canister プロジェクトで `idris2-icwasm gen-entry` を使うこと。**

手書きすると以下が漏れる:
- `sqlite_stable_save/load` (Stable Memory 永続化) → upgrade でデータ消滅
- `sql_ffi_open()` → DB 未初期化で全 SQL 失敗
- Candid パーサー → 引数デコード不正

## gen-entry コマンド

```bash
idris2-icwasm gen-entry \
    --did=can.did \
    --prefix=<ffi_prefix> \
    --lib=libic0 \
    --init=sql_ffi_open \
    --cmd-map=can.cmd-map \
    --out=build/canister_entry_gen.c
```

### オプション

| オプション | 必須 | 説明 |
|-----------|------|------|
| `--did` | ✅ | Candid 定義ファイル |
| `--prefix` | ✅ | FFI 関数プレフィックス (例: `mmnt`, `theworld`) |
| `--lib` | | ライブラリ名 (コメント用, デフォルト: `libic0`) |
| `--init` | ✅ | `canister_init/pre_upgrade/post_upgrade` で呼ぶ初期化関数。**SQLite 使用時は `sql_ffi_open` 必須** |
| `--cmd-map` | | cmd ID マッピングファイル。省略時は can.did 順で 0 から自動採番 |
| `--out` | | 出力ファイルパス |

### can.cmd-map フォーマット

```
# method_name=cmd_id
# CanisterMain.idr の case cmd of と完全一致させること
init_schema=0
version=1
write=5
read=6
node_post=20
proximity_set=21
```

## gen-entry が生成するライフサイクル

```c
canister_init:
  ic0_stable64_grow(10);     // Stable Memory 確保
  sql_ffi_open();             // ← --init で指定した関数
  {prefix}_reset_ffi();
  call CMD 0 (init_schema);   // CREATE TABLE IF NOT EXISTS

canister_pre_upgrade:
  sql_ffi_open();             // ← --init で指定
  sqlite_stable_save(1, ic0_time());  // DB → Stable Memory

canister_post_upgrade:
  sql_ffi_open();             // ← --init で指定
  sqlite_stable_load();       // Stable Memory → DB (存在時)
  call CMD 0 (init_schema);   // 新テーブルがあれば追加
```

## gen-entry 能力マトリクス (GE-001 完了)

| パターン | 状態 | 例 |
|---------|------|-----|
| 単一 nat/text/bool | ✅ 対応済 | getVersion, getProposal |
| (nat, text) / (text, nat) | ✅ 対応済 | - |
| N-arg mixed | ✅ 対応済 | submitProposal (7引数) |
| ic0_time 注入 | ✅ 対応済 | postIpProposal |
| ic0_time + offset | ✅ 対応済 | addIpFork |
| 定数注入 | ✅ 対応済 | postIpProposal (voting period) |
| カスタム結果チャネル | ✅ 対応済 | IpFork (ic_str_c_get) |
| canister_heartbeat | ✅ 対応済 | TheWorld heartbeat CMD=20 |

### can.cmd-map アノテーション

```
# 標準
getVersion=1

# ic0_time 注入: arg slot 2 に now, slot 3 に定数 900
postIpProposal=50 @inject_time=2 @inject_const=3:900

# ic0_time + オフセット: slot 3 に now+900
addIpFork=51 @inject_time=2 @inject_time_plus=3:900

# カスタム結果関数
listActiveIps=53 @result_fn=ic_str_c_get
```

TaskTree: `docs/tasktrees/20260314-gen-entry-full-coverage.toml`

## build-canister.sh テンプレート (Step 0)

```bash
# Step 0: canister_entry.c 自動生成
if command -v idris2-icwasm >/dev/null 2>&1; then
    idris2-icwasm gen-entry \
        --did="$PROJECT_DIR/can.did" \
        --prefix=<PREFIX> \
        --lib=libic0 \
        --init=sql_ffi_open \
        --cmd-map="$PROJECT_DIR/can.cmd-map" \
        --out="$BUILD_DIR/canister_entry_gen.c"

    # heartbeat が必要な場合のみ append
    cat >> "$BUILD_DIR/canister_entry_gen.c" << 'HEARTBEAT'
    __attribute__((used, visibility("default"), export_name("canister_heartbeat")))
    void canister_heartbeat(void) { ... }
HEARTBEAT

    CANISTER_ENTRY="$BUILD_DIR/canister_entry_gen.c"
else
    echo "WARNING: idris2-icwasm not found, using hand-written fallback"
    CANISTER_ENTRY="$IC0_SUPPORT/canister_entry.c"
fi
```

## FFI Bridge 命名規則

gen-entry は以下の関数名を期待する:

| gen-entry が呼ぶ関数 | 実装場所 |
|---------------------|---------|
| `{prefix}_c_set_arg_i32(idx, val)` | FFI bridge (xxx_ffi.c) |
| `{prefix}_c_set_arg_str(idx, val)` | FFI bridge |
| `{prefix}_c_get_result_str()` | FFI bridge |
| `{prefix}_c_get_result_i32()` | FFI bridge |
| `{prefix}_c_get_result_u64()` | FFI bridge |
| `{prefix}_reset_ffi()` | FFI bridge |
| `sql_ffi_open()` | sqlite_bridge.c |
| `sqlite_stable_save()` | sqlite_stable.c |
| `sqlite_stable_load()` | sqlite_stable.c |

**命名が違う場合はエイリアス関数を追加** (例: mmnt_ffi.c 参照)。

## SQLite API (SqliteHandle 必須 — 旧 API 廃止)

idris2-icwasm の SQLite は **SqliteHandle** を全操作で要求する。handle なしの旧 API はコンパイルエラー。

### 型シグネチャ

```idris
initSqlite  : StableConfig -> IO SqliteHandle   -- handle 取得の唯一の方法
sqlExec     : SqliteHandle -> String -> IO SqlResult
sqlPrepare  : SqliteHandle -> String -> IO SqlResult
sqlStep     : SqliteHandle -> IO SqlResult
```

- `sqlOpen` は private — 直接呼べない
- `StableConfig` なしに `SqliteHandle` を作れない → stable save 忘れが型レベルで不可能

### 初期化パターン

```idris
import IcWasm.SQLite           -- ✅ (Internal は import しない)

myStableConfig : StableConfig
myStableConfig = MkStableConfig
  { version   = 1      -- schema version
  , startPage = 0      -- stable memory offset
  , maxPages  = 1024   -- 64MB max
  }

-- canister_post_upgrade 相当の初期化
handle <- initSqlite myStableConfig
sqlExec handle "CREATE TABLE IF NOT EXISTS foo (id INTEGER PRIMARY KEY)"
```

### gen-entry との連携

- `--init=sql_ffi_open` を指定 → `canister_pre_upgrade` に `sqlite_stable_save` が自動挿入
- 開発者が stableSave を忘れる余地がない
- timer API: `setGlobalTimer` を使う (heartbeat は使わない — $34,000/月)

### 旧 API (廃止)

```idris
-- ❌ コンパイルエラー: handle 引数が不足
sqlExec "CREATE TABLE ..."

-- ✅ 新 API
sqlExec handle "CREATE TABLE ..."
```

## Stable Memory 永続化パターン

```
canister runtime:
  ┌──────────┐    pre_upgrade    ┌──────────────┐
  │  :memory: │ ──────────────► │ Stable Memory │
  │  SQLite   │                 │  (serialize)  │
  └──────────┘                  └──────────────┘
       ▲                              │
       │        post_upgrade          │
       └──────────────────────────────┘
              (deserialize)
```

- 通常時は `:memory:` SQLite (高速)
- upgrade 直前に `sqlite_stable_save()` で Stable Memory に serialize
- upgrade 直後に `sqlite_stable_load()` で deserialize + `init_schema` で新テーブル追加

## idris2-icwasm インストール

```bash
cd ~/code/idris2-magical-utils && pack install-app idris2-icwasm
HASH=$(ls -t ~/.local/state/pack/install/2be43760d947b6d315de909bc7f44404e3e9de7a/idris2-icwasm/ | head -1)
BIN=~/.local/state/pack/install/2be43760d947b6d315de909bc7f44404e3e9de7a/idris2-icwasm/$HASH/bin
cp $BIN/idris2-icwasm ~/.local/bin/
cp -a $BIN/idris2-icwasm_app/. ~/.local/bin/idris2-icwasm_app/
```

## DFX デプロイ手順

```bash
# identity 切替
dfx identity use mainnet-ouc

# cycles 確認 & 変換
dfx cycles balance --network ic
dfx cycles convert --amount=1 --network ic

# canister 作成 (初回のみ)
dfx canister create <name> --network ic --with-cycles 1000000000000

# WASM インストール (stubbed 版を使う)
dfx canister install <name> --network ic --wasm build/<name>_stubbed.wasm --mode upgrade

# cycles top up
dfx canister deposit-cycles 500000000000 <name> --network ic
```

## 実績

| Canister | ID | 永続化 | gen-entry | Annotations |
|----------|------|--------|-----------|-------------|
| TheWorld | `nrkou-hqaaa-aaaah-qq6qa-cai` | ✅ | ✅ 完全対応 (GE-001) | `@inject_time`, `@inject_const`, `@inject_time_plus`, `@result_fn` |
| mmnt | `dhihu-maaaa-aaaaa-qgada-cai` | ✅ | ✅ 完全対応 (GE-001) | — (heartbeat is build-canister.sh append) |

完全対応 = 手書き canister_entry.c を廃止し、gen-entry + can.cmd-map アノテーションで全メソッドを自動生成。
手書きファイルは `canister_entry_legacy.c` にリネーム保持。

## Inter-Canister Call: IcWasm.InterCanisterCall

`CallCtx Fresh/Called/Replied` の型状態機械で reply-before-call を **コンパイルエラー** にする。

```idris
import IcWasm.InterCanisterCall

-- Correct: deferred reply (cross-subnet safe)
handle : CallCtx Fresh -> IO (Either Int32 (CallCtx Called))
handle ctx = performCall ctx managementCanister "ecdsa_public_key" payload cbs cycles

-- Correct: immediate reply (no call)
simple : CallCtx Fresh -> IO (CallCtx Replied)
simple ctx = replyText ctx "result"

-- TYPE ERROR: reply then call → Mismatch between: Replied and Fresh
-- bad ctx = do { ctx' <- replyText ctx "x"; performCall ctx' ... }
```

### C 実装者向けルール

型で強制される設計だが、C 層を直接触る場合:
- Callback: `void cb(int32_t env)` (NOT `void(void)` → WASM trap)
- Table 登録: `static fn_ptr g = &cb;` + `(int32_t)(uintptr_t)g` = elem index
- Candid hash: `idl_hash(s) = sum(s[i]*223^(len-1-i)) % 2^32` — `pip install ic-py` で検証

## Artifact Verification: IcWasm.Verification

`verify : Artifact f → Deployed f → Maybe (Verified f)` — family 横断の verification 型。

```idris
import IcWasm.Verification

-- EVM (any chain): bytecode hash verification
let art = EvmBytecode (MkHash bytecodeHash) "0.8.28" "paris"
let dep = OnChain 8453 "0xb094..." (MkHash onchainHash)
case verify art dep of
  Just verified => ...  -- hashes match
  Nothing       => ...  -- MISMATCH

-- DFX: WASM module verification
let art = WasmModule (MkHash wasmHash) 1700221
let dep = OnCanister "nrkou-hqaaa-..." (MkHash moduleHash)

-- Full chain with provenance
let prov = MkProvenance "etherclaw" "abc123" sourceHash EVM
case buildChain prov art dep of
  Just chain => chain.verified  -- source → artifact → deployed, all verified
```

Multi-chain EVM: `EvmChainConfig` で Base/Ethereum/Arbitrum 等を切り替え。verification logic は共通。
