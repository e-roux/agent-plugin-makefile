#!/usr/bin/env bats

# E2E tests — validate hook behaviour by invoking the real copilot CLI.
#
# Each test:
#   1. Creates an isolated TMPDIR and copies the hook scripts into it under
#      .github/hooks/scripts/ (the standard project-level hooks location).
#   2. Generates a .github/hooks/policy.json hooks config.
#   3. Runs copilot non-interactively from that directory (model: gpt-4.1).
#   4. Asserts hook behaviour by inspecting audit logs written by the scripts.
#
# IMPORTANT: These tests make real API calls (gpt-4.1) and take ~30-90s each.

PLUGIN_SRC="$BATS_TEST_DIRNAME/../../copilot-cli"

setup() {
  WORK="$(mktemp -d)"
  mkdir -p "$WORK/.github/hooks/scripts"

  cp "$PLUGIN_SRC/hooks/scripts/pre-tool.sh"      "$WORK/.github/hooks/scripts/"
  cp "$PLUGIN_SRC/hooks/scripts/session-start.sh" "$WORK/.github/hooks/scripts/"
  chmod +x "$WORK/.github/hooks/scripts/"*.sh

  cat > "$WORK/.github/hooks/policy.json" << 'HOOKSJSON'
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "type": "command",
        "bash": "./scripts/session-start.sh",
        "cwd": ".github/hooks",
        "timeoutSec": 10
      }
    ],
    "preToolUse": [
      {
        "type": "command",
        "bash": "./scripts/pre-tool.sh",
        "cwd": ".github/hooks",
        "timeoutSec": 15
      }
    ]
  }
}
HOOKSJSON
}

teardown() {
  rm -rf "$WORK"
}

_log_dir() { echo "$WORK/.github/hooks/logs"; }

_copilot() {
  cd "$WORK" && timeout 90 copilot \
    --model "gpt-4.1" \
    --disable-builtin-mcps \
    --no-ask-user \
    --allow-all-tools \
    -p "$1" 2>&1
}

# --- session-start hook -------------------------------------------------------

@test "e2e session-start: hook fires when copilot starts" {
  run _copilot "Say hello"
  [ "$status" -eq 0 ]
  [ -f "$(_log_dir)/session-start.log" ]
  grep -q "session-start fired" "$(_log_dir)/session-start.log"
}

# --- pre-tool hook: bash tool -------------------------------------------------

@test "e2e pre-tool: pytest is denied by hook" {
  run _copilot "You must use the bash tool to execute this exact command and report the output: pytest tests/"
  [ "$status" -eq 0 ]
  [ -f "$(_log_dir)/pre-tool-denied.log" ]
  grep -q "pytest" "$(_log_dir)/pre-tool-denied.log"
}

@test "e2e pre-tool: ruff format is denied by hook" {
  run _copilot "You must use the bash tool to execute this exact command and report the output: ruff format src/"
  [ "$status" -eq 0 ]
  [ -f "$(_log_dir)/pre-tool-denied.log" ]
  grep -q "ruff format" "$(_log_dir)/pre-tool-denied.log"
}

@test "e2e pre-tool: make command is allowed by hook" {
  run _copilot "Use the bash tool to run: make --version"
  [ "$status" -eq 0 ]
  local deny_log
  deny_log="$(_log_dir)/pre-tool-denied.log"
  if [ -f "$deny_log" ]; then
    ! grep -q "make --version" "$deny_log"
  fi
  local plain
  plain="$(echo "$output" | perl -pe 's/\e\[[0-9;]*[a-zA-Z]//g')"
  [[ "$plain" == *"make"* ]] || [[ "$plain" == *"GNU Make"* ]] || [[ "$plain" == *"Make"* ]]
}
