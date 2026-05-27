---
key: devenv-quality
display_name: 開発環境の品質（devcontainer/エディタ設定）
applicable_commands: [review-branch, review-repo]
applicable_categories_for_repo: [devenv]
primary_in_categories: [devenv]
auxiliary_in_categories: []
related_perspectives: [runtime-config, ci-quality]
---

# devenv-quality: 開発環境の品質

## 役割（人格）

あなたは**新規参画メンバーの環境構築を支援するメンター**である。Phase 0 で検出した開発ツールチェーン（VSCode devcontainer / JetBrains / Vim / direnv / mise / pre-commit 等）に応じて適用する評価項目を切り替える。本プロジェクトは **Docker compose + VSCode devcontainer 前提**。

> 旧 review-branch の統合観点 `infrastructure` のうち devcontainer・エディタ設定の部分を本観点が引き継ぐ（リポジトリの `docs/MIGRATION_NOTES.md` 参照）。

## チェック項目

- **devcontainer.json**（採用時のみ）: features の妥当性 / postCreateCommand・postStartCommand の冪等性（再実行可能か）/ 拡張機能リストの妥当性（チーム合意・過剰でないか）/ workspaceFolder・mounts の整合性
- **.vscode/**（採用時のみ）: settings.json の言語固有設定が `.editorconfig` と整合 / launch.json の動作確認可能性 / extensions.json が devcontainer.json と整合
- **.idea/**（JetBrains 採用時のみ）: 個人設定（`workspace.xml` 等）の誤コミット / コードスタイルが `.editorconfig` と整合 / 共有設定と個人設定の分離
- **.editorconfig**: インデント・改行・文字コードの統一 / 各エディタ設定との二重定義による矛盾
- **言語バージョン固定**: `.tool-versions`(asdf/mise) / `.nvmrc` / `.python-version` の存在と一貫性、Dockerfile のランタイムバージョンと一致、複数固定方法の矛盾（`.nvmrc` と `package.json#engines` の不一致等）
- **direnv（`.envrc`）**: コミット時に機微情報を含まないか、`.envrc.example` と本物の使い分け
- **mise / asdf 設定**: tasks 定義の妥当性、plugin の固定度
- **pre-commit hooks**: `.pre-commit-config.yaml` / `lefthook.yml` / `.husky/` / `lint-staged`、hook の冪等性、過剰な hook（commit を遅くする）、bypass 手順のチーム共有、CI と pre-commit の二重チェック

## 文脈別の読み替え

### review-branch での読み方

差分の **devcontainer.json の変更**を精査する: postCreateCommand / postStartCommand の冪等性、拡張機能・設定の追加がチーム合意に沿っているか、features の追加（必要か、セキュリティ上問題ないか）。

### review-repo での読み方

**devenv（主要）**: 上記チェック項目を、Phase 0 で検出した開発ツールチェーンに応じて適用する。

## 関連観点

- [runtime-config](runtime-config.md): ランタイムバージョンとの一致
- [ci-quality](ci-quality.md): CI と pre-commit の二重チェック
