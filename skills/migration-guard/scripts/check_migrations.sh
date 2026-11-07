#!/bin/sh
# Mechanical migration checks against a base branch. Read-only: runs git only, never a database.
# Usage: check_migrations.sh <base-branch> [migration-dir ...]
# Finds: edited/deleted migrations that exist on base, a version number already used on base or
# twice on this branch, a new version older than base's newest, an .up.sql without .down.sql,
# and risky SQL in added lines. Prints "ok" when it finds nothing.
set -eu

base=${1:?usage: check_migrations.sh <base-branch> [migration-dir ...]}
shift
git rev-parse --verify -q "$base" >/dev/null || { echo "unknown base branch: $base" >&2; exit 2; }
mb=$(git merge-base "$base" HEAD)
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

if [ "$#" -eq 0 ]; then
  # Common layouts: migrations/, db/migrate/, <app>/migrations/, prisma/migrations/, alembic/versions/.
  set -- $(git ls-files | grep -E '(^|/)(migrations|versions|db/migrate)/' \
    | sed -E 's#^(.*(^|/)(migrations|versions|db/migrate))/.*#\1#' | sort -u)
  [ "$#" -gt 0 ] || { echo "no migration folder found; pass it as an argument" >&2; exit 2; }
fi

# Version = leading digits of the file name (000235_x.sql, 20240101120000_x.rb, 0042_x.py).
version() { basename "$1" | sed -nE 's/^([0-9]+)[_.-].*/\1/p'; }
stem() { basename "$1" | sed -E 's/\.(up|down)\.sql$//; s/\.[A-Za-z]+$//'; }

check_dir() {
  dir=$1
  changes=$(git diff --name-status --no-renames "$mb" HEAD -- "$dir")
  [ -n "$changes" ] || return 0

  echo "$changes" | awk '$1 != "A" {print $1, $2}' | while read -r st f; do
    case $st in M) what=edited ;; D) what=deleted ;; *) what=changed ;; esac
    echo "Edited   $f was $what, but it already exists on $base. Add a new migration instead."
  done

  added=$(echo "$changes" | awk '$1 == "A" {print $2}')
  [ -n "$added" ] || return 0

  # One line per migration: "folder|version|stem". Folder-scoped, because some tools (Django)
  # number each app separately.
  index() { sed -nE 's#^(.*/)?([0-9]+)([_.-][^/]*)$#\1|\2|\2\3#p' | sed -E 's#\.(up|down)\.sql$##; s#\.[A-Za-z]+$##' | sort -u; }
  git ls-tree -r --name-only "$base" -- "$dir" | index > "$tmp"
  echo "$added" | index | awk -F'|' -v base="$base" '
    NR == FNR { used[$1 "|" $2] = $3; if ($2 + 0 > newest[$1] + 0) newest[$1] = $2; next }
    { k = $1 "|" $2
      if ((k in used) && used[k] != $3) print "Number   " $3 " reuses " $2 ", already used on " base " by " used[k] ". Renumber after " newest[$1] "."
      else if (!(k in used) && newest[$1] != "" && $2 + 0 < newest[$1] + 0) print "Order    " $3 " is older than the newest on " base " (" newest[$1] "). It may run out of order or be skipped." }' "$tmp" -

  # Two new migrations on this branch sharing a number in the same folder.
  for f in $added; do
    v=$(version "$f"); [ -n "$v" ] && echo "$(dirname "$f") $v $(stem "$f")"
  done | sort -u | awk '{k=$1" "$2; n[k]++; s[k]=s[k]" "$3}
    END {for (k in n) if (n[k] > 1) print "Number   " k " is used twice on this branch:" s[k]}'

  for f in $added; do
    case $f in
      *.up.sql) git cat-file -e "HEAD:${f%.up.sql}.down.sql" 2>/dev/null \
        || echo "Pair     $(basename "$f") has no .down.sql, so it cannot be rolled back." ;;
    esac
  done

  # Risky SQL in added lines. Flags only; read the statement to decide.
  git diff "$mb" HEAD -- "$dir" | grep -E '^\+[^+]' | sed 's/^+//' \
    | grep -iE 'add column[^;]*not null|drop (table|column)|alter column[^;]*type|rename (column|to)|create (unique )?index' \
    | grep -viE 'not null[^;]*default|default[^;]*not null|concurrently' | head -20 \
    | while read -r line; do echo "Risk     $(echo "$line" | cut -c1-140)"; done

  # The same risks in ORM migrations (Django, Alembic, Rails, Laravel). An added field can span
  # several lines, so it is judged from its start to the next operation.
  git diff "$mb" HEAD -- "$dir" | grep -E '^\+[^+]' | sed 's/^+//' | awk '
    function flush() { if (field != "" && block !~ /null=True|nullable=True|default|server_default/) print "Risk     new required field with no default: " field; field = ""; block = "" }
    /migrations\.[A-Z]|op\.[a-z_]+\(/ { flush() }
    /migrations\.AddField\(/ { field = "AddField"; block = "" }
    /op\.add_column\(/ { if ($0 ~ /nullable=False/ && $0 !~ /server_default/) print "Risk     new required field with no default: " $0 }
    field != "" { block = block $0; if ($0 ~ /name=/ && $0 !~ /model_name=/) { line = $0; gsub(/^[ \t]+/, "", line); field = "AddField " line } }
    /migrations\.RunPython\(/ && !/reverse_code/ && !/,.*\)/ { print "Risk     RunPython with no reverse_code, cannot be rolled back: " $0 }
    /migrations\.RunSQL\(/ && !/reverse_sql/ && !/,.*\)/ { print "Risk     RunSQL with no reverse_sql, cannot be rolled back: " $0 }
    /migrations\.(RemoveField|DeleteModel|RenameField|RenameModel|AlterField)\(/ { print "Risk     " $0 }
    /op\.(drop_table|drop_column|alter_column)\(/ { print "Risk     " $0 }
    /(remove_column|drop_table|rename_column|change_column) / { print "Risk     " $0 }
    /add_column .*null: false/ && !/default:/ { print "Risk     new required field with no default: " $0 }
    /(dropColumn|renameColumn)\(|Schema::drop/ { print "Risk     " $0 }
    END { flush() }' | sed -E 's/  +/ /g' | cut -c1-150 | head -20
}

out=$(for dir in "$@"; do check_dir "$dir"; done)
if [ -n "$out" ]; then echo "$out"; else echo "ok: no problems found in $* against $base"; fi
