/**
 * Unit tests for opencode/core.ts — pure rule and validator logic.
 * Run with: bun test test/opencode/core.test.ts
 */
import { describe, it, expect } from "bun:test";
import {
  matchesRule,
  findMatchingRule,
  applyRule,
  intercept,
  validateMakefile,
  defaultCommandRules,
  defaultMakefileChecks,
  type BlockRule,
  type RewriteRule,
} from "../../opencode/core";

// ── matchesRule ──────────────────────────────────────────────────────────────

describe("matchesRule", () => {
  const block: BlockRule = { match: /^pytest\b/, action: "block", message: "no" };

  it("matches when regex test passes", () => {
    expect(matchesRule("pytest tests/", block)).toBe(true);
  });

  it("does not match when regex test fails", () => {
    expect(matchesRule("make test", block)).toBe(false);
  });
});

// ── findMatchingRule ─────────────────────────────────────────────────────────

describe("findMatchingRule", () => {
  it("returns first matching rule", () => {
    const r1: BlockRule = { match: /^pytest/, action: "block", message: "pytest" };
    const r2: BlockRule = { match: /^make/, action: "block", message: "make" };
    expect(findMatchingRule("pytest tests/", [r1, r2])).toBe(r1);
  });

  it("returns undefined when no rule matches", () => {
    const r1: BlockRule = { match: /^pytest/, action: "block", message: "pytest" };
    expect(findMatchingRule("git status", [r1])).toBeUndefined();
  });
});

// ── applyRule ────────────────────────────────────────────────────────────────

describe("applyRule", () => {
  it("block rule throws with message", () => {
    const rule: BlockRule = { match: /x/, action: "block", message: "blocked!" };
    expect(() => applyRule("x", rule)).toThrow("blocked!");
  });

  it("rewrite rule returns transformed command", () => {
    const rule: RewriteRule = {
      match: /x/,
      action: "rewrite",
      rewrite: () => "rewritten",
    };
    expect(applyRule("x", rule)).toBe("rewritten");
  });
});

// ── intercept ────────────────────────────────────────────────────────────────

describe("intercept", () => {
  it("returns command unchanged when no rule matches", () => {
    expect(intercept("git status", defaultCommandRules)).toBe("git status");
  });

  it("returns command unchanged for make targets", () => {
    expect(intercept("make test", defaultCommandRules)).toBe("make test");
  });

  it("throws when a block rule matches", () => {
    expect(() => intercept("pytest tests/", defaultCommandRules)).toThrow();
  });
});

// ── defaultCommandRules: pytest ───────────────────────────────────────────────

describe("defaultCommandRules — pytest", () => {
  it("blocks pytest at command start", () => {
    expect(() => intercept("pytest tests/", defaultCommandRules)).toThrow();
  });

  it("blocks pytest after semicolon", () => {
    expect(() => intercept("cd src; pytest .", defaultCommandRules)).toThrow();
  });

  it("blocks pytest after &&", () => {
    expect(() => intercept("cd src && pytest .", defaultCommandRules)).toThrow();
  });

  it("deny message mentions make test", () => {
    try {
      intercept("pytest .", defaultCommandRules);
    } catch (err) {
      expect((err as Error).message).toContain("make test");
    }
  });

  it("does not block make test", () => {
    expect(intercept("make test", defaultCommandRules)).toBe("make test");
  });
});

// ── defaultCommandRules: ruff ─────────────────────────────────────────────────

describe("defaultCommandRules — ruff", () => {
  it("blocks ruff format", () => {
    expect(() => intercept("ruff format src/", defaultCommandRules)).toThrow();
  });

  it("blocks ruff check", () => {
    expect(() => intercept("ruff check --fix src/", defaultCommandRules)).toThrow();
  });

  it("ruff format deny message mentions make fmt", () => {
    try {
      intercept("ruff format src/", defaultCommandRules);
    } catch (err) {
      expect((err as Error).message).toContain("make fmt");
    }
  });

  it("ruff check deny message mentions make lint", () => {
    try {
      intercept("ruff check src/", defaultCommandRules);
    } catch (err) {
      expect((err as Error).message).toContain("make lint");
    }
  });

  it("does not block make fmt", () => {
    expect(intercept("make fmt", defaultCommandRules)).toBe("make fmt");
  });
});

// ── defaultCommandRules: go ───────────────────────────────────────────────────

describe("defaultCommandRules — go", () => {
  it("blocks go test", () => {
    expect(() => intercept("go test ./...", defaultCommandRules)).toThrow();
  });

  it("blocks go build", () => {
    expect(() => intercept("go build ./...", defaultCommandRules)).toThrow();
  });

  it("go test deny message mentions make test", () => {
    try {
      intercept("go test ./...", defaultCommandRules);
    } catch (err) {
      expect((err as Error).message).toContain("make test");
    }
  });

  it("does not block go vet (not a blocked subcommand)", () => {
    expect(intercept("go vet ./...", defaultCommandRules)).toBe("go vet ./...");
  });
});

// ── defaultCommandRules: eslint/jest/black ────────────────────────────────────

describe("defaultCommandRules — eslint, jest, black", () => {
  it("blocks eslint", () => {
    expect(() => intercept("eslint --fix src/", defaultCommandRules)).toThrow();
  });

  it("blocks jest", () => {
    expect(() => intercept("jest --coverage", defaultCommandRules)).toThrow();
  });

  it("blocks bun test", () => {
    expect(() => intercept("bun test", defaultCommandRules)).toThrow();
  });

  it("blocks black", () => {
    expect(() => intercept("black .", defaultCommandRules)).toThrow();
  });

  it("blocks golangci-lint", () => {
    expect(() => intercept("golangci-lint run ./...", defaultCommandRules)).toThrow();
  });

  it("does not block git commands", () => {
    expect(intercept("git status", defaultCommandRules)).toBe("git status");
  });

  it("does not block make qa", () => {
    expect(intercept("make qa", defaultCommandRules)).toBe("make qa");
  });
});

// ── validateMakefile ──────────────────────────────────────────────────────────

const VALID_MAKEFILE = [
  "SHELL := /bin/bash",
  ".SILENT:",
  ".ONESHELL:",
  ".DEFAULT_GOAL := help",
  ".PHONY: qa test",
  "qa: test",
  "test:",
  "\tgo test ./...",
].join("\n");

describe("validateMakefile — valid", () => {
  it("does not throw for a valid Makefile", () => {
    expect(() => validateMakefile(VALID_MAKEFILE, defaultMakefileChecks)).not.toThrow();
  });
});

describe("validateMakefile — .SILENT:", () => {
  it("throws when .SILENT: is absent", () => {
    const content = VALID_MAKEFILE.replace(/^\.SILENT:\n/m, "");
    expect(() => validateMakefile(content, defaultMakefileChecks)).toThrow();
  });

  it("error message mentions .SILENT:", () => {
    const content = VALID_MAKEFILE.replace(/^\.SILENT:\n/m, "");
    try {
      validateMakefile(content, defaultMakefileChecks);
    } catch (err) {
      expect((err as Error).message).toContain(".SILENT:");
    }
  });
});

describe("validateMakefile — .ONESHELL:", () => {
  it("throws when .ONESHELL: is absent", () => {
    const content = VALID_MAKEFILE.replace(/^\.ONESHELL:\n/m, "");
    expect(() => validateMakefile(content, defaultMakefileChecks)).toThrow();
  });

  it("error message mentions .ONESHELL:", () => {
    const content = VALID_MAKEFILE.replace(/^\.ONESHELL:\n/m, "");
    try {
      validateMakefile(content, defaultMakefileChecks);
    } catch (err) {
      expect((err as Error).message).toContain(".ONESHELL:");
    }
  });
});

describe("validateMakefile — .DEFAULT_GOAL", () => {
  it("throws when .DEFAULT_GOAL is absent", () => {
    const content = VALID_MAKEFILE.replace(/^\.DEFAULT_GOAL.*\n/m, "");
    expect(() => validateMakefile(content, defaultMakefileChecks)).toThrow();
  });
});

describe("validateMakefile — no @ prefix", () => {
  it("throws when @ prefix is present in a recipe line", () => {
    const content = VALID_MAKEFILE + "\nfmt:\n\t@ruff format src/\n";
    expect(() => validateMakefile(content, defaultMakefileChecks)).toThrow();
  });

  it("error message mentions @ and .SILENT:", () => {
    const content = VALID_MAKEFILE + "\nfmt:\n\t@ruff format src/\n";
    try {
      validateMakefile(content, defaultMakefileChecks);
    } catch (err) {
      expect((err as Error).message).toContain("@");
    }
  });

  it("does not throw when @ appears in a comment (not recipe)", () => {
    const content = VALID_MAKEFILE + "\n# email@example.com\n";
    expect(() => validateMakefile(content, defaultMakefileChecks)).not.toThrow();
  });
});

describe("validateMakefile — qa target", () => {
  it("throws when qa target is absent", () => {
    const content = VALID_MAKEFILE
      .replace(/^\.PHONY: qa test\n/m, ".PHONY: test\n")
      .replace(/^qa: test\n/m, "");
    expect(() => validateMakefile(content, defaultMakefileChecks)).toThrow();
  });

  it("error message mentions qa", () => {
    const content = VALID_MAKEFILE
      .replace(/^\.PHONY: qa test\n/m, ".PHONY: test\n")
      .replace(/^qa: test\n/m, "");
    try {
      validateMakefile(content, defaultMakefileChecks);
    } catch (err) {
      expect((err as Error).message).toContain("qa");
    }
  });

  it("accepts qa declared only in .PHONY", () => {
    const content = VALID_MAKEFILE;
    expect(() => validateMakefile(content, defaultMakefileChecks)).not.toThrow();
  });
});
