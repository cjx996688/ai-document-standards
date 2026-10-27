#!/usr/bin/env bash
set -euo pipefail
BASE="https://raw.githubusercontent.com/cjx996688/ai-document-standards/main"
standards_dir="${CODEX_HOME:-$HOME/.codex}"
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
use_local=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    --local) use_local=true; shift ;;
    --config-dir) [ "$#" -ge 2 ] || exit 2; standards_dir="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done
mkdir -p "$standards_dir"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
if $use_local; then
  cp "$repo_dir/word_format.md" "$TMP"
elif curl -fsSL --connect-timeout 10 --max-time 30 "$BASE/word_format.md" -o "$TMP" && [ -s "$TMP" ]; then
  :
elif [ -s "$standards_dir/word_format.md" ]; then
  cp "$standards_dir/word_format.md" "$TMP"
  echo 'GitHub download failed; retained local cached standard.' >&2
elif [ -s "$repo_dir/word_format.md" ]; then
  cp "$repo_dir/word_format.md" "$TMP"
  echo 'GitHub download failed; used repository copy.' >&2
else
  echo 'No Word standard is available.' >&2; exit 1
fi
[ -s "$TMP" ] || { echo 'Empty standard file.' >&2; exit 1; }
mv "$TMP" "$standards_dir/word_format.md"
trap - EXIT
AGENTS="$standards_dir/AGENTS.md"
TMP=$(mktemp "$standards_dir/.word-agents.XXXXXX")
trap 'rm -f "$TMP"' EXIT
input=/dev/null
if [ -f "$AGENTS" ]; then input="$AGENTS"; fi
awk -v snippet="$repo_dir/AGENTS.global-snippet.md" '
BEGIN { while ((getline line < snippet) > 0) rule = rule line "\n"; close(snippet) }
/<!-- WORD_STANDARD_START -->/ {
  if ($0 !~ /^<!-- WORD_STANDARD_START -->[[:space:]]*$/ || seen || inside) { bad=1; exit 2 }
  printf "%s", rule; inside=1; seen=1; next
}
/<!-- WORD_STANDARD_END -->/ {
  if ($0 !~ /^<!-- WORD_STANDARD_END -->[[:space:]]*$/ || !inside) { bad=1; exit 2 }
  inside=0; next
}
!inside { print }
END { if (bad || inside) exit 2; if (!seen) { if (NR) print ""; printf "%s", rule } }
' "$input" > "$TMP" || { echo 'Malformed Word markers; AGENTS.md was not changed.' >&2; exit 1; }
if [ -f "$AGENTS" ] && cmp -s "$AGENTS" "$TMP"; then
  :
else
  if [ -f "$AGENTS" ]; then
    backup=$(mktemp "$AGENTS.bak.XXXXXX")
    cp "$AGENTS" "$backup"
  fi
  mv "$TMP" "$AGENTS"
fi
printf '安装完成：%s\n' "$AGENTS"
