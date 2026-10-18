"""G4: UnrealScript (UE3/KF2) rule checker. Token-based, not line regex.

  python kit/tools/ast_validator.py Classes/*.uc            # JSONL findings on stdout
  python kit/tools/ast_validator.py --corpus-selftest       # legacy corpus must give 0 ERRORs
  python kit/tools/ast_validator.py --format text FILE      # human-readable

Each finding: {"rule","file","line","msg","fix_hint","severity"}. Exit 1 if any ERROR.
Rule docs and corpus evidence: kit/bible/BIBLE_CORE.md and kit/reports/validator_selftest.md.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from common import (CORE_FILES, expand_globs, GENERATED_DIR, KIT_DIR, REPORTS_DIR, load_json, load_workspace,
                    read_text, run_main)
from uc_lexer import IDENT, NAME, NUMBER, PUNCT, STRING, LexError, match_brace
from uc_parser import ParsedFile, parse_file

ERROR, WARN = "ERROR", "WARN"
LATENT = {"sleep", "finishrotation", "finishanim", "moveto", "movetoward", "movetodirectnonpathpos",
          "waitforlanding"}
NAME_ARG_APIS = {"gotostate": 0, "isinstate": 0, "settimer": 2, "cleartimer": 0, "istimeractive": 0,
                 "gettimercount": 0, "gettimerrate": 0, "pausetimer": 1}
TIMER_APIS = {"settimer": 2, "cleartimer": 0, "istimeractive": 0, "gettimercount": 0, "gettimerrate": 0}
BAD_ARRAY_MEMBERS = {"count": "Length", "size": "Length", "push": "AddItem", "contains": "Find(x) >= 0"}
BUILTIN_TYPES = {"int", "float", "byte", "bool", "string", "name", "vector", "rotator"}
FORBIDDEN_PARENTS = {"KF2BotsFollowNavBase": "KFAIController", "EcholonFollowNavBase": "KFAIController"}


class Ctx:
    def __init__(self, path: Path, pf: ParsedFile, known: dict):
        self.path, self.pf, self.t, self.known = path, pf, pf.tokens, known
        self.out: list[dict] = []
        self.label_ranges = [d.label_code for d in pf.by_kind("state") if d.label_code]
        self.func_ranges = [(d.body_open, d.tok_end) for d in pf.by_kind("function", "event") if d.body_open]

    def add(self, rule, line, sev, msg, hint):
        self.out.append({"rule": rule, "file": self.path.name, "line": line, "msg": msg,
                         "fix_hint": hint, "severity": sev})

    def in_label_code(self, i) -> bool:
        return any(a <= i <= b for a, b in self.label_ranges) and not self.in_func(i)

    def in_func(self, i) -> bool:
        return any(a <= i <= b for a, b in self.func_ranges)

    def state_at(self, i):
        for d in self.pf.by_kind("state"):
            if d.tok_start <= i <= d.tok_end:
                return d
        return None

    def call_args(self, i):
        """For an identifier at i followed by '(', return list of arg token-lists."""
        t = self.t
        if i + 1 >= len(t) or t[i + 1].text != "(":
            return None
        c = match_brace(t, i + 1, "(", ")")
        args, cur, depth = [], [], 0
        for x in t[i + 2:c]:
            if x.text in ("(", "["):
                depth += 1
            elif x.text in (")", "]"):
                depth -= 1
            if x.text == "," and depth == 0:
                args.append(cur)
                cur = []
            else:
                cur.append(x)
        if cur or args:
            args.append(cur)
        return args


def _stmt_starts(t, a, b):
    """Token indices that begin a statement inside t[a+1:b] (a = '{', b = '}')."""
    out, expect, paren = [], True, 0
    for i in range(a + 1, b):
        x = t[i]
        if x.text == "(":
            paren += 1
        elif x.text == ")":
            paren -= 1
        if paren:
            continue
        if expect and x.text not in ("{", "}", ";"):
            out.append(i)
            expect = False
        if x.text in ("{", "}", ";") or (x.text == ":" and i > 0 and t[i - 1].kind == IDENT):
            expect = True
    return out


def rule_u001_u002(c: Ctx):
    t = c.t
    for d in c.pf.by_kind("function", "event"):
        if d.body_open is None:
            continue
        seen_stmt = None
        for i in _stmt_starts(t, d.body_open, d.tok_end):
            if t[i].is_("local"):
                if seen_stmt is not None:
                    c.add("U001", t[i].line, ERROR, f"`local` after a statement in {d.qual} (first statement line {seen_stmt})",
                          "move every `local` declaration to the top of the function body")
                _check_initializer(c, i, "local")
            elif seen_stmt is None and not t[i].is_("const"):
                seen_stmt = t[i].line
    for i, x in enumerate(t):
        if x.is_("var") and (i == 0 or t[i - 1].text in (";", "{", "}")):
            _check_initializer(c, i, "var")


def _check_initializer(c, i, word):
    t, angle, paren = c.t, 0, 0
    j = i + 1
    while j < len(t) and t[j].text != ";":
        s = t[j].text
        if s == "(":
            paren += 1
        elif s == ")":
            paren -= 1
        elif s == "<":
            angle += 1
        elif s == ">":
            angle -= 1
        elif s == ">>":
            angle -= 2
        elif s == "=" and angle <= 0 and paren == 0:
            c.add("U002", t[j].line, ERROR, f"initializer on `{word}` declaration",
                  "declare without a value; assign in code (local) or in defaultproperties (var)")
            return
        j += 1


def rule_u003_u004_u005(c: Ctx):
    t = c.t
    for i, x in enumerate(t):
        if x.kind == IDENT and x.low in LATENT and i + 1 < len(t) and t[i + 1].text == "(" \
                and (i == 0 or t[i - 1].text != "."):
            if not c.in_label_code(i):
                c.add("U003", x.line, ERROR, f"latent `{x.text}` outside state label code",
                      "latent functions only run in state code (after a label like Begin:)")
    for d in c.pf.by_kind("state"):
        if not d.label_code:
            continue
        a, b = d.label_code
        starts = _stmt_starts(t, a - 1, b)
        for n, i in enumerate(starts):
            if c.in_func(i):
                continue
            if t[i].is_("return"):
                c.add("U004", t[i].line, ERROR, f"`return` in label code of state {d.name}",
                      "use `Stop;` or `GotoState(...)` + `Stop;` in label code")
            if t[i].is_("gotostate"):
                nxt = starts[n + 1] if n + 1 < len(starts) else b
                y = t[nxt]
                ok = (y.text == "}" or y.is_("stop", "goto")
                      or (y.kind == IDENT and y.low in LATENT))
                if not ok:
                    c.add("U005", t[i].line, WARN, f"GotoState in label code of {d.name} is not followed by Stop/goto/latent",
                          "add `Stop;` after GotoState(...) in label code (legacy convention)")


def rule_u006(c: Ctx):
    t = c.t
    for i, x in enumerate(t):
        if x.kind == IDENT and x.low in NAME_ARG_APIS and (i == 0 or t[i - 1].text != "function"):
            args = c.call_args(i)
            pos = NAME_ARG_APIS[x.low]
            if args and len(args) > pos and len(args[pos]) == 1 and args[pos][0].kind == STRING:
                c.add("U006", x.line, ERROR, f"{x.text} expects a name ('Foo'), got a string {args[pos][0].text}",
                      f"use single quotes: '{args[pos][0].text.strip(chr(34))}'")


def rule_u007(c: Ctx):
    for d in c.pf.by_kind("defaultproperties"):
        lines = read_text(c.path).split("\n")[d.line:d.end - 1]
        for k, l in enumerate(lines, start=d.line + 1):
            s = l.split("//")[0].rstrip()
            if s.endswith(";"):
                c.add("U007", k, WARN, "semicolon in defaultproperties (corpus convention: none, 74 of 75 lines)",
                      "drop the trailing ';'")


def rule_u008(c: Ctx):
    t = c.t
    classes = c.known["classes"]
    for i, x in enumerate(t):
        if x.text == "?" and x.kind == PUNCT:
            c.add("U008", x.line, WARN, "ternary `?:` (compiles in KF2 but banned by house style)",
                  "use if/else")
        elif x.kind == IDENT and x.low == "null":
            c.add("U008", x.line, ERROR, "`null` is not UnrealScript", "use `None`")
        elif x.kind == IDENT and x.low in BAD_ARRAY_MEMBERS and i > 0 and t[i - 1].text == ".":
            c.add("U008", x.line, ERROR, f"`.{x.text}` is not a dynamic-array member",
                  f"use `.{BAD_ARRAY_MEMBERS[x.low]}`")
        elif x.is_("array") and i + 3 < len(t) and t[i + 1].text == "<" and t[i + 2].is_("array"):
            c.add("U008", x.line, ERROR, "nested dynamic arrays are not allowed",
                  "wrap the inner array in a struct: array<FMyRow>")
        elif x.text == "(" and i + 3 < len(t) and t[i + 2].text == ")" and t[i + 1].kind == IDENT \
                and (t[i + 1].low in BUILTIN_TYPES or t[i + 1].low in classes) \
                and t[i + 3].kind in (IDENT, NUMBER, STRING, NAME) and (i == 0 or t[i - 1].kind != IDENT):
            c.add("U008", x.line, ERROR, f"C-style cast ({t[i + 1].text})expr",
                  f"use {t[i + 1].text}(expr)")


def rule_u009(c: Ctx):
    t = c.t
    states, funcs, labels = c.known["states"], c.known["functions"], c.known["labels"]
    for i, x in enumerate(t):
        if x.kind != IDENT or (i > 0 and t[i - 1].text in (".", "function", "event")):
            continue
        low = x.low
        if low in ("gotostate", "isinstate"):
            args = c.call_args(i)
            if args and len(args[0]) == 1 and args[0][0].kind == NAME:
                s = args[0][0].text.strip("'").lower()
                if s and s != "none" and s not in states:
                    c.add("U009", x.line, ERROR, f"{x.text} target state '{s}' does not exist",
                          "check the state name against symbols.json / contracts.json")
                elif low == "gotostate" and len(args) > 1 and len(args[1]) == 1 and args[1][0].kind == NAME:
                    lab = args[1][0].text.strip("'").lower()
                    if lab not in labels.get(s, set()) | labels.get("*", set()):
                        c.add("U009", x.line, ERROR, f"GotoState label '{lab}' not found in state '{s}'",
                              "use a label that exists in that state (or a parent state)")
        elif low in TIMER_APIS:
            args = c.call_args(i)
            pos = TIMER_APIS[low]
            if args and len(args) > pos and len(args[pos]) == 1 and args[pos][0].kind == NAME \
                    and len(args) <= pos + 1:
                f = args[pos][0].text.strip("'").lower()
                if f not in funcs:
                    c.add("U009", x.line, ERROR, f"{x.text} names function '{f}' that does not exist",
                          "timer targets must be functions of this class (or pass the target object)")
        elif low == "goto" and c.in_label_code(i):
            j = i + 1 + (t[i + 1].text == "(")
            st = c.state_at(i)
            if t[j].kind == NAME and st:
                lab = t[j].text.strip("'").lower()
                if lab not in labels.get(st.name.lower(), set()):
                    c.add("U009", x.line, ERROR, f"goto label '{lab}' not found in state {st.name}",
                          "jump to an existing label")


def rule_u011(c: Ctx):
    t = c.t
    for i, x in enumerate(t):
        if not x.is_("for") or t[i + 1].text != "(":
            continue
        hc = match_brace(t, i + 1, "(", ")")
        hdr = t[i + 2:hc]
        txt = " ".join(y.text for y in hdr)
        if ".Length" not in txt.replace(" . ", ".").replace(" .", ".") or not any(y.text == "++" for y in hdr):
            continue
        if any(y.text == "--" for y in hdr):
            continue
        k = hc + 1
        end = match_brace(t, k) if t[k].text == "{" else next(n for n in range(k, len(t)) if t[n].text == ";")
        body = t[k:end + 1]
        removes = any(y.is_("remove", "removeitem") and n > 0 and body[n - 1].text == "." for n, y in enumerate(body))
        fixes = any(y.text == "--" or y.text == "-=" for y in body)
        if removes and not fixes:
            c.add("U011", x.line, WARN, "array element removed inside a forward for-loop",
                  "iterate backwards (i = Arr.Length - 1; i >= 0; i--) or decrement i after Remove")


def rule_u012(c: Ctx, chain: dict):
    pf = c.pf
    if pf.class_name.lower() != c.path.stem.lower():
        c.add("U012", 1, ERROR, f"class {pf.class_name} lives in {c.path.name}",
              f"rename the file to {pf.class_name}.uc")
    want = chain.get(pf.class_name)
    if want and pf.parent.lower() != want.lower():
        c.add("U012", 1, ERROR, f"{pf.class_name} extends {pf.parent}, contract says {want}",
              f"extends {want}")
    bad = FORBIDDEN_PARENTS.get(pf.class_name)
    if bad and pf.parent.lower() == bad.lower():
        c.add("U012", 1, ERROR, f"{pf.class_name} must never extend {bad} (W1)", "extends AIController")


def rule_u013(c: Ctx, dropped: dict):
    for x in c.t:
        key = x.text.strip("'").lower() if x.kind in (IDENT, NAME) else None
        if key in dropped:
            c.add("U013", x.line, WARN, f"dropped legacy symbol {x.text} ({dropped[key]})",
                  "do not port or reference it; see kit/decisions.md D5")


UC_KEYWORDS = {"if", "for", "while", "foreach", "switch", "return", "until", "do", "new", "assert", "goto",
               "super", "global", "self", "class", "default", "static", "const", "vect", "rot", "arraycount",
               "sizeof", "enumcount", "nameof", "local", "case", "stop", "break", "continue", "else", "function",
               "event", "delegate", "state", "native", "var", "config", "globalconfig", "hidecategories",
               "dependson", "within", "implements", "classgroup", "showcategories", "autoexpandcategories",
               # dynamic-array intrinsics
               "additem", "removeitem", "remove", "insert", "insertitem", "add", "find", "empty", "sort"}


def rule_u010(c: Ctx, sdk_names: set[str] | None):
    """Unknown function call: not in this file, the mod's symbols/contracts, or the SDK index (WARN).
    Calls only; member-variable access is not checked yet. No-op until sdk_symbols.json exists."""
    if not sdk_names:
        return
    t = c.t
    own = {d.name.lower() for d in c.pf.decls} | c.known["functions"] | c.known["classes"] | c.known["states"]
    header_end = next((d.tok_end for d in c.pf.decls if d.kind == "class"), -1)
    for i, x in enumerate(t):
        if i <= header_end:
            continue
        if x.kind != IDENT or i + 1 >= len(t) or t[i + 1].text != "(":
            continue
        low = x.low
        if low in UC_KEYWORDS or low in own or low in sdk_names or low in BUILTIN_TYPES:
            continue
        if i > 0 and t[i - 1].kind == IDENT and t[i - 1].low in ("function", "event", "delegate", "state"):
            continue
        c.add("U010", x.line, WARN, f"`{x.text}(` is not a known SDK or mod function",
              "check the name with `context_slicer.py sdk Class.Member`; do not invent SDK calls")


def rule_u014(c: Ctx):
    """Extension (not in the M0 spec): decompiler artifacts copied from the legacy corpus."""
    import re
    for i, x in enumerate(c.t):
        if x.kind == IDENT and re.fullmatch(r"J0x[0-9A-Fa-f]+", x.text) and i + 1 < len(c.t) and c.t[i + 1].text == ":":
            c.add("U014", x.line, WARN, f"decompiler label {x.text}: + goto loop", "rewrite as a for/while loop")
    for line, text in c.pf.comments:
        if re.match(r"//\s*End:0x", text):
            c.add("U014", line, WARN, "decompiler comment", "delete `// End:0x..` comments")


def known_names(pf: ParsedFile) -> dict:
    """States / functions / labels / classes from symbols.json + contracts.json + this file."""
    states, funcs, classes, labels = set(), set(), set(BUILTIN_TYPES), {}
    sources = []
    for p in (GENERATED_DIR / "symbols.json", KIT_DIR / "contracts" / "contracts.json"):
        if p.is_file():
            sources += load_json(p).get("symbols", [])
    seed = load_json(KIT_DIR / "contracts" / "sdk_seed.json", default={})
    states |= {s.lower() for s in seed.get("states", [])}
    funcs |= {s.lower() for s in seed.get("functions", [])}
    for d in pf.decls:
        sources.append({"kind": d.kind, "name": d.name, "state": d.state, "parent": d.parent, "class": pf.class_name})
    parent_of = {}
    for s in sources:
        k, n = s["kind"], s["name"].lower()
        if k == "state":
            states.add(n)
            if s.get("parent"):
                parent_of[n] = s["parent"].lower()
        elif k in ("function", "event"):
            funcs.add(n)
        elif k == "class":
            classes.add(n)
        elif k == "label":
            labels.setdefault((s.get("state") or "").lower(), set()).add(n)
    for st in list(states):  # labels are inherited through `state X extends Y`
        p, seen = parent_of.get(st), set()
        while p and p not in seen:
            seen.add(p)
            labels.setdefault(st, set()).update(labels.get(p, set()))
            p = parent_of.get(p)
    labels.setdefault("*", set()).update(l.lower() for l in seed.get("labels", []))
    return {"states": states, "functions": funcs, "classes": classes, "labels": labels}


_SDK_CACHE: dict = {}


def _sdk_names() -> set[str] | None:
    p = GENERATED_DIR / "sdk_symbols.json"
    if not p.is_file():
        return None
    key = (str(p), p.stat().st_mtime)
    if key not in _SDK_CACHE:
        from sdk_index import all_member_names
        data = load_json(p)
        names = all_member_names(data) | {k.lower() for k in data["classes"]}
        _SDK_CACHE.clear()
        _SDK_CACHE[key] = names
    return _SDK_CACHE[key]


def validate(path: Path, chain: dict | None = None, dropped: dict | None = None) -> list[dict]:
    try:
        pf = parse_file(read_text(path))
    except LexError as e:
        return [{"rule": "U000", "file": path.name, "line": 0, "msg": f"cannot tokenize: {e}",
                 "fix_hint": "fix the syntax error first", "severity": ERROR}]
    c = Ctx(path, pf, known_names(pf))
    for rule in (rule_u001_u002, rule_u003_u004_u005, rule_u006, rule_u007, rule_u008, rule_u009, rule_u011, rule_u014):
        rule(c)
    rule_u010(c, _sdk_names())
    contracts = load_json(KIT_DIR / "contracts" / "class_chain.json", default={})
    rule_u012(c, chain if chain is not None else contracts.get("parents", {}))
    rule_u013(c, dropped if dropped is not None else load_json(KIT_DIR / "contracts" / "dropped_symbols.json", default={}))
    return sorted(c.out, key=lambda f: (f["line"], f["rule"]))


def corpus_selftest(ws) -> int:
    names = CORE_FILES + list(ws.get("aux_legacy_files", []))
    rows, errors = [], 0
    for n in names:
        found = validate(Path(ws["legacy_dir"]) / n)
        e = [f for f in found if f["severity"] == ERROR]
        errors += len(e)
        by_rule = {}
        for f in found:
            by_rule[f["rule"]] = by_rule.get(f["rule"], 0) + 1
        rows.append(f"| {n} | {len(e)} | {', '.join(f'{k}x{v}' for k, v in sorted(by_rule.items())) or '-'} |")
        for f in e:
            print(json.dumps(f))
    rep = ["# Validator corpus self-test", "", f"Legacy files: {len(names)}. ERRORs: **{errors}**.", "",
           "| File | ERRORs | Findings by rule |", "|---|---|---|"] + rows
    REPORTS_DIR.mkdir(exist_ok=True)
    (REPORTS_DIR / "validator_selftest.md").write_text("\n".join(rep) + "\n", encoding="utf-8")
    print(f"corpus-selftest: {errors} ERRORs across {len(names)} legacy files -> validator_selftest.md")
    return 1 if errors else 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="*")
    ap.add_argument("--corpus-selftest", action="store_true")
    ap.add_argument("--format", choices=("jsonl", "text"), default="jsonl")
    a = ap.parse_args()
    if a.corpus_selftest:
        return corpus_selftest(load_workspace())
    worst = 0
    for f in expand_globs(a.files):
        for x in validate(Path(f)):
            worst = max(worst, x["severity"] == ERROR)
            if a.format == "text":
                print(f"{x['file']}({x['line']}) {x['severity']} {x['rule']}: {x['msg']} -- {x['fix_hint']}")
            else:
                print(json.dumps(x))
    return 1 if worst else 0


if __name__ == "__main__":
    run_main(main)
