# Colony Daemon — Agent Knowledge Base

## Role: TaskTree Execution + Submission + Review Awaiting

Colony is the autonomous execution agent. It receives finalized IPs from
TextDAO governance and converts them into executable TaskTrees.

## TextDAO Proposal Type System

Colony must understand all Proposal types to properly respond to governance decisions:

| Type | Colony Action |
|------|--------------|
| **IPAdoption** | Generate TaskTree from finalized IP → execute → submit PR |
| **TokenTransfer** | No direct action (treasury operation) |
| **CycleTopUp** | Colony auto-generates this proposal when cycles < threshold |
| **ParameterChange** | Reload configuration after parameter update |

## Fork Cycle Understanding

- 1 Proposal = 1 Purpose (never mix purposes in a single Proposal)
- Fork = Alternative expression of the same purpose
- Borda Rule selects top 3 Forks per Tally round
- Iteration continues until convergence
- Finalize triggers the execution hook

### Colony's Role in Fork Cycle

1. **Monitor** — Watch for IPAdoption finalization events
2. **Generate** — Convert finalized IP into TaskTree TOML
3. **Execute** — Run TaskTree via `etherclaw daemon --seed`
4. **Submit** — Create PR with implementation
5. **Await** — Wait for Reviewer approval

## CycleTopUp Auto-Proposal

Colony monitors canister cycles and automatically creates CycleTopUp proposals:

1. **Detect** — Canister cycles fall below `cycles_threshold` (see DAO_CONFIG.md)
2. **Propose** — Create CycleTopUp proposal in TextDAO
3. **Vote** — Shareholders vote on the top-up amount
4. **Execute** — If approved, CMC converts ICP → cycles

This ensures continuous canister operation without manual intervention.

## mmnt Integration

Colony reads mmnt for context:
- Discover relevant discussions about upcoming IPs
- Read Fork comparisons for implementation guidance
- Post progress updates to mmnt feed

## Economic Motivation

- **External (outward)**: Implement IPs → receive rewards from instance
- **Internal (inward)**: Propose improvements to EtherClaw itself → receive CLAW allocation if approved

## Self-Healing Pattern

When an agent encounters build errors or acceptance check failures after 2+ retries:

1. `etherclaw amending --dry-run` — Run obstacle analysis to identify root cause
2. Review the generated TaskTree in `docs/tasktrees/*-amend-fix.toml`
3. The fix TaskTree is auto-registered in ETHERCLAW.toml and executed in the next loop

This "amending escalation" runs automatically in `etherclaw daemon --standalone`.
In manual sessions, follow the same pattern when stuck on repeated failures.

## ENS

- Instance: `td.onthe.eth`
- Resolve: `etherclaw resolve td.onthe.eth`

## Colony Daemon の Cycles 節約ルール

- governed mode: mmnt 呼び出しをスキップ (`proximity_get` 禁止)
- IP ポーリング間隔: 30s (これ以上短くしない)
- `postEventToMmnt`: governed mode ではスキップ
- IC0207 検出時: circuit breaker で mmnt 呼び出しを停止
- query call も canister の compute cycles を消費する — ポーリング頻度を最小限に

## Colony が Idris2 で SQLite を使う際のルール

```idris
-- ✅ 正しい import
import IcWasm.SQLite

-- ❌ 間違い (Internal は private)
-- import IcWasm.SQLite.Internal

-- 初期化
handle <- initSqlite (MkStableConfig 1 0 1024)

-- SQL 実行 (全て handle 必須)
sqlExec handle "CREATE TABLE IF NOT EXISTS ..."
sqlPrepare handle "SELECT ..."
sqlStep handle
```

- `import IcWasm.SQLite` を使う (`IcWasm.SQLite.Internal` は使わない)
- `handle <- initSqlite (MkStableConfig version startPage maxPages)` で開始
- `sqlExec handle "..."` / `sqlPrepare handle "..."` / `sqlStep handle`
- `sqlOpen` を直接呼ばない (private — コンパイルエラーになる)
- 旧 API (`sqlExec "SQL"` — handle なし) は廃止済み

## Colony が IC inter-canister call を使う際のルール

```idris
import IcWasm.InterCanisterCall

-- ✅ Deferred Reply (cross-subnet safe)
handle : CallCtx Fresh -> IO (Either Int32 (CallCtx Called))
handle ctx = performCall ctx managementCanister method payload cbs cycles
-- callback が ic0.msg_reply を呼ぶ。ここでは reply しない。

-- ❌ TYPE ERROR: reply してから call (cross-subnet call が silent drop)
-- bad ctx = do { ctx' <- replyText ctx "pending"; performCall ctx' ... }
-- → Mismatch between: Replied and Fresh
```

## Colony が EVM address を扱う際のルール

```idris
import IcWasm.EvmAddress

-- ICP ecdsa_public_key は compressed SEC1 (33 bytes) を返す
-- compressed key から直接 address を導出すると間違った address になる (ETH lost)
-- ✅ decompress してから deriveAddress
case parseSec1 rawBytes of
  Right (ParsedCompressed key) => do
    Right uncompressed <- decompress key
    let addr = deriveAddress uncompressed keccak256
    ...

-- ❌ TYPE ERROR: compressed key で deriveAddress
-- deriveAddress compressedKey keccak256  → Expected Uncompressed, got Compressed
```

## Colony がリリース verification を扱う際のルール

```idris
import IcWasm.Verification

-- Family 横断: EVM / DFX / Core / Web 全て同じ型
let art = EvmBytecode (MkHash bytecodeHash) "0.8.28" "paris"
let dep = OnChain 8453 "0xb094..." (MkHash onchainHash)
case verify art dep of
  Just verified => ...  -- hash 一致 → verified
  Nothing       => ...  -- MISMATCH → release blocked

-- VerificationChain: source → artifact → deployed の完全トレーサビリティ
let prov = MkProvenance "etherclaw" commitHash sourceHash EVM
case buildChain prov art dep of
  Just chain => chain.verified
  Nothing    => -- verification 失敗
```
