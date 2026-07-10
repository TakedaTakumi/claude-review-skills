.DEFAULT_GOAL := help
.PHONY: help
help:
	@grep -E -e '^[a-zA-Z_-]+:.*?## .*$$' -e '^## .* ##$$' $(MAKEFILE_LIST) \
		| ./tools/help.awk | less -R

.PHONY: install install-copy install-force install-copy-force

## スキルをインストールする ##
install: ## ~/.claude/ に symlink で配置（リポジトリ更新が即反映）
	bash ./install.sh

install-copy: ## コピーで配置
	bash ./install.sh --copy

install-force: ## 本ツール由来でない同名エントリも確認なしで上書き
	bash ./install.sh --force

install-copy-force: ## コピーで配置かつ本ツール由来でない同名エントリも確認なしで上書き
	bash ./install.sh --copy --force
