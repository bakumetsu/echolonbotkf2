# Decisions

Final decisions from the Milestone 0 spec (D1-D6) plus answers given in the project thread.

## Spec decisions
- **D1 Skeleton-first.** M1 generates all class files from `contracts.json` with signature-only stubs; later milestones only replace bodies.
- **D2 Constants.** `constants.json` is the single source; the generator emits `const` blocks into Mut and Base.
- **D3 Code-gen protocol.** One function/state per model call, returned as one ```unrealscript block; JSON only for control messages; `splice.py` replaces stubs by symbol.
- **D4 Prompt budget.** Bible core ≤1.8k + doc slice ≤2k + contract ≤1k + task ≤0.5k tokens; hard fail >7k; estimator chars/3.5.
- **D5 Legacy policy.** Drop C5, A5, C9, RebuildHierarchy + its timer, GetActiveBoss (both copies). Fix C3, C6. C4 nearest-point fix is `BEHAVIOR-CHANGE`. D1/D2 states port thin as `UNVERIFIED-ENTRY`, pruned at M6. Machine-readable list: `contracts/dropped_symbols.json`; table: `USCRIPT_SYNTAX_BIBLE.md`.
- **D6 Milestones.** M1 skeleton + MUT-BOOT/SPAWN/PERK/UTIL; M2 NAV-*; M3 BASE-BOOT..BASE-RANK; M4 MUT-PLATOON..MUT-HEALCOOL; M5a/b/c BASE-FORM..LOGIC-UTIL (+LOGIC-DEATH); M6 BOT-HUB..BOT-TERM.

## Thread decisions (2026-10-18)
- **D7 Review is manual and model-agnostic.** No API calls to Opus. Escalations are self-contained markdown packets, so any AI can review them for edge cases, loopholes and bugs.
- **D8 Package name `EcholonBot`.** Classes are renamed per `workspace.json` `class_map` (EcholonMut, EcholonFollowNavBase, EcholonBotBase, EcholonBotLogic, EcholonBot, EcholonWeaponInfo, EcholonChat, EcholonBroadcastHandler, EcholonInventoryManager). The repo is cloned to `KFGame\Src\EcholonBot`.
- **D9 All 9 legacy classes are in scope,** including the 4 auxiliary ones. They are indexed and validated; the 943 gate still covers only the 5 core files.
- **D10 Backend is llama-swap** in front of your existing llama.cpp (`D:\LLM Storage\llama.cpp`), so exactly one model is loaded at a time. Roles: coder and debugger = `swift` (Swift 1.5 Qwen3.8-27B IQ3_S-mtp), doc = `ap` (Qwen3.8-27B-AP IQ3_S). Both use 32k context, since kit prompts stay ≤7k plus up to 8k of reasoning. The flags come from the user's .bat. Setup: `docs/LLAMA_SWAP_SETUP.md`.
- **D11 No LLM orchestrator.** Routing is deterministic Python. Local models write or fix one symbol at a time; planning and review stay with Opus/humans.
- **D12 Milestone 0 is split.** M0a = hashes, indexer, slicer, validator, Bible (done). M0b = boundary auditor, compile loop, sdk_index, log checker, runner, splice, skeleton/constants generators, contracts.json, docgen.
- **D13 Ternary is house-style banned (WARN), not a compile error.** Corpus evidence shows it compiles.

## Milestone 0b decisions (2026-10-18, defaults picked by the kit; change any of them)
- **D14 Config file is `config(EcholonBot)`.** The legacy `config(BotsMut)` is renamed so the rewrite's settings land in `KFEcholonBot.ini` and never mix with the old mod's.
- **D15 M5 split.** M5a = FORM, OVERWATCH, CQB, GRUNT, PANIC, RELOAD; M5b = LTBOUND, WEDGE, EMOTE, WEAPON, AUDIT, HEALQ (+ `EcholonWeaponInfo`); M5c = all LOGIC-*. Edit `MILESTONES` in `contracts_gen.py`, then re-run it with `--force`.
- **D16 Aux classes land in M1** (chat, broadcast handler, inventory manager are used by Mut boot and spawn), except `EcholonWeaponInfo`, which goes with BASE-WEAPON in M5b.
- **D17 `WaitForLanding` has a timeout parameter.** The SDK declares `WaitForLanding(optional float waitDuration)`, which corrects the doc's "no timeout". The Bible's W4 says to pass `WaitForLanding(2.0)` and keep an external timer, because the native behaviour is still [UNVERIFIED].
- **D18 Two writers missing from doc 6.2 are legitimate:** `FollowSetLeader` (Nav:214) and `AuditStateEntry` (Base:2564). They are listed in `single_writer.json` with notes.
- **D19 A failed task leaves no trace in the mod source.** agent_runner restores the class file byte for byte when a task fails or escalates; the attempt lives only in `kit/runs/`.
- **D20 Models answer with code or a control JSON, never both.** `{"control": "need_info" | "cannot" | "contract_conflict"}` stops the task and escalates it without touching the file.
