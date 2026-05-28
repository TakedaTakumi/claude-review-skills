---
key: devenv
display_name: 開発環境
typical_paths:
  - .devcontainer/
  - .vscode/
  - .idea/
  - .editorconfig
  - .tool-versions
  - .nvmrc
  - .python-version
  - .envrc
  - mise.toml
  - .pre-commit-config.yaml
  - lefthook.yml
  - .husky/
applicable_perspectives:
  primary: [devenv-quality]
  auxiliary: [security, dead-code]
---

# devenv: 開発環境

## 本質

開発者体験、再現性、チーム間の一貫性。
VSCode devcontainer 前提のプロジェクトでは要点が明確。**全ファイル詳読**。

## 適用観点

**主要（✅）**: devenv-quality（devcontainer/エディタ設定/言語バージョン固定/pre-commit）
**補助（⚠️）**: security（開発環境のシークレット）, dead-code（未使用の推奨拡張・古い tool-versions）

## 境界事例の判断ルール

- `package.json` の `lint-staged` 設定など、開発ツール設定の部分は devenv 観点で見る（ファイル自体の分類は build）。
- 言語バージョン固定（`.tool-versions`/`.nvmrc`/`.python-version`）は devenv だが、Dockerfile のランタイムバージョンとの一致は runtime-config と連動。
- 判断に迷うファイルは Phase 0 でユーザーに確認する。
