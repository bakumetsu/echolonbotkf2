import json
from pathlib import Path

import pytest

import ast_validator as av

NEG = Path(__file__).parent / "negative"


def rules(path):
    return {f["rule"] for f in av.validate(path)}


def test_corpus_selftest_zero_errors(legacy):
    for n in av.CORE_FILES + legacy["aux_legacy_files"]:
        errs = [f for f in av.validate(Path(legacy["legacy_dir"]) / n) if f["severity"] == av.ERROR]
        assert errs == [], (n, errs[:3])


@pytest.mark.parametrize("snippet", sorted(NEG.glob("U*.uc")), ids=lambda p: p.stem)
def test_negative_fires_exactly_its_rule(snippet):
    assert rules(snippet) == {snippet.stem}


def _check(tmp_path, body, cls="T"):
    p = tmp_path / f"{cls}.uc"
    p.write_text(f"class {cls} extends Actor;\n{body}\n")
    return [(f["rule"], f["severity"]) for f in av.validate(p)]


def test_u008_variants(tmp_path):
    assert ("U008", "ERROR") in _check(tmp_path, "function F() { local Actor A; if (A == null) {} }")
    assert ("U008", "ERROR") in _check(tmp_path, "var array<array<int> > X;")
    assert ("U008", "ERROR") in _check(tmp_path, "function F() { local int I; I = (int)2.5; }")
    assert ("U008", "WARN") in _check(tmp_path, "function int F(bool B) { return B ? 1 : 0; }")
    assert _check(tmp_path, "function F() { local bool B; if (B) F(); }") == []


def test_u009_labels_and_timers(tmp_path):
    body = "state S {\nBegin:\n Sleep(1);\n goto('Nope');\n}\nfunction F() { SetTimer(1, false, 'Missing'); GotoState('S', 'Begin'); }"
    found = _check(tmp_path, body)
    assert found.count(("U009", "ERROR")) == 2


def test_u012_kfaicontroller(tmp_path):
    p = tmp_path / "EcholonFollowNavBase.uc"
    p.write_text("class EcholonFollowNavBase extends KFAIController abstract;\n")
    msgs = [f["msg"] for f in av.validate(p) if f["rule"] == "U012"]
    assert any("never extend KFAIController" in m for m in msgs)


def test_jsonl_shape(tmp_path):
    f = av.validate(NEG / "U001.uc")[0]
    assert set(f) == {"rule", "file", "line", "msg", "fix_hint", "severity"}
    json.dumps(f)
