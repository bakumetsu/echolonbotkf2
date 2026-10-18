"""M0b tools: auditor, compile loop, SDK index, log checker, contracts/skeleton, splice, runner, docgen."""
import json
from pathlib import Path

import pytest

import agent_runner as ar
import ast_validator as av
import boundary_auditor as ba
import compile_loop as cl
import docgen
import log_checker as lc
import sdk_index
import skeleton_gen
from splice import SpliceError, extract_code, splice

FIX = Path(__file__).parent / "fixtures"
LOGS = FIX / "logs"


@pytest.fixture(scope="module")
def skel(tmp_path_factory):
    d = tmp_path_factory.mktemp("skel")
    skeleton_gen.generate(d)
    return d


# ---------------------------------------------------------------- contracts / skeleton
def test_skeleton_covers_all_classes_and_validates(skel):
    files = sorted(p.name for p in skel.glob("*.uc"))
    assert len(files) == 9 and "EcholonMut.uc" in files
    for f in skel.glob("*.uc"):
        assert f.read_bytes().count(b"\r\n") > 10, f  # CRLF like the SDK
        errs = [x for x in av.validate(f) if x["severity"] == av.ERROR]
        assert errs == [], (f.name, errs[:3])
        assert ba.audit(f) == [], f.name


def test_skeleton_refuses_overwrite(skel):
    with pytest.raises(Exception, match="never overwrite"):
        skeleton_gen.generate(skel, "EcholonMut")


def test_contracts_drop_d5_symbols_and_rename():
    c = json.loads((ar.KIT_DIR / "contracts" / "contracts.json").read_text())
    names = {f["name"].lower() for cls in c["classes"].values() for f in cls["functions"]}
    assert "rebuildhierarchy" not in names and "getactiveboss" not in names
    assert c["classes"]["EcholonMut"]["header"].count("config(EcholonBot)") == 1
    assert all(not cls["parent"].startswith("KF2Bot") for cls in c["classes"].values())


# ---------------------------------------------------------------- splice
def _copy(skel, tmp_path, name="EcholonMut.uc"):
    p = tmp_path / name
    p.write_bytes((skel / name).read_bytes())
    return p


def test_splice_function_keeps_crlf_and_drops_marker(skel, tmp_path):
    p = _copy(skel, tmp_path)
    reply = "<think>x</think>\n```unrealscript\nfunction int DetermineGroupCount(int BotCount)\n{\n    return BotCount / 4;\n}\n```"
    new, diff = splice(p, "EcholonMut.DetermineGroupCount", extract_code(reply))
    assert "return BotCount / 4;" in new and "\r\n" in new
    assert "-// @STUB(M4) @SYS-MUT-PLATOON legacy:KF2BotsMut.DetermineGroupCount" in diff


def test_splice_rejects_signature_change_and_extra_code(skel, tmp_path):
    p = _copy(skel, tmp_path)
    with pytest.raises(SpliceError, match="signature changed"):
        splice(p, "EcholonMut.DetermineGroupCount", "function int DetermineGroupCount(float BotCount)\n{\n}")
    with pytest.raises(SpliceError, match="exactly one function"):
        splice(p, "EcholonMut.DetermineGroupCount",
               "function int DetermineGroupCount(int BotCount)\n{\n}\nfunction Extra()\n{\n}")
    with pytest.raises(SpliceError, match="exactly one"):
        extract_code("```unrealscript\na\n```\n```unrealscript\nb\n```")


def test_splice_state_label_code_and_in_state_function(skel, tmp_path):
    p = _copy(skel, tmp_path, "EcholonBot.uc")
    states = [s for s in json.loads((ar.KIT_DIR / "contracts" / "contracts.json").read_text())
              ["classes"]["EcholonBot"]["states"] if s["labels"] == ["Begin"]]
    st = states[0]["name"]
    new, _ = splice(p, f"EcholonBot.{st}", "Begin:\n    Sleep(0.5);\n    Goto('Begin');")
    p.write_bytes(new.encode())
    assert "Sleep(0.5);" in new
    new2, _ = splice(p, f"EcholonBot.{st}", f"state {st}\n{{\nBegin:\n    Sleep(1.0);\n    Stop;\n}}")
    assert "Sleep(1.0);" in new2 and "Sleep(0.5);" not in new2
    new3, _ = splice(p, "EcholonBot.Roaming.BeginState",
                     "event BeginState(name PreviousStateName)\n{\n    SetTimer(1.0, false);\n}")
    assert "    event BeginState(name PreviousStateName)" in new3  # re-indented inside the state


# ---------------------------------------------------------------- auditor
def test_auditor_flags_foreign_writer_and_passes_owner(tmp_path):
    bad = tmp_path / "EcholonBot.uc"
    bad.write_text("class EcholonBot extends EcholonBotLogic;\n\nfunction Oops()\n{\n    FollowStatus = 3;\n}\n")
    f = ba.audit(bad)
    assert [x["rule"] for x in f] == ["B001"] and "FollowStatus" in f[0]["msg"]
    ok = tmp_path / "EcholonFollowNavBase.uc"
    ok.write_text("class EcholonFollowNavBase extends AIController;\n\nfunction FollowSetStatus(int S)\n{\n"
                  "    FollowStatus = S;\n}\n")
    assert ba.audit(ok) == []


# ---------------------------------------------------------------- compile loop
def test_parse_log_success_and_error(ws):
    ok = cl.compile_once(ws, LOGS / "compile_success_real.log")
    assert ok.ok and ok.errors == []
    bad = cl.compile_once(ws, LOGS / "compile_error_synthetic.log")
    assert not bad.ok and bad.errors[0]["line"] == 103 and "missing expression" in bad.errors[0]["msg"]


def test_fix_loop_escalates_after_three(ws, skel, tmp_path):
    w = dict(ws, package_src_dir=str(skel))
    calls = []
    res = cl.run_loop(w, lambda req: calls.append(req) or "--- a\n+++ b\n", tmp_path, "EcholonMut.PostBeginPlay",
                      [LOGS / "compile_error_synthetic.log"])
    assert not res["ok"] and len(calls) == 3 and Path(res["escalation"]).is_file()
    req = calls[0]
    assert req["errors"][0]["symbol"] and ">" in req["errors"][0]["slice"]
    assert cl.estimate_tokens((tmp_path / "escalation.md").read_text()) <= cl.ESCALATION_TOKENS


def test_fix_loop_recovers(ws, skel, tmp_path):
    res = cl.run_loop(dict(ws, package_src_dir=str(skel)), lambda r: "diff", tmp_path, None,
                      [LOGS / "compile_error_synthetic.log", LOGS / "compile_success_real.log"])
    assert res["ok"] and res["attempts"] == 1


# ---------------------------------------------------------------- sdk index / log checker
def test_sdk_index_fixture(tmp_path):
    data = sdk_index.index_tree(FIX / "sdk")
    assert set(data["classes"]) == {"Actor", "KFThing"} and data["failed"] == []
    assert data["classes"]["Actor"]["out_params"] == {"AllActors": [1]}
    assert sdk_index.lookup(data, "KFThing", "SetTimer")[0] == "Actor"
    assert sdk_index.lookup(data, "KFThing", "Nope") is None
    assert {"settimer", "max_thing", "idle", "count"} <= sdk_index.all_member_names(data)


def test_log_checker_real_excerpt():
    res = lc.scan((LOGS / "runtime_excerpt_real.log").read_text(encoding="utf-8"), ["EcholonBot"])
    assert res["total"] > 0 and res["own"] == 0
    fake = "[1.0] ScriptWarning: Accessed None 'Squad'\n\tEcholonBot E_0\n\tFunction EcholonBot.EcholonMut:Timer:00A1\n"
    res = lc.scan(fake, ["EcholonBot"])
    assert res["own"] == 1 and res["own_top"][0]["var"] == "Squad"
    assert res["own_top"][0]["function"] == "EcholonBot.EcholonMut:Timer"


# ---------------------------------------------------------------- runner / docgen
def test_plan_is_deterministic_and_valid():
    a, b = ar.plan("M1"), ar.plan("M1")
    assert a == b and len(a["tasks"]) > 10
    assert all(t["id"].startswith("M1-") and t["signature"] for t in a["tasks"])


def test_models_config_valid():
    cfg = ar.load_models()
    roles = {m["role"] for m in cfg["models"] if m["backend"] != "mock"}
    assert {"coder", "debugger", "doc"} <= roles


def test_runner_mock_end_to_end(legacy, skel, tmp_path):
    src = tmp_path / "src"
    src.mkdir()
    (src / "EcholonMut.uc").write_bytes((skel / "EcholonMut.uc").read_bytes())
    task = next(t for t in ar.plan("M1")["tasks"] if t["target"] == "EcholonMut.PostBeginPlay")
    w = dict(legacy, package_src_dir=str(src))
    mock = ar.MockBackend({"id": "mock", "backend": "mock"})
    res = ar.run_task(w, task, mock, mock, tmp_path / "run", [LOGS / "compile_success_real.log"])
    assert res["status"] == "done", res
    assert res["prompt_tokens"]["total"] <= legacy["budgets"]["hard_fail"]
    assert "// mock body" in (src / "EcholonMut.uc").read_text()
    # a failing compile restores the file byte for byte
    task2 = next(t for t in ar.plan("M1")["tasks"] if t["target"] == "EcholonMut.MatchStarting")
    before = (src / "EcholonMut.uc").read_bytes()
    res2 = ar.run_task(w, task2, mock, mock, tmp_path / "run", [LOGS / "compile_error_synthetic.log"])
    assert res2["status"] == "escalated" and (src / "EcholonMut.uc").read_bytes() == before


def test_runner_control_reply_escalates(legacy, skel, tmp_path):
    (tmp_path / "EcholonMut.uc").write_bytes((skel / "EcholonMut.uc").read_bytes())
    reply = tmp_path / "r.md"
    reply.write_text('{"control": "contract_conflict", "reason": "needs a var"}')
    task = ar.plan("M1")["tasks"][0]
    res = ar.run_task(dict(legacy, package_src_dir=str(tmp_path)), task,
                      ar.MockBackend({}, reply), None, tmp_path / "run")
    assert res["status"] == "escalated" and res["control"]["control"] == "contract_conflict"


def test_docgen_up_to_date():
    text = docgen.render(json.loads((ar.KIT_DIR / "contracts" / "contracts.json").read_text()),
                         json.loads((ar.KIT_DIR / "contracts" / "single_writer.json").read_text()))
    assert docgen.OUT.read_text(encoding="utf-8") == text, "run kit/tools/docgen.py"
    assert '<a id="EcholonMut.PostBeginPlay"></a>' in text
