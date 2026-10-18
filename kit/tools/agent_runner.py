"""G6 / D11: deterministic task runner. Python routes; local models write ONE symbol at a time.

  python kit/tools/agent_runner.py plan M1                  # tasks/M1.json from contract stubs
  python kit/tools/agent_runner.py run M1 [--task M1-003] [--limit 5]
  python kit/tools/agent_runner.py run M1 --mock-backend --fake-log ok.log --src DIR   # dry run
  python kit/tools/agent_runner.py status

Pipeline per task: prompt (Bible core + topics + doc slice + contract + task, D4 budget, hard
fail at 7k) -> coder -> splice -> validator -> auditor (one coder retry with findings) ->
compile -> debugger fixes x3 -> escalation.md. A failed task restores the file exactly as it
was. Everything a model saw and said is kept in runs/<timestamp>/<task>/.
"""
from __future__ import annotations

import argparse
import json
import re
import time
from datetime import datetime
from pathlib import Path

import jsonschema

from ast_validator import validate
from boundary_auditor import audit
from common import KIT_DIR, KitError, estimate_tokens, load_json, load_workspace, run_main, write_json
from compile_loop import run_loop, unified_diff
from context_slicer import NotFound, OverBudget, slice_legacy, slice_sys
from splice import SpliceError, extract_code, splice, strip_think

TASKS_DIR = KIT_DIR / "tasks"
RUNS_DIR = KIT_DIR / "runs"
DEFAULT_PARTS = [3, 4, 5, 6]
RETRIES = 3

SYSTEM = ("You write UnrealScript for Killing Floor 2 (Unreal Engine 3). Follow the Bible rules exactly. "
          "Reply with ONE ```unrealscript block containing only the requested symbol, with the exact signature "
          "given. No other code, no other functions. If you cannot do it, reply with JSON "
          '{"control": "need_info" | "cannot" | "contract_conflict", "reason": "..."}.')


# ---------------------------------------------------------------- backends
class Backend:
    def __init__(self, cfg: dict):
        self.cfg = cfg

    def health(self) -> None:
        import httpx
        r = httpx.get(self.cfg["endpoint"].rstrip("/") + "/models", timeout=10)
        r.raise_for_status()

    def chat(self, messages: list[dict]) -> str:
        import httpx
        c, last = self.cfg, None
        for n in range(RETRIES):
            try:
                if c["backend"] == "ollama":
                    r = httpx.post(c["endpoint"].rstrip("/") + "/api/chat", timeout=c.get("timeout_s", 600), json={
                        "model": c["model_name"], "messages": messages, "stream": False, "keep_alive": 0,
                        "think": c.get("think", False),
                        "options": {"temperature": c["temperature"], "num_predict": c["max_tokens"]}})
                    r.raise_for_status()
                    return strip_think(r.json()["message"]["content"])
                r = httpx.post(c["endpoint"].rstrip("/") + "/chat/completions", timeout=c.get("timeout_s", 600), json={
                    "model": c["model_name"], "messages": messages, "temperature": c["temperature"],
                    "max_tokens": c["max_tokens"], "stream": False})
                r.raise_for_status()
                return strip_think(r.json()["choices"][0]["message"].get("content") or "")
            except (httpx.HTTPError, KeyError, ValueError) as e:  # model loading, swap in progress, bad json
                last = e
                time.sleep(2 * 2 ** n)
        raise KitError(f"{c['id']}: no answer after {RETRIES} tries: {last}")


class MockBackend(Backend):
    """Answers with the target's exact signature and an empty body (or a canned reply file)."""

    def __init__(self, cfg: dict, reply_file: Path | None = None):
        super().__init__(cfg)
        self.reply_file = reply_file
        self.calls: list[list[dict]] = []

    def health(self) -> None:
        return None

    def chat(self, messages: list[dict]) -> str:
        self.calls.append(messages)
        if self.reply_file:
            return self.reply_file.read_text(encoding="utf-8")
        m = re.search(r"^SIGNATURE: (.+)$", messages[-1]["content"], re.M)
        if not m:
            return '{"control": "cannot", "reason": "mock has no signature"}'
        return f"```unrealscript\n{m.group(1)}\n{{\n    // mock body\n}}\n```"


def load_models(path: Path = KIT_DIR / "models_config.json") -> dict:
    cfg = load_json(path)
    jsonschema.validate(cfg, load_json(KIT_DIR / "schemas" / "models_config.schema.json"))
    for m in cfg["models"]:
        if m["vram_gb"] > cfg["vram_budget_gb"]:
            raise KitError(f"{m['id']} needs {m['vram_gb']} GB > vram_budget_gb {cfg['vram_budget_gb']}")
    return cfg


def backend_for(role: str, cfg: dict, mock: bool, reply_file: Path | None = None) -> Backend:
    if mock:
        return MockBackend({"id": "mock", "backend": "mock"}, reply_file)
    for m in cfg["models"]:
        if m["role"] == role and m["backend"] != "mock":
            return Backend(m)
    raise KitError(f"no model with role {role} in models_config.json")


# ---------------------------------------------------------------- planning
def topics_for(name: str, state: str | None, signature: str) -> list[str]:
    t = ["sdk"]
    low = (name + " " + signature).lower()
    if state or "state" in low or "goto" in low:
        t.append("states")
    if "timer" in low:
        t.append("timers")
    if "array<" in low:
        t.append("arrays")
    if "string" in low:
        t.append("strings")
    return t


def plan(milestone: str) -> dict:
    contracts = load_json(KIT_DIR / "contracts" / "contracts.json")
    tasks = []
    for cname, c in contracts["classes"].items():
        for f in c["functions"]:
            if f["milestone"] != milestone:
                continue
            target = f"{cname}.{f['state']}.{f['name']}" if f["state"] else f"{cname}.{f['name']}"
            tasks.append({"target": target, "kind": f["kind"], "tags": [f["tag"]] if f["tag"] else [],
                          "legacy_ref": f["legacy_ref"], "signature": f["signature"],
                          "bible_topics": topics_for(f["name"], f["state"], f["signature"])})
        for s in c["states"]:
            if s["milestone"] == milestone and s["labels"]:
                tasks.append({"target": f"{cname}.{s['name']}", "kind": "state", "tags": [s["tag"]] if s["tag"] else [],
                              "legacy_ref": s["legacy_ref"], "signature": s["signature"],
                              "bible_topics": ["states", "sdk"], "notes": s.get("flag", "")})
    out = []
    for n, t in enumerate(tasks, start=1):
        t.update({"id": f"{milestone}-{n:03d}", "milestone": milestone, "parts": DEFAULT_PARTS, "status": "todo",
                  "acceptance": ["signature unchanged", "validator: 0 ERROR", "auditor: 0 B001", "compiles"]})
        t.setdefault("notes", "")
        jsonschema.validate({k: v for k, v in t.items() if k != "signature"},
                            load_json(KIT_DIR / "schemas" / "task.schema.json"))
        out.append(t)
    return {"milestone": milestone, "tasks": out}


# ---------------------------------------------------------------- prompts
def _read(p: Path) -> str:
    return p.read_text(encoding="utf-8").strip()


def build_prompt(ws: dict, task: dict, findings: list[dict] | None = None) -> tuple[list[dict], dict]:
    b = ws["budgets"]
    bible = _read(KIT_DIR / "bible" / "BIBLE_CORE.md")
    for t in task["bible_topics"]:
        bible += "\n\n" + _read(KIT_DIR / "bible" / "topics" / f"{t}.md")
    doc = []
    for tag in task["tags"]:
        for parts in (task["parts"], [3], []):  # shrink until it fits the doc budget
            try:
                doc.append(slice_sys(ws, tag, parts, b["doc_slice"]))
                break
            except OverBudget:
                continue
            except NotFound:
                break
    legacy = ""
    if task.get("legacy_ref"):
        try:
            legacy = _legacy_slice(ws, task["legacy_ref"], b["contract"])
        except (OverBudget, NotFound, KitError):
            legacy = "(legacy body over budget; work from the doc slice)"
    contract = (f"TARGET: {task['target']} ({task['kind']})\nSIGNATURE: {task['signature']}\n"
                f"Legacy behaviour reference (do NOT copy its style; N13):\n{legacy}")
    body = f"TASK {task['id']}: implement {task['target']}.\n{task.get('notes', '')}\nAcceptance: " + \
           "; ".join(task["acceptance"])
    if findings:
        body += "\nYour previous attempt failed these checks; fix them:\n" + "\n".join(
            f"- {f['rule']} line {f['line']}: {f['msg']} ({f.get('fix_hint', '')})" for f in findings[:8])
    sizes = {"bible": estimate_tokens(bible), "doc": estimate_tokens("\n".join(doc)),
             "contract": estimate_tokens(contract), "task": estimate_tokens(body)}
    total = sum(sizes.values()) + estimate_tokens(SYSTEM)
    if total > b["hard_fail"]:
        raise KitError(f"{task['id']}: prompt ~{total} tokens > hard_fail {b['hard_fail']} ({sizes})")
    user = "\n\n".join(["# BIBLE", bible, "# DOC SLICE", "\n\n".join(doc) or "(none)", "# CONTRACT", contract,
                        "# TASK", body])
    sizes["total"] = total
    return [{"role": "system", "content": SYSTEM}, {"role": "user", "content": user}], sizes


def _legacy_slice(ws: dict, ref: str, max_tokens: int) -> str:
    from context_slicer import find_symbol
    syms = load_json(KIT_DIR / "generated" / "symbols.json")["symbols"]
    s = find_symbol(syms, ref)
    end = s["end"]
    while end > s["line"]:  # long legacy bodies: keep the head that fits, say it was cut
        try:
            text = slice_legacy(ws, s["file"], f"{s['line']}:{end}", max_tokens)
            return text if end == s["end"] else text + f"\n... (legacy body cut at line {end} of {s['end']} to fit budget)"
        except OverBudget:
            end = s["line"] + int((end - s["line"]) * 0.75)
    raise OverBudget(ref)


# ---------------------------------------------------------------- running
def _control(reply: str) -> dict | None:
    m = re.search(r'\{\s*"control"\s*:.*?\}', strip_think(reply), re.S)
    if m and "```unrealscript" not in reply:
        try:
            return json.loads(m.group(0))
        except ValueError:
            return None
    return None


def run_task(ws: dict, task: dict, coder: Backend, debugger: Backend, run_dir: Path,
             fake_logs: list[Path] | None = None) -> dict:
    d = run_dir / task["id"]
    d.mkdir(parents=True, exist_ok=True)
    src = Path(ws["package_src_dir"]) / f"{task['target'].split('.')[0]}.uc"
    if not src.is_file():
        raise KitError(f"{src} missing; run skeleton_gen.py first")
    original = src.read_bytes()
    findings: list[dict] = []
    result = {"id": task["id"], "target": task["target"]}
    for attempt in (1, 2):
        messages, sizes = build_prompt(ws, task, findings)
        (d / f"prompt{attempt}.md").write_text(messages[1]["content"], encoding="utf-8")
        reply = coder.chat(messages)
        (d / f"reply{attempt}.md").write_text(reply, encoding="utf-8")
        result["prompt_tokens"] = sizes
        ctl = _control(reply)
        if ctl:
            src.write_bytes(original)
            return {**result, "status": "escalated", "control": ctl}
        try:
            new_text, diff = splice(src, task["target"], extract_code(reply))
        except SpliceError as e:
            findings = [{"rule": "SPLICE", "line": 0, "msg": str(e), "fix_hint": "one block, exact signature"}]
            continue
        src.write_bytes(new_text.encode("utf-8"))
        findings = [f for f in validate(src) + audit(src) if f["severity"] == "ERROR"]
        (d / "diff.patch").write_text(diff, encoding="utf-8")
        if not findings:
            break
        src.write_bytes(original)
    if findings:
        write_json(d / "findings.json", findings)
        return {**result, "status": "failed", "findings": findings}

    def fixer(req: dict) -> str | None:
        target = req.get("target") or task["target"]
        sub = dict(task, target=target)
        msgs, _ = build_prompt(ws, sub)
        e = req["errors"][0]
        msgs[1]["content"] += (f"\n\n# COMPILE ERROR (attempt {req['attempt']})\n{e['file']}({e['line']}): {e['msg']}\n"
                               f"```\n{e['slice']}\n```\nSignatures in scope:\n" + "\n".join(e["signatures"]))
        reply = debugger.chat(msgs)
        (d / f"debug{req['attempt']}.md").write_text(reply, encoding="utf-8")
        try:
            before = src.read_text(encoding="utf-8")
            new_text, diff = splice(src, target, extract_code(reply))
        except SpliceError:
            return None
        src.write_bytes(new_text.encode("utf-8"))
        return diff or unified_diff(before, before, src.name)

    loop = run_loop(ws, fixer, d, task["target"], fake_logs)
    write_json(d / "compile.json", loop)
    if not loop["ok"]:
        src.write_bytes(original)
        return {**result, "status": "escalated", "compile": loop}
    return {**result, "status": "done", "compile": loop}


def run(milestone: str, only: str | None, limit: int | None, mock: bool, reply_file: Path | None,
        fake_logs: list[Path] | None, src_dir: Path | None) -> int:
    ws = load_workspace()
    if src_dir:
        ws["package_src_dir"] = str(src_dir)
    tpath = TASKS_DIR / f"{milestone}.json"
    if not tpath.is_file():
        raise KitError(f"{tpath} missing; run `agent_runner.py plan {milestone}` first")
    tasks = load_json(tpath)
    cfg = load_models()
    coder = backend_for("coder", cfg, mock, reply_file)
    debugger = coder if mock else backend_for("debugger", cfg, mock)
    coder.health()
    run_dir = RUNS_DIR / datetime.now().strftime("%Y%m%d-%H%M%S")
    done = 0
    for t in tasks["tasks"]:
        if (only and t["id"] != only) or (not only and t["status"] == "done"):
            continue
        if limit is not None and done >= limit:
            break
        res = run_task(ws, t, coder, debugger, run_dir, fake_logs)
        t["status"] = res["status"]
        write_json(run_dir / t["id"] / "result.json", res)
        print(f"{t['id']} {t['target']}: {res['status']}")
        done += 1
        if not mock:
            write_json(tpath, tasks)
    print(f"agent_runner: {done} task(s); logs in {run_dir}")
    return 0 if all(t["status"] == "done" for t in tasks["tasks"] if (not only or t["id"] == only)) or mock else 1


def status() -> int:
    ledger = load_json(KIT_DIR / "ledger.json")
    for m, v in ledger["milestones"].items():
        line = f"{m:<4} {v['status']}"
        tp = TASKS_DIR / f"{m}.json"
        if tp.is_file():
            ts = load_json(tp)["tasks"]
            counts = {s: sum(1 for t in ts if t["status"] == s) for s in ("done", "todo", "failed", "escalated")}
            line += "  tasks " + " ".join(f"{k}={n}" for k, n in counts.items() if n)
        print(line)
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("plan")
    p.add_argument("milestone")
    p.add_argument("--force", action="store_true")
    r = sub.add_parser("run")
    r.add_argument("milestone")
    r.add_argument("--task")
    r.add_argument("--limit", type=int)
    r.add_argument("--mock-backend", action="store_true")
    r.add_argument("--mock-reply", type=Path)
    r.add_argument("--fake-log", type=Path, action="append", help="compile log(s) to use instead of KFEditor")
    r.add_argument("--src", type=Path, help="package source dir override (dry runs)")
    sub.add_parser("status")
    a = ap.parse_args()
    if a.cmd == "plan":
        out = TASKS_DIR / f"{a.milestone}.json"
        if out.is_file() and not a.force:
            raise KitError(f"{out} exists (it records task status); use --force to re-plan")
        data = plan(a.milestone)
        write_json(out, data)
        print(f"plan: {len(data['tasks'])} tasks -> {out.relative_to(KIT_DIR.parent)}")
        return 0
    if a.cmd == "run":
        return run(a.milestone, a.task, a.limit, a.mock_backend, a.mock_reply, a.fake_log, a.src)
    return status()


if __name__ == "__main__":
    run_main(main)
