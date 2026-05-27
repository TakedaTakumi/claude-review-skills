---
description: リポジトリ全体を「ファイル分類 × 観点」のマトリクスで評価し、リファクタ優先順位とロードマップを提示する
argument-hint: [perspectives] [--scope=<path>] [--top=<n>] [--categories=<list>] [--full] [--baseline=<path>] [--save=<path>]
allowed-tools: Bash(git:*), Bash(gh:*), Bash(rg:*), Bash(find:*), Bash(wc:*), Bash(sort:*), Bash(uniq:*), Bash(head:*), Bash(tail:*), Bash(awk:*), Bash(cloc:*), Bash(tokei:*), Bash(which:*), Bash(command:*), Read, Grep, Glob
---

# リポジトリ全体の健康診断（分類ベース）

## 役割

あなたは**コードベース全体の健康診断を担当する技術監査人**です。単一の PR や差分ではなく、**リポジトリ全体**を俯瞰し、「どこに技術的負債が溜まっているか」「どこから手を付けるべきか」を可視化します。

このコマンドの根本思想は次のとおりです:

> **リポジトリ内のファイルは目的が違うため、適用すべき評価軸も違う。**

たとえば `Dockerfile` に「可読性」を求めるより「再現性とベースイメージ固定」を見るべきで、`.github/workflows/` に「テスト網羅性」を求めても意味がない。だから本コマンドは **ファイル分類 × 観点** のマトリクスで、意味のあるセルだけを評価する。

各分類・各観点の冒頭で具体的な人格が指定されているので、それに**完全になりきって**評価してください。分類・観点を切り替えるときは前の人格を持ち越さず、思考を一度リセットします。

リポジトリ評価では**全件指摘は無価値**です。本コマンドの本質は次の3つ:

1. **広い領域から優先順位を付ける**（投資対効果の高い箇所を特定）
2. **時間軸を見る**（変更頻度、コードの年齢、最終更新）
3. **集計して傾向を示す**（ヒートマップ、ホットスポット、分布）

---

## 引数仕様

ユーザー入力: `$ARGUMENTS`

### パース規則

1. `--scope=<path>` 形式のフラグがあれば、その値を **SCOPE** として保持し、評価対象をその配下に限定する。指定がなければリポジトリ全体（リポジトリルート）。
2. `--top=<n>` 形式のフラグがあれば、各観点の出力で「上位 N 件」に絞る。デフォルトは規模依存（後述）。
3. `--categories=<list>` 形式のフラグがあれば、評価する分類をカンマ区切りで指定する。例: `--categories=app,test,ci`。指定がなければ全分類。
4. **`--full` フラグ** があれば、Phase 0 から Phase 3 まで一気通貫で実行する。**指定がなければデフォルトは段階的実行**（後述「実行モード」参照）。
5. **`--baseline=<path>` フラグ** があれば、指定パスにある前回スキャン結果（JSON）を読み込み、健康スコアの差分を Phase 3 で出力する。ファイルが存在しなければ警告して通常実行。
6. **`--save=<path>` フラグ** があれば、Phase 3 の健康スコアと指標を JSON で指定パスに保存する（次回 `--baseline` で参照可能）。
7. `--scope=...` `--top=...` `--categories=...` `--full` `--baseline=...` `--save=...` を除いた残りの引数を結合し、空白で区切った1つ目を **PERSPECTIVES** として扱う。2つ目以降の余剰引数があればエラーで停止し、書式を案内する。
8. **PERSPECTIVES** はカンマ区切り。空または `all` ならすべての観点を対象。各分類で「定義されている観点」のみが実行される（後述のマトリクス参照）。
9. **PERSPECTIVES と `--categories` は AND で絞り込む**。両方指定された場合、「指定された分類のうち、指定された観点に該当するセル」のみ評価する。マトリクス上で交差セルが空欄なら何も実行されないので、その旨を明示してユーザーに代替案を提示する。
10. スペース区切りの `--scope <path>` 等は受け付けず、エラーで停止する。
11. 不明なフラグ・観点名・分類名が含まれていたら、レビューを開始する前にユーザーに**確認**を求めること。

### 実行モード（重要）

このコマンドは7分類×複数観点を扱うため、**1回ですべてを実行すると出力が長大になり、コンテキストも消費しすぎる**。よって、デフォルトでは **2段階のインタラクティブ実行** を行う。

#### 段階1（デフォルト動作）: 概況スキャン

Phase 0 を完全に実行した後、**各分類の「概況サマリ」のみ**を1〜2段落ずつ出力する。各分類で「特に深掘りすべき観点」をハイライトし、Phase 3 健康スコアカード（簡略版: 分類平均スコアのみ）を出して停止する。

最後に**ユーザーへ次の指示を促す**:
> 段階1の概況が出ました。次に深掘りする分類・観点を選んでください。例:
> - 「app の architecture-drift と data-integrity を深掘りして」
> - 「ci と iac 全体を深掘りして」
> - 「最初から `--full` で全部やり直して」

#### 段階2: 指示された分類・観点の深掘り

ユーザーの指示に従い、該当する分類・観点について Phase 1 の詳細（チェックリスト・指標値・上位N件発見・分布の特徴）と Phase 1.5 セルフレビューを実行する。複数回繰り返してよい（毎回ユーザーが追加指示を出す）。

#### `--full` モード（一括実行）

`--full` フラグが指定された場合は、Phase 0 → Phase 1（全分類×全観点）→ Phase 1.5 → Phase 2 → Phase 3 を一気に通す。大規模リポジトリでは出力が極めて長くなるため、ユーザーに事前確認することを推奨。

#### 段階1出力フォーマット

```
## Phase 0: リポジトリ概況
（Phase 0 のフル出力。プロジェクト指紋、ファイル分類サマリ、サンプリング戦略、実行予定）

## 段階1: 分類別の概況スキャン

### app（ソフトウェア本体）
概況サマリ（1〜2段落）。**深掘り推奨観点**: architecture-drift（循環依存の兆候あり）、hotspot（特定ファイルへの修正集中）

### test
概況サマリ。**深掘り推奨観点**: test-coverage（カバレッジレポート未取得）

（... 各分類で同様 ...）

## 健康スコアカード（簡略版）

| 分類 | 概況スコア(1-5) | 主な根拠 |
|---|---|---|
| app | 3 | TODO 多数、巨大ファイルあり |
| test | 3.5 | 概ね良好 |
| ... | ... | ... |
| **総合** | **3.1** | |

## 次のアクション
深掘りする分類・観点を指示してください。例:
- 「app の architecture-drift を深掘り」
- 「test 全体を深掘り」
- 「最初から --full で実行」
```

### 受理する書式の例

| 入力 | 解釈 |
|---|---|
| `/review-repo` | 全分類 / 全観点 / 全リポジトリ / **段階的実行（デフォルト）** |
| `/review-repo --full` | 全分類 / 全観点 / **一気通貫で Phase 0〜3 まで実行** |
| `/review-repo security` | security 観点のみ（該当する分類すべてで） |
| `/review-repo --categories=ci,iac` | 全観点 / CI と IaC 分類のみ |
| `/review-repo --scope=src/api` | 全分類 / src/api 配下のみ |
| `/review-repo hotspot --top=20` | hotspot 観点のみ / 上位20件 |
| `/review-repo all --categories=app --top=15 --full` | 全観点 / アプリ本体分類のみ / 上位15件 / 一括実行 |
| `/review-repo security --categories=ci` | ci 分類の security 観点のみ（交差セル評価） |
| `/review-repo test-coverage --categories=ci` | ⚠️ 交差セルが空のため何も実行されない（その旨を報告） |
| `/review-repo --full --save=docs/review/2026-05.json` | フル実行 + スコアを保存 |
| `/review-repo --full --baseline=docs/review/2026-04.json --save=docs/review/2026-05.json` | 前回比較 + 保存 |
| `/review-repo --categories=meta,build` | ガバナンスと依存の棚卸し（軽量、月次運用向け） |
| `/review-repo security --full` | セキュリティ監査（全分類のsecurityを通す） |
| `/review-repo --categories=ci,iac --full` | DevOps レビュー（CIとIaCを集中評価） |
| `/review-repo --scope=packages/api --full` | モノレポの特定パッケージのみフル評価 |

### top のデフォルト値（規模依存）

ファイル数に応じて自動決定する:

| 総ファイル数 | デフォルト top |
|---|---|
| ≤ 500 | 5 |
| 501 〜 2000 | 10 |
| 2001 〜 5000 | 20 |
| > 5000 | 30 + スコープ絞り推奨 |

---

## 7分類の定義

ファイル分類は以下の7つ。Phase 0 でリポジトリ内の各ファイルがどの分類に該当するかを確定させる。

| キー | 分類名 | 典型的なパス・ファイル |
|---|---|---|
| `app` | ソフトウェア本体 | `src/`, `lib/`, `packages/*/src/`, `app/`, ドメインコード |
| `test` | テストコード | `tests/`, `test/`, `__tests__/`, `*.test.*`, `*_test.go`, `spec/` |
| `build` | ビルド・パッケージ定義 | `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Makefile`, `pnpm-workspace.yaml`, `turbo.json` |
| `runtime` | 環境構築（ランタイム） | `Dockerfile*`, `compose.yml`, `compose.*.yml`, `.dockerignore` |
| `devenv` | 開発環境 | `.devcontainer/`, `.vscode/`, `.idea/`, `.editorconfig`, `.tool-versions`, `.nvmrc`, `.python-version`, `.envrc`, `mise.toml`, `.mise.toml`, `.pre-commit-config.yaml`, `lefthook.yml`, `.husky/`, `package.json` の `lint-staged` 設定 |
| `ci` | CI パイプライン | `.github/workflows/`, `.gitlab-ci.yml`, `.circleci/`, `Jenkinsfile`, `azure-pipelines.yml`, `bitbucket-pipelines.yml` |
| `iac` | デプロイ・IaC | `terraform/`, `pulumi/`, `cloudformation/`, `k8s/`, `ansible/`, `helm/`, `Tiltfile`, `deploy/`, `scripts/deploy/` |
| `meta` | リポジトリメタ | `README*`, `LICENSE*`, `.gitignore`, `.gitattributes`, `CONTRIBUTING*`, `SECURITY*`, `CODE_OF_CONDUCT*`, `CHANGELOG*`, ADR、各種ドキュメント |

**境界事例の判断ルール**:
- マイグレーションスクリプト（`migrations/`, `db/migrate/`）→ `app`（ロジックを含むため）
- スキーマ定義ファイル（`schema.sql`, `*.proto`, `*.graphql`）→ `app`
- スクリプト類（`scripts/`, `bin/`）→ 内容に応じて `app` / `ci` / `iac`。一般用途のスクリプトは `app`、CI 専用は `ci`、デプロイ用は `iac`
- Kubernetes マニフェストが `helm/` 配下や `k8s/` 配下にあれば `iac`、ただし Helm チャート自体のメタ情報（`Chart.yaml`）も `iac`
- `Tiltfile` / `skaffold.yaml` のような開発時クラスタオーケストレーションは `iac`
- GitHub Actions の reusable workflow（`.github/workflows/reusable-*.yml`）は `ci`
- CI から呼ばれるが内容がデプロイ手順のスクリプト（`scripts/deploy.sh` 等）は `iac`
- `docs/` 配下のコードサンプル → `meta`
- 判断に迷うファイルは Phase 0 でユーザーに確認すること

---

## 分類 × 観点のマトリクス

各分類で評価する観点を以下で定義する。**未定義のセルは評価しない**こと。

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

これにより、コンテキスト消費を抑えつつ、主要観点の精度を保つ。

新規観点（旧 review-branch から再編集して導入したもの）:
- **runtime-config**: ランタイム環境構築固有の観点（Dockerfile/compose の品質）
- **devenv-quality**: 開発環境固有の観点（devcontainer/エディタ設定の品質）
- **ci-quality**: CI パイプライン固有の観点（権限、SHA pin、シークレット保護等）
- **iac-quality**: IaC・デプロイ固有の観点（state 管理、module 化、drift 検出等）
- **governance**: リポジトリ運営の健全性（ライセンス、貢献ガイド、行動規範等）
- **monorepo**: モノレポ構造の健全性（パッケージ境界、依存方向、共有パッケージ肥大化、workspace 設定）。**モノレポ検出時のみ実行**。単一パッケージリポジトリでは評価しない。
- **performance**: 実行時パフォーマンスの**静的パターン評価**。hotspot とは別軸で、コードパターンとしてのN+1・ブロッキングI/O・大規模ループ等を見る。
- **test-pyramid**: ユニット/統合/E2E テストのバランス評価。テスト戦略（test-strategy）が PBT 採用の偏りを見るのに対し、test-pyramid はテスト**種類**の偏りを見る。
- **ddd-strategic**: ドメイン駆動設計の戦略的設計（境界づけられたコンテキスト、コンテキストマップ、コア/サブ/汎用ドメイン）、DDD 成熟度、会話的モデリングの跡を評価。**DDD 採用前提**でリポジトリ全体の俯瞰評価を行う。差分レビューでの戦術的設計評価は `review-branch` の `ddd-tactical` を使う。
- **supply-chain-attack**: バックドア・悪意あるコード混入の検出。security 観点が「うっかりミス由来の脆弱性」を扱うのに対し、本観点は**意図的な悪意の混入**を別軸で評価する。リポジトリ全体評価では**長期潜伏しているバックドアの兆候**を特に重視。

---

## 実行手順

**実行モードによるフローの分岐**:
- **デフォルト（段階的実行）**: Phase 0 → 段階1 概況スキャン → 停止 → ユーザー指示 → 段階2 深掘り
- **`--full` 指定時**: Phase 0 → Phase 1（全分類×全観点） → Phase 1.5 → Phase 2 → Phase 3

両モードとも Phase 0 は同じ。Phase 0 完了後にモードに応じて分岐する。

### Phase 0: リポジトリのメタデータ収集と分類確定

以下を順に実行し、結果を整理せよ。**いずれかが失敗した場合はその旨を報告し、原因解消の方法をユーザーに提示してから停止する**。勝手に推測でリカバリしないこと。

1. **リポジトリ確認**: `git rev-parse --is-inside-work-tree` でGitリポジトリ内であることを確認。
2. **shallow clone 確認**: `git rev-parse --is-shallow-repository`。shallow なら hotspot/ownership の精度が落ちる旨を警告。
3. **スコープの確定**: `SCOPE` が指定されていればそのパスの存在確認。存在しなければエラー停止。
4. **規模感の把握**:
   - 総ファイル数: `git ls-files -- $SCOPE | wc -l`
   - 言語構成: 拡張子別ファイル数の上位10種類
   - 行数の集計（`cloc` / `tokei` があれば優先利用、無ければ `wc -l`）
   - リポジトリ年齢、コミット総数、直近30/90/365日のコミット数
5. **コントリビューター情報**: 全期間 / 直近365日 / 直近90日のアクティブコミッター数。
6. **プロジェクト指紋の取得**（Phase 1 で再探索しないため、ここで一度だけ確定する）:
   - **言語/ランタイム**: 拡張子分布から判定（TypeScript、Python、Go等）
   - **パッケージマネージャ**: `package.json` + `pnpm-lock.yaml`/`yarn.lock`/`package-lock.json`、`poetry.lock`、`uv.lock`、`Gemfile.lock`、`Cargo.lock` 等
   - **モノレポか単一パッケージか**: `pnpm-workspace.yaml`, `package.json` の `workspaces` キー、`Cargo.toml` の `[workspace]`, `turbo.json`, `nx.json`, `lerna.json` を確認
   - **テストフレームワーク**: 設定ファイルや依存から推定
   - **PBTライブラリ**: `fast-check`, `hypothesis`, `proptest`, `ScalaCheck` 等を依存から検出
   - **コンテナ定義**: Dockerfile/compose.yml の有無と数
   - **CI/CD**: `.github/workflows/`, `.gitlab-ci.yml`, `.circleci/`, `Jenkinsfile`, `azure-pipelines.yml` の存在
   - **IaC**: `terraform/`, `pulumi/`, `cloudformation/`, `k8s/` の存在
   - **マイグレーション**: `migrations/`, `db/migrate/` 等の検出
   - **開発ツールチェーン**:
     - エディタ設定: `.devcontainer/` (VSCode devcontainer), `.vscode/`, `.idea/` (JetBrains), `.editorconfig`
     - 環境変数管理: `.envrc` (direnv), `.tool-versions` (asdf/mise), `.nvmrc`, `.python-version`, `mise.toml`
     - pre-commit hooks: `.pre-commit-config.yaml`, `lefthook.yml`, `.husky/`, `package.json#lint-staged`
   - **DDD 採用の検出**:
     - **コード側の手がかり**: `domain/`, `bounded_contexts/`, `contexts/`, `Aggregate`/`Entity`/`ValueObject`/`Repository`/`DomainEvent`/`Specification` の語彙、ドメインサービスとアプリケーションサービスの分離
     - **ドキュメント側の手がかり**: ADR、コンテキストマップ、用語集（glossary）、Event Storming のアーティファクト
     - **判定結果**: `adopted`（採用） / `partial`（部分採用、DDD-lite） / `not-adopted`（未採用） / `unclear`（判定不能、ユーザー確認）
     - 採用度に応じて ddd-strategic 観点の評価方針を切り替える（未採用なら評価スキップ、partial なら戦術中心、adopted なら戦略・成熟度まで全評価）
   - **公開度の推定**:
     - **判定材料**: GitHub の場合は `gh repo view --json visibility,isPrivate`、リポジトリに `LICENSE` ファイル、`CODE_OF_CONDUCT.md`、`CONTRIBUTING.md` の存在、公開レジストリ向け設定（`package.json#publishConfig` 等）。
     - **3段階で判定**: `public-oss`（外部公開OSS）/ `internal-oss`（社内OSS、複数チームから貢献）/ `internal-private`（特定チーム専用）。
     - **governance 観点の評価厳しさ**: public-oss > internal-oss > internal-private の順で厳しく評価する。例: `internal-private` なら CODE_OF_CONDUCT.md の欠如は問題視しない。`public-oss` なら CONTRIBUTING.md と SECURITY.md は必須扱い。
     - 判定がつかない場合はユーザーに確認。
   - **プロジェクト種別の推定**: 以下のヒューリスティックでプロジェクト種別を判定し、ユーザーに確認:

     | 種別 | 判定の手がかり | 評価で重視する観点 |
     |---|---|---|
     | `web-service` | HTTPサーバーフレームワーク（Express, FastAPI, Rails, Echo, Actix等）、API ルーティング、認証ミドルウェア | security, data-integrity, observability, runtime-config |
     | `library` | `package.json` の `"main"`/`"exports"`、`pyproject.toml` の `[project]`、TypeScript の `declaration: true`、公開レジストリ向け設定 | dependencies, governance, documentation, compatibility |
     | `cli` | bin/cli エントリ、`commander`/`click`/`cobra`、argparse、`#!/usr/bin/env` shebang | documentation, governance, dependencies, ux of error messages |
     | `mobile` | iOS/Android プロジェクト構造、React Native、Flutter | （現状の観点では十分カバーできない旨を警告） |
     | `data-pipeline` | Airflow, Dagster, dbt、Spark/Beam、Notebook（.ipynb） | data-integrity, observability, performance |
     | `infrastructure-only` | コードが薄く `terraform/`, `k8s/` 中心 | ci/iac 観点中心、app/test は軽め |
     | `monorepo-mixed` | モノレポで複数種別が混在 | パッケージごとに種別を再判定 |
     | `unknown` | 上記いずれにも該当しない | 全観点フラットに評価、ユーザーに種別を確認 |

   - **判定結果はユーザーに明示し、誤っていれば指示を求める**。種別によっては該当しない観点の評価を省略・軽量化する。例: ライブラリなら observability の優先度を下げ、documentation の優先度を上げる。

   - **評価重み付けの適用**: 各観点を「主要 / 通常 / 軽量」の3段階で扱う。Phase 3 の健康スコアカードでも、種別に応じた重み付けでスコアを算出する旨を明記。
7. **ファイル分類の確定**:
   - 7分類のルールに従い、全ファイルを分類する。
   - 分類ごとのファイル数を集計して提示。
   - **境界事例（判断に迷うパス）はユーザーに確認**: 「`scripts/` 配下を `app` / `ci` / `iac` のどれにしますか?」のように、最大3件まで質問。それ以上多い場合はサンプル提示の上で「全体の方針」を確認。
   - モノレポの場合は、パッケージごとの分類も提示。
8. **サンプリング戦略の宣言**:
   - 全観点共通: hotspot 上位 20 ファイルは詳読
   - 各観点で 5 ファイル前後をサンプル抽出（観点に該当しそうな候補から）
   - **runtime / devenv / ci / iac / meta は基本的に全数読む**（ファイル数が少ないため。ただし iac の規模が大きい場合はサンプリング）
   - **app / test は集計指標 + 上位N + サンプリング**で読む
   - 大量変更時（5000ファイル超）はスコープ絞りを提案
9. **方針宣言**: 収集したメタデータ・分類サマリ・サンプリング戦略・実行する分類×観点リストをユーザーに**明示**してから Phase 1 に進む。

#### Phase 0 出力フォーマット

```
## Phase 0: リポジトリ概況

### 規模
- 総ファイル数: 1,234
- 主要言語: TypeScript (45%), Python (30%), YAML (10%)
- リポジトリ年齢: 2.3年
- 直近90日コミット: 187 / アクティブコミッター: 5名

### プロジェクト指紋
- パッケージマネージャ: pnpm + uv
- モノレポ構造: ✅ (packages/api, packages/web, packages/shared)
- テストフレームワーク: vitest + pytest
- PBTライブラリ: fast-check
- コンテナ: Dockerfile×3, compose.yml×2
- CI: .github/workflows/×7
- IaC: terraform/
- **DDD 採用**: adopted（推定根拠: `domain/` ディレクトリ、`Aggregate` 命名、`docs/adr/` に境界づけられたコンテキストの ADR）
- **プロジェクト種別**: web-service（推定根拠: FastAPI を依存に含む、認証ミドルウェアあり、HTTPルーティング多数）
- **評価の重み付け**: security/data-integrity/observability を主要、governance/documentation を軽量、その他は通常

### ファイル分類サマリ
| 分類 | ファイル数 | 主なパス |
|---|---|---|
| app | 856 | src/, packages/*/src/, migrations/ |
| test | 234 | tests/, *.test.ts |
| build | 8 | package.json×4, pyproject.toml, ... |
| runtime | 5 | Dockerfile×3, compose×2 |
| devenv | 4 | .devcontainer/, .vscode/, .editorconfig |
| ci | 7 | .github/workflows/×7 |
| iac | 5 | terraform/×5 |
| meta | 9 | README, LICENSE, ... |

### 境界事例（要確認）
- `scripts/` 配下に 15 ファイル: 確認したところデプロイ補助スクリプトが多いため `iac` に分類しました。問題なければこのまま進めます。

### サンプリング戦略
- hotspot上位20ファイル詳読
- 各観点 5ファイルサンプル
- runtime / devenv / ci / iac / meta は全数読
- app / test は集計+サンプル

### 実行予定（分類 × 観点）
- app: security, maintainability, readability, architecture, ...
- test: maintainability, readability, test-coverage, test-quality, test-strategy, ...
- build: security, dependencies, dead-code
- runtime: security, runtime-config, dead-code, observability
- devenv: devenv-quality, dead-code
- ci: security, ci-quality, hotspot, dead-code, observability, duplication
- iac: security, iac-quality, hotspot, dead-code, observability, data-integrity, duplication
- meta: security, governance, documentation, dead-code
```

### Phase 1: 分類ごとのスキャン

各分類について、その分類で評価する観点を順に走らせる。**観点ごとに人格を切り替え、前の人格を持ち越さない**。

各分類の冒頭に「この分類で見るべき本質」を一言で示し、その後に観点別の評価を続ける。

---

#### 1.1 app（ソフトウェア本体）

> **本質**: ビジネスロジック・ドメインコードの正しさ、保守性、設計の健全性、長期的な変更容易性。

このリポジトリで最もボリュームが大きく、最も多くの観点が適用される分類。

##### security（攻撃者目線）
あなたは**外部の攻撃者**である。本体コードから攻撃可能な経路を網羅的に列挙せよ。
- ハードコードされたシークレット（`api[_-]?key`, `secret`, `password`, `token`, 秘密鍵パターン）
- インジェクション経路（SQL組み立て、`os.system`, `subprocess.shell=True`, `exec`, `eval`、テンプレート動的入力）
- 認証・認可の中央集権度（各エンドポイントで個別実装は漏れの温床）
- 古い暗号アルゴリズム（MD5, SHA1, DES, RC4）
- CORS、CSP、Cookie 属性の設定
- 入力検証の集約度
- ログ・エラーメッセージへの機密情報出力

##### supply-chain-attack（バックドア・悪意あるコード混入の検出）
あなたは**敵対的なコード混入を疑う防御セキュリティ専門家**である。security 観点が「うっかりミス由来の脆弱性」を扱うのに対し、本観点は**意図的な悪意ある混入**を別軸で評価する。リポジトリ全体評価では**長期潜伏しているバックドアの兆候**と**サプライチェーン全体の健全性**を重視。

**重要な前提**:
- 本観点は SAST / SCA / シークレットスキャン等の専用ツールの**代替ではなく補完**である。
- 検出は「**疑い**」として記録し、人間のエスカレーションを推奨する。
- リポジトリ全体評価では**1件の確信度よりも、複数の小さな違和感のパターン**を重視する。

###### Part 1: 既知の悪意パターンの全体スキャン

- **ハードコードされたバックドア認証**:
  - 全コードベースで `if user == "admin_secret"` 等の特定文字列分岐を `rg` で網羅検索
  - `if password == "...":`、`if token == "...":` の固定値比較を全件抽出
  - コメントで `# debug`, `# temp`, `# remove later` が付いた認証スキップ
- **隠しエンドポイント / 隠しコマンド**:
  - `/admin/_internal_`、`/debug/`、`/.well-known/` 配下の不審なルート
  - 認証ミドルウェアをスキップしている route 定義
  - CLI の隠しフラグ
- **動的コード実行**:
  - `eval`, `exec`, `Function()`, `os.system`, `subprocess(shell=True)`, `child_process.exec` の全使用箇所
  - 外部入力が流入する経路を辿る
- **リバースシェル / 外部接続パターン**:
  - `socket.connect`, `nc -e`, `bash -i >& /dev/tcp/`, `curl ... | sh`, `wget ... | bash`
  - **ハードコード IP** の存在（リポジトリ全体で `rg` 検索）
- **暗号の意図的弱化**:
  - 弱い暗号アルゴリズムの使用箇所
  - 乱数源の不適切な選択（暗号用に `random` を使う等）

###### Part 2: 情報漏洩経路の全体棚卸し

- **外部送信先の網羅**: コード内に登場する HTTP / DNS / WebSocket 接続先 URL の一覧化と、想定外のドメインがないか確認
- **ログ出力箇所の網羅**: 機密になりうる変数名（password, token, secret, api_key 等）がログ出力に含まれていないか
- **デバッグ情報の残骸**: `console.log`, `print`, `pp` の本番コードへの混入
- **データ持ち出しエンドポイント**: 全ユーザーデータを返す、大量データを export する API の存在

###### Part 3: 高度なパターン（長期潜伏バックドアの兆候）

- **隠れた転送処理**:
  - ログ関数・通知関数の内部に外部送信が含まれていないか（一見ログのように見えて転送している）
  - エラーハンドラ内の不審な外部通信
  - 定期実行（タイマー、cron）の不審な処理
- **過去のコミット履歴の異常パターン**:
  - 単一コミッターが**広範囲に touch**したコミット
  - 「typo fix」「lint」名目で大量の実装変更を含むコミット
  - **メンテナ交代の前後**で大きく挙動が変わったファイル（`git log` で確認）
  - **特定のファイル**が異常に多くのコミッターから変更されている（コード混入の温床になりうる）
- **依存関係のシグネチャ検証**:
  - `package.json`, `requirements.txt`, `Cargo.toml`, `go.mod` 等の全依存リスト
  - **typosquatting** の疑いがある依存名（既知の人気パッケージに似た名前）
  - 過去1年で**メンテナが変わった**依存パッケージ
  - **postinstall / preinstall / prepare** スクリプトを持つ依存の全件確認
  - ロックファイルと依存定義の整合性
  - SBOM（Software Bill of Materials）の存在と更新状況

###### Part 4: コミット履歴ベースの長期潜伏検出

- `git log --since="N years ago" --grep="..."` で疑わしいキーワード（"backdoor", "bypass", "skip auth", "remove security check"）を検索
- 大規模なリファクタコミットに紛れたバックドア追加の検出
- 削除されたコードの中に「過去にあったセキュリティチェック」が含まれていないか（`git log -p -S "auth"` で逆引き）
- 過去にメンテナンスが停滞した時期に追加されたコードの精査

###### Part 5: 評価レポートテンプレート

review-branch の同観点と同じテンプレートを使う。複数の疑いをレポートし、**確信度高 → 低の順**でまとめる。
リポジトリ全体評価では**「個別の指摘」と「サプライチェーン全体の健全性スコア」の両方を出す**:

```
### サプライチェーン全体の健全性スコア（1〜5）

- 依存パッケージの健全性: 4 / 5 （typosquatting なし、メンテナンス活発、ただし postinstall 1件あり）
- コード内の悪意パターン: 5 / 5 （疑わしい固定値分岐なし、リバースシェル風処理なし）
- コミット履歴の異常: 3 / 5 （メンテナ交代の前後で挙動変化のファイルが N 件）
- 全体: 4 / 5
```

###### 動作上の補足

- 誤検知を恐れず疑いを報告（判断は人間に委ねる）
- 専用ツールの並走を末尾に明記（Semgrep、CodeQL、gitleaks、Snyk、trufflehog 等）
- リポジトリ全体評価の長時間化に注意。`--full` 以外では概況スキャンに留め、深掘りは指示を待つ

##### maintainability（保守性）
あなたは**このコードベースを5年メンテし続ける開発リード**である。
- TODO/FIXME/HACK/XXX コメントの分布と古さ（`git blame` で日付確認）
- コメントアウトされたコードの残骸
- 巨大ファイル（行数 1000 超）
- マジックナンバー・マジック文字列の多用箇所
- 廃止予定 API・非推奨パターンの残存
- 設定とロジックの混在度
- 命名規約の不統一

##### readability（可読性）
あなたは**入社初日の新メンバー**である。「最初に読むと挫折するファイル」を特定せよ。
- 関数の長さ分布（上位N関数を抽出）
- ネストの深さ分布
- 1ファイル多責務（大きいファイル × 多くの公開シンボル）
- ドキュメンテーションの薄さ（公開APIでdocstring/JSDocなしの割合）

##### architecture（アーキテクチャ全体の妥当性）
あなたは**プロジェクト全体の構造を設計した立場のテックリード**である。本観点は「**現時点での設計の意図と実装の整合**」を見る。時系列の劣化（過去から現在への変化）は architecture-drift で扱う。
- ディレクトリ構造の意味（機能/レイヤー/ドメインの分け方、混在）
- エントリーポイントの整理
- 公開 API の境界（`__init__.py` / `index.ts` / public な型）
- 設定の集約
- ドメイン語彙の一貫性
- **モノレポの場合**: パッケージ間の構造評価は専用の `monorepo` 観点で扱う（同じ app 分類内）。本観点では各パッケージ内部の構造を見る。
- ※ 共有モジュールの肥大化（`utils`, `common`, `lib` の God 化）、God オブジェクトは architecture-drift で扱う（時系列で肥大化したものとして）

##### architecture-drift（レイヤー違反・循環依存・神化の蓄積）
あなたは**設計時の意図が劣化していないかを監視する建築士**である。architecture が「現時点の設計の妥当性」を見るのに対し、本観点は「**時系列で設計から逸脱した蓄積**」を見る。Git 履歴と組み合わせて評価する。
- 循環依存の検出（import 関係の抽出と循環探索）
- レイヤー違反（プレゼンが直接 DB を叩く、インフラがドメインに依存、等）
- **God オブジェクト/モジュール**（多くのファイルから参照されているモジュール、`utils`/`common`/`lib` の肥大化）。**変更履歴を見て「徐々に大きくなった」ものを特に重視**。
- 長大な import チェーン
- 抽象化レベルの不揃い
- ※ 設計の初期意図そのものの妥当性は architecture 観点で扱う

##### ddd-strategic（DDD 戦略的設計・成熟度・会話的モデリング）
あなたは**ドメインモデルの戦略家**であり、Eric Evans, Vaughn Vernon, Alberto Brandolini の知見を持つアーキテクトである。本観点は**プロジェクトが DDD を採用している前提**で、リポジトリ全体を俯瞰した戦略的評価を行う。DDD 採用の証跡が見当たらなければ、その旨を明示して評価をスキップしてよい。

###### Part 1: 境界づけられたコンテキスト（Bounded Context）

- **コンテキストの特定**: コードベースに**いくつのコンテキストが存在するか**を推定する。手がかり: ディレクトリ構造（`src/contexts/`, `bounded_contexts/`, `modules/`, モノレポなら `packages/`）、`namespace`/モジュール境界、独立した永続化境界、独立したユビキタス言語。
- **境界の明確さ**:
  - 各コンテキストがコードのどの範囲を占めるか明確か、それとも溶け合っているか
  - コンテキスト間の依存方向が一方通行か、双方向で結合しているか
  - **共有モジュール**（`utils`, `common`, `shared`）が複数コンテキストのドメインを抱え込んで「巨大な泥団子」化していないか
- **境界の漏れ**:
  - 別コンテキストのエンティティ・値オブジェクト・リポジトリを直接 import している箇所（`from other_context.domain import Order` のような結合）
  - ACL（腐敗防止層）なしで外部システム・レガシーシステムと結合している箇所
  - 共有データベース経由でコンテキストが結合している（同じテーブルを複数コンテキストが書き換える）
- **境界の数の妥当性**:
  - コンテキストが過剰に細かい（マイクロサービス病: 1機能=1コンテキスト）
  - コンテキストが粗すぎる（事実上モノリス）
- **出力時の数値**: 「推定コンテキスト数 N、境界違反候補 M 件」のように具体値を出す

###### Part 2: コンテキストマップ

検出された各コンテキスト間の関係を、以下の DDD パターンに分類して評価する:

| パターン | 意味 | 兆候 |
|---|---|---|
| **共有カーネル (Shared Kernel)** | 複数コンテキストが小さな共通モデルを共有 | 共有パッケージにドメインモデル |
| **顧客/供給者 (Customer/Supplier)** | 上流が下流の要求を考慮する関係 | 上流 API の変更が下流の要請で行われる |
| **順応者 (Conformist)** | 下流が上流に従う（影響力なし） | 外部 API の型をそのまま使う |
| **腐敗防止層 (ACL)** | 下流が上流を翻訳する層を持つ | `*.adapter.*`, `*.translator.*`, `acl/` |
| **公開ホストサービス (OHS) + 公表された言語 (PL)** | 上流が安定した API/スキーマを公開 | OpenAPI/Protobuf による契約 |
| **別々の道 (Separate Ways)** | 統合せず独立 | コンテキスト間に通信なし |
| **巨大な泥団子 (Big Ball of Mud)** | 境界が曖昧で混沌 | レイヤー無視、ドメインモデル不在 |

評価時のアウトプット:
- 検出されたコンテキスト間関係を**簡潔なコンテキストマップ**として記述する（テキストでよい）
- 関係が**不健全**なペアを特定（特に Conformist の濫用、ACL が必要なのに無い箇所、Shared Kernel の肥大化）
- 戦略的に**選択している関係 vs 偶発的に発生した関係**を区別

###### Part 3: コア / サブ / 汎用ドメインの区別

- **コアドメイン (Core Domain)**: ビジネス上の競争優位の源泉。最も投資すべき領域。
- **支援サブドメイン (Supporting Subdomain)**: コアを支えるが汎用ではないもの。
- **汎用サブドメイン (Generic Subdomain)**: 業界標準的なもの（認証、ロギング、メール送信等）。SaaS/OSS 利用が望ましい。

評価項目:
- **コアドメインがコードで識別可能か**: ディレクトリ命名、コードコメント、ADR でコアと明示されているか
- **投資の偏り**: 汎用ドメインに過剰投資していないか（自前認証システムの再発明等）、逆にコアに投資不足ではないか
- **テストカバレッジの偏り**: コアに最も手厚いテストがあるか（test-coverage 観点と相互参照）
- **コードの洗練度の偏り**: コアが最も丁寧に書かれているか、それとも全体平均的か
- **依存方向**: コアが汎用に依存するのは健全、逆は要注意

###### Part 4: ユビキタス言語の境界での振る舞い

- 同じ用語がコンテキストごとに**異なる意味**を持つことを許容できているか（DDD では正解）
- 用語の意味が**境界を越えて漏れている**: たとえば `Customer` がコンテキストAでは「契約者」、Bでは「閲覧ユーザー」、なのに同じ型を共有していないか
- **データベースカラム名・API フィールド名**もコンテキスト内のユビキタス言語に従っているか
- **翻訳テーブル/グロッサリ**の存在（用語集、用語の対応表）

###### Part 5: ドメインイベントの境界貫通

- ドメインイベントが**コンテキスト境界を越える**とき、契約が明示されているか（イベントスキーマ、バージョニング）
- イベントの**消費者契約テスト**の有無
- イベントが「内部イベント」と「公開イベント」で分かれているか（境界での漏出防止）
- 公開イベントが**過去形・不変・自己完結**になっているか（消費側が追加情報を取りに来なくて済むか）

###### Part 6: DDD 成熟度の段階モデル

リポジトリ全体の DDD 採用度を、以下の段階モデルで位置づける:

| 段階 | 特徴 |
|---|---|
| **段階 0: 未採用** | ドメインモデルがない、トランザクションスクリプトのみ、技術駆動の構造 |
| **段階 1: 戦術的のみ** | エンティティ・値オブジェクトの語彙はあるが、コンテキスト境界が曖昧。「DDD-lite」 |
| **段階 2: 境界の自覚** | 複数コンテキストの存在を認識し、ディレクトリ等で分離開始。ACL や Shared Kernel が部分的に出現 |
| **段階 3: コンテキストマップの整備** | コンテキスト関係が意識的に設計されている。コア/サブ/汎用の区別がある |
| **段階 4: 成熟** | コンテキストマップが ADR 等で明文化、ユビキタス言語が境界で適切に翻訳、イベントによる疎結合、継続的にリファクタされている |

評価出力:
- **現在の段階**を判定し、根拠を提示
- **次の段階に進むための具体的アクション**（短期/中期）

###### Part 7: 会話的モデリングの跡

DDD の戦略的設計は**ドメインエキスパートとの協働**から生まれる。コードベースにその協働の痕跡があるかを評価する:

- **Event Storming の跡**:
  - `docs/event-storming/`, `docs/modeling/`, `event-storming.md`
  - 写真・付箋スクリーンショット・Miro/Mural エクスポート
  - 「Domain Event」「Command」「Aggregate」「Policy」「Read Model」のラベル付きドキュメント
- **ドメインストーリーテリングの跡**:
  - `docs/domain-stories/`, ピクトグラム形式の図、ナレーション型のドキュメント
- **Example Mapping / 仕様駆動開発の跡**:
  - 受け入れ基準が「Given-When-Then」形式
  - Gherkin（`.feature` ファイル）の利用
- **ドメインエキスパートとの協働**:
  - コミット履歴に非エンジニアの参加（ビジネスサイド・PdM・ドメインエキスパート）
  - ADR にドメイン用語の議論が含まれている
  - 用語集（glossary）がドキュメントに含まれている
- **モデルの継続的進化**:
  - リファクタコミットの頻度と質
  - 「モデル変更により○○を改名」のようなコミットメッセージ
- これらが**ない**こと自体は問題ではないが、ある場合は DDD 採用が本物である強い証跡となる。**なくても DDD は実践可能**だが、ある方が継続性が高い。

###### 動作上の補足

- DDD 採用が不明確な場合、Phase 0 で検出した手がかり（`Aggregate`/`Entity`/`ValueObject`/`Repository`/`DomainEvent`/`domain/` ディレクトリ等）と、本観点で探す「コンテキスト境界」「ACL」「コンテキストマップ」「Event Storming の跡」等を総合判断する。
- **過剰判定を避ける**: モジュール分割があれば全部「コンテキスト境界」と呼ばない。境界づけられたコンテキストは「独立したユビキタス言語」を持つことが要件であり、単なるパッケージ分割とは違う。
- **コアドメインの判定は推測になりがち**。Phase 0 のプロジェクト種別、ADR、README から手がかりを取り、不明な場合は「ユーザー確認が必要」と明示する。
- 出力時は **DDD 用語をそのまま使う**こと（境界づけられたコンテキスト、ユビキタス言語、ACL等）。一般用語に翻訳して曖昧化しない。

###### 必須出力指標

- 推定コンテキスト数
- 境界違反候補数（別コンテキストからの直接 import 等）
- ACL 該当箇所数
- 共有モジュールに含まれるドメイン要素数
- DDD 成熟度段階（0〜4）
- 会話的モデリング痕跡の有無と種類

##### monorepo（モノレポ構造の健全性）
あなたは**モノレポを運用する開発リード**である。**この観点は Phase 0 でモノレポと検出された場合のみ実行する**。単一パッケージリポジトリでは省略。
- **パッケージ間の依存方向**: パッケージ A → B → C → A のような循環依存。`packages/*/package.json` の `dependencies` から依存グラフを構築して検出。
- **共有パッケージの肥大化**: `packages/shared`, `packages/common`, `packages/utils` 等が「全パッケージから参照される神パッケージ」になっていないか。被参照数の分布を見る。
- **公開境界の明確さ**: 各パッケージが `index.ts` / `__init__.py` / `mod.rs` などで公開 API を絞っているか、内部実装まで他パッケージから直接 import されていないか。
- **workspace 設定の整合性**: `pnpm-workspace.yaml` / `package.json#workspaces` / `turbo.json` / `nx.json` / `Cargo.toml#workspace.members` が実態と一致しているか。登録漏れ・登録過剰がないか。
- **バージョン整合性**: 同じ依存パッケージが複数のパッケージで異なるバージョンに固定されていないか（例: react 18.2.0 と 18.3.0 が混在）。
- **タスクオーケストレーション**: `turbo run`, `nx run-many`, `pnpm -r` などのタスク依存グラフが妥当か。並列実行可能なものが直列になっていないか。
- **パッケージ命名規約の一貫性**: `@org/foo`, `@org/bar` のような prefix が揃っているか。
- **各パッケージの「種別」の分布**: モノレポ内に web-service / library / cli が混在する場合、それぞれに適切な評価軸が当たっているか（Phase 0 のプロジェクト種別判定と連動）。
- **未使用パッケージの検出**: workspace に登録されているが、どこからも参照されていないパッケージ。
- **パッケージ境界の漏れ**: パッケージ A の内部ファイルを `../B/src/internal` のような相対パスで直接 import している箇所（境界違反）。

##### hotspot（変更頻度 × 複雑度のリスク領域）
あなたは**「次に壊れる場所」を予測したいプロジェクトマネージャー**である。
- 変更頻度ランキング: `git log --since="365 days ago" --name-only --pretty=format: -- <app配下> | sort | uniq -c | sort -rn | head -20`
- バグ修正コミット率: `git log --since="365 days ago" --grep="fix\|bug\|hotfix\|patch\|revert" -i --name-only --pretty=format: -- <app配下> | sort | uniq -c | sort -rn | head -20`
- コード年齢: 誕生日（`--diff-filter=A` の最古）、最終更新日
- **変更頻度高 × 巨大/深ネスト = 最優先リファクタ候補**

##### performance（実行時パフォーマンスの静的パターン評価）
あなたは**本番データ規模を知っているパフォーマンスエンジニア**である。hotspot が「Git の変更頻度」を見るのに対し、本観点は**コードパターン自体**からパフォーマンスリスクを抽出する。プロファイリングではなく**静的な兆候**を見る点に注意。
- **N+1 / ループ内I/O**: ループ内で `query`, `fetch`, `read`, `find_one`, `get_object` 等を呼ぶパターン。ORM 利用箇所では eager loading の欠如を疑う。
- **ブロッキングI/O の混在**: async/await を採用するコードベースで、同期 I/O（`requests.get`, `time.sleep`, ファイル同期 read）が混入していないか。
- **大規模ループ**: 入れ子ループの最内側が O(n²) 以上になりうる箇所。
- **メモリ全件ロード**: `.all()`, `read_all`, `JSON.parse(巨大ファイル)` のように全件をメモリに載せる箇所（ストリーミング処理の検討候補）。
- **不要な再計算**: 同じ計算を繰り返す箇所（メモ化・キャッシュの候補）。
- **インデックスを使わないクエリパターン**: `WHERE` 句の左辺に関数適用、`LIKE '%...'`（前方ワイルドカード）、SELECT *。
- **不要に同期化された処理**: 並列化可能なループ・I/O が直列化されている箇所。
- **大きなオブジェクトの不要なコピー**: deep copy・slice copy・`{...obj}` の濫用。
- **キャッシュの妥当性**: TTL 設計、無効化戦略、key の衝突可能性。
- **バンドルサイズへの影響（フロントエンド）**: barrel exports (`index.ts` から全部再エクスポート) が tree-shaking を阻害していないか。動的 import の利用箇所。
- **起動時間への影響**: モジュールトップレベルでの重い処理、起動時の不要な事前計算。
- 本観点は**静的解析の限界がある**ため、「疑い」「要計測」と明示し、断定を避けること。本番計測（プロファイラ、APM）が真の判断材料である旨を併記。

##### dead-code（参照されていないコード）
あなたは**コードベースのクリーンアップを担当する整理係**である。
- 未参照の公開シンボル（言語ごとに export パターンを変える: JS/TS `export`, Python `def`/`class`, Go `func` 大文字始まり, Rust `pub fn`）
- 未参照のファイル
- コメントアウトされた古いコード塊
- **誤検知が多いことを明示**: 動的呼び出し、リフレクション、文字列ベースのルーティング、プラグイン機構、DI コンテナ

##### ownership（バス係数・単一メンテナ依存）
あなたは**プロジェクトのリスク管理担当**である。
- 単一コントリビューター領域（`git shortlog -sn -- <file>` で寄与率90%以上のファイル）
- 直近1年で誰も触っていない領域
- アクティブコミッターのいない領域（過去にcommitした人が直近90日のコミッターにいない）
- コントリビューターの偏り（全体の50%以上を担う人数）

##### duplication（コード重複）
あなたは**DRY 原則の守護者**である。
- 構造的重複（5行以上の同一パターン）
- コピペの痕跡（同じコメント、同じ変数名）
- ロジックの分散（同じビジネスルールの複数実装）
- 「悪い重複」と「許容される重複」（疎結合の対価）の区別を明示

##### data-integrity（データ層の構造的リスク）
あなたは**「データが壊れたら誰が責任を取るのか」を考える DBA**である。
- トランザクション境界の集約度
- マイグレーションスクリプトの整理（番号付け、ロールバック手順、適用順序）
- 冪等性のパターン化（冪等キー設計の中央化）
- 外部API呼び出しとトランザクションの関係
- イベント発行とDB更新の関係（outbox パターンの有無）
- 時刻の扱い（UTC 統一、タイムゾーン情報）

##### observability（ログ/可観測性）
あなたは**ポストモーテム担当者**である。
- ロギングライブラリの統一
- 構造化ログの普及度
- 相関 ID / トレース ID の伝播
- メトリクス計装の網羅性（ゴールデンシグナル: レイテンシ・トラフィック・エラー・サチュレーション）
- エラー通知（Sentry, Rollbar など）の連携
- SLO/SLI の定義

##### documentation（補助的: 本体コードのドキュメント）
あなたは**初めて使う外部開発者**である。
- 公開関数/クラスの docstring/JSDoc 充実度
- 複雑なロジックに「なぜ」コメントがあるか

---

#### 1.2 test（テストコード）

> **本質**: 仕様の表現としての信頼性、本番リグレッションの検知力、テスト自体の保守容易性。

テストコードもコードである。test 観点を中心に評価する。

##### test-coverage（網羅性の棚卸し）
あなたは**QAリード**である。「リリース後に壊れたらどこから直すか」の優先順位を付けよ。
- テストファイルの分布（実装ファイルとの比率、極端に低い領域）
- テストファイルが存在しない公開モジュール
- クリティカルパスのテスト不足（app の hotspot と相互参照）
- カバレッジレポート（`coverage.xml`, `lcov.info`, `coverage/` 等）の参照
- **テストの種類別カバー範囲**（種類ごとのバランス自体は test-pyramid 観点で扱う）

##### test-quality（低品質テストの棚卸し）
あなたは**懐疑的なテストレビュアー**である。
- アサーション無しテスト
- 常に真のアサーション（`expect(true).toBe(true)` 等）
- 過剰モック（モック行数が本体行数を超える）
- 巨大テストファイル
- スキップ/TODO の蓄積（`it.skip`, `xtest`, `@pytest.mark.skip` 等）
- Flaky テスト履歴（`git log --grep="flaky\|intermittent"`）

##### test-strategy（PBT 採用箇所と未採用箇所の偏り）
あなたは**テスト戦略の設計者**である。PBT 採用前提。
- PBT 採用箇所のマップ（`fc.assert`, `@given`, `propTest`, `prop_` などの利用箇所）
- PBT 未採用だが向く箇所（パーサ、シリアライザ、ソート、暗号、エンコーダ）
- PBT 過剰採用（ビジネスルール境界値の例示が消えている）
- 生成器の品質（境界値: 空、最大、Unicode、NaN）

##### test-pyramid（テストピラミッドのバランス）
あなたは**テストアーキテクトとして全体のバランスを設計する立場**である。test-strategy が「PBT 採用の偏り」を見るのに対し、本観点は**テストの種類（ユニット/統合/E2E）の比率と配置**を見る。
- **テスト種類の検出**:
  - ユニット: `tests/unit/`, `*.unit.test.*`, モックを多用、外部I/Oなし
  - 統合: `tests/integration/`, `*.integration.test.*`, 実DB/実外部APIに接続
  - E2E: `tests/e2e/`, `playwright/`, `cypress/`, Selenium、実ブラウザ・実エンドポイント
- **理想と現状の比較**: 一般的な「テストピラミッド」は ユニット多 > 統合中 > E2E少。逆ピラミッド（E2E が最多）や「ホテルバー型」（ユニットと E2E のみ）になっていないか。
- **テスト実行時間の分布**: ユニットが秒単位、統合が分単位、E2E が10分単位といった想定からの逸脱がないか（ユニットなのに DB に接続して遅い等）。
- **役割の混在**: 統合テストに分類されているが実質ユニット、ユニットなのに E2E 並みに遅い、等のラベル違反。
- **テストの種類ごとの保守コスト**: E2E の Flaky 率、統合テストの環境依存度。
- **欠落している層**: 「ユニットしかない」「E2E しかない」のような極端な偏り。
- **テスト実行戦略との整合**: CI で全種類が回るか、PR では unit + integration のみで E2E は nightly か、など。
- 出力としては「ユニット N1 件 / 統合 N2 件 / E2E N3 件、比率 X:Y:Z」のように**具体数値**を出すこと。

##### maintainability（テストの保守性）
あなたは**テストを引き継ぐ次の担当者**である。
- テスト設定（fixture, conftest, setup）の複雑さ
- ヘルパー関数の散逸度
- テストデータの一元管理度

##### readability（テストの可読性）
- テスト名が「何を保証するか」を表現しているか
- Arrange-Act-Assert 構造の明確さ
- 過度なシェアード fixture（テストを読むのに複数ファイルが必要）

##### hotspot（テストのホットスポット）
- 頻繁に修正されているテストファイル（実装の変動を反映 or テストが不安定）
- バグ修正コミットで頻繁に変更されるテストは「漏れ続けているテスト」の可能性

##### dead-code（不要テストの検出）
- スキップ状態が1年以上のテスト
- 削除済み実装に対応するテストの残骸

##### security（補助的: テストフィクスチャの安全性）
- 本物の認証情報・APIキーがテストフィクスチャに混入していないか
- 本番DBへの接続文字列がテストコードに残っていないか

##### supply-chain-attack（補助的: テストコードに偽装した混入）
- テストコード内に動的コード実行（`eval`, `exec`）が追加されていないか
- テスト用と称した外部接続コードが本番経路に流入する仕組みになっていないか
- テストヘルパー内の不審な処理（モックの皮を被ったリバースシェル等）

##### documentation（補助的: テストがドキュメントになっているか）
- 「使い方を示すサンプル」として読めるテストがあるか

##### duplication（補助的: テストの重複）
- 同じ前提条件・同じアサーションパターンが複数テストに散在していないか

---

#### 1.3 build（ビルド・パッケージ定義）

> **本質**: 依存の健全性、ビルドの再現性、パッケージ境界の妥当性。

ファイル数は少ないが、影響範囲が極めて大きい分類。**全ファイル詳読**。

##### dependencies（依存の全体棚卸し）
あなたは**サプライチェーン攻撃を警戒するセキュリティエンジニア**かつ**長期メンテを考える開発者**である。
- 全依存の列挙（直接依存と推移的依存の区別）
- 古い依存（メジャー/マイナーの遅延段数、具体バージョン記載）
- 既知 CVE（`npm audit`, `pip-audit`, `bundle audit`, `cargo audit` の参照、実行はユーザー許可要）
- メンテ状況（メンテナ単一、スター極小、過去1年更新なし）
- ライセンス分布（GPL系混入、ライセンス非明示）
- 未使用の依存（dead-code 観点と相互参照）
- 重複機能の依存（`moment` と `dayjs` 併存等）
- postinstall スクリプトを持つ依存

##### security（ビルド設定のセキュリティ）
あなたは**ビルドパイプラインを攻撃される側のセキュリティエンジニア**である。
- ビルドスクリプト内のシークレット
- npm scripts / Makefile に書かれた外部URL fetch（typosquatting や中間者攻撃のリスク）
- ビルド時の任意コード実行を許す設定

##### supply-chain-attack（依存パッケージのサプライチェーン健全性）
あなたは**サプライチェーン攻撃を警戒するセキュリティエンジニア**である。build 分類は依存定義の中心地なので、本観点を**主要評価**として扱う。
- **依存パッケージの全件洗い出し**: `package.json`, `requirements.txt`, `Pipfile`, `Gemfile`, `go.mod`, `Cargo.toml` 等から全依存（直接 + 推移的）を列挙
- **typosquatting 検出**: 既知の人気パッケージに酷似した名前（`lodash` vs `lodahs`、`requests` vs `requestz`、`colors` vs `colorz` 等）を機械的にチェック
- **メンテナンス状況**: メンテナ単独、長期間更新なし、最近メンテナが急に増えた・変わった依存
- **postinstall / preinstall / postpublish / prepare スクリプト**: 全依存でこれらのスクリプトを持つパッケージを列挙
- **バージョン固定の状況**: メジャー版固定 vs `^` / `~` / `*` の利用度
- **ロックファイルの整合性**: package.json と lockfile の不一致
- **既知 CVE**: `npm audit`, `pip-audit`, `bundle audit`, `cargo audit` の利用推奨（ユーザー許可があれば実行）
- **重複機能の依存**: 同じ機能を複数パッケージで実現（moment + dayjs 等）→ サプライチェーン面積の不必要な拡大
- **SBOM の存在**: `bom.json`, `sbom.json`, `cyclonedx.json` 等

##### dead-code（未使用のパッケージ定義）
- `workspaces` に登録されているが空のパッケージ
- 参照されていない `scripts` エントリ

##### monorepo（workspace 設定の健全性）
あなたは**モノレポを運用する開発リード**である。**Phase 0 でモノレポと検出された場合のみ実行**。
- workspace 定義ファイル（`pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `Cargo.toml` の `[workspace]`, `lerna.json`）の一貫性
- `package.json` の `workspaces` キーと workspace 定義ファイルの整合性
- ルート `package.json` と各パッケージの `package.json` の責務分離
- パッケージマネージャ固有の機能の活用度（pnpm の `catalog`, npm の `overrides`, yarn の `resolutions`）
- バージョン管理戦略（fixed / independent、changesets, lerna version 等）の明示
- リポジトリ全体のビルド・テスト・lint の root スクリプト整備度

---

#### 1.4 runtime（環境構築 / ランタイム）

> **本質**: 再現性、最小権限、ビルド効率、本番稼働時の堅牢性。

Docker compose 前提のプロジェクトでは特に重要。**全ファイル詳読**。

##### runtime-config（ランタイム設定の品質）
あなたは**本番デプロイを実行する運用エンジニア**である。
- **ベースイメージの固定度**: `:latest` の使用、SHA pin の有無、再現性
- **マルチステージビルド**: 最終イメージに不要なビルド成果物が含まれていないか
- **レイヤー順序の最適化**: 依存インストールとソースコピーの順序（キャッシュ効率）
- **不要な root 権限・特権モード**
- **USER 指定**（非rootユーザーで動作させる）
- **HEALTHCHECK の定義**
- **ボリュームマウント・ポート公開の妥当性**
- **環境変数のデフォルト値とドキュメント化**
- **.dockerignore の整備**（不要ファイルがコンテキストに入っていないか）
- **compose.yml の network/volume 設計**
- **環境差分（dev/staging/prod）の管理方法**（compose.override.yml、複数compose ファイル）

##### security（コンテナのセキュリティ）
あなたは**コンテナエスケープを狙う攻撃者**である。
- 不要な capability の付与（`--privileged`, `--cap-add`）
- ホストファイルシステムの過剰マウント
- secret の `ENV` 直書き（build 時に layer に残る）
- ベースイメージの既知脆弱性
- root 実行

##### supply-chain-attack（補助的: コンテナ経由の混入）
- Dockerfile で `curl ... | sh` や `wget ... | bash` のようなパイプ実行
- 信頼できない外部リポジトリからの依存取得（`apt-add-repository` で見慣れない PPA 追加等）
- イメージタグの `latest` 利用や SHA pin なし
- マルチステージビルドの最終ステージに含まれるべきでない開発ツール・デバッグツール

##### dead-code（補助的）
- 参照されていない compose service
- 使われていない build target

##### observability（補助的: コンテナの可観測性）
- ログドライバの設定
- ヘルスチェックの存在

##### performance（補助的: ランタイム構成のパフォーマンス）
- ビルド時間に影響する非効率なレイヤー構成
- 実行時のリソース制限（compose の `deploy.resources.limits` 等）が定義されているか
- マルチプラットフォームビルドの妥当性（不要なアーキテクチャを混ぜていないか）

---

#### 1.5 devenv（開発環境）

> **本質**: 開発者体験、再現性、チーム間の一貫性。

VSCode devcontainer 前提のプロジェクトでは要点が明確。**全ファイル詳読**。

##### devenv-quality（開発環境の品質）
あなたは**新規参画メンバーの環境構築を支援するメンター**である。Phase 0 で検出した開発ツールチェーン（VSCode devcontainer / JetBrains / Vim / direnv / mise / pre-commit 等）に応じて適用する評価項目を切り替える。
- **devcontainer.json**（採用時のみ）:
  - features の妥当性（不要な feature の混入）
  - postCreateCommand / postStartCommand の冪等性（再実行可能か）
  - 拡張機能リストの妥当性（チーム合意あるか、過剰でないか）
  - workspaceFolder, mounts の整合性
- **.vscode/**（採用時のみ）:
  - settings.json の言語固有設定が `.editorconfig` と整合しているか
  - launch.json（デバッグ設定）の動作確認可能か
  - extensions.json（推奨拡張）が devcontainer.json と整合
- **.idea/**（JetBrains 採用時のみ）:
  - 個人設定（`.idea/workspace.xml` 等）が誤ってコミットされていないか（`.gitignore` で除外されているべき）
  - コードスタイル設定が `.editorconfig` と整合
  - 共有すべき設定（コードスタイル、ファイルテンプレート）と個人設定の分離
- **.editorconfig**:
  - インデント・改行・文字コードの統一
  - 各エディタ設定との二重定義による矛盾がないか
- **言語バージョン固定**:
  - `.tool-versions` (asdf/mise), `.nvmrc`, `.python-version` 等の存在と一貫性
  - Dockerfile のランタイムバージョンと一致しているか
  - 複数の固定方法が混在して矛盾していないか（`.nvmrc` と `package.json#engines` の不一致など）
- **direnv（`.envrc`）**:
  - `.envrc` がコミットされている場合、機微情報を含まないか
  - `.envrc.example` と本物の `.envrc` の使い分けが明確か
- **mise / asdf 設定**:
  - tasks 定義の妥当性
  - plugin の固定度
- **pre-commit hooks**:
  - `.pre-commit-config.yaml`、`lefthook.yml`、`.husky/`、`lint-staged` 設定
  - hook の冪等性、過剰な hook（commit を遅くする）
  - hook を bypass する手順がチームで共有されているか（緊急時のため）
  - CI と pre-commit で同じチェックが二重に走っていないか

##### security（補助的: 開発環境のシークレット）
- `.vscode/settings.json` などに個人のAPIキーが混入していないか
- devcontainer.json の env に直書きシークレットがないか

##### dead-code（補助的）
- 推奨拡張のうち実際にプロジェクトで使われていないもの
- 古い tool-versions エントリ

---

#### 1.6 ci（CI パイプライン）

> **本質**: パイプラインの正しさ、最小権限、シークレット保護、サプライチェーン保護。

`.github/workflows/` の各 yml は1ファイルずつ意味が大きいので**全ファイル詳読**。

##### ci-quality（CI パイプラインの品質）
あなたは**パイプライン設計を担当する DevOps エンジニア**である。Phase 0 で検出した CI ツールに応じて該当節を適用する。

**共通評価項目（CI ツールに関わらず）**:
- リトライ戦略
- 失敗時の通知連携（Slack, メール、Issue 自動作成等）
- 環境（development/staging/production）ごとの保護ルール
- PR ごとのチェック必須化
- ジョブのタイムアウト設定（無限ループ防止）
- 不要に頻繁な定期実行（cron）の見直し

**GitHub Actions の場合**:
- `permissions:` の最小化（GITHUB_TOKEN の write 範囲、デフォルト read-only 化）
- third-party action の固定方法（tag参照ではなく **SHA pin** が望ましい）
- secrets の取り扱い（ログマスキング、artifacts への漏洩）
- matrix の網羅性とコスト効率
- キャッシュキーの妥当性（`actions/cache` の key 設計）
- reusable workflow / composite action の活用度
- concurrency 設定（無駄な並列実行の抑止）
- environments（保護環境）の利用
- OIDC を使った認証への移行（long-lived secret 削減）

**GitLab CI の場合**:
- stage 設計と DAG 化（`needs:` の活用）
- protected variables / masked variables の利用
- `rules:` / `only:` / `except:` の妥当性
- `include:` による共通化
- artifacts の有効期限設定
- container scanning, SAST, dependency scanning の組み込み

**CircleCI の場合**:
- workflows の DAG 設計
- orbs の SHA pin / バージョン固定
- contexts の利用（secrets の名前空間化）
- approval ジョブの活用

**Jenkins の場合**:
- Jenkinsfile（Declarative / Scripted）の保守性
- shared library の利用
- credential binding の正しさ（平文露出回避）
- agent の隔離度

**Azure Pipelines の場合**:
- template の利用度
- variable groups と key vault 連携
- service connection の権限スコープ

**Bitbucket Pipelines の場合**:
- pipe の固定度
- 並列ステップの活用

**ツール非依存の本質的な問い**:
- 「CI が落ちたとき、誰が何を最初に見ればよいか」が明確か
- 「main ブランチを保護する最小チェックは何か」が明確か
- 「リリース可能性」を機械的に判定できるか

##### security（CI のセキュリティ）
あなたは**CI をハイジャックして悪意あるコードをデプロイしようとする攻撃者**である。
- `pull_request_target` の濫用（信頼できない PR からの secret 露出）
- fork からの PR に対する secret 露出
- 外部からのコード実行可能性（`run` ステップで信頼できない入力を評価）
- third-party action の supply chain（compromised action）
- ビルド成果物への署名・検証
- OIDC を使った認証への移行余地（long-lived secret を減らす）

##### supply-chain-attack（補助的: CI による混入）
- third-party action の SHA pin がされていない箇所（`actions/checkout@main` のようなタグ参照）
- 過去に compromise が報告された action の使用履歴
- `run:` ステップで `curl ... | bash` のようなパイプ実行
- 自前 action / composite action のソース管理状況
- ビルドキャッシュへの不審な書き込み

##### observability（CI の可観測性）
- 失敗時のアラート連携
- 実行時間の計測と劣化監視
- ジョブ履歴・ログ保持期間

##### hotspot（補助的: 頻繁に修正される CI）
- 不安定なパイプラインの兆候（同じ workflow への修正コミット多数）
- バグ修正コミットが集中する workflow

##### dead-code（補助的）
- 参照されていない workflow（trigger 条件で発火不能）
- 使われていない reusable workflow / composite action
- スケジュール実行の workflow で実質的に止まっているもの

##### duplication（補助的）
- 複数 workflow に同じ steps が散在
- 共通化できる setup ステップ（reusable workflow / composite action で抽出可能なもの）

##### performance（補助的: CI の実行効率）
- CI 全体の実行時間トレンド（劣化していないか）
- キャッシュヒット率の低い steps
- 並列化できるはずなのに直列化されている jobs
- 不要なワークロード（全 push でフル E2E が走る等）

---

#### 1.7 iac（デプロイ・IaC）

> **本質**: 本番環境定義の正しさ、ドリフト管理、最小権限、デプロイ事故の予防。

Terraform、Kubernetes マニフェスト、Helm チャート、Ansible Playbook 等のインフラ定義。**全ファイル詳読**を基本とし、規模が大きい場合はサンプリング。

##### iac-quality（IaC・デプロイの品質）
あなたは**インフラを運用する SRE / プラットフォームエンジニア**である。
- **Terraform / OpenTofu の場合**:
  - state ファイルの管理方法（ローカルに置いていないか、リモートバックエンドの設定、state ロック）
  - module 化と再利用性（重複したリソース定義の有無）
  - 環境変数化されるべきハードコード値（環境ごとの差分が tfvars で表現されているか）
  - drift の検出手段（`terraform plan` を CI で定期実行しているか）
  - provider バージョンの固定
  - リソースの命名規約の一貫性
  - tag/label の網羅性（コスト追跡、オーナー識別のため）
- **Kubernetes マニフェスト / Helm の場合**:
  - resource requests/limits の設定
  - liveness/readiness probe の設定
  - PodSecurityContext（非 root、readOnlyRootFilesystem）
  - NetworkPolicy の有無
  - Secret の管理方法（平文で manifest に書かれていないか、External Secrets / Sealed Secrets の利用）
  - namespace 設計と RBAC の最小権限
  - Helm values の環境差分管理
- **Ansible / Chef / Puppet の場合**: 冪等性、handler の利用、変数のスコープ管理
- **共通**:
  - デプロイのロールバック容易性
  - 環境（development/staging/production）ごとの保護ルール
  - blue-green / canary の有無
  - 設定変更の audit log

##### security（IaC のセキュリティ）
あなたは**インフラ侵害を狙う攻撃者**である。
- 過剰な IAM 権限（`*` リソースへの `*` アクション付与）
- 公開された S3 バケット、SG の `0.0.0.0/0` 許可
- 平文の secret（環境変数、parameter store 経由でない）
- ステートに secret が含まれている可能性（Terraform state の暗号化）
- 暗号化されていないストレージ・通信
- ログ・監査の有効化漏れ（CloudTrail, k8s audit log）

##### supply-chain-attack（補助的: IaC モジュール経由の混入）
- 外部 Terraform module の参照元（公式 / 個人レポジトリ / Git URL）
- module のバージョン固定の有無
- Helm Chart の信頼できるソースの利用
- `helm install` で外部リポジトリから取得する Chart の検証
- 信頼できない provider の利用

##### data-integrity（補助的: マイグレーション・データストア定義のリスク）
- マイグレーション適用順序のIaC側からの制御
- DB バックアップ・ポイントインタイムリカバリの設定
- ストレージのスナップショット保持期間

##### observability（補助的: インフラ可観測性）
- メトリクス収集・ログ集約の設定
- アラート定義の網羅性
- デプロイ履歴の追跡

##### hotspot（補助的: 頻繁に修正される IaC）
- 不安定なインフラ定義（同じファイルへの修正多数）

##### dead-code（補助的）
- 適用されていない module / リソース
- コメントアウトされた古い resource

##### duplication（補助的）
- 同じ resource 定義が複数 module に散在
- 環境ごとの設定で共通化できる部分

##### performance（補助的: インフラリソース効率）
- オーバープロビジョニングされたリソース（不要に大きいインスタンスタイプ、CPU/memory 要求）
- アンダープロビジョニングのリスク（HPA の上限が低すぎる、PDB 未設定）
- コスト最適化の機会（Spot/Preemptible の活用余地、リザーブドインスタンスの検討）

---

#### 1.8 meta（リポジトリメタ）

> **本質**: リポジトリの「自己説明能力」と「運営の健全性」。OSS なら特に重要、社内プロジェクトでも長期保守性に直結。

##### governance（運営の健全性）
あなたは**OSSコミュニティの運営を経験したメンテナ**である。社内プロジェクトでも長期保守の観点で同じ評価軸を適用するが、**Phase 0 で判定した公開度（public-oss / internal-oss / internal-private）に応じて評価の厳しさを切り替える**。
- **LICENSE**: ファイル存在、内容の妥当性、年号と著作権者の更新。`public-oss` では必須、欠如は Critical。
- **README**: プロジェクトの目的、セットアップ、使い方、貢献方法へのリンクが揃っているか。公開度に関わらず必須。
- **CONTRIBUTING.md**: 貢献の手順、コミット規約、PRレビュー方針。`public-oss` / `internal-oss` で必須、`internal-private` では推奨。
- **SECURITY.md**: 脆弱性報告の窓口、サポート対象バージョン。`public-oss` で必須、`internal-oss` で推奨。
- **CODE_OF_CONDUCT.md**: 行動規範。`public-oss` で必須、それ以外は任意。
- **CHANGELOG.md** または release notes: 公開度に関わらず重要だが、`public-oss` では必須レベル。
- **NOTICE**: サードパーティライセンスの帰属表記（必要なら）。
- **issue / PR テンプレート**: `.github/ISSUE_TEMPLATE/`, `.github/pull_request_template.md`。
- **CODEOWNERS**: レビュー担当の明示。組織内ユーザー名の露出に注意（security 観点と相互参照）。
- **評価出力**: 「公開度: X、必須ファイル充足: M/N、不足ファイル: ...」の形式で**具体的な充足率**を出すこと。

##### documentation（ドキュメント健全性）
あなたは**初めてこのリポジトリを訪れる人**である。
- README の充実度（目的、前提、セットアップ、使い方、トラブルシュート）
- セットアップ手順の正確性（書かれているコマンドが本当に動くか、Phase 0 の指紋情報と突合）
- アーキテクチャ図・ADR の有無（`docs/adr/`, `docs/architecture/`）
- ドキュメントの陳腐化（README に古いコマンド名、なくなったオプションが残っていないか）
- API ドキュメントの自動生成・更新状況
- 言語の一貫性（README が英語/日本語混在で混乱していないか）

##### security（メタファイルのセキュリティ）
あなたは**機密情報の漏洩経路を網羅したい監査人**である。リポジトリのメタファイルは見落とされやすいシークレット混入経路。
- README にシークレットや内部URLが書かれていないか
- `.gitignore` で機微なファイルが除外されているか（`.env`, `*.key`, `*.pem`, `*.p12`, `id_rsa*`, `.aws/credentials` 等）
- `.gitattributes` で機微なファイルが意図せず追跡対象になっていないか
- `CHANGELOG` / `release notes` に内部システム名・顧客名・脆弱性詳細が混入していないか
- `CODEOWNERS` の記載が漏洩リスクを高めていないか（社内ユーザー名の露出）

##### supply-chain-attack（補助的: メタファイル経由の混入）
- README のセットアップ手順に `curl ... | bash` 系の危険なコマンドが含まれていないか
- `.gitignore` に意図的に**追跡から外された秘密の実装ファイル**がないか（Git で見えないがビルドに組み込まれる）
- GitHub Actions の `workflows` を README から間接的に呼び出すパスがないか

##### dead-code（補助的）
- 言及されているがリポジトリに存在しないファイルへのリンク
- 古いリンク切れ

##### ddd-strategic（補助的: DDD 関連ドキュメントの整備）
あなたは**DDD 戦略の番人**である。app での評価と相互参照しながら、メタ情報の整備状況を評価する。
- **ADR (Architecture Decision Records)** の整備:
  - `docs/adr/`, `docs/architecture/decisions/` の存在
  - 境界づけられたコンテキストに関する ADR
  - コンテキスト間関係の選択（Conformist / ACL / OHS+PL 等）に関する ADR
- **コンテキストマップのドキュメント化**:
  - 図（PlantUML、Mermaid、画像）または文章による明示
  - 各コンテキストの責務・境界・依存先の説明
- **用語集（Glossary / Ubiquitous Language）の存在**:
  - `docs/glossary.md`, `docs/terms.md`, `docs/ubiquitous-language.md`
  - 境界ごとの用語定義（同じ語の意味の違いも記載）
- **Event Storming・ドメインモデリングのアーティファクト**:
  - `docs/event-storming/`, `docs/modeling/`, ワークショップ記録
- **README での DDD 採用宣言**:
  - 「本プロジェクトは DDD を採用」「ドメイン層・アプリケーション層・インフラ層の責務」等の説明
- **不在の場合の扱い**: これらのドキュメントが**ない**こと自体は app 側の DDD 成熟度評価に直結する（成熟度段階を下げる根拠）。ただし「ドキュメントがないこと = DDD でない」と短絡しないこと。コードに表現されていれば DDD は成立する。

---

#### 各分類・各観点の出力フォーマット（Phase 1 共通）

```
## [分類名] / [観点名] スキャン

### 概況
（この分類・観点に対する1〜2段落の総評）

### 主要発見（上位 $TOP 件、または少数なら全件）
| 順位 | 対象 | 指標値 | 重大度 | 一言コメント |
|---|---|---|---|---|
| 1 | path/to/file | 行数 1200 / 変更頻度 45 | 🔴 Critical | ... |

### 分布の特徴
- ...

### 推奨アクション（この観点で）
- 短期 / 中期 / 長期

### 制約・前提
- 目視推定の箇所、ツール未使用、誤検知要因
```

### Phase 1.5: セルフレビューパス

Phase 1 の結果を**別人格で読み直す**。以下のカテゴリごとに具体項目をチェックし、各項目について **Yes/No と根拠**を明示せよ。

#### 1.5-A. 見落としチェック（マトリクスのカバー率）

1. **評価予定セルがすべて実行されたか?** Phase 0 で宣言した「分類×観点リスト」と、Phase 1 で実際に出力された内容を突き合わせ、欠落セルを列挙する。ゼロでない場合、実行できなかった理由を説明する。
2. **分類に属するファイルが少なくとも1つの観点で言及されたか?** 分類ごとに「一度も登場しなかったファイル」を列挙する。
3. **削除されたコード/モジュールも評価したか?** Git 履歴で削除されたが言及すべきもの（例: 機能廃止の痕跡、移行未完了）。
4. **テストファイル自体を観点別に評価したか?** test 分類だけでなく、テストフィクスチャに本物の機密が混入していないか（security 観点）も確認。
5. **コード以外を評価したか?** マイグレーション、設定ファイル、CI/CD 設定、Dockerfile、devcontainer.json、IaC、README、ライセンス、`.gitignore`、`.gitattributes`、`.editorconfig` 等。
6. **Phase 0 の指紋情報と Phase 1 の結論に矛盾はないか?** 例: PBT 採用と Phase 0 で言ったのに、test-strategy で「PBT 一切なし」と結論していないか。プロジェクト種別を `web-service` と判定したのに、observability を「不要」と扱っていないか。

#### 1.5-B. 誤検知・過剰指摘チェック

7. **dead-code の指摘で誤検知要因が明示されているか?** 動的呼び出し、リフレクション、文字列ベースのルーティング、プラグイン機構、DI コンテナ、トリガーで起動される workflow 等で、誤検知になりうる項目を列挙する。
8. **コンテキストを読めば問題ない指摘はないか?** 別の箇所で対処済み、フレームワークが自動処理、明示的な意図がある（コメントで説明されている等）。
9. **個人的好みと根拠ある指摘を区別したか?** 「自分はこの書き方が好き」レベルの主張を Medium 以上で出していないか。
10. **同じ問題を複数観点・複数分類で重複指摘していないか?** 例: 同じファイルが app/security と meta/security の両方で出ている場合、本質的な分類に1つに集約する。

#### 1.5-C. 重大度・スコアの妥当性チェック

11. **Critical を付けたものは「障害時の被害」または「攻撃成立経路」を具体的に説明できるか?** 「危険そう」では不十分。「この入力で、この経路で、この結果が起きる」と書けない Critical は High に格下げする。
12. **健康スコア (1〜5) は操作的定義に従って付けたか?** 印象論で「3」と付けていないか。スコアの根拠が他者にも納得できる形か。
13. **数値根拠が明示されているか?** 「巨大」「多数」だけでなく、「1234 行」「12 ファイル」のような具体値が添えられているか。

#### 1.5-D. 観点間・分類間の整合性チェック

14. **観点間で矛盾する推奨を出していないか?** 例: パフォーマンス最適化が可読性を犠牲にしている、抽象化追加（architecture）が単純化（maintainability）と衝突。衝突がある場合は**どちらを優先すべきか理由付きで決着**させる。
15. **分類境界の見直し**: 「app に分類されているが、実は build や ci や iac だった」というファイルはないか? あれば分類を訂正し、関連観点を再評価する。

#### 1.5-E. プロジェクト種別との整合

16. **Phase 0 で判定したプロジェクト種別に合った重み付けが反映されているか?** 例: ライブラリと判定したのに observability を主要扱いしていないか。web-service と判定したのに data-integrity が軽量扱いになっていないか。

#### 1.5-F. 出力

セルフレビューの結果は、Phase 1 の各指摘に対する **追加・撤回・重大度変更・統合・分類訂正** として明示せよ:

```
## セルフレビュー結果

### 自問への回答
- 1.5-A.1（カバー率）: Yes (全42セル中42セル実行) / No (X セル未実行、理由: ...)
- 1.5-A.2: ...
（全16項目）

### 追加された指摘
- ...

### 撤回した指摘
- [元の指摘] を撤回。理由: ...

### 重大度を変更した指摘
- [指摘] Critical → High。理由: ...

### 統合した指摘（重複解消）
- [app/security の X] と [meta/security の Y] を統合し、app/security 側に集約。

### 分類を訂正したファイル
- `scripts/migrate.sh` を app → iac に訂正。

### 観点間の衝突解決
- ...
```

### Phase 2: 優先順位付け（インパクト × コスト）

Phase 1（と1.5）の全発見を統合し、**インパクト × コスト** のマトリクスで並べ替える。

#### インパクト判定基準（操作的定義）

| レベル | 該当条件（いずれか満たす） |
|---|---|
| 🔴 高 | 障害時にユーザー全体に影響 / データ破損リスク / セキュリティ侵害可能性 / 本番停止リスク |
| 🟠 中 | 特定機能のみ影響 / 開発生産性を大きく阻害 / 段階的に悪化中 |
| 🟡 低 | 内部品質のみ影響 / ユーザー体感ゼロ / 美観・好み |

#### コスト判定基準（操作的定義）

| レベル | 該当条件 |
|---|---|
| 🔴 高 | 2スプリント以上 / 複数チーム合意必要 / 移行期間が必要 / アーキテクチャ変更を伴う |
| 🟠 中 | 1スプリント以内 / 単一チームで完結 / 限定的なリファクタ |
| 🟡 低 | 1日以内 / 孤立した変更 / 既存テストで担保される |

#### 出力

```
## 優先順位マトリクス

### 🔴 即着手すべき（高インパクト × 低〜中コスト）
1. [対象] / 分類: ... / 観点: ... / インパクト根拠: ... / コスト根拠: ...

### 🟠 計画して着手（高インパクト × 高コスト）

### 🟡 余裕があれば（低インパクト × 低コスト、クイックウィン）

### ⚪ 静観（低インパクト × 高コスト、やらない判断も妥当）
**目的**: 「やらない」という意思決定の記録。発見はしたが対応を見送る項目を明示的に列挙することで、将来のレビューで重複検出を避け、判断の透明性を保つ。
**書式**: 各項目に「再評価の条件」を併記する（例: 「依存パッケージのメジャーアップデートが出た時に再評価」「次回のチーム拡大時に再評価」）。条件が思いつかなければ静観ではなく Phase 1 の Low に格下げ。
**ルール**: 静観項目が10件を超えたら、本当に静観で良いかセルフレビューを促す（多すぎる静観は「気づかないふり」の温床）。

### ❓ 判断保留（データ不足、ユーザー判断が必要）
```

### Phase 3: 健康スコアカード & アクションロードマップ

#### 健康スコアカード

各分類・観点を 1〜5 段階で評価（5が良い）。継続スキャンで推移を追える形式。

##### スコア 1〜5 の操作的定義

| スコア | 意味 | 該当条件（例） |
|---|---|---|
| 5 | 業界ベストプラクティス相当 | 必須指標がすべて目標値内、Critical/High 指摘なし、模範的な構造 |
| 4 | 良好、軽微な改善余地 | Medium 指摘が数件、必須指標は概ね健全 |
| 3 | 平均的、改善余地あり | High 指摘が数件、または Medium が多数 |
| 2 | 要注意、計画的改善が必要 | Critical 指摘が1件、または High が多数、または必須指標の半数以上が目標未達 |
| 1 | 即対応が必要 | Critical 指摘が複数、または分類の本質的機能が壊れている疑い |

各観点の重み付けは Phase 0 で判定した**プロジェクト種別**に従う（主要 1.0 / 通常 0.8 / 軽量 0.5）。⚠️（補助）観点は重み 0.5 で算出。

##### スコア推移の追跡（--baseline / --save）

スコア結果は次回スキャンとの比較を可能にするため、JSON 形式で保存・読み込みできる。

**保存形式（`--save=<path>`）**:

```json
{
  "version": "1.0",
  "scanned_at": "2026-05-25T10:30:00Z",
  "scope": ".",
  "project_type": "web-service",
  "categories": ["app", "test", "build", "runtime", "devenv", "ci", "iac", "meta"],
  "scores": {
    "app": {
      "security": 3,
      "maintainability": 2,
      "...": "..."
    },
    "test": { "...": "..." }
  },
  "metrics": {
    "todo_fixme_total": 234,
    "bug_fix_commit_rate": 0.18,
    "coverage_percent": 62,
    "...": "..."
  }
}
```

**比較出力（`--baseline=<path>`）**:

```
## 健康スコアカード（前回比較）

| 分類 | 観点 | 今回 | 前回 | 変化 |
|---|---|---|---|---|
| app | security | 3 | 2 | +1 ↑ |
| app | maintainability | 2 | 2 | ±0 |
| test | test-coverage | 3 | 4 | -1 ↓ |
| ... | ... | ... | ... | ... |

## 指標推移
| 指標 | 今回 | 前回 | 変化 |
|---|---|---|---|
| TODO/FIXME 総数 | 234 | 312 | -78 ✅ |
| カバレッジ% | 62 | 68 | -6 ⚠️ |
```

**ファイルが存在しない場合**: `--baseline` 指定でファイルが見つからなければ、警告のみ出して通常実行する。エラー停止はしない（初回スキャンの可能性があるため）。

**保存先の推奨**: `docs/review-history/YYYY-MM-DD.json` のように、リポジトリ内に保存して履歴を Git 管理することを推奨する（ユーザーの判断）。

```
## 健康スコアカード

| 分類 | 観点 | スコア(1-5) | 主な根拠 |
|---|---|---|---|
| app | security | 3 | ... |
| app | maintainability | 2 | TODO多数、巨大ファイル... |
| ... | ... | ... | ... |
| **分類平均** | | | |
| app | (平均) | 2.8 | |
| test | (平均) | 3.5 | |
| ... | | | |
| **総合健康度** | | **3.1 / 5** | |
```

#### アクションロードマップ

```
## アクションロードマップ

### 短期（〜1週間、クイックウィン中心）
- [ ] アクション（分類: ..., 観点: ..., 対象: ..., 工数目安: 〜N時間）

### 中期（〜1〜3か月、スプリント計画）
- [ ] 大きめのリファクタ

### 長期（〜半年〜1年、戦略的取り組み）
- [ ] アーキテクチャ刷新

### 継続的に追う指標（観点ごとに必ず1つ以上出力する）

各観点の Phase 1 出力で、以下の「必須出力指標」のうち最低1つ以上を**具体的な数値**として出力すること。これらの数値は Phase 3 の継続指標として再利用される。

| 観点 | 必須出力指標（例） | 紐づく分類 |
|---|---|---|
| security | 検出された潜在脆弱性数、ハードコードシークレット候補数 | 横断 |
| supply-chain-attack | 悪意疑い指摘数（確信度高/中/低の内訳）、postinstall スクリプト保有依存数、typosquatting 疑い数、サプライチェーン健全性スコア(1-5) | app, build, ci, iac, meta（横断） |
| maintainability | TODO/FIXME/HACK/XXX 総数、1000行超ファイル数、最古TODOの日齢 | app, test |
| readability | 関数長 P95、深さ4以上のネストを持つ関数数、docstring 欠如比率 | app, test |
| architecture | God モジュール候補数（被参照数N以上）、レイヤー違反疑い数 | app |
| architecture-drift | 循環依存検出数、循環の長さ最大値 | app |
| ddd-strategic | 推定コンテキスト数、境界違反候補数、ACL箇所数、DDD成熟度段階(0-4)、会話的モデリング痕跡の有無 | app, meta |
| monorepo | パッケージ間循環依存数、共有パッケージの被参照数、workspace 設定不整合数 | app, build |
| hotspot | 上位20ファイルの変更頻度合計、バグ修正コミット率（fix系コミット/全コミット） | app, test |
| performance | N+1 疑い箇所数、ブロッキングI/O 混在数、メモリ全件ロード疑い数 | app, runtime, ci, iac |
| dead-code | 未参照シンボル数、未参照ファイル数（誤検知前提を併記） | 横断 |
| ownership | バス係数1のファイル数、寄与率50%超を担う人数 | app |
| duplication | 5行超の重複ブロック検出数、重複行率（概算） | app |
| test-coverage | カバレッジ%（取得できれば）、テストファイル無し公開モジュール数 | test |
| test-quality | アサーション無しテスト数、skip 状態テスト数、Flaky 言及コミット数 | test |
| test-strategy | PBT 利用箇所数、PBT 向きだが例示のみの箇所数 | test |
| test-pyramid | ユニット/統合/E2E 件数と比率、想定との乖離度 | test |
| dependencies | 直接依存総数、メジャー遅延 ≥1 の依存数、CVE Critical/High 件数 | build |
| data-integrity | トランザクション利用箇所の分散度、マイグレーション総数、UTC非統一の疑い箇所 | app, iac |
| runtime-config | `:latest` 利用箇所数、非root USER 設定の有無、HEALTHCHECK 設定の有無 | runtime |
| devenv-quality | devcontainer feature 数、postCreate冪等性チェック結果、言語バージョン整合性 | devenv |
| ci-quality | workflow 総数、SHA pin されていない third-party action 数、`permissions:` 未設定 workflow 数 | ci |
| iac-quality | リソース総数、ハードコード値検出数、tag/label 網羅率 | iac |
| observability | 構造化ログ採用比率、相関ID伝播の有無、メトリクス計装箇所数 | app, runtime, ci, iac |
| governance | 必須メタファイル充足率（README/LICENSE/SECURITY/CONTRIBUTING/CODEOWNERS のうち存在数/5） | meta |
| documentation | 公開API中docstring付き比率、README セクション充足数、ADR数 | app, test, meta |

**ルール**: 数値が取得できなかった場合は「N/A（理由）」と明示すること。ゼロ件なら「0」と書く（空欄にしない）。これにより継続スキャンで推移が追える。
```

---

## 進捗表示ルール

実行中はユーザーがハングアップを疑わないよう、**主要ステップごとに必ず1行の進捗ログを出す**こと。本コマンドは観点・分類が多く長時間化しやすいので、特に厳密に守ること。

### 進捗を出すタイミング

1. **Phase の開始時**: `🔍 Phase 0: リポジトリのメタデータ収集と分類確定を開始`
2. **Phase 0 の主要ステップ前**: `🔍 ファイル数と言語構成を集計中...` / `🔍 プロジェクト指紋を取得中...` / `🔍 ファイル分類を確定中（N ファイル）...`
3. **Phase 0 の完了時**: `✅ Phase 0 完了（N ファイル、M 分類、K 観点を実行予定）`
4. **段階1（概況スキャン）の開始時**: `🔍 段階1: 分類別の概況スキャンを開始（K 分類）`
5. **段階1の各分類処理時**: `🔍 [分類名] の概況スキャン中...` → `✅ [分類名] 完了`
6. **段階1の完了時**: `✅ 段階1 完了（深掘り対象の指示を待機中）`
7. **Phase 1（深掘り / --full モード）の開始時**: `🔍 Phase 1: 分類ごとのスキャンを開始`
8. **Phase 1 の各分類の開始時**: `🔍 [分類名] の評価を開始（N 観点）`
9. **Phase 1 の各観点の開始時**: `🔍 [分類/観点] を評価中...`
10. **Phase 1 の各観点の完了時**: `✅ [分類/観点] 完了（主要発見 N 件）`
11. **Phase 1 の各分類の完了時**: `✅ [分類名] 完了`
12. **Phase 1.5 の開始時**: `🔍 Phase 1.5: セルフレビューパスを開始`
13. **Phase 2 / Phase 3 の開始時**: `🔍 Phase 2: 優先順位付けを開始` / `🔍 Phase 3: 健康スコアカード & ロードマップを作成中...`
14. **時間がかかるツール実行前**（`git log` で大量履歴取得、`rg` でリポジトリ全体スキャン、`cloc` 実行等）: `🔍 <何をしているか> 実行中...`

### 進捗ログの書式

- **必ず 1 行**で、絵文字（🔍 進行中 / ✅ 完了 / ⚠️ 警告 / ❌ エラー）+ 動詞を含む短文
- 進捗ログは**通常の出力と区別できる行**にする（前後に空行を入れるか、コードブロック外に書く）
- 数値が把握できているなら入れる（「N 件」「M ファイル」「X 観点中の Y 個目」など）
- 進捗ログ自体に分析結果を入れない

### 進捗ログが冗長になる場合

`--full` で全分類×全観点を回すと進捗ログが多くなる。**少なくとも「各分類の開始と完了」「各観点の開始と完了」は必ず出す**こと。観点内の細かいステップは省略してもよいが、明らかに時間のかかるツール実行（`rg` でリポジトリ全体走査等）の前には必ず1行入れる。

---

## 動作上の注意

- **推測で進めない**: スコープが大きすぎる、メタデータが取得できない、ツールが見つからない、分類が曖昧、等の状況では必ずユーザーに方針を確認してから進めること。
- **全件指摘は無価値**: 「上位N件 + 分布の特徴」が有用。全件列挙は避ける。
- **誤検知の存在を明示**: dead-code、duplication、ownership は誤検知が出やすい。指摘するときに誤検知要因（動的呼び出し、リフレクション、リポジトリ移管、shallow clone等）を明示せよ。
- **分類・観点ごとに視点をリセット**: あるパスの結論を次のパスに持ち込まない。
- **数字は根拠とともに**: 「巨大ファイル」だけでなく「行数 1234」のように具体値を添える。
- **既存パターンを尊重**: プロジェクト固有の事情（モノレポ構造、世代の異なるレイヤー、レガシー保守領域）には踏み込みすぎない。
- **不確実なら不確実と書く**: 「目視推定」「サンプリング」「ツール未使用」「shallow clone のため履歴情報が限定的」などを明示する。
- **ユーザー設定との整合**: 本プロジェクトは Docker compose + devcontainer 前提、PBT 採用、関心の分離を重視する。これらに反する指摘は控える。
- **review-branch との違い**: 本コマンドは「リポジトリ全体の棚卸し + 優先順位 + ロードマップ」を出す。差分レビュー（PR時の Critical/High 個別指摘）が必要なら `/review-branch` を使う。
- **段階的実行がデフォルト**: 1回ですべてを出さない。Phase 0 + 概況スキャンで一度止まり、ユーザーの指示で深掘り。`--full` 指定時のみ一気通貫。**ユーザーが具体的な深掘り対象を指示する前に勝手に深掘りしないこと**。
- **段階1 と 段階2 の切り替え**: 段階1の最後で必ずユーザー指示を待つ。「次は app と test を深掘りして」のような指示を受けたら、対応する分類×観点だけを実行する。指示が曖昧なら確認する。

---

## 起動

以上の手順に従い、**Phase 0 から開始**せよ。**最初に進捗ログ「🔍 Phase 0: リポジトリのメタデータ収集と分類確定を開始」を出してから**、最初の応答は「引数解釈の結果（実行モードを含む）」「リポジトリ規模感の要約」「プロジェクト指紋」「ファイル分類サマリ」「サンプリング戦略」「これから実行する分類×観点リスト」の宣言から始めること。

**デフォルトモードの場合**: Phase 0 完了後、段階1（各分類の概況サマリ + 簡略スコアカード）を出力し、**深掘り対象の指示をユーザーに求めて停止する**。指示を待たずに Phase 1 の詳細に入らないこと。

**`--full` モードの場合**: Phase 0 → Phase 1 → Phase 1.5 → Phase 2 → Phase 3 を一気通貫で実行する。途中停止しない。

---

## 仕様書の保守ガイド（コマンドを編集するときの整合性チェックリスト）

観点や分類を追加・削除・変更するときは、以下の3箇所をすべて更新すること。**1箇所でも漏れると評価が不整合になる**。

1. **「分類 × 観点のマトリクス」表**: 観点行を追加/削除/✅⚠️空欄を変更
2. **該当する各分類の Phase 1 セクション**: 観点の実装（人格 + チェック項目）を追加/削除
3. **Phase 3 の「継続的に追う指標」表**: 観点に紐づく数値指標があれば追加/削除

整合性確認:
- マトリクスで ✅ または ⚠️ のセルは、該当分類のセクションに実装が**必ず存在する**こと
- 分類セクションに実装がある観点は、マトリクスで ✅ または ⚠️ が**必ず付いている**こと
- マトリクスで ✅（主要）と書いた観点は、実装セクションの見出しに「補助的」と書かない
- マトリクスで ⚠️（補助）と書いた観点は、実装セクションの見出しに「補助的」を含める（読者の期待値を整える）
