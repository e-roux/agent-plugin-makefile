# Changelog

## [0.4.0] - 2026-04-02

### Added

- **skills/python/**: merged `agent-plugin-python` into this plugin. The Python/uv skill now lives
  at `copilot-cli/skills/python/SKILL.md`, alongside the existing Makefile skill. Includes all
  assets (`conftest.py`, `pyproject.toml.template`, `python.md`, `ruff.toml`) and resources
  (`scripts.md`, `build.md`).
- **pre-tool.sh**: merged Python toolchain guards from `agent-plugin-python`:
  - blocks direct `python`/`python3`, `pip`/`pip3`, `virtualenv` — use `uv` instead
  - blocks direct `mypy` — use `zmypy` (zuban drop-in) instead
- **skills directory restructured**: `copilot-cli/skill/` → `copilot-cli/skills/makefile/` per the
  latest copilot-cli plugin spec (skills must live in named subdirectories).
- **plugin.json**: `"skills"` path updated to `"skills/"`, version bumped to `0.4.0`, description
  and keywords updated to reflect the merged Python scope.
- **session-start.sh**: banner updated to cover both Makefile and Python toolchain rules.

## [0.3.1] - 2026-04-03

### Fixed

- **Makefile (root)**: Corrected `I` glyph in "AGENT PLUGIN MAKEFILE" banner — regenerated with `mcp-banner` tool using the centered serif `I` ( ╦ / ║ / ╩ ).
- **mcp/letters.json** + **copilot-cli/skill/assets/letters.json**: `I` glyph recentered with ╩ serif bottom (`[" ╦ ", " ║ ", " ╩ "]`) to eliminate 4-space gap before following letters.

## [0.3.0] - 2026-04-02

### Added

- **mcp/**: Go MCP server (`mcp-banner`) — exposes a `make_banner` tool that renders any string as a 3-row box-drawing banner using the double-line Unicode alphabet from `letters.json`. Eliminates error-prone hand-crafting of ASCII art in Makefile `help` targets.
- **copilot-cli/.mcp.json**: Registers the `mcp-banner` stdio server with the Copilot CLI plugin.
- **copilot-cli/plugin.json**: `"mcpServers": ".mcp.json"` — wires the MCP server into the plugin.
- **Makefile**: `mcp.test` and `mcp.build` targets; `go` added to `sync`; `distclean` now removes `copilot-cli/bin/`.

### Changed

- **Makefile (root)**: Help header migrated from block-font ASCII art to the box-drawing alphabet (`╔╦╗╔═╗╦╔ ╔═╗` / `║║║╠═╣╠╩╗║╣ ` / `╝ ╝╝ ╝╝ ╝╚═╝`).
- **copilot-cli/skill/assets/Makefile.template**: Same header fix — big block "MAKE" art replaced with the letters.json box-drawing version.
- **pre-tool.sh / validate.sh**: `##` inline annotations on target lines are now **FORBIDDEN** (Approach B removed). Any Makefile with `##`-annotated targets is denied/failed.
- **SKILL.md**: Approach B removed entirely; box-drawing `printf` help (Approach A) is the only valid pattern.

## [0.2.0] - 2026-03-28

### Added

- **pre-tool.sh**: `_validate_existing_file()` — reads the Makefile from disk on every `edit` and denies if required directives (`.SILENT:`, `.ONESHELL:`, `.DEFAULT_GOAL`) are missing, unless the edit itself adds them. Fixes the gap where a non-compliant file could be silently edited.
- **pre-tool.sh**: `_is_makefile()` helper — now detects `*.mk` include files in addition to `Makefile|makefile|GNUmakefile`.
- **SKILL.md**: documents both help approaches — Approach A (ANSI Shadow, ≤15 targets) and Approach B (inline `##` annotations + `grep` pipeline, >15 targets, preferred for large Makefiles).
- **validate.sh**: Check 3 now accepts both help approaches; auto-detects the `##` grep pipeline pattern.
- **hooks.bats**: 4 new tests for full-state validation and `*.mk` detection (38 tests, 0 failures).

### Fixed

- `hooks.bats` session-start banner test: case mismatch (`MAKEFILE POLICY` → `Makefile Policy`).

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
