# Topic: states and label code

- Shape: `[auto] [simulated] state Name [extends Parent] { ignores A, B; functions/events; Label: code }`.
  Functions and events come first; labels and latent code come last (after the first label, no
  more function declarations).
- `ignores E1, E2;` makes those events/functions do nothing while in this state. Corpus: Bot:956
  `ignores CheckGrabbed;`, Bot:1194 `ignores FinishedMove;`.
- `state X extends Y` inherits Y's functions AND labels; override by redeclaring. Corpus: Bot:485
  `state DoObjective extends Roaming`.
- `event BeginState(Name PreviousStateName)` / `event EndState(Name NextStateName)` run on entry/exit.
- In-state override that still wants the class behaviour: `global.F(...)` (Bot:489, Bot:857).
- Label code runs top to bottom; `goto('Label');` loops; `Stop;` ends it; `Sleep(t);` yields.
- Leave with `GotoState('Next'); Stop;` (Nav:1296). `GotoState('Same', 'Label')` restarts at a label;
  that label must exist in the state or its parent.
- `IsInState('S')` is true for S and for states that extend S (UNVERIFIED: native, check in M0b SDK index).
- Functions declared inside a state may `return`; label code may not.
- Follower states (W5): never `GotoState('PickNextMove')` from a follower state; report to the hub
  and let the hub decide (FollowNotifyHub / FollowCheckExit, doc 6.4).
