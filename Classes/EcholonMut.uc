class EcholonMut extends KFMutator config(EcholonBot) hidecategories(Navigation, Movement, Collision);

// Constants: generated from contracts/constants.json (D2). Edit there, not here.
const CUR_CONFIGVER = 3;
const MIN_GROUPS = 2;
const MAX_GROUPS = 4;
const BOTS_PER_GROUP_TARGET = 3;
const VIP_ESCORT_MIN_SIZE = 2;
const GROUP_DISSOLVE_SIZE = 1;
const VANGUARD_OFFSET = 2000.0;
const REARGUARD_OFFSET = 2000.0;
const CHOKEPOINT_LATERAL_OFFSET = 1000.0;
const NAV_SEARCH_RADIUS = 1500.0;
const HUNT_ORDER_MAX_ZEDS = 15;
const HUNT_ORDER_MIN_DIST_SQ = 1440000.0;
const HUNT_ORDER_INTERVAL = 1.0;
const MACRO_WAYPOINT_INTERVAL = 3.0;
const OBJ_BAIL_COOLDOWN = 8.0;
const PHASE_IDLE = 0;
const PHASE_ENROUTE = 1;
const PHASE_HOLDING = 2;
const PHASE_REGROUP = 3;
const REGROUP_DURATION = 5.0;
const REGROUP_HARD_TIMEOUT = 6.0;
const REGROUP_SCAN_RADIUS = 5000.0;
const WAVE_POLL_INTERVAL = 1.0;
const RELOCATE_MAX_PER_CRATE = 3;
const RELOCATE_HUMAN_RADIUS_SQ = 90000.0;

struct FireteamData { var array<EcholonBot> Members; var EcholonBot Leader; var NavigationPoint Anchor; };

struct NavNodeBlock { var name Node; var EcholonBot Owner; var float ExpiresAt; };

struct SquadOrder { var int SquadID; var EcholonBot Leader; var KFMapObjective_DoshHold Zone; var vector GoalPoint; var NavigationPoint GoalNav; var array<int> Slots; var int Phase; var float StartTime; var float ObjectiveBailUntil; var array<NavNodeBlock> NodeBlacklist; var array<vector> SlotLocs; var float SquadSeedAngle; };

struct PromotionRequest { var EcholonBot DeadOfficer; var EcholonBot Replacement; var EBotRank OldRank; var float Score; };

struct CachedHumanInfo { var KFPawn_Human HumanPawn; var vector Loc; var vector Vel; };

var transient array<EcholonWeaponInfo> TraderList;
var config int ConfigVer;
var config string _Separator1;
var() config byte NumBots;
var() config byte MinimumBots;
var byte OldWaveNum;
var config string _Separator2;
var() config int BotMinPerkLv;
var() config int BotMaxPerkLv;
var config string _Separator3;
var() config float BotsDamageScale;
var() config float ZedCountScaling;
var EcholonChat ActiveChat;
var array<EcholonBot> ActiveBots;
var array<FireteamData> Fireteams;
var array<SquadOrder> SquadOrders;
var int NumGroups;
var Controller VIPController;
var Controller AlphaCommander;
var Pawn CachedBossPawn;
var int LastPolledWaveNum;
var bool bForceRelocate;
var bool bInitialRelocated;
var KFGameInfo_Survival KF;
var Actor PrevObjective;
var array<NavigationPoint> ValidPoints;
var KFMapObjective_DoshHold HoldVolume;
var int MaxEmoteCount;
var float NextVictoryDance;
var bool bNewWave;
var bool bObjectiveActive;
var bool bHuntOrderActive;
var float LastHuntOrderTime;
var transient bool bTraderListInit;
var array<PromotionRequest> PendingPromotions;
var array<CachedHumanInfo> CachedHumans;
var array<float> SquadIdleStamp;
var transient bool bChatterInit;
var config string _Separator4;
var() config bool bBotsUnlimitedAmmo;
var() config bool bBotsUnlimitedCash;
var config string _Separator5;
var() config bool bNoZerkerBots;
var() config bool bUseCustomBotNames;
var() config bool bShowBotLevel;
var() config bool bShowBotRole;
var() config array<string> CustomBotNames;
var() config array<string> AllowedPerks;
var() config int MaxBotsPerPerk;
var config string _Separator6;
var() config bool bDebugGrapple;
var() config int MaxZedsForFailsafe;
var() config float FailsafeActivationDelay;
var config string _Separator7;
var() config float HealCylinderRadius;
var() config float HealCylinderHeight;
var() config float HealMinHealthPct;
var() config bool bEnableFastTraceHealing;
// Set bDisableAuditLog=True in the mutator's ini section to silence every [EcholonAudit] log line.
// Off by default (logs on) so a missing ini key keeps the debug trail.
var() config bool bDisableAuditLog;
// Bots crouch (cover, squad holds, overwatch). Off unless set to True: crouching bots looked out
// of place in playtests (2026-10-19).
var() config bool bAllowBotCrouch;
// Count bots as voters in the skip-trader vote (stock behaviour). Off by default: only human
// players vote, and the vote passes when every human votes yes (EcholonVoteCollector).
var() config bool bBotsCountInSkipTraderVote;
// Bots get scoreboard pictures from the local avatar server (kit\Start-AvatarServer.bat). Off by default.
var() config bool bBotAvatars;
// Port of the local avatar server. 0 or less means 8765.
var() config int AvatarServerPort;
var transient int AvatarMatchId;
// AvatarDL, AvatarPRI and AvatarApplied are parallel arrays, one slot per requested bot picture.
var transient array<KFHTTPImageDownloader> AvatarDL;
var transient array<PlayerReplicationInfo> AvatarPRI;
var transient array<bool> AvatarApplied;
var array<KFPawn_Human> RangedHealTargets;
var array<float> RangedHealCooldownEnds;
var transient array<string> AvailableBotNames;
var transient array<Class<KFPerk> > PerkPool;
var transient array<int> PerkPoolCounts;
var float LastAuditLogTime;
// Playtest mode (?Playtest=1 on the map URL): the human leaves play and watches the bots.
// Spike for the automated playtest runner; see the playtest plan.
var transient bool bPlaytest;
var transient bool bPlaytestSpectating;
var transient float PlaytestNextCamTime;
var transient float PlaytestNextReportTime;
var transient name PlaytestCamMode;           // 'ThirdPerson' or 'FirstPerson', kept across bot switches
var transient int PlaytestLastZedCount;
var transient float PlaytestZedCountSince;    // when AIAliveCount last changed (stuck-wave check)
var transient int PlaytestWaves;             // wave cap for this match (0 = whole match)
var transient int PlaytestBotsOverride;      // bot count override for this match only
var transient int PlaytestWavesDone;         // waves ended so far
var transient float PlaytestWaveStart;       // TimeSeconds when the current wave began
var transient bool bPlaytestLastTrader;      // bTraderIsOpen at the previous tick (edge detection)
var transient float PlaytestZeroSince;          // when the last living bot was first seen dead (0 = bots alive)
var transient bool bPlaytestStarted;           // the match has begun at least once
var transient bool bPlaytestDone;            // PLAYTEST_DONE logged, the game is about to quit
var transient bool bPlaytestReadyLogged;     // PLAYTEST_READY logged once

function EchelonLog(string Msg)
{
    if (WorldInfo == None || bDisableAuditLog)
        return;
    if (Left(Msg, 6) ~= "ORDER_")
    {
        if (WorldInfo.TimeSeconds - LastAuditLogTime < 5.0)
            return;
        LastAuditLogTime = WorldInfo.TimeSeconds;
    }
    `log("[EcholonAudit] [Mut] " $ Msg);
}

function PostBeginPlay()
{
    local int J;

    if(WorldInfo.Game.BaseMutator == None)
    {
        WorldInfo.Game.BaseMutator = self;
    }
    else
    {
        WorldInfo.Game.BaseMutator.AddMutator(self);
    }

    if(bDeleteMe)
    {
        return;
    }

    KF = KFGameInfo_Survival(WorldInfo.Game);

    if(ConfigVer != CUR_CONFIGVER)
    {
        NumBots = 7;
        BotMaxPerkLv = 25;
        BotsDamageScale = 1.0;
        ZedCountScaling = 0.2;
        bNoZerkerBots = true;
        bUseCustomBotNames = true;
        bShowBotLevel = false;
        bShowBotRole = true;
        CustomBotNames.Length = 0;
        CustomBotNames.AddItem("Alex");
        CustomBotNames.AddItem("Reaper");
        CustomBotNames.AddItem("Ghost");
        CustomBotNames.AddItem("Widow");
        CustomBotNames.AddItem("Havoc");
        CustomBotNames.AddItem("Ranger");
        CustomBotNames.AddItem("Blaze");
        CustomBotNames.AddItem("Cipher");
        MaxBotsPerPerk = 2;
        AllowedPerks.Length = 0;
        J = 0;
        while(J < Class'KFGame.KFPlayerController'.default.PerkList.Length)
        {
            AllowedPerks.AddItem(string(Class'KFGame.KFPlayerController'.default.PerkList[J].PerkClass.Name));
            J++;
        }
        bDebugGrapple = false;
        MaxZedsForFailsafe = 3;
        FailsafeActivationDelay = 3.0;
        _Separator1 = "--- BOT COUNT & SPAWNING ---";
        _Separator2 = "--- PERK LEVEL RANGE ---";
        _Separator3 = "--- DIFFICULTY & BALANCE ---";
        _Separator4 = "--- CHEATS ---";
        _Separator5 = "--- BOT NAMING & PERK RESTRICTIONS ---";
        _Separator6 = "--- GRAPPLE ESCAPE SETTINGS ---";
        HealCylinderRadius = 400.0;
        HealCylinderHeight = 300.0;
        HealMinHealthPct = 60.0;
        bEnableFastTraceHealing = true;
        _Separator7 = "--- HEALING SETTINGS ---";
        ConfigVer = CUR_CONFIGVER;
        SaveConfig();
    }

    if(!bChatterInit)
    {
        bChatterInit = true;
        ActiveChat = Spawn(class'EcholonChat');
    }

    SetTimer(WAVE_POLL_INTERVAL, true, 'PollWaveStart');
    SetTimer(3.0, true, 'CacheHumans');
}

function AddMutator(Mutator M)
{
    if (M != self)
    {
        if (M.Class == class)
        {
            M.Destroy();
        }
        else
        {
            super(Mutator).AddMutator(M);
        }
    }
}

function MatchStarting()
{
    local byte I;

    if (WorldInfo.NetMode == NM_Standalone)
    {
        if (bBotAvatars)
        {
            AvatarMatchId = Rand(1000000000) + 1;
            EchelonLog("AVATAR_ON match=" $ string(AvatarMatchId) $ " port=" $ string(AvatarPort()));
        }
        for (I = 0; I < NumBots; ++I)
        {
            AddBot();
        }
        // Spread the squads over random ammo crates right away, in the same tick the bots are created
        // (see InitialRelocate).
        InitialRelocate();
    }
    else
    {
        SetTimer(1.0, true);
    }
    SetTimer(0.1, true, 'CheckWave');
    InstallVoteCollector();
}

function InitMutator(string Options, out string ErrorMessage)
{
    super.InitMutator(Options, ErrorMessage);

    bPlaytest = class'GameInfo'.static.ParseOption(Options, "Playtest") ~= "1";
    if (bPlaytest)
    {
        // Our controller makes left/right click and the camera-mode key work on bots (see EcholonSpectatorPC).
        WorldInfo.Game.PlayerControllerClass = class'EcholonSpectatorPC';
        PlaytestCamMode = 'ThirdPerson';
        PlaytestWaves = class'GameInfo'.static.GetIntOption(Options, "PlaytestWaves", 0);
        PlaytestBotsOverride = class'GameInfo'.static.GetIntOption(Options, "PlaytestBots", 0);
        if (PlaytestBotsOverride > 0)
            NumBots = byte(PlaytestBotsOverride);
        EchelonLog("PLAYTEST_START map=" $ WorldInfo.GetMapName(true) $ " waves=" $ string(PlaytestWaves) $ " bots=" $ string(NumBots));
        SetTimer(1.0, true, 'PlaytestTick');
    }
}

final function KFPlayerController GetPlaytestHuman()
{
    local KFPlayerController PC;

    foreach WorldInfo.AllControllers(class'KFPlayerController', PC)
    {
        if (PC.IsLocalPlayerController())
            return PC;
    }
    return None;
}

// Takes the human out of play: no pawn, spectator flags set, spectating state.
// Runs again if the game hands the human a new pawn (e.g. a respawn at trader time).
final function PlaytestMakeSpectator(KFPlayerController PC)
{
    local Pawn P;
    local int LivingBefore;

    LivingBefore = KF.GetLivingPlayerCount();
    P = PC.Pawn;
    if (P != None)
    {
        PC.UnPossess();
        P.Destroy();
    }

    PC.PlayerReplicationInfo.bOnlySpectator = true;
    PC.PlayerReplicationInfo.bIsSpectator = true;
    PC.PlayerReplicationInfo.bOutOfLives = true;
    PC.GotoState('Spectating');
    KF.ForceLivingPlayerCount(byte(KF.NumBots));

    EchelonLog("PLAYTEST_SPECTATE again=" $ string(bPlaytestSpectating) $ " living_before=" $ string(LivingBefore)
        $ " living_after=" $ string(KF.GetLivingPlayerCount()) $ " wave=" $ string(KF.MyKFGRI.WaveNum));
    bPlaytestSpectating = true;
    PlaytestNextCamTime = 0.0;
}

// Points the human's camera at the next (Dir 1) or previous (Dir -1) living bot, in PlaytestCamMode.
// Stock SpectateNextPlayer skips bots: KFGameInfo.CanSpectate only accepts PlayerController owners.
// A manual switch (a click) pauses the 30 s auto-rotation for 60 s.
final function PlaytestStepCamera(PlayerController PC, int Dir, optional bool bManual)
{
    local int I, Start, Count;
    local EcholonBot B;

    Count = ActiveBots.Length;
    if (Count == 0 || PC == None)
        return;

    Start = (Dir < 0) ? Count - 1 : 0;
    for (I = 0; I < Count; I++)
    {
        if (ActiveBots[I] != None && ActiveBots[I].Pawn != None && ActiveBots[I].Pawn == PC.ViewTarget)
        {
            Start = I + Dir;
            break;
        }
    }

    for (I = 0; I < Count; I++)
    {
        B = ActiveBots[(((Start + I * Dir) % Count) + Count) % Count];
        if (B != None && B.Pawn != None && B.Pawn.IsAliveAndWell())
        {
            PC.SetViewTarget(B.Pawn);
            PC.SetCameraMode(PlaytestCamMode);
            PlaytestNextCamTime = WorldInfo.TimeSeconds + (bManual ? 60.0 : 30.0);
            EchelonLog("PLAYTEST_CAMERA target=" $ B.LogTag() $ " mode=" $ string(PlaytestCamMode) $ " manual=" $ string(bManual));
            return;
        }
    }
}

// Camera-mode key: first person <-> third person on the bot being watched.
final function PlaytestToggleCamMode(PlayerController PC)
{
    if (PC == None)
        return;
    PlaytestCamMode = (PlaytestCamMode == 'FirstPerson') ? 'ThirdPerson' : 'FirstPerson';
    PC.SetCameraMode(PlaytestCamMode);
    PlaytestNextCamTime = WorldInfo.TimeSeconds + 60.0;
    EchelonLog("PLAYTEST_CAMERA_MODE mode=" $ string(PlaytestCamMode));
}

// Stand-in VIP while no human is alive: the current anchor while it is a living squad leader,
// else the first living squad leader by group. It stays a squad leader (no CAPTAIN, no demotion).
final function EcholonBot PickLeaderAnchor()
{
    local EcholonBot Cur;
    local int GroupIdx;

    Cur = EcholonBot(VIPController);
    if (Cur != None && !Cur.bDeleteMe && Cur.bIsGroupLeader && Cur.Pawn != None && Cur.Pawn.Health > 0)
        return Cur;

    for (GroupIdx = 0; GroupIdx < Fireteams.Length; GroupIdx++)
    {
        Cur = Fireteams[GroupIdx].Leader;
        if (Cur != None && !Cur.bDeleteMe && Cur.Pawn != None && Cur.Pawn.Health > 0)
            return Cur;
    }
    return None;
}

// Last zeds that stop dying (stuck behind geometry, etc.): after 180 s with 3 or fewer left and no
// change in the count, log where they are and kill them so the run goes on.
final function PlaytestCheckStuckWave()
{
    local KFPawn_Monster M;
    local string Where;
    local int N;

    if (KF.AIAliveCount != PlaytestLastZedCount || KF.MyKFGRI.bTraderIsOpen || !KF.IsWaveActive())
    {
        PlaytestLastZedCount = KF.AIAliveCount;
        PlaytestZedCountSince = WorldInfo.TimeSeconds;
        return;
    }
    if (KF.AIAliveCount <= 0 || KF.AIAliveCount > 3 || !KF.SpawnManager.IsFinishedSpawning()
        || WorldInfo.TimeSeconds - PlaytestZedCountSince < 180.0)
        return;

    N = 0;
    foreach WorldInfo.AllPawns(class'KFPawn_Monster', M)
    {
        if (!M.IsAliveAndWell())
            continue;
        Where = Where $ (N > 0 ? "," : "") $ string(M.Class.Name) $ "@" $ CoordStr(M.Location);
        N++;
    }
    EchelonLog("PLAYTEST_STUCK_WAVE wave=" $ string(KF.MyKFGRI.WaveNum) $ " zeds=" $ string(N) $ " stuck_for="
        $ string(int(WorldInfo.TimeSeconds - PlaytestZedCountSince)) $ " where=" $ Where);
    foreach WorldInfo.AllPawns(class'KFPawn_Monster', M)
    {
        if (M.IsAliveAndWell() && PlayerController(M.Controller) == None)
            M.Died(None, None, M.Location);
    }
    PlaytestZedCountSince = WorldInfo.TimeSeconds;
}

final function int PlaytestCountBotsAlive()
{
    local int Count;
    local EcholonBot B;

    foreach WorldInfo.AllControllers(class'EcholonBot', B)
    {
        if (B.Pawn != None && B.Pawn.IsAliveAndWell())
            Count++;
    }
    return Count;
}

// Logs PLAYTEST_WAVE_END on each wave end (trader opens, or the match ends) and PLAYTEST_DONE when the run is over.
final function PlaytestCheckWaveEnd()
{
    local bool Over, Trader;
    local int Alive;
    local string Result, Reason;

    if (bPlaytestDone)
        return;

    Over = KF.MyKFGRI.bMatchIsOver || (bPlaytestStarted && !KF.MyKFGRI.bMatchHasBegun);
    Trader = KF.MyKFGRI.bTraderIsOpen;

    // A human spectator does not count as a survivor, so the engine may never flag the match over after the
    // bots die (the defeat menu just stays). Treat 5 s with no living bot in a running wave as the wipe.
    if (!Over && !Trader && ActiveBots.Length > 0 && PlaytestCountBotsAlive() == 0)
    {
        if (PlaytestZeroSince == 0.0)
            PlaytestZeroSince = WorldInfo.TimeSeconds;
        else if (WorldInfo.TimeSeconds - PlaytestZeroSince > 5.0)
            Over = true;
    }
    else
        PlaytestZeroSince = 0.0;

    if (PlaytestWaveStart == 0.0)
        PlaytestWaveStart = WorldInfo.TimeSeconds;

    if ((Trader && !bPlaytestLastTrader) || Over)
    {
        PlaytestWavesDone++;
        Alive = PlaytestCountBotsAlive();
        Result = (Over && Alive == 0) ? "wipe" : "won";
        EchelonLog("PLAYTEST_WAVE_END wave=" $ string(KF.MyKFGRI.WaveNum) $ " result=" $ Result $ " bots_alive=" $ string(Alive)
            $ " duration=" $ string(int(WorldInfo.TimeSeconds - PlaytestWaveStart)));

        if (Over)
            Reason = (Alive == 0) ? "wipe" : "victory";
        else if (PlaytestWaves > 0 && PlaytestWavesDone >= PlaytestWaves)
            Reason = "waves";

        if (Reason != "")
        {
            EchelonLog("PLAYTEST_DONE reason=" $ Reason $ " waves_done=" $ string(PlaytestWavesDone));
            bPlaytestDone = true;
            SetTimer(5.0, false, 'PlaytestQuit');
        }
    }

    if (!Trader && bPlaytestLastTrader)
        PlaytestWaveStart = WorldInfo.TimeSeconds;
    bPlaytestLastTrader = Trader;
}

function PlaytestQuit()
{
    local PlayerController PC;

    PC = WorldInfo.GetALocalPlayerController();
    if (PC != None)
        PC.ConsoleCommand("exit");
}

// Before the match begins the human sits in the ready-up lobby; mark them ready so the run needs no input.
final function PlaytestAutoReady()
{
    local KFPlayerController PC;

    PC = GetPlaytestHuman();
    if (PC == None || PC.PlayerReplicationInfo == None || PC.PlayerReplicationInfo.bReadyToPlay)
        return;

    PC.PlayerReplicationInfo.bReadyToPlay = true;
    if (!bPlaytestReadyLogged)
    {
        bPlaytestReadyLogged = true;
        EchelonLog("PLAYTEST_READY map=" $ WorldInfo.GetMapName(true));
    }
}

function PlaytestTick()
{
    local KFPlayerController PC;
    local Pawn ViewPawn;
    local int BotsAlive;

    if (KF == None || KF.MyKFGRI == None)
        return;

    if (KF.MyKFGRI.bMatchHasBegun)
        bPlaytestStarted = true;
    if (!KF.MyKFGRI.bMatchHasBegun)
    {
        // After the match has run, bMatchHasBegun goes false again at the defeat screen: the run must still end.
        if (bPlaytestStarted)
        {
            PlaytestCheckWaveEnd();
            return;
        }
        PlaytestAutoReady();
        return;
    }

    PC = GetPlaytestHuman();
    if (PC == None)
        return;

    if (PC.Pawn != None)
    {
        PlaytestMakeSpectator(PC);
    }

    ViewPawn = Pawn(PC.ViewTarget);
    if (WorldInfo.TimeSeconds >= PlaytestNextCamTime || ViewPawn == None || !ViewPawn.IsAliveAndWell())
    {
        PlaytestStepCamera(PC, 1);
    }

    PlaytestCheckStuckWave();
    PlaytestCheckWaveEnd();

    if (WorldInfo.TimeSeconds >= PlaytestNextReportTime)
    {
        PlaytestNextReportTime = WorldInfo.TimeSeconds + 10.0;
        BotsAlive = PlaytestCountBotsAlive();
        EchelonLog("PLAYTEST_HEARTBEAT wave=" $ string(KF.MyKFGRI.WaveNum) $ " trader=" $ string(KF.MyKFGRI.bTraderIsOpen)
            $ " over=" $ string(KF.MyKFGRI.bMatchIsOver) $ " state=" $ string(KF.GetStateName())
            $ " living=" $ string(KF.GetLivingPlayerCount()) $ " bots_alive=" $ string(BotsAlive)
            $ " zeds_left=" $ string(KF.AIAliveCount) $ " human_state=" $ string(PC.GetStateName()));
    }
}

// Swap the skip-trader vote for one that only counts humans (see bBotsCountInSkipTraderVote).
function InstallVoteCollector()
{
    local KFGameReplicationInfo KFGRI;

    KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
    if (bBotsCountInSkipTraderVote || KFGRI == None || EcholonVoteCollector(KFGRI.VoteCollector) != None)
    {
        return;
    }
    KFGRI.VoteCollector = new(KFGRI) class'EcholonVoteCollector';
    EchelonLog("VOTE_COLLECTOR installed: skip-trader vote counts humans only");
}

function Timer()
{
    if (KF.MyKFGRI.bMatchIsOver)
    {
        return;
    }

    if ((KF.NumPlayers + KF.NumBots) < NumBots || KF.NumBots < MinimumBots)
    {
        AddBot();
    }
    else if ((KF.NumPlayers + KF.NumBots) > NumBots && KF.NumBots > 0 && KF.NumBots > MinimumBots)
    {
        RemoveBot();
    }
}

function RegisterBot(EcholonBot NewBot)
{
    if (NewBot == None)
        return;
    if (ActiveBots.Find(NewBot) == INDEX_NONE)
        ActiveBots.AddItem(NewBot);
    NewBot.mut = self;
    NewBot.WdLastHubContactTime = WorldInfo.TimeSeconds;
}

function UnregisterBot(EcholonBot LeavingBot)
{
    local int Idx;

    if (LeavingBot == None)
        return;

    Idx = ActiveBots.Find(LeavingBot);
    if (Idx != INDEX_NONE)
        ActiveBots.Remove(Idx, 1);

    HandleFireteamCasualty(LeavingBot);
}

function PollWaveStart()
{
    local KFGameReplicationInfo KFGRI;

    KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
    if (KFGRI == None || !KFGRI.bMatchHasBegun)
        return;

    if (KFGRI.WaveNum != LastPolledWaveNum)
    {
        LastPolledWaveNum = KFGRI.WaveNum;
        InitializePlatoon();
        RelocateBotsToAmmoCrates();
    }
}

// One time at match start, in the same tick the bots are created: put every bot alone on a random ammo
// crate (see RelocateBotsToAmmoCrates). Squads are not formed here, so the bots have to find their squad
// leader by themselves (tests the tether and the pathfinding to the leader). The wave start relocation
// only moves bots that have not picked a move yet (bJustSpawned), so by wave 1 it never applied.
function InitialRelocate()
{
    // MatchStarting ran twice in the playtest logs (two SPAWN_SPREAD batches in the same tick): once only.
    if (bInitialRelocated)
        return;
    bInitialRelocated = true;
    bForceRelocate = true;
    RelocateBotsToAmmoCrates();
    bForceRelocate = false;
}

function InitializePlatoon()
{
    local int i, GroupCount, GroupIdx;
    local EcholonBot Bot;

    PruneInvalidBots();
    ShuffleActiveBots();

    if (ActiveBots.Length == 0)
        return;

    for (GroupIdx = 0; GroupIdx < Fireteams.Length; GroupIdx++)
    {
        for (i = Fireteams[GroupIdx].Members.Length - 1; i >= 0; i--)
        {
            if (Fireteams[GroupIdx].Members[i] == None
                || Fireteams[GroupIdx].Members[i].bDeleteMe
                || Fireteams[GroupIdx].Members[i].Pawn == None
                || Fireteams[GroupIdx].Members[i].Pawn.Health <= 0)
            {
                Fireteams[GroupIdx].Members.Remove(i, 1);
            }
        }
    }

    GroupCount = DetermineGroupCount(ActiveBots.Length);
    NumGroups = GroupCount;

    Fireteams.Length = 0;
    Fireteams.Length = GroupCount;

    for (i = 0; i < ActiveBots.Length; i++)
    {
        Bot = ActiveBots[i];
        if (Bot == None)
            continue;

        GroupIdx = i % GroupCount;
        Bot.GroupID = GroupIdx + 1;
        Bot.bIsGroupLeader = false;
        Fireteams[GroupIdx].Members.AddItem(Bot);
    }

    for (GroupIdx = 0; GroupIdx < GroupCount; GroupIdx++)
    {
        if (Fireteams[GroupIdx].Members.Length > 0)
        {
            Fireteams[GroupIdx].Leader = Fireteams[GroupIdx].Members[0];
            Fireteams[GroupIdx].Leader.bIsGroupLeader = true;
            Fireteams[GroupIdx].Leader.BotRank = SQUAD_LEADER;
        }
    }

    for (i = 0; i < ActiveBots.Length; i++)
    {
        Bot = ActiveBots[i];
        if (Bot == None)
            continue;
        if (Bot.bIsGroupLeader)
            continue;
        Bot.BotRank = GRUNT;
    }

    for (i = 0; i < ActiveBots.Length; i++)
    {
        Bot = ActiveBots[i];
        if (Bot == None)
            continue;
        if (Bot.bIsAlphaCommander)
            Bot.BotRank = LIEUTENANT;
        else if (Bot == VIPController && !Bot.bIsGroupLeader)
            Bot.BotRank = CAPTAIN;  // a stand-in VIP is always a squad leader, so this no longer fires
    }

    SyncSquadLeaders();

    for (i = 0; i < ActiveBots.Length; i++)
    {
        Bot = ActiveBots[i];
        if (Bot == None)
            continue;
        InitBotCharacter(Bot);
        Bot.RefreshRoleNameTag();
    }

    UpdateMacroWaypoints();
    if (!IsTimerActive('UpdateMacroWaypoints'))
        SetTimer(MACRO_WAYPOINT_INTERVAL, true, 'UpdateMacroWaypoints');
}

function SyncSquadLeaders()
{
    local int GroupIdx, i;
    local int FollowerSlot, FollowerTotal;
    local EcholonBot Ldr, Member;

    for (GroupIdx = 0; GroupIdx < Fireteams.Length; GroupIdx++)
    {
        Ldr = Fireteams[GroupIdx].Leader;
        if (Ldr != None && (Ldr.bDeleteMe || Ldr.Pawn == None || Ldr.Pawn.Health <= 0))
        {
            Ldr = None;
        }

        FollowerTotal = 0;
        for (i = 0; i < Fireteams[GroupIdx].Members.Length; i++)
        {
            Member = Fireteams[GroupIdx].Members[i];
            if (Member != None && Member != Ldr)
            {
                FollowerTotal++;
            }
        }

        FollowerSlot = 0;
        for (i = 0; i < Fireteams[GroupIdx].Members.Length; i++)
        {
            Member = Fireteams[GroupIdx].Members[i];
            if (Member == None)
            {
                continue;
            }

            if (Member == Ldr)
            {
                Member.SquadLeader = None;
            }
            else
            {
                Member.SquadLeader = Ldr;
                Member.FollowSetSlot(FollowerSlot, FollowerTotal);
                FollowerSlot++;
            }
        }
    }
}

function ShuffleActiveBots()
{
    local int i, SwapIdx;
    local EcholonBot Temp;

    for (i = ActiveBots.Length - 1; i > 0; i--)
    {
        SwapIdx = Rand(i + 1);
        Temp = ActiveBots[i];
        ActiveBots[i] = ActiveBots[SwapIdx];
        ActiveBots[SwapIdx] = Temp;
    }
}

function PruneInvalidBots()
{
    local int i;
    for (i = ActiveBots.Length - 1; i >= 0; i--)
    {
        if (ActiveBots[i] == None || ActiveBots[i].bDeleteMe || ActiveBots[i].Pawn == None || ActiveBots[i].Pawn.Health <= 0)
        {
            ActiveBots.Remove(i, 1);
        }
    }
}

function int DetermineGroupCount(int BotCount)
{
    local int Count;
    Count = BotCount / BOTS_PER_GROUP_TARGET;
    if (Count < MIN_GROUPS)
        Count = MIN_GROUPS;
    if (Count > MAX_GROUPS)
        Count = MAX_GROUPS;
    return Count;
}

function UpdateMacroWaypoints()
{
    local int GroupIdx;
    local EcholonBot GroupLeader;
    local KFGameReplicationInfo KFGRI;
    local Pawn BossPawn;
    local Actor NewAnchor;
    local vector ProjectedLoc;
    local Controller VIP;

    PruneInvalidBots();
    ProcessPromotionQueue();
    CleanupRangedHealCooldowns();

    if (VIPController != None && (VIPController.Pawn == None || VIPController.Pawn.Health <= 0))
    {
        HandleVIPSuccession();
    }

    if (ActiveBots.Length == 0 || NumGroups <= 0)
    {
        return;
    }

    EvaluateRegroupEntries();

    KFGRI = KFGameReplicationInfo(WorldInfo.GRI);

    if (KFGRI != None && KFGRI.IsBossWave())
    {
        BossPawn = FindBossPawn();
        if (BossPawn != None)
        {
            for (GroupIdx = 0; GroupIdx < NumGroups; GroupIdx++)
            {
                GroupLeader = Fireteams[GroupIdx].Leader;
                if (GroupLeader == None)
                {
                    continue;
                }
                Fireteams[GroupIdx].Anchor = None;
                GroupLeader.AssignedAnchor = BossPawn;
                PropagateAnchorToFollowers(GroupIdx);
            }
            return;
        }
    }

    VIP = GetVIPController();

    for (GroupIdx = 0; GroupIdx < NumGroups; GroupIdx++)
    {
        GroupLeader = Fireteams[GroupIdx].Leader;
        if (GroupLeader == None)
        {
            continue;
        }

        switch (GroupIdx)
        {
            case 0:
                if (KFGRI != None && KFGRI.bTraderIsOpen)
                {
                    Fireteams[GroupIdx].Anchor = None;
                    GroupLeader.AssignedAnchor = None;
                }
                else if (VIP == GroupLeader)
                {
                    // This leader is the stand-in VIP itself (no human alive), so it moves freely.
                    Fireteams[GroupIdx].Anchor = None;
                    GroupLeader.AssignedAnchor = None;
                }
                else if (VIP != None && VIP.Pawn != None)
                {
                    Fireteams[GroupIdx].Anchor = None;
                    GroupLeader.AssignedAnchor = VIP.Pawn;
                }
                break;
            case 1:
                if (VIP != None && VIP.Pawn != None)
                {
                    ProjectedLoc = VIP.Pawn.Location + (vector(VIP.Pawn.Rotation) * VANGUARD_OFFSET);
                    NewAnchor = FindNearestNavPoint(ProjectedLoc, NAV_SEARCH_RADIUS);
                    if (NewAnchor != None)
                    {
                        Fireteams[GroupIdx].Anchor = NavigationPoint(NewAnchor);
                        GroupLeader.AssignedAnchor = NewAnchor;
                    }
                }
                break;
            case 2:
                if (VIP != None && VIP.Pawn != None)
                {
                    ProjectedLoc = VIP.Pawn.Location - (vector(VIP.Pawn.Rotation) * REARGUARD_OFFSET);
                    NewAnchor = FindNearestNavPoint(ProjectedLoc, NAV_SEARCH_RADIUS);
                    if (NewAnchor != None)
                    {
                        Fireteams[GroupIdx].Anchor = NavigationPoint(NewAnchor);
                        GroupLeader.AssignedAnchor = NewAnchor;
                    }
                }
                break;
            case 3:
                NewAnchor = FindNearestChokepoint(VIP);
                if (NewAnchor != None)
                {
                    Fireteams[GroupIdx].Anchor = NavigationPoint(NewAnchor);
                    GroupLeader.AssignedAnchor = NewAnchor;
                }
                break;
        }
        PropagateAnchorToFollowers(GroupIdx);
    }
}

function PropagateAnchorToFollowers(int GroupIdx)
{
    local int i;
    local EcholonBot Member;

    if (Fireteams[GroupIdx].Leader == None)
        return;

    for (i = 0; i < Fireteams[GroupIdx].Members.Length; i++)
    {
        Member = Fireteams[GroupIdx].Members[i];
        if (Member != None && !Member.bIsGroupLeader)
        {
            Member.AssignedAnchor = Fireteams[GroupIdx].Leader.AssignedAnchor;
        }
    }
}

function NavigationPoint FindNearestNavPoint(vector ProjectedLoc, float SearchRadius)
{
    local NavigationPoint FoundNav, BestNav;
    local float Dist, BestDist;

    // C4 fix, BEHAVIOR-CHANGE: legacy returned the first hit of the radius iterator, which is not
    // ordered by distance. Return the closest navigation point instead.
    foreach WorldInfo.RadiusNavigationPoints(class'NavigationPoint', FoundNav, ProjectedLoc, SearchRadius)
    {
        Dist = VSizeSq(FoundNav.Location - ProjectedLoc);
        if (BestNav == None || Dist < BestDist)
        {
            BestNav = FoundNav;
            BestDist = Dist;
        }
    }
    return BestNav;
}


function NavigationPoint FindNearestChokepoint(Controller VIP)
{
    local vector ProjectedLoc, LateralVec;

    if (VIP == None || VIP.Pawn == None)
        return None;

    LateralVec = Normal(vector(VIP.Pawn.Rotation) cross vect(0,0,1));
    ProjectedLoc = VIP.Pawn.Location + (LateralVec * CHOKEPOINT_LATERAL_OFFSET);

    // C4 fix, BEHAVIOR-CHANGE: closest point to the flank position, not the iterator's first hit.
    return FindNearestNavPoint(ProjectedLoc, NAV_SEARCH_RADIUS);
}


// The VIP is a living human whenever there is one. While no human is alive (dead and waiting for the
// trader, or spectating in playtest mode) a living bot squad leader stands in as the anchor
// (PickLeaderAnchor); it stays a squad leader. The VIP goes back to the human as soon as they respawn.
function Controller GetVIPController()
{
    local Controller C, NewVIP;

    foreach WorldInfo.AllControllers(class'Controller', C)
    {
        if (PlayerController(C) != None && C.Pawn != None && C.Pawn.Health > 0)
        {
            NewVIP = C;
            break;
        }
    }
    if (NewVIP == None)
    {
        NewVIP = PickLeaderAnchor();
    }

    if (NewVIP != VIPController)
    {
        EchelonLog("VIP_CHANGE new=" $ VIPTag(NewVIP) $ " old=" $ VIPTag(VIPController)
            $ " kind=" $ (EcholonBot(NewVIP) != None ? "leader" : (NewVIP != None ? "human" : "none")));
        VIPController = NewVIP;
    }
    return VIPController;
}

final function string VIPTag(Controller C)
{
    if (EcholonBot(C) != None)
        return EcholonBot(C).LogTag();
    if (C != None && C.PlayerReplicationInfo != None)
        return "human(" $ C.PlayerReplicationInfo.PlayerName $ ")";
    return "None";
}

function Pawn FindBossPawn()
{
    local Pawn P;
    local Pawn BestBoss;

    if (CachedBossPawn != None && !CachedBossPawn.bDeleteMe && CachedBossPawn.Health > 0)
    {
        return CachedBossPawn;
    }

    foreach WorldInfo.AllPawns(class'Pawn', P)
    {
        if (KFPawn_Monster(P) != None && P.Health > 5000)
        {
            if (BestBoss == None || P.Health > BestBoss.Health)
            {
                BestBoss = P;
            }
        }
    }

    CachedBossPawn = BestBoss;
    return BestBoss;
}

function OnBotKilled(EcholonBot DeadBot)
{
    local PromotionRequest Req;

    if (DeadBot == None)
    {
        return;
    }

    if (DeadBot.BotRank == SQUAD_LEADER || DeadBot.BotRank == LIEUTENANT || DeadBot.BotRank == CAPTAIN)
    {
        Req.DeadOfficer = DeadBot;
        Req.OldRank = DeadBot.BotRank;
        Req.Replacement = None;
        Req.Score = 0;
        PendingPromotions.AddItem(Req);
    }

    if (DeadBot == VIPController)
    {
        HandleVIPSuccession();
        UpdateMacroWaypoints();
    }

    UnregisterBot(DeadBot);
}

function int ComputeCommandScore(EcholonBot Bot)
{
    if (Bot == None || Bot.PlayerReplicationInfo == None || Bot.Pawn == None)
        return -1;
    return (Bot.PlayerReplicationInfo.Kills * 10) + Bot.Pawn.Health;
}

function EcholonBot FindBestCandidate(array<EcholonBot> Candidates)
{
    local int i;
    local EcholonBot Best;

    Best = None;
    for (i = 0; i < Candidates.Length; i++)
    {
        if (Candidates[i] == None || Candidates[i].Pawn == None || Candidates[i].Pawn.Health <= 0)
            continue;
        if (Best == None || ComputeCommandScore(Candidates[i]) > ComputeCommandScore(Best))
            Best = Candidates[i];
    }
    return Best;
}

function EcholonBot FindExpendableMember(array<EcholonBot> Candidates)
{
    local int i;
    local EcholonBot Worst;
    Worst = None;
    for (i = 0; i < Candidates.Length; i++)
    {
        if (Candidates[i] == None || Candidates[i].bIsGroupLeader)
            continue;
        if (Candidates[i].Pawn == None || Candidates[i].Pawn.Health <= 0)
            continue;
        if (Worst == None || ComputeCommandScore(Candidates[i]) < ComputeCommandScore(Worst))
            Worst = Candidates[i];
    }
    return Worst;
}

function ProcessPromotionQueue()
{
    local int i, MaxPerTick;
    local int DeadGroupIdx;
    local PromotionRequest Req;
    local array<EcholonBot> Candidates;
    local KFGameReplicationInfo KFGRI;

    if (PendingPromotions.Length == 0)
    {
        return;
    }

    KFGRI = KFGameReplicationInfo(WorldInfo.GRI);

    MaxPerTick = 1;
    if (KFGRI != None && KFGRI.WaveNum > 5)
    {
        MaxPerTick = 2;
    }

    Candidates.Length = 0;
    for (i = 0; i < ActiveBots.Length; i++)
    {
        if (ActiveBots[i] != None && ActiveBots[i].BotRank == GRUNT
            && ActiveBots[i].Pawn != None && ActiveBots[i].Pawn.Health > 0)
        {
            Candidates.AddItem(ActiveBots[i]);
        }
    }

    while (PendingPromotions.Length > 0 && MaxPerTick > 0)
    {
        Req = PendingPromotions[PendingPromotions.Length - 1];
        PendingPromotions.Remove(PendingPromotions.Length - 1, 1);

        if (Req.OldRank == SQUAD_LEADER && Req.DeadOfficer != None)
        {
            DeadGroupIdx = Req.DeadOfficer.GroupID - 1;
            if (DeadGroupIdx >= 0 && DeadGroupIdx < Fireteams.Length)
            {
                if (Fireteams[DeadGroupIdx].Leader != None
                    && Fireteams[DeadGroupIdx].Leader.bIsGroupLeader
                    && Fireteams[DeadGroupIdx].Leader.Pawn != None
                    && Fireteams[DeadGroupIdx].Leader.Pawn.Health > 0)
                {
                    continue;
                }
            }
        }

        if (Req.Replacement == None)
        {
            Req.Replacement = FindBestCandidate(Candidates);
        }
        if (Req.Replacement != None && Req.Replacement.Pawn != None && Req.Replacement.Pawn.Health > 0)
        {
            PromoteBot(Req.Replacement, Req.OldRank);
            i = Candidates.Find(Req.Replacement);
            if (i != INDEX_NONE)
            {
                Candidates.Remove(i, 1);
            }
            MaxPerTick = MaxPerTick - 1;
        }
    }
}

function PromoteBot(EcholonBot Bot, EBotRank NewRank)
{
    if (Bot == None)
        return;
    Bot.BotRank = NewRank;
}

function RegisterRangedHealTarget(KFPawn_Human Target)
{
    local int I;

    if (Target == None)
        return;

    for (I = 0; I < RangedHealTargets.Length; I++)
    {
        if (RangedHealTargets[I] == Target)
        {
            RangedHealCooldownEnds[I] = WorldInfo.TimeSeconds + 25.0;
            return;
        }
    }

    RangedHealTargets.AddItem(Target);
    RangedHealCooldownEnds.AddItem(WorldInfo.TimeSeconds + 25.0);
}

function bool IsRangedHealTargetOnCooldown(KFPawn_Human Target)
{
    local int I;

    if (Target == None)
    {
        return false;
    }

    I = 0;
    while (I < RangedHealTargets.Length)
    {
        if (RangedHealTargets[I] == Target)
        {
            return WorldInfo.TimeSeconds < RangedHealCooldownEnds[I];
        }
        I++;
    }
    return false;
}

function CleanupRangedHealCooldowns()
{
    local int I;

    I = RangedHealTargets.Length - 1;
    while (I >= 0)
    {
        if (WorldInfo.TimeSeconds >= RangedHealCooldownEnds[I])
        {
            RangedHealTargets.Remove(I, 1);
            RangedHealCooldownEnds.Remove(I, 1);
        }
        I--;
    }
}

// The VIP died: a living human takes over, else a living squad leader stands in (see GetVIPController).
// Before 2026-10-22 the best-scoring bot became VIP and alpha commander, was demoted from squad leader,
// and kept the VIP even after the human respawned.
function HandleVIPSuccession()
{
    GetVIPController();
}

function HandleFireteamCasualty(EcholonBot DeadBot)
{
    local int GroupIdx, MemberIdx;
    local bool bWasLeader;
    local EcholonBot NewLeader;

    if (DeadBot == None)
    {
        return;
    }

    GroupIdx = DeadBot.GroupID - 1;
    if (GroupIdx < 0 || GroupIdx >= Fireteams.Length)
    {
        return;
    }

    bWasLeader = DeadBot.bIsGroupLeader;

    MemberIdx = Fireteams[GroupIdx].Members.Find(DeadBot);
    if (MemberIdx != INDEX_NONE)
    {
        Fireteams[GroupIdx].Members.Remove(MemberIdx, 1);
    }

    if (bWasLeader)
    {
        NewLeader = FindBestCandidate(Fireteams[GroupIdx].Members);
        if (NewLeader != None)
        {
            NewLeader.bIsGroupLeader = true;
            NewLeader.BotRank = SQUAD_LEADER;
            NewLeader.ResetStuckState();
            Fireteams[GroupIdx].Leader = NewLeader;
            InheritSquadOrder(GroupIdx, NewLeader);
        }
        else
        {
            Fireteams[GroupIdx].Leader = None;
            if (GroupIdx < SquadOrders.Length)
            {
                SquadOrders[GroupIdx].Leader = None;
                SquadOrders[GroupIdx].ObjectiveBailUntil = 0.0;
            }
        }
    }

    ConsolidateFireteams();
    SampleSquadSlots(GroupIdx);
}

function DemoteGroupLeader(EcholonBot OldLeader)
{
    local int GroupIdx, i;
    local EcholonBot Candidate, NewLeader;

    NewLeader = None;

    if (OldLeader == None || !OldLeader.bIsGroupLeader)
        return;

    GroupIdx = OldLeader.GroupID - 1;
    if (GroupIdx < 0 || GroupIdx >= Fireteams.Length)
        return;

    OldLeader.bIsGroupLeader = false;

    for (i = 0; i < Fireteams[GroupIdx].Members.Length; i++)
    {
        Candidate = Fireteams[GroupIdx].Members[i];
        if (Candidate == None || Candidate == OldLeader)
            continue;
        if (Candidate.Pawn == None || Candidate.Pawn.Health <= 0)
            continue;

        if (NewLeader == None || ComputeCommandScore(Candidate) > ComputeCommandScore(NewLeader))
        {
            NewLeader = Candidate;
        }
    }

    if (NewLeader != None)
    {
        NewLeader.bIsGroupLeader = true;
        NewLeader.ResetStuckState();
        Fireteams[GroupIdx].Leader = NewLeader;
        InheritSquadOrder(GroupIdx, NewLeader);
    }

    ConsolidateFireteams();
}

function RequestLeaderDemotion(EcholonBot StuckLeader)
{
    DemoteGroupLeader(StuckLeader);
}

function ConsolidateFireteams()
{
    local int GroupIdx;

    if (Fireteams.Length > 0 && Fireteams[0].Members.Length < VIP_ESCORT_MIN_SIZE)
    {
        PullBotFromNearestGroup(0);
    }
    for (GroupIdx = 0; GroupIdx < Fireteams.Length; GroupIdx++)
    {
        if (Fireteams[GroupIdx].Members.Length == GROUP_DISSOLVE_SIZE)
        {
            DissolveGroup(GroupIdx);
        }
    }
    SyncSquadLeaders();
}

function PullBotFromNearestGroup(int TargetGroupIdx)
{
    local int SourceGroupIdx, BestSourceIdx;
    local float BestDistSq, DistSq;
    local EcholonBot Puller;
    local vector TargetLoc;

    if (Fireteams[TargetGroupIdx].Leader == None || Fireteams[TargetGroupIdx].Leader.Pawn == None)
        return;

    TargetLoc = Fireteams[TargetGroupIdx].Leader.Pawn.Location;
    BestSourceIdx = INDEX_NONE;
    BestDistSq = 0.0;

    for (SourceGroupIdx = 0; SourceGroupIdx < Fireteams.Length; SourceGroupIdx++)
    {
        if (SourceGroupIdx == TargetGroupIdx) continue;
        if (Fireteams[SourceGroupIdx].Members.Length <= 2) continue;
        if (Fireteams[SourceGroupIdx].Leader == None || Fireteams[SourceGroupIdx].Leader.Pawn == None) continue;

        DistSq = VSizeSq(Fireteams[SourceGroupIdx].Leader.Pawn.Location - TargetLoc);
        if (BestSourceIdx == INDEX_NONE || DistSq < BestDistSq)
        {
            BestSourceIdx = SourceGroupIdx;
            BestDistSq = DistSq;
        }
    }

    if (BestSourceIdx == INDEX_NONE) return;

    Puller = FindExpendableMember(Fireteams[BestSourceIdx].Members);
    if (Puller == None) return;

    ReassignBotToGroup(Puller, TargetGroupIdx);
}

function DissolveGroup(int GroupIdx)
{
    local EcholonBot Remaining;
    local int NearestGroupIdx;

    if (Fireteams[GroupIdx].Members.Length != GROUP_DISSOLVE_SIZE)
        return;

    Remaining = Fireteams[GroupIdx].Members[0];
    NearestGroupIdx = FindNearestEligibleGroup(GroupIdx, Remaining);

    if (NearestGroupIdx == INDEX_NONE)
        return;

    Fireteams[GroupIdx].Members.Remove(0, 1);
    Fireteams[GroupIdx].Leader = None;

    ReassignBotToGroup(Remaining, NearestGroupIdx);
}

function int FindNearestEligibleGroup(int ExcludeGroupIdx, EcholonBot Bot)
{
    local int GroupIdx, BestIdx;
    local float BestDistSq, DistSq;

    BestIdx = INDEX_NONE;
    BestDistSq = 0.0;

    if (Bot == None || Bot.Pawn == None)
    {
        return INDEX_NONE;
    }

    for (GroupIdx = 0; GroupIdx < Fireteams.Length; GroupIdx++)
    {
        if (GroupIdx == ExcludeGroupIdx)
        {
            continue;
        }
        if (Fireteams[GroupIdx].Members.Length < 2)
        {
            continue;
        }
        if (Fireteams[GroupIdx].Leader == None || Fireteams[GroupIdx].Leader.Pawn == None)
        {
            continue;
        }

        DistSq = VSizeSq(Fireteams[GroupIdx].Leader.Pawn.Location - Bot.Pawn.Location);
        if (BestIdx == INDEX_NONE || DistSq < BestDistSq)
        {
            BestIdx = GroupIdx;
            BestDistSq = DistSq;
        }
    }

    return BestIdx;
}

function ReassignBotToGroup(EcholonBot Bot, int NewGroupIdx)
{
	local int OldGroupIdx, MemberIdx;

	if (Bot == None)
	{
		return;
	}

	OldGroupIdx = Bot.GroupID - 1;
	if (OldGroupIdx >= 0 && OldGroupIdx < Fireteams.Length)
	{
		MemberIdx = Fireteams[OldGroupIdx].Members.Find(Bot);
		if (MemberIdx != INDEX_NONE)
		{
			Fireteams[OldGroupIdx].Members.Remove(MemberIdx, 1);
		}
	}

	Bot.bIsGroupLeader = false;
	Bot.GroupID = NewGroupIdx + 1;
	Bot.ResetStuckState();
	Fireteams[NewGroupIdx].Members.AddItem(Bot);

	if (Fireteams[NewGroupIdx].Leader != None)
	{
		Bot.AssignedAnchor = Fireteams[NewGroupIdx].Leader.AssignedAnchor;
	}
}

function EcholonBot GetGroupLeader(int GroupID)
{
    local int GroupIdx;
    GroupIdx = GroupID - 1;
    if (GroupIdx < 0 || GroupIdx >= Fireteams.Length)
    {
        return None;
    }
    return Fireteams[GroupIdx].Leader;
}

function int GetGroupSize(int GroupID)
{
    local int GroupIdx;

    GroupIdx = GroupID - 1;
    if (GroupIdx < 0 || GroupIdx >= Fireteams.Length)
    {
        return 0;
    }
    return Fireteams[GroupIdx].Members.Length;
}

function int GetFollowerIndex(EcholonBot Bot)
{
    local int GroupIdx, i, FollowerCount;

    if (Bot == None)
        return 1;

    GroupIdx = Bot.GroupID - 1;
    if (GroupIdx < 0 || GroupIdx >= Fireteams.Length)
        return 1;

    FollowerCount = 0;
    for (i = 0; i < Fireteams[GroupIdx].Members.Length; i++)
    {
        if (Fireteams[GroupIdx].Members[i] == Fireteams[GroupIdx].Leader)
            continue;
        FollowerCount++;
        if (Fireteams[GroupIdx].Members[i] == Bot)
            return FollowerCount;
    }
    return FollowerCount + 1;
}

function BroadcastSpottedEnemy(int GroupID, Pawn Spotted)
{
    local int GroupIdx, i;
    local EcholonBot Member;

    if (Spotted == None || !Spotted.IsAliveAndWell())
        return;

    GroupIdx = GroupID - 1;
    if (GroupIdx < 0 || GroupIdx >= Fireteams.Length)
        return;

    for (i = 0; i < Fireteams[GroupIdx].Members.Length; i++)
    {
        Member = Fireteams[GroupIdx].Members[i];
        if (Member == None || Member.bIsGroupLeader)
            continue;
        if (Member.Pawn == None || Member.Pawn.Health <= 0)
            continue;
        if (Member.Enemy != None && Member.Enemy.IsAliveAndWell())
            continue;

        Member.SetEnemy(Spotted, true);
    }
}

function CheckWave()
{
    if (bNewWave && KF.GetStateName() == 'TraderOpen')
    {
        bNewWave = false;
        RespawnBots();
    }

    if (KF.WaveNum != OldWaveNum)
    {
        OldWaveNum = byte(KF.WaveNum);
        bNewWave = true;
        if ((ZedCountScaling > 0.0) && KF.SpawnManager.WaveTotalAI > 4)
        {
            KF.SpawnManager.WaveTotalAI *= (1.0 + (float(KF.NumBots) * ZedCountScaling));
            KF.MyKFGRI.AIRemaining = KF.SpawnManager.WaveTotalAI;
            KF.MyKFGRI.WaveTotalAICount = KF.SpawnManager.WaveTotalAI;
        }
    }

    if (PrevObjective != KF.MyKFGRI.CurrentObjective)
    {
        PrevObjective = KF.MyKFGRI.CurrentObjective;
        HoldVolume = KFMapObjective_DoshHold(PrevObjective);
        if (HoldVolume != None)
        {
            SetHoldObjective(HoldVolume);
        }
        else
        {
            if (bObjectiveActive)
            {
                EndObjective();
            }
        }
    }
    else
    {
        if (bObjectiveActive && HoldVolume != None && HoldVolume.GetProgress() >= 0.999)
        {
            EndObjective();
        }
    }

    UpdateHuntOrders();
    EvaluateSquadPhase();
}

// Hunt order: when only a few zeds are left (alive plus still to spawn) and the map has no objective, each
// squad leader is ordered toward the nearest leftover zed, and the whole squad follows (the bots reach it
// through the objective pipeline: P5 / DoObjective / follow). Bots used to wait until a leftover zed came
// within 1500 units, because Hunting only works on zeds a bot already sees.
function UpdateHuntOrders()
{
    local KFGameReplicationInfo GRI;
    local KFPawn_Monster Z, BestZ;
    local EcholonBot L;
    local NavigationPoint GP;
    local float D, BestD;
    local int Alive, i;
    local bool bWant;

    if (WorldInfo.TimeSeconds - LastHuntOrderTime < HUNT_ORDER_INTERVAL)
        return;
    LastHuntOrderTime = WorldInfo.TimeSeconds;

    GRI = KFGameReplicationInfo(WorldInfo.GRI);
    bWant = false;
    if (GRI != None && !bObjectiveActive && NumGroups > 0 && GRI.bMatchHasBegun && !GRI.bMatchIsOver
        && !GRI.bTraderIsOpen && !GRI.IsBossWave() && GRI.AIRemaining <= HUNT_ORDER_MAX_ZEDS)
    {
        foreach WorldInfo.AllPawns(class'KFPawn_Monster', Z)
        {
            if (Z.IsAliveAndWell())
                Alive++;
        }
        bWant = (Alive > 0);
    }

    if (!bWant)
    {
        if (bHuntOrderActive)
        {
            bHuntOrderActive = false;
            for (i = 0; i < SquadOrders.Length; i++)
                SquadOrders[i].GoalNav = None;
            EchelonLog("HUNT_ORDER_END");
        }
        return;
    }

    EnsureSquadOrderTable();
    if (!bHuntOrderActive)
        EchelonLog("HUNT_ORDER_START zeds=" $ string(Alive) $ " remaining=" $ string(GRI.AIRemaining));
    bHuntOrderActive = true;

    for (i = 0; i < Fireteams.Length && i < SquadOrders.Length; i++)
    {
        L = Fireteams[i].Leader;
        SquadOrders[i].GoalNav = None;
        if (L == None || L.Pawn == None || !L.Pawn.IsAliveAndWell())
            continue;
        BestZ = None;
        BestD = 999999999.0;
        foreach WorldInfo.AllPawns(class'KFPawn_Monster', Z)
        {
            if (!Z.IsAliveAndWell())
                continue;
            D = VSizeSq(Z.Location - L.Pawn.Location);
            if (D < BestD)
            {
                BestD = D;
                BestZ = Z;
            }
        }
        // Closer than this the normal combat states already see the zed.
        if (BestZ == None || BestD < HUNT_ORDER_MIN_DIST_SQ)
            continue;
        GP = FindNearestNavPoint(BestZ.Location, NAV_SEARCH_RADIUS);
        if (GP == None)
            continue;
        SquadOrders[i].Leader = L;
        SquadOrders[i].GoalNav = GP;
    }
}

final function SetHoldObjective(Volume V)
{
    local NavigationPoint N;
    local NavigationPoint GP;
    local int i;

    ValidPoints.Length = 0;
    foreach WorldInfo.AllNavigationPoints(Class'Engine.NavigationPoint', N)
    {
        if (V.Encompasses(N))
        {
            ValidPoints.AddItem(N);
        }
    }
    bObjectiveActive = ValidPoints.Length != 0;

    if (bObjectiveActive)
    {
        EnsureSquadOrderTable();
        for (i = 0; i < SquadOrders.Length; i++)
        {
            SquadOrders[i].Zone = HoldVolume;
            SquadOrders[i].SquadID = i + 1;
            SquadOrders[i].NodeBlacklist.Length = 0;
            SquadOrders[i].ObjectiveBailUntil = 0.0;
            if (SquadOrders[i].Leader != None && SquadOrders[i].Leader.Pawn != None)
            {
                GP = NearestValidPoint(SquadOrders[i].Leader.Pawn.Location);
                if (GP != None)
                {
                    SquadOrders[i].GoalNav = GP;
                    SquadOrders[i].GoalPoint = GP.Location;
                    SquadOrders[i].Phase = PHASE_ENROUTE;
                    SquadOrders[i].StartTime = WorldInfo.TimeSeconds;
                    SquadOrders[i].SquadSeedAngle = FRand() * 6.2831855;
                    EchelonLog("ORDER_CREATED squad=" $ string(i + 1) $ " goal=" $ CoordStr(SquadOrders[i].GoalPoint));
                    SampleSquadSlots(i);
                }
            }
            else
            {
                SquadOrders[i].GoalNav = None;
                SquadOrders[i].GoalPoint = vect(0, 0, 0);
                SquadOrders[i].Phase = PHASE_IDLE;
            }
        }
    }
}

final function EndObjective()
{
    local EcholonBot B;
    local int i;

    bObjectiveActive = false;
    ValidPoints.Length = 0;

    for (i = 0; i < SquadOrders.Length; i++)
    {
        ReleaseSquadSlots(i, "EndObjective");
        SquadOrders[i].Leader = None;
        SquadOrders[i].Zone = None;
        SquadOrders[i].GoalNav = None;
        SquadOrders[i].GoalPoint = vect(0, 0, 0);
        SquadOrders[i].Slots.Length = 0;
        SquadOrders[i].NodeBlacklist.Length = 0;
        SquadOrders[i].ObjectiveBailUntil = 0.0;

        if (Fireteams[i].Members.Length > 0)
        {
            SquadOrders[i].Phase = PHASE_REGROUP;
            SquadOrders[i].StartTime = WorldInfo.TimeSeconds;
        }
        else
        {
            SquadOrders[i].Phase = PHASE_IDLE;
        }
    }

    foreach WorldInfo.AllControllers(class'EcholonBot', B)
    {
        B.FinishObjective();
    }
}

function NavigationPoint NearestValidPoint(vector Loc)
{
    local int i;
    local NavigationPoint N, Best;
    local float BestDistSq, DistSq;

    Best = None;
    BestDistSq = 9999999999.0;
    for (i = 0; i < ValidPoints.Length; i++)
    {
        N = ValidPoints[i];
        if (N == None)
            continue;
        DistSq = VSizeSq(N.Location - Loc);
        if (DistSq < BestDistSq)
        {
            BestDistSq = DistSq;
            Best = N;
        }
    }
    return Best;
}

function string CoordStr(vector L)
{
    return string(FFloor(L.X / 100.0)) $ "," $ string(FFloor(L.Y / 100.0)) $ "," $ string(FFloor(L.Z / 100.0));
}

function EnsureSquadOrderTable()
{
    local int i;

    if (SquadOrders.Length == Fireteams.Length)
        return;
    // Playtest fix (legacy bug): writing SquadOrders[i].Member past the end does not grow a dynamic
    // array, it logs "Attempt to assign variable through None" (1,818 times in one 5-round test), so
    // the table stayed empty and every squad order read went out of bounds. Size it first.
    i = SquadOrders.Length;
    SquadOrders.Length = Fireteams.Length;
    for (i = i; i < Fireteams.Length; i++)
    {
        SquadOrders[i].SquadID = i + 1;
        SquadOrders[i].Leader = None;
        SquadOrders[i].Zone = None;
        SquadOrders[i].GoalNav = None;
        SquadOrders[i].GoalPoint = vect(0, 0, 0);
        SquadOrders[i].Phase = PHASE_IDLE;
    }
}

function InheritSquadOrder(int GroupIdx, EcholonBot NewLeader)
{
    local SquadOrder O;
    local NavigationPoint GP;
    local int GoalKept;

    if (NewLeader == None || NewLeader.Pawn == None)
        return;
    if (GroupIdx < 0 || GroupIdx >= SquadOrders.Length)
        return;

    O = SquadOrders[GroupIdx];
    if (O.GoalNav == None)
    {
        O.Leader = NewLeader;
        O.Phase = PHASE_IDLE;
        O.ObjectiveBailUntil = 0.0;
        SquadOrders[GroupIdx] = O;
        return;
    }

    O.Leader = NewLeader;
    O.ObjectiveBailUntil = 0.0;
    GoalKept = 1;
    if (O.Zone != None && !O.Zone.EncompassesPoint(O.GoalPoint)) // SDK-UNVERIFIED: EncompassesPoint
    {
        GP = NearestValidPoint(NewLeader.Pawn.Location);
        if (GP != None)
        {
            O.GoalNav = GP;
            O.GoalPoint = GP.Location;
            GoalKept = 0;
        }
    }
    SquadOrders[GroupIdx] = O;
    if (O.GoalNav != None)
    {
        SampleSquadSlots(GroupIdx);
    }
    EchelonLog("ORDER_INHERIT squad=" $ string(GroupIdx + 1) $ " newLeader=" $ string(NewLeader.Name) $ " goalKept=" $ string(GoalKept));
}

function SampleSquadSlots(int GroupIdx)
{
    local SquadOrder O;
    local EcholonBot Ldr, M;
    local vector LeaderLoc, Candidate;
    local array<vector> Candidates;
    local array<bool> bAlive;
    local float Angle, R0, DMin, Dist, BestDist;
    local int N, i, j, BestIdx;

    if (GroupIdx < 0 || GroupIdx >= SquadOrders.Length)
        return;
    if (GroupIdx >= Fireteams.Length)
        return;

    O = SquadOrders[GroupIdx];
    Ldr = O.Leader;
    if (Ldr == None || Ldr.Pawn == None || O.GoalNav == None)
        return;

    ReleaseSquadSlots(GroupIdx, "Resample");

    LeaderLoc = Ldr.Pawn.Location;

    N = 0;
    for (i = 0; i < Fireteams[GroupIdx].Members.Length; i++)
    {
        if (Fireteams[GroupIdx].Members[i] == None)
            continue;
        if (Fireteams[GroupIdx].Members[i] == Ldr)
            continue;
        N++;
    }
    if (N > 4)
        N = 4;
    if (N <= 0)
        return;

    O.Slots.Length = 0;
    O.SlotLocs.Length = 0;

    R0 = 96.0;
    for (i = 0; i < N; i++)
    {
        Angle = O.SquadSeedAngle + (float(i) * 6.2831855 / float(N));
        Candidate.X = O.GoalPoint.X + Cos(Angle) * R0;
        Candidate.Y = O.GoalPoint.Y + Sin(Angle) * R0;
        Candidate.Z = O.GoalPoint.Z;
        Candidates.AddItem(Candidate);
        bAlive.AddItem(true);
    }

    // SDK-UNVERIFIED: EncompassesPoint not separately verified in SDK index
    for (i = 0; i < N; i++)
    {
        if (O.Zone != None && !O.Zone.EncompassesPoint(Candidates[i]))
        {
            bAlive[i] = false;
        }
        if (Abs(Candidates[i].Z - LeaderLoc.Z) >= 50.0)
        {
            bAlive[i] = false;
        }
    }

    BestDist = 0.0;
    while (true)
    {
        BestIdx = INDEX_NONE;
        for (i = 0; i < N; i++)
        {
            if (!bAlive[i])
                continue;
            DMin = VSize(Candidates[i] - O.GoalPoint);
            for (j = 0; j < O.SlotLocs.Length; j++)
            {
                Dist = VSize(Candidates[i] - O.SlotLocs[j]);
                if (Dist < DMin)
                    DMin = Dist;
            }
            if (BestIdx == INDEX_NONE || DMin > BestDist)
            {
                BestDist = DMin;
                BestIdx = i;
            }
        }
        if (BestIdx == INDEX_NONE)
            break;
        if (BestIdx >= O.SlotLocs.Length)
        {
            O.SlotLocs.Length = BestIdx + 1;
        }
        O.SlotLocs[BestIdx] = Candidates[BestIdx];
        O.Slots.AddItem(BestIdx);
        bAlive[BestIdx] = false;
        BestDist = 0.0;
    }
    SquadOrders[GroupIdx] = O;

    for (j = 0; j < O.Slots.Length; j++)
    {
        M = GetFollowerBySlot(GroupIdx, O.Slots[j]);
        if (M == None)
            continue;
        EchelonLog("SLOT_CLAIM bot=" $ string(M.Name) $ " squad=" $ string(GroupIdx + 1) $ " slot=" $ string(O.Slots[j]) $ " angle=" $ string(Atan2(Candidates[O.Slots[j]].Y - O.GoalPoint.Y, Candidates[O.Slots[j]].X - O.GoalPoint.X) * 57.2957795) $ " dist=" $ string(VSize(Candidates[O.Slots[j]] - O.GoalPoint)));
    }
}

function ReleaseSquadSlots(int GroupIdx, string Reason)
{
    local SquadOrder O;
    local EcholonBot M;
    local int j;

    if (GroupIdx < 0 || GroupIdx >= SquadOrders.Length)
        return;

    O = SquadOrders[GroupIdx];
    for (j = 0; j < O.Slots.Length; j++)
    {
        M = GetFollowerBySlot(GroupIdx, O.Slots[j]);
        if (M != None)
        {
            EchelonLog("SLOT_RELEASE bot=" $ string(M.Name) $ " squad=" $ string(GroupIdx + 1) $ " slot=" $ string(O.Slots[j]) $ " reason=" $ Reason);
        }
    }
    O.Slots.Length = 0;
    O.SlotLocs.Length = 0;
    SquadOrders[GroupIdx] = O;
}

function EcholonBot GetFollowerBySlot(int GroupIdx, int SlotIdx)
{
    local int i, FollowerSlot;
    local EcholonBot M;

    if (GroupIdx < 0 || GroupIdx >= Fireteams.Length)
        return None;

    FollowerSlot = 0;
    for (i = 0; i < Fireteams[GroupIdx].Members.Length; i++)
    {
        M = Fireteams[GroupIdx].Members[i];
        if (M == None || M == Fireteams[GroupIdx].Leader)
            continue;
        if (FollowerSlot == SlotIdx)
            return M;
        FollowerSlot++;
    }
    return None;
}

function int GetSquadPhase(EcholonBot B)
{
    local int GroupIdx;

    if (B == None)
        return 0;
    GroupIdx = B.GroupID - 1;
    if (GroupIdx < 0 || GroupIdx >= SquadOrders.Length)
        return 0;
    return SquadOrders[GroupIdx].Phase;
}

function bool IsSquadInObjectivePhase(EcholonBot B)
{
    local int GroupIdx;

    if (B == None)
        return false;

    GroupIdx = B.GroupID - 1;
    if (GroupIdx < 0 || GroupIdx >= SquadOrders.Length)
        return false;

    return (SquadOrders[GroupIdx].Phase == PHASE_ENROUTE) || (SquadOrders[GroupIdx].Phase == PHASE_HOLDING);
}

function vector GetSlotLocation(EcholonBot B)
{
    local int GroupIdx, SlotIdx;

    if (B == None)
        return vect(0, 0, 0);
    GroupIdx = B.GroupID - 1;
    if (GroupIdx < 0 || GroupIdx >= SquadOrders.Length)
        return vect(0, 0, 0);
    SlotIdx = B.FollowSlotIndex;
    if (SlotIdx < 0 || SlotIdx >= SquadOrders[GroupIdx].SlotLocs.Length)
        return vect(0, 0, 0);
    return SquadOrders[GroupIdx].SlotLocs[SlotIdx];
}

function EvaluateSquadPhase()
{
    local SquadOrder O;
    local EcholonBot M;
    local vector GoalLoc;
    local float GoalRadiusSq;
    local float DistSq;
    local bool LeaderInside;
    local bool MemberInside;
    local int i;
    local int MemberIdx;

    if (WorldInfo == None || !bObjectiveActive)
        return;

    GoalRadiusSq = 9216.0;

    for (i = 0; i < SquadOrders.Length; i++)
    {
        if (i >= Fireteams.Length)
            break;

        O = SquadOrders[i];
        if (O.Leader == None || O.Leader.Pawn == None)
            continue;
        if (O.Phase != PHASE_ENROUTE && O.Phase != PHASE_HOLDING)
            continue;

        if (O.Zone != None)
        {
            LeaderInside = O.Zone.Encompasses(O.Leader.Pawn);
        }
        else
        {
            GoalLoc = O.GoalPoint;
            DistSq = VSizeSq(O.Leader.Pawn.Location - GoalLoc);
            LeaderInside = DistSq < GoalRadiusSq;
        }

        MemberInside = false;
        for (MemberIdx = 0; MemberIdx < Fireteams[i].Members.Length; MemberIdx++)
        {
            M = Fireteams[i].Members[MemberIdx];
            if (M == None || M == O.Leader)
                continue;
            if (M.Pawn == None || M.Pawn.Health <= 0)
                continue;
            if (O.Zone != None)
            {
                if (O.Zone.Encompasses(M.Pawn))
                    MemberInside = true;
            }
            else
            {
                if (VSizeSq(M.Pawn.Location - O.GoalPoint) < GoalRadiusSq)
                    MemberInside = true;
            }
        }

        if (O.Phase == PHASE_ENROUTE && LeaderInside && MemberInside)
        {
            O.Phase = PHASE_HOLDING;
            SquadOrders[i] = O;
        }
        else if (O.Phase == PHASE_HOLDING && !LeaderInside)
        {
            O.Phase = PHASE_ENROUTE;
            SquadOrders[i] = O;
        }
    }
}

function bool HasSquadGoal(EcholonBot B)
{
    local int G;

    if (B == None || B.GroupID - 1 < 0 || B.GroupID - 1 >= SquadOrders.Length)
    {
        return false;
    }

    G = B.GroupID - 1;
    return (SquadOrders[G].GoalNav != None && SquadOrders[G].GoalPoint != vect(0, 0, 0));
}

function ReissueSquadOrder(EcholonBot B)
{
    local int G;
    local SquadOrder O;

    if (B == None || B.GroupID - 1 < 0 || B.GroupID - 1 >= SquadOrders.Length)
    {
        return;
    }

    G = B.GroupID - 1;
    O = SquadOrders[G];
    O.ObjectiveBailUntil = 0.0;
    SquadOrders[G] = O;
    SampleSquadSlots(G);
    EchelonLog("ORDER_REISSUE group=" $ string(G + 1) $ " leader=" $ string(B.Name));
}

function Controller FindNearestActiveLeader(EcholonBot B, float MaxDist)
{
    local int i;
    local EcholonBot Cand;
    local EcholonMut.CachedHumanInfo CH;
    local KFPawn_Human CandH;
    local float BestD2, D2;
    local Controller BestCtrl;

    if (B == None || B.Pawn == None)
    {
        return None;
    }
    BestD2 = MaxDist * MaxDist;
    BestCtrl = None;
    for (i = 0; i < Fireteams.Length; i++)
    {
        Cand = Fireteams[i].Leader;
        if (Cand != None && Cand != B && Cand.Pawn != None && Cand.Pawn.Health > 0)
        {
            D2 = VSizeSq(Cand.Pawn.Location - B.Pawn.Location);
            if (D2 < BestD2)
            {
                BestD2 = D2;
                BestCtrl = Cand;
            }
        }
    }
    for (i = 0; i < CachedHumans.Length; i++)
    {
        CH = CachedHumans[i];
        CandH = CH.HumanPawn;
        if (CandH != None && CandH.IsAliveAndWell() && PlayerController(CandH.Controller) != None)
        {
            D2 = VSizeSq(CH.Loc - B.Pawn.Location);
            if (D2 < BestD2)
            {
                BestD2 = D2;
                BestCtrl = CandH.Controller;
            }
        }
    }
    return BestCtrl;
}

function int CountZedsInRadius(vector Origin, float Radius)
{
    local int Count;
    local KFPawn_Monster Zed;

    Count = 0;
    foreach DynamicActors(class'KFPawn_Monster', Zed)
    {
        if (Zed.IsAliveAndWell() && VSizeSq(Zed.Location - Origin) <= Radius * Radius)
        {
            Count++;
        }
    }
    return Count;
}

function EvaluateRegroupEntries()
{
    local int i;
    local SquadOrder O;
    local EcholonBot Leader, NewLeader;
    local bool bLeaderDead, bNoGoal, bIdleNow;
    local float Now;

    if (Fireteams.Length == 0)
        return;
    EnsureSquadOrderTable();
    if (SquadIdleStamp.Length != SquadOrders.Length)
        SquadIdleStamp.Length = SquadOrders.Length;
    Now = WorldInfo.TimeSeconds;

    for (i = 0; i < Fireteams.Length; i++)
    {
        Leader = Fireteams[i].Leader;
        bLeaderDead = (Leader == None || Leader.Pawn == None || Leader.Pawn.Health <= 0);
        if (bLeaderDead)
        {
            if (Fireteams[i].Members.Length > 0)
            {
                NewLeader = FindBestCandidate(Fireteams[i].Members);
                if (NewLeader != None)
                {
                    Fireteams[i].Leader = NewLeader;
                    NewLeader.bIsGroupLeader = true;
                    NewLeader.BotRank = SQUAD_LEADER;
                    NewLeader.ResetStuckState();
                    InheritSquadOrder(i, NewLeader);
                    SampleSquadSlots(i);
                    O = SquadOrders[i];
                    O.Phase = PHASE_REGROUP;
                    O.StartTime = Now;
                    SquadOrders[i] = O;
                    EchelonLog("REGROUP_ENTER squad=" $ string(i + 1) $ " leaderDead newLeader=" $ string(NewLeader.Name));
                    SyncSquadLeaders();
                }
            }
            continue;
        }

        bNoGoal = !HasSquadGoal(Leader);
        bIdleNow = Leader.IsInState('PickNextMove') || Leader.IsInState('Camp') || Leader.IsInState('Roaming');
        if (bNoGoal && bIdleNow && SquadIdleStamp[i] == 0.0)
        {
            SquadIdleStamp[i] = Now;
        }
        else if (!(bNoGoal && bIdleNow))
        {
            SquadIdleStamp[i] = 0.0;
        }
        if (bNoGoal && bIdleNow && SquadIdleStamp[i] > 0.0
            && Now - SquadIdleStamp[i] >= 3.0
            && CountZedsInRadius(Leader.Pawn.Location, REGROUP_SCAN_RADIUS) == 0)
        {
            O = SquadOrders[i];
            O.Phase = PHASE_REGROUP;
            O.StartTime = Now;
            SquadOrders[i] = O;
            SquadIdleStamp[i] = 0.0;
            EchelonLog("REGROUP_ENTER squad=" $ string(i + 1) $ " leaderIdle leader=" $ string(Leader.Name));
        }
    }
}

function float GetSquadStartTime(EcholonBot B)
{
    local int GroupIdx;

    if (B == None)
        return 0.0;
    GroupIdx = B.GroupID - 1;
    if (GroupIdx < 0 || GroupIdx >= SquadOrders.Length)
        return 0.0;
    return SquadOrders[GroupIdx].StartTime;
}

function int MoveSquadMembers(int FromIdx, int ToIdx)
{
    local int MemberIdx;
    local SquadOrder O;
    local EcholonBot M;

    if (FromIdx == ToIdx)
        return 0;
    if (FromIdx < 0 || FromIdx >= Fireteams.Length || ToIdx < 0 || ToIdx >= Fireteams.Length)
        return 0;

    O = SquadOrders[FromIdx];
    O.Phase = PHASE_IDLE;
    SquadOrders[FromIdx] = O;

    // Bug hunt (legacy bug): ReassignBotToGroup removes M from this same Members array, so a forward
    // loop skipped every second bot and left it in the dissolved squad with no leader. Walk backwards.
    for (MemberIdx = Fireteams[FromIdx].Members.Length - 1; MemberIdx >= 0; MemberIdx--)
    {
        M = Fireteams[FromIdx].Members[MemberIdx];
        if (M == None)
            continue;
        ReassignBotToGroup(M, ToIdx);
        M.WdLastHubContactTime = WorldInfo.TimeSeconds;
    }

    Fireteams[FromIdx].Leader = None;
    Fireteams[FromIdx].Anchor = None;

    O = SquadOrders[ToIdx];
    O.Leader = Fireteams[ToIdx].Leader;
    O.StartTime = WorldInfo.TimeSeconds;
    SquadOrders[ToIdx] = O;

    ConsolidateFireteams();
    return Fireteams[ToIdx].Members.Length;
}

final function NavigationPoint GetBotObjective(EcholonBot B)
{
    local int GroupIdx, i;
    local SquadOrder O;
    local float BestDistSq, DistSq;
    local NavigationPoint Best;

    if (!bObjectiveActive)
    {
        // Hunt order (no map objective): the squad's goal is the node nearest the leftover zed.
        if (!bHuntOrderActive || B == None)
        {
            return None;
        }
        EnsureSquadOrderTable();
        GroupIdx = B.GroupID - 1;
        if (GroupIdx >= 0 && GroupIdx < SquadOrders.Length)
        {
            return SquadOrders[GroupIdx].GoalNav;
        }
        return None;
    }
    if (B == None || B.Pawn == None)
    {
        return ValidPoints[Rand(ValidPoints.Length)];
    }

    EnsureSquadOrderTable();
    GroupIdx = B.GroupID - 1;
    if (GroupIdx >= 0 && GroupIdx < SquadOrders.Length)
    {
        O = SquadOrders[GroupIdx];
        if (O.Leader != None && O.GoalNav != None)
        {
            return O.GoalNav;
        }
    }

    Best = None;
    BestDistSq = 9999999999.0;
    for (i = 0; i < SquadOrders.Length; i++)
    {
        O = SquadOrders[i];
        if (O.Leader == None || O.Leader.Pawn == None || O.GoalNav == None)
        {
            continue;
        }
        DistSq = VSizeSq(O.Leader.Pawn.Location - B.Pawn.Location);
        if (DistSq < BestDistSq)
        {
            BestDistSq = DistSq;
            Best = O.GoalNav;
        }
    }
    if (Best != None)
    {
        return Best;
    }
    return ValidPoints[Rand(ValidPoints.Length)];
}

function bool IsNodeBlocked(EcholonBot OwnerBot, NavigationPoint Node)
{
    local int GroupIdx, i;
    local SquadOrder O;
    local float Now;

    if (OwnerBot == None || Node == None)
        return false;

    GroupIdx = OwnerBot.GroupID - 1;
    if (GroupIdx < 0 || GroupIdx >= SquadOrders.Length)
        return false;

    Now = WorldInfo.TimeSeconds;
    O = SquadOrders[GroupIdx];

    for (i = 0; i < O.NodeBlacklist.Length; i++)
    {
        if (O.NodeBlacklist[i].Owner != OwnerBot)
            continue;
        if (O.NodeBlacklist[i].Node != Node.Name)
            continue;
        if (O.NodeBlacklist[i].ExpiresAt > Now)
            return true;
    }

    return false;
}

function AddNodeBlock(EcholonBot OwnerBot, NavigationPoint Node)
{
    local int GroupIdx, i;
    local SquadOrder O;
    local NavNodeBlock B;
    local float Now;

    if (OwnerBot == None || Node == None)
        return;

    GroupIdx = OwnerBot.GroupID - 1;
    if (GroupIdx < 0 || GroupIdx >= SquadOrders.Length)
        return;

    Now = WorldInfo.TimeSeconds;
    O = SquadOrders[GroupIdx];

    for (i = O.NodeBlacklist.Length - 1; i >= 0; i--)
    {
        if (O.NodeBlacklist[i].ExpiresAt <= Now)
        {
            O.NodeBlacklist.Remove(i, 1);
        }
    }

    for (i = 0; i < O.NodeBlacklist.Length; i++)
    {
        if (O.NodeBlacklist[i].Owner == OwnerBot && O.NodeBlacklist[i].Node == Node.Name)
        {
            O.NodeBlacklist[i].ExpiresAt = Now + OBJ_BAIL_COOLDOWN;
            SquadOrders[GroupIdx] = O;
            return;
        }
    }

    B.Node = Node.Name;
    B.Owner = OwnerBot;
    B.ExpiresAt = Now + OBJ_BAIL_COOLDOWN;
    O.NodeBlacklist.AddItem(B);
    SquadOrders[GroupIdx] = O;
}

final function InitTraderList(KFGFxObject_TraderItems L)
{
    local int I;
    local EcholonWeaponInfo A;

    bTraderListInit = true;
    I = L.SaleItems.Length - 1;
    while (I >= 0)
    {
        if (A == None)
        {
            A = new class'EcholonBot.EcholonWeaponInfo';
        }
        if (A.InitInformation(L.SaleItems[I].WeaponDef, L.SaleItems[I].ClassName))
        {
            TraderList.AddItem(A);
            A = None;
        }
        I--;
    }
}

final function EcholonWeaponInfo FindWeaponByClass(Class<KFWeapon> W)
{
    local EcholonWeaponInfo A;
    local int i;

    for (i = 0; i < TraderList.Length; i++)
    {
        A = TraderList[i];
        if (A.WeaponClass == W)
        {
            return A;
        }
    }
    return None;
}

final function RespawnBots()
{
    local EcholonBot B;

    foreach WorldInfo.AllControllers(class'EcholonBot', B)
    {
        B.NextShoppingTime = WorldInfo.TimeSeconds - 1.0;
        if (B.Pawn == None || !B.Pawn.IsAliveAndWell())
        {
            RestartBot(B);
            continue;
        }
        B.PlayerReplicationInfo.Score += 500.0;
    }
}

final function string PickCustomBotName()
{
    local int Idx;
    local string PickedName;

    if (!bUseCustomBotNames || CustomBotNames.Length == 0)
    {
        return "";
    }
    if (AvailableBotNames.Length == 0)
    {
        AvailableBotNames = CustomBotNames;
    }
    Idx = Rand(AvailableBotNames.Length);
    PickedName = AvailableBotNames[Idx];
    AvailableBotNames.Remove(Idx, 1);
    return PickedName;
}

final function InitBotCharacter(EcholonBot Bot)
{
    local byte I, C, lvl;
    local EcholonBot B;
    local KFPlayerReplicationInfo PRI;
    local KFCharacterInfo_Human H;
    local string BotName;

    lvl = byte(BotMinPerkLv + Rand((BotMaxPerkLv - BotMinPerkLv) + 1));
    Bot.CurrentLevel = lvl;
    PRI = KFPlayerReplicationInfo(Bot.PlayerReplicationInfo);

    if((PRI == None) || (PRI.CharacterArchetypes.Length == 0))
    {
        Bot.CharacterArch = None;
    }
    else
    {
        I = byte(Rand(PRI.CharacterArchetypes.Length));
        H = PRI.CharacterArchetypes[I];

        C = 0;
        while((H == None || H.SoundGroupArch == None) && C < PRI.CharacterArchetypes.Length)
        {
            I = byte((I + 1) % PRI.CharacterArchetypes.Length);
            H = PRI.CharacterArchetypes[I];
            C++;
        }

        if(H == None || H.SoundGroupArch == None)
        {
            I = 0;
            H = PRI.CharacterArchetypes[0];
        }

        if(PRI.CharacterArchetypes.Length > 1)
        {
            C = 0;
            while(C < 4)
            {
                B = None;
                // SDK-UNVERIFIED: WorldInfo.AllControllers
                foreach WorldInfo.AllControllers(class'EcholonBot', B)
                {
                    if((B != None) && (B != Bot) && (B.CharacterArch == H))
                    {
                        break;
                    }
                    B = None;
                }
                if(B == None)
                {
                    break;
                }
                I = byte((I + 1) % PRI.CharacterArchetypes.Length);
                H = PRI.CharacterArchetypes[I];
                C++;
            }
        }
        Bot.CharacterArch = H;
    }

    BotName = PickCustomBotName();
    if(BotName == "")
    {
        if(Bot.CharacterArch != None)
        {
            BotName = string(Bot.CharacterArch.Name);
        }
        else
        {
            BotName = "Horzine_Bot";
        }
    }

    if(bShowBotLevel)
    {
        BotName = ("[Lv" $ string(lvl) $ "] ") $ BotName;
    }
    if(bShowBotRole)
    {
        BotName = ("[" $ Bot.GetRankName() $ "] ") $ BotName;
    }
    if(PRI != None)
    {
        PRI.SetPlayerName(BotName);
    }
}

final function Class<KFPerk> PickFallbackPerk()
{
    local Class<KFPerk> P;
    local int Idx;

    while (true)
    {
        Idx = Rand(Class'KFGame.KFPlayerController'.default.PerkList.Length);
        P = Class'KFGame.KFPlayerController'.default.PerkList[Idx].PerkClass;
        if (!bNoZerkerBots || P != Class'KFGame.KFPerk_Berserker')
        {
            break;
        }
    }
    return P;
}

final function Class<KFPerk> ResolvePerkByName(string PerkName)
{
    local int I;

    I = 0;
    while (I < Class'KFGame.KFPlayerController'.default.PerkList.Length)
    {
        if (string(Class'KFGame.KFPlayerController'.default.PerkList[I].PerkClass.Name) ~= PerkName)
        {
            return Class'KFGame.KFPlayerController'.default.PerkList[I].PerkClass;
        }
        I++;
    }
    return None;
}

final function ResetPerkPool()
{
    local int I;
    local Class<KFPerk> P;

    PerkPool.Length = 0;
    PerkPoolCounts.Length = 0;
    for (I = 0; I < AllowedPerks.Length; I++)
    {
        P = ResolvePerkByName(AllowedPerks[I]);
        if ((P != None) && (!bNoZerkerBots || P != Class'KFGame.KFPerk_Berserker'))
        {
            PerkPool.AddItem(P);
            PerkPoolCounts.AddItem(0);
        }
    }
}

final function Class<KFPerk> PickBotPerk()
{
    local int Idx;
    local Class<KFPerk> Picked;

    if (AllowedPerks.Length == 0)
    {
        return PickFallbackPerk();
    }
    if (PerkPool.Length == 0)
    {
        ResetPerkPool();
    }
    if (PerkPool.Length == 0)
    {
        return PickFallbackPerk();
    }
    Idx = Rand(PerkPool.Length);
    Picked = PerkPool[Idx];
    if (MaxBotsPerPerk > 0)
    {
        ++PerkPoolCounts[Idx];
        if (PerkPoolCounts[Idx] >= MaxBotsPerPerk)
        {
            PerkPool.Remove(Idx, 1);
            PerkPoolCounts.Remove(Idx, 1);
        }
    }
    return Picked;
}

final function int AvatarPort()
{
    if (AvatarServerPort > 0)
    {
        return AvatarServerPort;
    }
    return 8765;
}

// Give the bot a fake net id (high word zero, so it never matches a real Steam account) and ask the
// local avatar server for its picture. The scoreboard shows the KF2 logo until the download is done.
final function AvatarRequest(PlayerReplicationInfo PRI)
{
    local KFHTTPImageDownloader DL;
    local bool bStarted;

    if (WorldInfo.NetMode != NM_Standalone || !bBotAvatars || AvatarMatchId <= 0 || PRI == None)
    {
        return;
    }

    PRI.UniqueId.Uid.A = 0;
    PRI.UniqueId.Uid.B = 0x0EC00000 + PRI.PlayerID;
    AvatarSetEntry(PRI.UniqueId, None);

    DL = new(self) class'KFHTTPImageDownloader';
    AvatarDL.AddItem(DL);
    AvatarPRI.AddItem(PRI);
    AvatarApplied.AddItem(false);

    bStarted = DL.DownloadImageFromURL("http://127.0.0.1:" $ string(AvatarPort()) $ "/avatar/" $ string(AvatarMatchId) $ "/" $ string(PRI.PlayerID) $ ".png", AvatarDownloadDone);
    EchelonLog("AVATAR_REQUEST pid=" $ string(PRI.PlayerID) $ " started=" $ string(bStarted));
    if (!bStarted)
    {
        EchelonLog("AVATAR_FAIL pid=" $ string(PRI.PlayerID) $ " reason=start");
    }
}

// No early exit: every entry with this id is updated.
final function AvatarSetEntry(UniqueNetId Id, Texture2D Tex)
{
    local KFPlayerController PC;
    local KFPlayerController.PlayerSteamAvatar Entry;
    local int I;
    local bool bFound;

    PC = KFPlayerController(GetALocalPlayerController());
    if (PC == None)
    {
        return;
    }

    for (I = 0; I < PC.AvatarList.Length; ++I)
    {
        if (PC.AvatarList[I].NetID == Id)
        {
            PC.AvatarList[I].Avatar = Tex;
            bFound = true;
        }
    }
    if (!bFound)
    {
        Entry.NetID = Id;
        Entry.Avatar = Tex;
        PC.AvatarList.AddItem(Entry);
    }
}

// The download delegate does not say which downloader finished, so every pending one is checked.
// Downloaders stay in AvatarDL for the whole match so their textures are not garbage-collected.
function AvatarDownloadDone(bool bWasSuccessful)
{
    local int I;

    for (I = 0; I < AvatarDL.Length; ++I)
    {
        if (AvatarApplied[I] || AvatarDL[I] == None || AvatarPRI[I] == None)
        {
            continue;
        }
        if (AvatarDL[I].TheTexture == None)
        {
            continue;
        }
        AvatarSetEntry(AvatarPRI[I].UniqueId, AvatarDL[I].TheTexture);
        AvatarApplied[I] = true;
        EchelonLog("AVATAR_SET pid=" $ string(AvatarPRI[I].PlayerID) $ " tex=" $ PathName(AvatarDL[I].TheTexture));
    }
    if (!bWasSuccessful)
    {
        EchelonLog("AVATAR_FAIL reason=download");
    }
}

final function bool AddBot()
{
    local EcholonBot B;
    local KFPlayerReplicationInfo PRI;
    local NavigationPoint PS;

    PS = KF.FindPlayerStart(None, 0);
    if (PS == None)
    {
        return false;
    }

    B = Spawn(class'EcholonBot',,, PS.Location);
    if (B == None)
    {
        return false;
    }

    B.Perk = PickBotPerk();

    PRI = KFPlayerReplicationInfo(B.PlayerReplicationInfo);
    if (PRI != None)
    {
        PRI.CurrentPerkClass = B.Perk;
        PRI.PlayerID = KF.GetNextPlayerID();
        AvatarRequest(PRI);
    }

    KF.GenericPlayerInitialization(B);
    RestartBot(B);

    if (PRI != None)
    {
        PRI.Score = float(KF.DifficultyInfo.GetAdjustedStartingCash());
    }

    KF.bOnePlayerAtStart = false;
    KF.ForceLivingPlayerCount(byte(KF.NumPlayers + KF.NumBots));
    return true;
}

final function RemoveBot()
{
    local EcholonBot B, Best;
    local float Score, BestScore;

    BestScore = 0.0;
    Best = None;
    foreach WorldInfo.AllControllers(class'EcholonBot', B)
    {
        Score = (100.0 * FRand()) + (B.PlayerReplicationInfo.Score * 0.25);
        if (B.Pawn == None || !B.Pawn.IsAliveAndWell())
        {
            Score -= 500.0;
        }
        else
        {
            Score += float(B.Pawn.Health);
        }
        if (Best == None || Score < BestScore)
        {
            BestScore = Score;
            Best = B;
        }
    }
    if (Best != None)
    {
        Best.Destroy();
    }
}

final function RestartBot(EcholonBot NewPlayer, optional NavigationPoint StartSpot)
{
    local int TeamNum, Idx;
    local array<SequenceObject> Events;
    local SeqEvent_PlayerSpawned SpawnedEvent;

    TeamNum = 0;

    if((KF.bRestartLevel && WorldInfo.NetMode != NM_DedicatedServer) && WorldInfo.NetMode != NM_ListenServer)
    {
        WarnInternal("bRestartLevel && !server, abort from RestartPlayer" @ string(WorldInfo.NetMode));
        return;
    }

    if(StartSpot == None)
    {
        StartSpot = KF.FindPlayerStart(NewPlayer, byte(TeamNum));
    }

    if(StartSpot == None)
    {
        if(NewPlayer.StartSpot != None)
        {
            StartSpot = NewPlayer.StartSpot;
            WarnInternal("Player start not found, using last start spot");
        }
        else
        {
            WarnInternal("Player start not found, failed to restart player");
            return;
        }
    }

    if(NewPlayer.Pawn == None)
    {
        NewPlayer.Pawn = KF.SpawnDefaultPawnFor(NewPlayer, StartSpot);
    }

    if(NewPlayer.Pawn == None)
    {
        EchelonLog("SPAWN_FAIL start=" $ string(StartSpot));
        NewPlayer.GotoState('Dead');
    }
    else
    {
        NewPlayer.Pawn.SetAnchor(StartSpot);
        NewPlayer.Pawn.LastStartSpot = PlayerStart(StartSpot);
        NewPlayer.Pawn.LastStartTime = WorldInfo.TimeSeconds;
        NewPlayer.Possess(NewPlayer.Pawn, false);
        NewPlayer.Pawn.PlayTeleportEffect(true, true);
        NewPlayer.ClientSetRotation(NewPlayer.Pawn.Rotation, true);

        if(!WorldInfo.bNoDefaultInventoryForPlayer)
        {
            KF.AddDefaultInventory(NewPlayer.Pawn);
        }
        KF.SetPlayerDefaults(NewPlayer.Pawn);

        if(KFPawn(NewPlayer.Pawn) != None)
        {
            KFPawn(NewPlayer.Pawn).bIgnoreTeamCollision = KF.bDisableTeamCollision;
        }

        if(WorldInfo.GetGameSequence() != None)
        {
            WorldInfo.GetGameSequence().FindSeqObjectsByClass(Class'Engine.SeqEvent_PlayerSpawned', true, Events);
            Idx = 0;
            while(Idx < Events.Length)
            {
                SpawnedEvent = SeqEvent_PlayerSpawned(Events[Idx]);
                if((SpawnedEvent != None) && SpawnedEvent.CheckActivate(NewPlayer, NewPlayer))
                {
                    SpawnedEvent.SpawnPoint = StartSpot;
                    SpawnedEvent.PopulateLinkedVariableValues();
                }
                Idx++;
            }
        }

        KF.SetTeam(NewPlayer, KF.Teams[0]);

        // SetCharacterArch MUST follow SetTeam: SetTeam fires NotifyTeamChanged
        // which internally calls SetCharacterArch(GetCharacterInfo()) and would
        // snap the bot back to the default arch (Mr. Foster, index 0).
        if((KFPawn(NewPlayer.Pawn) != None) && (NewPlayer.CharacterArch != None))
        {
            KFPawn(NewPlayer.Pawn).SetCharacterArch(NewPlayer.CharacterArch, true);
        }

        if(KFPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo) != None)
        {
            KFPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo).PlayerHealthPercent = FloatToByte(float(NewPlayer.Pawn.Health) / float(NewPlayer.Pawn.HealthMax));
            KFPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo).PlayerHealth = NewPlayer.Pawn.Health;
            NewPlayer.PlayerReplicationInfo.Score = float(Max(int(NewPlayer.PlayerReplicationInfo.Score), KF.DifficultyInfo.GetAdjustedRespawnCash()));
        }
    }
}

static final function DebugMessage(string msg)
{
    local PlayerController P;

    msg = "[BOT]" @ msg;
    foreach Class'Engine.WorldInfo'.static.GetWorldInfo().AllControllers(Class'Engine.PlayerController', P)
    {
        P.ClientMessage(msg);
    }
}

final function PMsg(PlayerController Other, string msg)
{
    Other.TeamMessage(Other.PlayerReplicationInfo, msg, 'Event');

    if (LocalPlayer(Other.Player) != None)
    {
        LocalPlayer(Other.Player).ViewportClient.ViewportConsole.OutputText(msg);
    }
}

final function DebugAI(PlayerController Sender)
{
    local EcholonBot B, Best;
    local float Score, BestScore;
    local Vector V;

    V = Sender.ViewTarget.Location;

    foreach WorldInfo.AllControllers(class'EcholonBot', B)
    {
        if (B.Pawn == None)
        {
            continue;
        }
        Score = VSizeSq(B.Pawn.Location - V);
        if (Best == None || Score < BestScore)
        {
            Best = B;
            BestScore = Score;
        }
    }

    if (Best != None)
    {
        Sender.ClientMessage(Best.GetHumanReadableName() $ ": " $ Best.GetAIInfo());
    }
}

function Mutate(string MutateString, PlayerController Sender)
{
    if (MutateString ~= "AI")
    {
        DebugAI(Sender);
    }
    else if ((WorldInfo.NetMode == NM_Standalone) || Sender.PlayerReplicationInfo.bAdmin)
    {
        if (MutateString ~= "Help")
        {
            PMsg(Sender, "EcholonBot commands:");
            PMsg(Sender, ("-SetNumBots <" $ string(NumBots)) $ "> = Set bot count (subtracted by playercount)");
            PMsg(Sender, ("-SetMinBots <" $ string(MinimumBots)) $ "> = Change the minimum bot count");
            PMsg(Sender, ("-SetBotMinLv <" $ string(BotMinPerkLv)) $ "> = Set bots min perk level");
            PMsg(Sender, ("-SetBotMaxLv <" $ string(BotMaxPerkLv)) $ "> = Set bots max perk level");
            PMsg(Sender, ("-SetBotChat <" $ string(Class'EcholonBot.EcholonChat'.default.bBotsChat)) $ "> = Enable bot chatting");
            PMsg(Sender, "-BotTalk = Make bots say one preset line if enabled");
            PMsg(Sender, ("-SetScaleZedCount <" $ string(ZedCountScaling)) $ "> = Set by how much should bots scale zed count");
            PMsg(Sender, ("-SetNoZerker <" $ string(bNoZerkerBots)) $ "> = New bots should never spawn as berserker");
            PMsg(Sender, ("-SetBotsInfAmmo <" $ string(bBotsUnlimitedAmmo)) $ "> = Bots have unlimited ammo");
            PMsg(Sender, ("-SetBotDamageScale <" $ string(BotsDamageScale)) $ "> = Damage scaling bots should take");
            PMsg(Sender, ("-SetBotInfDosh <" $ string(bBotsUnlimitedCash)) $ "> = Bots have unlimited spending cash");
            PMsg(Sender, ("-SetUseCustomNames <" $ string(bUseCustomBotNames)) $ "> = Use CustomBotNames instead of look-based names");
            PMsg(Sender, ("-SetBotsLevel <" $ string(bShowBotLevel)) $ "> = Show [Lv X] prefix on bot names");
            PMsg(Sender, ("-SetBotRole <" $ string(bShowBotRole)) $ "> = Show [Role] prefix on bot names");
            PMsg(Sender, ("-SetBotAvatars <" $ string(bBotAvatars)) $ "> = Bots get scoreboard pictures from the local avatar server");
        }
        else if (Left(MutateString, 11) ~= "SetNumBots ")
        {
            NumBots = byte(int(Mid(MutateString, 11)));
            SaveConfig();
            PMsg(Sender, "Number of bots count changed to: " $ string(NumBots));
        }
        else if (Left(MutateString, 11) ~= "SetMinBots ")
        {
            MinimumBots = byte(int(Mid(MutateString, 11)));
            SaveConfig();
            PMsg(Sender, "Minimum amount of bots set to: " $ string(MinimumBots));
        }
        else if (Left(MutateString, 12) ~= "SetBotMinLv ")
        {
            BotMinPerkLv = int(Mid(MutateString, 12));
            SaveConfig();
            PMsg(Sender, "Set bots minimum perk level to: " $ string(BotMinPerkLv));
        }
        else if (Left(MutateString, 12) ~= "SetBotMaxLv ")
        {
            BotMaxPerkLv = int(Mid(MutateString, 12));
            SaveConfig();
            PMsg(Sender, "Set bots maximum perk level to: " $ string(BotMaxPerkLv));
        }
        else if (Left(MutateString, 17) ~= "SetScaleZedCount ")
        {
            ZedCountScaling = float(Mid(MutateString, 17));
            SaveConfig();
            PMsg(Sender, "Bots scale the number of zeds: X " $ string(ZedCountScaling));
        }
        else if (Left(MutateString, 12) ~= "SetNoZerker ")
        {
            bNoZerkerBots = bool(Mid(MutateString, 12));
            SaveConfig();
            PMsg(Sender, "Bots should never spawn as berserker: " $ string(bNoZerkerBots));
        }
        else if (Left(MutateString, 15) ~= "SetBotsInfAmmo ")
        {
            bBotsUnlimitedAmmo = bool(Mid(MutateString, 15));
            SaveConfig();
            PMsg(Sender, "Bots have infinite ammo: " $ string(bBotsUnlimitedAmmo));
        }
        else if (Left(MutateString, 14) ~= "SetBotInfDosh ")
        {
            bBotsUnlimitedCash = bool(Mid(MutateString, 14));
            SaveConfig();
            PMsg(Sender, "Bots have infinite dosh: " $ string(bBotsUnlimitedCash));
        }
        else if (Left(MutateString, 18) ~= "SetUseCustomNames ")
        {
            bUseCustomBotNames = bool(Mid(MutateString, 18));
            SaveConfig();
            PMsg(Sender, "Bots use custom name pool: " $ string(bUseCustomBotNames));
        }
        else if (Left(MutateString, 13) ~= "SetBotsLevel ")
        {
            bShowBotLevel = bool(Mid(MutateString, 13));
            SaveConfig();
            PMsg(Sender, "Bots show [Lv X] name prefix: " $ string(bShowBotLevel));
        }
        else if (Left(MutateString, 14) ~= "SetBotAvatars ")
        {
            bBotAvatars = bool(Mid(MutateString, 14));
            SaveConfig();
            PMsg(Sender, "Bots get avatar server pictures (new bots only): " $ string(bBotAvatars));
        }
        else if (Left(MutateString, 11) ~= "SetBotRole ")
        {
            bShowBotRole = bool(Mid(MutateString, 11));
            SaveConfig();
            PMsg(Sender, "Bots show [Role] name prefix: " $ string(bShowBotRole));
        }
        else if (Left(MutateString, 18) ~= "SetBotDamageScale ")
        {
            BotsDamageScale = float(Mid(MutateString, 18));
            SaveConfig();
            PMsg(Sender, "Bots new damage scaling: " $ string(BotsDamageScale));
        }
        else if (Left(MutateString, 11) ~= "SetBotChat ")
        {
            if (ActiveChat != None)
            {
                ActiveChat.bBotsChat = bool(Mid(MutateString, 11));
                ActiveChat.SaveConfig();
            }
            else
            {
                Class'EcholonBot.EcholonChat'.default.bBotsChat = bool(Mid(MutateString, 11));
                Class'EcholonBot.EcholonChat'.static.StaticSaveConfig();
            }
            PMsg(Sender, "Set bots chatting: " $ string(Class'EcholonBot.EcholonChat'.default.bBotsChat));
        }
        else if (MutateString ~= "BotTalk")
        {
            if (ActiveChat != None)
            {
                ActiveChat.BotChatterTimer();
            }
            else
            {
                PMsg(Sender, "Bot chat disabled.");
            }
        }
    }
    if (NextMutator != None)
    {
        NextMutator.Mutate(MutateString, Sender);
    }
}

function NetDamage(int OriginalDamage, out int Damage, Pawn injured, Controller InstigatedBy, Vector HitLocation, out Vector Momentum, Class<DamageType> DamageType, Actor DamageCauser)
{
    if ((Damage > 0) && (EcholonBot(injured.Controller) != None))
    {
        if (((InstigatedBy != None) && (InstigatedBy != injured.Controller)) && (injured.GetTeamNum() == InstigatedBy.GetTeamNum()))
        {
            Damage = 0;
            Momentum *= 0.25;
        }
        else
        {
            Damage *= BotsDamageScale;
        }
    }
    if (NextMutator != None)
    {
        NextMutator.NetDamage(OriginalDamage, Damage, injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);
    }
}

final function InitEmotes()
{
    local array<Emote> EA;

    EA = Class'KFGame.KFEmoteList'.static.GetEmoteArray();
    MaxEmoteCount = EA.Length;
}

final function byte PickRandEmote()
{
	if (MaxEmoteCount == -1)
	{
		InitEmotes();
	}
	return byte(Rand(MaxEmoteCount));
}

final function bool ShouldDoVictoryDance()
{
    if (NextVictoryDance > WorldInfo.TimeSeconds)
    {
        return false;
    }
    NextVictoryDance = WorldInfo.TimeSeconds + 5.0;
    return true;
}

function CacheHumans()
{
    CacheHumanPositions();
}

function CacheHumanPositions()
{
    local KFPawn_Human H;
    local CachedHumanInfo Info;
    local PlayerController PC;

    CachedHumans.Length = 0;
    foreach WorldInfo.AllPawns(class'KFPawn_Human', H)
    {
        if (H.IsAliveAndWell())
        {
            PC = PlayerController(H.Controller);
            if (PC != None)
            {
                Info.HumanPawn = H;
                Info.Loc = H.Location;
                Info.Vel = H.Velocity;
                CachedHumans.AddItem(Info);
            }
        }
    }
}

function vector GetObjectiveLocation()
{
    if (bObjectiveActive && PrevObjective != None)
    {
        return PrevObjective.Location;
    }
    if (HoldVolume != None)
    {
        return HoldVolume.Location;
    }
    return vect(0,0,0);
}

function SetupSquadSpawns(int NumSquads)
{
    local int i, j, NumFactories, NumAssigned;
    local array<KFPickupFactory> AmmoFactories;
    local KFPickupFactory Temp;
    local NavigationPoint PS;

    if (NumSquads <= 0)
    {
        return;
    }

    for (i = 0; i < KF.AllPickupFactories.Length; i++)
    {
        if (KFPickupFactory_Ammo(KF.AllPickupFactories[i]) != None)
        {
            AmmoFactories.AddItem(KF.AllPickupFactories[i]);
        }
    }
    NumFactories = AmmoFactories.Length;
    NumAssigned = Min(NumFactories, NumSquads);

    for (i = 0; i < NumAssigned; i++)
    {
        j = i + Rand(NumFactories - i);
        Temp = AmmoFactories[i];
        AmmoFactories[i] = AmmoFactories[j];
        AmmoFactories[j] = Temp;
        SpawnSquadAt(AmmoFactories[i].Location, i);
    }

    for (i = NumAssigned; i < NumSquads; i++)
    {
        PS = KF.FindPlayerStart(None, 0);
        if (PS != None)
        {
            SpawnSquadAt(PS.Location, i);
        }
        else if (NumAssigned > 0)
        {
            SpawnSquadAt(AmmoFactories[0].Location, i);
        }
    }

    HideAllPickups();
}

// Puts each bot (all of them at match start, later only bots that just spawned) alone on a random ammo
// crate. At most RELOCATE_MAX_PER_CRATE people share a crate, humans standing there included; when every
// crate is full the least crowded one is used. The spot is a random point 60-120 units from the crate that
// the crate can see (not behind a wall), the crate itself as the fallback.
function RelocateBotsToAmmoCrates()
{
    local int i, j, Tries, NumFactories, Pick, Best;
    local array<KFPickupFactory> AmmoFactories;
    local array<int> Occupancy;
    local KFPawn_Human H;
    local EcholonBot Bot;
    local vector AnchorPos, Spot;

    if (ActiveBots.Length == 0)
        return;

    for (i = 0; i < KF.AllPickupFactories.Length; i++)
    {
        if (KFPickupFactory_Ammo(KF.AllPickupFactories[i]) != None)
        {
            AmmoFactories.AddItem(KF.AllPickupFactories[i]);
        }
    }
    NumFactories = AmmoFactories.Length;
    if (NumFactories == 0)
        return;

    // Humans already standing at a crate (the player start can be next to one) take places first.
    Occupancy.Length = NumFactories;
    foreach WorldInfo.AllPawns(class'KFPawn_Human', H)
    {
        if (H.IsHumanControlled() && H.IsAliveAndWell())
        {
            for (i = 0; i < NumFactories; i++)
            {
                if (VSizeSq(H.Location - AmmoFactories[i].Location) < RELOCATE_HUMAN_RADIUS_SQ)
                    Occupancy[i]++;
            }
        }
    }

    for (j = 0; j < ActiveBots.Length; j++)
    {
        Bot = ActiveBots[j];
        if (Bot == None || Bot.Pawn == None)
            continue;
        if (!Bot.bJustSpawned && !bForceRelocate)
            continue;

        // Random crate with a free place; the least crowded one when all are full.
        Pick = -1;
        for (Tries = 0; Tries < 12 && Pick < 0; Tries++)
        {
            i = Rand(NumFactories);
            if (Occupancy[i] < RELOCATE_MAX_PER_CRATE)
                Pick = i;
        }
        if (Pick < 0)
        {
            Best = 999;
            for (i = 0; i < NumFactories; i++)
            {
                if (Occupancy[i] < Best)
                {
                    Best = Occupancy[i];
                    Pick = i;
                }
            }
        }
        Occupancy[Pick]++;

        AnchorPos = AmmoFactories[Pick].Location;
        Spot = PickRelocateSpot(AnchorPos, Bot.Pawn);
        Bot.Pawn.SetLocation(Spot);
        EchelonLog("SPAWN_SPREAD bot=" $ Bot.Name $ " crate=" $ string(Pick) $ " occupancy=" $ string(Occupancy[Pick]));
    }
}

function SpawnSquadAt(vector AnchorPos, int SquadIndex)
{
    local int i;
    local vector GruntPos;

    SpawnBotWithRank(SQUAD_LEADER, PickSquadSpawnPoint(AnchorPos, 60.0, 90.0));

    for (i = 0; i < 3; i++)
    {
        GruntPos = PickSquadSpawnPoint(AnchorPos, 90.0, 150.0);
        SpawnBotWithRank(GRUNT, GruntPos);
    }
}

function bool RelocateSpotOk(vector Spot, Pawn P)
{
    local vector HitLoc, HitNorm, FloorLoc, Probe, Ext, FloorTop;
    local float H, R;
    local NavigationPoint N;

    if (P == None)
    {
        return false;
    }

    if (Trace(HitLoc, HitNorm, Spot - vect(0,0,160), Spot + vect(0,0,32), false) == None)
    {
        EchelonLog("SPAWN_SPOT_REJECT reason=floor");
        return false;
    }
    FloorLoc = HitLoc;

    H = P.GetCollisionHeight();
    R = P.GetCollisionRadius();
    Probe = FloorLoc;
    Probe.Z += H + 4.0;
    Ext.X = R;
    Ext.Y = R;
    Ext.Z = H;
    if (Trace(HitLoc, HitNorm, Probe + vect(0,0,2), Probe, true, Ext) != None)
    {
        EchelonLog("SPAWN_SPOT_REJECT reason=clearance");
        return false;
    }

    FloorTop = FloorLoc + vect(0,0,32);
    foreach WorldInfo.RadiusNavigationPoints(class'NavigationPoint', N, FloorLoc, 400.0)
    {
        if (FastTrace(N.Location, FloorTop) && Abs(N.Location.Z - FloorLoc.Z) <= 128.0)
        {
            return true;
        }
    }

    EchelonLog("SPAWN_SPOT_REJECT reason=nav");
    return false;
}

function vector PickRelocateSpot(vector AnchorPos, Pawn P)
{
    local int Tries;
    local vector Spot;
    local NavigationPoint N;
    local PathNode BestNode;
    local float BestDistSq;
    local float DistSq;

    for (Tries = 0; Tries < 8; Tries++)
    {
        Spot = PickSquadSpawnPoint(AnchorPos, 80.0, 160.0);
        if (FastTrace(Spot + vect(0,0,40), AnchorPos + vect(0,0,40)) && RelocateSpotOk(Spot, P))
        {
            EchelonLog("SPAWN_SPOT result=ok tries=" $ string(Tries + 1));
            return Spot;
        }
    }

    BestNode = None;
    BestDistSq = 999999999.0;
    foreach WorldInfo.RadiusNavigationPoints(class'NavigationPoint', N, AnchorPos, 300.0)
    {
        if (PathNode(N) == None)
            continue;
        DistSq = VSizeSq(N.Location - AnchorPos);
        if (DistSq < BestDistSq)
        {
            BestDistSq = DistSq;
            BestNode = PathNode(N);
        }
    }

    EchelonLog("SPAWN_SPOT result=fallback");
    if (BestNode != None)
        Spot = BestNode.Location;
        Spot.Z += P.GetCollisionHeight();
        return Spot;
    return AnchorPos;
}

function vector PickSquadSpawnPoint(vector AnchorPos, float MinR, float MaxR)
{
    local float R, Ang;
    local vector P;

    R = MinR + FRand() * (MaxR - MinR);
    Ang = FRand() * 360.0;
    P = AnchorPos;
    P.X += Cos(Ang * 0.0174533) * R;
    P.Y += Sin(Ang * 0.0174533) * R;
    return P;
}

function EcholonBot SpawnBotWithRank(EBotRank Rank, vector SpawnPos)
{
    local EcholonBot B;

    B = Spawn(class'EcholonBot', Self, '', SpawnPos, rot(0,0,0));
    if (B != None)
    {
        B.BotRank = Rank;
        RegisterBot(B);
    }
    return B;
}

function HideAllPickups()
{
    local int i;

    for (i = 0; i < KF.AllPickupFactories.Length; i++)
    {
        KF.AllPickupFactories[i].bPickupHidden = true;
    }
    SetTimer(10.0, false, 'ReEnableAmmoFactories');
}

function ReEnableAmmoFactories()
{
    local int i;

    for (i = 0; i < KF.AllPickupFactories.Length; i++)
    {
        KF.AllPickupFactories[i].bPickupHidden = false;
    }
}

defaultproperties
{
    MaxEmoteCount=-1
}
