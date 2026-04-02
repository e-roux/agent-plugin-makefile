package main

import (
	"encoding/json"
	"strings"
	"testing"
)

// Each glyph is exactly 3 chars wide; rows are concatenated without separators.

func TestRenderEmpty(t *testing.T) {
	if got := render(""); got != "" {
		t.Errorf("empty input: want %q, got %q", "", got)
	}
}

func TestRenderSingleLetterA(t *testing.T) {
	want := "╔═╗\n╠═╣\n╝ ╝"
	if got := render("A"); got != want {
		t.Errorf("render(A): want %q, got %q", want, got)
	}
}

func TestRenderSingleLetterI(t *testing.T) {
	// I must be centered (1 space each side) with a serif bottom (╩).
	// This prevents the visual gap caused by I's trailing spaces combining
	// with J's leading spaces (old: "║    ║" → new: "║   ║").
	want := " ╦ \n ║ \n ╩ "
	if got := render("I"); got != want {
		t.Errorf("render(I): want %q, got %q", want, got)
	}
}

func TestRenderLowercaseEqualsUppercase(t *testing.T) {
	if render("make") != render("MAKE") {
		t.Error("lowercase should produce the same output as uppercase")
	}
}

func TestRenderMAKE(t *testing.T) {
	// M  A  K  E concatenated row-by-row
	want := "╔╦╗╔═╗╦╔ ╔═╗\n║║║╠═╣╠╩╗║╣ \n╝ ╝╝ ╝╝ ╝╚═╝"
	if got := render("MAKE"); got != want {
		t.Errorf("render(MAKE):\nwant %q\n got %q", want, got)
	}
}

func TestRenderVFDE(t *testing.T) {
	// V  F  D  E
	want := "╦ ╦╔═╗╔╦╗╔═╗\n║╔╝╠╣  ║║║╣ \n╚╝ ╚  ╚╩╝╚═╝"
	if got := render("VFDE"); got != want {
		t.Errorf("render(VFDE):\nwant %q\n got %q", want, got)
	}
}

func TestRenderSpace(t *testing.T) {
	want := "   \n   \n   "
	if got := render(" "); got != want {
		t.Errorf("render( ): want %q, got %q", want, got)
	}
}

func TestRenderUnknownCharFallsBackToSpace(t *testing.T) {
	// Unknown chars should not panic and should fall back to a space glyph
	got := render("?")
	if got == "" {
		t.Error("render(?) should return three non-empty rows (space fallback)")
	}
}

func TestRenderMultipleSpaces(t *testing.T) {
	one := render(" ")
	two := render("  ")
	if len(two) <= len(one) {
		t.Error("two spaces should produce wider output than one space")
	}
}

func TestRenderOutputHasExactlyTwoNewlines(t *testing.T) {
	for _, word := range []string{"A", "MAKE", "VFDE", "GO"} {
		got := render(word)
		count := 0
		for _, ch := range got {
			if ch == '\n' {
				count++
			}
		}
		if count != 2 {
			t.Errorf("render(%q): expected exactly 2 newlines, got %d", word, count)
		}
	}
}

// ── MCP protocol tests ────────────────────────────────────────────────────────

// mcpCall sends a single JSON-RPC request to serve() and returns the decoded response.
func mcpCall(t *testing.T, reqJSON string) map[string]any {
	t.Helper()
	var out strings.Builder
	serve(strings.NewReader(reqJSON+"\n"), &out)
	var result map[string]any
	if err := json.Unmarshal([]byte(out.String()), &result); err != nil {
		t.Fatalf("mcpCall: failed to parse response %q: %v", out.String(), err)
	}
	return result
}

func TestMakeBannerMCPProtocolVFDE(t *testing.T) {
	resp := mcpCall(t, `{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"make_banner","arguments":{"text":"VFDE"}}}`)

	result, ok := resp["result"].(map[string]any)
	if !ok {
		t.Fatalf("expected result object, got: %v", resp)
	}
	content, ok := result["content"].([]any)
	if !ok || len(content) == 0 {
		t.Fatalf("expected non-empty content array, got: %v", result)
	}
	item, ok := content[0].(map[string]any)
	if !ok {
		t.Fatalf("expected content item object, got: %v", content[0])
	}
	got, _ := item["text"].(string)
	want := "╦ ╦╔═╗╔╦╗╔═╗\n║╔╝╠╣  ║║║╣ \n╚╝ ╚  ╚╩╝╚═╝"
	if got != want {
		t.Errorf("make_banner(VFDE):\nwant %q\n got %q", want, got)
	}
}

func TestMakeBannerMCPProtocolInitialize(t *testing.T) {
	resp := mcpCall(t, `{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}`)
	result, ok := resp["result"].(map[string]any)
	if !ok {
		t.Fatalf("expected result, got: %v", resp)
	}
	info, _ := result["serverInfo"].(map[string]any)
	if info["name"] != "mcp-banner" {
		t.Errorf("serverInfo.name: want %q, got %q", "mcp-banner", info["name"])
	}
}

func TestMakeBannerMCPProtocolToolsList(t *testing.T) {
	resp := mcpCall(t, `{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}`)
	result, ok := resp["result"].(map[string]any)
	if !ok {
		t.Fatalf("expected result, got: %v", resp)
	}
	tools, _ := result["tools"].([]any)
	if len(tools) != 1 {
		t.Fatalf("expected 1 tool, got %d", len(tools))
	}
	tool := tools[0].(map[string]any)
	if tool["name"] != "make_banner" {
		t.Errorf("tool name: want %q, got %q", "make_banner", tool["name"])
	}
}

func TestMakeBannerMCPProtocolUnknownTool(t *testing.T) {
	resp := mcpCall(t, `{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"no_such_tool","arguments":{}}}`)
	if resp["error"] == nil {
		t.Errorf("expected error for unknown tool, got: %v", resp)
	}
}
