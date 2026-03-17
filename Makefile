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
BUN          := bun

COPILOT_DIR  := copilot-cli
OPENCODE_DIR := opencode
TEST_DIR     := test

HOOKS_SCRIPTS := $(COPILOT_DIR)/hooks/scripts

# Version source of truth: opencode/package.json
VERSION := $(shell $(JQ) -r .version $(OPENCODE_DIR)/package.json 2>/dev/null || echo "unknown")

#------------------------------------------------------------------------------
# Phony Targets Declaration
#------------------------------------------------------------------------------

.PHONY: help sync fmt lint typecheck check qa clean distclean
.PHONY: test test.unit copilot-cli.test opencode.test
.PHONY: version.check publish

#------------------------------------------------------------------------------
# High-Level Targets
#------------------------------------------------------------------------------

check: fmt lint typecheck
qa: version.check check test
test: copilot-cli.test opencode.test

#------------------------------------------------------------------------------
# Setup
#------------------------------------------------------------------------------

sync:
	which $(BATS)       >/dev/null 2>&1 || brew install bats-core
	which $(SHELLCHECK) >/dev/null 2>&1 || brew install shellcheck
	which $(JQ)         >/dev/null 2>&1 || brew install jq
	which $(BUN)        >/dev/null 2>&1 || brew install bun

#------------------------------------------------------------------------------
# Code Quality
#------------------------------------------------------------------------------

fmt:
	which shfmt >/dev/null 2>&1 && shfmt -w -i 2 $(HOOKS_SCRIPTS)/ || true

lint:
	$(SHELLCHECK) $(HOOKS_SCRIPTS)/*.sh

typecheck:
	cd $(OPENCODE_DIR) && $(BUN) x tsc --noEmit 2>/dev/null || true

#------------------------------------------------------------------------------
# Version
#------------------------------------------------------------------------------

version.check:
	pkgver="$$($(JQ) -r .version $(OPENCODE_DIR)/package.json)"; \
	pjver="$$($(JQ) -r .version $(COPILOT_DIR)/plugin.json)"; \
	if [ "$$pkgver" != "$$pjver" ]; then \
	  printf "Version mismatch: %s/package.json=%s vs %s/plugin.json=%s\n" \
	    "$(OPENCODE_DIR)" "$$pkgver" "$(COPILOT_DIR)" "$$pjver" >&2; \
	  exit 1; \
	fi; \
	printf "Versions aligned: v%s\n" "$$pkgver"

#------------------------------------------------------------------------------
# Testing
#------------------------------------------------------------------------------

copilot-cli.test:
	$(BATS) $(TEST_DIR)/copilot-cli/hooks.bats $(TEST_DIR)/copilot-cli/hooks_e2e.bats

opencode.test:
	$(BUN) test $(TEST_DIR)/opencode/core.test.ts
	$(BATS) $(TEST_DIR)/opencode/e2e.bats

#------------------------------------------------------------------------------
# Publish
#------------------------------------------------------------------------------

publish: version.check
	gh release create "v$(VERSION)" \
	  --title "v$(VERSION)" \
	  --notes-file CHANGELOG.md \
	  --latest
	printf "Released v%s\n" "$(VERSION)"

#------------------------------------------------------------------------------
# Cleanup
#------------------------------------------------------------------------------

clean:
	rm -rf $(COPILOT_DIR)/hooks/logs/ .opencode/logs/ .github/hooks/logs/

distclean: clean
	rm -rf $(OPENCODE_DIR)/node_modules $(OPENCODE_DIR)/dist

#------------------------------------------------------------------------------
# Help
#------------------------------------------------------------------------------

help:
	printf "\033[36m"
	printf "███╗   ███╗ █████╗ ██╗  ██╗███████╗\n"
	printf "████╗ ████║██╔══██╗██║ ██╔╝██╔════╝\n"
	printf "██╔████╔██║███████║█████╔╝ █████╗  \n"
	printf "██║╚██╔╝██║██╔══██║██╔═██╗ ██╔══╝  \n"
	printf "██║ ╚═╝ ██║██║  ██║██║  ██╗███████╗\n"
	printf "╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝\n"
	printf "\033[0m\n"
	printf "Usage: make [target]\n\n"
	printf "\033[1;35mSetup:\033[0m\n"
	printf "  sync              - Install required tools (bats, shellcheck, jq, bun)\n"
	printf "\n"
	printf "\033[1;35mDev:\033[0m\n"
	printf "  fmt               - Format scripts with shfmt\n"
	printf "  lint              - Lint scripts with shellcheck\n"
	printf "  check             - fmt + lint + typecheck\n"
	printf "  qa                - version.check + check + test (quality gate)\n"
	printf "\n"
	printf "\033[1;35mVersion:\033[0m\n"
	printf "  version.check     - Verify opencode/package.json and copilot-cli/plugin.json versions match\n"
	printf "\n"
	printf "\033[1;35mTest:\033[0m\n"
	printf "  test              - Run all tests\n"
	printf "  copilot-cli.test  - Run copilot-cli hook tests (bats unit + e2e)\n"
	printf "  opencode.test     - Run opencode plugin tests (bun unit + bats e2e)\n"
	printf "\n"
	printf "\033[1;35mRelease:\033[0m\n"
	printf "  publish           - Create GitHub Release for current version (v%s)\n" "$(VERSION)"
	printf "\n"
	printf "\033[1;35mClean:\033[0m\n"
	printf "  clean             - Remove log artifacts\n"
	printf "  distclean         - clean + remove build artifacts\n"
