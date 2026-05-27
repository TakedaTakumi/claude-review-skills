#!/usr/bin/env bash
#
# install.sh — claude-review-skills を ~/.claude/ 配下に配置する。
#
# 既定は symlink 配置（リポジトリの更新が即反映される）。
# symlink が使えない環境（Windows のジャンクション制約など）では
# 自動的にコピーへフォールバックする。明示的にコピーしたい場合は --copy。
#
# Usage:
#   ./install.sh            # symlink で配置（失敗時はコピー）
#   ./install.sh --copy     # 強制的にコピーで配置
#   CLAUDE_DIR=/path ./install.sh   # 配置先を上書き
#
set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="symlink"

for arg in "$@"; do
  case "$arg" in
    --copy) MODE="copy" ;;
    --symlink) MODE="symlink" ;;
    -h|--help)
      echo "Usage: ./install.sh [--symlink|--copy]"
      echo "  --symlink  (default) シンボリックリンクで配置"
      echo "  --copy     コピーで配置"
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands"

# 1 エントリ（ファイル or ディレクトリ）を symlink、失敗時はコピーで配置する。
link_or_copy() {
  local src="$1" dest="$2"
  if [ "$MODE" = "symlink" ]; then
    if ln -sfn "$src" "$dest" 2>/dev/null; then
      return 0
    fi
    echo "warn: symlink に失敗したためコピーにフォールバック: $dest" >&2
  fi
  rm -rf "$dest"
  cp -R "$src" "$dest"
}

# Skill（ディレクトリごと）
link_or_copy "$SCRIPT_DIR/skills/code-review-perspectives" "$CLAUDE_DIR/skills/code-review-perspectives"

# Sub Agent（*.md を個別配置）
for f in "$SCRIPT_DIR/agents"/*.md; do
  [ -e "$f" ] || continue
  link_or_copy "$f" "$CLAUDE_DIR/agents/$(basename "$f")"
done

# Slash Command（*.md を個別配置）
for f in "$SCRIPT_DIR/commands"/*.md; do
  [ -e "$f" ] || continue
  link_or_copy "$f" "$CLAUDE_DIR/commands/$(basename "$f")"
done

echo "Installed to $CLAUDE_DIR (mode: $MODE)"
