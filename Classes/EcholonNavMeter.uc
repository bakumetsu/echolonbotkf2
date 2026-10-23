class EcholonNavMeter extends Object transient;
// Counts navigation traces, route searches and reachability checks per frame for all bots.
// Converts raw counts into an estimated microsecond cost using unit costs measured once
// per match by NavBenchmark, and reports a summary every 30 s of game time.
// One instance lives on EcholonMut; every EcholonFollowNavBase bot points to it via NavMeter.
// This is a plain Object with no timers and no logging; EndFrame returns the report text
// (or an empty string) and the mutator decides what to do with it.
// Its own per-frame cost is a few integer and float additions, negligible.

var int FrameTraces, FrameSearches, FrameReaches, FrameSurvey, FrameGrid, FrameUnpack, FrameSaved;
var float UnitTraceUs, UnitSearchUs, UnitReachUs, UnitSurveyUs, UnitGridUs, UnitUnpackUs;
var int TotalFrames, TotalSaved, TotalGrid, TotalUnpack;   // whole match, for NAV_SURVEY_SUMMARY
var float TotalEstUs, TotalMaxEstUs;
var bool bBenchmarked;                                  // true once NavBenchmark has set measured unit costs
var float WindowStart;
var float ReportInterval;
var int WindowFrames, WindowTraces, WindowSearches, WindowReaches, WindowSurvey, WindowGrid, WindowUnpack, WindowSaved;
var float WindowEstUs;
var float WindowMaxEstUs;
var int WindowFramesOverTarget;

final function CountTrace(optional int N)
{
    if (N <= 0)
    {
        N = 1;
    }
    FrameTraces += N;
}

final function CountSearch()
{
    FrameSearches++;
}

final function CountReach()
{
    FrameReaches++;
}

// Survey verdict links set and cleared for one route search (EcholonFollowNavBase.FollowSurveyEdgesBlock).
final function CountSurvey(int N)
{
    FrameSurvey += N;
}

// Grid tile lookups, chunk unpacks and traces a grid answer saved (EcholonFollowNavBase, EcholonMut).
final function CountGrid(int N)
{
    FrameGrid += N;
}

final function CountUnpack(int N)
{
    FrameUnpack += N;
}

final function CountSaved(int N)
{
    FrameSaved += N;
}

final function SetGridUnits(float GridUs, float UnpackUs)
{
    if (GridUs >= 0)
    {
        UnitGridUs = GridUs;
    }
    if (UnpackUs >= 0)
    {
        UnitUnpackUs = UnpackUs;
    }
}

final function SetSurveyUnit(float Us)
{
    if (Us >= 0)
    {
        UnitSurveyUs = Us;
    }
}

final function SetUnitCosts(float TraceUs, float SearchUs, float ReachUs)
{
    if (TraceUs >= 0)
    {
        UnitTraceUs = TraceUs;
    }
    if (SearchUs >= 0)
    {
        UnitSearchUs = SearchUs;
    }
    if (ReachUs >= 0)
    {
        UnitReachUs = ReachUs;
    }
    bBenchmarked = true;
}

final function string UnitCostMessage()
{
    return "NAV_UNIT_COST trace_us=" $ string(UnitTraceUs) $ " search_us=" $ string(UnitSearchUs) $ " reach_us=" $ string(UnitReachUs);
}

// Whole-match numbers: average and worst estimated frame cost in microseconds and the grid totals.
final function string TotalsText()
{
    local int Avg;

    Avg = 0;
    if (TotalFrames > 0)
    {
        Avg = int(TotalEstUs / float(TotalFrames) + 0.5);
    }
    return "avg_us=" $ string(Avg) $ " max_us=" $ string(int(TotalMaxEstUs + 0.5)) $ " frames=" $ string(TotalFrames)
        $ " grid_checks=" $ string(TotalGrid) $ " unpacks=" $ string(TotalUnpack) $ " traces_saved=" $ string(TotalSaved);
}

final function string EndFrame(float Now)
{
    local float E;
    local int Bench;
    local string Msg;

    E = FrameTraces * UnitTraceUs + FrameSearches * UnitSearchUs + FrameReaches * UnitReachUs + FrameSurvey * UnitSurveyUs + FrameGrid * UnitGridUs + FrameUnpack * UnitUnpackUs;

    WindowFrames++;
    WindowTraces += FrameTraces;
    WindowSearches += FrameSearches;
    WindowReaches += FrameReaches;
    WindowSurvey += FrameSurvey;
    WindowGrid += FrameGrid;
    WindowUnpack += FrameUnpack;
    WindowSaved += FrameSaved;
    TotalFrames++;
    TotalEstUs += E;
    if (E > TotalMaxEstUs)
    {
        TotalMaxEstUs = E;
    }
    TotalSaved += FrameSaved;
    TotalGrid += FrameGrid;
    TotalUnpack += FrameUnpack;
    WindowEstUs += E;
    if (E > WindowMaxEstUs)
    {
        WindowMaxEstUs = E;
    }
    if (E > 500.0)
    {
        WindowFramesOverTarget++;
    }
    FrameTraces = 0;
    FrameSearches = 0;
    FrameReaches = 0;
    FrameSurvey = 0;
    FrameGrid = 0;
    FrameUnpack = 0;
    FrameSaved = 0;

    if (WindowStart == 0)
    {
        WindowStart = Now;
        return "";
    }
    if (Now - WindowStart < ReportInterval || WindowFrames == 0)
    {
        return "";
    }

    Bench = 0;
    if (bBenchmarked)
    {
        Bench = 1;
    }

    Msg = "NAV_COST avg_us=" $ string(int(WindowEstUs / WindowFrames + 0.5))
        $ " max_us=" $ string(int(WindowMaxEstUs + 0.5))
        $ " frames=" $ string(WindowFrames)
        $ " traces=" $ string(WindowTraces)
        $ " searches=" $ string(WindowSearches)
        $ " reaches=" $ string(WindowReaches)
        $ " survey_links=" $ string(WindowSurvey)
        $ " grid_checks=" $ string(WindowGrid)
        $ " unpacks=" $ string(WindowUnpack)
        $ " traces_saved=" $ string(WindowSaved)
        $ " over_target=" $ string(WindowFramesOverTarget)
        $ " benchmarked=" $ string(Bench);

    WindowStart = Now;
    WindowFrames = 0;
    WindowTraces = 0;
    WindowSearches = 0;
    WindowReaches = 0;
    WindowSurvey = 0;
    WindowGrid = 0;
    WindowUnpack = 0;
    WindowSaved = 0;
    WindowEstUs = 0;
    WindowMaxEstUs = 0;
    WindowFramesOverTarget = 0;

    return Msg;
}

defaultproperties
{
    ReportInterval=30.0
    UnitTraceUs=3.0
    UnitSearchUs=40.0
    UnitReachUs=17.0
    UnitSurveyUs=0.2
    UnitGridUs=0.3
    UnitUnpackUs=60.0
}
