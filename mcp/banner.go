package main

import (
	_ "embed"
	"encoding/json"
	"strings"
)

//go:embed letters.json
var lettersData []byte

// glyph holds the three rows of a single box-drawing character.
type glyph [3]string

var alphabet map[string]glyph

func init() {
	var raw map[string]json.RawMessage
	if err := json.Unmarshal(lettersData, &raw); err != nil {
		panic("letters.json: " + err.Error())
	}
	alphabet = make(map[string]glyph, len(raw))
	for k, v := range raw {
		if strings.HasPrefix(k, "_") {
			continue
		}
		var rows []string
		if err := json.Unmarshal(v, &rows); err != nil || len(rows) != 3 {
			continue
		}
		alphabet[k] = glyph{rows[0], rows[1], rows[2]}
	}
}

// render converts text to a 3-row box-drawing banner.
// Unknown characters fall back to the space glyph.
// Returns empty string for empty input.
func render(text string) string {
	if text == "" {
		return ""
	}
	upper := strings.ToUpper(text)
	var rows [3]strings.Builder
	space := alphabet[" "]
	for _, ch := range upper {
		g, ok := alphabet[string(ch)]
		if !ok {
			g = space
		}
		for i := range rows {
			rows[i].WriteString(g[i])
		}
	}
	return rows[0].String() + "\n" + rows[1].String() + "\n" + rows[2].String()
}
