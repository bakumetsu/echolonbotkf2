"""Shared helpers for the Echolon agent kit: workspace config, file I/O, token budget."""
from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

KIT_DIR = Path(__file__).resolve().parent.parent
REPO_DIR = KIT_DIR.parent
GENERATED_DIR = KIT_DIR / "generated"
REPORTS_DIR = KIT_DIR / "reports"

# Short aliases used by the architecture doc's citations ([Mut:12], [Nav:40], ...).
ALIASES = {
    "Mut": "KF2BotsMut.uc",
    "Nav": "KF2BotsFollowNavBase.uc",
    "Base": "KF2BotBase.uc",
    "Logic": "KF2BotLogic.uc",
    "Bot": "KF2Bot.uc",
}
FILE_TO_ALIAS = {v: k for k, v in ALIASES.items()}
CORE_FILES = list(ALIASES.values())


class KitError(Exception):
    """A loud, user-facing failure. Tools print it and exit non-zero."""


def _expand(value, env: dict):
    if isinstance(value, str):
        for _ in range(5):  # allow nested {placeholders}
            new = re.sub(r"\{(\w+)\}", lambda m: str(env.get(m.group(1), m.group(0))), value)
            if new == value:
                break
            value = new
        return value
    if isinstance(value, dict):
        return {k: _expand(v, env) for k, v in value.items()}
    if isinstance(value, list):
        return [_expand(v, env) for v in value]
    return value


def _merge(base: dict, over: dict) -> dict:
    out = dict(base)
    for k, v in over.items():
        if isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k] = _merge(out[k], v)
        else:
            out[k] = v
    return out


def load_workspace() -> dict:
    """workspace.json, overlaid by workspace.local.json (gitignored) or $ECHOLON_WORKSPACE."""
    ws = json.loads((KIT_DIR / "workspace.json").read_text(encoding="utf-8"))
    local = os.environ.get("ECHOLON_WORKSPACE") or str(KIT_DIR / "workspace.local.json")
    if Path(local).is_file():
        ws = _merge(ws, json.loads(Path(local).read_text(encoding="utf-8")))
    flat = {k: v for k, v in ws.items() if isinstance(v, str)}
    return _expand(ws, flat)


def legacy_path(ws: dict, name: str) -> Path:
    """Resolve 'Mut' / 'KF2BotsMut.uc' / 'KF2BotsMut' to a legacy file path."""
    fname = ALIASES.get(name, name)
    if not fname.lower().endswith(".uc"):
        fname += ".uc"
    p = Path(ws["legacy_dir"]) / fname
    if not p.is_file():
        raise KitError(f"legacy file not found: {p} (check legacy_dir in workspace.json)")
    return p


def read_lines(path: Path) -> list[str]:
    """Lines the way .NET ReadAllLines counts them (the doc's convention): CRLF, LF and CR
    all end a line, and a trailing terminator does not add an empty last line."""
    text = Path(path).read_bytes().decode("utf-8-sig", errors="replace")
    lines = re.split(r"\r\n|\n|\r", text)
    if lines and lines[-1] == "":
        lines.pop()
    return lines


def read_text(path: Path) -> str:
    """File text with line endings normalised to \\n (line numbers match read_lines)."""
    return "\n".join(read_lines(path)) + "\n"


def estimate_tokens(text: str) -> int:
    """D4 estimator: chars / 3.5, rounded up."""
    return int(-(-len(text) // 3.5))


def load_json(path: Path, default=None):
    p = Path(path)
    if not p.is_file():
        if default is not None:
            return default
        raise KitError(f"missing {p}; run the tool that generates it first")
    return json.loads(p.read_text(encoding="utf-8"))


def write_json(path: Path, data) -> None:
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text(json.dumps(data, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")


def run_main(fn) -> None:
    """Run a CLI entry point; KitError becomes a one-line message and exit code 1."""
    try:
        sys.exit(fn() or 0)
    except KitError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
