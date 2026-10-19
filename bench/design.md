# Two ideas: a Discord window into the models, and an 8-model benchmark

Design only. Nothing has been built, installed or changed. Each part ends with questions; my default is marked ★ so you can just answer "defaults" on any you don't care about.

Grounding (what exists today):
- The kit on your PC calls local models through llama-swap at `127.0.0.1`. One model is in VRAM at a time on a 16 GB GPU. Models now: `swift` (code) and `ap` (review, bug hunt).
- Every model call goes through one HTTP client in the kit (`common.py`), so there is a single choke point to capture traffic.
- Your rules, treated as hard constraints: models unload after 10 idle minutes (ttl 600), and the GPU must be empty before any playtest.
- Note: the llama-swap config snapshot in the project files still says `ttl: 1800`. I assume the live one on your PC says 600.

---

## Idea 1: Discord as the window into the model conversations

### What "the conversation" actually is
Today there are three kinds of messages you can't see:
1. **Kit to model**: the prompt Python builds (task, contract, Bible sheet, code slice). Up to ~7k tokens.
2. **Model to kit**: the answer, plus the model's hidden reasoning (llama-server returns it separately as `reasoning_content`).
3. **Claude**: my instructions to the kit (which command I ran and why) and my verdict on the output (accept, fix, escalate).

Points 1 and 2 are the bulk. Point 3 is short notes.

### How it would work
```
kit tool ──► common.py client ──► llama-swap ──► model
                 │
                 └─► transcript.jsonl (one line per request and per reply)
                                 │
                    discord_relay.py (tails the file)
                                 │
                       Discord webhook ──► #echolon-runs channel
Claude (via Remote Control) ──► post_note.py ──► same transcript ──► same channel
```
- **Capture**: a few lines in `common.py` append every request and reply to `kit/logs/transcript.jsonl` (time, run id, task id, model, prompt, answer, reasoning, tokens, seconds). This is useful even without Discord: it's a permanent record you can grep.
- **Relay**: a small separate script reads new lines and posts them to Discord with a **webhook**. A webhook can set a different name and avatar per message, so it reads like a group chat: "Claude", "swift", "ap", "kit".
- **One Discord thread per run** (for example "M6 batch 3" or "Benchmark run 1"), so the channel doesn't become a wall.
- **Long text**: Discord caps a message at 2,000 characters (4,096 in an embed). Short messages post in full. Long prompts post as a 2-3 line summary ("swift asked to write `EcholonBot.FightEnemy.BeginState`, 6,800 tokens, contract + timers sheet") with the full text attached as a `.txt` file. Code answers go in a code block, or as an attached `.uc` file if long.
- **Reasoning**: posted collapsed (spoiler tag or a file), because it is often several thousand tokens.
- **Claude's notes**: when I run something through Remote Control, I'd also run `post_note.py "Running bughunt on EcholonBotLogic; checking the 3 timer findings"`, and my verdict afterwards.

### Why this shape
- The relay is separate from the kit, so if Discord is down or rate limits, the kit never slows down or fails. It just catches up later.
- A webhook needs only `httpx`, which the kit already uses. No new framework, no always-on bot.
- No GPU cost at all.

### Possible stage 2: talk back from Discord
A real Discord **bot** (not a webhook) could read commands like `!pause`, `!stop`, `!skip M6-040`, or a free-text note, and write them into the kit's existing control file (there's already a `control.schema.json`). This needs a bot token, a library like `discord.py` (a new dependency, which breaks the "stdlib + httpx" rule), and a process that stays running. I'd only do this after stage 1 proves useful.

### Alternatives worth knowing
- `watch.py` already shows progress live in a terminal on your PC. Discord's real advantage is that you can read it on your phone, away from the PC, and scroll back later.
- A local web page would do the same without Discord, but isn't reachable from your phone unless you expose it.

### Risks
- **The webhook URL is a password.** Anyone with it can post to your channel. It would live in an environment variable on your PC, never in the repo.
- **Content leaves your PC.** Prompts contain your mod code (already public on GitHub) and possibly local paths. The relay can strip paths like `C:\Users\...`.
- **Volume.** An M6-size batch is hundreds of calls. Summaries plus attachments keep it readable; a "verdicts only" mode keeps it quiet.
- **Rate limits**: about 5 posts per 2 seconds per webhook. The relay queues and batches, so this is not a real problem.

### Feasibility: high
Roughly 150-250 lines of Python: the capture hook, the relay, and `post_note.py`. Nothing touches the mod or the GPU.

### Questions on idea 1
1. Do you already have a Discord server you'd use, or should it be a new private one? (existing / new ★)
2. Who should see it: only you, or friends too? (only me ★ / others)
3. What do you want to see? (everything / prompts as summaries + full answers + Claude's notes ★ / verdicts only)
4. Show the models' hidden reasoning? (no / collapsed as a file ★ / in full)
5. Live, or after the fact? Posting each message when the model finishes is easy. Streaming tokens as they're typed means editing a message every second or two, which is noisier. (when finished ★ / live streaming)
6. One channel with a thread per run, or a channel per model? (thread per run ★ / channel per model)
7. Should my (Claude's) side include my reasoning for decisions, or just short notes and verdicts? (short notes ★ / detailed)
8. Is stage 1 (watch only) enough, or do you want stage 2 (send commands from Discord) planned now? (watch only first ★ / plan both)
9. Should the relay start automatically with llama-swap (added to `Start-LlamaSwap.bat`), or do you start it yourself? (with llama-swap ★ / manual)
10. Is it OK for the full code and prompts to be posted to Discord's servers? (yes ★ / summaries only)

---

## Idea 2: an 8-model benchmark to assign roles

### Goal
Find out, with evidence from *our* code, which model is best at each job, then give each job to the best fit. The models that don't win a role become the peer review pool.

Roles I'd score:
| Role | What it does in the kit |
|---|---|
| Coder | writes a function from its contract (`agent_runner`) |
| Fixer | fixes a compile error from the log (`compile_loop`) |
| Reviewer | reads a diff and says OK or not, with reasons (`diff_review`) |
| Bug hunter | finds real bugs in existing code without inventing fake ones (`bughunt`) |
| Docs | writes doc comments and summaries (`docgen`) |

### The hardware rule shapes everything
Only one model fits in 16 GB, and loading a 27B model takes a while. So the benchmark runs **model by model, not question by question**: load model A, ask it every question, unload it, then model B. Eight loads in total, not hundreds. After the last model, the harness unloads it explicitly so the GPU is free for a playtest right away (rather than waiting 10 minutes for the ttl).

Each model needs its own entry in the llama-swap config, with its own settings (chat template, reasoning flags, context size). To be fair, all models get the same context (32k), the same temperature, and the same reasoning budget, unless a model needs something special.

### The questions: from our code base, easy to hard
About 20-30 questions in five tiers. Each question is a small JSON file: the prompt, the context the kit would normally give, and how to grade it.

| Tier | Example from our code | How it's graded |
|---|---|---|
| 1. Easy | Write a short getter or helper from its contract (e.g. a function in `EcholonWeaponInfo`) | validator + real compile |
| 2. UnrealScript traps | A function that needs timers, iterators or array removal in a loop (the exact areas where swift made its 3 timer bugs) | validator + compile + checklist of the specific trap |
| 3. Fix it | A real function with a compile error injected, plus the error line from the log | does it compile after one fix? |
| 4. Find the bug | A merged function with a known bug planted back in (the 3 timer bugs, the invented variable, plus ap's 6 real findings) and some clean functions as decoys | precision and recall against the answer key |
| 5. Hard | State code and multi-function logic from M6 (e.g. `FightEnemy` state entry, `PickNextMove`) | compile + Claude's blind rubric score |

Plus a **review test**: show 8-10 diffs, some good and some with bugs, and ask OK or not. ap's 25 findings (6 real, 19 false alarms) are a ready-made answer key for false-alarm rate.

### Grading, in order
1. **Automatic** (no judgment): the kit's validator, the boundary auditor, a check for invented variables against `symbols.json`, and the real KF2 compile through `compile_loop.py`.
2. **Answer keys** for bug hunting and review: precision (how many flags are real) and recall (how many real bugs it found).
3. **Blind rubric** for logic quality on tiers 2 and 5: I score the answers without knowing which model wrote them, against the original function's intent. This catches code that compiles but does the wrong thing.

Also recorded per model: speed (tokens per second), time to answer, reasoning tokens used, and whether it fit in VRAM at 32k.

Note: the reference answers in `main` were written by swift. Grading is by behavior and the rubric, not by "looks like the reference", so swift doesn't get a free advantage.

### Randomness
At temperature 0.6 the same model can answer differently each time. Running each question 2-3 times shows which models are consistent. It also multiplies the time. Alternative: temperature 0 for the benchmark (deterministic, but not how we run them for real).

### Time cost (rough, unverified)
The real compile is the slow part: each answer has to be spliced into the code and compiled by KFEditor. Plan: run the cheap checks first and only compile answers that pass them. Load time and generation speed depend on your models; the first model's run will give real numbers to estimate the rest.

### Output
- `kit/bench/questions/*.json` (the question set, versioned in the kit)
- `kit/bench/results/<date>.jsonl` (every answer, raw)
- A report: a table of models by role with scores, and a recommended role map, ready to paste into `models_config.json`. You approve the role map before anything changes.

### Peer review later (the vague part, sketched only)
With one model in VRAM at a time, "everyone reviews" can't happen live per function. It would work in **batches**: the coder writes a batch of functions; then each reviewer model loads once and reviews the whole batch; then the results are merged.
- Votes weighted by each model's measured reviewer precision from the benchmark, so a model that cries wolf counts less.
- An issue only counts if 2+ reviewers agree, or a compile check or Claude confirms it. This matters: ap was wrong 19 times out of 25.
- Cost: one model load per reviewer per batch. With 5 leftover models that's 5 loads per batch, which is fine for a nightly run and slow for a live loop.

### Feasibility: high, with one real limit
The harness reuses tools we already have, so it's maybe 300-500 lines plus the question set. The real limit is **time on your GPU**: 8 models, one at a time, with real compiles. It's an overnight-style job, and your PC can't playtest while it runs.

### Questions on idea 2
11. Which 8 models? Please list names and file sizes or quants (e.g. "Qwen3.8-27B IQ3_S, 11 GB"). Are they all already downloaded?
12. Do all 8 fit in 16 GB at 32k context, or are some bigger and would need a smaller context or CPU offload? (they all fit / not sure ★ = I check with `vram.py` first)
13. Are `swift` and `ap` two of the 8? (yes ★ / no)
14. Which roles matter most to you? Rank: coder, fixer, reviewer, bug hunter, docs. (my guess: coder > bug hunter > fixer > reviewer > docs ★)
15. Can one model hold two roles if it wins both? (yes ★ / one role each)
16. How many questions? (~12 quick / ~25 balanced ★ / 40+ thorough)
17. Repeat each question? (once at temp 0 / twice at 0.6 ★ / three times)
18. Should every answer go through the real KF2 compile, or only answers that pass the quick checks? (only the ones that pass ★ / all)
19. How long can the benchmark take over your PC? (a few hours while you're out / overnight ★ / whole weekend)
20. Who should write the questions? (Claude drafts, you approve ★ / Claude alone / you pick the functions)
21. Who grades the logic quality? (Claude blind ★ / Claude + you spot-check / automatic only)
22. Same settings for all models, or each model with its own best settings from your .bat? (same for fairness ★ / own best)
23. Should speed count in the score, or only quality? (quality first, speed as tie-break ★ / weighted together)
24. For peer review later: should leftover models review every function, or only functions that failed a check or touched risky areas (timers, states)? (only risky ones ★ / everything)
25. Who has the final say when reviewers disagree? (Claude ★ / majority vote / you)

### Shared questions
26. Which first? Discord makes the benchmark watchable live, so building it first helps the benchmark. (Discord first ★ / benchmark first / both in parallel)
27. Should this wait until PR #7 (post-M6 fixes) is merged, so the benchmark uses the final M6 code? (yes ★ / no)
28. Do you want the benchmark run in Discord too, with each model's answers in its own thread? (yes ★ / no)

---

## Decisions so far (2026-10-19)
- Models: the 8 are not chosen yet.
- Discord: use the user's existing server.
- Benchmark length: overnight is OK.
- Timing: start both ideas only once the code base is stable enough.
- Every other question: still open.

## Round 2 answers (2026-10-19)
- Start after PR #7 is merged.
- Models: highest quant that still leaves room for 32-64k context. Split tasks to save context if that buys a higher quant.
- Chat: consider a self-hosted platform with an iOS app on the user's old laptop (24 GB RAM, RTX 3060 6 GB, about 10 GB RAM free when idle). Move to it if it works.
- Reasoning should be shown inside a code block.
- Most important role: coder.
- Benchmark questions: Claude drafts them, the user approves.
- Peer review is for hidden bugs, loopholes, edge cases and better solutions, written in pseudocode rather than code.

### Self-hosted chat options (details to verify before setup)
| | Zulip | Mattermost | Matrix (Synapse or Conduit) + Element X |
|---|---|---|---|
| iOS app | yes, official | yes, official | yes (Element X) |
| Code blocks with highlighting | yes | yes | yes |
| Collapsible block (for reasoning) | yes: a `spoiler` block can hold a code block | no | partly (HTML details, depends on the app) |
| One conversation per run | "topics" inside a stream, which fits well | threads | threads or a room per run |
| Bot posting | bot API with a key; simple HTTP | incoming webhook; simple HTTP | HTTP API with an access token |
| Phone notifications when self-hosted | free push relay for small servers | free test push relay; production relay needs a licence | works through the Element push service |
| RAM | 2-4 GB | about 1-2 GB with Postgres | Conduit under 0.5 GB, Synapse about 1 GB |
| Install | Docker or Ubuntu/Debian installer | Docker | Docker |

Recommendation: **Zulip**. Topics give one clean conversation per run, and the reasoning can sit inside a collapsed spoiler as a code block, which is exactly what was asked for. Mattermost is the simpler fallback, without collapsible blocks.

Reaching it from the phone away from home: put the laptop and phone on Tailscale (private, nothing opened to the internet), or use a Cloudflare Tunnel with a domain. Tailscale is the safer default.

Only the relay changes with the platform. Capturing the transcript in the kit stays the same.

### Exactly what gets posted (one topic per run)
1. **Run start** (kit): the command, the milestone or benchmark, the model, and the task count.
2. **Claude note**: what I'm running and why, in 1-3 lines.
3. **Prompt** (kit to model): one summary line with the task id, function, token count and context pieces used. The full prompt goes in a collapsed block, or as an attached file if it's over the platform's length limit.
4. **Reasoning** (model): a collapsed code block.
5. **Answer** (model): the code in a highlighted code block.
6. **Checks** (kit): validator, boundary audit and compile, each as pass or fail, and the first error line if one failed.
7. **Fix round** (kit to model, and back): the same as 3 to 6, marked "fix 1 of 3".
8. **Verdict** (Claude): accepted, fixed or escalated, plus the reason and the commit if one was made.
9. **Run end** (kit): totals for passed, failed and escalated, time taken, and confirmation that the GPU is unloaded.

### Peer review, refined
- Reviewers get the best coder's function, its contract and the related code. Each one answers in a fixed format: hidden bugs, loopholes, edge cases, and a better solution, all in **pseudocode**.
- Why pseudocode helps: reviewers can't fail on UnrealScript syntax, and their ideas are easy to compare and merge.
- Claude or the coder model turns accepted ideas into real code, which then goes through the normal checks and compile.

### Context budget
The kit already keeps a coding prompt to about 7k tokens, plus up to 8k of reasoning and about 2k of code, so 32k is enough for coding. Peer review of a function plus its related code fits in 32-48k. That leaves the rest of the 16 GB for the highest quant that fits. Rough rule, to verify with `vram.py`: a model file of about 12-13 GB or less, with the KV cache at q8_0.

## Round 3 answers (2026-10-19)
- The laptop runs Proxmox, so Docker is available.
- The user is mostly at home. Tailscale is already installed, and there is a Cloudflare proxy with nginx.
- The chat server is for the user only.
- Peer review output goes to Zulip only. No extra files in the kit.
- Claude decides on peer review ideas. The user only wants the end result or a summary of what the models found.

### Defaults chosen (change any time)
- Zulip runs with Docker in its own small Debian VM on Proxmox (about 4 GB RAM, 2 cores). A VM avoids Docker-in-LXC problems.
- Reached over Tailscale only. Nothing is exposed through Cloudflare, since the user is mostly home. The existing Cloudflare + nginx setup is there if remote access is wanted later.
- The kit on the gaming PC posts to Zulip over the LAN or Tailscale with a bot API key. The key is stored in an environment variable on the PC, never in the repo.
- Streams: `#echolon-runs` (coding runs), `#benchmark`, `#peer-review`. One topic per run.
- In `#peer-review`, Claude posts one short summary per batch: which findings were accepted and why. The raw reviewer messages sit in the same topic, collapsed.
- Order once PR #7 is merged: 1) Zulip VM and relay, 2) benchmark question set (Claude drafts, user approves), 3) user picks the 8 models and Claude checks VRAM fit, 4) overnight benchmark, 5) role map, 6) peer review.

### Batch compiling (decided 2026-10-19)
- Yes, batch it. Each answer goes into its own throwaway benchmark class (for example `Bench_<model>_<question> extends EcholonBot`) that overrides only that one function or state. The answers then don't collide, and one KFEditor run compiles all of them.
- Catch: the compiler stops at the first error. When a batch fails, the log names the class, so that answer is marked failed and removed, and the batch recompiles. Total compiles = 1 + the number of broken answers, and the validator removes most broken ones before that.
- The benchmark package is separate from EcholonBot and is never deployed.
- The "fix the compile error" tier still needs a compile per round, but each round is batched across all models.
- Compiling uses the CPU, not the GPU, so it can run while the next model is generating.

### Benchmark output per model (decided 2026-10-19)
The user's three measures:
1. Questions completed successfully (also broken down by tier).
2. Compiles needed (first-try passes, and fix rounds used).
3. Time to output (seconds per answer, plus total time including model load).

Claude's additions:
4. Logic score: the blind rubric, which catches code that compiles but does the wrong thing.
5. Invented names: variables, functions or classes that don't exist (checked against `symbols.json`).
6. Rule breaks: validator and boundary-audit hits (UnrealScript traps, writing a variable it doesn't own).
7. Bug-hunt accuracy: real bugs found, and false alarms.
8. Speed details: tokens per second, and reasoning tokens used.
9. Setup: quant, context size, and VRAM used.
10. Consistency: whether the repeat runs agree.

Report: one summary table with a row per model, a per-tier breakdown, and the recommended role map.

### Making it fast without dropping anything
Sorted by how much time each one saves:
1. **One load per model**: every question in a row, then unload. No swapping back and forth.
2. **Shared prompt prefix**: every question starts with the same Bible and contract block, so llama-server reuses the cached prefill instead of reading it again each time.
3. **Reasoning budget per tier**: about 2k tokens for easy questions, 4k for medium, 8k for hard. Most of the time goes into reasoning tokens.
4. **Stop at the end of the code**: generation stops once the answer's code block closes, with no rambling after it.
5. **Smart repeats**: everything runs once at temp 0.6. Only questions where a model was borderline, plus the top 3 models on the hard tiers, run twice more. Consistency is still measured where it matters, at about a third of the cost of tripling everything.
6. **Compile and grade off the GPU**: quick checks and batched compiles run on the CPU while the next model is generating. Claude's blind scoring happens the next morning, outside GPU time.
7. **Early cut**: if a model fails most of tiers 1-2, it skips the hard-tier repeats. It still answers every question once, so its row stays complete.
8. Optional, test first: two parallel slots (`-np 2`) can raise throughput if VRAM allows the extra context.

Rough estimate, unverified: 8 models × 25 questions in about 4-6 hours instead of 10+. The first model's run will give real numbers.

### Example report (made-up numbers, for layout only)

**Summary**
| Model | Quant | Solved /25 | Compiles (1st try / total) | Avg time per answer | Logic /10 | Invented names | Rule breaks | Bug hunt (real / false) | tok/s | Consistency | Role |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Model A | Q4_K_M | 22 | 18 / 27 | 48 s | 8.4 | 0 | 1 | 7 / 2 | 31 | 95% | Coder |
| Model B | IQ4_XS | 20 | 15 / 31 | 36 s | 7.9 | 1 | 2 | 8 / 1 | 38 | 90% | Bug hunter |
| Model C | Q5_K_M | 19 | 16 / 26 | 71 s | 8.1 | 0 | 0 | 5 / 4 | 22 | 92% | Fixer |
| Model D | IQ3_S | 17 | 12 / 33 | 55 s | 7.0 | 3 | 3 | 6 / 3 | 29 | 80% | Reviewer pool |
| Model E | Q4_K_M | 15 | 11 / 35 | 42 s | 6.5 | 2 | 4 | 4 / 6 | 34 | 75% | Reviewer pool |
| Model F | Q6_K | 14 | 10 / 30 | 29 s | 6.8 | 1 | 2 | 3 / 2 | 45 | 85% | Docs |
| Model G | IQ3_M | 11 | 7 / 38 | 64 s | 5.2 | 5 | 6 | 2 / 9 | 25 | 60% | Reviewer pool |
| Model H | Q4_K_S | 8 | 5 / 40 | 33 s | 4.1 | 7 | 8 | 1 / 11 | 40 | 55% | Dropped |

**By tier (solved / questions)**
| Model | T1 Easy (5) | T2 Traps (5) | T3 Fix (5) | T4 Bug hunt (5) | T5 Hard (5) |
|---|---|---|---|---|---|
| Model A | 5 | 5 | 4 | 4 | 4 |
| Model B | 5 | 4 | 3 | 5 | 3 |
| Model C | 5 | 4 | 5 | 3 | 2 |
| ... | | | | | |

**Per model**: load time, total run time, reasoning tokens (avg and max), VRAM peak, context used, and links to each answer in the Zulip topic.

**Role map**: the suggested `models_config.json` change, shown as a diff for approval.

### Chat platform update (2026-10-19)
- The user already runs Cinny (an `alpine-cinny` container). Cinny is a Matrix web client, so this switches the plan from Zulip to **Matrix**. No new server is needed if a Matrix homeserver is already running behind it.
- The relay posts through the Matrix client API: a bot account with an access token, one `PUT .../rooms/{room}/send/m.room.message` per message, and an HTML `formatted_body` for code blocks.
- Layout: one room per stream (runs, benchmark, peer review), with one thread per run if the client handles threads well. Otherwise, one room per run.
- Reasoning: a code block. To collapse it, a Matrix spoiler or a `<details>` block if the client renders it, otherwise an attached `.txt` file. To verify in Cinny.
- iPhone: Cinny has no native iOS app. Use it as a web app from Safari's home screen, or use Element X or FluffyChat on the same homeserver. Push notifications need testing.
- Open question: which homeserver (Synapse, Conduit, conduwuit or Tuwunel)?

### Cinny checked (cinnyapp/cinny at eff1f48, 2026-10-15)
- **UnrealScript highlighting is built in**: Prism with `prism-unrealscript` (src/app/plugins/react-prism). The relay sends `<pre><code class="language-unrealscript">`.
- **Code blocks over 14 lines collapse automatically** to a short scroll box with an expand button and a Copy button (`CodeBlock` in src/app/plugins/react-custom-html-parser.tsx). So reasoning in a code block is collapsed by default. No spoiler or file is needed.
- **Custom label on a code block** (`data-label`), for example "swift · reasoning" or "ap · answer".
- `<details>`/`<summary>` and spoilers are allowed by the sanitizer (src/app/utils/sanitize.ts), so they're available if needed.
- **Threads**: "Reply in Thread" exists, but I found no separate thread panel, so threads may be awkward to read.
- Homeserver: any one works. The relay only needs a bot account and its access token.

### Layout decided
- A Matrix Space "Echolon" containing 3 rooms: `runs`, `benchmark`, `peer-review`.
- Each run starts with a bold header message (run name, model, task count) and ends with a summary message. No threads, because Cinny reads best as a flat timeline and long blocks collapse anyway.
- Web first. The phone app is decided later.

### Change of order (2026-10-19)
- No waiting for PR #7. ap is too weak for review and bug hunting, so finding a replacement comes first.
- New order: 1) benchmark question set (Claude drafts, user approves), 2) the user picks candidate models, 3) bench harness + Matrix relay, 4) overnight run, 5) new role map. Peer review comes later.
- The benchmark uses `main` (M4-M6 merged) as ground truth. PR #7 stays open as it is.
- Weighting: reviewer and bug-hunter scores now matter as much as coder, since those are ap's roles.
