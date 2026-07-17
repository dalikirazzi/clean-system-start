<#
    SessionStart hook - load knowledge-base state into context.

    Reads hot.md (rolling summary) and index.md (catalog) from an Obsidian vault
    and injects them as additionalContext at session start.

    Setup:
      Set CLAUDE_VAULT_ROOT to your vault path, or edit the fallback below.
      Register in ~/.claude/settings.json:

        "SessionStart": [
          { "hooks": [ { "type": "command", "timeout": 15,
              "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"<path>\\obsidian-load-history.ps1\"" } ] }
        ]

    Cost note: whatever this injects is paid on EVERY session. Keep hot.md and
    index.md small - the 4000-char cap below is a backstop, not a target.
#>
param()

$ErrorActionPreference = 'Stop'

$vaultRoot = $env:CLAUDE_VAULT_ROOT
if (-not $vaultRoot) { $vaultRoot = Join-Path $HOME "Obsidian\MyVault" }  # <-- edit or set CLAUDE_VAULT_ROOT

$hotPath = Join-Path $vaultRoot "hot\hot.md"
$indexPath = Join-Path $vaultRoot "index.md"

function Read-Capped($path, $cap) {
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($content.Length -gt $cap) {
        $content = $content.Substring(0, $cap) + "`n...(truncated)..."
    }
    return $content
}

$hot = Read-Capped $hotPath 4000
$index = Read-Capped $indexPath 4000

if (-not $hot -and -not $index) {
    Write-Output '{}'
    exit 0
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("Knowledge base (Obsidian vault) state - loaded automatically:")
[void]$sb.AppendLine()

if ($hot) {
    [void]$sb.AppendLine("## hot.md (current state summary)")
    [void]$sb.AppendLine($hot)
    [void]$sb.AppendLine()
}

if ($index) {
    [void]$sb.AppendLine("## index.md (vault catalog)")
    [void]$sb.AppendLine($index)
    [void]$sb.AppendLine()
}

[void]$sb.AppendLine("Note: raw session transcripts live in inbox/unprocessed-sessions/ and are NOT loaded here. If the user asks to update the vault, read the unprocessed sessions listed in index.md, update the wiki pages + hot/hot.md + index.md, and append a line to logs/processing-log.md.")

$contextText = $sb.ToString()

$result = [ordered]@{
    hookSpecificOutput = [ordered]@{
        hookEventName = "SessionStart"
        additionalContext = $contextText
    }
}

$result | ConvertTo-Json -Depth 10 -Compress
exit 0
