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
// Special edges (leap, climb, mantle) this bot found on a planned route; kept out of later routes.
var array<ReachSpec> FollowSpecialSpecs;
// Direct-steer only when the leader is within this height; above it, a ledge or balcony is likely in between.
var float FollowDirectMaxZ;

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
        && VSizeSq(FollowLeaderPawn.Location - FollowLastLeaderPathLoc) > (FollowRepathDistance * FollowRepathDistance))
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
    `log("[FollowNav]" @ string(Name) @ "watchdog interrupt -> Dispatch");
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

    IterReach = ActorReachable(FollowLeaderPawn);
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

// True for edges a walking bot can follow by steering at the end node.
function bool FollowIsWalkableSpec(ReachSpec Spec)
{
    if (Spec == None)
    {
        return true;
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

// Path toward Goal (or to Dest when Goal is None) that avoids every special edge this bot has seen.
// Known special edges are marked BlockedBy only for the duration of the search, so zeds keep them.
function Actor FollowFindWalkablePath(Actor Goal, vector Dest)
{
    local array<ReachSpec> IterBlocked;
    local ReachSpec IterSpec;
    local Actor IterFirst;
    local int IterPass, IterIdx;

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
        if (Goal != None)
        {
            IterFirst = FindPathToward(Goal);
        }
        else
        {
            IterFirst = FindPathTo(Dest);
        }
        for (IterIdx = 0; IterIdx < IterBlocked.Length; IterIdx++)
        {
            IterBlocked[IterIdx].BlockedBy = None;
        }
        if (IterFirst == None)
        {
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
        `log("[FollowNav]" @ string(Name) @ "route used " $ string(IterSpec.Class.Name) $ " " $ string(IterSpec.Start) $ " -> " $ string(IterSpec.GetEnd()) $ ", replanning without it");
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

    IterFirst = FollowFindWalkablePath(FollowLeaderPawn, vect(0,0,0));
    if (IterFirst == None)
    {
        FollowPathFailBackoff = FClamp(FollowPathFailBackoff * 2.0, FollowPathFailBackoffMin, FollowPathFailBackoffMax);
        FollowNextPathTime = IterNow + FMax(FollowPathMinInterval, FollowPathFailBackoff);
        FollowRetries++;
        `log("[FollowNav]" @ string(Name) @ "FindPathToward returned None, retries=" $ string(FollowRetries));
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
    `log("[FollowNav]" @ string(Name) @ "A* OK " $ string(FollowRoute.Length) @ "nodes to " $ string(FollowLeaderPawn));
    return true;
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

        if (!Pawn.ReachedDestination(IterNode))
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
        if (FollowLeaderPawn != None && VSizeSq(FollowLeaderPawn.Location - FollowLastPawnTargetPathLoc) > FollowNodeRepathDistSq)
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
    `log("[FollowNav]" @ string(Name) @ " stuck cause=" $ string(IterCause) @ " retries=" $ string(FollowRetries));

    FollowRepathPauseUntil = IterNow + 0.25 + FRand() + FollowSlotPhase();
    bFollowRouteStale = true;

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
    `log("[FollowNav] wall-escape set: nx=" $ string(FollowEscapeNormal.X) $ " ny=" $ string(FollowEscapeNormal.Y) $ " for=" $ string(FollowEscapeDuration) $ "s (slot=" $ string(FollowSlotIndex) $ ")");
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

    `log("[FollowNav]" @ string(Name) @ "MoveUnreachable -> forcing path, target=" $ string(AttemptedTarget));
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
    if (!PointReachable(IterDest))
    {
        IterSide = -IterSide;
        IterDest = Pawn.Location + (IterSide * FollowYieldDist) + (IterAway * (FollowYieldDist * 0.5));
        if (!PointReachable(IterDest))
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
    `log("[FollowNav]" @ string(Name) @ "status=" $ string(int(NewStatus)));
}

function FollowOnGaveUp()
{
    `log("[FollowNav]" @ string(Name) @ "gave up following; Hub should decide");
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
        `log("[FollowNav]" @ string(Name) @ "Enter FollowingLeader from " $ string(PreviousStateName));
    }

    event EndState(Name NextStateName)
    {
        ClearTimer('FollowWatchdogBegin');
        ClearTimer('FollowWatchdog');
        bFollowMoveActive = false;
        bFollowDirectActive = false;
        bFollowYielding = false;
        `log("[FollowNav]" @ string(Name) @ "Exit FollowingLeader to " $ string(NextStateName));
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
        `log("[FollowNav]" @ string(Name) @ "Accel leader " $ string(FollowLeaderPawn) @ " radius=" $ string(FollowGetArrivalRadius()));
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
    `log("[FollowNav]" @ string(Name) @ "Accel node " $ string(FollowNode));
    Pawn.Acceleration = Normal(FollowNode.Location - Pawn.Location) * FMax(Pawn.GroundSpeed, 0.0001f);
    Sleep(FollowMinLoopSleep);
    Goto('Dispatch');

EscapeStep:
    if (Pawn != None)
    {
        Pawn.Acceleration = FollowEscapeNormal * FMax(Pawn.GroundSpeed, 0.0001f);
    }
    `log("[FollowNav]" @ string(Name) @ "Accel escape off wall nx=" $ string(FollowEscapeNormal.X) $ " ny=" $ string(FollowEscapeNormal.Y));
    Sleep(FollowMinLoopSleep);
    Goto('Dispatch');

YieldStep:
    bFollowYieldPending = false;
    if (FollowComputeYieldPoint())
    {
        bFollowYielding = true;
        FollowYieldEndTime = WorldInfo.TimeSeconds + FollowYieldTimeout;
        `log("[FollowNav]" @ string(Name) @ "Accel yield " $ string(FollowYieldPoint.X) $ "," $ string(FollowYieldPoint.Y) $ "," $ string(FollowYieldPoint.Z));
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
    if (ActorReachable(FollowLeaderPawn) && Abs(FollowLeaderPawn.Location.Z - Pawn.Location.Z) <= FollowDirectMaxZ)
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
}
