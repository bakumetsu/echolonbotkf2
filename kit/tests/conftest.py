import sys
from pathlib import Path

import pytest

TOOLS = Path(__file__).resolve().parent.parent / "tools"
sys.path.insert(0, str(TOOLS))

from common import CORE_FILES, load_workspace  # noqa: E402


@pytest.fixture(scope="session")
def ws():
    return load_workspace()


@pytest.fixture(scope="session")
def legacy(ws):
    """Skip corpus tests on machines without the legacy files (e.g. CI)."""
    missing = [f for f in CORE_FILES if not (Path(ws["legacy_dir"]) / f).is_file()]
    if missing or not Path(ws["doc_path"]).is_file():
        pytest.skip("legacy corpus / architecture doc not present (set legacy_dir in workspace.local.json)")
    return ws
