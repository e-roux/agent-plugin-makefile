#!/usr/bin/env bats

# E2E tests — validate the OpenCode Makefile enforcer plugin via the real CLI.
#
# Each test:
#   1. Creates an isolated TMPDIR and copies the plugin files into
#      $WORK/.opencode/plugins/ (the project-level plugin directory).
#   2. Runs opencode non-interactively from that directory.
#   3. Asserts plugin behaviour via the audit log written by the plugin
#      ($WORK/.opencode/logs/pre-tool-denied.log).
#
# IMPORTANT: These tests make real API calls (github-copilot/gpt-4.1)
#            and take ~30-90s each.

PLUGIN_SRC="$BATS_TEST_DIRNAME/../../opencode"

setup() {
  WORK="$(mktemp -d)"
  mkdir -p "$WORK/.opencode/plugins"
  cp "$PLUGIN_SRC/core.ts"  "$WORK/.opencode/plugins/"
  cp "$PLUGIN_SRC/index.ts" "$WORK/.opencode/plugins/"
}

teardown() {
  rm -rf "$WORK"
}

_log_dir() { echo "$WORK/.opencode/logs"; }

_opencode() {
  cd "$WORK" && timeout 90 opencode \
    --model github-copilot/gpt-4.1 \
    run "$1" 2>&1
}

# --- session completes --------------------------------------------------------

@test "e2e opencode: session completes with plugin loaded" {
  run _opencode "Say the word: OPENCODE_OK"
  [ "$status" -eq 0 ]
  local plain
  plain="$(echo "$output" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')"
  [[ "$plain" == *"OPENCODE_OK"* ]]
}

# --- pre-tool: bash -----------------------------------------------------------

@test "e2e opencode: pytest is denied by plugin" {
  run _opencode "You must use the bash tool to execute this exact command and report the output: pytest tests/"
  [ "$status" -eq 0 ]
  local plain
  plain="$(echo "$output" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')"
  # Enforcement may happen at LLM level (system-prompt injection) or hook level (deny log).
  local deny_log="$(_log_dir)/pre-tool-denied.log"
  local hook_denied=false
  [ -f "$deny_log" ] && grep -q "pytest" "$deny_log" && hook_denied=true
  # Either the hook denied it or the LLM refused based on the injected policy.
  [[ "$hook_denied" == true ]] || [[ "$plain" == *"make"* ]] || [[ "$plain" == *"forbidden"* ]] || [[ "$plain" == *"Makefile"* ]]
}

@test "e2e opencode: ruff format is denied by plugin" {
  run _opencode "You must use the bash tool to execute this exact command and report the output: ruff format src/"
  [ "$status" -eq 0 ]
  local plain
  plain="$(echo "$output" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')"
  # Enforcement may happen at LLM level (system-prompt injection) or hook level (deny log).
  local deny_log="$(_log_dir)/pre-tool-denied.log"
  local hook_denied=false
  [ -f "$deny_log" ] && grep -q "ruff format" "$deny_log" && hook_denied=true
  [[ "$hook_denied" == true ]] || [[ "$plain" == *"make"* ]] || [[ "$plain" == *"forbidden"* ]] || [[ "$plain" == *"Makefile"* ]]
}

# --- pre-tool: make allowed ---------------------------------------------------

@test "e2e opencode: make command is allowed by plugin" {
  run _opencode "Use the bash tool to run: make --version"
  [ "$status" -eq 0 ]
  local deny_log
  deny_log="$(_log_dir)/pre-tool-denied.log"
  if [ -f "$deny_log" ]; then
    ! grep -q "make --version" "$deny_log"
  fi
  local plain
  plain="$(echo "$output" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')"
  [[ "$plain" == *"make"* ]] || [[ "$plain" == *"Make"* ]]
}
