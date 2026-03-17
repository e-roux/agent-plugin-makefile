---
name: makefile
description: "Makefile-centric development: enforces .SILENT:, .ONESHELL:, no @ prefix, mandatory qa target, and make-only workflow."
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
| 5 | Polished | `help` uses figlet ANSI Shadow header and categorised output. |
| 6 | Advanced | **Strict `.SILENT:` compliance — ZERO `@` prefixes in recipes.** |
| 7 | Professional | Real file targets as prerequisites (dependency graph). |
| 8 | Expert | Grouped targets (`&:`), pattern rules, auto-dependencies. |

**Minimum acceptable score: 6.**

---

## Help Design

Keep `help` output on **one terminal screen** (≤24 lines):
- **5 sections** max (Setup, Dev, Test, Docs, Info)
- **Max 10 character** section titles
- **3–4 items per section**
- **ASCII art header** via figlet ANSI Shadow font
- **Colors**: Magenta (`\033[1;35m`) for sections, Cyan (`\033[36m`) for header

---

## Templates

Base template: [assets/Makefile.template](assets/Makefile.template)
Validator: [assets/validate.sh](assets/validate.sh)
