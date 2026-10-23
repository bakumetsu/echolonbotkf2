// EcholonSurveyGrid.uc
// Storage and helpers for the KF2 mutator "survey" tile map.
// Each tile is addressed by (TX, TY, Lvl): TX/TY are tile indices (38 uu wide),
// Lvl is the floor-level band index (160 uu high). Three ints per tile:
//   Key   - packed identity
//   Data  - Kind (bits 0-3) | Flags (bits 4-13) | (ZQ << 14); ZQ = 12-bit floor height
//   Links - 8 directions x 3 bits: bit D = walkable, bits 8+2D,9+2D = level delta (0/1/2)
// One instance lives on the mutator. This class never traces; bots do.

class EcholonSurveyGrid extends Object transient;

const TILE = 38.0;
const LEVEL_H = 160.0;
const SLOTS = 524288;
const SLOT_MASK = 524287;
const MAX_USED = 400000;

const K_FLOOR = 1;
const K_STEEP = 2;
const K_WALL = 3;
const K_OBST = 4;
const K_DROP = 5;
const K_DOOR = 6;

const F_STEP = 16;
const F_CEIL = 32;
const F_HAZARD = 64;
const F_MOVER = 128;
const F_HIDDEN = 256;
const F_EXPANDED = 512;
const F_VISITED = 1024;
const F_ONEWAY = 2048;
const F_UNSAFE = 4096;
const F_BLOCKED = 8192;

var array<int> Keys;
var array<int> Data;
var array<int> Links;
var int Used;
var bool bFull;
var int MinTX;
var int MaxTX;
var int MinTY;
var int MaxTY;
var int MinLvl;
var int MaxLvl;
var array<int> KindCount;
var int HiddenCount;

// Reset all state; arrays are re-allocated to SLOTS zeroed slots.
final function Clear()
{
    Keys.Length = 0;
    Data.Length = 0;
    Links.Length = 0;
    Keys.Length = SLOTS;
    Data.Length = SLOTS;
    Links.Length = SLOTS;
    KindCount.Length = 0;
    KindCount.Length = 16;
    Used = 0;
    bFull = false;
    HiddenCount = 0;
    MinTX = 99999;
    MaxTX = -99999;
    MinTY = 99999;
    MaxTY = -99999;
    MinLvl = 99;
    MaxLvl = -99;
}

// World X/Y -> tile index, clamped to [-2047, 2047].
final function int TileOf(float V)
{
    local int I;
    I = FFloor(V / TILE);
    if (I < -2047) I = -2047;
    if (I > 2047) I = 2047;
    return I;
}

// World Z -> level band index, clamped to [-31, 31].
final function int LevelOf(float Z)
{
    local int I;
    I = Round(Z / LEVEL_H);
    if (I < -31) I = -31;
    if (I > 31) I = 31;
    return I;
}

// Tile index -> world-space center of that tile.
final function float CenterOf(int T)
{
    return (float(T) + 0.5) * TILE;
}

// Pack (TX, TY, Lvl) into a unique Key. Clamps inputs to valid ranges.
final function int MakeKey(int TX, int TY, int Lvl)
{
    local int CTX;
    local int CTY;
    local int CLvl;
    CTX = TX;
    CTY = TY;
    CLvl = Lvl;
    if (CTX < -2047) CTX = -2047;
    if (CTX > 2047) CTX = 2047;
    if (CTY < -2047) CTY = -2047;
    if (CTY > 2047) CTY = 2047;
    if (CLvl < -31) CLvl = -31;
    if (CLvl > 31) CLvl = 31;
    return ((((CTX + 2048) * 4096) + (CTY + 2048)) * 64) + (CLvl + 32) + 1;
}

// Inverse of MakeKey: extract TX.
final function int KeyTX(int Key)
{
    local int K;
    local int T;
    K = Key - 1;
    T = K >> 6;
    return (T >> 12) - 2048;
}

// Inverse of MakeKey: extract TY.
final function int KeyTY(int Key)
{
    local int K;
    local int T;
    K = Key - 1;
    T = K >> 6;
    return (T & 4095) - 2048;
}

// Inverse of MakeKey: extract Lvl.
final function int KeyLvl(int Key)
{
    local int K;
    K = Key - 1;
    return (K & 63) - 32;
}

// Hash a Key to a starting slot in the open-addressing table.
final function int SlotHash(int Key)
{
    return (Key * 40503 + (Key >> 11)) & SLOT_MASK;
}

// Linear-probe search for Key; returns slot index or -1 if absent.
final function int Find(int Key)
{
    local int s;
    local int i;
    s = SlotHash(Key);
    for (i = 0; i < SLOTS; i++)
    {
        if (Keys[s] == Key) return s;
        if (Keys[s] == 0) return -1;
        s = (s + 1) & SLOT_MASK;
    }
    return -1;
}

// Find or create a slot for Key. Returns slot, or -1 when full (sets bFull).
final function int Touch(int Key)
{
    local int s;
    local int i;
    local int tx;
    local int ty;
    local int lvl;
    s = SlotHash(Key);
    for (i = 0; i < SLOTS; i++)
    {
        if (Keys[s] == Key) return s;
        if (Keys[s] == 0)
        {
            if (Used >= MAX_USED)
            {
                bFull = true;
                return -1;
            }
            Keys[s] = Key;
            Used = Used + 1;
            tx = KeyTX(Key);
            ty = KeyTY(Key);
            lvl = KeyLvl(Key);
            if (tx < MinTX) MinTX = tx;
            if (tx > MaxTX) MaxTX = tx;
            if (ty < MinTY) MinTY = ty;
            if (ty > MaxTY) MaxTY = ty;
            if (lvl < MinLvl) MinLvl = lvl;
            if (lvl > MaxLvl) MaxLvl = lvl;
            return s;
        }
        s = (s + 1) & SLOT_MASK;
    }
    return -1;
}

// Return Data for Key, or 0 if the tile is not present.
final function int GetData(int Key)
{
    local int Slot;
    Slot = Find(Key);
    if (Slot < 0) return 0;
    return Data[Slot];
}

// Return Links for Key, or 0 if the tile is not present.
final function int GetLinks(int Key)
{
    local int Slot;
    Slot = Find(Key);
    if (Slot < 0) return 0;
    return Links[Slot];
}

// Store NewData for Key, maintaining KindCount and HiddenCount.
final function PutData(int Key, int NewData)
{
    local int Slot;
    local int OldData;
    Slot = Touch(Key);
    if (Slot < 0) return;
    OldData = Data[Slot];
    if (OldData != 0)
        KindCount[DKind(OldData)] = KindCount[DKind(OldData)] - 1;
    Data[Slot] = NewData;
    KindCount[DKind(NewData)] = KindCount[DKind(NewData)] + 1;
    if ((NewData & F_HIDDEN) != 0 && (OldData & F_HIDDEN) == 0)
        HiddenCount = HiddenCount + 1;
}

// Store NewLinks for Key (no-op if tile missing).
final function PutLinks(int Key, int NewLinks)
{
    local int Slot;
    Slot = Find(Key);
    if (Slot >= 0)
        Links[Slot] = NewLinks;
}

// Set flag bits in the tile's Data (no-op if missing).
final function AddFlags(int Key, int Flags)
{
    local int Slot;
    Slot = Find(Key);
    if (Slot >= 0)
        PutData(Key, Data[Slot] | Flags);
}

// Clear flag bits in the tile's Data (no-op if missing).
final function ClearFlags(int Key, int Flags)
{
    local int Slot;
    Slot = Find(Key);
    if (Slot >= 0)
        PutData(Key, Data[Slot] & (~Flags));
}

// Pack Kind, Flags, and world Z into a single Data int.
final function int PackData(int Kind, int Flags, float Z)
{
    return Kind | (Flags & 16368) | (ZQ(Z) << 14);
}

// World Z -> 12-bit quantised value (2 uu steps, +4096 offset, clamped 0..4095).
final function int ZQ(float Z)
{
    local int I;
    I = Round((Z + 4096.0) / 2.0);
    if (I < 0) I = 0;
    if (I > 4095) I = 4095;
    return I;
}

// 12-bit quantised value -> world Z.
final function float QZ(int Q)
{
    return float(Q) * 2.0 - 4096.0;
}

// Extract the 4-bit Kind from a Data int.
final function int DKind(int D)
{
    return D & 15;
}

// Extract the 10-bit Flags from a Data int.
final function int DFlags(int D)
{
    return D & 16368;
}

// Extract and de-quantise the 12-bit floor height from a Data int.
final function float DZ(int D)
{
    return QZ((D >> 14) & 4095);
}

// Test whether a Flag bit is set in a Data int.
final function bool DHas(int D, int Flag)
{
    return (D & Flag) != 0;
}

// X-component of the 8-direction offset.
final function int DirDX(int D)
{
    switch (D)
    {
    case 0: return 1;
    case 1: return 1;
    case 2: return 0;
    case 3: return -1;
    case 4: return -1;
    case 5: return -1;
    case 6: return 0;
    case 7: return 1;
    }
    return 0;
}

// Y-component of the 8-direction offset.
final function int DirDY(int D)
{
    switch (D)
    {
    case 0: return 0;
    case 1: return 1;
    case 2: return 1;
    case 3: return 1;
    case 4: return 0;
    case 5: return -1;
    case 6: return -1;
    case 7: return -1;
    }
    return 0;
}

// Test whether direction D is walkable in a Links int.
final function bool LinkOpen(int L, int D)
{
    return (L & (1 << D)) != 0;
}

// Level delta for direction D: 0=same, 1=up, -1=down, 99=a drop (the landing level is the one of the height stored in the drop tile at the same tile).
final function int LinkDelta(int L, int D)
{
    local int C;
    C = (L >> (8 + 2 * D)) & 3;
    if (C == 1) return 1;
    if (C == 2) return -1;
    if (C == 3) return 99;
    return 0;
}

// Open direction D with the given level delta, return modified Links.
final function int LinkSet(int L, int D, int Delta)
{
    local int Code;
    local int Mask;
    Code = 0;
    if (Delta == 1) Code = 1;
    else if (Delta == -1) Code = 2;
    else if (Delta == 99) Code = 3;
    Mask = (1 << D) | (3 << (8 + 2 * D));
    return (L & (~Mask)) | (1 << D) | (Code << (8 + 2 * D));
}

// Close direction D, return modified Links.
final function int LinkClose(int L, int D)
{
    local int Mask;
    Mask = (1 << D) | (3 << (8 + 2 * D));
    return L & (~Mask);
}

// Human-readable name for a Kind value.
final function string KindName(int K)
{
    switch (K)
    {
    case 1: return "floor";
    case 2: return "steep";
    case 3: return "wall";
    case 4: return "obstacle";
    case 5: return "drop";
    case 6: return "door";
    }
    return "unknown";
}

// Map 0..63 to a single base64 character.
final function string B64Char(int V)
{
    if (V < 26) return Chr(65 + V);
    if (V < 52) return Chr(97 + V - 26);
    if (V < 62) return Chr(48 + V - 52);
    if (V == 62) return "+";
    return "/";
}

// Encode a row of tiles as 5-char chunks; Known receives the count of stored tiles.
final function string RowChunk(int Lvl, int TY, int TX0, int Count, out int Known)
{
    local int i;
    local int TX;
    local int Key;
    local int Slot;
    local int D;
    local int Kind;
    local int Flags;
    local int ZQv;
    local string R;
    R = "";
    Known = 0;
    for (i = 0; i < Count; i++)
    {
        TX = TX0 + i;
        Key = MakeKey(TX, TY, Lvl);
        Slot = Find(Key);
        if (Slot < 0)
        {
            R = R $ ".....";
        }
        else
        {
            D = Data[Slot];
            Kind = DKind(D);
            Flags = DFlags(D);
            ZQv = (D >> 14) & 4095;
            R = R $ Chr(97 + Kind) $ B64Char((Flags >> 4) & 63) $ B64Char((Flags >> 10) & 63) $ B64Char(ZQv & 63) $ B64Char((ZQv >> 6) & 63);
            Known = Known + 1;
        }
    }
    return R;
}
