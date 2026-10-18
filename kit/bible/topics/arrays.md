# Topic: dynamic and static arrays

- Declare: `var array<int> Nums;` `local array<KFPawn> Seen;` Static: `var int Slots[8];`
- Size: `Nums.Length` (read or write; `Nums.Length = 0;` clears). No .Count/.Size/.Num().
- Add: `Nums.AddItem(5);` `Nums.Insert(i, n);` `Nums.Add(n);` (appends n defaults).
- Remove: `Nums.RemoveItem(5);` (all equal items) `Nums.Remove(i, n);`
- Find: `Nums.Find(5)` -> index or -1. Struct arrays: `DoorPaths.Find('Path', N)` (Base:1478) searches
  by member name.
- Never `array<array<T>>`. Wrap: `struct FRow { var array<int> V; };` then `var array<FRow> Rows;`
- Removing while iterating: iterate backwards, or `Remove(i,1); i--;`. Corpus: Base:1500-1509
  walks `I = DoorPaths.Length - 1` down to 0 and calls `DoorPaths.Remove(I, 1)` (correct pattern).
- Out of range read logs `Accessed array out of bounds` and returns a default; always guard with
  `i < A.Length`.
- Arrays of structs are copied on read: `S = Arr[i]; S.X = 1;` does NOT change Arr; write
  `Arr[i].X = 1;`.
- `foreach Arr(Elem)` and `foreach Arr(Elem, Idx)` iterate dynamic arrays (corpus: `foreach
  TraderList(...)`). Do not add/remove inside.
