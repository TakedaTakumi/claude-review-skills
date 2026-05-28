---
description: リポジトリ全体を「ファイル分類 × 観点」マトリクスで健康診断するオーケストレータ
argument-hint: "[perspectives] [--scope=<path>] [--categories=<list>] [--top=<n>] [--full] [--baseline=<path>] [--save=<path>]"
allowed-tools: Bash(git:*), Bash(gh:*), Bash(rg:*), Bash(cloc:*), Read, Grep, Glob
---

# Repository Review (Orchestrator)

観点ライブラリ Skill `code-review-perspectives` の「分類カタログ」「分類 × 観点マトリクス」と Sub Agent を組み合わせ、リポジトリ全体を健康診断する薄いオーケストレータ。

## 進捗表示

🔍/✅/⚠️/❌ + 1行。観点・分類が多く長時間化するため特に厳密に出す。詳細は Skill の `templates/progress-log.md`。

## 引数仕様（`$ARGUMENTS`）

- `--scope=<path>`: 対象を配下に限定（既定: リポジトリ全体）。
- `--categories=<list>`: 評価分類をカンマ区切り（既定: 全8分類）。
- `--top=<n>`: 各観点の上位 N 件（既定は規模依存: ≤500→5 / ≤2000→10 / ≤5000→20 / それ超→30＋スコープ推奨）。
- `--full`: Phase 0〜3 を一気通貫。
- `--baseline=<path>` / `--save=<path>`: 健康スコアの前回比較・保存（JSON）。
- 先頭の非フラグ = PERSPECTIVES（カンマ区切り、空 or `all` で全観点）。PERSPECTIVES と `--categories` は AND 絞り込み（交差セルが空なら明示し代替案提示）。スペース区切りフラグ不可。不明なフラグ/観点/分類は確認。

## 実行モード（既定 = 2段階インタラクティブ）

- **段階1（既定）**: Phase 0 完全実行後、各分類の概況サマリ（1〜2段落）＋深掘り推奨観点＋簡略スコアカードを出して**停止**。次に深掘りする分類・観点をユーザーに促す。
- **段階2**: 指示された分類・観点で Phase 1 詳細 + Phase 1.5 セルフレビュー（複数回繰り返し可）。
- **`--full`**: Phase 0 → Phase 1（全分類 × 全観点）→ 1.5 → 2 → 3 を一括（長くなるため事前確認推奨）。

## 実行手順

### Phase 0: メタデータ収集と分類確定

1. 規模（ファイル数・言語構成、`cloc` 等）とプロジェクト指紋（言語/FW/PM/モノレポ/DDD 採用/PBT 採用/公開度）。
2. 各ファイルを8分類に確定（Skill の `categories/*.md` の typical_paths と境界事例ルール。迷うものは Phase 0 でユーザー確認）。
3. 実行予定（分類 × 観点）を宣言。SCOPE / categories / PERSPECTIVES で絞る。

### Phase 1: 分類ごとに Sub Agent へ委任（並列）

各分類で評価する観点は Skill のマトリクス（✅ 主要 / ⚠️ 補助）に従う。観点を担当 Agent ごとにまとめ**並列**委任（評価モード=`repo`・分類・対象パス・適用観点を渡す）:

- security/supply-chain → `security-reviewer` / 品質 → `quality-reviewer` / アーキ・monorepo → `architecture-reviewer` / ddd-strategic → `ddd-reviewer` / テスト → `test-reviewer` / performance・hotspot・data-integrity → `performance-reviewer` / ops → `ops-reviewer` / 依存 → `dependencies-reviewer` / メタ → `meta-reviewer` / ownership → `ownership-reviewer`

✅/⚠️ で評価の深さ・出力の重みを変える（Skill の「✅ 主要と ⚠️ 補助の運用差」）。

### Phase 1.5 / 2 / 3

- **1.5 セルフレビュー**: マトリクスのカバー率、誤検知・過剰指摘、重大度・スコアの妥当性、観点間・分類間の整合、プロジェクト種別との整合。
- **2 優先順位**: インパクト × コスト（Skill の `templates/severity-criteria.md`）。
- **3 健康スコアカード（1〜5）＋アクションロードマップ**（短期/中期/長期）。`--baseline` で前回比較、`--save` で保存。

## 動作上の注意

- 推測で進めない。分類に迷うファイルは Phase 0 でユーザー確認。
- 長時間化を避けるため既定は段階1で停止し、深掘りは指示を待つ。
- `review-branch` / `review-slice` との棲み分けを尊重する。
