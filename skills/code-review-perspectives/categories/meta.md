---
key: meta
display_name: リポジトリメタ
typical_paths:
  - README*
  - LICENSE*
  - .gitignore
  - .gitattributes
  - CONTRIBUTING*
  - SECURITY*
  - CODE_OF_CONDUCT*
  - CHANGELOG*
  - ADR・各種ドキュメント
applicable_perspectives:
  primary: [governance, documentation, security]
  auxiliary: [supply-chain-attack, ddd-strategic, dead-code]
---

# meta: リポジトリメタ

## 本質

リポジトリの「自己説明能力」と「運営の健全性」。OSS なら特に重要、社内プロジェクトでも長期保守性に直結。

## 適用観点

**主要（✅）**: governance（運営の健全性・公開度依存）, documentation（ドキュメント健全性）, security（メタファイル経由のシークレット漏洩）
**補助（⚠️）**: supply-chain-attack（README の危険コマンド・隠し実装ファイル）, ddd-strategic（ADR・コンテキストマップ・用語集の整備）, dead-code（リンク切れ・存在しないファイルへの言及）

## 境界事例の判断ルール

- `docs/` 配下のコードサンプルは **meta**（実行コードではなくドキュメントの一部として）。
- ADR（`docs/adr/`）・アーキテクチャ図は meta だが、内容は ddd-strategic / documentation と相互参照。
- 判断に迷うファイルは Phase 0 でユーザーに確認する。
