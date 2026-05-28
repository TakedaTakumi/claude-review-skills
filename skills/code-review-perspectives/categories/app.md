---
key: app
display_name: ソフトウェア本体
typical_paths:
  - src/
  - lib/
  - packages/*/src/
  - app/
  - ドメインコード
applicable_perspectives:
  primary: [security, supply-chain-attack, maintainability, readability, architecture, architecture-drift, ddd-strategic, monorepo, hotspot, performance, dead-code, ownership, duplication, data-integrity, observability, documentation]
  auxiliary: []
---

# app: ソフトウェア本体

## 本質

ビジネスロジック・ドメインコードの正しさ、保守性、設計の健全性、長期的な変更容易性。
このリポジトリで最もボリュームが大きく、最も多くの観点が適用される分類。

## 適用観点

深さの違い（✅ 主要 / ⚠️ 補助）は SKILL.md の「✅（主要）と ⚠️（補助）の運用差」を参照。app は補助観点がなく、すべて主要として評価する。

**主要（✅）**: security, supply-chain-attack, maintainability, readability, architecture, architecture-drift, ddd-strategic, monorepo, hotspot, performance, dead-code, ownership, duplication, data-integrity, observability, documentation

## 境界事例の判断ルール

- マイグレーションスクリプト（`migrations/`, `db/migrate/`）→ **app**（ロジックを含むため）
- スキーマ定義ファイル（`schema.sql`, `*.proto`, `*.graphql`）→ **app**
- 一般用途のスクリプト（`scripts/`, `bin/` のうち CI/デプロイ専用でないもの）→ **app**
- 判断に迷うファイルは Phase 0 でユーザーに確認する。
