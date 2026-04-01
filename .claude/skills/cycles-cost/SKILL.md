# Cycles Cost Awareness

## Trigger
- ICP canister 操作 (query/update call)
- ポーリングループの設計・実装
- daemon / flow コマンドの interval 設定
- デモ準備

## ICP Cycles の消費モデル

### Query Call
- **Caller**: 無料 (cycles 不要)
- **Canister**: compute cycles を消費する (**無料ではない**)
- query は consensus 不要だが、canister の CPU instruction に応じて cycles が引かれる
- 頻繁な query ポーリングで canister の cycles が枯渇する

### Update Call
- **Caller**: ingress message fee を消費
- **Canister**: compute + storage cycles を消費

### 重要な誤解の訂正
> "query は無料" → **caller にとっては無料だが、canister にとっては無料ではない**

## ポーリング頻度ルール

| コマンド | 最小間隔 | 理由 |
|---------|---------|------|
| `etherclaw flow --watch` | 30s | canister compute cycles 節約 |
| daemon heartbeat polling | 30s | 同上 |
| `proximity_get` | **使用禁止** | instruction limit 超過リスク (IC0522) |

- 30s 未満のポーリング間隔を設定してはならない
- `proximity_get` はポーリングループ内で呼んではならない (IC0522: Canister trapped explicitly: instruction limit exceeded)

## デモ前チェックリスト

```bash
# cycles 残高確認
dfx canister status nrkou-hqaaa-aaaah-qq6qa-cai --network ic  # TheWorld: 5T+ 必要
dfx canister status dhihu-maaaa-aaaaa-qgada-cai --network ic  # mmnt: 1T+ 必要

# 不足時の補充
dfx cycles convert --amount=1 --network ic
dfx canister deposit-cycles <canister-id> --network ic <amount>
```

## cycles 枯渇時の症状

- `IC0522`: instruction limit exceeded (compute cycles 不足)
- `IC0207`: Canister has no cycles to process the message (cycles 完全枯渇)
- `SYS_TRANSIENT`: 一時的なシステムエラー (cycles 関連の場合あり)

## Circuit Breaker パターン

IC0207 を検出したら、そのcanisterへの呼び出しを即座に停止する:

1. IC0207 エラーをキャッチ
2. 該当 canister への呼び出しを停止 (circuit open)
3. `dfx canister status` で残高確認
4. cycles 補充後に呼び出し再開 (circuit close)
