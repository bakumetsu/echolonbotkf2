class EcholonBot extends EcholonBotLogic hidecategories(Navigation);

// @STUB(M6) @SYS-BOT-HUB legacy:KF2Bot.PickNextMove
state PickNextMove
{
    event BeginState(Name PreviousStateName)
    {
        AuditStateEntry();
        EchelonLog("HUB_ENTER from=" $ PreviousStateName);
    }

    event EndState(name NextStateName)
    {
        AuditStateExit(NextStateName);
    }

    function PickMove()
    {
        local bool bHasAmmo;
        local float RegroupElapsed;
        local int RegroupMyIdx, RegroupTargetIdx, RegroupMySize, RegroupTargetSize, ZedNearLeader;
        local Controller RegroupAttach;
        local EcholonBot RegroupAttachBot, RegroupHoldLeader;

        // Priority 1: Match Ended
        if (bInTerminalState)
        {
            HubPick("P1_MatchEnded", 'VictoryDance');
            GotoState('VictoryDance');
            return;
        }
        if (mut != None && mut.KF != None && mut.KF.MyKFGRI != None && mut.KF.MyKFGRI.bMatchIsOver)
        {
            HubPick("P1_MatchEnded", 'VictoryDance');
            GotoState('VictoryDance');
            return;
        }

        // Priority 3: Critical Survival
        if (KPawn != None && CheckShouldSelfHeal())
        {
            HubPick("P3_CriticalSurvival", 'HealingSelf');
            GotoState('HealingSelf');
            return;
        }

        // Priority 4: Tactical Retreat
        if (bIsGroupLeader && KPawn != None && !bIsRetreating && RetreatMayStart() && ShouldTacticalRetreat())
        {
            bIsRetreating = true;
            HubPick("P4_TacticalRetreat", 'TacticalRetreat');
            GotoState('TacticalRetreat');
            return;
        }

        // Priority 4.5: Regroup (not during free trader time: squads regroup in the last seconds)
        if (mut != None && !IsTraderFreeTime() && mut.GetSquadPhase(self) == mut.PHASE_REGROUP
            && !IsInState('FollowingLeader') && !IsInState('FollowingLeaderBasic'))
        {
            RegroupElapsed = WorldInfo.TimeSeconds - mut.GetSquadStartTime(self);
            if (RegroupElapsed < REGROUP_HARD_TIMEOUT && Pawn != None)
            {
                if (RegroupElapsed < REGROUP_DURATION
                    && KFGRI.bTraderIsOpen && NextShoppingTime < WorldInfo.TimeSeconds && KFGRI.OpenedTrader != None)
                {
                    if (mut.bRemoteShopActive)
                    {
                        RemoteShop();   // buys on the spot, then the regroup goes on below
                    }
                    else
                    {
                        EchelonLog("REGROUP_SHOP src=PickMove");
                        HubPick("P4.5_Regroup", 'GoShopping');
                        GotoState('GoShopping');
                        return;
                    }
                }
                if (RegroupElapsed < REGROUP_DURATION
                    && GlobalZedCount > 0 && GlobalZedCount != 15 && GlobalZedCount <= 30 && AcquireHuntTarget())
                {
                    EchelonLog("REGROUP_HUNT zeds=" $ string(GlobalZedCount));
                    HubPick("P4.5_Regroup", 'Hunting');
                    GotoState('Hunting');
                    return;
                }
                if (GlobalZedCount <= 30)
                {
                    if (bIsGroupLeader && !mut.HasSquadGoal(self))
                    {
                        ZedNearLeader = mut.CountZedsInRadius(Pawn.Location, mut.REGROUP_SCAN_RADIUS);
                        if (ZedNearLeader == 0)
                        {
                            RegroupMyIdx = GroupID - 1;
                            RegroupAttach = mut.FindNearestActiveLeader(self, AUDIT_ATTACH_RADIUS);
                            RegroupAttachBot = EcholonBot(RegroupAttach);
                            if (RegroupAttachBot != None && RegroupAttachBot.GroupID - 1 != RegroupMyIdx)
                            {
                                RegroupTargetIdx = RegroupAttachBot.GroupID - 1;
                                RegroupMySize = mut.GetGroupSize(GroupID);
                                RegroupTargetSize = mut.GetGroupSize(RegroupAttachBot.GroupID);
                                if (RegroupMySize > RegroupTargetSize
                                    && mut.GetSquadPhase(RegroupAttachBot) == mut.PHASE_REGROUP)
                                {
                                    mut.MoveSquadMembers(RegroupTargetIdx, RegroupMyIdx);
                                }
                                else
                                {
                                    mut.MoveSquadMembers(RegroupMyIdx, RegroupTargetIdx);
                                }
                                EchelonLog("REGROUP_ATTACH target=" $ string(RegroupTargetIdx + 1) $ " size=" $ string(RegroupMySize));
                                if (!bIsGroupLeader && SquadLeader != None && SquadLeader.Pawn != None)
                                {
                                    HubPick("P4.5_Regroup", 'FollowingLeader');
                                    FollowStart(SquadLeader);
                                    return;
                                }
                            }
                            else if (RegroupAttach != None && RegroupAttach.PlayerReplicationInfo != None)
                            {
                                EchelonLog("REGROUP_ATTACH human=" $ string(RegroupAttach.PlayerReplicationInfo.Name));
                                HubPick("P4.5_Regroup", 'FollowingLeader');
                                FollowStart(RegroupAttach);
                                return;
                            }
                        }
                    }
                    RegroupHoldLeader = SquadLeader;
                    if (!bIsGroupLeader && RegroupHoldLeader != None && RegroupHoldLeader.Pawn != None
                        && VSizeSq(RegroupHoldLeader.Pawn.Location - Pawn.Location) > REGROUP_HOLD_DIST_SQ)
                    {
                        EchelonLog("REGROUP_HOLD toLeader");
                        HubPick("P4.5_Regroup", 'FollowingLeader');
                        FollowStart(RegroupHoldLeader);
                        return;
                    }
                }
                if (bIsGroupLeader)
                {
                    ExecuteCampState();
                    return;
                }
            }
        }

        // Priority 5: SYG Enforcement (also the mutator's hunt order when few zeds are left, see UpdateHuntOrders)
        if (!mut.HasHoldGoals() && ObjectiveGoal != None && !mut.bHuntOrderActive)
        {
            ObjectiveGoal = None;
        }
        if (mut.HasHoldGoals() || mut.bHuntOrderActive)
        {
            // Hunt orders and zones hand out goals per squad: ask again at every pick. A real objective keeps the cached goal.
            if ((mut.bHuntOrderActive || mut.bZoneActive) && !mut.bObjectiveActive)
            {
                ObjectiveGoal = mut.GetBotObjective(self);
            }
            bHasAmmo = (Pawn != None) && (Pawn.Weapon != None)
                && (KFWeapon(Pawn.Weapon).GetTotalAmmoAmount(0) > 0);
            if (ObjectiveGoal == None)
            {
                if (bHasAmmo)
                {
                    ObjectiveGoal = mut.GetBotObjective(self);
                    ObjectiveBailUntil = 0.0;
                    AuditGoalLog("GOAL_SET", "PickMove");
                }
            }
            if (ObjectiveGoal != None && bHasAmmo && VSizeSq(ObjectiveGoal.Location - Pawn.Location) > SYG_DISTANCE_SQ
                && WorldInfo.TimeSeconds >= ObjectiveBailUntil)
            {
                HubPick("P5_SygEnforcement", 'DoObjective');
                GotoState('DoObjective');
                return;
            }
        }

        // Priority 6: Squad Medic (Triage)
        if (KPawn != None && WorldInfo.TimeSeconds - LastTriageTime >= TRIAGE_INTERVAL)
        {
            LastTriageTime = WorldInfo.TimeSeconds;
            if (CheckMedicGunHeal())
            {
                HubPick("P6_SquadMedic", 'HealRanged');
                GotoState('HealRanged');
                return;
            }
            if (CheckShouldHealMate())
            {
                HubPick("P6_SquadMedic", 'HealOther');
                GotoState('HealOther');
                return;
            }
        }

        // Priority 7: Combat Engagement
        if (Enemy != None && Enemy.IsAliveAndWell() && !(KFPawn_Monster(Enemy) != None && KFPawn_Monster(Enemy).bIsHeadless))
        {
            if (VSizeSq(Enemy.Location - Pawn.Location) > LEASH_DROP_DIST_SQ)
            {
                Enemy = None;
                LastLeashDropTime = WorldInfo.TimeSeconds;
            }
            else if (LineOfSightTo(Enemy))
            {
                HubPick("P7_CombatEngagement", 'FightEnemy');
                GotoState('FightEnemy');
                return;
            }
            else
            {
                HubPick("P7_CombatEngagement", 'Hunting');
                GotoState('Hunting');
                return;
            }
        }

        // Priority 8: Squad Tethering
        if (EvaluateSquadTether())
        {
            HubPick("P8_SquadTethering", 'Tether');
            return;
        }

        // Priority 8.5: Low zed count
        if (Enemy == None && GlobalZedCount > 0 && GlobalZedCount < HUNT_ZED_THRESHOLD && AcquireHuntTarget())
        {
            HubPick("P8.5_LowZedCount", 'Hunting');
            GotoState('Hunting');
            return;
        }

        // Priority 9: Economy
        if (KFGRI.bTraderIsOpen && NextShoppingTime < WorldInfo.TimeSeconds && KFGRI.OpenedTrader != None)
        {
            if (mut != None && mut.bRemoteShopActive)
            {
                RemoteShop();   // buys on the spot, then the trader roam below takes over
            }
            else
            {
                HubPick("P9_Economy", 'GoShopping');
                GotoState('GoShopping');
                return;
            }
        }

        // Priority 9.5: Trader roam (free trader time, already shopped)
        if (IsTraderFreeTime())
        {
            HubPick("P9.5_TraderRoam", 'Roaming');
            GotoState('Roaming');
            return;
        }

        // Priority 10: Camp
        HubPick("P10_Camp", 'Camp');
        ExecuteCampState();
    }

Begin:
    Sleep(0.0);
    PickMove();
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

    }

    function PickStyle()
    {
        local EcholonBot GroupLeader;

        if (IsTraderFreeTime())
        {
            // Free trader roam: skip the stick-to-leader branches below and wander.
            // A goal kept from before the trader opened can be anywhere on the map: drop it.
            if (RandGoal != None && !IsTraderRoamGoal(RandGoal))
            {
                RandGoal = None;
            }
        }
        else if (PlayStyle == 0 && KPawn != None)
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
                    if (WalkReachable(GroupLeader.Pawn))
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
                        LookModeSweep();
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
                        if (WalkReachable(FollowingHuman))
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
                            LookModeSweep();
                        }
                        return;
                    }
                }
            }
        }

        if (RandGoal != None && NavGoalSkipped(RandGoal))
        {
            RandGoal = None;
        }
        if (RandGoal == None && !BuildRandomPath())
        {
            NavRandomStep();
            return;
        }

        if (WalkReachable(RandGoal))
        {
            MoveTowardX(RandGoal);
            RandGoal = None;
            return;
        }

        if (!BuildPathToward(RandGoal))
        {
            RandGoal = None;
            NavRandomStep();
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
        if (WalkReachable(Other))
        {
            DonateHuman = Other;
            GotoState('DonatingMoney');
        }
    }

Begin:
    if(Pawn.Physics == 2)
    {
        WaitForLanding(2.0);
    }
    PickStyle();
    Stop;

Camp:
    Sleep(0.5 + FRand());
    PickCombatStyle();
    Stop;
}

// @STUB(M6) @SYS-BOT-MOVE legacy:KF2Bot.Camp
state Camp
{
    event BeginState(name PreviousStateName)
    {
        AuditStateEntry();
        AbortMove();
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
    if (Pawn.Physics == 2)
    {
        WaitForLanding(2.0);
    }
    Focus = None;
    LookModeSweep();
    Sleep(1.0 + FRand());
    PickCombatStyle();
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
        if (NavGoalSkipped(ObjectiveGoal))
        {
            PickCombatStyle();
            return;
        }

        if (VSizeSq(ObjectiveGoal.Location - Pawn.Location) > 90000.0)
        {
            if (WalkReachable(ObjectiveGoal))
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
            LookModeSweep();
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
            HubFail("objective_unreachable");
            if (mut != None && ObjectiveGoal != None
                && WorldInfo.TimeSeconds - LastNodeBlockTime >= 2.0
                && NodeBlockCount < 2)
            {
                mut.AddNodeBlock(self, ObjectiveGoal);
                LastNodeBlockTime = WorldInfo.TimeSeconds;
                NodeBlockCount++;
                EchelonLog("NODE_BLOCK node=(" $ string(FFloor(ObjectiveGoal.Location.X / 100.0)) $ "," $ string(FFloor(ObjectiveGoal.Location.Y / 100.0)) $ "," $ string(FFloor(ObjectiveGoal.Location.Z / 100.0)) $ ") reason=pathfail ttl=8s");
            }
            EchelonLog("OBJ_UNREACHABLE slot=" $ string(FollowSlotIndex));
            PickCombatStyle();
            return;
        }

        if (RandGoal != None && NavGoalSkipped(RandGoal))
        {
            RandGoal = None;
        }
        if (RandGoal == None && !BuildRandomPath())
        {
            NavRandomStep();
            return;
        }
        if (WalkReachable(RandGoal))
        {
            MoveTowardX(RandGoal);
            RandGoal = None;
            return;
        }
        if (!BuildPathToward(RandGoal))
        {
            RandGoal = None;
            NavRandomStep();
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
        ClearTimer('CombatRepick');
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
        local string Reason;

        Pawn.ShouldCrouch(false);

        if (Enemy == None || !Enemy.IsAliveAndWell())
        {
            Reason = "enemy_gone";
            LastHubCheckTime = WorldInfo.TimeSeconds;
            if (WorldInfo.TimeSeconds - LastRepickLog >= 2.0)
            {
                LastRepickLog = WorldInfo.TimeSeconds;
                EchelonLog("COMBAT_REPICK reason=" $ Reason);
            }
            PickCombatStyle();
            return;
        }
        if (KFPawn_Monster(Enemy) != None && KFPawn_Monster(Enemy).bIsHeadless)
        {
            Reason = "headless";
            LastHubCheckTime = WorldInfo.TimeSeconds;
            if (WorldInfo.TimeSeconds - LastRepickLog >= 2.0)
            {
                LastRepickLog = WorldInfo.TimeSeconds;
                EchelonLog("COMBAT_REPICK reason=" $ Reason);
            }
            PickCombatStyle();
            return;
        }
        if (WorldInfo.TimeSeconds - LastHubCheckTime >= CombatHubGap)
        {
            Reason = "hub_gap";
            LastHubCheckTime = WorldInfo.TimeSeconds;
            if (WorldInfo.TimeSeconds - LastRepickLog >= 2.0)
            {
                LastRepickLog = WorldInfo.TimeSeconds;
                EchelonLog("COMBAT_REPICK reason=" $ Reason);
            }
            PickCombatStyle();
            return;
        }

        PickStyle();
    }

    function CombatRepick()
    {
        if (Enemy != None && Enemy.IsAliveAndWell() && MoveFlags == 0)
        {
            PickStyle();
        }
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

        if (mut.HasHoldGoals())
        {
            if (ObjectiveGoal == None)
            {
                ObjectiveGoal = mut.GetBotObjective(self);
                AuditGoalLog("GOAL_SET", "PickCombatStyle");
            }
            if (ObjectiveGoal != None && VSizeSq(ObjectiveGoal.Location - Pawn.Location) > 640000.0)
            {
                if (WalkReachable(ObjectiveGoal))
                {
                    MoveTowardX(ObjectiveGoal, None, true, 'FE1');
                    return;
                }
                if (BuildPathToward(ObjectiveGoal))
                {
                    MoveTowardX(MoveTarget, None, true, 'FE2');
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
                MoveTowardX(MoveTarget, Enemy, true, 'FE3');
                return;
            }
        }
        else
        {
            if ((FollowingHuman != None) && VSizeSq(FollowingHuman.Location - Pawn.Location) > 2250000.0)
            {
                if (BuildPathToward(FollowingHuman))
                {
                    MoveTowardX(MoveTarget, Enemy, true, 'FE4');
                    return;
                }
            }
        }

        // Bug hunt: Enemy can be cleared (killed, NotifyKilled) between the hub and here; the
        // Enemy.Health reads below would be Accessed None.
        if (Enemy == None)
        {
            PickCombatStyle();
            return;
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
                if (WalkReachable(Enemy))
                {
                    MoveTowardX(Enemy, None, true, 'FE5');
                }
                else
                {
                    if (BuildPathToward(Enemy))
                    {
                        MoveTowardX(MoveTarget, Enemy, true, 'FE6');
                    }
                    else
                    {
                        MoveToX((Normal(Enemy.Location - Pawn.Location) * 150.0) + Pawn.Location + (RandDir2D() * 200.0), Enemy, true, 'FE7');
                    }
                }
            }
            else
            {
                if (Rand(2) == 0)
                {
                    MoveToX(Pawn.Location + (RandDir2D() * 300.0), Enemy, true, 'FE8');
                }
                else
                {
                    ApplyCrouch(Rand(2) == 0);  // honours bAllowBotCrouch
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
    if (Pawn.Physics == PHYS_Falling)
    {
        WaitForLanding(2.0);  // W4: bounded, as in the other states
    }
    PickStyle();
    Stop;
}

// @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.TacticalRetreat
state TacticalRetreat
{
    // Enters TacticalRetreat: aborts movement, starts both timers.
    event BeginState(name PreviousStateName)
    {
        AuditStateEntry();
        AbortMove();
        bIsRetreating = true;
        SetTimer(ZED_COUNT_INTERVAL, true, 'CheckRetreatStatus');
        SetTimer(RetreatFireInterval, true, 'RetreatFireTick');
    }

    // Leaves TacticalRetreat: clears timers and ends the retreat.
    event EndState(name NextStateName)
    {
        AuditStateExit(NextStateName);
        ClearTimer('CheckRetreatStatus');
        ClearTimer('RetreatFireTick');
        RetreatEnd("state_end");
        bIsRetreating = false;
    }

    // Periodic check: ends retreat when the area is clear and min-stay has elapsed.
    function CheckRetreatStatus()
    {
        if (Pawn == None || Pawn.Health <= 0)
        {
            return;
        }
        if (CountNearbyZeds(RETREAT_ZED_RADIUS) < RETREAT_ZED_CLEAR_COUNT && !HeavyZedWithin(RETREAT_HEAVY_RADIUS))
        {
            if (WorldInfo.TimeSeconds - RetreatStartTime >= RetreatMinStay || RetreatStartTime == 0.0)
            {
                RetreatEnd("clear");
                bIsRetreating = false;
                PickCombatStyle();
            }
        }
        if (bRetreatSurrounded)
        {
            PickRetreatMove();
        }
    }

    // Called when a move finishes during retreat; re-issues the retreat move.
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
    if (Pawn.Physics == 2)
    {
        WaitForLanding(2.0);
    }
    PickRetreatMove();
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
        if (((mut != None) && mut.bDebugGrapple) && (Pawn != None) && (Pawn.IsAliveAndWell() && ((KPawn == None) || !KPawn.IsDoingSpecialMove(SM_GrappleVictim))))
        {
            mut.DebugMessage(GetHumanReadableName() $ " broke free after " $ string(BreakFreeAttempts) $ " attempt(s), " $ string(int(WorldInfo.TimeSeconds - GrabStartTime)) $ "s.");
        }
    }

    function Timer()
    {
        local KFPawn Grabber;

        if( (KPawn != None) && (KPawn.Health > 0) && KPawn.IsDoingSpecialMove(SM_GrappleVictim) && (KPawn.InteractionPawn != None) )
        {
            Grabber = KPawn.InteractionPawn;
            Focus = Grabber;

            // Hard cap: whatever the zed count, never stay grabbed past FailsafeActivationDelay.
            // ForceBreakGrapple only ends the special moves; it deals no damage.
            if( (mut != None) && !bGrappleFailsafeTriggered && (WorldInfo.TimeSeconds - GrabStartTime) >= mut.FailsafeActivationDelay )
            {
                bGrappleFailsafeTriggered = true;
                ForceBreakGrapple();
                return;
            }

            // Surrounded: shoot the grabber (real hit). No clear shot or no usable weapon: bash below.
            if( IsGrabSurrounded(Grabber) && TryShootGrabber(Grabber) )
            {
                return;
            }

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
        SetTimer(0.25, true);
    }

    event EndState(name NextStateName)
    {
        AuditStateExit(NextStateName);
        SetTimer(0.0, false);
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
            NextHuntTime = WorldInfo.TimeSeconds + 1.0;
            PickCombatStyle();
            return;
        }

        if (!BuildPathToward(Enemy))
        {
            Enemy = None;
            NextHuntTime = WorldInfo.TimeSeconds + 1.0;
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
    if (Pawn.Physics == 2)
    {
        WaitForLanding(2.0);
    }
    PickStyle();
    Stop;
}

// @STUB(M6) @SYS-BOT-HEAL legacy:KF2Bot.HealingSelf
state HealingSelf
{
    ignores FinishedMove;

    event BeginState(name PreviousStateName)
    {
        AuditStateEntry();
        AbortMove();
    }

    event EndState(name NextStateName)
    {
        AuditStateExit(NextStateName);
        ClearTimer('HealFailsafe');
        ClearTimer('VerifyWeapon');
        PendingHeal = None;
        if(Pawn != None)
        {
            Pawn.StopFiring();
            if(KFWeap_HealerBase(Pawn.Weapon) != None && Pawn.InvManager != None)
            {
                Pawn.InvManager.SwitchToBestWeapon(true);
            }
            SetTimer(1.5, false, 'VerifyWeapon');
        }
    }

    function TimeOut()
    {
        HealFail();
        PickCombatStyle();
    }

    function HealFailsafe()
    {
    	HealFail();
    	PickCombatStyle();
    }

Begin:
    if(Pawn.Physics == PHYS_Walking)
    {
        landingDeadline = WorldInfo.TimeSeconds + 2.0;
        while(Pawn.Physics == PHYS_Walking && WorldInfo.TimeSeconds < landingDeadline)
        {
            Sleep(0.1);
        }
    }
    SetTimer(8.0, false, 'HealFailsafe');

    if((KPawn == None) || KPawn.Health <= 0)
    {
        HealFail();
        PickCombatStyle();
        Stop;
    }

    if(!CanAffordHeal(0))
    {
        HealFail();
        PickCombatStyle();
        Stop;
    }

    equipDeadline = WorldInfo.TimeSeconds + 3.0;
    while(Pawn.Weapon != MedicGun && WorldInfo.TimeSeconds < equipDeadline)
    {
        Pawn.InvManager.SetCurrentWeapon(MedicGun);
        Sleep(0.1);
    }
    if(Pawn.Weapon != MedicGun)
    {
        HealFail();
        PickCombatStyle();
        Stop;
    }

    Focus = Pawn;

    MedicGun.AmmoCount[0] -= 100;
    MedicGun.PerformReload();
    MedicGun.PlayAnimation('Heal_Self');
    KPawn.HealthToRegen += 20;
    Sleep(FMin(FMax(MedicGun.MySkelMesh.GetAnimInterruptTime('Heal_Self'), 0.1), 3.0));

    if(KPawn.Health + KPawn.HealthToRegen > KPawn.HealthMax)
    {
        KPawn.HealthToRegen = KPawn.HealthMax - KPawn.Health;
    }
    KPawn.SetTimer(KPawn.HealthRegenRate, true, 'GiveHealthOverTime');
    KPawn.PlayHeal(class'KFDT_Healing');

    HealSuccess();
    PickCombatStyle();
    Stop;
}

// @STUB(M6) @SYS-BOT-HEAL legacy:KF2Bot.HealOther
state HealOther
{
    ignores FinishedMove;

    event BeginState(name PreviousStateName)
    {
        AuditStateEntry();
        AbortMove();
    }

    event EndState(name NextStateName)
    {
        AuditStateExit(NextStateName);
        ClearTimer('HealFailsafe');
        ClearTimer('VerifyWeapon');
        PendingHeal = None;
        if(Pawn != None)
        {
            Pawn.StopFiring();
            if(KFWeap_HealerBase(Pawn.Weapon) != None && Pawn.InvManager != None)
            {
                Pawn.InvManager.SwitchToBestWeapon(true);
            }
            SetTimer(1.5, false, 'VerifyWeapon');
        }
    }

    function TimeOut()
    {
        HealFail();
        PickCombatStyle();
    }

    function HealFailsafe()
    {
        HealFail();
        PickCombatStyle();
    }

Begin:
    if(Pawn.Physics == PHYS_Walking)
    {
        landingDeadline = WorldInfo.TimeSeconds + 2.0;
        while(Pawn.Physics == PHYS_Walking && WorldInfo.TimeSeconds < landingDeadline)
        {
            Sleep(0.1);
        }
    }
    SetTimer(8.0, false, 'HealFailsafe');

    if(PendingHeal == None)
    {
        HealFail();
        PickCombatStyle();
        Stop;
    }

    while(true)
    {
        if((PendingHeal == None) || !PendingHeal.IsAliveAndWell() || PendingHeal.Health >= (HEAL_MIN_NEED_PCT / 100.0) * PendingHeal.HealthMax)
        {
            HealFail();
            PickCombatStyle();
            Stop;
        }
        if((VSize(PendingHeal.Location - Pawn.Location) <= 200.0) && LineOfSightTo(PendingHeal))
        {
            break;
        }
        MoveTowardX(PendingHeal);
        Sleep(0.1);
    }

    if(!CanAffordHeal(0))
    {
        HealFail();
        PickCombatStyle();
        Stop;
    }
    equipDeadline = WorldInfo.TimeSeconds + 3.0;
    while(Pawn.Weapon != MedicGun && WorldInfo.TimeSeconds < equipDeadline)
    {
        Pawn.InvManager.SetCurrentWeapon(MedicGun);
        Sleep(0.1);
    }
    if(Pawn.Weapon != MedicGun)
    {
        HealFail();
        PickCombatStyle();
        Stop;
    }

    AbortMove();
    Pawn.Acceleration = vect(0, 0, 0);
    Focus = PendingHeal;
    Target = PendingHeal;
    FinishRotation();

    // Bug hunt: the target can die or be cleared while the waits above run.
    if (PendingHeal == None || PendingHeal.Health <= 0)
    {
        HealFail();
        PickCombatStyle();
        Stop;
    }

    MedicGun.AmmoCount[0] -= 100;
    MedicGun.PerformReload();
    MedicGun.PlayAnimation('Heal_Team');
    PendingHeal.HealthToRegen += 20;
    Sleep(FMin(FMax(MedicGun.MySkelMesh.GetAnimInterruptTime('Heal_Team'), 0.1), 3.0));
    if (PendingHeal == None)  // cleared during the heal animation; the charge is already spent
    {
        HealSuccess();
        PickCombatStyle();
        Stop;
    }

    if(PendingHeal.Health + PendingHeal.HealthToRegen > PendingHeal.HealthMax)
    {
        PendingHeal.HealthToRegen = PendingHeal.HealthMax - PendingHeal.Health;
    }
    PendingHeal.SetTimer(PendingHeal.HealthRegenRate, true, 'GiveHealthOverTime');
    PendingHeal.PlayHeal(class'KFDT_Healing');

    HealSuccess();
    PickCombatStyle();
    Stop;
}

// @STUB(M6) @SYS-BOT-HEAL legacy:KF2Bot.HealRanged
state HealRanged
{
    ignores FinishedMove;

    event BeginState(name PreviousStateName)
    {
        AuditStateEntry();
        AbortMove();
    }

    event EndState(name NextStateName)
    {
        AuditStateExit(NextStateName);
        ClearTimer('HealFailsafe');
        ClearTimer('VerifyWeapon');
        PendingHeal = None;
        if(Pawn != None)
        {
            Pawn.StopFiring();
            if(KFWeap_MedicBase(Pawn.Weapon) != None)
            {
                Pawn.InvManager.SwitchToBestWeapon(true);
            }
            SetTimer(1.5, false, 'VerifyWeapon');
        }
    }

    function TimeOut()
    {
        HealFail();
        PickCombatStyle();
    }

    function HealFailsafe()
    {
        HealFail();
        PickCombatStyle();
    }

Begin:
    if(Pawn.Physics == PHYS_Walking)
    {
        landingDeadline = WorldInfo.TimeSeconds + 2.0;
        while(Pawn.Physics == PHYS_Walking && WorldInfo.TimeSeconds < landingDeadline)
        {
            Sleep(0.1);
        }
    }
    SetTimer(8.0, false, 'HealFailsafe');

    if(PendingHeal == None)
    {
        HealFail();
        PickCombatStyle();
        Stop;
    }

    while(true)
    {
        if((PendingHeal == None) || !PendingHeal.IsAliveAndWell() || PendingHeal.Health >= (HEAL_MIN_NEED_PCT / 100.0) * PendingHeal.HealthMax)
        {
            HealFail();
            PickCombatStyle();
            Stop;
        }
        if((VSize(PendingHeal.Location - Pawn.Location) <= 1500.0) && LineOfSightTo(PendingHeal))
        {
            break;
        }
        MoveTowardX(PendingHeal);
        Sleep(0.1);
    }

    if(!CanAffordHeal(1))
    {
        HealFail();
        PickCombatStyle();
        Stop;
    }
    equipDeadline = WorldInfo.TimeSeconds + 3.0;
    while(Pawn.Weapon != RangeMedicGun && WorldInfo.TimeSeconds < equipDeadline)
    {
        Pawn.InvManager.SetCurrentWeapon(RangeMedicGun);
        Sleep(0.1);
    }
    if(Pawn.Weapon != RangeMedicGun)
    {
        HealFail();
        PickCombatStyle();
        Stop;
    }

    AbortMove();
    Pawn.Acceleration = vect(0, 0, 0);
    Focus = PendingHeal;
    Target = PendingHeal;
    FinishRotation();

    // Bug hunt: the target can die or be cleared while the waits above run.
    if (PendingHeal == None || PendingHeal.Health <= 0)
    {
        HealFail();
        PickCombatStyle();
        Stop;
    }

    RangeMedicGun.AmmoCount[1] -= 50;
    RangeMedicGun.StartHealRecharge();
    RangeMedicGun.PlayAnimation('Shoot_Dart');
    if(mut != None)
    {
        mut.RegisterRangedHealTarget(PendingHeal);
    }
    PendingHeal.HealthToRegen += RangeMedicGun.default.HealAmount;
    Sleep(FMin(RangeMedicGun.GetFireInterval(1), 3.0));
    if (PendingHeal == None)  // cleared during the heal animation; the charge is already spent
    {
        HealSuccess();
        PickCombatStyle();
        Stop;
    }

    if(PendingHeal.Health + PendingHeal.HealthToRegen > PendingHeal.HealthMax)
    {
        PendingHeal.HealthToRegen = PendingHeal.HealthMax - PendingHeal.Health;
    }
    PendingHeal.SetTimer(PendingHeal.HealthRegenRate, true, 'GiveHealthOverTime');
    PendingHeal.PlayHeal(class'KFDT_Healing');

    HealSuccess();
    PickCombatStyle();
    Stop;
}

// @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.GrenadeTarget UNVERIFIED-ENTRY
state GrenadeTarget
{
    event BeginState(name PreviousStateName)
    {
        AuditStateEntry();
        AbortMove();
    }

    event EndState(name NextStateName)
    {
        if (Pawn != None)
        {
            Pawn.StopFiring();
        }
    }

    function FinishedMove()
    {
        PickCombatStyle();
    }

Begin:
    if (Pawn.Physics == 2)
    {
        WaitForLanding(2.0);
    }
    Focus = Target;
    FinishRotation();
    if (Pawn.Weapon != None)  // bug hunt: no weapon equipped during a swap
    {
        Pawn.Weapon.StartFire(4);
    }
    Sleep(0.2);
    Enemy = Pawn(Target);
    PickRetreatMove();
    Stop;
}

// @STUB(M6) @SYS-BOT-SHOP legacy:KF2Bot.GoShopping
state GoShopping
{
    event BeginState(name PreviousStateName)
    {
        AuditStateEntry();
        AbortMove();
        SetTimer(0.4 + FRand() * 0.25, true);  // default 'Timer': this state's Timer() walks to the trader
        TraderRetryCount = 0;
    }

    event EndState(name NextStateName)
    {
        AuditStateExit(NextStateName);
        ClearTimer('DoTrading');
        SetTimer(0.0, false);
    }

    function EnemyChanged()
    {
        PickCombatStyle();
    }

    function PickStyle()
    {
        if (KFGRI.OpenedTrader == None || NavGoalSkipped(KFGRI.OpenedTrader))
        {
            PickCombatStyle();
            return;
        }
        if (WalkReachable(KFGRI.OpenedTrader))
        {
            TraderRetryCount = 0;
            MoveToX(KFGRI.OpenedTrader.Location);
            return;
        }
        if (BuildPathToward(KFGRI.OpenedTrader))
        {
            TraderRetryCount = 0;
            MoveTowardX(MoveTarget);
        }
        else
        {
            AbortMove();
            SetTimer(0.0, false);  // stop the repeating Timer before the backoff retry
            ++TraderRetryCount;
            if (TraderRetryCount >= TRADER_MAX_RETRIES)
            {
                TraderRetryCount = 0;
                NextShoppingTime = WorldInfo.TimeSeconds + TRADER_GIVEUP_COOLDOWN;
                ShoppedWave = KFGRI.WaveNum;   // a bot that cannot reach the trader must not hold up the playtest trader skip
                HubFail("trader_unreachable");
                EchelonLog("TRADER_GIVEUP retries=" $ string(TRADER_MAX_RETRIES) $ " cooldown=" $ string(TRADER_GIVEUP_COOLDOWN));
                PickCombatStyle();
                return;
            }
            SetTimer((1.0 + (FRand() * 2.0)) + (float(TraderRetryCount) * 1.0), false, 'DoTrading');
        }
    }

    function Timer()
    {
        if (KFGRI.OpenedTrader == None)
        {
            PickCombatStyle();
        }
        else
        {
            if (Pawn.IsOverlapping(KFGRI.OpenedTrader))
            {
                AbortMove();
                SetTimer(0.0, false);
                SetTimer(1.0 + (FRand() * 2.0), false, 'DoTrading');
            }
        }
    }

    function FinishedMove()
    {
        PickCombatStyle();
    }

    function DoTrading()
    {
        if (KFGRI.TraderItems != None)
        {
            ProcessPurchase(KFGRI.TraderItems);
            EchelonLog("SHOP_WALK wave=" $ string(KFGRI.WaveNum) $ " dosh_before=" $ string(LastShopDoshBefore)
                $ " dosh_after=" $ string(int(PlayerReplicationInfo.Score)) $ " bought=" $ string(LastShopBought));
        }
        FinishShopping();
        if (Rand(3) == 0)
        {
            GotoState('VictoryDance', 'MoveTaunt');
        }
        else
        {
            PickCombatStyle();
        }
    }

    event bool NotifyBump(Actor Other, Vector HitNormal)
    {
        if (IsTimerActive('DoTrading'))
        {
            return false;
        }
        return global.NotifyBump(Other, HitNormal);
    }

Begin:
    if (Pawn.Physics == 2)
    {
        WaitForLanding();
    }
    PickStyle();
    Stop;
}

// @STUB(M6) @SYS-BOT-MOVE legacy:KF2Bot.GetItem UNVERIFIED-ENTRY
state GetItem
{
    event BeginState(name PreviousStateName)
    {
        AuditStateEntry();
        AbortMove();
        if ((Enemy != None) && LineOfSightTo(Enemy))
        {
            SetTimer(0.1 + FRand() * 0.15, true);  // default 'Timer', as legacy
        }
    }

    event EndState(name NextStateName)
    {
        AuditStateExit(NextStateName);
        ClearTimer('Timer');
        if (Pawn != None)
        {
            Pawn.StopFiring();
        }
    }

    function Timer()
    {
        if(Enemy != None)
        {
            EnemyEncounterTime = WorldInfo.TimeSeconds;
            Focus = Enemy;
            FireWeaponAt(Enemy);
        }
    }

    function FinishedMove()
    {
    	PickCombatStyle();
    }

Begin:
    if (Pawn.Physics == 2)
    {
        WaitForLanding(2.0);
    }
    MoveTowardX(LastFactory, Enemy);
    Stop;
}

// @STUB(M6) @SYS-BOT-MOVE legacy:KF2Bot.DonatingMoney
state DonatingMoney
{
    event BeginState(name PreviousStateName)
    {
        AuditStateEntry();
        if (Pawn != None)
        {
            Pawn.StopFiring();
        }
    }

    event EndState(name NextStateName)
    {
        AuditStateExit(NextStateName);
    }

    function Tick(float Delta)
    {
        global.Tick(Delta);
        if((DonateHuman == None) || (DonateHuman.Health <= 0) || (Pawn == None))
        {
            PickCombatStyle();
            return;
        }
        if(VSizeSq(DonateHuman.Location - Pawn.Location) < 90000.0)
        {
            if(FastTrace(DonateHuman.Location, Pawn.Location))
            {
                PickCombatStyle();
            }
            else
            {
                if(MoveFlags != 0)
                {
                    AbortMove();
                    GotoState('DonatingMoney', 'MoneyToss');
                }
                else
                {
                    Pawn.Acceleration = vect(0, 0, 0);
                }
            }
        }
        else
        {
            Pawn.Acceleration = DonateHuman.Location - Pawn.Location;
        }
    }

    function FinishedMove()
    {
        PickCombatStyle();
    }

    final function bool DropMoney()
    {
        local Vector TossVel, StartLocation;
        local Rotator R;
        local Vector X, Y, Z;
        local KFDroppedPickup_Cash KFDP;
        local int Amount;

        X = DonateHuman.Location - Pawn.Location;
        TossVel = Normal(X);
        TossVel = (TossVel * ((Pawn.Velocity Dot TossVel) + float(500))) + vect(0, 0, 200);
        X.Z = 0;
        R = Rotator(X);
        GetAxes(R, X, Y, Z);
        StartLocation = (Pawn.Location + ((0.8 * Pawn.CylinderComponent.CollisionRadius) * X)) - ((0.5 * Pawn.CylinderComponent.CollisionRadius) * Y);
        Amount = Min(50, int(PlayerReplicationInfo.Score));
        if (Amount <= 0)
        {
            return false;
        }
        StartLocation.Z += (Pawn.BaseEyeHeight / float(2));
        KFDP = Spawn(Class'KFGame.KFDroppedPickup_Cash', self,, StartLocation,,, true);
        if (KFDP == None)
        {
            return false;
        }
        KFDP.SetPhysics(2);
        KFDP.InventoryClass = Class'KFGameContent.KFInventory_Money';
        KFDP.Velocity = TossVel * 1.6;
        KFDP.Instigator = Pawn;
        KFDP.SetPickupMesh(Class'KFGameContent.KFInventory_Money'.default.DroppedPickupMesh);
        KFDP.SetPickupParticles(Class'KFGameContent.KFInventory_Money'.default.DroppedPickupParticles);
        KFDP.CashAmount = Amount;
        KFDP.TosserPRI = PlayerReplicationInfo;
        PlayerReplicationInfo.Score -= float(Amount);
        if ((Role == ROLE_Authority) && (KFGameInfo(WorldInfo.Game) != None) && (KFGameInfo(WorldInfo.Game).DialogManager != None))
        {
            KFGameInfo(WorldInfo.Game).DialogManager.PlayDoshTossDialog(KPawn);
        }
        return true;
    }

Begin:
    if (Pawn.Physics == 2)
    {
        WaitForLanding(2.0);
    }
    MoveTowardX(DonateHuman, DonateHuman, false);
    Stop;

MoneyToss:
    NextDoshShareTime = WorldInfo.TimeSeconds + 5.0;
    Sleep(0.45);
    DoshDropCounter = byte(Rand(4));
    while (DoshDropCounter < 8)
    {
        Sleep(0.35);
        if (!DropMoney())
        {
            break;
        }
        ++DoshDropCounter;
    }
    PickCombatStyle();
    Stop;
}

// @STUB(M6) @SYS-BOT-TERM legacy:KF2Bot.Dead
state Dead
{
    ignores StopAdjusting, Tick, CheckGrabbed, PickCombatStyle, SetEnemy, KilledBy, HearNoise, SeeMonster, SeePlayer;

    event BeginState(name PreviousStateName)
    {
        AuditStateEntry();
        SetTimer(1.0, true, 'ReassertScoreboardFlags');
    }

    event EndState(name NextStateName)
    {
        AuditStateExit(NextStateName);
        ClearTimer('ReassertScoreboardFlags');
    }

    function ReassertScoreboardFlags()
    {
        local KFPlayerReplicationInfo KFPRI;

        if (PlayerReplicationInfo != None)
        {
            KFPRI = KFPlayerReplicationInfo(PlayerReplicationInfo);
            if (KFPRI != None)
            {
                KFPRI.bHasSpawnedIn = true;
            }
        }
    }

Begin:
    Stop;
}

// @STUB(M6) @SYS-BOT-TERM legacy:KF2Bot.IsRagdolled
state IsRagdolled
{
    ignores StopAdjusting, Tick, CheckGrabbed, PickCombatStyle, SetEnemy, HearNoise, SeeMonster, SeePlayer;

    event BeginState(name PreviousStateName)
    {
        AuditStateEntry();
        AbortMove();
        if (Pawn != None)
        {
            Pawn.StopFiring();
        }
    }

    event EndState(name NextStateName)
    {
        AuditStateExit(NextStateName);
    }
}

// @STUB(M6) @SYS-BOT-TERM legacy:KF2Bot.VictoryDance
state VictoryDance
{
    ignores HearNoise, SeeMonster, SeePlayer;

    event BeginState(name PreviousStateName)
    {
        AuditStateEntry();
        AbortMove();
        if (Pawn != None)
        {
            Pawn.StopFiring();
        }

        // P1 Terminal Lock: derive the flag from the live match-over condition
        // rather than from WHY VictoryDance was entered
        if (mut != None && mut.KF != None && mut.KF.MyKFGRI != None && mut.KF.MyKFGRI.bMatchIsOver)
        {
            bInTerminalState = true;
        }
    }

    event EndState(name NextStateName)
    {
        AuditStateExit(NextStateName);
        bBossKillVictory = false;
    }

    final function PlayDance()
    {
        local KFPawn B;

        NextVictoryDance = WorldInfo.TimeSeconds + 20.0;
        B = KFPawn(Pawn);
        if (B != None && mut != None && mut.bBotEmotes)
        {
            B.DoSpecialMove(35, true, , mut.PickRandEmote());
        }
    }

    function FinishedMove()
    {
        local Vector V;

        V.X = FRand() - 0.5;
        V.Y = FRand() - 0.5;
        Focus = None;
        SetFocalPoint(Pawn.Location + (Normal2D(V) * 1000.0));
        GotoState('VictoryDance', 'Begin');
    }

    final function Vector GetRandMove()
    {
        local Vector V;
        local int I;

        I = 0;
        while (I < 5)
        {
            V.X = FRand() - 0.5;
            V.Y = FRand() - 0.5;
            V = Pawn.Location + (Normal2D(V) * ((FRand() * 200.0) + 250.0));
            if (FastTrace(V, Pawn.Location))
            {
                break;
            }
            I++;
        }

        return V;
    }

    function EnemyChanged()
    {
        if (!bBossKillVictory)
        {
            PickCombatStyle();
        }
    }

MoveTaunt:
    MoveToX(GetRandMove(), , false);
    Stop;

Begin:
    if (Pawn.Physics == 2)
    {
        WaitForLanding(2.0);
    }
    Sleep(0.1 + FRand());
    PlayDance();
    DoshDropCounter = 0;
    while (KPawn.IsDoingSpecialMove(35) && ++DoshDropCounter < 250)
    {
        Sleep(0.1);
    }
    PickCombatStyle();
    Stop;
}

defaultproperties
{
}
