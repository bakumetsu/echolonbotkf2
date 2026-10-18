"""G5: scan a KF2 game log (Launch.log) for script runtime problems.

  python kit/tools/log_checker.py                    # workspace runtime_log.path
  python kit/tools/log_checker.py path\\to\\Launch.log [--all] [--json]

Finds: Accessed None, Accessed array out of bounds, Script call stack, [ASSERT-FAIL],
runaway loops / infinite recursion. A ScriptWarning block is two tab-indented lines after
the warning: the object, then `Function Pkg.Class:Func:Offset` (verified from a real log).
By default only hits whose function is in our own packages count (runtime_log.own_packages);
base-game noise is summarised, not failed on. Exit 1 if any own-package hit or ASSERT-FAIL.
"""
from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path

from common import load_workspace, run_main

PATTERNS = {
    "accessed_none": re.compile(r"ScriptWarning: Accessed None(?: '(?P<var>\w+)')?"),
    "out_of_bounds": re.compile(r"Accessed array .*out of bounds|Accessed array '\w+' out of bounds"),
    "call_stack": re.compile(r"Script call stack:"),
    "assert_fail": re.compile(r"\[ASSERT-FAIL\]"),
    "runaway": re.compile(r"Runaway loop|Infinite script recursion"),
}
FUNC_LINE = re.compile(r"^\s+Function (?P<pkg>[\w-]+)\.(?P<cls>\w+):(?P<func>[\w:]+?)(?::(?P<off>[0-9A-F]{4}))?\s*$")


def scan(text: str, own: list[str]) -> dict:
    own_l = {p.lower() for p in own}
    lines = text.splitlines()
    hits = []
    for i, l in enumerate(lines):
        for kind, rx in PATTERNS.items():
            m = rx.search(l)
            if not m:
                continue
            func = None
            for nxt in lines[i + 1:i + 4]:
                fm = FUNC_LINE.match(nxt.rstrip("\r"))
                if fm:
                    func = fm
                    break
            hit = {"kind": kind, "line": i + 1, "text": l.strip()[:200],
                   "function": f"{func['pkg']}.{func['cls']}:{func['func']}" if func else None,
                   "own": bool(func and func["pkg"].lower() in own_l) or kind == "assert_fail"}
            if kind == "accessed_none":
                hit["var"] = m.group("var")
            hits.append(hit)
            break
    by_kind = Counter(h["kind"] for h in hits)
    own_hits = [h for h in hits if h["own"]]
    top_own = Counter((h["kind"], h["function"], h.get("var")) for h in own_hits).most_common(20)
    top_other = Counter((h["kind"], h["function"]) for h in hits if not h["own"]).most_common(5)
    return {"total": len(hits), "by_kind": dict(by_kind), "own": len(own_hits),
            "own_top": [{"kind": k, "function": f, "var": v, "count": c} for (k, f, v), c in top_own],
            "other_top": [{"kind": k, "function": f, "count": c} for (k, f), c in top_other],
            "hits": own_hits[:200]}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("log", nargs="?", type=Path)
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()
    ws = load_workspace()
    cfg = ws.get("runtime_log", {})
    path = a.log or Path(cfg.get("path", ""))
    text = path.read_text(encoding="utf-8", errors="replace")
    res = scan(text, cfg.get("own_packages", [ws["package_name"]]))
    if a.json:
        print(json.dumps(res, indent=1))
    else:
        print(f"log_checker: {res['total']} problems ({res['by_kind']}); {res['own']} in our packages")
        for t in res["own_top"]:
            print(f"  OURS  {t['count']:>5}x {t['kind']} {t['function']} {t['var'] or ''}")
        for t in res["other_top"]:
            print(f"  base  {t['count']:>5}x {t['kind']} {t['function']}")
    return 1 if res["own"] else 0


if __name__ == "__main__":
    run_main(main)
