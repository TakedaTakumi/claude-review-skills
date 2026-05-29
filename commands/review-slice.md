---
description: 起点ファイルから依存を辿って機能スライスを構築し、多観点でレビューするオーケストレータ
argument-hint: "<起点ファイル> [perspectives] [--depth=<n>] [--direction=<down|up|both>] [--full]"
allowed-tools: Bash(git:*), Bash(rg:*), Read, Grep, Glob
---

# Slice Review (Orchestrator)

観点ライブラリ Skill `code-review-perspectives` と Sub Agent を組み合わせ、起点ファイルからの依存スライスを集中レビューする薄いオーケストレータ。

## 進捗表示

🔍/✅/⚠️/❌ + 1行。依存追跡が長引く場合は深さが進むごとに出す。詳細は Skill の `templates/progress-log.md`。

## 引数仕様（`$ARGUMENTS`）

- 第1引数 = 起点ファイルパス（**必須**）。存在しない/ファイルでないならエラー停止。
- `--depth=<n>`: 追跡最大深さ（既定 無制限、安全上限 10、`0` で起点のみ）。
- `--direction=<down|up|both>`: 追跡方向（既定 `down`）。down=依存先 / up=利用元 / both=双方向。
- `--full`: 一気通貫。なければ段階的実行（Phase 0 で停止 → ユーザー確認 → 評価）。
- PERSPECTIVES（任意）: カンマ区切り、空 or `all` でスライス適用可能な全観点。スペース区切りフラグ不可。不明な値は確認。
- 評価可能な観点 = Skill の各観点 frontmatter で `applicable_commands` に `review-slice` を含むもの（`slice-cohesion` 含む。documentation/dead-code/duplication/hotspot/architecture-drift/test-strategy 等は対象外）。

## 実行手順

### Phase 0: スライス構築

1. リポジトリ確認・起点ファイル存在確認・言語判定。
2. プロジェクト指紋（軽量版: 言語/FW/PM/モノレポ/DDD 採用/PBT 採用/DI 機構）。
3. スライス構築: 起点から import/require/use をパースし `--direction`/`--depth` で再帰追跡。外部ライブラリは追跡対象外（名は記録）。動的解決（DI/リフレクション/文字列ルーティング）は静的追跡不可として明示。
4. スライス内ファイルをレイヤー（presentation/application/domain/infrastructure）・コンテキスト（DDD 時）に分類。
5. 境界貫通（レイヤー越え・コンテキスト越え/ACL の有無）を検出。
6. スライス情報・実行予定観点を宣言。**段階的実行では Phase 0 出力後に停止**し、スライス構成の正否・追加すべきファイルの要否をユーザーに確認。

### Phase 1: Sub Agent への委任（並列）

- まず `slice-flow-reviewer` に `slice-cohesion` ＋ 入口→出口の情報フロー追跡を委任（security/supply-chain の土台になる）。
- 適用観点を担当 Agent にまとめ**並列**委任（評価モード=`slice`・スライスファイル群・レイヤー/境界情報・情報フローを渡す）:
  - security 系 → `security-reviewer` / アーキ → `architecture-reviewer` / DDD → `ddd-reviewer` / 性能・データ → `performance-reviewer` / 品質（error-handling/maintainability/readability）→ `quality-reviewer` / 依存 → `dependencies-reviewer` / observability → `ops-reviewer` / code-provenance → `ownership-reviewer`

### Phase 2 / 3

- **2 スライス全体のセルフレビュー**: 観点間整合、誤検知、境界貫通の妥当性。
- **3 スライスサマリ**: 構成サマリ、良かった点（**指摘より先に提示・必須**。無ければ「特になし」）、Critical/High、スライスとしての推奨アクション、観点別スコア（1〜5）。重大度は Skill の `templates/severity-criteria.md`。

## 動作上の注意

- 推測で進めない。起点不明・依存が異常に多い・動的解決が多すぎる場合はユーザー確認。
- スライス外には踏み込まない（リポジトリ全体評価が必要なら `/review-repo` を案内）。
- 動的解決の限界を明示し、手動追加候補を提示。Docker compose+devcontainer / PBT / 関心の分離を尊重する。
