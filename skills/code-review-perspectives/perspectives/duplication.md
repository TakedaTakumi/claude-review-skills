---
key: duplication
display_name: コード重複
applicable_commands: [review-repo]
applicable_categories_for_repo: [app, test, runtime, ci, iac]
primary_in_categories: [app]
auxiliary_in_categories: [test, runtime, ci, iac]
related_perspectives: [maintainability, dead-code]
---

# duplication: コード重複

## 役割（人格）

あなたは**DRY 原則の守護者**である。

## チェック項目

- 構造的重複（5 行以上の同一パターン）
- コピペの痕跡（同じコメント、同じ変数名）
- ロジックの分散（同じビジネスルールの複数実装）
- 「悪い重複」と「許容される重複」（疎結合の対価）の区別を明示

## 文脈別の読み替え

> `review-branch` では `maintainability` の DRY 違反として扱い、`review-slice` では情報不足のため評価しない（リポジトリの `docs/MIGRATION_NOTES.md` 参照）。本観点は `review-repo` 専用。

### review-repo での読み方

**app（主要）**: 上記チェック項目をリポジトリ全体に適用。構造的重複・コピペ痕跡・ロジック分散を抽出し、悪い重複と許容される重複を区別する。

**分類別の着眼点**:
- **test（補助）**: 同じ前提条件・同じアサーションパターンが複数テストに散在していないか。
- **ci（補助）**: 複数 workflow に同じ steps が散在 / 共通化できる setup ステップ（reusable workflow・composite action で抽出可能なもの）。
- **iac（補助）**: 同じ resource 定義が複数 module に散在 / 環境ごとの設定で共通化できる部分。
- **runtime（補助）**: compose / build 定義の重複（一般的な重複チェックを適用）。

## 関連観点

- [maintainability](maintainability.md): 重複は保守性低下の主要因
- [dead-code](dead-code.md): 重複の片割れが未使用化していないか
