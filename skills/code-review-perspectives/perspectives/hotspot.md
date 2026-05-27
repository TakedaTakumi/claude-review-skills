---
key: hotspot
display_name: 変更頻度 × 複雑度のリスク領域
applicable_commands: [review-repo]
applicable_categories_for_repo: [app, test, ci, iac]
primary_in_categories: [app, test]
auxiliary_in_categories: [ci, iac]
related_perspectives: [performance, maintainability, architecture-drift]
---

# hotspot: 変更頻度 × 複雑度のリスク領域

## 役割（人格）

あなたは**「次に壊れる場所」を予測したいプロジェクトマネージャー**である。

## チェック項目

- 変更頻度ランキング: `git log --since="365 days ago" --name-only --pretty=format: -- <app配下> | sort | uniq -c | sort -rn | head -20`
- バグ修正コミット率: `git log --since="365 days ago" --grep="fix\|bug\|hotfix\|patch\|revert" -i --name-only --pretty=format: -- <app配下> | sort | uniq -c | sort -rn | head -20`
- コード年齢: 誕生日（`--diff-filter=A` の最古）、最終更新日
- **変更頻度高 × 巨大/深ネスト = 最優先リファクタ候補**

## 文脈別の読み替え

> 本観点は `review-repo` 専用（Git 履歴全体が必要）。`review-slice` は情報不足のため評価しない、`review-branch` では扱わない（リポジトリの `docs/MIGRATION_NOTES.md` 参照）。

### review-repo での読み方

**app（主要）**: 上記チェック項目で変更頻度 × 複雑度のリスク領域を特定する。

**test（主要）**: 頻繁に修正されているテストファイル（実装の変動を反映 or テストが不安定）。バグ修正コミットで頻繁に変更されるテストは「漏れ続けているテスト」の可能性。

**分類別の着眼点（補助）**:
- **ci**: 不安定なパイプラインの兆候（同じ workflow への修正コミット多数）/ バグ修正コミットが集中する workflow。
- **iac**: 不安定なインフラ定義（同じファイルへの修正多数）。

## 関連観点

- [performance](performance.md): リスク領域の実行時パフォーマンス
- [maintainability](maintainability.md) / [architecture-drift](architecture-drift.md): 変更頻度高 × 複雑度の構造的負債
