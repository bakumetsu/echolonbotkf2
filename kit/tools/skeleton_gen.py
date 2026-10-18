"""G6 / D1: generate every class file of the rewrite from contracts.json + constants.json.

  python kit/tools/skeleton_gen.py                 # writes into package_src_dir (refuses to overwrite)
  python kit/tools/skeleton_gen.py --out DIR       # another directory (tests, dry runs)
  python kit/tools/skeleton_gen.py --class EcholonMut --force

Output per class: header, const block (from constants.json, D2), enums, structs, vars,
signature-only stubs for every function/event, states with in-state stubs and one `Stop;`
per label, and defaultproperties. Each stub carries a marker comment
`// @STUB(<milestone>) <tag> legacy:<Class.Symbol>`; splice.py replaces stubs by symbol and
later milestones only ever replace bodies.
"""
from __future__ import annotations

import argparse
from pathlib import Path

from common import KIT_DIR, KitError, load_json, load_workspace, run_main

IND = "    "


def stub_marker(item: dict) -> str:
    flag = f" {item['flag']}" if item.get("flag") else ""
    return f"// @STUB({item['milestone']}) {item.get('tag') or '-'} legacy:{item['legacy_ref']}{flag}"


def function_stub(f: dict, indent: str = "") -> list[str]:
    return [indent + stub_marker(f), indent + f["signature"], indent + "{", indent + "}", ""]


def render_class(name: str, c: dict, consts: list[dict]) -> str:
    out = [c["header"].replace(" extends ", "\n" + IND + "extends ", 0) if False else c["header"], ""]
    mine = [k for k in consts if k["class"] == name]
    if mine:
        out.append("// Constants: generated from contracts/constants.json (D2). Edit there, not here.")
        out += [f"const {k['name']} = {k['value']};" for k in mine]
        out.append("")
    for e in c["enums"]:
        out += [e["text"], ""]
    for s in c["structs"]:
        out += [s["text"], ""]
    for v in c["vars"]:
        if v["names"]:
            out.append(v["text"])
    if c["vars"]:
        out.append("")
    for f in c["functions"]:
        if not f["state"]:
            out += function_stub(f)
    for st in c["states"]:
        out += [stub_marker(st), st["signature"], "{"]
        if st["ignores"]:
            out.append(IND + "ignores " + ", ".join(st["ignores"]) + ";")
            out.append("")
        for f in c["functions"]:
            if f["state"] == st["name"]:
                out += function_stub(f, IND)
        for lab in st["labels"]:
            out += [f"{lab}:", IND + "Stop;"]
        if out[-1] == "":
            out.pop()
        out += ["}", ""]
    dp = c.get("defaultproperties")
    out += ["defaultproperties", "{"]
    if dp:
        out += [IND + l.strip() for l in dp["lines"]]
    out += ["}", ""]
    return "\n".join(out)


def generate(out_dir: Path, only: str | None = None, force: bool = False) -> list[Path]:
    contracts = load_json(KIT_DIR / "contracts" / "contracts.json")
    consts = load_json(KIT_DIR / "contracts" / "constants.json")["constants"]
    out_dir.mkdir(parents=True, exist_ok=True)
    written = []
    for name, c in contracts["classes"].items():
        if only and name.lower() != only.lower():
            continue
        p = out_dir / c["file"]
        if p.exists() and not force:
            raise KitError(f"{p} exists; skeletons never overwrite real code (use --force for a fresh skeleton)")
        p.write_text(render_class(name, c, consts), encoding="utf-8", newline="\r\n")
        written.append(p)
    if only and not written:
        raise KitError(f"no class {only} in contracts.json")
    return written


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path)
    ap.add_argument("--class", dest="cls")
    ap.add_argument("--force", action="store_true")
    a = ap.parse_args()
    out = a.out or Path(load_workspace()["package_src_dir"])
    files = generate(out, a.cls, a.force)
    print(f"skeleton_gen: wrote {len(files)} class files -> {out}")
    return 0


if __name__ == "__main__":
    run_main(main)
