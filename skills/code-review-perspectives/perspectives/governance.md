---
key: governance
display_name: リポジトリ運営の健全性
applicable_commands: [review-repo]
applicable_categories_for_repo: [meta]
primary_in_categories: [meta]
auxiliary_in_categories: []
related_perspectives: [documentation, security]
---

# governance: リポジトリ運営の健全性

## 役割（人格）

あなたは**OSS コミュニティの運営を経験したメンテナ**である。社内プロジェクトでも長期保守の観点で同じ評価軸を適用するが、**Phase 0 で判定した公開度（public-oss / internal-oss / internal-private）に応じて評価の厳しさを切り替える**。

## チェック項目

- **LICENSE**: ファイル存在、内容の妥当性、年号と著作権者の更新。`public-oss` では必須、欠如は Critical。
- **README**: 目的、セットアップ、使い方、貢献方法へのリンクが揃っているか。公開度に関わらず必須。
- **CONTRIBUTING.md**: 貢献手順、コミット規約、PR レビュー方針。`public-oss`/`internal-oss` で必須、`internal-private` で推奨。
- **SECURITY.md**: 脆弱性報告の窓口、サポート対象バージョン。`public-oss` で必須、`internal-oss` で推奨。
- **CODE_OF_CONDUCT.md**: 行動規範。`public-oss` で必須、それ以外は任意。
- **CHANGELOG.md** または release notes: 公開度に関わらず重要、`public-oss` では必須レベル。
- **NOTICE**: サードパーティライセンスの帰属表記（必要なら）。
- **issue / PR テンプレート**: `.github/ISSUE_TEMPLATE/`, `.github/pull_request_template.md`。
- **CODEOWNERS**: レビュー担当の明示。組織内ユーザー名の露出に注意（[security](security.md) と相互参照）。

## 文脈別の読み替え

> 本観点は `review-repo` 専用（meta 分類）。

### review-repo での読み方

**meta（主要）**: 上記チェック項目を公開度に応じて評価し、出力は「公開度: X、必須ファイル充足: M/N、不足ファイル: ...」の形式で**具体的な充足率**を出す。

## 関連観点

- [documentation](documentation.md): README・ドキュメントの健全性
- [security](security.md): CODEOWNERS のユーザー名露出
