#!/usr/bin/env python3
"""Score eval runs from their diffs and session logs.

Usage: score.py <raw-dir> [build|review]
Writes results.json next to the raw folder and prints a summary table.
"""
import json
import re
import statistics
import sys
from pathlib import Path

HERE = Path(__file__).parent
EXPECTED = json.loads((HERE / "expected.json").read_text())
UI_EXT = re.compile(r"\.(tsx|jsx|html)$")
RAW = {
    "raw control": re.compile(r"<(button|input|select|textarea|dialog)[\s/>]"),
    "inline icon": re.compile(r"<(svg|path)[\s/>]"),
    "hard-coded color": re.compile(r"#[0-9a-fA-F]{3,8}\b|rgba?\("),
    "inline style": re.compile(r"\bstyle="),
}

# Names an answer has to use for a planted duplicate to count as found.
REVIEW_NAMES = {
    "react-app": {
        "layout": r"\bAppShell\b", "page header": r"\bPageHeader\b", "text input": r"\bTextField\b",
        "switch": r"\bSwitch\b", "button": r"\bButton\b", "save icon": r"\bSaveIcon\b",
        "trash icon": r"\bTrashIcon\b", "dialog": r"\bConfirmSheet\b", "notice": r"\bNotice\b",
    },
    "django-app": {
        "layout": r"layouts/app\.html", "page header": r"page_header", "text input": r"text_field",
        "switch": r"forms/switch|switch\.html", "button": r"partials/button|button\.html",
        "save icon": r"icons/save|save\.html", "trash icon": r"icons/trash|trash\.html",
        "dialog": r"confirm_sheet", "notice": r"notice\.html",
    },
}


def parse_diff(text):
    """Return ({path: [added lines]}, [new files])."""
    added, new_files, path = {}, [], None
    for line in text.splitlines():
        if line.startswith("diff --git"):
            path = line.rsplit(" b/", 1)[-1]
            added.setdefault(path, [])
        elif line.startswith("new file mode") and path:
            new_files.append(path)
        elif line.startswith("+") and not line.startswith("+++") and path:
            added[path].append(line[1:])
    return added, new_files


def score_log(path):
    tokens = cost = fresh = 0
    triggered = False
    for line in path.read_text().splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if event.get("type") == "assistant":
            for block in event["message"].get("content", []):
                if block.get("type") != "tool_use":
                    continue
                # Only this skill counts. Built-in skills such as code-review do not.
                tool_input = block.get("input", {})
                if (block.get("name") == "Skill" and tool_input.get("skill") == "component-reuse-check") \
                        or "build_inventory" in str(tool_input.get("command", "")):
                    triggered = True
        if event.get("type") == "result":
            usage = event.get("usage", {})
            fresh = (
                usage.get("input_tokens", 0)
                + usage.get("cache_creation_input_tokens", 0)
                + usage.get("output_tokens", 0)
            )
            tokens = fresh + usage.get("cache_read_input_tokens", 0)
            cost = event.get("total_cost_usd", 0)
    return {"tokens": tokens, "fresh_tokens": fresh, "cost_usd": cost, "triggered": triggered}


def score_run(raw_dir, run_id):
    fixture, arm, n = run_id.rsplit("-", 2)
    spec = EXPECTED[fixture.removesuffix("-large")]
    added, new_files = parse_diff((raw_dir / f"{run_id}.diff").read_text())
    lines = [line for path, rows in added.items() for line in rows]
    joined = "\n".join(lines)

    reused = [part for part, rx in spec["reuse"].items() if re.search(rx, joined)]
    # Raw patterns count only in UI files the run wrote, one hit per line.
    flags = {name: 0 for name in RAW}
    for path, rows in added.items():
        if UI_EXT.search(path):
            for row in rows:
                for name, rx in RAW.items():
                    flags[name] += bool(rx.search(row))
    extra = [
        p for p in new_files
        if UI_EXT.search(p) and not p.startswith(spec["page_dir"])
    ]
    return {
        "id": run_id, "fixture": fixture, "arm": arm,
        "reused": len(reused), "total_parts": len(spec["reuse"]),
        "missed": sorted(set(spec["reuse"]) - set(reused)),
        "nav_updated": spec["nav_file"] in added,
        "raw_hits": sum(flags.values()), "raw_detail": flags,
        "extra_ui_files": extra,
        **score_log(raw_dir / f"{run_id}.jsonl"),
    }


def score_review(raw_dir, run_id):
    """A planted duplicate counts as found if the answer names the component to use instead."""
    fixture, arm, n = run_id.rsplit("-", 2)
    log = raw_dir / f"{run_id}.jsonl"
    answer = ""
    for line in log.read_text().splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if event.get("type") == "result":
            answer += event.get("result") or ""
        if event.get("type") == "assistant":
            for block in event["message"].get("content", []):
                if block.get("type") == "tool_use" and block.get("name") == "ReportFindings":
                    answer += "\n" + json.dumps(block.get("input", {}))
    parts = REVIEW_NAMES[fixture.removesuffix("-large")]
    found = [part for part, rx in parts.items() if re.search(rx, answer)]
    return {
        "id": run_id, "fixture": fixture, "arm": arm,
        "found": len(found), "total_parts": len(parts),
        "missed": sorted(set(parts) - set(found)),
        "answer_words": len(answer.split()),
        **score_log(log),
    }


def main_review(raw_dir):
    runs = [score_review(raw_dir, p.stem) for p in sorted(raw_dir.glob("*.jsonl"))]
    (raw_dir.parent / "results.json").write_text(json.dumps(runs, indent=2) + "\n")
    print(f"{'fixture':17} {'arm':6} {'n':>2} {'found':>7} {'trig':>5} {'words':>6} {'tokens':>9} {'fresh':>7} {'usd':>6}")
    for fixture, arm in sorted({(r["fixture"], r["arm"]) for r in runs}):
        rows = [r for r in runs if r["fixture"] == fixture and r["arm"] == arm]
        med = lambda key: statistics.median(r[key] for r in rows)
        print(f"{fixture:17} {arm:6} {len(rows):>2} {med('found'):>5.1f}/{rows[0]['total_parts']} "
              f"{sum(r['triggered'] for r in rows):>3}/{len(rows)} {med('answer_words'):>6.0f} "
              f"{med('tokens'):>9.0f} {med('fresh_tokens'):>7.0f} {med('cost_usd'):>6.3f}")


def main():
    raw_dir = Path(sys.argv[1])
    if len(sys.argv) > 2 and sys.argv[2].startswith("review"):
        main_review(raw_dir)
        return
    runs = [score_run(raw_dir, p.stem) for p in sorted(raw_dir.glob("*.diff"))]
    out = raw_dir.parent / "results.json"
    out.write_text(json.dumps(runs, indent=2) + "\n")

    print(f"{'fixture':17} {'arm':6} {'n':>2} {'reused':>7} {'raw':>5} {'extra':>6} "
          f"{'nav':>4} {'trig':>5} {'tokens':>9} {'fresh':>7} {'usd':>6}")
    groups = sorted({(r["fixture"], r["arm"]) for r in runs})
    for fixture, arm in groups:
        rows = [r for r in runs if r["fixture"] == fixture and r["arm"] == arm]
        med = lambda key: statistics.median(r[key] for r in rows)
        print(f"{fixture:17} {arm:6} {len(rows):>2} "
              f"{med('reused'):>5.1f}/{rows[0]['total_parts']} {med('raw_hits'):>5.1f} "
              f"{statistics.median(len(r['extra_ui_files']) for r in rows):>6.1f} "
              f"{sum(r['nav_updated'] for r in rows):>2}/{len(rows)} "
              f"{sum(r['triggered'] for r in rows):>3}/{len(rows)} "
              f"{med('tokens'):>9.0f} {med('fresh_tokens'):>7.0f} {med('cost_usd'):>6.3f}")


if __name__ == "__main__":
    main()
