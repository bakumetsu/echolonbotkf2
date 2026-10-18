"""G5: index the KF2 SDK script source into kit/generated/sdk_symbols.json.

  python kit/tools/sdk_index.py                   # walks sdk_src_dir (Development\\Src\\*\\Classes\\*.uc)
  python kit/tools/sdk_index.py --src DIR         # another tree (tests use a tiny fixture SDK)
  python kit/tools/sdk_index.py --lookup Controller.MoveToward

Per class: package, parent, file, functions {name: signature}, out_params {name: [idx]},
vars {name: type}, states. Natives the doc could not find in source (doc Part 1.2) are seeded
as "opaque" names: allowed, behaviour unverified. Files that fail to parse are listed, not fatal.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

from common import GENERATED_DIR, load_json, load_workspace, read_lines, run_main, write_json
from uc_lexer import LexError
from uc_parser import parse_file

OUT = GENERATED_DIR / "sdk_symbols.json"


SKIP_PACKAGES = {"kf2bots", "echolonbot", "mod architecture"}  # our own code is not SDK


def index_tree(root: Path) -> dict:
    classes, failed = {}, []
    files = [f for f in sorted(root.glob("*/Classes/*.uc")) if f.parent.parent.name.lower() not in SKIP_PACKAGES]
    for f in files:
        try:
            pf = parse_file("\n".join(read_lines(f)) + "\n")
        except (LexError, IndexError, ValueError) as e:
            failed.append(f"{f.relative_to(root)}: {e}")
            continue
        if not pf.class_name:
            continue
        funcs, outs, vars_, states, consts, members = {}, {}, {}, [], {}, set()
        for d in pf.decls:
            if d.kind in ("function", "event") and not d.state:
                funcs[d.name] = d.signature
                o = [i for i, p in enumerate(d.params) if "out" in p.mods]
                if o:
                    outs[d.name] = o
            elif d.kind == "var":
                vars_[d.name] = d.var_type
            elif d.kind == "state":
                states.append(d.name)
            elif d.kind == "const":
                consts[d.name] = d.signature
            elif d.kind == "member":
                members.add(d.name)
        classes[pf.class_name] = {"package": f.parent.parent.name, "parent": pf.parent or None,
                                  "file": str(f.relative_to(root)).replace("\\", "/"),
                                  "functions": funcs, "out_params": outs, "vars": vars_, "consts": consts,
                                  "members": sorted(members), "states": states}
    return {"root": str(root), "files": len(files), "failed": failed, "classes": classes}


def doc_opaque(doc_path: Path) -> list[str]:
    """Symbols from doc Part 1.2 (used by the mod, not found in SDK source)."""
    if not Path(doc_path).is_file():
        return []
    lines = read_lines(doc_path)
    try:
        s = next(i for i, l in enumerate(lines) if l.startswith("## 1.2"))
    except StopIteration:
        return []
    out = []
    for l in lines[s + 1:]:
        if l.startswith("## "):
            break
        m = re.match(r"^\|\s*`(\w+)`", l)
        if m:
            out.append(m.group(1))
    return out


def lookup(data: dict, cls: str, member: str) -> tuple[str, str] | None:
    """Find member in cls or its SDK ancestors. Returns (owner class, signature/type)."""
    classes = {k.lower(): (k, v) for k, v in data["classes"].items()}
    cur, seen = cls.lower(), set()
    while cur in classes and cur not in seen:
        seen.add(cur)
        name, c = classes[cur]
        for table in ("functions", "vars", "consts"):
            for k, v in c.get(table, {}).items():
                if k.lower() == member.lower():
                    return name, v
        cur = (c.get("parent") or "").lower()
    return None


def all_member_names(data: dict) -> set[str]:
    names = {n.lower() for n in data.get("opaque", [])}
    for c in data["classes"].values():
        names |= {k.lower() for k in c["functions"]} | {k.lower() for k in c["vars"]}
        names |= {k.lower() for k in c.get("consts", {})} | {m.lower() for m in c.get("members", [])}
        names |= {s.lower() for s in c["states"]}
    return names


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", type=Path)
    ap.add_argument("--out", type=Path, default=OUT)
    ap.add_argument("--lookup", help="Class.Member to resolve through the parent chain")
    a = ap.parse_args()
    ws = load_workspace()
    if a.lookup:
        cls, _, member = a.lookup.partition(".")
        hit = lookup(load_json(a.out), cls, member)
        print(f"{hit[0]}: {hit[1]}" if hit else f"{a.lookup}: not found")
        return 0 if hit else 3
    root = a.src or Path(ws["sdk_src_dir"])
    if not root.is_dir():
        print(f"SDK source not found at {root} (set sdk_src_dir in workspace.json)", file=sys.stderr)
        return 1
    data = index_tree(root)
    data["opaque"] = doc_opaque(Path(ws["doc_path"]))
    write_json(a.out, data)
    print(f"sdk_index: {len(data['classes'])} classes from {data['files']} files, {len(data['failed'])} unparsed, "
          f"{len(data['opaque'])} opaque natives -> {a.out.name}")
    return 0


if __name__ == "__main__":
    run_main(main)
