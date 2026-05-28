# PERSPECTIVES — 32観点カタログ

各観点の詳細（役割・チェック項目・文脈別の読み替え・重大度例）は [perspectives/](../skills/code-review-perspectives/perspectives/) の対応ファイルを参照。`applicable_commands` は legacy 実体から導出（[MIGRATION_NOTES.md](MIGRATION_NOTES.md) §B 参照）。

> 凡例: 🌿 = `review-branch` 適用 / 📦 = `review-repo` 適用 / 🔬 = `review-slice` 適用

## セキュリティ系（security-reviewer）

| 観点 | 適用 | 概要 |
|---|---|---|
| [security](../skills/code-review-perspectives/perspectives/security.md) | 🌿📦🔬 | 攻撃者目線。うっかりミス由来の脆弱性（入力検証・認証/認可・機密漏洩・暗号・SSRF/XXE 等） |
| [supply-chain-attack](../skills/code-review-perspectives/perspectives/supply-chain-attack.md) | 🌿📦🔬 | 意図的な悪意の混入（バックドア・動的コード実行・隠れた転送・typosquatting・コミット署名異常） |

## コード品質系（quality-reviewer）

| 観点 | 適用 | 概要 |
|---|---|---|
| [maintainability](../skills/code-review-perspectives/perspectives/maintainability.md) | 🌿📦🔬 | 6か月後の自分・新担当者視点。TODO/FIXME・巨大ファイル・命名一貫性・設定とロジック分離 |
| [readability](../skills/code-review-perspectives/perspectives/readability.md) | 🌿📦🔬 | 入社初日視点。命名・関数長・ネスト・ブール引数・コメントの質 |
| [duplication](../skills/code-review-perspectives/perspectives/duplication.md) | 📦 | DRY 違反。構造的重複・コピペ痕跡・ロジック分散 |
| [dead-code](../skills/code-review-perspectives/perspectives/dead-code.md) | 📦 | 未参照シンボル/ファイル・古いコメントアウト（誤検知要因を明示） |
| [error-handling](../skills/code-review-perspectives/perspectives/error-handling.md) | 🌿🔬 | SRE 視点。握りつぶし・過剰 catch・リソースリーク・リトライ戦略・状態一貫性 |
| [compatibility](../skills/code-review-perspectives/perspectives/compatibility.md) | 🌿 | 既存利用者視点。公開 API 破壊・スキーマ互換・SemVer・非推奨化4手順 |

## アーキテクチャ系（architecture-reviewer）

| 観点 | 適用 | 概要 |
|---|---|---|
| [architecture](../skills/code-review-perspectives/perspectives/architecture.md) | 🌿📦🔬 | 現時点の設計の妥当性。レイヤー・依存方向・単一責任・既存パターンとの整合 |
| [architecture-drift](../skills/code-review-perspectives/perspectives/architecture-drift.md) | 📦 | 時系列の劣化。循環依存・God モジュール・抽象化レベル不揃いの蓄積 |
| [monorepo](../skills/code-review-perspectives/perspectives/monorepo.md) | 📦 | モノレポ構造。パッケージ循環・共有パッケージ肥大化・workspace 整合性（検出時のみ） |

## DDD 系（ddd-reviewer）

| 観点 | 適用 | 概要 |
|---|---|---|
| [ddd-tactical](../skills/code-review-perspectives/perspectives/ddd-tactical.md) | 🌿🔬 | 戦術的設計。集約・エンティティ/値オブジェクト・サービス・リポジトリ・イベント・ファクトリ・仕様・ユビキタス言語 |
| [ddd-strategic](../skills/code-review-perspectives/perspectives/ddd-strategic.md) | 📦🔬 | 戦略的設計。境界づけられたコンテキスト・コンテキストマップ・コア/サブ/汎用・成熟度段階・会話的モデリング |

## テスト系（test-reviewer）

| 観点 | 適用 | 概要 |
|---|---|---|
| [test-coverage](../skills/code-review-perspectives/perspectives/test-coverage.md) | 🌿📦🔬 | 網羅性。新規/変更コードのテスト・エッジ/異常/境界・公開 API 分岐・PBT 採用箇所の読み替え |
| [test-quality](../skills/code-review-perspectives/perspectives/test-quality.md) | 🌿📦🔬 | 品質。アサーション本質・過剰モック・Flaky 要素・PBT のシード再現/生成器純粋性/shrinking |
| [test-strategy](../skills/code-review-perspectives/perspectives/test-strategy.md) | 🌿📦 | 例示 vs PBT の使い分け。代数法則・ラウンドトリップ・トートロジー検出 |
| [test-pyramid](../skills/code-review-perspectives/perspectives/test-pyramid.md) | 📦 | ユニット/統合/E2E の比率と配置。逆ピラミッド・実行時間分布・ラベル違反 |

## 性能・データ系（performance-reviewer）

| 観点 | 適用 | 概要 |
|---|---|---|
| [performance](../skills/code-review-perspectives/perspectives/performance.md) | 🌿📦🔬 | 静的パターン評価（N+1・ループ内 I/O・O(n²)・全件ロード・キャッシュ）。「要計測」と留保 |
| [hotspot](../skills/code-review-perspectives/perspectives/hotspot.md) | 📦 | 変更頻度 × 複雑度のリスク領域（Git 履歴ベース） |
| [data-integrity](../skills/code-review-perspectives/perspectives/data-integrity.md) | 🌿📦🔬 | トランザクション・冪等性・outbox・整合性種類・マイグレーション安全性 |

## 運用系（ops-reviewer）

| 観点 | 適用 | 概要 |
|---|---|---|
| [runtime-config](../skills/code-review-perspectives/perspectives/runtime-config.md) | 🌿📦 | Dockerfile/compose の品質。base image 固定・layer 順・USER・HEALTHCHECK・環境変数整合 |
| [devenv-quality](../skills/code-review-perspectives/perspectives/devenv-quality.md) | 🌿📦 | devcontainer・エディタ設定・言語バージョン固定・pre-commit hooks |
| [ci-quality](../skills/code-review-perspectives/perspectives/ci-quality.md) | 🌿📦 | CI パイプライン（GitHub Actions/GitLab/CircleCI 等）の権限最小化・SHA pin・secrets 保護 |
| [iac-quality](../skills/code-review-perspectives/perspectives/iac-quality.md) | 📦 | IaC（Terraform/k8s/Ansible）。state・module 化・drift 検出・最小権限 |
| [observability](../skills/code-review-perspectives/perspectives/observability.md) | 🌿📦🔬 | ログ/メトリクス/トレース。構造化ログ・相関 ID・ゴールデンシグナル・SLO/SLI・アラート設計 |

## 依存・履歴・メタ系

| 観点 | 適用 | 担当 Agent | 概要 |
|---|---|---|---|
| [dependencies](../skills/code-review-perspectives/perspectives/dependencies.md) | 🌿📦🔬 | dependencies-reviewer | 依存追加/更新の必要性・ライセンス・メンテ状況・サプライチェーンリスク |
| [governance](../skills/code-review-perspectives/perspectives/governance.md) | 📦 | meta-reviewer | OSS 運営の健全性。LICENSE/README/CONTRIBUTING/SECURITY 等（公開度依存） |
| [documentation](../skills/code-review-perspectives/perspectives/documentation.md) | 🌿📦 | meta-reviewer | 公開 API docstring・README/CHANGELOG・ADR・コメントの「なぜ」 |
| [i18n-a11y](../skills/code-review-perspectives/perspectives/i18n-a11y.md) | 🌿 | meta-reviewer | 国際化（ハードコード文字列/ロケール依存）とアクセシビリティ（ARIA/フォーカス管理） |
| [ownership](../skills/code-review-perspectives/perspectives/ownership.md) | 📦 | ownership-reviewer | バス係数・単一メンテナ依存（Git 履歴） |
| [code-provenance](../skills/code-review-perspectives/perspectives/code-provenance.md) | 🌿🔬 | ownership-reviewer | AI 生成・コピペコード起源のリスク（幻覚 API・過剰実装・テストの自作自演） |

## スライス専用

| 観点 | 適用 | 概要 |
|---|---|---|
| [slice-cohesion](../skills/code-review-perspectives/perspectives/slice-cohesion.md) | 🔬 | スライスの凝集度・境界（サイズ・レイヤー分布・依存方向・責務集中・境界貫通） |

---

## 重大度判断基準

各観点の Critical / High 例は [templates/severity-criteria.md](../skills/code-review-perspectives/templates/severity-criteria.md) を参照。`review-repo` のインパクト × コストマトリクスも同ファイル内。
