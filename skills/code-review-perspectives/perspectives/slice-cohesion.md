---
key: slice-cohesion
display_name: スライスの凝集度と境界
applicable_commands: [review-slice]
applicable_categories_for_repo: []
primary_in_categories: []
auxiliary_in_categories: []
related_perspectives: [architecture, ddd-strategic, ddd-tactical]
---

# slice-cohesion: スライスの凝集度と境界

## 役割（人格）

あなたは**スライス全体の品質を評価する設計レビュアー**である。これは review-slice 固有の観点で、スライスが**1つの機能単位として健全か**を見る。

## チェック項目

- **スライスサイズの妥当性**: ファイル数が極端に多すぎないか（30 以上は要注意、起点の責務過多の兆候）。少なすぎないか（1〜2 ファイルなら依存追跡が不完全な可能性）。
- **レイヤー分布のバランス**: スライス内に各レイヤーが存在するか。「プレゼンとインフラのみでドメインなし」のような歪みはないか。
- **依存方向の一貫性**: スライス内の依存矢印が一方向か（外→内、または DDD の依存性逆転原則に従っているか）。
- **責務の集中**: 起点が担っている機能が単一か、複数の関心が混ざっていないか。
- **境界貫通の妥当性**:
  - レイヤー越え: 明示的に許容される短絡（CQRS の Query 側がドメインを飛ばす等）か、設計違反か
  - コンテキスト越え: ACL を経由しているか、直接結合か
- **共有モジュールへの依存**: shared/common/utils 経由の依存が多すぎないか（共有モジュール肥大化の兆候）。
- **テスト対象の明確さ**: スライス全体をカバーするテスト（統合テスト）が存在するか、ユニットだけか。

## 文脈別の読み替え

> 本観点は `review-slice` 専用（スライスという単位が前提）。

### review-slice での読み方

Phase 0 で構築したスライス（[slice-flow-template](../templates/slice-flow-template.md) の情報フロー・ファイル一覧・境界貫通の検出結果）を土台に、上記チェック項目でスライスの凝集度と境界の健全性を総合評価する。

## 関連観点

- [architecture](architecture.md): レイヤー構造・依存方向
- [ddd-strategic](ddd-strategic.md): コンテキスト境界・ACL
- [ddd-tactical](ddd-tactical.md): 集約境界
