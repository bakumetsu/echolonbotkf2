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
