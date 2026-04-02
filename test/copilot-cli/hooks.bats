#!/usr/bin/env bats

SCRIPTS_DIR="$BATS_TEST_DIRNAME/../../copilot-cli/hooks/scripts"

# ── session-start.sh ──────────────────────────────────────────────────────────

@test "session-start: exits successfully" {
  local input='{"timestamp":1704614400000,"cwd":"/tmp","source":"new"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/session-start.sh'"
  [ "$status" -eq 0 ]
}

@test "session-start: outputs policy banner" {
  local input='{"timestamp":1704614400000,"cwd":"/tmp","source":"new"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/session-start.sh'"
  [[ "$output" == *"Makefile"* ]] && [[ "$output" == *"Python"* ]]
}

@test "session-start: banner mentions .SILENT:" {
  local input='{"timestamp":1704614400000,"cwd":"/tmp","source":"new"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/session-start.sh'"
  [[ "$output" == *".SILENT:"* ]]
}

@test "session-start: banner mentions qa" {
  local input='{"timestamp":1704614400000,"cwd":"/tmp","source":"new"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/session-start.sh'"
  [[ "$output" == *"qa"* ]]
}

@test "session-start: banner mentions make" {
  local input='{"timestamp":1704614400000,"cwd":"/tmp","source":"new"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/session-start.sh'"
  [[ "$output" == *"make"* ]]
}

# ── pre-tool.sh: non-bash tool pass-through ───────────────────────────────────

@test "pre-tool: allows non-bash tool (view)" {
  local input='{"toolName":"view","toolArgs":"{\"path\":\"/tmp\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "pre-tool: allows safe bash command (git status)" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"git status\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "pre-tool: allows make test" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"make test\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "pre-tool: allows make qa" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"make qa\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "pre-tool: allows make fmt" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"make fmt\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── pre-tool.sh: bash — direct tool blocking ──────────────────────────────────

@test "pre-tool: denies pytest at command start" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"pytest tests/\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies pytest after semicolon" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"cd src; pytest .\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies ruff format" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"ruff format src/\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies ruff check" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"ruff check --fix src/\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies go test" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"go test ./...\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies go build" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"go build ./...\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies golangci-lint" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"golangci-lint run ./...\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies eslint" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"eslint --fix src/\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies jest" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"jest --coverage\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies bun test" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"bun test\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies black" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"black .\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies direct python" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"python script.py\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies direct pip install" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"pip install requests\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies direct mypy" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"mypy src/\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: allows uv run" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"uv run zmypy src/\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "pre-tool: deny response is valid JSON" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"pytest tests/\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  echo "$output" | jq . >/dev/null
}

@test "pre-tool: deny response contains reason mentioning make" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"pytest tests/\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  reason="$(echo "$output" | jq -r '.permissionDecisionReason')"
  [[ "$reason" == *"make"* ]]
}

# ── pre-tool.sh: create — Makefile validation ─────────────────────────────────

@test "pre-tool: allows create with non-Makefile path" {
  local args
  args=$(jq -n '{"path":"/tmp/main.go","file_text":"package main"}' | jq -Rs .)
  # args is now a quoted string; build the outer JSON using printf+jq
  local input
  input=$(printf '{"toolName":"create","toolArgs":%s}' "$args")
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "pre-tool: denies Makefile creation missing .SILENT:" {
  local content
  content=$(printf 'SHELL := /bin/bash\n.ONESHELL:\n.DEFAULT_GOAL := help\n.PHONY: qa\nqa: test\n')
  local toolargs
  toolargs=$(jq -n --arg path '/tmp/Makefile' --arg ft "$content" '{"path":$path,"file_text":$ft}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"create","toolArgs":$ta}')
  local tmpf
  tmpf=$(mktemp)
  echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies Makefile creation missing .ONESHELL:" {
  local content
  content=$(printf 'SHELL := /bin/bash\n.SILENT:\n.DEFAULT_GOAL := help\n.PHONY: qa\nqa: test\n')
  local toolargs
  toolargs=$(jq -n --arg path '/tmp/Makefile' --arg ft "$content" '{"path":$path,"file_text":$ft}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"create","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp)
  echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies Makefile creation with @ in recipes" {
  local content
  content=$(printf 'SHELL := /bin/bash\n.SILENT:\n.ONESHELL:\n.DEFAULT_GOAL := help\n.PHONY: qa\nqa: test\ntest:\n\t@pytest tests/\n')
  local toolargs
  toolargs=$(jq -n --arg path '/tmp/Makefile' --arg ft "$content" '{"path":$path,"file_text":$ft}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"create","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp)
  echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies Makefile creation missing qa target" {
  local content
  content=$(printf 'SHELL := /bin/bash\n.SILENT:\n.ONESHELL:\n.DEFAULT_GOAL := help\n.PHONY: test\ntest:\n\tgo test\n')
  local toolargs
  toolargs=$(jq -n --arg path '/tmp/Makefile' --arg ft "$content" '{"path":$path,"file_text":$ft}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"create","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp)
  echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: allows valid Makefile creation" {
  local content
  content=$(printf 'SHELL := /bin/bash\n.SILENT:\n.ONESHELL:\n.DEFAULT_GOAL := help\n.PHONY: qa test\nqa: test\ntest:\n\tgo test ./...\n')
  local toolargs
  toolargs=$(jq -n --arg path '/tmp/Makefile' --arg ft "$content" '{"path":$path,"file_text":$ft}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"create","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp)
  echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── pre-tool.sh: edit — Makefile validation ───────────────────────────────────

@test "pre-tool: allows edit with non-Makefile path" {
  local toolargs
  toolargs=$(jq -n '{"path":"/tmp/main.go","old_str":"old","new_str":"new"}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"edit","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp)
  echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "pre-tool: denies edit adding @ to Makefile recipe" {
  local toolargs
  toolargs=$(jq -n '{"path":"/tmp/Makefile","old_str":"test:\n\tpytest","new_str":"test:\n\t@pytest"}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"edit","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp)
  echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies edit removing .SILENT: from Makefile" {
  local toolargs
  toolargs=$(jq -n '{"path":"/tmp/Makefile","old_str":".SILENT:\n.ONESHELL:","new_str":".ONESHELL:"}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"edit","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp)
  echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies edit removing .ONESHELL: from Makefile" {
  local toolargs
  toolargs=$(jq -n '{"path":"/tmp/Makefile","old_str":".SILENT:\n.ONESHELL:","new_str":".SILENT:"}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"edit","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp)
  echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: allows safe edit of Makefile" {
  local toolargs
  toolargs=$(jq -n '{"path":"/tmp/Makefile","old_str":"echo old","new_str":"echo new"}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"edit","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp)
  echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── pre-tool.sh: full-state validation on edit ────────────────────────────────

@test "pre-tool: denies edit on Makefile missing .ONESHELL: on disk" {
  local mkf; mkf=$(mktemp -d)/Makefile
  printf '.SILENT:\n.DEFAULT_GOAL := help\n.PHONY: qa\nqa: test\ntest:\n\techo hi\n' > "$mkf"
  local toolargs
  toolargs=$(jq -n --arg path "$mkf" '{"path":$path,"old_str":"echo hi","new_str":"echo hello"}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"edit","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp)
  echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf" "$mkf"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
  [[ "$output" == *".ONESHELL:"* ]]
}

@test "pre-tool: allows edit on fully compliant Makefile on disk" {
  local mkf; mkf=$(mktemp -d)/Makefile
  printf '.SILENT:\n.ONESHELL:\n.DEFAULT_GOAL := help\n.PHONY: qa\nqa: test\ntest:\n\techo hi\n' > "$mkf"
  local toolargs
  toolargs=$(jq -n --arg path "$mkf" '{"path":$path,"old_str":"echo hi","new_str":"echo hello"}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"edit","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp)
  echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf" "$mkf"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "pre-tool: allows edit adding missing directive to non-compliant Makefile" {
  local mkf; mkf=$(mktemp -d)/Makefile
  printf '.SILENT:\n.DEFAULT_GOAL := help\n.PHONY: qa\nqa: test\n' > "$mkf"
  local toolargs
  toolargs=$(jq -n --arg path "$mkf" '{"path":$path,"old_str":".SILENT:","new_str":".SILENT:\n.ONESHELL:"}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"edit","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp)
  echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf" "$mkf"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "pre-tool: detects .mk include files" {
  local content
  content=$(printf '.PHONY: qa\nqa: test\n')
  local toolargs
  toolargs=$(jq -n --arg path '/tmp/build.mk' --arg ft "$content" '{"path":$path,"file_text":$ft}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"create","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp)
  echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

# ── pre-tool.sh: ## annotation enforcement ─────────────────────────────────────

@test "pre-tool: denies Makefile creation with ## annotations (Approach B)" {
  local content
  content=$(printf 'SHELL := /bin/bash\n.SILENT:\n.ONESHELL:\n.DEFAULT_GOAL := help\n.PHONY: qa test\nqa: test  ## Quality gate\ntest:\n\techo hi\n')
  local toolargs
  toolargs=$(jq -n --arg path '/tmp/Makefile' --arg ft "$content" '{"path":$path,"file_text":$ft}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"create","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp)
  echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: deny reason for ## annotations mentions Approach B" {
  local content
  content=$(printf 'SHELL := /bin/bash\n.SILENT:\n.ONESHELL:\n.DEFAULT_GOAL := help\n.PHONY: qa test\nqa: test  ## Quality gate\ntest:\n\techo hi\n')
  local toolargs
  toolargs=$(jq -n --arg path '/tmp/Makefile' --arg ft "$content" '{"path":$path,"file_text":$ft}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"create","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp)
  echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  reason="$(echo "$output" | jq -r '.permissionDecisionReason')"
  [[ "$reason" == *"##"* ]]
  [[ "$reason" == *"FORBIDDEN"* ]]
}

@test "pre-tool: allows Makefile creation without ## annotations" {
  local content
  content=$(printf 'SHELL := /bin/bash\n.SILENT:\n.ONESHELL:\n.DEFAULT_GOAL := help\n.PHONY: qa test\nqa: test\ntest:\n\techo hi\n')
  local toolargs
  toolargs=$(jq -n --arg path '/tmp/Makefile' --arg ft "$content" '{"path":$path,"file_text":$ft}')
  local input
  input=$(jq -n --arg ta "$toolargs" '{"toolName":"create","toolArgs":$ta}')
  local tmpf; tmpf=$(mktemp)
  echo "$input" > "$tmpf"
  run bash -c "'$SCRIPTS_DIR/pre-tool.sh' < '$tmpf'"
  rm -f "$tmpf"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
