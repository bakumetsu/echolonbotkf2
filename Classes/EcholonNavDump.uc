// EcholonNavDump.uc - Package EcholonBot
// Dumps the map's NavigationPoint network to the log one frame at a time.
// Driven by EcholonMut.Tick calling Step() while bActive is true.
// LOGGING ONLY; off unless bNavTrace config flag is set on the mutator.

class EcholonNavDump extends Object transient;

var EcholonMut Mut;
var array<NavigationPoint> Nodes;
var int NodeIdx;
var int SpecIdx;
var int Phase;
var bool bActive;
var bool bDone;
var int NodeCount;
var int LinkCount;
var int Sum;
var int Frames;
var float StartTime;

const PH_NODES  = 0;
const PH_LINKS  = 1;
const PH_DONE   = 2;
const PER_FRAME = 120;

// Initialises the dump: collects all NavigationPoints on the map and resets state.
final function Begin(EcholonMut M, float Now)
{
	local NavigationPoint N;

	Mut = M;
	Nodes.Length = 0;
	foreach M.WorldInfo.AllActors(class'NavigationPoint', N)
	{
		Nodes.AddItem(N);
	}
	NodeIdx = 0;
	SpecIdx = 0;
	Phase = PH_NODES;
	NodeCount = 0;
	LinkCount = 0;
	Sum = 0;
	Frames = 0;
	bDone = false;
	bActive = true;
	StartTime = Now;
	M.EchelonLog("NAVDUMP_START map=" $ M.WorldInfo.GetMapName() $ " nodes=" $ string(Nodes.Length));
}

// Called once per frame from the mutator's Tick. Processes up to PER_FRAME items.
// Returns bDone so the caller knows when to stop calling.
final function bool Step()
{
	local int Items;
	local NavigationPoint N;
	local ReachSpec Spec;

	Frames++;
	Items = 0;

	if (Phase == PH_NODES)
	{
		while (NodeIdx < Nodes.Length && Items < PER_FRAME)
		{
			N = Nodes[NodeIdx];
			if (N != None)
			{
				Mut.EchelonLog(NodeLine(N));
				NodeCount++;
				Sum = (Sum + Abs(int(N.Location.X)) + Abs(int(N.Location.Y)) * 3 + Abs(int(N.Location.Z)) * 7) % 16777213;
				Items++;
			}
			NodeIdx++;
		}
		if (NodeIdx >= Nodes.Length)
		{
			Phase = PH_LINKS;
			NodeIdx = 0;
			SpecIdx = 0;
		}
	}
	else if (Phase == PH_LINKS)
	{
		while (NodeIdx < Nodes.Length && Items < PER_FRAME)
		{
			N = Nodes[NodeIdx];
			if (N == None)
			{
				NodeIdx++;
				SpecIdx = 0;
			}
			else if (N.PathList.Length == 0)
			{
				NodeIdx++;
				SpecIdx = 0;
			}
			else
			{
				Spec = N.PathList[SpecIdx];
				if (Spec != None)
				{
					Mut.EchelonLog(LinkLine(N, Spec));
					LinkCount++;
				}
				Items++;
				SpecIdx++;
				if (SpecIdx >= N.PathList.Length)
				{
					NodeIdx++;
					SpecIdx = 0;
				}
			}
		}
		if (NodeIdx >= Nodes.Length)
		{
			Phase = PH_DONE;
		}
	}
	else
	{
		Mut.EchelonLog("NAVDUMP_DONE nodes=" $ string(NodeCount) $ " links=" $ string(LinkCount) $ " sum=" $ string(Sum) $ " frames=" $ string(Frames) $ " secs=" $ string(int(Mut.WorldInfo.TimeSeconds - StartTime + 0.5)));
		bActive = false;
		bDone = true;
	}

	return bDone;
}

// Builds the per-node log line (radius and height come from the node's cylinder; 0 if it has none).
final function string NodeLine(NavigationPoint N)
{
	local int R;
	local int H;

	R = 0;
	H = 0;
	if (N.CylinderComponent != None)
	{
		R = int(N.CylinderComponent.CollisionRadius);
		H = int(N.CylinderComponent.CollisionHeight);
	}
	return "NAVDUMP_NODE name=" $ string(N) $ " class=" $ string(N.Class.Name) $ " at=" $ string(int(N.Location.X)) $ "," $ string(int(N.Location.Y)) $ "," $ string(int(N.Location.Z)) $ " r=" $ string(R) $ " h=" $ string(H) $ " flags=" $ NodeFlags(N);
}

// One letter per applicable flag; "-" if none.
final function string NodeFlags(NavigationPoint N)
{
	local string S;

	S = "";
	if (N.IsA('DoorMarker'))   S = S $ "D";
	if (N.IsA('Ladder'))       S = S $ "L";
	if (N.IsA('UDKJumpPad'))   S = S $ "J";
	if (N.IsA('PickupFactory'))S = S $ "P";
	if (N.IsA('PlayerStart'))  S = S $ "S";
	if (N.bBlocked)            S = S $ "B";
	if (N.bOneWayPath)         S = S $ "O";
	if (N.bWallNode)           S = S $ "W";
	if (S == "")
		S = "-";
	return S;
}

// Builds the per-link log line.
final function string LinkLine(NavigationPoint From, ReachSpec Spec)
{
	local string ToStr;

	if (Spec.GetEnd() == None)
		ToStr = "none";
	else
		ToStr = string(Spec.GetEnd());

	return "NAVDUMP_LINK from=" $ string(From) $ " to=" $ ToStr $ " reach=" $ string(Spec.reachFlags) $ " r=" $ string(Spec.CollisionRadius) $ " h=" $ string(Spec.CollisionHeight) $ " d=" $ string(Spec.Distance) $ " spec=" $ string(Spec.Class.Name);
}
