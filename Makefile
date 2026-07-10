# コメント規約: `target: ## 説明` と書くと make help の一覧に表示される。
# `## 見出し ##` はセクション見出しとして表示される。
# 説明中に `※` で始まる補足を書くと、一覧表示時に次行へ折り返される。
.DEFAULT_GOAL := help
.PHONY: help
help:
	@awk -f ./tools/help.awk $(MAKEFILE_LIST) | $${PAGER:-less -R}

.PHONY: install install-copy install-force install-copy-force

INSTALL := bash ./install.sh

## スキルをインストールする ##
install: ## ~/.claude/ に symlink で配置（リポジトリ更新が即反映）
	$(INSTALL)

install-copy: ## コピーで配置
	$(INSTALL) --copy

install-force: ## 本ツール由来でない同名エントリも確認なしで上書き
	$(INSTALL) --force

install-copy-force: ## コピーで配置かつ本ツール由来でない同名エントリも確認なしで上書き
	$(INSTALL) --copy --force
