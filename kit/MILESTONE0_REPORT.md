# Milestone 0 report (M0a + M0b)

**Result: every M0 gate passes. 61 of 61 tests pass** against the real legacy corpus (`python -m pytest -q kit/tests`). Without the corpus (for example in CI), 43 pass and 18 skip.

| Gate | Result |
|---|---|
| G0-G4, G7 Bible | Unchanged from `MILESTONE0A_REPORT.md`: hashes match, 943 reconciled with 0 unexplained, every @SYS tag slices under budget, 0 validator ERRORs on the corpus. |
| G5 boundary_auditor | 0 findings on the legacy corpus (`reports/boundary_legacy.md`). A synthetic foreign write of `FollowStatus` fails with B001, and the owner's write passes. |
| G5 compile_loop | Parses your real success log and a synthetic error log. The fix request holds the first 3 error locations, a ±20-line slice, the signatures in scope and the enclosing symbol. After 3 failed fixes it writes `escalation.md` (≤1.5k tokens). |
| G5 sdk_index / log_checker | The SDK indexer resolves members through the parent chain (`--lookup`). Run against your real Launch.log, the log checker found 11,323 Accessed None warnings, all in base-game code and none in ours. |
| G6 contracts + skeleton | 9 classes, 447 functions/events, 20 states, 112 consts. The generated skeleton gives 0 validator ERRORs and 0 audit findings, uses CRLF, and is never overwritten without `--force`. |
| G6 splice + runner | splice refuses a changed signature, extra code or two code blocks, and keeps CRLF. `agent_runner plan` splits the work into 464 tasks (M1 70, M2 43, M3 81, M4 59, M5a 44, M5b 35, M5c 39, M6 93). The largest prompt is ~4.3k tokens (hard cap 7k). A mock end-to-end run succeeds, and a failed run restores the file byte for byte. |
| G7 docgen | `docs/ARCH_V3.md` is generated from the contracts, and `--check` fails when it is stale. |

## [UNVERIFIED]
- **Compile error line format** `File.uc(N) : Error, msg`. The error fixture is synthetic; your first failing compile will confirm or correct `error_regex`.
- **`-unattended`** on the KFEditor command line.
- **Forward-slash paths** in the llama-swap config.
- **Native behaviour** of `WaitForLanding(2.0)`, in-state `super`, `IsInState` on parent states, and timer dispatch to state overrides.
- **U010 (unknown function)** stays quiet until you build the full SDK index with `sdk_index.py`; the sample used here covered only 24 files.

## Known limits
- `ast_validator.py` is 443 lines, a little over the ~400 guideline. It is one rule per function and can be split if it grows.
- Contracts for the big classes (Base ~4.5k tokens) don't fit one prompt. The runner sends only the target signature and a trimmed legacy body.
- The mock backend proves the plumbing, not the models. The first real run of `agent_runner run M1 --limit 3` is the real test.
