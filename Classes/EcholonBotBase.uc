class EcholonBotBase extends EcholonFollowNavBase hidecategories(Navigation);

// Constants: generated from contracts/constants.json (D2). Edit there, not here.
const CQB_TRACE_RADIUS_SQ = 90000.0;
const CQB_TRACE_INTERVAL = 1.0;
const CQB_PROBE_DIST = 150.0;
const STUCK_SAMPLE_INTERVAL = 3.0;
const STUCK_DIST_SQ = 10000.0;
const DOOR_CHECK_RADIUS = 200.0;
const SINGLE_FILE_SPACING = 130.0;
const PERIMETER_RADIUS = 220.0;
const DEG_TO_RAD = 0.0174532925;
const SYG_DISTANCE_SQ = 1000000.0;
const BOSS_HEALTH_THRESHOLD = 5000;
const RETREAT_ZED_RADIUS = 500.0;
const RETREAT_ZED_TRIGGER_COUNT = 4;
const RETREAT_ZED_CLEAR_COUNT = 2;
const RETREAT_HEAVY_RADIUS = 300.0;
const FOLLOWER_DRIFT_SQ = 250000.0;
const OBJ_BAIL_COOLDOWN = 8.0;
const FOLLOW_ESCAPE_COOLDOWN = 1.5;
const HUNT_ZED_THRESHOLD = 15;
const HUNT_SCAN_RADIUS = 5000.0;
const GLOBAL_ZED_RADIUS = 8000.0;
const GLOBAL_ZED_COUNT_INTERVAL = 3.0;
const TRIAGE_INTERVAL = 2.0;
const VIP_TRIAGE_GATE_PCT = 50.0;
const VIP_TRIAGE_BONUS_PCT = 15.0;
const HEAL_MAX_NEED_PCT = 80.0;
const HEAL_MIN_NEED_PCT = 60.0;
const ENEMY_SCAN_INTERVAL = 0.5;
const ENEMY_SCAN_RADIUS = 1500.0;
const SPOT_RADIUS_SQ = 4000000.0;
const LEASH_DROP_DIST_SQ = 5760000.0;
const LEASH_COOLDOWN = 2.0;
const ZED_COUNT_INTERVAL = 1.0;
const OBJECTIVE_HAZARD_RADIUS = 800.0;
const OBJECTIVE_HAZARD_ZED_COUNT = 3;
const SIREN_CHECK_RADIUS = 1200.0;
const TRADER_MAX_RETRIES = 3;
const TRADER_GIVEUP_COOLDOWN = 10.0;
const AUDIT_INTENT_TIMEOUT = 10.0;
const AUDIT_HUB_TIMEOUT = 20.0;
const AUDIT_IDLE_STUCK_DELTA = 50.0;
const AUDIT_ATTACH_RADIUS = 3000.0;
const AUDIT_WD_PERIOD = 1.5;
const AUDIT_WD_STEP_COOLDOWN = 5.0;
const REGROUP_DURATION = 5.0;
const REGROUP_HARD_TIMEOUT = 6.0;
const REGROUP_HOLD_DIST_SQ = 10000.0;
const TRADER_ROAM_RADIUS = 3000.0;
const TRADER_ROAM_RADIUS_SQ = 9000000.0;
const TRADER_REFORM_REMAINING = 5.0;
const FORM_SCAN_DIST = 150.0;
const FORM_LINE_DIST = 650.0;
const BOTFM_PRIMARY = 0;
const BOTFM_RELOAD = 2;
const BOTFM_BASH = 3;
const BOTFM_GRENADE = 4;
const OW_TOGGLE_INTERVAL = 1.5;
const OW_STUCK_TIME = 1.0;
const OW_STUCK_MIN_DIST_SQ = 10000.0;
const OW_STUCK_MOVE_SQ = 900.0;
const SW_ARRIVE_SQ = 22500.0;
const SW_SCAN_AMP_DEG = 15.0;
const SW_SCAN_OMEGA = 1.5707963;
const SW_TWO_PI = 6.2831853;
const SW_DEG_TO_URU = 182.0444;
const CQB_BASH_SQ = 14400.0;
const CQB_MID_SQ = 32400.0;
const CQB_BASH_INTERVAL = 0.8;
const CQB_STEPBACK_SPEED = 100.0;
const COVER_RANGE_SQ = 640000.0;
const RESCUE_RANGE_SQ = 1000000.0;
const RESCUE_DURATION = 5.0;
const HEAR_RANGE_SQ = 4000000.0;
const PANIC_MULT = 2.0;
const PANIC_SCATTER_MIN = 200.0;
const PANIC_SCATTER_MAX = 400.0;
const RELOAD_DRIFT_DIST = 100.0;
const RELOAD_DRIFT_LEASE = 1.0;
const HUMAN_BOUND_INTERVAL = 1.5;
const HUMAN_PUSH_DOT = 0.5;
const HUMAN_MIN_SPEED_SQ = 10000.0;
const HUMAN_LT_RANGE_SQ = 250000.0;
const WEDGE_REAR_OFFSET = 150.0;
const WEDGE_LEASE = 2.5;
const EMOTE_RADIUS_SQ = 22500.0;
const EMOTE_CHANCE = 0.30;
const EMOTE_ROLL_COOLDOWN = 6.0;
const BREATH_OMEGA = 0.3;
const DRIFT_RATE = 0.8333333;
const DRIFT_MIN_DIST_SQ = 10000.0;
const DRIFT_MAX_TOTAL = 300.0;

enum EBotRank { GRUNT, SQUAD_LEADER, LIEUTENANT, CAPTAIN, };

struct FRouteDoorBlockade { var KFDoorActor door; var NavigationPoint Path; };

var array<FRouteDoorBlockade> DoorPaths;
var array<NavigationPoint> BotBlockRoutes;
var byte PlayStyle;
var Actor AssignedAnchor;
var EBotRank BotRank;
var EcholonBot SquadLeader;
var vector LastValidSquadLeaderPos;
var float LastValidSLTime;
var int BlockedCounter;
var bool bPromotionGapTimerActive;
var int GroupID;
var bool bIsGroupLeader;
var bool bIsAlphaCommander;
var bool bSingleFileFormation;
var float LastCQBCheckTime;
var bool bIsStuck;
var bool bAttemptingUnweld;
var bool bHasStuckBaseline;
var vector LeaderLocation3SecAgo;
var float LastStuckSampleTime;
var float LastRouteDist;
var transient byte CallStack;
var byte MoveFlags;
var byte HealingStage;
var byte FailedMoveCount;
var byte DoshDropCounter;
var int CurrentLevel;
var Class<KFPerk> Perk;
var Class<KFWeapon> FavoriteWeapon;
var EcholonMut mut;
var KFCharacterInfo_Human CharacterArch;
var KFPawn_Human KPawn;
var KFPawn_Human PendingHeal;
var Pawn FollowingHuman;
var Pawn DonateHuman;
var KFInventoryManager KFInvManager;
var KFGameReplicationInfo KFGRI;
var transient KFWeap_HealerBase MedicGun;
var transient KFWeap_MedicBase RangeMedicGun;
var transient bool bHealFired;
var transient float LastHealFireTime;
var transient float LastCallTimer;
var transient float EndMoveTime;
var transient float SerpentineTime;
var transient float NextGrenadeTimer;
var transient float EnemyEncounterTime;
var transient float NextShoppingTime;
var transient float ObjectiveBailUntil;
var transient float LastNodeBlockTime;
var int NodeBlockCount;
var transient float NextAdjustTime;
var transient float MovePauseTime;
var transient float TempBlockTime;
var transient float NextVictoryDance;
var transient float NextDoshShareTime;
var transient float GrabStartTime;
var transient int BreakFreeAttempts;
var transient float NextEscapeAttempt;
var transient bool bGrappleFailsafeTriggered;
var transient KFPickupFactory LastFactory;
var transient Vector PrevMovePos;
var NavigationPoint RandGoal;
var NavigationPoint ObjectiveGoal;
var NavigationPoint LastFailedMove;
var NavigationPoint TempBlockPath;
var Actor Target;
var bool bSerpentineMove;
var bool bSerpentLeft;
var bool bBossKillVictory;
var bool bInTerminalState;
var bool bIsRetreating;
var float LastZedCountTime;
var int CachedZedCount;
var bool bCachedHeavyZed;
var float LastFollowEscapeTime;
var int GlobalZedCount;
var float LastGlobalZedCountTime;
var float AuditStateEntryTime;
var name AuditStateEntryName;
var float AuditDwellTotal;
var float AuditLastLog_STATE_EXIT;
var float AuditLastLog_GOAL;
var float AuditLastLog_FOLLOWGATE;
var float AuditLastLog_GEN;
var float AuditLastLog_DWELLTOT;
var bool bHasHoldPosition;
var vector HoldPosition;
var float LastTriageTime;
var float SyringeRechargeEnd;
var float HealPacingEnd;
var float HealRetryAfter;
var int FailStreak;
var float landingDeadline;
var float equipDeadline;
var bool bJustSpawned;
var string BasePlayerName;
var float LastEnemyScanTime;
var float LastLeashDropTime;
var int TraderRetryCount;
var bool bOverwatchPhase;
var vector EngageAnchor;
var bool bEngageActive;
var float EngageExpireTime;
var bool PanicActive;
var NavigationPoint CachedRoutePoint;
var array<EcholonBot> Subordinates;
var EcholonBot Supervisor;
var int PathTokensUsed;
var float PathTokenResetTime;
var name CurrentFormation;
var name PendingFormation;
var byte PendingFormationCount;
var byte ScanMask;
var int FormationEpoch;
var int FormationYaw;
var float FormationHoldUntil;
var float LastRerouteTime;
var bool bRerouteRequested;
var bool bSquadCrouchHold;
var bool bHoldCrouching;
var Pawn InheritedEnemy;
var transient bool bFormationScanDeferred;
var transient float LastFormationScanTime;
var transient float NextFireLineCheck;
var transient bool bFireLineClear;
var transient Actor FireLineTarget;
var transient bool bOffsetCached;
var transient Vector CachedLocalOffset;
var transient int CachedOffsetEpoch;
var transient int CachedOffsetSlot;
var transient name CachedOffsetFormation;
var transient int LastFormationYaw;
var transient float LastOffsetUpdate;
var transient float LastHealthCheck;
var int GruntSlot;
var Pawn SquadZedCache[16];
var byte SquadZedCount;
var bool GrenadeSignal;
var byte GrenadeThrowsLeft;
var Pawn GrenadeTargetPawn;
var float NextGrenadeSignalTime;
var int HearNoiseZedCount;
var float HearNoiseExpireTime;
var Vector LastNoiseLoc;
var bool bOutOfEffectiveRange;
var bool bFallbackWeapon;
var bool bFallbackHadSpare;
var byte BlockedShooterCount;
var float BlockedShooterWindowStart;
var float LineSuppressUntil;
var transient KFWeapon RangeCacheWeapon;
var transient float RangeCacheSq;
var float ShotgunEffectiveRangeUU;
var float FlamethrowerEffectiveRangeUU;
var float DefaultWeaponEffectiveRangeUU;
var transient float NextReloadAttempt;
var transient float NextWeaponSwitchTime;
var transient float NextFallbackPoll;
var transient KFWeapon FallbackPrimary;
var transient float FallbackSince;
var transient byte GrenadeAimTicks;
var float OverwatchResetUntil;
var byte StuckCounter;
var bool GruntOverwatchPhase, bOverwatchAllMove, bOverwatchMoving, bOverwatchLOS, bGruntMeleeStyle;
var byte OverwatchSlot;
var vector OverwatchOffset, OverwatchSamplePos, RescueLoc;
var float OverwatchSampleTime, OverwatchStuckTime, NextOverwatchLOSTime;
var float SectorScanPhase, SectorLastTime, NoiseGlanceUntil, NextBashTime, RescueUntil, StyleCrouchUntil;
var int LastValidSquadLeaderYaw;
var EcholonBot SquadMembers[4];
var name CurrentOrder;
var vector OrderAnchor;
var array<EcholonBot> SquadLeaders;
var float PanicVarianceMultiplier, PanicScanSpeedMultiplier;
var bool bWasReloading, bReloadDriftMove, bReloadPullClear;
var float ReloadDriftUntil, ReloadPullStamp;
var vector ReloadDriftLoc, ReloadDriftOffset, ReloadPullAnchor, HoldAreaAnchor;
var bool bWedgeActive;
var KFPawn_Human WedgeHuman;
var float WedgeExpireTime;
var bool bPlayingEmote;
var float NextEmoteRollTime;
var bool bSLLoopSuspended;
var float BreathingPhase, PanicFlashUntil, LastDriftTime, HoldDriftDist;
var vector PanicFlashLoc;
var bool bWdEscalating;
var int WdEscStep;
var float WdLastMoveIntentTime;
var float WdLastHubContactTime;
var float WdLastStepTime;
var float WdProgressGoalD2;
var vector WdIdleStartLoc;

// @STUB(M3) @SYS-BASE-BOOT legacy:KF2BotBase.PreBeginPlay
simulated function PreBeginPlay()
{
    // BRIDGE(M1): minimal engine pass-through so bots spawn; replaced by the full port in M3.
    local Mutator M;

    for (M = WorldInfo.Game.BaseMutator; M != None; M = M.NextMutator)
    {
        mut = EcholonMut(M);
        if (mut != None)
        {
            break;
        }
    }
    super.PreBeginPlay();
    WorldInfo.Game.NumBots++;
    KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
    if (mut != None)
    {
        mut.RegisterBot(EcholonBot(self));
    }
    bJustSpawned = true;
}

// @STUB(M3) @SYS-BASE-BOOT legacy:KF2BotBase.Destroyed
simulated function Destroyed()
{
    // BRIDGE(M1): minimal engine pass-through so bots spawn; replaced by the full port in M3.
    super(Controller).Destroyed();
    WorldInfo.Game.NumBots--;
    if (mut != None)
    {
        mut.UnregisterBot(EcholonBot(self));
    }
}

// @STUB(M3) @SYS-BASE-BOOT legacy:KF2BotBase.InitPlayerReplicationInfo
function InitPlayerReplicationInfo()
{
    // BRIDGE(M1): minimal engine pass-through so bots spawn; replaced by the full port in M3.
    local KFGameInfo KFGI;
    local KFPlayerReplicationInfo KFPRI;

    super(Controller).InitPlayerReplicationInfo();
    if (PlayerReplicationInfo != None)
    {
        PlayerReplicationInfo.bBot = false;
        PlayerReplicationInfo.bOnlySpectator = false;
        if (PlayerReplicationInfo.PlayerName == "")
        {
            PlayerReplicationInfo.PlayerName = "Bot_" $ Rand(9999);
        }
        KFPRI = KFPlayerReplicationInfo(PlayerReplicationInfo);
        if (KFPRI != None)
        {
            KFPRI.bHasSpawnedIn = true;
        }
        KFGI = KFGameInfo(WorldInfo.Game);
        if (KFGI != None && KFGI.Teams[0] != None)
        {
            KFGI.SetTeam(self, KFGI.Teams[0]);
        }
        if (WorldInfo.GRI != None)
        {
            WorldInfo.GRI.AddPRI(PlayerReplicationInfo);
        }
    }
    if (mut != None)
    {
        mut.InitBotCharacter(EcholonBot(self));
    }
}

// @STUB(M3) @SYS-BASE-BOOT legacy:KF2BotBase.GiveWeaponDef
final function GiveWeaponDef(Class<KFWeaponDefinition> W)
{
    // BRIDGE(M1): minimal engine pass-through so bots spawn; replaced by the full port in M3.
    local Class<Weapon> WC;

    if (W == None)
    {
        return;
    }
    WC = Class<Weapon>(DynamicLoadObject(W.default.WeaponClassPath, Class'Core.Class'));
    if (WC != None)
    {
        Pawn.InvManager.CreateInventory(WC);
    }
}

// @STUB(M3) @SYS-BASE-BOOT legacy:KF2BotBase.Restart
function Restart(bool bVehicleTransition)
{
    // BRIDGE(M1): minimal engine pass-through so bots spawn; replaced by the full port in M3.
    NextShoppingTime = WorldInfo.TimeSeconds - 1.0;
    if (KFInventoryManager(Pawn.InvManager) != None && Pawn.InvManager.Class != Class'EcholonBot.EcholonInventoryManager')
    {
        Pawn.InvManager.Destroy();
        Pawn.InvManager = Spawn(Class'EcholonBot.EcholonInventoryManager', Pawn);
        Pawn.InvManager.SetupFor(Pawn);
    }
    super(Controller).Restart(bVehicleTransition);
    BotRank = GRUNT;
    bIsGroupLeader = false;
    KPawn = KFPawn_Human(Pawn);
    if (Pawn.Physics == PHYS_None)
    {
        Pawn.SetPhysics(PHYS_Falling);
    }
    KFInvManager = KFInventoryManager(Pawn.InvManager);
    if (KFInvManager != None)
    {
        if (Perk != None)
        {
            GiveWeaponDef(Perk.default.PrimaryWeaponDef);
            GiveWeaponDef(Perk.default.SecondaryWeaponPaths[Rand(Perk.default.SecondaryWeaponPaths.Length)]);
            GiveWeaponDef(Perk.default.KnifeWeaponDef);
            GiveWeaponDef(Perk.default.GrenadeWeaponDef);
        }
        KFInvManager.GrenadeCount = 2;
    }
    if (KFPlayerReplicationInfo(PlayerReplicationInfo) != None)
    {
        KFPlayerReplicationInfo(PlayerReplicationInfo).bHasSpawnedIn = true;
    }
}

// @STUB(M3) @SYS-BASE-PERCEPT legacy:KF2BotBase.NotifyTakeHit
function NotifyTakeHit(Controller InstigatedBy, Vector HitLocation, int Damage, Class<DamageType> DamageType, Vector Momentum)
{
    // BRIDGE(M1): minimal engine pass-through so bots spawn; replaced by the full port in M3.
    super.NotifyTakeHit(InstigatedBy, HitLocation, Damage, DamageType, Momentum);
}

// @STUB(M3) @SYS-BASE-PERCEPT legacy:KF2BotBase.SeePlayer
function SeePlayer(Pawn Seen)
{
    // BRIDGE(M1): minimal engine pass-through so bots spawn; replaced by the full port in M3.
    super.SeePlayer(Seen);
}

// @STUB(M3) @SYS-BASE-PERCEPT legacy:KF2BotBase.SeeMonster
function SeeMonster(Pawn Seen)
{
    // PASS-THROUGH: overrides Controller; keep the engine behaviour until the real port lands.
    super.SeeMonster(Seen);
}

// @STUB(M3) @SYS-BASE-PERCEPT legacy:KF2BotBase.NotifyBump
event bool NotifyBump(Actor Other, Vector HitNormal)
{
    // PASS-THROUGH: overrides Controller; keep the engine behaviour until the real port lands.
    return super.NotifyBump(Other, HitNormal);
}

// @STUB(M3) @SYS-BASE-PERCEPT legacy:KF2BotBase.TargetLowHealth
final function bool TargetLowHealth(Pawn Other)
{
}

// @STUB(M3) @SYS-BASE-PERCEPT legacy:KF2BotBase.EyeSightCheck
function EyeSightCheck()
{
}

// @STUB(M3) @SYS-BASE-PERCEPT legacy:KF2BotBase.PickNextEnemy
final function bool PickNextEnemy()
{
}

// @STUB(M3) @SYS-BASE-PERCEPT legacy:KF2BotBase.SetEnemy
function bool SetEnemy(Pawn Other, optional bool bNoNotify)
{
}

// @STUB(M3) @SYS-BASE-PERCEPT legacy:KF2BotBase.GetEnemyThreat
function float GetEnemyThreat(Pawn Other)
{
}

// @STUB(M3) @SYS-BASE-FIRE legacy:KF2BotBase.FireWeaponAt
function bool FireWeaponAt(Actor inActor)
{
    // PASS-THROUGH: overrides Controller; keep the engine behaviour until the real port lands.
    return super.FireWeaponAt(inActor);
}

// @STUB(M3) @SYS-BASE-OBJ legacy:KF2BotBase.TryBreakFree
final function TryBreakFree()
{
}

// @STUB(M3) @SYS-BASE-FIRE legacy:KF2BotBase.SimulateBashHit
final function SimulateBashHit(KFPawn TargetZed, KFWeapon W)
{
}

// @STUB(M5b) @SYS-BASE-HEALQ legacy:KF2BotBase.EnemyChanged
function EnemyChanged()
{
}

// @STUB(M3) @SYS-BASE-SHOP legacy:KF2BotBase.DonateMoney
function DonateMoney(Pawn Other)
{
}

// @STUB(M3) @SYS-BASE-SHOP legacy:KF2BotBase.SwitchToBestWeapon
exec function SwitchToBestWeapon(optional bool bForceNewWeapon, optional bool check_9mm_logic = false)
{
    // PASS-THROUGH: overrides Controller; keep the engine behaviour until the real port lands.
    super.SwitchToBestWeapon(bForceNewWeapon, check_9mm_logic);
}

// @STUB(M3) @SYS-BASE-FIRE legacy:KF2BotBase.GetAdjustedAimFor
function Rotator GetAdjustedAimFor(Weapon W, Vector StartFireLoc)
{
    // PASS-THROUGH: overrides Controller; keep the engine behaviour until the real port lands.
    return super.GetAdjustedAimFor(W, StartFireLoc);
}

// @STUB(M3) @SYS-BASE-FIRE legacy:KF2BotBase.GetPlayerViewPoint
simulated function GetPlayerViewPoint(out Vector out_Location, out Rotator out_Rotation)
{
    // PASS-THROUGH: overrides AIController; keep the engine behaviour until the real port lands.
    super.GetPlayerViewPoint(out_Location, out_Rotation);
}

// @STUB(M3) @SYS-BASE-MOVE legacy:KF2BotBase.MoveToX
final function MoveToX(Vector Dest, optional Actor ViewFocus, optional bool bSerpent = true)
{
}

// @STUB(M3) @SYS-BASE-MOVE legacy:KF2BotBase.MoveTowardX
final function MoveTowardX(Actor Dest, optional Actor ViewFocus, optional bool bSerpent = true)
{
}

// @STUB(M3) @SYS-BASE-MOVE legacy:KF2BotBase.StrafeTowardPoint
final function StrafeTowardPoint(Vector Dest)
{
}

// @STUB(M3) @SYS-BASE-MOVE legacy:KF2BotBase.GetMoveDirection
final function Vector GetMoveDirection()
{
}

// @STUB(M3) @SYS-BASE-MOVE legacy:KF2BotBase.ProcessMoveTo
final function ProcessMoveTo()
{
}

// @STUB(M3) @SYS-BASE-MOVE legacy:KF2BotBase.ProcessMoveToward
final function ProcessMoveToward()
{
}

// @STUB(M3) @SYS-BASE-MOVE legacy:KF2BotBase.AbortMove
final function AbortMove()
{
}

// @STUB(M3) @SYS-BASE-MOVE legacy:KF2BotBase.CheckBlockedPath
final function CheckBlockedPath(Actor Start, NavigationPoint End)
{
}

// @STUB(M3) @SYS-BASE-MOVE legacy:KF2BotBase.FollowNotifyHub
function FollowNotifyHub(EFollowStatus NewStatus)
{
    // PASS-THROUGH: overrides EcholonFollowNavBase; keep the engine behaviour until the real port lands.
    super.FollowNotifyHub(NewStatus);
}

// @STUB(M3) @SYS-BASE-MOVE legacy:KF2BotBase.FollowOnGaveUp
function FollowOnGaveUp()
{
    // PASS-THROUGH: overrides EcholonFollowNavBase; keep the engine behaviour until the real port lands.
    super.FollowOnGaveUp();
}

// @STUB(M3) @SYS-BASE-MOVE legacy:KF2BotBase.Tick
function Tick(float Delta)
{
    // PASS-THROUGH: overrides Actor; keep the engine behaviour until the real port lands.
    super.Tick(Delta);
}

// @STUB(M3) @SYS-BASE-PATH legacy:KF2BotBase.MarkDoorPath
final function bool MarkDoorPath(KFDoorActor door)
{
}

// @STUB(M3) @SYS-BASE-PATH legacy:KF2BotBase.BuildPathToward
final function bool BuildPathToward(Actor Other)
{
}

// @STUB(M3) @SYS-BASE-PATH legacy:KF2BotBase.BuildPathTo
final function bool BuildPathTo(Vector Dest)
{
}

// @STUB(M3) @SYS-BASE-PATH legacy:KF2BotBase.BuildRandomPath
final function bool BuildRandomPath()
{
}

// @STUB(M3) @SYS-BASE-FIRE legacy:KF2BotBase.StopAdjusting
function StopAdjusting()
{
}

// @STUB(M3) @SYS-BASE-FIRE legacy:KF2BotBase.NeedToTurn
final function bool NeedToTurn(Vector targ)
{
}

// @STUB(M3) @SYS-BASE-PERCEPT legacy:KF2BotBase.NotifyHitWall
event bool NotifyHitWall(Vector HitNormal, Actor Wall)
{
    // PASS-THROUGH: overrides Controller; keep the engine behaviour until the real port lands.
    return super.NotifyHitWall(HitNormal, Wall);
}

// @STUB(M3) @SYS-BASE-MOVE legacy:KF2BotBase.FinishedMove
function FinishedMove()
{
}

// @STUB(M3) @SYS-BASE-MOVE legacy:KF2BotBase.PickFavorite
final function PickFavorite()
{
}

// @STUB(M3) @SYS-BASE-SHOP legacy:KF2BotBase.SellWeapon
final function bool SellWeapon(KFWeapon W, out int Dosh)
{
}

// @STUB(M3) @SYS-BASE-SHOP legacy:KF2BotBase.GetBestBuy
final function EcholonWeaponInfo GetBestBuy(int Cash)
{
}

// @STUB(M3) @SYS-BASE-SHOP legacy:KF2BotBase.ProcessPurchase
final function ProcessPurchase(KFGFxObject_TraderItems L)
{
}

// @STUB(M3) @SYS-BASE-SHOP legacy:KF2BotBase.NotifyAddInventory
function NotifyAddInventory(Inventory NewItem)
{
    // PASS-THROUGH: overrides Controller; keep the engine behaviour until the real port lands.
    super.NotifyAddInventory(NewItem);
}

// @STUB(M3) @SYS-BASE-MOVE legacy:KF2BotBase.PickCombatStyle
function PickCombatStyle()
{
}

// @STUB(M3) @SYS-BASE-BOOT legacy:KF2BotBase.ValidateAndNudgeSpawn
function ValidateAndNudgeSpawn()
{
}

// @STUB(M3) @SYS-BASE-BOOT legacy:KF2BotBase.IsOnWalkableFloor
function bool IsOnWalkableFloor()
{
}

// @STUB(M5a) @SYS-BASE-FORM legacy:KF2BotBase.ComputeFormationOffset
function vector ComputeFormationOffset(EcholonBot Leader, bool bSingleFile)
{
}

// @STUB(M3) @SYS-BASE-ZEDS legacy:KF2BotBase.CountNearbyZeds
final function int CountNearbyZeds(float Radius)
{
}

// @STUB(M3) @SYS-BASE-ZEDS legacy:KF2BotBase.AreZedsNear
final function bool AreZedsNear(vector Loc, bool bRequireCanSee, float CheckRadius, int MinimalCount)
{
}

// @STUB(M3) @SYS-BASE-ZEDS legacy:KF2BotBase.HeavyZedWithin
final function bool HeavyZedWithin(float Radius)
{
}

// @STUB(M3) @SYS-BASE-ZEDS legacy:KF2BotBase.ShouldTacticalRetreat
final function bool ShouldTacticalRetreat()
{
}

// @STUB(M3) @SYS-BASE-FIRE legacy:KF2BotBase.IsMeleeOnly
final function bool IsMeleeOnly()
{
}

// @STUB(M3) @SYS-BASE-OBJ legacy:KF2BotBase.CheckObjectiveHazard
final function bool CheckObjectiveHazard()
{
}

// @STUB(M3) @SYS-BASE-OBJ legacy:KF2BotBase.ForceBreakGrapple
final function ForceBreakGrapple()
{
}

// @STUB(M5b) @SYS-BASE-HEALQ legacy:KF2BotBase.IsBotAlive
function bool IsBotAlive()
{
}

// @STUB(M5b) @SYS-BASE-HEALQ legacy:KF2BotBase.CanHealOthers
function bool CanHealOthers()
{
}

// @STUB(M5b) @SYS-BASE-HEALQ legacy:KF2BotBase.IsHealLockedOut
function bool IsHealLockedOut()
{
}

// @STUB(M5b) @SYS-BASE-HEALQ legacy:KF2BotBase.ShouldAbortRetreat
function bool ShouldAbortRetreat()
{
}

// @STUB(M3) @SYS-BASE-OBJ legacy:KF2BotBase.GetObjectiveLocation
function vector GetObjectiveLocation()
{
}

// @STUB(M3) @SYS-BASE-OBJ legacy:KF2BotBase.IsBossWaveActive
function bool IsBossWaveActive()
{
}

// @STUB(M3) @SYS-BASE-BOOT legacy:KF2BotBase.EchelonLog
function EchelonLog(string Msg)
{
}

// @STUB(M5b) @SYS-BASE-AUDIT legacy:KF2BotBase.AuditRateLimit
function bool AuditRateLimit(string Msg)
{
}

// @STUB(M5b) @SYS-BASE-AUDIT legacy:KF2BotBase.FollowGetOrderAnchor
function bool FollowGetOrderAnchor(out vector OutLoc)
{
    // PASS-THROUGH: overrides EcholonFollowNavBase; keep the engine behaviour until the real port lands.
    return super.FollowGetOrderAnchor(OutLoc);
}

// @STUB(M5b) @SYS-BASE-AUDIT legacy:KF2BotBase.AuditStateEntry
function AuditStateEntry()
{
}

// @STUB(M5b) @SYS-BASE-AUDIT legacy:KF2BotBase.AuditStateExit
function AuditStateExit(name NextStateName)
{
}

// @STUB(M5b) @SYS-BASE-AUDIT legacy:KF2BotBase.AuditGoalLog
function AuditGoalLog(string Op, string Src)
{
}

// @STUB(M3) @SYS-BASE-RANK legacy:KF2BotBase.IssueCommand
function IssueCommand(name Cmd, Vector Anchor)
{
}

// @STUB(M3) @SYS-BASE-RANK legacy:KF2BotBase.SLDecisionLoop
function SLDecisionLoop()
{
}

// @STUB(M3) @SYS-BASE-RANK legacy:KF2BotBase.LTDispatchLoop
function LTDispatchLoop()
{
}

// @STUB(M5a) @SYS-BASE-FORM legacy:KF2BotBase.ScanRoomForFormation
final function ScanRoomForFormation()
{
}

// @STUB(M5a) @SYS-BASE-FORM legacy:KF2BotBase.DeferredFormationScan
function DeferredFormationScan()
{
}

// @STUB(M5a) @SYS-BASE-FORM legacy:KF2BotBase.GetFormationBase
final function Vector GetFormationBase(int Slot, name Formation, bool bMirror)
{
}

// @STUB(M5a) @SYS-BASE-FORM legacy:KF2BotBase.ComputeSlotOffset
function Vector ComputeSlotOffset(optional int Slot = - 1)
{
}

// @STUB(M5a) @SYS-BASE-OVERWATCH legacy:KF2BotBase.SyncLineFocus
final function bool SyncLineFocus()
{
}

// @STUB(M5a) @SYS-BASE-OVERWATCH legacy:KF2BotBase.HasOwnFireLine
final function bool HasOwnFireLine(Actor T)
{
}

// @STUB(M5a) @SYS-BASE-FORM legacy:KF2BotBase.ValidateOffsetTarget
final function bool ValidateOffsetTarget(Vector OffsetTarget)
{
}

// @STUB(M5a) @SYS-BASE-FORM legacy:KF2BotBase.RequestRerouteWithBlock
function RequestRerouteWithBlock(Vector BlockedPos)
{
}

// @STUB(M5a) @SYS-BASE-FORM legacy:KF2BotBase.IsDirClearCached
final function bool IsDirClearCached(Vector Dest)
{
}

// @STUB(M3) @SYS-BASE-ZEDS legacy:KF2BotBase.IsRetreatSafe
final function bool IsRetreatSafe(Vector RetreatDest)
{
}

// @STUB(M5a) @SYS-BASE-CQB legacy:KF2BotBase.SetSquadCrouchHold
final function SetSquadCrouchHold()
{
}

// @STUB(M5a) @SYS-BASE-CQB legacy:KF2BotBase.ClearSquadCrouchHold
function ClearSquadCrouchHold()
{
}

// @STUB(M5a) @SYS-BASE-CQB legacy:KF2BotBase.HoldAndCrouch
final function HoldAndCrouch()
{
}

// @STUB(M5a) @SYS-BASE-CQB legacy:KF2BotBase.TryIssueSafeAnchor
final function bool TryIssueSafeAnchor(Vector NewAnchor)
{
}

// @STUB(M5a) @SYS-BASE-CQB legacy:KF2BotBase.ApplySquadCrouchHold
final function ApplySquadCrouchHold()
{
}

// @STUB(M3) @SYS-BASE-RANK legacy:KF2BotBase.ClearRankTimers
final function ClearRankTimers()
{
}

// @STUB(M3) @SYS-BASE-RANK legacy:KF2BotBase.GetRankName
final function name GetRankName()
{
}

// @STUB(M3) @SYS-BASE-RANK legacy:KF2BotBase.UpdateRoleNameTag
final function UpdateRoleNameTag()
{
}

// @STUB(M3) @SYS-BASE-RANK legacy:KF2BotBase.RefreshRoleNameTag
final function RefreshRoleNameTag()
{
}

// @STUB(M3) @SYS-BASE-RANK legacy:KF2BotBase.SeedGruntGates
final function SeedGruntGates()
{
}

// @STUB(M3) @SYS-BASE-RANK legacy:KF2BotBase.ArmRankTimers
final function ArmRankTimers()
{
}

// @STUB(M3) @SYS-BASE-RANK legacy:KF2BotBase.StartSLLoop
function StartSLLoop()
{
}

// @STUB(M3) @SYS-BASE-RANK legacy:KF2BotBase.StartLTLoop
function StartLTLoop()
{
}

// @STUB(M3) @SYS-BASE-RANK legacy:KF2BotBase.StartCaptainLoop
function StartCaptainLoop()
{
}

// @STUB(M3) @SYS-BASE-RANK legacy:KF2BotBase.SetBotRank
final function SetBotRank(EBotRank NewRank)
{
}

// @STUB(M5a) @SYS-BASE-OVERWATCH legacy:KF2BotBase.NotifyBlockedShooter
final function NotifyBlockedShooter(EcholonBot Shooter)
{
}

// @STUB(M5b) @SYS-BASE-WEAPON legacy:KF2BotBase.ShouldReload
final function bool ShouldReload(KFWeapon W)
{
}

// @STUB(M5b) @SYS-BASE-WEAPON legacy:KF2BotBase.GetWeaponEffectiveRangeUU
final function float GetWeaponEffectiveRangeUU(KFWeapon W)
{
}

// @STUB(M5b) @SYS-BASE-WEAPON legacy:KF2BotBase.IsInEffectiveRange
final function bool IsInEffectiveRange(Actor T)
{
}

// @STUB(M5b) @SYS-BASE-WEAPON legacy:KF2BotBase.CloseToEffectiveRange
final function CloseToEffectiveRange()
{
}

// @STUB(M5b) @SYS-BASE-WEAPON legacy:KF2BotBase.CheckWeaponReequip
final function CheckWeaponReequip()
{
}

// @STUB(M5b) @SYS-BASE-WEAPON legacy:KF2BotBase.ShouldThrowGrenade
final function bool ShouldThrowGrenade(out Actor Aim, bool bFromSignal, Actor CurEnemy)
{
}

// @STUB(M5b) @SYS-BASE-WEAPON legacy:KF2BotBase.TryThrowGrenade
final function bool TryThrowGrenade(KFWeapon W, Actor CurEnemy)
{
}

// @STUB(M5b) @SYS-BASE-WEAPON legacy:KF2BotBase.SLGrenadeCheck
function SLGrenadeCheck()
{
}

// @STUB(M5b) @SYS-BASE-WEAPON legacy:KF2BotBase.SLGrenadeLOSPhase
function SLGrenadeLOSPhase()
{
}

// @STUB(M5b) @SYS-BASE-WEAPON legacy:KF2BotBase.ClearGrenadeSignal
function ClearGrenadeSignal()
{
}

// @STUB(M5b) @SYS-BASE-WEAPON legacy:KF2BotBase.HandleWeaponManagement
final function bool HandleWeaponManagement(KFWeapon W)
{
}

// @STUB(M3) @SYS-BASE-ZEDS legacy:KF2BotBase.CountNearbyZedsCached
final function int CountNearbyZedsCached(float Radius)
{
}

// @STUB(M3) @SYS-BASE-ZEDS legacy:KF2BotBase.RefreshSquadZedCache
final function RefreshSquadZedCache()
{
}

// @STUB(M5a) @SYS-BASE-CQB legacy:KF2BotBase.ApplyCrouch
final function ApplyCrouch(bool bWant)
{
}

// @STUB(M3) @SYS-BASE-PERCEPT legacy:KF2BotBase.IsHostileZed
final function bool IsHostileZed(Pawn P)
{
}

// @STUB(M5a) @SYS-BASE-OVERWATCH legacy:KF2BotBase.ToggleOverwatchPhase
function ToggleOverwatchPhase()
{
}

// @STUB(M5a) @SYS-BASE-OVERWATCH legacy:KF2BotBase.BroadcastOverwatchState
function BroadcastOverwatchState()
{
}

// @STUB(M5a) @SYS-BASE-FORM legacy:KF2BotBase.AssignSquadSlots
function AssignSquadSlots()
{
}

// @STUB(M5a) @SYS-BASE-OVERWATCH legacy:KF2BotBase.UpdateOverwatchTimer
function UpdateOverwatchTimer()
{
}

// @STUB(M5a) @SYS-BASE-OVERWATCH legacy:KF2BotBase.CheckOverwatchStall
function CheckOverwatchStall()
{
}

// @STUB(M5a) @SYS-BASE-OVERWATCH legacy:KF2BotBase.ReceiveOverwatchState
function ReceiveOverwatchState(bool bPhase, byte InSlot, bool bAllMove)
{
}

// @STUB(M5a) @SYS-BASE-OVERWATCH legacy:KF2BotBase.IsOverwatchStuck
final function bool IsOverwatchStuck()
{
}

// @STUB(M5a) @SYS-BASE-OVERWATCH legacy:KF2BotBase.UpdateOverwatchMovement
function bool UpdateOverwatchMovement(out vector OutMovePos)
{
}

// @STUB(M5a) @SYS-BASE-OVERWATCH legacy:KF2BotBase.OnBreakLoseComplete
function OnBreakLoseComplete()
{
}

// @STUB(M5a) @SYS-BASE-OVERWATCH legacy:KF2BotBase.UpdateSectorWatch
function UpdateSectorWatch()
{
}

// @STUB(M5a) @SYS-BASE-CQB legacy:KF2BotBase.HandleCQBProximity
function HandleCQBProximity()
{
}

// @STUB(M5a) @SYS-BASE-GRUNT legacy:KF2BotBase.OnGruntGrabbed
function OnGruntGrabbed(EcholonBot GruntBot)
{
}

// @STUB(M5a) @SYS-BASE-GRUNT legacy:KF2BotBase.BeginRescue
function BeginRescue(vector GrabLoc, Pawn Grabber)
{
}

// @STUB(M5a) @SYS-BASE-CQB legacy:KF2BotBase.UpdateCoverCrouch
function UpdateCoverCrouch()
{
}

// @STUB(M5a) @SYS-BASE-GRUNT legacy:KF2BotBase.IsGruntCombatLocked
final function bool IsGruntCombatLocked()
{
}

// @STUB(M5a) @SYS-BASE-GRUNT legacy:KF2BotBase.GruntOnSight
function GruntOnSight(Pawn Seen)
{
}

// @STUB(M5a) @SYS-BASE-GRUNT legacy:KF2BotBase.GruntEnterCombat
function GruntEnterCombat(Pawn NewEnemy)
{
}

// @STUB(M5a) @SYS-BASE-GRUNT legacy:KF2BotBase.GruntPickCombatStyle
function GruntPickCombatStyle()
{
}

// @STUB(M3) @SYS-BASE-PERCEPT legacy:KF2BotBase.HearNoise
event HearNoise(float Loudness, Actor NoiseMaker, optional Name NoiseType)
{
    // BRIDGE(M1): minimal engine pass-through so bots spawn; replaced by the full port in M3.
    super.HearNoise(Loudness, NoiseMaker, NoiseType);
}

// @STUB(M3) @SYS-BASE-ZEDS legacy:KF2BotBase.IsHeavyZedPawn
final function bool IsHeavyZedPawn(Pawn P)
{
}

// @STUB(M5a) @SYS-BASE-PANIC legacy:KF2BotBase.UpdatePanicBroadcast
function UpdatePanicBroadcast()
{
}

// @STUB(M5a) @SYS-BASE-PANIC legacy:KF2BotBase.ReceivePanic
function ReceivePanic(bool bPanic)
{
}

// @STUB(M5a) @SYS-BASE-PANIC legacy:KF2BotBase.ApplyPanicVariance
function ApplyPanicVariance()
{
}

// @STUB(M5a) @SYS-BASE-RELOAD legacy:KF2BotBase.IsReloading
final function bool IsReloading()
{
}

// @STUB(M5a) @SYS-BASE-RELOAD legacy:KF2BotBase.HandleReloadDrift
function HandleReloadDrift()
{
}

// @STUB(M5a) @SYS-BASE-RELOAD legacy:KF2BotBase.ReceiveReloadDrift
function ReceiveReloadDrift(vector Anchor, bool bMove, float Lease)
{
}

// @STUB(M5a) @SYS-BASE-RELOAD legacy:KF2BotBase.OnReloadDriftAnchor
function OnReloadDriftAnchor(vector Anchor)
{
}

// @STUB(M5a) @SYS-BASE-RELOAD legacy:KF2BotBase.OnReloadComplete
function OnReloadComplete()
{
}

// @STUB(M5a) @SYS-BASE-RELOAD legacy:KF2BotBase.TrackReloadState
function TrackReloadState()
{
}

// @STUB(M5b) @SYS-BASE-LTBOUND legacy:KF2BotBase.StartLtHumanBounding
function StartLtHumanBounding()
{
}

// @STUB(M5b) @SYS-BASE-LTBOUND legacy:KF2BotBase.BeginLtHumanBounding
function BeginLtHumanBounding()
{
}

// @STUB(M5b) @SYS-BASE-LTBOUND legacy:KF2BotBase.LtHumanBoundLoop
function LtHumanBoundLoop()
{
}

// @STUB(M5b) @SYS-BASE-WEDGE legacy:KF2BotBase.ReceiveWedgeOrder
function ReceiveWedgeOrder(KFPawn_Human Human, vector WedgeCenter, float ExpireTime)
{
}

// @STUB(M5b) @SYS-BASE-WEDGE legacy:KF2BotBase.UpdateWedgeMode
function UpdateWedgeMode()
{
}

// @STUB(M5b) @SYS-BASE-WEDGE legacy:KF2BotBase.ClearWedge
function ClearWedge()
{
}

// @STUB(M5b) @SYS-BASE-WEDGE legacy:KF2BotBase.ComputeWedgeOffset
function vector ComputeWedgeOffset(int Slot, KFPawn_Human PlayerRef)
{
}

// @STUB(M5b) @SYS-BASE-WEDGE legacy:KF2BotBase.ApplyWedgeTarget
function ApplyWedgeTarget(out vector OutTarget)
{
}

// @STUB(M5b) @SYS-BASE-EMOTE legacy:KF2BotBase.StartEmoteEchoTimer
function StartEmoteEchoTimer()
{
}

// @STUB(M5b) @SYS-BASE-EMOTE legacy:KF2BotBase.BeginEmoteEcho
function BeginEmoteEcho()
{
}

// @STUB(M5b) @SYS-BASE-EMOTE legacy:KF2BotBase.CheckEmoteEcho
function CheckEmoteEcho()
{
}

// @STUB(M5b) @SYS-BASE-EMOTE legacy:KF2BotBase.PlayBotEmote
final function PlayBotEmote()
{
}

// @STUB(M5b) @SYS-BASE-EMOTE legacy:KF2BotBase.ClearEmoteFlag
function ClearEmoteFlag()
{
}

// @STUB(M3) @SYS-BASE-ZEDS legacy:KF2BotBase.GetWaveMomentum
final function float GetWaveMomentum()
{
}

// @STUB(M3) @SYS-BASE-ZEDS legacy:KF2BotBase.ExceedsRetreatZedCount
final function bool ExceedsRetreatZedCount()
{
}

// @STUB(M3) @SYS-BASE-FIRE legacy:KF2BotBase.ApplyBreathing
function ApplyBreathing(float t)
{
}

// @STUB(M3) @SYS-BASE-ZEDS legacy:KF2BotBase.UpdateHoldAreaDrift
function UpdateHoldAreaDrift()
{
}

defaultproperties
{
    bIsPlayer=true
    bNotifyApex=true
    CurrentFormation=StaggeredColumn
    ScanMask=15
    PanicVarianceMultiplier=1.0
    PanicScanSpeedMultiplier=1.0
    ShotgunEffectiveRangeUU=1100.0
    FlamethrowerEffectiveRangeUU=700.0
    DefaultWeaponEffectiveRangeUU=5000.0
}
