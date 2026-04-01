---
name: halt-coverage
description: 自律稼働性を担保するHaltCoverage測定と改善 — H1-H24 halt states、α_H、γ_H
triggers:
  - HaltCoverage
  - halt coverage
  - ホルトカバレッジ
  - autonomy rate
  - 自律回復率
  - α_H
  - H1-H24
  - halt state
  - 停止状態
  - γ_H
  - halt handler
  - ハンドラ網羅度
---
# HaltCoverage Skill

自律稼働性を担保するためのHaltCoverage測定と改善

## Triggers

- `HaltCoverage`, `halt coverage`, `ホルトカバレッジ`
- `autonomy rate`, `自律回復率`, `α_H`
- `H1-H24`, `halt state`, `停止状態`
- `γ_H`, `halt handler`, `ハンドラ網羅度`

## Overview

HaltCoverageは、A-Lifeシステムの24種のHalt状態(H1-H24)に対するハンドラの網羅度を測定する指標。

**用語の区別:**

| 用語 | 意味 |
|------|------|
| **HaltCoverage (γ_H)** | Halt状態のハンドラ網羅度 (本Skill) |
| **TestCoverage** | コードパスのテスト網羅度 (idris2-coverage) |
| **Totality** | Idris2の停止性・網羅性検査 |

## Key Metrics

### 現状 (2025-01-26)

| 指標 | 値 | 定義 |
|------|-----|------|
| α_H (自律回復率) | **12.5%** | autoRecoverable / totalHalts |
| γ_H (全体HaltCoverage) | **33.3%** | handled / totalHalts |
| α_max (最大自律回復率) | **87.5%** | (24 - 3) / 24 |

### 本質的人間依存 (essentialHumanDependency)

以下の3つはγ_H = 1.0でも自動回復不可能:

- **H5 (KeyCompromise)**: 新鍵の正当性は人間のみが判断可能
- **H6 (AuditFailed)**: コードの「正しさ」の最終判断は人間
- **H9 (Dead)**: 終端状態、回復不可能

## Boundary Coverage Table

| Boundary | γ_H(b) | Halts | Priority |
|----------|--------|-------|----------|
| B_EvmRpc | **0.75** | H12, H13, H20, H24 | ✓ |
| B_Governance | 0.43 | H6-H11, H14 | P2 |
| B_Build | 0.20 | H15-H19 | P3 |
| B_AGA | **0.00** | H1-H4 | **P1** |
| B_Crypto | **0.00** | H5 | **P1** |
| B_IcpCall | 0.00 | H21 | P3 |
| B_StableMemory | 0.00 | H23 | P3 |

## Type Definitions

`Governance/Core.idr` に以下の型が定義済み:

```idris
-- 界面
data Boundary = B_EvmRpc | B_IcpCall | B_StableMemory | B_Candid
              | B_Governance | B_Crypto | B_Build | B_AGA

-- Halt ID (H1-H24)
data HaltId = H1_InfiniteLoop | ... | H24_NetworkPartition

-- Recovery Type
data RecoveryType = AutoRecoverable | HumanRecoverable | Terminal

-- HaltCoverage測定
record HaltCoverage
record BoundaryHaltCoverage
record SystemHaltCoverage

-- 自律回復率
autonomyRate : SystemHaltCoverage -> Double

-- 最大自律回復率
maxAutonomyRate : Double  -- 0.875

-- 本質的人間依存
essentialHumanDependency : List HaltId  -- [H5, H6, H9]
```

## HaltCoverage-Autonomy Hypothesis (RQ3.1.2)

$$
\gamma_H(b) \uparrow \implies \alpha_H(b) \uparrow
$$

現状データ:
- B_EvmRpc: γ_H = 0.75, autoRecoverable = 2 (H20, H24)
- B_AGA: γ_H = 0.00, autoRecoverable = 0

仮説を支持: 高いHaltCoverageを持つ界面は高い自律回復率を持つ。

## Improvement Actions

### P1: B_AGA HaltCoverage改善

| Halt | 現状 | アクション |
|------|------|----------|
| H1 (InfiniteLoop) | NoHandler | lazy core ask 結果の連続Gap検出 → FR Monad化 |
| H2 (UnresolvableUrgent) | NoHandler | Gap種別の自動分類 → 複数解決パス定義 |
| H3 (LazyCliCrash) | NoHandler | ビルド状態監視 → 自動rebuild |
| H4 (SchemaInconsistency) | NoHandler | Config validation → 自動修正提案 |

### P1: B_Crypto HaltCoverage改善

| Halt | 現状 | アクション |
|------|------|----------|
| H5 (KeyCompromise) | NoHandler | 鍵漏洩検出ロジック (異常署名パターン) |

Note: H5は検出のみ。回復は人間必須 (essentialHumanDependency)。

### P2: B_Governance HaltCoverage改善

| Halt | 現状 | アクション |
|------|------|----------|
| H10 (UpgradeRejected) | NoHandler | InstanceFactoryイベント監視 → 提案見直しフロー |
| H11 (ThresholdTimeout) | NoHandler | 投票期限監視 → Auditor追加提案 |

## Measurement Commands

```bash
# HaltCoverage測定レポート確認
cat docs/halt-coverage-measurement.md

# 型定義確認
grep -A 50 "HALT COVERAGE MEASUREMENT" pkgs/Idris2TheWorld/src/Governance/Core.idr

# 界面別Halt一覧
grep "haltBoundary" pkgs/Idris2TheWorld/src/Governance/Core.idr
```

## Skill Chaining

| 状況 | 連鎖先Skill |
|------|-------------|
| H5-H9 検出 | theworld-monitor → governance-decision |
| H1-H4 検出 | aga-loop → failure-recovery |
| H20, H24 発生 | etherclaw-crosschain (リトライ) |
| HaltCoverage改善後 | idris2-dev (実装) |

## Documentation

- `docs/halt-coverage-measurement.md`: 詳細測定レポート
- `docs/research-question-tree.md`: RQ3.1.1成果
- `docs/halt-state-analysis.md`: Halt状態の網羅的分析

## Autonomy Proof Goal

HaltCoverageを改善することで、以下を型レベルで証明可能:

```idris
||| 自律稼働の証明: 本質的人間依存以外の全Haltにハンドラ存在
AutonomyProof : SystemHaltCoverage -> Type
AutonomyProof sc =
  ( frHaltCoverageRate sc >= maxAutonomyRate
  , all (\h => elem h essentialHumanDependency || hasHandler h) allHaltIds
  )
```

目標: γ_H = 0.875 (21/24) を達成し、「人間が必要なのは本質的に不可避な3ケース (H5, H6, H9) のみ」を証明。
