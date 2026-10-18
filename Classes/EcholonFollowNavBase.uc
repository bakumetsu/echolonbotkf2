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

// @STUB(M2) @SYS-NAV-EPISODE legacy:KF2BotsFollowNavBase.FollowStart
function FollowStart(Controller NewLeaderCtrl)
{
}

// @STUB(M2) @SYS-NAV-EPISODE legacy:KF2BotsFollowNavBase.FollowSetLeader
function FollowSetLeader(Controller NewLeaderCtrl)
{
}

// @STUB(M2) @SYS-NAV-EPISODE legacy:KF2BotsFollowNavBase.FollowSetSlot
function FollowSetSlot(int NewSlotIndex, int NewSlotCount)
{
}

// @STUB(M2) @SYS-NAV-EPISODE legacy:KF2BotsFollowNavBase.FollowGetOrderAnchor
function bool FollowGetOrderAnchor(out vector OutLoc)
{
}

// @STUB(M2) @SYS-NAV-EPISODE legacy:KF2BotsFollowNavBase.FollowResetEpisode
function FollowResetEpisode()
{
}

// @STUB(M2) @SYS-NAV-EPISODE legacy:KF2BotsFollowNavBase.FollowInvalidateRoute
function FollowInvalidateRoute()
{
}

// @STUB(M2) @SYS-NAV-EPISODE legacy:KF2BotsFollowNavBase.FollowSlotPhase
function float FollowSlotPhase()
{
}

// @STUB(M2) @SYS-NAV-EPISODE legacy:KF2BotsFollowNavBase.FollowScheduleWatchdog
function FollowScheduleWatchdog()
{
}

// @STUB(M2) @SYS-NAV-EPISODE legacy:KF2BotsFollowNavBase.FollowWatchdogBegin
function FollowWatchdogBegin()
{
}

// @STUB(M2) @SYS-NAV-WATCHDOG legacy:KF2BotsFollowNavBase.FollowCheckExit
function bool FollowCheckExit()
{
}

// @STUB(M2) @SYS-NAV-WATCHDOG legacy:KF2BotsFollowNavBase.FollowWatchdog
function FollowWatchdog()
{
}

// @STUB(M2) @SYS-NAV-WATCHDOG legacy:KF2BotsFollowNavBase.FollowRequestDispatch
function FollowRequestDispatch()
{
}

// @STUB(M2) @SYS-NAV-LEADER legacy:KF2BotsFollowNavBase.FollowRefreshLeader
function bool FollowRefreshLeader()
{
}

// @STUB(M2) @SYS-NAV-LEADER legacy:KF2BotsFollowNavBase.FollowGetArrivalRadius
function float FollowGetArrivalRadius()
{
}

// @STUB(M2) @SYS-NAV-LEADER legacy:KF2BotsFollowNavBase.FollowEvalArrived
function bool FollowEvalArrived()
{
}

// @STUB(M2) @SYS-NAV-LEADER legacy:KF2BotsFollowNavBase.FollowCheckReachable
function bool FollowCheckReachable(bool bForceNow)
{
}

// @STUB(M2) @SYS-NAV-PATH legacy:KF2BotsFollowNavBase.FollowBuildPath
function bool FollowBuildPath()
{
}

// @STUB(M2) @SYS-NAV-PATH legacy:KF2BotsFollowNavBase.FollowGetNextNode
function Actor FollowGetNextNode()
{
}

// @STUB(M2) @SYS-NAV-DECIDE legacy:KF2BotsFollowNavBase.FollowDecide
function EFollowAction FollowDecide()
{
}

// @STUB(M2) @SYS-NAV-PATH legacy:KF2BotsFollowNavBase.FollowOnMoveBegin
function FollowOnMoveBegin(bool bDirect)
{
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
}

// @STUB(M2) @SYS-NAV-HANDLE legacy:KF2BotsFollowNavBase.NotifyBump
event bool NotifyBump(Actor Other, vector HitNormal)
{
}

// @STUB(M2) @SYS-NAV-HANDLE legacy:KF2BotsFollowNavBase.MoveUnreachable
event MoveUnreachable(vector AttemptedDest, Actor AttemptedTarget)
{
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
