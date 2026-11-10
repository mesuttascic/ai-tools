# Handoff bench (PowerShell): ~/.claude/projects altındaki en büyük N session'ın toplam token'ını
# handoff-tail.ps1 -1 / -2 çıktılarıyla karşılaştırır. Markdown tablo + CSV üretir.
# handoff-bench.sh'in birebir karşılığı; jq gerektirmez.
#
# Kullanım: .\handoff-bench.ps1 [-N 10]
# Gereksinim: handoff-tail.ps1 (aynı klasörde)

param([int]$N = 10)
$ErrorActionPreference = 'Stop'

$Dir  = $PSScriptRoot
$Tail = Join-Path $Dir 'handoff-tail.ps1'
$Root = Join-Path $HOME '.claude/projects'
if (-not (Test-Path $Tail)) { Write-Error "handoff-tail.ps1 bulunamadı: $Tail"; exit 1 }

$utf8 = [Text.Encoding]::UTF8
function Est([string]$s)   { [int][math]::Floor($utf8.GetByteCount($s) / 4) }   # karakter/4
function Words([string]$s) { ($s -split '\s+' | Where-Object { $_ }).Count }

function Get-Strings($o) {
    if ($null -eq $o) { return }
    if ($o -is [string]) { $o; return }
    if ($o -is [System.Collections.IEnumerable]) { foreach ($x in $o) { Get-Strings $x }; return }
    if ($o -is [psobject] -and $o.PSObject.Properties.Count) {
        foreach ($p in $o.PSObject.Properties) { Get-Strings $p.Value }
    }
}

$OutCsv = Join-Path $Dir 'handoff-bench.csv'
'klasor,session,baslik,total_tok,min1_tok,min2_tok,min1_kelime,min2_kelime' | Set-Content $OutCsv -Encoding utf8

'| Session klasörü | Session başlığı | Total token | -1 token | -2 token | -1 tasarruf |'
'|---|---|---:|---:|---:|---:|'

# Alt-agent (subagents/) dosyalarını hariç tut, boyuta göre en büyük N
$files = Get-ChildItem $Root -Depth 1 -Filter '*.jsonl' -File -ErrorAction SilentlyContinue |
         Sort-Object Length -Descending | Select-Object -First $N

foreach ($file in $files) {
    $f = $file.FullName
    $folder = $file.Directory.Name
    $sid = $file.BaseName.Substring(0, [math]::Min(8, $file.BaseName.Length))

    $recs = foreach ($line in [IO.File]::ReadLines($f)) {
        if (-not $line) { continue }
        try { $line | ConvertFrom-Json } catch { }
    }

    $title = ''
    foreach ($r in $recs) {
        if ($r.type -in 'summary', 'custom-title', 'ai-title') {
            $t = $r.summary ?? $r.customTitle ?? $r.aiTitle ?? $r.title
            if ($t) { $title = [string]$t }
        }
    }
    if (-not $title) {
        $title = $recs |
            Where-Object { $_.type -eq 'user' -and $_.message.content -is [string] -and $_.isMeta -ne $true } |
            ForEach-Object { $_.message.content -split "`n" } |
            Where-Object { -not $_.StartsWith('<') } |
            Select-Object -First 1
    }
    $title = ([string]$title) -replace '[\n|,]', ' '
    if ($title.Length -gt 60) { $title = $title.Substring(0, 60) }

    $total = 0
    $last = $recs | Where-Object { $_.type -eq 'assistant' -and $null -ne $_.message.usage } | Select-Object -Last 1
    if ($last) {
        $u = $last.message.usage
        $total = [int64]($u.input_tokens ?? 0) + [int64]($u.cache_read_input_tokens ?? 0) + [int64]($u.cache_creation_input_tokens ?? 0)
    }
    $mark = ''
    if ($total -eq 0) {
        $total = Est ((($recs | ForEach-Object { Get-Strings $_.message.content }) -join "`n"))
        $mark = '*'
    }

    $o1 = try { (& $Tail -1 $f 2>$null) -join "`n" } catch { '' }
    $o2 = try { (& $Tail -2 $f 2>$null) -join "`n" } catch { '' }
    $t1 = Est $o1; $w1 = Words $o1
    $t2 = Est $o2; $w2 = Words $o2
    $saving = if ($total -gt 0) { [string]::Format([cultureinfo]::InvariantCulture, '{0:F1}%', 100 * (1 - $t1 / $total)) } else { '-' }

    "| $folder | $title ($sid) | $total$mark | $t1 | $t2 | $saving |"
    "`"$folder`",$sid,`"$title`",$total,$t1,$t2,$w1,$w2" | Add-Content $OutCsv -Encoding utf8
}

''
'(*) usage alanı yok, karakter/4 ile tahmin edildi. -1/-2 sütunları her zaman karakter/4 tahminidir.'
"CSV: $OutCsv"
