"""G6 / D3: replace ONE stub (function, event, state label code or defaultproperties) by symbol.

  python kit/tools/splice.py Classes/EcholonMut.uc EcholonMut.PostBeginPlay reply.md
  python kit/tools/splice.py Classes/EcholonBot.uc EcholonBot.Roaming.BeginState body.uc --dry-run

The model reply must contain exactly ONE ```unrealscript fenced block (D3). For a function the
block is the whole function; its name, return type and parameters must match the contract
(the target's current signature), so a model can't silently change an API. For a state target
(Class.State) the block is either the whole `state X {...}` (its label code is taken) or just
the label code. Prints a unified diff; the file keeps its own line endings.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

from common import KitError, read_lines, run_main
from compile_loop import unified_diff
from uc_lexer import LexError
from uc_parser import parse_file

FENCE = re.compile(r"```(?:unrealscript|uc|uscript)[^\n]*\n(.*?)```", re.S | re.I)
ANY_FENCE = re.compile(r"```[^\n]*\n(.*?)```", re.S)


class SpliceError(KitError):
    pass


def strip_think(text: str) -> str:
    return re.sub(r"<think>.*?</think>", "", text, flags=re.S | re.I).strip()


def extract_code(reply: str) -> str:
    reply = strip_think(reply)
    blocks = FENCE.findall(reply)
    if not blocks:
        blocks = ANY_FENCE.findall(reply)
    if len(blocks) != 1:
        raise SpliceError(f"expected exactly one ```unrealscript block, found {len(blocks)}")
    return blocks[0].strip("\n")


def _norm_sig(d) -> tuple:
    return (d.name.lower(), (d.return_type or "").lower().replace(" ", ""),
            tuple((p.type.lower().replace(" ", ""), p.name.lower(), tuple(sorted(p.mods))) for p in d.params))


def _find(pf, target: str):
    parts = target.split(".")
    if len(parts) < 2 or parts[0].lower() != pf.class_name.lower():
        raise SpliceError(f"target {target} is not in class {pf.class_name}")
    if len(parts) == 2:
        name, state = parts[1], None
        cands = [d for d in pf.decls if d.name.lower() == name.lower() and not d.state
                 and d.kind in ("function", "event", "state", "defaultproperties")]
    else:
        state, name = parts[1], parts[2]
        cands = [d for d in pf.decls if d.kind in ("function", "event") and d.name.lower() == name.lower()
                 and (d.state or "").lower() == state.lower()]
    if len(cands) != 1:
        raise SpliceError(f"{target}: {len(cands)} matching declarations")
    return cands[0]


def splice(path: Path, target: str, code: str, allow_signature_change: bool = False) -> tuple[str, str]:
    """Return (new_text, diff). Does not write."""
    raw = Path(path).read_bytes().decode("utf-8-sig")
    eol = "\r\n" if "\r\n" in raw else "\n"
    lines = read_lines(path)
    text = "\n".join(lines) + "\n"
    pf = parse_file(text)
    d = _find(pf, target)
    indent = re.match(r"\s*", lines[d.line - 1]).group(0)
    if d.kind in ("function", "event"):
        wrapper = f"class {pf.class_name} extends Object;\n{code}\n"
        try:
            new = parse_file(wrapper)
        except LexError as e:
            raise SpliceError(f"reply does not tokenize: {e}")
        funcs = [x for x in new.decls if x.kind in ("function", "event") and not x.state]
        if len(funcs) != 1 or len([x for x in new.decls if x.kind not in ("class",)]) != 1:
            raise SpliceError("reply must contain exactly one function and nothing else")
        if funcs[0].name.lower() != d.name.lower():
            raise SpliceError(f"reply defines {funcs[0].name}, target is {d.name}")
        if not allow_signature_change and _norm_sig(funcs[0]) != _norm_sig(d):
            raise SpliceError(f"signature changed: contract is `{d.signature}`, reply has `{funcs[0].signature}`")
        body = [indent + l if l.strip() else l for l in code.split("\n")] if indent else code.split("\n")
        first = d.line
        # keep the @STUB marker line out: it sits on the line above the declaration
        if first >= 2 and "@STUB(" in lines[first - 2]:
            first -= 1
        new_lines = lines[:first - 1] + body + lines[d.end:]
    elif d.kind == "state":
        if not d.label_code:
            raise SpliceError(f"state {d.name} has no label code to replace; splice its functions instead")
        label_text = code
        if re.match(r"\s*(auto\s+|simulated\s+)*state\b", code, re.I):
            sp = parse_file(f"class {pf.class_name} extends Object;\n{code}\n")
            st = next((x for x in sp.decls if x.kind == "state"), None)
            if st is None or not st.label_code:
                raise SpliceError("reply state has no label code")
            code_lines = code.split("\n")
            a = sp.tokens[st.label_code[0]].line - 1  # -1 for the wrapper's class line
            b = sp.tokens[st.label_code[1]].line - 1
            label_text = "\n".join(code_lines[a - 1:b - 1])
        a = pf.tokens[d.label_code[0]].line
        b = pf.tokens[d.label_code[1]].line  # the state's closing brace line
        new_lines = lines[:a - 1] + label_text.rstrip("\n").split("\n") + lines[b - 1:]
    else:  # defaultproperties
        new_lines = lines[:d.line - 1] + code.rstrip("\n").split("\n") + lines[d.end:]
    new_text = "\n".join(new_lines) + "\n"
    parse_file(new_text)  # the spliced file must still tokenize and parse
    return new_text.replace("\n", eol), unified_diff(text, new_text, Path(path).name)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("file", type=Path)
    ap.add_argument("target")
    ap.add_argument("reply", type=Path, help="model reply (markdown with one fenced block) or a .uc snippet")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--allow-signature-change", action="store_true")
    a = ap.parse_args()
    reply = a.reply.read_text(encoding="utf-8")
    code = extract_code(reply) if "```" in reply else reply
    new_text, diff = splice(a.file, a.target, code, a.allow_signature_change)
    sys.stdout.write(diff)
    if not a.dry_run:
        a.file.write_bytes(new_text.encode("utf-8"))
    return 0


if __name__ == "__main__":
    run_main(main)
