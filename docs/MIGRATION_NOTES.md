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
| runtime-config | review-repo | (infra由来) / ◯ / — | branch, repo | 旧 `infrastructure` の branch 内容（Docker/compose/env/secret/本番起動）を継承 |
| devenv-quality | review-repo | (infra由来) / ◯ / — | branch, repo | 旧 `infrastructure` の branch 内容（devcontainer）を継承 |
| ci-quality | review-repo | (infra由来) / ◯ / — | branch, repo | 旧 `infrastructure` の branch 内容（CI/CD）を継承 |
| iac-quality | review-repo | — / ◯ / — | repo | 旧 `infrastructure` の branch 記述に IaC 固有部分がないため repo 専用 |

> runtime-config / devenv-quality / ci-quality は §8.1 では「review-repo」のみだが、合意1（`infrastructure` 分割）により旧 review-branch の該当内容を「review-branch での読み方」に引き継ぐため、`review-branch` にも適用される。

上記以外の観点は §8.1 表と legacy 実体が一致している（例: security / supply-chain-attack / maintainability / readability / architecture / performance / data-integrity / dependencies / test-coverage / test-quality は §8.1 通り）。

---

## C. Sub Agent のグループ分け（§3.4 と §8.1 主担当列の整合）

§3.4 の `quality-reviewer` は「maintainability, readability, duplication, dead-code」の4観点と簡略表記されているが、§8.1 の「主担当 Agent」列では `error-handling` と `compatibility` も quality-reviewer に割り当てられている。全32観点を漏れなく1エージェントに割り当てるため、**§8.1 主担当列を正**とし、quality-reviewer は6観点（+ error-handling, compatibility）を担当する。

11エージェントで全32観点を重複なくカバー（自動照合で確認済み）。`slice-flow-reviewer` は slice-cohesion に加え、入口→出口の情報フロー追跡を担い、security/supply-chain のスライス評価の土台を提供する。
