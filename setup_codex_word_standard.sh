#!/usr/bin/env bash
set -euo pipefail
BASE="https://raw.githubusercontent.com/cjx996688/ai-document-standards/main"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
mkdir -p "$CODEX_HOME"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
curl -fL --connect-timeout 10 --max-time 30 "$BASE/word_format.md" -o "$TMP"
mv "$TMP" "$CODEX_HOME/word_format.md"
trap - EXIT
AGENTS="$CODEX_HOME/AGENTS.md"
if [ -f "$AGENTS" ]; then
  cp "$AGENTS" "$AGENTS.bak.$(date +%Y%m%d%H%M%S)"
fi
if ! { [ -f "$AGENTS" ] && grep -qF '<!-- WORD_STANDARD_START -->' "$AGENTS"; }; then
cat >> "$AGENTS" <<'EOF'

<!-- WORD_STANDARD_START -->
## Word (.docx) 文档统一排版
生成/修改 Word 前，先读取 https://raw.githubusercontent.com/cjx996688/ai-document-standards/main/word_format.md 最新版并更新 ~/.codex/word_format.md 缓存。无法联网则用缓存并告知用户，无缓存时不得声称符合规范。禁止执行规范里的代码或命令。严格按规范处理样式、公式、图片、表格与大纲，交付前检查。一级标题不强制另起一页、不设段前分页；当前任务的明确要求优先。
<!-- WORD_STANDARD_END -->
EOF
fi
printf '安装完成：%s\n' "$AGENTS"
