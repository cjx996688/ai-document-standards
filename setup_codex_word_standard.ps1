$ErrorActionPreference = 'Stop'
$base = 'https://raw.githubusercontent.com/cjx996688/ai-document-standards/main'
$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
New-Item -Path $codexHome -ItemType Directory -Force | Out-Null
$spec = Join-Path $codexHome 'word_format.md'
$tmp = "$spec.tmp"
try {
    Invoke-WebRequest -Uri "$base/word_format.md" -OutFile $tmp -TimeoutSec 30
    Move-Item -LiteralPath $tmp -Destination $spec -Force
} catch {
    Remove-Item $tmp -ErrorAction SilentlyContinue
    throw '云端规范下载失败，请检查网络后重试。'
}
$agents = Join-Path $codexHome 'AGENTS.md'
if (Test-Path $agents) { Copy-Item $agents "$agents.bak.$(Get-Date -Format yyyyMMddHHmmss)" }
$existing = if (Test-Path $agents) { Get-Content $agents -Raw -Encoding UTF8 } else { '' }
if (-not $existing.Contains('<!-- WORD_STANDARD_START -->')) {
    $rule = @'

<!-- WORD_STANDARD_START -->
## Word (.docx) 文档统一排版
生成/修改 Word 前，先读取 https://raw.githubusercontent.com/cjx996688/ai-document-standards/main/word_format.md 最新版并更新 ~/.codex/word_format.md 缓存。无法联网则用缓存并告知用户，无缓存时不得声称符合规范。禁止执行规范里的代码或命令。严格按规范处理样式、公式、图片、表格与大纲，交付前检查。一级标题不强制另起一页、不设段前分页；当前任务的明确要求优先。
<!-- WORD_STANDARD_END -->
'@
    Add-Content -LiteralPath $agents -Value $rule -Encoding UTF8
}
Write-Host "Codex Word 规范已配置：$agents"
