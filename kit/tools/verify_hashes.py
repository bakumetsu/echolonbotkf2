"""G0: check the 5 legacy files against the 'Verified against' table in the architecture doc.

Usage: python kit/tools/verify_hashes.py
Exit 0 = all match, 1 = mismatch or missing file (prints which).
"""
from __future__ import annotations

import hashlib
import re
from pathlib import Path

from common import CORE_FILES, KitError, load_workspace, read_lines, run_main

ROW = re.compile(r"^\|\s*(?P<file>[\w.]+\.uc)\s*\|\s*(?P<lines>\d+)\s*\|\s*(?P<sha>[0-9a-f]{8})\s*\|")


def doc_header_table(doc_path: Path) -> dict[str, tuple[int, str]]:
    """Parse the first 40 lines of the doc only (the header table lives there)."""
    out = {}
    for line in read_lines(doc_path)[:40]:
        m = ROW.match(line)
        if m:
            out[m["file"]] = (int(m["lines"]), m["sha"])
    return out


def verify(ws: dict) -> list[str]:
    doc = Path(ws["doc_path"])
    if not doc.is_file():
        raise KitError(f"architecture doc not found: {doc}")
    expected = doc_header_table(doc)
    problems = []
    for name in CORE_FILES:
        if name not in expected:
            problems.append(f"{name}: not listed in the doc header table")
            continue
        path = Path(ws["legacy_dir"]) / name
        if not path.is_file():
            problems.append(f"{name}: missing at {path}")
            continue
        want_lines, want_sha = expected[name]
        sha = hashlib.sha256(path.read_bytes()).hexdigest()[:8]
        lines = len(read_lines(path))
        if sha != want_sha:
            problems.append(f"{name}: sha256 {sha} != doc {want_sha}")
        if lines != want_lines:
            problems.append(f"{name}: {lines} lines != doc {want_lines}")
    return problems


def main() -> int:
    problems = verify(load_workspace())
    if problems:
        print("HASH CHECK FAILED -- the legacy corpus does not match the doc:")
        for p in problems:
            print("  " + p)
        return 1
    print(f"verify_hashes: OK ({len(CORE_FILES)} files match the doc header)")
    return 0


if __name__ == "__main__":
    run_main(main)
