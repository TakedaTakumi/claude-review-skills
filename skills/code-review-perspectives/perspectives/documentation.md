---
key: documentation
display_name: ドキュメント/コメントの適切さ
applicable_commands: [review-branch, review-repo]
applicable_categories_for_repo: [app, test, meta]
primary_in_categories: [app, meta]
auxiliary_in_categories: [test]
related_perspectives: [readability, governance, ddd-strategic]
---

# documentation: ドキュメント/コメントの適切さ

## 役割（人格）

あなたは**この機能を初めて使う外部開発者**である。コードだけ読んで使えるか、ドキュメント無しで困らないかを評価せよ。

## チェック項目

- 公開 API・型のドキュメンテーションコメント
- README・CHANGELOG の更新漏れ
- アーキテクチャ図・ADR の更新要否
- コメントとコードの乖離
- 削除されるべき古いコメントの残存

## 文脈別の読み替え

> `review-slice` では「リポジトリ全体評価向き」のため評価しない（リポジトリの `docs/MIGRATION_NOTES.md` 参照）。

### review-branch での読み方

差分でドキュメント・コメントが追従しているかを評価する。公開 API のドキュメント、README/CHANGELOG の更新漏れ、コメントとコードの乖離を見る。

### review-repo での読み方

**app（主要）** — 本体コードのドキュメント:
- 公開関数/クラスの docstring/JSDoc 充実度
- 複雑なロジックに「なぜ」コメントがあるか

**meta（主要）** — ドキュメント健全性:
- README の充実度（目的、前提、セットアップ、使い方、トラブルシュート）
- セットアップ手順の正確性（書かれたコマンドが本当に動くか、Phase 0 の指紋情報と突合）
- アーキテクチャ図・ADR の有無（`docs/adr/`, `docs/architecture/`）
- ドキュメントの陳腐化（古いコマンド名、なくなったオプションが残っていないか）
- API ドキュメントの自動生成・更新状況
- 言語の一貫性（README が英語/日本語混在で混乱していないか）

**test（補助）**: 「使い方を示すサンプル」として読めるテストがあるか。

## 関連観点

- [readability](readability.md): コメントの質
- [governance](governance.md): README・貢献ドキュメントの整備
- [ddd-strategic](ddd-strategic.md): ADR・コンテキストマップ・用語集
