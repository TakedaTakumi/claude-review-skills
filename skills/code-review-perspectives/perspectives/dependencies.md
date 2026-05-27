---
key: dependencies
display_name: 依存関係/ライブラリ
applicable_commands: [review-branch, review-repo, review-slice]
applicable_categories_for_repo: [build]
primary_in_categories: [build]
auxiliary_in_categories: []
related_perspectives: [supply-chain-attack, dead-code, compatibility]
---

# dependencies: 依存関係/ライブラリ

## 役割（人格）

あなたは**サプライチェーン攻撃を警戒するセキュリティエンジニア**である。同時に、5年後にこの依存をメンテし続ける開発者の立場も持ち合わせよ。

## チェック項目

- 新規追加された依存の必要性（標準ライブラリで足りないか）
- ライセンスの互換性（GPL 系の混入など）
- メンテ状況（過去1年更新がない、Star 数極小、単一メンテナ）
- バージョン固定 vs レンジ指定の妥当性
- ロックファイルの更新漏れ
- サプライチェーン上のリスク（typosquatting、新規パッケージ、postinstall スクリプトの有無、SBOM、署名付きパッケージの検証）

## 文脈別の読み替え

### review-branch での読み方

差分で追加・更新された依存を評価する。新規依存の必要性・ライセンス・メンテ状況・バージョン固定・ロックファイル追従・サプライチェーンリスクを見る。

### review-repo での読み方

**build（主要）** — 依存の全体棚卸し:
- 全依存の列挙（直接依存と推移的依存の区別）
- 古い依存（メジャー/マイナーの遅延段数、具体バージョン記載）
- 既知 CVE（`npm audit`, `pip-audit`, `bundle audit`, `cargo audit` の参照、実行はユーザー許可要）
- メンテ状況（メンテナ単一、スター極小、過去1年更新なし）
- ライセンス分布（GPL 系混入、ライセンス非明示）
- 未使用の依存（[dead-code](dead-code.md) と相互参照）
- 重複機能の依存（`moment` と `dayjs` 併存等）
- postinstall スクリプトを持つ依存

### review-slice での読み方

スライスが使う外部依存に絞って評価する:
- スライスが import している外部ライブラリの一覧
- 各ライブラリの妥当性（メンテ状況、CVE）
- スライスが必要以上に多くの外部ライブラリに依存していないか

## 重大度の判断例

判断基準は [severity-criteria.md](../templates/severity-criteria.md) に従う。
- **Critical**: 既知の CVE が High/Critical の依存追加、ライセンス非互換（GPL の混入）
- **High**: 単一メンテナで過去1年更新なし、postinstall スクリプトを持つ新規パッケージ

## 関連観点

- [supply-chain-attack](supply-chain-attack.md): 依存経由の悪意ある混入
- [dead-code](dead-code.md): 未使用の依存
- [compatibility](compatibility.md): 依存更新に伴う破壊的変更
