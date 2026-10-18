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
var KFGameInfo_Survival KF;
var Actor PrevObjective;
var array<NavigationPoint> ValidPoints;
var KFMapObjective_DoshHold HoldVolume;
var int MaxEmoteCount;
var float NextVictoryDance;
var bool bNewWave;
var bool bObjectiveActive;
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
var array<KFPawn_Human> RangedHealTargets;
var array<float> RangedHealCooldownEnds;
var transient array<string> AvailableBotNames;
var transient array<Class<KFPerk> > PerkPool;
var transient array<int> PerkPoolCounts;
var float LastAuditLogTime;

function EchelonLog(string Msg)
{
    if (WorldInfo == None)
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
        for (I = 0; I < NumBots; ++I)
        {
            AddBot();
        }
    }
    else
    {
        SetTimer(1.0, true);
    }
    SetTimer(0.1, true, 'CheckWave');
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
        else if (Bot == VIPController)
            Bot.BotRank = CAPTAIN;
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
    local NavigationPoint FoundNav;

    foreach WorldInfo.RadiusNavigationPoints(class'NavigationPoint', FoundNav, ProjectedLoc, SearchRadius)
    {
        return FoundNav;
    }

    return None;
}

function NavigationPoint FindNearestChokepoint(Controller VIP)
{
    local vector ProjectedLoc, LateralVec;
    local NavigationPoint FoundNav;

    if (VIP == None || VIP.Pawn == None)
        return None;

    LateralVec = Normal(vector(VIP.Pawn.Rotation) cross vect(0,0,1));
    ProjectedLoc = VIP.Pawn.Location + (LateralVec * CHOKEPOINT_LATERAL_OFFSET);

    foreach WorldInfo.RadiusNavigationPoints(class'NavigationPoint', FoundNav, ProjectedLoc, NAV_SEARCH_RADIUS)
    {
        return FoundNav;
    }
    return None;
}

// @STUB(M4) @SYS-MUT-PLATOON legacy:KF2BotsMut.GetVIPController
function Controller GetVIPController()
{
}

// @STUB(M4) @SYS-MUT-PLATOON legacy:KF2BotsMut.FindBossPawn
function Pawn FindBossPawn()
{
}

// @STUB(M4) @SYS-MUT-SUCCESSION legacy:KF2BotsMut.OnBotKilled
function OnBotKilled(EcholonBot DeadBot)
{
}

// @STUB(M4) @SYS-MUT-SUCCESSION legacy:KF2BotsMut.ComputeCommandScore
function int ComputeCommandScore(EcholonBot Bot)
{
}

// @STUB(M4) @SYS-MUT-SUCCESSION legacy:KF2BotsMut.FindBestCandidate
function EcholonBot FindBestCandidate(array<EcholonBot> Candidates)
{
}

// @STUB(M4) @SYS-MUT-SUCCESSION legacy:KF2BotsMut.FindExpendableMember
function EcholonBot FindExpendableMember(array<EcholonBot> Candidates)
{
}

// @STUB(M4) @SYS-MUT-SUCCESSION legacy:KF2BotsMut.ProcessPromotionQueue
function ProcessPromotionQueue()
{
}

// @STUB(M4) @SYS-MUT-SUCCESSION legacy:KF2BotsMut.PromoteBot
function PromoteBot(EcholonBot Bot, EBotRank NewRank)
{
}

// @STUB(M4) @SYS-MUT-HEALCOOL legacy:KF2BotsMut.RegisterRangedHealTarget
function RegisterRangedHealTarget(KFPawn_Human Target)
{
}

// @STUB(M4) @SYS-MUT-HEALCOOL legacy:KF2BotsMut.IsRangedHealTargetOnCooldown
function bool IsRangedHealTargetOnCooldown(KFPawn_Human Target)
{
}

// @STUB(M4) @SYS-MUT-HEALCOOL legacy:KF2BotsMut.CleanupRangedHealCooldowns
function CleanupRangedHealCooldowns()
{
}

// @STUB(M4) @SYS-MUT-SUCCESSION legacy:KF2BotsMut.HandleVIPSuccession
function HandleVIPSuccession()
{
}

// @STUB(M4) @SYS-MUT-SUCCESSION legacy:KF2BotsMut.HandleFireteamCasualty
function HandleFireteamCasualty(EcholonBot DeadBot)
{
}

// @STUB(M4) @SYS-MUT-SUCCESSION legacy:KF2BotsMut.DemoteGroupLeader
function DemoteGroupLeader(EcholonBot OldLeader)
{
}

// @STUB(M4) @SYS-MUT-SUCCESSION legacy:KF2BotsMut.RequestLeaderDemotion
function RequestLeaderDemotion(EcholonBot StuckLeader)
{
}

// @STUB(M4) @SYS-MUT-SUCCESSION legacy:KF2BotsMut.ConsolidateFireteams
function ConsolidateFireteams()
{
}

// @STUB(M4) @SYS-MUT-SUCCESSION legacy:KF2BotsMut.PullBotFromNearestGroup
function PullBotFromNearestGroup(int TargetGroupIdx)
{
}

// @STUB(M4) @SYS-MUT-SUCCESSION legacy:KF2BotsMut.DissolveGroup
function DissolveGroup(int GroupIdx)
{
}

// @STUB(M4) @SYS-MUT-SUCCESSION legacy:KF2BotsMut.FindNearestEligibleGroup
function int FindNearestEligibleGroup(int ExcludeGroupIdx, EcholonBot Bot)
{
}

// @STUB(M4) @SYS-MUT-SUCCESSION legacy:KF2BotsMut.ReassignBotToGroup
function ReassignBotToGroup(EcholonBot Bot, int NewGroupIdx)
{
}

// @STUB(M4) @SYS-MUT-SUCCESSION legacy:KF2BotsMut.GetGroupLeader
function EcholonBot GetGroupLeader(int GroupID)
{
}

// @STUB(M4) @SYS-MUT-SUCCESSION legacy:KF2BotsMut.GetGroupSize
function int GetGroupSize(int GroupID)
{
}

// @STUB(M4) @SYS-MUT-SUCCESSION legacy:KF2BotsMut.GetFollowerIndex
function int GetFollowerIndex(EcholonBot Bot)
{
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

    EvaluateSquadPhase();
}

// @STUB(M4) @SYS-MUT-WAVE legacy:KF2BotsMut.SetHoldObjective
final function SetHoldObjective(Volume V)
{
}

// @STUB(M4) @SYS-MUT-WAVE legacy:KF2BotsMut.EndObjective
final function EndObjective()
{
}

// @STUB(M4) @SYS-MUT-WAVE legacy:KF2BotsMut.NearestValidPoint
function NavigationPoint NearestValidPoint(vector Loc)
{
}

function string CoordStr(vector L)
{
    return string(FFloor(L.X / 100.0)) $ "," $ string(FFloor(L.Y / 100.0)) $ "," $ string(FFloor(L.Z / 100.0));
}

// @STUB(M4) @SYS-MUT-ORDERS legacy:KF2BotsMut.EnsureSquadOrderTable
function EnsureSquadOrderTable()
{
}

// @STUB(M4) @SYS-MUT-ORDERS legacy:KF2BotsMut.InheritSquadOrder
function InheritSquadOrder(int GroupIdx, EcholonBot NewLeader)
{
}

// @STUB(M4) @SYS-MUT-ORDERS legacy:KF2BotsMut.SampleSquadSlots
function SampleSquadSlots(int GroupIdx)
{
}

// @STUB(M4) @SYS-MUT-ORDERS legacy:KF2BotsMut.ReleaseSquadSlots
function ReleaseSquadSlots(int GroupIdx, string Reason)
{
}

// @STUB(M4) @SYS-MUT-SUCCESSION legacy:KF2BotsMut.GetFollowerBySlot
function EcholonBot GetFollowerBySlot(int GroupIdx, int SlotIdx)
{
}

// @STUB(M4) @SYS-MUT-ORDERS legacy:KF2BotsMut.GetSquadPhase
function int GetSquadPhase(EcholonBot B)
{
}

// @STUB(M4) @SYS-MUT-ORDERS legacy:KF2BotsMut.IsSquadInObjectivePhase
function bool IsSquadInObjectivePhase(EcholonBot B)
{
}

// @STUB(M4) @SYS-MUT-ORDERS legacy:KF2BotsMut.GetSlotLocation
function vector GetSlotLocation(EcholonBot B)
{
}

// @STUB(M4) @SYS-MUT-ORDERS legacy:KF2BotsMut.EvaluateSquadPhase
function EvaluateSquadPhase()
{
}

// @STUB(M4) @SYS-MUT-ORDERS legacy:KF2BotsMut.HasSquadGoal
function bool HasSquadGoal(EcholonBot B)
{
}

// @STUB(M4) @SYS-MUT-ORDERS legacy:KF2BotsMut.ReissueSquadOrder
function ReissueSquadOrder(EcholonBot B)
{
}

// @STUB(M4) @SYS-MUT-REGROUP legacy:KF2BotsMut.FindNearestActiveLeader
function Controller FindNearestActiveLeader(EcholonBot B, float MaxDist)
{
}

// @STUB(M4) @SYS-MUT-REGROUP legacy:KF2BotsMut.CountZedsInRadius
function int CountZedsInRadius(vector Origin, float Radius)
{
}

// @STUB(M4) @SYS-MUT-REGROUP legacy:KF2BotsMut.EvaluateRegroupEntries
function EvaluateRegroupEntries()
{
}

// @STUB(M4) @SYS-MUT-REGROUP legacy:KF2BotsMut.GetSquadStartTime
function float GetSquadStartTime(EcholonBot B)
{
}

// @STUB(M4) @SYS-MUT-REGROUP legacy:KF2BotsMut.MoveSquadMembers
function int MoveSquadMembers(int FromIdx, int ToIdx)
{
}

// @STUB(M4) @SYS-MUT-ORDERS legacy:KF2BotsMut.GetBotObjective
final function NavigationPoint GetBotObjective(EcholonBot B)
{
}

// @STUB(M4) @SYS-MUT-NODEBLOCK legacy:KF2BotsMut.IsNodeBlocked
function bool IsNodeBlocked(EcholonBot OwnerBot, NavigationPoint Node)
{
}

// @STUB(M4) @SYS-MUT-NODEBLOCK legacy:KF2BotsMut.AddNodeBlock
function AddNodeBlock(EcholonBot OwnerBot, NavigationPoint Node)
{
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
        EchelonLog("failed to spawn player at " $ string(StartSpot));
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

// @STUB(M4) @SYS-MUT-PLATOON legacy:KF2BotsMut.CacheHumans
function CacheHumans()
{
}

// @STUB(M4) @SYS-MUT-PLATOON legacy:KF2BotsMut.CacheHumanPositions
function CacheHumanPositions()
{
}

// @STUB(M4) @SYS-MUT-WAVE legacy:KF2BotsMut.GetObjectiveLocation
function vector GetObjectiveLocation()
{
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

function RelocateBotsToAmmoCrates()
{
    local int i, j, NumFactories, GroupIdx;
    local array<KFPickupFactory> AmmoFactories;
    local KFPickupFactory Temp;
    local EcholonBot Bot;
    local vector AnchorPos;

    if (ActiveBots.Length == 0)
        return;

    AmmoFactories.Length = 0;
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

    for (i = 0; i < NumFactories; i++)
    {
        j = i + Rand(NumFactories - i);
        Temp = AmmoFactories[i];
        AmmoFactories[i] = AmmoFactories[j];
        AmmoFactories[j] = Temp;
    }

    for (GroupIdx = 0; GroupIdx < Fireteams.Length; GroupIdx++)
    {
        if (GroupIdx >= NumFactories)
            break;
        AnchorPos = AmmoFactories[GroupIdx].Location;

        for (i = 0; i < Fireteams[GroupIdx].Members.Length; i++)
        {
            Bot = Fireteams[GroupIdx].Members[i];
            if (Bot == None || Bot.Pawn == None)
                continue;
            if (!Bot.bJustSpawned)
                continue;

            if (Bot.bIsGroupLeader)
            {
                Bot.Pawn.SetLocation(AnchorPos);
            }
            else
            {
                Bot.Pawn.SetLocation(PickSquadSpawnPoint(AnchorPos, 90.0, 150.0));
            }
        }
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
