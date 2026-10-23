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
const SP_LEAD = 6;
const LP_PLACE = 0;
const LP_RUN = 1;
const LP_AIR = 2;
// Copies of the tile constants in EcholonSurveyGrid (keep in sync with that class).
const TILE = 38.0;
const K_FLOOR = 1;
const K_STEEP = 2;
const K_WALL = 3;
const K_OBST = 4;
const K_DROP = 5;
const K_DOOR = 6;
const K_NARROW = 7;
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
// The step height is the pawn's own (Mut.SurveyStepMax, 70 uu for a KF2 human): the down trace starts a little above it, a floor within it
// is a step, the body-sized wall trace runs just above it (Knee), and no floor within a step below is a drop edge.
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
var int LeadIdx;             // pass 2: the lead being tried (index in Mut.SurveyLeads.List), -1 none
var NavigationPoint LeadA;
var NavigationPoint LeadB;
var int LeadType;
var byte LeadPhase;
var bool bLeadJump;          // this lead needs a jump
var bool bLeadDrop;          // this lead is a drop
var bool bLeadJumped;
var bool bLeadJumped2;
var float LeadT0;
var float LeadTimeout;
var float LeadJumpAt;        // jump when this close (2D) to the link's end
var float LeadStartZ;
var float LeadApexZ;
var vector LeadStartPos;
var vector LeadProgPos;
var float LeadProgT;
var int LeadHealth0;
var array<vector> LeadTrack;     // positions during the run of a try (every 19 uu), where the walls it passed become narrow floor
var float LeadPlaceT0;       // when placing the bot on its start floor first failed (another pawn on the spot)
var int NLeadOk;
var int NLeadFail;
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
    local int PTX, PTY, PL, QTX, QTY, Delta, QKey, QD, QL, Kind, Flags, DeltaIdx, Si;
    local float PX, PY, QX, QY, ZQ, NZ, LandZ, Fall, StepMax, Knee, Shift;
    local vector Start, End, HitLoc, HitNorm, Ext, Perp;
    local Actor Hit, Hit2;
    local string SafeStr;
    local bool bNarrow;

    StepMax = Mut.SurveyStepMax;
    Knee = StepMax + 8.0;
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
            if (Grid.DKind(QD) == K_FLOOR || Grid.DKind(QD) == K_STEEP || Grid.DKind(QD) == K_NARROW)
            {
                if (Abs(Grid.DZ(QD) - ExpZ) <= StepMax + 2.0)
                {
                    if (Grid.DKind(QD) == K_NARROW)
                    {
                        // a gap only one body wide: known, but walking tile centre to tile centre through it gets stuck, so no link
                        // here; pass 2 walks the designer's link line through it instead
                        QL = PL + Delta;
                    }
                    else if (Grid.DKind(QD) == K_FLOOR && (Grid.DFlags(QD) & (F_HAZARD | F_MOVER | F_BLOCKED | F_HIDDEN)) == 0)
                    {
                        Start = V3(PX, PY, ExpZ + Knee);
                        End = V3(QX, QY, Grid.DZ(QD) + Knee);
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
    Start = V3(QX, QY, ExpZ + StepMax + 5.0);
    End = V3(QX, QY, ExpZ - StepMax);
    Hit = CaneTrace(HitLoc, HitNorm, End, Start);
    if (Pawn(Hit) != None)
        return 1;

    if (Hit == None)
    {
        // drop edge: second trace to find landing
        Start = V3(QX, QY, ExpZ - StepMax);
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

    if (ZQ - ExpZ > StepMax)
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
    Start = V3(PX, PY, ExpZ + Knee);
    End = V3(QX, QY, ZQ + Knee);
    Ext = V3(BodyR, BodyR, 6.0);
    Hit = CaneTrace(HitLoc, HitNorm, End, Start, Ext);
    if (Pawn(Hit) != None)
        return 1;
    if (Hit != None)
    {
        // A diagonal sweep also clips the corners beside it: leave the tile unknown, the straight neighbours decide it.
        if ((D & 1) != 0)
            return 0;
        bNarrow = false;
        if (!Hit.IsA('KFDoorActor'))
        {
            // A doorway only one body wide fails the centred sweep. Feel the same sweep shifted a quarter and half a tile to
            // each side before calling the tile a wall; a clear shifted sweep makes it a narrow gap (walkable).
            Perp = Normal(V3(PY - QY, QX - PX, 0.0));
            for (Si = 0; Si < 4 && !bNarrow; Si++)
            {
                if (Si == 0)
                    Shift = 9.5;
                else if (Si == 1)
                    Shift = -9.5;
                else if (Si == 2)
                    Shift = 19.0;
                else
                    Shift = -19.0;
                Start = V3(PX + Perp.X * Shift, PY + Perp.Y * Shift, ExpZ + Knee);
                End = V3(QX + Perp.X * Shift, QY + Perp.Y * Shift, ZQ + Knee);
                Hit2 = CaneTrace(HitLoc, HitNorm, End, Start, Ext);
                if (Pawn(Hit2) != None)
                    return 1;
                if (Hit2 == None)
                    bNarrow = true;
            }
        }
        if (!bNarrow)
        {
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

    if (bNarrow)
        Grid.PutData(QKey, Grid.PackData(K_NARROW, Flags, ZQ));
    else
        Grid.PutData(QKey, Grid.PackData(K_FLOOR, Flags, ZQ));
    if ((Flags & (F_HAZARD | F_MOVER)) == 0 && !bNarrow)
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
                if (Grid.DKind(ND) != K_FLOOR && Grid.DKind(ND) != K_NARROW)
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
    LeadIdx = -1;
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

    if ((Now - BumpTime) < 0.25 && (MoveDir dot BumpNormal) < -0.5 && Grid.DKind(Grid.GetData(WalkToKey)) != K_NARROW)
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
            Mut.EchelonLog("SURVEY_DEATH bot=" $ string(BotIdx) $ " tile=" $ TileText(CurKey) $ " level_deaths=" $ string(Mut.SurveyLevelDeaths[CurLvl + 32]));
            NDeaths++;
            // a death marks the tile and counts against its floor level; a level with 3 deaths is not transferred to any more.
            // During a lead CurKey is the tile before the lead (the bot was placed elsewhere), so the lead's own failure records it.
            if (LeadIdx < 0)
            {
                Grid.AddFlags(CurKey, F_BLOCKED);
                Mut.SurveyLevelDeaths[CurLvl + 32] = Mut.SurveyLevelDeaths[CurLvl + 32] + 1;
            }
            if (LeadIdx >= 0)
            {
                Mut.SurveyLeads.Finish(LeadIdx, false);
                NLeadFail++;
                Mut.EchelonLog("SURVEY_LEAD_FAIL bot=" $ string(BotIdx) $ " type=" $ LeadTypeName() $ " from=" $ string(LeadA) $ " to=" $ string(LeadB) $ " reason=died");
                LeadIdx = -1;
            }
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
                // nothing reachable on foot: in pass 2 a lead comes first (the far-frontier pockets never run out), else go to the
                // nearest unexplored floor on the mutator's shared list
                if (TryClaimLead())
                {
                    Pawn.Acceleration = V3(0.0, 0.0, 0.0);
                }
                else
                {
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
            }
            break;
        case SP_WALK:
            StepWalk();
            break;
        case SP_LEAD:
            StepLead();
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
        if (D == 0 || (Grid.DKind(D) != K_FLOOR && Grid.DKind(D) != K_NARROW) || (Grid.DFlags(D) & (F_EXPANDED | F_BLOCKED)) != 0)
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

// ---- Pass 2: trying a lead (a designer link pass 1 did not walk) ----

// Called when the walking search and the far-frontier list have nothing: take the best unclaimed lead, if pass 2 runs.
final function bool TryClaimLead()
{
    local int I;
    local float Dz;

    if (!Mut.bPass2Active || Mut.SurveyLeads == None || !Mut.SurveyLeads.bBuilt)
    {
        return false;
    }
    I = Mut.SurveyLeads.Claim(BotIdx, Pawn.Location);
    if (I < 0)
    {
        return false;
    }
    LeadIdx = I;
    LeadA = Mut.SurveyLeads.List[I].A;
    LeadB = Mut.SurveyLeads.List[I].B;
    LeadType = Mut.SurveyLeads.List[I].Type;
    Dz = Mut.SurveyLeads.List[I].Dz;
    bLeadDrop = (Dz < -60.0);
    bLeadJump = (!bLeadDrop && (Mut.SurveyLeads.List[I].bJump || Dz > Mut.SurveyStepMax * 0.8));
    LeadPhase = LP_PLACE;
    Phase = SP_LEAD;
    ClaimKey = 0;
    Pawn.Acceleration = V3(0.0, 0.0, 0.0);
    Mut.EchelonLog("SURVEY_LEAD bot=" $ string(BotIdx) $ " type=" $ LeadTypeName() $ " from=" $ string(LeadA) $ " to=" $ string(LeadB) $ " dz=" $ string(int(Dz))
        $ " dist=" $ string(int(Mut.SurveyLeads.List[I].Dist)) $ " try=" $ string(Mut.SurveyLeads.List[I].Tries + 1));
    return true;
}

final function string LeadTypeName()
{
    switch (LeadType)
    {
        case 0:
            return "unreached";
        case 1:
            return "through";
        case 2:
            return "shortcut";
    }
    return "drop";
}

// The centre of the mapped floor tile nearest to Loc (floor within a body height below it), +4 uu; false when there is none.
final function bool FindFloorNear(vector Loc, int Radius, out vector Pos)
{
    local int TX, TY, DX, DY, L0, Dl, D, Kind;
    local float Z, Dd, BestD, Cx, Cy;
    local bool bFound;

    TX = Grid.TileOf(Loc.X);
    TY = Grid.TileOf(Loc.Y);
    L0 = Grid.LevelOf(Loc.Z - BodyH);
    BestD = 1000000000000.0;
    bFound = false;
    for (DX = -Radius; DX <= Radius; DX++)
    {
        for (DY = -Radius; DY <= Radius; DY++)
        {
            for (Dl = -1; Dl <= 1; Dl++)
            {
                D = Grid.GetData(Grid.MakeKey(TX + DX, TY + DY, L0 + Dl));
                if (D == 0)
                {
                    continue;
                }
                Kind = Grid.DKind(D);
                if ((Kind != K_FLOOR && Kind != K_NARROW) || (Grid.DFlags(D) & (F_HAZARD | F_MOVER | F_BLOCKED)) != 0)
                {
                    continue;
                }
                Z = Grid.DZ(D);
                if (Z < Loc.Z - BodyH - 100.0 || Z > Loc.Z - BodyH + 40.0)
                {
                    continue;
                }
                Cx = Grid.CenterOf(TX + DX);
                Cy = Grid.CenterOf(TY + DY);
                Dd = (Cx - Loc.X) * (Cx - Loc.X) + (Cy - Loc.Y) * (Cy - Loc.Y);
                if (Dd < BestD)
                {
                    BestD = Dd;
                    Pos = V3(Cx, Cy, Z + BodyH + 4.0);
                    bFound = true;
                }
            }
        }
    }
    return bFound;
}

// One try of the lead starts here: stand on mapped floor next to the link's start (for a jump, a run-up behind it), face the end.
final function LeadPlace()
{
    local vector Dir, Pos, HitLoc, HitNorm;
    local Actor Hit;
    local bool bFound;
    local int Tries;

    Tries = Mut.SurveyLeads.List[LeadIdx].Tries;
    if (LeadType == 1 && Tries >= 1)
    {
        bLeadJump = true;     // a window sill: walking into it failed, jump on the later tries
    }
    Dir = Normal(V3(LeadB.Location.X - LeadA.Location.X, LeadB.Location.Y - LeadA.Location.Y, 0.0));
    bFound = false;
    if (bLeadJump)
    {
        bFound = FindFloorNear(LeadA.Location - Dir * 100.0, 1, Pos);
    }
    if (!bFound)
    {
        bFound = FindFloorNear(LeadA.Location, 3, Pos);
    }
    if (!bFound)
    {
        LeadFail("no_floor", true);
        return;
    }
    if (bLeadJump && Tries == 0)
    {
        // is there room to stand where the link ends?
        Hit = Trace(HitLoc, HitNorm, LeadB.Location + V3(0.0, 0.0, 2.0), LeadB.Location, true, V3(BodyR * 0.8, BodyR * 0.8, BodyH * 0.8),, TRACEFLAG_Blocking);
        if (Hit != None && Pawn(Hit) == None)
        {
            LeadFail("no_room", true);
            return;
        }
    }
    if (!Pawn.SetLocation(Pos))
    {
        // another pawn stands there: wait a frame, give up the try after 3 s
        if (LeadPlaceT0 == 0.0)
        {
            LeadPlaceT0 = WorldInfo.TimeSeconds;
        }
        if (WorldInfo.TimeSeconds - LeadPlaceT0 > 3.0)
        {
            LeadPlaceT0 = 0.0;
            LeadFail("occupied", false);
        }
        return;
    }
    LeadPlaceT0 = 0.0;
    Pawn.Health = Pawn.HealthMax;     // a bot hurt by an earlier drop must not die on a safe one
    Pawn.Velocity = V3(0.0, 0.0, 0.0);
    Pawn.Acceleration = V3(0.0, 0.0, 0.0);
    Pawn.SetPhysics(PHYS_Walking);
    LeadTrack.Length = 0;
    LeadStartPos = Pos;
    LeadStartZ = Pos.Z;
    LeadApexZ = Pos.Z;
    LeadHealth0 = Pawn.Health;
    bLeadJumped = false;
    bLeadJumped2 = false;
    LeadT0 = WorldInfo.TimeSeconds;
    LeadTimeout = VSize(LeadB.Location - Pos) / 250.0 + 6.0;
    LeadProgPos = Pos;
    LeadProgT = WorldInfo.TimeSeconds;
    if (Tries % 3 == 0)
        LeadJumpAt = 190.0;
    else if (Tries % 3 == 1)
        LeadJumpAt = 120.0;
    else
        LeadJumpAt = 260.0;
    bWasFalling = false;
    LeadPhase = LP_RUN;
}

// One frame of a try: run at the link's end, jump when close enough, steer in the air, judge the landing.
final function StepLead()
{
    local float Now, Dist2D;
    local vector ToB, MoveDir;

    if (LeadIdx < 0)
    {
        BeginSearch();
        return;
    }
    if (LeadPhase == LP_PLACE)
    {
        LeadPlace();
        return;
    }
    Now = WorldInfo.TimeSeconds;
    ToB = LeadB.Location - Pawn.Location;
    ToB.Z = 0.0;
    Dist2D = VSize(ToB);
    MoveDir = Normal(ToB);
    if (Pawn.Location.Z > LeadApexZ)
    {
        LeadApexZ = Pawn.Location.Z;
    }
    if (LeadPhase == LP_RUN)
    {
        if (Dist2D < 70.0 && Abs(Pawn.Location.Z - LeadB.Location.Z) < 110.0 && Pawn.Physics != PHYS_Falling)
        {
            LeadSuccess();
            return;
        }
        if (bLeadJump && !bLeadJumped && Dist2D <= LeadJumpAt && Pawn.Physics == PHYS_Walking)
        {
            Pawn.Acceleration = MoveDir * 2000.0;
            Pawn.DoJump(false);
            bLeadJumped = true;
            LeadPhase = LP_AIR;
            return;
        }
        if (Pawn.Physics == PHYS_Falling && bLeadDrop)
        {
            LeadPhase = LP_AIR;
            return;
        }
        Pawn.Acceleration = MoveDir * 2000.0;
        Pawn.SetRotation(rotator(MoveDir));
        if (LeadTrack.Length == 0 || VSize(Pawn.Location - LeadTrack[LeadTrack.Length - 1]) >= 19.0)
        {
            if (LeadTrack.Length < 200)
            {
                LeadTrack.AddItem(Pawn.Location);
            }
        }
        if (VSize(Pawn.Location - LeadProgPos) > 8.0)
        {
            LeadProgPos = Pawn.Location;
            LeadProgT = Now;
        }
        else if (Now - LeadProgT > 2.0)
        {
            LeadFail("blocked", false);
            return;
        }
        if (Now - LeadT0 > LeadTimeout)
        {
            LeadFail("timeout", false);
        }
        return;
    }
    // LP_AIR
    Pawn.Acceleration = MoveDir * 2000.0;
    if (bLeadJumped && !bLeadJumped2 && Pawn.Velocity.Z < 30.0 && Pawn.Physics == PHYS_Falling && Pawn.Location.Z < LeadB.Location.Z - 20.0)
    {
        // a second jump at the top of the first, as the real bots have (NumJumpsAllowed 2)
        Pawn.DoJump(false);
        bLeadJumped2 = true;
    }
    if (Pawn.Physics != PHYS_Falling)
    {
        if (Dist2D < 90.0 && Abs(Pawn.Location.Z - LeadB.Location.Z) < 110.0)
        {
            LeadSuccess();
        }
        else if (Dist2D >= 90.0 && LeadApexZ - LeadStartZ < LeadB.Location.Z - LeadStartZ - 20.0)
        {
            LeadFail("short", false);
        }
        else if (Dist2D >= 90.0)
        {
            LeadFail("short_far", false);
        }
        else
        {
            LeadFail("slid", false);
        }
        return;
    }
    if (Now - LeadT0 > LeadTimeout + 3.0)
    {
        LeadFail("timeout", false);
    }
}

// The kind of link a success records.
final function string LeadKind()
{
    if (bLeadDrop)
        return "drop";
    if (bLeadJumped)
    {
        if (LeadType == 1)
            return "window";
        return "jump";
    }
    if (LeadType == 2)
        return "shortcut";
    if (LeadType == 1)
        return "through";
    return "walk";
}

// Wall, obstacle and door tiles the bot actually stood on during the run become narrow floor (the designer's link proved the way, and
// the bot's own positions show where the gap is; a straight line from start to landing could cross real walls).
final function MarkTrack()
{
    local int I, TX, TY, L0, Dl, Key, D, Kind, N;
    local float FloorZ, Tz;

    for (I = 0; I < LeadTrack.Length; I++)
    {
        TX = Grid.TileOf(LeadTrack[I].X);
        TY = Grid.TileOf(LeadTrack[I].Y);
        FloorZ = LeadTrack[I].Z - BodyH;
        L0 = Grid.LevelOf(FloorZ);
        for (Dl = -1; Dl <= 1; Dl++)
        {
            Key = Grid.MakeKey(TX, TY, L0 + Dl);
            D = Grid.GetData(Key);
            if (D != 0)
            {
                Kind = Grid.DKind(D);
                Tz = Grid.DZ(D);
                if ((Kind == K_WALL || Kind == K_OBST || Kind == K_DOOR) && Tz >= FloorZ - 100.0 && Tz <= FloorZ + 60.0)
                {
                    Grid.PutData(Key, Grid.PackData(K_NARROW, 0, Tz));
                    N++;
                }
            }
        }
    }
    Mut.SurveyPassageTiles += N;
}

// The try worked: record the link, mark the tiles walked through, and start exploring from here (new floor).
final function LeadSuccess()
{
    local int Dmg, TX, TY, Key, OneWay;
    local float FloorZ, Dz;
    local string Kind;

    Kind = LeadKind();
    Dmg = Max(0, LeadHealth0 - Pawn.Health);
    Dz = LeadB.Location.Z - LeadA.Location.Z;
    OneWay = 1;
    if (!bLeadDrop && !bLeadJumped)
    {
        OneWay = 0;
    }
    else if (bLeadJumped && Dz > 0.0 && Dz <= Mut.SurveyDropMax)
    {
        OneWay = 0;
    }
    if (Dmg > 0 && bLeadDrop)
    {
        Mut.EchelonLog("SURVEY_DROP_DAMAGE bot=" $ string(BotIdx) $ " fall=" $ string(int(-Dz)) $ " health_lost=" $ string(Dmg) $ " predicted=" $ string(int(Mut.SurveyLeads.List[LeadIdx].DropDmg)) $ " lead=1");
    }
    Mut.EchelonLog("SURVEY_LINK kind=" $ Kind $ " from=" $ string(LeadA) $ " to=" $ string(LeadB) $ " from_at=" $ LeadXYZ(LeadStartPos) $ " to_at=" $ LeadXYZ(Pawn.Location)
        $ " oneway=" $ string(OneWay) $ " dmg=" $ string(Dmg) $ " tries=" $ string(Mut.SurveyLeads.List[LeadIdx].Tries + 1));
    if (!bLeadJumped && !bLeadDrop)
    {
        MarkTrack();
    }
    Mut.SurveyLeads.Finish(LeadIdx, true);
    NLeadOk++;
    LeadIdx = -1;
    Pawn.Acceleration = V3(0.0, 0.0, 0.0);
    TX = Grid.TileOf(Pawn.Location.X);
    TY = Grid.TileOf(Pawn.Location.Y);
    FloorZ = Pawn.Location.Z - BodyH;
    Key = Grid.MakeKey(TX, TY, Grid.LevelOf(FloorZ));
    if (Grid.GetData(Key) == 0)
    {
        Grid.PutData(Key, Grid.PackData(K_FLOOR, 0, FloorZ));
    }
    SetCurTile(Key);
    LastGoodKey = Key;
    LastGoodPos = Pawn.Location;
    if (Grid.DHas(Grid.GetData(Key), F_EXPANDED))
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

final function string LeadXYZ(vector V)
{
    return string(int(V.X)) $ "," $ string(int(V.Y)) $ "," $ string(int(V.Z));
}

// The try failed: log it; another try (3 in all, a different jump distance each) unless it can never work.
final function LeadFail(string Reason, bool bFinal)
{
    local int Tries;

    Tries = Mut.SurveyLeads.List[LeadIdx].Tries + 1;
    Mut.SurveyLeads.List[LeadIdx].Tries = Tries;
    if (bLeadJump)
    {
        Mut.EchelonLog("SURVEY_JUMP_FAIL bot=" $ string(BotIdx) $ " at=" $ LeadXYZ(LeadStartPos) $ " ledge=" $ LeadXYZ(LeadB.Location) $ " reason=" $ Reason $ " try=" $ string(Tries));
    }
    else
    {
        Mut.EchelonLog("SURVEY_LEAD_FAIL bot=" $ string(BotIdx) $ " type=" $ LeadTypeName() $ " from=" $ string(LeadA) $ " to=" $ string(LeadB) $ " reason=" $ Reason $ " try=" $ string(Tries));
    }
    if (bFinal || Tries >= 3)
    {
        if (Reason == "no_floor" || Reason == "no_room")
        {
            Mut.SurveyLeads.Retire(LeadIdx);
        }
        else
        {
            Mut.SurveyLeads.Finish(LeadIdx, false);
        }
        NLeadFail++;
        LeadIdx = -1;
        Pawn.Acceleration = V3(0.0, 0.0, 0.0);
        TeleportToGood();
        BeginSearch();
        return;
    }
    LeadPhase = LP_PLACE;
}

// StatLine: one-line summary of this bot's counters.
final function string StatLine()
{
    return "expanded=" $ string(NExpanded) $ " leads_ok=" $ string(NLeadOk) $ " leads_fail=" $ string(NLeadFail) $ " transfers=" $ string(NTransfers) $ " hidden=" $ string(NHidden) $ " stuck=" $ string(NStuck) $ " bybot=" $ string(NBlockedByBot) $ " teleports=" $ string(NTeleports) $ " deaths=" $ string(NDeaths) $ " searches=" $ string(NSearches) $ " traces=" $ string(NTraces);
}

defaultproperties
{
    bIsPlayer=true
}
