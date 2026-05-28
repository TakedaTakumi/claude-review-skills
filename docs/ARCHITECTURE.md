# ARCHITECTURE — 設計の全体像

## 構成要素（4層）

```
┌──────────────────────────────────────────────────┐
│ Slash Command（薄いオーケストレータ、各100行以下）   │
│  /review-branch  /review-repo  /review-slice     │
│  - 引数パース・Phase 0 準備                          │
│  - Sub Agent への並列委任                            │
│  - 結果集約・セルフレビュー・サマリー出力             │
└──────────────────────┬───────────────────────────┘
                       │ 委任（評価モード・対象・適用観点）
                       ▼
┌──────────────────────────────────────────────────┐
│ Sub Agent（観点グループ別の専門ワーカー、11個）       │
│  security-reviewer / quality-reviewer / ...      │
│  - 独立コンテキストで実行                            │
│  - 担当観点を Skill から読み込んで評価                │
│  - 観点別に構造化した結果を返す                       │
└──────────────────────┬───────────────────────────┘
                       │ 参照（必要な観点・テンプレだけ）
                       ▼
┌──────────────────────────────────────────────────┐
│ Skill: code-review-perspectives（観点ライブラリ）   │
│  SKILL.md（カタログ + マトリクス + 索引）             │
│  perspectives/*.md  — 32 観点（1観点 = 1ファイル）   │
│  categories/*.md    — 8 分類（app/test/build/...）  │
│  templates/*.md     — 5 テンプレ（重大度・出力・進捗・エスカレ・slice-flow） │
└──────────────────────────────────────────────────┘
```

## 設計原則

- **単一情報源（Single Source of Truth）**: 1観点 = 1ファイル。3コマンドはこの観点ライブラリを共有参照する（以前は3ファイルに同じ観点が重複していた）
- **段階的開示（Progressive Disclosure）**: メインコンテキストには SKILL.md と必要な観点だけをロード。全観点を一度に読み込まない
- **関心の分離**: Skill = 観点定義 / Sub Agent = 評価実行 / Slash Command = オーケストレーション
- **並列性**: 観点グループごとに Sub Agent を**並列**実行（観点数が多くてもコンテキスト枯渇を避ける）
- **拡張容易性**: 観点追加は1ファイル追加のみで完結（カタログ表に行を足す＋担当 Agent に追記）

## なぜこの構成か

| 要素 | 理由 |
|---|---|
| **Skill** | 32観点 × 8分類 = 重複しがちな構造を単一情報源に。`SKILL.md` の auto-invocation で「コードレビュー」用途を自動認識 |
| **Sub Agent** | 観点グループを独立コンテキストで評価でき、メインの探索ノイズで汚さない。並列実行で速い |
| **Slash Command** | ユーザーは `/review-branch` のような明示呼び出しを期待。薄いオーケストレータに留め、本体は Skill に置く |

## データの流れ（例: `/review-branch security`）

1. Slash Command が引数を解析、Phase 0 でベースブランチ決定・差分取得・公開シンボル参照を準備
2. `security` 観点ファイル（`perspectives/security.md`）と関連テンプレを Skill から確認し、担当 Agent を決定（→ `security-reviewer`）
3. `security-reviewer` に **`branch` モード + 差分情報 + 適用観点キー** を渡して**並列**起動
4. Agent は `perspectives/security.md` ＋ 関連テンプレ（`severity-criteria.md` 等）を読み、`output-format.md` の branch 形式で結果を返す
5. メインが結果を集約 → セルフレビュー15項目 → 総評（マージ可否＋必須/推奨/改善＋評価サマリ表）

`security,supply-chain-attack,performance` のように複数指定すれば、担当 Agent（`security-reviewer` と `performance-reviewer`）が並列に走る。

## マトリクスの整合性

「観点ファイルの frontmatter（`primary_in_categories` / `auxiliary_in_categories`）」「分類ファイルの frontmatter（`applicable_perspectives`）」「SKILL.md のマトリクス（✅/⚠️）」の三者は**完全一致**を保つ（移行時に自動照合で確認、検収条件7）。新観点を追加する際は、これら3箇所をいずれも更新すること。

## 11 Sub Agent の担当範囲

| Agent | 担当観点 |
|---|---|
| `security-reviewer` | security, supply-chain-attack |
| `quality-reviewer` | maintainability, readability, duplication, dead-code, error-handling, compatibility |
| `architecture-reviewer` | architecture, architecture-drift, monorepo |
| `ddd-reviewer` | ddd-tactical, ddd-strategic |
| `test-reviewer` | test-coverage, test-quality, test-strategy, test-pyramid |
| `performance-reviewer` | performance, hotspot, data-integrity |
| `ops-reviewer` | runtime-config, devenv-quality, ci-quality, iac-quality, observability |
| `dependencies-reviewer` | dependencies |
| `meta-reviewer` | governance, documentation, i18n-a11y |
| `ownership-reviewer` | ownership, code-provenance |
| `slice-flow-reviewer` | slice-cohesion ＋ 入口→出口情報フロー追跡（review-slice 専用） |

合計32観点を**漏れ・重複なく**カバー（自動照合で検証済み）。

## 観点・分類・コマンドの観点適用

各観点ファイル先頭の `applicable_commands` で、どのコマンド（`review-branch` / `review-repo` / `review-slice`）で評価されるかを宣言する。これは legacy の3コマンドファイルの実体に基づき決定しており、`MIGRATION_PLAN.md` §8.1 の表と異なる箇所は [MIGRATION_NOTES.md](MIGRATION_NOTES.md) §B に記録している。

## なぜ Slash Command を残したか（Skill だけにしなかった理由）

- ユーザーは依然として `/review-branch` のような**明示呼び出し**を期待する
- Skill だけでは auto-invocation の不確実性がある（ユースケースが曖昧だと発火しない）
- 軽量化された Slash Command（各100行以下）はオーケストレータとして最小限の役割を持つ
