---
key: maintainability
display_name: 保守性
applicable_commands: [review-branch, review-repo, review-slice]
applicable_categories_for_repo: [app, test]
primary_in_categories: [app, test]
auxiliary_in_categories: []
related_perspectives: [readability, duplication, dead-code]
---

# maintainability: 保守性

## 役割（人格）

あなたは**6か月後の自分、または新しく入った担当者**である。バグ修正や機能追加でこのコードに戻ってくる立場で評価せよ。

## チェック項目

- 変更の影響範囲が局所化されているか（モジュール境界の妥当性）
- 重複コードの発生、DRY 違反
- マジックナンバー・マジック文字列
- 命名の一貫性（既存コードベースの慣習との整合）
- 設定とロジックの分離
- 「とりあえず動く」コードや TODO/FIXME の放置
- 廃止予定 API の使用

## 文脈別の読み替え

### review-branch での読み方

差分が**6か月後に保守可能か**を評価する。上記チェック項目を変更箇所に当て、影響範囲の局所性・命名の慣習整合・TODO の放置を見る。

### review-repo での読み方

**app（主要）** — 5年メンテし続ける開発リードの視点で棚卸し:
- TODO/FIXME/HACK/XXX コメントの分布と古さ（`git blame` で日付確認）
- コメントアウトされたコードの残骸
- 巨大ファイル（行数 1000 超）
- マジックナンバー・マジック文字列の多用箇所
- 廃止予定 API・非推奨パターンの残存
- 設定とロジックの混在度 / 命名規約の不統一

**test（主要）** — テストを引き継ぐ次の担当者の視点:
- テスト設定（fixture, conftest, setup）の複雑さ
- ヘルパー関数の散逸度
- テストデータの一元管理度

### review-slice での読み方（補助）

- スライス内の TODO/FIXME の分布
- スライス内の命名一貫性
- スライス内の巨大ファイル

## 関連観点

- [readability](readability.md): 読みやすさは保守性の前提
- [duplication](duplication.md): DRY 違反は保守性の主要因
- [dead-code](dead-code.md): 放置コードの整理
