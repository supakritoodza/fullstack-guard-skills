#!/bin/sh
# Compare plain AI with AI + skill on the same task, in clean copies of each sample project.
# Usage: [MODE=build|review|review-asked] [FIXTURES="..."] run.sh [runs-per-combo=3] [model=sonnet] [parallel=4] [out-dir=results/raw]
# The prompt never mentions the skill, so the runs also show whether it triggers by itself.
set -eu

RUNS=${1:-3}
MODEL=${2:-sonnet}
JOBS=${3:-4}
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
out=${4:-$here/results/raw}
# build: write the page.
# review: ordinary review request, on a branch with planted duplicates.
# review-asked: same branch, both arms asked to find duplicates, skill arm told to use the skill.
MODE=${MODE:-build}
task_file() {
  case "$MODE" in
    build) echo task.txt ;;
    review) echo review-task.txt ;;
    review-asked) echo "review-asked-$1.txt" ;;
  esac
}
mkdir -p "$out"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

run_one() {
  fixture=$1 arm=$2 n=$3
  id="$fixture-$arm-$n"
  dir="$work/$id"
  base=${fixture%-large}
  cp -R "$here/fixtures/$base" "$dir"
  if [ "$base" != "$fixture" ]; then
    python3 "$here/make_large.py" "$base" "$dir"
  fi
  if [ "$arm" = skill ]; then
    mkdir -p "$dir/.claude/skills"
    cp -R "$repo/skills/component-reuse-check" "$dir/.claude/skills/"
  fi
  git -C "$dir" init -q
  git -C "$dir" add -A
  git -C "$dir" -c user.name=eval -c user.email=eval@example.com commit -qm baseline
  if [ "$MODE" != build ]; then
    git -C "$dir" branch -M main
    git -C "$dir" checkout -qb feature/settings
    python3 "$here/make_review.py" "$base" "$dir"
    git -C "$dir" add -A
    git -C "$dir" -c user.name=eval -c user.email=eval@example.com commit -qm "Add settings page"
  fi

  # Project settings only, so the user's own plugins, hooks, memory, and MCP servers stay out.
  (cd "$dir" && CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 claude -p "$(cat "$here/$(task_file "$arm")")" \
    --model "$MODEL" \
    --setting-sources project \
    --strict-mcp-config \
    --no-session-persistence \
    --allowedTools "Read Edit Write Glob Grep Bash Skill" \
    --max-budget-usd 2 \
    --output-format stream-json --verbose) > "$out/$id.jsonl" 2> "$out/$id.err" || true

  git -C "$dir" add -A
  git -C "$dir" diff --cached --no-renames -- . ':(exclude).claude' > "$out/$id.diff"
  echo "done $id"
}

for fixture in ${FIXTURES:-react-app django-app react-app-large django-app-large}; do
  for arm in plain skill; do
    n=1
    while [ "$n" -le "$RUNS" ]; do
      while [ "$(jobs -r | wc -l)" -ge "$JOBS" ]; do sleep 2; done
      run_one "$fixture" "$arm" "$n" &
      n=$((n + 1))
    done
  done
done
wait
python3 "$here/score.py" "$out" "$MODE"
