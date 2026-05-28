# Changelog

このリポジトリの注目すべき変更を [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) 形式で記録します。
バージョン番号は [Semantic Versioning](https://semver.org/lang/ja/) に従います。

## [Unreleased]

### Added

- `SECURITY.md` — 脆弱性報告チャネル（GitHub Security Advisories）を明示
- `CHANGELOG.md` — 本ファイル
- `docs/MAINTAINER_NOTES.md` — 観点・分類・Agent 追加時の同期チェックリスト（メンテナー向け）

### Changed

- 公開スタンスを **Personal Public**（個人ツール／PR 受け付けなし）として README に明示
- `README.md`: インストール要件として Claude Code（動作確認 2.1.150）と bash 4+ を明示
- `README.md`: MIGRATION_PLAN.md の紹介文を「21観点ベースの旧計画書／現32観点」に補注
- `MIGRATION_PLAN.md`: 冒頭に「移行時点の 21観点ベース、最新は SKILL.md / docs/PERSPECTIVES.md 参照」の警告ボックスを追加

### Fixed

- `install.sh`: `CLAUDE_DIR` が空文字列・ルート (`/`)・末尾スラッシュ付きパスでも安全に動作するよう入力検証を追加（特に `CLAUDE_DIR="/"` で `rm -rf` が予期せぬパスを対象にしうる経路を遮断）

### Security

- `.gitignore`: シークレットファイルパターン（`.env*`・`*.pem`・`*.key`・`id_rsa*` 等）を予防的に除外

## [0.1.0] - 2026-05-28

Code Review Skills 移行（Phase 1〜8）の完了スナップショット。3つのスラッシュコマンドを **Skill（観点ライブラリ）+ Sub Agent + 軽量 Slash Command** の組み合わせに再構築。

### Added

- **Skill** `skills/code-review-perspectives/`
  - `SKILL.md`: 32観点・8分類・テンプレートのカタログ（段階的開示の起点）
  - `perspectives/` 32 ファイル: 各観点ごとに役割・チェック項目・文脈別の読み替え・重大度判断例
  - `categories/` 8 ファイル: app / test / build / runtime / devenv / ci / iac / meta
  - `templates/` 5 ファイル: severity-criteria / output-format / progress-log / escalation-report / slice-flow-template
- **Sub Agent** `agents/` 11 ファイル: security-reviewer / quality-reviewer / architecture-reviewer / ddd-reviewer / test-reviewer / performance-reviewer / ops-reviewer / dependencies-reviewer / meta-reviewer / ownership-reviewer / slice-flow-reviewer
- **Slash Command** `commands/` 3 ファイル: review-branch / review-repo / review-slice（各 100 行以下の薄いオーケストレータ）
- **install.sh**: `~/.claude/` への symlink 配置（コピーフォールバック・本ツール由来でない同名エントリへのガードあり）
- **docs/**: ARCHITECTURE / USAGE / PERSPECTIVES / CATEGORIES / MIGRATION_NOTES、`docs/legacy/` に移行元（旧 spec、凍結）

### Notes

旧スラッシュコマンド3個（`docs/legacy/`）から、本リポジトリ構成への再構築は [issue #1](https://github.com/TakedaTakumi/claude-review-skills/issues/1) と [MIGRATION_PLAN.md](MIGRATION_PLAN.md) を参照。
旧 review-branch の統合観点 `infrastructure` は、`runtime-config` / `devenv-quality` / `ci-quality` / `iac-quality` の4観点へ分解（一部 `data-integrity` へ）。差異は [docs/MIGRATION_NOTES.md](docs/MIGRATION_NOTES.md) に記録。

[Unreleased]: https://github.com/TakedaTakumi/claude-review-skills/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/TakedaTakumi/claude-review-skills/releases/tag/v0.1.0
