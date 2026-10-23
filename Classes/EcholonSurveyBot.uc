// EcholonSurveyBot - a blind explorer for survey mode (mutator flag bSurvey).
// It knows no path nodes and no map data. It feels the world with very short traces ("the cane"), records
// what it finds in the shared tile map (EcholonSurveyGrid on the mutator), and walks tile by tile to the
// nearest tile whose neighbours have not been felt yet (the frontier). It does not use or change the
// bot nav code (follow, hub, recovery). Movement is raw Pawn.Acceleration steering; everything is driven
// from the mutator's Tick through SurveyTick, which keeps the per-frame trace budget shared by all bots.
// Phases: SP_WAIT (no pawn yet), SP_EXPAND (feeling the 8 neighbours of the current tile), SP_PLAN
// (breadth-first search over known walkable links to the nearest frontier), SP_WALK, SP_IDLE (no frontier
// reachable now), SP_DEAD (waiting to be respawned).
class EcholonSurveyBot extends AIController;

const SP_WAIT = 0;
const SP_EXPAND = 1;
const SP_PLAN = 2;
const SP_WALK = 3;
const SP_IDLE = 4;
const SP_DEAD = 5;
// Copies of the tile constants in EcholonSurveyGrid (keep in sync with that class).
const TILE = 38.0;
const K_FLOOR = 1;
const K_STEEP = 2;
const K_WALL = 3;
const K_OBST = 4;
const K_DROP = 5;
const K_DOOR = 6;
const F_STEP = 16;
const F_CEIL = 32;
const F_HAZARD = 64;
const F_MOVER = 128;
const F_HIDDEN = 256;
const F_EXPANDED = 512;
const F_VISITED = 1024;
const F_ONEWAY = 2048;
const F_UNSAFE = 4096;
const F_BLOCKED = 8192;
const MOMENTUM = 0.25;      // seconds a bot keeps moving after a path ends, so it does not stop at every tile
const VIS_SIZE = 131072;
const VIS_MASK = 131071;
const SEARCH_CAP = 60000;
const STEP_UP = 40.0;       // the down trace starts this far above the current floor
const STEP_DOWN = 60.0;     // ... and reaches this far below it; no floor in that span is a drop edge
const STEP_MAX = 35.0;      // highest step a bot climbs (Pawn.MaxStepHeight)
const KNEE = 45.0;          // height above the floor of the body-sized wall trace
const DROP_PROBE = 900.0;   // how far the second down trace looks for the landing (the safe fall limit itself is Mut.SurveyDropMax, computed from the pawn's fall damage settings)
const ARRIVE_DIST = 10.0;   // 2D distance at which the last tile of a path counts as reached
const PASS_DIST = 12.0;     // ... and an intermediate tile (also reached when the bot passed it within 40 uu)
const BOT_BLOCK_MAX = 3;    // blocked-by-bot waits in a row before it counts as a real stuck
const START_GRACE = 15.0;   // seconds after a spawn in which a bot that has not moved yet is just waiting, not stuck
const STUCK_SECS = 3.0;     // no progress for this long is a stuck bot
const BOT_NEAR = 80.0;      // another survey pawn this close makes a stuck a blocked_by_bot

var EcholonMut Mut;
var EcholonSurveyGrid Grid;
var int BotIdx;
var byte Phase;
var float BodyR;             // collision radius used for the body-sized trace
var float BodyH;             // collision half height; the pawn's centre is BodyH above the floor
var int CurKey;              // tile the bot last stood on (centre of tile reached)
var int CurTX;
var int CurTY;
var int CurLvl;
var float CurZ;              // floor height of that tile
var int LastGoodKey;
var vector LastGoodPos;      // pawn location at the last good tile centre
var int ExpDir;              // next neighbour (0..7) to feel; 8 = all done
var int ExpKey;              // tile being expanded
var float ExpZ;              // its floor height
var float RetryAt;           // do not retry a failed (pawn in the way) feel before this time
var array<int> BQ;           // breadth-first queue: tile keys
var array<int> BP;           // parent index in BQ of each queue entry
var int BHead;
var array<int> VisKeys;
var array<int> VisStamp;
var int SearchId;
var int GoalIdx;             // queue index of the goal when found
var int ClaimKey;            // frontier tile this bot has claimed (0 = none); other bots skip it
var array<int> PathKeys;     // tiles to walk, in order, after the current one
var int PathIdx;
var int WalkFromKey;
var int WalkToKey;
var int WalkDir;
var vector WalkTarget;       // pawn location to steer to (tile centre, BodyH above the floor)
var vector WalkFromPos;      // where the bot was when this step began
var float StartedAt;         // when the bot was last placed (spawn or respawn)
var bool bEverMoved;         // the bot has moved since it was placed (the game holds new pawns still for a few seconds)
var float WalkStartTime;
var vector ProgPos;
var float ProgTime;
var float BumpTime;
var vector BumpNormal;
var string BumpActorName;
var float FallStartZ;
var float FallStartTime;
var bool bWasFalling;
var float LastMoveTime;      // last frame StepWalk steered the pawn
var bool bDropStep;          // the step being walked is a planned drop
var int DropHealth;          // pawn health before that drop
var float DropFall;          // its fall height
var int NTransfers;
var float IdleSince;
var int IdleFails;           // consecutive searches that found no frontier (the mutator ends the survey when all bots reach 3)
var float DeadSince;
var int NExpanded;
var int NHidden;
var int NStuck;
var int NSearches;
var int NTraces;
var int NTeleports;
var int NDeaths;
var int NBlockedByBot;
var int BotBlockRun;         // blocked-by-bot waits in a row on this step

// ---- stage C: the cane ----
final function vector V3(float X, float Y, float Z)
{
    local vector V;
    V.X = X;
    V.Y = Y;
    V.Z = Z;
    return V;
}

final function Actor CaneTrace(out vector HitLoc, out vector HitNorm, vector TraceEnd, vector TraceStart, optional vector Ext)
{
    local Actor A;
    A = Trace(HitLoc, HitNorm, TraceEnd, TraceStart, true, Ext,, TRACEFLAG_Blocking);
    NTraces++;
    Mut.SurveyTraceLeft--;
    return A;
}

final function bool InHazard(float X, float Y, float Z)
{
    local int i;
    local PhysicsVolume V;
    local vector O, E;
    for (i = 0; i < Mut.SurveyHazards.Length; i++)
    {
        V = Mut.SurveyHazards[i];
        if (V == None)
            continue;
        O = V.BrushComponent.Bounds.Origin;
        E = V.BrushComponent.Bounds.BoxExtent;
        if (Abs(X - O.X) <= E.X && Abs(Y - O.Y) <= E.Y && Abs(Z - O.Z) <= E.Z)
            return true;
    }
    return false;
}

final function BeginExpand()
{
    ExpKey = CurKey;
    ExpZ = CurZ;
    ExpDir = 0;
    RetryAt = 0.0;
    Phase = SP_EXPAND;
}

final function int FeelNeighbour(int D)
{
    local int PTX, PTY, PL, QTX, QTY, Delta, QKey, QD, QL, Kind, Flags, DeltaIdx;
    local float PX, PY, QX, QY, ZQ, NZ, LandZ, Fall;
    local vector Start, End, HitLoc, HitNorm, Ext;
    local Actor Hit;
    local string SafeStr;

    PTX = Grid.KeyTX(ExpKey);
    PTY = Grid.KeyTY(ExpKey);
    PL = Grid.KeyLvl(ExpKey);
    QTX = PTX + Grid.DirDX(D);
    QTY = PTY + Grid.DirDY(D);
    PX = Grid.CenterOf(PTX);
    PY = Grid.CenterOf(PTY);
    QX = Grid.CenterOf(QTX);
    QY = Grid.CenterOf(QTY);

    // b. check existing neighbour at Delta = 0, 1, -1
    DeltaIdx = 0;
    while (DeltaIdx < 3)
    {
        if (DeltaIdx == 0) Delta = 0;
        else if (DeltaIdx == 1) Delta = 1;
        else Delta = -1;

        QKey = Grid.MakeKey(QTX, QTY, PL + Delta);
        QD = Grid.GetData(QKey);
        if (QD != 0)
        {
            if (Grid.DKind(QD) == K_FLOOR || Grid.DKind(QD) == K_STEEP)
            {
                if (Abs(Grid.DZ(QD) - ExpZ) <= STEP_MAX + 2.0)
                {
                    if (Grid.DKind(QD) == K_FLOOR && (Grid.DFlags(QD) & (F_HAZARD | F_MOVER | F_BLOCKED | F_HIDDEN)) == 0)
                    {
                        Start = V3(PX, PY, ExpZ + KNEE);
                        End = V3(QX, QY, Grid.DZ(QD) + KNEE);
                        Ext = V3(BodyR, BodyR, 6.0);
                        Hit = CaneTrace(HitLoc, HitNorm, End, Start, Ext);
                        if (Pawn(Hit) != None)
                            return 1;
                        if (Hit == None)
                        {
                            QL = PL + Delta;
                            Grid.PutLinks(ExpKey, Grid.LinkSet(Grid.GetLinks(ExpKey), D, QL - PL));
                        }
                    }
                    return 0;
                }
            }
            else
            {
                if (Delta == 0)
                    return 0;
            }
        }
        DeltaIdx++;
    }

    // c. new neighbour: DOWN trace (point)
    Start = V3(QX, QY, ExpZ + STEP_UP);
    End = V3(QX, QY, ExpZ - STEP_DOWN);
    Hit = CaneTrace(HitLoc, HitNorm, End, Start);
    if (Pawn(Hit) != None)
        return 1;

    if (Hit == None)
    {
        // drop edge: second trace to find landing
        Start = V3(QX, QY, ExpZ - STEP_DOWN);
        End = V3(QX, QY, ExpZ - DROP_PROBE);
        Hit = CaneTrace(HitLoc, HitNorm, End, Start);
        if (Hit != None)
            LandZ = HitLoc.Z;
        else
            LandZ = ExpZ - DROP_PROBE;
        Fall = ExpZ - LandZ;
        if (Fall > Mut.SurveyDropMax)
            Flags = F_UNSAFE;
        else
            Flags = 0;
        Grid.PutData(Grid.MakeKey(QTX, QTY, PL), Grid.PackData(K_DROP, Flags, LandZ));
        if (Fall <= Mut.SurveyDropMax)
            SafeStr = "1";
        else
            SafeStr = "0";
        // A drop that lands on floor we know nothing about is taken once: the landing becomes a one-way floor tile and
        // the link carries code 99 (see EcholonSurveyGrid.LinkDelta). Unsafe or already known landings are only logged.
        if (Hit != None && HitNorm.Z >= 0.7 && Fall > 60.0 && Fall <= Mut.SurveyDropMax && Grid.GetData(Grid.MakeKey(QTX, QTY, Grid.LevelOf(LandZ))) == 0)
        {
            Grid.PutData(Grid.MakeKey(QTX, QTY, Grid.LevelOf(LandZ)), Grid.PackData(K_FLOOR, F_ONEWAY, LandZ));
            Grid.PutLinks(ExpKey, Grid.LinkSet(Grid.GetLinks(ExpKey), D, 99));
            SafeStr = SafeStr $ " link=1";
        }
        if (Mut.SurveyDropLogs < 150)
        {
            Mut.SurveyDropLogs++;
            Mut.EchelonLog("SURVEY_DROP bot=" $ string(BotIdx) $ " at=" $ int(QX) $ "," $ int(QY) $ "," $ int(ExpZ) $ " fall=" $ int(Fall) $ " safe=" $ SafeStr);
        }
        return 0;
    }

    // floor found
    ZQ = HitLoc.Z;
    NZ = HitNorm.Z;
    Flags = 0;
    if (Hit.IsA('InterpActor') || Hit.IsA('Mover'))
        Flags = Flags | F_MOVER;

    if (ZQ - ExpZ > STEP_MAX)
    {
        Grid.PutData(Grid.MakeKey(QTX, QTY, PL), Grid.PackData(K_WALL, 0, ExpZ));
        return 0;
    }
    if (NZ < 0.7)
    {
        Grid.PutData(Grid.MakeKey(QTX, QTY, Grid.LevelOf(ZQ)), Grid.PackData(K_STEEP, Flags, ZQ));
        return 0;
    }
    QL = Grid.LevelOf(ZQ);
    QKey = Grid.MakeKey(QTX, QTY, QL);

    // KNEE (wall) trace
    Start = V3(PX, PY, ExpZ + KNEE);
    End = V3(QX, QY, ZQ + KNEE);
    Ext = V3(BodyR, BodyR, 6.0);
    Hit = CaneTrace(HitLoc, HitNorm, End, Start, Ext);
    if (Pawn(Hit) != None)
        return 1;
    if (Hit != None)
    {
        // A diagonal sweep also clips the corners beside it: leave the tile unknown, the straight neighbours decide it.
        if ((D & 1) != 0)
            return 0;
        if (Hit.IsA('KFDoorActor'))
            Kind = K_DOOR;
        else if (WorldInfo(Hit) != None || Hit.IsA('StaticMeshCollectionActor'))
            Kind = K_WALL;
        else if (Hit.CollisionComponent != None && (FMax(Hit.CollisionComponent.Bounds.BoxExtent.X, Hit.CollisionComponent.Bounds.BoxExtent.Y) > 200.0 || Hit.CollisionComponent.Bounds.BoxExtent.Z > 150.0))
            Kind = K_WALL;
        else
            Kind = K_OBST;
        Grid.PutData(Grid.MakeKey(QTX, QTY, PL), Grid.PackData(Kind, 0, ExpZ));
        return 0;
    }

    // CEILING trace (point)
    Start = V3(QX, QY, ZQ + 2.0);
    End = V3(QX, QY, ZQ + BodyH * 2.0 + 4.0);
    Hit = CaneTrace(HitLoc, HitNorm, End, Start);
    if (Pawn(Hit) != None)
        return 1;
    if (Hit != None)
    {
        Flags = Flags | F_CEIL;
        if (HitLoc.Z - ZQ < 60.0)
        {
            Grid.PutData(Grid.MakeKey(QTX, QTY, PL), Grid.PackData(K_WALL, F_CEIL, ExpZ));
            return 0;
        }
    }

    // finalise flags and record
    if (InHazard(QX, QY, ZQ + BodyH))
        Flags = Flags | F_HAZARD;
    if (Abs(ZQ - ExpZ) > 8.0)
        Flags = Flags | F_STEP;

    Grid.PutData(QKey, Grid.PackData(K_FLOOR, Flags, ZQ));
    if ((Flags & (F_HAZARD | F_MOVER)) == 0)
        Grid.PutLinks(ExpKey, Grid.LinkSet(Grid.GetLinks(ExpKey), D, QL - PL));
    return 0;
}

final function bool StepExpand()
{
    local int R;
    while (ExpDir < 8)
    {
        if (Mut.SurveyTraceLeft < 4)
            return false;
        if (WorldInfo.TimeSeconds < RetryAt)
            return false;
        R = FeelNeighbour(ExpDir);
        if (R == 1)
        {
            RetryAt = WorldInfo.TimeSeconds + 0.4;
            return false;
        }
        ExpDir++;
    }
    Grid.AddFlags(ExpKey, F_EXPANDED | F_VISITED);
    NExpanded++;
    return true;
}

// ---- stage B: search for the nearest frontier ----
final function bool ClaimedByOther(int Key)
{
    local int i;
    for (i = 0; i < Mut.SurveyBotList.Length; i++)
    {
        if (Mut.SurveyBotList[i] == None || Mut.SurveyBotList[i] == self)
            continue;
        if (Mut.SurveyBotList[i].ClaimKey == Key)
            return true;
    }
    return false;
}

// Per-search open-addressing visited set; inserts on first call, true on repeat.
final function bool VisitedBefore(int Key)
{
    local int S, Probes;
    S = (Key * 40503 + (Key >> 11)) & VIS_MASK;
    while (VisStamp[S] == SearchId)
    {
        if (VisKeys[S] == Key)
            return true;
        S = (S + 1) & VIS_MASK;
        Probes++;
        if (Probes > 4096)
            return true;
    }
    VisKeys[S] = Key;
    VisStamp[S] = SearchId;
    return false;
}

final function BeginSearch()
{
    SearchId++;
    BQ.Length = 0;
    BP.Length = 0;
    BQ.AddItem(CurKey);
    BP.AddItem(-1);
    VisitedBefore(CurKey);
    BHead = 0;
    GoalIdx = -1;
    Phase = SP_PLAN;
    NSearches++;
}

// BFS over open links; 0 = budget exhausted, 1 = goal found, 2 = queue empty or capped.
final function int StepSearch()
{
    local int Key, Idx, L, TX, TY, Lv, D, NK, ND;
    while (BHead < BQ.Length)
    {
        if (Mut.SurveyBfsLeft <= 0)
            return 0;
        Mut.SurveyBfsLeft--;
        Key = BQ[BHead];
        Idx = BHead;
        BHead++;
        L = Grid.GetLinks(Key);
        TX = Grid.KeyTX(Key);
        TY = Grid.KeyTY(Key);
        Lv = Grid.KeyLvl(Key);
        for (D = 0; D < 8; D++)
        {
            if (Grid.LinkOpen(L, D))
            {
                if (Grid.LinkDelta(L, D) == 99)
                    NK = Grid.MakeKey(TX + Grid.DirDX(D), TY + Grid.DirDY(D), Grid.LevelOf(Grid.DZ(Grid.GetData(Grid.MakeKey(TX + Grid.DirDX(D), TY + Grid.DirDY(D), Lv)))));
                else
                    NK = Grid.MakeKey(TX + Grid.DirDX(D), TY + Grid.DirDY(D), Lv + Grid.LinkDelta(L, D));
                if (VisitedBefore(NK))
                    continue;
                ND = Grid.GetData(NK);
                if (ND == 0)
                    continue;
                if (Grid.DKind(ND) != K_FLOOR)
                    continue;
                if (Grid.DHas(ND, F_BLOCKED))
                    continue;
                if ((Grid.DFlags(ND) & F_EXPANDED) == 0 && !ClaimedByOther(NK))
                {
                    BQ.AddItem(NK);
                    BP.AddItem(Idx);
                    GoalIdx = BQ.Length - 1;
                    return 1;
                }
                BQ.AddItem(NK);
                BP.AddItem(Idx);
                if (BQ.Length >= SEARCH_CAP)
                    return 2;
            }
        }
    }
    return 2;
}

// Reconstruct the walk order (root's child first, goal last) and claim the goal tile.
final function BuildPath()
{
    local int I, J, N, Tmp;
    PathKeys.Length = 0;
    I = GoalIdx;
    while (I != -1)
    {
        if (BP[I] != -1)
            PathKeys.AddItem(BQ[I]);
        I = BP[I];
    }
    N = PathKeys.Length;
    for (J = 0; J < N / 2; J++)
    {
        Tmp = PathKeys[J];
        PathKeys[J] = PathKeys[N - 1 - J];
        PathKeys[N - 1 - J] = Tmp;
    }
    PathIdx = 0;
    ClaimKey = BQ[GoalIdx];
    IdleFails = 0;
}

// ---- stage W: setup, walking, hidden collisions, stuck handling, the tick ----
// NotifyHitWall: records bump info from the pawn's collision callback.
event bool NotifyHitWall(vector HitNormal, actor Wall)
{
    BumpTime = WorldInfo.TimeSeconds;
    BumpNormal = HitNormal;
    if (Wall == None)
        BumpActorName = "world";
    else
        BumpActorName = string(Wall.Class.Name);
    return false;
}

// Setup: wires the bot to its mutator and allocates the search visited set.
final function Setup(EcholonMut M, int Idx)
{
    Mut = M;
    Grid = M.SurveyGrid;
    BotIdx = Idx;
    Phase = SP_WAIT;
    VisKeys.Length = VIS_SIZE;
    VisStamp.Length = VIS_SIZE;
    SearchId = 0;
    ClaimKey = 0;
    IdleFails = 0;
}

// PawnOk: true when the controller has a living pawn.
final function bool PawnOk()
{
    return (Pawn != None && Pawn.IsAliveAndWell());
}

// SetCurTile: updates CurKey/TX/TY/Lvl/Z from a grid key.
final function SetCurTile(int Key)
{
    CurKey = Key;
    CurTX = Grid.KeyTX(Key);
    CurTY = Grid.KeyTY(Key);
    CurLvl = Grid.KeyLvl(Key);
    CurZ = Grid.DZ(Grid.GetData(Key));
}

// StartHere: snaps the pawn to its tile centre and begins expand or search.
final function StartHere()
{
    local float FloorZ;
    local int TX, TY, Key;

    BodyR = Pawn.GetCollisionRadius();
    StartedAt = WorldInfo.TimeSeconds;
    bEverMoved = false;
    BodyH = Pawn.GetCollisionHeight();
    FloorZ = Pawn.Location.Z - BodyH;
    TX = Grid.TileOf(Pawn.Location.X);
    TY = Grid.TileOf(Pawn.Location.Y);
    Key = Grid.MakeKey(TX, TY, Grid.LevelOf(FloorZ));
    if (Grid.GetData(Key) == 0)
        Grid.PutData(Key, Grid.PackData(K_FLOOR, 0, FloorZ));
    SetCurTile(Key);
    Pawn.SetLocation(V3(Grid.CenterOf(TX), Grid.CenterOf(TY), CurZ + BodyH));
    Pawn.Velocity = V3(0.0, 0.0, 0.0);
    Pawn.SetPhysics(PHYS_Walking);
    LastGoodKey = Key;
    LastGoodPos = Pawn.Location;
    Mut.EchelonLog("SURVEY_START bot=" $ string(BotIdx) $ " at=" $ string(int(Pawn.Location.X)) $ "," $ string(int(Pawn.Location.Y)) $ "," $ string(int(Pawn.Location.Z)) $ " tile=" $ TileText(Key));
    if (Grid.DHas(Grid.GetData(CurKey), F_EXPANDED))
    {
        ClaimKey = 0;
        BeginSearch();
    }
    else
    {
        ClaimKey = Key;
        BeginExpand();
    }
}

// SetWalkTarget: computes the steering destination and direction for the next tile.
final function SetWalkTarget(int NextKey)
{
    local int D, ND, NTX, NTY;

    WalkFromKey = CurKey;
    WalkToKey = NextKey;
    NTX = Grid.KeyTX(NextKey);
    NTY = Grid.KeyTY(NextKey);
    WalkDir = 8;
    for (D = 0; D < 8; D++)
    {
        if (NTX - CurTX == Grid.DirDX(D) && NTY - CurTY == Grid.DirDY(D))
        {
            WalkDir = D;
            break;
        }
    }
    ND = Grid.GetData(NextKey);
    WalkTarget = V3(Grid.CenterOf(NTX), Grid.CenterOf(NTY), Grid.DZ(ND) + BodyH);
    WalkStartTime = WorldInfo.TimeSeconds;
    bDropStep = (WalkDir < 8 && Grid.LinkDelta(Grid.GetLinks(CurKey), WalkDir) == 99);
    if (bDropStep)
    {
        DropHealth = Pawn.Health;
        DropFall = CurZ - Grid.DZ(ND);
    }
    BotBlockRun = 0;
    ProgPos = Pawn.Location;
    WalkFromPos = Pawn.Location;
    ProgTime = WorldInfo.TimeSeconds;
    bWasFalling = false;
}

// BeginWalk: enters SP_WALK and targets the first path tile.
final function BeginWalk()
{
    PathIdx = 0;
    Phase = SP_WALK;
    SetWalkTarget(PathKeys[0]);
}

// TeleportToGood: restores the pawn to the last safe tile centre.
final function TeleportToGood()
{
    Pawn.SetLocation(LastGoodPos);
    Pawn.Velocity = V3(0.0, 0.0, 0.0);
    Pawn.Acceleration = V3(0.0, 0.0, 0.0);
    Pawn.SetPhysics(PHYS_Walking);
    SetCurTile(LastGoodKey);
    NTeleports++;
    bWasFalling = false;
}

// NearOtherBot: true when another survey pawn is within BOT_NEAR.
final function bool NearOtherBot()
{
    local int i;
    local EcholonSurveyBot B;
    for (i = 0; i < Mut.SurveyBotList.Length; i++)
    {
        B = Mut.SurveyBotList[i];
        if (B == None || B == self || B.Pawn == None)
            continue;
        if (VSize(Pawn.Location - B.Pawn.Location) < BOT_NEAR)
            return true;
    }
    return false;
}

// TileText: formats a grid key as "tx,ty,lvl".
final function string TileText(int Key)
{
    return string(Grid.KeyTX(Key)) $ "," $ string(Grid.KeyTY(Key)) $ "," $ string(Grid.KeyLvl(Key));
}

// HiddenFound: marks the destination tile hidden, closes the link, teleports back, re-searches.
final function HiddenFound(string HowText, string Extra)
{
    local int HitKey;

    NHidden++;
    HitKey = Grid.MakeKey(Grid.TileOf(Pawn.Location.X), Grid.TileOf(Pawn.Location.Y), Grid.LevelOf(Pawn.Location.Z - BodyH));
    if (Grid.GetData(HitKey) != 0)
        Grid.AddFlags(HitKey, F_HIDDEN);
    else
        Grid.AddFlags(WalkToKey, F_HIDDEN);
    if (WalkDir < 8)
        Grid.PutLinks(WalkFromKey, Grid.LinkClose(Grid.GetLinks(WalkFromKey), WalkDir));
    Mut.EchelonLog("SURVEY_HIDDEN bot=" $ string(BotIdx) $ " how=" $ HowText $ " from=" $ TileText(WalkFromKey) $ " to=" $ TileText(WalkToKey) $ " at=" $ string(int(Pawn.Location.X)) $ "," $ string(int(Pawn.Location.Y)) $ "," $ string(int(Pawn.Location.Z)) $ " " $ Extra);
    ClaimKey = 0;
    TeleportToGood();
    BeginSearch();
}

// StuckFound: handles a bot that cannot progress (blocked by bot or terrain).
final function StuckFound()
{
    if (!bEverMoved && WorldInfo.TimeSeconds - StartedAt < START_GRACE)
    {
        ProgTime = WorldInfo.TimeSeconds;
        ProgPos = Pawn.Location;
        WalkStartTime = WorldInfo.TimeSeconds;
        return;
    }
    if (NearOtherBot() && BotBlockRun < BOT_BLOCK_MAX)
    {
        NBlockedByBot++;
        BotBlockRun++;
        ProgTime = WorldInfo.TimeSeconds;
        ProgPos = Pawn.Location;
        WalkStartTime = WorldInfo.TimeSeconds;
        Mut.EchelonLog("SURVEY_STUCK_BOT bot=" $ string(BotIdx) $ " at=" $ string(int(Pawn.Location.X)) $ "," $ string(int(Pawn.Location.Y)) $ "," $ string(int(Pawn.Location.Z)));
        return;
    }
    BotBlockRun = 0;
    NStuck++;
    Grid.AddFlags(WalkToKey, F_BLOCKED);
    if (WalkDir < 8)
        Grid.PutLinks(WalkFromKey, Grid.LinkClose(Grid.GetLinks(WalkFromKey), WalkDir));
    Mut.EchelonLog("SURVEY_STUCK bot=" $ string(BotIdx) $ " from=" $ TileText(WalkFromKey) $ " to=" $ TileText(WalkToKey) $ " at=" $ string(int(Pawn.Location.X)) $ "," $ string(int(Pawn.Location.Y)) $ "," $ string(int(Pawn.Location.Z)));
    ClaimKey = 0;
    TeleportToGood();
    BeginSearch();
}

// ReachedTile: advances the path or transitions to expand/search when the path ends.
final function ReachedTile()
{
    LastGoodKey = WalkToKey;
    LastGoodPos = Pawn.Location;
    SetCurTile(WalkToKey);
    PathIdx++;
    if (PathIdx < PathKeys.Length)
    {
        SetWalkTarget(PathKeys[PathIdx]);
        return;
    }
    Pawn.Acceleration = V3(0.0, 0.0, 0.0);
    if (Grid.DHas(Grid.GetData(CurKey), F_EXPANDED))
    {
        ClaimKey = 0;
        BeginSearch();
    }
    else
    {
        BeginExpand();
    }
}

// StepWalk: one frame of acceleration-based steering with fall/bump/stuck detection.
final function StepWalk()
{
    local float Now, Dist, Fall, ArriveD, SegDot;
    local vector ToDest, MoveDir;

    Now = WorldInfo.TimeSeconds;
    ToDest = WalkTarget - Pawn.Location;
    ToDest.Z = 0.0;
    Dist = VSize(ToDest);

    if (Pawn.Physics == PHYS_Falling && !bWasFalling)
    {
        bWasFalling = true;
        FallStartZ = Pawn.Location.Z;
        FallStartTime = Now;
    }
    else if (Pawn.Physics != PHYS_Falling && bWasFalling)
    {
        bWasFalling = false;
        Fall = FallStartZ - Pawn.Location.Z;
        if (!bDropStep && Fall > 45.0 && (Now - FallStartTime) > 0.25)
        {
            HiddenFound("fall", "fall=" $ string(int(Fall)));
            return;
        }
    }

    if (PathIdx == PathKeys.Length - 1)
        ArriveD = ARRIVE_DIST;
    else
        ArriveD = PASS_DIST;
    SegDot = (WalkTarget.X - WalkFromPos.X) * ToDest.X + (WalkTarget.Y - WalkFromPos.Y) * ToDest.Y;
    LastMoveTime = Now;
    if (bDropStep)
    {
        // a drop: arrived once it has landed near the landing tile (the fall can carry it a little past)
        MoveDir = Normal(ToDest);
        if (Pawn.Physics != PHYS_Falling && Dist < 70.0 && Abs(Pawn.Location.Z - WalkTarget.Z) < 40.0)
        {
            if (Pawn.Health < DropHealth)
            {
                Mut.SurveyDropMax = FMax(0.0, DropFall - 30.0);
                Mut.EchelonLog("SURVEY_DROP_DAMAGE bot=" $ string(BotIdx) $ " fall=" $ string(int(DropFall)) $ " health_lost=" $ string(DropHealth - Pawn.Health) $ " max_now=" $ string(int(Mut.SurveyDropMax)));
            }
            bDropStep = false;
            ReachedTile();
            return;
        }
        if (Pawn.Physics != PHYS_Falling)
            Pawn.Acceleration = MoveDir * 2000.0;
        if ((Now - WalkStartTime) > 8.0)
            StuckFound();
        return;
    }
    if (Dist < ArriveD || (SegDot < 0.0 && Dist < 40.0))
    {
        ReachedTile();
        return;
    }

    MoveDir = Normal(ToDest);
    Pawn.Acceleration = MoveDir * 2000.0;
    Pawn.SetRotation(rotator(MoveDir));

    if ((Now - BumpTime) < 0.25 && (MoveDir dot BumpNormal) < -0.5)
    {
        HiddenFound("bump", "actor=" $ BumpActorName);
        return;
    }

    if (VSize(Pawn.Location - ProgPos) > 8.0)
    {
        bEverMoved = true;
        ProgPos = Pawn.Location;
        ProgTime = Now;
    }
    else if ((Now - ProgTime) > STUCK_SECS)
    {
        StuckFound();
        return;
    }
    if ((Now - WalkStartTime) > 8.0)
        StuckFound();
}

// SurveyTick: per-frame dispatcher driven by the mutator.
final function SurveyTick(float DT)
{
    local int R, Far;

    if (!PawnOk())
    {
        if (Phase != SP_DEAD && Phase != SP_WAIT)
        {
            Mut.EchelonLog("SURVEY_DEATH bot=" $ string(BotIdx) $ " tile=" $ TileText(CurKey));
            NDeaths++;
            Phase = SP_DEAD;
            DeadSince = WorldInfo.TimeSeconds;
            ClaimKey = 0;
        }
        if (Phase == SP_DEAD && (WorldInfo.TimeSeconds - DeadSince) > 2.0)
        {
            Mut.SurveyRespawn(self);
            Phase = SP_WAIT;
        }
        return;
    }
    if (Phase == SP_WAIT)
    {
        StartHere();
        return;
    }
    switch (Phase)
    {
        case SP_EXPAND:
            if (WorldInfo.TimeSeconds - LastMoveTime > MOMENTUM)
                Pawn.Acceleration = V3(0.0, 0.0, 0.0);
            if (StepExpand())
            {
                ClaimKey = 0;
                BeginSearch();
            }
            break;
        case SP_PLAN:
            if (WorldInfo.TimeSeconds - LastMoveTime > MOMENTUM)
                Pawn.Acceleration = V3(0.0, 0.0, 0.0);
            R = StepSearch();
            if (R == 1)
            {
                BuildPath();
                BeginWalk();
            }
            else if (R == 2)
            {
                // nothing reachable on foot: go to the nearest unexplored floor on the mutator's shared list
                Far = PickFarFrontier();
                if (Far != 0)
                {
                    TransferTo(Far);
                }
                else
                {
                    IdleFails++;
                    Phase = SP_IDLE;
                    IdleSince = WorldInfo.TimeSeconds;
                    if (IdleFails == 1)
                        Mut.EchelonLog("SURVEY_IDLE bot=" $ string(BotIdx) $ " expanded=" $ string(NExpanded));
                }
            }
            break;
        case SP_WALK:
            StepWalk();
            break;
        case SP_IDLE:
            Pawn.Acceleration = V3(0.0, 0.0, 0.0);
            if (WorldInfo.TimeSeconds - IdleSince > 2.0)
                BeginSearch();
            break;
    }
}

// PickFarFrontier: the nearest unexplored floor tile (not blocked, not claimed by another bot) on the mutator's shared list,
// which it rebuilds once a second from the whole grid. 0 when there is none.
final function int PickFarFrontier()
{
    local int I, K, D, Best;
    local float X, Y, Z, Dd, BestD;

    Best = 0;
    BestD = 1000000000000.0;
    for (I = 0; I < Mut.SurveyFrontList.Length; I++)
    {
        K = Mut.SurveyFrontList[I];
        D = Grid.GetData(K);
        if (D == 0 || Grid.DKind(D) != K_FLOOR || (Grid.DFlags(D) & (F_EXPANDED | F_BLOCKED)) != 0)
            continue;
        X = Grid.CenterOf(Grid.KeyTX(K)) - Pawn.Location.X;
        Y = Grid.CenterOf(Grid.KeyTY(K)) - Pawn.Location.Y;
        Z = Grid.DZ(D) + BodyH - Pawn.Location.Z;
        Dd = X * X + Y * Y + Z * Z;
        if (Dd < BestD && !ClaimedByOther(K))
        {
            BestD = Dd;
            Best = K;
        }
    }
    return Best;
}

// TransferTo: put the bot on a far frontier tile and start feeling from there (no walking route to it was known).
final function TransferTo(int Key)
{
    local float X, Y, Z;
    local int FromKey;

    FromKey = CurKey;
    X = Grid.CenterOf(Grid.KeyTX(Key));
    Y = Grid.CenterOf(Grid.KeyTY(Key));
    Z = Grid.DZ(Grid.GetData(Key)) + BodyH + 4.0;
    ClaimKey = Key;
    if (!Pawn.SetLocation(V3(X, Y, Z)))
    {
        Grid.AddFlags(Key, F_BLOCKED);
        ClaimKey = 0;
        Phase = SP_IDLE;
        IdleSince = WorldInfo.TimeSeconds;
        return;
    }
    Pawn.Velocity = V3(0.0, 0.0, 0.0);
    Pawn.Acceleration = V3(0.0, 0.0, 0.0);
    Pawn.SetPhysics(PHYS_Walking);
    SetCurTile(Key);
    LastGoodKey = Key;
    LastGoodPos = Pawn.Location;
    NTransfers++;
    IdleFails = 0;
    bWasFalling = false;
    Mut.EchelonLog("SURVEY_TRANSFER bot=" $ string(BotIdx) $ " from=" $ TileText(FromKey) $ " to=" $ TileText(Key) $ " at=" $ string(int(X)) $ "," $ string(int(Y)) $ "," $ string(int(Z)));
    BeginExpand();
}

// StatLine: one-line summary of this bot's counters.
final function string StatLine()
{
    return "expanded=" $ string(NExpanded) $ " transfers=" $ string(NTransfers) $ " hidden=" $ string(NHidden) $ " stuck=" $ string(NStuck) $ " bybot=" $ string(NBlockedByBot) $ " teleports=" $ string(NTeleports) $ " deaths=" $ string(NDeaths) $ " searches=" $ string(NSearches) $ " traces=" $ string(NTraces);
}

defaultproperties
{
    bIsPlayer=true
}
