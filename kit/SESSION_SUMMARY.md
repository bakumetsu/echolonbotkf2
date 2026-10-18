# What we built in this session, in plain English

## The big picture
You want to rewrite your KF2 bot mod from scratch, in a new repo, with local AI models doing most of the typing. Big local models can't hold a 3,000-line UnrealScript file in their head, and they make confident mistakes. So before writing any mod code, we built a **kit**: a set of small Python tools that slice the work into tiny pieces, hand each piece to the model with only what it needs, and check the result automatically.

The rule throughout is that **Python decides, and the model only writes**. No AI picks what to do next. The kit picks one function, gives the model a short, budgeted prompt, and refuses anything that breaks the rules.

## What exists now

**1. The new mod's shape is decided (but not written).**
- The new package is **EcholonBot**, with 9 classes (EcholonMut, EcholonBot, EcholonBotBase and so on), renamed from the old ones.
- `contracts.json` lists every class, variable, function signature and state the rewrite will have: 447 functions and 20 states.
- Each function is assigned to a milestone (M1 to M6). Dead code from the old mod is dropped.

**2. A skeleton generator.** One command writes all 9 `.uc` files with every function as an empty stub, marked with the milestone that will fill it. The skeleton should compile as-is. That is step one of M1.

**3. A knowledge pack for the model (the "Bible").**
- A ~1,500-token rulebook of UnrealScript gotchas, such as states, latent functions, no ternaries and arrays.
- Small topic sheets, plus SDK facts checked against your real SDK.
- The old mod's design doc can be sliced by system, so the model reads 500 relevant tokens instead of the whole document.

**4. Automatic checks the model's code must pass.**
- A **validator** catches UnrealScript mistakes (14 rules).
- A **boundary auditor** makes sure only the owning function writes each shared variable. That rule was the source of many old bugs.
- A **compile loop** runs KFEditor, reads the log, and turns the first error into a small fix request.
- A **log checker** reads the game log after a test match and reports "Accessed None" errors in *our* code only. Your current log has 11k of them, all from the base game.

**5. The runner (`agent_runner.py`).** This ties it all together:
1. `plan M1` makes the task list (70 tasks for M1).
2. `run M1` does each task in order: build the prompt, ask the coder model, splice the function in, validate it, audit it, compile it, and let the debugger model fix compile errors up to 3 times.
3. If a task still fails, it writes `escalation.md`. That is a short, self-contained page you can paste into another AI (Opus, GPT, whatever) for review, which matches your "manual review" answer.
4. A failed task leaves your source file exactly as it was.

**6. llama-swap is installed.** `config.yaml` and `Start-LlamaSwap.bat` are in `D:\LLM Storage\llama.cpp`. llama-swap keeps one model in VRAM at a time and swaps automatically between them:
- `swift` (Swift 1.5) writes and fixes code.
- `ap` writes docs.

**7. Tests.** 61 automated tests cover all of this.

## What's still unproven
- **The compile error line format.** Your log was a successful compile, so the kit guesses the format of an *error* line. The first real error will confirm it.
- **llama-swap paths.** Whether llama-swap is happy with the forward-slash paths in the config.
- **The models themselves.** So far only a fake "mock" model has run the pipeline. Real quality shows on the first M1 run.

## Before the next session (M1), on your PC
1. **Pull the repo.** Clone or pull the repo into `Documents\My Games\KillingFloor2\KFGame\Src\EcholonBot`.
2. **Install the Python packages:** `pip install httpx jsonschema pytest`.
3. **Check the tests:** `python -m pytest -q kit\tests` should show all passing.
4. **Index your SDK once:** `python kit\tools\sdk_index.py`.
5. **Start the models:**
   - Close your old .bat server.
   - Double-click `D:\LLM Storage\llama.cpp\Start-LlamaSwap.bat`.
   - Then run `python kit\tools\backend_check.py`. It should list `swift` and `ap` and get a reply from each.
6. **Register the package:** add `ModPackages=EcholonBot` under `[ModPackages]` in `KFGame\Config\KFEditor.ini`, as the Steam guide describes.
7. **Write the skeleton:** `python kit\tools\skeleton_gen.py`.
8. **Compile once:** `python kit\tools\compile_loop.py`.
   - If it fails, keep `KFGame\Logs\Launch.log`. That error line is exactly what we need to confirm the format.

Then M1 starts with `python kit\tools\agent_runner.py plan M1` and `run M1 --limit 3`, a small first batch to judge the model's output before letting it run longer.
