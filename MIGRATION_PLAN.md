# Code Review Skills 移行計画書

> ⚠️ **本書は移行作業開始時点（2026-05）の計画書で、観点数は 21観点ベースの当時値です。**
> 移行完了後（Phase 8 まで）に観点を拡張し、現在のリポジトリは **32観点 × 8分類** で運用されています。
> **観点・分類の最新カタログは [skills/code-review-perspectives/SKILL.md](skills/code-review-perspectives/SKILL.md) および [docs/PERSPECTIVES.md](docs/PERSPECTIVES.md) を参照してください。**
> 本書は移行の経緯・設計判断の記録として保持されており、現運用の真実の源ではありません。

このドキュメントは、3つのスラッシュコマンド（review-branch / review-repo / review-slice）を Claude Code の **Skill + Sub Agent + 軽量 Slash Command** の組み合わせに再構築するための完全な計画書です。Claude Code がこの計画書を読んでゼロから実装することを想定しています。

---

## 0. はじめに（Claude Code 向け）

### このドキュメントの読み方

- **§1〜§3 は設計思想と全体構造**。実装に入る前に必ず読み込んでください。
- **§4〜§7 は各成果物（Skill、Sub Agent、Slash Command、共通リソース）の詳細仕様**。実装の参照リファレンスです。
- **§8 は21観点と8分類の完全な定義**。これがコンテンツの本体です。
- **§9 は実装の進め方と検収条件**。これに沿って作業を進めてください。
- **§10 は既存リソース**。必要に応じて参照してください。

### 進め方の推奨

1. §1〜§3 を読んで全体像を把握
2. §4〜§7 の規約を確認
3. §9 のフェーズに沿って順に実装（フェーズごとに動作確認）
4. 詰まったらユーザーに質問する。**推測で進めないこと**

### 重要な原則

- **関心の分離**: Skill = 観点ライブラリ、Sub Agent = 専門ワーカー、Slash Command = 薄いオーケストレータ
- **段階的開示**: コンテキストに毎回全部ロードしない。必要な観点だけ読み込む構造にする
- **複数案の提示**: 設計判断で迷ったら、ユーザーに案を複数提示してから進める
- **ユーザー設定との整合**: Docker compose + devcontainer 前提、PBT 採用、関心の分離・分割統治

---

## 1. 背景と目的

### 1.1 これまでの経緯

3つのスラッシュコマンドが累積的に成長し、合計約 2700 行・21 観点 + 7〜8 分類を扱う規模になった。観点の追加・修正で 3 ファイル同時編集が必要、トークン消費が大きい、出力が長大、という問題が発生。

### 1.2 移行の目的

| 項目 | 現状 | 移行後 |
|---|---|---|
| 観点定義の重複 | 3ファイルに記述 | 1観点 = 1ファイル、3コマンドが参照 |
| コンテキスト消費 | 毎回数千行ロード | 段階的開示で必要な分のみ |
| 観点追加コスト | 3箇所同時編集 | 1ファイル追加のみ |
| 並列実行 | 直列のみ | 観点グループごとに Sub Agent 並列 |
| 出力 | 1つの長大な出力 | エージェント別に整理 |
| 保守性 | 不整合が再発しやすい | 単一情報源で整合性を保ちやすい |

### 1.3 移行で**変えない**こと

- 21観点 + 8分類の内容そのもの（これまでの議論で固めた本体）
- 3コマンドのユーザー向けインタフェース（`/review-branch`, `/review-repo`, `/review-slice` で呼び出せる）
- 引数仕様（`--scope=`, `--top=`, `--full`, `--baseline=`, `--save=`, `--depth=`, `--direction=` 等）
- ユーザー設定との整合方針
- 進捗表示ルール（🔍 / ✅ / ⚠️ / ❌ の絵文字 + 1行進捗）

---

## 2. 全体アーキテクチャ

### 2.1 4つの構成要素

```
┌─────────────────────────────────────────────────┐
│  Slash Command（薄いオーケストレータ）              │
│  /review-branch  /review-repo  /review-slice    │
│  - 引数パース                                       │
│  - Sub Agent への委任                              │
│  - 結果の集約                                       │
└─────────────────┬───────────────────────────────┘
                  │ 委任
                  ▼
┌─────────────────────────────────────────────────┐
│  Sub Agent（観点グループ別の専門ワーカー）           │
│  security-reviewer / ddd-reviewer /             │
│  architecture-reviewer / quality-reviewer / ... │
│  - 独立コンテキストで実行                            │
│  - 並列実行可能                                     │
│  - 担当する観点群を Skill から読み込んで評価         │
└─────────────────┬───────────────────────────────┘
                  │ 参照
                  ▼
┌─────────────────────────────────────────────────┐
│  Skill（観点ライブラリ）                            │
│  code-review-perspectives/                       │
│  - SKILL.md（カタログ・メタ情報）                   │
│  - perspectives/*.md（21観点の独立ファイル）        │
│  - categories/*.md（8分類の独立ファイル）           │
│  - templates/*.md（出力・重大度・レポートテンプレ）  │
└─────────────────────────────────────────────────┘
```

### 2.2 ディレクトリ構造

```
~/.claude/
├── skills/
│   └── code-review-perspectives/
│       ├── SKILL.md                    # 観点カタログ + メタ情報
│       ├── perspectives/
│       │   ├── security.md
│       │   ├── supply-chain-attack.md
│       │   ├── maintainability.md
│       │   ├── readability.md
│       │   ├── architecture.md
│       │   ├── architecture-drift.md
│       │   ├── ddd-tactical.md
│       │   ├── ddd-strategic.md
│       │   ├── monorepo.md
│       │   ├── hotspot.md
│       │   ├── performance.md
│       │   ├── dead-code.md
│       │   ├── ownership.md
│       │   ├── duplication.md
│       │   ├── test-coverage.md
│       │   ├── test-quality.md
│       │   ├── test-strategy.md
│       │   ├── test-pyramid.md
│       │   ├── dependencies.md
│       │   ├── data-integrity.md
│       │   ├── error-handling.md
│       │   ├── code-provenance.md
│       │   ├── compatibility.md
│       │   ├── runtime-config.md
│       │   ├── devenv-quality.md
│       │   ├── ci-quality.md
│       │   ├── iac-quality.md
│       │   ├── observability.md
│       │   ├── governance.md
│       │   ├── documentation.md
│       │   ├── i18n-a11y.md
│       │   └── slice-cohesion.md         # review-slice 専用
│       ├── categories/
│       │   ├── app.md
│       │   ├── test.md
│       │   ├── build.md
│       │   ├── runtime.md
│       │   ├── devenv.md
│       │   ├── ci.md
│       │   ├── iac.md
│       │   └── meta.md
│       └── templates/
│           ├── severity-criteria.md      # 重大度の操作的定義
│           ├── escalation-report.md      # supply-chain-attack 等のエスカレーション用
│           ├── output-format.md          # 観点別出力フォーマット
│           ├── progress-log.md           # 進捗表示ルール
│           └── slice-flow-template.md    # スライスの情報フロー記述
├── agents/
│   ├── security-reviewer.md             # security + supply-chain-attack
│   ├── ddd-reviewer.md                  # ddd-tactical + ddd-strategic
│   ├── architecture-reviewer.md         # architecture + architecture-drift + monorepo
│   ├── quality-reviewer.md              # maintainability + readability + duplication + dead-code
│   ├── test-reviewer.md                 # test-coverage + test-quality + test-strategy + test-pyramid
│   ├── performance-reviewer.md          # performance + hotspot + data-integrity
│   ├── ops-reviewer.md                  # runtime-config + devenv-quality + ci-quality + iac-quality + observability
│   ├── dependencies-reviewer.md         # dependencies（supply-chain-attack の build 部分と連携）
│   ├── meta-reviewer.md                 # governance + documentation + i18n-a11y
│   ├── slice-flow-reviewer.md           # review-slice の情報フロー専門
│   └── ownership-reviewer.md            # ownership + code-provenance
└── commands/
    ├── review-branch.md                 # 100行以下
    ├── review-repo.md                   # 100行以下
    └── review-slice.md                  # 100行以下
```

### 2.3 GitHub リポジトリ構造（推奨）

`~/.claude/` に直接置く前に、Git リポジトリで管理する:

```
claude-review-skills/
├── README.md                            # プロジェクト全体の説明
├── MIGRATION_PLAN.md                    # このドキュメント
├── LICENSE
├── .gitignore
├── docs/
│   ├── ARCHITECTURE.md                  # アーキテクチャ詳細
│   ├── PERSPECTIVES.md                  # 21観点のカタログ
│   ├── CATEGORIES.md                    # 8分類のカタログ
│   └── USAGE.md                         # 使い方ガイド
├── install.sh                           # ~/.claude/ への配置スクリプト
├── skills/                              # Skill 群（~/.claude/skills/ にコピーされる）
│   └── code-review-perspectives/
│       └── ...
├── agents/                              # Sub Agent 群（~/.claude/agents/ にコピーされる）
│   └── ...
└── commands/                            # Slash Command 群（~/.claude/commands/ にコピーされる）
    └── ...
```

`install.sh` は単純なコピーまたは symlink を作るスクリプト。

---

## 3. 設計判断の根拠（変更しないこと）

### 3.1 なぜ Skill か

- 21観点 × 8分類 = 重複しがちな構造を**単一情報源**にまとめる
- 段階的開示（Progressive Disclosure）でコンテキスト効率が良い
- Claude Code 以外（Claude.ai, Desktop）でも将来再利用できる可能性
- 複数の関連ファイル（perspective / category / template）をバンドルできる

### 3.2 なぜ Sub Agent か

- 観点を関連グループに分けて**独立コンテキスト**で評価できる
- 並列実行で速くなる
- メインコンテキストを汚さない（Sub Agent の探索ノイズが入らない）
- 観点グループ別の出力でレポートが整理される

### 3.3 なぜ Slash Command を残すか

- ユーザーは依然として `/review-branch` のような**明示的呼び出し**を期待
- Skill だけだと auto-invocation の不確実性がある
- 軽量化された Slash Command はオーケストレータとして最小限の役割を持つ

### 3.4 Sub Agent のグループ分けの方針

11個のエージェントに分けた根拠:

| Agent | 担当観点 | 根拠 |
|---|---|---|
| security-reviewer | security, supply-chain-attack | セキュリティ系を一括 |
| ddd-reviewer | ddd-tactical, ddd-strategic | DDD系を一括 |
| architecture-reviewer | architecture, architecture-drift, monorepo | 構造系を一括 |
| quality-reviewer | maintainability, readability, duplication, dead-code | コード品質系 |
| test-reviewer | test-coverage, test-quality, test-strategy, test-pyramid | テスト系 |
| performance-reviewer | performance, hotspot, data-integrity | 性能・データ系 |
| ops-reviewer | runtime-config, devenv-quality, ci-quality, iac-quality, observability | 運用系 |
| dependencies-reviewer | dependencies | 依存系単独（supply-chain との連携が重要） |
| meta-reviewer | governance, documentation, i18n-a11y | メタ系 |
| slice-flow-reviewer | slice-cohesion + 情報フロー追跡 | review-slice 専用 |
| ownership-reviewer | ownership, code-provenance | 履歴・由来系 |

---

## 4. Skill の仕様

### 4.1 SKILL.md の構造

`~/.claude/skills/code-review-perspectives/SKILL.md`:

```markdown
---
name: code-review-perspectives
description: 21観点・8分類のコードレビュー観点カタログ。/review-branch, /review-repo, /review-slice から参照される。観点ごとに人格・チェック項目・出力テンプレート・重大度判断基準を持つ。
---

# Code Review Perspectives

このスキルは、コードレビューで用いる21観点・8分類・各種テンプレートをまとめた観点ライブラリです。3つのスラッシュコマンド（review-branch / review-repo / review-slice）および 11 個の Sub Agent から参照されます。

## 観点カタログ

[21観点を表形式で列挙、各観点へのリンク]

| キー | 観点名 | 詳細ファイル |
|---|---|---|
| security | 攻撃者目線 | perspectives/security.md |
| supply-chain-attack | バックドア検出 | perspectives/supply-chain-attack.md |
| ... | ... | ... |

## 分類カタログ（review-repo 用）

| キー | 分類名 | 詳細ファイル |
|---|---|---|
| app | ソフトウェア本体 | categories/app.md |
| ... | ... | ... |

## 分類 × 観点マトリクス（review-repo 用）

[現状 review-repo にあるマトリクスをそのまま掲載]

## 重大度判断基準

詳細: templates/severity-criteria.md

## エスカレーションレポートテンプレート

詳細: templates/escalation-report.md

## 進捗表示ルール

詳細: templates/progress-log.md
```

### 4.2 観点ファイル（perspectives/*.md）の書式

各観点ファイルは独立した1観点を扱う。

```markdown
---
key: security
display_name: 攻撃者目線（セキュリティ）
applicable_commands: [review-branch, review-repo, review-slice]
applicable_categories_for_repo: [app, test, build, runtime, devenv, ci, iac, meta]
primary_in_categories: [app, build, runtime, ci, iac, meta]
auxiliary_in_categories: [test, devenv]
related_perspectives: [supply-chain-attack, data-integrity]
---

# security: 攻撃者目線（セキュリティ）

## 役割（人格）

あなたは**外部の攻撃者**である。...

## チェック項目

- 入力検証の欠如
- 認証・認可の抜け道
- ...

## 文脈別の読み替え

### review-branch での読み方

差分で**新しく追加された脆弱性**を捉える。...

### review-repo での読み方

リポジトリ全体の脆弱性パターンを棚卸し。...

### review-slice での読み方

スライス入口から出口までの攻撃経路を追跡。...

## 必須出力指標

- 検出された潜在脆弱性数
- ハードコードシークレット候補数

## 重大度の判断例

### Critical の例
- 認証バイパス
- リモートコード実行
- 機密データの平文露出

### High の例
- CSRF トークン欠如
- ハッシュ化されていないパスワード保存

## 関連観点

- supply-chain-attack（意図的混入は別観点で扱う）
- data-integrity（トランザクション境界）
```

### 4.3 分類ファイル（categories/*.md）の書式

```markdown
---
key: app
display_name: ソフトウェア本体
typical_paths:
  - src/
  - lib/
  - packages/*/src/
  - app/
applicable_perspectives:
  primary: [security, maintainability, readability, architecture, ...]
  auxiliary: [documentation]
---

# app: ソフトウェア本体

## 本質

ビジネスロジック・ドメインコードの正しさ、保守性、設計の健全性、長期的な変更容易性。

## 適用観点

- security (✅)
- maintainability (✅)
- readability (✅)
- ...

## 境界事例の判断ルール

- マイグレーションスクリプト → app（ロジックを含むため）
- ...
```

### 4.4 テンプレートファイル（templates/*.md）

| ファイル | 内容 |
|---|---|
| severity-criteria.md | 重大度（Critical/High/Medium/Low）の操作的定義、観点別 Critical/High 例の表 |
| escalation-report.md | supply-chain-attack 等のエスカレーション用レポートフォーマット |
| output-format.md | Phase 1 共通の観点別出力フォーマット |
| progress-log.md | 進捗表示の絵文字ルール（🔍 / ✅ / ⚠️ / ❌）と書式 |
| slice-flow-template.md | review-slice での「入口→出口」の情報フロー記述テンプレート |

---

## 5. Sub Agent の仕様

### 5.1 Sub Agent ファイルの書式

`~/.claude/agents/security-reviewer.md`:

```markdown
---
name: security-reviewer
description: セキュリティ観点（security + supply-chain-attack）の専門レビュアー。攻撃者目線での脆弱性検出と、バックドア・悪意あるコード混入の検出を担当する。
tools: [Bash(git:*), Bash(gh:*), Bash(rg:*), Read, Grep, Glob]
---

# Security Reviewer

あなたは security と supply-chain-attack の専門レビュアーです。code-review-perspectives スキルから以下の観点ファイルを読み込み、評価を実行します:

- perspectives/security.md
- perspectives/supply-chain-attack.md

## 入力

メインの Claude から以下が委任される:
- 評価モード: `branch` / `repo` / `slice`
- 評価対象: 差分情報 / スコープパス / スライスファイル群
- 適用文脈: 該当する分類 or 観点指定

## 出力

各観点について、observed テンプレート（templates/output-format.md）に従ったレポートを出力する。

## 注意

- 観点ごとに人格を切り替える
- 進捗ログを出す（templates/progress-log.md のルール）
- 過剰判定を避ける（特に supply-chain-attack の誤検知）
- 結果は構造化したまま返し、メインの Claude が集約する
```

### 5.2 Sub Agent の共通ガイドライン

- **担当観点を明示**: description に観点キーを書く（auto-routing 精度向上のため）
- **tools を最小化**: Bash の権限を絞る
- **コンテキストはメインから受け取る情報のみ**: グローバル状態に依存しない
- **結果は構造化**: メインが集約しやすいよう、観点別に整理された Markdown を返す
- **観点間の協調**: 必要なら他観点の結果を参照したい旨を返す（メインで調整）

---

## 6. Slash Command の仕様（軽量化）

### 6.1 ファイル長の目安

各コマンド 100 行以下を目標。

### 6.2 review-branch.md の構造例

```markdown
---
description: ブランチの変更を多観点（21観点）で評価する
argument-hint: [perspectives] [--base=<branch>]
allowed-tools: Bash(git:*), Bash(gh:*), Bash(rg:*), Read, Grep, Glob
---

# Branch Review (Orchestrator)

このコマンドは観点ライブラリ Skill と複数の Sub Agent を組み合わせてブランチレビューを実行します。

## 進捗表示

🔍 / ✅ / ⚠️ / ❌ の絵文字 + 1 行で進捗を出力する。詳細は code-review-perspectives Skill の templates/progress-log.md。

## 引数仕様

[現状の review-branch の引数仕様を簡潔に]

## 実行手順

### Phase 0: 準備

1. リポジトリ確認、ベースブランチ決定、差分取得（現状の review-branch Phase 0 と同じ）
2. code-review-perspectives Skill をロードし、適用観点を決定する

### Phase 1: Sub Agent への委任

決定した観点を以下のグループに分け、対応する Sub Agent に並列委任する:

- security 系 → security-reviewer
- DDD 系 → ddd-reviewer
- アーキテクチャ系 → architecture-reviewer
- 品質系 → quality-reviewer
- テスト系 → test-reviewer
- ...

### Phase 2: 結果集約とセルフレビュー

各 Sub Agent の結果を集約し、観点間の重複・矛盾を解消する。

### Phase 3: サマリー出力

総評、必須対応、推奨対応、評価サマリ表を出力。

## 動作上の注意

- 推測で進めない
- ユーザーに確認すべきケースは Sub Agent に委任せず、メインで確認する
- review-repo / review-slice との棲み分けを尊重する
```

### 6.3 review-repo と review-slice も同様の構造

それぞれの特性（review-repo は段階的実行、review-slice は依存追跡）は維持する。

---

## 7. 共通リソース

### 7.1 README.md

- プロジェクトの目的
- 3つのコマンドの使い分け
- インストール方法（`install.sh`）
- 観点と分類の一覧（docs/PERSPECTIVES.md, CATEGORIES.md へのリンク）
- カスタマイズ方法

### 7.2 install.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# symlink で配置（更新が即反映される）
mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands"

ln -sfn "$SCRIPT_DIR/skills/code-review-perspectives" "$CLAUDE_DIR/skills/code-review-perspectives"

for f in "$SCRIPT_DIR/agents"/*.md; do
  ln -sf "$f" "$CLAUDE_DIR/agents/$(basename "$f")"
done

for f in "$SCRIPT_DIR/commands"/*.md; do
  ln -sf "$f" "$CLAUDE_DIR/commands/$(basename "$f")"
done

echo "Installed to $CLAUDE_DIR"
```

### 7.3 .gitignore

```
.DS_Store
*.swp
node_modules/
```

---

## 8. 21観点 + 8分類の完全な定義

ここに記述する内容は、これまでの議論で固めた本体です。Claude Code は各観点・分類のファイルを生成する際、ここを「真実の源（source of truth）」として参照してください。

### 8.1 21観点リスト

| キー | 観点名 | 適用コマンド | 主担当 Agent |
|---|---|---|---|
| security | 攻撃者目線 | 全コマンド | security-reviewer |
| supply-chain-attack | バックドア検出 | 全コマンド | security-reviewer |
| maintainability | 保守性 | 全コマンド | quality-reviewer |
| readability | 可読性 | 全コマンド | quality-reviewer |
| architecture | アーキテクチャ | 全コマンド | architecture-reviewer |
| architecture-drift | 構造ドリフト | review-repo, review-slice | architecture-reviewer |
| ddd-tactical | DDD戦術的設計 | 全コマンド | ddd-reviewer |
| ddd-strategic | DDD戦略的設計 | review-repo, review-slice | ddd-reviewer |
| monorepo | モノレポ健全性 | review-repo | architecture-reviewer |
| hotspot | リスク領域特定 | review-repo, review-slice | performance-reviewer |
| performance | パフォーマンス | 全コマンド | performance-reviewer |
| dead-code | 未参照コード | review-repo, review-slice | quality-reviewer |
| ownership | バス係数・所有 | review-repo | ownership-reviewer |
| duplication | コード重複 | review-repo, review-slice | quality-reviewer |
| test-coverage | テスト網羅性 | 全コマンド | test-reviewer |
| test-quality | テスト品質 | 全コマンド | test-reviewer |
| test-strategy | PBT 戦略 | 全コマンド | test-reviewer |
| test-pyramid | テストピラミッド | review-repo | test-reviewer |
| dependencies | 依存関係 | 全コマンド | dependencies-reviewer |
| data-integrity | データ整合性 | 全コマンド | performance-reviewer |
| error-handling | エラー処理 | review-branch, review-slice | quality-reviewer |
| code-provenance | AI生成コード由来 | review-branch | ownership-reviewer |
| compatibility | 後方互換性 | review-branch | quality-reviewer |
| runtime-config | ランタイム設定 | review-repo | ops-reviewer |
| devenv-quality | 開発環境品質 | review-repo | ops-reviewer |
| ci-quality | CI 品質 | review-repo | ops-reviewer |
| iac-quality | IaC 品質 | review-repo | ops-reviewer |
| observability | 可観測性 | review-repo, review-slice | ops-reviewer |
| governance | 運営健全性 | review-repo | meta-reviewer |
| documentation | ドキュメント | 全コマンド | meta-reviewer |
| i18n-a11y | 国際化・a11y | review-branch, review-repo | meta-reviewer |
| slice-cohesion | スライス凝集 | review-slice | slice-flow-reviewer |

※ 33個になっているのは正常です。「21観点」と数えてきたのは中核観点で、スライス専用やコマンド固有を含めた総数です。実態に合わせて表現を「30以上の観点」と修正可。

### 8.2 8分類リスト（review-repo 用）

| キー | 分類名 | 典型パス |
|---|---|---|
| app | ソフトウェア本体 | src/, lib/, packages/*/src/ |
| test | テストコード | tests/, *.test.* |
| build | ビルド・パッケージ定義 | package.json, pyproject.toml, Cargo.toml |
| runtime | 環境構築 | Dockerfile*, compose.yml |
| devenv | 開発環境 | .devcontainer/, .vscode/, .idea/ |
| ci | CI パイプライン | .github/workflows/, .gitlab-ci.yml |
| iac | デプロイ・IaC | terraform/, k8s/, ansible/ |
| meta | リポジトリメタ | README, LICENSE, .gitignore |

### 8.3 各観点・分類の詳細な内容

**重要**: 各観点・分類の詳細な内容（人格、チェック項目、文脈別読み替え、必須出力指標、重大度例、関連観点）は、現状の3つのスラッシュコマンドファイル（`review-branch.md`, `review-repo.md`, `review-slice.md`）に既に記述されている。

§10 に列挙する既存ファイルから、観点別・分類別に内容を抽出して移行すること。**新規に書き起こすのではなく、既存記述を観点ファイルに分解・再配置する作業**であることに注意。

### 8.4 分類 × 観点マトリクス

review-repo の現状ファイルにある「分類 × 観点のマトリクス」表をそのまま移行する。場所は SKILL.md または docs/CATEGORIES.md。

### 8.5 重大度判断基準

review-branch および review-repo の現状ファイルにある:

- 重大度の判断基準（Critical/High/Medium/Low の操作的定義）
- インパクト × コストマトリクス（review-repo）
- 観点別 Critical/High 例の表

これらを `templates/severity-criteria.md` に集約する。

### 8.6 進捗表示ルール

3コマンドの現状ファイルにある「進捗表示ルール」セクションを `templates/progress-log.md` に集約する。コマンド固有の進捗ポイント（review-branch なら差分取得、review-repo ならプロジェクト指紋、等）はそれぞれの Slash Command ファイルから参照する。

### 8.7 エスカレーションレポート

supply-chain-attack のレポートテンプレートを `templates/escalation-report.md` に。

---

## 9. 実装の進め方と検収条件

### 9.1 推奨フェーズ

#### Phase 1: スケルトン作成（30分目安）

- [ ] GitHub リポジトリ初期化（README, LICENSE, .gitignore）
- [ ] ディレクトリ構造作成（skills/, agents/, commands/, docs/）
- [ ] install.sh の実装
- [ ] SKILL.md の骨格作成（観点・分類カタログ、相互リンク）

#### Phase 2: テンプレート作成（30分目安）

- [ ] templates/severity-criteria.md
- [ ] templates/escalation-report.md
- [ ] templates/output-format.md
- [ ] templates/progress-log.md
- [ ] templates/slice-flow-template.md

#### Phase 3: 観点ファイル作成（2〜3時間目安、並列可）

- [ ] 21観点（+ slice-cohesion）を独立した md ファイルとして生成
- [ ] 既存の review-branch / review-repo / review-slice から該当部分を抽出して再構成
- [ ] 各ファイルの frontmatter（key, display_name, applicable_commands 等）を正しく設定
- [ ] 「文脈別の読み替え」セクションで3コマンド用の解釈を残す

#### Phase 4: 分類ファイル作成（30分目安）

- [ ] 8分類のファイルを生成
- [ ] 適用観点リスト・境界事例ルールを記述

#### Phase 5: Sub Agent 作成（1時間目安）

- [ ] 11個のエージェントファイルを生成
- [ ] 各エージェントが担当観点を Skill から読み込む構造にする
- [ ] tools 権限を適切に設定

#### Phase 6: Slash Command 軽量化（30分目安）

- [ ] review-branch.md を 100行以下に
- [ ] review-repo.md を 100行以下に
- [ ] review-slice.md を 100行以下に
- [ ] それぞれ Sub Agent への委任ロジックを実装

#### Phase 7: 動作確認（1〜2時間目安）

- [ ] 小さなテストブランチで `/review-branch` 実行 → 期待通り動くか
- [ ] 小さなリポジトリで `/review-repo` 実行 → 段階1停止と段階2深掘りが動くか
- [ ] 1ファイル起点で `/review-slice` 実行 → 依存追跡が動くか
- [ ] 各コマンドで進捗ログが出るか
- [ ] Sub Agent の並列実行が機能しているか

#### Phase 8: ドキュメント整備（30分目安）

- [ ] README.md の完成
- [ ] docs/USAGE.md（使い方ガイド）
- [ ] docs/PERSPECTIVES.md（観点カタログ）
- [ ] docs/CATEGORIES.md（分類カタログ）

### 9.2 検収条件

以下がすべて満たされたら完成と判断する:

1. **機能等価性**: 現状の3コマンドと同等の評価が行える
2. **構造性**: 観点が1観点=1ファイルに分解され、3コマンドから参照される構造になっている
3. **コンテキスト効率**: メインのコンテキストには SKILL.md と必要な観点のみがロードされる
4. **並列性**: 観点グループが Sub Agent で並列実行される
5. **進捗表示**: ユーザーにハングアップを疑わせない頻度で進捗ログが出る
6. **保守性**: 観点追加が1ファイル追加で完結する
7. **整合性**: マトリクスと実装に不整合がない（保守ガイドのチェックリスト準拠）
8. **配置容易性**: `install.sh` で `~/.claude/` 配下に1コマンドで配置できる

### 9.3 トラブルシューティング指針

- **Sub Agent が呼ばれない**: description の文言が抽象的すぎる可能性。担当観点キーを明示する
- **Skill が auto-invoke されない**: SKILL.md の description にユースケースを明確に書く
- **コンテキスト溢れ**: 観点ファイルが大きすぎる可能性。さらに分解
- **観点間の重複指摘**: メインの Slash Command で集約時に統合ルールを適用

---

## 10. 既存リソース

このセッションで作成した3つのスラッシュコマンドファイルを、Claude Code に渡してください。これらは観点・分類・テンプレートの **真実の源** として参照される最も重要な入力です:

1. **review-branch.md**（約 720 行）
   - 21観点のうち、ブランチ差分レビュー文脈での記述を含む
   - 重大度判断基準テーブル
   - 進捗表示ルール

2. **review-repo.md**（約 1500 行）
   - 8分類 × 21観点のマトリクス
   - 各分類セクションでの観点記述
   - プロジェクト指紋・DDD採用判定・公開度判定のロジック
   - 健康スコアカード仕様
   - Phase 1.5 セルフレビューの 16 項目

3. **review-slice.md**（約 450 行）
   - スライス構築のロジック
   - slice-cohesion 観点
   - 観点別のスライス文脈での読み替え

これらのファイルは、リポジトリ作成時に `docs/legacy/` に保存しておくことを推奨。移行作業中の参照用、および将来の検証用。

### 10.1 既存ファイルからの内容抽出ガイド

| 抽出元 | 抽出する内容 | 配置先 |
|---|---|---|
| review-branch.md の各 ##### セクション | 観点の本文（人格・チェック項目） | perspectives/{key}.md |
| review-repo.md の各 ##### セクション | 観点の文脈別読み替え | perspectives/{key}.md の「review-repo での読み方」 |
| review-slice.md の各 ##### セクション | 観点のスライス文脈での読み替え | perspectives/{key}.md の「review-slice での読み方」 |
| review-repo.md の `#### 1.X` セクション | 分類本文 | categories/{key}.md |
| review-repo.md のマトリクス表 | 分類 × 観点マトリクス | SKILL.md |
| review-branch.md の重大度テーブル | 重大度判断基準 | templates/severity-criteria.md |
| review-branch.md / review-repo.md / review-slice.md の進捗表示ルール | 進捗書式 | templates/progress-log.md |
| supply-chain-attack のレポートテンプレート | エスカレーション書式 | templates/escalation-report.md |

---

## 11. Claude Code への初期プロンプト例

リポジトリを作成してこのファイルを `MIGRATION_PLAN.md` として配置した後、Claude Code を起動して以下を渡してください:

```
このリポジトリの MIGRATION_PLAN.md を読んで、§9 のフェーズに沿って実装を進めてください。

docs/legacy/ に配置した既存の3つのスラッシュコマンドファイル（review-branch.md, review-repo.md, review-slice.md）を真実の源として、観点と分類の内容を移行してください。

進める前に、§1〜§3 を読んで全体像を把握し、設計判断で迷ったら必ず確認してください。推測で進めないでください。

Phase 1（スケルトン作成）から始めて、各フェーズの完了時に動作確認をしてから次に進んでください。
```

### 11.1 段階的に進める場合の指示例

途中で止めて検証したいときは:

```
Phase 1 と Phase 2 だけを実装してください。Phase 3 以降は次のセッションで進めます。
```

特定の観点だけ先に作りたいときは:

```
Phase 3 の中で、まず security 観点と supply-chain-attack 観点のファイルだけ作ってください。1観点を作るごとに内容を見せてください。
```

### 11.2 Claude Code が判断に迷ったら

ユーザーへの質問例として:

- 観点ファイルの内容が現状の3コマンドで微妙に違うとき、どちらを採用するか
- 観点と分類の境界判定が曖昧なとき
- 新規に書き起こすべきか既存を流用するか

これらは必ずユーザーに確認すること。**推測で進めない**。

---

## 12. 移行後の運用ガイド

### 12.1 観点を追加するとき

1. `skills/code-review-perspectives/perspectives/<new-key>.md` を作成
2. SKILL.md の観点カタログに行を追加
3. 該当する Sub Agent の description を更新（担当観点に追加）
4. 必要なら docs/PERSPECTIVES.md を更新
5. `install.sh` の再実行は不要（symlink のため）

### 12.2 分類を追加するとき（稀）

1. `categories/<new-key>.md` を作成
2. SKILL.md のマトリクスに列を追加
3. 各観点ファイルの `applicable_categories_for_repo` を更新
4. review-repo.md（Slash Command）の引数仕様の `--categories=` 例を更新

### 12.3 Sub Agent を追加/再編するとき

1. `agents/<new-name>.md` を作成
2. 既存エージェントの担当範囲を再調整
3. 該当する Slash Command の Phase 1 委任ロジックを更新

### 12.4 バージョン管理

- 大きな変更は Git ブランチで作業
- 各観点ファイルにバージョン情報を持たせる必要はない（Git 履歴で十分）
- 健康スコアの基準を変えるときは CHANGELOG.md に記録

---

## 13. リスクと対策

| リスク | 対策 |
|---|---|
| Sub Agent が auto-route されない | description を担当観点キーで明確化、必要なら Slash Command で明示的に呼ぶ |
| Skill が auto-load されない | SKILL.md の description にユースケースを書く、Slash Command から明示参照 |
| 観点ファイル間で矛盾 | 移行作業時に統合ルールを徹底、保守ガイドのチェックリスト遵守 |
| install.sh の symlink がうまく動かない | コピー版のフォールバックを用意 |
| Claude Code が観点ファイルを読まずに自己流で進める | 強い指示を MIGRATION_PLAN.md と Claude Code 起動時プロンプトの両方で繰り返す |

---

## おわりに

このドキュメントは、これまでのセッションで蓄積した設計判断・観点定義・分類定義・テンプレートを Claude Code が再現実装するための完全な計画書です。

実装中に判断が必要な箇所が出てきたら、推測で進めず、ユーザーに確認してください。

成功条件は **「現状の3コマンドと同等の評価ができ、かつ保守性が大幅に向上していること」** です。
