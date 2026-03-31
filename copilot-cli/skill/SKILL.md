---
name: makefile
description: "Use when creating, adding, or editing a Makefile in any project. Enforces .SILENT:, .ONESHELL:, no @ prefix, mandatory qa target, and make-only workflow."
---

# Makefile Skill

**CRITICAL**: Every project MUST have a Makefile. It is the MANDATORY interface for all development tasks.

## Core Mandate

**Step 0 — always**: If no Makefile exists yet, create one from `Makefile.template` BEFORE doing anything else. Adapt it to the project's language and toolchain.

Once a Makefile exists, you MUST use `make` targets exclusively:

```bash
make sync      # Restore dependencies
make fmt       # Format code
make lint      # Lint and auto-fix
make typecheck # Type validation
make test      # Run unit tests
make check     # fmt + lint + typecheck
make qa        # MANDATORY before completion: check + test
```

You ARE NOT ALLOWED to run direct commands:
```bash
# ✗ FORBIDDEN
pytest / ruff format / ruff check / go test / go build / eslint / jest / bun test / black
```

> **Hook enforcement**: Direct invocations of the above tools are **denied** by the plugin's `preToolUse` hook. Always use `make <target>`.

---

## Required Makefile Directives

Every Makefile MUST include all four directives at the top:

```makefile
SHELL := /bin/bash
.SILENT:
.ONESHELL:
.DEFAULT_GOAL := help
```

| Directive | Purpose |
|-----------|---------|
| `.SILENT:` | Suppresses recipe echoing — **removes ALL need for `@` prefix** |
| `.ONESHELL:` | Runs each recipe in a single shell instance (enables multi-line logic) |
| `.DEFAULT_GOAL := help` | Makes `help` the default target when `make` is run bare |

> **Hook enforcement**: Creating or editing a Makefile without these directives is **denied** by the plugin's `preToolUse` hook.

---

## FORBIDDEN: `@` Prefix in Recipes

**NEVER** use the `@` prefix in recipe lines. `.SILENT:` already suppresses all echoing.

```makefile
# ✗ WRONG — @ is redundant and forbidden
test:
	@pytest tests/

# ✓ CORRECT
test:
	pytest tests/
```

> **Hook enforcement**: Adding `@` to recipe lines is **denied** by the plugin's `preToolUse` hook.

---

## Standard Targets

All projects provide these targets:

| Target | Purpose |
|:---|:---|
| `sync` | Restore dependencies |
| `fmt` | Format code |
| `lint` | Lint + auto-fix |
| `typecheck` | Type validation |
| `test` | Run unit tests |
| `test.unit` | Unit tests only (excludes integration/e2e) |
| `test.integration` | Integration tests (requires running services) |
| `test.e2e` | End-to-end tests (requires deployed stack) |
| `check` | All checks (`fmt + lint + typecheck`) |
| `qa` | Quality gate (`check + test` — **MUST PASS**) |
| `clean` | Remove temporary artifacts |
| `distclean` | Deep clean (clean + dist/) |

---

## Agent Protocol

```
Development Progress:
- [ ] 0. Create Makefile from Makefile.template if absent (ALWAYS first)
- [ ] 0.5. Validate Makefile with validate.sh (score must be ≥6)
- [ ] 1. Restore environment: make sync
- [ ] 2. Implement changes (write tests FIRST)
- [ ] 3. Verify tests: make test
- [ ] 4. Quality check: make check
- [ ] 5. Final gate: make qa (MUST PASS)
```

**Do NOT stop working until `make qa` passes.**

---

## Makefile Evaluation Scale

| Score | Level | Requirements |
|:---:|:---:|:---|
| 1 | Rudimentary | Makefile exists. Commands hardcoded. Only PHONY targets. |
| 2 | Basic | Variables for tool paths. Partial target compliance. |
| 3 | Functional | All mandatory standard targets implemented. |
| 4 | Proper | `.PHONY:`, `.DEFAULT_GOAL:`, `.SILENT:`, `.ONESHELL:` present. |
| 5 | Polished | `help` uses double-line box-drawing header (from `assets/letters.json`) and categorised output. |
| 6 | Advanced | **Strict `.SILENT:` compliance — ZERO `@` prefixes in recipes.** |
| 7 | Professional | Real file targets as prerequisites (dependency graph). |
| 8 | Expert | Grouped targets (`&:`), pattern rules, auto-dependencies. |

**Minimum acceptable score: 6.**

---

## Help Design

Two valid approaches — choose based on project size:

### Approach A: Box-drawing header (≤15 targets)

Best for small projects. Centralised help with ASCII art header.

Keep output on **one terminal screen** (≤24 lines):
- **5 sections** max (Setup, Dev, Test, Docs, Info)
- **Max 10 character** section titles
- **3–4 items per section**
- **ASCII art header** using the double-line box-drawing alphabet — see [`assets/letters.json`](assets/letters.json)
- **Colors**: Magenta (`\033[1;35m`) for sections, Cyan (`\033[36m`) for header

**Rendering a banner from `letters.json`:**

1. Read `assets/letters.json`
2. For each character in the project name (uppercase), look up the 3-element array
3. Concatenate all characters row by row (row 0 = top, 1 = middle, 2 = bottom)
4. Emit as three `printf` lines inside the `help` target

Example for project name `MAKE`:
```makefile
help:
	printf "\033[36m"
	printf "╔╦╗╔═╗╦╔ ╔═╗\n"
	printf "║║║╠═╣╠╩╗║╣ \n"
	printf "╝ ╝╝ ╝╝ ╝╚═╝\n"
	printf "\033[0m\n"
```

### Approach B: Inline `##` annotations (>15 targets) — PREFERRED

Best for large Makefiles. Self-documenting — help stays in sync automatically.

Add `## description` after each public target:

```makefile
build: $(BINARY)  ## Build the project binary
test: test.unit   ## Run all tests
qa: check test    ## Quality gate (MUST PASS before commit)
```

The `help` target parses annotations with `grep`:

```makefile
help:  ## Show available targets
	printf "\033[1;36mProject\033[0m — make targets\n\n"
	grep -E '^[a-zA-Z_.]+:.*##' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'
```

These `##` annotations are NOT code comments — they are **machine-parsed metadata**
for the help system. They are required on every public target.

---

## Templates

Base template: [assets/Makefile.template](assets/Makefile.template)
Validator: [assets/validate.sh](assets/validate.sh)
Box-drawing alphabet: [assets/letters.json](assets/letters.json)
