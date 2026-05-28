# claude-review-skills

Claude Code 向けの多観点コードレビューツール群。3つのスラッシュコマンドを
**Skill（観点ライブラリ）+ Sub Agent（専門ワーカー）+ 軽量 Slash Command（オーケストレータ）**
の組み合わせで構成する。

- **32観点 × 8分類**のマトリクスでブランチ差分／リポジトリ全体／機能スライスを評価
- 観点は1ファイル1観点で**単一情報源**。3コマンドが共有する Skill `code-review-perspectives` から参照
- 観点グループごとに**Sub Agent が並列実行**、観点別に整理された出力

旧 spec（真実の源）は [`docs/legacy/`](docs/legacy/) を、移行の背景は [issue #1](https://github.com/TakedaTakumi/claude-review-skills/issues/1) と [MIGRATION_PLAN.md](MIGRATION_PLAN.md) を参照。

## 3つのコマンド

| コマンド | 用途 |
|---|---|
| `/review-branch` | ブランチの変更（差分）を多観点で評価 |
| `/review-repo` | リポジトリ全体を「ファイル分類 × 観点」で健康診断 |
| `/review-slice` | 起点ファイルから依存を辿って機能スライスを構築し評価 |

使い方の詳細は [docs/USAGE.md](docs/USAGE.md) を参照。

## 構成

```
skills/code-review-perspectives/   # 観点ライブラリ（SKILL.md + perspectives/ + categories/ + templates/）
agents/                            # 観点グループ別の Sub Agent（11個）
commands/                          # 各スラッシュコマンド（薄いオーケストレータ、3個）
docs/                              # ドキュメント（legacy/ に旧仕様を保管）
install.sh                         # ~/.claude/ への配置スクリプト
```

設計の全体像は [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)、観点・分類のカタログは [docs/PERSPECTIVES.md](docs/PERSPECTIVES.md) と [docs/CATEGORIES.md](docs/CATEGORIES.md) を参照。

## インストール

```bash
./install.sh                  # ~/.claude/ に symlink で配置（リポジトリ更新が即反映）
./install.sh --copy           # コピーで配置
./install.sh --force          # 本ツール由来でない同名エントリも確認なしで上書き
CLAUDE_DIR=/path ./install.sh # 配置先を上書き
```

実行には bash が必要です。`sh install.sh` ではなく、`./install.sh`（要実行権限）または `bash install.sh` で実行してください（`/bin/sh` が dash の環境では `sh install.sh` は失敗します）。

### 既定 = symlink、ただし以下では `--copy` を推奨

| ケース | 推奨 | 理由 |
|---|---|---|
| ローカル開発（観点をその場で編集して反映したい） | `./install.sh`（symlink） | リポジトリ更新が即反映 |
| **VSCode 拡張版 Claude Code** | `./install.sh --copy` | 拡張版がスラッシュコマンドを discovery する際、symlink を辿らずコマンド一覧に出ないことがある |
| `~/.claude` を別 Docker コンテナにバインドする運用 | `./install.sh --copy` | symlink のターゲットパスはコンテナ内に存在しないため壊れる |
| `~/.claude` を **`code-review-perspectives` 以外**の用途にも使っている | （安全策の症状なし時はそのまま） | install.sh は自前の名前（`code-review-perspectives` / `*-reviewer.md` / `review-{branch,repo,slice}.md`）以外には触れない。同名衝突がある場合はガードが効いて確認を求める |

`--copy` で配置した場合、観点・Agent・コマンドを編集した後は `./install.sh --copy` の再実行が必要です（symlink では不要）。

## ドキュメント

- [MIGRATION_PLAN.md](MIGRATION_PLAN.md) — 移行計画（観点・分類・テンプレートの定義を含む完全な計画書）
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — Skill + Sub Agent + Slash Command の設計
- [docs/USAGE.md](docs/USAGE.md) — 3コマンドの使い方・引数・例
- [docs/PERSPECTIVES.md](docs/PERSPECTIVES.md) — 32観点のカタログ
- [docs/CATEGORIES.md](docs/CATEGORIES.md) — 8分類のカタログ
- [docs/MIGRATION_NOTES.md](docs/MIGRATION_NOTES.md) — 移行時の構造組み替えと差異記録

## カスタマイズ

- **観点を追加**: [skills/code-review-perspectives/perspectives/](skills/code-review-perspectives/perspectives/) に1ファイル追加し、[SKILL.md](skills/code-review-perspectives/SKILL.md) のカタログに行を足す。担当 Agent の description にも追記。
- **分類を追加**（稀）: [categories/](skills/code-review-perspectives/categories/) に1ファイル追加し、SKILL.md のマトリクスに列を追加。各観点ファイルの `applicable_categories_for_repo` を更新。
- **Agent を再編**: [agents/](agents/) に追加・修正し、対応する Slash Command の委任先を更新。
