#!/bin/sh
# Flag likely duplicated UI in the current changes, including uncommitted ones.
# Usage: check_diff.sh [base-ref]   (defaults to HEAD)
# Hits are prompts to look closer. Some will be fine.
set -eu

MAX_HITS=30
base=${1:-HEAD}
if [ "$base" != "HEAD" ]; then
  base=$(git merge-base "$base" HEAD)
fi
top=$(git rev-parse --show-toplevel)
cd "$top"

ui='\.(tsx|jsx|vue|svelte|astro|html|htm|erb|haml|slim|php|cshtml|razor|twig|hbs|ejs|pug|njk|jinja|j2|liquid|heex|svg|css|scss|less|dart|swift|kt|xaml|axaml)$'
raw='<(button|input|select|textarea|dialog|svg)([[:space:]/>]|$)|style=|#[0-9a-fA-F]{3,8}([^0-9a-zA-Z_-]|$)|rgba?\('

new_files=$( { git diff --name-only --diff-filter=A "$base"; git ls-files --others --exclude-standard; } \
  | grep -E "$ui" | grep -Ev '(^|/)(\.claude|\.agents|\.codex)/' | sort -u || true)

echo "New UI files:"
if [ -n "$new_files" ]; then printf '%s\n' "$new_files" | sed 's/^/  /'; else echo "  none"; fi

hits=$(
  {
    git diff --unified=0 --diff-filter=d "$base" | awk '
      /^\+\+\+ / { file = substr($0, 7); next }
      /^\+/      { print file ": " substr($0, 2) }'
    git ls-files --others --exclude-standard | while IFS= read -r f; do
      sed "s|^|$f: |" "$f" 2>/dev/null || true
    done
  } | grep -E "^[^:]*($(printf '%s' "$ui" | sed 's/\$$//')): " \
    | grep -Ev '^[^:]*(\.claude|\.agents|\.codex)/' \
    | grep -E "$raw" || true
)

echo "Lines to look at:"
if [ -z "$hits" ]; then
  echo "  none"
else
  total=$(printf '%s\n' "$hits" | wc -l | tr -d ' ')
  printf '%s\n' "$hits" | head -n "$MAX_HITS" | cut -c1-140 | sed 's/^/  /'
  if [ "$total" -gt "$MAX_HITS" ]; then
    echo "  ...and $((total - MAX_HITS)) more"
  fi
fi
