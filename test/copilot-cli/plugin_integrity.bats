#!/usr/bin/env bats

PLUGIN_DIR="$BATS_TEST_DIRNAME/../.."

@test "plugin.json exists and has required fields" {
  [ -f "$PLUGIN_DIR/plugin.json" ]
  jq -e '.name' "$PLUGIN_DIR/plugin.json" >/dev/null
  jq -e '.version' "$PLUGIN_DIR/plugin.json" >/dev/null
  jq -e '.skills' "$PLUGIN_DIR/plugin.json" >/dev/null
}

@test "plugin.json has single version source of truth" {
  jq -e '.version' "$PLUGIN_DIR/plugin.json" >/dev/null
}

@test "plugin.json does not reference a removed mcpServers field" {
  local has_mcp
  has_mcp=$(jq 'has("mcpServers")' "$PLUGIN_DIR/plugin.json")
  [ "$has_mcp" = "false" ]
}

@test "banner skill directory contains required files" {
  local banner_dir="$PLUGIN_DIR/skills/banner"
  [ -d "$banner_dir" ]
  [ -f "$banner_dir/SKILL.md" ]
  [ -f "$banner_dir/banner.sh" ]
  [ -f "$banner_dir/letters.json" ]
}

@test "banner.sh is executable" {
  [ -x "$PLUGIN_DIR/skills/banner/banner.sh" ]
}

@test "banner.sh renders MAKE correctly" {
  local expected=$'╔╦╗╔═╗╦╔ ╔═╗\n║║║╠═╣╠╩╗║╣ \n╝ ╝╝ ╝╝ ╝╚═╝'
  local got
  got=$(bash "$PLUGIN_DIR/skills/banner/banner.sh" "MAKE")
  [ "$got" = "$expected" ]
}

@test "banner.sh renders VFDE correctly" {
  local expected=$'╦ ╦╔═╗╔╦╗╔═╗\n║╔╝╠╣  ║║║╣ \n╚╝ ╚  ╚╩╝╚═╝'
  local got
  got=$(bash "$PLUGIN_DIR/skills/banner/banner.sh" "VFDE")
  [ "$got" = "$expected" ]
}

@test "hooks policy.json is valid" {
  [ -f "$PLUGIN_DIR/hooks/policy.json" ]
  jq -e '.version' "$PLUGIN_DIR/hooks/policy.json" >/dev/null
  jq -e '.hooks' "$PLUGIN_DIR/hooks/policy.json" >/dev/null
}

@test "all hook scripts referenced in policy.json exist and are executable" {
  local hooks_file="$PLUGIN_DIR/hooks/policy.json"
  [ -f "$hooks_file" ] || skip "no policy.json"
  for script in $(jq -r '.. | .bash? // empty' "$hooks_file"); do
    local full_path="$PLUGIN_DIR/$script"
    [ -f "$full_path" ] || { echo "missing: $full_path"; false; }
    [ -x "$full_path" ] || { echo "not executable: $full_path"; false; }
  done
}

@test "skill directories contain SKILL.md" {
  local skills_dir="$PLUGIN_DIR/skills"
  [ -d "$skills_dir" ] || skip "no skills dir"
  for dir in "$skills_dir"/*/; do
    [ -d "$dir" ] || continue
    [ -f "$dir/SKILL.md" ] || { echo "missing SKILL.md in $dir"; false; }
  done
}

@test "agent files have required frontmatter" {
  local agents_dir="$PLUGIN_DIR/agents"
  [ -d "$agents_dir" ] || skip "no agents dir"
  for f in "$agents_dir"/*.agent.md; do
    [ -f "$f" ] || continue
    head -1 "$f" | grep -q '^---' || { echo "missing frontmatter in $f"; false; }
    grep -q '^name:' "$f" || { echo "missing name in $f"; false; }
  done
}
