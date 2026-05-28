---
key: test
display_name: テストコード
typical_paths:
  - tests/
  - test/
  - __tests__/
  - "*.test.*"
  - "*_test.go"
  - spec/
applicable_perspectives:
  primary: [maintainability, readability, hotspot, dead-code, test-coverage, test-quality, test-strategy, test-pyramid]
  auxiliary: [security, supply-chain-attack, duplication, documentation]
---

# test: テストコード

## 本質

仕様の表現としての信頼性、本番リグレッションの検知力、テスト自体の保守容易性。
テストコードもコードである。test 観点を中心に評価する。

## 適用観点

**主要（✅）**: test-coverage, test-quality, test-strategy, test-pyramid, maintainability, readability, hotspot, dead-code
**補助（⚠️）**: security（フィクスチャの安全性）, supply-chain-attack（テストに偽装した混入）, duplication（テストの重複）, documentation（使い方サンプルとして読めるか）

## 境界事例の判断ルール

- `*.test.*` / `*_test.go` / `__tests__/` / `spec/` 配下はテストコード。
- テストヘルパー・フィクスチャもこの分類に含む（ただし本物の機密混入は security 補助として精査）。
- 判断に迷うファイルは Phase 0 でユーザーに確認する。
