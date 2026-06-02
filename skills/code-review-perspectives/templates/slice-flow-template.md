---
name: slice-flow-template
type: template
description: review-slice で「入口（プレゼン層）→出口（インフラ層）」の情報フローと副作用・攻撃経路を記述するテンプレート。slice-flow-reviewer / security / supply-chain-attack が用いる。
---

# スライス情報フロー記述テンプレート

review-slice の強みは、起点（入口）から最深部（出口）までの**経路を追える**ことにある。security・supply-chain-attack・slice-cohesion の各観点は、この情報フローを共通の土台として評価する。

## フロー記法

レイヤーを矢印でつなぎ、注目すべき箇所に `❗` を付ける。

```
presentation → application → domain → infrastructure
                                   └ ❗ ここで外部送信 / ファイル書き込み / コマンド実行
```

## 入口→出口フロー記述

起点（presentation 層など）で受け取った情報が、どの経路を通り、最終的にどこへ出ていくかを段ごとに記述する。

```
## スライス情報フロー

### 入口
- 起点: src/api/order_controller.py（presentation）
- 受け取る情報: 注文リクエスト（user_id, items, payment_token）

### 経路（各段の処理と外部作用）
| 深さ | パス | レイヤー | 処理 | 外部作用（送信/書込/実行） |
|---|---|---|---|---|
| 0 | order_controller.py | presentation | 入力受領・検証 | なし |
| 1 | order_service.py | application | 業務調整 | なし |
| 2 | order.py | domain | 不変条件の適用 | なし |
| 3 | order_repository_impl.py | infrastructure | 永続化 | DB 書き込み |

### 出口（副作用の棚卸し）
スライス内の各レイヤーで「外部送信」「ファイル書き込み」「コマンド実行」が起きる箇所を列挙する:
- DB 書き込み: order_repository_impl.py:88
- 外部 API 送信: （なし / あれば送信先とデータ）
- ファイル書き込み: （なし）
- コマンド実行: （なし）
```

## シンボル起点（`path::symbol`）の場合

起点がファイルではなくシンボル（関数 / クラス / `Class.method`）のとき、入口は「起点シンボル」になる。起点ファイル内は **経路上（span）** と **起点同居（span 外の同ファイルコード）** を区別して記述する。依存追跡は span 内で実際に参照される依存だけを辿る（ファイル全体の import は辿らない）。

```
## スライス情報フロー（シンボル起点）

### 入口
- 起点シンボル: OrderService.checkout（src/app/order_service.py::OrderService.checkout, application）
- 受け取る情報: 注文確定リクエスト（order_id, payment_token）
- 起点同居（span 外・参考）: 同ファイルの OrderService.cancel ほか（スライス本体＝経路上＋依存先には含めない／責務集中の判断材料）

### 経路（span 内参照のみ辿る）
| 深さ | パス | レイヤー | タグ | 処理 | 外部作用 |
|---|---|---|---|---|---|
| 0 | src/app/order_service.py::OrderService.checkout | application | 経路上 | 業務調整 | なし |
| 1 | src/infra/payment_gateway.py | infrastructure | 依存先 | 決済要求 | 外部 API 送信 |

### 出口（副作用の棚卸し）
- 外部 API 送信: src/infra/payment_gateway.py:42（決済）
```

## 攻撃経路・悪意混入の注目ポイント

フロー上で以下を確認する（security / supply-chain-attack のスライス文脈）:

- **入口での入力検証**と、**レイヤー越えで検証が抜ける箇所**。
- 出口（DB・外部 API・ファイル）への到達経路での**インジェクション可能性**。
- 認証・認可が**どのレイヤーで実施**され、漏れがないか。
- 想定外の中間処理（**ログ・通知関数の皮を被った外部送信**）が経路上にないか。
- **ハードコード IP / URL** への送信、`eval`/`exec`/`subprocess(shell=True)` 等への到達経路。
- レイヤーの責務に反する作用:「ドメイン層なのに外部 API 呼び出し」「リポジトリ実装が認証情報を外部送信」「ロガーが外部送信」。

疑いを検出したら `escalation-report.md` のスライス文脈バリアントで報告する（`情報フロー:` 行に上記フロー記法を用いる）。
