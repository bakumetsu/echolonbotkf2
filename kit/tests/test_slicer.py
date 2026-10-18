import pytest

import context_slicer as cs
from common import estimate_tokens, read_lines


def test_every_sys_tag_slices_within_budget(legacy):
    lines = read_lines(legacy["doc_path"])
    tags = cs.all_tags(lines)
    assert len(tags) >= 59
    for tag in tags:
        out = cs.slice_sys(legacy, tag, [3, 4, 5, 6], legacy["budgets"]["doc_slice"])
        assert out.startswith(tag)
        assert estimate_tokens(out) <= legacy["budgets"]["doc_slice"]


def test_p6_multi_match(legacy):
    out = cs.slice_sys(legacy, "@SYS-P6-BOUNDARY", None, 7000)
    assert out.count("@SYS-P6-BOUNDARY |") == 4


def test_exact_tag_match_only(legacy):
    with pytest.raises(cs.NotFound):
        cs.slice_sys(legacy, "@SYS-MUT", None, 2000)


def test_bare_citations_rewritten(legacy):
    out = cs.slice_sys(legacy, "@SYS-MUT-PERK", [5], 2000)
    assert "[KF2BotsMut.uc:2325]" in out


def test_over_budget_gives_drop_hint(legacy, capsys):
    rc = cs.main(["sys", "@SYS-BOT-COMBAT", "--parts", "all", "--max-tokens", "500"])
    assert rc == 2 and "Drop these parts" in capsys.readouterr().err


def test_hard_cap_cannot_be_raised(legacy, capsys):
    rc = cs.main(["legacy", "Base", "1:4615", "--max-tokens", "999999"])
    assert rc == 2


def test_az_index_refused(legacy):
    lines = read_lines(legacy["doc_path"])
    s, e = cs._forbidden_range(lines)
    assert lines[s].startswith("## 0.7") and e - s > 900


def test_legacy_and_sym(legacy):
    out = cs.slice_legacy(legacy, "Nav", "1285:1290", 2000)
    assert out.splitlines()[0] == "// KF2BotsFollowNavBase.uc:1285-1290" and len(out.splitlines()) == 7
    out = cs.slice_sym(legacy, "Mut.GetActiveBoss", 2000)
    assert "return none" in out


def test_contract_fallback(legacy):
    out = cs.slice_contract(legacy, "KF2BotLogic", 2000)
    assert "function" in out
