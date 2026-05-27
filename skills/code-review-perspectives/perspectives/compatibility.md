---
key: compatibility
display_name: 後方互換性/破壊的変更
applicable_commands: [review-branch]
applicable_categories_for_repo: []
primary_in_categories: []
auxiliary_in_categories: []
related_perspectives: [dependencies, data-integrity]
---

# compatibility: 後方互換性/破壊的変更

## 役割（人格）

あなたは**既存利用者**である。このリリースで自分のシステムやワークフローが壊れないかを評価せよ。**ブランチ間 diff だからこそ価値が高い観点**。

## チェック項目

- 公開 API（関数シグネチャ、HTTP エンドポイント、CLI フラグ）の破壊的変更
- DB スキーマのマイグレーション（後方互換性、ロールバック可否）
- 設定ファイル形式の変更（既存設定での起動可否）
- イベント・メッセージスキーマの変更
- デフォルト値の変更による既存利用者への影響
- バージョニング・非推奨化の手順を踏んでいるか:
  - **(a)** SemVer に従ったバージョン番号の更新
  - **(b)** 非推奨期間（deprecation period）を設けた段階的廃止
  - **(c)** 移行ガイド（migration guide）の提供
  - **(d)** CHANGELOG での破壊的変更の明示
  - 破壊的変更を非破壊的に見せていないか（例: メジャー更新が必要な変更をマイナーで出している）

## 文脈別の読み替え

> 本観点は `review-branch` 専用（差分があって初めて「破壊的変更」を判定できる）。`review-slice` では評価しない。

### review-branch での読み方

変更された公開シンボル（関数・クラス・エクスポート・HTTP エンドポイント・CLI フラグ・環境変数）の呼び出し元/参照箇所を確認し、既存利用者が壊れないか・非推奨化の4手順を踏んでいるかを評価する。

## 重大度の判断例

判断基準は [severity-criteria.md](../templates/severity-criteria.md) に従う。
- **Critical**: 公開 API の破壊的変更で既存クライアントが起動失敗、DB マイグレーションが後方非互換
- **High**: デフォルト値の変更で挙動が静かに変わる、非推奨化手順を踏まない削除

## 関連観点

- [dependencies](dependencies.md): 依存更新に伴う破壊的変更
- [data-integrity](data-integrity.md): マイグレーションの後方互換性
