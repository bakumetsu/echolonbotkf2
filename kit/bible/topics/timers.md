# Topic: timers

- `SetTimer(Rate, bLoop, 'FuncName');` SDK Actor.uc:2036. Optional 4th arg: target object; then the
  function lives on that object.
- `ClearTimer('FuncName');` `IsTimerActive('FuncName')`, `GetTimerCount('FuncName')`,
  `GetTimerRate('FuncName')`.
- The timer function takes no parameters and must exist (validator U009). Never name a dropped
  legacy timer (CaptainPathTimer, CaptainPathLoop, RebuildHierarchy: D5).
- Re-calling SetTimer on an active timer restarts it (UNVERIFIED: native); guard with `IsTimerActive`.
- Timers call the current state's version of the function if the state overrides it (UNVERIFIED).
- Rate 0 or ClearTimer stops it. Clear every looping timer in Destroyed/EndState paths that own it.
- Deadline watchdog pattern (W4) for latent calls with no SDK timeout:
  `SetTimer(2.0, false, 'LandingDeadline');` before `WaitForLanding();`, `ClearTimer('LandingDeadline');`
  after; the deadline function forces the state forward (GotoState + let the hub re-evaluate).
- Single-writer: `NextShoppingTime` is hub-owned; `WdLastHubContactTime` is a multi-writer stamp
  (doc 6.2). Timers must respect the same writer rules as normal functions.
