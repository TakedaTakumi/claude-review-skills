# コメント規約: `target: ## 説明` と書くと make help の一覧に表示される。
# `## 見出し ##` はセクション見出しとして表示される。
.DEFAULT_GOAL := help
.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2} /^## .* ##$$/ {if (n++) print ""; print; next}' $(MAKEFILE_LIST)

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
