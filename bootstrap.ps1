# Links shared rules/skills into ~/.claude and seeds personal files from
# agent/templates on first run. Idempotent — safe to re-run.
# Symlinks require Windows Developer Mode (Settings > For developers) or admin.
$ErrorActionPreference = "Stop"

$Repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null

function Link($src, $dst) {
    if (Test-Path $dst) {
        $item = Get-Item $dst -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            Remove-Item $dst -Force
        } else {
            Move-Item $dst "$dst.bak.$(Get-Date -Format yyyyMMddHHmmss)"
            Write-Host "backed up: $dst"
        }
    }
    New-Item -ItemType SymbolicLink -Path $dst -Target $src | Out-Null
    Write-Host "link:   $dst -> $src"
}

function Seed($src, $dst) {
    if (Test-Path $dst) {
        Write-Host "kept:   $dst (personal, not touched)"
    } else {
        Copy-Item $src $dst
        Write-Host "seeded: $dst (edit freely — stays local)"
    }
}

Link (Join-Path $Repo "agent\rules")  (Join-Path $ClaudeDir "rules")
Link (Join-Path $Repo "agent\skills") (Join-Path $ClaudeDir "skills")
Seed (Join-Path $Repo "agent\templates\CLAUDE.md")     (Join-Path $ClaudeDir "CLAUDE.md")
Seed (Join-Path $Repo "agent\templates\settings.json") (Join-Path $ClaudeDir "settings.json")

Write-Host ""
Write-Host "Done. Claude Code reads ~/.claude natively; Cursor picks up the same"
Write-Host "skills via its ~/.claude/skills compatibility path. For Cursor rules,"
Write-Host "paste your ~/.claude/CLAUDE.md once into Cursor > Settings > Rules."
