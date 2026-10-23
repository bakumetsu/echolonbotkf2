// EcholonMapData.uc - Package EcholonBot
// One map's survey data, read from KFGame\Config\KFEcholonMapData.ini (section "<Map_Name> EcholonMapData").
// The kit writes the file (python kit\tools\nav_viz.py --export-mapdata <map>); the mod only reads it and never calls SaveConfig.
// The config vars below are filled by the engine when the object is created with new(None, "<Map_Name>").
// Link and node verdicts are resolved to live ReachSpecs and NavigationPoints a few entries per frame (Step, driven by
// EcholonMut.Tick) so a 450-entry list never costs a frame spike. The packed grid chunks stay as text until step 4 unpacks them.
// Fallback: no section, a node count or checksum that differs from the live map, or bSurveyNav off -> bUsable stays false
// and the nav works exactly as before.

class EcholonMapData extends Object config(EcholonMapData) perobjectconfig;

const VK_NONE = 0;
const VK_BAD_WALL = 1;
const VK_BAD_HIDDEN = 2;
const VK_NARROW = 3;
const VK_SAFE_DROP = 4;
const VK_HURT_DROP = 5;
const VK_PROVEN = 7;                    // a window or shortcut link a survey bot walked: usable although the route search treats it as special
const VK_TROUBLE = 6;                   // passes within 76 uu of a trouble spot: starts the match with one strike
const NV_WALL = 1;
const NV_UNREACHED = 2;
const PER_FRAME = 10;                   // verdict entries resolved per frame (NodeByName is a linear string search)
const SUM_MOD = 16777213;               // same checksum as EcholonNavDump
const SELFTEST_NODES = 50;              // verdict-free nodes checked against the survey grid at load
const SELFTEST_PER_FRAME = 5;

// file contents (header, verdict lists, packed chunks)
var config string Map;
var config string Date;
var config int Nodes;
var config int Links;
var config int Sum;
var config int Tile;
var config int OriginX;
var config int OriginY;
var config int LevelH;
var config array<string> LinkV;         // "from>to:verdict"
var config array<string> NodeV;         // "name:verdict"
var config array<string> Spot;          // "x,y,z,count"
var config array<string> GridChunk;        // "cx,cy,lvl,packed"

// state
var EcholonMut Mut;
var EcholonNavGrid Grid;                // receives the packed chunks (the lava grid object of the mutator)
var int ProvenUsed;                     // proven links the accepted routes used (one per link per search)
var int ProvenCount;                    // links with the proven verdict
var int TroubleCount;                   // links with the trouble verdict (the first relax step lets them back in)
var array<KFDoorActor> Doors;           // every door on the map: a clear grid line near a closed one still gets a real trace
var int LcDoor;
var int LcClear;                        // NavSurveyLineClear answers: clear, or why not (for NAV_GRID_UNPACK)
var int LcTooHigh;
var int LcTooLong;
var int LcUnknown;
var int LcNoFloor;
var int LcHidden;
var int LcEdge;
var int LcDist0;
var array<NavigationPoint> SelfNodes;   // self-test sample
var int SelfIdx;
var int SelfOk;
var int SelfClear;
var int SelfEdge;
var int SelfHidden;
var int SelfNoFloor;
var int SelfUnknown;
var bool bSelfDone;
var int RelaxCount;                     // route searches that had to relax a survey step (for NAV_SURVEY_SUMMARY)
var bool bFound;                        // the section exists in the ini
var bool bChecked;                      // header compared with the live map
var bool bMatch;                        // node count and checksum equal the live ones
var bool bUsable;                       // found and matching: verdicts may be used
var bool bDone;                         // every entry resolved
var int Phase;                          // 0 links, 1 nodes, 2 spots, 3 grid chunks
var int Idx;
var int Frames;
var int LiveNodes;
var int LiveSum;
var int LinksUsed;
var int LinksSkipped;
var int NodesUsed;
var int NodesSkipped;
var int PackedChars;
var array<NavigationPoint> NodeRefs;
var array<string> NodeNames;

// resolved verdicts
var array<ReachSpec> VSpec;
var array<int> VKind;
var array<NavigationPoint> VNode;       // nodes with a node verdict (wall / unreached)
var array<int> VNodeKind;
var array<vector> SpotPos;
var array<int> SpotCount;

// "Burning Paris" -> "Burning_Paris": every run of characters that are not letters or digits becomes one "_", the ends are trimmed.
// The kit writes the section name with the same rule (nav_mapdata.section_name).
static final function string SectionKey(string MapName)
{
    local string R, C;
    local int I, A;
    local bool bGap;

    R = "";
    bGap = false;
    for (I = 0; I < Len(MapName); I++)
    {
        C = Mid(MapName, I, 1);
        A = Asc(C);
        if ((A >= 48 && A <= 57) || (A >= 65 && A <= 90) || (A >= 97 && A <= 122))
        {
            if (bGap && R != "")
            {
                R = R $ "_";
            }
            bGap = false;
            R = R $ C;
        }
        else
        {
            bGap = true;
        }
    }
    return R;
}

// Collect the live nodes and their checksum, compare with the header. Called on the object the mutator created with new(None, key).
final function Begin(EcholonMut M)
{
    local NavigationPoint N;
    local KFDoorActor IterDoor;
    local int I;

    Mut = M;
    Grid = M.NavGrid;
    bFound = (Map != "");
    LiveNodes = 0;
    LiveSum = 0;
    NodeRefs.Length = 0;
    NodeNames.Length = 0;
    Doors.Length = 0;
    foreach M.WorldInfo.AllActors(class'KFDoorActor', IterDoor)
    {
        Doors.AddItem(IterDoor);
    }
    foreach M.WorldInfo.AllActors(class'NavigationPoint', N)
    {
        NodeRefs.AddItem(N);
        NodeNames.AddItem(string(N));
        LiveNodes++;
        LiveSum = (LiveSum + Abs(int(N.Location.X)) + Abs(int(N.Location.Y)) * 3 + Abs(int(N.Location.Z)) * 7) % SUM_MOD;
    }
    bMatch = bFound && Nodes == LiveNodes && Sum == LiveSum;
    bUsable = bMatch;
    bChecked = true;
    Phase = 0;
    Idx = 0;
    Frames = 0;
    for (I = 0; I < GridChunk.Length; I++)
    {
        PackedChars += Len(GridChunk[I]);
    }
    if (!bUsable)
    {
        bDone = true;
        Report();
        if (bFound)
        {
            M.EchelonLog("NAV_MAPDATA_MISMATCH map=" $ Map $ " file_nodes=" $ string(Nodes) $ " live_nodes=" $ string(LiveNodes)
                $ " file_sum=" $ string(Sum) $ " live_sum=" $ string(LiveSum) $ " action=file_ignored rerun_survey=1");
        }
    }
}

// Find a live node by name; None when the map no longer has it.
final function NavigationPoint NodeByName(string NodeName)
{
    local int I;

    I = NodeNames.Find(NodeName);
    if (I < 0)
    {
        return None;
    }
    return NodeRefs[I];
}

// The ReachSpec of From that ends at To; None when there is no such link.
final function ReachSpec FindSpec(NavigationPoint From, NavigationPoint To)
{
    local int I;

    if (From == None || To == None)
    {
        return None;
    }
    for (I = 0; I < From.PathList.Length; I++)
    {
        if (From.PathList[I] != None && From.PathList[I].GetEnd() == To)
        {
            return From.PathList[I];
        }
    }
    return None;
}

final function int KindOfName(string V)
{
    if (V == "bad_wall")
        return VK_BAD_WALL;
    if (V == "bad_hidden")
        return VK_BAD_HIDDEN;
    if (V == "narrow")
        return VK_NARROW;
    if (V == "safe_drop")
        return VK_SAFE_DROP;
    if (V == "hurt_drop")
        return VK_HURT_DROP;
    if (V == "trouble")
        return VK_TROUBLE;
    if (V == "proven")
        return VK_PROVEN;
    return VK_NONE;
}

// Resolve up to PER_FRAME entries; returns bDone. Called once per frame from EcholonMut.Tick until bDone.
final function bool Step()
{
    local int Items, P, Q, K;
    local string Entry, FromName, ToName, Verdict;
    local NavigationPoint A, B, N;
    local ReachSpec S;
    local array<string> Parts;

    if (bDone)
    {
        return true;
    }
    Frames++;
    Items = 0;
    if (Phase == 0)
    {
        while (Idx < LinkV.Length && Items < PER_FRAME)
        {
            Entry = LinkV[Idx];
            Idx++;
            Items++;
            P = InStr(Entry, ">");
            Q = InStr(Entry, ":");
            if (P < 0 || Q < P)
            {
                LinksSkipped++;
                continue;
            }
            FromName = Left(Entry, P);
            ToName = Mid(Entry, P + 1, Q - P - 1);
            Verdict = Mid(Entry, Q + 1);
            K = KindOfName(Verdict);
            A = NodeByName(FromName);
            B = NodeByName(ToName);
            S = FindSpec(A, B);
            if (K == VK_NONE || S == None)
            {
                LinksSkipped++;
                continue;
            }
            VSpec.AddItem(S);
            VKind.AddItem(K);
            LinksUsed++;
            if (K == VK_TROUBLE)
            {
                TroubleCount++;
            }
            if (K == VK_PROVEN)
            {
                ProvenCount++;
            }
        }
        if (Idx >= LinkV.Length)
        {
            Phase = 1;
            Idx = 0;
        }
    }
    else if (Phase == 1)
    {
        while (Idx < NodeV.Length && Items < PER_FRAME)
        {
            Entry = NodeV[Idx];
            Idx++;
            Items++;
            Q = InStr(Entry, ":");
            if (Q < 0)
            {
                NodesSkipped++;
                continue;
            }
            N = NodeByName(Left(Entry, Q));
            Verdict = Mid(Entry, Q + 1);
            if (N == None || (Verdict != "wall" && Verdict != "unreached"))
            {
                NodesSkipped++;
                continue;
            }
            VNode.AddItem(N);
            if (Verdict == "wall")
            {
                VNodeKind.AddItem(NV_WALL);
            }
            else
            {
                VNodeKind.AddItem(NV_UNREACHED);
            }
            NodesUsed++;
        }
        if (Idx >= NodeV.Length)
        {
            Phase = 2;
            Idx = 0;
        }
    }
    else if (Phase == 2)
    {
        while (Idx < Spot.Length && Items < PER_FRAME)
        {
            Entry = Spot[Idx];
            Idx++;
            Items++;
            ParseStringIntoArray(Entry, Parts, ",", true);
            if (Parts.Length < 4)
            {
                continue;
            }
            SpotPos.Length = SpotPos.Length + 1;
            SpotPos[SpotPos.Length - 1].X = float(Parts[0]);
            SpotPos[SpotPos.Length - 1].Y = float(Parts[1]);
            SpotPos[SpotPos.Length - 1].Z = float(Parts[2]);
            SpotCount.AddItem(int(Parts[3]));
        }
        if (Idx >= Spot.Length)
        {
            Phase = 3;
            Idx = 0;
            if (Grid != None)
            {
                Grid.SurveyPrepare(GridChunk.Length, LevelH);
            }
        }
    }
    else if (Phase == 3)
    {
        while (Idx < GridChunk.Length && Items < PER_FRAME)
        {
            Entry = GridChunk[Idx];
            Idx++;
            Items++;
            ParseStringIntoArray(Entry, Parts, ",", false);
            if (Grid == None || Parts.Length < 4)
            {
                continue;
            }
            Grid.SurveyAddChunk(int(Parts[0]), int(Parts[1]), int(Parts[2]), Parts[3]);
        }
        if (Idx >= GridChunk.Length)
        {
            if (Grid != None)
            {
                Grid.bSurveyLoaded = true;
                Grid.bSurveyReady = Mut.bSurveyNavGridNow;
            }
            Phase = 4;
            Idx = 0;
            PickSelfTest();
            Report();
        }
    }
    else
    {
        SelfTestStep();
        if (bSelfDone)
        {
            bDone = true;
        }
    }
    return bDone;
}

// Take up to SELFTEST_NODES nodes that have no node verdict, spread over the node list.
final function PickSelfTest()
{
    local int I, Step;

    SelfNodes.Length = 0;
    SelfIdx = 0;
    if (Grid == None || NodeRefs.Length == 0)
    {
        bSelfDone = true;
        return;
    }
    Step = Max(1, NodeRefs.Length / SELFTEST_NODES);
    for (I = 0; I < NodeRefs.Length && SelfNodes.Length < SELFTEST_NODES; I += Step)
    {
        if (NodeRefs[I] != None && VNode.Find(NodeRefs[I]) < 0)
        {
            SelfNodes.AddItem(NodeRefs[I]);
        }
    }
}

// Check a few nodes per frame: the floor tile under a verdict-free node should be standable on the survey grid. A low hit rate
// means the kit and the mod disagree about the packing (row order, negative chunk coordinates or the level rule).
final function SelfTestStep()
{
    local int N, S, D;
    local NavigationPoint Nd;

    N = 0;
    while (SelfIdx < SelfNodes.Length && N < SELFTEST_PER_FRAME)
    {
        Nd = SelfNodes[SelfIdx];
        SelfIdx++;
        N++;
        S = Grid.SurveyTileForce(Grid.TileOf(Nd.Location.X), Grid.TileOf(Nd.Location.Y), Nd.Location.Z - 45.0, D);
        if (S == class'EcholonNavGrid'.const.SV_CLEAR)
            SelfClear++;
        else if (S == class'EcholonNavGrid'.const.SV_EDGE)
            SelfEdge++;
        else if (S == class'EcholonNavGrid'.const.SV_HIDDEN)
            SelfHidden++;
        else if (S == class'EcholonNavGrid'.const.SV_NOFLOOR)
            SelfNoFloor++;
        else
            SelfUnknown++;
    }
    if (SelfIdx >= SelfNodes.Length)
    {
        SelfOk = SelfClear + SelfEdge + SelfHidden;
        bSelfDone = true;
        Mut.EchelonLog("NAV_MAPDATA_SELFTEST ok=" $ string(SelfOk) $ "/" $ string(SelfNodes.Length) $ " clear=" $ string(SelfClear) $ " edge=" $ string(SelfEdge)
            $ " hidden=" $ string(SelfHidden) $ " nofloor=" $ string(SelfNoFloor) $ " unknown=" $ string(SelfUnknown));
    }
}

// NAV_MAPDATA_LOAD: one line per match.
final function Report()
{
    local int F, M;

    F = 0;
    M = 0;
    if (bFound)
        F = 1;
    if (bMatch)
        M = 1;
    Mut.EchelonLog("NAV_MAPDATA_LOAD map=" $ Mut.WorldInfo.GetMapName() $ " found=" $ string(F) $ " checksum_match=" $ string(M)
        $ " links=" $ string(LinksUsed) $ " links_skipped=" $ string(LinksSkipped) $ " proven=" $ string(ProvenCount) $ " nodes=" $ string(NodesUsed) $ " nodes_skipped=" $ string(NodesSkipped)
        $ " spots=" $ string(SpotPos.Length) $ " chunks=" $ string(GridChunk.Length) $ " packed_chars=" $ string(PackedChars)
        $ " frames=" $ string(Frames));
}

// Verdict of a link (VK_NONE when the survey has nothing on it).
final function int VerdictOf(ReachSpec S)
{
    local int I;

    if (!bUsable || !bDone || S == None)
    {
        return VK_NONE;
    }
    I = VSpec.Find(S);
    if (I < 0)
    {
        return VK_NONE;
    }
    return VKind[I];
}

// Node verdict (0 none, NV_WALL, NV_UNREACHED).
final function int NodeVerdictOf(NavigationPoint N)
{
    local int I;

    if (!bUsable || !bDone || N == None)
    {
        return 0;
    }
    I = VNode.Find(N);
    if (I < 0)
    {
        return 0;
    }
    return VNodeKind[I];
}
