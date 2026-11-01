class EcholonZedCoord extends Object transient;

const BAND_FAR=0; const BAND_MID=1; const BAND_CLOSE=2; const BAND_MELEE=3;

struct ZedTrack { var Pawn Z; var int Band; var float BeyondSince; var float EnragedUntil; var float D; };
struct NoRetake { var EcholonBot B; var Pawn Z; var float Until; };
struct TeamPlan { var array<ZedTrack> Tracks; var array<EcholonBot> SlotBots; var array<Pawn> SlotZeds; var Pawn LeadZed; var float LeadChangeTime; var Pawn CandLead; var float CandLeadSince; var EcholonBot FreeBot; var float FreeChangeTime; var EcholonBot CasterBot; var Pawn CasterZed; var float CasterChangeTime; var bool bOverwhelmed; var float OverwhelmFalseSince; var array<NoRetake> NoRetakes; var float LastQuotaLog; var int LastN; };

var array<TeamPlan> Teams;
var TeamPlan Cur;
var int CurTeam, CurN, CurBudget;
var float Now;
var EcholonMut Mut;
var array<EcholonBot> Elig;
var array<int> Order;
var array<KFPawn_Monster> ScanBig; var array<KFPawn_Monster> ScanCaster;
var int TickOps, TickCount, TickMaxOps; var float WindowStart;

function Tick(EcholonMut M)
{
    local int i, j, NewLen;
    local KFPawn_Monster Z;
    local float T;
    local bool Found;

    Mut = M;
    Now = M.WorldInfo.TimeSeconds;
    T = Now;
    NewLen = M.Fireteams.Length;

    if (NewLen != Teams.Length)
    {
        Teams.Length = NewLen;
        WindowStart = T;
        TickCount = 0;
        TickMaxOps = 0;
    }

    // Single scan for whole mutator
    ScanBig.Length = 0;
    ScanCaster.Length = 0;
    TickOps = 0;

    for (i = 0; i < NewLen; i++)
    {
        if (M.Fireteams[i].Anchor != None)
        {
            foreach M.WorldInfo.AllPawns(class'KFPawn_Monster', Z, M.Fireteams[i].Anchor.Location, M.ZedScanDist)
            {
                TickOps++;
                Found = false;
                for (j = 0; j < ScanBig.Length; j++)
                    if (ScanBig[j] == Z) { Found = true; break; }
                for (j = 0; j < ScanCaster.Length; j++)
                    if (ScanCaster[j] == Z) { Found = true; break; }
                if (!Found)
                {
                    if (Z.IsA('KFPawn_ZedFleshpound') || Z.IsA('KFPawn_ZedFleshpoundMini') || Z.IsA('KFPawn_ZedScrake'))
                        ScanBig[ScanBig.Length] = Z;
                    else if ((Z.IsA('KFPawn_ZedSiren') || Z.IsA('KFPawn_ZedHusk')) && !Z.bIsHeadless)
                        ScanCaster[ScanCaster.Length] = Z;
                }
            }
        }
    }

    // Early cheap return
    if (ScanBig.Length == 0 && ScanCaster.Length == 0)
    {
        for (i = 0; i < NewLen; i++)
        {
            Teams[i].SlotBots.Length = 0;
            Teams[i].SlotZeds.Length = 0;
            Teams[i].LeadZed = None;
            Teams[i].CandLead = None;
            Teams[i].FreeBot = None;
            Teams[i].CasterBot = None;
            Teams[i].CasterZed = None;
            Teams[i].Tracks.Length = 0;
            Teams[i].NoRetakes.Length = 0;
        }
        TickCount++;
        if (TickOps > TickMaxOps) TickMaxOps = TickOps;
        if (T - WindowStart >= 30.0)
        {
            Mut.EchelonLog("ZED_TICK avg_us=" @ ((TickOps * 3) / 2) @ " max_ops=" @ TickMaxOps @ " ticks=" @ TickCount @ " est=1");
            WindowStart = T;
            TickCount = 0;
            TickMaxOps = 0;
        }
        return;
    }

    // Per-team pass
    for (i = 0; i < NewLen; i++)
    {
        Cur = Teams[i];
        CurTeam = i;
        BuildEligible();
        if (CurN == 0)
        {
            Cur.SlotBots.Length = 0;
            Cur.SlotZeds.Length = 0;
            Cur.FreeBot = None;
            Cur.CasterBot = None;
            Cur.CasterZed = None;
            Cur.Tracks.Length = 0;
            Teams[i] = Cur;
            continue;
        }
        UpdateTracks();
        BuildOrder();
        UpdateLead();
        UpdateOverwhelmed();
        ProcessSlots();
        ProcessFreeAndCaster();
        LogQuota();
        Teams[i] = Cur;
    }

    TickCount++;
    if (TickOps > TickMaxOps) TickMaxOps = TickOps;
    if (T - WindowStart >= 30.0)
    {
        Mut.EchelonLog("ZED_TICK avg_us=" @ ((TickOps * 3) / 2) @ " max_ops=" @ TickMaxOps @ " ticks=" @ TickCount @ " est=1");
        WindowStart = T;
        TickCount = 0;
        TickMaxOps = 0;
    }
}

final function BuildEligible()
{
    local int i, n;
    local EcholonBot B;

    Elig.Length = 0;
    n = 0;
    for (i = 0; i < Mut.Fireteams[CurTeam].Members.Length; i++)
    {
        B = Mut.Fireteams[CurTeam].Members[i];
        if (B != None && B.Pawn != None && B.Pawn.Health > 0 && B.HasUsableRangedWeapon())
        {
            Elig[Elig.Length] = B;
            n++;
        }
    }
    CurN = n;
    if (n >= 3) CurBudget = n - 1;
    else if (n == 2) CurBudget = 1;
    else if (n == 1) CurBudget = 1;
    else CurBudget = 0;
}

final function int QuotaFor(int Band, int N)
{
    local int col;

    if (N <= 3) col = 0;
    else if (N == 4) col = 1;
    else col = 2;

    if (Band == BAND_FAR)
        return 1;
    if (Band == BAND_MID)
    {
        if (col == 0) return 1;
        return 2;
    }
    if (Band == BAND_CLOSE)
    {
        if (col == 0) return 2;
        return 3;
    }
    // BAND_MELEE
    if (col == 0) return 2;
    if (col == 1) return 3;
    return N - 1;
}

final function bool ZedValid(Pawn Z)
{
    return Z != None && !Z.bDeleteMe && Z.IsAliveAndWell();
}

final function int TrackIndex(Pawn Z)
{
    local int i;
    for (i = 0; i < Cur.Tracks.Length; i++)
        if (Cur.Tracks[i].Z == Z) return i;
    return -1;
}

final function UpdateTracks()
{
    local int i, j, ti;
    local float bestD, D, hystBnd;
    local int natBand, curBand;
    local KFPawn_Monster Z;
    local bool bEnraged, bFlesh;
    local array<int> Dead;

    for (i = 0; i < ScanBig.Length; i++)
    {
        Z = ScanBig[i];
        if (!ZedValid(Z)) continue;

        // Distance to nearest eligible bot
        bestD = 999999.0;
        for (j = 0; j < CurN; j++)
        {
            D = VSize(Z.Location - Elig[j].Pawn.Location);
            TickOps++;
            if (D < bestD) bestD = D;
        }

        bEnraged = Z.IsEnraged();
        bFlesh = Z.IsA('KFPawn_ZedFleshpound');

        // Find or create track
        ti = TrackIndex(Z);
        if (ti < 0)
        {
            ti = Cur.Tracks.Length;
            Cur.Tracks[ti].Z = Z;
            Cur.Tracks[ti].Band = BAND_FAR;
            Cur.Tracks[ti].BeyondSince = 0;
            Cur.Tracks[ti].EnragedUntil = 0;
            Cur.Tracks[ti].D = bestD;
        }

        // Enraged latch
        if (bEnraged)
            Cur.Tracks[ti].EnragedUntil = Now + 3.0;

        // Natural band
        if (bFlesh && Cur.Tracks[ti].EnragedUntil > Now && bestD <= 400.0)
            natBand = BAND_MELEE;
        else if (bestD > Mut.ZedBandFar)
            natBand = BAND_FAR;
        else if (bestD > Mut.ZedBandMid)
            natBand = BAND_MID;
        else if (bestD > Mut.ZedBandClose)
            natBand = BAND_CLOSE;
        else
            natBand = BAND_MELEE;

        curBand = Cur.Tracks[ti].Band;

        if (natBand < curBand)
        {
            // Moved closer: immediate
            Cur.Tracks[ti].Band = natBand;
            Cur.Tracks[ti].BeyondSince = 0;
        }
        else if (natBand > curBand)
        {
            // Moved farther: hysteresis, drop one level at a time
            if (curBand == BAND_MELEE) hystBnd = Mut.ZedBandClose;
            else if (curBand == BAND_CLOSE) hystBnd = Mut.ZedBandMid;
            else hystBnd = Mut.ZedBandFar;

            if (bestD > hystBnd)
            {
                if (Cur.Tracks[ti].BeyondSince == 0)
                    Cur.Tracks[ti].BeyondSince = Now;
                else if (Now - Cur.Tracks[ti].BeyondSince >= Mut.ZedQuotaHoldSec)
                {
                    Cur.Tracks[ti].Band = curBand + 1;
                    Cur.Tracks[ti].BeyondSince = 0;
                }
            }
            else
            {
                Cur.Tracks[ti].BeyondSince = 0;
            }
        }

        Cur.Tracks[ti].D = bestD;
    }

    // Remove dead/gone tracks
    Dead.Length = 0;
    for (i = 0; i < Cur.Tracks.Length; i++)
    {
        if (!ZedValid(Cur.Tracks[i].Z))
            Dead[Dead.Length] = i;
    }
    for (i = Dead.Length - 1; i >= 0; i--)
    {
        ti = Dead[i];
        Cur.Tracks.Length = Cur.Tracks.Length - 1;
        if (ti < Cur.Tracks.Length)
            Cur.Tracks[ti] = Cur.Tracks[Cur.Tracks.Length];
    }
}

final function BuildOrder()
{
    local int i, j, n;

    Order.Length = Cur.Tracks.Length;
    n = Order.Length;
    for (i = 0; i < n; i++)
        Order[i] = i;

    // Insertion sort: enraged-latched first, then smaller D
    for (i = 1; i < n; i++)
    {
        j = i;
        while (j > 0)
        {
            if (Cur.Tracks[Order[j]].EnragedUntil > Now && Cur.Tracks[Order[j-1]].EnragedUntil <= Now)
                break;
            if (Cur.Tracks[Order[j]].EnragedUntil <= Now && Cur.Tracks[Order[j-1]].EnragedUntil > Now)
            {
                if (Cur.Tracks[Order[j]].D < Cur.Tracks[Order[j-1]].D)
                {
                    Order[j] = Order[j-1];
                    Order[j-1] = i;
                    break;
                }
            }
            if (Cur.Tracks[Order[j]].D < Cur.Tracks[Order[j-1]].D)
            {
                Order[j] = Order[j-1];
                Order[j-1] = i;
                break;
            }
            j--;
            if (j == 0) break;
        }
    }
}

defaultproperties
{
}

final function UpdateLead()
{
    local int LeadIdx, I, TargetIdx;
    local float LeadD;
    local bool bNeedSwitch, bCandFound, bCandReady;

    LeadIdx = TrackIndex(Cur.LeadZed);
    if (Cur.LeadZed == None || Cur.LeadZed.bDeleteMe || !Cur.LeadZed.IsAliveAndWell() || LeadIdx == -1)
    {
        Cur.CandLead = None;
        Cur.CandLeadSince = 0;
        Cur.LeadZed = None;
        if (Order.Length > 0)
        {
            TargetIdx = Order[0];
            Cur.LeadZed = Cur.Tracks[TargetIdx].Z;
            Cur.LeadChangeTime = Now;
        }
        return;
    }

    LeadD = Cur.Tracks[LeadIdx].D;
    bNeedSwitch = false;
    TargetIdx = -1;

    // (a) another zed enraged-latched, lead not
    if (Cur.Tracks[LeadIdx].EnragedUntil <= Now)
    {
        for (I = 0; I < Order.Length; I++)
        {
            if (Order[I] == LeadIdx)
                continue;
            if (Cur.Tracks[Order[I]].EnragedUntil > Now)
            {
                bNeedSwitch = true;
                TargetIdx = Order[I];
                break;
            }
        }
    }

    // (b) CandLead 100+ uu closer for 1.5 s
    if (!bNeedSwitch)
    {
        bCandFound = false;
        bCandReady = false;
        for (I = 0; I < Order.Length; I++)
        {
            if (Order[I] == LeadIdx)
                continue;
            if (Cur.Tracks[Order[I]].D < LeadD - 100.0)
            {
                bCandFound = true;
                if (Cur.CandLead == Cur.Tracks[Order[I]].Z)
                {
                    if (Now - Cur.CandLeadSince >= 1.5)
                    {
                        bCandReady = true;
                        TargetIdx = Order[I];
                    }
                }
                else
                {
                    Cur.CandLead = Cur.Tracks[Order[I]].Z;
                    Cur.CandLeadSince = Now;
                }
                break;
            }
        }
        if (!bCandFound)
        {
            Cur.CandLead = None;
            Cur.CandLeadSince = 0;
        }
    }
    else
    {
        // (a) already wants switch; no cand bookkeeping needed
    }

    if (bCandReady)
    {
        bNeedSwitch = true;
    }

    // Apply with 3 s cooldown (lead death handled above as immediate)
    if (bNeedSwitch && TargetIdx >= 0 && Now - Cur.LeadChangeTime >= 3.0)
    {
        Cur.LeadZed = Cur.Tracks[TargetIdx].Z;
        Cur.LeadChangeTime = Now;
        Cur.CandLead = None;
        Cur.CandLeadSince = 0;
    }
}

final function UpdateOverwhelmed()
{
    local int I, CloseMeleeCount;
    local bool bNewCond, bEnragedMelee;
    local EcholonBot FTLeader;

    FTLeader = Mut.Fireteams[CurTeam].Leader;
    if (FTLeader != None && FTLeader.IsInState('TacticalRetreat'))
        return;

    bNewCond = false;
    bEnragedMelee = false;
    CloseMeleeCount = 0;

    for (I = 0; I < Cur.Tracks.Length; I++)
    {
        if (Cur.Tracks[I].Band == BAND_CLOSE || Cur.Tracks[I].Band == BAND_MELEE)
        {
            CloseMeleeCount++;
            if (Cur.Tracks[I].EnragedUntil > Now && Cur.Tracks[I].Band == BAND_MELEE)
                bEnragedMelee = true;
        }
    }

    if (CloseMeleeCount >= Mut.ZedOverwhelmCount)
        bNewCond = true;
    if (bEnragedMelee && CloseMeleeCount >= 2)
        bNewCond = true;

    if (bNewCond)
    {
        if (!Cur.bOverwhelmed)
        {
            Cur.bOverwhelmed = true;
            Cur.OverwhelmFalseSince = 0;
            if (FTLeader != None)
                Mut.EchelonLog("ZED_ROLE bot=" @ FTLeader.LogTag() @ " role=release why=overwhelmed state=on team=" @ string(CurTeam));
        }
    }
    else
    {
        if (Cur.bOverwhelmed)
        {
            if (Cur.OverwhelmFalseSince == 0)
                Cur.OverwhelmFalseSince = Now;
            else if (Now - Cur.OverwhelmFalseSince >= 3.0)
            {
                Cur.bOverwhelmed = false;
                Cur.OverwhelmFalseSince = 0;
                if (FTLeader != None)
                    Mut.EchelonLog("ZED_ROLE bot=" @ FTLeader.LogTag() @ " role=release why=overwhelmed state=off team=" @ string(CurTeam));
            }
        }
    }
}

final function ProcessSlots()
{
	local int i, j, k, totalAssigned, remaining, q, band, leadBand;
	local int wanted, assigned, toRelease, toFill, leadWanted, leadAssigned;
	local int emptySlot, bestBotIdx, SeqLen;
	local float bestS, s, d;
	local Pawn Z;
	local EcholonBot B, bestBot;
	local bool bFound, bIsLead, bFocusOK, bInElig, bWasAnchor;
	local array<int> ZedSeq;

	// --- Step A: release invalid slots ---
	for (i = 0; i < Cur.SlotBots.Length; i++)
	{
		B = Cur.SlotBots[i];
		Z = Cur.SlotZeds[i];
		if (B == None || B.Pawn == None || B.Pawn.Health <= 0)
		{
			ReleaseSlot(i, "dead");
		}
		else if (!B.HasUsableRangedWeapon())
		{
			ReleaseSlot(i, "no_ammo");
		}
		else if (Z == None || !Z.IsAliveAndWell() || TrackIndex(Z) < 0)
		{
			ReleaseSlot(i, "dead");
		}
		else
		{
			bInElig = false;
			for (j = 0; j < Elig.Length; j++)
			{
				if (Elig[j] == B) { bInElig = true; break; }
			}
			if (!bInElig)
				ReleaseSlot(i, "team_change");
		}
	}

	// --- Step B: enforce budget cap ---
	totalAssigned = 0;
	for (i = 0; i < Cur.SlotBots.Length; i++)
	{
		if (Cur.SlotBots[i] != None) totalAssigned++;
	}
	while (totalAssigned > CurBudget)
	{
		bFound = false;
		for (i = Cur.SlotBots.Length - 1; i >= 0; i--)
		{
			if (Cur.SlotBots[i] != None)
			{
				ReleaseSlot(i, "budget");
				totalAssigned = totalAssigned - 1;
				bFound = true;
				break;
			}
		}
		if (!bFound) break;
	}

	// --- Step C: per-zed fill / release with focus rule ---
	ZedSeq.Length = 0;
	if (Cur.LeadZed != None && TrackIndex(Cur.LeadZed) >= 0)
	{
		ZedSeq[0] = TrackIndex(Cur.LeadZed);
		SeqLen = 1;
	}
	else
	{
		SeqLen = 0;
	}
	for (i = 0; i < Order.Length; i++)
	{
		bIsLead = false;
		if (SeqLen > 0 && Order[i] == ZedSeq[0])
			bIsLead = true;
		if (!bIsLead)
			ZedSeq[ZedSeq.Length] = Order[i];
	}

	for (i = 0; i < ZedSeq.Length; i++)
	{
		Z = Cur.Tracks[ZedSeq[i]].Z;
		band = Cur.Tracks[ZedSeq[i]].Band;
		q = QuotaFor(band, CurN);
		remaining = CurBudget - totalAssigned;

		// Determine wanted for this zed
		if (i == 0 && Cur.LeadZed != None)
		{
			wanted = q;
			if (wanted > remaining) wanted = remaining;
		}
		else
		{
			wanted = 0;
			if (band >= BAND_CLOSE && Cur.LeadZed != None && TrackIndex(Cur.LeadZed) >= 0)
			{
				leadBand = Cur.Tracks[TrackIndex(Cur.LeadZed)].Band;
				leadWanted = QuotaFor(leadBand, CurN);
				if (leadWanted > CurBudget) leadWanted = CurBudget;
				leadAssigned = CountAssigned(Cur.LeadZed);
				bFocusOK = (leadAssigned >= leadWanted);
				if (bFocusOK)
				{
					wanted = q;
					if (wanted > remaining) wanted = remaining;
				}
			}
		}

		assigned = CountAssigned(Z);

		// Release extras in reverse slot order
		if (assigned > wanted)
		{
			toRelease = assigned - wanted;
			j = 0;
			for (k = Cur.SlotBots.Length - 1; k >= 0 && j < toRelease; k--)
			{
				if (Cur.SlotZeds[k] == Z && Cur.SlotBots[k] != None)
				{
					ReleaseSlot(k, "band_drop");
					totalAssigned = totalAssigned - 1;
					j++;
				}
			}
		}

		// Fill empty slots
		if (assigned < wanted)
		{
			toFill = wanted - assigned;
			remaining = CurBudget - totalAssigned;
			if (toFill > remaining) toFill = remaining;
			for (j = 0; j < toFill; j++)
			{
				bestBot = None;
				bestS = -9999;
				for (k = 0; k < Elig.Length; k++)
				{
					B = Elig[k];
					if (!BotSlotted(B) && !IsRetaken(B, Z))
					{
						s = CandidateScore(B, Z, band);
						if (s > bestS || (s == bestS && string(B.Name) < string(bestBot.Name)))
						{
							bestS = s;
							bestBot = B;
						}
					}
				}
				if (bestBot != None)
				{
					// Find or create an empty slot
					bFound = false;
					for (k = 0; k < Cur.SlotBots.Length; k++)
					{
						if (Cur.SlotBots[k] == None && Cur.SlotZeds[k] == None)
						{
							emptySlot = k;
							bFound = true;
							break;
						}
					}
					if (!bFound)
					{
						emptySlot = Cur.SlotBots.Length;
						Cur.SlotBots[Cur.SlotBots.Length] = None;
						Cur.SlotZeds[Cur.SlotZeds.Length] = None;
					}
					Cur.SlotBots[emptySlot] = bestBot;
					Cur.SlotZeds[emptySlot] = Z;
					totalAssigned++;
					// Role: anchor if first slot for this zed, else slot
					bWasAnchor = (assigned + j == 0);
					if (bWasAnchor)
						LogRole(bestBot, Z, "anchor", "assign");
					else
						LogRole(bestBot, Z, "slot", "assign");
				}
			}
		}
	}
}

final function ReleaseSlot(int SlotIdx, string Why)
{
	local EcholonBot B;
	local Pawn Z;
	local NoRetake NR;

	B = Cur.SlotBots[SlotIdx];
	Z = Cur.SlotZeds[SlotIdx];
	if (B == None) return;
	LogRole(B, Z, "release", Why);
	// Add no-retake entry
	NR.B = B;
	NR.Z = Z;
	NR.Until = Now + Mut.ZedQuotaHoldSec;
	Cur.NoRetakes[Cur.NoRetakes.Length] = NR;
	Cur.SlotBots[SlotIdx] = None;
	Cur.SlotZeds[SlotIdx] = None;
}

final function int CountAssigned(Pawn Z)
{
	local int i, c;
	c = 0;
	for (i = 0; i < Cur.SlotZeds.Length; i++)
	{
		if (Cur.SlotZeds[i] == Z && Cur.SlotBots[i] != None)
			c++;
	}
	return c;
}

final function bool IsRetaken(EcholonBot B, Pawn Z)
{
	local int i;
	for (i = 0; i < Cur.NoRetakes.Length; i++)
	{
		if (Cur.NoRetakes[i].B == B && Cur.NoRetakes[i].Z == Z && Cur.NoRetakes[i].Until > Now)
			return true;
	}
	return false;
}

final function float CandidateScore(EcholonBot B, Pawn Z, int Band)
{
	local float s, d;
	local int hpPct;
	local float rng;

	s = 0;
	hpPct = int(B.Pawn.Health * 100.0 / B.Pawn.HealthMax);
	if (hpPct >= int(Mut.ZedHurtHealthPct))
		s += 100;
	d = VSize(B.Pawn.Location - Z.Location);
	if (d > 250 || Band == BAND_MELEE)
		s += 10;
	if (B != Mut.Fireteams[CurTeam].Leader && (Band == BAND_FAR || Band == BAND_MID))
		s += 10;
	rng = B.GetWeaponEffectiveRangeUU(KFWeapon(B.Pawn.Weapon));
	if (rng >= d)
		s += 5;
	return s;
}

final function LogRole(EcholonBot B, Pawn Z, string Role, string Why)
{
	local int lBand, lDist, lQuota, lRng;
	local string zedName, zid, wepName;

	if (Z != None && TrackIndex(Z) >= 0)
	{
		lBand = Cur.Tracks[TrackIndex(Z)].Band;
		lDist = int(VSize(B.Pawn.Location - Z.Location));
	}
	else
	{
		lBand = 0;
		lDist = 0;
	}
	lQuota = QuotaFor(lBand, CurN);
	if (Z != None)
	{
		zedName = string(Z.Class.Name);
		zid = string(Z.Name);
	}
	else
	{
		zedName = "None";
		zid = "None";
	}
	if (B != None && B.Pawn != None && B.Pawn.Weapon != None)
	{
		wepName = string(B.Pawn.Weapon.Class.Name);
		lRng = int(B.GetWeaponEffectiveRangeUU(KFWeapon(B.Pawn.Weapon)));
	}
	else
	{
		wepName = "None";
		lRng = 0;
	}
	Mut.EchelonLog("ZED_ROLE team=" @ CurTeam @ " bot=" @ B.LogTag() @ " zed=" @ zedName
		@ " zid=" @ zid @ " role=" @ Role @ " band=" @ lBand @ " dist=" @ lDist
		@ " quota=" @ lQuota @ " budget=" @ CurBudget @ " n=" @ CurN @ " why=" @ Why
		@ " wep=" @ wepName @ " rng=" @ lRng);
}

final function bool BotSlotted(EcholonBot B)
{
    local int i;
    for (i = 0; i < Cur.SlotBots.Length; i++)
    {
        if (Cur.SlotBots[i] == B)
            return true;
    }
    return false;
}

final function ProcessFreeAndCaster()
{
    local int i, j, nU;
    local EcholonBot B, BestBot;
    local Pawn Z, BestZed;
    local float Dist, BestDist, ZedMinDist;
    local bool bKeepFree, bKeepCaster, bSlotted;
    local array<EcholonBot> Unslotted;

    // --- Free Bot (only n>=3) ---
    if (CurN >= 3)
    {
        Unslotted.Length = 0;
        for (i = 0; i < Elig.Length; i++)
        {
            B = Elig[i];
            bSlotted = false;
            for (j = 0; j < Cur.SlotBots.Length; j++)
            {
                if (Cur.SlotBots[j] == B)
                {
                    bSlotted = true;
                    break;
                }
            }
            if (!bSlotted)
                Unslotted[Unslotted.Length] = B;
        }

        bKeepFree = false;
        if (Cur.FreeBot != None)
        {
            bKeepFree = (Cur.FreeBot.Pawn != None && Cur.FreeBot.Pawn.Health > 0 && Cur.FreeBot.HasUsableRangedWeapon());
            if (bKeepFree && BotSlotted(Cur.FreeBot))
                bKeepFree = false;
        }

        if (bKeepFree)
        {
            // keep silent
        }
        else if (Now - Cur.FreeChangeTime >= 3.0)
        {
            BestBot = None;
            for (i = 0; i < Unslotted.Length; i++)
            {
                if (Unslotted[i] == Mut.Fireteams[CurTeam].Leader)
                {
                    BestBot = Unslotted[i];
                    break;
                }
            }
            if (BestBot == None && Unslotted.Length > 0)
            {
                BestBot = Unslotted[0];
                nU = Unslotted.Length;
                for (i = 1; i < nU; i++)
                {
                    if (string(Unslotted[i].Name) < string(BestBot.Name))
                        BestBot = Unslotted[i];
                }
            }
            if (BestBot != None)
            {
                Cur.FreeBot = BestBot;
                Cur.FreeChangeTime = Now;
                Mut.EchelonLog("ZED_ROLE team=" $ string(CurTeam) $ " bot=" $ BestBot.LogTag() $ " zed=None zid=None role=free band=-1 dist=-1 quota=-1 budget=" $ string(CurBudget) $ " n=" $ string(CurN) $ " why=assign wep=None rng=-1");
            }
            else
            {
                Cur.FreeBot = None;
                Cur.FreeChangeTime = Now;
            }
        }
        else
        {
            Cur.FreeBot = None;
        }
    }
    else
    {
        Cur.FreeBot = None;
    }

    // --- Caster Duty ---
    Unslotted.Length = 0;
    for (i = 0; i < Elig.Length; i++)
    {
        B = Elig[i];
        bSlotted = false;
        for (j = 0; j < Cur.SlotBots.Length; j++)
        {
            if (Cur.SlotBots[j] == B)
            {
                bSlotted = true;
                break;
            }
        }
        if (!bSlotted)
            Unslotted[Unslotted.Length] = B;
    }

    bKeepCaster = false;
    if (Cur.CasterBot != None && Cur.CasterZed != None)
    {
        bKeepCaster = (Cur.CasterBot.Pawn != None && Cur.CasterBot.Pawn.Health > 0 && Cur.CasterBot.HasUsableRangedWeapon());
        if (bKeepCaster && BotSlotted(Cur.CasterBot))
            bKeepCaster = false;
        if (bKeepCaster && !ZedValid(Cur.CasterZed))
            bKeepCaster = false;
        if (bKeepCaster)
        {
            Dist = VSize(Cur.CasterBot.Pawn.Location - Cur.CasterZed.Location);
            if (Dist > Mut.ZedHunterDist)
                bKeepCaster = false;
        }
    }

    if (!bKeepCaster)
    {
        if (Now - Cur.CasterChangeTime >= 3.0)
        {
            BestZed = None;
            BestDist = 999999.0;
            for (i = 0; i < ScanCaster.Length; i++)
            {
                Z = ScanCaster[i];
                if (Z == None || Z.bDeleteMe || !Z.IsAliveAndWell())
                    continue;
                ZedMinDist = 999999.0;
                for (j = 0; j < Unslotted.Length; j++)
                {
                    B = Unslotted[j];
                    if (B.Pawn == None || B.Pawn.Health <= 0)
                        continue;
                    Dist = VSize(B.Pawn.Location - Z.Location);
                    if (Dist < ZedMinDist)
                        ZedMinDist = Dist;
                }
                if (ZedMinDist <= Mut.ZedHunterDist && ZedMinDist < BestDist)
                {
                    BestDist = ZedMinDist;
                    BestZed = Z;
                }
            }
            if (BestZed != None)
            {
                BestBot = None;
                BestDist = 999999.0;
                for (i = 0; i < Unslotted.Length; i++)
                {
                    B = Unslotted[i];
                    if (B.Pawn == None || B.Pawn.Health <= 0)
                        continue;
                    Dist = VSize(B.Pawn.Location - BestZed.Location);
                    if (Dist < BestDist)
                    {
                        BestDist = Dist;
                        BestBot = B;
                    }
                }
                if (BestBot != None)
                {
                    Cur.CasterBot = BestBot;
                    Cur.CasterZed = BestZed;
                    Cur.CasterChangeTime = Now;
                    Mut.EchelonLog("ZED_ROLE team=" $ string(CurTeam) $ " bot=" $ BestBot.LogTag() $ " zed=" $ BestZed.Class.Name $ " zid=" $ BestZed.Name $ " role=caster band=-1 dist=" $ string(int(BestDist)) $ " quota=-1 budget=" $ string(CurBudget) $ " n=" $ string(CurN) $ " why=assign wep=" $ BestBot.Pawn.Weapon.Class.Name $ " rng=" $ string(int(BestBot.GetWeaponEffectiveRangeUU(KFWeapon(BestBot.Pawn.Weapon)))) $ " los=n/a");
                }
            }
            Cur.CasterChangeTime = Now;
            if (BestBot == None)
            {
                Cur.CasterBot = None;
                Cur.CasterZed = None;
            }
        }
        else
        {
            Cur.CasterBot = None;
            Cur.CasterZed = None;
        }
    }
}

final function LogQuota()
{
    local int i;
    local Pawn Z;
    local int BigCount, TotalAssigned, nWanted, Empty, zQuota, Assigned;
    local string ZedList, LeadStr, FreeStr, CasterStr, OhInt;

    if (Now - Cur.LastQuotaLog < 5.0)
        return;

    BigCount = 0;
    for (i = 0; i < Cur.Tracks.Length; i++)
    {
        Z = Cur.Tracks[i].Z;
        if (Z != None && !Z.bDeleteMe && Z.IsAliveAndWell())
            BigCount++;
    }
    if (BigCount == 0)
        return;

    Cur.LastQuotaLog = Now;

    ZedList = "";
    TotalAssigned = 0;
    nWanted = 0;
    for (i = 0; i < Cur.Tracks.Length; i++)
    {
        Z = Cur.Tracks[i].Z;
        if (Z == None || Z.bDeleteMe || !Z.IsAliveAndWell())
            continue;
        zQuota = QuotaFor(Cur.Tracks[i].Band, CurN);
        Assigned = CountAssigned(Z);
        TotalAssigned = TotalAssigned + Assigned;
        if (zQuota > CurBudget)
            nWanted = nWanted + CurBudget;
        else
            nWanted = nWanted + zQuota;
        if (ZedList != "")
            ZedList = ZedList $ ",";
        ZedList = ZedList $ Z.Class.Name $ ":" $ string(Cur.Tracks[i].Band) $ ":" $ string(zQuota) $ ":" $ string(Assigned);
    }

    Empty = nWanted - TotalAssigned;
    if (Empty < 0)
        Empty = 0;

    if (Cur.LeadZed != None)
        LeadStr = string(Cur.LeadZed.Name);
    else
        LeadStr = "None";
    if (Cur.FreeBot != None)
        FreeStr = Cur.FreeBot.LogTag();
    else
        FreeStr = "None";
    if (Cur.CasterBot != None)
        CasterStr = Cur.CasterBot.LogTag();
    else
        CasterStr = "None";
    if (Cur.bOverwhelmed)
        OhInt = "1";
    else
        OhInt = "0";

    Mut.EchelonLog("ZED_QUOTA team=" $ string(CurTeam) $ " n=" $ string(CurN) $ " budget=" $ string(CurBudget) $ " bigs=" $ string(BigCount) $ " zeds=" $ ZedList $ " assigned=" $ string(TotalAssigned) $ " empty=" $ string(Empty) $ " engaged=0 lead=" $ LeadStr $ " free=" $ FreeStr $ " caster=" $ CasterStr $ " overwhelmed=" $ OhInt);
}

defaultproperties
{
}
