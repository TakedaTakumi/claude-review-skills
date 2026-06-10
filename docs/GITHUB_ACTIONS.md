# GitHub Actions で動かす — 設定手順

別のリポジトリ（**対象リポ**）の PR で本ツールのレビューを自動実行し、結果を PR コメントに投稿するための設定手順。**対象リポの管理者がこの手順を見ながら設定する**ことを想定している。

> このリポジトリ自身を CI で動かす手順ではない。サンプルのワークフローは [`examples/claude-review.yml`](../examples/claude-review.yml)。

## できること

- PR が **opened** されたら `/review-branch`（ブランチ差分の多観点レビュー）を自動実行
- レビュー結果を **PR コメントとして自動投稿**

## 仕組み

公式アクション [`anthropics/claude-code-action`](https://github.com/anthropics/claude-code-action) は、`actions/checkout` 後のリポジトリ直下 `.claude/`（`skills/` `agents/` `commands/`）を Claude Code のプロジェクト設定として自動読込する。本ツールは通常 `~/.claude/` に置くが、CI では **対象リポの `.claude/` に展開**すれば同じように使える。

ワークフローは次の順で動く:

1. `actions/checkout`（**全履歴**。差分の merge-base 計算に必要）
2. PR の **base ブランチを pre-fetch**（後述の注意点を参照）
3. 本ツールを固定タグで `git clone` → `install.sh --copy` で `$GITHUB_WORKSPACE/.claude/` に展開
4. `claude-code-action@v1` が `prompt: "/review-branch ..."` を自動実行し、結果を PR コメントへ投稿

---

## セットアップ手順（API キー方式・推奨）

### Step 1. API キーを Secrets に登録

[Anthropic Console](https://console.anthropic.com/) で API キーを発行し、対象リポの **Settings → Secrets and variables → Actions** に `ANTHROPIC_API_KEY` として登録する。

> 認証方式の選択（API キー / WIF）は [認証方式](#認証方式) を参照。**Claude のサブスク（Pro/Max/Team）と API キーは別物**で、CI の無人実行で素直に使えるのは API キー（または WIF）。サブスク料金内で CI 実行を賄うことは基本できず、CI 実行はトークン従量課金になる。

### Step 2. ワークフローを追加

[`examples/claude-review.yml`](../examples/claude-review.yml) を対象リポの `.github/workflows/claude-review.yml` としてコピーする。最低限、次を確認/調整する:

- `REVIEW_SKILLS_REF`: 取り込む本ツールのバージョン（既定 `release_20260528`）。タグ・ブランチ・SHA いずれも可。
- `--model` / `--max-turns`: コスト方針に合わせて調整（[カスタマイズ](#カスタマイズ)）。

### Step 3. 動作確認

対象リポで適当な PR を新規作成（opened）し、Actions の `Claude PR Review` が走ってレビュー結果が PR コメントに付くことを確認する。

---

## ワークフローの要点

```yaml
on:
  pull_request:
    types: [opened]            # opened のみ（再 push では再実行しない）

permissions:
  contents: read
  pull-requests: write         # PR コメント投稿に必要
  issues: write

steps:
  - uses: actions/checkout@v4
    with: { fetch-depth: 0 }   # ★ 全履歴

  - name: Pre-fetch base branch # ★ base をローカルに用意
    run: git fetch --no-tags origin "+refs/heads/${BASE}:refs/remotes/origin/${BASE}"

  - name: Install into .claude/  # 固定タグで clone → install.sh --copy
    run: |
      git clone --depth 1 --branch "$REVIEW_SKILLS_REF" https://github.com/TakedaTakumi/claude-review-skills.git /tmp/crs
      CLAUDE_DIR="$GITHUB_WORKSPACE/.claude" bash /tmp/crs/install.sh --copy

  - uses: anthropics/claude-code-action@v1
    with:
      anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
      prompt: "/review-branch --base=${{ github.event.pull_request.base.ref }}"
      claude_args: |
        --model claude-sonnet-4-6
        --max-turns 40
        --allowedTools Read,Grep,Glob,Task,Bash(git:*),Bash(gh:*),Bash(rg:*)
```

---

## 認証方式

### A. ANTHROPIC_API_KEY（推奨・最も単純）

Console 発行の API キーを Secrets に登録し、`anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}` を渡すだけ。CI の正攻法。従量課金。

### B. WIF（Workload Identity Federation・キーレス）

静的キーを Secrets に保存したくない場合の選択肢。GitHub OIDC トークンを Anthropic 側で交換するため、リポジトリにキーを置かない。Anthropic の Organization（Team プランも保有）に紐づく。

```yaml
permissions:
  contents: read
  pull-requests: write
  issues: write
  id-token: write              # ★ OIDC に必要

steps:
  # ...checkout / pre-fetch / install は同じ...
  - uses: anthropics/claude-code-action@v1
    with:
      # API キーの代わりにフェデレーション情報を渡す（値は Console で発行）
      anthropic_federation_rule_id: ${{ vars.ANTHROPIC_FEDERATION_RULE_ID }}
      anthropic_organization_id: ${{ vars.ANTHROPIC_ORGANIZATION_ID }}
      anthropic_service_account_id: ${{ vars.ANTHROPIC_SERVICE_ACCOUNT_ID }}
      anthropic_workspace_id: ${{ vars.ANTHROPIC_WORKSPACE_ID }}
      prompt: "/review-branch --base=${{ github.event.pull_request.base.ref }}"
      claude_args: |
        --model claude-sonnet-4-6
        --max-turns 40
        --allowedTools Read,Grep,Glob,Task,Bash(git:*),Bash(gh:*),Bash(rg:*)
```

> WIF の各 ID（rule / organization / service account / workspace）は Anthropic Console のフェデレーション設定で発行する。`id-token: write` 権限が必須。フェデレーション入力名は action のバージョンで変わり得るため、設定前に [action の README / action.yml](https://github.com/anthropics/claude-code-action) で最新の入力名を確認すること。

---

## カスタマイズ

| 変えたいこと | 方法 |
|---|---|
| レビュー観点を絞る | `prompt: "/review-branch security,performance --base=..."`（第1引数にカンマ区切り） |
| 再 push でも再実行 | `on.pull_request.types` に `synchronize` を追加（実行回数=コスト増に注意） |
| 手動起動も足す | `on` に `workflow_dispatch` を追加。`@claude` メンション運用にするなら `prompt` を外し `issue_comment` 等をトリガーにする（[公式ドキュメント](https://code.claude.com/docs/en/github-actions) 参照） |
| モデルを上げる | `--model claude-opus-4-8`（より深いレビュー・高コスト） |
| 取り込むバージョン固定 | ワークフローの `REVIEW_SKILLS_REF` をタグ/SHA に設定 |

---

## コスト

`/review-branch` は最大 11 個の Sub Agent を**並列**で起動し、各エージェントが観点定義＋差分＋関連ソースを読みながら複数ターン回る。各 API 呼び出しはターンごとに累積コンテキストを送り直すため、1 PR あたりのトークン消費は大きくなりやすい。

### 単価（2026 時点）

| モデル | 入力 $/MTok | 出力 $/MTok |
|---|---|---|
| `claude-sonnet-4-6`（サンプル既定） | $3 | $15 |
| `claude-opus-4-8` | $5 | $25 |

プロンプトキャッシュは書き込み 1.25×・**読み出し 0.1×**（出力は通常価格）。同一プレフィックスの再送はキャッシュ読み出しで大幅に安くなる。

### 1 PR あたりの目安（概算・要実測）

中規模 PR で全観点を回した場合の**桁感**は、**Sonnet で概ね $3〜$20/PR、Opus で $8〜$35/PR** 程度。差分量・関連ファイル数・ターン数で**数倍ぶれる**。
**正確な額は対象リポの実 PR で 1〜2 回実測して確かめること**（これがいちばん確実）。最も重いのは「全観点 × 大きい PR × Opus」の組み合わせ。`/review-branch` は差分中心でリポ全体を舐めないため `/review-repo` よりは軽い。

### 抑制レバー（効果が大きい順）

1. **トリガーを `opened` のみにする**（サンプル既定）— 再 push ごとの再実行を防ぐ。最大の効き目。
2. **観点を絞る** — `prompt: "/review-branch security,performance --base=..."`。起動 Agent 数が 11→2〜3 に減り消費が激減。「全観点」が最も高い。
3. **モデルを Sonnet 4.6 に**（サンプル既定）— Opus 比で約 1.7 倍安い。深いレビューが要る PR だけ Opus に上げる。
4. **大きい PR / Draft を除外** — ジョブ条件で Draft をスキップ（例: `if: github.event.pull_request.draft == false`）、または差分行数でガードする。
5. **`--max-turns` 上限**（サンプル済み）— 暴走の安全弁。
6. **Console で予算アラート / 専用 API キー** — 月次上限・通知を設定し、想定超過を早期検知する。

---

## 注意点・トラブルシュート

- **全履歴が必須**: `fetch-depth: 0` を外すと merge-base 差分が取れずレビューが成立しない。
- **base の pre-fetch**: 本ツールの `/review-branch` は「勝手に fetch しない（ユーザーに確認）」設計。CI には確認相手がいないため、base ブランチを事前取得しておく（サンプルの Pre-fetch ステップ）。
- **許可ツール**: 11 個の Sub Agent が `git` / `rg` / `Read/Grep/Glob` を、オーケストレータが `gh` と `Task`（委任）を使う。CI は権限プロンプトを出せないので `--allowedTools` で明示する。レビューが「権限待ち」で進まないときはこの許可リストを見直す。
- **コスト/時間**: `/review-branch` は最大 11 Agent を並列起動するため、1 回の実行でトークン・実行時間が大きい。`opened` のみのトリガー、`--model`、`--max-turns`、観点の絞り込みでコントロールする。
- **対象リポに既存の `.claude/` がある場合**: `install.sh --copy` は本ツール由来でない同名エントリを CI（非対話）では上書きせずスキップする。本ツールの名前（`code-review-perspectives` / `*-reviewer.md` / `review-{branch,repo,slice}.md`）と衝突しなければ問題ない。意図的に上書きするなら install.sh に `--force` を付ける。
- **`gh` 認証**: 既定の `GITHUB_TOKEN` で動作する。PR コメントには `pull-requests: write` が必要。

---

## セキュリティ（本ツールの `ci-quality` 観点に沿った推奨）

本リポジトリ自身は CI で「third-party action は commit SHA で pin」する方針を採っている（[`.github/workflows/check.yml`](../.github/workflows/check.yml)）。対象リポでも同様に固めるなら:

- `anthropics/claude-code-action@v1` を **commit SHA に pin** する
- `REVIEW_SKILLS_REF` を**タグではなく SHA** に固定する（タグは付け替え可能なため）
- `git clone` 先（`/tmp/...`）は対象リポ外。`install.sh` は bash 4+ を要求する（ubuntu-latest は bash 5 で問題なし）

サンプルは可読性を優先して `@v1` / タグ参照にしている。運用の堅さを優先する場合は上記の SHA pin を検討する。
