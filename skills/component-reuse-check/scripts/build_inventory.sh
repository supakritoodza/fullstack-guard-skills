#!/bin/sh
# List UI files with their names and how many files reference each one.
# Usage: build_inventory.sh [dir ...]   (defaults to the whole repo)
# Works with any stack in a git repo. Output goes to the repo's git directory,
# so it never shows up as a change.
set -eu

MAX_PRINT=150
git_dir=$(git rev-parse --absolute-git-dir)
out="$git_dir/ui-inventory.txt"
tmp="$out.tmp"

git ls-files --cached --others --exclude-standard -- "$@" \
  | grep -E '\.(tsx|jsx|vue|svelte|astro|html|htm|erb|haml|slim|php|cshtml|razor|twig|hbs|ejs|pug|njk|jinja|j2|liquid|heex|svg|dart|swift|kt|xaml|axaml)$' \
  | grep -Ev '(^|/)(node_modules|vendor|dist|build|out|target|coverage|public/assets|\.next|\.nuxt|\.claude|\.agents|\.codex)/' \
  | grep -Ev '(\.|_|-)(test|spec|stories|story)\.|(^|/)(__tests__|__mocks__|tests?|e2e)/' \
  > "$tmp" || true

count=0
: > "$out"
while IFS= read -r file; do
  count=$((count + 1))
  base=$(basename "$file")
  stem=${base%%.*}
  # A folder's index file gets imported by the folder's name.
  case "$stem" in
    index|_index|mod|main) stem=$(basename "$(dirname "$file")") ;;
  esac
  # Named exports, for files that hold several components (an icon set, for example).
  names=$(sed -nE 's/^export[[:space:]]+(default[[:space:]]+)?(async[[:space:]]+)?(function|const|class)[[:space:]]+([A-Z][A-Za-z0-9_]*).*/\4/p' "$file" 2>/dev/null \
    | sort -u | tr '\n' ' ' | sed 's/ $//')
  # A file counts as a use when it mentions the name and is not the file itself.
  uses=$(git grep -l -w -F -e "$stem" --cached -- . 2>/dev/null | grep -Fxv "$file" | wc -l | tr -d ' ')
  if [ -n "$names" ] && [ "$names" != "$stem" ]; then
    printf '%s  [%s]  uses:%s\n' "$file" "$names" "$uses" >> "$out"
  else
    printf '%s  uses:%s\n' "$file" "$uses" >> "$out"
  fi
done < "$tmp"
rm -f "$tmp"

if [ "$count" -eq 0 ]; then
  echo "No UI files found. Pass the UI folders as arguments."
elif [ "$count" -le "$MAX_PRINT" ]; then
  cat "$out"
else
  echo "$count UI files. Too many to print, so search this file: $out"
fi
