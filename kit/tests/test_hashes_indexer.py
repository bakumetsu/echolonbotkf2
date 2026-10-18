import json
import re

import symbol_indexer as si
import verify_hashes
from common import read_lines


def test_hashes_match_doc(legacy):
    assert verify_hashes.verify(legacy) == []


def test_hash_mismatch_fails_loudly(legacy, tmp_path):
    for f in si.CORE_FILES:
        (tmp_path / f).write_bytes((si.Path(legacy["legacy_dir"]) / f).read_bytes())
    (tmp_path / "KF2Bot.uc").write_bytes(b"// tampered\n")
    problems = verify_hashes.verify({**legacy, "legacy_dir": str(tmp_path)})
    assert any("KF2Bot.uc: sha256" in p for p in problems)


def _index(legacy):
    names = si.CORE_FILES + legacy["aux_legacy_files"]
    syms = [s for n in names for s in si.index_file(si.Path(legacy["legacy_dir"]) / n)]
    diffs, counts = si.reconcile(syms, si.doc_index(si.Path(legacy["doc_path"])))
    return syms, diffs, counts


def test_gate_reconciles_to_943(legacy):
    syms, diffs, counts = _index(legacy)
    total = sum(sum(c.values()) for c in counts.values())
    unexplained = [d for why, d in diffs if not why]
    n_src = sum(1 for why, _ in diffs if why == si.EXPLAINED_EDITABLE)
    n_doc = sum(1 for why, _ in diffs if why == si.EXPLAINED_MEMBER)
    assert unexplained == []
    assert total - n_src + n_doc == si.GATE_TOTAL == 943
    for f, want in si.SPEC_COUNTS.items():  # functions/events/states/consts match the doc exactly
        for k in ("function", "event", "state", "const"):
            assert counts[f].get(k, 0) == want[k], (f, k)


def test_section_ranges_match_doc_0_3(legacy):
    syms, _, _ = _index(legacy)
    lines = read_lines(legacy["doc_path"])
    cur, checked = None, 0
    for l in lines[58:300]:
        m = re.match(r"^### (\S+\.uc)", l)
        if m:
            cur = m.group(1)
            continue
        if cur and l.startswith("|"):
            for name, a, b in re.findall(r"(\w+) \[(\d+)-(\d+)\]", l):
                checked += 1
                assert any(s["file"] == cur and s["name"] == name and s["line"] == int(a) and s["end"] == int(b)
                           for s in syms), (cur, name, a, b)
    assert checked > 300


def test_every_symbol_has_owner_tag_or_is_data(legacy):
    syms, _, _ = _index(legacy)
    untagged = [s["name"] for s in syms if s["file"] in si.CORE_FILES and s["kind"] in ("function", "event", "state")
                and not s.get("tag")]
    assert untagged == []


def test_incremental_reindex(legacy, tmp_path, monkeypatch):
    out = tmp_path / "symbols.json"
    monkeypatch.setattr("sys.argv", ["x", "--out", str(out)])
    assert si.main() == 0
    full = json.loads(out.read_text())["symbols"]
    monkeypatch.setattr("sys.argv", ["x", "--out", str(out), "--file", "Bot"])
    assert si.main() == 0
    again = json.loads(out.read_text())["symbols"]
    key = lambda s: (s["file"], s["kind"], s["name"], s["line"])
    assert sorted(map(key, full)) == sorted(map(key, again))
