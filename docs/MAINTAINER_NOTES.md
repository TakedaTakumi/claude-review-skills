# Maintainer Notes

このリポジトリは個人ツールで PR は受け付けていません。本ドキュメントは **メンテナー（今のところ自分）と作業を補助する Claude Code** のための同期チェックリストです。

## 観点を追加する場合

このリポジトリの中核となる更新です。追加時は **以下のすべてを同期** してください（同期点の削減は中期課題）。

- [ ] `skills/code-review-perspectives/perspectives/<key>.md` を追加（frontmatter キー: `key` / `display_name` / `applicable_commands` / `applicable_categories_for_repo` / `primary_in_categories` / `auxiliary_in_categories` / `related_perspectives`）
- [ ] 本文の節構成を既存観点に合わせる（役割（人格）→ チェック項目 → 文脈別の読み替え → 重大度の判断例 → 関連観点）
- [ ] `skills/code-review-perspectives/SKILL.md` の観点カタログ表に行を追加
- [ ] 該当する分類で評価する場合は `SKILL.md` の **分類 × 観点マトリクス**（`✅` / `⚠️`）にも反映
- [ ] `docs/PERSPECTIVES.md` の観点リストにも追記
- [ ] 担当 Sub Agent の `agents/<agent>.md` の `description` に追記（auto-invocation のヒント）
- [ ] [CHANGELOG.md](../CHANGELOG.md) の `[Unreleased]` セクションに `### Added` で記録

## 分類を追加する場合（稀）

- [ ] `skills/code-review-perspectives/categories/<key>.md` を追加（`key` / `display_name` / `typical_paths` / `applicable_perspectives.primary` / `applicable_perspectives.auxiliary` を frontmatter で）
- [ ] `SKILL.md` の分類カタログ表と **分類 × 観点マトリクス** に列を追加
- [ ] 既存32観点それぞれの `applicable_categories_for_repo` / `primary_in_categories` / `auxiliary_in_categories` を更新
- [ ] `docs/CATEGORIES.md` にも追記
- [ ] CHANGELOG に記録

## Sub Agent を追加・改修する場合

- [ ] `agents/<agent>.md` を作成・編集（`description` / `tools:` / 入力 / 評価手順 / 注意 の節構成）
- [ ] `tools:` は **最小権限の原則** に従う（`Bash` を無制限に与えず、`Bash(git:*)` 等で絞る）
- [ ] 対応する Slash Command（`commands/review-{branch,repo,slice}.md`）の委任先を更新
- [ ] `docs/ARCHITECTURE.md` の Sub Agent 担当表を更新
- [ ] CHANGELOG に記録

## Slash Command を追加・改修する場合

- [ ] `commands/<name>.md` を作成・編集
- [ ] **100 行以内** に収める（薄いオーケストレータの設計を維持）
- [ ] `allowed-tools` で必要最小限の Bash サブコマンドのみ宣言
- [ ] `docs/USAGE.md` に使い方を追記
- [ ] CHANGELOG に記録

## コミット規約

直近の履歴に合わせ、以下のスタイル:

- 1行サマリは **70文字以内**、主題（"何を変えたか"）と理由（"なぜ"）を本文で補足
- 移行作業に類するまとまった変更は `Phase N: <主題>` 形式
- 限定的なファイル変更は `<対象>: <主題>` 形式（例: `install.sh: 上書きガードを追加`）
- 観点・分類・テンプレートの追加は `<観点キー> 観点を追加` / `<分類キー> 分類を追加` 等

## 危険コマンドの取り扱い

観点ファイル・テンプレートに **検出パターンとして危険コマンド**（`curl ... | sh` / `nc -e` / `bash -i >& /dev/tcp/` 等）を引用することがあります。引用する際は:

- 「これを検出せよ」と明確に分かる文脈で書く（「これを実行せよ」と読めないように）
- コードブロックで囲む
- 不可視文字・双方向制御文字・ホモグリフを含めない

## CI（GitHub Actions）

`.github/workflows/check.yml` に 3 ジョブを置いています:

| ジョブ | 内容 | ローカル再現 |
|---|---|---|
| `unicode` | 観点ファイル等への不可視文字／双方向制御文字／BOM の混入検出（prompt injection 予防） | `grep -rPln '[\x{200B}-\x{200F}\x{202A}-\x{202E}\x{2066}-\x{2069}\x{FEFF}]' --include='*.md' --include='*.sh' .` |
| `shellcheck` | `install.sh` の静的解析 | `shellcheck install.sh` |
| `gitleaks` | シークレットの誤コミット検出 | `gitleaks detect` |

トリガーは `main` / `develop` への push、`pull_request`、`workflow_dispatch`（GitHub UI / `gh workflow run check.yml` から手動実行）。GitHub 公式 actions は major version tag、third-party action は commit SHA pin（ci-quality 観点準拠）。

## セルフレビュー（dogfooding）

変更後、本リポジトリ自身に対して `/review-branch` や `/review-repo` を実行することで、観点ライブラリ自体の品質を担保できます。
