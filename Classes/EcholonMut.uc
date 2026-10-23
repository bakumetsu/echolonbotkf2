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

struct SquadDeal
{
    var int Role;
    var NavigationPoint LeaderNav;
    var vector LeaderSpot;
    var array<vector> FollowerSpots;
    var int Shortage;
};
struct SquadOrder { var int SquadID; var EcholonBot Leader; var KFMapObjective_DoshHold Zone; var vector GoalPoint; var NavigationPoint GoalNav; var array<int> Slots; var int Phase; var float StartTime; var float ObjectiveBailUntil; var array<NavNodeBlock> NodeBlacklist; var array<vector> SlotLocs; var float SquadSeedAngle; var int Role; };

struct PromotionRequest { var EcholonBot DeadOfficer; var EcholonBot Replacement; var EBotRank OldRank; var float Score; };

struct CachedHumanInfo { var KFPawn_Human HumanPawn; var vector Loc; var vector Vel; };

var transient array<EcholonWeaponInfo> TraderList;
var transient EcholonNavMeter NavMeter;       // nav cost counter, shared by all bots (N6)
var transient EcholonNavBudget NavBudget;     // per-frame nav budget, shared by all bots (N7)
var transient EcholonNavScan NavScan;         // start-of-match link scan state and bad links (N8)
var transient EcholonNavDump NavDump;         // start-of-match node and link dump for the kit's map viewer (bNavTrace)
var() config bool bNavTrace;                  // log the map's path network (NAVDUMP_ lines) at match start; off by default
// Survey mode (?Survey=1 on the map URL): no zeds, survey bots explore the map blind and record a tile map.
var transient bool bSurvey;
var transient EcholonSurveyGrid SurveyGrid;          // the shared tile map
var transient array<EcholonSurveyBot> SurveyBotList; // all survey bots
var transient array<PhysicsVolume> SurveyHazards;    // pain and water volumes, boxes used for the hazard flag
var transient int SurveyTraceLeft;                   // traces the survey bots may still run this frame
var transient int SurveyBfsLeft;                     // search nodes the survey bots may still expand this frame
var transient int SurveyScanLeft;                    // grid slots the bots may still read this frame (far-frontier scans)
var transient float SurveyDropMax;                   // deepest drop (uu) the bots take; lowered when a fall hurts
var transient float SurveyStepMax;                   // the pawn's own step height (MaxStepHeight), 35 until read
var transient float SurveyGravityZ;                  // pawn gravity (positive uu/s^2), read at survey start
var transient float SurveyMaxFall;                   // pawn MaxFallSpeed: a landing faster than this hurts
var transient float SurveyJumpReach;                 // highest ledge a jump can reach: (apex x jumps allowed + step) x 0.9
var transient EcholonSurveyLeads SurveyLeads;        // pass 2 lead list
var transient bool bPass2Allowed;                    // ?SurveyPass2=0 turns pass 2 off
var transient bool bPass2Active;                     // pass 1 stalled, bots now try the designer's links
var transient bool bSurveyPass2Req;                  // mutate SurveyPass2, or ?SurveyPass1Mins= passed: start pass 2 now
var transient int SurveyPass1Mins;                   // ?SurveyPass1Mins=N: pass 2 starts after N minutes whatever pass 1 is doing (0 = when it stalls)
var transient int SurveyPass2Tiles0;                 // grid size when pass 2 began (for the gain)
var transient int SurveyPassageTiles;                // wall tiles turned into narrow floor by a walked lead
var transient array<int> SurveyLevelDeaths;          // survey bot deaths per floor level (index level + 32); 3 bans the level for transfers
var transient int SurveyDropLogs;                    // SURVEY_DROP lines written so far (capped)
var transient int SurveyFrontScan;                   // shared far-frontier scan: cursor over the grid's slots
var transient array<int> SurveyFrontBuild;           // ... unexpanded floor tile keys found so far in this pass
var transient array<int> SurveyFrontList;            // ... the list of the last finished pass; idle bots pick from it
var transient float SurveyFrontNextAt;               // next pass starts at this time (one a second)
var transient array<byte> SurveyRowMark;             // export: 1 for each (level, row) that holds a tile
var transient int SurveyExpSlot;                     // export phase 0 cursor over the grid's slots
var transient int SurveyExpPhase;                    // 0 = find the rows with tiles, 1 = write them
var transient int SurveyCostFrames;                  // SURVEY_COST accumulators (reset every 30 s)
var transient float SurveyCostDt;
var transient float SurveyCostDtMax;
var transient int SurveyCostTraces;
var transient int SurveyCostBfs;
var transient int SurveyCostScan;
var transient float SurveyUnitTraceUs;              // unit costs measured once at survey start (SurveyBenchmark), microseconds
var transient float SurveyUnitFindUs;                // one grid lookup
var transient float SurveyUnitSlotUs;                // one hash slot read
var transient float SurveyCostEst;                   // sum of the estimated survey cost per frame (us) in this window
var transient float SurveyCostEstMax;
var transient int SurveyCostOver;                    // frames whose estimate was above 4000 us
var() config int SurveyBots;                         // survey bot count (0 or less = 4); ?SurveyBots=N overrides for one match
var() config int SurveyMinutes;                      // time limit of a survey (0 or less = 60); ?SurveyMinutes=N overrides
var() config int SurveyTraces;                       // traces per frame for all survey bots together (0 or less = 120)
var() config int SurveyBfsNodes;                     // search nodes per frame for all survey bots together (0 or less = 400)
var transient int SurveyBotsNow;                     // values in force for this match (config or URL, defaults filled in)
var transient int SurveyMinutesNow;
var transient int SurveyTracesNow;
var transient int SurveyBfsNow;
var transient array<PlayerStart> SurveyStarts;       // player starts the survey bots spawn at
var transient float SurveyStartTime;
var transient int SurveyRot;                         // rotates which bot gets the frame's budget first
var transient float SurveyNextProgress;
var transient bool bSurveyDone;                      // the survey ended; the grid is being written to the log
var transient bool bSurveyStopReq;                   // mutate SurveyStop
var transient int SurveyLastExpanded;                // expanded-tile total at the last growth
var transient float SurveyLastGrowth;                // when that total last grew by 30 or more in a minute (the survey ends as stalled after 3 minutes without)
var transient float SurveyGrowthCheckAt;             // the growth check runs once a minute
var transient int SurveyLastLeadsDone;               // pass 2: leads finished at the last check (a finished lead counts as growth)
var transient string SurveyDoneReason;
var transient bool bSurveyExporting;
var transient int SurveyExpLvl;                      // GRID_ROW export cursor
var transient int SurveyExpTY;
var transient int SurveyExpTX;
var transient int SurveyExpRows;
var transient int SurveyExpTiles;
var transient EcholonZonePlanner ZonePlanner;  // zone list builder, logging only (Hold and Relocate zones, step 2)
var transient bool bZoneStarted;
var() config int ZoneConfigVer;               // 0 = zone settings never written; 1 = defaults written once (separate from ConfigVer, which resets everything)
var() config bool bZonePlanner;               // build the zone list at match start and hold a zone per normal wave
var() config int ZoneMinSpots;                // standing spots a zone needs to count as usable
var() config float ZoneSpotSpacing;           // minimum distance between two picked spots
var() config float ZonePodRadius;             // first radius tried around a trader pod
var() config float ZonePodRadiusMax;          // largest radius tried around a trader pod
var() config float ZonePodStep;               // radius growth per try
var() config float ZoneSpawnClear;            // a zone with a zed spawn volume this close is not usable
var() config float ZoneMinDist;               // zone pick band: nearest distance from the squads (uu)
var() config float ZoneMaxDist;               // zone pick band: farthest distance (uu)
var() config float ZoneWideDist;              // widened band when the first one is empty (uu)
var() config float ZoneMergeDist;             // a pod this close to a Dosh Hold zone merges into it
var transient EcholonNavGrid NavGrid;         // shared floor-is-lava tile table (N10)
var() config bool bSurveyNav;                 // use the survey map data (KFEcholonMapData.ini) for routes and steering; opt-in until the playtest passes. ?SurveyNav=1/0 overrides for one match
var() config bool bSurveyNavGrid;             // the grid half of the survey nav (lazy chunks, grid steering, grid-first corner check); needs bSurveyNav. ?SurveyNavGrid=1/0 overrides
var transient bool bSurveyNavGridNow;
var transient bool bSurveyNavNow;             // bSurveyNav after the ?SurveyNav= option
var transient int SurveyUnpacked;             // chunks unpacked this frame
var transient int NavStuckGrunt;              // of those, stucks of GRUNT-rank bots (rank=0 in NAV_STUCK)
var transient int NavStuckCount;              // NAV_STUCK level 1 events this match (NAV_SURVEY_SUMMARY)
var transient EcholonMapData MapData;         // this map's survey data from KFEcholonMapData.ini (None when the switch is off)
var() config int NavGridSquads;               // 0 = lava grid for every squad, N = only squad N (1 = first), -1 = off
var() config bool bNavGridDebug;              // log an ASCII map of the grid around squad 1's leader every 20 s
var transient float NavScanR;                 // body radius used by the scan
var transient float NavScanH;                 // body half height used by the scan
var transient float NavScanKnee;              // trace height above the floor (knee), set in NavScanBegin
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
var bool bZoneActive;                         // a planner zone (not a map objective) owns the squad goals; never true together with bObjectiveActive
var int ActiveZoneId;
var transient int ZoneActiveIdx;              // index of the active zone in ZonePlanner.Zones
var transient vector ZoneCenterLoc;           // centre and radius of the active zone (for "inside")
var transient float ZoneRadiusVal;
var transient float ZoneStartTime;
var transient bool bZonePickPending;          // a zone pick is waiting for a free nav slice (ZonePickStep)
var transient bool bZoneNoMoreThisWave;       // a hunt started: no new zone for the rest of the wave
var transient string ZonePickReason;
var transient int ZoneTries;
var transient float ZoneRetryAt;
var transient array<int> ZoneTriedIds;
var transient array<int> RecentZones;         // ids of the last 2 zones used, kept across waves
var transient float LastZoneTrackTime;
var transient array<vector> ZoneTrackLoc;
var transient array<float> ZoneTrackBad;
var transient array<bool> ZoneTrackTurned;
var transient array<vector> ZoneTravelLoc;
var float LastHoldTravelTime;
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
// Remote shop: bots buy from where they stand instead of walking to the trader. Off unless set to True
// here, or for one match with ?RemoteShop=1 on the map URL (?RemoteShop=0 forces it off).
var() config bool bRemoteShop;
var transient bool bRemoteShopActive;
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
var transient float PlaytestNextReportTime;
var transient name PlaytestCamMode;           // 'ThirdPerson', 'FirstPerson' or 'Orbit' (middle click cycles them), kept across bot switches
var transient bool bPlaytestFreeFly;          // Space: the camera flies free (view target = the spectator itself)
var transient Pawn PlaytestLastWatched;       // the bot to go back to when free fly ends
var transient bool bPlaytestSkipTrader;       // ?SkipTrader=1: cut the trader to 5 s once every living bot has shopped
var transient bool bSkipTraderOpen;           // the trader was open at the previous tick
var transient bool bSkipTraderDone;           // this trader round was skipped already
var transient int SkipTraderWave;             // WaveNum of this trader round
var transient float SkipTraderAllDoneAt;      // when every living bot was first seen done (0 = not yet)
var transient string SkipTraderBlockers;      // the bots that held the skip up the last time any did (for TRADER_SKIP_MISSED)
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
        NavGridSquads = 0;
        bNavGridDebug = false;
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
    NavMeter = new class'EcholonBot.EcholonNavMeter';
    NavBudget = new class'EcholonBot.EcholonNavBudget';
    NavScan = new class'EcholonBot.EcholonNavScan';
    // Config vars cannot be given defaults in defaultproperties and ConfigVer must not be bumped (it resets
    // every setting). ZoneConfigVer is a separate stamp: the first time it is below 1, the zone settings get
    // their defaults and are saved once. Nothing else in the ini is touched.
    if (ZoneConfigVer < 1)
    {
        bZonePlanner = true;
        ZoneMinSpots = 6;
        ZoneSpotSpacing = 200.0;
        ZonePodRadius = 800.0;
        ZonePodRadiusMax = 1400.0;
        ZonePodStep = 200.0;
        ZoneSpawnClear = 300.0;
        ZoneMergeDist = 800.0;
        ZoneConfigVer = 1;
        SaveConfig();
    }
    if (ZoneConfigVer < 2)
    {
        ZoneMinDist = 1500.0;
        ZoneMaxDist = 4000.0;
        ZoneWideDist = 6000.0;
        ZoneConfigVer = 2;
        SaveConfig();
    }
    // A zone value cleared by hand reads 0: use the built-in default.
    if (ZoneMinDist <= 0.0)
        ZoneMinDist = 1500.0;
    if (ZoneMaxDist <= 0.0)
        ZoneMaxDist = 4000.0;
    if (ZoneWideDist <= 0.0)
        ZoneWideDist = 6000.0;
    if (ZoneMinSpots <= 0)
        ZoneMinSpots = 6;
    if (ZoneSpotSpacing <= 0.0)
        ZoneSpotSpacing = 200.0;
    if (ZonePodRadius <= 0.0)
        ZonePodRadius = 800.0;
    if (ZonePodRadiusMax <= 0.0)
        ZonePodRadiusMax = 1400.0;
    if (ZonePodStep <= 0.0)
        ZonePodStep = 200.0;
    if (ZoneSpawnClear <= 0.0)
        ZoneSpawnClear = 300.0;
    if (ZoneMergeDist <= 0.0)
        ZoneMergeDist = 800.0;
    if (bZonePlanner)
    {
        ZonePlanner = new class'EcholonBot.EcholonZonePlanner';
    }
    NavGrid = new class'EcholonBot.EcholonNavGrid';
    NavGrid.Clear();
    if (bNavGridDebug)
    {
        SetTimer(20.0, true, 'NavGridDump');
    }
    SetTimer(15.0, false, 'NavBenchmarkRun');
}

// Load this map's survey data (bSurveyNav only). The object reads its section of KFEcholonMapData.ini when created; Tick resolves the
// verdicts a few entries per frame. Without the switch, a section or a matching checksum the nav stays as it was.
function MapDataBegin()
{
    local string Key;
    local int I;

    if (MapData != None)
    {
        return;
    }
    if (!bSurveyNavNow)
    {
        EchelonLog("NAV_MAPDATA_LOAD map=" $ WorldInfo.GetMapName() $ " found=0 switch=off");
        return;
    }
    Key = class'EcholonBot.EcholonMapData'.static.SectionKey(WorldInfo.GetMapName());
    MapData = new(None, Key) class'EcholonBot.EcholonMapData';
    MapData.Begin(self);
    for (I = 0; I < ActiveBots.Length; I++)
    {
        if (ActiveBots[I] != None)
        {
            ActiveBots[I].MapData = MapData;
        }
    }
}

// Once, when the data is resolved: let the first living bot time the per-link blocking cost (NAV_MAPDATA_UNIT).
function MapDataUnits()
{
    local int I;

    for (I = 0; I < ActiveBots.Length; I++)
    {
        if (ActiveBots[I] != None && ActiveBots[I].Pawn != None)
        {
            ActiveBots[I].NavMapDataBenchmark();
            return;
        }
    }
}

// Every 0.25 s: queue the survey chunks around each bot so they are unpacked before the bot gets there.
function SurveyPrefetch()
{
    local int I;

    if (NavGrid == None || !NavGrid.bSurveyReady)
    {
        return;
    }
    for (I = 0; I < ActiveBots.Length; I++)
    {
        if (ActiveBots[I] != None && ActiveBots[I].Pawn != None)
        {
            NavGrid.SurveyPrefetch(ActiveBots[I].Pawn.Location);
        }
    }
}

// NAV_GRID_UNPACK every 30 s.
function SurveyGridReport()
{
    if (NavGrid == None || !NavGrid.bSurveyReady || MapData == None)
    {
        return;
    }
    EchelonLog("NAV_GRID_UNPACK unpacked=" $ string(NavGrid.SUnpacked) $ "/" $ string(NavGrid.SKeys.Length) $ " window=" $ string(NavGrid.SUnpackedWindow)
        $ " max_per_frame=" $ string(NavGrid.SMaxFrame) $ " tiles=" $ string(NavGrid.SUnpacked * 256) $ " queued=" $ string(NavGrid.SQueue.Length)
        $ " line_clear=" $ string(MapData.LcClear) $ " line_no_too_high=" $ string(MapData.LcTooHigh) $ " too_long=" $ string(MapData.LcTooLong)
        $ " unknown=" $ string(MapData.LcUnknown) $ " nofloor=" $ string(MapData.LcNoFloor) $ " hidden=" $ string(MapData.LcHidden)
        $ " edge=" $ string(MapData.LcEdge) $ " dist0=" $ string(MapData.LcDist0));
    NavGrid.SUnpackedWindow = 0;
    NavGrid.SMaxFrame = 0;
}

// End of a playtest match: stucks, relaxes and the estimated frame cost, so a run with bSurveyNav on and one with it off can be compared.
function SurveyNavSummary()
{
    local int On, Relax, Unpacked;
    local string TotalsText;

    On = 0;
    Relax = 0;
    Unpacked = 0;
    TotalsText = "";
    if (NavMeter != None)
    {
        TotalsText = NavMeter.TotalsText();
    }
    if (MapData != None && MapData.bUsable)
    {
        On = 1;
        Relax = MapData.RelaxCount;
    }
    if (NavGrid != None)
    {
        Unpacked = NavGrid.SUnpacked;
    }
    EchelonLog("NAV_SURVEY_SUMMARY map=" $ WorldInfo.GetMapName() $ " survey_nav=" $ string(On) $ " stucks=" $ string(NavStuckCount) $ " stucks_grunt=" $ string(NavStuckGrunt) $ " relaxes=" $ string(Relax)
        $ " chunks_unpacked=" $ string(Unpacked) $ " minutes=" $ string(int(WorldInfo.TimeSeconds / 60.0)) $ " " $ TotalsText);
}

// True when the survey says this node sits inside a wall (never a steer target, crumb or relocation spot).
function bool SurveyNodeInWall(NavigationPoint N)
{
    if (MapData == None || N == None)
    {
        return false;
    }
    return MapData.NodeVerdictOf(N) == class'EcholonMapData'.const.NV_WALL;
}

// One-time: let the first living bot measure the unit cost of a trace, a route search and a reach check.
function NavBenchmarkRun()
{
    local int I;

    if (bSurvey)
    {
        return;
    }
    for (I = 0; I < ActiveBots.Length; I++)
    {
        if (ActiveBots[I] != None && ActiveBots[I].Pawn != None)
        {
            ActiveBots[I].NavBenchmark();
            EchelonLog(NavMeter.UnitCostMessage());
            NavScanBegin();
            NavDumpBegin();
            MapDataBegin();
            return;
        }
    }
    SetTimer(10.0, false, 'NavBenchmarkRun');
}

// Probe body dimensions, fill the node list and start the start-of-match link scan (N8).
function NavScanBegin()
{
    local int i;
    local NavigationPoint N;

    if (NavScan == None || NavScan.bActive || NavScan.bDone)
    {
        return;
    }
    NavScanR = 36.0;
    NavScanH = 86.0;
    NavScanKnee = 40.0;
    for (i = 0; i < ActiveBots.Length; i++)
    {
        if (ActiveBots[i] != None && ActiveBots[i].Pawn != None)
        {
            NavScanR = ActiveBots[i].Pawn.GetCollisionRadius() * 0.9;
            NavScanH = ActiveBots[i].Pawn.GetCollisionHeight();
            break;
        }
    }
    foreach WorldInfo.AllActors(class'NavigationPoint', N)
    {
        NavScan.Nodes.AddItem(N);
    }
    NavScan.Begin(WorldInfo.TimeSeconds);
    EchelonLog("NAV_SCAN_START nodes=" $ string(NavScan.Nodes.Length));
}

// Start the one-time node and link dump (bNavTrace only, or always in a survey); the work is spread over frames in Tick.
function NavDumpBegin(optional bool bForce)
{
    if ((!bNavTrace && !bForce) || NavDump != None)
    {
        return;
    }
    NavDump = new class'EcholonBot.EcholonNavDump';
    NavDump.Begin(self, WorldInfo.TimeSeconds);
}

// Per-frame budgeted step: process up to 25 links or until the scan budget is spent.
function NavScanStep()
{
    local float Now;
    local ReachSpec Spec;
    local NavigationPoint From;
    local int Why;
    local int TraceCount;
    local int Count;
    local string WhyName;
    Now = WorldInfo.TimeSeconds;
    Count = 0;
    while (Count < 25)
    {
        if (NavBudget != None && NavBudget.UsLeft(class'EcholonNavBudget'.const.NAV_PRIO_SCAN, Now) < 6.0 * NavMeter.UnitTraceUs)
        {
            break;
        }
        if (!NavScan.NextSpec(Spec, From))
        {
            EchelonLog(NavScan.Summary(Now));
            break;
        }
        Count++;
        NavScan.Links++;
        Why = NavScanCheck(Spec, From, TraceCount);
        NavScan.Traces += TraceCount;
        if (NavBudget != None)
        {
            NavBudget.TakeUs(class'EcholonNavBudget'.const.NAV_PRIO_SCAN, TraceCount * NavMeter.UnitTraceUs, Now);
        }
        if (Why == 1 || Why == 2 || Why == 3)
        {
            NavScan.AddBad(Spec);
            if (Why == 3)
            {
                NavScan.Special++;
            }
            if (NavScan.BadLogged < 150)
            {
                NavScan.BadLogged++;
                if (Why == 1)
                {
                    WhyName = "blocked";
                }
                else if (Why == 2)
                {
                    WhyName = "nofloor";
                }
                else
                {
                    WhyName = "special";
                }
                EchelonLog("NAV_SCAN_BAD from=" $ string(From) $ " to=" $ string(Spec.GetEnd()) $ " why=" $ WhyName $ " at=" $ string(int(From.Location.X)) $ "," $ string(int(From.Location.Y)) $ "," $ string(int(From.Location.Z)));
            }
        }
        else if (Why == 4)
        {
            NavScan.Drops++;
        }
        else if (Why == 5)
        {
            NavScan.Doors++;
        }
    }
}

// Z of the floor under Loc (up to 300 uu down); the node's own Z minus the body half height if there is none.
function float NavScanFloorZ(vector Loc)
{
    local vector HitLoc;
    local vector HitNorm;
    local vector Down;

    Down = Loc;
    Down.Z -= 300.0;
    if (Trace(HitLoc, HitNorm, Down, Loc, false) != None)
    {
        return HitLoc.Z;
    }
    return Loc.Z - NavScanH;
}

// Trace one link for body-block, no-floor, zed-only, drop, and door conditions.
function int NavScanCheck(ReachSpec Spec, NavigationPoint From, out int TraceCount)
{
    local NavigationPoint To;
    local vector Dir;
    local float Dist;
    local vector A;
    local vector B;
    local vector Ext;
    local vector HitLoc;
    local vector HitNorm;
    local vector Pt;
    local vector Probe;
    local Actor Hit;
    local float FloorA;
    local float FloorB;
    local int K;

    TraceCount = 0;
    if (Spec == None || Spec.GetEnd() == None)
    {
        return 0;
    }
    To = Spec.GetEnd();
    if (Spec.IsA('KFDoorReachSpec'))
    {
        return 5;
    }
    if (Spec.IsA('KFLeapReachSpec') || Spec.IsA('FloorToWallReachSpec') || Spec.IsA('WallReachSpec') || Spec.IsA('WallToFloorReachSpec') || Spec.IsA('MantleReachSpec') || Spec.IsA('CeilingReachSpec') || Spec.IsA('FloorToCeilingReachSpec') || Spec.IsA('LadderReachSpec') || Spec.IsA('WallTransReachSpec') || Spec.CollisionRadius < NavScanR / 0.9)
    {
        return 3;
    }
    if (float(Spec.MaxLandingVelocity) > NavScan.MaxLanding)
    {
        NavScan.MaxLanding = float(Spec.MaxLandingVelocity);
    }
    if (Spec.MaxLandingVelocity > 0 || To.Location.Z < From.Location.Z - 128.0)
    {
        return 4;
    }
    Dir = To.Location - From.Location;
    Dir.Z = 0;
    Dist = VSize(Dir);
    if (Dist < 120.0)
    {
        return 0;
    }
    Dir = Normal(Dir);
    // Heights come from the floor under each node: node Z is not a fixed height above the floor.
    FloorA = NavScanFloorZ(From.Location);
    FloorB = NavScanFloorZ(To.Location);
    TraceCount += 2;
    Ext.X = NavScanR;
    Ext.Y = NavScanR;
    Ext.Z = 8.0;
    A = From.Location + Dir * 30.0;
    A.Z = FloorA + NavScanKnee;
    B = To.Location - Dir * 30.0;
    B.Z = FloorB + NavScanKnee;
    TraceCount++;
    Hit = Trace(HitLoc, HitNorm, B, A, true, Ext);
    if (Hit != None && Pawn(Hit) == None && KFDoorActor(Hit) == None)
    {
        return 1;
    }
    K = 1;
    while (K * 100.0 < Dist)
    {
        Pt = From.Location + Dir * (K * 100.0);
        Pt.Z = Lerp(FloorA, FloorB, (K * 100.0) / Dist) + NavScanKnee;
        Probe = Pt;
        Probe.Z = Probe.Z - NavScanKnee - 80.0;
        TraceCount++;
        if (Trace(HitLoc, HitNorm, Probe, Pt, false) == None)
        {
            return 2;
        }
        K++;
    }
    return 0;
}

// True when the lava grid steers this bot: NavGridSquads 0 = everyone, N = members of squad N, -1 = nobody.
function bool NavGridAppliesTo(EcholonBot B)
{
    local int GroupIdx;

    if (NavGridSquads < 0 || B == None)
    {
        return false;
    }
    if (NavGridSquads == 0)
    {
        return true;
    }
    GroupIdx = NavGridSquads - 1;
    return GroupIdx < Fireteams.Length && Fireteams[GroupIdx].Members.Find(B) != INDEX_NONE;
}

// Debug: logs a 21 x 21 tile map (north up) around squad 1's leader: B bot, . safe, # lava, ? unknown.
function NavGridDump()
{
    local EcholonBot Ldr;
    local int I, DX, DY, TX0, TY0, Band, St;
    local float FloorZ;
    local string Row;

    if (Fireteams.Length == 0)
    {
        return;
    }
    Ldr = Fireteams[0].Leader;
    if (Ldr == None || Ldr.Pawn == None)
    {
        for (I = 0; I < Fireteams[0].Members.Length && (Ldr == None || Ldr.Pawn == None); I++)
        {
            Ldr = Fireteams[0].Members[I];
        }
    }
    if (Ldr == None || Ldr.Pawn == None)
    {
        return;
    }
    TX0 = NavGrid.TileOf(Ldr.Pawn.Location.X);
    TY0 = NavGrid.TileOf(Ldr.Pawn.Location.Y);
    Band = NavGrid.BandOf(Ldr.Pawn.Location.Z - Ldr.Pawn.GetCollisionHeight());
    EchelonLog("NAV_GRID_MAP squad=1 leader=" $ string(Ldr.Name) $ " tile=" $ string(TX0) $ "," $ string(TY0));
    for (DY = 10; DY >= -10; DY--)
    {
        Row = "";
        for (DX = -10; DX <= 10; DX++)
        {
            St = NavGrid.Lookup(TX0 + DX, TY0 + DY, Band, WorldInfo.TimeSeconds, FloorZ);
            if (DX == 0 && DY == 0)
            {
                Row $= "B";
            }
            else if (St == class'EcholonNavGrid'.const.NAV_SAFE)
            {
                Row $= ".";
            }
            else if (St == class'EcholonNavGrid'.const.NAV_LAVA)
            {
                Row $= "#";
            }
            else
            {
                Row $= "?";
            }
        }
        EchelonLog("NAV_GRID_ROW dy=" $ string(DY) $ " " $ Row);
    }
}

// Closes the nav meter's frame and logs its report every 30 s (N6); steps the link scan (N8).
event Tick(float DeltaTime)
{
    local string NavReport;

    super.Tick(DeltaTime);
    if (NavMeter != None)
    {
        NavReport = NavMeter.EndFrame(WorldInfo.TimeSeconds);
        if (NavReport != "")
        {
            EchelonLog(NavReport $ " " $ NavBudget.TakeDeniedCounts());
        }
    }
    if (NavDump != None && NavDump.bActive)
    {
        NavDump.Step();
    }
    if (MapData != None && !MapData.bDone)
    {
        if (MapData.Step() && MapData.bUsable)
        {
            MapDataUnits();
            SetTimer(0.25, true, 'SurveyPrefetch');
            SetTimer(30.0, true, 'SurveyGridReport');
        }
    }
    if (NavGrid != None && NavGrid.bSurveyReady)
    {
        SurveyUnpacked = NavGrid.SurveyUnpackStep();
        if (SurveyUnpacked > 0 && NavMeter != None)
        {
            NavMeter.CountUnpack(SurveyUnpacked);
        }
    }
    if (bSurvey && SurveyGrid != None)
    {
        if (!bSurveyDone)
        {
            SurveyTickAll(DeltaTime);
        }
        else if (bSurveyExporting)
        {
            SurveyExportStep();
        }
    }
    if (NavScan != None && NavScan.bActive)
    {
        NavScanStep();
    }
    else if (ZonePlanner != None && NavScan != None && NavScan.bDone)
    {
        ZoneStep();
    }
}

// Zone list (logging only): starts once the link scan is done, then steps one unit of work per frame.
function ZoneStep()
{
    if (ZonePlanner.bDone)
    {
        return;
    }
    if (!bZoneStarted)
    {
        bZoneStarted = true;
        ZonePlanner.Begin(self, WorldInfo.TimeSeconds);
        return;
    }
    ZonePlanner.Step(WorldInfo.TimeSeconds);
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
        if (bSurvey)
        {
            SurveyBegin();
        }
        else
        {
            for (I = 0; I < NumBots; ++I)
            {
                AddBot();
            }
            // Spread the squads over random ammo crates right away, in the same tick the bots are created
            // (see InitialRelocate).
            InitialRelocate();
        }
    }
    else
    {
        SetTimer(1.0, true);
    }
    if (!bSurvey)
    {
        SetTimer(0.1, true, 'CheckWave');
    }
    InstallVoteCollector();
}

// Remote shop: while the trader is open every bot that may shop buys on the spot, whatever it is doing.
// The bots' own picks reach the economy step only after objective, regroup and follow steps, which can hold
// a bot for a minute (seen 2026-10-23: a trader round passed with 3 of 7 bots not yet shopped).
// RemoteShop skips bots in a fight, still on cooldown, or with nothing to buy from.
// CheckWave starts this 1 s timer when the trader opens; it stops itself when the trader closes.
function RemoteShopSweep()
{
    local int I;

    if (KF == None || KF.MyKFGRI == None || !KF.MyKFGRI.bTraderIsOpen)
    {
        ClearTimer('RemoteShopSweep');
        return;
    }
    for (I = 0; I < ActiveBots.Length; I++)
    {
        if (ActiveBots[I] != None && ActiveBots[I].Pawn != None && ActiveBots[I].Pawn.IsAliveAndWell())
            ActiveBots[I].RemoteShop();
    }
}

function InitMutator(string Options, out string ErrorMessage)
{
    super.InitMutator(Options, ErrorMessage);

    bRemoteShopActive = bRemoteShop;
    if (class'GameInfo'.static.HasOption(Options, "RemoteShop"))
    {
        bRemoteShopActive = class'GameInfo'.static.ParseOption(Options, "RemoteShop") ~= "1";
    }
    if (bRemoteShopActive)
    {
        EchelonLog("SHOP_REMOTE_MODE on=1 source=" $ (class'GameInfo'.static.HasOption(Options, "RemoteShop") ? "url" : "config"));
    }

    // Our controller makes the spectator keys work on bots (click, middle click, Space, wheel) when the human is dead,
    // in normal play as well as in playtest mode. Everything it overrides sits in state Spectating (see EcholonSpectatorPC).
    WorldInfo.Game.PlayerControllerClass = class'EcholonSpectatorPC';
    PlaytestCamMode = 'ThirdPerson';

    bPlaytest = class'GameInfo'.static.ParseOption(Options, "Playtest") ~= "1";
    if (bPlaytest)
    {
        bPlaytestSkipTrader = class'GameInfo'.static.ParseOption(Options, "SkipTrader") ~= "1";
        PlaytestWaves = class'GameInfo'.static.GetIntOption(Options, "PlaytestWaves", 0);
        PlaytestBotsOverride = class'GameInfo'.static.GetIntOption(Options, "PlaytestBots", 0);
        if (PlaytestBotsOverride > 0)
            NumBots = byte(PlaytestBotsOverride);
        EchelonLog("PLAYTEST_START map=" $ WorldInfo.GetMapName(true) $ " waves=" $ string(PlaytestWaves) $ " bots=" $ string(NumBots)
            $ " skip_trader=" $ string(bPlaytestSkipTrader) $ " remote_shop=" $ string(bRemoteShopActive));
        SetTimer(1.0, true, 'PlaytestTick');
    }

    bSurveyNavNow = bSurveyNav;
    if (class'GameInfo'.static.HasOption(Options, "SurveyNav"))
    {
        bSurveyNavNow = class'GameInfo'.static.GetIntOption(Options, "SurveyNav", 0) != 0;
    }
    bSurveyNavGridNow = bSurveyNavGrid;
    if (class'GameInfo'.static.HasOption(Options, "SurveyNavGrid"))
    {
        bSurveyNavGridNow = class'GameInfo'.static.GetIntOption(Options, "SurveyNavGrid", 0) != 0;
    }
    bSurvey = class'GameInfo'.static.ParseOption(Options, "Survey") ~= "1";
    if (bSurvey)
    {
        bPass2Allowed = class'GameInfo'.static.GetIntOption(Options, "SurveyPass2", 1) != 0;
        SurveyPass1Mins = class'GameInfo'.static.GetIntOption(Options, "SurveyPass1Mins", 0);
        SurveyBotsNow = class'GameInfo'.static.GetIntOption(Options, "SurveyBots", SurveyBots);
        if (SurveyBotsNow <= 0)
            SurveyBotsNow = 4;
        SurveyMinutesNow = class'GameInfo'.static.GetIntOption(Options, "SurveyMinutes", SurveyMinutes);
        if (SurveyMinutesNow <= 0)
            SurveyMinutesNow = 60;
        SurveyTracesNow = SurveyTraces;
        if (SurveyTracesNow <= 0)
            SurveyTracesNow = 120;
        SurveyBfsNow = SurveyBfsNodes;
        if (SurveyBfsNow <= 0)
            SurveyBfsNow = 400;
        EchelonLog("SURVEY_MODE bots=" $ string(SurveyBotsNow) $ " minutes=" $ string(SurveyMinutesNow) $ " traces=" $ string(SurveyTracesNow)
            $ " bfs=" $ string(SurveyBfsNow));
        SetTimer(1.0, true, 'SurveyCheck');
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
    if (bSurvey)
        KF.ForceLivingPlayerCount(byte(SurveyBotList.Length));
    else
        KF.ForceLivingPlayerCount(byte(KF.NumBots));

    EchelonLog("PLAYTEST_SPECTATE again=" $ string(bPlaytestSpectating) $ " living_before=" $ string(LivingBefore)
        $ " living_after=" $ string(KF.GetLivingPlayerCount()) $ " wave=" $ string(KF.MyKFGRI.WaveNum));
    bPlaytestSpectating = true;
}

// Camera style for a watched bot: the orbit mode uses the stock 'FreeCam' style (the camera sits behind the
// bot and takes its rotation from the mouse); 'ThirdPerson' follows the bot's own facing.
final function name PlaytestBotCamStyle()
{
    return (PlaytestCamMode == 'Orbit') ? 'FreeCam' : PlaytestCamMode;
}

// Points the human's camera at the next (Dir 1) or previous (Dir -1) living bot, in PlaytestCamMode.
// Stock SpectateNextPlayer skips bots: KFGameInfo.CanSpectate only accepts PlayerController owners.
// The camera stays on a bot until it dies (PlaytestTick) or a click moves it; a click also ends free fly.
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
            if (bPlaytestFreeFly)
            {
                bPlaytestFreeFly = false;
                EchelonLog("PLAYTEST_CAMERA_FREE on=0");
            }
            PlaytestLastWatched = B.Pawn;
            PC.SetViewTarget(B.Pawn);
            PC.SetCameraMode(PlaytestBotCamStyle());
            PlaytestApplyZoom(PC);
            EchelonLog("PLAYTEST_CAMERA target=" $ B.LogTag() $ " mode=" $ string(PlaytestCamMode) $ " manual=" $ string(bManual));
            return;
        }
    }
}

// Camera-mode key (middle click): third person -> first person -> free turning orbit -> third person,
// on the bot being watched. While the camera flies free it only changes the mode used when a bot is
// watched again.
final function PlaytestToggleCamMode(PlayerController PC)
{
    if (PC == None)
        return;
    if (PlaytestCamMode == 'ThirdPerson')
        PlaytestCamMode = 'FirstPerson';
    else if (PlaytestCamMode == 'FirstPerson')
        PlaytestCamMode = 'Orbit';
    else
        PlaytestCamMode = 'ThirdPerson';
    if (!bPlaytestFreeFly)
    {
        PC.SetCameraMode(PlaytestBotCamStyle());
        PlaytestApplyZoom(PC);
    }
    EchelonLog("PLAYTEST_CAMERA_MODE mode=" $ string(PlaytestCamMode));
}

// Puts the remembered wheel-zoom distance back on the camera (it survives bot and mode switches).
final function PlaytestApplyZoom(PlayerController PC)
{
    if (EcholonSpectatorPC(PC) != None)
        EcholonSpectatorPC(PC).ApplyZoom();
}

// Space: the camera leaves the bots and flies free (view target = the spectator, WASD + mouse), starting
// where the camera is now. Space again goes back to the bot watched last (the next living bot if it died).
final function PlaytestToggleFreeFly(PlayerController PC)
{
    local Pawn Watched;
    local vector Loc;
    local rotator Rot;

    if (PC == None)
        return;

    if (!bPlaytestFreeFly)
    {
        Watched = Pawn(PC.ViewTarget);
        if (Watched != None)
            PlaytestLastWatched = Watched;
        PC.GetPlayerViewPoint(Loc, Rot);
        Rot.Roll = 0;
        PC.SetLocation(Loc);
        PC.SetRotation(Rot);
        bPlaytestFreeFly = true;
        PC.SetViewTarget(PC);
        PC.SetCameraMode('FirstPerson');
        EchelonLog("PLAYTEST_CAMERA_FREE on=1");
        return;
    }

    bPlaytestFreeFly = false;
    if (PlaytestLastWatched != None && PlaytestLastWatched.IsAliveAndWell())
    {
        PC.SetViewTarget(PlaytestLastWatched);
        PC.SetCameraMode(PlaytestBotCamStyle());
        PlaytestApplyZoom(PC);
    }
    else
    {
        PlaytestStepCamera(PC, 1);
    }
    EchelonLog("PLAYTEST_CAMERA_FREE on=0");
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
            SurveyNavSummary();
            EchelonLog("PLAYTEST_DONE reason=" $ Reason $ " waves_done=" $ string(PlaytestWavesDone));
            bPlaytestDone = true;
            SetTimer(5.0, false, 'PlaytestQuit');
        }
    }

    if (!Trader && bPlaytestLastTrader)
        PlaytestWaveStart = WorldInfo.TimeSeconds;
    bPlaytestLastTrader = Trader;
}

// Playtest trader skip (?SkipTrader=1): once every living bot has finished shopping (or given up) the trader
// is cut to 5 s through the stock skip path (KFVoteCollector.SkipTraderTime, no vote), so a run does not sit
// through the whole break. Bots sharing dosh (DonatingMoney) get up to 20 s after the last bot finished.
// Dead bots are ignored; a bot that respawns counts again once alive (Restart clears its ShoppedWave).
final function PlaytestCheckTraderSkip()
{
    local KFGameReplicationInfo KFGRI;
    local EcholonBot B;
    local bool bSharing;
    local int Living, Remaining, After;
    local float Waited;
    local string Pending;

    if (!bPlaytestSkipTrader || KF == None || KF.MyKFGRI == None)
        return;
    KFGRI = KF.MyKFGRI;

    if (!KFGRI.bTraderIsOpen)
    {
        if (bSkipTraderOpen && !bSkipTraderDone)
        {
            EchelonLog("TRADER_SKIP_MISSED wave=" $ string(SkipTraderWave) $ " pending=" $ SkipTraderBlockers);
        }
        bSkipTraderOpen = false;
        return;
    }

    if (!bSkipTraderOpen)
    {
        bSkipTraderOpen = true;
        bSkipTraderDone = false;
        SkipTraderWave = KFGRI.WaveNum;
        SkipTraderAllDoneAt = 0.0;
        SkipTraderBlockers = "none";
    }

    // Remembered every tick, also inside the last 5 s: a bot that shops just before the trader closes must
    // still be named as the one that held the skip up.
    Pending = PlaytestPendingShoppers();
    if (Pending != "none")
        SkipTraderBlockers = Pending;

    Remaining = KFGRI.GetTraderTimeRemaining();
    if (bSkipTraderDone || Remaining <= 5)
        return;

    foreach WorldInfo.AllControllers(class'EcholonBot', B)
    {
        if (B.Pawn == None || !B.Pawn.IsAliveAndWell())
            continue;
        Living++;
        if (B.IsInState('DonatingMoney'))
            bSharing = true;
    }
    if (Living == 0 || Pending != "none")
    {
        SkipTraderAllDoneAt = 0.0;
        return;
    }

    if (SkipTraderAllDoneAt == 0.0)
        SkipTraderAllDoneAt = WorldInfo.TimeSeconds;
    Waited = WorldInfo.TimeSeconds - SkipTraderAllDoneAt;
    if (bSharing && Waited < 20.0)
        return;

    if (KFGRI.VoteCollector != None)
    {
        KFGRI.VoteCollector.SkipTraderTime();
    }
    else
    {
        KFGRI.RemainingTime = 5;
        KFGRI.RemainingMinute = 5;
        KF.SkipTrader(5);
    }
    After = KFGRI.GetTraderTimeRemaining();
    bSkipTraderDone = true;
    EchelonLog("TRADER_SKIP wave=" $ string(SkipTraderWave) $ " bots=" $ string(Living) $ " waited_share=" $ string(int(Waited))
        $ " saved=" $ string(Remaining - After));
}

// Names of the living bots that have not finished shopping this trader round, comma separated; "none" if all have.
final function string PlaytestPendingShoppers()
{
    local EcholonBot B;
    local string Pending;

    foreach WorldInfo.AllControllers(class'EcholonBot', B)
    {
        if (B.Pawn == None || !B.Pawn.IsAliveAndWell() || B.ShoppedWave == SkipTraderWave)
            continue;
        Pending = Pending $ (Pending != "" ? "," : "") $ B.LogTag();
    }
    return (Pending == "") ? "none" : Pending;
}

function PlaytestQuit()
{
    local PlayerController PC;

    PC = WorldInfo.GetALocalPlayerController();
    if (PC != None)
    {
        if (EcholonSpectatorPC(PC) != None)
            EcholonSpectatorPC(PC).RestoreWheelBinds();
        PC.ConsoleCommand("exit");
    }
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

    // Before the human lookup: after a defeat the local controller can be gone, and the run must still end.
    PlaytestCheckWaveEnd();
    PlaytestCheckTraderSkip();

    PC = GetPlaytestHuman();
    if (PC == None)
        return;

    if (PC.Pawn != None)
    {
        PlaytestMakeSpectator(PC);
    }

    // The camera stays on a bot until the bot dies (or is gone); only Space (free fly) or a click moves it.
    ViewPawn = Pawn(PC.ViewTarget);
    if (!bPlaytestFreeFly && (ViewPawn == None || !ViewPawn.IsAliveAndWell()))
    {
        PlaytestStepCamera(PC, 1);
    }

    PlaytestCheckStuckWave();

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
    NewBot.NavMeter = NavMeter;
    NewBot.NavBudget = NavBudget;
    NewBot.NavScan = NavScan;
    NewBot.NavGrid = NavGrid;
    NewBot.MapData = MapData;
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
        if (bZoneActive)
        {
            EndZone("wave_end");
        }
        bZoneNoMoreThisWave = false;
        ZoneQueuePick("wave_start");
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

    if (bObjectiveActive && HoldVolume != None)
    {
        EchelonLog("HOLD_REISSUE reason=PlatoonRebuilt squads=" $ string(Fireteams.Length));
        SetHoldObjective(HoldVolume);
    }
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

        if (bZoneActive && SquadOrders.Length > GroupIdx && SquadOrders[GroupIdx].GoalNav != None)
        {
            // While a zone is active the tether anchor is the squad's role spot, so the tether and the zone pull the same way.
            Fireteams[GroupIdx].Anchor = SquadOrders[GroupIdx].GoalNav;
            GroupLeader.AssignedAnchor = SquadOrders[GroupIdx].GoalNav;
            PropagateAnchorToFollowers(GroupIdx);
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
    if (bRemoteShopActive && KF.MyKFGRI.bTraderIsOpen && !IsTimerActive('RemoteShopSweep'))
    {
        SetTimer(1.0, true, 'RemoteShopSweep');
    }

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

    if (bZoneActive || bZonePickPending)
    {
        if (KF.MyKFGRI.bTraderIsOpen)
        {
            EndZone("trader");
        }
        else if (KF.MyKFGRI.IsBossWave())
        {
            EndZone("boss");
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
            // A hold zone that started in the same tick owns the goals now.
            if (!bObjectiveActive)
            {
                for (i = 0; i < SquadOrders.Length; i++)
                    SquadOrders[i].GoalNav = None;
            }
            EchelonLog("HUNT_ORDER_END");
        }
        return;
    }

    if (bZoneActive)
    {
        EndZone("hunt");
    }
    bZoneNoMoreThisWave = true;
    ZoneCancelPick();
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
    local EcholonBot L;
    local EcholonBot B;

    // A real map objective always wins over a planner zone.
    if (bZoneActive)
    {
        EndZone("objective");
    }
    ZoneCancelPick();
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
        // Bots cache their goal node; drop it so they fetch the new squad goal (squads may have been reshuffled).
        foreach WorldInfo.AllControllers(class'EcholonBot', B)
        {
            B.ObjectiveGoal = None;
        }
        EnsureSquadOrderTable();
        for (i = 0; i < SquadOrders.Length; i++)
        {
            SquadOrders[i].Zone = HoldVolume;
            SquadOrders[i].SquadID = i + 1;
            SquadOrders[i].NodeBlacklist.Length = 0;
            SquadOrders[i].ObjectiveBailUntil = 0.0;
            if (i < Fireteams.Length)
            {
                L = Fireteams[i].Leader;
                if (L != None && L.Pawn != None && L.Pawn.IsAliveAndWell())
                {
                    SquadOrders[i].Leader = L;
                    GP = NearestValidPoint(L.Pawn.Location);
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
                    SquadOrders[i].Leader = None;
                    SquadOrders[i].GoalNav = None;
                    SquadOrders[i].GoalPoint = vect(0, 0, 0);
                    SquadOrders[i].Phase = PHASE_IDLE;
                    EchelonLog("HOLD_SKIP squad=" $ string(i + 1) $ " reason=NoLeader");
                }
            }
            else
            {
                SquadOrders[i].GoalNav = None;
                SquadOrders[i].GoalPoint = vect(0, 0, 0);
                SquadOrders[i].Phase = PHASE_IDLE;
            }
        }
        EchelonLog("HOLD_START squads=" $ string(SquadOrders.Length) $ " points=" $ string(ValidPoints.Length));
    }
    else
    {
        EchelonLog("HOLD_EMPTY volume=" $ string(V.Name));
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
        EchelonLog("HOLD_END squad=" $ string(i + 1) $ " phase=" $ string(SquadOrders[i].Phase));
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
    if (KF != None && KF.MyKFGRI != None && KF.MyKFGRI.AIRemaining > HUNT_ORDER_MAX_ZEDS && !KF.MyKFGRI.bTraderIsOpen
        && !KF.MyKFGRI.IsBossWave())
    {
        ZoneQueuePick("objective_end");
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

    if (bZoneActive)
    {
        // The new leader takes the squad's spot and role: deal the zone again for the living squads.
        ZoneDeal("leader");
        return;
    }

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

    // A zone deals its own spots (ZoneDeal); the ring sampling is for real objectives.
    if (bZoneActive)
        return;

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

// True when the location is inside the active zone: within its radius (2D) and less than 350 uu above or below the centre (spots are picked up to 300 uu off the centre height).
function bool ZoneInside(vector L)
{
    return VSize2D(L - ZoneCenterLoc) <= ZoneRadiusVal + 100.0 && Abs(L.Z - ZoneCenterLoc.Z) < 350.0;
}

function LogHoldTravel()
{
    local int i;
    local int bIn;
    local SquadOrder O;

    if (WorldInfo.TimeSeconds - LastHoldTravelTime < 5.0)
        return;

    LastHoldTravelTime = WorldInfo.TimeSeconds;

    for (i = 0; i < SquadOrders.Length && i < Fireteams.Length; i++)
    {
        O = SquadOrders[i];
        if (O.Leader == None)
            continue;
        if (O.Leader.Pawn == None)
            continue;
        if (O.Phase != PHASE_ENROUTE && O.Phase != PHASE_HOLDING)
            continue;

        if (bZoneActive)
        {
            if (ZoneTravelLoc.Length != SquadOrders.Length)
                ZoneTravelLoc.Length = SquadOrders.Length;
            if (O.Phase == PHASE_ENROUTE)
            {
                EchelonLog("ZONE_TRAVEL squad=" $ string(i + 1) $ " left=" $ string(int(VSize(O.Leader.Pawn.Location - O.GoalPoint))) $ " moved=" $ string(int(VSize(O.Leader.Pawn.Location - ZoneTravelLoc[i]))));
            }
            ZoneTravelLoc[i] = O.Leader.Pawn.Location;
            continue;
        }

        if (O.Zone != None && O.Zone.Encompasses(O.Leader.Pawn))
            bIn = 1;
        else
            bIn = 0;

        EchelonLog("HOLD_TRAVEL squad=" $ string(i + 1) $ " phase=" $ string(O.Phase) $ " dist=" $ string(int(VSize(O.Leader.Pawn.Location - O.GoalPoint))) $ " inside=" $ bIn);
    }
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
    local int OthersAlive;

    if (WorldInfo == None || !HasHoldGoals())
        return;

    if (bZoneActive)
    {
        ZoneTrack();
    }
    LogHoldTravel();
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

        if (bZoneActive)
        {
            LeaderInside = ZoneInside(O.Leader.Pawn.Location);
        }
        else if (O.Zone != None)
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
        OthersAlive = 0;
        for (MemberIdx = 0; MemberIdx < Fireteams[i].Members.Length; MemberIdx++)
        {
            M = Fireteams[i].Members[MemberIdx];
            if (M == None || M == O.Leader)
                continue;
            if (M.Pawn == None || M.Pawn.Health <= 0)
                continue;
            OthersAlive++;
            if (bZoneActive)
            {
                if (ZoneInside(M.Pawn.Location))
                    MemberInside = true;
            }
            else if (O.Zone != None)
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

        // A zone squad down to its leader alone has no follower to wait for.
        if (bZoneActive && OthersAlive == 0)
            MemberInside = true;

        if (O.Phase == PHASE_ENROUTE && LeaderInside && MemberInside)
        {
            O.Phase = PHASE_HOLDING;
            SquadOrders[i] = O;
            EchelonLog("HOLD_PHASE squad=" $ string(i + 1) $ " phase=HOLDING");
            if (bZoneActive)
            {
                EchelonLog("ZONE_ARRIVE squad=" $ string(i + 1) $ " role=" $ string(O.Role) $ " secs=" $ string(int(WorldInfo.TimeSeconds - O.StartTime)));
            }
        }
        else if (O.Phase == PHASE_HOLDING && !LeaderInside)
        {
            O.Phase = PHASE_ENROUTE;
            SquadOrders[i] = O;
            EchelonLog("HOLD_PHASE squad=" $ string(i + 1) $ " phase=ENROUTE");
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
                    // A zone keeps its squads on their role spots: the zone re-deal already set the order.
                    if (!bZoneActive)
                    {
                        O = SquadOrders[i];
                        O.Phase = PHASE_REGROUP;
                        O.StartTime = Now;
                        SquadOrders[i] = O;
                        EchelonLog("REGROUP_ENTER squad=" $ string(i + 1) $ " leaderDead newLeader=" $ string(NewLeader.Name));
                    }
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


// ---------------------------------------------------------------------------------------------
// Zone hold (Hold and Relocate zones, step 3): the planner picks one zone per wave and every squad
// goes there with a role. bZoneActive says a zone owns the squad goals (see HasHoldGoals).
// ---------------------------------------------------------------------------------------------

// Ask for a zone pick; ZonePickStep does it over the next frames (one route search at a time).
function ZoneQueuePick(string Reason)
{
    if (ZonePlanner == None || bZoneActive || bZoneNoMoreThisWave)
    {
        return;
    }
    bZonePickPending = true;
    ZonePickReason = Reason;
    ZoneTries = 0;
    ZoneTriedIds.Length = 0;
    ZoneRetryAt = 0.0;
    if (!IsTimerActive('ZonePickStep'))
    {
        SetTimer(0.5, true, 'ZonePickStep');
    }
}

function ZoneCancelPick()
{
    bZonePickPending = false;
    ClearTimer('ZonePickStep');
}

// Timer: choose a zone at random in the distance band, check one route, commit or try the next.
function ZonePickStep()
{
    local KFGameReplicationInfo GRI;
    local EcholonBot L, Core;
    local vector Ref;
    local int i, n, Pick, ZIdx, Pass;
    local float Now, D;
    local array<int> Excl, Cands;
    local string BandName, RecentStr;

    if (!bZonePickPending)
    {
        ClearTimer('ZonePickStep');
        return;
    }
    GRI = KFGameReplicationInfo(WorldInfo.GRI);
    if (GRI == None || bZoneActive || bObjectiveActive || bHuntOrderActive || bZoneNoMoreThisWave
        || GRI.bTraderIsOpen || GRI.IsBossWave() || !GRI.bMatchHasBegun || GRI.bMatchIsOver)
    {
        ZoneCancelPick();
        return;
    }
    Now = WorldInfo.TimeSeconds;
    if (ZonePlanner == None || !ZonePlanner.bDone || Now < ZoneRetryAt)
    {
        return;
    }

    n = 0;
    Core = None;
    Ref = vect(0, 0, 0);
    for (i = 0; i < Fireteams.Length; i++)
    {
        L = Fireteams[i].Leader;
        if (L == None || L.Pawn == None || L.Pawn.Health <= 0)
        {
            continue;
        }
        Ref += L.Pawn.Location;
        n++;
        if (Core == None)
        {
            Core = L;
        }
    }
    if (n == 0)
    {
        return;
    }
    Ref = Ref / float(n);

    // Pass 0 skips the last zones used; if that leaves nothing (a map with 1 or 2 usable zones), pass 1 allows them.
    for (Pass = 0; Pass < 2 && Cands.Length == 0; Pass++)
    {
        Excl.Length = 0;
        if (Pass == 0)
        {
            for (i = 0; i < RecentZones.Length; i++)
            {
                Excl.AddItem(RecentZones[i]);
            }
        }
        for (i = 0; i < ZoneTriedIds.Length; i++)
        {
            Excl.AddItem(ZoneTriedIds[i]);
        }

        BandName = "30-80";
        Cands = ZonePlanner.CandidateZones(Ref, ZoneMinDist, ZoneMaxDist, Excl);
        if (Cands.Length == 0)
        {
            BandName = "120";
            Cands = ZonePlanner.CandidateZones(Ref, ZoneMinDist, ZoneWideDist, Excl);
        }
        if (Cands.Length == 0)
        {
            BandName = "nearest";
            ZIdx = ZonePlanner.NearestUsable(Ref, Excl);
            if (ZIdx >= 0)
            {
                Cands.AddItem(ZIdx);
            }
        }
    }
    if (Cands.Length == 0)
    {
        if (ZoneTries == 0)
        {
            EchelonLog("ZONE_NONE reason=no_usable");
            ZoneCancelPick();
        }
        else
        {
            EchelonLog("ZONE_NONE reason=no_route");
            ZoneTries = 0;
            ZoneTriedIds.Length = 0;
            ZoneRetryAt = Now + 10.0;
        }
        return;
    }

    // Fully random among the candidates (user decision), then one route check through the nav budget.
    if (NavBudget != None && !NavBudget.TakeSearch(Now))
    {
        return;
    }
    Pick = Cands[Rand(Cands.Length)];
    ZoneTries++;
    if (Core != None && (ZonePlanner.Zones[Pick].Spots.Length == 0 || !Core.ProbeRoute(ZonePlanner.Zones[Pick].Spots[0])))
    {
        ZoneTriedIds.AddItem(ZonePlanner.Zones[Pick].Id);
        if (ZoneTries >= 3)
        {
            EchelonLog("ZONE_NONE reason=no_route");
            ZoneTries = 0;
            ZoneTriedIds.Length = 0;
            ZoneRetryAt = Now + 10.0;
        }
        return;
    }

    D = VSize(ZonePlanner.Zones[Pick].Center - Ref);
    RecentStr = "";
    for (i = 0; i < RecentZones.Length; i++)
    {
        if (i > 0)
        {
            RecentStr = RecentStr $ ",";
        }
        RecentStr = RecentStr $ string(RecentZones[i]);
    }
    EchelonLog("ZONE_PICK zone=" $ string(ZonePlanner.Zones[Pick].Id) $ " src=" $ ZoneSrcName(ZonePlanner.Zones[Pick].Src) $ " dist=" $ string(int(D)) $ " band=" $ BandName $ " tries=" $ string(ZoneTries) $ " recent=" $ RecentStr $ " reason=" $ ZonePickReason);
    ZoneCommit(Pick);
}

function string ZoneSrcName(byte Src)
{
    if (Src == 0)
    {
        return "dosh";
    }
    return "pod";
}

// Make the picked zone the active hold and deal the roles.
function ZoneCommit(int ZIdx)
{
    ZoneCancelPick();
    bZoneActive = true;
    bZoneNoMoreThisWave = false;
    ZoneActiveIdx = ZIdx;
    ActiveZoneId = ZonePlanner.Zones[ZIdx].Id;
    ZoneCenterLoc = ZonePlanner.Zones[ZIdx].Center;
    ZoneRadiusVal = ZonePlanner.Zones[ZIdx].Radius;
    ZoneStartTime = WorldInfo.TimeSeconds;
    RecentZones.AddItem(ActiveZoneId);
    while (RecentZones.Length > 2)
    {
        RecentZones.Remove(0, 1);
    }
    ZoneDeal("");
}

// Deal roles and spots of the active zone to the living squads (Why is empty for the first deal).
function ZoneDeal(string Why)
{
    local int i, j, N;
    local array<int> Counts;
    local array<SquadDeal> Deals;
    local SquadOrder O;
    local EcholonBot Ldr;
    local string RoleName;
    local NavigationPoint PrevNav;
    local EcholonBot PrevLeader;
    local int PrevPhase;
    local float PrevStart;

    if (!bZoneActive || ZonePlanner == None)
    {
        return;
    }
    EnsureSquadOrderTable();
    for (i = 0; i < Fireteams.Length; i++)
    {
        N = 0;
        for (j = 0; j < Fireteams[i].Members.Length; j++)
        {
            if (Fireteams[i].Members[j] != None && Fireteams[i].Members[j].Pawn != None && Fireteams[i].Members[j].Pawn.Health > 0)
            {
                N++;
            }
        }
        Counts.AddItem(N);
    }
    Deals = ZonePlanner.DealSpots(ZoneActiveIdx, Counts);
    if (Why != "")
    {
        EchelonLog("ZONE_REDEAL reason=" $ Why);
    }
    for (i = 0; i < Fireteams.Length && i < SquadOrders.Length && i < Deals.Length; i++)
    {
        O = SquadOrders[i];
        PrevNav = O.GoalNav;
        PrevLeader = O.Leader;
        PrevPhase = O.Phase;
        PrevStart = O.StartTime;
        O.SquadID = i + 1;
        O.Zone = None;
        O.Role = Deals[i].Role;
        O.Slots.Length = 0;
        O.SlotLocs.Length = 0;
        O.ObjectiveBailUntil = 0.0;
        Ldr = Fireteams[i].Leader;
        if (Counts[i] == 0 || Ldr == None || Ldr.Pawn == None || Ldr.Pawn.Health <= 0 || Deals[i].LeaderNav == None)
        {
            O.Leader = None;
            O.GoalNav = None;
            O.GoalPoint = vect(0, 0, 0);
            O.Phase = PHASE_IDLE;
            SquadOrders[i] = O;
            continue;
        }
        O.Leader = Ldr;
        O.GoalNav = Deals[i].LeaderNav;
        O.GoalPoint = Deals[i].LeaderSpot;
        O.Phase = PHASE_ENROUTE;
        O.StartTime = WorldInfo.TimeSeconds;
        // A re-deal that leaves this squad's leader and spot alone must not restart its arrival clock.
        if (Why != "" && PrevNav == O.GoalNav && PrevLeader == Ldr && (PrevPhase == PHASE_ENROUTE || PrevPhase == PHASE_HOLDING))
        {
            O.Phase = PrevPhase;
            O.StartTime = PrevStart;
        }
        for (j = 0; j < Deals[i].FollowerSpots.Length; j++)
        {
            O.Slots.AddItem(j);
            O.SlotLocs.AddItem(Deals[i].FollowerSpots[j]);
        }
        SquadOrders[i] = O;
        if (Deals[i].Role == 0)
        {
            RoleName = "core";
        }
        else if (Deals[i].Role == 1)
        {
            RoleName = "entry";
        }
        else
        {
            RoleName = "reserve";
        }
        EchelonLog("ZONE_ROLE squad=" $ string(i + 1) $ " role=" $ RoleName $ " leader=" $ string(Ldr.Name) $ " spot=" $ CoordStr(O.GoalPoint) $ " slots=" $ string(O.SlotLocs.Length) $ " short=" $ string(Deals[i].Shortage));
    }
    for (i = 0; i < ActiveBots.Length; i++)
    {
        if (ActiveBots[i] != None)
        {
            ActiveBots[i].ObjectiveGoal = None;
        }
    }
}

// The zone is over: clear goals, slots and roles and hand the squads back to the legacy anchors.
function EndZone(string Reason)
{
    local int i;
    local EcholonBot B;

    ZoneCancelPick();
    if (!bZoneActive)
    {
        return;
    }
    EchelonLog("ZONE_END zone=" $ string(ActiveZoneId) $ " reason=" $ Reason $ " held=" $ string(int(WorldInfo.TimeSeconds - ZoneStartTime)));
    bZoneActive = false;
    ActiveZoneId = 0;
    for (i = 0; i < SquadOrders.Length; i++)
    {
        SquadOrders[i].Leader = None;
        SquadOrders[i].Zone = None;
        SquadOrders[i].GoalNav = None;
        SquadOrders[i].GoalPoint = vect(0, 0, 0);
        SquadOrders[i].Slots.Length = 0;
        SquadOrders[i].SlotLocs.Length = 0;
        SquadOrders[i].Role = 0;
        SquadOrders[i].ObjectiveBailUntil = 0.0;
        SquadOrders[i].Phase = PHASE_IDLE;
    }
    ZoneTrackLoc.Length = 0;
    ZoneTrackBad.Length = 0;
    ZoneTrackTurned.Length = 0;
    ZoneTravelLoc.Length = 0;
    foreach WorldInfo.AllControllers(class'EcholonBot', B)
    {
        B.FinishObjective();
    }
}

// Every 0.5 s while a zone is active: log a ZONE_TURN when a leader walks away from its spot for 1 s.
function ZoneTrack()
{
    local int i;
    local SquadOrder O;
    local vector Mv, ToGoal;
    local float Now, CosA;

    Now = WorldInfo.TimeSeconds;
    if (Now - LastZoneTrackTime < 0.5)
    {
        return;
    }
    LastZoneTrackTime = Now;
    if (ZoneTrackLoc.Length != SquadOrders.Length)
    {
        ZoneTrackLoc.Length = SquadOrders.Length;
        ZoneTrackBad.Length = SquadOrders.Length;
        ZoneTrackTurned.Length = SquadOrders.Length;
    }
    for (i = 0; i < SquadOrders.Length; i++)
    {
        O = SquadOrders[i];
        if (O.Leader == None || O.Leader.Pawn == None || O.Phase != PHASE_ENROUTE)
        {
            ZoneTrackBad[i] = 0.0;
            ZoneTrackTurned[i] = false;
            ZoneTrackLoc[i] = vect(0, 0, 0);
            continue;
        }
        Mv = O.Leader.Pawn.Location - ZoneTrackLoc[i];
        Mv.Z = 0.0;
        ToGoal = O.GoalPoint - O.Leader.Pawn.Location;
        ToGoal.Z = 0.0;
        if (ZoneTrackLoc[i] != vect(0, 0, 0) && VSize(Mv) > 40.0 && VSize(ToGoal) > 100.0)
        {
            CosA = (Mv dot ToGoal) / (VSize(Mv) * VSize(ToGoal));
            if (CosA < -0.5)
            {
                if (ZoneTrackBad[i] == 0.0)
                {
                    ZoneTrackBad[i] = Now;
                }
                else if (Now - ZoneTrackBad[i] >= 1.0 && !ZoneTrackTurned[i])
                {
                    ZoneTrackTurned[i] = true;
                    EchelonLog("ZONE_TURN squad=" $ string(i + 1));
                }
            }
            else
            {
                ZoneTrackBad[i] = 0.0;
                ZoneTrackTurned[i] = false;
            }
        }
        ZoneTrackLoc[i] = O.Leader.Pawn.Location;
    }
}

// True when squads have a hold goal: a real map objective or a planner zone.
final function bool HasHoldGoals()
{
    return bObjectiveActive || bZoneActive;
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
        // Planner zone: the squad's goal is its role spot (set by the planner in SquadOrders).
        if ((!bHuntOrderActive && !bZoneActive) || B == None)
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

// ---- Survey mode (?Survey=1): no zeds, survey bots feel the map and fill a shared tile grid ----

// Start of the survey: build the grid, collect hazards and player starts, spawn the survey bots.
function SurveyBegin()
{
    local PhysicsVolume V;
    local PlayerStart PS;
    local int I;

    if (SurveyGrid != None)
    {
        return;
    }
    SurveyGrid = new class'EcholonBot.EcholonSurveyGrid';
    SurveyGrid.Clear();
    SurveyLevelDeaths.Length = 64;
    SurveyDropMax = 180.0;      // until SurveyComputeLimits has read the pawn
    SurveyStepMax = 35.0;
    foreach WorldInfo.AllActors(class'PhysicsVolume', V)
    {
        if (V.bPainCausing || V.bWaterVolume)
        {
            SurveyHazards.AddItem(V);
        }
    }
    foreach WorldInfo.AllActors(class'PlayerStart', PS)
    {
        SurveyStarts.AddItem(PS);
    }
    SurveyStartTime = WorldInfo.TimeSeconds;
    SurveyNextProgress = WorldInfo.TimeSeconds + 30.0;
    for (I = 0; I < SurveyBotsNow; I++)
    {
        SurveyAddBot(I);
    }
    SurveyOpenDoors();
    EchelonLog("SURVEY_BEGIN map=" $ WorldInfo.GetMapName() $ " bots=" $ string(SurveyBotList.Length) $ " starts=" $ string(SurveyStarts.Length)
        $ " hazards=" $ string(SurveyHazards.Length));
    SurveyComputeLimits();
    SurveyBenchmark();
    NavDumpBegin(true);
}

// The deepest drop that does not hurt, from the pawn's own settings: damage starts when the landing speed passes MaxFallSpeed,
// and a fall of h uu lands at sqrt(2 g h), so h = 0.85 MaxFallSpeed^2 / (2 g) with a margin. Logged once.
function SurveyComputeLimits()
{
    local int I, Jumps;
    local Pawn P;
    local float G, V, Apex;

    for (I = 0; I < SurveyBotList.Length; I++)
    {
        if (SurveyBotList[I] != None && SurveyBotList[I].Pawn != None)
        {
            P = SurveyBotList[I].Pawn;
            break;
        }
    }
    if (P == None)
    {
        return;
    }
    G = Abs(P.GetGravityZ());
    if (G < 1.0)
    {
        G = 1150.0;
    }
    V = P.MaxFallSpeed;
    if (V < 1.0)
    {
        V = 1325.0;
    }
    SurveyDropMax = 0.85 * V * V / (2.0 * G);
    if (P.MaxStepHeight > 1.0)
    {
        SurveyStepMax = P.MaxStepHeight;
    }
    SurveyGravityZ = G;
    SurveyMaxFall = V;
    Jumps = 1;
    if (KFPawn(P) != None && KFPawn(P).NumJumpsAllowed > 1)
    {
        Jumps = KFPawn(P).NumJumpsAllowed;
    }
    Apex = P.JumpZ * P.JumpZ / (2.0 * G);
    SurveyJumpReach = (Apex * float(Jumps) + SurveyStepMax) * 0.9;
    EchelonLog("SURVEY_JUMP_LIMITS jump_z=" $ string(int(P.JumpZ)) $ " jumps=" $ string(Jumps) $ " gravity=" $ string(int(G)) $ " apex=" $ string(int(Apex)) $ " step=" $ string(int(SurveyStepMax)) $ " reach=" $ string(int(SurveyJumpReach)));
    EchelonLog("SURVEY_LIMITS safe_fall=" $ string(int(SurveyDropMax)) $ " max_fall_speed=" $ string(int(V)) $ " gravity=" $ string(int(G))
        $ " step=" $ string(int(P.MaxStepHeight)) $ " jump_z=" $ string(int(P.JumpZ)) $ " jump_apex=" $ string(int(P.JumpZ * P.JumpZ / (2.0 * G))));
}

// Opens every door and keeps it open, so doors do not cut the map; each door is logged (SURVEY_DOOR) for the viewer.
function SurveyOpenDoors()
{
    local KFDoorActor Door;
    local int Count, AutoDoors, Welded;
    local Pawn Opener;
    local int J;

    for (J = 0; J < SurveyBotList.Length; J++)
    {
        if (SurveyBotList[J] != None && SurveyBotList[J].Pawn != None)
        {
            Opener = SurveyBotList[J].Pawn;
            break;
        }
    }
    if (Opener == None)
    {
        EchelonLog("SURVEY_DOORS skipped why=no_pawn");
        return;
    }

    foreach WorldInfo.AllActors(class'KFDoorActor', Door)
    {
        Count++;
        if (Door.bAutomaticDoor)
        {
            AutoDoors++;
        }
        if (Door.WeldIntegrity > 0)
        {
            Welded++;
        }
        Door.bCanCloseDoor = false;
        if (!Door.bIsDoorOpen)
        {
            if (Door.bAutomaticDoor)
            {
                // an automatic door opens when a pawn bumps it; with bCanCloseDoor off it then stays open
                Door.Bump(Opener, None, vect(0.0, 0.0, 1.0));
            }
            else
            {
                Door.UseDoor(Opener);
            }
        }
        EchelonLog("SURVEY_DOOR at=" $ string(int(Door.Location.X)) $ "," $ string(int(Door.Location.Y)) $ "," $ string(int(Door.Location.Z))
            $ " auto=" $ string(Door.bAutomaticDoor) $ " welded=" $ string(Door.WeldIntegrity > 0) $ " open=" $ string(Door.bIsDoorOpen));
    }
    EchelonLog("SURVEY_DOORS count=" $ string(Count) $ " automatic=" $ string(AutoDoors) $ " welded=" $ string(Welded));
}

// One survey bot: a controller with a player record, then a pawn at a player start.
function bool SurveyAddBot(int Idx)
{
    local EcholonSurveyBot B;
    local PlayerStart Spot;
    local KFPlayerReplicationInfo PRI;

    if (SurveyStarts.Length == 0)
    {
        EchelonLog("SURVEY_SPAWN_FAIL bot=" $ string(Idx) $ " why=no_player_start");
        return false;
    }
    Spot = SurveyStarts[Idx % SurveyStarts.Length];
    B = Spawn(class'EcholonSurveyBot',,, Spot.Location);
    if (B == None)
    {
        EchelonLog("SURVEY_SPAWN_FAIL bot=" $ string(Idx) $ " why=controller");
        return false;
    }
    B.Setup(self, Idx);
    SurveyBotList.AddItem(B);
    // The scoreboard reads the perk of every player record every frame; without one the log fills with Accessed None.
    PRI = KFPlayerReplicationInfo(B.PlayerReplicationInfo);
    if (PRI != None)
    {
        PRI.CurrentPerkClass = PickBotPerk();
        PRI.PlayerID = KF.GetNextPlayerID();
    }
    KF.GenericPlayerInitialization(B);
    SurveyPlace(B, Spot);
    KF.bOnePlayerAtStart = false;
    KF.ForceLivingPlayerCount(byte(SurveyBotList.Length));
    return true;
}

// Give a survey bot a pawn at a start spot: no inventory, no team collision (traces and bodies pass other bots).
function SurveyPlace(EcholonSurveyBot B, NavigationPoint Spot)
{
    if (B.Pawn == None)
    {
        B.Pawn = KF.SpawnDefaultPawnFor(B, Spot);
    }
    if (B.Pawn == None)
    {
        EchelonLog("SURVEY_SPAWN_FAIL bot=" $ string(B.BotIdx) $ " why=pawn start=" $ string(Spot));
        return;
    }
    B.Pawn.SetAnchor(Spot);
    B.Possess(B.Pawn, false);
    B.Pawn.SetMovementPhysics();
    // the real bots jump higher and twice (EcholonBotBase.Restart); the survey pawns match so the links they find hold for the bots
    B.Pawn.JumpZ = FMax(B.Pawn.JumpZ, 750.0);
    if (KFPawn(B.Pawn) != None)
    {
        KFPawn(B.Pawn).NumJumpsAllowed = 2;
    }
    KF.SetTeam(B, KF.Teams[0]);
    KF.SetPlayerDefaults(B.Pawn);
    if (KFPawn(B.Pawn) != None)
    {
        KFPawn(B.Pawn).bIgnoreTeamCollision = true;
    }
}

// A dead survey bot gets a new pawn at its player start (not where it died: that can be a pit).
function SurveyRespawn(EcholonSurveyBot B)
{
    local PlayerStart Spot;

    if (SurveyStarts.Length == 0)
    {
        return;
    }
    Spot = SurveyStarts[B.BotIdx % SurveyStarts.Length];
    SurveyPlace(B, Spot);
}

// Per frame: refresh the budgets, keep zed spawns off, run every survey bot (the first one rotates).
function SurveyTickAll(float DT)
{
    local int I, K, N;

    SurveyTraceLeft = SurveyTracesNow;
    SurveyBfsLeft = SurveyBfsNow;
    SurveyScanLeft = 12000;
    SurveyFrontierStep();
    if (bPass2Active && SurveyLeads != None && !SurveyLeads.bBuilt)
    {
        SurveyLeads.BuildStep();
    }
    if (KF != None && KF.SpawnManager != None)
    {
        KF.SpawnManager.TimeUntilNextSpawn = 9999.0;
    }
    N = SurveyBotList.Length;
    if (N == 0)
    {
        return;
    }
    for (K = 0; K < N; K++)
    {
        I = (SurveyRot + K) % N;
        if (SurveyBotList[I] != None)
        {
            SurveyBotList[I].SurveyTick(DT);
        }
    }
    SurveyRot++;
    SurveyCostFrames++;
    SurveyCostDt += DT;
    if (DT > SurveyCostDtMax)
    {
        SurveyCostDtMax = DT;
    }
    SurveyCostTraces += SurveyTracesNow - SurveyTraceLeft;
    SurveyCostBfs += SurveyBfsNow - SurveyBfsLeft;
    SurveyCostScan += 12000 - SurveyScanLeft;
    SurveyAccountFrame();
}

// Estimated cost of this frame's survey work (us): traces, search nodes (about 12 grid lookups each) and slot reads, times the unit costs.
function SurveyAccountFrame()
{
    local float Est;

    Est = float(SurveyTracesNow - SurveyTraceLeft) * SurveyUnitTraceUs + float(SurveyBfsNow - SurveyBfsLeft) * 12.0 * SurveyUnitFindUs
        + float(12000 - SurveyScanLeft) * SurveyUnitSlotUs;
    SurveyCostEst += Est;
    if (Est > SurveyCostEstMax)
    {
        SurveyCostEstMax = Est;
    }
    if (Est > 4000.0)
    {
        SurveyCostOver++;
    }
}

// Measure the unit costs once. Actor.Clock returns 0 in the retail game, so the time comes from GetSystemTime (millisecond steps, so
// the loops are long enough): 6000 body-sized traces, 40000 grid lookups (on the empty grid, a little faster than a full one) and
// 200000 hash slot reads.
function SurveyBenchmark()
{
    local int I, Y, Mo, Dw, D, H, Mi, S, Ms, StartMs, EndMs, Sink;
    local float Angle;
    local vector Start, End, Ext, HitLoc, HitNorm;
    local Pawn P;

    for (I = 0; I < SurveyBotList.Length; I++)
    {
        if (SurveyBotList[I] != None && SurveyBotList[I].Pawn != None)
        {
            P = SurveyBotList[I].Pawn;
            break;
        }
    }
    if (P == None || SurveyGrid == None)
    {
        return;
    }
    Start = P.Location;
    Ext.X = 36.0;
    Ext.Y = 36.0;
    Ext.Z = 8.0;
    GetSystemTime(Y, Mo, Dw, D, H, Mi, S, Ms);
    StartMs = ((H * 60 + Mi) * 60 + S) * 1000 + Ms;
    for (I = 0; I < 6000; I++)
    {
        Angle = float(I % 8) * 0.785398;
        End = Start;
        End.X += Cos(Angle) * 400.0;
        End.Y += Sin(Angle) * 400.0;
        Trace(HitLoc, HitNorm, End, Start, true, Ext);
    }
    GetSystemTime(Y, Mo, Dw, D, H, Mi, S, Ms);
    EndMs = ((H * 60 + Mi) * 60 + S) * 1000 + Ms;
    if (EndMs < StartMs)
    {
        EndMs += 86400000;      // the clock passed midnight
    }
    SurveyUnitTraceUs = FMax(0.5, float(EndMs - StartMs) * 1000.0 / 6000.0);
    StartMs = EndMs;
    for (I = 0; I < 40000; I++)
    {
        Sink += SurveyGrid.GetData(SurveyGrid.MakeKey(I % 300 - 150, (I / 300) % 300 - 150, 0)) & 1;
    }
    GetSystemTime(Y, Mo, Dw, D, H, Mi, S, Ms);
    EndMs = ((H * 60 + Mi) * 60 + S) * 1000 + Ms;
    if (EndMs < StartMs)
    {
        EndMs += 86400000;      // the clock passed midnight
    }
    SurveyUnitFindUs = FMax(0.05, float(EndMs - StartMs) * 1000.0 / 40000.0);
    StartMs = EndMs;
    for (I = 0; I < 200000; I++)
    {
        Sink += SurveyGrid.Keys[I % SurveyGrid.Keys.Length] & 1;
    }
    GetSystemTime(Y, Mo, Dw, D, H, Mi, S, Ms);
    EndMs = ((H * 60 + Mi) * 60 + S) * 1000 + Ms;
    if (EndMs < StartMs)
    {
        EndMs += 86400000;      // the clock passed midnight
    }
    SurveyUnitSlotUs = FMax(0.02, float(EndMs - StartMs) * 1000.0 / 200000.0);
    EchelonLog("SURVEY_UNIT_COST trace_us=" $ string(SurveyUnitTraceUs) $ " find_us=" $ string(SurveyUnitFindUs) $ " slot_us=" $ string(SurveyUnitSlotUs) $ " sink=" $ string(Sink));
}

// One shared pass over the grid's slots (12000 a frame, one pass a second at most): the unexplored floor tiles become the list
// idle bots pick a far frontier from, instead of every idle bot reading the whole table itself.
function SurveyFrontierStep()
{
    local int Slot, K, D;

    if (SurveyFrontScan == 0 && WorldInfo.TimeSeconds < SurveyFrontNextAt)
    {
        return;
    }
    while (SurveyFrontScan < SurveyGrid.Keys.Length)
    {
        if (SurveyScanLeft <= 0)
        {
            return;
        }
        SurveyScanLeft--;
        Slot = SurveyFrontScan;
        SurveyFrontScan++;
        K = SurveyGrid.Keys[Slot];
        if (K == 0)
        {
            continue;
        }
        D = SurveyGrid.Data[Slot];
        if ((SurveyGrid.DKind(D) == class'EcholonSurveyGrid'.const.K_FLOOR || SurveyGrid.DKind(D) == class'EcholonSurveyGrid'.const.K_NARROW)
            && (SurveyGrid.DFlags(D) & (class'EcholonSurveyGrid'.const.F_EXPANDED | class'EcholonSurveyGrid'.const.F_BLOCKED)) == 0
            && SurveyLevelDeaths[SurveyGrid.KeyLvl(K) + 32] < 3)
        {
            SurveyFrontBuild.AddItem(K);
        }
    }
    SurveyFrontList = SurveyFrontBuild;
    SurveyFrontBuild.Length = 0;
    SurveyFrontScan = 0;
    SurveyFrontNextAt = WorldInfo.TimeSeconds + 1.0;
}

// 1 s timer: progress line every 30 s, and the end conditions.
function SurveyCheck()
{
    local int I, IdleBots, Alive, Expanded, InLead;
    local float Mins;
    local EcholonSurveyBot B;

    if (SurveyGrid == None || bSurveyDone)
    {
        return;
    }
    Mins = (WorldInfo.TimeSeconds - SurveyStartTime) / 60.0;
    if (KF != None)
    {
        // deaths make the game recount the living players; without them it would end the wave as a wipe
        KF.ForceLivingPlayerCount(byte(SurveyBotList.Length));
    }
    if (WorldInfo.TimeSeconds >= SurveyNextProgress)
    {
        SurveyNextProgress = WorldInfo.TimeSeconds + 30.0;
        SurveyLogCost();
        EchelonLog("SURVEY_PROGRESS mins=" $ string(int(Mins)) $ " tiles=" $ string(SurveyGrid.Used) $ " floor=" $ string(SurveyGrid.KindCount[1])
            $ " wall=" $ string(SurveyGrid.KindCount[3]) $ " hidden=" $ string(SurveyGrid.HiddenCount) $ " " $ SurveyStatTotals());
    }
    for (I = 0; I < SurveyBotList.Length; I++)
    {
        B = SurveyBotList[I];
        if (B != None && B.PawnOk())
        {
            Alive++;
            if (B.Phase == B.SP_IDLE && B.IdleFails >= 3)
            {
                IdleBots++;
            }
            if (B.Phase == B.SP_LEAD)
            {
                InLead++;
            }
        }
    }
    if (WorldInfo.TimeSeconds - SurveyStartTime > 60.0 && WorldInfo.TimeSeconds - SurveyGrowthCheckAt >= 60.0)
    {
        // growth is 0.1 percent of the expanded tiles (at least 30) in the last minute, or in pass 2 a lead that finished; a
        // trickle does not keep the survey alive (Paris and Dystopia trickled for 15 minutes after they were mapped)
        Expanded = SurveyExpandedTotal();
        if (Expanded - SurveyLastExpanded >= Max(30, Expanded / 1000) || SurveyLastGrowth == 0.0)
        {
            SurveyLastGrowth = WorldInfo.TimeSeconds;
        }
        if (bPass2Active && SurveyLeads != None && SurveyLeads.NOk + SurveyLeads.NFailed > SurveyLastLeadsDone)
        {
            SurveyLastLeadsDone = SurveyLeads.NOk + SurveyLeads.NFailed;
            SurveyLastGrowth = WorldInfo.TimeSeconds;
        }
        SurveyLastExpanded = Expanded;
        SurveyGrowthCheckAt = WorldInfo.TimeSeconds;
    }
    if (bSurveyStopReq)
        SurveyFinish("stop");
    else if (SurveyGrid.bFull)
        SurveyFinish("grid_full");
    else if (Mins >= float(SurveyMinutesNow))
        SurveyFinish("time");
    else if (bPass2Allowed && !bPass2Active && NavDump != None && NavDump.bDone
        && (bSurveyPass2Req || (SurveyPass1Mins > 0 && Mins >= float(SurveyPass1Mins))
            || (SurveyLastGrowth > 0.0 && WorldInfo.TimeSeconds - SurveyLastGrowth > 180.0) || (Alive > 0 && IdleBots == Alive)))
        SurveyPass2Begin();
    else if (bPass2Active && SurveyLeads != None && !SurveyLeads.bBuilt)
        return;      // the lead list is still being built: the idle bots are waiting for it
    else if (bPass2Active && SurveyLeads != None && SurveyLeads.Remaining() == 0 && InLead == 0 && SurveyLeads.NOkRound > 0 && SurveyLeads.Round < 8)
    {
        // every lead of this round is done and some worked: they opened new floor, so read the links again for the next round
        EchelonLog("SURVEY_PASS2 round=" $ string(SurveyLeads.Round) $ " done ok=" $ string(SurveyLeads.NOkRound) $ " tiles=" $ string(SurveyGrid.Used));
        SurveyLeads.Rebuild();
        SurveyLastGrowth = WorldInfo.TimeSeconds;
    }
    else if (SurveyLastGrowth > 0.0 && WorldInfo.TimeSeconds - SurveyLastGrowth > 180.0)
        SurveyFinish("stalled");
    else if (Alive > 0 && IdleBots == Alive)
        SurveyFinish("no_frontier");
}

// Pass 1 has stalled: build the lead list from the designer's links and let the idle bots try them (pass 2).
function SurveyPass2Begin()
{
    local int I;

    bPass2Active = true;
    SurveyPass2Tiles0 = SurveyGrid.Used;
    SurveyLeads = new class'EcholonBot.EcholonSurveyLeads';
    SurveyLeads.Begin(self);
    SurveyLastGrowth = WorldInfo.TimeSeconds;
    SurveyLastExpanded = SurveyExpandedTotal();
    for (I = 0; I < SurveyBotList.Length; I++)
    {
        if (SurveyBotList[I] != None)
        {
            SurveyBotList[I].IdleFails = 0;
        }
    }
    EchelonLog("SURVEY_PASS2 begin tiles=" $ string(SurveyGrid.Used) $ " nodes=" $ string(SurveyLeads.Nodes.Length) $ " jump_reach=" $ string(int(SurveyJumpReach)));
}

// SURVEY_COST every 30 s: the frame time while the survey runs (Actor.Clock returns 0 in the retail game, so the frame delta is the
// measure) and the average work per frame against the budgets.
function SurveyLogCost()
{
    local float N;
    local int A10;

    if (SurveyCostFrames <= 0)
    {
        return;
    }
    N = float(SurveyCostFrames);
    A10 = int(SurveyCostDt / N * 10000.0);
    EchelonLog("SURVEY_COST frames=" $ string(SurveyCostFrames) $ " est_avg_us=" $ string(int(SurveyCostEst / N)) $ " est_max_us=" $ string(int(SurveyCostEstMax))
        $ " over_4ms=" $ string(SurveyCostOver) $ " traces_avg=" $ string(int(float(SurveyCostTraces) / N)) $ "/" $ string(SurveyTracesNow)
        $ " bfs_avg=" $ string(int(float(SurveyCostBfs) / N)) $ "/" $ string(SurveyBfsNow) $ " scan_avg=" $ string(int(float(SurveyCostScan) / N)) $ "/12000"
        $ " front=" $ string(SurveyFrontList.Length) $ " frame_ms_avg=" $ string(A10 / 10) $ "." $ string(A10 % 10) $ " (frame time includes the cap, not only the survey)");
    SurveyCostFrames = 0;
    SurveyCostDt = 0.0;
    SurveyCostDtMax = 0.0;
    SurveyCostTraces = 0;
    SurveyCostBfs = 0;
    SurveyCostScan = 0;
    SurveyCostEst = 0.0;
    SurveyCostEstMax = 0.0;
    SurveyCostOver = 0;
}

// Tiles all bots have expanded so far.
function int SurveyExpandedTotal()
{
    local int I, Total;

    for (I = 0; I < SurveyBotList.Length; I++)
    {
        if (SurveyBotList[I] != None)
        {
            Total += SurveyBotList[I].NExpanded;
        }
    }
    return Total;
}

// Summed bot counters for the progress and done lines.
function string SurveyStatTotals()
{
    local int I, Ex, Hid, Stk, Byb, Tel, Dea, Trc, Idl;
    local EcholonSurveyBot B;

    for (I = 0; I < SurveyBotList.Length; I++)
    {
        B = SurveyBotList[I];
        if (B == None)
        {
            continue;
        }
        Ex += B.NExpanded;
        Hid += B.NHidden;
        Stk += B.NStuck;
        Byb += B.NBlockedByBot;
        Tel += B.NTeleports;
        Dea += B.NDeaths;
        Trc += B.NTraces;
        if (B.Phase == B.SP_IDLE)
        {
            Idl++;
        }
    }
    return "expanded=" $ string(Ex) $ " bot_hidden=" $ string(Hid) $ " stuck=" $ string(Stk) $ " bybot=" $ string(Byb) $ " teleports=" $ string(Tel)
        $ " deaths=" $ string(Dea) $ " traces=" $ string(Trc) $ " idle=" $ string(Idl);
}

// End of the survey: stop the bots, log the summary, then write the grid rows to the log over the next frames.
function SurveyFinish(string Reason)
{
    local int I;

    if (bSurveyDone)
    {
        return;
    }
    bSurveyDone = true;
    SurveyDoneReason = Reason;
    for (I = 0; I < SurveyBotList.Length; I++)
    {
        if (SurveyBotList[I] != None && SurveyBotList[I].Pawn != None)
        {
            SurveyBotList[I].Pawn.Acceleration = vect(0.0, 0.0, 0.0);
        }
    }
    EchelonLog("SURVEY_DONE reason=" $ Reason $ " mins=" $ string(int((WorldInfo.TimeSeconds - SurveyStartTime) / 60.0)) $ " tiles=" $ string(SurveyGrid.Used)
        $ " floor=" $ string(SurveyGrid.KindCount[1]) $ " steep=" $ string(SurveyGrid.KindCount[2]) $ " wall=" $ string(SurveyGrid.KindCount[3])
        $ " obstacle=" $ string(SurveyGrid.KindCount[4]) $ " drop=" $ string(SurveyGrid.KindCount[5]) $ " door=" $ string(SurveyGrid.KindCount[6])
        $ " hidden=" $ string(SurveyGrid.HiddenCount) $ " " $ SurveyStatTotals());
    EchelonLog("GRID_START tile=" $ string(int(class'EcholonSurveyGrid'.const.TILE)) $ " level_h=" $ string(int(class'EcholonSurveyGrid'.const.LEVEL_H))
        $ " tx=" $ string(SurveyGrid.MinTX) $ ".." $ string(SurveyGrid.MaxTX) $ " ty=" $ string(SurveyGrid.MinTY) $ ".." $ string(SurveyGrid.MaxTY)
        $ " lvl=" $ string(SurveyGrid.MinLvl) $ ".." $ string(SurveyGrid.MaxLvl) $ " tiles=" $ string(SurveyGrid.Used)
        $ " chars=5 order=kind,flagsLow,flagsHigh,zLow,zHigh");
    SurveyExpLvl = SurveyGrid.MinLvl;
    SurveyExpTY = SurveyGrid.MinTY;
    SurveyExpTX = SurveyGrid.MinTX;
    SurveyExpRows = 0;
    SurveyExpTiles = 0;
    SurveyExpSlot = 0;
    SurveyExpPhase = 0;
    if (bPass2Active && SurveyLeads != None)
    {
        EchelonLog("SURVEY_PASS2 end leads=" $ string(SurveyLeads.List.Length) $ " ok=" $ string(SurveyLeads.NOk) $ " failed=" $ string(SurveyLeads.NFailed) $ " left=" $ string(SurveyLeads.Remaining())
            $ " tiles_gained=" $ string(SurveyGrid.Used - SurveyPass2Tiles0) $ " passage_tiles=" $ string(SurveyPassageTiles));
    }
    SurveyRowMark.Length = 0;
    SurveyRowMark.Length = 262144;
    if (SurveyGrid.ClampCount > 0)
    {
        EchelonLog("SURVEY_CLAMP count=" $ string(SurveyGrid.ClampCount) $ " note=map_outside_tile_level_or_height_range");
    }
    SurveyLogCost();
    bSurveyExporting = SurveyGrid.Used > 0;
    if (!bSurveyExporting)
    {
        SurveyExportDone();
    }
}

// Moves the export cursor to the start of the next row; false when there are no more rows.
function bool SurveyExpNextRow()
{
    SurveyExpTX = SurveyGrid.MinTX;
    SurveyExpTY++;
    if (SurveyExpTY > SurveyGrid.MaxTY)
    {
        SurveyExpTY = SurveyGrid.MinTY;
        SurveyExpLvl++;
        if (SurveyExpLvl > SurveyGrid.MaxLvl)
        {
            return false;
        }
    }
    return true;
}

// Export in two phases: first find which (level, row) pairs hold any tile (20000 slots a frame), then write only those rows as
// GRID_ROW lines (6 chunks of 100 tiles a frame), so one stray tile far away does not make the export walk an empty bounding box.
function SurveyExportStep()
{
    local int Chunks, Known, Skips, Slot, K;
    local string Data;

    if (SurveyExpPhase == 0)
    {
        for (Skips = 0; Skips < 20000 && SurveyExpSlot < SurveyGrid.Keys.Length; Skips++)
        {
            Slot = SurveyExpSlot;
            SurveyExpSlot++;
            K = SurveyGrid.Keys[Slot];
            if (K != 0)
            {
                SurveyRowMark[(SurveyGrid.KeyLvl(K) + 32) * 4096 + SurveyGrid.KeyTY(K) + 2048] = 1;
            }
        }
        if (SurveyExpSlot >= SurveyGrid.Keys.Length)
        {
            SurveyExpPhase = 1;
        }
        return;
    }
    Chunks = 0;
    Skips = 0;
    while (Chunks < 6 && Skips < 3000)
    {
        if (SurveyRowMark[(SurveyExpLvl + 32) * 4096 + SurveyExpTY + 2048] == 0)
        {
            Skips++;
            if (!SurveyExpNextRow())
            {
                bSurveyExporting = false;
                SurveyExportDone();
                return;
            }
            continue;
        }
        Data = SurveyGrid.RowChunk(SurveyExpLvl, SurveyExpTY, SurveyExpTX, 100, Known);
        if (Known > 0)
        {
            EchelonLog("GRID_ROW level=" $ string(SurveyExpLvl) $ " y=" $ string(SurveyExpTY) $ " x0=" $ string(SurveyExpTX) $ " data=" $ Data);
            SurveyExpRows++;
            SurveyExpTiles += Known;
        }
        Chunks++;
        SurveyExpTX += 100;
        if (SurveyExpTX > SurveyGrid.MaxTX && !SurveyExpNextRow())
        {
            bSurveyExporting = false;
            SurveyExportDone();
            return;
        }
    }
}

// The grid is in the log: tell the playtest runner the run is over.
function SurveyExportDone()
{
    EchelonLog("GRID_DONE rows=" $ string(SurveyExpRows) $ " tiles=" $ string(SurveyExpTiles) $ " reason=" $ SurveyDoneReason);
    if (bPlaytest && !bPlaytestDone)
    {
        EchelonLog("PLAYTEST_DONE reason=survey waves_done=0");
        bPlaytestDone = true;
        SetTimer(5.0, false, 'PlaytestQuit');
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
        else if (MutateString ~= "SurveyStop")
        {
            bSurveyStopReq = true;
            PMsg(Sender, "Survey: stop requested");
        }
        else if (MutateString ~= "SurveyPass2")
        {
            bSurveyPass2Req = true;
            PMsg(Sender, "Survey: pass 2 requested");
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
    if (bZoneActive)
    {
        return ZoneCenterLoc;
    }
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
        if (PathNode(N) == None || SurveyNodeInWall(N))
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
