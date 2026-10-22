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
const THREAT_SIREN = 2.0;
const THREAT_HUSK = 1.6;
const THREAT_LARGE = 1.5;
const THREAT_STALKER = 1.3;
const THREAT_CRAWLER = 0.9;
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
const TRADER_ROAM_HEIGHT_BAND = 350.0;
const TRADER_TETHER_RADIUS_SQ = 10890000.0;
const TRADER_TETHER_HEIGHT = 500.0;
const TRADER_ROAM_PICK_TRIES = 6;
const TRADER_ROAM_ROUTE_SLACK = 1.6;
const TRADER_ROAM_ROUTE_EXTRA = 500.0;
const SHOT_PROBE_INTERVAL = 0.15;
const AIM_INTERP_SPEED = 8.0;
const AIM_FIRE_CONE_DOT = 0.985;
const AIM_REACT_MIN = 0.08;
const AIM_REACT_RANGE = 0.17;
const AIM_RESET_GAP = 1.0;
const GRAB_SURROUND_RADIUS = 600.0;
const GRAB_SURROUND_COUNT = 3;
const SPRINT_TICK_INTERVAL = 0.25;
const SPRINT_MIN_SPEED_SQ = 10000.0;
const SPRINT_ENEMY_RADIUS_SQ = 2250000.0;
const SPRINT_CATCHUP_START_SQ = 810000.0;
const SPRINT_CATCHUP_STOP_SQ = 250000.0;

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
var transient float NextHuntTime;
var transient float ObjectiveBailUntil;
var transient float LastNodeBlockTime;
var int NodeBlockCount;
var transient float NextAdjustTime;
var transient float MovePauseTime;
// One stuck ladder for every mover (nav redesign N5): progress = the pawn moved NAV_PROGRESS_MIN uu in NAV_PROBE_INTERVAL.
var transient vector NavProbeLoc;
var transient float NavProbeTime;
var transient float NavStall;
var transient int NavLevel;
var transient NavigationPoint NavLastGood;
var float NavBlockedUntil;
var bool bNavTeleport;
var float NavTeleportAfter; // seconds of stall before teleport is allowed
var float NavNextTeleportTry; // earliest game time the next teleport attempt may fire
var float NavTeleportWaitLog; // last game time a NAV_TELEPORT_WAIT log was printed
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
var transient array<NavigationPoint> TraderRoamNodes;
var transient NavigationPoint TraderRoamHome;
var transient Actor TraderRoamNodesFor;
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
// Priority hub audit (HubPick / HubFail / HubResolve): which hub priority sent the bot where,
// and whether that step ended well. Read by kit/tools/hub_audit.py.
var string HubPriority;
var name HubNextState;
var float HubPickTime;
var string HubFailReason;
var float AuditDwellTotal;
var float AuditLastLog_STATE_EXIT;
var float AuditLastLog_GOAL;
var float AuditLastLog_FOLLOWGATE;
var float AuditLastLog_GEN;
var float AuditLastLog_DWELLTOT;
var float AuditLastLog_NAVACCEL;
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
var transient float NextShotProbeTime;
var transient Actor ShotProbeTarget;
var transient name ShotProbeBone;
var transient bool bShotProbeClear;
var transient rotator AimRot;
var transient float LastAimTime;
var transient float AimReadyTime;
var float RetreatStartTime; // when the current retreat began (0 = none)
var vector RetreatStartLoc; // where it began
var float RetreatCooldownUntil; // no new retreat before this time (2 s after one ends)
var Pawn RetreatTarget; // the zed the retreat is shooting at now
var Pawn RetreatNoFire; // a calm Fleshpound we must not shoot during its calm window
var float RetreatCalmUntil; // end of the calm-Fleshpound sprint window
var bool bRetreatSprint; // sprint is allowed during this retreat (calm Fleshpound window or raging Scrake close)
var bool bRetreatSurrounded; // every direction was blocked at the last check
var float RetreatLogTime; // throttle for RETREAT_SHOT logs
var array<Pawn> RetreatFPs; // Fleshpounds seen within 25 m
var array<bool> RetreatFPRaged; // their last known IsEnraged()
var float RetreatMaxDist; // 750.0 (15 m)
var float RetreatMinStay; // 1.5 s minimum retreat duration
var float RetreatFireInterval; // 0.2 s between fire ticks
var vector RetreatDir; // last escape direction chosen by PickRetreatMove
var float LastHubCheckTime;     // game time of the last PickCombatStyle (hub) call made from FightEnemy.FinishedMove
var float CombatHubGap;         // seconds between hub checks while FightEnemy keeps the same enemy
var float LastRepickLog;        // game time of the last COMBAT_REPICK log line (throttle 2 s)
var float ZeroMoveMinDist;      // 2D distance under which a combat move is not started
var float BashMaxDistSq;        // squared distance for a bash
var float BashInterval;         // seconds between bashes
var transient bool bAimInit;
var transient Actor AimLastTarget;
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

simulated function PreBeginPlay()
{
    local Mutator M;
    local float WatchdogDelay;

    M = WorldInfo.Game.BaseMutator;
    while (M != None)
    {
        mut = EcholonMut(M);
        if (mut != None)
        {
            break;
        }
        M = M.NextMutator;
    }

    super.PreBeginPlay();

    if (WorldInfo.Game.NumBots < 255)
    {
        ++WorldInfo.Game.NumBots;
    }

    KFGRI = KFGameReplicationInfo(WorldInfo.GRI);

    SetTimer(0.5 + (FRand() * 0.5), true, 'EyeSightCheck');

    if (mut != None)
    {
        mut.RegisterBot(EcholonBot(self));
    }

    bJustSpawned = true;

    WatchdogDelay = 0.5;
    if (GroupID > 0)
    {
        WatchdogDelay += GroupID * 0.1;
    }
    SetTimer(WatchdogDelay, false, 'IdleWatchdogTimer');

    if (BotRank == CAPTAIN)
    {
        SetTimer(5.0, true, 'ProcessOverwatchPhase');
    }
    if (BotRank == GRUNT)
    {
        SetTimer(1.5, true, 'GruntDecisionTimer');
    }

    BreathingPhase = FRand() * 6.2831853;
    StartEmoteEchoTimer();
}

simulated function Destroyed()
{
    ClearRankTimers();
    super(Controller).Destroyed();
    if (WorldInfo.Game.NumBots > 0)
    {
        --WorldInfo.Game.NumBots;
    }
    if (mut != None)
    {
        mut.UnregisterBot(EcholonBot(self));
    }
}

function InitPlayerReplicationInfo()
{
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
        if ((KFGI != None) && KFGI.Teams[0] != None)
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

final function GiveWeaponDef(Class<KFWeaponDefinition> W)
{
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

function Restart(bool bVehicleTransition)
{
    local KFPlayerReplicationInfo KFPRI;

    FollowingHuman = None;
    LastFactory = None;
    FavoriteWeapon = None;
    NextShoppingTime = WorldInfo.TimeSeconds - 1.0;

    if ((KFInventoryManager(Pawn.InvManager) != None) && (Pawn.InvManager.Class != Class'EcholonBot.EcholonInventoryManager'))
    {
        Pawn.InvManager.Destroy();
        Pawn.InvManager = Spawn(Class'EcholonBot.EcholonInventoryManager', Pawn);
        Pawn.InvManager.SetupFor(Pawn);
    }

    super(Controller).Restart(bVehicleTransition);

    BotRank = GRUNT;
    bIsGroupLeader = false;
    ArmRankTimers();
    bFallbackWeapon = false;
    FallbackPrimary = None;
    NextGrenadeTimer = 0.0;
    Pawn.PeripheralVision = -0.2;
    Pawn.JumpZ = FMax(Pawn.JumpZ, 750.0);
    // Wall-jump fix: KFPawn hops by itself when it walks into a wall (bCanJumpOverWalls). Our movers
    // steer with raw acceleration and can't clear the ledge, so the hop repeated until death.
    Pawn.bCanJumpOverWalls = false;

    KPawn = KFPawn_Human(Pawn);
    KPawn.NumJumpsAllowed = 2;

    if (Pawn.Physics == 0)
    {
        Pawn.SetPhysics(2);
    }

    SetTimer(0.2 + (FRand() * 0.1), true, 'CheckGrabbed');
    SetTimer(SPRINT_TICK_INTERVAL + (FRand() * 0.05), true, 'SprintTick');
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

    KFPRI = KFPlayerReplicationInfo(PlayerReplicationInfo);
    Pawn.bModifyReachSpecCost = false;
    Pawn.PathSearchType = 1;

    AuditGoalLog("GOAL_CLEAR", "Restart");
    ObjectiveGoal = None;
    ObjectiveBailUntil = 0.0;
    LastNodeBlockTime = 0.0;
    NodeBlockCount = 0;
    ValidateAndNudgeSpawn();
    GotoState('Roaming');

    if (KPawn != None)
    {
        if ((Perk == Class'KFGame.KFPerk_Berserker') || (Perk == Class'KFGame.KFPerk_FieldMedic'))
        {
            KPawn.HealthMax = 100 + Min(CurrentLevel * 4, 100);
            KPawn.Health = KPawn.HealthMax;

            if (KFPRI != None)
            {
                KFPRI.PlayerHealthPercent = FloatToByte(float(KPawn.Health) / float(KPawn.HealthMax));
                KFPRI.PlayerHealth = KPawn.Health;
            }

            KPawn.MaxArmor = byte(100 + Min(CurrentLevel * 2, 150));

            if (CurrentLevel > 20)
            {
                KPawn.Armor = KPawn.MaxArmor;
            }
        }
    }

    if (KFPRI != None)
    {
        KFPRI.bHasSpawnedIn = true;
    }
}

function NotifyTakeHit(Controller InstigatedBy, Vector HitLocation, int Damage, Class<DamageType> DamageType, Vector Momentum)
{
    if ((InstigatedBy != None) && (InstigatedBy.Pawn != None))
    {
        SetEnemy(InstigatedBy.Pawn);
    }
}

function SeePlayer(Pawn Seen)
{
    if (BotRank == GRUNT)
    {
        GruntOnSight(Seen);
        return;
    }
    SetEnemy(Seen);
}

function SeeMonster(Pawn Seen)
{
    if (BotRank == GRUNT)
    {
        GruntOnSight(Seen);
        return;
    }
    SetEnemy(Seen);
}

event bool NotifyBump(Actor Other, Vector HitNormal)
{
    local Vector Dir;

    if (FollowOwnsEvents() && FollowHandleBump(Other, HitNormal))
    {
        return true;
    }

    super.NotifyBump(Other, HitNormal);
    Enable('NotifyBump');

    if ((Pawn(Other) != None) && !SetEnemy(Pawn(Other)))
    {
        if (MoveFlags > 0)
        {
            Dir = GetMoveDirection();
            if ((Dir Dot (Other.Location - Pawn.Location)) > 0.0)
            {
                HitNormal.X = -Dir.Y;
                HitNormal.Y = Dir.X;
                HitNormal.Z = 0.0;
                HitNormal = Normal(HitNormal);
                bAdjusting = true;
                if ((HitNormal Dot Dir) < 0.0)
                {
                    AdjustPosition.Position = Pawn.Location + (HitNormal * 80.0);
                }
                else
                {
                    AdjustPosition.Position = Pawn.Location - (HitNormal * 80.0);
                }
            }
        }
        else
        {
            if (!bAdjusting)
            {
                bAdjusting = true;
                AdjustPosition.Position = ((Normal(Pawn.Location - Other.Location) * 45.0) + (VRand() * 25.0)) + Pawn.Location;
                SetTimer(0.5, false, 'StopAdjusting');
            }
        }
    }
    else
    {
        if (KFDoorActor(Other) != None)
        {
            if (!MarkDoorPath(KFDoorActor(Other)))
            {
                KFDoorActor(Other).UseDoor(Pawn);
            }
            else
            {
                EndMoveTime = WorldInfo.TimeSeconds - 1.0;
            }
        }
    }
    return false;
}

final function bool TargetLowHealth(Pawn Other)
{
    local float T;
    local int H;

    H = Other.Health;
    if (KFPawn_Human(Other) != None)
    {
        H += int(KFPawn_Human(Other).HealthToRegen);
    }
    if (H < Other.HealthMax)
    {
        T = WorldInfo.TimeSeconds - EnemyEncounterTime;
        if (T > 4.0)
        {
            return true;
        }
        if (T > 2.0)
        {
            return H < 85;
        }
        return H < 70;
    }
    return false;
}

function EyeSightCheck()
{
    if ((Pawn != None) && Pawn.IsAliveAndWell())
    {
        if (Enemy != None && Enemy.IsAliveAndWell())
            return;
        if (WorldInfo.TimeSeconds - LastEnemyScanTime < ENEMY_SCAN_INTERVAL)
            return;
        LastEnemyScanTime = WorldInfo.TimeSeconds;
        PickNextEnemy();
    }
}

final function bool PickNextEnemy()
{
    local KFPawn_Monster P;
    local bool bResult;

    if (WorldInfo.TimeSeconds - LastLeashDropTime < LEASH_COOLDOWN)
    {
        return false;
    }

    bResult = false;
    foreach WorldInfo.AllPawns(class'KFPawn_Monster', P, Pawn.Location, ENEMY_SCAN_RADIUS)
    {
        if ((P != Pawn) && P.IsAliveAndWell() && FastTrace(P.Location, Pawn.Location))
        {
            bResult = SetEnemy(P, true) || bResult;
        }
    }
    return bResult;
}

function bool SetEnemy(Pawn Other, optional bool bNoNotify)
{
    local KFPawn_Monster M;

    if (Other == None || Other == Pawn || Other.SpawnTime == WorldInfo.TimeSeconds || !Other.IsAliveAndWell())
    {
        return false;
    }

    M = KFPawn_Monster(Other);
    if (M != None && M.bIsHeadless)
    {
        return false;
    }

    if (Other.Health > BOSS_HEALTH_THRESHOLD && IsMeleeOnly())
    {
        return false;
    }

    if (Pawn.IsSameTeam(Other))
    {
        if (PlayStyle == 1 && KPawn != None && FollowingHuman == None && KFPawn_Human(Other) != None && Other.IsHumanControlled() && Rand(3) == 0)
        {
            FollowingHuman = Other;
        }
        if (Enemy == None && NextDoshShareTime > WorldInfo.TimeSeconds && PlayerReplicationInfo != None && PlayerReplicationInfo.Score > 800.0 && Other.PlayerReplicationInfo != None && Other.PlayerReplicationInfo.Score < 500.0)
        {
            DonateMoney(Other);
        }
        return false;
    }

    EnemyEncounterTime = WorldInfo.TimeSeconds;

    if (Enemy != None && GetEnemyThreat(Enemy) > GetEnemyThreat(Other))
    {
        return false;
    }

    Enemy = Other;

    if (!bNoNotify)
    {
        EnemyChanged();
    }

    if (bIsGroupLeader && mut != None && VSizeSq(Other.Location - Pawn.Location) <= SPOT_RADIUS_SQ)
    {
        mut.BroadcastSpottedEnemy(GroupID, Other);
    }

    return true;
}

// Target priority multiplier by zed type: Sirens (scream damage) and Husks (fire) first, large zeds
// (Fleshpound, Scrake) next, then Stalkers; Crawlers are the least urgent.
final function float GetSpecialZedFactor(Pawn Other)
{
    local KFPawn_Monster M;

    M = KFPawn_Monster(Other);
    if (M == None)
        return 1.0;
    if (M.Class == class'KFPawn_ZedSiren')
        return THREAT_SIREN;
    if (M.Class == class'KFPawn_ZedHusk')
        return THREAT_HUSK;
    if (M.bLargeZed)
        return THREAT_LARGE;
    if (M.Class == class'KFPawn_ZedStalker')
        return THREAT_STALKER;
    if (M.Class == class'KFPawn_ZedCrawler')
        return THREAT_CRAWLER;
    return 1.0;
}

function float GetEnemyThreat(Pawn Other)
{
    local float V;

    V = FMin(float(Other.Health), 600.0) + 100.0;
    if (V < 30.0)
    {
        V += 800.0;
    }
    // Special zeds first: the factor scales the base score before the distance penalty, so a Siren or
    // Fleshpound still wins over a closer Clot but a far one does not pull a bot across the room.
    V *= GetSpecialZedFactor(Other);
    V -= (VSize(Other.Location - Pawn.Location) / 2.0);
    if (Other == Enemy)
    {
        V *= 1.25;
    }
    return V;
}

function bool FireWeaponAt(Actor inActor)
{
	local KFWeapon W;

	bOutOfEffectiveRange = false;

	if ((inActor == None) || (Pawn == None))
	{
		return false;
	}
	// Shot-point probe before the IsFiring early return, so a burst stops when the target goes behind cover.
	if (!ProbeShotPoint(inActor))
	{
		Pawn.StopFiring();
		return false;
	}
	// Keep the aim on the target we are shooting now, also while a burst is running: Target used to be set
	// only when a burst started, so the next zed was ignored until the burst stopped.
	Target = inActor;
	if (inActor != AimLastTarget)
	{
		AimLastTarget = inActor;
		if ((Normal(inActor.Location - Pawn.Location) dot vector(Rotation)) < 0.9659)
		{
			AimReadyTime = WorldInfo.TimeSeconds + AIM_REACT_MIN + (FRand() * AIM_REACT_RANGE);
		}
	}
	if (Pawn.IsFiring())
	{
		return true;
	}
	if (NeedToTurn(inActor.Location) || !Pawn.CanAttack(inActor))
	{
		return false;
	}
	if (KPawn != None && KPawn.bIsSprinting)
	{
		KPawn.SetSprinting(false);
	}
	W = KFWeapon(Pawn.Weapon);
	if (W != None)
	{
		if (HandleWeaponManagement(W))
		{
			return false;
		}
		if (TryThrowGrenade(W, inActor))
		{
			return true;
		}
		if (W.bMeleeWeapon)
		{
			W.StartFire(BOTFM_PRIMARY);
		}
		else if (VSizeSq(inActor.Location - Pawn.Location) < BashMaxDistSq && WorldInfo.TimeSeconds >= NextBashTime)
		{
			NextBashTime = WorldInfo.TimeSeconds + BashInterval;
			EchelonLog("COMBAT_BASH dist=" $ string(int(VSize(inActor.Location - Pawn.Location))));
			W.StartFire(BOTFM_BASH);
		}
		else
		{
			if (!IsInEffectiveRange(inActor))
			{
				bOutOfEffectiveRange = true;
				return false;
			}
			if (!AimReadyToFire(inActor, W))
			{
				return false;
			}
			W.StartFire(BOTFM_PRIMARY);
		}
	}
	return Pawn.BotFire(false);
}

final function TryBreakFree()
{
    local KFWeapon W;
    local KFPawn GrabbingZed;

    if (Pawn == None)
    {
        return;
    }
    if (Pawn.Weapon == None)
    {
        if (Pawn.InvManager != None)
        {
            Pawn.InvManager.SwitchToBestWeapon(true);
        }
        return;
    }
    W = KFWeapon(Pawn.Weapon);
    if (W == None)
    {
        return;
    }
    GrabbingZed = KPawn.InteractionPawn;
    if (W.bMeleeWeapon)
    {
        W.StartFire(0);
        SimulateBashHit(GrabbingZed, W);
    }
    else if (W == MedicGun)
    {
        if (Pawn.InvManager != None)
        {
            Pawn.InvManager.SwitchToBestWeapon(true);
        }
    }
    else
    {
        W.StartFire(3);
        SimulateBashHit(GrabbingZed, W);
    }
}

// Scripted bash hit on the grabber: a flat 25, because the bot's alt-fire bash does not reliably connect
// during the grab. The old random 200-damage roll is gone; a real shot is the strong option (TryShootGrabber).
final function SimulateBashHit(KFPawn TargetZed, KFWeapon W)
{
    if (TargetZed == None || !TargetZed.IsAliveAndWell())
    {
        return;
    }

    if (W == MedicGun)
    {
        return;
    }

    TargetZed.TakeDamage(25, self, TargetZed.Location, vect(0.0, 0.0, 0.0), Class'Engine.DamageType');
}

function EnemyChanged()
{
}

function DonateMoney(Pawn Other)
{
}

exec function SwitchToBestWeapon(optional bool bForceNewWeapon, optional bool check_9mm_logic = false)
{
	if (Pawn != None && Pawn.InvManager != None)
	{
		Pawn.InvManager.SwitchToBestWeapon(bForceNewWeapon, check_9mm_logic);
	}
}

// Where the bot wants to hit T: the bone the shot-point probe found clear, else the head, else the pivot.
final function vector GetAimTargetPos(Actor T, Weapon W)
{
    if((W != None) && (KFPawn(T) != None) && (T == ShotProbeTarget) && bShotProbeClear && (ShotProbeBone != ''))
    {
        return KFPawn(T).Mesh.GetBoneLocation(ShotProbeBone);
    }
    if((W != None) && (KFPawn(T) != None) && !((T == ShotProbeTarget) && bShotProbeClear))
    {
        return KFPawn(T).Mesh.GetBoneLocation(KFPawn(T).HeadBoneName);
    }
    return T.Location;
}

// Eased aim: the aim direction turns toward the wanted direction at a limited speed instead of snapping
// to it, like a player moving a mouse. It starts from where the bot is looking after a pause.
final function rotator StepAim(vector StartLoc, vector TargetPos)
{
    local rotator Want;
    local float Dt;

    Want = Rotator(TargetPos - StartLoc);
    if (Pawn == None)
        return Want;
    Dt = WorldInfo.TimeSeconds - LastAimTime;
    if (!bAimInit || Dt > AIM_RESET_GAP)
    {
        AimRot = Pawn.Rotation;
        bAimInit = true;
    }
    else if (Dt > 0.0)
    {
        AimRot = RInterpTo(AimRot, Want, FMin(Dt, 0.25), AIM_INTERP_SPEED);
    }
    LastAimTime = WorldInfo.TimeSeconds;
    return AimRot;
}

// True when a new burst at T may start: the reaction delay after switching target has passed and the eased
// aim is within about 10 degrees of the target. Also steps the aim, so it keeps turning between shots.
final function bool AimReadyToFire(Actor T, Weapon W)
{
    local vector EyeLoc, TargetPos;
    local rotator EyeRot, Cur;

    Pawn.GetActorEyesViewPoint(EyeLoc, EyeRot);
    TargetPos = GetAimTargetPos(T, W);
    Cur = StepAim(EyeLoc, TargetPos);
    if (WorldInfo.TimeSeconds < AimReadyTime)
        return false;
    return (Normal(vector(Cur)) Dot Normal(TargetPos - EyeLoc)) >= AIM_FIRE_CONE_DOT;
}

function Rotator GetAdjustedAimFor(Weapon W, Vector StartFireLoc)
{
    // A dead target must not keep the aim: a burst that never stopped kept shooting at the corpse for
    // 1-2 seconds before the bot looked at the next zed.
    if((Pawn(Target) != None) && !Pawn(Target).IsAliveAndWell())
    {
        Target = Enemy;
    }
    if(Target == None)
    {
        Target = Enemy;
        if(Target == None)
        {
            return super(Controller).GetAdjustedAimFor(W, StartFireLoc);
        }
    }

    return StepAim(StartFireLoc, GetAimTargetPos(Target, W));
}

simulated function GetPlayerViewPoint(out Vector out_Location, out Rotator out_Rotation)
{
    if (Pawn != None)
    {
        Pawn.GetActorEyesViewPoint(out_Location, out_Rotation);
        out_Rotation = GetAdjustedAimFor(Pawn.Weapon, out_Location);
    }
    else
    {
        out_Location = Location;
        out_Rotation = Rotation;
    }
}

final function MoveToX(Vector Dest, optional Actor ViewFocus, optional bool bSerpent = true, optional name Src)
{
    if (IsInState('FightEnemy') && VSize2D(Dest - Pawn.Location) < ZeroMoveMinDist)
    {
        ZeroMoveHold(Src, "to");
        return;
    }
    bAdjusting = false;
    MoveFlags = 1;
    SetDestinationPosition(Dest);
    SetFocalPoint(Dest);
    Focus = ViewFocus;
    EndMoveTime = (WorldInfo.TimeSeconds + (VSize(Dest - Pawn.Location) / Pawn.GroundSpeed)) + 0.6;
    bSerpentineMove = bSerpent;
    PrevMovePos = Pawn.Location;
    MovePauseTime = WorldInfo.TimeSeconds;
    if (bSerpent)
    {
        bSerpentLeft = Rand(2) == 0;
    }
}

final function MoveTowardX(Actor Dest, optional Actor ViewFocus, optional bool bSerpent = true, optional name Src)
{
    if (IsInState('FightEnemy') && Dest != None && Pawn.ReachedDestination(Dest))
    {
        ZeroMoveHold(Src, "toward");
        return;
    }
    bAdjusting = false;
    MoveFlags = 2;
    MoveTarget = Dest;
    bSerpentineMove = bSerpent;
    PrevMovePos = Pawn.Location;
    MovePauseTime = WorldInfo.TimeSeconds;
    if (Dest != None)
    {
        SetDestinationPosition(Dest.Location);
        SetFocalPoint(Dest.Location);
        Focus = Dest;
        EndMoveTime = (WorldInfo.TimeSeconds + (VSize(Dest.Location - Pawn.Location) / Pawn.GroundSpeed)) + 0.75;
    }
    if (ViewFocus != None)
    {
        Focus = ViewFocus;
    }
    if (bSerpent)
    {
        bSerpentLeft = (Rand(2) == 0);
    }
}

final function ZeroMoveHold(name Src, string Kind)
{
    MoveFlags = 0;
    Pawn.Acceleration = vect(0, 0, 0);
    EchelonLog("COMBAT_ZERO_MOVE src=" $ string(Src) $ " kind=" $ Kind);
    SetTimer(0.25, false, 'CombatRepick');
}

final function StrafeTowardPoint(Vector Dest)
{
    local Vector X, Y;

    X = Dest - Pawn.Location;
    if (VSizeSq2D(X) > 22500.0)
    {
        Y.X = -X.Y;
        Y.Y = X.X;
        if (SerpentineTime < WorldInfo.TimeSeconds)
        {
            SerpentineTime = (WorldInfo.TimeSeconds + 0.3) + (FRand() * 0.05);
            bSerpentLeft = !bSerpentLeft;
        }
        if (bSerpentLeft)
        {
            X = Normal(X + (Y * 0.5));
        }
        else
        {
            X = Normal(X - (Y * 0.5));
        }
    }
    X = NavGridSteer(X);
    Pawn.Acceleration = X * 2000.0;
}

final function Vector GetMoveDirection()
{
    switch(MoveFlags)
    {
        case 1:
            return DestinationPosition.Position - Pawn.Location;
        case 2:
            if (MoveTarget != None)
            {
                return MoveTarget.Location - Pawn.Location;
            }
            return vect(0, 0, 0);
        default:
            return vect(0, 0, 0);
    }
}

final function ProcessMoveTo()
{
    if (VSizeSq2D(DestinationPosition.Position - Pawn.Location) < 2500.0)
    {
        Pawn.Acceleration = vect(0.0, 0.0, 0.0);
        MoveFlags = 0;
        CurrentPath = None;
        FinishedMove();
    }
    else
    {
        if (bSerpentineMove)
        {
            StrafeTowardPoint(DestinationPosition.Position);
        }
        else
        {
            Pawn.Acceleration = NavGridSteer(Normal2D(DestinationPosition.Position - Pawn.Location)) * 2000.0;
        }
    }
}

final function ProcessMoveToward()
{
    if (MoveTarget == None || Pawn.ReachedDestination(MoveTarget))
    {
        if (NavigationPoint(MoveTarget) != None)
        {
            Pawn.SetAnchor(NavigationPoint(MoveTarget));
        }
        Pawn.Acceleration = vect(0.0, 0.0, 0.0);
        MoveFlags = 0;
        CurrentPath = None;
        FinishedMove();
    }
    else
    {
        if (bSerpentineMove)
        {
            StrafeTowardPoint(MoveTarget.Location);
        }
        else
        {
            Pawn.Acceleration = NavGridSteer(Normal2D(MoveTarget.Location - Pawn.Location)) * 2000.0;
        }
    }
}

final function AbortMove()
{
    Pawn.Acceleration = vect(0.0, 0.0, 0.0);
    MoveFlags = 0;
    bAdjusting = false;
    CurrentPath = None;
}

final function CheckBlockedPath(Actor Start, NavigationPoint End)
{
    local KFPawnBlockingVolume B;
    local Vector HL, HN;

    if ((Start == None) || (End == None) || (BotBlockRoutes.Find(End) >= 0))
    {
        return;
    }

    foreach Pawn.TraceActors(class'KFPawnBlockingVolume', B, HL, HN, End.Location, Start.Location, vect(32.0, 32.0, 64.0))
    {
        if (B.bBlockPlayers)
        {
            BotBlockRoutes.AddItem(End);
            break;
        }
    }
}

function FollowNotifyHub(EFollowStatus NewStatus)
{
    switch (NewStatus)
    {
        case FS_Arrived:
            EchelonLog("NAV_ARRIVED slot=" $ string(FollowSlotIndex) $ "/" $ string(FollowSlotCount));
            break;

        case FS_LeaderTeleported:
            EchelonLog("NAV_LEADER_TELEPORTED");
            break;

        case FS_LeaderLost:
        case FS_Blocked:
            EchelonLog("NAV_STATUS_EXIT status=" $ string(int(NewStatus)));
            FollowExitState = 'PickNextMove';
            bFollowExitPending = true;
            break;
    }
}

function FollowOnGaveUp()
{
    EchelonLog("NAV_RETRY_EXHAUSTED");
}

function Tick(float Delta)
{
    local KFPawn_Monster MonCheck;

    if (Pawn == None)
    {
        return;
    }

    FollowSampleCrumb();

    // Follow-combat escape: route to combat when a Zed has LOS while tethered
    if (IsInState('FollowingLeader') || IsInState('FollowingLeaderBasic'))
    {
        MonCheck = KFPawn_Monster(Enemy);
        if (Enemy != None && Enemy.IsAliveAndWell()
            && !(MonCheck != None && MonCheck.bIsHeadless)
            && (WorldInfo.TimeSeconds - LastFollowEscapeTime >= FOLLOW_ESCAPE_COOLDOWN))
        {
            LastFollowEscapeTime = WorldInfo.TimeSeconds;
            if (LineOfSightTo(Enemy))
            {
                GotoState('FightEnemy');
            }
            else
            {
                GotoState('Hunting');
            }
            return;
        }
    }

    // Global zed count refresh (throttled)
    if (WorldInfo.TimeSeconds - LastGlobalZedCountTime >= GLOBAL_ZED_COUNT_INTERVAL)
    {
        LastGlobalZedCountTime = WorldInfo.TimeSeconds;
        GlobalZedCount = CountNearbyZeds(GLOBAL_ZED_RADIUS);
    }

    NavProgressCheck();

    // Adjusting movement
    if (bAdjusting)
    {
        if (VSizeSq2D(AdjustPosition.Position - Pawn.Location) < 2500.0)
        {
            StopAdjusting();
        }
        else
        {
            Pawn.Acceleration = Normal(AdjustPosition.Position - Pawn.Location) * 2000.0;
        }
    }

    // Move processing
    if (MoveFlags != 0)
    {
        if (EndMoveTime < WorldInfo.TimeSeconds)
        {
            if (MoveFlags == 2)
            {
                if (LastFailedMove != NavigationPoint(MoveTarget))
                {
                    LastFailedMove = NavigationPoint(MoveTarget);
                    FailedMoveCount = 0;
                }
                else
                {
                    if (LastFailedMove != None && ++FailedMoveCount > 5)
                    {
                        TempBlockPath = LastFailedMove;
                        TempBlockTime = WorldInfo.TimeSeconds + 30.0;
                    }
                }

                if (CurrentPath != None)
                {
                    CheckBlockedPath(CurrentPath.Start, CurrentPath.GetEnd());
                }
                else
                {
                    if (LastFailedMove != None)
                    {
                        CheckBlockedPath(Pawn, LastFailedMove);
                    }
                }
            }

            Pawn.Acceleration = vect(0, 0, 0);
            MoveFlags = 0;
            FinishedMove();
        }
        else
        {
            // No hop when the pawn stops moving (nav redesign N1): jumping against a wall was the wall-jumping.
            // The wall-hit sidestep in NotifyHitWall and the follow mover's stuck ladder handle it.
            if (VSizeSq(PrevMovePos - Pawn.Location) >= 2500.0 * Delta)
            {
                PrevMovePos = Pawn.Location;
                MovePauseTime = WorldInfo.TimeSeconds;
            }

            if (!bAdjusting)
            {
                if (MoveFlags == 1)
                {
                    ProcessMoveTo();
                }
                else
                {
                    ProcessMoveToward();
                }
            }
        }
    }
}

// Teleport-step member vars

// True when no human camera can see Loc (or Subject); false if any line of sight succeeds.
final function bool NavUnseen(vector Loc, Pawn Subject)
{
    local vector CamLoc, ToLoc;
    local Rotator CamRot;
    local PlayerController PC;

    foreach WorldInfo.AllControllers(class'PlayerController', PC)
    {
        if (Subject != None && PC.ViewTarget == Subject)
        {
            return false;
        }

        PC.GetPlayerViewPoint(CamLoc, CamRot);
        ToLoc = Loc - CamLoc;

        if (VSize(ToLoc) > 6000.0)
        {
            continue;
        }

        if ((Normal(ToLoc) dot vector(CamRot)) < 0.25)
        {
            continue;
        }

        if (FastTrace(Loc + vect(0, 0, 50), CamLoc))
        {
            return false;
        }
    }

    return true;
}

// Teleports the pawn to NavLastGood if both origin and target are off-screen and stalled long enough.
final function NavTryTeleport(float IterNow)
{
    local vector TeleportLoc;

    if (!bNavTeleport || NavLastGood == None || Pawn == None
        || NavStall < NavTeleportAfter || IterNow < NavNextTeleportTry)
    {
        return;
    }

    TeleportLoc = NavLastGood.Location;
    TeleportLoc.Z += Pawn.GetCollisionHeight();

    if (NavUnseen(Pawn.Location, Pawn) && NavUnseen(TeleportLoc, Pawn))
    {
        Pawn.SetLocation(TeleportLoc);
        Pawn.Velocity = vect(0, 0, 0);
        EchelonLog("NAV_TELEPORT to=" $ string(NavLastGood) $ " unseen=1");
        NavStall = 0.0;
        NavLevel = 0;
        NavProbeLoc = Pawn.Location;
        NavNextTeleportTry = IterNow + 1.0;
    }
    else
    {
        NavNextTeleportTry = IterNow + 1.0;
        if (IterNow - NavTeleportWaitLog >= 10.0)
        {
            NavTeleportWaitLog = IterNow;
            EchelonLog("NAV_TELEPORT_WAIT stall=" $ string(NavStall));
        }
    }
}

// Asks the mutator whether the lava grid applies to this bot (NavGridSquads config) and logs a change.
final function NavGridRefresh()
{
    local bool bWas;

    if (mut == None || NavGrid == None)
    {
        return;
    }
    bWas = bNavGridOn;
    bNavGridOn = mut.NavGridAppliesTo(EcholonBot(self));
    if (bNavGridOn != bWas)
    {
        EchelonLog("NAV_GRID_BOT on=" $ string(bNavGridOn));
    }
}

// Progress check for MoveTo/MoveToward and the follow mover. 0.75 s without progress backs off (not in follow, which
// has its own ladder), 1.5 s strikes the edge and ends the move so the hub replans, 3 s walks back to the last good
// node, 6 s reports Blocked (the hub skips tethering for 10 s), 5 s of stall teleports to the last good node when neither the bot
// nor the target spot is on any human's screen (retried every second).
final function NavProgressCheck()
{
    local float IterNow;
    local bool bFollow, bMoving;
    local vector IterDir;
    local ReachSpec IterSpec;
    local NavigationPoint IterEnd;

    if (Pawn == None)
    {
        return;
    }
    IterNow = WorldInfo.TimeSeconds;
    if (IterNow - NavProbeTime < 0.75)
    {
        return;
    }
    NavGridRefresh();
    bFollow = IsInState('FollowingLeader');
    bMoving = (bFollow && bFollowMoveActive) || (!bFollow && MoveFlags != 0);
    if (!bMoving || Pawn.Physics == PHYS_Falling || (Enemy != None && Enemy.IsAliveAndWell() && LineOfSightTo(Enemy)))
    {
        NavStall = 0.0;
        NavLevel = 0;
        NavProbeLoc = Pawn.Location;
        NavProbeTime = IterNow;
        return;
    }
    if (VSize(Pawn.Location - NavProbeLoc) >= 48.0)
    {
        if (NavStall > 0.0)
        {
            EchelonLog("NAV_RECOVER level=" $ string(NavLevel) $ " ok=1");
        }
        NavStall = 0.0;
        NavLevel = 0;
        if (Pawn.Anchor != None && VSizeSq(Pawn.Location - Pawn.Anchor.Location) < 14400.0)
        {
            NavLastGood = Pawn.Anchor;
        }
        NavProbeLoc = Pawn.Location;
        NavProbeTime = IterNow;
        return;
    }
    NavStall += IterNow - NavProbeTime;
    NavProbeTime = IterNow;

    if (NavLevel < 1 && NavStall >= 0.75)
    {
        NavLevel = 1;
        if (!bFollow)
        {
            if (NavLastGood != None)
            {
                IterDir = NavLastGood.Location - Pawn.Location;
            }
            else
            {
                IterDir = -vector(Pawn.Rotation);
            }
            IterDir.Z = 0.0;
            if (VSizeSq(IterDir) < 1.0)
            {
                IterDir = VRand();
                IterDir.Z = 0.0;
            }
            bAdjusting = true;
            AdjustPosition.Position = Pawn.Location + (Normal(IterDir) * 64.0);
            EchelonLog("NAV_STUCK level=1 state=" $ string(GetStateName()) $ " stalled=" $ string(NavStall));
        }
    }
    if (NavLevel < 2 && NavStall >= 1.5)
    {
        NavLevel = 2;
        NavGridMarkStuck(Normal2D(Pawn.Acceleration));
        if (!bFollow)
        {
            IterEnd = NavigationPoint(MoveTarget);
            if (MoveFlags == 2 && IterEnd != None && Pawn.Anchor != None && Pawn.Anchor != IterEnd)
            {
                IterSpec = Pawn.Anchor.GetReachSpecTo(IterEnd);
                FollowStrikeEdge(IterSpec);
            }
            EchelonLog("NAV_STUCK level=2 state=" $ string(GetStateName()) $ " target=" $ string(MoveTarget));
            EndMoveTime = IterNow - 1.0;
        }
    }
    if (NavLevel < 3 && NavStall >= 3.0)
    {
        NavLevel = 3;
        EchelonLog("NAV_STUCK level=3 state=" $ string(GetStateName()) $ " lastgood=" $ string(NavLastGood));
        if (!bFollow && NavLastGood != None)
        {
            MoveTowardX(NavLastGood, None, false);
        }
    }
    if (NavLevel < 4 && NavStall >= 6.0)
    {
        NavLevel = 4;
        NavBlockedUntil = IterNow + 10.0;
        EchelonLog("NAV_BLOCKED state=" $ string(GetStateName()) $ " stalled=" $ string(NavStall));
        if (bFollow)
        {
            bFollowExitPending = true;
        }
        else
        {
            AbortMove();
            HubFail("NavBlocked");
            EndMoveTime = IterNow - 1.0;
        }
    }
    NavTryTeleport(IterNow);
}

final function bool MarkDoorPath(KFDoorActor door)
{
    local int I;
    local NavigationPoint N;

    if (door.bIsDoorOpen || door.WeldIntegrity <= 0 || door.bAutomaticDoor)
    {
        return false;
    }

    N = NavigationPoint(MoveTarget);
    if (N != None)
    {
        if (DoorPaths.Find('Path', N) >= 0)
        {
            return true;
        }
        if (((N.Location - Pawn.Location) Dot (door.Location - Pawn.Location)) < 0.0)
        {
            return false;
        }
        I = DoorPaths.Length;
        DoorPaths.Length = I + 1;
        DoorPaths[I].door = door;
        DoorPaths[I].Path = N;
    }
    return true;
}

final function bool BuildPathToward(Actor Other)
{
    local int I;

    I = DoorPaths.Length - 1;
    while (I >= 0)
    {
        if ((DoorPaths[I].Path.bBlocked || DoorPaths[I].door.bIsDestroyed) || DoorPaths[I].door.bIsDoorOpen || DoorPaths[I].door.WeldIntegrity <= 0)
        {
            DoorPaths.Remove(I, 1);
        }
        else
        {
            DoorPaths[I].Path.bBlocked = true;
        }
        I--;
    }

    I = BotBlockRoutes.Length - 1;
    while (I >= 0)
    {
        BotBlockRoutes[I].bBlocked = true;
        I--;
    }

    if (TempBlockPath != None)
    {
        if (TempBlockTime < WorldInfo.TimeSeconds)
        {
            TempBlockPath = None;
        }
        else
        {
            TempBlockPath.bBlocked = true;
        }
    }

    MoveTarget = FollowFindWalkablePath(Other, vect(0,0,0));  // skips leap/climb edges (wall-jump fix)

    I = DoorPaths.Length - 1;
    while (I >= 0)
    {
        DoorPaths[I].Path.bBlocked = false;
        I--;
    }

    I = BotBlockRoutes.Length - 1;
    while (I >= 0)
    {
        BotBlockRoutes[I].bBlocked = false;
        I--;
    }

    if (TempBlockPath != None)
    {
        TempBlockPath.bBlocked = false;
    }

    return MoveTarget != None;
}

final function bool BuildPathTo(Vector Dest)
{
    local int I;

    for (I = DoorPaths.Length - 1; I >= 0; I--)
    {
        if (DoorPaths[I].Path.bBlocked || DoorPaths[I].door.bIsDestroyed || DoorPaths[I].door.bIsDoorOpen || DoorPaths[I].door.WeldIntegrity <= 0)
        {
            DoorPaths.Remove(I, 1);
        }
        else
        {
            DoorPaths[I].Path.bBlocked = true;
        }
    }

    for (I = BotBlockRoutes.Length - 1; I >= 0; I--)
    {
        BotBlockRoutes[I].bBlocked = true;
    }

    if (TempBlockPath != None)
    {
        if (TempBlockTime < WorldInfo.TimeSeconds)
        {
            TempBlockPath = None;
        }
        else
        {
            TempBlockPath.bBlocked = true;
        }
    }

    MoveTarget = FollowFindWalkablePath(None, Dest);  // skips leap/climb edges (wall-jump fix)

    for (I = DoorPaths.Length - 1; I >= 0; I--)
    {
        DoorPaths[I].Path.bBlocked = false;
    }

    for (I = BotBlockRoutes.Length - 1; I >= 0; I--)
    {
        BotBlockRoutes[I].bBlocked = false;
    }

    if (TempBlockPath != None)
    {
        TempBlockPath.bBlocked = false;
    }

    return MoveTarget != None;
}

final function bool BuildRandomPath()
{
    local int I;

    I = DoorPaths.Length - 1;
    while (I >= 0)
    {
        if (DoorPaths[I].Path.bBlocked || DoorPaths[I].door.bIsDestroyed || DoorPaths[I].door.bIsDoorOpen || DoorPaths[I].door.WeldIntegrity <= 0)
        {
            DoorPaths.Remove(I, 1);
        }
        else
        {
            DoorPaths[I].Path.bBlocked = true;
        }
        I--;
    }

    I = BotBlockRoutes.Length - 1;
    while (I >= 0)
    {
        BotBlockRoutes[I].bBlocked = true;
        I--;
    }

    if (TempBlockPath != None)
    {
        if (TempBlockTime < WorldInfo.TimeSeconds)
        {
            TempBlockPath = None;
        }
        else
        {
            TempBlockPath.bBlocked = true;
        }
    }

    if (IsTraderFreeTime() && KFGRI.OpenedTrader != None && Pawn != None)
    {
        RandGoal = PickTraderRoamGoal();
    }
    else
    {
        RandGoal = FindRandomDest();
    }

    I = DoorPaths.Length - 1;
    while (I >= 0)
    {
        DoorPaths[I].Path.bBlocked = false;
        I--;
    }

    I = BotBlockRoutes.Length - 1;
    while (I >= 0)
    {
        BotBlockRoutes[I].bBlocked = false;
        I--;
    }

    if (TempBlockPath != None)
    {
        TempBlockPath.bBlocked = false;
    }

    return RandGoal != None;
}

// Lists the path nodes a bot may roam to in free trader time: within TRADER_ROAM_RADIUS of the trader
// horizontally and within TRADER_ROAM_HEIGHT_BAND of its height (same floor), never crawler wall nodes or
// unlinked nodes. Built once per trader (nav nodes never move). TraderRoamHome is the node closest to the
// trader, the fallback goal.
final function BuildTraderRoamNodes(Actor Trader)
{
    local NavigationPoint N;
    local vector D;
    local float DistSq, BestSq;

    TraderRoamNodes.Length = 0;
    TraderRoamHome = None;
    TraderRoamNodesFor = Trader;
    BestSq = 999999999.0;
    foreach WorldInfo.AllNavigationPoints(class'NavigationPoint', N)
    {
        if (N.bWallNode || N.PathList.Length == 0)
            continue;
        D = N.Location - Trader.Location;
        if (Abs(D.Z) > TRADER_ROAM_HEIGHT_BAND)
            continue;
        DistSq = VSizeSq2D(D);
        if (DistSq > TRADER_ROAM_RADIUS_SQ)
            continue;
        TraderRoamNodes.AddItem(N);
        if (DistSq < BestSq)
        {
            BestSq = DistSq;
            TraderRoamHome = N;
        }
    }
    `log("[EcholonAudit] " $ LogTag() $ " TRADER_ROAM_LIST nodes=" $ string(TraderRoamNodes.Length) $ " trader=" $ string(Trader.Name));
}

// True when N is a roam goal of the trader that is open now (a goal kept from before the trader opened can
// be anywhere on the map, and Roaming drops it).
final function bool IsTraderRoamGoal(NavigationPoint N)
{
    if (N == None || KFGRI == None || KFGRI.OpenedTrader == None || KFGRI.OpenedTrader != TraderRoamNodesFor)
        return false;
    return (N == TraderRoamHome) || (TraderRoamNodes.Find(N) != INDEX_NONE);
}

// True when another bot is already roaming to N, so bots spread out instead of bunching on one node.
final function bool IsRoamGoalTaken(NavigationPoint N)
{
    local int J;

    if (mut == None)
        return false;
    for (J = 0; J < mut.ActiveBots.Length; J++)
    {
        if (mut.ActiveBots[J] != None && mut.ActiveBots[J] != self && mut.ActiveBots[J].RandGoal == N)
            return true;
    }
    return false;
}

// Free trader time roam goal (replaces the map-wide FindRandomDest). Tries a few random nodes from
// TraderRoamNodes, skipping blocked nodes, nodes another bot uses, and nodes whose route is far longer than
// the straight line (a node on another level that only looks close). Falls back to TraderRoamHome.
final function NavigationPoint PickTraderRoamGoal()
{
    local Actor Trader, NextHop;
    local NavigationPoint N;
    local int Tries;
    local float Straight;

    Trader = KFGRI.OpenedTrader;
    if (Trader != TraderRoamNodesFor)
        BuildTraderRoamNodes(Trader);
    if (TraderRoamNodes.Length == 0)
    {
        `log("[EcholonAudit] " $ LogTag() $ " TRADER_ROAM_EMPTY");
        return None;
    }
    for (Tries = 0; Tries < TRADER_ROAM_PICK_TRIES; Tries++)
    {
        N = TraderRoamNodes[Rand(TraderRoamNodes.Length)];
        if (N == None || N.bBlocked || IsRoamGoalTaken(N))
            continue;
        Straight = VSize(N.Location - Pawn.Location);
        RouteDist = 0.0;
        NavCountSearch();
        NextHop = FindPathToward(N);
        if (NextHop == None)
            continue;
        // NextHop == N means directly reachable: no route to judge.
        if (NextHop != N && RouteDist > (Straight * TRADER_ROAM_ROUTE_SLACK) + TRADER_ROAM_ROUTE_EXTRA)
            continue;
        `log("[EcholonAudit] " $ LogTag() $ " TRADER_ROAM goal=" $ string(N.Name)
            $ " dist2d=" $ string(int(VSize2D(N.Location - Trader.Location)))
            $ " dz=" $ string(int(N.Location.Z - Trader.Location.Z))
            $ " route=" $ string(int(RouteDist)) $ " straight=" $ string(int(Straight)));
        return N;
    }
    `log("[EcholonAudit] " $ LogTag() $ " TRADER_ROAM_FALLBACK tries=" $ string(TRADER_ROAM_PICK_TRIES));
    return TraderRoamHome;
}

function StopAdjusting()
{
    bAdjusting = false;
    Pawn.Acceleration = vect(0, 0, 0);
}

final function bool NeedToTurn(Vector targ)
{
    local Rotator R;

    R.Yaw = Pawn.Rotation.Yaw;
    return (Vector(R) Dot Normal2D(targ - Pawn.Location)) < 0.93;
}

event bool NotifyHitWall(Vector HitNormal, Actor Wall)
{
    if (FollowOwnsEvents())
    {
        return FollowHandleHitWall(HitNormal, Wall);
    }

    super.NotifyHitWall(HitNormal, Wall);

    if (MoveFlags != 0)
    {
        if (KFDoorActor(Wall) != None)
        {
            if (!MarkDoorPath(KFDoorActor(Wall)))
            {
                KFDoorActor(Wall).UseDoor(Pawn);
            }
            else
            {
                EndMoveTime = WorldInfo.TimeSeconds - 1.0;
            }
        }

        if ((MoveFlags == 2) && MoveTarget != None)
        {
            SetDestinationPosition(MoveTarget.Location);
        }

        if (!PickWallAdjust(HitNormal))
        {
            if ((NextAdjustTime < WorldInfo.TimeSeconds) && Pawn.Physics == 1)
            {
                bAdjusting = true;
                AdjustPosition.Position = (Pawn.Location + (HitNormal * 80.0)) + (VRand() * 50.0);
            }
        }
        else
        {
            NextAdjustTime = WorldInfo.TimeSeconds + 0.5;
        }
    }

    return false;
}

function FinishedMove()
{
    PickCombatStyle();
}

final function PickFavorite()
{
    local float desire, BestDesire;
    local EcholonWeaponInfo A;

    foreach mut.TraderList(A)
    {
        desire = A.AIRating * (FRand() + 0.3);
        if ((Perk != None) && (A.Perk != None) && Perk != A.Perk)
        {
            desire *= 0.15;
        }
        if (FavoriteWeapon == None || desire > BestDesire)
        {
            FavoriteWeapon = A.WeaponClass;
            BestDesire = desire;
        }
    }
}

final function bool SellWeapon(KFWeapon W, out int Dosh)
{
    local float desire, BestDesire;
    local KFWeapon T;
    local EcholonWeaponInfo A;

    if (W == None)
    {
        foreach KFInvManager.InventoryActors(class'KFWeapon', T)
        {
            A = mut.FindWeaponByClass(T.Class);
            if (A == None || !A.bCanSell)
            {
                continue;
            }
            desire = A.AIRating * (0.5 + FRand());
            if (W == None || desire < BestDesire)
            {
                W = T;
                BestDesire = desire;
            }
        }
        if (W == None)
        {
            return false;
        }
    }

    A = mut.FindWeaponByClass(W.Class);
    if (A == None || !A.bCanSell)
    {
        return false;
    }

    W.Destroy();
    Dosh += int(A.BuyPrice * 0.75);
    return true;
}

final function EcholonWeaponInfo GetBestBuy(int Cash)
{
    local EcholonWeaponInfo A, Best;
    local float desire, BestDesire;
    local KFWeapon W;

    Best = None;
    BestDesire = 0.0;

    foreach mut.TraderList(A)
    {
        desire = A.AIRating * (FRand() + 0.5);

        if (FavoriteWeapon == A.WeaponClass)
        {
            desire *= 4.0;
        }
        else
        {
            if ((Perk != None) && (A.Perk != None) && (Perk != A.Perk))
            {
                continue;
            }
        }

        W = KFWeapon(KFInvManager.FindInventoryType(A.WeaponClass));

        if (W != None)
        {
            if ((!W.UsesAmmo() || W.GetMissingSpareAmmoAmount(0) <= 0) || Cash < A.AmmoPricePerMag)
            {
                continue;
            }
            desire *= 2.5;
        }
        else
        {
            if ((Cash < A.BuyPrice) || ((!KFInvManager.CanCarryWeapon(A.WeaponClass)) && (FavoriteWeapon != A.WeaponClass)))
            {
                continue;
            }
        }

        if ((Best == None) || (desire > BestDesire))
        {
            Best = A;
            BestDesire = desire;
        }
    }

    return Best;
}

final function ProcessPurchase(KFGFxObject_TraderItems L)
{
    local int S, N, J, olds;
    local byte I, loops;
    local KFWeapon W, WW;
    local EcholonWeaponInfo A;

    if (!mut.bTraderListInit)
    {
        mut.InitTraderList(L);
    }

    if (FavoriteWeapon == None)
    {
        PickFavorite();
    }

    S = int(PlayerReplicationInfo.Score);
    olds = 0;

    if (Perk != None)
    {
        foreach KFInvManager.InventoryActors(Class'KFWeapon', WW)
        {
            if (WW.GetWeaponPerkClass(Perk) == Perk)
            {
                continue;
            }
            A = mut.FindWeaponByClass(WW.Class);
            if ((A == None) || !A.bCanSell)
            {
                continue;
            }
            WW.Destroy();
            S += int(float(A.BuyPrice) * 0.75);
        }
    }

    loops = 0;
    while (((S > 150) || mut.bBotsUnlimitedCash) && olds != S && loops < 7)
    {
        olds = S;
        if (mut.bBotsUnlimitedCash)
        {
            A = GetBestBuy(999999);
        }
        else
        {
            A = GetBestBuy(S);
        }

        if (A == None)
        {
            break;
        }

        W = KFWeapon(KFInvManager.FindInventoryType(A.WeaponClass));
        if (W != None)
        {
            if (!W.UsesAmmo())
            {
                break;
            }
            I = 0;
            while (I < 2)
            {
                if ((I == 1) && !W.UsesSecondaryAmmo())
                {
                    I++;
                    continue;
                }
                N = W.GetMissingSpareAmmoAmount(I);
                if (N > 0)
                {
                    if (!mut.bBotsUnlimitedCash)
                    {
                        N = Min(N, int(float(S) / A.PricePerBullet[I]));
                    }
                    W.SpareAmmoCount[I] += N;
                    S -= int(float(N) * A.PricePerBullet[I]);
                    if (S <= 0)
                    {
                        break;
                    }
                }
                I++;
            }
        }
        else
        {
            J = 0;
            while (!KFInvManager.CanCarryWeapon(A.WeaponClass) && J < 5)
            {
                if (!SellWeapon(None, S))
                {
                    break;
                }
                J++;
            }
            KFInvManager.CreateInventory(A.WeaponClass);
            S -= A.BuyPrice;
        }
        loops++;
    }

    if (((S >= L.ArmorPrice) || mut.bBotsUnlimitedCash) && KPawn.Armor < KPawn.MaxArmor)
    {
        N = KPawn.MaxArmor - KPawn.Armor;
        if (((N * L.ArmorPrice) > S) && !mut.bBotsUnlimitedCash)
        {
            N = S / L.ArmorPrice;
        }
        KPawn.Armor += byte(N);
        S -= (N * L.ArmorPrice);
    }

    if ((S > 0) || mut.bBotsUnlimitedCash)
    {
        N = (1 + Rand(4)) - KFInvManager.GrenadeCount;
        while ((N > 0) && ((S >= L.GrenadePrice) || mut.bBotsUnlimitedCash))
        {
            S -= L.GrenadePrice;
            KFInvManager.GrenadeCount++;
            N--;
        }
    }

    PlayerReplicationInfo.Score = float(Max(S, 0));
    PlayerReplicationInfo.bForceNetUpdate = true;
}

function NotifyAddInventory(Inventory NewItem)
{
    if (KFWeap_Welder(NewItem) != None)
    {
        Weapon(NewItem).AIRating = -1.0;
    }
}

function PickCombatStyle()
{
    bJustSpawned = false;
    WdLastMoveIntentTime = WorldInfo.TimeSeconds;

    if (bInTerminalState)
    {
        GotoState('VictoryDance');
        return;
    }

    if (bEnableAdvancedLocomotion && (IsInState('FollowingLeader') || IsInState('FollowingLeaderBasic')))
    {
        return;
    }

    GotoState('PickNextMove');
}

// Finds the nearest living enemy zed within hunt range and in line of sight and makes it the Enemy
// (through SetEnemy, so its filters apply) when there is none. Hunting with no Enemy has nothing to chase and bounces straight back to
// PickNextMove (zero-dwell loop), so every priority that sends a bot to Hunting must pass this first.
// Hunting.PickStyle sets NextHuntTime when it has to bounce, which stops a re-pick for a moment.
function bool AcquireHuntTarget()
{
    local KFPawn_Monster Zed, Best;
    local float Dist, BestDist;

    if (Pawn == None || WorldInfo.TimeSeconds < NextHuntTime)
        return false;
    BestDist = 999999999.0;
    foreach WorldInfo.AllPawns(class'KFPawn_Monster', Zed, Pawn.Location, HUNT_SCAN_RADIUS)
    {
        if (!Zed.IsAliveAndWell() || Zed.bIsHeadless || Zed.GetTeamNum() == GetTeamNum() || !FastTrace(Zed.Location, Pawn.Location))
            continue;
        Dist = VSizeSq(Zed.Location - Pawn.Location);
        if (Dist < BestDist)
        {
            BestDist = Dist;
            Best = Zed;
        }
    }
    if (Best == None)
        return false;
    if (Enemy != None && Enemy.IsAliveAndWell())
        return true;
    return SetEnemy(Best, true);
}

function ValidateAndNudgeSpawn()
{
    local vector NudgeLoc;
    local int Attempts;

    if (Pawn == None)
        return;
    if (IsOnWalkableFloor())
        return;

    EchelonLog("SPAWN_NUDGE status=nudging");

    for (Attempts = 0; Attempts < 6; Attempts++)
    {
        NudgeLoc = Pawn.Location;
        NudgeLoc.X = NudgeLoc.X + (FRand() * 128.0 - 64.0);
        NudgeLoc.Y = NudgeLoc.Y + (FRand() * 128.0 - 64.0);
        SetLocation(NudgeLoc);
        if (IsOnWalkableFloor())
            return;
    }

    EchelonLog("SPAWN_NUDGE status=settling");
}

function bool IsOnWalkableFloor()
{
    if (Pawn == None || Pawn.Base == None || Pawn.Base == Pawn)
        return false;
    if (Pawn.Location.Z < Pawn.Base.Location.Z)
        return false;
    return (Pawn.Location.Z - Pawn.Base.Location.Z) < 80.0;
}

function vector ComputeFormationOffset(EcholonBot Leader, bool bSingleFile)
{
    local int FollowerIdx, GroupSize;
    local float Angle;
    local vector Forward, Right, Offset;

    if (Leader == None || Leader.Pawn == None || Pawn == None)
        return Pawn.Location;

    FollowerIdx = mut.GetFollowerIndex(EcholonBot(self));
    GroupSize = mut.GetGroupSize(GroupID);
    if (GroupSize <= 0)
        GroupSize = 1;

    Forward = vector(Leader.Pawn.Rotation);
    Right = Normal(Forward cross vect(0, 0, 1));

    if (bSingleFile)
    {
        Offset = Leader.Pawn.Location - (Forward * (SINGLE_FILE_SPACING * FollowerIdx));
    }
    else
    {
        Angle = ((360.0 / GroupSize) * FollowerIdx) + (GroupID * 15.0);
        Offset = Leader.Pawn.Location + (Forward * PERIMETER_RADIUS * cos(Angle * DEG_TO_RAD)) + (Right * PERIMETER_RADIUS * sin(Angle * DEG_TO_RAD));
    }

    return Offset;
}

final function int CountNearbyZeds(float Radius)
{
    local KFPawn_Monster Z;
    local int ZedCount;

    if (Pawn == None)
    {
        return 0;
    }

    ZedCount = 0;
    foreach WorldInfo.AllPawns(class'KFPawn_Monster', Z, Pawn.Location, Radius)
    {
        if ((Z != None) && Z.IsAliveAndWell())
        {
            ZedCount++;
        }
    }

    return ZedCount;
}

final function bool AreZedsNear(vector Loc, bool bRequireCanSee, float CheckRadius, int MinimalCount)
{
    local KFPawn_Monster Z;
    local int ZedCount;

    ZedCount = 0;
    foreach WorldInfo.AllPawns(class'KFPawn_Monster', Z, Loc, CheckRadius)
    {
        if (Z == None || !Z.IsAliveAndWell())
        {
            continue;
        }
        if (bRequireCanSee && !FastTrace(Z.Location, Loc))
        {
            continue;
        }

        ZedCount++;
        if (ZedCount >= MinimalCount)
        {
            return true;
        }
    }
    return false;
}

final function bool HeavyZedWithin(float Radius)
{
    local KFPawn_Monster Z;

    if (Pawn == None)
    {
        return false;
    }

    foreach WorldInfo.AllPawns(class'KFPawn_Monster', Z, Pawn.Location, Radius)
    {
        if (Z == None || !Z.IsAliveAndWell())
        {
            continue;
        }

        if (Z.bLargeZed || Z.Class == class'KFPawn_ZedSiren')
        {
            return true;
        }
    }
    return false;
}

final function bool ShouldTacticalRetreat()
{
	if (Pawn == None)
		return false;

	if (WorldInfo.TimeSeconds - LastZedCountTime >= ZED_COUNT_INTERVAL)
	{
		LastZedCountTime = WorldInfo.TimeSeconds;
		CachedZedCount = CountNearbyZeds(RETREAT_ZED_RADIUS);
		bCachedHeavyZed = HeavyZedWithin(RETREAT_HEAVY_RADIUS);
	}

	return (CachedZedCount >= RETREAT_ZED_TRIGGER_COUNT) || bCachedHeavyZed || ExceedsRetreatZedCount();
}

final function bool IsMeleeOnly()
{
    if (Pawn == None)
        return false;

    if (Pawn.Weapon != None)
        return Pawn.Weapon.bMeleeWeapon;
    else
        return !Pawn.HasRangedAttack();
}

final function bool CheckObjectiveHazard()
{
    local KFPawn_Monster P;

    if (Pawn == None)
        return false;

    // Siren check: engage a nearby Siren before pushing further into the
    // objective corridor.
    foreach WorldInfo.AllPawns(class'KFPawn_Monster', P, Pawn.Location, SIREN_CHECK_RADIUS)
    {
        if (P == None || !P.IsAliveAndWell())
            continue;
        if (P.Class == class'KFPawn_ZedSiren' && FastTrace(Pawn.Location, P.Location))
        {
            SetEnemy(P, true);
            GotoState('FightEnemy');
            return true;
        }
    }

    if (!AreZedsNear(Pawn.Location, false, OBJECTIVE_HAZARD_RADIUS, OBJECTIVE_HAZARD_ZED_COUNT))
    {
        return false;
    }

    // Dense crowd in the approach corridor: fight through it first.
    if (Enemy == None || !Enemy.IsAliveAndWell())
    {
        PickNextEnemy();
    }
    if (Enemy != None && Enemy.IsAliveAndWell())
    {
        GotoState('FightEnemy');
        return true;
    }

    // Zeds are near but nothing is targetable yet -- hold this call.
    Focus = None;
    SetFocalPoint(Pawn.Location + (VRand() * 300.0));
    return true;
}

final function ForceBreakGrapple()
{
    local KFPawn GrabbingZed;

    if (KPawn == None)
    {
        return;
    }

    GrabbingZed = KPawn.InteractionPawn;

    if (mut != None && mut.bDebugGrapple)
    {
        mut.DebugMessage(GetHumanReadableName() $ " grapple failsafe triggered after " $ string(int(WorldInfo.TimeSeconds - GrabStartTime)) $ "s - ending the grab (hard cap).");
    }

    if (GrabbingZed != None)
    {
        GrabbingZed.EndSpecialMove();
    }

    KPawn.EndSpecialMove();
    KPawn.InteractionPawn = None;
}

// Grabbed and surrounded: besides the grabber, GRAB_SURROUND_COUNT or more visible living zeds within
// GRAB_SURROUND_RADIUS, or at least 2 with one of them behind the bot (more than 90 degrees from the grabber).
final function bool IsGrabSurrounded(Pawn Grabber)
{
    local KFPawn_Monster Z;
    local vector ToGrabber, ToZed;
    local int Others;
    local bool bFlanked;

    if (Pawn == None || Grabber == None)
        return false;
    ToGrabber = Grabber.Location - Pawn.Location;
    ToGrabber.Z = 0.0;
    ToGrabber = Normal(ToGrabber);
    foreach WorldInfo.AllPawns(class'KFPawn_Monster', Z, Pawn.Location, GRAB_SURROUND_RADIUS)
    {
        if (Z == Grabber || !Z.IsAliveAndWell() || Z.bIsHeadless || Z.GetTeamNum() == GetTeamNum()
            || !FastTrace(Z.Location, Pawn.Location))
        {
            continue;
        }
        Others++;
        ToZed = Z.Location - Pawn.Location;
        ToZed.Z = 0.0;
        if ((Normal(ToZed) Dot ToGrabber) < 0.0)
            bFlanked = true;
    }
    return (Others >= GRAB_SURROUND_COUNT) || (Others >= 2 && bFlanked);
}

// Surrounded while grabbed: shoot the grabber with the current weapon for a real hit (any enemy hit ends an
// AI grab). Uses the shot-point probe so the bot never fires into a wall. Returns false when it can't shoot
// (no weapon, medic gun, no ammo, no clear point) so the caller falls back to the bash.
final function bool TryShootGrabber(KFPawn Grabber)
{
    local KFWeapon W;

    if (Pawn == None || Grabber == None)
        return false;
    W = KFWeapon(Pawn.Weapon);
    if (W == None || W == MedicGun || !W.HasAmmo(BOTFM_PRIMARY))
        return false;
    if (!ProbeShotPoint(Grabber))
        return false;
    Target = Grabber;
    if (!Pawn.IsFiring())
        W.StartFire(BOTFM_PRIMARY);
    return true;
}

function bool IsBotAlive()
{
    return (Pawn != None) && (Pawn.Health > 0);
}

function bool CanHealOthers()
{
    return MedicGun != None;
}

function bool IsHealLockedOut()
{
    return false;
}

function bool ShouldAbortRetreat()
{
    return false;
}

function vector GetObjectiveLocation()
{
    local vector ObjLoc;

    ObjLoc = vect(0, 0, 0);

    if (mut != None)
    {
        ObjLoc = mut.GetObjectiveLocation();
        if (VSizeSq(ObjLoc) > 1.0)
        {
            return ObjLoc;
        }
    }

    if (Pawn != None)
    {
        return Pawn.Location;
    }

    return vect(0, 0, 0);
}

function bool IsBossWaveActive()
{
    local KFGameReplicationInfo GRI;

    GRI = KFGameReplicationInfo(WorldInfo.GRI);
    return (GRI != None && GRI.IsBossWave());
}

function EchelonLog(string Msg)
{
	if (WorldInfo == None || (mut != None && mut.bDisableAuditLog))
	{
		return;
	}
	if (!AuditRateLimit(Msg))
	{
		return;
	}
	`log("[EcholonAudit] " $ LogTag() $ " " $ Msg);
}

function bool AuditRateLimit(string Msg)
{
	local float IterNow;

	IterNow = WorldInfo.TimeSeconds;
	if (Left(Msg, 4) ~= "HUB_")
	{
		return true;  // hub audit lines are never throttled; hub_audit.py needs every one
	}
	if (Left(Msg, 10) ~= "NAV_ACCEL_")
	{
		// per-tick movement lines: one a second per bot is enough (NAV_STUCK names the node itself)
		if (IterNow - AuditLastLog_NAVACCEL < 1.0)
		{
			return false;
		}
		AuditLastLog_NAVACCEL = IterNow;
		return true;
	}
	if (Left(Msg, 4) ~= "NAV_" || Left(Msg, 11) ~= "SPAWN_NUDGE")
	{
		return true;  // were plain `log lines before; kept unthrottled
	}
	if (Left(Msg, 10) ~= "STATE_EXIT")
	{
		if (IterNow - AuditLastLog_STATE_EXIT < 5.0)
		{
			return false;
		}
		AuditLastLog_STATE_EXIT = IterNow;
		return true;
	}
	if (Left(Msg, 4) ~= "GOAL")
	{
		if (IterNow - AuditLastLog_GOAL < 5.0)
		{
			return false;
		}
		AuditLastLog_GOAL = IterNow;
		return true;
	}
	if (Left(Msg, 15) ~= "FOLLOWGATE_EVAL")
	{
		if (IterNow - AuditLastLog_FOLLOWGATE < 5.0)
		{
			return false;
		}
		AuditLastLog_FOLLOWGATE = IterNow;
		return true;
	}
	if (IterNow - AuditLastLog_GEN < 5.0)
	{
		return false;
	}
	AuditLastLog_GEN = IterNow;
	return true;
}

function bool FollowGetOrderAnchor(out vector OutLoc)
{
    local vector Loc;

    OutLoc = vect(0, 0, 0);
    if (mut == None)
    {
        return false;
    }
    if (!mut.IsSquadInObjectivePhase(EcholonBot(self)))
    {
        return false;
    }
    Loc = mut.GetSlotLocation(EcholonBot(self));
    if (Loc == vect(0, 0, 0))
    {
        return false;
    }
    OutLoc = Loc;
    return true;
}

function AuditStateEntry()
{
	if (WorldInfo != None)
	{
		AuditStateEntryTime = WorldInfo.TimeSeconds;
		AuditStateEntryName = GetStateName();
		WdLastMoveIntentTime = WorldInfo.TimeSeconds;
		// PickNextMove is the hub every decision passes through; logging it would drown the rest.
		if (AuditStateEntryName != 'PickNextMove')
		{
			EchelonLog("STATE_ENTER state=" $ AuditStateEntryName);
		}
	}
}

function AuditStateExit(name NextStateName)
{
	local float IterDwell;

	if (HubPriority != "" && AuditStateEntryName == HubNextState)
	{
		HubResolve(NextStateName);
	}
	if (WorldInfo != None)
	{
		IterDwell = WorldInfo.TimeSeconds - AuditStateEntryTime;
		AuditDwellTotal += IterDwell;
		if (IterDwell >= 3.0)
		{
			EchelonLog("STATE_EXIT state=" $ AuditStateEntryName $ " next=" $ NextStateName $ " reason=unspecified" $ " duration=" $ string(IterDwell));
		}
		if (WorldInfo.TimeSeconds - AuditLastLog_DWELLTOT >= 60.0)
		{
			EchelonLog("DWELL_TOTAL sinceLast=" $ string(AuditDwellTotal));
			AuditDwellTotal = 0.0;
			AuditLastLog_DWELLTOT = WorldInfo.TimeSeconds;
		}
	}
}

function AuditGoalLog(string Op, string Src)
{
	local string IterLoc;
	local int IterAmmo;
	local KFWeapon W;

	if (ObjectiveGoal == None || WorldInfo == None)
	{
		return;
	}

	IterAmmo = 0;
	if (Pawn != None && Pawn.Weapon != None)
	{
		W = KFWeapon(Pawn.Weapon);
		if (W != None && W.GetTotalAmmoAmount(0) > 0)
		{
			IterAmmo = 1;
		}
	}

	IterLoc = string(FFloor(ObjectiveGoal.Location.X / 100.0)) $ "," $ string(FFloor(ObjectiveGoal.Location.Y / 100.0)) $ "," $ string(FFloor(ObjectiveGoal.Location.Z / 100.0));

	if (Op == "GOAL_SET")
	{
		EchelonLog("GOAL_SET goal=(" $ IterLoc $ ") ammo=" $ string(IterAmmo) $ " src=" $ Src);
	}
	else
	{
		EchelonLog("GOAL_CLEAR src=" $ Src);
	}
}

function IssueCommand(name Cmd, Vector Anchor)
{
    CurrentOrder = Cmd;
    OrderAnchor = Anchor;
    EchelonLog("CMD_ISSUE cmd=" $ Cmd);
}

function SLDecisionLoop()
{
    local Vector RetreatDest;
    local Rotator R;
    local Vector Fwd, Rgt, Up;

    bSLLoopSuspended = (Pawn == None || Pawn.Health <= 0
                        || IsInState('BreakLose') || IsInState('IsRagdolled') || IsInState('Dead'));
    if (bSLLoopSuspended)
        return;

    ScanRoomForFormation();
    RefreshSquadZedCache();
    SLGrenadeCheck();
    CheckWeaponReequip();
    UpdateOverwatchTimer();
    CheckOverwatchStall();
    UpdatePanicBroadcast();
    HandleReloadDrift();
    UpdateWedgeMode();
    UpdateHoldAreaDrift();

    if (ShouldTacticalRetreat() || ExceedsRetreatZedCount())
    {
        R.Yaw = Pawn.Rotation.Yaw;
        GetAxes(R, Fwd, Rgt, Up);
        RetreatDest = Pawn.Location - (Fwd * 300.0);
        if (!IsRetreatSafe(RetreatDest))
        {
            HoldAndCrouch();
            return;
        }
        IssueCommand('CMD_TacticalRetreat', RetreatDest);
        return;
    }
}

function LTDispatchLoop()
{
    EchelonLog("LT_DISPATCH_LOOP");
}

final function ScanRoomForFormation()
{
    local Vector Src, X, Y, Z, EndPt, HitLoc, HitNorm;
    local Rotator FlatRot;
    local Actor HitActor;
    local float FwdDistSq;
    local int ClearCount;
    local bool bFwd, bLeft, bRight, bBack;
    local name Wanted;

    if (BotRank != SQUAD_LEADER || Pawn == None || bFormationScanDeferred)
    {
        return;
    }

    FormationYaw = Pawn.Rotation.Yaw;

    if (bRerouteRequested)
    {
        bRerouteRequested = false;
        FormationEpoch++;
        if (WorldInfo.TimeSeconds - LastRerouteTime < 4.0)
        {
            CurrentFormation = 'SingleFile';
            PendingFormationCount = 0;
            FormationHoldUntil = WorldInfo.TimeSeconds + 3.0;
        }
        LastRerouteTime = WorldInfo.TimeSeconds;
    }

    if (WorldInfo.TimeSeconds < FormationHoldUntil)
    {
        return;
    }

    if (Class'EcholonBotBase'.default.LastFormationScanTime == WorldInfo.TimeSeconds)
    {
        bFormationScanDeferred = true;
        SetTimer(0.034, false, 'DeferredFormationScan');
        return;
    }
    LastFormationScanTime = WorldInfo.TimeSeconds;

    Src = Pawn.Location;
    FlatRot.Yaw = Pawn.Rotation.Yaw;
    GetAxes(FlatRot, X, Y, Z);

    EndPt = Src + (X * FORM_LINE_DIST);
    HitActor = Trace(HitLoc, HitNorm, EndPt, Src, false);
    if (HitActor != None && KFPawn_Human(HitActor) == None)
    {
        FwdDistSq = VSizeSq(HitLoc - Src);
    }
    else
    {
        FwdDistSq = FORM_LINE_DIST * FORM_LINE_DIST;
    }
    bFwd = FwdDistSq >= FORM_SCAN_DIST * FORM_SCAN_DIST;

    bLeft = FastTrace(Src - (Y * FORM_SCAN_DIST), Src);
    bRight = FastTrace(Src + (Y * FORM_SCAN_DIST), Src);
    bBack = FastTrace(Src - (X * FORM_SCAN_DIST), Src);

    ScanMask = 0;
    if (bFwd)
    {
        ScanMask = byte(ScanMask | 1);
        ClearCount++;
    }
    if (bLeft)
    {
        ScanMask = byte(ScanMask | 2);
        ClearCount++;
    }
    if (bRight)
    {
        ScanMask = byte(ScanMask | 4);
        ClearCount++;
    }
    if (bBack)
    {
        ScanMask = byte(ScanMask | 8);
        ClearCount++;
    }

    if (ClearCount >= 3)
    {
        Wanted = 'Arrowhead';
    }
    else if (ClearCount >= 2)
    {
        Wanted = 'StaggeredColumn';
    }
    else
    {
        Wanted = 'SingleFile';
    }

    if (FwdDistSq >= 360000.0 && bLeft && bRight && Enemy != None && Enemy.IsAliveAndWell()
        && (X Dot Normal(Enemy.Location - Src)) > 0.5
        && WorldInfo.TimeSeconds >= LineSuppressUntil)
    {
        Wanted = 'LineFormation';
    }

    if (Wanted == CurrentFormation)
    {
        PendingFormationCount = 0;
        return;
    }
    if (Wanted != PendingFormation)
    {
        PendingFormation = Wanted;
        PendingFormationCount = 1;
        return;
    }
    CurrentFormation = Wanted;
    PendingFormationCount = 0;
    FormationEpoch++;
}

function DeferredFormationScan()
{
	bFormationScanDeferred = false;
	ScanRoomForFormation();
}

final function Vector GetFormationBase(int Slot, name Formation, bool bMirror)
{
	local Vector V;
	local float SideSign, Tier;

	Slot = Slot % 4;
	if ((Slot % 2) == 0)
	{
		SideSign = -1.0;
	}
	else
	{
		SideSign = 1.0;
	}
	Tier = float((Slot / 2) + 1);
	switch (Formation)
	{
		case 'Arrowhead':
			V.X = -150.0 * Tier;
			V.Y = SideSign * 150.0 * Tier;
			break;
		case 'LineFormation':
			V.X = -40.0;
			V.Y = SideSign * (120.0 * Tier);
			break;
		case 'SingleFile':
			V.X = -150.0 * float(Slot + 1);
			break;
		default:
			V.X = -130.0 * float(Slot + 1);
			if (bMirror)
			{
				V.Y = SideSign * 70.0 * -1.0;
			}
			else
			{
				V.Y = SideSign * 70.0;
			}
			break;
	}
	return V;
}

function Vector ComputeSlotOffset(optional int Slot = -1)
{
	local EcholonBot SL;
	local name Form;
	local int Epoch, Yaw;
	local float Jitter;
	local Rotator R;
	local Vector Fwd, Rgt, Up;

	if(Slot < 0)
	{
		Slot = GruntSlot;
	}
	SL = SquadLeader;
	if(SL != None)
	{
		Form = SL.CurrentFormation;
		Epoch = SL.FormationEpoch;
		Yaw = SL.FormationYaw;
		LastFormationYaw = Yaw;
	}
	else
	{
		Form = CachedOffsetFormation;
		Epoch = CachedOffsetEpoch;
		Yaw = LastFormationYaw;
	}
	if(Form == 'None')
	{
		Form = 'StaggeredColumn';
	}

	if(!bOffsetCached || (Epoch != CachedOffsetEpoch) || (Slot != CachedOffsetSlot) || (Form != CachedOffsetFormation))
	{
		bOffsetCached = true;
		CachedOffsetEpoch = Epoch;
		CachedOffsetSlot = Slot;
		CachedOffsetFormation = Form;
		Jitter = 0.10 + (0.05 * FRand());
		CachedLocalOffset = GetFormationBase(Slot, Form, Rand(2) == 0);
		if(Rand(2) == 0)
		{
			CachedLocalOffset.X *= 1.0 + Jitter;
		}
		else
		{
			CachedLocalOffset.X *= 1.0 - Jitter;
		}
		if(Rand(2) == 0)
		{
			CachedLocalOffset.Y *= 1.0 + Jitter;
		}
		else
		{
			CachedLocalOffset.Y *= 1.0 - Jitter;
		}
	}

	R.Yaw = Yaw;
	GetAxes(R, Fwd, Rgt, Up);
	return (Fwd * CachedLocalOffset.X) + (Rgt * CachedLocalOffset.Y);
}

final function bool SyncLineFocus()
{
	local Pawn LT;

	if ((BotRank != GRUNT) || (Pawn == None))
	{
		return false;
	}

	if ((SquadLeader != None) && (SquadLeader.CurrentFormation == 'LineFormation'))
	{
		LT = SquadLeader.Enemy;
		if ((LT != None) && LT.IsAliveAndWell())
		{
			if (InheritedEnemy != LT)
			{
				InheritedEnemy = LT;
				Enemy = LT;
				Focus = LT;
				if (GetStateName() != 'FightEnemy')
				{
					GotoState('FightEnemy');
				}
			}
			return false;
		}
	}

	if (InheritedEnemy != None)
	{
		if (Enemy == InheritedEnemy)
		{
			Enemy = None;
			Focus = None;
			Pawn.StopFiring();
			InheritedEnemy = None;
			if (GetStateName() == 'FightEnemy')
			{
				PickCombatStyle();
				return true;
			}
		}
		InheritedEnemy = None;
	}

	return false;
}

// Kept for its callers (FightEnemy and the line-formation blocked-shooter report); now the shot-point probe.
final function bool HasOwnFireLine(Actor T)
{
    return ProbeShotPoint(T);
}

// Picks the first point of T that a bullet from the eyes would reach: head, torso, pelvis, then the pivot.
// Clear means the first thing the trace hits is nothing, T, or another zed (it takes the bullet instead).
// World geometry, doors and teammates block. Cached SHOT_PROBE_INTERVAL per target; the chosen bone is
// read again on every aim call (GetAdjustedAimFor) because bones move.
final function bool ProbeShotPoint(Actor T)
{
    local KFPawn KP;
    local KFPawn_Monster KM;
    local vector EyeLoc;
    local rotator EyeRot;
    local name Bone;
    local int I;

    if ((T == None) || (Pawn == None))
        return false;
    if ((T == ShotProbeTarget) && (WorldInfo.TimeSeconds < NextShotProbeTime))
        return bShotProbeClear;

    ShotProbeTarget = T;
    NextShotProbeTime = WorldInfo.TimeSeconds + SHOT_PROBE_INTERVAL;
    ShotProbeBone = '';
    bShotProbeClear = false;

    Pawn.GetActorEyesViewPoint(EyeLoc, EyeRot);
    KP = KFPawn(T);
    KM = KFPawn_Monster(T);

    if ((KP != None) && (KP.Mesh != None))
    {
        for (I = 0; I < 3; I++)
        {
            if (I == 0)
            {
                if ((KM != None) && KM.bIsHeadless)
                    continue;
                Bone = KP.HeadBoneName;
            }
            else if (I == 1)
            {
                Bone = KP.TorsoBoneName;
            }
            else
            {
                Bone = KP.PelvisBoneName;
            }
            if ((Bone == '') || (KP.Mesh.MatchRefBone(Bone) == INDEX_NONE))
                continue;
            if (IsShotPathClear(T, EyeLoc, KP.Mesh.GetBoneLocation(Bone)))
            {
                ShotProbeBone = Bone;
                bShotProbeClear = true;
                return true;
            }
        }
    }

    bShotProbeClear = IsShotPathClear(T, EyeLoc, T.Location);
    return bShotProbeClear;
}

// One bullet-style trace (same flags as Weapon.CalcWeaponFire). Clear when nothing, T or any zed is hit first.
final function bool IsShotPathClear(Actor T, vector StartLoc, vector EndLoc)
{
    local vector HitLoc, HitNorm;
    local TraceHitInfo HitInfo;
    local Actor HitActor;

    HitActor = Pawn.Trace(HitLoc, HitNorm, EndLoc, StartLoc, true, vect(0.0, 0.0, 0.0), HitInfo, TRACEFLAG_Bullet);
    if ((HitActor == None) || (HitActor == T))
        return true;
    return (KFPawn_Monster(HitActor) != None);
}

final function bool ValidateOffsetTarget(Vector OffsetTarget)
{
    if (FastTrace(OffsetTarget, Pawn.Location))
    {
        BlockedCounter = 0;
        return true;
    }

    BlockedCounter++;
    if (BlockedCounter >= 3)
    {
        BlockedCounter = 0;
        if ((SquadLeader != None) && (SquadLeader.Pawn != None) && SquadLeader.Pawn.IsAliveAndWell())
        {
            SquadLeader.RequestRerouteWithBlock(Pawn.Location);
        }
    }

    return false;
}

function RequestRerouteWithBlock(Vector BlockedPos)
{
	if (BotRank == SQUAD_LEADER)
	{
		bRerouteRequested = true;
	}
}

final function bool IsDirClearCached(Vector Dest)
{
	local Vector X, Y, Z, Dir;
	local Rotator R;
	local float DX, DY;
	local byte Bit;

	R.Yaw = FormationYaw;
	GetAxes(R, X, Y, Z);
	Dir = Normal2D(Dest - Pawn.Location);
	DX = Dir Dot X;
	DY = Dir Dot Y;
	if ((DX * DX) >= (DY * DY))
	{
		if (DX > 0.0)
		{
			Bit = 1;
		}
		else
		{
			Bit = 8;
		}
	}
	else
	{
		if (DY > 0.0)
		{
			Bit = 4;
		}
		else
		{
			Bit = 2;
		}
	}
	return (ScanMask & Bit) != 0;
}

final function bool IsRetreatSafe(Vector RetreatDest)
{
	local KFPawn_Monster M;
	local byte Zeds;

	Zeds = 0;
	if (!IsDirClearCached(RetreatDest))
	{
		return false;
	}
	foreach VisibleCollidingActors(class'KFPawn_Monster', M, 500.0, RetreatDest)
	{
		if (M.IsAliveAndWell() && (++Zeds >= 20))
		{
			return false;
		}
	}
	return true;
}

final function SetSquadCrouchHold()
{
	bSquadCrouchHold = true;
	SetTimer(3.0, false, 'ClearSquadCrouchHold');
}

function ClearSquadCrouchHold()
{
	bSquadCrouchHold = false;
}

final function HoldAndCrouch()
{
	IssueCommand('CMD_HoldArea', Pawn.Location);
	SetSquadCrouchHold();
}

final function bool TryIssueSafeAnchor(Vector NewAnchor)
{
    if ((Pawn != None) && IsDirClearCached(NewAnchor))
    {
        bSquadCrouchHold = false;
        IssueCommand('CMD_HoldArea', NewAnchor);
        return true;
    }
    SetSquadCrouchHold();
    return false;
}

final function ApplySquadCrouchHold()
{
	local bool bWant;

	bWant = (SquadLeader != None) && SquadLeader.bSquadCrouchHold;
	if (bWant && (mut == None || !mut.bAllowBotCrouch))
	{
		bWant = false;
	}
	if (bWant != bHoldCrouching)
	{
		bHoldCrouching = bWant;
		Pawn.ShouldCrouch(bWant);
	}
}

final function ClearRankTimers()
{
    ClearTimer('StartSLLoop');
    ClearTimer('SLDecisionLoop');
    ClearTimer('StartLTLoop');
    ClearTimer('LTDispatchLoop');
    ClearTimer('StartCaptainLoop');
    ClearTimer('DeferredFormationScan');
    ClearTimer('ClearSquadCrouchHold');
    ClearTimer('SLGrenadeLOSPhase');
    ClearTimer('ClearGrenadeSignal');
    GrenadeSignal = false;
    GrenadeThrowsLeft = 0;
    GrenadeTargetPawn = None;
    bFormationScanDeferred = false;
}

final function name GetRankName()
{
    switch (BotRank)
    {
        case CAPTAIN:
            return 'Captain';
        case LIEUTENANT:
            return 'Lieutenant';
        case SQUAD_LEADER:
            return 'SquadLeader';
        default:
            return 'Grunt';
    }
}

final function UpdateRoleNameTag()
{
    local string IDStr;
    local int StartIdx;

    if (PlayerReplicationInfo != None)
    {
        if (BasePlayerName == "")
        {
            BasePlayerName = PlayerReplicationInfo.PlayerName;
        }

        StartIdx = 0;
        if (Left(BasePlayerName, 4) == "Bot_")
        {
            StartIdx = 4;
        }

        IDStr = Mid(BasePlayerName, StartIdx, Len(BasePlayerName) - StartIdx);
        PlayerReplicationInfo.PlayerName = "[" $ GetRankName() $ "] " $ IDStr;
    }
}

final function RefreshRoleNameTag()
{
    local string BaseName;
    local int BracketsEnd;
    local int StartIdx;

    if (PlayerReplicationInfo == None)
    {
        return;
    }

    if (BasePlayerName != "")
    {
        BaseName = BasePlayerName;
    }
    else
    {
        BaseName = PlayerReplicationInfo.PlayerName;
        if (Left(BaseName, 1) == "[")
        {
            BracketsEnd = InStr(BaseName, "]");
            if (BracketsEnd >= 0)
            {
                BaseName = Mid(BaseName, BracketsEnd + 1, Len(BaseName) - BracketsEnd - 1);
                if (Left(BaseName, 1) == " ")
                {
                    BaseName = Mid(BaseName, 1, Len(BaseName) - 1);
                }
            }
        }
        BasePlayerName = BaseName;
    }

    StartIdx = 0;
    if (Left(BaseName, 4) == "Bot_")
    {
        StartIdx = 4;
    }
    PlayerReplicationInfo.PlayerName = "[" $ GetRankName() $ "] " $ Mid(BaseName, StartIdx, Len(BaseName) - StartIdx);
}

final function SeedGruntGates()
{
	LastOffsetUpdate = WorldInfo.TimeSeconds - (FRand() * 0.2);
	LastHealthCheck = WorldInfo.TimeSeconds - (FRand() * 2.0);
	NextFireLineCheck = WorldInfo.TimeSeconds + (FRand() * 0.5);
}

final function ArmRankTimers()
{
    ClearRankTimers();
    switch (BotRank)
    {
        case SQUAD_LEADER:
            SetTimer(0.01 + (FRand() * 0.49), false, 'StartSLLoop');
            break;
        case LIEUTENANT:
            SetTimer(0.01 + (FRand() * 0.99), false, 'StartLTLoop');
            break;
        case CAPTAIN:
            SetTimer(0.01 + (FRand() * 2.99), false, 'StartCaptainLoop');
            break;
        default:
            SeedGruntGates();
            break;
    }
}

function StartSLLoop()
{
	SetTimer(0.5, true, 'SLDecisionLoop');
	SLDecisionLoop();
}

function StartLTLoop()
{
	SetTimer(1.0, true, 'LTDispatchLoop');
	LTDispatchLoop();
}

function StartCaptainLoop()
{
}

final function SetBotRank(EBotRank NewRank)
{
    BotRank = NewRank;
    ArmRankTimers();
}

final function NotifyBlockedShooter(EcholonBot Shooter)
{
	if (BotRank != SQUAD_LEADER)
	{
		return;
	}

	if ((WorldInfo.TimeSeconds - BlockedShooterWindowStart) > 1.5)
	{
		BlockedShooterWindowStart = WorldInfo.TimeSeconds;
		BlockedShooterCount = 0;
	}

	if (++BlockedShooterCount >= 2)
	{
		BlockedShooterCount = 0;
		LineSuppressUntil = WorldInfo.TimeSeconds + 4.0;
		if (CurrentFormation == 'LineFormation')
		{
			CurrentFormation = 'StaggeredColumn';
			PendingFormationCount = 0;
			++FormationEpoch;
		}
	}
}

final function bool ShouldReload(KFWeapon W)
{
	if (W == None)
	{
		return false;
	}
	if (W.HasAmmo(BOTFM_PRIMARY, 1))
	{
		return false;
	}
	return W.HasAnyAmmo();
}

final function float GetWeaponEffectiveRangeUU(KFWeapon W)
{
	if (W == None)
	{
		return DefaultWeaponEffectiveRangeUU;
	}
	if (W.IsA('KFWeap_ShotgunBase'))
	{
		return ShotgunEffectiveRangeUU;
	}
	if (W.IsA('KFWeap_Flame_Flamethrower'))
	{
		return FlamethrowerEffectiveRangeUU;
	}
	if (W.IsA('KFWeap_FlameBase'))
	{
		return FlamethrowerEffectiveRangeUU;
	}
	return DefaultWeaponEffectiveRangeUU;
}

final function bool IsInEffectiveRange(Actor T)
{
	local KFWeapon W;
	local float MaxRange;

	W = KFWeapon(Pawn.Weapon);
	if (W == None || T == None)
	{
		return false;
	}
	if (W != RangeCacheWeapon)
	{
		RangeCacheWeapon = W;
		MaxRange = GetWeaponEffectiveRangeUU(W);
		RangeCacheSq = MaxRange * MaxRange;
	}
	if (RangeCacheSq <= 0.0)
	{
		return true;
	}
	return VSizeSq(T.Location - Pawn.Location) <= RangeCacheSq;
}

// A random unit vector in the horizontal plane (VRand() has a vertical part that makes zero-length or floor-bound moves).
final function vector RandDir2D()
{
    local vector V;

    V = VRand();
    V.Z = 0.0;
    if (VSizeSq(V) < 0.01)
    {
        V.X = 1.0;
        V.Y = 0.0;
    }
    return Normal(V);
}

final function CloseToEffectiveRange()
{
    if (BotRank == GRUNT)
    {
        MoveToX(Pawn.Location + (Normal2D(Enemy.Location - Pawn.Location) * 250.0), Enemy, true, 'CloseRange1');
    }
    else if (WalkReachable(Enemy))
    {
        MoveTowardX(Enemy, Enemy, true, 'CloseRange2');
    }
    else if (BuildPathToward(Enemy))
    {
        MoveTowardX(MoveTarget, Enemy, true, 'CloseRange3');
    }
    else
    {
        MoveToX(Pawn.Location + (Normal2D(Enemy.Location - Pawn.Location) * 300.0), Enemy, true, 'CloseRange4');
    }
}

final function CheckWeaponReequip()
{
	local bool bReady;

	if (!bFallbackWeapon || (Pawn == None))
	{
		return;
	}
	if ((FallbackPrimary == None) || (Pawn.Weapon == FallbackPrimary))
	{
		bFallbackWeapon = false;
		return;
	}
	if (bFallbackHadSpare)
	{
		bReady = ((WorldInfo.TimeSeconds - FallbackSince) > 1.5) && ((Enemy == None) || (CountNearbyZedsCached(500.0) < 3));
	}
	else
	{
		bReady = FallbackPrimary.HasAnyAmmo();
	}
	if (bReady)
	{
		bFallbackWeapon = false;
		Pawn.InvManager.SetCurrentWeapon(FallbackPrimary);
		return;
	}
	if ((Pawn.Weapon != None) && Pawn.Weapon.bMeleeWeapon && (NextFallbackPoll < WorldInfo.TimeSeconds))
	{
		NextFallbackPoll = WorldInfo.TimeSeconds + 1.0;
		SwitchToBestWeapon(true);
	}
}

final function bool ShouldThrowGrenade(out Actor Aim, bool bFromSignal, Actor CurEnemy)
{
	local EcholonBot SL;

	Aim = None;
	bFromSignal = false;

	if ((KFInvManager == None) || (KFInvManager.GrenadeCount <= 0) || (NextGrenadeTimer > WorldInfo.TimeSeconds))
	{
		return false;
	}

	if (BotRank == SQUAD_LEADER)
	{
		SL = EcholonBot(self);
	}
	else
	{
		SL = SquadLeader;
	}

	// (1) SL broadcast
	if ((SL != None) && SL.GrenadeSignal && (SL.GrenadeThrowsLeft > 0) && (SL.GrenadeTargetPawn != None)
		&& SL.GrenadeTargetPawn.IsAliveAndWell()
		&& (VSizeSq(SL.GrenadeTargetPawn.Location - Pawn.Location) < 90000.0))
	{
		Aim = SL.GrenadeTargetPawn;
		bFromSignal = true;
		return true;
	}

	// (2) HearNoise
	if ((CurEnemy != None) && (HearNoiseZedCount >= 2) && (WorldInfo.TimeSeconds < HearNoiseExpireTime)
		&& (VSizeSq(LastNoiseLoc - Pawn.Location) < 160000.0))
	{
		Aim = CurEnemy;
		return true;
	}

	// (3) self-preservation
	if ((CurEnemy != None) && (Pawn.Health < (Pawn.HealthMax * 0.3)) && (CountNearbyZedsCached(200.0) >= 2))
	{
		Aim = CurEnemy;
		return true;
	}

	return false;
}

final function bool TryThrowGrenade(KFWeapon W, Actor CurEnemy)
{
	local Actor Aim;
	local bool bFromSignal;

	bFromSignal = false;

	if (!ShouldThrowGrenade(Aim, bFromSignal, CurEnemy))
	{
		GrenadeAimTicks = 0;
		return false;
	}

	if (NeedToTurn(Aim.Location))
	{
		if (++GrenadeAimTicks > 3)
		{
			GrenadeAimTicks = 0;
			NextGrenadeTimer = WorldInfo.TimeSeconds + 2.0;
			return false;
		}
		Focus = Aim;
		return true;
	}

	GrenadeAimTicks = 0;
	NextGrenadeTimer = WorldInfo.TimeSeconds + 4.0 + (FRand() * 3.0);

	if (bFromSignal && (SquadLeader != None) && (SquadLeader.GrenadeThrowsLeft > 0))
	{
		--SquadLeader.GrenadeThrowsLeft;
	}

	Target = Aim;
	Focus = Aim;
	W.StartFire(BOTFM_GRENADE);
	return true;
}

function SLGrenadeCheck()
{
	local int I, Near;

	if( (BotRank != SQUAD_LEADER) || (Pawn == None) || GrenadeSignal || (NextGrenadeSignalTime > WorldInfo.TimeSeconds) )
	{
		return;
	}
	for( I = 0; I < SquadZedCount; I++ )
	{
		if( (SquadZedCache[I] != None) && (SquadZedCache[I].Health > 0)
			&& (VSizeSq(SquadZedCache[I].Location - Pawn.Location) < 90000.0) )
		{
			Near++;
		}
	}
	if( Near >= 3 )
	{
		SetTimer(0.07, false, 'SLGrenadeLOSPhase');
	}
}

function SLGrenadeLOSPhase()
{
	local int I, Traces, NoLOS, Near;
	local Pawn Z, Pick;

	if (BotRank != SQUAD_LEADER || Pawn == None)
	{
		return;
	}
	for (I = 0; I < SquadZedCount; I++)
	{
		Z = SquadZedCache[I];
		if (Z == None || Z.Health <= 0 || VSizeSq(Z.Location - Pawn.Location) >= 90000.0)
		{
			continue;
		}
		Near++;
		if (Traces < 3)
		{
			Traces++;
			if (!FastTrace(Z.Location, Pawn.Location))
			{
				NoLOS++;
				if (Pick == None)
				{
					Pick = Z;
				}
			}
		}
	}
	if (Near >= 3 && NoLOS >= 2)
	{
		GrenadeSignal = true;
		GrenadeThrowsLeft = 2;
		GrenadeTargetPawn = Pick;
		NextGrenadeSignalTime = WorldInfo.TimeSeconds + 6.0;
		SetTimer(2.0, false, 'ClearGrenadeSignal');
	}
}

function ClearGrenadeSignal()
{
	GrenadeSignal = false;
	GrenadeThrowsLeft = 0;
	GrenadeTargetPawn = None;
}

final function bool HandleWeaponManagement(KFWeapon W)
{
	local KFWeapon Best;

	if (ShouldReload(W))
	{
		if (NextReloadAttempt < WorldInfo.TimeSeconds)
		{
			NextReloadAttempt = WorldInfo.TimeSeconds + 1.0;
			W.StartFire(BOTFM_RELOAD);
		}
		return true;
	}

	if (!W.HasAnyAmmo())
	{
		SwitchToBestWeapon(true);
		Best = KFWeapon(Pawn.Weapon);
		if (Best != W)
		{
			bFallbackWeapon = true;
			bFallbackHadSpare = W.HasAnyAmmo();
			FallbackPrimary = W;
			FallbackSince = WorldInfo.TimeSeconds;
			return true;
		}
		if ((Pawn.Weapon == None) || (Pawn.Weapon.bMeleeWeapon == false))
		{
			SwitchToBestWeapon(true);
		}
		return true;
	}
	return false;
}

final function int CountNearbyZedsCached(float Radius)
{
	local int I, C;
	local float R2;

	R2 = Radius * Radius;
	C = 0;
	for(I = 0; I < int(SquadZedCount); I++)
	{
		if((SquadZedCache[I] != None) && (SquadZedCache[I].Health > 0)
			&& (VSizeSq(SquadZedCache[I].Location - Pawn.Location) < R2))
		{
			++C;
		}
	}
	return C;
}

final function RefreshSquadZedCache()
{
	local KFPawn_Monster P;

	SquadZedCount = 0;
	if (Pawn == None)
	{
		return;
	}

	foreach WorldInfo.AllPawns(class'KFPawn_Monster', P, Pawn.Location, 300.0)
	{
		if (P == None)
		{
			continue;
		}
		if (P.Health > 0)
		{
			if (SquadZedCount < 16)
			{
				SquadZedCache[SquadZedCount] = P;
				++SquadZedCount;
			}
		}
	}
}

// The priority hub chose Priority and is sending the bot to NextState (or to a follow/move, with
// NextState naming it). Closes the previous pick if it never reached a state exit.
function HubPick(string Priority, name NextState)
{
	if (WorldInfo == None)
	{
		return;
	}
	if (HubPriority != "")
	{
		HubResolve('Superseded');
	}
	HubPriority = Priority;
	HubNextState = NextState;
	HubPickTime = WorldInfo.TimeSeconds;
	HubFailReason = "";
	EchelonLog("HUB_PICK p=" $ Priority $ " next=" $ NextState);
}

// Marks the current hub step as failed; the first reason wins.
function HubFail(string Reason)
{
	if (HubPriority != "" && HubFailReason == "")
	{
		HubFailReason = Reason;
	}
}

function HubResolve(name ExitTo)
{
	local string Result;

	if (HubPriority == "" || WorldInfo == None)
	{
		return;
	}
	Result = "ok";
	if (HubFailReason != "")
	{
		Result = "fail:" $ HubFailReason;
	}
	EchelonLog("HUB_RESULT p=" $ HubPriority $ " state=" $ HubNextState $ " exit=" $ ExitTo
		$ " dwell=" $ string(WorldInfo.TimeSeconds - HubPickTime) $ " result=" $ Result);
	HubPriority = "";
	HubFailReason = "";
}

// Trader is open with more than TRADER_REFORM_REMAINING seconds left: squads break formation and
// bots shop and roam freely; they regroup in the last seconds (playtest request, 2026-10-19).
final function bool IsTraderFreeTime()
{
	return (KFGRI != None && KFGRI.bTraderIsOpen && KFGRI.GetTraderTimeRemaining() > TRADER_REFORM_REMAINING);
}

// Overridden in EcholonBotLogic (retreat that shoots); the base class only needs the name for SprintTick.
function RetreatFireTick()
{
}

// Single owner of the sprint flag (replaces the per-state SetSprinting calls). Named timer, 0.25 s.
// Edge-triggered: SetSprinting plays panting dialog and lowers the weapon, so call it only on a change.
function SprintTick()
{
    local bool bWant;

    if (Pawn == None || KPawn == None || KPawn.Health <= 0)
        return;
    bWant = WantsSprint();
    if (bWant != KPawn.bIsSprinting)
        KPawn.SetSprinting(bWant);
    if (CurrentOrder == 'CMD_TacticalRetreat' && !IsInState('TacticalRetreat'))
        RetreatFireTick();
}

// Whether the bot should sprint right now; see SprintTick. Retreat and shopping always sprint, free trader
// time sprints everyone, otherwise no sprint with a visible enemy within 1500 units.
final function bool WantsSprint()
{
    local name S;
    local vector V;
    local float LeaderDistSq;

    if (KPawn.bIsCrouched || !KPawn.bAllowSprinting || KPawn.IsFiring() || IsReloading())
        return false;
    V = KPawn.Velocity;
    V.Z = 0.0;
    if (VSizeSq(V) < SPRINT_MIN_SPEED_SQ)
        return false;

    S = GetStateName();
    if (S == 'GoShopping')
        return true;
    if (S == 'TacticalRetreat' || CurrentOrder == 'CMD_TacticalRetreat')
        return bRetreatSprint;
    if (IsTraderFreeTime() && (S == 'Roaming' || S == 'DoObjective' || S == 'FollowingLeader'
        || S == 'FollowingLeaderBasic' || S == 'PickNextMove'))
    {
        return true;
    }
    if (Enemy != None && Enemy.IsAliveAndWell() && VSizeSq(Enemy.Location - Pawn.Location) < SPRINT_ENEMY_RADIUS_SQ
        && LineOfSightTo(Enemy))
    {
        return false;
    }
    if (S == 'Hunting' || S == 'GetItem')
        return true;
    if (S == 'Roaming' || S == 'DoObjective')
        return !bIsGroupLeader;
    if (S == 'FollowingLeader' || S == 'FollowingLeaderBasic')
    {
        if (FollowLeaderPawn == None)
            return false;
        LeaderDistSq = VSizeSq(FollowLeaderPawn.Location - Pawn.Location);
        if (KPawn.bIsSprinting)
            return LeaderDistSq > SPRINT_CATCHUP_STOP_SQ;
        return LeaderDistSq > SPRINT_CATCHUP_START_SQ;
    }
    if (S == 'PickNextMove')
        return KPawn.bIsSprinting;
    return false;
}

final function ApplyCrouch(bool bWant)
{
    if (bWant && (mut == None || !mut.bAllowBotCrouch))
    {
        bWant = false;
    }
    if (Pawn != None && Pawn.bWantsToCrouch != bWant)
    {
        Pawn.ShouldCrouch(bWant);
    }
}

final function bool IsHostileZed(Pawn P)
{
    local KFPawn_Monster M;

    M = KFPawn_Monster(P);
    return (M != None && M.IsAliveAndWell());
}

function ToggleOverwatchPhase()
{
    if (BotRank != SQUAD_LEADER || Pawn == None)
    {
        ClearTimer('ToggleOverwatchPhase');
        return;
    }
    bOverwatchPhase = !bOverwatchPhase;
    if (bOverwatchAllMove && WorldInfo.TimeSeconds >= OverwatchResetUntil)
    {
        bOverwatchAllMove = false;
    }
    BroadcastOverwatchState();
}

function BroadcastOverwatchState()
{
    local int i;
    for (i = 0; i < 4; i++)
    {
        if (SquadMembers[i] != None && SquadMembers[i].Pawn != None)
        {
            SquadMembers[i].ReceiveOverwatchState(bOverwatchPhase, byte(i), bOverwatchAllMove);
        }
    }
}

function AssignSquadSlots()
{
    local int i;

    for (i = 0; i < 4; i++)
    {
        if (SquadMembers[i] != None)
        {
            SquadMembers[i].OverwatchSlot = byte(i);
        }
    }
}

function UpdateOverwatchTimer()
{
    local int i;
    local bool bMoveOrder;

    bMoveOrder = (CurrentOrder == 'CMD_PushAnchor' || CurrentOrder == 'CMD_TacticalRetreat');
    if (bMoveOrder)
    {
        if (!IsTimerActive('ToggleOverwatchPhase'))
        {
            bOverwatchAllMove = false;
            StuckCounter = 0;
            BroadcastOverwatchState();
            SetTimer(OW_TOGGLE_INTERVAL, true, 'ToggleOverwatchPhase');
        }
    }
    else
    {
        AssignSquadSlots();
        if (IsTimerActive('ToggleOverwatchPhase'))
        {
            ClearTimer('ToggleOverwatchPhase');
            bOverwatchAllMove = false;
            StuckCounter = 0;
            for (i = 0; i < 4; i++)
            {
                if (SquadMembers[i] != None)
                {
                    SquadMembers[i].bOverwatchMoving = false;
                    SquadMembers[i].OverwatchStuckTime = 0.0;
                }
            }
        }
    }
}

function CheckOverwatchStall()
{
    local int i, stuckCount;
    local EcholonBot G;
    local vector newAnchor;

    stuckCount = 0;

    if (!IsTimerActive('ToggleOverwatchPhase') || bOverwatchAllMove)
    {
        StuckCounter = 0;
        return;
    }

    for (i = 0; i < 4; i++)
    {
        G = SquadMembers[i];
        if (G != None && G.Pawn != None && G.GetStateName() != 'BreakLose' && G.IsOverwatchStuck())
        {
            stuckCount++;
        }
    }

    if (stuckCount < 2)
    {
        StuckCounter = 0;
        return;
    }

    StuckCounter++;
    if (int(StuckCounter) < 2)
    {
        return;
    }

    StuckCounter = 0;
    bOverwatchAllMove = true;
    OverwatchResetUntil = WorldInfo.TimeSeconds + OW_TOGGLE_INTERVAL;
    BroadcastOverwatchState();

    newAnchor = OrderAnchor + (VRand() * 150.0);
    newAnchor.Z = OrderAnchor.Z;
    IssueCommand(CurrentOrder, newAnchor);
}

function ReceiveOverwatchState(bool bPhase, byte InSlot, bool bAllMove)
{
    if (Pawn == None)
        return;
    GruntOverwatchPhase = bPhase;
    OverwatchSlot = InSlot;
    bOverwatchAllMove = bAllMove;
    OverwatchOffset = ComputeSlotOffset(InSlot);
}

final function bool IsOverwatchStuck()
{
    return (bOverwatchMoving && OverwatchStuckTime >= OW_STUCK_TIME);
}

function bool UpdateOverwatchMovement(out vector OutMovePos)
{
    local bool bMovingTeam;
    local float now;
    local vector moved, toGoal;
    local Pawn tgt;

    if (SquadLeader == None || SquadLeader.Pawn == None)
    {
        bOverwatchMoving = false;
        return true;
    }

    now = WorldInfo.TimeSeconds;

    if (bOverwatchAllMove)
    {
        bMovingTeam = true;
    }
    else if ((OverwatchSlot & 1) == 1)
    {
        bMovingTeam = GruntOverwatchPhase;
    }
    else
    {
        bMovingTeam = !GruntOverwatchPhase;
    }
    bOverwatchMoving = bMovingTeam;

    if (bMovingTeam)
    {
        ApplyCrouch(false);
        OutMovePos = SquadLeader.Pawn.Location + OverwatchOffset;

        if (now - OverwatchSampleTime >= 0.5)
        {
            moved = Pawn.Location - OverwatchSamplePos;
            moved.Z = 0.0;
            toGoal = OutMovePos - Pawn.Location;
            toGoal.Z = 0.0;
            if (VSizeSq(toGoal) > OW_STUCK_MIN_DIST_SQ && VSizeSq(moved) < OW_STUCK_MOVE_SQ)
            {
                OverwatchStuckTime += (now - OverwatchSampleTime);
            }
            else
            {
                OverwatchStuckTime = 0.0;
            }
            OverwatchSamplePos = Pawn.Location;
            OverwatchSampleTime = now;
        }
        return true;
    }

    OverwatchStuckTime = 0.0;
    OverwatchSampleTime = now;
    OverwatchSamplePos = Pawn.Location;
    ApplyCrouch(true);

    if (GetStateName() != 'FightEnemy')
    {
        tgt = Enemy;
        if (tgt == None)
        {
            tgt = SquadLeader.Enemy;
        }
        if (tgt != None && tgt.IsAliveAndWell())
        {
            if (now >= NextOverwatchLOSTime)
            {
                NextOverwatchLOSTime = now + 0.5;
                bOverwatchLOS = FastTrace(tgt.Location, Pawn.Location);
            }
            if (bOverwatchLOS)
            {
                FireWeaponAt(tgt);
            }
        }
    }
    return false;
}

function OnBreakLoseComplete()
{
    if (SquadLeader != None && SquadLeader.Pawn != None)
    {
        ReceiveOverwatchState(SquadLeader.bOverwatchPhase, OverwatchSlot, SquadLeader.bOverwatchAllMove);
    }
    OverwatchStuckTime = 0.0;
    OverwatchSampleTime = WorldInfo.TimeSeconds;
    RescueUntil = 0.0;
}

function UpdateSectorWatch()
{
    local float now, dt;
    local int baseYaw, scanOffset;
    local Rotator R;

    if (Pawn == None)
        return;

    now = WorldInfo.TimeSeconds;

    ApplyCrouch(true);

    if ((Enemy != None && Enemy.IsAliveAndWell()) || now < NoiseGlanceUntil)
    {
        SectorLastTime = now;
        return;
    }

    if (SquadLeader != None && SquadLeader.Pawn != None && SquadLeader.Pawn.IsAliveAndWell())
    {
        LastValidSquadLeaderYaw = SquadLeader.Pawn.Rotation.Yaw;
    }
    else if (LastValidSquadLeaderYaw == 0)
    {
        LastValidSquadLeaderYaw = Pawn.Rotation.Yaw;
    }

    dt = now - SectorLastTime;
    SectorLastTime = now;
    if (dt > 0.5)
        dt = 0.2;

    SectorScanPhase += dt * SW_SCAN_OMEGA * PanicScanSpeedMultiplier;
    if (SectorScanPhase > SW_TWO_PI)
        SectorScanPhase -= SW_TWO_PI;

    baseYaw = LastValidSquadLeaderYaw + (OverwatchSlot * 16384);
    scanOffset = int(SW_SCAN_AMP_DEG * PanicScanSpeedMultiplier * Sin(SectorScanPhase + (float(OverwatchSlot) * 0.7853982)) * SW_DEG_TO_URU);

    R.Pitch = 0;
    R.Roll = 0;
    R.Yaw = (baseYaw + scanOffset) & 65535;

    SetFocalPoint(Pawn.Location + (vector(R) * 512.0));
}

function HandleCQBProximity()
{
    local float distSq, now;
    local KFWeapon W;
    local KFPawn_Human KFPH;
    local vector awayDir;
    local bool bWantLight;

    if (Pawn == None || Enemy == None || Enemy.Health <= 0 || CurrentFormation != 'SingleFile')
    {
        return;
    }

    now = WorldInfo.TimeSeconds;
    KFPH = KFPawn_Human(Pawn);
    distSq = VSizeSq(Enemy.Location - Pawn.Location);

    if (distSq < CQB_BASH_SQ)
    {
        if (now >= NextBashTime)
        {
            NextBashTime = now + CQB_BASH_INTERVAL;

            W = KFWeapon(Pawn.Weapon);
            if (W != None)
            {
                if (W.bMeleeWeapon)
                {
                    W.StartFire(0);
                }
                else
                {
                    W.StartFire(3);
                }
            }

            if (Pawn.Physics == PHYS_Walking)
            {
                awayDir = Pawn.Location - Enemy.Location;
                awayDir.Z = 0.0;
                Pawn.Velocity = Normal(awayDir) * CQB_STEPBACK_SPEED;
            }

            if (KFPH != None)
            {
                KFPH.SetFlashlight(!KFPH.bFlashlightOn, false);
            }
        }
    }
    else if (KFPH != None)
    {
        bWantLight = (distSq >= CQB_MID_SQ);
        if (KFPH.bFlashlightOn != bWantLight)
        {
            KFPH.SetFlashlight(bWantLight, false);
        }
    }
}

function OnGruntGrabbed(EcholonBot GruntBot)
{
    local int i;
    local EcholonBot M, N1, N2;
    local float d, D1, D2;
    local vector grabLoc;
    local Pawn grabber;
    local KFPawn KFP;

    if (GruntBot == None || GruntBot.Pawn == None)
        return;

    grabLoc = GruntBot.Pawn.Location;
    KFP = KFPawn(GruntBot.Pawn);
    if (KFP != None)
        grabber = KFP.InteractionPawn;

    D1 = RESCUE_RANGE_SQ;
    D2 = RESCUE_RANGE_SQ;
    N1 = None;
    N2 = None;

    for (i = 0; i < 4; i++)
    {
        M = SquadMembers[i];
        if (M == None || M == GruntBot || M.Pawn == None || M.GetStateName() == 'BreakLose' || !M.Pawn.IsAliveAndWell())
            continue;
        d = VSizeSq(M.Pawn.Location - grabLoc);
        if (d < D1)
        {
            D2 = D1;
            N2 = N1;
            D1 = d;
            N1 = M;
        }
        else if (d < D2)
        {
            D2 = d;
            N2 = M;
        }
    }

    if (N1 != None)
        N1.BeginRescue(grabLoc, grabber);
    if (N2 != None)
        N2.BeginRescue(grabLoc, grabber);
}

function BeginRescue(vector GrabLoc, Pawn Grabber)
{
    if (Pawn == None || IsGruntCombatLocked())
        return;

    RescueLoc = GrabLoc;
    RescueUntil = WorldInfo.TimeSeconds + RESCUE_DURATION;
    IssueCommand('CMD_FocusTarget', GrabLoc);

    if (IsHostileZed(Grabber))
    {
        SetEnemy(Grabber);
        GruntEnterCombat(Grabber);
    }
}

function UpdateCoverCrouch()
{
    local bool bWantCrouch;

    if (WorldInfo.TimeSeconds < StyleCrouchUntil)
        return;

    bWantCrouch = false;
    if (SquadLeader != None && CurrentFormation == 'SingleFile' && SquadLeader.Enemy != None)
    {
        if (SquadLeader.Enemy.IsAliveAndWell()
            && VSizeSq(SquadLeader.Enemy.Location - Pawn.Location) < COVER_RANGE_SQ)
        {
            bWantCrouch = true;
        }
    }
    ApplyCrouch(bWantCrouch);
}

final function bool IsGruntCombatLocked()
{
    return (GetStateName() == 'BreakLose' || GetStateName() == 'HealingSelf' || GetStateName() == 'HealOther'
        || GetStateName() == 'HealRanged' || GetStateName() == 'TacticalRetreat' || GetStateName() == 'IsRagdolled'
        || GetStateName() == 'Dead' || GetStateName() == 'VictoryDance');
}

function GruntOnSight(Pawn Seen)
{
    if (Pawn == None || !IsHostileZed(Seen))
        return;

    if (GetStateName() == 'FightEnemy')
    {
        if (Enemy == None || !Enemy.IsAliveAndWell())
            SetEnemy(Seen);
        return;
    }
    GruntEnterCombat(Seen);
}

function GruntEnterCombat(Pawn NewEnemy)
{
    if (Pawn == None || NewEnemy == None || IsGruntCombatLocked())
        return;

    if (Enemy != NewEnemy && (Enemy == None || !Enemy.IsAliveAndWell()))
    {
        SetEnemy(NewEnemy);
    }
    if (Enemy == None)
        return;

    bGruntMeleeStyle = IsMeleeOnly();
    GotoState('FightEnemy');
}

function GruntPickCombatStyle()
{
    local vector toEnemy, strafeDir;

    if (Pawn == None || Enemy == None)
        return;

    if (bGruntMeleeStyle)
    {
        ApplyCrouch(false);
        MoveTowardX(Enemy, None, true, 'Grunt1');
        return;
    }

    if (FRand() < 0.5)
    {
        ApplyCrouch(false);
        toEnemy = Enemy.Location - Pawn.Location;
        toEnemy.Z = 0.0;
        strafeDir = Normal(toEnemy Cross vect(0,0,1));
        if (FRand() < 0.5)
            strafeDir = -strafeDir;
        MoveToX(Pawn.Location + (strafeDir * 150.0), None, true, 'Grunt2');
    }
    else
    {
        StyleCrouchUntil = WorldInfo.TimeSeconds + 1.0 + FRand();
        ApplyCrouch(true);
    }
}

event HearNoise(float Loudness, Actor NoiseMaker, optional Name NoiseType)
{
    local Pawn NoisePawn;

    if (BotRank != GRUNT || Pawn == None || NoiseMaker == None)
    {
        if (NoiseMaker != None && NoiseMaker.Instigator != None)
        {
            SetEnemy(NoiseMaker.Instigator);
        }
        Super.HearNoise(Loudness, NoiseMaker, NoiseType);
        return;
    }

    if (Loudness <= 0.5 || VSizeSq(NoiseMaker.Location - Pawn.Location) >= HEAR_RANGE_SQ)
    {
        return;
    }
    if (Enemy != None && Enemy.IsAliveAndWell())
    {
        return;
    }

    NoisePawn = Pawn(NoiseMaker);
    if (NoisePawn == None)
    {
        NoisePawn = NoiseMaker.Instigator;
    }

    if (IsHostileZed(NoisePawn))
    {
        GruntOnSight(NoisePawn);
    }
    else
    {
        NoiseGlanceUntil = WorldInfo.TimeSeconds + 1.5;
        SetFocalPoint(NoiseMaker.Location);
    }
}

final function bool IsHeavyZedPawn(Pawn P)
{
    local KFPawn_Monster M;

    M = KFPawn_Monster(P);
    return (M != None && M.bLargeZed);
}

function UpdatePanicBroadcast()
{
    local int i;
    local bool bWantPanic;

    bWantPanic = (Enemy != None && Enemy.IsAliveAndWell() && IsHeavyZedPawn(Enemy)
               && VSizeSq(Enemy.Location - Pawn.Location) < 90000.0);

    for (i = 0; i < 4; i++)
    {
        if (SquadMembers[i] != None)
        {
            SquadMembers[i].ReceivePanic(bWantPanic);
        }
    }
}

function ReceivePanic(bool bPanic)
{
	if (PanicActive == bPanic)
		return;
	PanicActive = bPanic;
	ApplyPanicVariance();
}

function ApplyPanicVariance()
{
    local float wantMult;

    if (PanicActive)
        wantMult = 2.0;
    else
        wantMult = 1.0;

    PanicScanSpeedMultiplier = wantMult;

    if (PanicVarianceMultiplier != wantMult)
    {
        PanicVarianceMultiplier = wantMult;
    }
}

final function bool IsReloading()
{
    local KFWeapon W;

    if (Pawn == None)
        return false;

    W = KFWeapon(Pawn.Weapon);
    return (W != None && W.IsInState('Reloading'));
}

function HandleReloadDrift()
{
    local int i, reloadingCount;
    local float now;
    local vector dir;
    local EcholonBot Grunt;

    if (Pawn == None)
        return;
    if (CurrentOrder == 'CMD_PushAnchor' || CurrentOrder == 'CMD_TacticalRetreat')
        return;

    now = WorldInfo.TimeSeconds;

    for (i = 0; i < 4; i++)
    {
        Grunt = SquadMembers[i];
        if (Grunt != None && Grunt.Pawn != None && Grunt.IsReloading())
        {
            reloadingCount++;
        }
    }
    if (reloadingCount < 2)
        return;

    if (now - ReloadPullStamp > 0.75)
    {
        if (Enemy != None)
            dir = Enemy.Location - Pawn.Location;
        else
            dir = vector(Pawn.Rotation);
        dir.Z = 0.0;
        if (VSizeSq(dir) < 1.0)
            dir = vect(1, 0, 0);
        dir = Normal(dir);

        ReloadPullAnchor = Pawn.Location - (dir * RELOAD_DRIFT_DIST);
        bReloadPullClear = FastTrace(ReloadPullAnchor, Pawn.Location);

        if (bReloadPullClear)
        {
            HoldAreaAnchor = ReloadPullAnchor;
            IssueCommand('CMD_HoldArea', ReloadPullAnchor);
        }
    }
    ReloadPullStamp = now;

    for (i = 0; i < 4; i++)
    {
        if (SquadMembers[i] != None && SquadMembers[i].Pawn != None)
        {
            SquadMembers[i].ReceiveReloadDrift(ReloadPullAnchor, bReloadPullClear, RELOAD_DRIFT_LEASE);
        }
    }
}

function ReceiveReloadDrift(vector Anchor, bool bMove, float Lease)
{
    local float now;
    local bool bNewEpisode;

    now = WorldInfo.TimeSeconds;
    bNewEpisode = (ReloadDriftUntil <= now);
    ReloadDriftUntil = now + Lease;
    bReloadDriftMove = bMove;

    if (bMove)
    {
        if (bNewEpisode)
        {
            ReloadDriftOffset = ComputeFormationOffset(SquadLeader, false);
        }
        OnReloadDriftAnchor(Anchor);
    }
    else
    {
        ApplyCrouch(true);
    }
}

function OnReloadDriftAnchor(vector Anchor)
{
    ReloadDriftLoc = Anchor + ReloadDriftOffset;
    ApplyCrouch(true);
    MoveToX(ReloadDriftLoc);
}

function OnReloadComplete()
{
	ReloadDriftUntil = 0.0;
	ApplyCrouch(false);
}

function TrackReloadState()
{
    local bool bNow;

    bNow = IsReloading();
    if (bWasReloading && !bNow)
    {
        OnReloadComplete();
    }
    bWasReloading = bNow;
}

function StartLtHumanBounding()
{
    SetTimer(FRand() * HUMAN_BOUND_INTERVAL, false, 'BeginLtHumanBounding');
}

function BeginLtHumanBounding()
{
    if (BotRank == LIEUTENANT)
    {
        SetTimer(HUMAN_BOUND_INTERVAL, true, 'LtHumanBoundLoop');
    }
}

function LtHumanBoundLoop()
{
    local int hIdx, s;
    local float now, pushDot, d, d1, d2;
    local vector objLoc, objDir, hVel, hLoc, ltAnchor, wedgeCenter;
    local KFPawn_Human Human;
    local EcholonBot SL, N1, N2;

    if (BotRank != LIEUTENANT || Pawn == None || mut == None)
    {
        ClearTimer('LtHumanBoundLoop');
        return;
    }
    if (mut.CachedHumans.Length == 0 || SquadLeaders.Length == 0)
    {
        return;
    }

    now = WorldInfo.TimeSeconds;

    ltAnchor = OrderAnchor;
    if (ltAnchor == vect(0,0,0))
    {
        ltAnchor = Pawn.Location;
    }

    if (mut.bObjectiveActive)
    {
        objLoc = mut.GetObjectiveLocation();
    }
    else
    {
        objLoc = ltAnchor;
    }

    for (hIdx = 0; hIdx < mut.CachedHumans.Length; hIdx++)
    {
        Human = mut.CachedHumans[hIdx].HumanPawn;
        if (Human == None || !Human.IsAliveAndWell())
        {
            continue;
        }

        hVel = mut.CachedHumans[hIdx].Vel;
        hVel.Z = 0.0;
        if (VSizeSq(hVel) < HUMAN_MIN_SPEED_SQ)
        {
            continue;
        }

        hLoc = mut.CachedHumans[hIdx].Loc;
        if (VSizeSq(hLoc - ltAnchor) >= HUMAN_LT_RANGE_SQ)
        {
            continue;
        }

        objDir = objLoc - hLoc;
        objDir.Z = 0.0;
        if (VSizeSq(objDir) < 1.0)
        {
            continue;
        }
        objDir = Normal(objDir);

        pushDot = objDir dot Normal(hVel);
        if (pushDot <= HUMAN_PUSH_DOT)
        {
            continue;
        }

        d1 = 99999999.0;
        d2 = 99999999.0;
        N1 = None;
        N2 = None;
        for (s = 0; s < SquadLeaders.Length; s++)
        {
            SL = SquadLeaders[s];
            if (SL == None || SL.Pawn == None || !SL.Pawn.IsAliveAndWell())
            {
                continue;
            }
            if (SL.CurrentOrder == 'CMD_TacticalRetreat')
            {
                continue;
            }
            if (SL.WedgeExpireTime > now + HUMAN_BOUND_INTERVAL)
            {
                continue;
            }

            d = VSizeSq(SL.Pawn.Location - hLoc);
            if (d < d1)
            {
                d2 = d1;
                N2 = N1;
                d1 = d;
                N1 = SL;
            }
            else if (d < d2)
            {
                d2 = d;
                N2 = SL;
            }
        }

        wedgeCenter = hLoc - (objDir * WEDGE_REAR_OFFSET);
        wedgeCenter.Z = hLoc.Z;

        if (N1 != None)
        {
            N1.ReceiveWedgeOrder(Human, wedgeCenter, now + WEDGE_LEASE);
        }
        if (N2 != None)
        {
            N2.ReceiveWedgeOrder(Human, wedgeCenter, now + WEDGE_LEASE);
        }
    }
}

function ReceiveWedgeOrder(KFPawn_Human Human, vector WedgeCenter, float ExpireTime)
{
    local int i;

    bWedgeActive = true;
    WedgeHuman = Human;
    WedgeExpireTime = ExpireTime;
    CurrentFormation = 'WedgeBehindHuman';

    for (i = 0; i < 4; i++)
    {
        if (SquadMembers[i] != None)
        {
            SquadMembers[i].CurrentFormation = 'WedgeBehindHuman';
        }
    }

    IssueCommand('CMD_PushAnchor', WedgeCenter);
}

function UpdateWedgeMode()
{
    if (!bWedgeActive)
        return;
    if (WorldInfo.TimeSeconds > WedgeExpireTime || WedgeHuman == None || !WedgeHuman.IsAliveAndWell())
    {
        ClearWedge();
    }
}

function ClearWedge()
{
    local int i;

    bWedgeActive = false;
    WedgeHuman = None;
    WedgeExpireTime = 0.0;
    CurrentFormation = 'StaggeredColumn';
    for (i = 0; i < 4; i++)
    {
        if (SquadMembers[i] != None)
        {
            SquadMembers[i].CurrentFormation = 'StaggeredColumn';
        }
    }
}

function vector ComputeWedgeOffset(int Slot, KFPawn_Human PlayerRef)
{
    local rotator R;
    local vector AxX, AxY, AxZ, dir;
    local float ang, dist;
    local int sl;

    sl = Clamp(Slot, 0, 3);
    switch (sl)
    {
        case 0:
            ang = -60.0;
            break;
        case 1:
            ang = -30.0;
            break;
        case 2:
            ang = 30.0;
            break;
        default:
            ang = 60.0;
            break;
    }
    ang = ang * DEG_TO_RAD;
    dist = 150.0 + (50.0 * float(sl));

    R = rot(0, 0, 0);
    R.Yaw = PlayerRef.Rotation.Yaw;
    GetAxes(R, AxX, AxY, AxZ);

    dir = ((-AxX) * Cos(ang)) + (AxY * Sin(ang));
    return dir * dist;
}

function ApplyWedgeTarget(out vector OutTarget)
{
    local KFPawn_Human Human;

    if (SquadLeader == None || !SquadLeader.bWedgeActive)
        return;
    Human = SquadLeader.WedgeHuman;
    if (Human == None || !Human.IsAliveAndWell())
        return;

    OutTarget = Human.Location + ComputeWedgeOffset(OverwatchSlot, Human);
}

function StartEmoteEchoTimer()
{
    SetTimer(FRand(), false, 'BeginEmoteEcho');
}

function BeginEmoteEcho()
{
    SetTimer(1.0, true, 'CheckEmoteEcho');
}

function CheckEmoteEcho()
{
    local int i;
    local float now;
    local KFPawn_Human H;
    local KFGameReplicationInfo GRI;

    if (Pawn == None || bPlayingEmote || mut == None)
        return;

    GRI = mut.KF.MyKFGRI;
    if (GRI == None || !(GRI.bTraderIsOpen || GRI.WaveNum == 0))
        return;

    now = WorldInfo.TimeSeconds;
    if (now < NextEmoteRollTime || Enemy != None)
        return;
    if (IsGruntCombatLocked() || IsInState('GoShopping') || IsInState('GetItem') || IsInState('DonatingMoney'))
        return;

    for (i = 0; i < mut.CachedHumans.Length; i++)
    {
        H = mut.CachedHumans[i].HumanPawn;
        if (H == None || !H.IsAliveAndWell())
            continue;
        if (VSizeSq(H.Location - Pawn.Location) >= EMOTE_RADIUS_SQ)
            continue;
        if (!H.IsDoingSpecialMove(SM_Emote))
            continue;

        NextEmoteRollTime = now + EMOTE_ROLL_COOLDOWN;
        if (FRand() < EMOTE_CHANCE)
        {
            Focus = None;
            SetFocalPoint(H.Location);
            PlayBotEmote();
        }
        break;
    }
}

final function PlayBotEmote()
{
    local KFPawn KFP;

    KFP = KFPawn(Pawn);
    if (KFP == None || bPlayingEmote)
        return;

    if (!KFP.CanDoSpecialMove(SM_Emote))
        return;

    bPlayingEmote = true;
    KFP.DoSpecialMove(SM_Emote, true, None, 0);
    SetTimer(4.0, false, 'ClearEmoteFlag');
}

function ClearEmoteFlag()
{
    bPlayingEmote = false;
}

final function float GetWaveMomentum()
{
    local KFGameReplicationInfo GRI;

    GRI = mut.KF.MyKFGRI;
    if (GRI == None)
        return 1.0;
    return Max(1.0, float(GRI.WaveNum) * 0.15 + 1.0);
}

final function bool ExceedsRetreatZedCount()
{
    if (Pawn == None)
        return false;
    return (CachedZedCount >= int(RETREAT_ZED_TRIGGER_COUNT / GetWaveMomentum()));
}

function ApplyBreathing(float t)
{
    BreathingPhase += BREATH_OMEGA * t;
}

function UpdateHoldAreaDrift()
{
    local float now, drift;

    if (CurrentOrder != 'CMD_HoldArea')
        return;

    now = WorldInfo.TimeSeconds;
    if (now - LastDriftTime < 60.0)
        return;
    LastDriftTime = now;

    drift = DRIFT_RATE * 60.0;
    HoldDriftDist += drift;
    if (HoldDriftDist > DRIFT_MAX_TOTAL)
        HoldDriftDist = DRIFT_MAX_TOTAL;
}

defaultproperties
{
    RetreatMaxDist=750.0
    RetreatMinStay=1.5
    RetreatFireInterval=0.2
    CombatHubGap=0.5
    ZeroMoveMinDist=50.0
    BashMaxDistSq=5625.0
    BashInterval=1.5
    bNavTeleport=true
    NavTeleportAfter=5.0
    NavNextTeleportTry=0.0
    NavTeleportWaitLog=0.0
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
