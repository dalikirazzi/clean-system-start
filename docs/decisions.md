# Decisions

Why this setup looks the way it does. Each entry states what was decided, the evidence, and the trade-off accepted.

---

## Fetch upstream instead of vendoring

**Decided:** `install.ps1` clones [affaan-m/ECC](https://github.com/affaan-m/ECC) at install time. No ECC files live in this repo.

**Evidence:** Copies of this toolkit exist that were created once and never updated, while still pointing at the original author in their own plugin manifest. One such copy was ~40× smaller than the live upstream six months later (81 files vs 3,322). Vendoring reproduces exactly that failure.

**Trade-off:** Install needs network and `git`, and upstream renames can break the manifest. `install.ps1` reports missing entries rather than failing silently.

---

## Install no hooks

**Decided:** ECC's `hooks.json` is not installed. Not partially — none of it.

**Evidence:** Two hooks in it are incompatible with a normal setup, and neither failure is obvious until it bites:

1. A `PreToolUse` hook blocks `Write` to any `.md` file whose name isn't `README`, `CLAUDE`, `AGENTS`, or `CONTRIBUTING`, via `exit 1`. Any markdown-based notes or knowledge base becomes unwritable.
2. Another blocks `npm run dev` unless `$TMUX` is set. There is no tmux on Windows, so the dev server is blocked permanently.

Others run `npx prettier` and `npx tsc` on every single edit.

**Trade-off:** You lose the auto-format and type-check-on-edit conveniences. Run them in your editor or CI instead, where they don't sit in the critical path of every tool call.

**Generalisation:** a hook is not a suggestion. The engine runs it; the model cannot skip it; a non-zero exit cancels the action. Read hooks before installing them.

---

## Rules as pointers, not `@import`

**Decided:** `CLAUDE.md` names the rule directories and says when to read them. It does not `@import` them.

**Evidence:** `~/.claude/rules/` is not auto-loaded — it's a convention, so files there do nothing until referenced. The obvious wiring, `@import`, loads all 27 files into every session regardless of relevance. Measured: the rules total ~12,814 tokens. As pointers they cost 0.

**Trade-off:** an import is guaranteed to load; a pointer depends on the model following an instruction. If that turns out unreliable in practice, switch to `@import` and pay the tokens.

---

## Skip four commands and one skill

**Decided:** `/code-review`, `/plan`, `/verify`, `/security-review` and the `security-review` skill are not installed.

**Evidence:** Claude Code ships built-ins with these exact names. A same-named file in `~/.claude/` shadows the built-in silently — you'd lose working functionality and not be told.

**Trade-off:** if you prefer the ECC versions, add them to `manifest.json` knowingly.

---

## Measure hooks before trusting them

**Decided:** A "token optimizer" hook chain running on four events was removed after measurement.

**Evidence** (from its own 10,037-line log — 980 `PreToolUse` + 954 `PostToolUse` calls):

| | |
|---|---|
| `PreToolUse` | avg 1.21 s (max 13 s) → 19.7 min |
| `PostToolUse` | avg 1.41 s (max 13 s) → 22.5 min |
| Per tool call | **~2.6 s** |
| Total | **42 minutes** |

Return on that cost:

- `context-guard`: 0 triggers in 980 calls.
- `smart-read`: 0 successes in 980 — the mechanism intercepts `Read`, tries a cached read, and on success blocks the plain `Read` with `exit 2`. The log shows `[ALLOW] Read` 980 times, meaning it fell through every time. The comment above that call reads `CRITICAL FOR TOKEN SAVINGS!`.
- Cache directory: never created.
- `totalTokensSaved`: 0.
- 67 orphaned temp files — `PostToolUse` spawned a hidden background process per tool call and left cleanup to it; it never ran.
- A `UserPromptSubmit` hook printed ~250 tokens of all-zero statistics per message. Over a 40-message session: ~10,000 tokens to report savings of zero.

It also turned out to be the likely root cause of an intermittent `PreToolUse:Read hook error` that had previously been written off as "resolved itself, root cause not isolated."

**Trade-off:** none found. Removing it broke nothing. The MCP tools it wrapped (`smart_read`, `smart_grep`, …) still exist and can be called directly.

**Generalisation:** keep hooks that do real work (the session-capture hooks in `scripts/` write files and inject nothing). Measure the rest. Latency per tool call is the number to watch; it hides well because no single call feels slow.

---

## Install generously, but only lazy-loaded things

**Decided:** 16 agents + 18 skills is fine. Zero hooks is also fine. These aren't in tension.

**Evidence:** ~59,000 tokens of content costs ~1,770 tokens per session, because only one-line descriptions load up front. The full body loads on invocation. Standing overhead of the whole setup lands at ~3,982 tokens — ~2% of a 200K window.

**Trade-off:** description quality matters more than count. A bloated `description:` in frontmatter is paid every session; the body is not.

*Estimates use `words × 1.3`, ±15%. Built-in tool schemas aren't measurable from user space and are excluded.*
