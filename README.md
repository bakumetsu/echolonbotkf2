# EcholonBot (KF2)

A ground-up rewrite of the KF2Bots single-player bot mod for Killing Floor 2 (UE3 UnrealScript), package `EcholonBot`, built with a deterministic agent kit that lets local models write one function at a time.

## Layout

```
Classes/              mod source (empty until M1 generates the skeleton)
kit/
  tools/              the agent kit (Python 3.11+, stdlib + httpx + jsonschema + pytest)
  tests/              pytest suite; tests/negative/ has one snippet per validator rule
  bible/              BIBLE_CORE.md (always in prompts) + topics/*.md (by task tag)
  contracts/          class chain, dropped symbols, SDK seed (contracts.json lands in M0b)
  generated/          symbols.json (built from the legacy corpus)
  reports/            symbol_diff.md, validator_selftest.md
  docs/               llama-swap setup guide + config
  workspace.json      machine paths (override in workspace.local.json, which is gitignored)
  USCRIPT_SYNTAX_BIBLE.md, decisions.md, ledger.json, MILESTONE0A_REPORT.md
```

## Setup on your PC

1. Clone this repo to `Documents\My Games\KillingFloor2\KFGame\Src\EcholonBot`.
2. Run `pip install httpx jsonschema pytest`.
3. Check the paths in `kit\workspace.json` (SDK root, legacy folder, doc path). Put any changes in `kit\workspace.local.json`.
4. Optional, for the local models: follow `kit\docs\LLAMA_SWAP_SETUP.md`.

## Commands (run from the repo root)

```powershell
python kit\tools\verify_hashes.py                      # legacy files match the doc?
python kit\tools\symbol_indexer.py                     # rebuild symbols.json + reconcile to 943
python kit\tools\context_slicer.py sys @SYS-MUT-BOOT   # budgeted doc slice for a prompt
python kit\tools\context_slicer.py sym Bot.HealOther   # one legacy symbol body
python kit\tools\ast_validator.py --format text Classes\*.uc
python kit\tools\ast_validator.py --corpus-selftest
python kit\tools\backend_check.py                      # is llama-swap up?
python -m pytest -q kit\tests
```
