#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs"

INPUT="$(cat)"
CWD="$(echo "$INPUT" | jq -r '.cwd // "unknown"')"

cat << 'EOF'
┌─────────────────────────────────────────────────────┐
│          MAKEFILE POLICY ACTIVE                     │
├─────────────────────────────────────────────────────┤
│  All Makefiles MUST follow these rules:             │
│    .SILENT:           — suppress recipe echoing     │
│    .ONESHELL:         — single shell per recipe     │
│    .DEFAULT_GOAL:=help — default target is help     │
│    NO @ prefix        — redundant with .SILENT:     │
│    qa: target         — MANDATORY quality gate      │
│                                                     │
│  Use make targets exclusively:                      │
│    make fmt / lint / typecheck / test / qa          │
└─────────────────────────────────────────────────────┘
EOF

mkdir -p "$LOG_DIR" && \
  echo "session-start fired at $(date -u +%Y-%m-%dT%H:%M:%SZ), cwd=${CWD}" >> "$LOG_DIR/session-start.log" \
  || true

exit 0
