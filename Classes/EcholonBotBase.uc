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

    KPawn = KFPawn_Human(Pawn);
    KPawn.NumJumpsAllowed = 2;

    if (Pawn.Physics == 0)
    {
        Pawn.SetPhysics(2);
    }

    SetTimer(0.2 + (FRand() * 0.1), true, 'CheckGrabbed');
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

function float GetEnemyThreat(Pawn Other)
{
    local float V;

    V = FMin(float(Other.Health), 600.0) + 100.0;
    if (V < 30.0)
    {
        V += 800.0;
    }
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

	if ((InheritedEnemy != None) && (inActor == InheritedEnemy) && !HasOwnFireLine(inActor))
	{
		Pawn.StopFiring();
		return false;
	}
	if (Pawn.IsFiring())
	{
		return true;
	}
	if ((inActor == None) || NeedToTurn(inActor.Location) || !Pawn.CanAttack(inActor))
	{
		return false;
	}
	Target = inActor;
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
		else if (VSizeSq(inActor.Location - Pawn.Location) < 40000.0)
		{
			W.StartFire(BOTFM_BASH);
		}
		else
		{
			if (!IsInEffectiveRange(inActor))
			{
				bOutOfEffectiveRange = true;
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

final function SimulateBashHit(KFPawn TargetZed, KFWeapon W)
{
    local float RngRoll;
    local int BashDamage;

    if (TargetZed == None || !TargetZed.IsAliveAndWell())
    {
        return;
    }

    if (W == MedicGun)
    {
        return;
    }

    RngRoll = FRand();
    if (RngRoll < 0.30)
    {
        BashDamage = 200;
    }
    else
    {
        BashDamage = 25;
    }

    TargetZed.TakeDamage(BashDamage, self, TargetZed.Location, vect(0.0, 0.0, 0.0), Class'Engine.DamageType');
}

// @STUB(M5b) @SYS-BASE-HEALQ legacy:KF2BotBase.EnemyChanged
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

function Rotator GetAdjustedAimFor(Weapon W, Vector StartFireLoc)
{
    local Vector TargetPos;

    if(Target == None)
    {
        Target = Enemy;
        if(Target == None)
        {
            return super(Controller).GetAdjustedAimFor(W, StartFireLoc);
        }
    }

    if((W != None) && (KFPawn(Target) != None))
    {
        TargetPos = KFPawn(Target).Mesh.GetBoneLocation(KFPawn(Target).HeadBoneName);
    }
    else
    {
        TargetPos = Target.Location;
    }

    return Rotator(TargetPos - StartFireLoc);
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

final function MoveToX(Vector Dest, optional Actor ViewFocus, optional bool bSerpent = true)
{
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

final function MoveTowardX(Actor Dest, optional Actor ViewFocus, optional bool bSerpent = true)
{
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
            Pawn.Acceleration = DestinationPosition.Position - Pawn.Location;
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
            Pawn.Acceleration = MoveTarget.Location - Pawn.Location;
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
            `log("[FollowNav] EcholonBot: FS_Arrived -- holding slot " $ string(FollowSlotIndex) $ "/" $ string(FollowSlotCount));
            break;

        case FS_LeaderTeleported:
            `log("[FollowNav] EcholonBot: FS_LeaderTeleported -- route invalid, decorrelated");
            break;

        case FS_LeaderLost:
        case FS_Blocked:
            `log("[FollowNav] EcholonBot: " $ string(int(NewStatus)) @ "-- returning to PickNextMove");
            FollowExitState = 'PickNextMove';
            bFollowExitPending = true;
            break;
    }
}

function FollowOnGaveUp()
{
    `log("[FollowNav] EcholonBot: follow retry ladder exhausted; hub will re-decide via PickNextMove");
}

function Tick(float Delta)
{
    local KFPawn_Monster MonCheck;

    if (Pawn == None)
    {
        return;
    }

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
            if (VSizeSq(PrevMovePos - Pawn.Location) < 2500.0 * Delta)
            {
                if (WorldInfo.TimeSeconds - MovePauseTime > 0.5)
                {
                    Pawn.DoJump(false);
                }
            }
            else
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

    MoveTarget = FindPathToward(Other);

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

    MoveTarget = FindPathTo(Dest);

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

    RandGoal = FindRandomDest();

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
                if (Rand(3) == 0)
                {
                    Pawn.DoJump(false);
                }
                else
                {
                    bAdjusting = true;
                    AdjustPosition.Position = (Pawn.Location + (HitNormal * 80.0)) + (VRand() * 50.0);
                }
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

function ValidateAndNudgeSpawn()
{
    local vector NudgeLoc;
    local int Attempts;

    if (Pawn == None)
        return;
    if (IsOnWalkableFloor())
        return;

    `log("[FollowNav] ValidateAndNudgeSpawn: spawn not on a floor, nudging");

    for (Attempts = 0; Attempts < 6; Attempts++)
    {
        NudgeLoc = Pawn.Location;
        NudgeLoc.X = NudgeLoc.X + (FRand() * 128.0 - 64.0);
        NudgeLoc.Y = NudgeLoc.Y + (FRand() * 128.0 - 64.0);
        SetLocation(NudgeLoc);
        if (IsOnWalkableFloor())
            return;
    }

    `log("[FollowNav] ValidateAndNudgeSpawn: nudged, still settling");
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
        mut.DebugMessage(GetHumanReadableName() $ " grapple failsafe triggered after " $ string(int(WorldInfo.TimeSeconds - GrabStartTime)) $ "s - forcing a break free.");
    }

    if (GrabbingZed != None)
    {
        GrabbingZed.TakeDamage(150, self, GrabbingZed.Location, vect(0, 0, 0), Class'Engine.DamageType');
        GrabbingZed.EndSpecialMove();
    }

    KPawn.EndSpecialMove();
    KPawn.InteractionPawn = None;
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
	if (WorldInfo == None)
	{
		return;
	}
	if (!AuditRateLimit(Msg))
	{
		return;
	}
	`log("[EcholonAudit] " $ Name $ " " $ Msg);
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

function IssueCommand(name Cmd, Vector Anchor)
{
    CurrentOrder = Cmd;
    OrderAnchor = Anchor;
    EchelonLog("IssueCommand: " $ Cmd);
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
    EchelonLog("LTDispatchLoop");
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

// @STUB(M5a) @SYS-BASE-CQB legacy:KF2BotBase.ApplyCrouch
final function ApplyCrouch(bool bWant)
{
}

final function bool IsHostileZed(Pawn P)
{
    local KFPawn_Monster M;

    M = KFPawn_Monster(P);
    return (M != None && M.IsAliveAndWell());
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
