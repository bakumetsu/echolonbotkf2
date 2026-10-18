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

    IterFirst = FindPathToward(FollowLeaderPawn);
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

// @STUB(M2) @SYS-NAV-PATH legacy:KF2BotsFollowNavBase.FollowOnMoveEnd
function FollowOnMoveEnd(bool bDirect)
{
}

// @STUB(M2) @SYS-NAV-PATH legacy:KF2BotsFollowNavBase.FollowOnNodeMoveEnd
function FollowOnNodeMoveEnd(Actor IterNode)
{
}

// @STUB(M2) @SYS-NAV-STUCK legacy:KF2BotsFollowNavBase.FollowGuessStuckCause
function Name FollowGuessStuckCause()
{
}

// @STUB(M2) @SYS-NAV-STUCK legacy:KF2BotsFollowNavBase.FollowOnStuck
function FollowOnStuck(Name IterCause)
{
}

// @STUB(M2) @SYS-NAV-STUCK legacy:KF2BotsFollowNavBase.FollowTryBlockNode
function bool FollowTryBlockNode(Actor IterNodeActor)
{
}

// @STUB(M2) @SYS-NAV-HANDLE legacy:KF2BotsFollowNavBase.FollowOwnsEvents
function bool FollowOwnsEvents()
{
}

// @STUB(M2) @SYS-NAV-HANDLE legacy:KF2BotsFollowNavBase.FollowHandleHitWall
function bool FollowHandleHitWall(vector HitNormal, Actor Wall)
{
}

// @STUB(M2) @SYS-NAV-STUCK legacy:KF2BotsFollowNavBase.FollowSetWallEscape
function FollowSetWallEscape(vector HitNormal)
{
}

// @STUB(M2) @SYS-NAV-HANDLE legacy:KF2BotsFollowNavBase.FollowIsFriendly
function bool FollowIsFriendly(Pawn IterOther)
{
}

// @STUB(M2) @SYS-NAV-HANDLE legacy:KF2BotsFollowNavBase.FollowShouldYieldTo
function bool FollowShouldYieldTo(Pawn IterOther)
{
}

// @STUB(M2) @SYS-NAV-HANDLE legacy:KF2BotsFollowNavBase.FollowHandleBump
function bool FollowHandleBump(Actor Other, vector HitNormal)
{
}

// @STUB(M2) @SYS-NAV-HANDLE legacy:KF2BotsFollowNavBase.FollowHandleMoveUnreachable
function FollowHandleMoveUnreachable(vector AttemptedDest, Actor AttemptedTarget)
{
}

// @STUB(M2) @SYS-NAV-HANDLE legacy:KF2BotsFollowNavBase.FollowComputeYieldPoint
function bool FollowComputeYieldPoint()
{
}

// @STUB(M2) @SYS-NAV-STATUS legacy:KF2BotsFollowNavBase.FollowSetStatus
function FollowSetStatus(EFollowStatus NewStatus)
{
}

// @STUB(M2) @SYS-NAV-STATUS legacy:KF2BotsFollowNavBase.FollowNotifyHub
function FollowNotifyHub(EFollowStatus NewStatus)
{
}

// @STUB(M2) @SYS-NAV-WATCHDOG legacy:KF2BotsFollowNavBase.FollowOnGaveUp
function FollowOnGaveUp()
{
}

// @STUB(M2) @SYS-NAV-HANDLE legacy:KF2BotsFollowNavBase.NotifyHitWall
event bool NotifyHitWall(vector HitNormal, Actor Wall)
{
    // PASS-THROUGH: overrides Controller; keep the engine behaviour until the real port lands.
    return super.NotifyHitWall(HitNormal, Wall);
}

// @STUB(M2) @SYS-NAV-HANDLE legacy:KF2BotsFollowNavBase.NotifyBump
event bool NotifyBump(Actor Other, vector HitNormal)
{
    // PASS-THROUGH: overrides Controller; keep the engine behaviour until the real port lands.
    return super.NotifyBump(Other, HitNormal);
}

// @STUB(M2) @SYS-NAV-HANDLE legacy:KF2BotsFollowNavBase.MoveUnreachable
event MoveUnreachable(vector AttemptedDest, Actor AttemptedTarget)
{
    // PASS-THROUGH: overrides Controller; keep the engine behaviour until the real port lands.
    super.MoveUnreachable(AttemptedDest, AttemptedTarget);
}

// @STUB(M2) @SYS-NAV-STATE legacy:KF2BotsFollowNavBase.FollowingLeader
state FollowingLeader
{
    // @STUB(M2) @SYS-NAV-STATE legacy:KF2BotsFollowNavBase.FollowingLeader.BeginState
    event BeginState(Name PreviousStateName)
    {
    }

    // @STUB(M2) @SYS-NAV-STATE legacy:KF2BotsFollowNavBase.FollowingLeader.EndState
    event EndState(Name NextStateName)
    {
    }

Begin:
    Stop;
Dispatch:
    Stop;
WaitStep:
    Stop;
HoldStep:
    Stop;
DirectMove:
    Stop;
PathMove:
    Stop;
EscapeStep:
    Stop;
YieldStep:
    Stop;
GiveUpStep:
    Stop;
}

// @STUB(M2) @SYS-NAV-STATE legacy:KF2BotsFollowNavBase.FollowingLeaderBasic
state FollowingLeaderBasic
{
Begin:
    Stop;
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
