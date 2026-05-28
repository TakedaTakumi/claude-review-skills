# USAGE — 3コマンドの使い方

3つのスラッシュコマンドの使い分け・引数・実行例。観点・分類の本体は Skill 側（`skills/code-review-perspectives/`）にあり、本コマンドは薄いオーケストレータとして Sub Agent に委任する。

## 使い分け

| 状況 | 使うコマンド |
|---|---|
| PR・ブランチ差分を多観点で評価したい | `/review-branch` |
| リポジトリ全体の健康診断（分類別の問題棚卸し、優先順位、スコア推移） | `/review-repo` |
| 起点ファイルから依存スライスを構築し、入口→出口の流れで評価したい | `/review-slice` |

## 共通の挙動

- 進捗ログ: 🔍 進行中 / ✅ 完了 / ⚠️ 警告 / ❌ エラー + 1行（ハングに見えないように主要ステップで必ず出す）
- 各観点は frontmatter の `applicable_commands` で評価モード（branch/repo/slice）を絞っている。指定された観点と当該コマンドの組合せが存在しないときは明示して停止
- 不明なフラグ・観点名・分類名は開始前にユーザー確認（推測で進めない）
- スペース区切りのフラグ（`--base develop` 等）は受け付けず、`=` 区切り（`--base=develop`）のみ

---

## `/review-branch` — ブランチ差分レビュー

### 引数

| 引数 | 既定 | 説明 |
|---|---|---|
| 第1引数（PERSPECTIVES） | `all` | 観点をカンマ区切り。空 / `all` で適用可能な全観点 |
| `--base=<branch>` | リモートのデフォルトブランチを自動検出 | 比較先ブランチ |

### 例

| 入力 | 動作 |
|---|---|
| `/review-branch` | 全観点 / base=自動検出 |
| `/review-branch security` | security のみ |
| `/review-branch security,performance` | 複数観点 |
| `/review-branch --base=develop` | base=develop / 全観点 |
| `/review-branch security --base=main` | security のみ / base=main |

### 流れ

1. **Phase 0**: ベースブランチ決定 → 差分取得 → 公開シンボルの参照箇所収集
2. **Phase 1**: 観点を担当 Agent 群に**並列**委任
3. **Phase 2**: セルフレビュー（15項目）
4. **Phase 3**: 総評（マージ可否 ✅/⚠️/❌）＋ 必須対応 / 推奨対応 / 改善提案 / 評価サマリ表

---

## `/review-repo` — リポジトリ健康診断

### 引数

| 引数 | 既定 | 説明 |
|---|---|---|
| 第1引数（PERSPECTIVES） | `all` | 観点をカンマ区切り |
| `--scope=<path>` | リポジトリ全体 | 評価対象を配下に限定 |
| `--categories=<list>` | 全8分類 | 評価分類をカンマ区切り |
| `--top=<n>` | 規模依存（≤500→5 / ≤2000→10 / ≤5000→20 / 超→30） | 各観点で上位 N 件に絞る |
| `--full` | 段階的実行 | Phase 0 → 1 → 1.5 → 2 → 3 を一気通貫 |
| `--baseline=<path>` | なし | 前回スコア JSON との差分を Phase 3 で出力 |
| `--save=<path>` | なし | Phase 3 のスコアを JSON 保存（次回 `--baseline` で使える） |

### 実行モード

**既定 = 2段階インタラクティブ**:
- **段階1**: Phase 0 完全実行後、各分類の概況サマリ＋簡略スコアカードで**停止**し、深掘り対象の指示を待つ
- **段階2**: ユーザー指示に従い、該当分類・観点の Phase 1 詳細 + Phase 1.5 セルフレビューを実行（複数回繰り返し可）

`--full` を付けると一気通貫（長くなるため事前確認推奨）。

### 例

| 入力 | 動作 |
|---|---|
| `/review-repo` | 段階1（全分類の概況スキャン）で停止 |
| `/review-repo --full` | Phase 0〜3 を一括実行 |
| `/review-repo security` | security 観点のみ（該当する全分類で） |
| `/review-repo --categories=ci,iac` | CI と IaC 分類のみ |
| `/review-repo --scope=src/api` | src/api 配下のみ |
| `/review-repo hotspot --top=20` | hotspot 観点のみ / 上位20件 |
| `/review-repo --full --save=docs/review/2026-05.json` | フル＋スコア保存 |
| `/review-repo --full --baseline=docs/review/2026-04.json --save=docs/review/2026-05.json` | 前回比較＋保存 |
| `/review-repo --categories=meta,build` | ガバナンス＋依存の軽量月次運用 |

PERSPECTIVES と `--categories` は **AND** で絞り込み。交差セルが空欄なら何も実行されない旨を明示。

### スコアカード

各分類×観点を 1〜5 で評価。`--baseline` で前回比較（↑/↓ + 差分指標）。`--save` で次回比較用に JSON 永続化。

---

## `/review-slice` — 機能スライスレビュー

### 引数

| 引数 | 既定 | 説明 |
|---|---|---|
| 第1引数（起点ファイル） | **必須** | 評価の起点。存在しない/ファイルでないならエラー停止 |
| 第2引数以降（PERSPECTIVES） | `all` | スライス適用可能な観点をカンマ区切り |
| `--depth=<n>` | 無制限（安全上限10、0で起点のみ） | 依存追跡の最大深さ |
| `--direction=<down\|up\|both>` | `down` | 追跡方向。down=依存先 / up=利用元 / both=双方向 |
| `--full` | 段階的実行 | Phase 0 → 1 → 2 → 3 を一気通貫 |

### 例

| 入力 | 動作 |
|---|---|
| `/review-slice src/api/order_controller.py` | 段階的実行（Phase 0 後に停止し確認） |
| `/review-slice src/api/order_controller.py --full` | 一気通貫 |
| `/review-slice src/api/order_controller.py --depth=3` | 依存追跡を3段まで |
| `/review-slice src/domain/order.py --direction=up` | 上流（利用元）を辿る |
| `/review-slice src/api/order_controller.py --direction=both` | 双方向 |
| `/review-slice src/api/order_controller.py ddd-tactical,ddd-strategic` | DDD 観点のみ |
| `/review-slice src/api/order_controller.py security,data-integrity --depth=5` | 観点と深さを併用 |

### 流れ

1. **Phase 0**: 起点 → 依存追跡（`--direction`/`--depth`）→ レイヤー・コンテキスト分類 → 境界貫通検出 → 動的解決の警告。段階的実行ではここで停止しユーザー確認
2. **Phase 1**: `slice-flow-reviewer` が入口→出口の情報フローを作成 → 各観点 Agent に並列委任（情報フローを土台にする）
3. **Phase 2**: スライス全体のセルフレビュー
4. **Phase 3**: スライスサマリ（構成サマリ／Critical・High／推奨アクション／観点別スコア 1〜5）

slice で評価しない観点（`documentation`, `dead-code`, `duplication`, `hotspot`, `architecture-drift`, `test-strategy` 等）は対象外。詳細は [MIGRATION_NOTES.md](MIGRATION_NOTES.md) の §B を参照。

---

## トラブルシューティング

- **VSCode 拡張でコマンドが補完に出ない** → `./install.sh --copy` でコピー配置にする（README の「既定 = symlink」表を参照）
- **`sh install.sh` でエラー** → `./install.sh` または `bash install.sh` で実行（dash 非対応）
- **観点を追加したのに認識されない** → SKILL.md のカタログ表に行を追加、担当 Agent の description にも追記。`--copy` モードなら `./install.sh --copy` を再実行
