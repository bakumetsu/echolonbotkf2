"""Check the local model backend (llama-swap / any OpenAI-compatible server).

  python kit/tools/backend_check.py            # list models, ping each one
  python kit/tools/backend_check.py --model coder

Prints one line per model: load+reply time and the reply. Exit 1 if the server is unreachable.
"""
from __future__ import annotations

import argparse
import time

import httpx

from common import KitError, load_workspace, run_main


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", help="only ping this model")
    ap.add_argument("--timeout", type=float, default=300.0)
    a = ap.parse_args()
    base = load_workspace()["backend"]["endpoint"].rstrip("/")
    try:
        models = httpx.get(f"{base}/models", timeout=10).json().get("data", [])
    except httpx.HTTPError as e:
        raise KitError(f"cannot reach {base} ({e.__class__.__name__}). Is llama-swap running? "
                       "See kit/docs/LLAMA_SWAP_SETUP.md step 6.")
    names = [m["id"] for m in models]
    print(f"backend {base}: models = {names or 'none'}")
    for name in [a.model] if a.model else names:
        t0 = time.time()
        try:
            r = httpx.post(f"{base}/chat/completions", timeout=a.timeout, json={
                "model": name, "max_tokens": 20, "temperature": 0,
                "messages": [{"role": "user", "content": "Reply with the single word: ready /no_think"}]})
            r.raise_for_status()
            text = r.json()["choices"][0]["message"]["content"].strip().replace("\n", " ")[:60]
            print(f"  {name}: OK in {time.time() - t0:.1f}s -> {text!r}")
        except (httpx.HTTPError, KeyError, ValueError) as e:
            print(f"  {name}: FAILED after {time.time() - t0:.1f}s ({e})")
    return 0


if __name__ == "__main__":
    run_main(main)
