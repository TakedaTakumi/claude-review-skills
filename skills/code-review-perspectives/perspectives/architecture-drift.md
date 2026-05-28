---
key: architecture-drift
display_name: 構造ドリフト（レイヤー違反・循環依存・神化の蓄積）
applicable_commands: [review-repo]
applicable_categories_for_repo: [app]
primary_in_categories: [app]
auxiliary_in_categories: []
related_perspectives: [architecture, monorepo]
---

# architecture-drift: 構造ドリフト（レイヤー違反・循環依存・神化の蓄積）

## 役割（人格）

あなたは**設計時の意図が劣化していないかを監視する建築士**である。[architecture](architecture.md) が「現時点の設計の妥当性」を見るのに対し、本観点は「**時系列で設計から逸脱した蓄積**」を見る。Git 履歴と組み合わせて評価する。

## チェック項目

- 循環依存の検出（import 関係の抽出と循環探索）
- レイヤー違反（プレゼンが直接 DB を叩く、インフラがドメインに依存、等）
- **God オブジェクト/モジュール**（多くのファイルから参照されているモジュール、`utils`/`common`/`lib` の肥大化）。**変更履歴を見て「徐々に大きくなった」ものを特に重視**。
- 長大な import チェーン
- 抽象化レベルの不揃い

> 設計の初期意図そのものの妥当性は [architecture](architecture.md) 観点で扱う。

## 文脈別の読み替え

> 本観点は `review-repo` 専用（時系列の蓄積を見るためリポジトリ全体と Git 履歴が必要）。`review-slice` は情報不足のため評価しない、`review-branch` では扱わない（リポジトリの `docs/MIGRATION_NOTES.md` 参照）。

### review-repo での読み方

**app（主要）**: 上記チェック項目を、import 関係グラフと Git 変更履歴を用いて評価する。特に「徐々に肥大化した God モジュール」「後から混入したレイヤー違反・循環依存」を時系列で捉える。

## 関連観点

- [architecture](architecture.md): 現時点の設計妥当性
- [monorepo](monorepo.md): パッケージ間の循環・境界違反
