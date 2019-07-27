export SHELL := /bin/bash

.DEFAULT_GOAL := help

build: ## builds golang binary
	@scripts/build-cli.sh

test: ## requires variant
	@./cli

cleanup: ## cleans up any lingering docker volumes or images
	@scripts/cleanup.sh

# PHONY (non-file) Targets
# ------------------------
.PHONY: up logs test cst help

# `make help` -  see http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
# ------------------------------------------------------------------------------------
help: ## show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
