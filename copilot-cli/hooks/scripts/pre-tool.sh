#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs"

INPUT="$(cat)"
TOOL_NAME="$(echo "$INPUT" | jq -r '.toolName // empty')"
TOOL_ARGS_RAW="$(echo "$INPUT" | jq -r '.toolArgs // empty')"

# ── Helper ────────────────────────────────────────────────────────────────────

_deny() {
  local reason="$1"
  mkdir -p "$LOG_DIR" 2>/dev/null \
    && echo "denied at $(date -u +%Y-%m-%dT%H:%M:%SZ): $reason" >> "$LOG_DIR/pre-tool-denied.log" 2>/dev/null \
    || true
  jq -n --arg reason "$reason" \
    '{"permissionDecision":"deny","permissionDecisionReason":$reason}'
  exit 0
}

# ── Makefile content validator ────────────────────────────────────────────────

_validate_makefile() {
  local content="$1"

  if ! echo "$content" | grep -q '^\.SILENT'; then
    _deny "Makefile missing required directive: '.SILENT:' — add it before the first target to suppress recipe echoing without @."
  fi

  if ! echo "$content" | grep -q '\.ONESHELL'; then
    _deny "Makefile missing required directive: '.ONESHELL:' — add it to run each recipe in a single shell instance."
  fi

  if ! echo "$content" | grep -q '\.DEFAULT_GOAL'; then
    _deny "Makefile missing required directive: '.DEFAULT_GOAL := help' — the default target must be 'help'."
  fi

  # Recipe lines start with a tab; @ on such lines is redundant and forbidden
  if echo "$content" | grep -qP '^\t@'; then
    _deny "Makefile has '@' prefix in recipe lines — this is redundant with '.SILENT:' and FORBIDDEN. Remove all '@' prefixes from recipes."
  fi

  # qa target: check .PHONY declaration and actual recipe
  if ! echo "$content" | grep -qP '(?:^\.PHONY:[^\n]*\bqa\b|^qa\s*:)'; then
    _deny "Makefile missing required 'qa' target — add a 'qa:' recipe that runs 'check test' as the quality gate (e.g., 'qa: check test')."
  fi
}

# ── bash tool ────────────────────────────────────────────────────────────────

if [ "$TOOL_NAME" = "bash" ]; then
  COMMAND="$(echo "$TOOL_ARGS_RAW" | jq -r '.command // empty')"

  # Matches token at command start or after shell operator (; & |)
  _matches() { echo "$COMMAND" | grep -qE "(^|[;&|][[:space:]]*)$1([[:space:]]|\$)"; }

  # pytest — use make test
  if _matches "pytest"; then
    _deny "Direct pytest is forbidden. Use Make targets instead: make test"
  fi

  # ruff format — use make fmt
  if echo "$COMMAND" | grep -qE '(^|[;&|][[:space:]]*)ruff[[:space:]]+format([[:space:]]|$)'; then
    _deny "Direct 'ruff format' is forbidden. Use Make targets instead: make fmt"
  fi

  # ruff check — use make lint
  if echo "$COMMAND" | grep -qE '(^|[;&|][[:space:]]*)ruff[[:space:]]+check([[:space:]]|$)'; then
    _deny "Direct 'ruff check' is forbidden. Use Make targets instead: make lint"
  fi

  # go test — use make test
  if echo "$COMMAND" | grep -qE '(^|[;&|][[:space:]]*)go[[:space:]]+test([[:space:]]|$)'; then
    _deny "Direct 'go test' is forbidden. Use Make targets instead: make test"
  fi

  # go build — use make build
  if echo "$COMMAND" | grep -qE '(^|[;&|][[:space:]]*)go[[:space:]]+build([[:space:]]|$)'; then
    _deny "Direct 'go build' is forbidden. Use Make targets instead: make build"
  fi

  # golangci-lint — use make lint
  if _matches "golangci-lint"; then
    _deny "Direct golangci-lint is forbidden. Use Make targets instead: make lint"
  fi

  # eslint — use make lint
  if _matches "eslint"; then
    _deny "Direct eslint is forbidden. Use Make targets instead: make lint"
  fi

  # jest — use make test
  if _matches "jest"; then
    _deny "Direct jest is forbidden. Use Make targets instead: make test"
  fi

  # bun test — use make test
  if echo "$COMMAND" | grep -qE '(^|[;&|][[:space:]]*)bun[[:space:]]+test([[:space:]]|$)'; then
    _deny "Direct 'bun test' is forbidden. Use Make targets instead: make test"
  fi

  # black — use make fmt
  if _matches "black"; then
    _deny "Direct black is forbidden. Use Make targets instead: make fmt"
  fi

  exit 0
fi

# ── create tool ───────────────────────────────────────────────────────────────

if [ "$TOOL_NAME" = "create" ]; then
  FILE_PATH="$(echo "$TOOL_ARGS_RAW" | jq -r '.path // empty')"
  FILE_BASE="$(basename "$FILE_PATH")"

  if [ "$FILE_BASE" = "Makefile" ] || [ "$FILE_BASE" = "makefile" ] || [ "$FILE_BASE" = "GNUmakefile" ]; then
    CONTENT="$(echo "$TOOL_ARGS_RAW" | jq -r '.file_text // empty')"
    _validate_makefile "$CONTENT"
  fi

  exit 0
fi

# ── edit tool ─────────────────────────────────────────────────────────────────

if [ "$TOOL_NAME" = "edit" ]; then
  FILE_PATH="$(echo "$TOOL_ARGS_RAW" | jq -r '.path // empty')"
  FILE_BASE="$(basename "$FILE_PATH")"

  if [ "$FILE_BASE" = "Makefile" ] || [ "$FILE_BASE" = "makefile" ] || [ "$FILE_BASE" = "GNUmakefile" ]; then
    NEW_STR="$(echo "$TOOL_ARGS_RAW" | jq -r '.new_str // empty')"
    OLD_STR="$(echo "$TOOL_ARGS_RAW" | jq -r '.old_str // empty')"

    # Forbid adding @ in new recipe lines
    if echo "$NEW_STR" | grep -qP '^\t@'; then
      _deny "Adding '@' prefix to recipe lines is FORBIDDEN — '.SILENT:' already suppresses echoing. Remove the '@' prefix."
    fi

    # Forbid removing .SILENT: without replacing it
    if echo "$OLD_STR" | grep -q '^\.SILENT' && ! echo "$NEW_STR" | grep -q '^\.SILENT'; then
      _deny "Removing '.SILENT:' from the Makefile is FORBIDDEN — it is a required directive."
    fi

    # Forbid removing .ONESHELL: without replacing it
    if echo "$OLD_STR" | grep -q '\.ONESHELL' && ! echo "$NEW_STR" | grep -q '\.ONESHELL'; then
      _deny "Removing '.ONESHELL:' from the Makefile is FORBIDDEN — it is a required directive."
    fi
  fi

  exit 0
fi

exit 0
