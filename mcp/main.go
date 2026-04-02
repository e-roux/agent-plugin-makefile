package main

import (
"bufio"
"encoding/json"
"fmt"
"io"
"log"
"os"
"strings"
)

// ── JSON-RPC 2.0 types ────────────────────────────────────────────────────────

type request struct {
JSONRPC string           `json:"jsonrpc"`
ID      *json.RawMessage `json:"id,omitempty"`
Method  string           `json:"method"`
Params  json.RawMessage  `json:"params,omitempty"`
}

type response struct {
JSONRPC string           `json:"jsonrpc"`
ID      *json.RawMessage `json:"id,omitempty"`
Result  any              `json:"result,omitempty"`
Error   *rpcError        `json:"error,omitempty"`
}

type rpcError struct {
Code    int    `json:"code"`
Message string `json:"message"`
}

// ── server ────────────────────────────────────────────────────────────────────

type server struct{ enc *json.Encoder }

func (s *server) reply(id *json.RawMessage, result any) {
if err := s.enc.Encode(response{JSONRPC: "2.0", ID: id, Result: result}); err != nil {
log.Printf("encode: %v", err)
}
}

func (s *server) replyError(id *json.RawMessage, code int, msg string) {
_ = s.enc.Encode(response{JSONRPC: "2.0", ID: id, Error: &rpcError{code, msg}})
}

// ── tool definitions ──────────────────────────────────────────────────────────

var toolsListResult = map[string]any{
"tools": []map[string]any{
{
"name":        "make_banner",
"description": "Render a project name as a 3-row box-drawing ASCII art banner using the double-line Unicode alphabet. Use this to generate the help target header in Makefiles — avoids hand-crafting error-prone art.",
"inputSchema": map[string]any{
"type": "object",
"properties": map[string]any{
"text": map[string]any{
"type":        "string",
"description": "Text to render (letters A-Z and spaces). Case-insensitive. 1-12 characters recommended for a single terminal line.",
},
},
"required": []string{"text"},
},
},
},
}

// ── tool call handler ─────────────────────────────────────────────────────────

func (s *server) handleToolsCall(id *json.RawMessage, raw json.RawMessage) {
var p struct {
Name      string          `json:"name"`
Arguments json.RawMessage `json:"arguments"`
}
if err := json.Unmarshal(raw, &p); err != nil {
s.replyError(id, -32602, "invalid params")
return
}
if p.Name != "make_banner" {
s.replyError(id, -32601, fmt.Sprintf("unknown tool: %s", p.Name))
return
}
var args struct {
Text string `json:"text"`
}
if err := json.Unmarshal(p.Arguments, &args); err != nil {
s.replyError(id, -32602, "invalid arguments: "+err.Error())
return
}
s.reply(id, map[string]any{
"content": []map[string]any{
{"type": "text", "text": render(args.Text)},
},
})
}

// ── serve loop ────────────────────────────────────────────────────────────────

func serve(in io.Reader, out io.Writer) {
s := &server{enc: json.NewEncoder(out)}
scanner := bufio.NewScanner(in)
scanner.Buffer(make([]byte, 64*1024), 64*1024)

for scanner.Scan() {
var req request
if err := json.Unmarshal(scanner.Bytes(), &req); err != nil {
log.Printf("parse: %v", err)
continue
}
switch req.Method {
case "initialize":
s.reply(req.ID, map[string]any{
"protocolVersion": "2024-11-05",
"capabilities":    map[string]any{"tools": map[string]any{}},
"serverInfo":      map[string]any{"name": "mcp-banner", "version": "0.3.0"},
})
case "notifications/initialized":
// notification — no response
case "tools/list":
s.reply(req.ID, toolsListResult)
case "tools/call":
s.handleToolsCall(req.ID, req.Params)
default:
if req.ID != nil {
s.replyError(req.ID, -32601, "method not found: "+req.Method)
}
}
}
if err := scanner.Err(); err != nil {
log.Fatalf("stdin: %v", err)
}
}

// ── entry point ───────────────────────────────────────────────────────────────

func main() {
log.SetOutput(os.Stderr)
// CLI mode: mcp-banner <TEXT> — render and print, then exit
if len(os.Args) > 1 {
fmt.Println(render(strings.Join(os.Args[1:], " ")))
return
}
// MCP server mode: JSON-RPC 2.0 over stdio
serve(os.Stdin, os.Stdout)
}
