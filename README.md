# claude-review-skills

> [!IMPORTANT]
> このリポジトリは [claude-tools](https://github.com/TakedaTakumi/claude-tools) に統合されました。
> 今後の更新は claude-tools 側で行います。本リポジトリの内容は統合時点のまま凍結します。
> なお、移行経緯資料（docs/legacy/・MIGRATION_PLAN.md・docs/MIGRATION_NOTES.md）は claude-tools には移管していないため、本リポジトリで参照してください。

Claude Code 向けの多観点コードレビューツール群。3つのスラッシュコマンドを
**Skill（観点ライブラリ）+ Sub Agent（専門ワーカー）+ 軽量 Slash Command（オーケストレータ）**
の組み合わせで構成する。

- **33観点 × 8分類**のマトリクスでブランチ差分／リポジトリ全体／機能スライスを評価
- 観点は1ファイル1観点で**単一情報源**。3コマンドが共有する Skill `code-review-perspectives` から参照
- 観点グループごとに**Sub Agent が並列実行**、観点別に整理された出力

旧 spec（真実の源）は [`docs/legacy/`](docs/legacy/) を、移行の背景は [issue #1](https://github.com/TakedaTakumi/claude-review-skills/issues/1) と [MIGRATION_PLAN.md](MIGRATION_PLAN.md) を参照。

## 3つのコマンド

| コマンド | 用途 |
|---|---|
| `/review-branch` | ブランチの変更（差分）を多観点で評価 |
| `/review-repo` | リポジトリ全体を「ファイル分類 × 観点」で健康診断 |
| `/review-slice` | 起点（ファイル or `ファイル::シンボル`）から依存を辿って機能スライスを構築し評価 |

使い方の詳細は [docs/USAGE.md](docs/USAGE.md) を参照。

## 構成

```
skills/code-review-perspectives/   # 観点ライブラリ（SKILL.md + perspectives/ + categories/ + templates/）
agents/                            # 観点グループ別の Sub Agent（12個）
commands/                          # 各スラッシュコマンド（薄いオーケストレータ、3個）
docs/                              # ドキュメント（legacy/ に旧仕様を保管）
install.sh                         # ~/.claude/ への配置スクリプト
```

設計の全体像は [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)、観点・分類のカタログは [docs/PERSPECTIVES.md](docs/PERSPECTIVES.md) と [docs/CATEGORIES.md](docs/CATEGORIES.md) を参照。

## インストール

### 要件

- **Claude Code**: Skill / Sub Agent / Slash Command 機構をサポートするバージョン（動作確認: **2.1.150**）。`claude --version` で確認できます。
- **bash**: 4 以上（`set -euo pipefail`・`BASH_SOURCE` を使用するため dash / posh では実行不可）。

### make 経由（推奨）

```bash
make                     # ターゲット一覧（help）を表示
make install             # ~/.claude/ に symlink で配置（リポジトリ更新が即反映）
make install-copy        # コピーで配置
make install-force       # 本ツール由来でない同名エントリも確認なしで上書き
make install-copy-force  # コピーで配置かつ本ツール由来でない同名エントリも確認なしで上書き
```

各 `install` 系ターゲットは、内部で `bash ./install.sh` を対応するフラグ付きで呼び出す薄いラッパーです。

### make を使わない場合（`./install.sh` 直接実行）

```bash
./install.sh                  # ~/.claude/ に symlink で配置（リポジトリ更新が即反映）
./install.sh --copy           # コピーで配置
./install.sh --force          # 本ツール由来でない同名エントリも確認なしで上書き
CLAUDE_DIR=/path ./install.sh # 配置先を上書き
```

実行には bash が必要です。`sh install.sh` ではなく、`./install.sh`（要実行権限）または `bash install.sh` で実行してください（`/bin/sh` が dash の環境では `sh install.sh` は失敗します）。`make install` 系ターゲットは内部で `bash ./install.sh` を呼ぶため、この制約を意識せずに使えます。

### clone せずにインストール（一時環境向け）

一時的な環境（使い捨てのコンテナなど）でリポジトリを clone せずに導入したい場合、`gh`（GitHub CLI、認証済み）があれば以下のワンライナーで導入できます。

```bash
gh api repos/TakedaTakumi/claude-review-skills/contents/bootstrap.sh -H "Accept: application/vnd.github.raw" | bash
```

`--force` などのオプションを渡す場合は `bash -s --` に続けて指定します。

```bash
gh api repos/TakedaTakumi/claude-review-skills/contents/bootstrap.sh -H "Accept: application/vnd.github.raw" | bash -s -- --force
```

内部で GitHub の tarball を取得して展開し、`install.sh --copy` を実行します。symlink ではなくコピー配置になる点に注意してください（リポジトリ更新の反映にはこのワンライナーの再実行が必要です）。

### 既定 = symlink、ただし以下では `--copy`（`make install-copy`）を推奨

| ケース | 推奨 | 理由 |
|---|---|---|
| ローカル開発（観点をその場で編集して反映したい） | `make install` / `./install.sh`（symlink） | リポジトリ更新が即反映 |
| **VSCode 拡張版 Claude Code** | `make install-copy` / `./install.sh --copy` | 拡張版がスラッシュコマンドを discovery する際、symlink を辿らずコマンド一覧に出ないことがある |
| `~/.claude` を別 Docker コンテナにバインドする運用 | `make install-copy` / `./install.sh --copy` | symlink のターゲットパスはコンテナ内に存在しないため壊れる |
| `~/.claude` を **`code-review-perspectives` 以外**の用途にも使っている | （安全策の症状なし時はそのまま） | install.sh は自前の名前（`code-review-perspectives` / `*-reviewer.md` / `review-{branch,repo,slice}.md`）以外には触れない。同名衝突がある場合はガードが効いて確認を求める |

`--copy`（`make install-copy`）で配置した場合、観点・Agent・コマンドを編集した後は `make install-copy`（または `./install.sh --copy`）の再実行が必要です（symlink では不要）。`CLAUDE_DIR` で配置先を変えたい場合は `CLAUDE_DIR=/path make install-copy` のように環境変数で指定できます（`./install.sh` 直接実行でも同様）。

## ドキュメント

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — Skill + Sub Agent + Slash Command の設計
- [docs/USAGE.md](docs/USAGE.md) — 3コマンドの使い方・引数・例
- [docs/PERSPECTIVES.md](docs/PERSPECTIVES.md) — 33観点のカタログ
- [docs/CATEGORIES.md](docs/CATEGORIES.md) — 8分類のカタログ
- [docs/MIGRATION_NOTES.md](docs/MIGRATION_NOTES.md) — 移行時の構造組み替えと差異記録
- [CHANGELOG.md](CHANGELOG.md) — 変更履歴（Keep a Changelog 形式）
- [MIGRATION_PLAN.md](MIGRATION_PLAN.md) — 移行計画書（移行作業開始時点の 21観点ベース、経緯記録として保持）

## 利用方針

本リポジトリは **個人ツールとして公開** しているもので、外部からの Pull Request は基本的に受け付けていません。利用・フォーク・派生は [LICENSE](LICENSE)（MIT）の範囲で自由に行ってください（保証なし）。

- 脆弱性を見つけた場合のみ [SECURITY.md](SECURITY.md) に沿って GitHub Security Advisories に報告してください。
- メンテナンス用の同期チェックリストは [docs/MAINTAINER_NOTES.md](docs/MAINTAINER_NOTES.md) にあります（メンテナーと作業を補助する Claude Code 向け）。
