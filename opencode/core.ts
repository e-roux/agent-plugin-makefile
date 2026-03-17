/**
 * Command interceptor and Makefile validator — pure logic, no runtime deps.
 *
 * Enforces the same policy as the copilot-cli pre-tool hook:
 *   - Direct tool invocations (pytest, ruff, go test, eslint, jest…) are blocked.
 *   - Makefiles must have .SILENT:, .ONESHELL:, .DEFAULT_GOAL, no @ in recipes,
 *     and a qa: target.
 *
 * Tested with `bun test`.
 */

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface BlockRule {
  match: RegExp;
  action: "block";
  message: string;
}

export interface RewriteRule {
  match: RegExp;
  action: "rewrite";
  rewrite: (command: string) => string;
}

export type CommandRule = BlockRule | RewriteRule;

export interface MakefileCheck {
  name: string;
  /** Returns true when the Makefile content PASSES the check. */
  check: (content: string) => boolean;
  message: string;
}

// ---------------------------------------------------------------------------
// Matching helpers
// ---------------------------------------------------------------------------

/**
 * Build a regex that matches `token` at the start of a command OR immediately
 * after a shell operator (; & |), with optional surrounding whitespace.
 * The token must be followed by whitespace or end-of-string.
 */
function shellToken(token: string): RegExp {
  return new RegExp(`(?:^|[;&|]\\s*)${token}(?:\\s|$)`);
}

// ---------------------------------------------------------------------------
// Core functions (exported for unit testing)
// ---------------------------------------------------------------------------

/** Test whether a command matches a rule's pattern. */
export function matchesRule(command: string, rule: CommandRule): boolean {
  return rule.match.test(command);
}

/** Find the first matching rule for a command (first-wins). */
export function findMatchingRule(
  command: string,
  rules: readonly CommandRule[],
): CommandRule | undefined {
  return rules.find((rule) => matchesRule(command, rule));
}

/**
 * Apply a matched rule to a command.
 * - block rules throw an Error with the configured message.
 * - rewrite rules return the transformed command.
 */
export function applyRule(command: string, rule: CommandRule): string {
  if (rule.action === "block") {
    throw new Error(rule.message);
  }
  return rule.rewrite(command);
}

/**
 * Run a command through the full rule list.
 * Returns the (possibly rewritten) command, or throws if blocked.
 * When no rule matches the command is returned unchanged.
 */
export function intercept(
  command: string,
  rules: readonly CommandRule[],
): string {
  const rule = findMatchingRule(command, rules);
  if (!rule) return command;
  return applyRule(command, rule);
}

/**
 * Validate Makefile content against a list of checks.
 * Throws with the first failing check's message.
 */
export function validateMakefile(
  content: string,
  checks: readonly MakefileCheck[],
): void {
  for (const check of checks) {
    if (!check.check(content)) {
      throw new Error(check.message);
    }
  }
}

// ---------------------------------------------------------------------------
// Default command rules — mirror the copilot-cli pre-tool bash enforcement
// More-specific rules listed first (first-wins matching).
// ---------------------------------------------------------------------------

export const defaultCommandRules: readonly CommandRule[] = [
  // ── ruff format ────────────────────────────────────────────────────
  {
    match: /(?:^|[;&|]\s*)ruff\s+format\b/,
    action: "block",
    message:
      "'ruff format' is forbidden. Use Make targets instead:\n\n" +
      "  make fmt    — format code via the project Makefile",
  },

  // ── ruff check ─────────────────────────────────────────────────────
  {
    match: /(?:^|[;&|]\s*)ruff\s+check\b/,
    action: "block",
    message:
      "'ruff check' is forbidden. Use Make targets instead:\n\n" +
      "  make lint   — lint code via the project Makefile",
  },

  // ── go test ────────────────────────────────────────────────────────
  {
    match: /(?:^|[;&|]\s*)go\s+test\b/,
    action: "block",
    message:
      "'go test' is forbidden. Use Make targets instead:\n\n" +
      "  make test   — run tests via the project Makefile",
  },

  // ── go build ───────────────────────────────────────────────────────
  {
    match: /(?:^|[;&|]\s*)go\s+build\b/,
    action: "block",
    message:
      "'go build' is forbidden. Use Make targets instead:\n\n" +
      "  make build  — build via the project Makefile",
  },

  // ── bun test ───────────────────────────────────────────────────────
  {
    match: /(?:^|[;&|]\s*)bun\s+test\b/,
    action: "block",
    message:
      "'bun test' is forbidden. Use Make targets instead:\n\n" +
      "  make test   — run tests via the project Makefile",
  },

  // ── pytest ─────────────────────────────────────────────────────────
  {
    match: shellToken("pytest"),
    action: "block",
    message:
      "Direct pytest is forbidden. Use Make targets instead:\n\n" +
      "  make test   — run tests via the project Makefile",
  },

  // ── golangci-lint ──────────────────────────────────────────────────
  {
    match: shellToken("golangci-lint"),
    action: "block",
    message:
      "Direct golangci-lint is forbidden. Use Make targets instead:\n\n" +
      "  make lint   — lint via the project Makefile",
  },

  // ── eslint ─────────────────────────────────────────────────────────
  {
    match: shellToken("eslint"),
    action: "block",
    message:
      "Direct eslint is forbidden. Use Make targets instead:\n\n" +
      "  make lint   — lint via the project Makefile",
  },

  // ── jest ───────────────────────────────────────────────────────────
  {
    match: shellToken("jest"),
    action: "block",
    message:
      "Direct jest is forbidden. Use Make targets instead:\n\n" +
      "  make test   — run tests via the project Makefile",
  },

  // ── black ──────────────────────────────────────────────────────────
  {
    match: shellToken("black"),
    action: "block",
    message:
      "Direct black is forbidden. Use Make targets instead:\n\n" +
      "  make fmt    — format via the project Makefile",
  },
];

// ---------------------------------------------------------------------------
// Default Makefile checks — mirror the copilot-cli create/edit validation
// ---------------------------------------------------------------------------

export const defaultMakefileChecks: readonly MakefileCheck[] = [
  {
    name: "SILENT",
    check: (c) => /^\.SILENT/m.test(c),
    message:
      "Makefile missing required directive: '.SILENT:'\n\n" +
      "Add it at the top (before first target):\n  .SILENT:\n\n" +
      "This suppresses recipe echoing without needing '@' prefixes.",
  },

  {
    name: "ONESHELL",
    check: (c) => /\.ONESHELL/.test(c),
    message:
      "Makefile missing required directive: '.ONESHELL:'\n\n" +
      "Add it at the top:\n  .ONESHELL:\n\n" +
      "This runs each recipe in a single shell instance.",
  },

  {
    name: "DEFAULT_GOAL",
    check: (c) => /\.DEFAULT_GOAL/.test(c),
    message:
      "Makefile missing required directive: '.DEFAULT_GOAL := help'\n\n" +
      "Add it at the top:\n  .DEFAULT_GOAL := help",
  },

  {
    name: "no-at-prefix",
    check: (c) => !/^\t@/m.test(c),
    message:
      "Makefile has '@' prefix in recipe lines — FORBIDDEN.\n\n" +
      "'.SILENT:' already suppresses all echoing. Remove every '@' from recipes:\n\n" +
      "  ✗  @pytest tests/\n" +
      "  ✓   pytest tests/",
  },

  {
    name: "qa-target",
    check: (c) => /(?:^\.PHONY:[^\n]*\bqa\b|^qa\s*:)/m.test(c),
    message:
      "Makefile missing required 'qa' target.\n\n" +
      "Add it as the quality gate:\n\n" +
      "  .PHONY: ... qa ...\n" +
      "  qa: check test",
  },
];
