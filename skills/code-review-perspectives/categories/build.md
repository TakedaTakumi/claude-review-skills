---
key: build
display_name: ビルド・パッケージ定義
typical_paths:
  - package.json
  - pyproject.toml
  - Cargo.toml
  - go.mod
  - Makefile
  - pnpm-workspace.yaml
  - turbo.json
applicable_perspectives:
  primary: [dependencies, security, supply-chain-attack, dead-code, monorepo]
  auxiliary: []
---

# build: ビルド・パッケージ定義

## 本質

依存の健全性、ビルドの再現性、パッケージ境界の妥当性。
ファイル数は少ないが、影響範囲が極めて大きい分類。**全ファイル詳読**。

## 適用観点

**主要（✅）**: dependencies（依存の中心地）, security（ビルド設定）, supply-chain-attack（依存パッケージの健全性、build では主要評価）, dead-code（未使用のパッケージ定義）, monorepo（workspace 設定）

## 境界事例の判断ルール

- `package.json` は build だが、`lint-staged` 設定など開発ツール設定部分は devenv 観点でも見る。
- workspace 定義（`pnpm-workspace.yaml`, `turbo.json`, `Cargo.toml#workspace`）はモノレポ検出時に monorepo 観点と連動。
- 判断に迷うファイルは Phase 0 でユーザーに確認する。
