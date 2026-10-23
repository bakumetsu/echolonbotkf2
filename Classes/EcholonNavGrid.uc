// EcholonNavGrid.uc
// Shared "floor is lava" tile table for EcholonBot path steering.
// A tile is identified by (tile x, tile y, floor band). States: unknown / safe / lava.
// Open-addressing hash table of 8192 slots; when the table is full the oldest
// probed slot is simply overwritten (a full table just forgets old data).
// This class stores data only; the bots perform the traces (Object cannot trace).
// A lookup costs one hash and one compare. Lava marked for a stuck spot expires
// after 60 s so the bot can retry. One instance lives on EcholonMut; every bot
// points to it through its NavGrid var. Tile size is 38 uu (50 uu = 1 m); the
// human collision radius is 40 uu and step height is 35 uu.

class EcholonNavGrid extends Object transient;

const NAV_TILE = 38.0;
const NAV_SLOTS = 8192;
const NAV_UNKNOWN = 0;
const NAV_SAFE = 1;
const NAV_LAVA = 2;

struct GridSlot
{
    var int Key;
    var int State;
    var float FloorZ;
    var float Expire;
};

var array<GridSlot> Slots;
var int Evaluated;
var int EvaluatedLava;

// ---- survey chunks (KFEcholonMapData.ini, see EcholonMapData) ----
// Each 16 x 16 tile chunk of one floor level stays as packed text until a bot comes within 2 chunks of it, then it is unpacked
// into STiles (256 bytes per chunk: 0 = not standable, else 1 + wall_distance * 8 + flags; flags 1 drop edge, 2 narrow, 4 hidden).
// The 8192-slot table above stays for runtime marks (stuck lava) and live evaluations and is always asked first.
const SV_UNKNOWN = 0;      // chunk missing or not unpacked yet: the caller falls back to the live evaluation
const SV_CLEAR = 1;        // standable (the caller reads the wall distance from Dist)
const SV_EDGE = 2;         // drop edge
const SV_HIDDEN = 3;       // standable but a hidden collision was seen here: needs a real trace
const SV_NOFLOOR = 4;      // not standable (wall, obstacle, door or never surveyed)
const SV_PER_FRAME = 2;    // chunks unpacked per frame

var array<int> SKeys;
var array<string> SPacked;
var array<byte> SReady;
var array<byte> SQueued;
var array<byte> STiles;
var array<int> SQueue;
var int SLevelH;
var int SUnpacked;
var int SUnpackedWindow;
var int SMaxFrame;
var bool bSurveyReady;

static final function int ChunkKey(int CX, int CY, int Lvl)
{
    return ((CX + 512) * 1024 + (CY + 512)) * 64 + (Lvl + 32);
}

// Reserve the tile storage for Chunks chunks and forget any earlier survey data.
final function SurveyPrepare(int Chunks, int LevelH)
{
    SKeys.Length = 0;
    SPacked.Length = 0;
    SReady.Length = 0;
    SQueued.Length = 0;
    SQueue.Length = 0;
    STiles.Length = Chunks * 256;
    SLevelH = LevelH;
    SUnpacked = 0;
    SUnpackedWindow = 0;
    SMaxFrame = 0;
    bSurveyReady = false;
}

final function SurveyAddChunk(int CX, int CY, int Lvl, string Packed)
{
    SKeys.AddItem(ChunkKey(CX, CY, Lvl));
    SPacked.AddItem(Packed);
    SReady.AddItem(0);
    SQueued.AddItem(0);
}

// Value 0..63 of a packed tile character ('.' is handled by the caller).
final function int SymbolValue(int A)
{
    if (A >= 65 && A <= 90)
        return A - 65;
    if (A >= 97 && A <= 122)
        return A - 97 + 26;
    if (A >= 48 && A <= 57)
        return A - 48 + 52;
    if (A == 43)
        return 62;
    return 63;
}

// Decode chunk Idx into STiles.
final function UnpackChunk(int Idx)
{
    local string S;
    local int I, J, N, Pos, A, V, K, Base;

    S = SPacked[Idx];
    Base = Idx * 256;
    Pos = 0;
    I = 0;
    while (I < Len(S) && Pos < 256)
    {
        N = 1;
        if (Mid(S, I, 1) == "{")
        {
            J = I + 1;
            N = 0;
            while (J < Len(S) && Mid(S, J, 1) != "}")
            {
                N = N * 10 + (Asc(Mid(S, J, 1)) - 48);
                J++;
            }
            I = J + 1;
        }
        A = Asc(Mid(S, I, 1));
        I++;
        if (A == 46)
        {
            V = 0;
        }
        else
        {
            V = SymbolValue(A) + 1;
        }
        for (K = 0; K < N && Pos < 256; K++)
        {
            STiles[Base + Pos] = byte(V);
            Pos++;
        }
    }
    SReady[Idx] = 1;
    SUnpacked++;
    SUnpackedWindow++;
}

final function SurveyEnqueue(int Idx)
{
    if (SReady[Idx] == 0 && SQueued[Idx] == 0)
    {
        SQueued[Idx] = 1;
        SQueue.AddItem(Idx);
    }
}

// Unpack up to SV_PER_FRAME queued chunks (called once per frame); returns how many were unpacked.
final function int SurveyUnpackStep()
{
    local int N, Idx;

    N = 0;
    while (SQueue.Length > 0 && N < SV_PER_FRAME)
    {
        Idx = SQueue[0];
        SQueue.Remove(0, 1);
        if (SReady[Idx] == 0)
        {
            UnpackChunk(Idx);
            N++;
        }
    }
    if (N > SMaxFrame)
    {
        SMaxFrame = N;
    }
    return N;
}

// Queue every chunk within 2 chunks of Loc, on the floor level of Loc and the ones next to it.
final function SurveyPrefetch(vector Loc)
{
    local int CX, CY, L0, DX, DY, DL, Idx;

    if (!bSurveyReady || SLevelH <= 0)
    {
        return;
    }
    CX = FFloor(float(FFloor(Loc.X / NAV_TILE)) / 16.0);
    CY = FFloor(float(FFloor(Loc.Y / NAV_TILE)) / 16.0);
    L0 = Round(Loc.Z / float(SLevelH));
    for (DX = -2; DX <= 2; DX++)
    {
        for (DY = -2; DY <= 2; DY++)
        {
            for (DL = -1; DL <= 1; DL++)
            {
                Idx = SKeys.Find(ChunkKey(CX + DX, CY + DY, L0 + DL));
                if (Idx >= 0)
                {
                    SurveyEnqueue(Idx);
                }
            }
        }
    }
}

// What the survey says about tile (TX, TY) at floor height RefZ; Dist gets the wall distance (0..7) for SV_CLEAR.
final function int SurveyTile(int TX, int TY, float RefZ, out int Dist)
{
    local int CX, CY, Lvl, Idx, V;

    Dist = 0;
    if (!bSurveyReady || SLevelH <= 0)
    {
        return SV_UNKNOWN;
    }
    CX = FFloor(float(TX) / 16.0);
    CY = FFloor(float(TY) / 16.0);
    Lvl = Round(RefZ / float(SLevelH));
    Idx = SKeys.Find(ChunkKey(CX, CY, Lvl));
    if (Idx < 0)
    {
        return SV_UNKNOWN;
    }
    if (SReady[Idx] == 0)
    {
        SurveyEnqueue(Idx);
        return SV_UNKNOWN;
    }
    V = STiles[Idx * 256 + (TY - CY * 16) * 16 + (TX - CX * 16)];
    if (V == 0)
    {
        return SV_NOFLOOR;
    }
    V--;
    Dist = V / 8;
    if ((V & 4) != 0)
    {
        return SV_HIDDEN;
    }
    if ((V & 1) != 0)
    {
        return SV_EDGE;
    }
    return SV_CLEAR;
}

// A tile inside the first chunk (for the unit-cost benchmark): fills its tile coordinates and floor height; false when there is no chunk.
final function bool SurveySampleTile(out int TX, out int TY, out float Z)
{
    local int K, CX, CY, Lvl;

    if (SKeys.Length == 0)
    {
        return false;
    }
    K = SKeys[0];
    Lvl = (K % 64) - 32;
    K = K / 64;
    CY = (K % 1024) - 512;
    CX = (K / 1024) - 512;
    TX = CX * 16 + 8;
    TY = CY * 16 + 8;
    Z = float(Lvl * SLevelH);
    return true;
}

// Convert a world coordinate to a tile index along one axis.
final function int TileOf(float V)
{
    return FFloor(V / NAV_TILE);
}

// Quantise a Z coordinate into a storey band so stacked floors do not mix.
final function int BandOf(float Z)
{
    return Round(Z / 128.0);
}

// Build a non-zero key below 2^31 from clamped tile coords (+-2000 tiles, about 76000 uu) and the floor band.
final function int MakeKey(int TX, int TY, int Band)
{
    local int CTX, CTY, CB;

    CTX = Clamp(TX, -2000, 2000);
    CTY = Clamp(TY, -2000, 2000);
    CB = Clamp(Band, -30, 30);
    return (((CTX + 2048) * 4096) + (CTY + 2048)) * 64 + (CB + 32) + 1;
}

// Hash a key to a slot index in 0..8191.
final function int SlotOf(int Key)
{
    local int H;
    H = ((Key * 31) ^ (Key / 4096)) & 8191;
    if (H < 0)
    {
        H = -H;
    }
    return H;
}

// Linear-probe lookup; returns state and fills FloorZ when found and not expired.
final function int Lookup(int TX, int TY, int Band, float Now, out float FloorZ)
{
    local int Key, Start, I, SlotIdx;
    local GridSlot S;

    Key = MakeKey(TX, TY, Band);
    Start = SlotOf(Key);
    FloorZ = 0.0;

    for (I = 0; I < 8; I++)
    {
        SlotIdx = (Start + I) & 8191;
        S = Slots[SlotIdx];
        if (S.Key == Key)
        {
            if (S.Expire > 0.0 && Now > S.Expire)
            {
                return NAV_UNKNOWN;
            }
            FloorZ = S.FloorZ;
            return S.State;
        }
        if (S.Key == 0)
        {
            break;
        }
    }
    return NAV_UNKNOWN;
}

// Store or update a tile; probes up to 8 slots for a match or empty slot.
final function Store(int TX, int TY, int Band, int NewState, float FloorZ, float Expire)
{
    local int Key, Start, I, SlotIdx, FirstSlot;
    local bool bFound;
    local GridSlot S;

    Key = MakeKey(TX, TY, Band);
    Start = SlotOf(Key);
    FirstSlot = Start;
    bFound = false;

    for (I = 0; I < 8; I++)
    {
        SlotIdx = (Start + I) & 8191;
        S = Slots[SlotIdx];
        if (S.Key == Key)
        {
            Slots[SlotIdx].Key = Key;
            Slots[SlotIdx].State = NewState;
            Slots[SlotIdx].FloorZ = FloorZ;
            Slots[SlotIdx].Expire = Expire;
            bFound = true;
            break;
        }
        if (S.Key == 0 && !bFound)
        {
            Slots[SlotIdx].Key = Key;
            Slots[SlotIdx].State = NewState;
            Slots[SlotIdx].FloorZ = FloorZ;
            Slots[SlotIdx].Expire = Expire;
            bFound = true;
            break;
        }
        if (I == 0)
        {
            FirstSlot = SlotIdx;
        }
    }

    if (!bFound)
    {
        Slots[FirstSlot].Key = Key;
        Slots[FirstSlot].State = NewState;
        Slots[FirstSlot].FloorZ = FloorZ;
        Slots[FirstSlot].Expire = Expire;
    }

    if (Expire == 0.0)
    {
        Evaluated++;
        if (NewState == NAV_LAVA)
        {
            EvaluatedLava++;
        }
    }
}

// Zero the evaluation counters.
final function ResetCounters()
{
    Evaluated = 0;
    EvaluatedLava = 0;
}

// True when more than 80 percent of recent evaluations produced lava.
final function bool Suspect()
{
    if (Evaluated >= 200 && EvaluatedLava * 10 > Evaluated * 8)
    {
        return true;
    }
    return false;
}

// Wipe every slot and reset counters.
final function Clear()
{
    local int I;

    Slots.Length = NAV_SLOTS;
    for (I = 0; I < NAV_SLOTS; I++)
    {
        Slots[I].Key = 0;
        Slots[I].State = 0;
        Slots[I].FloorZ = 0.0;
        Slots[I].Expire = 0.0;
    }
    ResetCounters();
}
