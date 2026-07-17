<#
.SYNOPSIS
    Bootstrap a lean Claude Code setup: fetch a curated subset of ECC into ~/.claude.

.DESCRIPTION
    Clones affaan-m/ECC (MIT, (c) 2026 Affaan Mustafa) to a temp dir and copies the
    agents/commands/skills/rules listed in manifest.json into ~/.claude.

    Non-destructive by default: existing files are never overwritten, only reported.
    No hooks are installed. See README.md for why that is deliberate.

.PARAMETER DryRun
    Show what would happen. Touch nothing.

.PARAMETER Force
    Overwrite existing files instead of skipping them.

.PARAMETER ClaudeHome
    Target directory. Defaults to ~/.claude.

.EXAMPLE
    ./install.ps1 -DryRun
    ./install.ps1
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force,
    [string]$ClaudeHome = (Join-Path $HOME ".claude")
)

$ErrorActionPreference = "Stop"

function Say  { param([string]$m) Write-Host $m }
function Ok   { param([string]$m) Write-Host "  [ok]   $m" -ForegroundColor Green }
function Skip { param([string]$m) Write-Host "  [skip] $m" -ForegroundColor DarkGray }
function Warn { param([string]$m) Write-Host "  [warn] $m" -ForegroundColor Yellow }

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$manifestPath = Join-Path $root "manifest.json"

if (-not (Test-Path $manifestPath)) { throw "manifest.json not found next to install.ps1" }
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

Say ""
Say "Clean System Start"
Say "=================="
Say "  target   : $ClaudeHome"
Say "  upstream : $($manifest.upstream.repo)"
Say "  license  : $($manifest.upstream.license) (c) $($manifest.upstream.author)"
if ($DryRun) { Say "  MODE     : DRY RUN - nothing will be written" }
if ($Force)  { Warn "MODE: FORCE - existing files WILL be overwritten" }
Say ""

# --- Preflight -------------------------------------------------------------
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git is required but was not found on PATH."
}

# --- Clone upstream --------------------------------------------------------
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("ecc-" + [guid]::NewGuid().ToString().Substring(0, 8))
Say "Fetching upstream (shallow clone)..."
if ($DryRun) {
    Say "  would clone $($manifest.upstream.repo) -> $tmp"
    Say ""
    Say "Planned installation:"
    Say "  agents   : $($manifest.agents.Count)"
    Say "  commands : $($manifest.commands.Count)"
    Say "  skills   : $($manifest.skills.Count)"
    Say "  rules    : $($manifest.rules -join ', ')"
    Say ""
    Say "No hooks are installed (deliberate - see README)."
    exit 0
}

git clone --depth 1 --quiet $manifest.upstream.repo $tmp
if ($LASTEXITCODE -ne 0) { throw "Clone failed. Check your network and that the repo is reachable." }
Ok "cloned to $tmp"
Say ""

$stats = @{ installed = 0; skipped = 0; missing = 0 }

function Copy-Item-Safe {
    param([string]$Source, [string]$Dest, [string]$Label, [switch]$Directory)

    if (-not (Test-Path $Source)) {
        Warn "$Label - not found upstream (renamed or removed?)"
        $script:stats.missing++
        return
    }
    if ((Test-Path $Dest) -and -not $Force) {
        Skip "$Label - already exists"
        $script:stats.skipped++
        return
    }
    $parent = Split-Path -Parent $Dest
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }

    if ($Directory) { Copy-Item $Source $Dest -Recurse -Force }
    else            { Copy-Item $Source $Dest -Force }
    Ok $Label
    $script:stats.installed++
}

# --- Agents ----------------------------------------------------------------
Say "Agents ($($manifest.agents.Count)):"
foreach ($a in $manifest.agents) {
    Copy-Item-Safe -Source (Join-Path $tmp "agents/$a.md") -Dest (Join-Path $ClaudeHome "agents/$a.md") -Label $a
}
Say ""

# --- Commands --------------------------------------------------------------
Say "Commands ($($manifest.commands.Count)):"
foreach ($c in $manifest.commands) {
    Copy-Item-Safe -Source (Join-Path $tmp "commands/$c.md") -Dest (Join-Path $ClaudeHome "commands/$c.md") -Label "/$c"
}
Say ""

# --- Skills ----------------------------------------------------------------
Say "Skills ($($manifest.skills.Count)):"
foreach ($s in $manifest.skills) {
    Copy-Item-Safe -Source (Join-Path $tmp "skills/$s") -Dest (Join-Path $ClaudeHome "skills/$s") -Label $s -Directory
}
Say ""

# --- Rules -----------------------------------------------------------------
Say "Rules ($($manifest.rules -join ', ')):"
foreach ($r in $manifest.rules) {
    Copy-Item-Safe -Source (Join-Path $tmp "rules/$r") -Dest (Join-Path $ClaudeHome "rules/$r") -Label "rules/$r" -Directory
}
Say ""

# --- Local extras ----------------------------------------------------------
Say "Local files from this repo:"
$fable = Join-Path $root "commands/fable.md"
Copy-Item-Safe -Source $fable -Dest (Join-Path $ClaudeHome "commands/fable.md") -Label "/fable"

$claudeMd = Join-Path $ClaudeHome "CLAUDE.md"
if (Test-Path $claudeMd) {
    Skip "CLAUDE.md - already exists (yours is kept; compare with CLAUDE.md in this repo)"
    $stats.skipped++
} else {
    Copy-Item (Join-Path $root "CLAUDE.md") $claudeMd -Force
    Ok "CLAUDE.md"
    $stats.installed++
}
Say ""

# --- Cleanup ---------------------------------------------------------------
Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue

# --- Report ----------------------------------------------------------------
Say "Done."
Say "  installed : $($stats.installed)"
Say "  skipped   : $($stats.skipped)  (existing files are never clobbered; use -Force to override)"
if ($stats.missing -gt 0) {
    Warn "missing   : $($stats.missing)  - upstream moved or renamed these; check manifest.json"
}
Say ""
Say "Rules are installed but INERT until referenced."
Say "  ~/.claude/rules/ is not auto-loaded by Claude Code. See the pointer block in this repo's"
Say "  CLAUDE.md and copy it into yours to activate them without paying the per-session cost."
Say ""
Say "No hooks were installed. This is deliberate - see README.md."
Say ""
