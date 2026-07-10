#!/usr/bin/env bash
#
# bootstrap.sh — git clone せずに claude-review-skills を ~/.claude/ 配下に配置する。
#
# GitHub の tarball API でリポジトリを取得し、一時ディレクトリに展開した上で
# install.sh をコピーモードで実行する。一時環境（clone せずワンライナーで
# 導入したい場合）向け。
#
# Usage:
#   ./bootstrap.sh            # コピーで配置
#   ./bootstrap.sh --force    # 本ツール由来でない同名エントリも確認なしで上書き
#   CLAUDE_DIR=/path ./bootstrap.sh   # 配置先を上書き
#
# 前提: gh コマンドがインストール済みかつ認証済みであること。
#
set -euo pipefail

REPO="${BOOTSTRAP_REPO:-TakedaTakumi/claude-review-skills}"

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh コマンドが見つかりません。https://cli.github.com/ からインストールしてください" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "error: gh が認証されていません。'gh auth login' を実行してください" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TMP_DIR"' EXIT

gh api "repos/$REPO/tarball" | tar xzf - -C "$TMP_DIR" --strip-components=1

bash "$TMP_DIR/install.sh" --copy "$@"
