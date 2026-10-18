import re
from pathlib import Path

from common import load_workspace

FIX = Path(__file__).parent / "fixtures" / "logs"


def test_summary_regex_matches_real_compile_log():
    ws = load_workspace()
    text = (FIX / "compile_success_real.log").read_text()
    m = re.search(ws["compile"]["summary_regex"], text)
    assert m and m["result"] == "Success" and m["errors"] == "0"
    assert ws["compile"]["nothing_to_do"] in text


def test_error_regex_on_ue3_style_line():
    ws = load_workspace()
    line = r"[0012.30] Error: C:\Users\X\Documents\My Games\KillingFloor2\KFGame\Src\EcholonBot\Classes\EcholonMut.uc(25) : Error, Bad or missing expression in 'If'"
    m = re.search(ws["compile"]["error_regex"], line)
    assert m and m["line"] == "25" and m["sev"] == "Error" and m["file"].endswith("EcholonMut.uc")


def test_runtime_log_shape():
    text = (FIX / "runtime_excerpt_real.log").read_text()
    assert re.search(r"ScriptWarning: Accessed None '\w+'\n\t\S+ \S+\n\tFunction \w+\.\w+:\w+:[0-9A-F]+", text)
    assert "Script call stack:" in text


def test_backend_roles_point_at_config_models():
    ws = load_workspace()
    cfg = (Path(__file__).resolve().parent.parent / "docs" / "llama-swap.config.yaml").read_text()
    for model in set(ws["backend"]["roles"].values()):
        assert f'"{model}":' in cfg
