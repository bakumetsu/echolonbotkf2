"""G5: single-writer boundary auditor (doc Part 6.2, encoded in contracts/single_writer.json).

  python kit/tools/boundary_auditor.py Classes/*.uc          # JSONL findings, exit 1 on any
  python kit/tools/boundary_auditor.py --corpus              # audit the legacy corpus (report)

A write is: an assignment (=, +=, ..., ++/--) to a guarded var or to one of its fields or
elements; a dynamic-array mutation (AddItem/RemoveItem/Remove/Insert/InsertItem/Add/Empty,
`.Length =`); or passing it as an `out` argument. The writer is the enclosing function
(`Func`, `State.Func`, or `State:label` for label code) of the enclosing class. Locals and
parameters that shadow a guarded name are ignored. Calls to Mut-owned mutators are calls,
not writes, so they are never flagged (doc 6.1).
"""
from __future__ import annotations

import argparse
import json
import sys
from fnmatch import fnmatchcase
from pathlib import Path

from common import expand_globs, CORE_FILES, GENERATED_DIR, KIT_DIR, REPORTS_DIR, load_json, load_workspace, read_text, run_main
from uc_lexer import IDENT, PUNCT, match_brace
from uc_parser import parse_file

ASSIGN_OPS = {"=", "+=", "-=", "*=", "/=", "$=", "@=", "++", "--"}
ARRAY_MUTATORS = {"additem", "removeitem", "remove", "insert", "insertitem", "add", "empty"}
RESET_VALUES = {"false", "none", "''", '""', "0", "0.0", "0.0000000"}


def load_rules() -> dict:
    return load_json(KIT_DIR / "contracts" / "single_writer.json")


def role_of(cls: str, rules: dict) -> str | None:
    for role, names in rules["roles"].items():
        if cls.lower() in (n.lower() for n in names):
            return role
    return None


def out_params() -> dict[str, list[int]]:
    """function name (lower) -> indexes of its `out` params, from symbols + contracts."""
    res: dict[str, list[int]] = {}
    for p in (GENERATED_DIR / "symbols.json", GENERATED_DIR / "sdk_symbols.json"):
        if not p.is_file():
            continue
        data = load_json(p)
        for s in data.get("symbols", []):
            idx = [i for i, prm in enumerate(s.get("params") or []) if "out" in prm.get("mods", [])]
            if idx:
                res[s["name"].lower()] = idx
        for c in data.get("classes", {}).values():
            for name, o in c.get("out_params", {}).items():
                res[name.lower()] = o
    return res


def _writer_matches(entry: dict, role: str, writer: str, rules: dict) -> bool:
    want = entry["role"]
    if want == "hub":
        if role not in rules["hub_roles"]:
            return False
    elif want != role:
        return False
    pat = entry["function"]
    name = writer.split(".")[-1]
    return pat == "*" or fnmatchcase(writer.lower(), pat.lower()) or (
        "." not in pat and ":" not in pat and name.lower() == pat.lower())


def _rhs_is_reset(toks, i) -> bool:
    j = i + 1
    vals = []
    while j < len(toks) and toks[j].text != ";":
        vals.append(toks[j].text.lower())
        j += 1
    return len(vals) == 1 and vals[0] in RESET_VALUES


def find_writes(pf, guarded_lower: dict[str, str], outs: dict[str, list[int]]):
    """Yield (var, writer, line, kind, is_reset) for every write to a guarded var."""
    t = pf.tokens
    scopes = []  # (start, end, writer, shadowed names)
    for d in pf.by_kind("function", "event"):
        if d.body_open is None:
            continue
        shadow = {p.name.lower() for p in d.params}
        k = d.body_open
        while k < d.tok_end:
            if t[k].is_("local"):
                e = k
                while t[e].text != ";":
                    e += 1
                shadow |= {x.low for x in t[k + 1:e] if x.kind == IDENT}
                k = e
            k += 1
        scopes.append((d.body_open, d.tok_end, d.qual, shadow))
    for d in pf.by_kind("state"):
        if d.label_code:
            scopes.append((d.label_code[0], d.label_code[1], f"{d.name}:label", set()))

    def scope_at(i):
        best = None
        for s in scopes:
            if s[0] <= i <= s[1] and (best is None or s[0] >= best[0]):
                best = s
        return best

    for i, x in enumerate(t):
        if x.kind != IDENT or x.low not in guarded_lower:
            continue
        sc = scope_at(i)
        if sc is None or x.low in sc[3] and (i == 0 or t[i - 1].text != "."):
            continue
        var = guarded_lower[x.low]
        # skip a trailing [..] and .Field chains to find what follows the l-value
        j = i + 1
        while j < len(t):
            if t[j].text == "[":
                j = match_brace(t, j, "[", "]") + 1
            elif t[j].text == "." and j + 1 < len(t) and t[j + 1].kind == IDENT \
                    and not (j + 2 < len(t) and t[j + 2].text == "("):
                if t[j + 1].low == "length" and j + 2 < len(t) and t[j + 2].text == "=":
                    yield var, sc[2], x.line, "array length", False
                j += 2
            else:
                break
        nxt = t[j] if j < len(t) else None
        prev = t[i - 1] if i > 0 else None
        if nxt is not None and nxt.kind == PUNCT and nxt.text in ASSIGN_OPS and nxt.text not in ("==",):
            yield var, sc[2], x.line, "assignment", nxt.text == "=" and _rhs_is_reset(t, j)
        elif prev is not None and prev.text in ("++", "--") and (i < 2 or t[i - 2].kind != IDENT):
            yield var, sc[2], x.line, "increment", False
        elif nxt is not None and nxt.text == "." and j + 2 < len(t) and t[j + 1].low in ARRAY_MUTATORS \
                and t[j + 2].text == "(":
            yield var, sc[2], x.line, f"array {t[j + 1].text}", False
        else:
            # out-argument: find the call this token is an argument of
            depth, k = 0, i - 1
            while k >= 0:
                if t[k].text == ")":
                    depth += 1
                elif t[k].text == "(":
                    if depth == 0:
                        break
                    depth -= 1
                elif t[k].text in (";", "{", "}"):
                    k = -1
                    break
                k -= 1
            if k > 0 and t[k - 1].kind == IDENT and t[k - 1].low in outs:
                argi, d2 = 0, 0
                for y in t[k + 1:i]:
                    if y.text in ("(", "["):
                        d2 += 1
                    elif y.text in (")", "]"):
                        d2 -= 1
                    elif y.text == "," and d2 == 0:
                        argi += 1
                if argi in outs[t[k - 1].low]:
                    yield var, sc[2], x.line, f"out-arg of {t[k - 1].text}", False


def audit(path: Path, rules: dict | None = None, outs: dict | None = None) -> list[dict]:
    rules = rules or load_rules()
    outs = outs if outs is not None else out_params()
    pf = parse_file(read_text(path))
    role = role_of(pf.class_name, rules) or "other"
    guarded = rules["guarded"]
    gl = {k.lower(): k for k in guarded}
    found = []
    for var, writer, line, kind, is_reset in find_writes(pf, gl, outs):
        g = guarded[var]
        ok = any(_writer_matches(e, role, writer, rules) for e in g.get("writers", []))
        ok = ok or (is_reset and any(_writer_matches(e, role, writer, rules) for e in g.get("clear", [])))
        if not ok:
            allowed = ", ".join(f"{e['role']}.{e['function']}" for e in g.get("writers", [])) or "nobody (config only)"
            found.append({"rule": "B001", "file": path.name, "line": line, "severity": "ERROR",
                          "msg": f"{kind} of guarded `{var}` in {pf.class_name}.{writer} ({role})",
                          "fix_hint": f"only {allowed} may write it: {g['rule']}"})
    return found


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="*")
    ap.add_argument("--corpus", action="store_true", help="audit the legacy corpus and write a report")
    a = ap.parse_args()
    if a.corpus:
        ws = load_workspace()
        rows, total = [], 0
        for n in CORE_FILES:
            f = audit(Path(ws["legacy_dir"]) / n)
            total += len(f)
            rows += [f"| {x['file']}:{x['line']} | {x['msg']} |" for x in f]
        rep = ["# Boundary audit of the legacy corpus", "", f"Findings: **{total}**", ""]
        rep += (["| where | finding |", "|---|---|"] + rows) if rows else ["None: legacy code respects Part 6.2."]
        (REPORTS_DIR / "boundary_legacy.md").write_text("\n".join(rep) + "\n", encoding="utf-8")
        print(f"boundary_auditor: {total} findings in the legacy corpus -> boundary_legacy.md")
        return 0
    bad = 0
    for f in expand_globs(a.files):
        for x in audit(Path(f)):
            bad += 1
            print(json.dumps(x))
    return 1 if bad else 0


if __name__ == "__main__":
    run_main(main)
