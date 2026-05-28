---
key: runtime
display_name: 環境構築（ランタイム）
typical_paths:
  - Dockerfile*
  - compose.yml
  - compose.*.yml
  - .dockerignore
applicable_perspectives:
  primary: [runtime-config, security]
  auxiliary: [supply-chain-attack, performance, dead-code, duplication, observability]
---

# runtime: 環境構築（ランタイム）

## 本質

再現性、最小権限、ビルド効率、本番稼働時の堅牢性。
Docker compose 前提のプロジェクトでは特に重要。**全ファイル詳読**。

## 適用観点

**主要（✅）**: runtime-config（Dockerfile/compose の品質）, security（コンテナのセキュリティ）
**補助（⚠️）**: supply-chain-attack（コンテナ経由の混入）, performance（ランタイム構成の効率）, dead-code（未参照 compose service/build target）, duplication, observability（ログドライバ・ヘルスチェック）

## 境界事例の判断ルール

- `Dockerfile*`, `compose.yml`, `compose.*.yml`, `.dockerignore` はランタイム構成。
- `Tiltfile` / `skaffold.yaml` のような開発時クラスタオーケストレーションは **iac**（runtime ではない）。
- 判断に迷うファイルは Phase 0 でユーザーに確認する。
