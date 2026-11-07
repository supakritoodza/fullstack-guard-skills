#!/bin/sh
# Find wire field names a client uses that the server never mentions, and wire-name changes on a branch.
# Read-only. Usage: field_gaps.sh [-b base-branch] [-e endpoint-path ...] <server-dir> <client-dir> [client-dir ...]
# With -e, client dirs can be whole repos: the script keeps only the feature folders whose files
# mention one of the endpoint paths (e.g. -e users/profile): the folder of each matching source file, with subfolders.
#
# Server names: every quoted identifier, SQL alias (AS x), and YAML key in the server repo.
#   That is a superset, so a name missing from it is almost surely never sent or read by the server.
# Client names: snake_case properties, accesses, and object keys, plus explicit wire-name
#   annotations (@SerialName, @SerializedName, @Json(name=), @JsonProperty, json:"x").
# With -b, also prints server diff lines that add, drop, or rename a wire name since base.
set -eu

base=""; endpoints=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -b) base=$2; shift 2 ;;
    -e) endpoints="$endpoints $2"; shift 2 ;;
    *) break ;;
  esac
done
[ "$#" -ge 2 ] || { echo "usage: field_gaps.sh [-b base] <server-dir> <client-dir> [client-dir ...]" >&2; exit 2; }
server=$1; shift
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT


src_files() {
  # Tracked files when in git (skips node_modules, build output, vendored code); fall back to find.
  if git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    (cd "$1" && git ls-files | grep -E "$2" | grep -vE '(^|/)(node_modules|vendor|build|dist|generated|\.next)/' | sed "s#^#$1/#")
  else
    find "$1" -type f | grep -E "$2" | grep -vE '/(node_modules|vendor|build|dist|generated|\.next)/'
  fi
}

if [ -n "$endpoints" ]; then
  scoped=""
  for c in "$@"; do
    for e in $endpoints; do
      found=$(src_files "$c" '\.(ts|tsx|js|jsx|mjs|vue|svelte|kt|java|swift|dart|py|go|cs)$' \
        | grep -vE '(^|/)(docs?|tests?|__tests__|test|androidTest)/|\.(test|spec)\.' | tr '\n' '\0' \
        | xargs -0 grep -lF "$e" 2>/dev/null || true)
      for f in $found; do scoped="$scoped
$(dirname "$f")"; done
    done
  done
  scoped=$(echo "$scoped" | grep . | sort -u)
  [ -n "$scoped" ] || { echo "no client file mentions:$endpoints" >&2; exit 2; }
  echo "Client folders that call$endpoints:"; echo "$scoped" | sed 's/^/  /'; echo
  set -- $scoped
fi

code='\.(go|py|rb|php|java|kt|kts|ts|tsx|js|jsx|mjs|cs|rs|dart|swift|sql|ya?ml|json|graphql|proto)$'

src_files "$server" "$code" | tr '\n' '\0' | xargs -0 cat 2>/dev/null | {
  tee "$tmp/server.txt" | grep -oE "[\"'\`][A-Za-z_][A-Za-z0-9_]*[\"'\`]" | tr -d "\"'\`"
  grep -oiE '\bAS[[:space:]]+"?[a-z_][a-z0-9_]*' "$tmp/server.txt" | sed -E 's/^[Aa][Ss][[:space:]]+"?//'
  grep -oE '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*:' "$tmp/server.txt" | tr -d ' :\t'
} | sort -u > "$tmp/server_names"

: > "$tmp/client_uses"; : > "$tmp/nested"
for c in "$@"; do
  src_files "$c" '\.(ts|tsx|js|jsx|mjs|vue|svelte|kt|java|swift|dart|py|go|cs)$' | grep -vE '\.(test|spec)\.|(^|/)(tests?|__tests__|androidTest)/|[Mm]ock' | while read -r f; do
    {
      # Explicit wire names, any case: @SerialName("x"), @SerializedName("x"), @JsonProperty("x"), @Json(name = "x").
      grep -noE '@(SerialName|SerializedName|JsonProperty)\("[^"]+"\)|@Json\(name *= *"[^"]+"\)' "$f" \
        | sed -E 's/^([0-9]+):[^"]*"([^"]+)".*/\1 \2 decode/'
      grep -noE 'json:"[^",]+' "$f" | sed -E 's/^([0-9]+):json:"(.*)/\1 \2 decode/'
      # Assigned onto an object, which usually builds a request: payload.foo_bar = ...
      grep -noE '\.[a-z][a-z0-9]*(_[a-z0-9]+)+ *= *[^=>]' "$f" | sed -E 's/^([0-9]+):\.([a-z0-9_]+).*/\1 \2 sent/'
      # snake_case members, keys, and accesses: foo_bar:, foo_bar?:, .foo_bar, ["foo_bar"], 'foo_bar':
      grep -noE "(\.|\[[\"'])[a-z][a-z0-9]*(_[a-z0-9]+)+|(^|[{,[:space:]])[\"']?[a-z][a-z0-9]*(_[a-z0-9]+)+[\"']?\??:" "$f" \
        | sed -E "s/^([0-9]+):[^a-z]*([a-z][a-z0-9_]*).*/\1 \2 other/"
    } | while read -r line name kind; do echo "$name $f:$line $kind"; done >> "$tmp/client_uses"
    # A wire field set inside a nested object: details.foo_bar = ...
    grep -noE '\b[a-z][A-Za-z0-9_]*\.[a-z][a-z0-9]*(_[a-z0-9]+)+ *= *[^=>]' "$f" \
      | sed -E "s#^([0-9]+):([A-Za-z0-9_]+)\.([a-z0-9_]+).*#\2 \3 $f:\1#" >> "$tmp/nested" || true
  done
done

# Names the server never mentions, most likely bugs first:
#   Typo?   first and last words match a server name (user_adress_line vs user_address_line)
#   Sent?   the client assigns it on an object, so the server probably ignores what it sends
#   Decode? an explicit wire-name annotation, so the client decodes a field that never arrives
awk 'NR == FNR { s[$1] = 1; n = split($1, w, "_"); if (n > 1) near[w[1] "_" w[n]] = near[w[1] "_" w[n]] " " $1; next }
  !($1 in s) { if (!($1 in at)) { order[++m] = $1; at[$1] = $2 } count[$1]++; if ($3 == "sent") sent[$1] = $2; if ($3 == "decode") dec[$1] = $2 }
  END { for (i = 1; i <= m; i++) { k = order[i]; n = split(k, w, "_"); hint = ""; best = 99
    if (n > 1 && (w[1] "_" w[n]) in near) { c = split(near[w[1] "_" w[n]], cand, " ")
      for (j = 1; j <= c; j++) { d = length(cand[j]) - length(k); if (d < 0) d = -d; if (d < best) { best = d; hint = cand[j] } } }
    if (hint != "" && best <= 2) printf "0Typo?    %-30s %s  server has %s\n", k, at[k], hint
    else if (k in sent) printf "1Sent?    %-30s %s\n", k, sent[k]
    else if (k in dec) printf "2Decode?  %-30s %s\n", k, dec[k]
    else printf "3Missing  %-30s %s\n", k, at[k] } }' \
  "$tmp/server_names" "$tmp/client_uses" | sort | cut -c2- > "$tmp/missing"

# Both names exist on the server, so a name check passes, but nesting may not match.
# Variables that normally hold the request root are skipped.
awk 'NR == FNR { s[$1] = 1; next }
  ($1 in s) && ($2 in s) && $1 !~ /^(this|self|payload|body|data|params|form|req|request|values|dto|record|state|result|row|item|obj|it)$/ {
    print "Nested?  " $1 "." $2 "  " $3 "  server knows both names; check it reads " $2 " inside " $1 }' \
  "$tmp/server_names" "$tmp/nested" | sort -u | head -15 > "$tmp/nested_out"

if [ -s "$tmp/missing" ]; then
  echo "Client names the server never mentions ($(wc -l < "$tmp/missing" | tr -d ' ')). Typo?, Sent? and Decode? are likely bugs; Missing is often a client-only field:"
  head -60 "$tmp/missing"
  [ "$(wc -l < "$tmp/missing")" -le 60 ] || echo "... $(($(wc -l < "$tmp/missing") - 60)) more in this list; narrow the client folders"
else
  echo "ok: every client wire name appears somewhere in the server"
fi
[ ! -s "$tmp/nested_out" ] || { echo; cat "$tmp/nested_out"; }

if [ -n "$base" ]; then
  echo
  echo "Server wire-name changes since $base (check each against the clients):"
  git -C "$server" diff "$(git -C "$server" merge-base "$base" HEAD)" HEAD -- . \
    | grep -E '^[-+][^-+].*(json:"|[[:space:]]AS[[:space:]]|@SerialName|@JsonProperty|serializers?\.|fields *=)' \
    | cut -c1-160 | head -40 || true
fi
