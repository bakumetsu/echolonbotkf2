// EcholonZonePlanner.uc
// Builds the zone list once per match: candidate defend zones (Dosh Hold volumes and trader pods), a
// reachability flood from the player starts, standing spots, entries and a usable verdict.
// Logging only; no behaviour change. Work is spread over frames via Step() from the mutator Tick.

class EcholonZonePlanner extends Object transient;

struct ZoneEntry
{
    var vector Loc;
    var NavigationPoint Inside;
    var NavigationPoint Outside;
    var int Links;
};

struct ZoneRec
{
    var int Id;
    var byte Src;
    var Actor Source;
    var vector Center;
    var float Radius;
    var array<NavigationPoint> Spots;
    var array<ZoneEntry> Entries;
    var bool bUsable;
    var string Why;
    var array<NavigationPoint> Pool;
};

var array<ZoneRec> Zones;
var EcholonMut Mut;
var int Phase;
var int Cursor;
var float StartTime;
var int Frames;
var bool bDone;
var array<vector> SpawnLocs;
var array<NavigationPoint> AllNodes;
var array<byte> Reached;
var int DoshCount;
var int PodCount;

var array<int> NodeHash;
var array<int> Queue;
var int QHead;
var bool bFloodInit;
var int ReachedCount;
var int StarvedFrames;
var array<vector> ZoneSpawns;
var array<NavigationPoint> SeenIn;
var array<NavigationPoint> SeenOut;

const PH_COLLECT = 0;
const PH_FLOOD = 1;
const PH_ZONES = 2;
const PH_DONE = 3;

// Initialise planner; call once at match start.
final function Begin(EcholonMut M, float Now)
{
    Mut = M;
    StartTime = Now;
    Phase = PH_COLLECT;
    Cursor = 0;
    Frames = 0;
    bDone = false;
    Zones.Length = 0;
    SpawnLocs.Length = 0;
    AllNodes.Length = 0;
    Reached.Length = 0;
    DoshCount = 0;
    PodCount = 0;
    bFloodInit = false;
    QHead = 0;
    ReachedCount = 0;
    StarvedFrames = 0;
    Queue.Length = 0;
    NodeHash.Length = 0;
}

// Per-frame advance; returns true when finished.
final function bool Step(float Now)
{
    local bool Done;

    Frames++;
    switch (Phase)
    {
    case PH_COLLECT:
        StepCollect();
        break;
    case PH_FLOOD:
        StepFlood(Now);
        break;
    case PH_ZONES:
        StepZones(Now);
        break;
    case PH_DONE:
        bDone = true;
        break;
    }
    Done = bDone;
    return Done;
}

// Hash key derived from a NavigationPoint's location (13-bit bucket).
final function int NodeHashKey(NavigationPoint N)
{
    local int Key;

    Key = ((int(N.Location.X) / 16) * 73856093) ^ ((int(N.Location.Y) / 16) * 19349663) ^ ((int(N.Location.Z) / 16) * 83492791);
    Key = Key & 8191;
    return Key;
}

// Insert AllNodes[Idx] into the open-addressing hash (linear probe).
final function HashAdd(int Idx)
{
    local int Slot;
    local int Probes;


    Slot = NodeHashKey(AllNodes[Idx]);
    while (NodeHash[Slot] != -1 && Probes < 8192)
    {
        Slot = (Slot + 1) & 8191;
        Probes++;
    }
    if (Probes < 8192)
    {
        NodeHash[Slot] = Idx;
    }
}

// Look up the AllNodes index for a given NavigationPoint; -1 if absent.
final function int NodeIndex(NavigationPoint N)
{
    local int Slot;
    local int Idx;
    local int Probes;

    Slot = NodeHashKey(N);
    while (NodeHash[Slot] != -1 && Probes < 8192)
    {
        Idx = NodeHash[Slot];
        if (AllNodes[Idx] == N)
        {
            return Idx;
        }
        Slot = (Slot + 1) & 8191;
        Probes++;
    }
    return -1;
}

// True when N was marked reachable by the flood.
final function bool IsReached(NavigationPoint N)
{
    local int Idx;

    Idx = NodeIndex(N);
    if (Idx < 0)
    {
        return false;
    }
    return Reached[Idx] == 1;
}

// BFS reachability flood over AllNodes, spread across frames (300 nodes/step).
final function StepFlood(float Now)
{
    local int i, j;
    local int NodeIdx;
    local int EndIdx;
    local int Count;
    local NavigationPoint N;
    local NavigationPoint End;
    local ReachSpec Spec;
    local bool bFoundStart;

    if (!bFloodInit)
    {
        // The node hash has 8192 slots; a bigger map cannot be indexed, so skip the list instead of looping.
        if (AllNodes.Length > 6000)
        {
            Mut.EchelonLog("ZONE_SKIP reason=too_many_nodes nodes=" $ string(AllNodes.Length));
            Phase = PH_DONE;
            bDone = true;
            return;
        }
        // --- one-shot init ---
        Reached.Length = AllNodes.Length;
        for (i = 0; i < AllNodes.Length; i++)
        {
            Reached[i] = 0;
        }

        NodeHash.Length = 8192;
        for (i = 0; i < 8192; i++)
        {
            NodeHash[i] = -1;
        }
        for (i = 0; i < AllNodes.Length; i++)
        {
            HashAdd(i);
        }

        // Queue every PlayerStart nav-point as a root.
        Queue.Length = 0;
        ReachedCount = 0;
        QHead = 0;
        bFoundStart = false;

        for (i = 0; i < AllNodes.Length; i++)
        {
            if (AllNodes[i].IsA('PlayerStart'))
            {
                Reached[i] = 1;
                ReachedCount++;
                Queue.AddItem(i);
                bFoundStart = true;
            }
        }

        // Fallback: no PlayerStart on map � seed with node 0.
        if (!bFoundStart && AllNodes.Length > 0)
        {
            Reached[0] = 1;
            ReachedCount++;
            Queue.AddItem(0);
        }

        bFloodInit = true;
        return;
    }

    // --- steady-state: process up to 300 nodes this frame ---
    Count = 0;
    while (QHead < Queue.Length && Count < 300)
    {
        // Budget gate: bail early if the scanner's time slice is nearly gone.
        if (Mut.NavBudget != None && Mut.NavBudget.UsLeft(class'EcholonNavBudget'.const.NAV_PRIO_SCAN, Now) < 4.0 * Mut.NavMeter.UnitTraceUs)
        {
            break;
        }

        NodeIdx = Queue[QHead];
        N = AllNodes[NodeIdx];

        // Walk every outgoing link.
        for (j = 0; j < N.PathList.Length; j++)
        {
            Spec = N.PathList[j];
            if (Spec != None)
            {
                End = Spec.GetEnd();
                if (End != None)
                {
                    EndIdx = NodeIndex(End);
                    if (EndIdx >= 0 && Reached[EndIdx] == 0)
                    {
                        Reached[EndIdx] = 1;
                        ReachedCount++;
                        Queue.AddItem(EndIdx);
                    }
                }
            }
        }

        // Charge the budget for the work just done.
        if (Mut.NavBudget != None)
        {
            Mut.NavBudget.TakeUs(class'EcholonNavBudget'.const.NAV_PRIO_SCAN, 2.0 * Mut.NavMeter.UnitTraceUs, Now);
        }

        QHead++;
        Count++;
    }

    // Queue exhausted � flood is complete.
    if (QHead >= Queue.Length)
    {
        Mut.EchelonLog("ZONE_FLOOD reached=" $ string(ReachedCount) $ " nodes=" $ string(AllNodes.Length) $ " frames=" $ string(Frames));
        Phase = PH_ZONES;
    }
}

// Stage C: zone builder � processes one zone per call, logs results.

final function StepZones(float Now)
{
    local ZoneRec Z;
    local int i, j;
    local int U;
    local NavigationPoint N;
    local NavigationPoint End;
    local ReachSpec Spec;
    local KFTraderTrigger T;
    local float PodR;
    local float PodH;
    local float Excl;
    local float R;
    local float D;
    local float BestDist;
    local vector BestLoc;
    local bool bFoundCenter;
    local bool bMerged;
    local bool bInZone;
    local array<NavigationPoint> Candidates;
    local string SrcStr;
    local int EntryCount;
    local int UsableInt;
    local int Dropped;
    local float ReachMax;
    local float NearSpawn;

    // --- Step 0: all zones processed ---
    if (Cursor >= Zones.Length)
    {
        U = 0;
        for (i = 0; i < Zones.Length; i++)
        {
            if (Zones[i].bUsable)
            {
                U++;
            }
        }
        Mut.EchelonLog("ZONE_LIST_DONE map=" $ Mut.WorldInfo.GetMapName() $ " usable=" $ string(U) $ " total=" $ string(Zones.Length) $ " frames=" $ string(Frames) $ " secs=" $ string(int(Now - StartTime + 0.5)) $ " reached=" $ string(ReachedCount) $ "/" $ string(AllNodes.Length));
        Phase = PH_DONE;
        bDone = true;
        return;
    }

    // --- Budget gate ---
    // Wait for a free slice, but never starve: after 10 busy frames in a row do the zone anyway.
    if (Mut.NavBudget != None && StarvedFrames < 10
        && Mut.NavBudget.UsLeft(class'EcholonNavBudget'.const.NAV_PRIO_SCAN, Now) < 20.0 * Mut.NavMeter.UnitTraceUs)
    {
        StarvedFrames++;
        return;
    }
    StarvedFrames = 0;

    // --- Step 1: copy zone, check merged ---
    Z = Zones[Cursor];
    bMerged = (Left(Z.Why, 6) == "merged");

    if (!bMerged)
    {
        Candidates.Length = 0;
        Dropped = 0;

        ZoneSpawns.Length = 0;

        if (Z.Src == 0)
        {
            // Dosh: candidates = reached GoodSpotNodes in Z.Pool (plus the area of pods merged into it)
            AbsorbMergedPods(Z);
            ReachMax = 0.0;
            for (i = 0; i < Z.Pool.Length; i++)
            {
                D = VSize(Z.Pool[i].Location - Z.Center);
                if (D > ReachMax)
                {
                    ReachMax = D;
                }
            }
            BuildZoneSpawns(Z.Center, ReachMax + Mut.ZoneSpawnClear + 50.0);
            for (i = 0; i < Z.Pool.Length; i++)
            {
                N = Z.Pool[i];
                if (IsReached(N) && GoodSpotNode(N))
                {
                    if (SpawnNear(N.Location))
                    {
                        Dropped++;
                    }
                    else
                    {
                        Candidates.AddItem(N);
                    }
                }
            }
            PickSpots(Z, Candidates);
        }
        else
        {
            // Pod
            T = KFTraderTrigger(Z.Source);
            T.GetBoundingCylinder(PodR, PodH);
            Excl = PodR + 150.0;

            // Find best center node
            bFoundCenter = false;
            BestDist = 0.0;
            for (i = 0; i < AllNodes.Length; i++)
            {
                N = AllNodes[i];
                if (IsReached(N) && GoodSpotNode(N))
                {
                    if (VSize2D(N.Location - T.Location) > Excl)
                    {
                        D = VSize(N.Location - T.Location);
                        if (!bFoundCenter || D < BestDist)
                        {
                            BestDist = D;
                            BestLoc = N.Location;
                            bFoundCenter = true;
                        }
                    }
                }
            }

            if (bFoundCenter)
            {
                Z.Center = BestLoc;
                BuildZoneSpawns(Z.Center, Mut.ZonePodRadiusMax + Mut.ZoneSpawnClear + 50.0);
                R = Mut.ZonePodRadius;

                // Build initial candidates
                Candidates.Length = 0;
                Dropped = 0;
                for (i = 0; i < AllNodes.Length; i++)
                {
                    N = AllNodes[i];
                    if (IsReached(N) && GoodSpotNode(N))
                    {
                        if (VSize2D(N.Location - Z.Center) <= R && Abs(N.Location.Z - Z.Center.Z) <= 300.0 && VSize2D(N.Location - T.Location) > Excl)
                        {
                            if (SpawnNear(N.Location))
                            {
                                Dropped++;
                            }
                            else
                            {
                                Candidates.AddItem(N);
                            }
                        }
                    }
                }

                PickSpots(Z, Candidates);

                // Expand radius until enough spots or max reached
                while (Z.Spots.Length < Mut.ZoneMinSpots && R + Mut.ZonePodStep <= Mut.ZonePodRadiusMax)
                {
                    R += Mut.ZonePodStep;
                    Candidates.Length = 0;
                    Dropped = 0;
                    for (i = 0; i < AllNodes.Length; i++)
                    {
                        N = AllNodes[i];
                        if (IsReached(N) && GoodSpotNode(N))
                        {
                            if (VSize2D(N.Location - Z.Center) <= R && Abs(N.Location.Z - Z.Center.Z) <= 300.0 && VSize2D(N.Location - T.Location) > Excl)
                            {
                                if (SpawnNear(N.Location))
                                {
                                    Dropped++;
                                }
                                else
                                {
                                    Candidates.AddItem(N);
                                }
                            }
                        }
                    }
                    PickSpots(Z, Candidates);
                }
            }
            // else: no center found, Z.Center unchanged, no candidates
        }

        // --- Step 5: Entries ---
        Z.Entries.Length = 0;
        SeenIn.Length = 0;
        SeenOut.Length = 0;
        for (i = 0; i < AllNodes.Length; i++)
        {
            N = AllNodes[i];
            if (!IsReached(N))
            {
                continue;
            }

            bInZone = ZoneHas(Z, N);

            if (bInZone)
            {
                for (j = 0; j < N.PathList.Length; j++)
                {
                    Spec = N.PathList[j];
                    if (Spec != None)
                    {
                        End = Spec.GetEnd();
                        if (End != None && !ZoneHas(Z, End))
                        {
                            AddEntryLink(Z, N, End);
                        }
                    }
                }
            }
            else if (VSize2D(N.Location - Z.Center) <= Z.Radius + 1500.0)
            {
                for (j = 0; j < N.PathList.Length; j++)
                {
                    Spec = N.PathList[j];
                    if (Spec != None)
                    {
                        End = Spec.GetEnd();
                        if (End != None && ZoneHas(Z, End))
                        {
                            AddEntryLink(Z, End, N);
                        }
                    }
                }
            }
        }

        // --- Step 6: Verdict ---
        Z.bUsable = true;
        Z.Why = "ok";

        if (Z.Src == 0 && Z.Pool.Length == 0)
        {
            Z.Why = "no_nodes";
            Z.bUsable = false;
        }
        else if (Z.Spots.Length == 0 && Dropped == 0)
        {
            Z.Why = "unreachable";
            Z.bUsable = false;
        }
        else if (SpawnNear(Z.Center))
        {
            Z.Why = "spawn_near";
            Z.bUsable = false;
        }
        else if (Z.Spots.Length < Mut.ZoneMinSpots)
        {
            Z.Why = "few_spots";
            Z.bUsable = false;
        }

        if (Z.bUsable && Z.Entries.Length == 0)
        {
            Z.Why = "no_entry";
            Z.bUsable = false;
        }
    }

    // --- Step 7: Log ---
    if (Z.Src == 0)
    {
        SrcStr = "dosh";
    }
    else
    {
        SrcStr = "pod";
    }

    if (bMerged)
    {
        Mut.EchelonLog("ZONE_LIST id=" $ string(Z.Id) $ " src=" $ SrcStr $ " name=" $ string(Z.Source.Name) $ " at=" $ Fmt(Z.Center) $ " radius=" $ string(int(Z.Radius)) $ " spots=0 entries=0 usable=0 why=" $ Z.Why $ " into=" $ Mid(Z.Why, 12));
    }
    else
    {
        EntryCount = Z.Entries.Length;
        NearSpawn = 999999.0;
        for (i = 0; i < SpawnLocs.Length; i++)
        {
            D = VSize(SpawnLocs[i] - Z.Center);
            if (D < NearSpawn)
            {
                NearSpawn = D;
            }
        }
        UsableInt = 0;
        if (Z.bUsable)
        {
            UsableInt = 1;
        }
        Mut.EchelonLog("ZONE_LIST id=" $ string(Z.Id) $ " src=" $ SrcStr $ " name=" $ string(Z.Source.Name) $ " at=" $ Fmt(Z.Center) $ " radius=" $ string(int(Z.Radius)) $ " spots=" $ string(Z.Spots.Length) $ " entries=" $ string(EntryCount) $ " usable=" $ string(UsableInt) $ " why=" $ Z.Why $ " nearspawn=" $ string(int(NearSpawn)) $ " dropped=" $ string(Dropped));

        if (Z.bUsable)
        {
            for (i = 0; i < Z.Entries.Length; i++)
            {
                Mut.EchelonLog("ZONE_ENTRY zone=" $ string(Z.Id) $ " idx=" $ string(i) $ " at=" $ Fmt(Z.Entries[i].Loc) $ " links=" $ string(Z.Entries[i].Links));
            }
        }
    }

    // --- Step 8: Write back ---
    Zones[Cursor] = Z;
    Cursor++;

    // Charge budget
    if (Mut.NavBudget != None)
    {
        Mut.NavBudget.TakeUs(class'EcholonNavBudget'.const.NAV_PRIO_SCAN, 50.0 * Mut.NavMeter.UnitTraceUs, Now);
    }
}

// Greedy spot picker: nearest-to-center first, maintaining min spacing.
final function PickSpots(out ZoneRec Z, array<NavigationPoint> Candidates)
{
    local int i, j;
    local NavigationPoint N;
    local NavigationPoint BestN;
    local float BestDist;
    local float D;
    local bool bFound;
    local bool bValid;
    local float MaxDist;

    Z.Spots.Length = 0;

    while (true)
    {
        bFound = false;
        BestDist = 0.0;

        for (i = 0; i < Candidates.Length; i++)
        {
            N = Candidates[i];

            // Skip if already picked
            bValid = true;
            for (j = 0; j < Z.Spots.Length; j++)
            {
                if (Z.Spots[j] == N)
                {
                    bValid = false;
                    break;
                }
            }
            if (!bValid)
            {
                continue;
            }

            // Check spacing from every picked spot
            for (j = 0; j < Z.Spots.Length; j++)
            {
                if (VSize2D(N.Location - Z.Spots[j].Location) < Mut.ZoneSpotSpacing)
                {
                    bValid = false;
                    break;
                }
            }
            if (!bValid)
            {
                continue;
            }

            D = VSize2D(N.Location - Z.Center);
            if (!bFound || D < BestDist)
            {
                BestDist = D;
                BestN = N;
                bFound = true;
            }
        }

        if (!bFound)
        {
            break;
        }

        Z.Spots.AddItem(BestN);
    }

    // Radius = farthest picked spot from center, minimum 600.0
    if (Z.Spots.Length > 0)
    {
        MaxDist = 0.0;
        for (i = 0; i < Z.Spots.Length; i++)
        {
            D = VSize2D(Z.Spots[i].Location - Z.Center);
            if (D > MaxDist)
            {
                MaxDist = D;
            }
        }
        Z.Radius = MaxDist;
        if (Z.Radius < 600.0)
        {
            Z.Radius = 600.0;
        }
    }
}

// True when a zed spawn volume centre lies within ZoneSpawnClear of the location.
final function bool SpawnNear(vector L)
{
    local int i;

    for (i = 0; i < ZoneSpawns.Length; i++)
    {
        if (VSize(ZoneSpawns[i] - L) < Mut.ZoneSpawnClear)
        {
            return true;
        }
    }
    return false;
}

// Keep only the spawn volume centres that can matter for the zone being built (within Reach of its centre).
final function BuildZoneSpawns(vector C, float Reach)
{
    local int i;

    ZoneSpawns.Length = 0;
    for (i = 0; i < SpawnLocs.Length; i++)
    {
        if (VSize(SpawnLocs[i] - C) <= Reach)
        {
            ZoneSpawns.AddItem(SpawnLocs[i]);
        }
    }
}

// A trader pod merged into a Dosh Hold zone lends its standing area to it: its reached nodes join the Pool.
final function AbsorbMergedPods(out ZoneRec Z)
{
    local int k, m;
    local KFTraderTrigger T;
    local float PodR, PodH, Excl;
    local NavigationPoint N;
    local string Tag;

    Tag = "merged_into_" $ string(Z.Id);
    for (k = 0; k < Zones.Length; k++)
    {
        if (Zones[k].Src != 1 || Zones[k].Why != Tag)
        {
            continue;
        }
        T = KFTraderTrigger(Zones[k].Source);
        if (T == None)
        {
            continue;
        }
        T.GetBoundingCylinder(PodR, PodH);
        Excl = PodR + 150.0;
        for (m = 0; m < AllNodes.Length; m++)
        {
            N = AllNodes[m];
            if (IsReached(N) && GoodSpotNode(N) && Z.Pool.Find(N) < 0
                && VSize2D(N.Location - T.Location) > Excl && VSize2D(N.Location - T.Location) <= Mut.ZonePodRadius)
            {
                Z.Pool.AddItem(N);
            }
        }
    }
}

// True when N is a valid spot candidate (not a lift, ladder, teleporter or jump pad).
final function bool GoodSpotNode(NavigationPoint N)
{
    if (N == None)
    {
        return false;
    }
    if (N.IsA('Teleporter'))
    {
        return false;
    }
    if (N.IsA('LiftCenter'))
    {
        return false;
    }
    if (N.IsA('LiftExit'))
    {
        return false;
    }
    if (N.IsA('LadderMarker'))
    {
        return false;
    }
    if (N.IsA('JumpPad'))
    {
        return false;
    }
    return true;
}

// True when N belongs to zone Z (pool membership or radial check).
final function bool ZoneHas(out ZoneRec Z, NavigationPoint N)
{
    if (Z.Src == 0)
    {
        return Z.Pool.Find(N) >= 0;
    }
    return (VSize2D(N.Location - Z.Center) <= Z.Radius + 100.0) && (Abs(N.Location.Z - Z.Center.Z) <= 300.0);
}

// Record a transition between an inside node and an outside node as an entry link.
final function AddEntryLink(out ZoneRec Z, NavigationPoint Inside, NavigationPoint Outside)
{
    local int i;
    local ZoneEntry E;
    local bool bFound;

    // A two-way link shows up from both ends: count each Inside/Outside pair once.
    for (i = 0; i < SeenIn.Length; i++)
    {
        if (SeenIn[i] == Inside && SeenOut[i] == Outside)
        {
            return;
        }
    }
    SeenIn.AddItem(Inside);
    SeenOut.AddItem(Outside);

    bFound = false;
    for (i = 0; i < Z.Entries.Length; i++)
    {
        E = Z.Entries[i];
        if (VSize(Outside.Location - E.Loc) < 400.0)
        {
            E.Loc = (E.Loc * float(E.Links) + Outside.Location) / float(E.Links + 1);
            E.Links++;
            Z.Entries[i] = E;
            bFound = true;
            break;
        }
    }

    if (!bFound)
    {
        E.Loc = Outside.Location;
        E.Inside = Inside;
        E.Outside = Outside;
        E.Links = 1;
        Z.Entries.AddItem(E);
    }
}

// Format a vector as "x,y,z" in integer unreal units.
final function string Fmt(vector V)
{
    return string(int(V.X)) $ "," $ string(int(V.Y)) $ "," $ string(int(V.Z));
}

// One-shot collection of candidate zones, spawn points, and merge cull.
final function StepCollect()
{
    local NavigationPoint N;
    local KFMapObjective_DoshHold D;
    local KFTraderTrigger T;
    local KFSpawnVolume SV;
    local ZoneRec Z;
    local ZoneRec P;
    local int i, j;
    local vector C;

    // Gather every NavigationPoint in the map.
    foreach Mut.WorldInfo.AllActors(class'NavigationPoint', N)
    {
        AllNodes.AddItem(N);
    }

    // Dosh Hold volumes (Src 0).
    foreach Mut.WorldInfo.AllActors(class'KFMapObjective_DoshHold', D)
    {
        Z.Id = Zones.Length + 1;
        Z.Src = 0;
        Z.Source = D;
        Z.Center = D.Location;
        Z.Radius = 0.0;
        Z.bUsable = true;
        Z.Why = "ok";
        Z.Pool.Length = 0;

        // Pool = nodes encompassed by this volume.
        for (i = 0; i < AllNodes.Length; i++)
        {
            if (D.Encompasses(AllNodes[i]))
            {
                Z.Pool.AddItem(AllNodes[i]);
            }
        }

        // Centre on average pool location if any.
        if (Z.Pool.Length > 0)
        {
            C = vect(0, 0, 0);
            for (i = 0; i < Z.Pool.Length; i++)
            {
                C += Z.Pool[i].Location;
            }
            C = C / float(Z.Pool.Length);
            Z.Center = C;
        }

        Zones.AddItem(Z);
        DoshCount++;
    }

    // Trader pods (Src 1); Pool filled in stage B.
    foreach Mut.WorldInfo.AllActors(class'KFTraderTrigger', T)
    {
        Z.Id = Zones.Length + 1;
        Z.Src = 1;
        Z.Source = T;
        Z.Center = T.Location;
        Z.Radius = 0.0;
        Z.bUsable = true;
        Z.Why = "ok";
        Z.Pool.Length = 0;

        Zones.AddItem(Z);
        PodCount++;
    }

    // Spawn volume locations.
    foreach Mut.WorldInfo.AllActors(class'KFSpawnVolume', SV)
    {
        SpawnLocs.AddItem(SV.Location);
    }

    // Merge cull: disable pod zones that are too close to a Dosh Hold zone.
    for (i = 0; i < Zones.Length; i++)
    {
        P = Zones[i];
        if (P.Src != 1)
        {
            continue;
        }
        for (j = 0; j < Zones.Length; j++)
        {
            if (Zones[j].Src != 0)
            {
                continue;
            }
            if (VSize2D(P.Center - Zones[j].Center) < Mut.ZoneMergeDist)
            {
                P.bUsable = false;
                P.Why = "merged_into_" $ string(Zones[j].Id);
                Zones[i] = P;
                break;
            }
        }
    }

    // Log summary.
    Mut.EchelonLog("ZONE_LIST_START dosh=" $ string(DoshCount) $ " pods=" $ string(PodCount) $ " spawns=" $ string(SpawnLocs.Length) $ " nodes=" $ string(AllNodes.Length));

    // Advance to flood-fill phase.
    Phase = PH_FLOOD;
}

final function int PrimaryEntry(int ZoneIdx)
{
    local ZoneRec Z;
    local int e, s;
    local int NearestIdx;
    local float NearestDist;
    local array<int> EntryCounts;
    local int BestIdx;
    local int BestCount;
    local int BestLinks;
    local int NumEntries;

    Z = Zones[ZoneIdx];
    NumEntries = Z.Entries.Length;
    if (NumEntries == 0)
        return -1;

    // count nearest-entry hits per entry
    for (e = 0; e < NumEntries; e++)
        EntryCounts.AddItem(0);

    for (s = 0; s < SpawnLocs.Length; s++)
    {
        NearestIdx = 0;
        NearestDist = VSize(SpawnLocs[s] - Z.Entries[0].Loc);
        for (e = 1; e < NumEntries; e++)
        {
            if (VSize(SpawnLocs[s] - Z.Entries[e].Loc) < NearestDist)
            {
                NearestDist = VSize(SpawnLocs[s] - Z.Entries[e].Loc);
                NearestIdx = e;
            }
        }
        EntryCounts[NearestIdx]++;
    }

    // best: highest count, tie -> larger Links, tie -> lower index
    BestIdx = 0;
    BestCount = EntryCounts[0];
    BestLinks = Z.Entries[0].Links;
    for (e = 1; e < NumEntries; e++)
    {
        if (EntryCounts[e] > BestCount)
        {
            BestIdx = e;
            BestCount = EntryCounts[e];
            BestLinks = Z.Entries[e].Links;
        }
        else if (EntryCounts[e] == BestCount && Z.Entries[e].Links > BestLinks)
        {
            BestIdx = e;
            BestLinks = Z.Entries[e].Links;
        }
    }
    return BestIdx;
}

final function array<EcholonMut.SquadDeal> DealSpots(int ZoneIdx, array<int> MemberCounts)
{
    local ZoneRec Z;
    local array<EcholonMut.SquadDeal> Result;
    local array<bool> bTaken;
    local int i, j, k;
    local int NumSquads;
    local int NumSpots;
    local int pe;
    local int PickNum;
    local int BestIdx;
    local float BestDist;
    local vector Target;
    local vector CoreLeader;
    local vector EntryLeader;
    local vector ReserveTarget;
    local EcholonMut.SquadDeal Deal;
    local EcholonMut.SquadDeal EmptyDeal;
    local bool bCoreDealt;
    local bool bEntryDealt;

    if (MemberCounts.Length == 0)
    {
        return Result;
    }

    Z = Zones[ZoneIdx];
    NumSquads = MemberCounts.Length;
    NumSpots = Z.Spots.Length;

    // default deals with correct Role
    for (i = 0; i < NumSquads; i++)
    {
        Deal = EmptyDeal;
        if (i == 0)
            Deal.Role = 0;
        else if (i == 1)
            Deal.Role = 1;
        else
            Deal.Role = 2;
        Result.AddItem(Deal);
    }

    // no spots -> Shortage = MemberCounts[i], LeaderNav already None
    if (NumSpots == 0)
    {
        for (i = 0; i < NumSquads; i++)
        {
            Deal = Result[i];
            Deal.Shortage = MemberCounts[i];
            Result[i] = Deal;
        }
        return Result;
    }

    for (i = 0; i < NumSpots; i++)
        bTaken.AddItem(false);

    bCoreDealt = (MemberCounts[0] > 0);
    bEntryDealt = (NumSquads > 1 && MemberCounts[1] > 0);

    // --- Squad 0: Core ---
    if (MemberCounts[0] > 0)
    {
        Target = Z.Center;
        PickNum = 0;
        for (j = 0; j < MemberCounts[0]; j++)
        {
            BestIdx = -1;
            BestDist = 999999.0;
            for (i = 0; i < NumSpots; i++)
            {
                if (!bTaken[i] && VSize2D(Z.Spots[i].Location - Target) < BestDist)
                {
                    BestDist = VSize2D(Z.Spots[i].Location - Target);
                    BestIdx = i;
                }
            }
            if (BestIdx == -1)
            {
                // no free spot: nearest regardless
                BestIdx = 0;
                BestDist = VSize2D(Z.Spots[0].Location - Target);
                for (i = 1; i < NumSpots; i++)
                {
                    if (VSize2D(Z.Spots[i].Location - Target) < BestDist)
                    {
                        BestDist = VSize2D(Z.Spots[i].Location - Target);
                        BestIdx = i;
                    }
                }
                Deal = Result[0];
                Deal.Shortage++;
                Result[0] = Deal;
            }
            else
            {
                bTaken[BestIdx] = true;
            }

            Deal = Result[0];
            if (PickNum == 0)
            {
                Deal.LeaderNav = Z.Spots[BestIdx];
                Deal.LeaderSpot = Z.Spots[BestIdx].Location;
                CoreLeader = Deal.LeaderSpot;
            }
            else
            {
                Deal.FollowerSpots.AddItem(Z.Spots[BestIdx].Location);
            }
            Result[0] = Deal;
            PickNum++;
        }
    }

    // --- Squad 1: Entry ---
    if (NumSquads > 1 && MemberCounts[1] > 0)
    {
        pe = PrimaryEntry(ZoneIdx);
        if (pe >= 0 && Z.Entries[pe].Inside != None)
            Target = Z.Entries[pe].Inside.Location;
        else if (pe >= 0)
            Target = Z.Entries[pe].Loc;
        else
            Target = Z.Center;

        PickNum = 0;
        for (j = 0; j < MemberCounts[1]; j++)
        {
            BestIdx = -1;
            BestDist = 999999.0;
            for (i = 0; i < NumSpots; i++)
            {
                if (!bTaken[i] && VSize2D(Z.Spots[i].Location - Target) < BestDist)
                {
                    BestDist = VSize2D(Z.Spots[i].Location - Target);
                    BestIdx = i;
                }
            }
            if (BestIdx == -1)
            {
                BestIdx = 0;
                BestDist = VSize2D(Z.Spots[0].Location - Target);
                for (i = 1; i < NumSpots; i++)
                {
                    if (VSize2D(Z.Spots[i].Location - Target) < BestDist)
                    {
                        BestDist = VSize2D(Z.Spots[i].Location - Target);
                        BestIdx = i;
                    }
                }
                Deal = Result[1];
                Deal.Shortage++;
                Result[1] = Deal;
            }
            else
            {
                bTaken[BestIdx] = true;
            }

            Deal = Result[1];
            if (PickNum == 0)
            {
                Deal.LeaderNav = Z.Spots[BestIdx];
                Deal.LeaderSpot = Z.Spots[BestIdx].Location;
                EntryLeader = Deal.LeaderSpot;
            }
            else
            {
                Deal.FollowerSpots.AddItem(Z.Spots[BestIdx].Location);
            }
            Result[1] = Deal;
            PickNum++;
        }
    }

    // --- Squads 2+: Reserve ---
    for (i = 2; i < NumSquads; i++)
    {
        if (MemberCounts[i] > 0)
        {
            if (bCoreDealt && bEntryDealt)
                ReserveTarget = (CoreLeader + EntryLeader) * 0.5;
            else if (bCoreDealt)
                ReserveTarget = CoreLeader;
            else
                ReserveTarget = Z.Center;
            Target = ReserveTarget;

            PickNum = 0;
            for (j = 0; j < MemberCounts[i]; j++)
            {
                BestIdx = -1;
                BestDist = 999999.0;
                for (k = 0; k < NumSpots; k++)
                {
                    if (!bTaken[k] && VSize2D(Z.Spots[k].Location - Target) < BestDist)
                    {
                        BestDist = VSize2D(Z.Spots[k].Location - Target);
                        BestIdx = k;
                    }
                }
                if (BestIdx == -1)
                {
                    BestIdx = 0;
                    BestDist = VSize2D(Z.Spots[0].Location - Target);
                    for (k = 1; k < NumSpots; k++)
                    {
                        if (VSize2D(Z.Spots[k].Location - Target) < BestDist)
                        {
                            BestDist = VSize2D(Z.Spots[k].Location - Target);
                            BestIdx = k;
                        }
                    }
                    Deal = Result[i];
                    Deal.Shortage++;
                    Result[i] = Deal;
                }
                else
                {
                    bTaken[BestIdx] = true;
                }

                Deal = Result[i];
                if (PickNum == 0)
                {
                    Deal.LeaderNav = Z.Spots[BestIdx];
                    Deal.LeaderSpot = Z.Spots[BestIdx].Location;
                }
                else
                {
                    Deal.FollowerSpots.AddItem(Z.Spots[BestIdx].Location);
                }
                Result[i] = Deal;
                PickNum++;
            }
        }
    }

    return Result;
}

final function array<int> CandidateZones(vector Ref, float MinD, float MaxD, array<int> Exclude)
{
    local array<int> Result;
    local int i, j;
    local ZoneRec Z;
    local bool bExcluded;
    local float D;

    for (i = 0; i < Zones.Length; i++)
    {
        Z = Zones[i];
        if (!Z.bUsable)
            continue;
        bExcluded = false;
        for (j = 0; j < Exclude.Length; j++)
        {
            if (Exclude[j] == Z.Id)
            {
                bExcluded = true;
                break;
            }
        }
        if (bExcluded)
            continue;
        D = VSize(Z.Center - Ref);
        if (D >= MinD && D <= MaxD)
            Result.AddItem(i);
    }
    return Result;
}

final function int NearestUsable(vector Ref, array<int> Exclude)
{
    local int i, j;
    local ZoneRec Z;
    local bool bExcluded;
    local float D;
    local int BestIdx;
    local float BestDist;

    BestIdx = -1;
    BestDist = 999999999.0;
    for (i = 0; i < Zones.Length; i++)
    {
        Z = Zones[i];
        if (!Z.bUsable)
            continue;
        bExcluded = false;
        for (j = 0; j < Exclude.Length; j++)
        {
            if (Exclude[j] == Z.Id)
            {
                bExcluded = true;
                break;
            }
        }
        if (bExcluded)
            continue;
        D = VSize(Z.Center - Ref);
        if (D < BestDist)
        {
            BestDist = D;
            BestIdx = i;
        }
    }
    return BestIdx;
}
