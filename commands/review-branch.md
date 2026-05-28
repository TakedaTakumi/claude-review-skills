---
description: ブランチの変更（差分）を多観点で評価するオーケストレータ
argument-hint: "[perspectives] [--base=<branch>]"
allowed-tools: Bash(git:*), Bash(gh:*), Bash(rg:*), Read, Grep, Glob
---

# Branch Review (Orchestrator)

観点ライブラリ Skill `code-review-perspectives` と複数の Sub Agent を組み合わせてブランチ差分レビューを実行する薄いオーケストレータ。観点の本体は Skill 側（`perspectives/`, `templates/`）にある。

## 進捗表示

🔍 進行中 / ✅ 完了 / ⚠️ 警告 / ❌ エラー + 1行で進捗を出す。詳細は Skill の `templates/progress-log.md`。

## 引数仕様（`$ARGUMENTS`）

- `--base=<branch>`: ベースブランチ（スペース区切り `--base <branch>` は不可＝エラー停止）。未指定なら GitHub デフォルトブランチを自動取得。
- 先頭の非フラグ引数 = PERSPECTIVES（カンマ区切り、空 or `all` で全観点）。余剰引数はエラー停止。
- 評価可能な観点 = Skill の各観点 frontmatter で `applicable_commands` に `review-branch` を含むもの。
- 不明なフラグ・観点名は開始前にユーザー確認（推測で進めない）。

## 実行手順

### Phase 0: 準備（ベースブランチ決定 & 差分取得）

1. `git rev-parse --is-inside-work-tree` で確認。
2. BASE_BRANCH 決定（引数 > `gh repo view --json defaultBranchRef` > `git symbolic-ref refs/remotes/origin/HEAD` > ローカル main/master）。決定根拠を明示。
3. remote 鮮度確認（`git fetch --dry-run origin <BASE>`）。更新があれば fetch するかユーザー確認（勝手に fetch しない）。
4. 現在ブランチ取得。base == head ならエラー停止。
5. マージベース取得 → 差分（`--name-status` / `--stat` / 詳細 diff、大きければファイル単位）。
6. コミット履歴 `git log --oneline <merge-base>..HEAD`。
7. 影響範囲: 変更/追加/削除された公開シンボル（関数・クラス・エンドポイント・CLI フラグ・env・設定キー・DB スキーマ）を抽出し、`rg`/`git grep` で参照箇所を洗う（compatibility/architecture/test-coverage で参照）。
8. 大量変更（目安 1000 行超 or 30 ファイル超、または平均 PR 比で大）ならファイル単位読みへ方針宣言。
9. 適用観点を決定（PERSPECTIVES × applicable_commands）。

### Phase 1: Sub Agent への委任（並列）

決定した観点を担当 Agent ごとにまとめ、**並列に**委任する（各 Agent に 評価モード=`branch`・差分情報・適用観点を渡す）:

- security 系 → `security-reviewer` / 品質系 → `quality-reviewer` / アーキ → `architecture-reviewer` / DDD → `ddd-reviewer` / テスト → `test-reviewer` / 性能・データ → `performance-reviewer` / ops（runtime-config/devenv-quality/ci-quality/observability）→ `ops-reviewer` / 依存 → `dependencies-reviewer` / メタ（documentation/i18n-a11y）→ `meta-reviewer` / 由来（code-provenance）→ `ownership-reviewer`

### Phase 2: 集約とセルフレビュー

各 Agent の結果を集約し、観点間の重複・矛盾を解消する。branch のセルフレビュー15項目に準拠（見落とし／誤検知・過剰指摘／重大度の妥当性／観点間の整合／影響範囲）。

### Phase 3: サマリー出力

総評（マージ可否 ✅/⚠️/❌）、必須対応（Critical/High）、推奨対応（Medium）、今後の改善提案（Low/Info）、評価サマリ表。重大度は Skill の `templates/severity-criteria.md`。

## 動作上の注意

- 推測で進めない。確認すべきケースは Sub Agent に委任せずメインで確認する。
- ファイルパスと行番号を必ず添える。既存コードのスタイル・規約を尊重する。
- `review-repo` / `review-slice` との棲み分けを尊重する。
