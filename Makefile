SHELL := /bin/bash
.SILENT:
.ONESHELL:
.DEFAULT_GOAL := help

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

JQ           := jq
BATS         := bats
SHELLCHECK   := shellcheck

TEST_DIR     := test

HOOKS_SCRIPTS := hooks/scripts

VERSION := $(shell $(JQ) -r .version plugin.json 2>/dev/null || echo "unknown")

#------------------------------------------------------------------------------
# Phony Targets Declaration
#------------------------------------------------------------------------------

.PHONY: help sync fmt lint typecheck check qa clean
.PHONY: test copilot-cli.test banner.test publish

#------------------------------------------------------------------------------
# High-Level Targets
#------------------------------------------------------------------------------

check: fmt lint
qa: check test
test: copilot-cli.test banner.test

#------------------------------------------------------------------------------
# Setup
#------------------------------------------------------------------------------

sync:
	which $(BATS)       >/dev/null 2>&1 || brew install bats-core
	which $(SHELLCHECK) >/dev/null 2>&1 || brew install shellcheck
	which $(JQ)         >/dev/null 2>&1 || brew install jq

#------------------------------------------------------------------------------
# Code Quality
#------------------------------------------------------------------------------

fmt:
	which shfmt >/dev/null 2>&1 && shfmt -w -i 2 $(HOOKS_SCRIPTS)/ skills/banner/banner.sh || true

lint:
	$(SHELLCHECK) $(HOOKS_SCRIPTS)/*.sh skills/banner/banner.sh

typecheck:
	true

#------------------------------------------------------------------------------
# Testing
#------------------------------------------------------------------------------

copilot-cli.test:
	$(BATS) $(TEST_DIR)/copilot-cli/hooks.bats $(TEST_DIR)/copilot-cli/hooks_e2e.bats $(TEST_DIR)/copilot-cli/plugin_integrity.bats

banner.test:
	$(BATS) $(TEST_DIR)/copilot-cli/banner.bats

#------------------------------------------------------------------------------
# Build & Publish
#------------------------------------------------------------------------------

publish:
	gh release create "v$(VERSION)" \
	  --title "v$(VERSION)" \
	  --notes-file CHANGELOG.md \
	  --latest
	printf "Released v%s\n" "$(VERSION)"

#------------------------------------------------------------------------------
# Cleanup
#------------------------------------------------------------------------------

clean:
	rm -rf hooks/logs/

#------------------------------------------------------------------------------
# Help
#------------------------------------------------------------------------------

help:
	printf "\033[36m"
	printf "╔═╗╔═╗╔═╗╔╗╔╔╦╗   ╔═╗╦  ╦ ╦╔═╗ ╦ ╔╗╔   ╔╦╗╔═╗╦╔ ╔═╗╔═╗ ╦ ╦  ╔═╗\n"
	printf "╠═╣║╠╗║╣ ║║║ ║    ╠═╝║  ║ ║║╠╗ ║ ║║║   ║║║╠═╣╠╩╗║╣ ╠╣  ║ ║  ║╣ \n"
	printf "╝ ╝╚═╝╚═╝╝╚╝ ╝    ╝  ╩═╝╚═╝╚═╝ ╩ ╝╚╝   ╝ ╝╝ ╝╝ ╝╚═╝╚   ╩ ╩═╝╚═╝\n"
	printf "\033[0m\n"
	printf "Usage: make [target]\n\n"
	printf "\033[1;35mSetup:\033[0m\n"
	printf "  sync              - Install required tools (bats, shellcheck, jq)\n"
	printf "\n"
	printf "\033[1;35mDev:\033[0m\n"
	printf "  fmt               - Format scripts with shfmt\n"
	printf "  lint              - Lint scripts with shellcheck\n"
	printf "  check             - fmt + lint\n"
	printf "  qa                - check + test (quality gate)\n"
	printf "\n"
	printf "\033[1;35mTest:\033[0m\n"
	printf "  test              - Run all tests\n"
	printf "  copilot-cli.test  - Run hook and integrity tests (bats)\n"
	printf "  banner.test       - Run banner.sh unit tests (bats)\n"
	printf "\n"
	printf "\033[1;35mRelease:\033[0m\n"
	printf "  publish           - Create GitHub Release (v%s)\n" "$(VERSION)"
	printf "\n"
	printf "\033[1;35mClean:\033[0m\n"
	printf "  clean             - Remove log artifacts\n"
