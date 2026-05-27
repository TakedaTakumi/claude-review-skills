# 移行メモ（MIGRATION_NOTES）

このファイルは、legacy 3コマンド（`docs/legacy/`）から Skill 構成へ移行する際に生じた
**構造の組み替え**と、`MIGRATION_PLAN.md` §8.1 の表と legacy 実体の**差異**を記録する。

方針（合意済み）:
- **真実の源は legacy ファイル**。観点の適用範囲（`applicable_commands`）は legacy の実際の採用実態から導出する。
- §8.1 のコマンド適用表は**参考情報**として扱い、legacy と食い違う場合は legacy を優先する。
- legacy にない観点・内容は新規に書き起こさない。

---

## A. `infrastructure` 観点の分解

旧 `review-branch` には統合観点 `infrastructure`（インフラ・環境設定・CI/CD）があったが、
`review-repo` では同領域が4観点に分割されている。移行先は後者に揃え、`infrastructure.md` は作らない。

| 旧 infrastructure の内容 | 移行先の観点 |
|---|---|
| Dockerfile / compose / ベースイメージ / ボリューム・ポート / ヘルスチェック | `runtime-config` |
| 環境変数の整合（`.env.example`/compose/devcontainer/CI 反映）・シークレット管理 | `runtime-config`（+ `security`） |
| devcontainer.json / エディタ設定 / postCreateCommand 冪等性 | `devenv-quality` |
| CI/CD パイプライン（権限、SHA pin、secret 取り扱い、matrix） | `ci-quality` |
| IaC・デプロイ（state、module、drift） | `iac-quality` |
| マイグレーションスクリプト（適用順序・冪等性・ロールバック） | `data-integrity`（ロジックを含むものは `app` 分類） |

各観点ファイルの「review-branch での読み方」セクションに、上記の review-branch 文脈の内容を再配置する。
`templates/severity-criteria.md` の Critical/High 例も、旧 `infrastructure` 行を `runtime-config` と `ci-quality` に分割した（例文は原文のまま）。

---

## B. `applicable_commands` の §8.1 表との差異一覧

各観点の `applicable_commands` frontmatter は、以下のとおり **legacy の実体**で確定する。
（◯=該当セクションが存在 / —=なし。slice の「評価しない観点」= `docs/legacy/review-slice.md` 97–105 行）

| 観点 | §8.1 表 | legacy 実体（branch / repo / slice） | 確定 applicable_commands | 差異の理由 |
|---|---|---|---|---|
| documentation | 全コマンド | ◯ / ◯ / 評価しない | branch, repo | slice は「リポジトリ全体評価向き」として除外 |
| architecture-drift | repo, slice | — / ◯ / 評価しない | repo | slice は「単位として情報不足」で除外 |
| dead-code | repo, slice | — / ◯ / 評価しない | repo | 同上 |
| duplication | repo, slice | — / ◯ / 評価しない | repo | 同上 |
| hotspot | repo, slice | — / ◯ / 評価しない | repo | 同上 |
| test-strategy | 全コマンド | ◯ / ◯ / 評価しない | branch, repo | slice は「テスト全体の戦略評価向き」で除外 |
| observability | repo, slice | ◯ / ◯ / ◯(補助) | branch, repo, slice | branch にも observability セクションが存在（§8.1 に branch 欠落） |
| code-provenance | branch | ◯ / — / ◯(補助) | branch, slice | slice に補助観点として存在（§8.1 に slice 欠落） |
| ddd-tactical | 全コマンド | ◯ / — / ◯ | branch, slice | repo は `ddd-strategic` を使う（repo に ddd-tactical セクションなし） |
| i18n-a11y | branch, repo | ◯ / — / 評価しない | branch | review-repo に i18n-a11y セクション・マトリクス行が存在しない |

上記以外の観点は §8.1 表と legacy 実体が一致している（例: security / supply-chain-attack / maintainability / readability / architecture / performance / data-integrity / dependencies / test-coverage / test-quality は §8.1 通り）。

> このセクションは Phase 3 の各グループ作成に合わせて検証・追補する。
