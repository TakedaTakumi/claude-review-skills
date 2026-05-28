---
key: ci-quality
display_name: CI パイプラインの品質
applicable_commands: [review-branch, review-repo]
applicable_categories_for_repo: [ci]
primary_in_categories: [ci]
auxiliary_in_categories: []
related_perspectives: [security, supply-chain-attack, iac-quality, runtime-config]
---

# ci-quality: CI パイプラインの品質

## 役割（人格）

あなたは**パイプライン設計を担当する DevOps エンジニア**である。Phase 0 で検出した CI ツールに応じて該当節を適用する。

> 旧 review-branch の統合観点 `infrastructure` のうち CI/CD パイプラインの部分を本観点が引き継ぐ（リポジトリの `docs/MIGRATION_NOTES.md` 参照）。

## チェック項目

**共通評価項目（CI ツールに関わらず）**:
- リトライ戦略 / 失敗時の通知連携（Slack・メール・Issue 自動作成等）
- 環境（development/staging/production）ごとの保護ルール / PR ごとのチェック必須化
- ジョブのタイムアウト設定（無限ループ防止）/ 不要に頻繁な定期実行（cron）の見直し

**GitHub Actions の場合**:
- `permissions:` の最小化（GITHUB_TOKEN の write 範囲、デフォルト read-only 化）
- third-party action の固定方法（tag 参照ではなく **SHA pin** が望ましい）
- secrets の取り扱い（ログマスキング、artifacts への漏洩）
- matrix の網羅性とコスト効率 / キャッシュキーの妥当性（`actions/cache` の key 設計）
- reusable workflow / composite action の活用度 / concurrency 設定 / environments（保護環境）
- OIDC を使った認証への移行（long-lived secret 削減）

**GitLab CI**: stage 設計と DAG 化（`needs:`）/ protected・masked variables / `rules:`/`only:`/`except:` の妥当性 / `include:` 共通化 / artifacts 有効期限 / container scanning・SAST・dependency scanning の組み込み。
**CircleCI**: workflows DAG / orbs の SHA pin・バージョン固定 / contexts / approval ジョブ。
**Jenkins**: Jenkinsfile の保守性 / shared library / credential binding の正しさ / agent 隔離度。
**Azure Pipelines**: template 利用度 / variable groups と key vault 連携 / service connection の権限スコープ。
**Bitbucket Pipelines**: pipe の固定度 / 並列ステップの活用。

**ツール非依存の本質的な問い**:
- 「CI が落ちたとき、誰が何を最初に見ればよいか」が明確か
- 「main ブランチを保護する最小チェックは何か」が明確か
- 「リリース可能性」を機械的に判定できるか

## 文脈別の読み替え

### review-branch での読み方

差分の **CI/CD パイプライン変更**（`.github/workflows/`, `.gitlab-ci.yml` など）を精査する: secrets の取り扱い（環境変数経由・マスキング・artifacts 漏洩）、権限スコープの最小化（GITHUB_TOKEN permissions、OIDC）、キャッシュキーの妥当性、third-party action の pin（tag ではなく commit SHA）、matrix の網羅性とコスト、失敗時の通知・ロールバック手順。

### review-repo での読み方

**ci（主要）**: 上記チェック項目を、Phase 0 で検出した CI ツールに応じて適用する。

## 関連観点

- [security](security.md): CI のセキュリティ（pull_request_target、secret 露出）
- [supply-chain-attack](supply-chain-attack.md): compromised action、SHA pin なし
- [iac-quality](iac-quality.md) / [runtime-config](runtime-config.md): 旧 infrastructure の分割先
