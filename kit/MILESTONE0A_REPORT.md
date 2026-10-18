# Milestone 0a report

**Result: all M0a gates pass. 44 of 44 tests pass** (`python -m pytest -q kit/tests`, run against the real legacy corpus).

| Gate | Result |
|---|---|
| G0 scaffold + verify_hashes | All 5 sha256 prefixes and line counts match the doc. A tampered file fails loudly (tested). |
| G2 symbol_indexer | 1058 symbols across 9 files. The 5 core files hold 938 real top-level symbols, which reconcile to **943** with **0 unexplained** differences (`reports/symbol_diff.md`). All 375 line ranges in doc 0.3 match exactly. Every function, event and state has an owner @SYS tag. `--file` incremental re-index is tested. |
| G3 context_slicer | All 60 @SYS tags slice under 2000 tokens (default parts 3-6). P6 returns its 4 headings. Over-budget runs exit 2 with a list of parts to drop. The 7k hard cap can't be raised. The A-Z index is refused. Bare citations are rewritten to `File:a-b` and range-checked. |
| G4 ast_validator | **0 ERRORs** on all 9 legacy files. 13 negative snippets each fire exactly their own rule. |
| G1/G7 Bible | The core is ~1050 of 1800 tokens; 6 topics run 290-380 of 600. Every W-item has a status and a citation. No [VERIFY] remains; resolutions are in `USCRIPT_SYNTAX_BIBLE.md`. |

**Spec corrections found:** (1) ternary `?:` compiles in KF2 (16 corpus uses), so U008 ternary is a WARN, not an ERROR. (2) The legacy files are partly decompiler output (`J0x..:` + goto loops), so a new rule N13 and validator U014 (WARN) cover that style. (3) The doc's 943 count came from an extractor that counted struct members and missed `var()`. (4) The `bFollowExitPending` writers are resolved: Nav clears it, the hub sets it.

## [UNVERIFIED]
- The per-error compile line format (`File.uc(N) : Error, msg`). The command `make -useunpublished -log`, the log path, the `Success - N error(s), N warning(s)` summary and the runtime ScriptWarning format are now verified from your real logs (trimmed copies in `tests/fixtures/logs/`). `-unattended` is an addition that hasn't been tried.
- Whether llama-swap accepts the forward-slash, quoted paths in `docs/llama-swap.config.yaml`.
- U010 (unknown SDK member) is deferred to M0b because it needs `sdk_index.py`.
- In-state `super.` semantics, `IsInState` matching parent states, and timers dispatching to state overrides. These are marked UNVERIFIED in the Bible topics.

## Next: M0b
The boundary auditor + single_writer.json, compile_loop (with `--fake-log`), sdk_index, log_checker, splice, skeleton_gen, contracts.json + constants.json generators, agent_runner with `--mock-backend`, and docgen.

## Answered (2026-10-18)
- SDK: `D:\SteamLibrary\steamapps\common\killingfloor2\Development\Src` (confirmed).
- Models: Swift 1.5 Qwen3.8-27B IQ3_S-mtp (coder/debugger) and Qwen3.8-27B-AP IQ3_S (docs), both from your .bat, now in `docs/llama-swap.config.yaml`.
- Logs: your Launch.log was a successful no-op compile, so the error-line format gets confirmed on the kit's first failing compile.
