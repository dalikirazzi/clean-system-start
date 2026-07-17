# Global Claude Code Instructions

Engineering discipline:

- Stay in scope.
- Inspect before editing.
- Use real available tools only.
- Never pretend a tool exists.
- Never fabricate command output, logs, tests, file contents, web results, citations, or installed MCP servers.
- Make small, reversible, testable changes.
- Do not claim completion without verification.
- Separate verified facts from assumptions.
- Ask before destructive, sensitive, broad, production, auth, payment, database, deployment, secret, or security-related actions.
- Report changed files, verification, assumptions, and unverified items.

User simplicity:
- Do not unnecessarily instruct the user to use terminal, Git, package managers, or config files.
- If tools are available, handle technical execution yourself.
- Ask the user for manual action only when credentials, approval, login, or missing tools require it.

Engineering rules (installed at `~/.claude/rules/`):
- These are pointers, NOT auto-loaded imports - read the files only when they fit the task, so the token cost is paid only when the rules are actually relevant.
- When writing React / TypeScript / web frontend code, consult `~/.claude/rules/react/`, `~/.claude/rules/typescript/`, and `~/.claude/rules/web/` before writing the code, and follow them. Read only the files that fit the task (e.g. `patterns.md` when structuring components, `security.md` when handling user input, `design-quality.md` for UI work) - do not load a whole directory by default.
- `~/.claude/rules/common/` (coding-style, testing, security, git-workflow, patterns, performance) is language-agnostic - consult it when starting substantial work on any project.
- Only react, typescript, web, and common are installed. Rule sets for other stacks (python, go, rust, java, kotlin, swift, dart/flutter, vue, angular, php, ruby, csharp, cpp, and more) exist upstream but are NOT installed. When a new project's stack is decided during planning, remind the user that these rule sets exist and offer to install the matching one. This is a standing habit - do not wait to be asked.

Third-party automation:
- Do not trust a hook, plugin, or MCP server to be earning its keep just because it is installed. Measure it: latency per tool call, and whether its claimed output is actually produced.
- If a vendor's automation is broken, prefer the simple direct fix (a plain instruction in this file) over debugging someone else's machinery.
- Never install third-party hooks without reading them first. Hooks run unconditionally and can cancel actions with a non-zero exit.
