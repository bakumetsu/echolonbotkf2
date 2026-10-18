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

// @STUB(M1) @SYS-MUT-UTIL legacy:KF2BotsMut.EchelonLog
function EchelonLog(string Msg)
{
}

// @STUB(M1) @SYS-MUT-BOOT legacy:KF2BotsMut.PostBeginPlay
function PostBeginPlay()
{
}

// @STUB(M1) @SYS-MUT-BOOT legacy:KF2BotsMut.AddMutator
function AddMutator(Mutator M)
{
}

// @STUB(M1) @SYS-MUT-BOOT legacy:KF2BotsMut.MatchStarting
function MatchStarting()
{
}

// @STUB(M1) @SYS-MUT-BOOT legacy:KF2BotsMut.Timer
function Timer()
{
}

// @STUB(M1) @SYS-MUT-SPAWN legacy:KF2BotsMut.RegisterBot
function RegisterBot(EcholonBot NewBot)
{
}

// @STUB(M1) @SYS-MUT-SPAWN legacy:KF2BotsMut.UnregisterBot
function UnregisterBot(EcholonBot LeavingBot)
{
}

// @STUB(M4) @SYS-MUT-WAVE legacy:KF2BotsMut.PollWaveStart
function PollWaveStart()
{
}

// @STUB(M4) @SYS-MUT-PLATOON legacy:KF2BotsMut.InitializePlatoon
function InitializePlatoon()
{
}

// @STUB(M4) @SYS-MUT-PLATOON legacy:KF2BotsMut.SyncSquadLeaders
function SyncSquadLeaders()
{
}

// @STUB(M4) @SYS-MUT-PLATOON legacy:KF2BotsMut.ShuffleActiveBots
function ShuffleActiveBots()
{
}

// @STUB(M4) @SYS-MUT-PLATOON legacy:KF2BotsMut.PruneInvalidBots
function PruneInvalidBots()
{
}

// @STUB(M4) @SYS-MUT-PLATOON legacy:KF2BotsMut.DetermineGroupCount
function int DetermineGroupCount(int BotCount)
{
}

// @STUB(M4) @SYS-MUT-PLATOON legacy:KF2BotsMut.UpdateMacroWaypoints
function UpdateMacroWaypoints()
{
}

// @STUB(M4) @SYS-MUT-PLATOON legacy:KF2BotsMut.PropagateAnchorToFollowers
function PropagateAnchorToFollowers(int GroupIdx)
{
}

// @STUB(M4) @SYS-MUT-PLATOON legacy:KF2BotsMut.FindNearestNavPoint
function NavigationPoint FindNearestNavPoint(vector ProjectedLoc, float SearchRadius)
{
}

// @STUB(M4) @SYS-MUT-PLATOON legacy:KF2BotsMut.FindNearestChokepoint
function NavigationPoint FindNearestChokepoint(Controller VIP)
{
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

// @STUB(M1) @SYS-MUT-UTIL legacy:KF2BotsMut.BroadcastSpottedEnemy
function BroadcastSpottedEnemy(int GroupID, Pawn Spotted)
{
}

// @STUB(M4) @SYS-MUT-WAVE legacy:KF2BotsMut.CheckWave
function CheckWave()
{
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

// @STUB(M1) @SYS-MUT-UTIL legacy:KF2BotsMut.CoordStr
function string CoordStr(vector L)
{
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

// @STUB(M1) @SYS-MUT-UTIL legacy:KF2BotsMut.InitTraderList
final function InitTraderList(KFGFxObject_TraderItems L)
{
}

// @STUB(M1) @SYS-MUT-UTIL legacy:KF2BotsMut.FindWeaponByClass
final function EcholonWeaponInfo FindWeaponByClass(Class<KFWeapon> W)
{
}

// @STUB(M1) @SYS-MUT-SPAWN legacy:KF2BotsMut.RespawnBots
final function RespawnBots()
{
}

// @STUB(M1) @SYS-MUT-SPAWN legacy:KF2BotsMut.PickCustomBotName
final function string PickCustomBotName()
{
}

// @STUB(M1) @SYS-MUT-SPAWN legacy:KF2BotsMut.InitBotCharacter
final function InitBotCharacter(EcholonBot Bot)
{
}

// @STUB(M1) @SYS-MUT-PERK legacy:KF2BotsMut.PickFallbackPerk
final function Class<KFPerk> PickFallbackPerk()
{
}

// @STUB(M1) @SYS-MUT-PERK legacy:KF2BotsMut.ResolvePerkByName
final function Class<KFPerk> ResolvePerkByName(string PerkName)
{
}

// @STUB(M1) @SYS-MUT-PERK legacy:KF2BotsMut.ResetPerkPool
final function ResetPerkPool()
{
}

// @STUB(M1) @SYS-MUT-PERK legacy:KF2BotsMut.PickBotPerk
final function Class<KFPerk> PickBotPerk()
{
}

// @STUB(M1) @SYS-MUT-SPAWN legacy:KF2BotsMut.AddBot
final function bool AddBot()
{
}

// @STUB(M1) @SYS-MUT-SPAWN legacy:KF2BotsMut.RemoveBot
final function RemoveBot()
{
}

// @STUB(M1) @SYS-MUT-SPAWN legacy:KF2BotsMut.RestartBot
final function RestartBot(EcholonBot NewPlayer, optional NavigationPoint StartSpot)
{
}

// @STUB(M1) @SYS-MUT-UTIL legacy:KF2BotsMut.DebugMessage
static final function DebugMessage(string msg)
{
}

// @STUB(M1) @SYS-MUT-UTIL legacy:KF2BotsMut.PMsg
final function PMsg(PlayerController Other, string msg)
{
}

// @STUB(M1) @SYS-MUT-UTIL legacy:KF2BotsMut.DebugAI
final function DebugAI(PlayerController Sender)
{
}

// @STUB(M1) @SYS-MUT-SPAWN legacy:KF2BotsMut.Mutate
function Mutate(string MutateString, PlayerController Sender)
{
}

// @STUB(M1) @SYS-MUT-SPAWN legacy:KF2BotsMut.NetDamage
function NetDamage(int OriginalDamage, out int Damage, Pawn injured, Controller InstigatedBy, Vector HitLocation, out Vector Momentum, Class<DamageType> DamageType, Actor DamageCauser)
{
}

// @STUB(M1) @SYS-MUT-BOOT legacy:KF2BotsMut.InitEmotes
final function InitEmotes()
{
}

// @STUB(M1) @SYS-MUT-BOOT legacy:KF2BotsMut.PickRandEmote
final function byte PickRandEmote()
{
}

// @STUB(M1) @SYS-MUT-BOOT legacy:KF2BotsMut.ShouldDoVictoryDance
final function bool ShouldDoVictoryDance()
{
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

// @STUB(M1) @SYS-MUT-SPAWN legacy:KF2BotsMut.SetupSquadSpawns
function SetupSquadSpawns(int NumSquads)
{
}

// @STUB(M1) @SYS-MUT-SPAWN legacy:KF2BotsMut.RelocateBotsToAmmoCrates
function RelocateBotsToAmmoCrates()
{
}

// @STUB(M1) @SYS-MUT-SPAWN legacy:KF2BotsMut.SpawnSquadAt
function SpawnSquadAt(vector AnchorPos, int SquadIndex)
{
}

// @STUB(M1) @SYS-MUT-SPAWN legacy:KF2BotsMut.PickSquadSpawnPoint
function vector PickSquadSpawnPoint(vector AnchorPos, float MinR, float MaxR)
{
}

// @STUB(M1) @SYS-MUT-SPAWN legacy:KF2BotsMut.SpawnBotWithRank
function EcholonBot SpawnBotWithRank(EBotRank Rank, vector SpawnPos)
{
}

// @STUB(M1) @SYS-MUT-SPAWN legacy:KF2BotsMut.HideAllPickups
function HideAllPickups()
{
}

// @STUB(M1) @SYS-MUT-SPAWN legacy:KF2BotsMut.ReEnableAmmoFactories
function ReEnableAmmoFactories()
{
}

defaultproperties
{
    MaxEmoteCount=-1
}
