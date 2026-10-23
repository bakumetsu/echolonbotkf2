// EcholonNavBudget: per-frame budget of estimated microseconds and a limit of
// route searches, shared by all bots. One instance lives on EcholonMut; each
// bot points to it via its NavBudget var. A caller asks before it spends; when
// the answer is no it keeps its previous result and asks again later. Callers
// carry a priority; a lower priority cannot consume the tail of the frame
// budget, which is reserved for higher ones. Per-call cost is a few
// comparisons.
class EcholonNavBudget extends Object transient;

const NAV_PRIO_STEER = 0;
const NAV_PRIO_STUCK = 1;
const NAV_PRIO_SCAN = 2;
const NAV_PRIO_GRID = 3;
const NAV_PRIO_COUNT = 4;

var float FrameBudgetUs;
var float Reserve[4];
var int SearchBudget;
var float FrameStamp;
var float UsedUs;
var int SearchesUsed;
var int UsDenied;
var int SearchesDenied;
var int CurRank;                 // rank of the bot asking (0 grunt .. 3 captain, -1 unknown); set by EcholonFollowNavBase before it asks
var int UsDeniedRank[4];
var int SearchesDeniedRank[4];

// Reset per-frame counters when Now advances past the last stamped frame.
final function NewFrameIf(float Now)
{
    if (Now != FrameStamp)
    {
        FrameStamp = Now;
        UsedUs = 0.0;
        SearchesUsed = 0;
    }
}

// Spend CostUs at Prio; the first request of a frame always passes.
final function bool TakeUs(int Prio, float CostUs, float Now)
{
    local int ClampedPrio;

    NewFrameIf(Now);

    if (Prio < 0 || Prio >= NAV_PRIO_COUNT)
    {
        ClampedPrio = NAV_PRIO_COUNT - 1;
    }
    else
    {
        ClampedPrio = Prio;
    }

    if (UsedUs + CostUs <= FrameBudgetUs - Reserve[ClampedPrio] || UsedUs == 0.0)
    {
        UsedUs += CostUs;
        return true;
    }

    UsDenied++;
    if (CurRank >= 0 && CurRank < 4)
    {
        UsDeniedRank[CurRank]++;
    }
    return false;
}

// Consume one route-search slot for this frame.
final function bool TakeSearch(float Now)
{
    NewFrameIf(Now);

    if (SearchesUsed < SearchBudget)
    {
        SearchesUsed++;
        return true;
    }

    SearchesDenied++;
    if (CurRank >= 0 && CurRank < 4)
    {
        SearchesDeniedRank[CurRank]++;
    }
    return false;
}

// Remaining microseconds available at Prio after this frame's spend.
final function float UsLeft(int Prio, float Now)
{
    local int ClampedPrio;
    local float Left;

    NewFrameIf(Now);

    if (Prio < 0 || Prio >= NAV_PRIO_COUNT)
    {
        ClampedPrio = NAV_PRIO_COUNT - 1;
    }
    else
    {
        ClampedPrio = Prio;
    }

    Left = FrameBudgetUs - Reserve[ClampedPrio] - UsedUs;
    if (Left < 0.0)
    {
        Left = 0.0;
    }
    return Left;
}

// Return a summary of denied counts since last call and reset them.
final function string TakeDeniedCounts()
{
    local string S;

    local int I;

    S = "denied_us=" $ UsDenied $ " denied_search=" $ SearchesDenied
        $ " denied_us_rank=" $ UsDeniedRank[0] $ "/" $ UsDeniedRank[1] $ "/" $ UsDeniedRank[2] $ "/" $ UsDeniedRank[3]
        $ " denied_search_rank=" $ SearchesDeniedRank[0] $ "/" $ SearchesDeniedRank[1] $ "/" $ SearchesDeniedRank[2] $ "/" $ SearchesDeniedRank[3];
    UsDenied = 0;
    SearchesDenied = 0;
    for (I = 0; I < 4; I++)
    {
        UsDeniedRank[I] = 0;
        SearchesDeniedRank[I] = 0;
    }
    return S;
}

defaultproperties
{
    FrameBudgetUs=150.0
    SearchBudget=1
    Reserve(0)=0.0
    Reserve(1)=0.0
    Reserve(2)=30.0
    Reserve(3)=60.0
}
