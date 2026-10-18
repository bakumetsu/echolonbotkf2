class EcholonBotLogic extends EcholonBotBase hidecategories(Navigation);

final function bool CheckShouldHealMate()
{
    local KFWeap_HealerBase W;
    local KFPawn_Human P, Best;
    local float Pct, DHoriz, DVert;
    local float EffectivePct, BestEffectivePct;

    if (mut == None)
    {
        return false;
    }
    if (KPawn == None || !KPawn.IsAliveAndWell())
    {
        return false;
    }

    if (WorldInfo.TimeSeconds < HealRetryAfter)
    {
        return false;
    }

    if (KFGRI == None || !KFGRI.bTraderIsOpen)
    {
        return false;
    }

    MedicGun = None;
    foreach KFInvManager.InventoryActors(Class'KFWeap_HealerBase', W)
    {
        if (W.HasAmmo(0))
        {
            MedicGun = W;
            break;
        }
    }
    if (MedicGun == None)
    {
        return false;
    }

    Best = None;
    BestEffectivePct = 0.0;
    foreach WorldInfo.AllPawns(Class'KFPawn_Human', P, Pawn.Location, mut.HealCylinderRadius)
    {
        if (P == Pawn)
        {
            continue;
        }
        if (!P.IsAliveAndWell())
        {
            continue;
        }
        if (P.GetTeamNum() != GetTeamNum())
        {
            continue;
        }
        Pct = (float(P.Health) / float(P.HealthMax)) * 100.0;
        if (Pct > HEAL_MAX_NEED_PCT)
        {
            continue;
        }
        if (!TargetLowHealth(P))
        {
            continue;
        }
        DHoriz = VSize(P.Location - Pawn.Location);
        DVert = Abs(P.Location.Z - Pawn.Location.Z);
        if (DHoriz > mut.HealCylinderRadius)
        {
            continue;
        }
        if (DVert > mut.HealCylinderHeight)
        {
            continue;
        }
        if (!ActorReachable(P))
        {
            continue;
        }
        if (mut.bEnableFastTraceHealing && !FastTrace(Pawn.Location, P.Location))
        {
            continue;
        }

        EffectivePct = Pct;
        if ((mut.VIPController != None) && (P == mut.VIPController.Pawn) && (Pct < VIP_TRIAGE_GATE_PCT))
        {
            EffectivePct = FMax(Pct - VIP_TRIAGE_BONUS_PCT, 0.0);
        }

        if ((Best == None) || (EffectivePct < BestEffectivePct))
        {
            Best = P;
            BestEffectivePct = EffectivePct;
        }
    }

    PendingHeal = Best;
    return Best != None;
}

final function bool CheckMedicGunHeal()
{
    local KFPawn_Human P, Best;
    local float Pct, EffectivePct, BestEffectivePct;

    if (mut == None)
    {
        return false;
    }
    if (KPawn == None || !KPawn.IsAliveAndWell())
    {
        return false;
    }

    if (WorldInfo.TimeSeconds < HealRetryAfter)
    {
        return false;
    }

    RangeMedicGun = KFWeap_MedicBase(Pawn.Weapon);
    if (RangeMedicGun == None)
    {
        return false;
    }
    if (!RangeMedicGun.HasAmmo(1))
    {
        return false;
    }

    Best = None;
    BestEffectivePct = 0.0;

    foreach WorldInfo.AllPawns(class'KFPawn_Human', P, Pawn.Location, 1800.0)
    {
        if (P == Pawn)
        {
            continue;
        }
        if (!P.IsAliveAndWell())
        {
            continue;
        }
        if (P.GetTeamNum() != GetTeamNum())
        {
            continue;
        }
        if (mut.IsRangedHealTargetOnCooldown(P))
        {
            continue;
        }
        Pct = (float(P.Health) / float(P.HealthMax)) * 100.0;
        if (Pct > HEAL_MAX_NEED_PCT)
        {
            continue;
        }
        if (!TargetLowHealth(P))
        {
            continue;
        }
        if (mut.bEnableFastTraceHealing && !FastTrace(Pawn.Location, P.Location))
        {
            continue;
        }

        EffectivePct = Pct;
        if (mut.VIPController != None && P == mut.VIPController.Pawn && Pct < VIP_TRIAGE_GATE_PCT)
        {
            EffectivePct = FMax(Pct - VIP_TRIAGE_BONUS_PCT, 0.0);
        }

        if (Best == None || EffectivePct < BestEffectivePct)
        {
            Best = P;
            BestEffectivePct = EffectivePct;
        }
    }

    PendingHeal = Best;
    return Best != None;
}

final function bool CheckShouldSelfHeal()
{
    local KFWeap_HealerBase W;

    if (mut == None)
    {
        return false;
    }
    if (KPawn == None || !KPawn.IsAliveAndWell())
    {
        return false;
    }

    // Failure backoff: a failed heal stamps HealRetryAfter, so a failing heal can't livelock.
    if (WorldInfo.TimeSeconds < HealRetryAfter)
    {
        return false;
    }

    // Primary threshold: self-heal at HEAL_MAX_NEED_PCT health or below.
    if (KPawn.Health >= (HEAL_MAX_NEED_PCT / 100.0) * KPawn.HealthMax)
    {
        return false;
    }

    // Mechanical recharge: no heal at all until the syringe has recharged.
    if (WorldInfo.TimeSeconds < SyringeRechargeEnd)
    {
        return false;
    }

    // Behavioural pacing: skip chip-damage heals, except below 50% health or while the trader is open.
    if (WorldInfo.TimeSeconds < HealPacingEnd && !(KFGRI != None && KFGRI.bTraderIsOpen))
    {
        if (KPawn.Health >= 0.50 * KPawn.HealthMax)
        {
            return false;
        }
    }

    MedicGun = None;
    if (KFInvManager != None)
    {
        foreach KFInvManager.InventoryActors(class'KFWeap_HealerBase', W)
        {
            if (W.HasAmmo(0))
            {
                MedicGun = W;
                break;
            }
        }
    }
    return MedicGun != None;
}


final function bool ShouldNadeEnemies()
{
    local KFPawn_Monster M, B, Best;
    local byte T;
    local float Score, BestScore;

    T = GetTeamNum();
    BestScore = 0.0;

    foreach WorldInfo.AllPawns(class'KFPawn_Monster', M, Pawn.Location, 1400.0)
    {
        if ((!M.IsAliveAndWell() || !FastTrace(M.Location, Pawn.Location)) || M.GetTeamNum() == T)
        {
            continue;
        }
        Score = FClamp(float(M.Health) / 5.0, 50.0, 150.0);
        foreach WorldInfo.AllPawns(class'KFPawn_Monster', B, M.Location, 600.0)
        {
            if (((B == M) || !B.IsAliveAndWell() || !FastTrace(B.Location, M.Location)) || B.GetTeamNum() == T)
            {
                continue;
            }
            Score += FClamp(float(B.Health) / 7.0, 50.0, 150.0);
        }
        if ((Score > 300.0 && Best == None) || Score > BestScore)
        {
            Best = M;
            BestScore = Score;
        }
    }

    if (Best == None)
    {
        return false;
    }
    Target = Best;
    return true;
}

function CheckGrabbed()
{
    if ( (KPawn != None && KPawn.Health > 0 && KPawn.IsDoingSpecialMove(31)) && KPawn.InteractionPawn != None )
    {
        GotoState('BreakLose');
        return;
    }
    if (BotRank == GRUNT)
    {
        UpdateGruntOffset();
    }
}

function UpdateGruntOffset()
{
    local vector GruntTarget;
    local vector OverwatchMoveTarget;
    local float sc;
    local vector bOff;
    local Controller VIP;

    if (((KPawn != None) && KPawn.Health > 0) && KPawn.IsDoingSpecialMove(31) && KPawn.InteractionPawn != None)
    {
        GotoState('BreakLose');
        return;
    }

    ApplyPanicVariance();
    TrackReloadState();

    if (SyncLineFocus())
    {
        return;
    }

    ApplySquadCrouchHold();

    if (SquadLeader == None || SquadLeader.Pawn == None || SquadLeader.Pawn.Health <= 0)
    {
        if (LastValidSquadLeaderPos != vect(0, 0, 0))
        {
            MoveToX(LastValidSquadLeaderPos);
        }
        else
        {
            VIP = None;
            if (mut != None)
            {
                VIP = mut.GetVIPController();
            }
            if (VIP != None && VIP.Pawn != None && VIP.Pawn.Health > 0)
            {
                MoveToX(VIP.Pawn.Location);
            }
        }
        if (!bPromotionGapTimerActive)
        {
            bPromotionGapTimerActive = true;
            SetTimer(10.0, false, 'PromotionGapTimer');
        }
        return;
    }

    LastValidSLTime = WorldInfo.TimeSeconds;

    if (bPromotionGapTimerActive)
    {
        bPromotionGapTimerActive = false;
        ClearTimer('PromotionGapTimer');
    }

    if (bOverwatchMoving)
    {
        if (UpdateOverwatchMovement(OverwatchMoveTarget))
        {
            MoveToX(OverwatchMoveTarget);
        }
        return;
    }

    if (CurrentOrder == 'CMD_HoldArea' && Enemy == None)
    {
        UpdateSectorWatch();
        return;
    }

    HandleCQBProximity();

    if (RescueUntil > WorldInfo.TimeSeconds)
    {
        MoveToX(RescueLoc);
        return;
    }

    UpdateCoverCrouch();

    if (bReloadDriftMove && ReloadDriftUntil > WorldInfo.TimeSeconds)
    {
        MoveToX(ReloadDriftLoc);
        return;
    }

    if (SquadLeader != None && SquadLeader.bWedgeActive)
    {
        GruntTarget = SquadLeader.Pawn.Location;
        ApplyWedgeTarget(GruntTarget);
        GruntTarget = ApplyZStep(GruntTarget);
        MoveToX(GruntTarget);
        return;
    }

    GruntTarget = SquadLeader.Pawn.Location + ComputeSlotOffset();

    sc = PanicVarianceMultiplier / GetWaveMomentum();
    GruntTarget.X = SquadLeader.Pawn.Location.X + (GruntTarget.X - SquadLeader.Pawn.Location.X) * sc;
    GruntTarget.Y = SquadLeader.Pawn.Location.Y + (GruntTarget.Y - SquadLeader.Pawn.Location.Y) * sc;

    bOff.X = Sin(BreathingPhase) * 10.0;
    bOff.Y = Cos(BreathingPhase) * 10.0;
    GruntTarget = GruntTarget + bOff;

    GruntTarget = ApplyZStep(GruntTarget);

    if (!ValidateOffsetTarget(GruntTarget))
    {
        GruntTarget = SquadLeader.Pawn.Location;
    }

    MoveToX(GruntTarget);
}

function vector ApplyZStep(vector T)
{
    local float DZ;
    DZ = T.Z - Pawn.Location.Z;
    if (Abs(DZ) > 300.0)
    {
        T.Z = Pawn.Location.Z;
        return T;
    }
    if (Abs(DZ) > 200.0)
    {
        if (DZ > 0.0)
        {
            T.Z += 50.0;
        }
        else
        {
            T.Z -= 50.0;
        }
    }
    if (Abs(T.Z - Pawn.Location.Z) <= 50.0)
    {
        T.Z = Pawn.Location.Z;
    }
    return T;
}

function RequestReroute()
{
    LastValidSquadLeaderPos = SquadLeader.Pawn.Location;
}

function PromotionGapTimer()
{
    bPromotionGapTimerActive = false;
    if (BotRank == GRUNT && (SquadLeader == None || SquadLeader.Pawn == None || SquadLeader.Pawn.Health <= 0))
    {
        SetBotRank(SQUAD_LEADER);
        PickCombatStyle();
    }
}

function bool CanAffordHeal(int Type)
{
    if (Type == 0)
    {
        return (MedicGun != None) && (MedicGun.AmmoCount[0] >= 100.0);
    }
    return (RangeMedicGun != None) && (RangeMedicGun.AmmoCount[1] >= 50.0);
}

function HealFail()
{
    FailStreak++;
    HealRetryAfter = WorldInfo.TimeSeconds + FMin(4.0 * FailStreak, 20.0);
    PendingHeal = None;
}

function HealSuccess()
{
    FailStreak = 0;
    SyringeRechargeEnd = WorldInfo.TimeSeconds + 15.0;
    HealPacingEnd = WorldInfo.TimeSeconds + (20.0 + FRand() * 10.0);
}

function VerifyWeapon()
{
    if (Pawn == None)
    {
        return;
    }
    if (GetStateName() == 'HealingSelf' || GetStateName() == 'HealOther' || GetStateName() == 'HealRanged')
    {
        return;
    }
    if (KFWeap_HealerBase(Pawn.Weapon) != None)
    {
        Pawn.InvManager.SwitchToBestWeapon(true);
    }
}

function HealTimeOut()
{
    PickCombatStyle();
}

function bool ConsumePathToken()
{
    if (WorldInfo.TimeSeconds > PathTokenResetTime)
    {
        PathTokensUsed = 0;
        PathTokenResetTime = WorldInfo.TimeSeconds + 1.0;
    }
    if (PathTokensUsed >= 10)
    {
        return false;
    }
    PathTokensUsed++;
    return true;
}

function GruntDecisionTimer()
{
    local KFPawn_Monster M;
    local float BestDist;
    local float D;

    if (BotRank != GRUNT)
    {
        return;
    }
    if (Pawn == None || KPawn == None || !KPawn.IsAliveAndWell())
    {
        return;
    }

    BestDist = 800.0;
    foreach VisibleCollidingActors(class'KFPawn_Monster', M, 800.0, Pawn.Location)
    {
        if (M.IsAliveAndWell())
        {
            D = VSize(M.Location - Pawn.Location);
            if (D < BestDist)
            {
                BestDist = D;
            }
        }
    }

    if (BestDist < 800.0)
    {
        if (!bEngageActive)
        {
            bEngageActive = true;
            EchelonLog("GruntDecisionTimer: bEngageActive=true (enemy at " $ string(int(BestDist)) $ "u)");
        }
    }
    else
    {
        bEngageActive = false;
    }
}

function IdleWatchdogTimer()
{
    SetTimer(AUDIT_WD_PERIOD, false, 'IdleWatchdogTimer');
    IdleWatchdog();
}

function IdleWatchdog()
{
    local float IterNow;
    local float IterSinceIntent;
    local float IterSinceHub;
    local float IterStuckDelta;
    local float IterGoalD2;
    local name IterState;
    local bool bLegitState;
    local bool bNotIdle;
    local bool bStuck;
    local bool bProgressing;
    local bool bAttached;
    local NavigationPoint IterGoalN;
    local Controller IterAttachCtrl;
    local EcholonBot IterAttachBot;

    if (Pawn == None || KPawn == None || !KPawn.IsAliveAndWell())
    {
        return;
    }

    IterNow = WorldInfo.TimeSeconds;
    IterSinceIntent = IterNow - WdLastMoveIntentTime;
    IterSinceHub = IterNow - WdLastHubContactTime;
    IterState = GetStateName();

    bLegitState = (IterState == 'HealingSelf' || IterState == 'HealOther' ||
        IterState == 'HealRanged' || IterState == 'BreakLose' ||
        IterState == 'VictoryDance' || IterState == 'Camp' ||
        IterState == 'GoShopping' || IterState == 'FollowingLeader' ||
        IterState == 'FollowingLeaderBasic' || IterState == 'DoObjective' ||
        IterState == 'Hunting');

    if (!bLegitState && IterState == 'FightEnemy' && Enemy != None && Enemy.Health > 0)
    {
        bLegitState = true;
    }

    bNotIdle = !bLegitState && (IterSinceIntent > AUDIT_INTENT_TIMEOUT && IterSinceHub > AUDIT_HUB_TIMEOUT);

    if (!bNotIdle)
    {
        bWdEscalating = false;
        WdEscStep = 1;
        WdLastStepTime = 0.0;
        WdProgressGoalD2 = 0.0;
        return;
    }

    if (!bWdEscalating)
    {
        bWdEscalating = true;
        WdEscStep = 1;
        WdLastStepTime = 0.0;
        WdProgressGoalD2 = 0.0;
        WdIdleStartLoc = Pawn.Location;
        EchelonLog("WD_IDLE bot=" $ Name $ " state=" $ IterState $ " intentAge=" $ string(IterSinceIntent) $ " hubAge=" $ string(IterSinceHub));
        return;
    }

    IterStuckDelta = VSize(Pawn.Location - WdIdleStartLoc);
    bStuck = (IterStuckDelta < AUDIT_IDLE_STUCK_DELTA);

    IterGoalN = None;
    if (mut != None)
    {
        IterGoalN = mut.GetBotObjective(EcholonBot(self));
    }

    if (IterGoalN != None)
    {
        IterGoalD2 = VSizeSq(Pawn.Location - IterGoalN.Location);
        if (WdProgressGoalD2 == 0.0 || IterGoalD2 < WdProgressGoalD2)
        {
            bProgressing = true;
            WdProgressGoalD2 = IterGoalD2;
        }
        else
        {
            bProgressing = false;
        }
    }
    else
    {
        bProgressing = !bStuck;
    }

    if (!bStuck && bProgressing)
    {
        bWdEscalating = false;
        WdEscStep = 1;
        WdLastStepTime = 0.0;
        WdProgressGoalD2 = 0.0;
        return;
    }

    if (IterNow - WdLastStepTime < AUDIT_WD_STEP_COOLDOWN)
    {
        return;
    }

    WdLastStepTime = IterNow;

    if (WdEscStep == 1)
    {
        if (mut != None && mut.HasSquadGoal(EcholonBot(self)))
        {
            mut.ReissueSquadOrder(EcholonBot(self));
            EchelonLog("WD_FIRE bot=" $ Name $ " step=1 reissue state=" $ IterState $ " delta=" $ string(IterStuckDelta));
            WdEscStep++;
        }
        else
        {
            WdEscStep = 2;
        }
    }
    else if (WdEscStep == 2)
    {
        bAttached = false;
        if (SquadLeader == None || SquadLeader.Pawn == None || SquadLeader.Pawn.Health <= 0)
        {
            IterAttachCtrl = None;
            if (mut != None)
            {
                IterAttachCtrl = mut.FindNearestActiveLeader(EcholonBot(self), AUDIT_ATTACH_RADIUS);
            }
            if (IterAttachCtrl != None)
            {
                IterAttachBot = EcholonBot(IterAttachCtrl);
                if (IterAttachBot != None)
                {
                    mut.ReassignBotToGroup(EcholonBot(self), IterAttachBot.GroupID - 1);
                }
                EchelonLog("WD_FIRE bot=" $ Name $ " step=2 attach leader=" $ string(IterAttachCtrl.Name));
                FollowStart(IterAttachCtrl);
                bWdEscalating = false;
                WdEscStep = 1;
                WdLastStepTime = 0.0;
                WdProgressGoalD2 = 0.0;
                bAttached = true;
            }
        }
        if (!bAttached)
        {
            WdEscStep = 3;
        }
    }
    else
    {
        EchelonLog("WD_FIRE bot=" $ Name $ " step=3 fresh-pick state=" $ IterState $ " delta=" $ string(IterStuckDelta));
        GotoState('PickNextMove');
        bWdEscalating = false;
        WdEscStep = 1;
        WdLastStepTime = 0.0;
        WdProgressGoalD2 = 0.0;
    }
}

function ProcessOverwatchPhase()
{
    local string PhaseStr;

    if (BotRank != CAPTAIN)
        return;

    if (WorldInfo.TimeSeconds > EngageExpireTime)
    {
        bOverwatchPhase = !bOverwatchPhase;
        EngageExpireTime = WorldInfo.TimeSeconds + 5.0;

        if (bOverwatchPhase)
            PhaseStr = "HOLD";
        else
            PhaseStr = "ADVANCE";

        EchelonLog("Overwatch phase toggled: " $ PhaseStr);
    }
}

function bool FollowCheckExit()
{
    local int IterDistSq;

    if (KFGRI != None
        && KFGRI.bTraderIsOpen
        && KFGRI.OpenedTrader != None
        && NextShoppingTime < WorldInfo.TimeSeconds)
    {
        FollowExitState = 'GoShopping';
        bFollowExitPending = true;
        EchelonLog("FOLLOWGATE_EVAL bot=" $ Name $ " slot=" $ string(FollowSlotIndex) $ " result=GoShopping");
        WdLastHubContactTime = WorldInfo.TimeSeconds;
        return true;
    }

    if (mut != None
        && mut.bObjectiveActive
        && ObjectiveGoal != None)
    {
        IterDistSq = VSizeSq(ObjectiveGoal.Location - Pawn.Location);
        if (IterDistSq > SYG_DISTANCE_SQ
            && WorldInfo.TimeSeconds >= ObjectiveBailUntil)
        {
            FollowExitState = 'DoObjective';
            bFollowExitPending = true;
            EchelonLog("FOLLOWGATE_EVAL bot=" $ Name $ " slot=" $ string(FollowSlotIndex) $ " result=DoObjective distSq=" $ string(IterDistSq));
            WdLastHubContactTime = WorldInfo.TimeSeconds;
            return true;
        }
    }
    return false;
}

function PawnDied(Pawn inPawn)
{
    local int Idx;

    if (inPawn != Pawn)
    {
        return;
    }

    ActivatePlayerDiedSequenceEvents();
    TriggerEventClass(Class'Engine.SeqEvent_Death', self);

    Idx = 0;
    while (Idx < LatentActions.Length)
    {
        if (LatentActions[Idx] != None)
        {
            LatentActions[Idx].AbortFor(self);
        }
        Idx++;
    }
    LatentActions.Length = 0;

    if (Pawn != None)
    {
        SetLocation(Pawn.Location);
        Pawn.UnPossessed();
    }
    Pawn = None;

    ClearRankTimers();
    GotoState('Dead');
}

final function ActivatePlayerDiedSequenceEvents()
{
    local Sequence GameSeq;
    local array<SequenceObject> AllSeqEvents;
    local array<int> ActivateIndices;
    local int I;
    local KFGameInfo KFGI;

    KFGI = KFGameInfo(WorldInfo.Game);
    GameSeq = WorldInfo.GetGameSequence();

    if ((GameSeq != None) && (KFGI != None))
    {
        GameSeq.FindSeqObjectsByClass(Class'KFGame.KFSeqEvent_PlayerDied', true, AllSeqEvents);

        if (KFGI.GetLivingPlayerCount() > 0)
        {
            ActivateIndices[0] = 0;
        }
        else
        {
            ActivateIndices[0] = 1;
        }

        for (I = 0; I < AllSeqEvents.Length; I++)
        {
            KFSeqEvent_PlayerDied(AllSeqEvents[I]).CheckActivate(WorldInfo, None, false, ActivateIndices);
        }
    }
}

final function PickRetreatMove()
{
    local NavigationPoint N, Best;
    local float Score, BestScore;

    Best = None;
    BestScore = 0.0;

    foreach WorldInfo.RadiusNavigationPoints(class'NavigationPoint', N, Pawn.Location, 1200.0)
    {
        if (VSizeSq2D(N.Location - Pawn.Location) < 6400.0)
        {
            continue;
        }

        if (Enemy != None)
        {
            Score = VSizeSq(N.Location - Enemy.Location) - VSizeSq(N.Location - Pawn.Location);
        }
        else
        {
            Score = VSizeSq(N.Location - Pawn.Location);
        }

        Score *= (0.5 + FRand());

        if ((Best == None || BestScore < Score) && ActorReachable(N))
        {
            Best = N;
            BestScore = Score;
        }
    }

    if (Best == None)
    {
        if (Enemy == None)
        {
            MoveToX(Pawn.Location + (VRand() * 400.0));
        }
        else
        {
            MoveToX(((Normal(Pawn.Location - Enemy.Location) * 500.0) + Pawn.Location) + (VRand() * 200.0), Enemy);
        }
    }
    else
    {
        MoveTowardX(Best, Enemy);
    }
}

final function bool FindCollectable()
{
    local KFPickupFactory P;
    local KFPickupFactory_Item I;

    foreach VisibleCollidingActors(class'KFPickupFactory', P, 800.0, Pawn.Location, true)
    {
        if ((P != LastFactory) && !P.bPickupHidden)
        {
            I = KFPickupFactory_Item(P);
            if (I == None)
            {
                if (ActorReachable(P))
                {
                    break;
                }
                continue;
            }
            if ((I.CurrentPickupIsArmor() && (KPawn != None)) && (KPawn.Armor < KPawn.MaxArmor) && ActorReachable(P))
            {
                break;
            }
        }
    }

    if (P != None)
    {
        LastFactory = P;
        return true;
    }
    return false;
}

// @STUB(M5c) @SYS-LOGIC-UTIL legacy:KF2BotLogic.NotifyJumpApex
event NotifyJumpApex()
{
    // PASS-THROUGH: overrides Controller; keep the engine behaviour until the real port lands.
    super.NotifyJumpApex();
}

// @STUB(M5c) @SYS-LOGIC-UTIL legacy:KF2BotLogic.GetAIInfo
function string GetAIInfo()
{
}

// @STUB(M5c) @SYS-LOGIC-DEATH legacy:KF2BotLogic.ReplicatedEvent
simulated event ReplicatedEvent(name VarName)
{
    // PASS-THROUGH: overrides Controller; keep the engine behaviour until the real port lands.
    super.ReplicatedEvent(VarName);
}

// @STUB(M5c) @SYS-LOGIC-DEATH legacy:KF2BotLogic.FinishObjective
function FinishObjective()
{
}

// @STUB(M5c) @SYS-LOGIC-UTIL legacy:KF2BotLogic.GetPointNear
final function Vector GetPointNear(Pawn Other, float MaxDist)
{
}

// @STUB(M5c) @SYS-LOGIC-DEATH legacy:KF2BotLogic.NotifyKilled
function NotifyKilled(Controller Killer, Controller Killed, Pawn KilledPawn, Class<DamageType> damageTyp)
{
    // PASS-THROUGH: overrides Controller; keep the engine behaviour until the real port lands.
    super.NotifyKilled(Killer, Killed, KilledPawn, damageTyp);
}

// @STUB(M5c) @SYS-LOGIC-MOVEVAL legacy:KF2BotLogic.EvaluateSquadTether
function bool EvaluateSquadTether()
{
}

// @STUB(M5c) @SYS-LOGIC-MOVEVAL legacy:KF2BotLogic.IsAnchorValid
function bool IsAnchorValid(Actor Anchor)
{
}

// @STUB(M5c) @SYS-LOGIC-MOVEVAL legacy:KF2BotLogic.EvaluateLeaderMove
function bool EvaluateLeaderMove()
{
}

// @STUB(M5c) @SYS-LOGIC-MOVEVAL legacy:KF2BotLogic.EvaluateFollowerMove
function bool EvaluateFollowerMove()
{
}

// @STUB(M5c) @SYS-LOGIC-MOVEVAL legacy:KF2BotLogic.MoveTowardGoal
function bool MoveTowardGoal(Actor GoalActor, vector GoalPoint, bool bActorGoal)
{
}

// @STUB(M5c) @SYS-LOGIC-MOVEVAL legacy:KF2BotLogic.UpdateCQBFormation
function UpdateCQBFormation()
{
}

// @STUB(M5c) @SYS-LOGIC-MOVEVAL legacy:KF2BotLogic.UpdatePillarOfSaltTracking
function UpdatePillarOfSaltTracking()
{
}

// @STUB(M5c) @SYS-LOGIC-MOVEVAL legacy:KF2BotLogic.ExecuteCampState
function bool ExecuteCampState()
{
}

// @STUB(M5c) @SYS-LOGIC-MOVEVAL legacy:KF2BotLogic.ResetStuckState
function ResetStuckState()
{
}

defaultproperties
{
}
