# Changelog

## [0.1.1] - 2026-03-17

### Added

- **opencode plugin**: proactive policy injection via three new hooks — `experimental.chat.system.transform` (policy in system prompt), `tool.definition` (bash tool description addendum), `experimental.session.compacting` (policy preserved across compaction).

## [0.1.0] - 2026-03-17

### Added

- Initial release of `agent-plugin-makefile`.
- **copilot-cli plugin**
  - `session-start` hook: displays Makefile policy banner (`.SILENT:`, `.ONESHELL:`, no `@`, `qa` required).
  - `preToolUse` hook (`pre-tool.sh`):
    - Blocks direct tool invocations via `bash`: `pytest`, `ruff format`, `ruff check`, `go test`, `go build`, `golangci-lint`, `eslint`, `jest`, `bun test`, `black`.
    - Validates Makefile content on `create` tool: enforces `.SILENT:`, `.ONESHELL:`, `.DEFAULT_GOAL`, no `@` in recipes, `qa` target.
    - Validates Makefile edits on `edit` tool: blocks adding `@` to recipes and removing required directives.
  - Skill definition (`SKILL.md`) with Makefile evaluation scale (1–8).
  - `Makefile.template` with all required directives.
  - `validate.sh` static Makefile validator.
- **opencode plugin** (`opencode-makefile-enforcer`)
  - Pure TypeScript rule engine (`core.ts`): `CommandRule`, `MakefileCheck`, `intercept()`, `validateMakefile()`.
  - Plugin entry point (`index.ts`): enforces the same policy as the copilot-cli hook for `bash`, `create`, and `edit` tools.
  - `/makefile` command documentation.
- **Test suite**
  - 34 bats unit tests for copilot-cli hooks.
  - 42 bun unit tests for opencode core rule engine.
  - E2E bats tests for both agents (real CLI invocations).
