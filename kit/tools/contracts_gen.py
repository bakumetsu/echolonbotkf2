"""G6: generate contracts/contracts.json and contracts/constants.json from the legacy corpus.

  python kit/tools/contracts_gen.py            # writes both files (refuses to overwrite edits)
  python kit/tools/contracts_gen.py --force    # regenerate even if the contracts were hand-edited

The contracts are the rewrite's source of truth for every class's shape: header, structs,
enums, vars, function/state signatures, labels, defaultproperties, plus the milestone and
@SYS tag that owns each body (doc D6 map). Legacy names are renamed with workspace class_map,
and D5-dropped symbols are left out. After generation the file is HUMAN-EDITABLE; the
"_generated_hash" field lets the tool notice hand edits and refuse to clobber them.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

from common import CORE_FILES, KIT_DIR, KitError, load_json, load_workspace, read_lines, read_text, run_main, write_json
from uc_parser import join_tokens, parse_file

CONTRACTS = KIT_DIR / "contracts" / "contracts.json"
CONSTANTS = KIT_DIR / "contracts" / "constants.json"

# Doc D6 milestone map, tag suffix -> milestone. M5 split (a/b/c) is a default: edit freely.
MILESTONES = {
    "M1": ["MUT-BOOT", "MUT-SPAWN", "MUT-PERK", "MUT-UTIL"],
    "M2": ["NAV-CONFIG", "NAV-EPISODE", "NAV-WATCHDOG", "NAV-LEADER", "NAV-PATH", "NAV-DECIDE", "NAV-STUCK",
           "NAV-HANDLE", "NAV-STATUS", "NAV-STATE"],
    "M3": ["BASE-BOOT", "BASE-PERCEPT", "BASE-FIRE", "BASE-MOVE", "BASE-PATH", "BASE-SHOP", "BASE-OBJ",
           "BASE-ZEDS", "BASE-RANK"],
    "M4": ["MUT-PLATOON", "MUT-SUCCESSION", "MUT-WAVE", "MUT-ORDERS", "MUT-REGROUP", "MUT-NODEBLOCK",
           "MUT-HEALCOOL"],
    "M5a": ["BASE-FORM", "BASE-OVERWATCH", "BASE-CQB", "BASE-GRUNT", "BASE-PANIC", "BASE-RELOAD"],
    "M5b": ["BASE-LTBOUND", "BASE-WEDGE", "BASE-EMOTE", "BASE-WEAPON", "BASE-AUDIT", "BASE-HEALQ"],
    "M5c": ["LOGIC-HEAL", "LOGIC-WATCHDOG", "LOGIC-GRUNTMOVE", "LOGIC-MOVEVAL", "LOGIC-DEATH", "LOGIC-UTIL"],
    "M6": ["BOT-HUB", "BOT-MOVE", "BOT-COMBAT", "BOT-HEAL", "BOT-SHOP", "BOT-TERM"],
}
TAG_TO_MS = {f"@SYS-{t}": m for m, tags in MILESTONES.items() for t in tags}
AUX_MILESTONE = {"AIWeaponInfo": "M5b"}  # other aux classes default to M1 (used by Mut boot/spawn)
UNVERIFIED_ENTRY = {"GrenadeTarget", "GetItem"}  # doc D1/D2: thin port, prune at the M6 gate
CONFIG_RENAME = {"config(BotsMut)": "config(EcholonBot)"}


class Renamer:
    def __init__(self, class_map: dict, package: str):
        self.map = {k: v for k, v in class_map.items() if not k.startswith("_")}
        names = sorted(self.map, key=len, reverse=True)
        self.rx = re.compile(r"\b(" + "|".join(map(re.escape, names)) + r")\b")
        self.package = package

    def __call__(self, text: str) -> str:
        text = re.sub(r"\bKF2Bots\.", f"{self.package}.", text)
        text = self.rx.sub(lambda m: self.map[m.group(1)], text)
        for a, b in CONFIG_RENAME.items():
            text = text.replace(a, b)
        return text


def milestone_for(tag: str | None, legacy_class: str) -> str:
    if tag in TAG_TO_MS:
        return TAG_TO_MS[tag]
    return AUX_MILESTONE.get(legacy_class, "M1")


def _stmt_text(pf, d) -> str:
    return join_tokens(pf.tokens[d.tok_start:d.tok_end + 1])


def class_contract(path: Path, tags: dict, ren: Renamer, dropped: set[str]) -> tuple[str, dict, list[dict]]:
    pf = parse_file(read_text(path))
    legacy = pf.class_name
    new = ren(legacy)
    out = {"legacy": legacy, "file": f"{new}.uc", "header": ren(_stmt_text(pf, pf.decls[0])),
           "parent": ren(pf.parent), "structs": [], "enums": [], "vars": [], "consts": [],
           "functions": [], "states": [], "defaultproperties": None}
    consts = []
    seen_stmt = set()
    lines = read_lines(path)
    for d in pf.decls:
        if d.name.lower() in dropped:
            continue
        tag = tags.get((legacy, d.state or "", d.name, d.kind))
        if d.kind == "struct" and not d.state:
            out["structs"].append({"name": d.name, "text": ren(_stmt_text(pf, d))})
        elif d.kind == "enum" and not d.state:
            out["enums"].append({"name": d.name, "values": d.values, "text": ren(_stmt_text(pf, d))})
        elif d.kind == "var" and not d.state and d.tok_start not in seen_stmt:
            seen_stmt.add(d.tok_start)
            group = [x.name for x in pf.decls if x.kind == "var" and x.tok_start == d.tok_start]
            keep = [n for n in group if n.lower() not in dropped]
            text = _stmt_text(pf, d)
            for n in group:
                if n not in keep:  # strip a dropped name out of a multi-name declaration
                    text = re.sub(r",\s*\b%s\b|\b%s\b\s*," % (n, n), "", text)
            out["vars"].append({"names": keep, "text": ren(text), "tag": tag})
        elif d.kind == "const" and not d.state:
            value = _stmt_text(pf, d).split("=", 1)[1].rstrip(";").strip()
            out["consts"].append(d.name)
            consts.append({"name": d.name, "class": new, "value": ren(value), "tag": tag,
                           "legacy": f"{path.name}:{d.line}"})
        elif d.kind in ("function", "event"):
            ms = milestone_for(tag, legacy)
            out["functions"].append({"name": d.name, "state": d.state, "kind": d.kind,
                                     "signature": ren(d.signature), "return_type": ren(d.return_type) or None,
                                     "params": [{"type": ren(p.type), "name": p.name, "mods": p.mods} for p in d.params],
                                     "tag": tag, "milestone": ms, "legacy_ref": f"{legacy}.{d.qual}"})
        elif d.kind == "state":
            labels = [x.name for x in pf.decls if x.kind == "label" and x.state == d.name]
            st = {"name": d.name, "signature": ren(d.signature), "parent": d.parent or None,
                  "ignores": d.ignores, "labels": labels, "tag": tag, "milestone": milestone_for(tag, legacy),
                  "legacy_ref": f"{legacy}.{d.name}"}
            if d.name in UNVERIFIED_ENTRY:
                st["flag"] = "UNVERIFIED-ENTRY"
            out["states"].append(st)
        elif d.kind == "defaultproperties":
            body = []
            for l in lines[d.line:d.end - 1]:
                s = l.split("//")[0].rstrip().rstrip(";").rstrip()
                if s.strip() and s.strip() not in ("{", "}") and not any(re.search(rf"\b{x}\b", s, re.I) for x in dropped):
                    body.append(ren(s))
            out["defaultproperties"] = {"lines": body, "milestone": milestone_for(None, legacy) if legacy in AUX_MILESTONE
                                        else ("M1" if legacy in ("KF2BotsMut",) else
                                              {"KF2BotsFollowNavBase": "M2", "KF2BotBase": "M3"}.get(legacy, "M1"))}
    return new, out, consts


def flat_symbols(classes: dict) -> list[dict]:
    """The flat list the validator reads (states/functions/labels/classes that exist in the rewrite)."""
    out = []
    for cname, c in classes.items():
        out.append({"kind": "class", "name": cname, "class": cname, "parent": c["parent"]})
        for f in c["functions"]:
            out.append({"kind": f["kind"], "name": f["name"], "state": f["state"], "class": cname})
        for s in c["states"]:
            out.append({"kind": "state", "name": s["name"], "parent": s["parent"], "class": cname})
            out += [{"kind": "label", "name": l, "state": s["name"], "class": cname} for l in s["labels"]]
    return out


def content_hash(data: dict) -> str:
    body = {k: v for k, v in data.items() if k != "_generated_hash"}
    return hashlib.sha256(json.dumps(body, sort_keys=True).encode()).hexdigest()[:16]


def generate(ws: dict) -> tuple[dict, dict]:
    syms = load_json(KIT_DIR / "generated" / "symbols.json")["symbols"]
    tags = {(s["class"], s.get("state") or "", s["name"], s["kind"]): s.get("tag") for s in syms}
    ren = Renamer(ws["class_map"], ws["package_name"])
    dropped = set(load_json(KIT_DIR / "contracts" / "dropped_symbols.json"))
    classes, consts = {}, []
    for n in CORE_FILES + list(ws.get("aux_legacy_files", [])):
        name, c, k = class_contract(Path(ws["legacy_dir"]) / n, tags, ren, dropped)
        classes[name] = c
        consts += k
    contracts = {"_comment": "Generated by contracts_gen.py, then human-editable. One entry per class of the rewrite.",
                 "package": ws["package_name"], "milestones": MILESTONES, "classes": classes,
                 "symbols": flat_symbols(classes)}
    contracts["_generated_hash"] = content_hash(contracts)
    constants = {"_comment": "Single source of every const (D2). skeleton_gen emits these as const blocks.",
                 "constants": consts}
    return contracts, constants


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true")
    a = ap.parse_args()
    if CONTRACTS.is_file() and not a.force:
        cur = load_json(CONTRACTS)
        if cur.get("_generated_hash") != content_hash(cur):
            raise KitError("contracts.json has hand edits; re-run with --force to discard them")
    contracts, constants = generate(load_workspace())
    write_json(CONTRACTS, contracts)
    write_json(CONSTANTS, constants)
    n_f = sum(len(c["functions"]) for c in contracts["classes"].values())
    n_s = sum(len(c["states"]) for c in contracts["classes"].values())
    print(f"contracts_gen: {len(contracts['classes'])} classes, {n_f} functions/events, {n_s} states, "
          f"{len(constants['constants'])} consts -> contracts.json, constants.json")
    return 0


if __name__ == "__main__":
    run_main(main)
