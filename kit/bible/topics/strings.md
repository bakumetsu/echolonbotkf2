# Topic: strings and names

- Name literal `'PickNextMove'`; string literal `"text"`. They are different types.
- Name parameters (GotoState, IsInState, SetTimer, ClearTimer, IsTimerActive, PlayAnim...) take
  `'Name'`. A string there is a compile error (validator U006).
- Convert: `name("Foo")`, `string(SomeName)`. Comparing `GetStateName() == 'Idle'` is name vs name.
- In defaultproperties both forms parse for name vars: corpus Nav:1497 `FollowExitState="PickNextMove"`.
  In code, always use `'Name'`.
- Concatenate: `"a" $ B` (no space), `"a" @ B` (adds one space). `$=`/`@=` append in place.
- Numbers to text: `string(I)`; text to number: `int(S)`, `float(S)`. Corpus: Mut:2618
  `byte(int(Mid(MutateString, 11)))`.
- Useful: `Len(S)`, `Mid(S, i, n)`, `Left(S, n)`, `Right(S, n)`, `InStr(S, Sub)` (-1 if absent),
  `Caps(S)`, `Locs(S)`, `Repl(S, From, To)`, `ParseStringIntoArray(S, Arr, ",", true)`.
- Logging: `` `log("[Tag]" @ string(Name) @ "msg"); `` (Nav:432) is the corpus macro form.
