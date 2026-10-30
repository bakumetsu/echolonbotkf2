// EcholonTraffic: shadow-mode reservation table for narrow spots ("blocks").
// Computes tickets and reports where a bot WOULD have to wait; never holds
// anyone. Pure Object: no timers, no logging, no GotoState. Callers log.
// One instance lives on EcholonMut; the mutator calls Step() once per frame
// until it returns true, then Gate() per hop.
class EcholonTraffic extends Object transient;

const PER_FRAME = 10;
const TICKET_LIFE = 5.0;

var EcholonMut Mut;
var EcholonMapData MapData;
var bool bReady;
var int LoadIdx;
var array<string> BId;
var array<string> BKind;
var array<int> BCap;
var array<NavigationPoint> BEnd;
var array<NavigationPoint> EFrom;
var array<NavigationPoint> ETo;
var array<int> EBlock;
var array<int> TBlock;
var array<int> TDir;
var array<int> TPrio;
var array<Controller> TCtrl;
var array<Object> TSquad;
var array<float> TExpiry;
var array<float> TWouldAt;
var int CntBlocks;
var int CntDoor;
var int CntSpawn;
var int CntStairs;
var int CntNarrow;
var int CntSkipped;
var int CntEdges;
var int CntTickets;
var int CntWould;
var int CntWouldEnd;
var float SumWouldSecs;

final function bool Step()
{
    local array<string> Parts;
    local int I;
    local int NumLeft;
    local int Pos;
    local string BNameS, FNameS, TNameS;
    local NavigationPoint BNode;
    local array<string> Edges;
    local int J;
    local int EdgePos;
    local NavigationPoint FNode, TNode;
    local int BIdx;
    local string Entry;

    if (bReady)
        return true;
    if (MapData == None || !MapData.bUsable)
    {
        bReady = true;
        return true;
    }

    NumLeft = MapData.Block.Length - LoadIdx;
    if (NumLeft > PER_FRAME)
        NumLeft = PER_FRAME;

    I = 0;
    while (I < NumLeft)
    {
        Entry = MapData.Block[LoadIdx];
        LoadIdx++;
        I++;

        Parts.Length = 0;
        ParseStringIntoArray(Entry, Parts, ":", true);
        if (Parts.Length < 5)
        {
            CntSkipped++;
            continue;
        }

        Pos = InStr(Parts[3], ">");
        if (Pos < 0)
        {
            CntSkipped++;
            continue;
        }
        BNameS = Mid(Parts[3], Pos + 1);
        BNode = MapData.NodeByName(BNameS);
        if (BNode == None)
        {
            CntSkipped++;
            continue;
        }

        BId.AddItem(Parts[0]);
        BKind.AddItem(Parts[1]);
        BCap.AddItem(int(Parts[2]));
        if (BCap[BCap.Length - 1] <= 0)
            BCap[BCap.Length - 1] = 3;
        BEnd.AddItem(BNode);

        if (Parts[1] == "door")
            CntDoor++;
        else if (Parts[1] == "spawn")
            CntSpawn++;
        else if (Parts[1] == "stairs")
            CntStairs++;
        else
            CntNarrow++;
        CntBlocks++;

        BIdx = BId.Length - 1;

        Edges.Length = 0;
        ParseStringIntoArray(Parts[4], Edges, ",", true);
        for (J = 0; J < Edges.Length; J++)
        {
            EdgePos = InStr(Edges[J], ">");
            if (EdgePos < 0)
                continue;
            FNameS = Left(Edges[J], EdgePos);
            TNameS = Mid(Edges[J], EdgePos + 1);
            FNode = MapData.NodeByName(FNameS);
            TNode = MapData.NodeByName(TNameS);
            if (FNode == None || TNode == None)
                continue;
            EFrom.AddItem(FNode);
            ETo.AddItem(TNode);
            EBlock.AddItem(BIdx);
            CntEdges++;
        }
    }

    if (LoadIdx >= MapData.Block.Length)
        bReady = true;
    return bReady;
}

final function int EdgeBlockOf(NavigationPoint P, NavigationPoint N)
{
    local int I;

    if (P == None || N == None)
        return -1;

    for (I = 0; I < EFrom.Length; I++)
    {
        if ((EFrom[I] == P && ETo[I] == N) || (EFrom[I] == N && ETo[I] == P))
            return EBlock[I];
    }
    return -1;
}

final function int DirOf(int B, NavigationPoint P, NavigationPoint N)
{
    local float D2N, D2P;

    D2N = VSizeSq(N.Location - BEnd[B].Location);
    D2P = VSizeSq(P.Location - BEnd[B].Location);
    if (D2N < D2P)
        return 0;
    return 1;
}

final function int Occupied(int B, int Dir, Object Squad, bool bOpposite)
{
    local int I, Count;
    local float Now;

    Now = Mut.WorldInfo.TimeSeconds;
    Count = 0;
    for (I = 0; I < TBlock.Length; I++)
    {
        if (TBlock[I] != B)
            continue;
        if (TSquad[I] == Squad)
            continue;
        if (TExpiry[I] <= Now)
            continue;
        if (bOpposite)
        {
            if (TDir[I] != Dir)
                Count++;
        }
        else
        {
            if (TDir[I] == Dir)
                Count++;
        }
    }
    return Count;
}

final function bool Refused(int B, int Dir, Object Squad, out string Why, out int Load)
{
    Load = Occupied(B, Dir, Squad, false);
    if (Occupied(B, Dir, Squad, true) > 0)
    {
        Why = "opposite";
        return true;
    }
    if (Load >= BCap[B])
    {
        Why = "full";
        return true;
    }
    Why = "";
    return false;
}

final function bool Gate(Controller C, Object Squad, int Prio, NavigationPoint P, NavigationPoint N, NavigationPoint N2, out string WouldInfo, out string EndInfo)
{
    local float Now;
    local int I;
    local int B;
    local int idx;
    local float secs;
    local int Dir;
    local bool bRefuse;
    local string Why;
    local int Load;
    local int B2;
    local int Dir2;

    Now = Mut.WorldInfo.TimeSeconds;
    WouldInfo = "";
    EndInfo = "";

    // Step 1: sweep dead tickets (skip C's own for step 3)
    for (I = TCtrl.Length - 1; I >= 0; I--)
    {
        if (TExpiry[I] < Now || TCtrl[I] == None || TCtrl[I].Pawn == None || TCtrl[I].Pawn.Health <= 0)
        {
            if (TCtrl[I] != C)
            {
                if (TWouldAt[I] >= 0.0)
                {
                    if (Now < TExpiry[I])
                        SumWouldSecs += Now - TWouldAt[I];
                    else
                        SumWouldSecs += TExpiry[I] - TWouldAt[I];
                    CntWouldEnd++;
                }
                TBlock.Remove(I, 1);
                TDir.Remove(I, 1);
                TPrio.Remove(I, 1);
                TCtrl.Remove(I, 1);
                TSquad.Remove(I, 1);
                TExpiry.Remove(I, 1);
                TWouldAt.Remove(I, 1);
            }
        }
    }

    // Step 2
    B = EdgeBlockOf(P, N);
    idx = -1;
    for (I = 0; I < TCtrl.Length; I++)
    {
        if (TCtrl[I] == C)
        {
            idx = I;
            break;
        }
    }

    // Step 3
    if (idx >= 0)
    {
        if (B == TBlock[idx])
        {
            TExpiry[idx] = Now + TICKET_LIFE;
            return true;
        }
        // C leaves its block
        if (TWouldAt[idx] >= 0.0)
        {
            secs = Now - TWouldAt[idx];
            SumWouldSecs += secs;
            CntWouldEnd++;
            EndInfo = "block=" $ BId[TBlock[idx]] $ " secs=" $ string(int(secs + 0.5));
        }
        TBlock.Remove(idx, 1);
        TDir.Remove(idx, 1);
        TPrio.Remove(idx, 1);
        TCtrl.Remove(idx, 1);
        TSquad.Remove(idx, 1);
        TExpiry.Remove(idx, 1);
        TWouldAt.Remove(idx, 1);
    }

    // Step 4
    if (B < 0)
        return true;

    // Step 5
    Dir = DirOf(B, P, N);
    bRefuse = Refused(B, Dir, Squad, Why, Load);
    if (!bRefuse && N2 != None)
    {
        B2 = EdgeBlockOf(N, N2);
        if (B2 >= 0 && B2 != B)
        {
            Dir2 = DirOf(B2, N, N2);
            if (Refused(B2, Dir2, Squad, Why, Load))
            {
                bRefuse = true;
                Why = "chain";
            }
        }
    }

    // Step 6
    TBlock.AddItem(B);
    TDir.AddItem(Dir);
    TPrio.AddItem(Prio);
    TCtrl.AddItem(C);
    TSquad.AddItem(Squad);
    TExpiry.AddItem(Now + TICKET_LIFE);
    if (bRefuse)
        TWouldAt.AddItem(Now);
    else
        TWouldAt.AddItem(-1.0);
    CntTickets++;

    // Step 7
    if (bRefuse)
    {
        CntWould++;
        WouldInfo = "block=" $ BId[B] $ " kind=" $ BKind[B] $ " dir=" $ string(Dir) $ " prio=" $ string(Prio) $ " why=" $ Why $ " load=" $ string(Load);
    }

    // Step 8
    return true;
}

final function Leave(Controller C, out string EndInfo)
{
    local float Now;
    local int I;
    local float secs;

    EndInfo = "";
    Now = Mut.WorldInfo.TimeSeconds;

    for (I = 0; I < TCtrl.Length; I++)
    {
        if (TCtrl[I] == C)
        {
            if (TWouldAt[I] >= 0.0)
            {
                secs = Now - TWouldAt[I];
                SumWouldSecs += secs;
                CntWouldEnd++;
                EndInfo = "block=" $ BId[TBlock[I]] $ " secs=" $ string(int(secs + 0.5));
            }
            TBlock.Remove(I, 1);
            TDir.Remove(I, 1);
            TPrio.Remove(I, 1);
            TCtrl.Remove(I, 1);
            TSquad.Remove(I, 1);
            TExpiry.Remove(I, 1);
            TWouldAt.Remove(I, 1);
            break;
        }
    }
}

final function string SummaryText()
{
    local string S;

    S = "tickets=" $ string(CntTickets) $ " would=" $ string(CntWould) $ " would_end=" $ string(CntWouldEnd) $ " would_secs=" $ string(int(SumWouldSecs + 0.5)) $ " live=" $ string(TCtrl.Length);
    CntTickets = 0;
    CntWould = 0;
    CntWouldEnd = 0;
    SumWouldSecs = 0.0;
    return S;
}

final function string BlocksText()
{
    return "map=" $ Mut.WorldInfo.GetMapName() $ " count=" $ string(CntBlocks) $ " door=" $ string(CntDoor) $ " spawn=" $ string(CntSpawn) $ " stairs=" $ string(CntStairs) $ " narrow=" $ string(CntNarrow) $ " edges=" $ string(CntEdges) $ " skipped=" $ string(CntSkipped);
}
