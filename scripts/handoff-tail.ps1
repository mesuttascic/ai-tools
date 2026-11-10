# Handoff tail (PowerShell): handoff-tail.sh'in karşılığı. jq programı tek kaynak olsun diye
# handoff-tail.sh içindeki <<'JQ' bloğundan okunur.
#
# Kullanım: .\handoff-tail.ps1 [-K] [session.jsonl]    ya da    .\handoff-tail.ps1 --list
# Ortam: MAXCHARS (600), FULL (0), PREV (1). Gereksinim: jq

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$projDir = Join-Path $HOME ('.claude/projects/' + ((Get-Location).Path -replace '[^A-Za-z0-9]', '-'))

if ($args[0] -eq '--list') {
    Get-ChildItem $projDir -Filter '*.jsonl' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 10
    exit 0
}

$arg = if ($args.Count -ge 1) { [string]$args[0] } else { '-1' }
if ($arg -notmatch '^-[0-9]+$') { Write-Error 'İlk parametre -1, -2 ... olmalı'; exit 1 }
$K        = $arg.Substring(1)
$file     = if ($args.Count -ge 2) { [string]$args[1] } else { '' }
$maxChars = $env:MAXCHARS ?? '600'
$full     = $env:FULL ?? '0'

if (-not $file) {
    $prev = [int]($env:PREV ?? '1')
    $file = Get-ChildItem $projDir -Filter '*.jsonl' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -Skip $prev -First 1 |
            ForEach-Object FullName
    if (-not $file) { Write-Error "Session dosyası bulunamadı: $projDir (dosya yolunu 2. parametre olarak verebilirsin)"; exit 1 }
}

$sh = Get-Content (Join-Path $PSScriptRoot 'handoff-tail.sh') -Raw
$prog = [regex]::Match($sh, "(?s)<<'JQ'[^\n]*\n(.*?)\r?\nJQ\r?\n").Groups[1].Value
$progFile = New-TemporaryFile
try {
    Set-Content $progFile $prog -Encoding utf8NoBOM
    "# Kaynak: $file"
    & jq -s -r --argjson K $K --argjson max $maxChars --arg full $full --from-file $progFile.FullName $file
} finally { Remove-Item $progFile -ErrorAction SilentlyContinue }
