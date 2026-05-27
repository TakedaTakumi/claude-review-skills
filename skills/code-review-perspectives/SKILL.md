---
name: code-review-perspectives
description: コードレビューの観点ライブラリ（32観点・8分類）。/review-branch, /review-repo, /review-slice の3コマンドと11個の Sub Agent から参照される。観点ごとに人格・チェック項目・文脈別の読み替え・必須出力指標・重大度判断基準を持つ。ブランチ差分レビュー、リポジトリ全体の健康診断、機能スライスのレビューを行うときに参照する。
---

# Code Review Perspectives

コードレビューで用いる **32観点・8分類・各種テンプレート** をまとめた観点ライブラリ。
3つのスラッシュコマンド（`review-branch` / `review-repo` / `review-slice`）および 11 個の Sub Agent から参照される。

- **段階的開示**: このカタログ（SKILL.md）と、評価に必要な観点ファイルのみを読み込む。全観点を一度にロードしない。
- **単一情報源**: 1観点 = 1ファイル。3コマンドはこのライブラリを共有参照する。
- **真実の源（移行元）**: `docs/legacy/{review-branch,review-repo,review-slice}.md`。§8.1 のコマンド適用表と legacy 実体の差異は `docs/MIGRATION_NOTES.md` に記録。

> 注: 各観点ファイル・分類ファイル・テンプレートは段階的に追加される。本 SKILL.md はカタログとして全体の索引を提供する。

## 観点カタログ（32観点）

各観点の `applicable_commands`（どのコマンドで評価するか）は、各 `perspectives/{key}.md` の frontmatter で定義する（legacy 実体から導出）。

| キー | 観点名 | 詳細ファイル | 主担当 Agent |
|---|---|---|---|
| `security` | 攻撃者目線（セキュリティ） | [perspectives/security.md](perspectives/security.md) | security-reviewer |
| `supply-chain-attack` | バックドア・悪意あるコード混入の検出 | [perspectives/supply-chain-attack.md](perspectives/supply-chain-attack.md) | security-reviewer |
| `maintainability` | 保守性 | [perspectives/maintainability.md](perspectives/maintainability.md) | quality-reviewer |
| `readability` | 可読性 | [perspectives/readability.md](perspectives/readability.md) | quality-reviewer |
| `architecture` | アーキテクチャ/設計 | [perspectives/architecture.md](perspectives/architecture.md) | architecture-reviewer |
| `architecture-drift` | 構造ドリフト（レイヤー違反・循環依存・神化） | [perspectives/architecture-drift.md](perspectives/architecture-drift.md) | architecture-reviewer |
| `ddd-tactical` | DDD 戦術的設計・ユビキタス言語 | [perspectives/ddd-tactical.md](perspectives/ddd-tactical.md) | ddd-reviewer |
| `ddd-strategic` | DDD 戦略的設計・成熟度 | [perspectives/ddd-strategic.md](perspectives/ddd-strategic.md) | ddd-reviewer |
| `monorepo` | モノレポ構造の健全性 | [perspectives/monorepo.md](perspectives/monorepo.md) | architecture-reviewer |
| `hotspot` | 変更頻度 × 複雑度のリスク領域 | [perspectives/hotspot.md](perspectives/hotspot.md) | performance-reviewer |
| `performance` | パフォーマンス（静的パターン評価） | [perspectives/performance.md](perspectives/performance.md) | performance-reviewer |
| `dead-code` | 未参照コード | [perspectives/dead-code.md](perspectives/dead-code.md) | quality-reviewer |
| `ownership` | バス係数・単一メンテナ依存 | [perspectives/ownership.md](perspectives/ownership.md) | ownership-reviewer |
| `duplication` | コード重複 | [perspectives/duplication.md](perspectives/duplication.md) | quality-reviewer |
| `test-coverage` | テスト網羅性 | [perspectives/test-coverage.md](perspectives/test-coverage.md) | test-reviewer |
| `test-quality` | テスト品質 | [perspectives/test-quality.md](perspectives/test-quality.md) | test-reviewer |
| `test-strategy` | テスト戦略（例示ベース vs PBT） | [perspectives/test-strategy.md](perspectives/test-strategy.md) | test-reviewer |
| `test-pyramid` | テストピラミッドのバランス | [perspectives/test-pyramid.md](perspectives/test-pyramid.md) | test-reviewer |
| `dependencies` | 依存関係/ライブラリ | [perspectives/dependencies.md](perspectives/dependencies.md) | dependencies-reviewer |
| `data-integrity` | データ整合性・トランザクション・冪等性 | [perspectives/data-integrity.md](perspectives/data-integrity.md) | performance-reviewer |
| `error-handling` | エラーハンドリング/例外処理 | [perspectives/error-handling.md](perspectives/error-handling.md) | quality-reviewer |
| `code-provenance` | AI 生成・コピペコード起源のリスク | [perspectives/code-provenance.md](perspectives/code-provenance.md) | ownership-reviewer |
| `compatibility` | 後方互換性/破壊的変更 | [perspectives/compatibility.md](perspectives/compatibility.md) | quality-reviewer |
| `runtime-config` | ランタイム設定の品質（Dockerfile/compose 等） | [perspectives/runtime-config.md](perspectives/runtime-config.md) | ops-reviewer |
| `devenv-quality` | 開発環境の品質（devcontainer/エディタ設定） | [perspectives/devenv-quality.md](perspectives/devenv-quality.md) | ops-reviewer |
| `ci-quality` | CI パイプラインの品質 | [perspectives/ci-quality.md](perspectives/ci-quality.md) | ops-reviewer |
| `iac-quality` | IaC・デプロイの品質 | [perspectives/iac-quality.md](perspectives/iac-quality.md) | ops-reviewer |
| `observability` | ログ/可観測性 | [perspectives/observability.md](perspectives/observability.md) | ops-reviewer |
| `governance` | リポジトリ運営の健全性 | [perspectives/governance.md](perspectives/governance.md) | meta-reviewer |
| `documentation` | ドキュメント/コメントの適切さ | [perspectives/documentation.md](perspectives/documentation.md) | meta-reviewer |
| `i18n-a11y` | 国際化/アクセシビリティ | [perspectives/i18n-a11y.md](perspectives/i18n-a11y.md) | meta-reviewer |
| `slice-cohesion` | スライスの凝集度と境界（review-slice 専用） | [perspectives/slice-cohesion.md](perspectives/slice-cohesion.md) | slice-flow-reviewer |

> 旧 review-branch の統合観点 `infrastructure` は、`runtime-config` / `devenv-quality` / `ci-quality` / `iac-quality` の4観点へ分解した（migration スクリプト部分は `data-integrity`）。詳細は `docs/MIGRATION_NOTES.md`。

## 分類カタログ（8分類・review-repo 用）

| キー | 分類名 | 詳細ファイル |
|---|---|---|
| `app` | ソフトウェア本体 | [categories/app.md](categories/app.md) |
| `test` | テストコード | [categories/test.md](categories/test.md) |
| `build` | ビルド・パッケージ定義 | [categories/build.md](categories/build.md) |
| `runtime` | 環境構築（ランタイム） | [categories/runtime.md](categories/runtime.md) |
| `devenv` | 開発環境 | [categories/devenv.md](categories/devenv.md) |
| `ci` | CI パイプライン | [categories/ci.md](categories/ci.md) |
| `iac` | デプロイ・IaC | [categories/iac.md](categories/iac.md) |
| `meta` | リポジトリメタ | [categories/meta.md](categories/meta.md) |

## 分類 × 観点マトリクス（review-repo 用）

各分類で評価する観点を以下で定義する。**未定義（空欄）のセルは評価しない**。

| 観点 \ 分類 | app | test | build | runtime | devenv | ci | iac | meta |
|---|---|---|---|---|---|---|---|---|
| security | ✅ | ⚠️ | ✅ | ✅ | ⚠️ | ✅ | ✅ | ✅ |
| supply-chain-attack | ✅ | ⚠️ | ✅ | ⚠️ |  | ⚠️ | ⚠️ | ⚠️ |
| maintainability | ✅ | ✅ |  |  |  |  |  |  |
| readability | ✅ | ✅ |  |  |  |  |  |  |
| architecture | ✅ |  |  |  |  |  |  |  |
| architecture-drift | ✅ |  |  |  |  |  |  |  |
| ddd-strategic | ✅ |  |  |  |  |  |  | ⚠️ |
| monorepo | ✅ |  | ✅ |  |  |  |  |  |
| hotspot | ✅ | ✅ |  |  |  | ⚠️ | ⚠️ |  |
| performance | ✅ |  |  | ⚠️ |  | ⚠️ | ⚠️ |  |
| dead-code | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ |
| ownership | ✅ |  |  |  |  |  |  |  |
| duplication | ✅ | ⚠️ |  | ⚠️ |  | ⚠️ | ⚠️ |  |
| test-coverage |  | ✅ |  |  |  |  |  |  |
| test-quality |  | ✅ |  |  |  |  |  |  |
| test-strategy |  | ✅ |  |  |  |  |  |  |
| test-pyramid |  | ✅ |  |  |  |  |  |  |
| dependencies |  |  | ✅ |  |  |  |  |  |
| data-integrity | ✅ |  |  |  |  |  | ⚠️ |  |
| runtime-config |  |  |  | ✅ |  |  |  |  |
| devenv-quality |  |  |  |  | ✅ |  |  |  |
| ci-quality |  |  |  |  |  | ✅ |  |  |
| iac-quality |  |  |  |  |  |  | ✅ |  |
| observability | ✅ |  |  | ⚠️ |  | ⚠️ | ⚠️ |  |
| governance |  |  |  |  |  |  |  | ✅ |
| documentation | ✅ | ⚠️ |  |  |  |  |  | ✅ |

凡例: ✅ = この分類の主要観点として評価 / ⚠️ = 補助的に評価 / 空欄 = 評価しない

### ✅（主要）と ⚠️（補助）の運用差

両者は実行有無ではなく **評価の深さ・出力の重み** で区別する。

| 項目 | ✅ 主要 | ⚠️ 補助 |
|---|---|---|
| 出力の構造 | 概況 + 上位N件発見テーブル + 分布特徴 + 推奨アクション + 制約 | 概況1〜2段落 + 主な発見3件まで（テーブル省略可） |
| サンプリング数 | 各観点で 5 ファイル相当を読む | 各観点で 2〜3 ファイル相当に絞る |
| 健康スコアの重み | 1.0 倍（基本重み） | 0.5 倍（分類平均算出時） |
| Phase 2 マトリクスへの取り込み | Critical/High を積極的に拾う | Critical のみ Phase 2 に渡す（High 以下は Phase 1 出力のみ） |
| Phase 3 ロードマップ | 短期/中期/長期すべてに反映 | 中期以降のみ |

## テンプレート

| ファイル | 内容 |
|---|---|
| [templates/severity-criteria.md](templates/severity-criteria.md) | 重大度（Critical/High/Medium/Low）の操作的定義、観点別 Critical/High 例、インパクト × コストマトリクス |
| [templates/escalation-report.md](templates/escalation-report.md) | supply-chain-attack 等の人間へのエスカレーション用レポート書式 |
| [templates/output-format.md](templates/output-format.md) | 観点別（および分類 × 観点）の出力フォーマット |
| [templates/progress-log.md](templates/progress-log.md) | 進捗表示ルール（🔍 / ✅ / ⚠️ / ❌ の絵文字 + 1行進捗） |
| [templates/slice-flow-template.md](templates/slice-flow-template.md) | review-slice の「入口 → 出口」情報フロー記述テンプレート |
