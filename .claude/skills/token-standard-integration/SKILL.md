---
name: token-standard-integration
description: ICRC-1/ICRC-2/ERC-20 準拠トークンシステム設計 — TheWorld/InstanceRegistry SQLiteスキーマ、トークン正規化
triggers:
  - ICRC-1
  - ICRC-2
  - ERC-20
  - token standard
  - トークン標準
  - token design
  - トークン設計
  - InstanceRegistry
  - token table
  - トークンテーブル
  - colony token
  - ETHERCLAW token
---
# Token Standard Integration Skill

ICRC-1/ICRC-2/ERC-20 準拠のトークンシステム設計とER統合

## Overview

このSkillは、A-Lifeプロジェクトのトークン設計がICP (ICRC-1/ICRC-2) およびEVM (ERC-20) の標準規格に準拠するための知識を提供します。TheWorld/InstanceRegistry CanisterのSQLiteスキーマ設計において、トークン関連テーブルの正規化と標準インターフェース実装をガイドします。

## Token Architecture

### Dual-Layer Token System

A-Lifeは2層のトークン構造を持ちます:

1. **ETHERCLAW** (グローバルトークン)
   - 全ネットワークで単一
   - c_gov (グローバルガバナンス) の投票力
   - Colony Memory Stake
   - Auditor Reputation

2. **$t^i$** (インスタンストークン)
   - Agent i ごとに発行
   - c^i_share (インスタンス経済ガバナンス) の投票力
   - Instance固有の経済圏

```
┌─────────────────────────────────────────────┐
│  ETHERCLAW (token_type='etherclaw')         │
│  - Global governance (c_gov)                │
│  - Colony/Auditor stakes                    │
│  - Total supply: fixed                      │
└─────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│  Instance Tokens ($t^i$)                    │
│  token_type='instance', instance_id FK      │
│  - Instance-specific governance (c^i_share) │
│  - Economic incentive alignment             │
│  - Total supply: per-instance configured    │
└─────────────────────────────────────────────┘
```

## Token Standards

### ICRC-1: Fungible Token Standard (ICP)

**必須メタデータ**:
- `icrc1_name()` → `tokens.token_name`
- `icrc1_symbol()` → `tokens.token_symbol`
- `icrc1_decimals()` → `tokens.decimals` (通常8)
- `icrc1_total_supply()` → `tokens.total_supply`
- `icrc1_fee()` → `tokens.fee` (transfer手数料)
- `icrc1_metadata()` → `tokens.metadata` (JSON)

**Account モデル**:
```candid
type Account = record {
  owner : principal;
  subaccount : opt blob;  -- 32 bytes or NULL
};
```

**Transfer操作**:
```candid
type TransferArgs = record {
  from_subaccount : opt blob;
  to : Account;
  amount : nat;
  fee : opt nat;
  memo : opt blob;
  created_at_time : opt nat64;  -- idempotency key
};
```

### ICRC-2: Approve/TransferFrom Extension (ICP)

ERC-20の `approve()` / `transferFrom()` 相当:

```candid
type ApproveArgs = record {
  from_subaccount : opt blob;
  spender : Account;
  amount : nat;
  expires_at : opt nat64;
  fee : opt nat;
  memo : opt blob;
  created_at_time : opt nat64;
};

icrc2_approve : (ApproveArgs) -> variant { Ok : nat; Err : ApproveError };
icrc2_transfer_from : (TransferFromArgs) -> variant { Ok : nat; Err : TransferFromError };
icrc2_allowance : (AllowanceArgs) -> Allowance query;
```

### ERC-20: Ethereum Token Standard

**基本インターフェース**:
```solidity
interface IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
```

## ER Schema Design (3NF Normalized)

### 1. tokens テーブル (メタデータ)

```sql
CREATE TABLE tokens (
  token_id TEXT PRIMARY KEY,
  token_type TEXT NOT NULL CHECK(token_type IN ('etherclaw', 'instance')),

  -- ICRC-1 / ERC-20 共通メタデータ
  token_name TEXT NOT NULL,
  token_symbol TEXT NOT NULL,
  decimals INTEGER NOT NULL DEFAULT 8,
  total_supply TEXT NOT NULL,  -- BigInt as TEXT
  fee TEXT NOT NULL DEFAULT '10000',  -- 0.0001 with 8 decimals

  -- Instance token
  instance_id TEXT NULL,

  -- EVM deployment (multi-chain support)
  chain_id INTEGER NULL,
  contract_address TEXT NULL,

  -- ICRC-1 metadata (JSON)
  metadata TEXT,  -- [{"key": "logo", "value": "data:image/svg+xml;base64,..."}]

  created_at INTEGER NOT NULL,

  FOREIGN KEY (instance_id) REFERENCES instances(instance_id) ON DELETE CASCADE,
  FOREIGN KEY (chain_id) REFERENCES chains(chain_id),

  CHECK (
    (token_type = 'etherclaw' AND instance_id IS NULL)
    OR
    (token_type = 'instance' AND instance_id IS NOT NULL)
  ),

  UNIQUE(instance_id) WHERE token_type = 'instance'
);
```

**Design Rationale**:
- `total_supply` / `fee` は TEXT 型 (SQLiteにBigInt型がないため、文字列としてnubber-bigintで扱う)
- `metadata` はJSON (ICRC-1 `vec record { text; Value }` をシリアライズ)
- `chain_id` / `contract_address` はEVMブリッジ用 (NULLable)

### 2. token_balances テーブル (ICRC-1 Account 対応)

```sql
CREATE TABLE token_balances (
  balance_id INTEGER PRIMARY KEY AUTOINCREMENT,
  token_id TEXT NOT NULL,

  -- ICRC-1 Account
  owner_principal TEXT NOT NULL,
  subaccount BLOB NULL,  -- 32 bytes or NULL (default subaccount)

  balance TEXT NOT NULL,  -- BigInt as TEXT

  -- Staking (ETHERCLAW のみ使用)
  staked_amount TEXT NOT NULL DEFAULT '0',
  stake_locked_until INTEGER NULL,

  updated_at INTEGER NOT NULL,

  FOREIGN KEY (token_id) REFERENCES tokens(token_id) ON DELETE CASCADE,

  UNIQUE(token_id, owner_principal, subaccount)
);

CREATE INDEX idx_balances_owner ON token_balances(owner_principal);
CREATE INDEX idx_balances_token ON token_balances(token_id);
```

**Design Rationale**:
- ICRC-1 Account = (owner_principal, subaccount) の複合キー
- `subaccount` がNULLの場合はデフォルトサブアカウント
- `staked_amount` / `stake_locked_until` はETHERCLAWのStaking用 (instance tokenでは未使用)

### 3. token_transactions テーブル (ICRC-1 TransferArgs 対応)

```sql
CREATE TABLE token_transactions (
  tx_id INTEGER PRIMARY KEY AUTOINCREMENT,
  token_id TEXT NOT NULL,

  tx_type TEXT NOT NULL
    CHECK(tx_type IN ('transfer', 'mint', 'burn', 'stake', 'unstake', 'reward', 'approve', 'transfer_from')),

  -- From Account (ICRC-1)
  from_owner_principal TEXT NULL,
  from_subaccount BLOB NULL,

  -- To Account (ICRC-1)
  to_owner_principal TEXT NULL,
  to_subaccount BLOB NULL,

  amount TEXT NOT NULL,
  fee TEXT NULL,
  memo BLOB NULL,
  created_at_time INTEGER NULL,  -- ICRC-1 idempotency key

  -- Context
  related_proposal_id INTEGER NULL,

  timestamp INTEGER NOT NULL,

  FOREIGN KEY (token_id) REFERENCES tokens(token_id) ON DELETE CASCADE,
  FOREIGN KEY (related_proposal_id) REFERENCES proposals(proposal_id),

  CHECK (
    (tx_type = 'mint' AND from_owner_principal IS NULL)
    OR
    (tx_type = 'burn' AND to_owner_principal IS NULL)
    OR
    (tx_type NOT IN ('mint', 'burn'))
  )
);

CREATE INDEX idx_tx_token ON token_transactions(token_id);
CREATE INDEX idx_tx_from ON token_transactions(from_owner_principal);
CREATE INDEX idx_tx_to ON token_transactions(to_owner_principal);
CREATE INDEX idx_tx_timestamp ON token_transactions(timestamp);

-- ICRC-1 idempotency: created_at_time が同じなら重複排除
CREATE UNIQUE INDEX idx_tx_idempotency
  ON token_transactions(token_id, from_owner_principal, from_subaccount, created_at_time)
  WHERE created_at_time IS NOT NULL;
```

**Design Rationale**:
- `created_at_time` はICRC-1のidempotency key (同一リクエストの重複実行を防ぐ)
- `mint` は from が NULL、`burn` は to が NULL (CHECK制約で保証)
- `related_proposal_id` はガバナンス起因のtransfer追跡用

### 4. token_allowances テーブル (ICRC-2 / ERC-20)

```sql
CREATE TABLE token_allowances (
  allowance_id INTEGER PRIMARY KEY AUTOINCREMENT,
  token_id TEXT NOT NULL,

  -- Owner (spender に転送を許可する側)
  owner_principal TEXT NOT NULL,
  owner_subaccount BLOB NULL,

  -- Spender (転送を許可される側)
  spender_principal TEXT NOT NULL,
  spender_subaccount BLOB NULL,

  -- Allowance
  amount TEXT NOT NULL,  -- BigInt as TEXT
  expires_at INTEGER NULL,  -- ICRC-2 expiration

  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,

  FOREIGN KEY (token_id) REFERENCES tokens(token_id) ON DELETE CASCADE,

  UNIQUE(token_id, owner_principal, owner_subaccount, spender_principal, spender_subaccount)
);

CREATE INDEX idx_allowances_owner ON token_allowances(token_id, owner_principal, owner_subaccount);
CREATE INDEX idx_allowances_spender ON token_allowances(token_id, spender_principal, spender_subaccount);
```

**Design Rationale**:
- ICRC-2の `expires_at` をサポート (ERC-20にはない機能)
- 複合UNIQUE制約でallowance重複を防ぐ

## Candid Interface Implementation

### InstanceRegistry as Multi-Token Ledger

```candid
// can.did に追加
type Account = record {
  owner : principal;
  subaccount : opt blob;
};

type TransferArgs = record {
  from_subaccount : opt blob;
  to : Account;
  amount : nat;
  fee : opt nat;
  memo : opt blob;
  created_at_time : opt nat64;
};

type TransferError = variant {
  BadFee : record { expected_fee : nat };
  BadBurn : record { min_burn_amount : nat };
  InsufficientFunds : record { balance : nat };
  TooOld;
  CreatedInFuture : record { ledger_time : nat64 };
  Duplicate : record { duplicate_of : nat };
  TemporarilyUnavailable;
  GenericError : record { error_code : nat; message : text };
};

service : {
  // Multi-token ICRC-1 (token_id で切り替え)
  icrc1_name : (token_id : text) -> (text) query;
  icrc1_symbol : (token_id : text) -> (text) query;
  icrc1_decimals : (token_id : text) -> (nat8) query;
  icrc1_total_supply : (token_id : text) -> (nat) query;
  icrc1_fee : (token_id : text) -> (nat) query;
  icrc1_balance_of : (token_id : text, account : Account) -> (nat) query;
  icrc1_transfer : (token_id : text, args : TransferArgs) -> (variant { Ok : nat; Err : TransferError });
  icrc1_metadata : (token_id : text) -> (vec record { text; Value }) query;

  // ICRC-2 Extension (optional)
  icrc2_approve : (token_id : text, args : ApproveArgs) -> (variant { Ok : nat; Err : ApproveError });
  icrc2_transfer_from : (token_id : text, args : TransferFromArgs) -> (variant { Ok : nat; Err : TransferFromError });
  icrc2_allowance : (token_id : text, args : AllowanceArgs) -> (Allowance) query;
}
```

### SQL Query Patterns

**`icrc1_balance_of(token_id, account)` の実装**:

```idris
icrc1BalanceOf : TokenId -> Account -> InstanceRegistryM Nat
icrc1BalanceOf tokenId (MkAccount owner subacct) = do
  rows <- execQuery "SELECT balance FROM token_balances WHERE token_id = ? AND owner_principal = ? AND subaccount IS ?"
                    [tokenId, owner, subacct]
  case rows of
    [balance] => pure (parseNat balance)
    [] => pure 0
    _ => throwError "Multiple balances found"
```

**`icrc1_transfer(token_id, args)` の実装**:

```idris
icrc1Transfer : TokenId -> TransferArgs -> InstanceRegistryM (Either TransferError Nat)
icrc1Transfer tokenId args = do
  -- 1. Check idempotency
  whenJust args.created_at_time $ \ts => do
    existing <- execQuery "SELECT tx_id FROM token_transactions WHERE token_id = ? AND created_at_time = ?" [tokenId, show ts]
    whenJust existing $ \txId => pure (Left $ Duplicate txId)

  -- 2. Check balance
  fromBalance <- icrc1BalanceOf tokenId (MkAccount args.from args.from_subaccount)
  let totalAmount = args.amount + fromMaybe defaultFee args.fee
  when (fromBalance < totalAmount) $ pure (Left $ InsufficientFunds fromBalance)

  -- 3. Execute transfer
  txId <- insertTransaction tokenId "transfer" args
  updateBalance tokenId (args.from, args.from_subaccount) (negate totalAmount)
  updateBalance tokenId (args.to.owner, args.to.subaccount) args.amount

  pure (Right txId)
```

## Multi-Chain Token Synchronization

### ICP → EVM (HTTP Outcall)

```idris
-- ETHERCLAW を EVM にミント (HTTP Outcall経由)
syncTokenToEVM : TokenId -> ChainId -> Account -> Nat -> InstanceRegistryM ()
syncTokenToEVM tokenId chainId recipient amount = do
  -- 1. Get EVM contract address
  contractAddr <- getContractAddress tokenId chainId

  -- 2. Build ERC-20 mint calldata
  let calldata = encodeMintCall recipient amount

  -- 3. HTTP Outcall to execute transaction
  httpOutcall $ MkEvmTxRequest {
    chainId = chainId,
    to = contractAddr,
    data = calldata,
    gasLimit = 100000
  }

  -- 4. Log sync event
  insertEvent "TokenSyncToEVM" $ show (tokenId, chainId, recipient, amount)
```

### EVM → ICP (Event Indexing)

```idris
-- EVM Transfer イベントを ICP に反映
indexEvmTransferEvents : ChainId -> BlockNumber -> InstanceRegistryM ()
indexEvmTransferEvents chainId fromBlock = do
  -- 1. HTTP Outcall to get ERC-20 Transfer events
  events <- httpOutcall $ MkEvmGetLogsRequest {
    chainId = chainId,
    fromBlock = fromBlock,
    topics = ["Transfer(address,address,uint256)"]
  }

  -- 2. Parse and insert to token_transactions
  forM_ events $ \event => do
    let (from, to, amount) = parseTransferEvent event
    insertTransaction tokenId "transfer" $ MkTransferArgs {
      from_owner_principal = evmAddressToPrincipal from,
      to = MkAccount (evmAddressToPrincipal to) Nothing,
      amount = amount,
      memo = Just (encode event.transactionHash)
    }
```

## Migration Guide

### Phase 1: Add Missing Columns

```sql
-- tokens テーブル拡張
ALTER TABLE tokens ADD COLUMN decimals INTEGER NOT NULL DEFAULT 8;
ALTER TABLE tokens ADD COLUMN fee TEXT NOT NULL DEFAULT '10000';
ALTER TABLE tokens ADD COLUMN metadata TEXT;

-- token_balances に subaccount 追加
ALTER TABLE token_balances ADD COLUMN subaccount BLOB NULL;

-- UNIQUE制約の再作成
DROP INDEX IF EXISTS idx_balances_unique;
CREATE UNIQUE INDEX idx_balances_unique ON token_balances(token_id, owner_principal, subaccount);
```

### Phase 2: Add ICRC-1 Idempotency

```sql
-- token_transactions に created_at_time 追加
ALTER TABLE token_transactions ADD COLUMN created_at_time INTEGER NULL;

-- idempotency index
CREATE UNIQUE INDEX idx_tx_idempotency
  ON token_transactions(token_id, from_owner_principal, from_subaccount, created_at_time)
  WHERE created_at_time IS NOT NULL;
```

### Phase 3: Add ICRC-2 Support

```sql
-- token_allowances テーブル新規作成
CREATE TABLE token_allowances (
  allowance_id INTEGER PRIMARY KEY AUTOINCREMENT,
  token_id TEXT NOT NULL,
  owner_principal TEXT NOT NULL,
  owner_subaccount BLOB NULL,
  spender_principal TEXT NOT NULL,
  spender_subaccount BLOB NULL,
  amount TEXT NOT NULL,
  expires_at INTEGER NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (token_id) REFERENCES tokens(token_id) ON DELETE CASCADE,
  UNIQUE(token_id, owner_principal, owner_subaccount, spender_principal, spender_subaccount)
);
```

### Phase 4: Candid Interface Update

```diff
 service : {
+  // ICRC-1 Standard
+  icrc1_name : (token_id : text) -> (text) query;
+  icrc1_symbol : (token_id : text) -> (text) query;
+  icrc1_decimals : (token_id : text) -> (nat8) query;
+  icrc1_total_supply : (token_id : text) -> (nat) query;
+  icrc1_fee : (token_id : text) -> (nat) query;
+  icrc1_balance_of : (token_id : text, account : Account) -> (nat) query;
+  icrc1_transfer : (token_id : text, args : TransferArgs) -> (variant { Ok : nat; Err : TransferError });
+  icrc1_metadata : (token_id : text) -> (vec record { text; Value }) query;
 }
```

## Best Practices

### 1. BigInt as TEXT Pattern

SQLiteにBigInt型がないため、TEXT型で保存してIdris2の `Data.BigInt` で処理:

```idris
-- TEXT → BigInt
parseBalance : String -> BigInt
parseBalance str = fromMaybe 0 (parseBigInt str)

-- BigInt → TEXT
showBalance : BigInt -> String
showBalance = show
```

### 2. Subaccount Handling

ICRC-1のsubaccountは32 bytesだが、NULLの場合はデフォルトサブアカウント:

```idris
normalizeSubaccount : Maybe Blob -> Maybe Blob
normalizeSubaccount Nothing = Nothing
normalizeSubaccount (Just b) =
  if length b == 32 then Just b else Nothing
```

### 3. Fee Calculation

ICRC-1では `fee` はoptional。未指定の場合はtokens.feeを使用:

```idris
calculateFee : TokenId -> Maybe Nat -> InstanceRegistryM Nat
calculateFee tokenId (Just fee) = pure fee
calculateFee tokenId Nothing = do
  rows <- execQuery "SELECT fee FROM tokens WHERE token_id = ?" [tokenId]
  case rows of
    [feeStr] => pure (parseNat feeStr)
    _ => throwError "Token not found"
```

### 4. Idempotency Check

`created_at_time` が同じリクエストは重複実行を防ぐ:

```idris
checkIdempotency : TokenId -> Maybe Nat64 -> InstanceRegistryM (Maybe TxId)
checkIdempotency tokenId Nothing = pure Nothing
checkIdempotency tokenId (Just ts) = do
  rows <- execQuery "SELECT tx_id FROM token_transactions WHERE token_id = ? AND created_at_time = ?"
                    [tokenId, show ts]
  case rows of
    [txId] => pure (Just txId)
    [] => pure Nothing
```

## Testing Checklist

### ICRC-1 Compliance

- [ ] `icrc1_name()` / `icrc1_symbol()` がtokensテーブルから正しく取得
- [ ] `icrc1_decimals()` が8 (またはカスタム値) を返す
- [ ] `icrc1_total_supply()` が全balanceの合計と一致
- [ ] `icrc1_balance_of()` がsubaccount対応
- [ ] `icrc1_transfer()` がidempotency対応 (同じcreated_at_timeで重複実行しない)
- [ ] `icrc1_metadata()` がJSON → Candid Value変換

### ICRC-2 Compliance

- [ ] `icrc2_approve()` がtoken_allowancesに正しく記録
- [ ] `icrc2_transfer_from()` がallowanceを消費
- [ ] `icrc2_allowance()` がexpires_at考慮

### ERC-20 Mapping

- [ ] EVM contractアドレスがtokensテーブルに記録
- [ ] HTTP Outcallでmint/transfer実行
- [ ] Event indexingでEVM → ICP同期

## References

- [ICRC-1 Specification](https://github.com/dfinity/ICRC-1)
- [ICRC-2 Specification](https://github.com/dfinity/ICRC-1/blob/main/standards/ICRC-2/README.md)
- [ERC-20 Token Standard](https://eips.ethereum.org/EIPS/eip-20)
- [ICP HTTP Outcalls](https://internetcomputer.org/docs/current/developer-docs/integrations/https-outcalls/)

## When to Use This Skill

このSkillは以下の状況で発動:

- [ ] `tokens`, `token_balances`, `token_transactions`, `token_allowances` テーブル編集時
- [ ] `can.did` にICRC-1/ICRC-2インターフェース追加時
- [ ] EVM ↔ ICP トークンブリッジ実装時
- [ ] `lazy dfx init --token` コマンド実行時
- [ ] トークン関連のガバナンス提案実装時

**自動発動トリガー**:
- File pattern: `**/Token/**/*.idr`, `**/can.did`
- SQL keyword: `CREATE TABLE token`, `ALTER TABLE token`
- Candid keyword: `icrc1_`, `icrc2_`
