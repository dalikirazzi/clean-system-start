# Clean System Start

A bootstrap for a **lean, measured Claude Code setup** on a fresh machine.

This is not another "install everything" toolkit. It is the opposite: a curated selection, and — more importantly — **the reasoning and the measurements behind what was left out.**

Everything here was measured on a real Windows 10 machine, not assumed.

---

## What this gives you

| What | Count | Source |
|---|---|---|
| Agents | 16 | fetched from [affaan-m/ECC](https://github.com/affaan-m/ECC) |
| Commands | 8 | fetched from ECC |
| Skills | 18 | fetched from ECC |
| Rules | 27 | fetched from ECC (`common`, `typescript`, `react`, `web`) |
| `CLAUDE.md` | 1 | this repo |
| Obsidian session-capture hooks | 2 scripts | this repo |

The ECC files are **not vendored here.** `install.ps1` fetches them from upstream at install time, so this repo cannot go stale and the license stays clean. See [NOTICE.md](NOTICE.md).

## Install

```powershell
git clone https://github.com/dalikirazzi/clean-system-start.git
cd clean-system-start
./install.ps1
```

The script is **non-destructive by default**: it never overwrites an existing file, and prints what it skipped. Use `-DryRun` to see the plan without touching anything, `-Force` to overwrite.

---

## The three decisions that matter

Most of the value in this repo is here, not in the file list.

### 1. No hooks. Not one.

ECC ships a `hooks.json`. It is not installed, deliberately.

A hook is not advice — the engine runs it, and the model cannot skip it. A hook returning `exit 1` **cancels the action.** Two of ECC's hooks would have quietly broken this setup:

- A `PreToolUse` hook blocks writing any new `.md` file except `README/CLAUDE/AGENTS/CONTRIBUTING`. If your notes, docs, or knowledge base are markdown, this makes writing to them impossible.
- Another blocks `npm run dev` outside tmux. There is no tmux on Windows, so this blocks the dev server permanently.

Read third-party hooks before installing them. They run on your machine, on every tool call, whether you notice or not.

### 2. Rules are pointers, not imports.

`~/.claude/rules/` is **not auto-loaded by Claude Code.** It is a convention. Files sitting there do nothing until something references them.

The obvious wiring is `@import` in `CLAUDE.md`. This repo does not do that. `@import` loads all 27 rule files into **every** session — including sessions that have nothing to do with React.

Instead `CLAUDE.md` carries a pointer: *"when writing React/TypeScript code, read the relevant files from `~/.claude/rules/react/`."* The cost is paid only when the rules are actually relevant.

Trade-off, stated honestly: an import is guaranteed; a pointer relies on the model following an instruction. If that proves unreliable for you, switch to `@import`.

### 3. Measure your hooks. Ours cost 42 minutes and returned nothing.

The setup this repo came from ran a "token optimizer" hook chain on four events. Measured from its own 10,037-line log:

| Metric | Result |
|---|---|
| `PreToolUse` latency | avg **1.21 s** (max 13 s) → 19.7 min total |
| `PostToolUse` latency | avg **1.41 s** (max 13 s) → 22.5 min total |
| Per tool call | **~2.6 seconds** |
| Total time spent waiting | **42 minutes** |

What it produced, on every measurable axis:

- `context-guard` fired **0 times** in 980 calls.
- `smart-read` succeeded **0 times out of 980** — every call fell through to plain `Read`. The comment above that line read `CRITICAL FOR TOKEN SAVINGS!`.
- The cache directory was never created.
- `totalTokensSaved` stayed at `0`.
- 67 orphaned temp files, because the background cleanup never ran.
- One `UserPromptSubmit` hook printed ~250 tokens of all-zero statistics **on every message** — a token optimizer spending tokens to report that it had saved none.

It was removed. Nothing broke.

The lesson isn't "hooks are bad" — the session-capture hooks in this repo do real work and are kept. The lesson is that automation you never measured is a cost you never counted.

---

## Token cost, measured

Installing ~59,000 tokens' worth of content (agents 20,876 + skills 38,626 + rules 12,814) costs **~1,770 tokens per session**, because Claude Code loads skills and agents lazily — only the one-line description loads up front; the body loads when invoked. Rules cost **zero** because they are pointers.

Total standing overhead of the full setup: **~3,982 tokens** — about **2%** of a 200K window.

| Component | Tokens |
|---|---|
| Skill descriptions (18) | ~1,114 |
| `CLAUDE.md` | ~743 |
| Agent descriptions (16) | ~656 |
| Rules (27 files) | **0** |

So: install generously, but only things that load lazily. The thing to watch is not how many skills you have — it's your hooks and your always-loaded context.

*Estimates use `words × 1.3`; treat them as ±15%. Built-in tool schemas are not included — they aren't measurable from user space.*

---

## What is NOT here, on purpose

No secrets, no personal data, no history. Specifically excluded: `.claude.json` (contains MCP auth tokens), `memory/`, `sessions/`, `history.jsonl`, `telemetry/`, `cache/`, and any knowledge-base content.

If you fork this, keep it that way. `.claude.json` in particular holds API keys.

## Not included, but worth knowing

`impeccable` and `browser-harness` are shipped by Claude Code itself, not by this repo — don't expect `install.ps1` to create them.

Rule sets for other stacks (python, go, rust, java, kotlin, swift, dart, vue, angular, php, ruby, csharp, cpp…) exist in ECC and are **not** installed by default. Add them to `manifest.json` if you want them.

## Credits

The agents, commands, skills, and rules are the work of **Affaan Mustafa** ([affaan-m/ECC](https://github.com/affaan-m/ECC)), MIT licensed. This repo curates and bootstraps them; it does not claim them. See [NOTICE.md](NOTICE.md).

## License

MIT — see [LICENSE](LICENSE). Applies to the contents of this repository (the installer, `CLAUDE.md`, scripts, and docs), not to the upstream files it fetches.
