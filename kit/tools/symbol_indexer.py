"""G2: build kit/generated/symbols.json from the legacy corpus and reconcile it with the doc.

Usage:
  python kit/tools/symbol_indexer.py              # index all legacy files, reconcile, write report
  python kit/tools/symbol_indexer.py --file Bot   # re-index one file in place (incremental)
  python kit/tools/symbol_indexer.py --src DIR    # index another source dir (e.g. the new Classes/)

Ranges: `line` = `start` = declaration line (matches the doc's A-Z index), `end` = closing
brace (or ';') line. This is the doc's "body-only" convention: leading comments are excluded. Labels are indexed but excluded from the 943 gate.
Source wins over the doc: every disagreement goes to kit/reports/symbol_diff.md.
"""
from __future__ import annotations

import argparse
import re
from collections import Counter
from pathlib import Path

from common import (ALIASES, CORE_FILES, FILE_TO_ALIAS, GENERATED_DIR, REPORTS_DIR, KitError,
                    load_json, load_workspace, read_lines, read_text, run_main, write_json)
from uc_parser import parse_file

SYMBOLS = GENERATED_DIR / "symbols.json"
GATE_KINDS = ("class", "function", "event", "state", "const", "var", "struct", "enum", "defaultproperties")
# Part 2.1 of the doc, as given in the Milestone 0 spec (Functions/Events/States/Consts/Vars).
SPEC_COUNTS = {
    "KF2BotsMut.uc": dict(function=97, event=0, state=0, const=21, var=63),
    "KF2BotsFollowNavBase.uc": dict(function=36, event=5, state=2, const=0, var=97),
    "KF2BotBase.uc": dict(function=158, event=3, state=0, const=91, var=217),
    "KF2BotLogic.uc": dict(function=38, event=2, state=0, const=0, var=0),
    "KF2Bot.uc": dict(function=41, event=37, state=18, const=0, var=0),
}
GATE_TOTAL = 943
EXPLAINED_EDITABLE = "doc extractor missed `var()` declarations"
EXPLAINED_MEMBER = "doc counted a struct member as a class var"
INDEX_ROW = re.compile(r"^\|\s*(?P<sym>[^|]+?)\s*\|\s*(?P<kind>\w+)\s*\|\s*(?P<alias>\w+):(?P<line>\d+)\s*\|\s*(?P<tag>[^|]*)\|")


def index_file(path: Path) -> list[dict]:
    lines = read_lines(path)
    pf = parse_file(read_text(path))
    out = []
    for d in pf.decls:
        out.append({
            "name": d.name, "kind": d.kind, "class": pf.class_name, "state": d.state,
            "file": path.name, "line": d.line, "start": d.line,
            "end": d.end, "signature": d.signature, "parent": d.parent or None,
            "mods": d.mods or None, "return_type": d.return_type or None,
            "params": [{"type": p.type, "name": p.name, "mods": p.mods} for p in d.params] or None,
            "var_type": d.var_type or None, "ignores": d.ignores or None, "tag": None,
            "owner": d.owner or None, "values": d.values or None,
        })
    # a label runs to the last non-blank line before the next label (or the state's '}')
    for d, s in zip(pf.decls, out):
        if d.kind == "label":
            nxt = [x.line for x in pf.decls if x.kind == "label" and x.state == d.state and x.line > d.line]
            st_end = next(x.end for x in pf.decls if x.kind == "state" and x.name == d.state)
            e = (min(nxt) if nxt else st_end) - 1
            while e > d.line and not lines[e - 1].strip():
                e -= 1
            s["end"] = e
    assert len(lines) >= max((s["end"] for s in out), default=0)
    return [{k: v for k, v in s.items() if v is not None} for s in out]


def doc_index(doc_path: Path) -> list[dict]:
    """Parse the doc's 0.7 A-Z index by script (never loaded into a prompt)."""
    lines = read_lines(doc_path)
    start = next(i for i, l in enumerate(lines) if l.startswith("## 0.7"))
    rows = []
    for l in lines[start:]:
        if l.startswith("## ") and not l.startswith("## 0.7"):
            break
        m = INDEX_ROW.match(l)
        if m and m["kind"] != "kind":
            tag = re.search(r"@SYS-[A-Z0-9-]+", m["tag"])
            rows.append({"name": m["sym"].strip("` "), "kind": m["kind"], "file": ALIASES.get(m["alias"], m["alias"]),
                         "line": int(m["line"]), "tag": tag.group(0) if tag else None})
    return rows


def reconcile(symbols: list[dict], index: list[dict]) -> tuple[list[str], dict]:
    """Attach owner tags; return (diff lines, per-file gate counts)."""
    by_key = {}
    for r in index:
        by_key.setdefault((r["file"], r["kind"], r["name"].lower()), []).append(r)
    diffs = []
    seen = set()
    for s in symbols:
        if s["kind"] not in GATE_KINDS or s["file"] not in CORE_FILES:
            continue
        cands = by_key.get((s["file"], s["kind"], s["name"].lower()), [])
        hit = next((r for r in cands if r["line"] == s["line"] and id(r) not in seen), None)
        hit = hit or next((r for r in cands if id(r) not in seen), None)
        if hit is None:
            why = EXPLAINED_EDITABLE if s["kind"] == "var" and "editable" in s.get("mods", []) else ""
            diffs.append((why, f"| source only | {s['kind']} | {s['name']} | {FILE_TO_ALIAS[s['file']]}:{s['line']} | {why} |"))
            continue
        seen.add(id(hit))
        s["tag"] = hit["tag"]
        if hit["line"] != s["line"]:
            diffs.append(("", f"| line differs | {s['kind']} | {s['name']} | {FILE_TO_ALIAS[s['file']]}:{s['line']} | doc says :{hit['line']} |"))
    members = {(s["file"], s["name"].lower(), s["line"]) for s in symbols if s["kind"] == "member"}
    for r in index:
        if id(r) not in seen:
            why = EXPLAINED_MEMBER if r["kind"] == "var" and (r["file"], r["name"].lower(), r["line"]) in members else ""
            diffs.append((why, f"| doc only | {r['kind']} | {r['name']} | {FILE_TO_ALIAS.get(r['file'], r['file'])}:{r['line']} | {why} |"))
    # functions/labels inside a state inherit the state's tag when they have none
    state_tag = {(s["file"], s["name"]): s.get("tag") for s in symbols if s["kind"] == "state"}
    for s in symbols:
        if not s.get("tag") and s.get("state"):
            s["tag"] = state_tag.get((s["file"], s["state"]))
    counts = {f: Counter(s["kind"] for s in symbols if s["file"] == f and s["kind"] in GATE_KINDS) for f in CORE_FILES}
    return diffs, counts


def write_report(diffs: list[str], counts: dict, total: int) -> Path:
    rep = ["# Symbol reconciliation (source vs doc)", "",
           f"Gate total (5 core files, labels excluded): **{total}** (doc: {GATE_TOTAL}).", "",
           "| File | " + " | ".join(SPEC_COUNTS["KF2Bot.uc"]) + " |", "|---|---|---|---|---|---|"]
    for f in CORE_FILES:
        cells = []
        for k, want in SPEC_COUNTS[f].items():
            got = counts[f].get(k, 0)
            cells.append(f"{got}" if got == want else f"**{got}** (doc {want})")
        rep.append(f"| {f} | " + " | ".join(cells) + " |")
    unexplained = [d for why, d in diffs if not why]
    n_src = sum(1 for why, _ in diffs if why == EXPLAINED_EDITABLE)
    n_doc = sum(1 for why, _ in diffs if why == EXPLAINED_MEMBER)
    rep += ["", f"Reconciliation: {total} source - {n_src} `var()` vars the doc missed + {n_doc} struct members "
            f"the doc counted = **{total - n_src + n_doc}** (doc {GATE_TOTAL}). Unexplained differences: "
            f"**{len(unexplained)}**.", "", "## Differences (source wins)", ""]
    rep += (["| what | kind | name | source | note |", "|---|---|---|---|---|"] + [d for _, d in diffs]) if diffs else ["None."]
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    p = REPORTS_DIR / "symbol_diff.md"
    p.write_text("\n".join(rep) + "\n", encoding="utf-8")
    return p


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--file", help="re-index a single legacy file (alias or name)")
    ap.add_argument("--src", help="index every .uc in this directory instead of legacy_dir")
    ap.add_argument("--out", default=str(SYMBOLS))
    a = ap.parse_args()
    ws = load_workspace()
    out = Path(a.out)
    if a.src:
        files = sorted(Path(a.src).glob("*.uc"))
        symbols = [s for f in files for s in index_file(f)]
        write_json(out, {"source": str(a.src), "symbols": symbols})
        print(f"symbol_indexer: {len(symbols)} symbols from {len(files)} files -> {out}")
        return 0
    legacy = Path(ws["legacy_dir"])
    if a.file:
        name = ALIASES.get(a.file, a.file)
        name = name if name.endswith(".uc") else name + ".uc"
        data = load_json(out)
        data["symbols"] = [s for s in data["symbols"] if s["file"] != name] + index_file(legacy / name)
        symbols = data["symbols"]
    else:
        names = CORE_FILES + list(ws.get("aux_legacy_files", []))
        missing = [n for n in names if not (legacy / n).is_file()]
        if missing:
            raise KitError(f"missing legacy files in {legacy}: {missing}")
        symbols = [s for n in names for s in index_file(legacy / n)]
    diffs, counts = reconcile(symbols, doc_index(Path(ws["doc_path"])))
    total = sum(sum(c.values()) for c in counts.values())
    write_json(out, {"source": "legacy", "gate_total": total, "symbols": symbols})
    rep = write_report(diffs, counts, total)
    n_src = sum(1 for why, _ in diffs if why == EXPLAINED_EDITABLE)
    n_doc = sum(1 for why, _ in diffs if why == EXPLAINED_MEMBER)
    unexplained = sum(1 for why, _ in diffs if not why)
    ok = total - n_src + n_doc == GATE_TOTAL and unexplained == 0
    print(f"symbol_indexer: {len(symbols)} symbols indexed; gate {total}/{GATE_TOTAL} "
          f"(reconciled {total - n_src + n_doc}) {'OK' if ok else 'MISMATCH'}; {len(diffs)} differences, "
          f"{unexplained} unexplained -> {rep.name}")
    return 0 if ok else 2


if __name__ == "__main__":
    run_main(main)
