# Notice and Attribution

## Upstream: ECC (everything-claude-code)

The agents, commands, skills, and rules that `install.ps1` fetches are **not the work of this repository.** They are:

> **ECC — everything-claude-code**
> Copyright (c) 2026 Affaan Mustafa
> https://github.com/affaan-m/ECC
> MIT License

This repository **does not vendor, copy, or redistribute** those files. `install.ps1` clones the upstream repository at install time and copies a selected subset into your local `~/.claude/`. The upstream MIT license and copyright notice travel with the clone.

If you use this bootstrap, you are using Affaan Mustafa's work. Star the upstream repo, not just this one.

### A note on repo identity

If you searched for this toolkit, you may find copies. At the time of writing:

- `affaan-m/ECC` — the live upstream (renamed from `affaan-m/everything-claude-code`). Actively maintained.
- Various copies exist that are **not forks** and stopped receiving updates shortly after being created, while still pointing at `affaan-m` in their own plugin manifests.

This bootstrap targets the upstream by design, so it follows the maintained source rather than pinning a snapshot.

## This repository

Original to this repo, MIT licensed under [LICENSE](LICENSE):

- `install.ps1` and `manifest.json` — the installer and the curated selection
- `CLAUDE.md` — global instruction template
- `commands/fable.md` — a strict-discipline mode command
- `scripts/*.ps1` — Obsidian session-capture hooks
- `README.md`, `docs/` — the reasoning and measurements

## Not included

`impeccable` and `browser-harness` are shipped with Claude Code by Anthropic. They are referenced in the docs for context but are **not** redistributed here and are not installed by `install.ps1`.
