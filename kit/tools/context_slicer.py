"""G3: budgeted context slices for prompts. Never returns a whole file, the whole doc, or the
doc's A-Z index.

  python kit/tools/context_slicer.py sys @SYS-MUT-BOOT [--parts 3,4,5,6] [--max-tokens N]
  python kit/tools/context_slicer.py legacy Nav 1285:1337
  python kit/tools/context_slicer.py sym KF2Bot.HealOther.BeginState     (or Bot.PickNextMove)
  python kit/tools/context_slicer.py contract KF2BotBase
  python kit/tools/context_slicer.py sdk Controller.MoveToward

Exit codes: 0 ok, 1 error, 2 over budget (stderr says what to drop), 3 not found.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

from common import (ALIASES, CORE_FILES, GENERATED_DIR, KIT_DIR, KitError, estimate_tokens,
                    load_json, load_workspace, read_lines)

HEADING = re.compile(r"^(#{1,4}) ")
PART = re.compile(r"^#### (\d)\. ")
PRIMARY = re.compile(r"Primary file:\s*([\w.]+\.uc)")
BARE_CITE = re.compile(r"(?<![\w\]`])\[(\d+)(?:-(\d+))?\](?!\()")
ANY_CITE = re.compile(r"\[(Mut|Nav|Base|Logic|Bot):(\d+)(?:-(\d+))?\]")
DEFAULT_PARTS = "3,4,5,6"


class OverBudget(Exception):
    pass


class NotFound(Exception):
    pass


def _forbidden_range(lines: list[str]) -> tuple[int, int]:
    """0-based [start, end) of the A-Z index section (## 0.7 ... next ##)."""
    s = next(i for i, l in enumerate(lines) if l.startswith("## 0.7"))
    e = next(i for i in range(s + 1, len(lines)) if lines[i].startswith(("## ", "# ")))
    return s, e


def doc_sections(lines: list[str], tag: str) -> list[tuple[int, int]]:
    """All (start, end) 0-based ranges whose heading carries exactly `tag`."""
    pat = re.compile(re.escape(tag) + r"(?![\w-])")
    out = []
    for i, l in enumerate(lines):
        m = HEADING.match(l)
        if m and pat.search(l) and len(m.group(1)) <= 3:
            level = len(m.group(1))
            j = i + 1
            while j < len(lines):
                h = HEADING.match(lines[j])
                if h and len(h.group(1)) <= level:
                    break
                j += 1
            out.append((i, j))
    # an outer heading (e.g. '# PART 6 ... @SYS-P6-BOUNDARY') that contains other matches is dropped
    out = [r for r in out if not any(o != r and r[0] <= o[0] and o[1] <= r[1] for o in out)]
    # a 'PART n' umbrella heading only holds a contents table; drop it when real sections match
    real = [r for r in out if not re.match(r"^#{1,3} PART \d", lines[r[0]])]
    return real or out


def all_tags(lines: list[str]) -> list[str]:
    tags = []
    for l in lines:
        if HEADING.match(l) and len(HEADING.match(l).group(1)) <= 3:
            tags += [t for t in re.findall(r"@SYS-[A-Z0-9-]+", l) if t not in tags]
    return tags


def _file_lengths(ws) -> dict[str, int]:
    out = {}
    for f in CORE_FILES:
        p = Path(ws["legacy_dir"]) / f
        out[f] = len(read_lines(p)) if p.is_file() else 10 ** 9
    return out


def rewrite_citations(text: str, primary: str | None, lengths: dict[str, int]) -> tuple[str, list[str]]:
    bad = []

    def check(fname, a, b):
        if int(b or a) > lengths.get(fname, 10 ** 9):
            bad.append(f"{fname}:{a}{'-' + b if b else ''} is past the end of the file ({lengths[fname]} lines)")

    for m in ANY_CITE.finditer(text):
        check(ALIASES[m.group(1)], m.group(2), m.group(3))
    if primary:
        def sub(m):
            check(primary, m.group(1), m.group(2))
            return f"[{primary}:{m.group(1)}{'-' + m.group(2) if m.group(2) else ''}]"
        text = BARE_CITE.sub(sub, text)
    return text, bad


def slice_sys(ws, tag: str, parts: list[int] | None, max_tokens: int) -> str:
    lines = read_lines(Path(ws["doc_path"]))
    fs, fe = _forbidden_range(lines)
    secs = doc_sections(lines, tag)
    if not secs:
        raise NotFound(f"no heading carries {tag}")
    lengths = _file_lengths(ws)
    chunks: list[tuple[str, str]] = []  # (label, text), all sections
    for s, e in secs:
        sec: list[tuple[str, str]] = []
        if s < fe and e > fs:
            raise KitError("refused: that range overlaps the A-Z index (0.7); use symbols.json")
        body = lines[s:e]
        pm = PRIMARY.search(body[0])
        primary = pm.group(1) if pm else None
        title = body[0].lstrip("# ").split("   ")[0]
        sec.append(("header", f"{tag} | {title} | primary: {primary or 'n/a'}"))
        # split into parts; text before the first '#### N.' is the preamble
        cur_label, cur = "preamble", []
        for l in body[1:]:
            m = PART.match(l)
            if m:
                sec.append((cur_label, "\n".join(cur)))
                cur_label, cur = f"part {m.group(1)}", [l]
            else:
                cur.append(l)
        sec.append((cur_label, "\n".join(cur)))
        if parts is not None:
            sec = [c for c in sec if c[0] in ("header", "preamble") or
                      (c[0].startswith("part ") and int(c[0][5:]) in parts)]
        for label, text in sec:
            text, bad = rewrite_citations(text, primary, lengths)
            if bad:
                text += "\n[slicer] bad citations: " + "; ".join(bad)
            chunks.append((label, text))
    out = "\n".join(t for _, t in chunks if t.strip())
    n = estimate_tokens(out)
    if n > max_tokens:
        sizes = {}
        for label, t in chunks:
            if label.startswith("part "):
                sizes[label] = sizes.get(label, 0) + estimate_tokens(t)
        drop, over = [], n - max_tokens
        for label, size in sorted(sizes.items(), key=lambda x: -x[1]):
            if over <= 0:
                break
            drop.append(f"{label} (~{size} tok)")
            over -= size
        raise OverBudget(f"{tag}: ~{n} tokens > budget {max_tokens}. Drop these parts: {', '.join(drop)}")
    return out


def slice_legacy(ws, file: str, rng: str, max_tokens: int) -> str:
    fname = ALIASES.get(file, file)
    fname = fname if fname.lower().endswith(".uc") else fname + ".uc"
    path = Path(ws["legacy_dir"]) / fname
    if not path.is_file():
        raise NotFound(f"no legacy file {fname}")
    m = re.fullmatch(r"(\d+)[:\-](\d+)", rng)
    if not m:
        raise KitError("range must look like a:b")
    a, b = int(m.group(1)), int(m.group(2))
    lines = read_lines(path)
    if not (1 <= a <= b <= len(lines)):
        raise KitError(f"{fname} has {len(lines)} lines; {a}:{b} is out of range")
    out = f"// {fname}:{a}-{b}\n" + "\n".join(f"{i:>5} {lines[i - 1]}" for i in range(a, b + 1))
    if estimate_tokens(out) > max_tokens:
        raise OverBudget(f"{fname}:{a}-{b} is ~{estimate_tokens(out)} tokens > {max_tokens}; ask for a smaller range")
    return out


def _resolve_class(name: str) -> str:
    f = ALIASES.get(name, name)
    return f[:-3] if f.lower().endswith(".uc") else f


def find_symbol(symbols: list[dict], qual: str) -> dict:
    parts = qual.split(".")
    if len(parts) < 2:
        raise KitError("use Class.Name or Class.State.Name")
    cls = _resolve_class(parts[0]).lower()
    want_state = parts[1].lower() if len(parts) == 3 else None
    name = parts[-1].lower()
    hits = [s for s in symbols if s["class"].lower() == cls and s["name"].lower() == name
            and (s.get("state") or "").lower() == (want_state or "")]
    if not hits and want_state is None:  # Class.State
        hits = [s for s in symbols if s["class"].lower() == cls and s["name"].lower() == name]
    if not hits:
        raise NotFound(f"no symbol {qual} in symbols.json")
    pri = {"function": 0, "event": 0, "state": 1, "struct": 2, "enum": 2, "const": 3, "var": 3}
    return sorted(hits, key=lambda s: pri.get(s["kind"], 9))[0]


def slice_sym(ws, qual: str, max_tokens: int) -> str:
    s = find_symbol(load_json(GENERATED_DIR / "symbols.json")["symbols"], qual)
    return slice_legacy(ws, s["file"], f"{s['line']}:{s['end']}", max_tokens)


def slice_contract(ws, cls: str, max_tokens: int) -> str:
    cls = _resolve_class(cls)
    cpath = KIT_DIR / "contracts" / "contracts.json"
    if cpath.is_file():
        c = load_json(cpath)
        entry = next((v for k, v in c.get("classes", {}).items()
                      if cls.lower() in (k.lower(), v.get("legacy", "").lower())), None)
        if entry is None:
            raise NotFound(f"no class {cls} in contracts.json")
        lines = [f"// contract (contracts.json)", entry["header"]]
        lines += [f"const {k};" for k in entry["consts"]]
        lines += [e["text"] for e in entry["enums"]] + [st["text"] for st in entry["structs"]]
        lines += [v["text"] for v in entry["vars"] if v["names"]]
        lines += [f["signature"] + ";" for f in entry["functions"] if not f["state"]]
        for st in entry["states"]:
            inner = [f["signature"] + ";" for f in entry["functions"] if f["state"] == st["name"]]
            lines.append(st["signature"] + " { " + " ".join(inner + [l + ":" for l in st["labels"]]) + " }")
    else:
        syms = [s for s in load_json(GENERATED_DIR / "symbols.json")["symbols"] if s["class"].lower() == cls.lower()]
        if not syms:
            raise NotFound(f"no class {cls} in symbols.json")
        lines = [f"// contract {cls} (derived from legacy symbols.json; contracts.json not generated yet)"]
        for s in syms:
            if s["kind"] in ("var", "const", "struct", "enum"):
                lines.append(s["signature"] + ";")
        for s in syms:
            if s["kind"] in ("function", "event") and not s.get("state"):
                lines.append(s["signature"] + ";")
            elif s["kind"] == "state":
                lines.append(s["signature"] + " {...}")
    out = "\n".join(lines)
    if estimate_tokens(out) > max_tokens:
        raise OverBudget(f"contract {cls} is ~{estimate_tokens(out)} tokens > {max_tokens}; "
                         "slice by symbol with `sym` instead, or raise --max-tokens")
    return out


def slice_sdk(ws, symbol: str, max_tokens: int) -> str:
    p = GENERATED_DIR / "sdk_symbols.json"
    if not p.is_file():
        raise NotFound("sdk_symbols.json not built yet (sdk_index.py arrives in M0b)")
    data = load_json(p)["classes"]
    cls, _, member = symbol.partition(".")
    c = next((v for k, v in data.items() if k.lower() == cls.lower()), None)
    if c is None:
        raise NotFound(f"SDK class {cls} not indexed")
    if not member:
        out = f"class {cls} extends {c.get('parent')}  // {c.get('file')}"
    else:
        hit = {**c.get("functions", {}), **c.get("vars", {})}
        sig = next((v for k, v in hit.items() if k.lower() == member.lower()), None)
        if sig is None:
            raise NotFound(f"{symbol} not in the SDK index (inherited members: try the parent {c.get('parent')})")
        out = f"// SDK {cls} ({c.get('file')})\n{sig}"
    if estimate_tokens(out) > max_tokens:
        raise OverBudget("sdk result over budget")
    return out


def main(argv=None) -> int:
    ws = load_workspace()
    hard = int(ws["budgets"]["hard_fail"])
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("sys")
    p.add_argument("tag")
    p.add_argument("--parts", default=DEFAULT_PARTS, help="comma list of subsections 1-7, or 'all'")
    p = sub.add_parser("legacy")
    p.add_argument("file")
    p.add_argument("range")
    p = sub.add_parser("sym")
    p.add_argument("qual")
    p = sub.add_parser("contract")
    p.add_argument("cls")
    p = sub.add_parser("sdk")
    p.add_argument("symbol")
    for sp in sub.choices.values():
        sp.add_argument("--max-tokens", type=int, default=int(ws["budgets"]["doc_slice"]))
    a = ap.parse_args(argv)
    budget = min(a.max_tokens, hard)
    try:
        if a.cmd == "sys":
            parts = None if a.parts == "all" else [int(x) for x in a.parts.split(",") if x]
            out = slice_sys(ws, a.tag, parts, budget)
        elif a.cmd == "legacy":
            out = slice_legacy(ws, a.file, a.range, budget)
        elif a.cmd == "sym":
            out = slice_sym(ws, a.qual, budget)
        elif a.cmd == "contract":
            out = slice_contract(ws, a.cls, budget)
        else:
            out = slice_sdk(ws, a.symbol, budget)
    except OverBudget as e:
        print(f"OVER BUDGET: {e}", file=sys.stderr)
        return 2
    except NotFound as e:
        print(f"NOT FOUND: {e}", file=sys.stderr)
        return 3
    except KitError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    sys.stdout.write(out + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
