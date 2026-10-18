"""G5: compile the package with KFEditor and turn the first errors into a small fix request.

  python kit/tools/compile_loop.py                     # one real compile (Windows), writes fix_request.json
  python kit/tools/compile_loop.py --fake-log X.log    # parse a saved log instead (tests, dry runs)

Config lives in workspace.json "compile": args, log_path, output_u, error_regex, summary_regex,
timeout_s. Known legacy warnings go in contracts/warning_baseline.json and are ignored.
The fix loop itself (max 3 attempts, then escalation.md) is run_loop(), driven by agent_runner.
"""
from __future__ import annotations

import argparse
import difflib
import json
import re
import subprocess
import time
from dataclasses import dataclass, field
from pathlib import Path

import jsonschema

from common import KIT_DIR, KitError, estimate_tokens, load_json, load_workspace, read_lines, run_main, write_json
from uc_lexer import IDENT, tokenize
from uc_parser import parse_file

SLICE_RADIUS = 20
MAX_LOCATIONS = 3
MAX_LOOPS = 3
ESCALATION_TOKENS = 1500


@dataclass
class CompileResult:
    ok: bool
    summary: str
    errors: list[dict] = field(default_factory=list)
    warnings: list[dict] = field(default_factory=list)
    log_tail: str = ""
    seconds: float = 0.0


def parse_log(text: str, cfg: dict, baseline: set[str] | None = None) -> CompileResult:
    err_re = re.compile(cfg["error_regex"])
    sum_re = re.compile(cfg["summary_regex"])
    errors, warnings, loose = [], [], []
    for raw in text.splitlines():
        line = raw.rstrip("\r")
        m = err_re.search(line)
        if m:
            item = {"file": m["file"], "line": int(m["line"]), "sev": m["sev"], "msg": m["msg"].strip()}
            if item["sev"].lower() == "error":
                errors.append(item)
            elif f"{Path(item['file'].replace(chr(92), '/')).name}|{item['msg']}" not in (baseline or set()):
                warnings.append(item)
        elif re.search(r"\]\s*Error:|^Error:", line) and not m:
            loose.append(line.strip())
    s = None
    for s in sum_re.finditer(text):
        pass  # keep the last summary line
    if s is None:
        ok = not errors and not loose and cfg.get("nothing_to_do", "\0") in text
        summary = "no summary line found" + (" (nothing to recompile)" if ok else "")
    else:
        ok = s["result"] == "Success" and int(s["errors"]) == 0 and not errors
        summary = s.group(0)
    if not ok and not errors and loose:  # failure without a File(line) error: keep the raw lines
        errors = [{"file": "", "line": 0, "sev": "Error", "msg": l} for l in loose[:MAX_LOCATIONS]]
    tail = "\n".join(text.splitlines()[-40:])
    return CompileResult(ok, summary, errors, warnings, tail)


def compile_once(ws: dict, fake_log: Path | None = None) -> CompileResult:
    cfg = ws["compile"]
    base = load_json(KIT_DIR / "contracts" / "warning_baseline.json", default={"warnings": []})
    baseline = set(base.get("warnings", []))
    if fake_log is not None:
        return parse_log(Path(fake_log).read_text(encoding="utf-8", errors="replace"), cfg, baseline)
    exe = Path(ws["kfeditor_path"])
    if not exe.is_file():
        raise KitError(f"KFEditor not found at {exe}; set kfeditor_path in workspace.json")
    out_u = Path(cfg["output_u"])
    if out_u.is_file():
        out_u.unlink()  # stale .u: force a real rebuild ("No scripts need recompiling" otherwise)
    t0 = time.time()
    try:
        subprocess.run([str(exe), *cfg["args"]], cwd=exe.parent, timeout=cfg["timeout_s"],
                       capture_output=True, check=False)
    except subprocess.TimeoutExpired:
        return CompileResult(False, f"timeout after {cfg['timeout_s']}s", [{"file": "", "line": 0, "sev": "Error",
                             "msg": "KFEditor did not finish (dialog open? raise timeout_s)"}])
    log = Path(cfg["log_path"])
    if not log.is_file():
        raise KitError(f"compile log not found at {log}")
    res = parse_log(log.read_text(encoding="utf-8", errors="replace"), cfg, baseline)
    res.seconds = time.time() - t0
    return res


def _resolve_source(ws: dict, file: str) -> Path | None:
    p = Path(file)
    if p.is_file():
        return p
    cand = Path(ws["package_src_dir"]) / Path(file.replace("\\", "/")).name
    return cand if cand.is_file() else None


def _symbol_index(src_dir: Path) -> dict[str, dict]:
    idx = {}
    for f in sorted(src_dir.glob("*.uc")):
        try:
            pf = parse_file("\n".join(read_lines(f)) + "\n")
        except Exception:  # a broken file must not stop the fix request
            continue
        for d in pf.decls:
            if d.kind in ("function", "event", "var", "const", "struct", "enum", "state"):
                idx.setdefault(d.name.lower(), {"sig": d.signature, "file": f.name, "line": d.line, "end": d.end,
                                                "qual": f"{pf.class_name}.{d.qual}"})
    return idx


def _enclosing(lines: list[str], line: int) -> str | None:
    """Innermost function/state around `line` (per file: names repeat across classes)."""
    try:
        pf = parse_file("\n".join(lines) + "\n")
    except Exception:
        return None
    hits = [d for d in pf.decls if d.kind in ("function", "event", "state", "defaultproperties")
            and d.line <= line <= d.end]
    return f"{pf.class_name}.{min(hits, key=lambda d: d.end - d.line).qual}" if hits else None


def build_fix_request(ws: dict, res: CompileResult, attempt: int, target: str | None = None) -> dict:
    seen, picked = set(), []
    for e in res.errors:
        key = (e["file"].lower(), e["line"])
        if key not in seen:
            seen.add(key)
            picked.append(e)
        if len(picked) == MAX_LOCATIONS:
            break
    src_dir = Path(ws["package_src_dir"])
    idx = _symbol_index(src_dir) if src_dir.is_dir() else {}
    out = []
    for e in picked:
        src = _resolve_source(ws, e["file"]) if e["file"] else None
        slice_txt, sigs, sym = "", [], None
        if src is not None:
            lines = read_lines(src)
            a, b = max(1, e["line"] - SLICE_RADIUS), min(len(lines), e["line"] + SLICE_RADIUS)
            slice_txt = "\n".join(f"{i:>5}{'>' if i == e['line'] else ' '} {lines[i - 1]}" for i in range(a, b + 1))
            names = {t.low for t in tokenize("\n".join(lines[a - 1:b])) if t.kind == IDENT}
            sigs = [v["sig"] for k, v in idx.items() if k in names][:15]
            sym = _enclosing(lines, e["line"])
        out.append({"file": e["file"], "line": e["line"], "msg": e["msg"], "symbol": sym,
                    "slice": slice_txt, "signatures": sigs})
    req = {"attempt": attempt, "summary": res.summary, "target": target, "errors": out or
           [{"file": "", "line": 0, "msg": res.summary, "symbol": None, "slice": res.log_tail, "signatures": []}]}
    jsonschema.validate(req, load_json(KIT_DIR / "schemas" / "fix_request.schema.json"))
    return req


def write_escalation(path: Path, req: dict, attempts: list[dict]) -> Path:
    """<=1.5k tokens: the error, its slice, and the last 2 attempt diffs."""
    e = req["errors"][0]
    parts = [f"# Escalation: {req.get('target') or e.get('symbol') or 'compile failure'}", "",
             f"Compile still failing after {len(attempts)} attempts. Summary: `{req['summary']}`", "",
             f"## First error\n`{e['file']}({e['line']})`: {e['msg']}", "", "```unrealscript", e["slice"], "```"]
    for n, att in enumerate(attempts[-2:], start=max(1, len(attempts) - 1)):
        parts += ["", f"## Attempt {n} diff", "```diff", att.get("diff", "(no diff)"), "```"]
    text = "\n".join(parts)
    while estimate_tokens(text) > ESCALATION_TOKENS and len(text) > 400:
        text = text[: int(len(text) * 0.85)] + "\n...(truncated to the 1.5k-token budget)\n```"
    path.write_text(text + "\n", encoding="utf-8")
    return path


def run_loop(ws: dict, fixer, out_dir: Path, target: str | None = None, fake_logs: list[Path] | None = None,
             max_loops: int = MAX_LOOPS) -> dict:
    """Compile; on failure call fixer(fix_request) -> diff text, recompile; escalate after max_loops fixes."""
    attempts = []
    out_dir.mkdir(parents=True, exist_ok=True)
    for n in range(max_loops + 1):
        fake = fake_logs[min(n, len(fake_logs) - 1)] if fake_logs else None
        res = compile_once(ws, fake)
        if res.ok:
            return {"ok": True, "attempts": len(attempts), "summary": res.summary, "warnings": res.warnings}
        req = build_fix_request(ws, res, n + 1, target)
        write_json(out_dir / "fix_request.json", req)
        if n == max_loops:
            esc = write_escalation(out_dir / "escalation.md", req, attempts)
            return {"ok": False, "attempts": len(attempts), "summary": res.summary, "escalation": str(esc)}
        diff = fixer(req) if fixer else None
        if not diff:
            return {"ok": False, "attempts": len(attempts), "summary": res.summary, "fix_request": str(out_dir / "fix_request.json")}
        attempts.append({"attempt": n + 1, "diff": diff})
    raise AssertionError("unreachable")


def unified_diff(old: str, new: str, name: str) -> str:
    return "".join(difflib.unified_diff(old.splitlines(True), new.splitlines(True), f"a/{name}", f"b/{name}", n=2))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--fake-log", type=Path, help="parse this log instead of running KFEditor")
    ap.add_argument("--out", type=Path, default=KIT_DIR / "runs" / "compile")
    a = ap.parse_args()
    ws = load_workspace()
    res = compile_once(ws, a.fake_log)
    print(f"compile: {'OK' if res.ok else 'FAILED'} - {res.summary} ({len(res.errors)} errors, "
          f"{len(res.warnings)} new warnings)")
    if not res.ok:
        req = build_fix_request(ws, res, 1)
        write_json(a.out / "fix_request.json", req)
        for e in req["errors"]:
            print(f"  {Path(e['file'].replace(chr(92), '/')).name}({e['line']}): {e['msg'][:120]}")
        print(f"  -> {a.out / 'fix_request.json'}")
    return 0 if res.ok else 1


if __name__ == "__main__":
    run_main(main)
