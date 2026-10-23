// EcholonSurveyLeads - the lead list of survey pass 2 (shortcuts and high floors).
// Pass 1 (the blind explorer) maps every floor a bot can walk to. When it stalls, this list is built from the
// designer's path links (the node dump's NavigationPoint.PathList) and the grid pass 1 filled: links worth trying
// because pass 1 did not walk them. A lead is "try this link": a bot goes to the mapped floor next to the link's
// start and tries to get to its end (walk, jump or drop), see EcholonSurveyBot.StepLead. The nodes only point at
// where to try; the map itself is still built from what the bots feel.
// Lead kinds:
//   LT_UNREACHED  the link ends at a node with no mapped floor under it (a high floor, a gap pass 1 could not cross)
//   LT_THROUGH    both ends are mapped but the link's straight line runs through wall tiles (a doorway only one
//                 body wide, a window)
//   LT_SHORTCUT   a jump or forced link between two mapped places
//   LT_DROP       the link ends lower than it starts (a drop pass 1 did not take); drops that do no damage first,
//                 drops that hurt but cannot kill after them
// Blocked and proscribed links are not leads (the designer turned them off); door links are skipped (doors are open).
// One instance lives on EcholonMut while pass 2 runs. It only reads the grid and the nodes (an Object cannot trace).
class EcholonSurveyLeads extends Object transient;

const LT_UNREACHED = 0;
const LT_THROUGH = 1;
const LT_SHORTCUT = 2;
const LT_DROP = 3;
const PER_FRAME = 20;        // nodes read per BuildStep (each node's links are checked against the grid)
const K_FLOOR = 1;           // copies of the tile kinds in EcholonSurveyGrid (keep in sync with that class)
const K_STEEP = 2;
const K_WALL = 3;
const K_OBST = 4;
const K_DOOR = 6;
const K_NARROW = 7;

struct SurveyLead
{
    var NavigationPoint A;   // link start (on mapped floor)
    var NavigationPoint B;   // link end
    var int Type;
    var float Prio;          // lower is tried first
    var float Dz;            // B height minus A height
    var float Dist;          // straight distance
    var float DropDmg;       // predicted fall damage (LT_DROP and downward leads)
    var bool bJump;          // the link's reach flags say jump
    var int Tries;
    var int Claim;           // bot index + 1 while a bot works on it
    var bool bDone;
    var bool bOk;
};

var array<SurveyLead> List;
var EcholonMut Mut;
var EcholonSurveyGrid Grid;
var array<NavigationPoint> Nodes;
var int Cursor;
var bool bBuilt;
var int NUnreached;
var int NThrough;
var int NShortcut;
var int NDrop;
var int NTooHigh;
var int NLethal;
var int NOk;
var int NFailed;
var int Round;              // pass 2 runs in rounds: a success opens new floor, which gives new leads
var int NOkRound;           // successes in this round
var array<NavigationPoint> DoneA;   // every lead tried in earlier rounds (start and end), so a round never repeats one
var array<NavigationPoint> DoneB;

// Start a build over the node dump's nodes.
final function Begin(EcholonMut M)
{
    Mut = M;
    Grid = M.SurveyGrid;
    Nodes = M.NavDump.Nodes;
    Cursor = 0;
    bBuilt = false;
    List.Length = 0;
    Round = 1;
    NOkRound = 0;
}

// The next round: forget this round's list, keep what was tried, read the nodes again against the grown grid.
final function Rebuild()
{
    Round++;
    NOkRound = 0;
    Cursor = 0;
    bBuilt = false;
    List.Length = 0;
    NUnreached = 0;
    NThrough = 0;
    NShortcut = 0;
    NDrop = 0;
    NTooHigh = 0;
    NLethal = 0;
}

final function bool WasTried(NavigationPoint A, NavigationPoint B)
{
    local int I;

    for (I = 0; I < DoneA.Length; I++)
    {
        if (DoneA[I] == A && DoneB[I] == B)
        {
            return true;
        }
    }
    return false;
}

// Read up to PER_FRAME nodes; true when the whole list is built (logs SURVEY_LEADS once).
final function bool BuildStep()
{
    local int Count;
    local NavigationPoint A;

    if (bBuilt)
    {
        return true;
    }
    Count = 0;
    while (Cursor < Nodes.Length && Count < PER_FRAME)
    {
        A = Nodes[Cursor];
        Cursor++;
        Count++;
        if (A != None && NodeMapped(A.Location))
        {
            AddLeadsFrom(A);
        }
    }
    if (Cursor >= Nodes.Length)
    {
        bBuilt = true;
        Mut.EchelonLog("SURVEY_LEADS round=" $ string(Round) $ " total=" $ string(List.Length) $ " unreached=" $ string(NUnreached) $ " through=" $ string(NThrough)
            $ " shortcut=" $ string(NShortcut) $ " drop=" $ string(NDrop) $ " too_high=" $ string(NTooHigh) $ " lethal=" $ string(NLethal));
    }
    return bBuilt;
}

// True when surveyed floor lies under a node (within one tile, node 120 uu above to 20 below the floor).
final function bool NodeMapped(vector Loc)
{
    local int TX, TY, DX, DY, L0, Dl, D, Kind;
    local float Z;

    TX = Grid.TileOf(Loc.X);
    TY = Grid.TileOf(Loc.Y);
    L0 = Grid.LevelOf(Loc.Z - 45.0);
    for (DX = -1; DX <= 1; DX++)
    {
        for (DY = -1; DY <= 1; DY++)
        {
            for (Dl = -1; Dl <= 1; Dl++)
            {
                D = Grid.GetData(Grid.MakeKey(TX + DX, TY + DY, L0 + Dl));
                if (D != 0)
                {
                    Kind = Grid.DKind(D);
                    if (Kind == K_FLOOR || Kind == K_STEEP || Kind == K_NARROW)
                    {
                        Z = Grid.DZ(D);
                        if (Z >= Loc.Z - 120.0 && Z <= Loc.Z + 20.0)
                        {
                            return true;
                        }
                    }
                }
            }
        }
    }
    return false;
}

// True when the straight line from A to B runs through wall, obstacle or door tiles where there is no mapped floor.
final function bool LinkCrossesWall(vector A, vector B)
{
    local int Steps, K, TX, TY, L0, Dl, D, Kind;
    local float F, Z, Tz;
    local vector P;
    local bool bFloor, bWall;

    Steps = Max(1, int(VSize(B - A) / 19.0));
    for (K = 0; K <= Steps; K++)
    {
        F = float(K) / float(Steps);
        P = A + (B - A) * F;
        TX = Grid.TileOf(P.X);
        TY = Grid.TileOf(P.Y);
        Z = P.Z;
        L0 = Grid.LevelOf(Z - 45.0);
        bFloor = false;
        bWall = false;
        for (Dl = -1; Dl <= 1; Dl++)
        {
            D = Grid.GetData(Grid.MakeKey(TX, TY, L0 + Dl));
            if (D != 0)
            {
                Kind = Grid.DKind(D);
                Tz = Grid.DZ(D);
                if ((Kind == K_FLOOR || Kind == K_STEEP || Kind == K_NARROW) && Tz >= Z - 130.0 && Tz <= Z + 30.0)
                {
                    bFloor = true;
                }
                else if ((Kind == K_WALL || Kind == K_OBST || Kind == K_DOOR) && Tz >= Z - 130.0 && Tz <= Z + 60.0)
                {
                    bWall = true;
                }
            }
        }
        if (bWall && !bFloor)
        {
            return true;
        }
    }
    return false;
}

// Add the leads of A's links.
final function AddLeadsFrom(NavigationPoint A)
{
    local int I;
    local ReachSpec Spec;
    local NavigationPoint B;
    local SurveyLead L;
    local float Dz, V, Dmg;
    local bool bBMapped, bAdd;

    for (I = 0; I < A.PathList.Length; I++)
    {
        Spec = A.PathList[I];
        if (Spec == None || Spec.bDisabled || Spec.IsA('ProscribedReachSpec') || Spec.IsA('KFDoorReachSpec'))
        {
            continue;
        }
        B = Spec.GetEnd();
        if (B == None || WasTried(A, B))
        {
            continue;
        }
        L.A = A;
        L.B = B;
        L.Dz = B.Location.Z - A.Location.Z;
        L.Dist = VSize(B.Location - A.Location);
        L.bJump = (Spec.reachFlags & 8) != 0;
        L.DropDmg = 0.0;
        L.Tries = 0;
        L.Claim = 0;
        L.bDone = false;
        L.bOk = false;
        Dz = L.Dz;
        bAdd = false;
        if (Dz < -60.0)
        {
            // a drop: the pawn lands at sqrt(2 g h); damage starts above MaxFallSpeed (the same formula the engine uses)
            V = Sqrt(2.0 * Mut.SurveyGravityZ * (-Dz));
            if (V > Mut.SurveyMaxFall)
            {
                Dmg = 100.0 * (V - Mut.SurveyMaxFall) / Mut.SurveyMaxFall;
                L.DropDmg = Dmg;
            }
            if (L.DropDmg >= 85.0)
            {
                NLethal++;
                continue;
            }
        }
        bBMapped = NodeMapped(B.Location);
        if (!bBMapped)
        {
            if (Dz > Mut.SurveyJumpReach)
            {
                NTooHigh++;
                continue;
            }
            L.Type = LT_UNREACHED;
            L.Prio = 0.0 + L.DropDmg / 100.0;
            NUnreached++;
            bAdd = true;
        }
        else if (Spec.IsA('KFForcedReachSpec') || L.bJump)
        {
            if (Dz > Mut.SurveyJumpReach)
            {
                NTooHigh++;
                continue;
            }
            L.Type = LT_SHORTCUT;
            L.Prio = 2.0 + L.DropDmg / 100.0;
            NShortcut++;
            bAdd = true;
        }
        else if (Dz < -60.0)
        {
            L.Type = LT_DROP;
            L.Prio = 3.0 + L.DropDmg / 100.0;
            NDrop++;
            bAdd = true;
        }
        else if (LinkCrossesWall(A.Location, B.Location))
        {
            L.Type = LT_THROUGH;
            L.Prio = 1.0;
            NThrough++;
            bAdd = true;
        }
        if (bAdd)
        {
            List.AddItem(L);
        }
    }
}

// The best lead nobody works on: lowest Prio, then the one nearest to the bot. Marks it as claimed; -1 when none is left.
final function int Claim(int BotId, vector BotLoc)
{
    local int I, Best;
    local float Score, BestScore;

    Best = -1;
    BestScore = 1000000000.0;
    for (I = 0; I < List.Length; I++)
    {
        if (List[I].bDone || List[I].Claim != 0)
        {
            continue;
        }
        Score = List[I].Prio * 100000.0 + VSize(List[I].A.Location - BotLoc);
        if (Score < BestScore)
        {
            BestScore = Score;
            Best = I;
        }
    }
    if (Best >= 0)
    {
        List[Best].Claim = BotId + 1;
    }
    return Best;
}

// A bot gave up the lead for now (died, no floor): it can be claimed again until it has been tried 3 times.
final function Release(int Idx)
{
    List[Idx].Claim = 0;
}

// The lead is finished: it worked, or it failed for good.
final function Finish(int Idx, bool bOkay)
{
    List[Idx].bDone = true;
    List[Idx].Claim = 0;
    List[Idx].bOk = bOkay;
    DoneA.AddItem(List[Idx].A);
    DoneB.AddItem(List[Idx].B);
    if (bOkay)
    {
        NOk++;
        NOkRound++;
    }
    else
    {
        NFailed++;
    }
}

// Leads not finished yet.
final function int Remaining()
{
    local int I, N;

    for (I = 0; I < List.Length; I++)
    {
        if (!List[I].bDone)
        {
            N++;
        }
    }
    return N;
}
