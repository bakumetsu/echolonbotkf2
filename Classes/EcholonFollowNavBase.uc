class EcholonFollowNavBase extends AIController abstract;

enum EFollowAction { FA_Hold, FA_Direct, FA_Path, FA_Escape, FA_Yield, FA_Wait, FA_GiveUp };

enum EFollowStatus { FS_Idle, FS_Following, FS_Arrived, FS_Blocked, FS_LeaderLost, FS_LeaderTeleported };

var bool bEnableAdvancedLocomotion;
var Controller FollowLeaderCtrl;
var Pawn FollowLeaderPawn;
var vector FollowLeaderLastSampleLoc;
var float FollowLeaderLastSampleTime;
var float FollowLeaderInvalidSince;
var float FollowLeaderGraceTime;
var float FollowLeaderTeleportDist;
var float FollowLeaderTeleportSpeed;
var bool bFollowLeaderJumped;
var int FollowSlotIndex;
var int FollowSlotCount;
var name FollowExitState;
var bool bFollowExitPending;
var float FollowBaseOffset;
var float FollowSlotRingStep;
var float FollowResumeMargin;
var float FollowZTolerance;
var bool bFollowArrived;
var bool bFollowOrderAnchorActive;
var vector FollowOrderAnchorLoc;
var float FollowWatchdogPeriod;
var float FollowPhaseJitter;
var float FollowReachIntervalDirect;
var float FollowReachIntervalPath;
var float FollowNextReachCheckTime;
var bool bFollowReachStable;
var bool bFollowReachKnown;
var int FollowReachFailStreak;
var int FollowReachFailsToPath;
var float FollowMinLoopSleep;
var float FollowInterruptMinGap;
var float FollowNextInterruptTime;
var bool bFollowDispatchPending;
var float FollowPathMinInterval;
var float FollowNextPathTime;
var float FollowPathFailBackoff;
var float FollowPathFailBackoffMin;
var float FollowPathFailBackoffMax;
var float FollowRepathDistance;
var float FollowNodeRepathDistSq;
var float FollowForcePathDuration;
var float FollowForcePathUntil;
var float FollowRepathPauseUntil;
var vector FollowLastLeaderPathLoc;
var vector FollowLastPawnTargetPathLoc;
var array<Actor> FollowRoute;
var int FollowRouteIdx;
var int FollowMaxRouteNodes;
var bool bFollowRouteStale;
var bool bFollowMoveActive;
var bool bFollowDirectActive;
var float FollowMoveStartTime;
var float FollowLegTimeout;
var vector FollowStuckRefLoc;
var float FollowStuckRefTime;
var float FollowStuckWindow;
var float FollowStuckMinMove;
var Actor FollowNodeLast;
var int FollowSameNodeCount;
var int FollowSameNodeLimit;
var Actor FollowLastWall;
var float FollowLastWallTime;
var float FollowWallWindowStart;
var int FollowWallHitCount;
var int FollowWallHitThreshold;
var float FollowWallWindow;
var float FollowWallDebounce;
var float FollowLastBumpTime;
var float FollowNextBumpReactTime;
var float FollowBumpCooldown;
var float FollowYieldDist;
var float FollowYieldHold;
var float FollowYieldTimeout;
var float FollowYieldEndTime;
var bool bFollowYieldPending;
var bool bFollowYielding;
var vector FollowYieldAway;
var vector FollowYieldPoint;
var bool bFollowEscaping;
var vector FollowEscapeNormal;
var float FollowEscapeUntil;
var float FollowEscapeDuration;
var int FollowRetries;
var int FollowRetriesBlockAt;
var int FollowRetriesGiveUpAt;
var vector FollowRetryAnchorLoc;
var float FollowRetryResetDist;
var int FollowBlocksThisEpisode;
var float FollowGiveUpHold;
var EFollowAction FollowAction;
var Actor FollowNode;
var float FollowWaitTime;
var EFollowStatus FollowStatus;
var EcholonNavMeter NavMeter;      // shared nav cost counter, set by EcholonMut.RegisterBot
var EcholonNavBudget NavBudget;    // shared per-frame nav budget, set by EcholonMut.RegisterBot
var EcholonNavScan NavScan;        // start-of-match link scan result (bad links), set by EcholonMut.RegisterBot
var EcholonNavGrid NavGrid;           // shared tile table, set by EcholonMut.RegisterBot
var bool bNavGridOn;                  // true while the grid steers this bot (set by the owner class)
var vector NavGridDir;                // last direction the grid chose
var float NavGridKeepUntil;           // keep NavGridDir until this game time unless it becomes blocked
var float NavGridOffUntil;            // grid disabled for this bot until this time (suspect data)
var int NavGridEvals;                 // tiles evaluated by this bot (for logs)
var float NavGridLogTime;             // last time a bend log line was written (2 s throttle)
var float FollowRampStart; // game time the pawn last started from a stop
var float FollowRampUpTime; // seconds to ramp from min pct to full speed
var float FollowRampMinPct; // minimum speed fraction at ramp start
var float FollowCornerSlowDist; // uu distance from next node to begin corner slow
var float FollowCornerMinPct; // minimum speed fraction during corner slow
var float FollowCornerAngle; // degree threshold above which corner slow applies
var float FollowSeparationDist; // 2D radius (uu) within which squadmates repel
var float FollowSeparationGain; // multiplier applied to the accumulated push
var vector FollowSteerCachePoint;  // last steer point computed
var Actor FollowSteerCacheNode;    // the route node that point was computed for
var float FollowSteerCacheTime;    // when it was computed
var float FollowSteerCacheMaxAge;  // how long a cached steer point may be reused when the budget is out
// Special edges (leap, climb, mantle) this bot found on a planned route; kept out of later routes.
var array<ReachSpec> FollowSpecialSpecs;
// Direct-steer only when the leader is within this height; above it, a ledge or balcony is likely in between.
var float FollowDirectMaxZ;
var bool bFollowSavedCanJump;
var int FollowPlanDepth;  // nesting guard so an inner Begin/End can't lose the saved bCanJump
// Bad-edge memory (nav redesign N1): edges this bot failed to walk. Parallel arrays, max FollowBadEdgeMax rows.
// A row is blocked (ReachSpec.BlockedBy) only for the length of this bot's own search; rows expire by time.
var array<ReachSpec> FollowBadSpecs;
var array<float> FollowBadUntil;
var array<int> FollowBadStrikes;
var int FollowBadEdgeMax;
var float FollowBadBaseTime;
var float FollowBadMaxTime;
// Stuck ladder state for the edge being walked: level 1 backs off and retries it, level 2 strikes it.
var ReachSpec FollowLadderSpec;
var int FollowLadderCount;
var float FollowBackoffDist;
// Path follower (nav redesign N2): lookahead, pass-through arrival, wall feelers.
var int FollowLookahead;
var float FollowArriveRadius;
var float FollowFeelerAngle;
var float FollowFeelerPush;
var float FollowKneeHeight;
var float FollowFloorDrop;
// Breadcrumbs (nav redesign N3): the nav points this bot actually walked, newest last. A follower plans to
// the newest crumb of its leader instead of chasing the leader pawn.
var array<NavigationPoint> FollowCrumbs;
var int FollowCrumbMax;
var float FollowCrumbNextTime;
var float FollowCrumbInterval;
var NavigationPoint FollowCrumbGoal;
var int FollowCrumbMaxLag;


// Log id for this bot: "EcholonBot_3(Widow)", the in-game name without its rank tag. kit/tools/log_reader.py reads it.
function string LogTag()
{
    local string N;
    local int BracketsEnd;

    if (PlayerReplicationInfo == None || PlayerReplicationInfo.PlayerName == "")
    {
        return string(Name);
    }
    N = PlayerReplicationInfo.PlayerName;
    if (Left(N, 1) == "[")
    {
        BracketsEnd = InStr(N, "]");
        if (BracketsEnd >= 0)
        {
            N = Mid(N, BracketsEnd + 1);
        }
    }
    if (Left(N, 1) == " ")
    {
        N = Mid(N, 1);
    }
    if (Left(N, 4) == "Bot_")
    {
        N = Mid(N, 4);
    }
    return string(Name) $ "(" $ Repl(N, " ", "_") $ ")";
}

// Every mod log line goes through here as "KEY name=value ..."; EcholonBotBase overrides it with rate limits.
function EchelonLog(string Msg)
{
    `log("[EcholonAudit] " $ LogTag() $ " " $ Msg);
}

function FollowStart(Controller NewLeaderCtrl)
{
    FollowSetLeader(NewLeaderCtrl);

    if (bEnableAdvancedLocomotion)
    {
        GotoState('FollowingLeader');
    }
    else
    {
        GotoState('FollowingLeaderBasic');
    }
}

function FollowSetLeader(Controller NewLeaderCtrl)
{
    FollowLeaderCtrl = NewLeaderCtrl;
    FollowLeaderPawn = None;
    FollowLeaderInvalidSince = 0.0;
    bFollowArrived = false;
    FollowResetEpisode();
}

function FollowSetSlot(int NewSlotIndex, int NewSlotCount)
{
	FollowSlotIndex = Max(NewSlotIndex, 0);
	FollowSlotCount = Max(NewSlotCount, 1);
}

function bool FollowGetOrderAnchor(out vector OutLoc)
{
    OutLoc = vect(0, 0, 0);
    return false;
}

function FollowResetEpisode()
{
    FollowRetries = 0;
    FollowBlocksThisEpisode = 0;
    FollowSameNodeCount = 0;
    FollowNodeLast = None;
    FollowWallHitCount = 0;
    FollowLastWall = None;
    bFollowEscaping = false;
    FollowEscapeNormal = vect(0, 0, 0);
    FollowEscapeUntil = 0.0;
    FollowForcePathUntil = 0.0;
    FollowStuckRefTime = 0.0;
    bFollowYieldPending = false;
    bFollowYielding = false;
    bFollowDispatchPending = false;
    bFollowExitPending = false;

    if (Pawn != None)
    {
        FollowRetryAnchorLoc = Pawn.Location;
    }
    FollowInvalidateRoute();
}

function FollowInvalidateRoute()
{
    FollowRoute.Length = 0;
    FollowRouteIdx = 0;
    bFollowRouteStale = true;
    bFollowReachKnown = false;
    FollowReachFailStreak = 0;
    FollowNextReachCheckTime = 0.0;
}

function float FollowSlotPhase()
{
    return (float(FollowSlotIndex) / FMax(float(Max(FollowSlotCount, 1)), 0.0001)) * FollowWatchdogPeriod;
}

function FollowScheduleWatchdog()
{
    local float IterDelay;

    IterDelay = FollowSlotPhase() + (FRand() * FollowPhaseJitter);
    if (IterDelay < 0.01)
    {
        IterDelay = 0.01;
    }
    SetTimer(IterDelay, false, 'FollowWatchdogBegin');
}

function FollowWatchdogBegin()
{
    SetTimer(FollowWatchdogPeriod, true, 'FollowWatchdog');
    FollowWatchdog();
}

function bool FollowCheckExit()
{
    return false;
}

// ---------------------------------------------------------------- speed ramps and separation (N9)
// Speed ramp member vars

// Returns the maximum 2D speed (uu/s) allowed right now.
function float FollowSpeedCap()
{
    local float Now, Speed, Cap1, Cap2, Dot, AngleDeg, V1Len, V2Len;
    local vector V1, V2;

    Now = WorldInfo.TimeSeconds;
    Speed = VSize2D(Pawn.Velocity);

    if (Speed < 30.0)
    {
        FollowRampStart = Now;
    }

    Cap1 = Pawn.GroundSpeed * FClamp(
        FollowRampMinPct + (1.0 - FollowRampMinPct) * (Now - FollowRampStart) / FollowRampUpTime,
        FollowRampMinPct, 1.0);

    Cap2 = Pawn.GroundSpeed;

    if (FollowRouteIdx + 1 < FollowRoute.Length
        && FollowRoute[FollowRouteIdx] != None
        && FollowRoute[FollowRouteIdx + 1] != None)
    {
        V1 = FollowRoute[FollowRouteIdx].Location - Pawn.Location;
        V1.Z = 0.0;
        V2 = FollowRoute[FollowRouteIdx + 1].Location - FollowRoute[FollowRouteIdx].Location;
        V2.Z = 0.0;
        V1Len = VSize(V1);
        V2Len = VSize(V2);

        if (V1Len > 1.0 && V2Len > 1.0)
        {
            Dot = Normal(V1) dot Normal(V2);
            Dot = FClamp(Dot, -1.0, 1.0);
            AngleDeg = Acos(Dot) * 57.29578;

            if (AngleDeg > FollowCornerAngle)
            {
                Cap2 = Pawn.GroundSpeed * FClamp(V1Len / FollowCornerSlowDist, FollowCornerMinPct, 1.0);
            }
        }
    }

    return FMin(Cap1, Cap2);
}

// Scales horizontal velocity when it exceeds the current speed cap (walking only: sprint speed is above GroundSpeed).
function FollowApplySpeedCap()
{
    local float Cap, Speed;
    local KFPawn KP;

    KP = KFPawn(Pawn);
    if (KP == None || KP.bIsSprinting)
    {
        return;
    }
    Cap = FollowSpeedCap();
    Speed = VSize2D(Pawn.Velocity);

    if (Pawn.Physics == PHYS_Walking && Speed > Cap && Speed > 1.0)
    {
        Pawn.Velocity.X *= Cap / Speed;
        Pawn.Velocity.Y *= Cap / Speed;
    }
}

// Separation member vars

// Blends a separation push into the given unit movement direction.
function vector FollowSeparationPush(vector Dir)
{
    local vector Push, Away, Result;
    local float Len;
    local KFPawn_Human P;

    Push = vect(0.0, 0.0, 0.0);

    foreach WorldInfo.AllPawns(class'KFPawn_Human', P, Pawn.Location, FollowSeparationDist)
    {
        if (P == Pawn || !P.IsAliveAndWell())
        {
            continue;
        }

        Away = Pawn.Location - P.Location;
        Away.Z = 0.0;
        Len = VSize(Away);

        if (Len < 1.0)
        {
            Away = -Dir;
            Len = 1.0;
        }

        Push += (Away / Len) * (1.0 - FMin(Len, FollowSeparationDist) / FollowSeparationDist);
    }

    if (VSize(Push) < 0.001)
    {
        return Dir;
    }

    Result = Dir + Push * FollowSeparationGain;
    Result.Z = Dir.Z;
    return Normal(Result);
}

// ---------------------------------------------------------------- floor is lava grid (N10)
// Evaluate one tile with up to 6 traces and store the result in NavGrid.
function int NavGridEval(int TX, int TY, float RefZ, float Now)
{
    local vector C, Top, Bottom, P, End, HitLoc, HitNorm, Dir;
    local float Floor;
    local int TileState, I;
    local Actor HitActor;

    C.X = (TX + 0.5) * class'EcholonNavGrid'.const.NAV_TILE;
    C.Y = (TY + 0.5) * class'EcholonNavGrid'.const.NAV_TILE;
    C.Z = 0.0;
    Floor = RefZ;

    // 1. Floor trace
    Top.X = C.X;
    Top.Y = C.Y;
    Top.Z = RefZ + 70.0;
    Bottom.X = C.X;
    Bottom.Y = C.Y;
    Bottom.Z = RefZ - 110.0;
    NavCountTrace();
    HitActor = Trace(HitLoc, HitNorm, Bottom, Top, false);
    if (HitActor == None || HitNorm.Z < 0.7)
    {
        TileState = class'EcholonNavGrid'.const.NAV_LAVA;
        NavGrid.Store(TX, TY, NavGrid.BandOf(RefZ), TileState, Floor, 0.0);
        NavGridEvals++;
        return TileState;
    }
    Floor = HitLoc.Z;

    // 2. Body trace in four horizontal directions
    TileState = class'EcholonNavGrid'.const.NAV_SAFE;
    for (I = 0; I < 4; I++)
    {
        Dir.X = 0.0;
        Dir.Y = 0.0;
        Dir.Z = 0.0;
        if (I == 0) { Dir.X = 1.0; }
        else if (I == 1) { Dir.X = -1.0; }
        else if (I == 2) { Dir.Y = 1.0; }
        else { Dir.Y = -1.0; }
        P.X = C.X;
        P.Y = C.Y;
        P.Z = Floor + 40.0;
        End.X = P.X + Dir.X * 36.0;
        End.Y = P.Y + Dir.Y * 36.0;
        End.Z = P.Z;
        NavCountTrace();
        HitActor = Trace(HitLoc, HitNorm, End, P, true);
        if (HitActor != None)
        {
            if (Pawn(HitActor) == None && KFDoorActor(HitActor) == None)
            {
                TileState = class'EcholonNavGrid'.const.NAV_LAVA;
                break;
            }
        }
    }

    // 3. Ceiling trace
    if (TileState == class'EcholonNavGrid'.const.NAV_SAFE)
    {
        Bottom.X = C.X;
        Bottom.Y = C.Y;
        Bottom.Z = Floor + 8.0;
        Top.X = C.X;
        Top.Y = C.Y;
        Top.Z = Floor + 150.0;
        NavCountTrace();
        HitActor = Trace(HitLoc, HitNorm, Top, Bottom, false);
        if (HitActor != None)
        {
            TileState = class'EcholonNavGrid'.const.NAV_LAVA;
        }
    }

    NavGrid.Store(TX, TY, NavGrid.BandOf(RefZ), TileState, Floor, 0.0);
    NavGridEvals++;
    return TileState;
}

// Return the cached (or freshly evaluated) state of the tile containing Loc.
function int NavGridTile(vector Loc, float RefZ, float Now, optional bool bEval)
{
    local int TX, TY, Band, TileState;
    local float FloorZ;

    TX = NavGrid.TileOf(Loc.X);
    TY = NavGrid.TileOf(Loc.Y);
    Band = NavGrid.BandOf(RefZ);
    TileState = NavGrid.Lookup(TX, TY, Band, Now, FloorZ);
    if (TileState == class'EcholonNavGrid'.const.NAV_UNKNOWN && bEval)
    {
        if (NavBudget == None || NavMeter == None || NavBudget.TakeUs(class'EcholonNavBudget'.const.NAV_PRIO_GRID, 6.0 * NavMeter.UnitTraceUs, Now))
        {
            return NavGridEval(TX, TY, RefZ, Now);
        }
    }
    return TileState;
}

// Walk tile centres along Dir; return count of consecutive clear tiles.
function int NavGridRayClear(vector Dir, float RefZ, float Now, int MaxTiles, bool bEval)
{
    local int I, TileState, TX, TY, Band;
    local float FloorZ, PrevFloorZ;
    local bool bHasPrev;
    local vector Loc;

    PrevFloorZ = 0.0;
    bHasPrev = false;

    for (I = 1; I <= MaxTiles; I++)
    {
        Loc.X = Pawn.Location.X + Dir.X * I * class'EcholonNavGrid'.const.NAV_TILE;
        Loc.Y = Pawn.Location.Y + Dir.Y * I * class'EcholonNavGrid'.const.NAV_TILE;
        Loc.Z = RefZ;
        TileState = NavGridTile(Loc, RefZ, Now, bEval);
        if (TileState == class'EcholonNavGrid'.const.NAV_LAVA)
        {
            return I - 1;
        }
        if (TileState == class'EcholonNavGrid'.const.NAV_SAFE)
        {
            TX = NavGrid.TileOf(Loc.X);
            TY = NavGrid.TileOf(Loc.Y);
            Band = NavGrid.BandOf(RefZ);
            NavGrid.Lookup(TX, TY, Band, Now, FloorZ);
            if (bHasPrev && Abs(FloorZ - PrevFloorZ) > 35.0)
            {
                return I - 1;
            }
            PrevFloorZ = FloorZ;
            bHasPrev = true;
        }
    }
    return MaxTiles;
}

// Choose the walk direction, bending around lava when the wanted path is blocked.
function vector NavGridSteer(vector WantDir)
{
    local float Now, RefZ, C0, BestScore, BestC, BestAngle;
    local vector BestDir, H, R;
    local int I, C;
    local float Deg, Rad, CosA, SinA;
    local int Angles[8];

    Now = WorldInfo.TimeSeconds;

    if (NavGrid == None || !bNavGridOn || Pawn == None)
    {
        return WantDir;
    }
    if (Now < NavGridOffUntil)
    {
        return WantDir;
    }
    if (NavGrid.Suspect())
    {
        NavGridOffUntil = Now + 60.0;
        NavGrid.ResetCounters();
        EchelonLog("NAV_GRID_SUSPECT lava_pct=high");
        return WantDir;
    }

    RefZ = Pawn.Location.Z - Pawn.GetCollisionHeight();

    // Keep: re-use the last bend direction if still clear.
    if (Now < NavGridKeepUntil && NavGridRayClear(NavGridDir, RefZ, Now, 3, false) >= 3)
    {
        return NavGridDir;
    }

    // Open space: wanted direction is clear, grid sleeps.
    C0 = float(NavGridRayClear(WantDir, RefZ, Now, 8, true));
    if (C0 >= 6.0)
    {
        NavGridKeepUntil = 0.0;
        return WantDir;
    }

    // Try rotated headings.
    Angles[0] = 30;
    Angles[1] = -30;
    Angles[2] = 60;
    Angles[3] = -60;
    Angles[4] = 90;
    Angles[5] = -90;
    Angles[6] = 120;
    Angles[7] = -120;

    BestScore = -1000.0;
    BestC = -1.0;
    BestAngle = 0.0;
    BestDir = WantDir;

    for (I = 0; I < 8; I++)
    {
        Deg = float(Angles[I]);
        Rad = Deg * 0.0174533;
        CosA = Cos(Rad);
        SinA = Sin(Rad);
        H.X = WantDir.X * CosA - WantDir.Y * SinA;
        H.Y = WantDir.X * SinA + WantDir.Y * CosA;
        H.Z = 0.0;
        C = NavGridRayClear(H, RefZ, Now, 8, true);
        R.X = 10.0 * float(C) - Abs(Deg) * 0.1;
        if (R.X > BestScore)
        {
            BestScore = R.X;
            BestC = float(C);
            BestAngle = Deg;
            BestDir = H;
        }
    }

    if (BestC < C0 + 2.0)
    {
        return WantDir;
    }

    NavGridDir = BestDir;
    NavGridKeepUntil = Now + 0.5;
    if (Now - NavGridLogTime >= 2.0)
    {
        EchelonLog("NAV_GRID_BEND clear0=" $ string(int(C0)) $ " clear=" $ string(int(BestC)) $ " angle=" $ string(int(BestAngle)));
        NavGridLogTime = Now;
    }
    return BestDir;
}

// Marks the tile 1.5 tiles ahead of the pawn along unit Dir as lava for 60 s (a spot where a bot got stuck).
function NavGridMarkStuck(vector Dir)
{
    local vector Loc;

    if (NavGrid == None || !bNavGridOn || Pawn == None || VSizeSq(Dir) < 0.25)
    {
        return;
    }
    Loc = Pawn.Location + Dir * 57.0;
    NavGrid.Store(NavGrid.TileOf(Loc.X), NavGrid.TileOf(Loc.Y), NavGrid.BandOf(Pawn.Location.Z - Pawn.GetCollisionHeight()),
        class'EcholonNavGrid'.const.NAV_LAVA, 0.0, WorldInfo.TimeSeconds + 60.0);
}

// ---------------------------------------------------------------- nav budget (N7)
// True when a route search is permitted this frame.

function bool NavAllowSearch()
{
    if (NavBudget == None)
    {
        return true;
    }
    return NavBudget.TakeSearch(WorldInfo.TimeSeconds);
}

// True when a reachability check is permitted this frame.
function bool NavAllowReach()
{
    if (NavBudget == None || NavMeter == None)
    {
        return true;
    }
    return NavBudget.TakeUs(class'EcholonNavBudget'.const.NAV_PRIO_STEER, NavMeter.UnitReachUs, WorldInfo.TimeSeconds);
}

// Budgeted follow-steer direction; caches the steer point and falls back to a
// direct horizontal vector when feeler traces are denied.
function vector FollowSteerDirBudgeted(Actor Current)
{
    local vector P;
    local vector Dir;
    local float Now;
    local bool bCacheUsable;

    Now = WorldInfo.TimeSeconds;

    // Obtain the steer point.
    if (NavBudget == None || NavMeter == None)
    {
        P = FollowSteerPoint(Current);
    }
    else
    {
        bCacheUsable = (FollowSteerCacheNode == Current && Now - FollowSteerCacheTime <= FollowSteerCacheMaxAge);

        if (NavBudget.TakeUs(class'EcholonNavBudget'.const.NAV_PRIO_STEER, 9.0 * NavMeter.UnitTraceUs, Now) || !bCacheUsable)
        {
            P = FollowSteerPoint(Current);
            FollowSteerCachePoint = P;
            FollowSteerCacheNode = Current;
            FollowSteerCacheTime = Now;
        }
        else
        {
            P = FollowSteerCachePoint;
        }
    }

    // Feelers: prefer real traces; fall back to a cheap horizontal direction.
    if (NavBudget == None || NavMeter == None || NavBudget.TakeUs(class'EcholonNavBudget'.const.NAV_PRIO_STEER, 2.0 * NavMeter.UnitTraceUs, Now))
    {
        return FollowFeelDir(P);
    }

    Dir = P - Pawn.Location;
    Dir.Z = 0.0;
    if (VSize(Dir) > 0.0)
    {
        return Normal(Dir);
    }
    return Normal(P - Pawn.Location);
}

// ---------------------------------------------------------------- nav cost counting (N6)
// The engine's Clock/UnClock return 0 in the retail game, so nav cost is estimated: each trace, route
// search and reachability check is counted per frame in the shared EcholonNavMeter, which multiplies
// the counts by unit costs measured once by NavBenchmark.
function NavCountTrace()
{
    if (NavMeter != None)
    {
        NavMeter.CountTrace(1);
    }
}

function NavCountSearch()
{
    if (NavMeter != None)
    {
        NavMeter.CountSearch();
    }
}

function NavCountReach()
{
    if (NavMeter != None)
    {
        NavMeter.CountReach();
    }
}

// One-time per-match micro-benchmark: measures unit cost of a trace, a reach check,
// and a path search on this pawn, then stores results in NavMeter.
function NavBenchmark()
{
    local float TraceUs, ReachUs, SearchUs, TotalMs;
    local float R, Angle;
    local int Elapsed;
    local int StartMs, EndMs;
    local int Y, Mo, Dw, D, H, Mi, S, Ms;
    local int I, NodeCount;
    local vector StartPoint, EndPoint, Extent, HitLoc, HitNorm;
    local NavigationPoint N;
    local array<NavigationPoint> Nodes;

    if (Pawn == None)
    {
        return;
    }
    if (NavMeter == None)
    {
        return;
    }

    TraceUs = 0;
    ReachUs = 0;
    SearchUs = 0;
    TotalMs = 0;

    // TRACES: 6000 collision traces in 8 rotating directions
    R = Pawn.GetCollisionRadius();
    StartPoint = Pawn.Location;
    Extent.X = R;
    Extent.Y = R;
    Extent.Z = 8.0;

    GetSystemTime(Y, Mo, Dw, D, H, Mi, S, Ms);
    StartMs = ((H * 60 + Mi) * 60 + S) * 1000 + Ms;

    for (I = 0; I < 6000; I++)
    {
        Angle = float(I % 8) * 0.785398;
        EndPoint = StartPoint;
        EndPoint.X += Cos(Angle) * 400.0;
        EndPoint.Y += Sin(Angle) * 400.0;
        Trace(HitLoc, HitNorm, EndPoint, StartPoint, true, Extent);
    }

    GetSystemTime(Y, Mo, Dw, D, H, Mi, S, Ms);
    EndMs = ((H * 60 + Mi) * 60 + S) * 1000 + Ms;

    if (EndMs >= StartMs)
    {
        Elapsed = EndMs - StartMs;
        TraceUs = float(Elapsed) * 1000.0 / 6000.0;
        TotalMs += float(Elapsed);
    }

    // Collect up to 12 navigation points near the pawn
    NodeCount = 0;
    foreach WorldInfo.RadiusNavigationPoints(class'NavigationPoint', N, Pawn.Location, 2500.0)
    {
        if (NodeCount < 12)
        {
            Nodes.AddItem(N);
            NodeCount++;
        }
    }

    if (NodeCount >= 2)
    {
        // REACH: 400 reachability checks cycling through the nodes
        GetSystemTime(Y, Mo, Dw, D, H, Mi, S, Ms);
        StartMs = ((H * 60 + Mi) * 60 + S) * 1000 + Ms;

        for (I = 0; I < 400; I++)
        {
            ActorReachable(Nodes[I % NodeCount]);
        }

        GetSystemTime(Y, Mo, Dw, D, H, Mi, S, Ms);
        EndMs = ((H * 60 + Mi) * 60 + S) * 1000 + Ms;

        if (EndMs >= StartMs)
        {
            Elapsed = EndMs - StartMs;
            ReachUs = float(Elapsed) * 1000.0 / 400.0;
            TotalMs += float(Elapsed);
        }

        // SEARCH: 300 path searches cycling through the nodes
        GetSystemTime(Y, Mo, Dw, D, H, Mi, S, Ms);
        StartMs = ((H * 60 + Mi) * 60 + S) * 1000 + Ms;

        for (I = 0; I < 300; I++)
        {
            FollowPlanBegin();
            FindPathToward(Nodes[I % NodeCount]);
            FollowPlanEnd();
        }

        GetSystemTime(Y, Mo, Dw, D, H, Mi, S, Ms);
        EndMs = ((H * 60 + Mi) * 60 + S) * 1000 + Ms;

        if (EndMs >= StartMs)
        {
            Elapsed = EndMs - StartMs;
            SearchUs = float(Elapsed) * 1000.0 / 300.0;
            TotalMs += float(Elapsed);
        }
    }

    NavMeter.SetUnitCosts(TraceUs, SearchUs, ReachUs);
    EchelonLog("NAV_BENCH traces=6000 reach=400 search=300 total_ms=" $ string(TotalMs));
}

function FollowWatchdog()
{
    local float IterNow;
    local float IterMovedSq;
    local float IterMinMoveSq;
    local bool IterReach;

    if (!bEnableAdvancedLocomotion || !IsInState('FollowingLeader'))
    {
        ClearTimer('FollowWatchdog');
        return;
    }

    IterNow = WorldInfo.TimeSeconds;

    if (FollowCheckExit())
    {
        return;
    }

    if (bFollowYielding)
    {
        if (IterNow >= FollowYieldEndTime)
        {
            bFollowYielding = false;
            GotoState('FollowingLeader', 'Dispatch');
        }
        return;
    }

    if (!bFollowMoveActive || Pawn == None)
    {
        return;
    }

    if (bFollowDispatchPending)
    {
        FollowRequestDispatch();
        return;
    }

    if (!FollowRefreshLeader() || bFollowLeaderJumped)
    {
        bFollowLeaderJumped = false;
        FollowRequestDispatch();
        return;
    }

    if (!bFollowDirectActive && (IterNow - FollowMoveStartTime) > FollowLegTimeout)
    {
        FollowOnStuck('Timeout');
        return;
    }

    if (Pawn.Physics != PHYS_Falling && (IterNow - FollowStuckRefTime) >= FollowStuckWindow)
    {
        IterMovedSq = VSizeSq(Pawn.Location - FollowStuckRefLoc);
        IterMinMoveSq = FollowStuckMinMove * FollowStuckMinMove;
        FollowStuckRefLoc = Pawn.Location;
        FollowStuckRefTime = IterNow;

        if (IterMovedSq < IterMinMoveSq)
        {
            FollowOnStuck(FollowGuessStuckCause());
            return;
        }
        if (VSizeSq(Pawn.Location - FollowRetryAnchorLoc) > (FollowRetryResetDist * FollowRetryResetDist))
        {
            FollowRetries = 0;
            FollowBlocksThisEpisode = 0;
            FollowRetryAnchorLoc = Pawn.Location;
        }
    }

    IterReach = FollowCheckReachable(false);
    if (IterNow >= FollowForcePathUntil && IterReach != bFollowDirectActive)
    {
        FollowRequestDispatch();
        return;
    }

    if (!IterReach && !bFollowRouteStale
        && FollowLeaderMovedOn(FollowLastLeaderPathLoc, FollowRepathDistance * FollowRepathDistance))
    {
        bFollowRouteStale = true;
    }
}

function FollowRequestDispatch()
{
    local float IterNow;

    if (!bFollowMoveActive)
    {
        return;
    }
    IterNow = WorldInfo.TimeSeconds;
    if (IterNow < FollowNextInterruptTime)
    {
        bFollowDispatchPending = true;
        return;
    }
    FollowNextInterruptTime = IterNow + FollowInterruptMinGap;
    bFollowDispatchPending = false;
    EchelonLog("NAV_WATCHDOG_DISPATCH");
    GotoState('FollowingLeader', 'Dispatch');
}

function bool FollowRefreshLeader()
{
    local Pawn IterPawn;
    local float IterNow;
    local float IterDt;
    local float IterJump;
    local float IterSpeed;

    IterNow = WorldInfo.TimeSeconds;
    IterPawn = None;

    if (FollowLeaderCtrl != None && !FollowLeaderCtrl.bDeleteMe)
    {
        IterPawn = FollowLeaderCtrl.Pawn;
    }

    if (IterPawn == None || IterPawn.bDeleteMe || IterPawn.Health <= 0)
    {
        FollowLeaderPawn = None;
        if (FollowLeaderInvalidSince <= 0.0)
        {
            FollowLeaderInvalidSince = IterNow;
        }
        if (FollowLeaderCtrl == None || (IterNow - FollowLeaderInvalidSince) >= FollowLeaderGraceTime)
        {
            FollowSetStatus(FS_LeaderLost);
        }
        return false;
    }

    FollowLeaderInvalidSince = 0.0;

    if (IterPawn != FollowLeaderPawn)
    {
        FollowLeaderPawn = IterPawn;
        FollowInvalidateRoute();
        FollowLeaderLastSampleLoc = IterPawn.Location;
        FollowLeaderLastSampleTime = IterNow;
        bFollowLeaderJumped = true;
        return true;
    }

    IterDt = IterNow - FollowLeaderLastSampleTime;
    if (IterDt >= 0.2)
    {
        IterJump = VSize(IterPawn.Location - FollowLeaderLastSampleLoc);
        IterSpeed = IterJump / FMax(IterDt, 0.0001);
        if (IterJump > FollowLeaderTeleportDist && IterSpeed > FollowLeaderTeleportSpeed)
        {
            FollowInvalidateRoute();
            FollowRetries = 0;
            FollowForcePathUntil = 0.0;
            FollowNextPathTime = FMax(FollowNextPathTime, IterNow + FollowSlotPhase() + (FRand() * 0.25));
            bFollowLeaderJumped = true;
            FollowSetStatus(FS_LeaderTeleported);
        }
        FollowLeaderLastSampleLoc = IterPawn.Location;
        FollowLeaderLastSampleTime = IterNow;
    }
    return true;
}

function float FollowGetArrivalRadius()
{
    local float IterOffset;

    IterOffset = FollowBaseOffset + (float(FollowSlotIndex) * FollowSlotRingStep);
    if (Pawn == None || FollowLeaderPawn == None)
    {
        return IterOffset;
    }
    return Pawn.GetCollisionRadius() + FollowLeaderPawn.GetCollisionRadius() + IterOffset;
}

function bool FollowEvalArrived()
{
    local vector IterDelta;
    local float IterDist;
    local float IterDz;
    local float IterRadius;
    local bool IterWasArrived;
    local vector IterAnchorRef;

    if (Pawn == None || FollowLeaderPawn == None)
    {
        bFollowArrived = false;
        return false;
    }

    IterWasArrived = bFollowArrived;

    if (bFollowOrderAnchorActive)
    {
        IterAnchorRef = FollowOrderAnchorLoc;
    }
    else
    {
        IterAnchorRef = FollowLeaderPawn.Location;
    }

    IterDelta = IterAnchorRef - Pawn.Location;
    IterDz = Abs(IterDelta.Z);
    IterDelta.Z = 0.0;
    IterDist = VSize(IterDelta);
    IterRadius = FollowGetArrivalRadius();

    if (IterWasArrived)
    {
        bFollowArrived = (IterDist <= (IterRadius + FollowResumeMargin)) && (IterDz <= FollowZTolerance);
    }
    else
    {
        bFollowArrived = (IterDist <= IterRadius) && (IterDz <= FollowZTolerance);
    }

    if (bFollowArrived && !IterWasArrived)
    {
        FollowRetries = 0;
        FollowBlocksThisEpisode = 0;
        FollowRetryAnchorLoc = Pawn.Location;
    }

    return bFollowArrived;
}

function bool FollowCheckReachable(bool bForceNow)
{
    local float IterNow;
    local bool IterReach;

    if (Pawn == None || FollowLeaderPawn == None)
    {
        return false;
    }

    IterNow = WorldInfo.TimeSeconds;

    if (!bForceNow && bFollowReachKnown && IterNow < FollowNextReachCheckTime)
    {
        return bFollowReachStable;
    }

    if (bFollowReachKnown && (FollowLeaderPawn.Physics == PHYS_Falling || Pawn.Physics == PHYS_Falling))
    {
        FollowNextReachCheckTime = IterNow + FollowReachIntervalDirect;
        return bFollowReachStable;
    }

    if (!bForceNow && bFollowReachKnown && !NavAllowReach())
    {
        FollowNextReachCheckTime = IterNow + 0.02;
        return bFollowReachStable;
    }

    IterReach = WalkReachable(FollowLeaderPawn);
    // ActorReachable may count a jump up to a ledge; this mover can't jump it, so make it path instead.
    if (IterReach && Abs(FollowLeaderPawn.Location.Z - Pawn.Location.Z) > FollowDirectMaxZ)
    {
        IterReach = false;
    }

    if (IterReach)
    {
        FollowReachFailStreak = 0;
        bFollowReachStable = true;
        if (bFollowDirectActive)
        {
            FollowNextReachCheckTime = IterNow + FollowReachIntervalDirect;
        }
        else
        {
            FollowNextReachCheckTime = IterNow + FollowReachIntervalPath;
        }
    }
    else
    {
        FollowReachFailStreak++;
        if (!bFollowReachKnown || FollowReachFailStreak >= FollowReachFailsToPath)
        {
            bFollowReachStable = false;
            FollowNextReachCheckTime = IterNow + FollowReachIntervalPath;
        }
        else
        {
            FollowNextReachCheckTime = IterNow + FollowReachIntervalDirect;
        }
    }

    bFollowReachKnown = true;
    return bFollowReachStable;
}

// ---------------------------------------------------------------- wall-jump fix (2026-10-19)
// Every EcholonBot mover steers with raw Pawn.Acceleration (Bible W2): it walks in a straight line
// to the next route node and never runs a reach spec's special move. KF2 maps also carry zed-only
// edges (leaps, wall and ceiling climbs, mantles), and the bot's boosted JumpZ makes A* accept some
// of them, so the "shortest" route went straight up a wall or onto a balcony edge. The bot then ran
// into the wall, hopped (stuck DoJump + NotifyJumpApex double jump) and re-planned the same edge
// until it died. These helpers keep such edges out of every route this bot plans.

// Plan as a walker: with bCanJump on, the engine counts jump-ups when it picks the start anchor and
// checks reachability, then this mover (no jumps) walks into the ledge. Off only for the query, so
// the bot can still drop off ledges while moving (MayFall reads bCanJump).
function FollowPlanBegin()
{
    if (Pawn != None && FollowPlanDepth++ == 0)
    {
        bFollowSavedCanJump = Pawn.bCanJump;
        Pawn.bCanJump = false;
    }
}

function FollowPlanEnd()
{
    if (FollowPlanDepth > 0 && --FollowPlanDepth == 0 && Pawn != None)
    {
        Pawn.bCanJump = bFollowSavedCanJump;
    }
}

// ActorReachable / PointReachable without counting jumps (see FollowPlanBegin).
function bool WalkReachable(Actor Other)
{
    local bool bReach;

    FollowPlanBegin();
    NavCountReach();
    bReach = ActorReachable(Other);
    FollowPlanEnd();
    return bReach;
}

function bool WalkPointReachable(vector Dest)
{
    local bool bReach;

    FollowPlanBegin();
    NavCountReach();
    bReach = PointReachable(Dest);
    FollowPlanEnd();
    return bReach;
}

// True for edges a walking bot can follow by steering at the end node.
function bool FollowIsWalkableSpec(ReachSpec Spec)
{
    if (Spec == None)
    {
        return true;
    }
    // Gaps narrower than this pawn are for zeds; treat them like special edges.
    if (Pawn != None && Spec.CollisionRadius < Pawn.GetCollisionRadius())
    {
        return false;
    }
    return !(Spec.IsA('KFLeapReachSpec') || Spec.IsA('FloorToWallReachSpec') || Spec.IsA('WallReachSpec')
        || Spec.IsA('WallToFloorReachSpec') || Spec.IsA('MantleReachSpec') || Spec.IsA('CeilingReachSpec')
        || Spec.IsA('FloorToCeilingReachSpec') || Spec.IsA('LadderReachSpec') || Spec.IsA('WallTransReachSpec'));
}

// First non-walkable edge on the route FindPathToward/FindPathTo just left in RouteCache, or None.
function ReachSpec FollowFindSpecialEdge()
{
    local NavigationPoint IterPrev, IterNav;
    local ReachSpec IterSpec;
    local int IterIdx;

    if (Pawn == None)
    {
        return None;
    }
    IterPrev = Pawn.Anchor;
    for (IterIdx = 0; IterIdx < RouteCache.Length; IterIdx++)
    {
        IterNav = RouteCache[IterIdx];
        if (IterNav == None)
        {
            break;
        }
        if (IterPrev != None && IterPrev != IterNav)
        {
            IterSpec = IterPrev.GetReachSpecTo(IterNav);
            if (!FollowIsWalkableSpec(IterSpec))
            {
                return IterSpec;
            }
        }
        IterPrev = IterNav;
    }
    return None;
}

// Blocks, for one search, every link the start-of-match scan found bad (blocked, no floor, zed-only).
function FollowScanEdgesBlock(out array<ReachSpec> OutBlocked)
{
    local int I;

    if (NavScan == None || Pawn == None)
    {
        return;
    }
    for (I = 0; I < NavScan.BadSpecs.Length; I++)
    {
        if (NavScan.BadSpecs[I] != None && NavScan.BadSpecs[I].BlockedBy == None)
        {
            NavScan.BadSpecs[I].BlockedBy = Pawn;
            OutBlocked.AddItem(NavScan.BadSpecs[I]);
        }
    }
}

// Path toward Goal (or to Dest when Goal is None) that avoids every special edge this bot has seen.
// Known special edges are marked BlockedBy only for the duration of the search, so zeds keep them.
function Actor FollowFindWalkablePath(Actor Goal, vector Dest)
{
    local array<ReachSpec> IterBlocked;
    local ReachSpec IterSpec;
    local Actor IterFirst;
    local int IterPass, IterIdx, IterMinStrikes;
    local bool IterStrict;

    IterMinStrikes = 1;
    IterStrict = true;
    for (IterPass = 0; IterPass < 4; IterPass++)
    {
        IterBlocked.Length = 0;
        for (IterIdx = 0; IterIdx < FollowSpecialSpecs.Length; IterIdx++)
        {
            if (FollowSpecialSpecs[IterIdx] != None && FollowSpecialSpecs[IterIdx].BlockedBy == None)
            {
                FollowSpecialSpecs[IterIdx].BlockedBy = Pawn;
                IterBlocked.AddItem(FollowSpecialSpecs[IterIdx]);
            }
        }
        FollowBadEdgesBlock(IterMinStrikes, IterBlocked);
        FollowSquadEdgesBlock(IterMinStrikes, IterBlocked);
        if (IterStrict)
        {
            FollowScanEdgesBlock(IterBlocked);
            class'Path_AvoidClosedDoors'.static.AvoidClosedDoors(Pawn, true);
        }
        FollowPlanBegin();
        NavCountSearch();
        if (Goal != None)
        {
            IterFirst = FindPathToward(Goal);
        }
        else
        {
            IterFirst = FindPathTo(Dest);
        }
        FollowPlanEnd();
        Pawn.ClearConstraints();
        for (IterIdx = 0; IterIdx < IterBlocked.Length; IterIdx++)
        {
            IterBlocked[IterIdx].BlockedBy = None;
        }
        if (IterFirst == None)
        {
            if (IterStrict)
            {
                EchelonLog("NAV_PATH_RELAX rules=scan_doors");
                IterStrict = false;
                IterPass--;
                continue;
            }
            if (IterMinStrikes == 1 && FollowBadSpecs.Length > 0)
            {
                EchelonLog("NAV_PATH_RELAX bad=" $ string(FollowBadSpecs.Length));
                IterMinStrikes = 2;
                IterPass--;
                continue;
            }
            return None;
        }
        IterSpec = FollowFindSpecialEdge();
        if (IterSpec == None)
        {
            return IterFirst;
        }
        if (FollowSpecialSpecs.Find(IterSpec) == INDEX_NONE && FollowSpecialSpecs.Length < 64)
        {
            FollowSpecialSpecs.AddItem(IterSpec);
        }
        EchelonLog("NAV_REPLAN spec=" $ string(IterSpec.Class.Name) $ " from=" $ string(IterSpec.Start) $ " to=" $ string(IterSpec.GetEnd()));
    }
    return None;
}

function bool FollowBuildPath()
{
    local float IterNow;
    local Actor IterFirst;
    local int IterIdx;

    IterNow = WorldInfo.TimeSeconds;
    if (FollowLeaderPawn == None || IterNow < FollowNextPathTime)
    {
        return false;
    }

    FollowNextPathTime = IterNow + FollowPathMinInterval + (FRand() * FollowPhaseJitter);

    if (FollowBuildTrailRoute())
    {
        FollowRouteIdx = 0;
        FollowPathFailBackoff = 0.0;
        bFollowRouteStale = false;
        FollowLastLeaderPathLoc = FollowLeaderPawn.Location;
        FollowLastPawnTargetPathLoc = FollowLeaderPawn.Location;
        EchelonLog("NAV_TRAIL nodes=" $ string(FollowRoute.Length) $ " goal=" $ string(FollowCrumbGoal));
        return true;
    }

    FollowCrumbGoal = FollowPickCrumbFrom(EcholonFollowNavBase(FollowLeaderCtrl));
    if (!NavAllowSearch())
    {
        FollowNextPathTime = IterNow;
        return false;
    }
    IterFirst = None;
    if (FollowCrumbGoal != None)
    {
        IterFirst = FollowFindWalkablePath(FollowCrumbGoal, vect(0,0,0));
    }
    if (IterFirst == None)
    {
        FollowCrumbGoal = None;
        IterFirst = FollowFindWalkablePath(FollowLeaderPawn, vect(0,0,0));
    }
    if (IterFirst == None)
    {
        FollowPathFailBackoff = FClamp(FollowPathFailBackoff * 2.0, FollowPathFailBackoffMin, FollowPathFailBackoffMax);
        FollowNextPathTime = IterNow + FMax(FollowPathMinInterval, FollowPathFailBackoff);
        FollowRetries++;
        EchelonLog("NAV_PATH_NONE retries=" $ string(FollowRetries));
        return false;
    }

    FollowRoute.Length = 0;
    for (IterIdx = 0; IterIdx < RouteCache.Length && IterIdx < FollowMaxRouteNodes; IterIdx++)
    {
        FollowRoute.AddItem(RouteCache[IterIdx]);
    }
    if (FollowRoute.Length == 0)
    {
        FollowRoute.AddItem(IterFirst);
    }

    FollowRouteIdx = 0;
    FollowPathFailBackoff = 0.0;
    bFollowRouteStale = false;
    FollowLastLeaderPathLoc = FollowLeaderPawn.Location;
    FollowLastPawnTargetPathLoc = FollowLeaderPawn.Location;
    EchelonLog("NAV_PATH_OK nodes=" $ string(FollowRoute.Length) $ " to=" $ string(FollowLeaderPawn) $ " crumb=" $ string(FollowCrumbGoal));
    return true;
}

// True when the pawn cylinder can walk in a line from From to To (both pawn-centre positions): a swept
// extent trace at knee height is clear and there is floor within FollowFloorDrop under the middle and the end.
function bool FollowWalkClear(vector From, vector To)
{
    local vector Ext, HitLoc, HitNorm, A, B, Mid, Probe;
    local float R, H;

    if (Pawn == None)
    {
        return false;
    }
    R = Pawn.GetCollisionRadius();
    H = Pawn.GetCollisionHeight();
    Ext.X = R;
    Ext.Y = R;
    Ext.Z = 8.0;
    A = From;
    A.Z = From.Z - H + FollowKneeHeight;
    B = To;
    B.Z = To.Z - H + FollowKneeHeight;
    NavCountTrace();
    if (Trace(HitLoc, HitNorm, B, A, true, Ext) != None)
    {
        return false;
    }
    Mid = (From + To) * 0.5;
    Probe = Mid;
    Probe.Z -= H + FollowFloorDrop;
    NavCountTrace();
    if (Trace(HitLoc, HitNorm, Probe, Mid, false) == None)
    {
        return false;
    }
    Probe = To;
    Probe.Z -= H + FollowFloorDrop;
    NavCountTrace();
    if (Trace(HitLoc, HitNorm, Probe, To, false) == None)
    {
        return false;
    }
    return true;
}

// Where to aim while walking the route: the furthest of the next FollowLookahead nodes that passes
// FollowWalkClear from the pawn and is reached over walkable edges only; else the current node.
function vector FollowSteerPoint(Actor Current)
{
    local int IterIdx, IterLast, IterBest;
    local Actor IterNode, IterPrev;
    local NavigationPoint IterStart;

    if (Current == None)
    {
        return Pawn.Location;
    }
    IterBest = FollowRouteIdx;
    IterLast = Min(FollowRouteIdx + FollowLookahead - 1, FollowRoute.Length - 1);
    IterPrev = Current;
    for (IterIdx = FollowRouteIdx + 1; IterIdx <= IterLast; IterIdx++)
    {
        IterNode = FollowRoute[IterIdx];
        IterStart = NavigationPoint(IterPrev);
        if (IterNode == None || IterStart == None || NavigationPoint(IterNode) == None
            || !FollowIsWalkableSpec(IterStart.GetReachSpecTo(NavigationPoint(IterNode))))
        {
            break;
        }
        if (FollowWalkClear(Pawn.Location, IterNode.Location))
        {
            IterBest = IterIdx;
        }
        IterPrev = IterNode;
    }
    if (IterBest < FollowRoute.Length && FollowRoute[IterBest] != None)
    {
        return FollowRoute[IterBest].Location;
    }
    return Current.Location;
}

// Heading to Target with a small push away from a wall seen by a feeler 35 degrees to either side.
function vector FollowFeelDir(vector Target)
{
    local vector Dir, Left, Right, Side, Start, HitLoc, HitNorm;
    local float R, Ang, Len;
    local bool bHitL, bHitR;

    Dir = Target - Pawn.Location;
    Dir.Z = 0.0;
    if (VSizeSq(Dir) < 1.0)
    {
        return Normal(Target - Pawn.Location);
    }
    Dir = Normal(Dir);
    R = Pawn.GetCollisionRadius();
    Len = R * 1.5 + R;
    Ang = FollowFeelerAngle * 0.0174533;
    Side.X = -Dir.Y;
    Side.Y = Dir.X;
    Side.Z = 0.0;
    Left = Normal(Dir * Cos(Ang) + Side * Sin(Ang));
    Right = Normal(Dir * Cos(Ang) - Side * Sin(Ang));
    Start = Pawn.Location;
    Start.Z = Start.Z - Pawn.GetCollisionHeight() + FollowKneeHeight;
    NavCountTrace();
    bHitL = (Trace(HitLoc, HitNorm, Start + Left * Len, Start, false) != None);
    NavCountTrace();
    bHitR = (Trace(HitLoc, HitNorm, Start + Right * Len, Start, false) != None);
    if (bHitL && !bHitR)
    {
        Dir = Normal(Dir - Side * FollowFeelerPush);
    }
    else if (bHitR && !bHitL)
    {
        Dir = Normal(Dir + Side * FollowFeelerPush);
    }
    return Dir;
}

// True once the pawn has walked past Node along the edge from the previous route node while the next
// node is in a clear line (stops orbiting a node that is already behind the pawn).
function bool FollowPassedNode(int Idx)
{
    local vector A, B, Seg;
    local float SegLenSq, T;

    if (Idx <= 0 || Idx + 1 >= FollowRoute.Length || FollowRoute[Idx - 1] == None
        || FollowRoute[Idx] == None || FollowRoute[Idx + 1] == None)
    {
        return false;
    }
    A = FollowRoute[Idx - 1].Location;
    B = FollowRoute[Idx].Location;
    Seg = B - A;
    SegLenSq = VSizeSq(Seg);
    if (SegLenSq < 1.0)
    {
        return false;
    }
    T = ((Pawn.Location - A) dot Seg) / SegLenSq;
    return (T > 1.0 && VSizeSq(Pawn.Location - B) < 40000.0 && FollowWalkClear(Pawn.Location, FollowRoute[Idx + 1].Location));
}

function Actor FollowGetNextNode()
{
    local Actor IterNode;

    if (Pawn == None)
    {
        return None;
    }

    Pawn.DestinationOffset = 0.0;

    while (FollowRouteIdx < FollowRoute.Length)
    {
        IterNode = FollowRoute[FollowRouteIdx];

        if (IterNode == None)
        {
            FollowRouteIdx++;
            continue;
        }

        if (!Pawn.ReachedDestination(IterNode) && !FollowPassedNode(FollowRouteIdx)
            && !(Abs(Pawn.Location.Z - IterNode.Location.Z) < Pawn.GetCollisionHeight()
                && VSizeSq(Pawn.Location - IterNode.Location) < FMax(Pawn.GetCollisionRadius(), FollowArriveRadius) * FMax(Pawn.GetCollisionRadius(), FollowArriveRadius)))
        {
            return IterNode;
        }

        FollowRouteIdx++;
    }

    return None;
}

function EFollowAction FollowDecide()
{
    local float IterNow;
    local bool IterUsePath;
    local vector IterAnchor;

    IterNow = WorldInfo.TimeSeconds;
    FollowWaitTime = FollowWatchdogPeriod;

    if (Pawn == None || Pawn.Health <= 0)
    {
        FollowWaitTime = 0.5;
        return FA_Wait;
    }

    if (!FollowRefreshLeader())
    {
        FollowWaitTime = 0.5;
        return FA_Wait;
    }

    if (FollowGetOrderAnchor(IterAnchor))
    {
        bFollowOrderAnchorActive = true;
        FollowOrderAnchorLoc = IterAnchor;
    }
    else
    {
        bFollowOrderAnchorActive = false;
    }

    if (FollowRetries >= FollowRetriesGiveUpAt)
    {
        return FA_GiveUp;
    }

    if (bFollowEscaping)
    {
        if (IterNow < FollowEscapeUntil)
        {
            return FA_Escape;
        }
        bFollowEscaping = false;
        FollowEscapeNormal = vect(0, 0, 0);
        FollowEscapeUntil = 0.0;
    }

    if (FollowEvalArrived())
    {
        FollowSetStatus(FS_Arrived);
        FollowWaitTime = FollowWatchdogPeriod + (FRand() * FollowPhaseJitter);
        return FA_Hold;
    }

    if (bFollowYieldPending)
    {
        return FA_Yield;
    }

    if (IterNow < FollowRepathPauseUntil)
    {
        FollowWaitTime = FollowRepathPauseUntil - IterNow;
        return FA_Wait;
    }

    FollowSetStatus(FS_Following);

    IterUsePath = (IterNow < FollowForcePathUntil) || !FollowCheckReachable(false);
    if (!IterUsePath)
    {
        return FA_Direct;
    }

    if (bFollowRouteStale || FollowRouteIdx >= FollowRoute.Length)
    {
        if (!FollowBuildPath() && FollowRouteIdx >= FollowRoute.Length)
        {
            FollowWaitTime = FMax(FollowNextPathTime - IterNow, FollowMinLoopSleep);
            return FA_Wait;
        }
    }

    return FA_Path;
}

function FollowOnMoveBegin(bool bDirect)
{
    local float IterNow;

    IterNow = WorldInfo.TimeSeconds;
    bFollowMoveActive = true;
    bFollowDirectActive = bDirect;
    FollowMoveStartTime = IterNow;

    if (FollowStuckRefTime <= 0.0 || (IterNow - FollowStuckRefTime) > (FollowStuckWindow * 3.0))
    {
        FollowStuckRefLoc = Pawn.Location;
        FollowStuckRefTime = IterNow;
    }

    if (!bDirect && FollowNode != None)
    {
        FollowLegTimeout = FMax(0.5, 2.0 * (VSize(FollowNode.Location - Pawn.Location) / FMax(Pawn.GroundSpeed, 0.0001)));
    }
}

function FollowOnMoveEnd(bool bDirect)
{
    bFollowMoveActive = false;
    bFollowDirectActive = false;

    if (bDirect && Pawn != None && FollowLeaderPawn != None)
    {
        Pawn.DestinationOffset = FollowGetArrivalRadius();
        if (Pawn.ReachedDestination(FollowLeaderPawn))
        {
            bFollowArrived = true;
        }
    }
}

function FollowOnNodeMoveEnd(Actor IterNode)
{
    FollowOnMoveEnd(false);

    if (Pawn == None || IterNode == None)
    {
        return;
    }

    Pawn.DestinationOffset = 0.0;

    if (IterNode == FollowNodeLast)
    {
        FollowSameNodeCount++;
    }
    else
    {
        FollowNodeLast = IterNode;
        FollowSameNodeCount = 1;
    }

    if (Pawn.ReachedDestination(IterNode))
    {
        FollowSameNodeCount = 0;
        if (FollowLeaderPawn != None && FollowLeaderMovedOn(FollowLastPawnTargetPathLoc, FollowNodeRepathDistSq))
        {
            bFollowRouteStale = true;
            FollowLastPawnTargetPathLoc = FollowLeaderPawn.Location;
        }
    }
    else if (FollowSameNodeCount > FollowSameNodeLimit && VSizeSq(Pawn.Velocity) < 600.0)
    {
        FollowOnStuck('SameNode');
    }
}

function Name FollowGuessStuckCause()
{
    local float IterNow;

    IterNow = WorldInfo.TimeSeconds;
    if ((IterNow - FollowLastBumpTime) < 1.0)
    {
        return 'Pawn';
    }
    if (FollowLastWall != None && (IterNow - FollowLastWallTime) < 2.0 && !FollowLastWall.IsA('Pawn'))
    {
        return 'Wall';
    }
    return 'Unknown';
}

function FollowOnStuck(Name IterCause)
{
    local float IterNow;

    IterNow = WorldInfo.TimeSeconds;
    if (IterNow < FollowRepathPauseUntil)
    {
        return;
    }

    FollowRetries++;
    EchelonLog("NAV_STUCK cause=" $ string(IterCause) $ " retries=" $ string(FollowRetries) $ " node=" $ string(FollowNode));

    FollowRepathPauseUntil = IterNow + 0.25 + FRand() + FollowSlotPhase();
    // Ladder level 1 backs off and retries the same edge, so the route stays; level 2 strikes the edge and replans.
    if (!FollowLadderStuck(IterCause))
    {
        bFollowRouteStale = true;
    }

    if (bFollowDirectActive)
    {
        FollowForcePathUntil = IterNow + FollowForcePathDuration;
    }

    if (IterCause == 'Pawn')
    {
        bFollowYieldPending = true;
    }
    else if (IterCause == 'SameNode' || ((IterCause == 'Wall' || IterCause == 'Unreachable') && FollowRetries >= FollowRetriesBlockAt))
    {
        FollowTryBlockNode(FollowNodeLast);
    }

    FollowNodeLast = None;
    FollowSameNodeCount = 0;
    if (Pawn != None)
    {
        FollowStuckRefLoc = Pawn.Location;
    }
    FollowStuckRefTime = IterNow;
    FollowRequestDispatch();
}

function ReachSpec FollowCurrentEdge()
{
	local NavigationPoint StartNode, EndNode;

	if (Pawn == None || FollowNode == None)
	{
		return None;
	}

	EndNode = NavigationPoint(FollowNode);
	if (EndNode == None)
	{
		return None;
	}

	StartNode = None;
	if (FollowRouteIdx > 0 && FollowRouteIdx < FollowRoute.Length)
	{
		StartNode = NavigationPoint(FollowRoute[FollowRouteIdx - 1]);
	}
	if (StartNode == None)
	{
		StartNode = Pawn.Anchor;
	}

	if (StartNode == None || StartNode == EndNode)
	{
		return None;
	}

	return StartNode.GetReachSpecTo(EndNode);
}

function FollowStrikeEdge(ReachSpec Spec)
{
    local int I, J;
    local float Penalty;

    if (Spec == None)
        return;

    I = FollowBadSpecs.Find(Spec);
    if (I >= 0)
    {
        FollowBadStrikes[I]++;
    }
    else
    {
        if (FollowBadSpecs.Length >= FollowBadEdgeMax)
        {
            J = 0;
            for (I = 1; I < FollowBadSpecs.Length; I++)
            {
                if (FollowBadUntil[I] < FollowBadUntil[J])
                    J = I;
            }
            FollowBadSpecs.Remove(J, 1);
            FollowBadUntil.Remove(J, 1);
            FollowBadStrikes.Remove(J, 1);
        }
        FollowBadSpecs.AddItem(Spec);
        FollowBadUntil.AddItem(0.0);
        FollowBadStrikes.AddItem(1);
        I = FollowBadSpecs.Length - 1;
    }

    Penalty = FollowBadBaseTime;
    for (J = 1; J < FollowBadStrikes[I]; J++)
        Penalty *= 2.0;
    if (Penalty > FollowBadMaxTime)
        Penalty = FollowBadMaxTime;

    FollowBadUntil[I] = WorldInfo.TimeSeconds + Penalty;

    if (EcholonFollowNavBase(FollowLeaderCtrl) != None && EcholonFollowNavBase(FollowLeaderCtrl) != Self)
    {
        EcholonFollowNavBase(FollowLeaderCtrl).FollowAddSquadStrike(Spec);
    }
    EchelonLog("NAV_STRIKE edge=" $ string(Spec.Start) $ "->" $ string(Spec.GetEnd()) $ " strikes=" $ string(FollowBadStrikes[I]) $ " until=" $ string(FollowBadUntil[I]));
}

function FollowBadEdgesBlock(int MinStrikes, out array<ReachSpec> OutBlocked)
{
    local int i;

    // Drop expired rows
    for (i = FollowBadSpecs.Length - 1; i >= 0; i--)
    {
        if (FollowBadSpecs[i] == None || FollowBadUntil[i] <= WorldInfo.TimeSeconds)
        {
            FollowBadSpecs.Remove(i, 1);
            FollowBadUntil.Remove(i, 1);
            FollowBadStrikes.Remove(i, 1);
        }
    }

    if (Pawn == None)
    {
        return;
    }

    // Block live edges meeting threshold
    for (i = 0; i < FollowBadSpecs.Length; i++)
    {
        if (FollowBadStrikes[i] >= MinStrikes && FollowBadSpecs[i].BlockedBy == None)
        {
            FollowBadSpecs[i].BlockedBy = Pawn;
            OutBlocked.AddItem(FollowBadSpecs[i]);
        }
    }
}

function bool FollowLadderStuck(Name IterCause)
{
    local ReachSpec Spec;
    local vector Dir;

    if (Pawn == None)
        return false;

    if (IterCause == 'Pawn')
        return false;

    Spec = FollowCurrentEdge();
    if (Spec == None)
    {
        FollowLadderSpec = None;
        FollowLadderCount = 0;
        return false;
    }

    if (Spec != FollowLadderSpec)
    {
        FollowLadderSpec = Spec;
        FollowLadderCount = 0;
    }

    FollowLadderCount++;

    if (FollowLadderCount == 1)
    {
        Dir = Spec.Start.Location - Pawn.Location;
        Dir.Z = 0;
        if (VSize(Dir) < 1.0)
        {
            Dir = -vector(Pawn.Rotation);
            Dir.Z = 0;
            Dir = Dir / FMax(VSize(Dir), 0.0001);
        }
        else
        {
            Dir = Dir / VSize(Dir);
        }
        FollowEscapeNormal = Dir;
        bFollowEscaping = true;
        FollowEscapeUntil = WorldInfo.TimeSeconds + (FollowBackoffDist / FMax(Pawn.GroundSpeed, 1.0));
        EchelonLog("NAV_LADDER level=1 edge=" $ string(Spec.Start) $ "->" $ string(Spec.GetEnd()) $ " cause=" $ string(IterCause));
        return true;
    }

    FollowStrikeEdge(Spec);
    FollowLadderSpec = None;
    FollowLadderCount = 0;
    EchelonLog("NAV_LADDER level=2 edge=" $ string(Spec.Start) $ "->" $ string(Spec.GetEnd()) $ " cause=" $ string(IterCause));
    return false;
}

// Called every tick by the bot: records the nav point the pawn stands at when it changes.
function FollowSampleCrumb()
{
    local NavigationPoint IterAnchor;

    if (Pawn == None || WorldInfo.TimeSeconds < FollowCrumbNextTime)
    {
        return;
    }
    FollowCrumbNextTime = WorldInfo.TimeSeconds + FollowCrumbInterval;
    if (Pawn.Physics != PHYS_Walking)
    {
        return;
    }
    IterAnchor = Pawn.Anchor;
    if (IterAnchor == None || VSizeSq(Pawn.Location - IterAnchor.Location) > 14400.0)
    {
        return;
    }
    if (FollowCrumbs.Length > 0 && FollowCrumbs[FollowCrumbs.Length - 1] == IterAnchor)
    {
        return;
    }
    FollowCrumbs.AddItem(IterAnchor);
    if (FollowCrumbs.Length > FollowCrumbMax)
    {
        FollowCrumbs.Remove(0, FollowCrumbs.Length - FollowCrumbMax);
    }
}

// Newest crumb of Leader's trail that this pawn is not already standing at, or None (then plan to the leader pawn).
function NavigationPoint FollowPickCrumbFrom(EcholonFollowNavBase Leader)
{
    local int IterIdx;

    if (Leader == None || Leader == Self || Pawn == None)
    {
        return None;
    }
    for (IterIdx = Leader.FollowCrumbs.Length - 1; IterIdx >= 0; IterIdx--)
    {
        if (Leader.FollowCrumbs[IterIdx] != None)
        {
            if (VSizeSq(Pawn.Location - Leader.FollowCrumbs[IterIdx].Location) < 22500.0)
            {
                return None;
            }
            return Leader.FollowCrumbs[IterIdx];
        }
    }
    return None;
}

// How many leader crumbs are newer than the crumb this route leads to; -1 without a crumb goal.
function int FollowCrumbLag()
{
    local EcholonFollowNavBase IterLeader;
    local int IterIdx;

    IterLeader = EcholonFollowNavBase(FollowLeaderCtrl);
    if (FollowCrumbGoal == None || IterLeader == None)
    {
        return -1;
    }
    IterIdx = IterLeader.FollowCrumbs.Find(FollowCrumbGoal);
    if (IterIdx == INDEX_NONE)
    {
        return FollowCrumbMaxLag;
    }
    return IterLeader.FollowCrumbs.Length - 1 - IterIdx;
}

// True when the route should be replanned because the leader moved on: crumb lag with a crumb goal,
// else the old distance test.
function bool FollowLeaderMovedOn(vector LastLoc, float DistSq)
{
    local int IterLag;

    if (FollowLeaderPawn == None)
    {
        return false;
    }
    IterLag = FollowCrumbLag();
    if (IterLag >= 0)
    {
        return IterLag >= FollowCrumbMaxLag;
    }
    return VSizeSq(FollowLeaderPawn.Location - LastLoc) > DistSq;
}

// Reuse the leader's trail as the route when this pawn stands on or beside it (no A*).
function bool FollowBuildTrailRoute()
{
    local EcholonFollowNavBase IterLeader;
    local int IterIdx, IterStart, IterBest;
    local float IterD, IterBestD;
    local NavigationPoint IterPrev;

    IterLeader = EcholonFollowNavBase(FollowLeaderCtrl);
    if (IterLeader == None || IterLeader == Self || Pawn == None || IterLeader.FollowCrumbs.Length < 2)
    {
        return false;
    }
    IterBest = -1;
    IterBestD = 40000.0;
    for (IterIdx = 0; IterIdx < IterLeader.FollowCrumbs.Length - 1; IterIdx++)
    {
        if (IterLeader.FollowCrumbs[IterIdx] == None)
        {
            continue;
        }
        IterD = VSizeSq(Pawn.Location - IterLeader.FollowCrumbs[IterIdx].Location);
        if (IterD < IterBestD && FollowWalkClear(Pawn.Location, IterLeader.FollowCrumbs[IterIdx].Location))
        {
            IterBestD = IterD;
            IterBest = IterIdx;
        }
    }
    if (IterBest < 0)
    {
        return false;
    }
    FollowRoute.Length = 0;
    IterPrev = IterLeader.FollowCrumbs[IterBest];
    for (IterStart = IterBest + 1; IterStart < IterLeader.FollowCrumbs.Length && FollowRoute.Length < FollowMaxRouteNodes; IterStart++)
    {
        if (IterLeader.FollowCrumbs[IterStart] == None || IterLeader.FollowCrumbs[IterStart] == IterPrev)
        {
            continue;
        }
        if (!FollowIsWalkableSpec(IterPrev.GetReachSpecTo(IterLeader.FollowCrumbs[IterStart])))
        {
            break;
        }
        FollowRoute.AddItem(IterLeader.FollowCrumbs[IterStart]);
        IterPrev = IterLeader.FollowCrumbs[IterStart];
    }
    if (FollowRoute.Length == 0)
    {
        return false;
    }
    FollowCrumbGoal = NavigationPoint(FollowRoute[FollowRoute.Length - 1]);
    return true;
}

// Copy a strike into this bot's table as a squad strike (no forwarding, no log spam).
function FollowAddSquadStrike(ReachSpec Spec)
{
    local int IterIdx, IterJ;
    local float IterPenalty;

    if (Spec == None)
    {
        return;
    }
    IterIdx = FollowBadSpecs.Find(Spec);
    if (IterIdx == INDEX_NONE)
    {
        if (FollowBadSpecs.Length >= FollowBadEdgeMax)
        {
            return;
        }
        FollowBadSpecs.AddItem(Spec);
        FollowBadUntil.AddItem(0.0);
        FollowBadStrikes.AddItem(1);
        IterIdx = FollowBadSpecs.Length - 1;
    }
    else
    {
        FollowBadStrikes[IterIdx]++;
    }
    IterPenalty = FollowBadBaseTime;
    for (IterJ = 1; IterJ < FollowBadStrikes[IterIdx]; IterJ++)
    {
        IterPenalty *= 2.0;
    }
    FollowBadUntil[IterIdx] = WorldInfo.TimeSeconds + FMin(IterPenalty, FollowBadMaxTime);
}

// Block the leader's live bad edges too (squad table: strikes any member recorded were copied to the leader).
function FollowSquadEdgesBlock(int MinStrikes, out array<ReachSpec> OutBlocked)
{
    local EcholonFollowNavBase IterLeader;
    local int IterIdx;

    IterLeader = EcholonFollowNavBase(FollowLeaderCtrl);
    if (IterLeader == None || IterLeader == Self || Pawn == None)
    {
        return;
    }
    for (IterIdx = 0; IterIdx < IterLeader.FollowBadSpecs.Length; IterIdx++)
    {
        if (IterLeader.FollowBadSpecs[IterIdx] != None && IterLeader.FollowBadStrikes[IterIdx] >= MinStrikes
            && IterLeader.FollowBadUntil[IterIdx] > WorldInfo.TimeSeconds && IterLeader.FollowBadSpecs[IterIdx].BlockedBy == None)
        {
            IterLeader.FollowBadSpecs[IterIdx].BlockedBy = Pawn;
            OutBlocked.AddItem(IterLeader.FollowBadSpecs[IterIdx]);
        }
    }
}

function bool FollowTryBlockNode(Actor IterNodeActor)
{
	// PLAN B: node blacklist is intentionally unavailable.
	// Persistent blockers are handled by force-repath + wall-escape (FollowSetWallEscape),
	// not by blocking the navigation node.
	return false;
}

function bool FollowOwnsEvents()
{
    return (bEnableAdvancedLocomotion && IsInState('FollowingLeader'));
}

function bool FollowHandleHitWall(vector HitNormal, Actor Wall)
{
    local float IterNow;

    IterNow = WorldInfo.TimeSeconds;

    if ((IterNow - FollowLastWallTime) < FollowWallDebounce)
    {
        return false;
    }

    if (Pawn != None && Pawn.Physics == PHYS_Falling)
    {
        return true;
    }

    if (Wall != FollowLastWall || (IterNow - FollowWallWindowStart) > FollowWallWindow)
    {
        FollowLastWall = Wall;
        FollowWallWindowStart = IterNow;
        FollowWallHitCount = 0;
    }
    FollowLastWallTime = IterNow;
    FollowWallHitCount++;

    if (FollowWallHitCount >= FollowWallHitThreshold && bFollowMoveActive)
    {
        FollowWallHitCount = 0;

        if (Wall != None && Wall.IsA('Pawn'))
        {
            FollowOnStuck('Pawn');
        }
        else
        {
            FollowOnStuck('Wall');
            FollowSetWallEscape(HitNormal);
        }
    }

    return false;
}

function FollowSetWallEscape(vector HitNormal)
{
    local float Now;
    local float NormLen;

    Now = WorldInfo.TimeSeconds;
    NormLen = VSize(HitNormal);
    if (NormLen < 0.01)
    {
        return;
    }
    FollowEscapeNormal.X = HitNormal.X / NormLen;
    FollowEscapeNormal.Y = HitNormal.Y / NormLen;
    FollowEscapeNormal.Z = HitNormal.Z / NormLen;
    bFollowEscaping = true;
    FollowEscapeUntil = Now + FollowEscapeDuration;
    EchelonLog("NAV_WALL_ESCAPE nx=" $ string(FollowEscapeNormal.X) $ " ny=" $ string(FollowEscapeNormal.Y) $ " for=" $ string(FollowEscapeDuration) $ " slot=" $ string(FollowSlotIndex));
}

function bool FollowIsFriendly(Pawn IterOther)
{
    if (IterOther == None)
    {
        return false;
    }
    if (IterOther == FollowLeaderPawn)
    {
        return true;
    }
    if (PlayerController(IterOther.Controller) != None)
    {
        return true;
    }
    return (EcholonFollowNavBase(IterOther.Controller) != None);
}

function bool FollowShouldYieldTo(Pawn IterOther)
{
    local EcholonFollowNavBase IterBot;

    if (IterOther == FollowLeaderPawn)
    {
        return true;
    }
    IterBot = EcholonFollowNavBase(IterOther.Controller);
    if (IterBot == None)
    {
        return true;
    }
    if (IterBot.FollowSlotIndex == FollowSlotIndex)
    {
        return (string(IterBot.Name) < string(Name));
    }
    return (IterBot.FollowSlotIndex < FollowSlotIndex);
}

function bool FollowHandleBump(Actor Other, vector HitNormal)
{
    local Pawn POther;
    local float Now;

    POther = Pawn(Other);
    if (POther == None || Pawn == None || !FollowIsFriendly(POther))
    {
        return false;
    }

    Now = WorldInfo.TimeSeconds;
    FollowLastBumpTime = Now;

    if (Now < FollowNextBumpReactTime)
    {
        return true;
    }
    FollowNextBumpReactTime = Now + FollowBumpCooldown;

    if (FollowShouldYieldTo(POther))
    {
        FollowYieldAway = Pawn.Location - POther.Location;
        FollowYieldAway.Z = 0.0;
        bFollowYieldPending = true;
        FollowRequestDispatch();
    }
    return true;
}

function FollowHandleMoveUnreachable(vector AttemptedDest, Actor AttemptedTarget)
{
    local float IterNow;

    IterNow = WorldInfo.TimeSeconds;

    if (bFollowMoveActive && !bFollowDirectActive)
    {
        FollowOnStuck('Unreachable');
        return;
    }

    if (IterNow < FollowForcePathUntil)
    {
        return;
    }

    EchelonLog("NAV_UNREACHABLE target=" $ string(AttemptedTarget));
    FollowForcePathUntil = IterNow + FollowForcePathDuration;
    FollowNextPathTime = FMax(FollowNextPathTime, IterNow + FollowSlotPhase());
    bFollowRouteStale = true;
    FollowRequestDispatch();
}

function bool FollowComputeYieldPoint()
{
    local vector IterAway;
    local vector IterSide;
    local vector IterDest;

    if (Pawn == None)
    {
        return false;
    }

    IterAway = FollowYieldAway;
    IterAway.Z = 0.0;
    if (VSize(IterAway) < 1.0 && FollowLeaderPawn != None)
    {
        IterAway = Pawn.Location - FollowLeaderPawn.Location;
        IterAway.Z = 0.0;
    }
    if (VSize(IterAway) < 1.0)
    {
        return false;
    }
    IterAway = Normal(IterAway);

    // Even slots step left, odd slots step right: two yielding bots never
    // pick the same side.
    IterSide = IterAway Cross vect(0.0, 0.0, 1.0);
    if ((FollowSlotIndex % 2) == 1)
    {
        IterSide = -IterSide;
    }

    IterDest = Pawn.Location + (IterSide * FollowYieldDist) + (IterAway * (FollowYieldDist * 0.5));
    if (!WalkPointReachable(IterDest))
    {
        IterSide = -IterSide;
        IterDest = Pawn.Location + (IterSide * FollowYieldDist) + (IterAway * (FollowYieldDist * 0.5));
        if (!WalkPointReachable(IterDest))
        {
            return false;
        }
    }
    FollowYieldPoint = IterDest;
    return true;
}

function FollowSetStatus(EFollowStatus NewStatus)
{
    if (NewStatus == FollowStatus)
    {
        return;
    }
    FollowStatus = NewStatus;
    FollowNotifyHub(NewStatus);
}

function FollowNotifyHub(EFollowStatus NewStatus)
{
    EchelonLog("NAV_STATUS status=" $ string(int(NewStatus)));
}

function FollowOnGaveUp()
{
    EchelonLog("NAV_GIVEUP");
}

event bool NotifyHitWall(vector HitNormal, Actor Wall)
{
    if (FollowOwnsEvents())
    {
        return FollowHandleHitWall(HitNormal, Wall);
    }
    return Super.NotifyHitWall(HitNormal, Wall);
}

event bool NotifyBump(Actor Other, vector HitNormal)
{
    if (FollowOwnsEvents() && FollowHandleBump(Other, HitNormal))
    {
        return true;
    }
    return Super.NotifyBump(Other, HitNormal);
}

event MoveUnreachable(vector AttemptedDest, Actor AttemptedTarget)
{
    if (FollowOwnsEvents())
    {
        FollowHandleMoveUnreachable(AttemptedDest, AttemptedTarget);
        return;
    }
    Super.MoveUnreachable(AttemptedDest, AttemptedTarget);
}

// @STUB(M2) @SYS-NAV-STATE legacy:KF2BotsFollowNavBase.FollowingLeader
state FollowingLeader
{
    event BeginState(Name PreviousStateName)
    {
        FollowResetEpisode();
        bFollowMoveActive = false;
        bFollowDirectActive = false;
        if (Pawn != None)
        {
            Pawn.Acceleration = vect(0.0, 0.0, 0.0);
        }
        FollowScheduleWatchdog();
        EchelonLog("NAV_FOLLOW_ENTER from=" $ string(PreviousStateName));
    }

    event EndState(Name NextStateName)
    {
        ClearTimer('FollowWatchdogBegin');
        ClearTimer('FollowWatchdog');
        bFollowMoveActive = false;
        bFollowDirectActive = false;
        bFollowYielding = false;
        EchelonLog("NAV_FOLLOW_EXIT to=" $ string(NextStateName));
    }

Begin:
    Goto('Dispatch');

Dispatch:
    if (!IsInState('FollowingLeader'))
    {
        Stop;
    }
    bFollowMoveActive = false;
    bFollowDirectActive = false;
    bFollowDispatchPending = false;
    if (bFollowExitPending)
    {
        bFollowExitPending = false;
        if (FollowExitState != '')
        {
            GotoState(FollowExitState);
            Stop;
        }
    }
    FollowAction = FollowDecide();
    if (FollowAction == FA_Direct)
    {
        Goto('DirectMove');
    }
    if (FollowAction == FA_Path)
    {
        Goto('PathMove');
    }
    if (FollowAction == FA_Yield)
    {
        Goto('YieldStep');
    }
    if (FollowAction == FA_Escape)
    {
        Goto('EscapeStep');
    }
    if (FollowAction == FA_Hold)
    {
        Goto('HoldStep');
    }
    if (FollowAction == FA_GiveUp)
    {
        Goto('GiveUpStep');
    }
    Goto('WaitStep');

WaitStep:
    Sleep(FClamp(FollowWaitTime, FollowMinLoopSleep, 1.0));
    Goto('Dispatch');

HoldStep:
    if (Pawn != None)
    {
        Pawn.Acceleration = vect(0.0, 0.0, 0.0);
    }
    Sleep(FClamp(FollowWaitTime, FollowMinLoopSleep, 1.0));
    Goto('Dispatch');

DirectMove:
    FollowOnMoveBegin(true);
    if (bFollowOrderAnchorActive)
    {
        Pawn.Acceleration = Normal(FollowOrderAnchorLoc - Pawn.Location) * FMax(Pawn.GroundSpeed, 0.0001f);
    }
    else
    {
        EchelonLog("NAV_ACCEL_LEADER pawn=" $ string(FollowLeaderPawn) $ " radius=" $ string(FollowGetArrivalRadius()));
        Pawn.Acceleration = Normal(FollowLeaderPawn.Location - Pawn.Location) * FMax(Pawn.GroundSpeed, 0.0001f);
    }
    Sleep(FollowMinLoopSleep);
    Goto('Dispatch');

PathMove:
    FollowNode = FollowGetNextNode();
    if (FollowNode == None)
    {
        Sleep(FollowMinLoopSleep);
        Goto('Dispatch');
    }
    FollowOnMoveBegin(false);
    EchelonLog("NAV_ACCEL_NODE node=" $ string(FollowNode));
    Pawn.Acceleration = FollowSeparationPush(NavGridSteer(FollowSteerDirBudgeted(FollowNode))) * FMax(Pawn.GroundSpeed, 0.0001f);
    FollowApplySpeedCap();
    Sleep(FollowMinLoopSleep);
    Goto('Dispatch');

EscapeStep:
    if (Pawn != None)
    {
        Pawn.Acceleration = FollowEscapeNormal * FMax(Pawn.GroundSpeed, 0.0001f);
    }
    EchelonLog("NAV_ACCEL_ESCAPE nx=" $ string(FollowEscapeNormal.X) $ " ny=" $ string(FollowEscapeNormal.Y));
    Sleep(FollowMinLoopSleep);
    Goto('Dispatch');

YieldStep:
    bFollowYieldPending = false;
    if (FollowComputeYieldPoint())
    {
        bFollowYielding = true;
        FollowYieldEndTime = WorldInfo.TimeSeconds + FollowYieldTimeout;
        EchelonLog("NAV_ACCEL_YIELD at=" $ string(FollowYieldPoint.X) $ "," $ string(FollowYieldPoint.Y) $ "," $ string(FollowYieldPoint.Z));
        Pawn.Acceleration = Normal(FollowYieldPoint - Pawn.Location) * FMax(Pawn.GroundSpeed, 0.0001f);
        bFollowYielding = false;
    }
    Sleep(FollowYieldHold);
    Goto('Dispatch');

GiveUpStep:
    FollowSetStatus(FS_Blocked);
    FollowOnGaveUp();
    Sleep(FollowGiveUpHold);
    FollowRetries = 0;
    FollowBlocksThisEpisode = 0;
    Goto('Dispatch');
}

// @STUB(M2) @SYS-NAV-STATE legacy:KF2BotsFollowNavBase.FollowingLeaderBasic
state FollowingLeaderBasic
{
Begin:
    if (!IsInState('FollowingLeaderBasic'))
    {
        Stop;
    }
    if (bFollowExitPending)
    {
        bFollowExitPending = false;
        if (FollowExitState != '')
        {
            GotoState(FollowExitState);
            Stop;
        }
    }
    if (Pawn == None || !FollowRefreshLeader())
    {
        Sleep(0.5);
        Goto('Begin');
    }
    Pawn.Acceleration = vect(0.0, 0.0, 0.0);
    if (FollowEvalArrived())
    {
        Sleep(0.3);
        Goto('Begin');
    }
    if (FollowGetOrderAnchor(FollowOrderAnchorLoc))
    {
        bFollowOrderAnchorActive = true;
    }
    else
    {
        bFollowOrderAnchorActive = false;
    }
    if (WalkReachable(FollowLeaderPawn) && Abs(FollowLeaderPawn.Location.Z - Pawn.Location.Z) <= FollowDirectMaxZ)
    {
        if (bFollowOrderAnchorActive)
        {
            Pawn.Acceleration = Normal(FollowOrderAnchorLoc - Pawn.Location) * FMax(Pawn.GroundSpeed, 0.0001);
        }
        else
        {
            Pawn.Acceleration = Normal(FollowLeaderPawn.Location - Pawn.Location) * FMax(Pawn.GroundSpeed, 0.0001);
        }
    }
    else
    {
        FollowNode = FollowFindWalkablePath(FollowLeaderPawn, vect(0,0,0));
        if (FollowNode != None)
        {
            Pawn.Acceleration = Normal(FollowNode.Location - Pawn.Location) * FMax(Pawn.GroundSpeed, 0.0001);
        }
    }
    Sleep(0.25);
    Goto('Begin');
}

defaultproperties
{
    bEnableAdvancedLocomotion=true
    FollowExitState="PickNextMove"
    FollowLeaderGraceTime=2.0
    FollowLeaderTeleportDist=1200.0
    FollowLeaderTeleportSpeed=4000.0
    FollowSlotIndex=0
    FollowSlotCount=1
    FollowBaseOffset=96.0
    FollowSlotRingStep=64.0
    FollowResumeMargin=96.0
    FollowZTolerance=128.0
    FollowWatchdogPeriod=0.25
    FollowRampUpTime=0.6
    FollowRampMinPct=0.4
    FollowCornerSlowDist=300.0
    FollowCornerMinPct=0.45
    FollowCornerAngle=60.0
    FollowSeparationDist=80.0
    FollowSeparationGain=0.8
    FollowSteerCacheMaxAge=0.4
    FollowPhaseJitter=0.03
    FollowReachIntervalDirect=0.25
    FollowReachIntervalPath=0.5
    FollowReachFailsToPath=2
    FollowDirectMaxZ=72.0
    FollowMinLoopSleep=0.05
    FollowInterruptMinGap=0.15
    FollowPathMinInterval=0.75
    FollowPathFailBackoffMin=0.5
    FollowPathFailBackoffMax=4.0
    FollowRepathDistance=1224.0
    FollowNodeRepathDistSq=589824.0
    FollowForcePathDuration=2.0
    FollowMaxRouteNodes=24
    FollowStuckWindow=1.5
    FollowStuckMinMove=32.0
    FollowSameNodeLimit=20
    FollowWallHitThreshold=5
    FollowWallWindow=3.0
    FollowWallDebounce=0.2
    FollowBumpCooldown=0.5
    FollowYieldDist=64.0
    FollowYieldHold=0.3
    FollowYieldTimeout=0.75
    FollowEscapeDuration = 0.8
    FollowRetriesBlockAt=5
    FollowRetriesGiveUpAt=10
    FollowRetryResetDist=384.0
    FollowGiveUpHold=2.0
    FollowBadEdgeMax=32
    FollowBadBaseTime=20.0
    FollowBadMaxTime=120.0
    FollowBackoffDist=64.0
    FollowLookahead=3
    FollowArriveRadius=48.0
    FollowFeelerAngle=35.0
    FollowFeelerPush=0.6
    FollowKneeHeight=40.0
    FollowFloorDrop=80.0
    FollowCrumbMax=16
    FollowCrumbInterval=0.4
    FollowCrumbMaxLag=3
}
