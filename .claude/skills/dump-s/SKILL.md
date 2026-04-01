---
name: dump-s
description: etherclaw dump-s — ETHERCLAW.toml の [[lazy]] 全パッケージの仕様を集約出力
triggers:
  - dump-s
  - dump specs
  - spec document
  - 仕様出力
  - 仕様集約
  - aggregate specs
---

# dump-s Skill — EtherClaw 仕様文書集約

## 概要

`etherclaw dump-s` は ETHERCLAW.toml の `[[lazy]]` エントリを横断し、
各パッケージの SPEC.toml 要件を統合 Markdown ドキュメントとして出力する。

## コマンド

```bash
etherclaw dump-s    # [[lazy]] 全パッケージの仕様を集約出力
```

内部では各 `[[lazy]]` entry に対して `lazy <family> dump-s <target>` を実行し、
結果を結合する。

## ETHERCLAW.toml の [[lazy]] entries

```toml
[[lazy]]
target    = "pkgs/EtherClaw"
family    = "core"

[[lazy]]
target    = "pkgs/LazyEvm"
family    = "evm"
```

## 出力例

```markdown
# EtherClaw Spec Document (EC — EtherClaw)

## pkgs/EtherClaw (family: core)

# Project Specs: pkgs/EtherClaw

## Module: Commands
- [REQ_CMD_001] Daemon standalone mode
- [REQ_CMD_002] Brainstorm multi-agent

---

## pkgs/LazyEvm (family: evm)

# Project Specs: pkgs/LazyEvm

## Module: Ask
- [REQ_ASK_001] EVM contract analysis

---
Total: 2 packages
```

## AI エージェントへのコンテキスト注入

### 直接注入 (CLAUDE.md / Skill に貼り付け)

```bash
etherclaw dump-s | head -2000
# → CLAUDE.md やスキルファイルにペースト
```

### 動的注入 (実行時にコンテキスト取得)

AI エージェントが実行時に `etherclaw dump-s` を実行してプロジェクト全体の仕様を把握:

```bash
etherclaw dump-s 2>/dev/null
```

## SPEC.toml フォーマット (必須)

**`[[requirement]]` / `[[requirement_area]]` は deprecated — 使用禁止。**
`lazy dump-s` は deprecated terminology を検出するとそのファイルを一切処理せず `Total: 0 specs` を返す。

### 正しいフォーマット

```toml
[definitions]
prefix = "REQ_MYMOD"

[[spec_area]]
name = "Core Operations"

[[spec]]
id = "${prefix}_001"
title = "Human-readable requirement title"
invariant = "Formal invariant: what must always hold"
```

### 禁止パターン

```toml
# ❌ 全て deprecated — lazy dump-s が拒否する
[[requirement]]
[[requirement_area]]
requirements = [...]
```

SPEC.toml を新規作成・更新する際は必ずこのフォーマットに従うこと。

## STI Parity との関係

dump-s の出力は Spec-Test-Impl Parity が担保された仕様全文を意味する。
`lazy <family> ask --steps=1,2` で Spec↔Test の対応が確認され、
dump-s はその Spec 側の全貌を出力する。
