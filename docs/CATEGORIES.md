# CATEGORIES — 8分類カタログ

`review-repo` で使うファイル分類。Phase 0 でリポジトリ内の各ファイルがどの分類に該当するかを確定させる。

各分類の詳細（本質・適用観点・境界事例ルール）は [categories/](../skills/code-review-perspectives/categories/) の対応ファイルを参照。

## 概観

| キー | 分類名 | 典型パス | 本質 |
|---|---|---|---|
| [app](../skills/code-review-perspectives/categories/app.md) | ソフトウェア本体 | `src/`, `lib/`, `packages/*/src/`, `app/` | ビジネスロジック・ドメインの正しさ、保守性、設計の健全性、長期的変更容易性 |
| [test](../skills/code-review-perspectives/categories/test.md) | テストコード | `tests/`, `test/`, `__tests__/`, `*.test.*`, `*_test.go`, `spec/` | 仕様の表現としての信頼性、本番リグレッションの検知力、テスト自体の保守容易性 |
| [build](../skills/code-review-perspectives/categories/build.md) | ビルド・パッケージ定義 | `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Makefile`, `pnpm-workspace.yaml` | 依存の健全性、ビルドの再現性、パッケージ境界の妥当性 |
| [runtime](../skills/code-review-perspectives/categories/runtime.md) | 環境構築（ランタイム） | `Dockerfile*`, `compose.yml`, `compose.*.yml`, `.dockerignore` | 再現性、最小権限、ビルド効率、本番稼働時の堅牢性 |
| [devenv](../skills/code-review-perspectives/categories/devenv.md) | 開発環境 | `.devcontainer/`, `.vscode/`, `.idea/`, `.editorconfig`, `.tool-versions`, `.pre-commit-config.yaml` | 開発者体験、再現性、チーム間の一貫性 |
| [ci](../skills/code-review-perspectives/categories/ci.md) | CI パイプライン | `.github/workflows/`, `.gitlab-ci.yml`, `.circleci/`, `Jenkinsfile` | パイプラインの正しさ、最小権限、シークレット保護、サプライチェーン保護 |
| [iac](../skills/code-review-perspectives/categories/iac.md) | デプロイ・IaC | `terraform/`, `k8s/`, `helm/`, `ansible/`, `Tiltfile`, `deploy/` | 本番環境定義の正しさ、ドリフト管理、最小権限、デプロイ事故の予防 |
| [meta](../skills/code-review-perspectives/categories/meta.md) | リポジトリメタ | `README*`, `LICENSE*`, `.gitignore`, `CONTRIBUTING*`, `SECURITY*`, `CHANGELOG*`, ADR | リポジトリの「自己説明能力」と「運営の健全性」 |

## 分類 × 観点マトリクス

各分類で評価する観点は [SKILL.md](../skills/code-review-perspectives/SKILL.md) のマトリクスに集約されている（✅ 主要 / ⚠️ 補助 / 空欄 = 評価しない）。マトリクス・category 定義・perspective frontmatter の三者は完全一致を保つ（[ARCHITECTURE.md](ARCHITECTURE.md) 参照）。

## ✅ 主要と ⚠️ 補助の運用差

両者は実行有無ではなく **評価の深さ・出力の重み** で区別する:

| 項目 | ✅ 主要 | ⚠️ 補助 |
|---|---|---|
| 出力の構造 | 概況 + 上位 N 件発見テーブル + 分布特徴 + 推奨アクション + 制約 | 概況1〜2段落 + 主な発見3件まで（テーブル省略可） |
| サンプリング数 | 各観点で 5 ファイル相当 | 各観点で 2〜3 ファイル相当 |
| 健康スコアの重み | 1.0 倍 | 0.5 倍 |
| Phase 2 マトリクスへの取り込み | Critical/High を積極的に拾う | Critical のみ |
| Phase 3 ロードマップ | 短期/中期/長期すべてに反映 | 中期以降のみ |

## 境界事例の判断

ファイル分類に迷う典型例は各 category ファイル内の「境界事例の判断ルール」セクションを参照（マイグレーションスクリプト → app、reusable workflow → ci、Tiltfile → iac、`scripts/deploy.sh` → iac、`docs/` 配下のコードサンプル → meta 等）。判断に迷うものは Phase 0 でユーザー確認する。
