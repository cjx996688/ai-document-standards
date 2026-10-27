param([switch]$UseLocalStandard, [string]$ConfigDirectory)
$ErrorActionPreference = 'Stop'
$base = 'https://raw.githubusercontent.com/cjx996688/ai-document-standards/main'
$codexHome = if ($ConfigDirectory) { $ConfigDirectory } elseif ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
New-Item -Path $codexHome -ItemType Directory -Force | Out-Null

# ASCII-only bootstrap for Windows PowerShell 5.1, which assumes ANSI for BOM-less scripts.
$spec = Join-Path $codexHome 'word_format.md'
$tmp = "$spec.tmp"
$source = Join-Path $PSScriptRoot 'word_format.md'
try {
    if ($UseLocalStandard) {
        Copy-Item -LiteralPath $source -Destination $tmp -Force
    } else {
        Invoke-WebRequest -UseBasicParsing -Uri "$base/word_format.md" -OutFile $tmp -TimeoutSec 30
    }
    if ((Get-Item -LiteralPath $tmp).Length -eq 0) { throw 'Empty standard file.' }
    Move-Item -LiteralPath $tmp -Destination $spec -Force
    Write-Host 'Word standard refreshed.'
} catch {
    Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
    if ((Test-Path -LiteralPath $spec) -and (Get-Item -LiteralPath $spec).Length -gt 0) {
        Write-Warning 'GitHub download failed; retained local cached standard.'
    } elseif (Test-Path -LiteralPath $source) {
        Copy-Item -LiteralPath $source -Destination $spec -Force
        Write-Warning 'GitHub download failed; used repository copy. Update manually when online.'
    } else {
        throw 'Cannot obtain the Word formatting standard from GitHub or local files.'
    }
}

$agents = Join-Path $codexHome 'AGENTS.md'
$existing = ''
if (Test-Path -LiteralPath $agents) {
    # Avoid PowerShell's pipeline converting an empty string expression to $null.
    $readText = [System.IO.File]::ReadAllText($agents, [System.Text.Encoding]::UTF8)
    if ($null -ne $readText) { $existing = [string]$readText }
}
$rule = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot 'AGENTS.global-snippet.md'), [System.Text.Encoding]::UTF8).TrimEnd()
$starts = [regex]::Matches($existing, '<!-- WORD_STANDARD_START -->').Count
$ends = [regex]::Matches($existing, '<!-- WORD_STANDARD_END -->').Count
$pattern = '(?ms)^<!-- WORD_STANDARD_START -->\r?\n.*?^<!-- WORD_STANDARD_END -->(?:\r?\n|$)'
if ($starts -eq 0 -and $ends -eq 0) {
    $updated = if ($existing.Length) { $existing.TrimEnd() + "`r`n`r`n" + $rule + "`n" } else { $rule + "`n" }
} elseif ($starts -eq 1 -and $ends -eq 1 -and [regex]::IsMatch($existing, $pattern)) {
    $updated = [regex]::Replace($existing, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $rule + "`n" })
} else {
    throw 'Malformed or duplicate Word rule markers; AGENTS.md was not changed.'
}
if ($updated -cne $existing) {
    if (Test-Path -LiteralPath $agents) {
        Copy-Item -LiteralPath $agents -Destination ($agents + '.bak.' + [guid]::NewGuid().ToString('N'))
    }
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($agents, $updated, $utf8)
}
Write-Host "Codex Word standard configured: $agents"
Write-Host "Local standard: $spec"
