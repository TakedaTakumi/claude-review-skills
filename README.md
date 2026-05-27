# claude-review-skills

Claude Code 向けの多観点コードレビューツール群。3つのスラッシュコマンドを
**Skill（観点ライブラリ）+ Sub Agent（専門ワーカー）+ 軽量 Slash Command（オーケストレータ）**
の組み合わせで構成する。

> ⚠️ **移行作業中**: 現在 `review-branch` / `review-repo` / `review-slice` を Skill ベースへ再構築中です。
> 詳細は [issue #1](https://github.com/TakedaTakumi/claude-review-skills/issues/1) と
> [MIGRATION_PLAN.md](MIGRATION_PLAN.md) を参照。旧仕様（真実の源）は [`docs/legacy/`](docs/legacy/) にあります。

## 3つのコマンド

| コマンド | 用途 |
|---|---|
| `/review-branch` | ブランチの変更（差分）を多観点で評価 |
| `/review-repo` | リポジトリ全体を「ファイル分類 × 観点」で健康診断 |
| `/review-slice` | 起点ファイルから依存を辿って機能スライスを構築し評価 |

## 構成

```
skills/code-review-perspectives/   # 観点ライブラリ（SKILL.md + perspectives/ + categories/ + templates/）
agents/                            # 観点グループ別の Sub Agent
commands/                          # 各スラッシュコマンド（薄いオーケストレータ）
docs/                              # ドキュメント（legacy/ に旧仕様を保管）
install.sh                         # ~/.claude/ への配置スクリプト
```

## インストール

```bash
./install.sh                  # ~/.claude/ に symlink 配置（symlink 不可環境では自動でコピー）
./install.sh --copy           # コピーで配置
CLAUDE_DIR=/path ./install.sh  # 配置先を上書き
```

> 実行には bash が必要です。`sh install.sh` ではなく、`./install.sh`（要実行権限）
> または `bash install.sh` で実行してください（`/bin/sh` が dash の環境では `sh install.sh` は失敗します）。

## ドキュメント

- [MIGRATION_PLAN.md](MIGRATION_PLAN.md) — 移行計画の全体像（観点・分類・テンプレートの定義を含む）
- `docs/`（ARCHITECTURE / PERSPECTIVES / CATEGORIES / USAGE）— Phase 8 で整備予定
