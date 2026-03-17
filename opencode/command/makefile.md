---
description: "Makefile-first development workflow. Enforces .SILENT:, .ONESHELL:, no @ prefix, qa target. Blocks direct tool invocations."
---

# Makefile Development Workflow

The `MakefileEnforcerPlugin` is active. Direct tool invocations and malformed Makefiles are **blocked**.

## MANDATORY: Use `make` targets — Never direct tools

| Forbidden | Replacement |
|-----------|-------------|
| `pytest tests/` | `make test` |
| `ruff format src/` | `make fmt` |
| `ruff check src/` | `make lint` |
| `go test ./...` | `make test` |
| `go build ./...` | `make build` |
| `golangci-lint run` | `make lint` |
| `eslint .` | `make lint` |
| `jest` | `make test` |
| `bun test` | `make test` |
| `black .` | `make fmt` |

---

## Required Makefile Directives

Every Makefile MUST start with:

```makefile
SHELL := /bin/bash
.SILENT:
.ONESHELL:
.DEFAULT_GOAL := help
```

## FORBIDDEN: `@` Prefix in Recipes

```makefile
# ✗ WRONG
test:
	@pytest tests/

# ✓ CORRECT
test:
	pytest tests/
```

`.SILENT:` already suppresses all echoing. Never add `@`.

## Required Target: `qa`

```makefile
.PHONY: ... qa ...
qa: check test
```

`make qa` is the mandatory quality gate. Work is not done until `make qa` passes.

---

## Standard Targets

```bash
make sync      # Install/restore dependencies
make fmt       # Format code
make lint      # Lint + auto-fix
make typecheck # Type check
make test      # Run tests
make check     # fmt + lint + typecheck
make qa        # Full quality gate (MANDATORY)
make clean     # Remove build artifacts
```

---

## Workflow

```bash
# 1. Create Makefile if absent (from Makefile.template)
# 2. Restore dependencies
make sync

# 3. Implement changes (tests first)
# 4. Run quality gate
make qa
```
