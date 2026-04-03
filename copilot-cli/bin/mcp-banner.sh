#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARY="$SCRIPT_DIR/mcp-banner"
SRC_DIR="$SCRIPT_DIR/../src"

if [[ ! -x "$BINARY" ]]; then
  if ! command -v go >/dev/null 2>&1; then
    printf "mcp-banner: Go is required to build the MCP server. Install it with: brew install go\n" >&2
    exit 1
  fi
  printf "mcp-banner: building from source (first run)...\n" >&2
  go build -o "$BINARY" "$SRC_DIR"
fi

exec "$BINARY" "$@"
