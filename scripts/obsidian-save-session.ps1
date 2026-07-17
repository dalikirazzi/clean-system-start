<#
    Stop hook - capture the session transcript into the knowledge base.

    Extracts the user/assistant text from the session transcript and writes it to
    <vault>/inbox/unprocessed-sessions/, then appends one line to index.md and
    logs/processing-log.md. Distilling those raw captures into wiki pages is a
    separate, deliberate step - this hook only captures.

    Setup:
      Set CLAUDE_VAULT_ROOT to your vault path, or edit the fallback below.
      Register in ~/.claude/settings.json:

        "Stop": [
          { "hooks": [ { "type": "command", "timeout": 30,
              "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"<path>\\obsidian-save-session.ps1\"" } ] }
        ]

    Notes:
      - Stop fires at every stop, so the index line is deduplicated.
      - This hook does real work and is cheap - it writes files, it does not
        inject anything into context. Contrast with the hooks measured in README.
#>
param()

$ErrorActionPreference = 'Stop'

try {
    $inputJson = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($inputJson)) { exit 0 }
    $data = $inputJson | ConvertFrom-Json
} catch {
    exit 0
}

$transcriptPath = $data.transcript_path
$sessionId = $data.session_id
if (-not $transcriptPath -or -not (Test-Path -LiteralPath $transcriptPath)) { exit 0 }
if (-not $sessionId) { $sessionId = "unknown" }

$vaultRoot = $env:CLAUDE_VAULT_ROOT
if (-not $vaultRoot) { $vaultRoot = Join-Path $HOME "Obsidian\MyVault" }  # <-- edit or set CLAUDE_VAULT_ROOT

$vaultDir = Join-Path $vaultRoot "inbox\unprocessed-sessions"
if (-not (Test-Path -LiteralPath $vaultDir)) {
    New-Item -ItemType Directory -Path $vaultDir -Force | Out-Null
}

$lines = Get-Content -LiteralPath $transcriptPath -Encoding UTF8
$sb = New-Object System.Text.StringBuilder
$firstTimestamp = $null
$sessionShort = $sessionId.Substring(0, [Math]::Min(8, $sessionId.Length))

foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    try {
        $entry = $line | ConvertFrom-Json
    } catch {
        continue
    }

    if (-not $firstTimestamp -and $entry.timestamp) {
        $firstTimestamp = $entry.timestamp
    }

    $type = $entry.type
    if ($type -ne "user" -and $type -ne "assistant") { continue }

    $msg = $entry.message
    if (-not $msg) { continue }
    $role = $msg.role
    $content = $msg.content

    $textParts = New-Object System.Collections.Generic.List[string]
    if ($content -is [string]) {
        $textParts.Add($content)
    } elseif ($content) {
        foreach ($block in $content) {
            if ($block.type -eq "text" -and $block.text) {
                $textParts.Add($block.text)
            }
        }
    }

    if ($textParts.Count -eq 0) { continue }
    $text = ($textParts -join "`n").Trim()
    if ([string]::IsNullOrWhiteSpace($text)) { continue }

    $label = if ($role -eq "user") { "User" } else { "Claude" }
    [void]$sb.AppendLine("### $label")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine($text)
    [void]$sb.AppendLine()
}

$dateForName = Get-Date -Format "yyyy-MM-dd"
if ($firstTimestamp) {
    try {
        $dateForName = ([DateTime]$firstTimestamp).ToString("yyyy-MM-dd")
    } catch {}
}

$fileName = "${dateForName}_$sessionShort.md"
$filePath = Join-Path $vaultDir $fileName

$header = "# Session $sessionShort - $dateForName`n`nSession ID: $sessionId`n`n---`n`n"
$body = $sb.ToString()

if ([string]::IsNullOrWhiteSpace($body)) { exit 0 }

Set-Content -LiteralPath $filePath -Value ($header + $body) -Encoding UTF8

$logPath = Join-Path $vaultRoot "logs\processing-log.md"
$indexPath = Join-Path $vaultRoot "index.md"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"

# Stop fires at every stop - do not append the same session twice.
$alreadyListed = $false
if (Test-Path -LiteralPath $indexPath) {
    $alreadyListed = Select-String -LiteralPath $indexPath -SimpleMatch "- $fileName --" -Quiet -ErrorAction SilentlyContinue
}

if (-not $alreadyListed) {
    if (Test-Path -LiteralPath $indexPath) {
        Add-Content -LiteralPath $indexPath -Value "- $fileName -- $dateForName" -Encoding UTF8
    }
    if (Test-Path -LiteralPath $logPath) {
        Add-Content -LiteralPath $logPath -Value "- $timestamp | Session $sessionShort captured -> inbox/unprocessed-sessions/$fileName (unprocessed)" -Encoding UTF8
    }
}

exit 0
