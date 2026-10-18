import re
from pathlib import Path

from common import estimate_tokens

BIBLE = Path(__file__).resolve().parent.parent / "bible"
TOPICS = ["states", "arrays", "iterators", "strings", "timers", "sdk"]


def test_core_budget():
    assert estimate_tokens((BIBLE / "BIBLE_CORE.md").read_text()) <= 1800


def test_topics_exist_and_fit():
    for t in TOPICS:
        assert estimate_tokens((BIBLE / "topics" / f"{t}.md").read_text()) <= 600, t


def test_every_workaround_has_status_and_citation():
    core = (BIBLE / "BIBLE_CORE.md").read_text()
    for w in ["W1", "W2", "W3", "W4", "W5"]:
        block = core.split(w + " ", 1)[1].split("\nW", 1)[0]
        assert "[" in block and "]" in block, f"{w} has no [status]"
        assert re.search(r"(doc |@SYS-|Mut:|Nav:|Base:|Logic:|Bot:|SDK)", block), f"{w} has no citation"


def test_no_unresolved_verify():
    files = [BIBLE / "BIBLE_CORE.md", *(BIBLE / "topics").glob("*.md")]
    for f in files:
        assert "[VERIFY]" not in f.read_text(), f
