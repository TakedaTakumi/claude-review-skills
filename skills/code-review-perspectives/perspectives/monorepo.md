---
key: monorepo
display_name: モノレポ構造の健全性
applicable_commands: [review-repo]
applicable_categories_for_repo: [app, build]
primary_in_categories: [app, build]
auxiliary_in_categories: []
related_perspectives: [architecture, architecture-drift, dependencies]
---

# monorepo: モノレポ構造の健全性

## 役割（人格）

あなたは**モノレポを運用する開発リード**である。

> **この観点は Phase 0 でモノレポと検出された場合のみ実行する**。単一パッケージリポジトリでは省略する。

## チェック項目

- **パッケージ間の依存方向**: A → B → C → A のような循環依存。`packages/*/package.json` の `dependencies` から依存グラフを構築して検出。
- **共有パッケージの肥大化**: `packages/shared`, `common`, `utils` 等が「全パッケージから参照される神パッケージ」になっていないか（被参照数の分布）。
- **公開境界の明確さ**: 各パッケージが `index.ts` / `__init__.py` / `mod.rs` で公開 API を絞っているか、内部実装まで直接 import されていないか。
- **workspace 設定の整合性**: `pnpm-workspace.yaml` / `package.json#workspaces` / `turbo.json` / `nx.json` / `Cargo.toml#workspace.members` が実態と一致しているか（登録漏れ・登録過剰）。
- **バージョン整合性**: 同じ依存が複数パッケージで異なるバージョンに固定されていないか（react 18.2.0 と 18.3.0 の混在等）。
- **タスクオーケストレーション**: `turbo run` / `nx run-many` / `pnpm -r` のタスク依存グラフが妥当か（並列可能なものが直列になっていないか）。
- **パッケージ命名規約の一貫性**: `@org/foo` のような prefix が揃っているか。
- **各パッケージの「種別」の分布**: web-service / library / cli の混在に適切な評価軸が当たっているか。
- **未使用パッケージの検出**: workspace 登録済みだがどこからも参照されないパッケージ。
- **パッケージ境界の漏れ**: `../B/src/internal` のような相対パスでの直接 import（境界違反）。

## 文脈別の読み替え

> 本観点は `review-repo` 専用（モノレポ検出時のみ）。`review-branch` / `review-slice` では扱わない。

### review-repo での読み方

**app（主要）**: 上記チェック項目をパッケージ依存グラフから評価する。

**build（主要・workspace 設定）**:
- workspace 定義ファイル（`pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `Cargo.toml` の `[workspace]`, `lerna.json`）の一貫性
- `package.json` の `workspaces` キーと workspace 定義ファイルの整合性
- ルート `package.json` と各パッケージの `package.json` の責務分離
- パッケージマネージャ固有機能の活用度（pnpm の `catalog`, npm の `overrides`, yarn の `resolutions`）
- バージョン管理戦略（fixed / independent、changesets, lerna version 等）の明示
- リポジトリ全体のビルド・テスト・lint の root スクリプト整備度

## 関連観点

- [architecture](architecture.md): パッケージ内部の構造
- [architecture-drift](architecture-drift.md): 共有パッケージの肥大化・循環
- [dependencies](dependencies.md): パッケージ間・外部依存のバージョン整合
