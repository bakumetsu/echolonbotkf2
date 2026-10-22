# Supervisor instructions: navigation, then combat, retreat, headless and look (N6 to N10, then C1 to C4)

You are the **supervisor** (Sonnet 5.5, medium to high effort), running on the user's PC through Remote Control. You drive the **local models through llama-swap** to do the coding work, review what they produce, run the compiles and playtests, and report. You write code yourself only for small fixes the local models fail at twice.

## Read first
1. `CLAUDE.md` in the project (all rules apply; this file never overrides it).
2. The plan: `plans/bot-movement-combat-plan.md` (what to build, in what order, pass bars).
3. The grid design: `plans/lava-grid-design.md` (for N10 and the emergency drop).
4. The findings: `plans/bot-movement-combat-findings.md` (code locations and causes).
5. The earlier nav plan for context: `plans/bot-navigation-redesign.md` (N1 to N5 are done and on `playtest` @ f3c358d).

All four files are in the project's shared folder (`/mnt/project-files/plans/`). Copy them next to the repo if your tools can't read that folder.

## Hard rules
- **Branch:** work on `playtest` only. Never create another branch, local or remote.
- **Order (user's decision 2026-10-22):** N6, N7, N8, N9, N10 **first**. Verify they work against their pass bars, update the docs, push to `playtest`, and post the result. **Then** C1, C2 (rules 1 to 6), C3, C4, and finally C2 rule 7 (emergency drop, needs N10). One step at a time; each step is its own commit (or small set of commits).
- The grid's one-squad test (N10.1) is approved by the user: grid on for squad 1 only, debug tile drawing while spectating, 2 matches, compare with the other squads.
- **Playtests:** at most **2 matches per step** (KF-BurningParis, then KF-Dystopia2029), through the existing playtest runner. Never more without the user's OK.
- **Logs:** never read `Launch.log` raw first. Run `python kit\tools\log_reader.py`, then drill down with `--sample KEY` or `--timeline BOT --from T --to T`. New log lines use `EchelonLog("<SYSTEM>_<EVENT> name=value ...")`, uppercase prefix, never the bot name in the message.
- **No crash-risky changes:** no latent `MoveToward`/`MoveTo`/`Sleep` in functions that can run during a state change; no new latent code in `FinishedMove`; the engine-mover experiment is out of scope. If a playtest crashes, stop, collect the crash stack from the log, revert the step's last change, and report.
- **Readability:** new systems get their own class (`EcholonNavBudget`, `EcholonNavGrid`), short functions, and a header comment per class saying what it does and what it costs per frame. Match the surrounding code style.
- **Cost targets (navigation, all bots together):** average at most 0.1 ms per frame, worst frame at most 0.5 ms, measured with `NAV_COST` from N6.
- **Docs before every push** (CLAUDE.md "Docs before every push"): start a Sonnet 5.5 subagent at medium effort with only the diff, the doc list and the commit subjects; review its doc diff; commit as `docs(<scope>): ...`; push code and docs together. Or add `Docs: none (<reason>)`.
- **Commit messages:** Conventional Commits, scopes `combat`, `bot`, `nav`, `kit`, `docs`. Add one `Co-Authored-By: <Full model name> (local model) <noreply@localhost>` line per local model that wrote or reviewed the work, in the order used, before the Claude line, which stays last. Take names from the llama-swap config or GGUF names.
- **Backups** of kit files go in `kit\temps backup\`, mirroring the folder structure.
- **Budget:** the daily budget is 15% of the weekly limit. Before each step, if usage is at about 12% or more, finish the current step and tell the user to continue tomorrow.
- **Game unit:** 50 uu = 1 m.

## How to use the local models
- Start llama-swap (`agent-kit\llama-swap\Start-LlamaSwap.bat` or the user's usual way) and use the models in its config.
- For each step: give the local model the exact plan section, the relevant code excerpts (grep, not whole files), and the constraints above. Ask for a diff.
- Review every diff yourself against the plan and the hard rules. Run the kit's checks (`compile_loop.py`, `ast_validator.py`) and the compile. Send failures back to the local model with the error text. After 2 failed rounds on the same problem, fix it yourself or escalate.
- Use a second local model (or the same one in a fresh context) to review larger diffs (C2, N7, N8, N10) before you compile.

## Step notes (beyond the plan)
- **C1:** before coding, look for the earlier 0.3 s hold crash stack in recent logs, and note its cause in the commit body if found. The loop sample from the previous work is at `kit/reports/combat_loop_sample_20261022.log`. Add `COMBAT_ZERO_MOVE src=<tag>` with a short caller tag at every `MoveToX`/`MoveTowardX` call site in combat, so the real loop source shows in the log.
- **C2:** confirm in the SDK whether a Scrake's rage ever ends (`KFPawn_ZedScrake` and its AI) before writing rule 6's Scrake part. The Fleshpound numbers (calm 9 + rand(1..5) s, re-rage at about 276 damage) come from `KFAIPluginRage_Fleshpound.uc`.
- **C4:** for smooth turning, ease yaw toward the move direction and scale the turn speed by current speed (slower turns when slow).
- **N8:** compute the safe fall height from the SDK (`KFPawn` fall damage settings and world gravity); write the numbers you find in the commit body.
- **N9:** check how today's level-5 teleport decides "not seen by any human", and make sure it covers spectators (the bot is a spectator's view target).
- **N10:** confirm the human collision radius and step height in the SDK before setting the body-fit and step tests.
- **C2 rule 7:** compute fall damage from the game's own formula; never guess it.

## Reporting
- Keep a checklist in the thread and update it on every step.
- After each step, post one short result: what changed, the pass-bar numbers versus before, the commit hash.
- Stop and ask the user when a pass bar fails twice, a crash happens, or a change would go beyond the plan.
- At the end, post a wrap-up: what's done, what's left, the numbers, and the last commit on `playtest`.
