# EcholonBot (KF2)

A ground-up rewrite of the KF2Bots single-player bot mod for Killing Floor 2 (UE3 UnrealScript), package `EcholonBot`, built with a deterministic agent kit that lets local models write one function at a time.

## Layout

```
Classes/              mod source (empty until you run skeleton_gen in M1)
kit/
  tools/              the agent kit (Python 3.11+, stdlib + httpx + jsonschema + pytest)
  tests/              pytest suite; tests/negative/ has one snippet per validator rule
  bible/              BIBLE_CORE.md (always in prompts) + topics/*.md (by task tag)
  contracts/          contracts.json (every class's shape), constants.json, single-writer rules, dropped symbols
  generated/          symbols.json (legacy corpus); sdk_symbols.json (your SDK, built locally, gitignored)
  reports/            symbol_diff.md, validator_selftest.md, boundary_legacy.md
  docs/               ARCH_V3.md (generated architecture), llama-swap setup guide + config
  models_config.json  which local model plays coder / debugger / doc
  workspace.json      machine paths (override in workspace.local.json, which is gitignored)
  USCRIPT_SYNTAX_BIBLE.md, decisions.md, ledger.json, MILESTONE0_REPORT.md, SESSION_SUMMARY.md
```

## Setup on your PC

1. Clone this repo to `Documents\My Games\KillingFloor2\KFGame\Src\EcholonBot`.
2. Run `pip install httpx jsonschema pytest`.
3. Check the paths in `kit\workspace.json` (SDK root, legacy folder, doc path). Put any changes in `kit\workspace.local.json`.
4. Run `python kit\tools\sdk_index.py` once to index your SDK (needed for the unknown-function check).
5. For the local models: double-click `D:\LLM Storage\llama.cpp\Start-LlamaSwap.bat` (details in `kit\docs\LLAMA_SWAP_SETUP.md`).

## Commands (run from the repo root)

```powershell
python kit\tools\verify_hashes.py                      # legacy files match the doc?
python kit\tools\symbol_indexer.py                     # rebuild symbols.json + reconcile to 943
python kit\tools\context_slicer.py sys @SYS-MUT-BOOT   # budgeted doc slice for a prompt
python kit\tools\context_slicer.py sym Bot.HealOther   # one legacy symbol body
python kit\tools\ast_validator.py --format text Classes\*.uc
python kit\tools\ast_validator.py --corpus-selftest
python kit\tools\backend_check.py                      # is llama-swap up?
python kit\tools\sdk_index.py --lookup Controller.MoveToward
python kit\tools\boundary_auditor.py Classes\*.uc       # single-writer rules (B001)
python kit\tools\compile_loop.py                      # one KFEditor compile -> fix_request.json
python kit\tools\log_checker.py                       # runtime Accessed None etc. in our package
python kit\tools\contracts_gen.py                     # rebuild contracts from legacy (refuses hand edits)
python kit\tools\skeleton_gen.py                      # write all 9 class files as stubs (M1 start)
python kit\tools\splice.py Classes\EcholonMut.uc EcholonMut.PostBeginPlay reply.md
python kit\tools\agent_runner.py plan M1              # tasks from the M1 stubs
python kit\tools\agent_runner.py run M1 --limit 3     # coder -> splice -> checks -> compile -> fix x3
python kit\tools\agent_runner.py status
python kit\tools\docgen.py                            # regenerate kit\docs\ARCH_V3.md
python -m pytest -q kit\tests
```
