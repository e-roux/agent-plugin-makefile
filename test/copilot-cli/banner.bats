#!/usr/bin/env bats

BANNER_SCRIPT="$BATS_TEST_DIRNAME/../../skills/banner/banner.sh"

# ── existence ─────────────────────────────────────────────────────────────────

@test "banner.sh exists" {
  [ -f "$BANNER_SCRIPT" ]
}

@test "banner.sh is executable" {
  [ -x "$BANNER_SCRIPT" ]
}

# ── render correctness ────────────────────────────────────────────────────────

@test "empty input produces no output" {
  run bash "$BANNER_SCRIPT" ""
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "render A" {
  run bash "$BANNER_SCRIPT" "A"
  [ "$status" -eq 0 ]
  [ "$output" = $'╔═╗\n╠═╣\n╝ ╝' ]
}

@test "render I is centered with serif bottom" {
  run bash "$BANNER_SCRIPT" "I"
  [ "$status" -eq 0 ]
  [ "$output" = $' ╦ \n ║ \n ╩ ' ]
}

@test "render MAKE" {
  run bash "$BANNER_SCRIPT" "MAKE"
  [ "$status" -eq 0 ]
  [ "$output" = $'╔╦╗╔═╗╦╔ ╔═╗\n║║║╠═╣╠╩╗║╣ \n╝ ╝╝ ╝╝ ╝╚═╝' ]
}

@test "render VFDE" {
  run bash "$BANNER_SCRIPT" "VFDE"
  [ "$status" -eq 0 ]
  [ "$output" = $'╦ ╦╔═╗╔╦╗╔═╗\n║╔╝╠╣  ║║║╣ \n╚╝ ╚  ╚╩╝╚═╝' ]
}

@test "render space glyph" {
  run bash "$BANNER_SCRIPT" " "
  [ "$status" -eq 0 ]
  [ "$output" = $'   \n   \n   ' ]
}

@test "lowercase equals uppercase output" {
  local upper lower
  upper=$(bash "$BANNER_SCRIPT" "MAKE")
  lower=$(bash "$BANNER_SCRIPT" "make")
  [ "$upper" = "$lower" ]
}

@test "unknown character falls back to space (no crash)" {
  run bash "$BANNER_SCRIPT" "?"
  [ "$status" -eq 0 ]
  [ -n "$output" ]
}

# ── output structure ──────────────────────────────────────────────────────────

@test "output has exactly two newlines for single and multi-char inputs" {
  for word in "A" "MAKE" "VFDE" "GO"; do
    local count
    count=$(bash "$BANNER_SCRIPT" "$word" | tr -cd '\n' | wc -c | tr -d ' ')
    [ "$count" -eq 2 ] || { echo "Expected 2 newlines for '$word', got $count"; return 1; }
  done
}

@test "two spaces produce wider output than one space" {
  local one two
  one=$(bash "$BANNER_SCRIPT" " " | head -1)
  two=$(bash "$BANNER_SCRIPT" "  " | head -1)
  [ "${#two}" -gt "${#one}" ]
}
