# Handoff: Matrix chat for the local models, and the benchmark plan

Context for another Claude session. State as of 2026-10-19. This thread covered two ideas from the user (AnhBaSing). Idea 1 is now built and working. Idea 2 is planned but not started.

## Project background (short)
- **EcholonBot**: a Killing Floor 2 UnrealScript bot mod. Repo `bakumetsu/echolonbotkf2`. Milestones M4 to M6 are merged on `main`. PR #7 (post-M6 fixes) is open, and the user said to **skip it for now**, because the `ap` model is too weak at review.
- **Agent kit**: Python tools (stdlib + httpx, jsonschema, pytest; no agent frameworks) that drive local models through **llama-swap** on the user's Windows PC (16 GB GPU, one model in VRAM at a time).
  - Rule: Python decides what to do; the model only writes code.
  - Models now: `swift` (coder) and `ap` (review and bug hunt; weak).
  - The kit lives at `C:\Users\AnhBaSing\Documents\My Games\KillingFloor2\KFGame\Src\EcholonBot\kit\`. It is git-ignored and local only, and the PC copy is the source of truth.
- User rules:
  - llama-swap unloads models after 10 idle minutes (ttl 600).
  - The GPU must be freed before any playtest.
  - Reversible kit work is fine. Don't commit the kit.

## Idea 1: watch the Claude ↔ model conversations (DONE)
The user couldn't see what Claude and the local models say to each other. This is now solved with **Matrix**, read in **Cinny**.

### Platform
- The user's self-hosted Cinny (`https://cinny.anhbasing.io.vn`, LAN `http://192.168.50.40:8080`) is only a client. The homeserver is **matrix.org** (`https://matrix-client.matrix.org`).
  - Moving to a private homeserver (for example Tuwunel on the user's Proxmox laptop) was discussed and deferred. Only test and demo data has been posted so far.
- Discord was the first idea. It was replaced because the user wanted self-hosted, and checked Cinny instead.
- Cinny facts that were checked in its source code:
  - Prism UnrealScript syntax highlighting is built in.
  - Code blocks over 14 lines collapse automatically, with expand and copy buttons.
  - Code blocks accept a `data-label`.
  - There's no thread panel, so the layout is flat rooms.

### Accounts and rooms
- **Space "Echolon"**, with the rooms **general, runs, benchmark, peer-review**. A temporary `livechat-test` room was removed from the space and the bots left it; the user needs to leave it in Cinny.
- **Claude** = `@echolon-bot:matrix.org`, display name "Claude". It posts orchestration messages, prompts, checks and verdicts.
- **5 model seats**: `@model-1` … `@model-5:matrix.org`, under seat keys `model-1` to `model-5`.
  - Display names: model-1 = "swift", model-2 = "ap", the others "Model-3" to "Model-5".
  - `chat.json` → `speakers` maps a kit model name to a seat (swift→model-1, ap→model-2). Unmapped models post through Claude with their name in front.
  - Seats will be renamed after their benchmark roles, for example "Coder (swift)".
- The user's account `@filthyfrankowo:matrix.org` is admin (power level 100) everywhere.

### Files (all in `kit\chat\` on the PC)
- `echolon_chat.py` has these subcommands:
  - `setup`: idempotent. Creates the space and rooms, invites, joins every seat and sets display names.
  - `check`
  - `demo`
  - `note`
  - `name "<display>" --account <seat>`
  - `relay <transcript>`: posts `kit\logs\transcript.jsonl` live.
  - `livechat` (see below)
- `chat.json`: homeserver, room ids, `speakers`, and `"livechat": {"rooms": "all"}`.
- `chat.secret.json`: `me`, plus per-seat `user`, `password` and `token`. On first login the password is blanked and the token is saved. Never print or commit this file.
- `chat_log.py`: writes `kit\logs\transcript.jsonl`. It is hooked once into `Backend.chat` in `kit\tools\agent_runner.py`, which covers agent_runner, bughunt, diff_review, hub_audit, comment_pass and overnight. agent_runner also logs pass/fail for splice, validator, audit and compile.
  - Not done: run-start and run-end headers in agent_runner, because a permission prompt blocked that edit.
- Launchers:
  - `kit\Start-All.bat`: starts llama-swap, waits until it answers, then starts the watchdog and the relay. It never loads a model.
  - `kit\tools\Start-Watch.bat` (watchdog = `watch.py`)
  - `kit\chat\Start-ChatRelay.bat`
  - `kit\chat\Start-LiveChat.bat`
- `kit\README.md` has a section at the top, **"Before any task: start these 3"**: llama-swap, the watchdog and the chat relay. GPU check: `python kit\tools\vram.py status`, which only reads. Don't use `backend_check.py` as a check: it sends a real prompt and loads a model.
- Tests: 18 chat tests, and the kit suite is 72/72.
  - `test_deploy_copies_u_and_resets_ini` was fixed so it no longer unloads the real llama-swap.
  - Don't run the kit suite while livechat is open anyway.
- An older draft of the chat tool is in `/mnt/project-files/agent-kit/chat/`. It is out of date; the PC copy wins.

### Livechat (talk to the models from Cinny)
- Triggers:
  - Listens in all rooms by default (`chat.json` livechat.rooms).
  - Only the user's account triggers it.
  - `@swift` / `@ap` (or their ids or pills) get an answer from that model; `@all` gets swift then ap. A message with no mention gets no answer.
- Answers:
  - Each answer uses the room's last 10 messages, is at most 3 sentences, and is posted in the same room.
  - It is one message from the model's own account that edits itself: ⏳ loading model → 💭 thinking (N s) → ✍️ writing (N s) → the answer, with its reasoning collapsed and a "(N s, tokens)" line. Edits happen at most every 5 s. For livechat only, the output is streamed.
  - The Claude account only posts the start and disconnect lines.
- Startup: if llama-swap isn't running, livechat starts it automatically.
- Stopping:
  - The user types `livechat disconnect` in any room.
  - Automatically when llama-swap reports no model loaded after its idle ttl.
  - Ctrl+C.
  - Either way it posts "Live chat disconnected" and unloads the GPU.
- Matrix connection glitches are retried with backoff. After 10 failures in a row it posts a disconnect line and stops.
- `livechat --test` runs the old poem round (each model writes a Linux poem, max 5 lines × 6 words, with one retry if it breaks the rule).
- Livechat calls are written to the transcript, marked as already posted, so the relay doesn't post them twice.

### Open item: @Claude replies
- The user chose **real Claude**: tagging @Claude should run a headless `claude -p` on the PC and answer in the room.
- Planned limits:
  - Read-only tools only, working directory = the repo.
  - `--max-turns 5` and a 180 s timeout.
  - Short answers.
  - Blocked from reading `chat.secret.json`, with tokens stripped from the output.
  - Every call logged to `kit\logs\claude_calls.jsonl`. Each @Claude tag uses the user's Claude plan.
- **Blocked**: the Claude Code command-line tool isn't installed on the PC. Nothing was installed. Finish this once the user installs it.

## Idea 2: 8-model benchmark to assign roles (PLANNED, not started)
- Goal: test 8 models (the user hasn't chosen them yet) on questions taken from this codebase, easy to hard, and assign roles: coder (most important), fixer, reviewer, bug hunter, docs. Since replacing ap is now the priority, reviewer and bug-hunter scores count as much as coder. Leftover models go to a peer-review pool.
- Questions, in five tiers:
  1. easy functions
  2. UnrealScript traps (timers and the like)
  3. fixing compile errors
  4. finding planted bugs, using ap's 6 real findings out of 25 and swift's 3 timer bugs and 1 invented variable as the answer key
  5. hard M6 state code
- About 25 questions. Claude drafts them and the user approves.
- Grading:
  - automatic checks: the validator, the boundary auditor, invented symbols against `symbols.json`, and the real KF2 compile
  - answer keys for bug-hunt precision and recall
  - Claude's blind rubric for logic
- **Batch compile**:
  - Each answer goes in a throwaway `Bench_<model>_<q>` subclass. The benchmark package is separate and never deployed.
  - The compiler stops at the first error, so: remove the failing class and recompile.
  - Compiles run on the CPU while the next model generates.
- Output per model:
  - the user's three: questions solved, compiles needed, time to answer
  - plus: results per tier, logic score, invented names, rule breaks, bug-hunt real vs false alarms, tok/s and reasoning tokens, quant/context/VRAM, consistency across repeats
  - A summary table, a per-tier table and a role map, shown as a diff to `models_config.json` for approval.
- Speed:
  - one load per model
  - a shared prompt prefix, so the cache gets reused
  - a reasoning budget per tier (2k, 4k or 8k tokens)
  - stop when the code block closes
  - smart repeats (borderline answers and the top 3 models only)
  - early cut on hard-tier repeats
  - Rough estimate, unverified: 4 to 6 h overnight.
- Model choice: the highest quant that still leaves room for 32 to 64k context. A rule of thumb to verify with `vram.py`: a model file of about 12–13 GB or less, with the KV cache at q8_0. The SSD only affects load time.
- Peer review (vague, later):
  - Leftover models review the best coder's output and look for hidden bugs, loopholes and edge cases, and suggest better solutions, **in pseudocode**.
  - Reviews run in batches, one model load per reviewer.
  - Claude decides which ideas to accept, and the user only wants a summary. Results go to the peer-review room only.
- Next steps:
  1. The user picks the models; Claude checks VRAM fit.
  2. Claude drafts the questions.
  3. Build the bench harness, reusing chat_log so the benchmark room shows it live.
  4. Run it overnight.
  5. Write the role map and rename the seats.

## Full design doc
`/mnt/project-files/plans/discord-and-model-benchmark.md` has the full history of decisions, including the early Discord and Zulip ideas, the mock report table and the context-budget notes.
