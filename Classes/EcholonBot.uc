class EcholonBot extends EcholonBotLogic hidecategories(Navigation);

// @STUB(M6) @SYS-BOT-HUB legacy:KF2Bot.PickNextMove
state PickNextMove
{
    event BeginState(Name PreviousStateName)
    {
        AuditStateEntry();
        `log("EcholonBot: Entered PickNextMove from " $ PreviousStateName);
    }

    event EndState(name NextStateName)
    {
        AuditStateExit(NextStateName);
    }

    // @STUB(M6) @SYS-BOT-HUB legacy:KF2Bot.PickNextMove.PickMove
    function PickMove()
    {
    }

Begin:
    Stop;
}

// @STUB(M6) @SYS-BOT-MOVE legacy:KF2Bot.Roaming
state Roaming
{
    event BeginState(name PreviousStateName)
    {
        local KFWeapon MW;

        AuditStateEntry();
        AbortMove();

        if (KPawn != None)
        {
            KPawn.SetSprinting(!bIsGroupLeader);

            if (KFGRI != None && KFGRI.bTraderIsOpen && Pawn.Weapon != None && !Pawn.Weapon.bMeleeWeapon)
            {
                foreach Pawn.InvManager.InventoryActors(class'KFWeapon', MW)
                {
                    if (MW != None && MW.bMeleeWeapon)
                    {
                        Pawn.InvManager.SetCurrentWeapon(MW);
                        break;
                    }
                }
            }
        }
    }

    event EndState(name NextStateName)
    {
        AuditStateExit(NextStateName);

        if (KPawn != None)
        {
            KPawn.SetSprinting(false);
        }
    }

    function PickStyle()
    {
        local EcholonBot GroupLeader;

        if (PlayStyle == 0 && KPawn != None)
        {
            if (mut != None)
            {
                GroupLeader = mut.GetGroupLeader(GroupID);
            }
            else
            {
                GroupLeader = None;
            }

            if (!bIsGroupLeader && GroupLeader != None && GroupLeader.Pawn != None)
            {
                if (VSizeSq(GroupLeader.Pawn.Location - Pawn.Location) > 360000.0)
                {
                    if (ActorReachable(GroupLeader.Pawn))
                    {
                        MoveToX(GetPointNear(GroupLeader.Pawn, 600.0));
                        return;
                    }
                    if (BuildPathToward(GroupLeader.Pawn))
                    {
                        MoveTowardX(MoveTarget);
                        return;
                    }
                }
                else
                {
                    if (Rand(3) == 0)
                    {
                        MoveToX(GetPointNear(GroupLeader.Pawn, 600.0));
                    }
                    else
                    {
                        Focus = None;
                        SetFocalPoint(Pawn.Location + (VRand() * 1000.0));
                    }
                    return;
                }
            }
        }
        else
        {
            if (FollowingHuman != None)
            {
                if (!FollowingHuman.IsAliveAndWell())
                {
                    FollowingHuman = None;
                }
                else
                {
                    if (VSizeSq(FollowingHuman.Location - Pawn.Location) > 360000.0)
                    {
                        if (ActorReachable(FollowingHuman))
                        {
                            MoveToX(GetPointNear(FollowingHuman, 600.0));
                            return;
                        }
                        if (BuildPathToward(FollowingHuman))
                        {
                            MoveTowardX(MoveTarget);
                            return;
                        }
                    }
                    else
                    {
                        if (Rand(3) == 0)
                        {
                            MoveToX(GetPointNear(FollowingHuman, 600.0));
                        }
                        else
                        {
                            Focus = None;
                            SetFocalPoint(Pawn.Location + (VRand() * 1000.0));
                        }
                        return;
                    }
                }
            }
        }

        if (RandGoal == None && !BuildRandomPath())
        {
            MoveToX(Pawn.Location + (VRand() * 300.0));
            return;
        }

        if (ActorReachable(RandGoal))
        {
            MoveTowardX(RandGoal);
            RandGoal = None;
            return;
        }

        if (!BuildPathToward(RandGoal))
        {
            RandGoal = None;
            MoveToX(Pawn.Location + (VRand() * 300.0));
            return;
        }

        MoveTowardX(MoveTarget);
    }

    function FinishedMove()
    {
    	PickCombatStyle();
    }

    function EnemyChanged()
    {
        PickCombatStyle();
    }

    function DonateMoney(Pawn Other)
    {
        if (ActorReachable(Other))
        {
            DonateHuman = Other;
            GotoState('DonatingMoney');
        }
    }

Begin:
    Stop;
Camp:
    Stop;
}

// @STUB(M6) @SYS-BOT-MOVE legacy:KF2Bot.Camp
state Camp
{
    event BeginState(name PreviousStateName)
    {
        AuditStateEntry();
        AbortMove();
        if (KPawn != None)
        {
            KPawn.SetSprinting(false);
        }
    }

    event EndState(name NextStateName)
    {
        AuditStateExit(NextStateName);
    }

    function EnemyChanged()
    {
        PickCombatStyle();
    }

Begin:
    Stop;
}

// @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.DoObjective
state DoObjective extends Roaming
{
    function FinishObjective()
    {
        global.FinishObjective();
        PickCombatStyle();
    }

    function PickStyle()
    {
        local bool IterGoalReachable;

        IterGoalReachable = false;

        if (CheckObjectiveHazard())
        {
            return;
        }

        if (ObjectiveGoal == None)
        {
            ObjectiveGoal = mut.GetBotObjective(self);
            ObjectiveBailUntil = 0.0;
            AuditGoalLog("GOAL_SET", "DoObjectivePick");
        }

        if (ObjectiveGoal == None)
        {
            PickCombatStyle();
            return;
        }

        if (mut != None && mut.IsNodeBlocked(self, ObjectiveGoal))
        {
            PickCombatStyle();
            return;
        }

        if (VSizeSq(ObjectiveGoal.Location - Pawn.Location) > 90000.0)
        {
            if (ActorReachable(ObjectiveGoal))
            {
                IterGoalReachable = true;
                MoveTowardX(ObjectiveGoal);
                return;
            }
            if (BuildPathToward(ObjectiveGoal))
            {
                IterGoalReachable = true;
                MoveTowardX(MoveTarget);
                return;
            }
        }
        else
        {
            Focus = None;
            SetFocalPoint(Pawn.Location + (VRand() * 1000.0));
            return;
        }

        if (!IterGoalReachable && VSizeSq(ObjectiveGoal.Location - Pawn.Location) > 90000.0)
        {
            if (WorldInfo.TimeSeconds < ObjectiveBailUntil)
            {
                PickCombatStyle();
                return;
            }
            ObjectiveBailUntil = WorldInfo.TimeSeconds + OBJ_BAIL_COOLDOWN;
            if (mut != None && ObjectiveGoal != None
                && WorldInfo.TimeSeconds - LastNodeBlockTime >= 2.0
                && NodeBlockCount < 2)
            {
                mut.AddNodeBlock(self, ObjectiveGoal);
                LastNodeBlockTime = WorldInfo.TimeSeconds;
                NodeBlockCount++;
                EchelonLog("NODE_BLOCK bot=" $ Name $ " node=(" $ string(FFloor(ObjectiveGoal.Location.X / 100.0)) $ "," $ string(FFloor(ObjectiveGoal.Location.Y / 100.0)) $ "," $ string(FFloor(ObjectiveGoal.Location.Z / 100.0)) $ ") reason=pathfail ttl=8s");
            }
            EchelonLog("DoObjective: objective unreachable, bailing to combat (slot=" $ string(FollowSlotIndex) $ ")");
            PickCombatStyle();
            return;
        }

        if (RandGoal == None && !BuildRandomPath())
        {
            MoveToX(Pawn.Location + (VRand() * 300.0));
            return;
        }
        if (ActorReachable(RandGoal))
        {
            MoveTowardX(RandGoal);
            RandGoal = None;
            return;
        }
        if (!BuildPathToward(RandGoal))
        {
            RandGoal = None;
            MoveToX(Pawn.Location + (VRand() * 300.0));
            return;
        }
        MoveTowardX(MoveTarget);
    }
}

// @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.FightEnemy
state FightEnemy
{
    event BeginState(name PreviousStateName)
    {
        AuditStateEntry();
        AbortMove();
        SetTimer(0.2, true, 'Timer');
        Focus = Enemy;
        Timer();
    }

    event EndState(name NextStateName)
    {
        AuditStateExit(NextStateName);
        SetTimer(0.0, false);
        ClearTimer('FinishedMove');
        if (Pawn != None)
        {
            Pawn.ShouldCrouch(false);
            Pawn.StopFiring();
        }
    }

    event Timer()
    {
        if (Enemy == none)
        {
            return;
        }
        if (!Enemy.IsAliveAndWell() && !PickNextEnemy())
        {
            if (Pawn != none)
            {
                Pawn.StopFiring();
            }
            Enemy = none;
            AbortMove();
            CheckWeaponReequip();
            FinishedMove();
            return;
        }
        if (Enemy != none && KFPawn_Monster(Enemy) != none && KFPawn_Monster(Enemy).bIsHeadless)
        {
            if (Pawn != none)
            {
                Pawn.StopFiring();
            }
            Enemy = none;
            AbortMove();
            CheckWeaponReequip();
            FinishedMove();
            return;
        }
        if (SyncLineFocus())
        {
            return;
        }
        CheckWeaponReequip();
        EnemyEncounterTime = WorldInfo.TimeSeconds;
        Focus = Enemy;
        if (!HasOwnFireLine(Enemy))
        {
            Pawn.StopFiring();
            if (BotRank == GRUNT && SquadLeader != none && SquadLeader.CurrentFormation == 'LineFormation')
            {
                SquadLeader.NotifyBlockedShooter(self);
            }
            return;
        }
        FireWeaponAt(Enemy);
    }

    function NotifyKilled(Controller Killer, Controller Killed, Pawn KilledPawn, Class<DamageType> damageTyp)
    {
        if (KFPawn_MonsterBoss(KilledPawn) != None)
        {
            Enemy = None;
            bBossKillVictory = true;
            GotoState('VictoryDance');
            return;
        }

        if (Enemy == KilledPawn)
        {
            if (!PickNextEnemy())
            {
                Enemy = None;
                AbortMove();
                if ((Killer == self) && (NextVictoryDance < WorldInfo.TimeSeconds) && (Rand(3) == 0) && mut.ShouldDoVictoryDance())
                {
                    GotoState('VictoryDance');
                    return;
                }
                FinishedMove();
            }
            else
            {
                Focus = Enemy;
                Target = Enemy;
            }
        }
    }

    function FinishedMove()
    {
        Pawn.ShouldCrouch(false);
        PickCombatStyle();
    }

    function PickStyle()
    {
        local bool bMelee;
        local EcholonBot GroupLeader;
        local float RetreatDistSq;

        if (BotRank == GRUNT)
        {
            GruntPickCombatStyle();
            return;
        }

        if (mut.bObjectiveActive)
        {
            if (ObjectiveGoal == None)
            {
                ObjectiveGoal = mut.GetBotObjective(self);
                AuditGoalLog("GOAL_SET", "PickCombatStyle");
            }
            if (ObjectiveGoal != None && VSizeSq(ObjectiveGoal.Location - Pawn.Location) > 640000.0)
            {
                if (ActorReachable(ObjectiveGoal))
                {
                    MoveTowardX(ObjectiveGoal);
                    return;
                }
                if (BuildPathToward(ObjectiveGoal))
                {
                    MoveTowardX(MoveTarget);
                    return;
                }
            }
        }

        if (mut != None)
        {
            GroupLeader = mut.GetGroupLeader(GroupID);
        }
        else
        {
            GroupLeader = None;
        }

        if ((!bIsGroupLeader) && GroupLeader != None && GroupLeader.Pawn != None && VSizeSq(GroupLeader.Pawn.Location - Pawn.Location) > 2250000.0)
        {
            if (BuildPathToward(GroupLeader.Pawn))
            {
                MoveTowardX(MoveTarget, Enemy);
                return;
            }
        }
        else
        {
            if ((FollowingHuman != None) && VSizeSq(FollowingHuman.Location - Pawn.Location) > 2250000.0)
            {
                if (BuildPathToward(FollowingHuman))
                {
                    MoveTowardX(MoveTarget, Enemy);
                    return;
                }
            }
        }

        bMelee = IsMeleeOnly();

        if (bOutOfEffectiveRange && !bMelee)
        {
            CloseToEffectiveRange();
            return;
        }

        if (bMelee && Enemy.Health > BOSS_HEALTH_THRESHOLD)
        {
            Enemy = None;
            PickCombatStyle();
            return;
        }

        if (Enemy.Health > 500)
        {
            RetreatDistSq = 250000.0;
        }
        else
        {
            RetreatDistSq = 14400.0;
        }

        if ((((KPawn != None) || !bMelee) && !bMelee || (Vector(Enemy.Rotation) Dot (Enemy.Location - Pawn.Location)) < 0.0) && VSizeSq(Enemy.Location - Pawn.Location) < RetreatDistSq)
        {
            PickRetreatMove();
        }
        else
        {
            if (bMelee)
            {
                if (Pawn.Weapon != None && VSizeSq(Enemy.Location - Pawn.Location) < 40000.0)
                {
                    Pawn.Weapon.StartFire(0);
                }
                if (ActorReachable(Enemy))
                {
                    MoveTowardX(Enemy);
                }
                else
                {
                    if (BuildPathToward(Enemy))
                    {
                        MoveTowardX(MoveTarget, Enemy);
                    }
                    else
                    {
                        MoveToX((Normal(Enemy.Location - Pawn.Location) * 150.0) + Pawn.Location + (VRand() * 200.0), Enemy);
                    }
                }
            }
            else
            {
                if (Rand(2) == 0)
                {
                    MoveToX(Pawn.Location + (VRand() * 300.0), Enemy);
                }
                else
                {
                    Pawn.ShouldCrouch(Rand(2) == 0);
                    SetTimer(0.5 + (FRand() * 1.5), false, 'FinishedMove');
                }
            }
        }
    }

    event bool NotifyBump(Actor Other, Vector HitNormal)
    {
        global.NotifyBump(Other, HitNormal);

        if (Other == Enemy && MoveTarget == Enemy)
        {
            if ((Vector(Enemy.Rotation) Dot (Enemy.Location - Pawn.Location)) < 0.0)
            {
                FinishedMove();
            }
            else
            {
                MoveTarget = None;
                AbortMove();
                SetTimer(0.2 + (FRand() * 0.75), false, 'FinishedMove');
            }
        }

        return false;
    }

Begin:
    Stop;
}

// @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.TacticalRetreat
state TacticalRetreat
{
    event BeginState(name PreviousStateName)
    {
        AuditStateEntry();
        AbortMove();
        bIsRetreating = true;
        if (KPawn != None)
        {
            KPawn.SetSprinting(true);
        }
        SetTimer(ZED_COUNT_INTERVAL, true, 'CheckRetreatStatus');
    }

    event EndState(name NextStateName)
    {
        AuditStateExit(NextStateName);
        ClearTimer('CheckRetreatStatus');
        bIsRetreating = false;
        if (KPawn != None)
        {
            KPawn.SetSprinting(false);
        }
    }

    function CheckRetreatStatus()
    {
        if (Pawn == None || Pawn.Health <= 0)
        {
            return;
        }

        if (CountNearbyZeds(RETREAT_ZED_RADIUS) < RETREAT_ZED_CLEAR_COUNT && !HeavyZedWithin(RETREAT_HEAVY_RADIUS))
        {
            bIsRetreating = false;
            PickCombatStyle();
        }
    }

    function FinishedMove()
    {
        if (bIsRetreating)
        {
            PickRetreatMove();
        }
    }

    function EnemyChanged()
    {
        // Deliberately ignored -- P4 overrides P7: a newly spotted Zed must
        // not interrupt an active retreat.
    }

Begin:
    Stop;
}

// @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.BreakLose
state BreakLose
{
    ignores CheckGrabbed;

    event BeginState(name PreviousStateName)
    {
        AuditStateEntry();
        AbortMove();
        BreakFreeAttempts = 0;
        GrabStartTime = WorldInfo.TimeSeconds;
        NextEscapeAttempt = 0.0;
        bGrappleFailsafeTriggered = false;
        SetTimer(0.15, true, 'Timer');
        Focus = KPawn.InteractionPawn;

        if (BotRank == GRUNT && SquadLeader != None)
        {
            SquadLeader.OnGruntGrabbed(self);
        }

        if (mut != None && mut.bDebugGrapple)
        {
            mut.DebugMessage(GetHumanReadableName() $ " grabbed - attempting to break free.");
        }
    }

    event EndState(name NextStateName)
    {
        AuditStateExit(NextStateName);
        SetTimer(0.0, false);
        if (Pawn != None)
        {
            Pawn.StopFiring();
        }
        OnBreakLoseComplete();
        if (((mut != None) && mut.bDebugGrapple) && (Pawn != None) && (Pawn.IsAliveAndWell() && ((KPawn == None) || !KPawn.IsDoingSpecialMove(31))))
        {
            mut.DebugMessage(GetHumanReadableName() $ " broke free after " $ string(BreakFreeAttempts) $ " attempt(s), " $ string(int(WorldInfo.TimeSeconds - GrabStartTime)) $ "s.");
        }
    }

    function Timer()
    {
        local int NearbyZeds;

        if( (KPawn != None) && (KPawn.Health > 0) && KPawn.IsDoingSpecialMove(31) && (KPawn.InteractionPawn != None) )
        {
            Focus = KPawn.InteractionPawn;

            if( WorldInfo.TimeSeconds >= NextEscapeAttempt )
            {
                NextEscapeAttempt = WorldInfo.TimeSeconds + 1.5;
                BreakFreeAttempts++;
                TryBreakFree();
                if( (mut != None) && mut.bDebugGrapple )
                {
                    mut.DebugMessage( GetHumanReadableName() $ " struggling free (attempt " $ string(BreakFreeAttempts) $ ")" );
                }
            }

            if( (mut != None) && !bGrappleFailsafeTriggered && (WorldInfo.TimeSeconds - GrabStartTime) >= mut.FailsafeActivationDelay )
            {
                NearbyZeds = CountNearbyZeds(600.0);
                if( NearbyZeds <= mut.MaxZedsForFailsafe )
                {
                    bGrappleFailsafeTriggered = true;
                    ForceBreakGrapple();
                }
            }
        }
        else
        {
            PickCombatStyle();
        }
    }
}

// @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.Hunting
state Hunting
{
    event BeginState(name PreviousStateName)
    {
        AuditStateEntry();
        AbortMove();
        if (KPawn != None)
        {
            KPawn.SetSprinting(true);
        }
        SetTimer(0.25, true);
    }

    event EndState(name NextStateName)
    {
        AuditStateExit(NextStateName);
        SetTimer(0.0, false);
        if (KPawn != None)
        {
            KPawn.SetSprinting(false);
        }
    }

    function PickStyle()
    {
        local EcholonBot GroupLeader;

        GroupLeader = None;
        if (mut != None)
        {
            GroupLeader = mut.GetGroupLeader(GroupID);
        }

        if (!bIsGroupLeader && GroupLeader != None && GroupLeader.Pawn != None && VSizeSq(GroupLeader.Pawn.Location - Pawn.Location) > 810000.0)
        {
            Enemy = None;
        }
        else
        {
            if (FollowingHuman != None && VSizeSq(FollowingHuman.Location - Pawn.Location) > 810000.0)
            {
                Enemy = None;
            }
        }

        if (Enemy == None || !Enemy.IsAliveAndWell())
        {
            PickCombatStyle();
            return;
        }

        if (!BuildPathToward(Enemy))
        {
            Enemy = None;
            PickCombatStyle();
        }
        else
        {
            MoveTowardX(MoveTarget, Enemy);
        }
    }

    function FinishedMove()
    {
        PickCombatStyle();
    }

    function EnemyChanged()
    {
        PickCombatStyle();
    }

    function Timer()
    {
        local KFPawn_Monster BestZed;
        local float BestDist;

        BestZed = None;
        BestDist = 999999.0;

        foreach WorldInfo.AllPawns(class'KFPawn_Monster', BestZed, Pawn.Location, HUNT_SCAN_RADIUS)
        {
            if (!BestZed.IsAliveAndWell())
            {
                continue;
            }
            if (BestZed.GetTeamNum() == GetTeamNum())
            {
                continue;
            }
            if (!FastTrace(BestZed.Location, Pawn.Location))
            {
                continue;
            }
            if (VSizeSq(BestZed.Location - Pawn.Location) < BestDist)
            {
                BestDist = VSizeSq(BestZed.Location - Pawn.Location);
            }
        }

        if (BestZed != None)
        {
            SetEnemy(BestZed);
            BuildPathToward(Enemy);
            MoveTowardX(MoveTarget, Enemy);
        }
        else if ((Enemy == None) || !Enemy.IsAliveAndWell())
        {
            PickCombatStyle();
        }
        else if (LineOfSightTo(Enemy))
        {
            PickCombatStyle();
        }
    }

Begin:
    Stop;
}

// @STUB(M6) @SYS-BOT-HEAL legacy:KF2Bot.HealingSelf
state HealingSelf
{
    ignores FinishedMove;

    // @STUB(M6) @SYS-BOT-HEAL legacy:KF2Bot.HealingSelf.BeginState
    event BeginState(name PreviousStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-HEAL legacy:KF2Bot.HealingSelf.EndState
    event EndState(name NextStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-HEAL legacy:KF2Bot.HealingSelf.TimeOut
    function TimeOut()
    {
    }

    // @STUB(M6) @SYS-BOT-HEAL legacy:KF2Bot.HealingSelf.HealFailsafe
    function HealFailsafe()
    {
    }

Begin:
    Stop;
}

// @STUB(M6) @SYS-BOT-HEAL legacy:KF2Bot.HealOther
state HealOther
{
    ignores FinishedMove;

    // @STUB(M6) @SYS-BOT-HEAL legacy:KF2Bot.HealOther.BeginState
    event BeginState(name PreviousStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-HEAL legacy:KF2Bot.HealOther.EndState
    event EndState(name NextStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-HEAL legacy:KF2Bot.HealOther.TimeOut
    function TimeOut()
    {
    }

    // @STUB(M6) @SYS-BOT-HEAL legacy:KF2Bot.HealOther.HealFailsafe
    function HealFailsafe()
    {
    }

Begin:
    Stop;
}

// @STUB(M6) @SYS-BOT-HEAL legacy:KF2Bot.HealRanged
state HealRanged
{
    ignores FinishedMove;

    // @STUB(M6) @SYS-BOT-HEAL legacy:KF2Bot.HealRanged.BeginState
    event BeginState(name PreviousStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-HEAL legacy:KF2Bot.HealRanged.EndState
    event EndState(name NextStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-HEAL legacy:KF2Bot.HealRanged.TimeOut
    function TimeOut()
    {
    }

    // @STUB(M6) @SYS-BOT-HEAL legacy:KF2Bot.HealRanged.HealFailsafe
    function HealFailsafe()
    {
    }

Begin:
    Stop;
}

// @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.GrenadeTarget UNVERIFIED-ENTRY
state GrenadeTarget
{
    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.GrenadeTarget.BeginState
    event BeginState(name PreviousStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.GrenadeTarget.EndState
    event EndState(name NextStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.GrenadeTarget.FinishedMove
    function FinishedMove()
    {
    }

Begin:
    Stop;
}

// @STUB(M6) @SYS-BOT-SHOP legacy:KF2Bot.GoShopping
state GoShopping
{
    // @STUB(M6) @SYS-BOT-SHOP legacy:KF2Bot.GoShopping.BeginState
    event BeginState(name PreviousStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-SHOP legacy:KF2Bot.GoShopping.EndState
    event EndState(name NextStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-SHOP legacy:KF2Bot.GoShopping.EnemyChanged
    function EnemyChanged()
    {
    }

    // @STUB(M6) @SYS-BOT-SHOP legacy:KF2Bot.GoShopping.PickStyle
    function PickStyle()
    {
    }

    // @STUB(M6) @SYS-BOT-SHOP legacy:KF2Bot.GoShopping.Timer
    function Timer()
    {
    }

    // @STUB(M6) @SYS-BOT-SHOP legacy:KF2Bot.GoShopping.FinishedMove
    function FinishedMove()
    {
    }

    // @STUB(M6) @SYS-BOT-SHOP legacy:KF2Bot.GoShopping.DoTrading
    function DoTrading()
    {
    }

    // @STUB(M6) @SYS-BOT-SHOP legacy:KF2Bot.GoShopping.NotifyBump
    event bool NotifyBump(Actor Other, Vector HitNormal)
    {
    }

Begin:
    Stop;
}

// @STUB(M6) @SYS-BOT-MOVE legacy:KF2Bot.GetItem UNVERIFIED-ENTRY
state GetItem
{
    // @STUB(M6) @SYS-BOT-MOVE legacy:KF2Bot.GetItem.BeginState
    event BeginState(name PreviousStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-MOVE legacy:KF2Bot.GetItem.EndState
    event EndState(name NextStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-MOVE legacy:KF2Bot.GetItem.Timer
    function Timer()
    {
    }

    // @STUB(M6) @SYS-BOT-MOVE legacy:KF2Bot.GetItem.FinishedMove
    function FinishedMove()
    {
    }

Begin:
    Stop;
}

// @STUB(M6) @SYS-BOT-MOVE legacy:KF2Bot.DonatingMoney
state DonatingMoney
{
    // @STUB(M6) @SYS-BOT-MOVE legacy:KF2Bot.DonatingMoney.BeginState
    event BeginState(name PreviousStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-MOVE legacy:KF2Bot.DonatingMoney.EndState
    event EndState(name NextStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-MOVE legacy:KF2Bot.DonatingMoney.Tick
    function Tick(float Delta)
    {
    }

    // @STUB(M6) @SYS-BOT-MOVE legacy:KF2Bot.DonatingMoney.FinishedMove
    function FinishedMove()
    {
    }

    // @STUB(M6) @SYS-BOT-MOVE legacy:KF2Bot.DonatingMoney.DropMoney
    final function bool DropMoney()
    {
    }

Begin:
    Stop;
MoneyToss:
    Stop;
}

// @STUB(M6) @SYS-BOT-TERM legacy:KF2Bot.Dead
state Dead
{
    ignores StopAdjusting, Tick, CheckGrabbed, PickCombatStyle, SetEnemy, KilledBy, HearNoise, SeeMonster, SeePlayer;

    // @STUB(M6) @SYS-BOT-TERM legacy:KF2Bot.Dead.BeginState
    event BeginState(name PreviousStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-TERM legacy:KF2Bot.Dead.EndState
    event EndState(name NextStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-TERM legacy:KF2Bot.Dead.ReassertScoreboardFlags
    function ReassertScoreboardFlags()
    {
    }

Begin:
    Stop;
}

// @STUB(M6) @SYS-BOT-TERM legacy:KF2Bot.IsRagdolled
state IsRagdolled
{
    ignores StopAdjusting, Tick, CheckGrabbed, PickCombatStyle, SetEnemy, HearNoise, SeeMonster, SeePlayer;

    // @STUB(M6) @SYS-BOT-TERM legacy:KF2Bot.IsRagdolled.BeginState
    event BeginState(name PreviousStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-TERM legacy:KF2Bot.IsRagdolled.EndState
    event EndState(name NextStateName)
    {
    }
}

// @STUB(M6) @SYS-BOT-TERM legacy:KF2Bot.VictoryDance
state VictoryDance
{
    ignores HearNoise, SeeMonster, SeePlayer;

    // @STUB(M6) @SYS-BOT-TERM legacy:KF2Bot.VictoryDance.BeginState
    event BeginState(name PreviousStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-TERM legacy:KF2Bot.VictoryDance.EndState
    event EndState(name NextStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-TERM legacy:KF2Bot.VictoryDance.PlayDance
    final function PlayDance()
    {
    }

    // @STUB(M6) @SYS-BOT-TERM legacy:KF2Bot.VictoryDance.FinishedMove
    function FinishedMove()
    {
    }

    // @STUB(M6) @SYS-BOT-TERM legacy:KF2Bot.VictoryDance.GetRandMove
    final function Vector GetRandMove()
    {
    }

    // @STUB(M6) @SYS-BOT-TERM legacy:KF2Bot.VictoryDance.EnemyChanged
    function EnemyChanged()
    {
    }

MoveTaunt:
    Stop;
Begin:
    Stop;
}

defaultproperties
{
}
