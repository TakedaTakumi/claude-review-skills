---
key: ci
display_name: CI パイプライン
typical_paths:
  - .github/workflows/
  - .gitlab-ci.yml
  - .circleci/
  - Jenkinsfile
  - azure-pipelines.yml
  - bitbucket-pipelines.yml
applicable_perspectives:
  primary: [ci-quality, security]
  auxiliary: [supply-chain-attack, observability, hotspot, dead-code, duplication, performance]
---

# ci: CI パイプライン

## 本質

パイプラインの正しさ、最小権限、シークレット保護、サプライチェーン保護。
`.github/workflows/` の各 yml は1ファイルずつ意味が大きいので**全ファイル詳読**。

## 適用観点

**主要（✅）**: ci-quality（パイプライン品質）, security（CI のハイジャック対策）
**補助（⚠️）**: supply-chain-attack（action の SHA pin・compromised action）, observability（失敗時アラート・実行時間）, hotspot（頻繁に修正される CI）, dead-code（発火不能 workflow）, duplication（共通 steps）, performance（CI 実行効率）

## 境界事例の判断ルール

- GitHub Actions の reusable workflow（`.github/workflows/reusable-*.yml`）は **ci**。
- CI 専用のスクリプト（`scripts/` 配下で CI からのみ呼ばれるもの）は **ci**。
- CI から呼ばれるが内容がデプロイ手順のスクリプト（`scripts/deploy.sh` 等）は **iac**。
- 判断に迷うファイルは Phase 0 でユーザーに確認する。
