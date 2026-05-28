---
key: iac
display_name: デプロイ・IaC
typical_paths:
  - terraform/
  - pulumi/
  - cloudformation/
  - k8s/
  - ansible/
  - helm/
  - Tiltfile
  - deploy/
  - scripts/deploy/
applicable_perspectives:
  primary: [iac-quality, security]
  auxiliary: [supply-chain-attack, data-integrity, observability, hotspot, dead-code, duplication, performance]
---

# iac: デプロイ・IaC

## 本質

本番環境定義の正しさ、ドリフト管理、最小権限、デプロイ事故の予防。
Terraform、Kubernetes マニフェスト、Helm チャート、Ansible Playbook 等のインフラ定義。**全ファイル詳読**を基本とし、規模が大きい場合はサンプリング。

## 適用観点

**主要（✅）**: iac-quality（IaC・デプロイの品質）, security（インフラ侵害対策）
**補助（⚠️）**: supply-chain-attack（外部 module/Chart 経由の混入）, data-integrity（マイグレーション・バックアップの IaC 制御）, observability（インフラ可観測性）, hotspot（頻繁に修正される IaC）, dead-code（未適用 module）, duplication（resource 定義の散在）, performance（リソース効率）

## 境界事例の判断ルール

- Kubernetes マニフェストが `helm/` / `k8s/` 配下にあれば **iac**。Helm チャートのメタ情報（`Chart.yaml`）も **iac**。
- `Tiltfile` / `skaffold.yaml`（開発時クラスタオーケストレーション）は **iac**。
- CI から呼ばれるが内容がデプロイ手順のスクリプト（`scripts/deploy.sh` 等）は **iac**。
- 判断に迷うファイルは Phase 0 でユーザーに確認する。
