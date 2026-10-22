// EcholonNavScan - start-of-match link scan state.
// Holds progress (current node / link index) and results (bad-link list, counts)
// for the one-time walk of every NavigationPoint link at match start.
// The actual tracing runs in EcholonMut (an Object cannot call Trace).
// One instance lives on EcholonMut; bots read BadSpecs to block routes.
// Cost is a few vector adds and traces per link, budgeted per frame.
// Links that are door, zed-only, blocked, no-floor, or too narrow are flagged.
// After the scan completes, Summary() formats a one-line report for the log.
class EcholonNavScan extends Object transient;

var array<NavigationPoint> Nodes;
var int NodeIdx;
var int SpecIdx;
var bool bActive;
var bool bDone;
var array<ReachSpec> BadSpecs;
var int Links;
var int Bad;
var int Special;
var int Drops;
var int Doors;
var int Traces;
var float MaxLanding;
var float StartTime;
var float EndTime;
var int BadLogged;

// Reset all progress and counters; caller must fill Nodes before calling this.
final function Begin(float Now)
{
    NodeIdx = 0;
    SpecIdx = 0;
    bActive = true;
    bDone = false;
    StartTime = Now;
    EndTime = 0.0;
    Links = 0;
    Bad = 0;
    Special = 0;
    Drops = 0;
    Doors = 0;
    Traces = 0;
    MaxLanding = 0.0;
    BadLogged = 0;
    BadSpecs.Length = 0;
}

// Advance cursor to next link; returns false and marks scan complete when exhausted.
final function bool NextSpec(out ReachSpec Spec, out NavigationPoint From)
{
    while (NodeIdx < Nodes.Length)
    {
        if (Nodes[NodeIdx] == None)
        {
            NodeIdx++;
            continue;
        }
        if (Nodes[NodeIdx].PathList.Length == 0)
        {
            NodeIdx++;
            continue;
        }
        if (SpecIdx >= Nodes[NodeIdx].PathList.Length)
        {
            NodeIdx++;
            SpecIdx = 0;
            continue;
        }
        Spec = Nodes[NodeIdx].PathList[SpecIdx];
        From = Nodes[NodeIdx];
        SpecIdx++;
        return true;
    }
    bActive = false;
    bDone = true;
    return false;
}

// Record a bad link in BadSpecs (max 800) and increment the bad counter.
final function AddBad(ReachSpec Spec)
{
    Bad++;
    if (BadSpecs.Length >= 800)
    {
        return;
    }
    BadSpecs.AddItem(Spec);
}

// Build and return the one-line scan report; stamps EndTime on first call after done.
final function string Summary(float Now)
{
    local float Secs;
    if (bDone && EndTime == 0.0)
    {
        EndTime = Now;
    }
    if (EndTime > 0.0)
    {
        Secs = EndTime - StartTime + 0.5;
    }
    else
    {
        Secs = Now - StartTime + 0.5;
    }
    return "NAV_SCAN links=" $ string(Links) $ " bad=" $ string(Bad) $ " special=" $ string(Special) $ " drops=" $ string(Drops) $ " doors=" $ string(Doors) $ " traces=" $ string(Traces) $ " maxland=" $ string(int(MaxLanding)) $ " secs=" $ string(int(Secs));
}
