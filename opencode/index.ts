/**
 * OpenCode plugin: Makefile structure enforcer.
 *
 * Mirrors the copilot-cli pre-tool hook:
 *   - Blocks direct tool invocations (pytest, ruff, go test, eslint, jest…).
 *   - Validates Makefile content on create/edit: .SILENT:, .ONESHELL:,
 *     .DEFAULT_GOAL, no @ in recipes, qa: target required.
 *
 * Install from this repository (project-level):
 *   Copy core.ts + index.ts to .opencode/plugins/
 */
import type { Plugin } from "@opencode-ai/plugin";
import { appendFileSync, mkdirSync } from "node:fs";
import { basename, join } from "node:path";
import {
  BASH_TOOL_ADDENDUM,
  MAKEFILE_POLICY,
  defaultCommandRules,
  defaultMakefileChecks,
  intercept,
  validateMakefile,
} from "./core";

const MAKEFILE_NAMES = new Set(["Makefile", "makefile", "GNUmakefile"]);

function isMakefile(path: unknown): boolean {
  if (typeof path !== "string") return false;
  return MAKEFILE_NAMES.has(basename(path));
}

export const MakefileEnforcerPlugin: Plugin = async ({ directory }) => {
  const logDir = join(directory, ".opencode", "logs");
  const deniedLog = join(logDir, "pre-tool-denied.log");

  function logDenial(reason: string): void {
    try {
      mkdirSync(logDir, { recursive: true });
      appendFileSync(deniedLog, `denied at ${new Date().toISOString()}: ${reason}\n`);
    } catch {
      // Logging failure must never block enforcement.
    }
  }

  return {
    // ── Proactive policy injection ────────────────────────────────────────────

    // Inject Makefile policy into the system prompt so the LLM knows the
    // rules before it has a chance to violate them.
    "experimental.chat.system.transform": async (_input, output) => {
      output.system.push(MAKEFILE_POLICY);
    },

    // Augment the bash tool description so the blocked-command list appears
    // in every tool-call context window.
    "tool.definition": async (input, output) => {
      if (input.toolID === "bash") {
        output.description += BASH_TOOL_ADDENDUM;
      }
    },

    // Preserve the Makefile policy during session compaction so it survives
    // long sessions that summarise their history.
    "experimental.session.compacting": async (_input, output) => {
      output.context.push(MAKEFILE_POLICY);
    },

    // ── Reactive enforcement ──────────────────────────────────────────────────

    "tool.execute.before": async (input, output) => {
      const args = (output as { args?: Record<string, unknown> }).args ?? {};

      // ── bash tool: block direct tool invocations ──────────────────────────
      if (input.tool === "bash") {
        const command = args["command"];
        if (typeof command !== "string" || !command.trimStart()) return;

        const trimmed = command.trimStart();
        try {
          intercept(trimmed, defaultCommandRules);
        } catch (err) {
          logDenial(trimmed);
          throw err;
        }
        return;
      }

      // ── create tool: validate full Makefile content ───────────────────────
      if (input.tool === "create") {
        const path = args["path"];
        const content = args["file_text"] ?? args["content"];
        if (!isMakefile(path) || typeof content !== "string") return;

        try {
          validateMakefile(content, defaultMakefileChecks);
        } catch (err) {
          logDenial(`create ${String(path)}: ${(err as Error).message}`);
          throw err;
        }
        return;
      }

      // ── edit tool: validate new_str added to a Makefile ───────────────────
      if (input.tool === "edit") {
        const path = args["path"];
        const newStr = args["new_str"];
        const oldStr = args["old_str"];
        if (!isMakefile(path)) return;

        const errors: string[] = [];

        // Forbid adding @ in new recipe lines
        if (typeof newStr === "string" && /^\t@/m.test(newStr)) {
          errors.push(
            "Adding '@' prefix to recipe lines is FORBIDDEN — '.SILENT:' already suppresses echoing. Remove the '@' prefix.",
          );
        }

        // Forbid removing .SILENT:
        if (
          typeof oldStr === "string" &&
          typeof newStr === "string" &&
          /^\.SILENT/m.test(oldStr) &&
          !/^\.SILENT/m.test(newStr)
        ) {
          errors.push("Removing '.SILENT:' is FORBIDDEN — it is a required directive.");
        }

        // Forbid removing .ONESHELL:
        if (
          typeof oldStr === "string" &&
          typeof newStr === "string" &&
          /\.ONESHELL/.test(oldStr) &&
          !/\.ONESHELL/.test(newStr)
        ) {
          errors.push("Removing '.ONESHELL:' is FORBIDDEN — it is a required directive.");
        }

        if (errors.length > 0) {
          const reason = errors.join("\n");
          logDenial(`edit ${String(path)}: ${reason}`);
          throw new Error(reason);
        }
        return;
      }
    },
  };
};
