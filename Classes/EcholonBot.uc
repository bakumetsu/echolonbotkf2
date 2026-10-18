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
    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.DoObjective.FinishObjective
    function FinishObjective()
    {
    }

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.DoObjective.PickStyle
    function PickStyle()
    {
    }
}

// @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.FightEnemy
state FightEnemy
{
    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.FightEnemy.BeginState
    event BeginState(name PreviousStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.FightEnemy.EndState
    event EndState(name NextStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.FightEnemy.Timer
    event Timer()
    {
    }

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.FightEnemy.NotifyKilled
    function NotifyKilled(Controller Killer, Controller Killed, Pawn KilledPawn, Class<DamageType> damageTyp)
    {
    }

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.FightEnemy.FinishedMove
    function FinishedMove()
    {
    }

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.FightEnemy.PickStyle
    function PickStyle()
    {
    }

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.FightEnemy.NotifyBump
    event bool NotifyBump(Actor Other, Vector HitNormal)
    {
    }

Begin:
    Stop;
}

// @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.TacticalRetreat
state TacticalRetreat
{
    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.TacticalRetreat.BeginState
    event BeginState(name PreviousStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.TacticalRetreat.EndState
    event EndState(name NextStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.TacticalRetreat.CheckRetreatStatus
    function CheckRetreatStatus()
    {
    }

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.TacticalRetreat.FinishedMove
    function FinishedMove()
    {
    }

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.TacticalRetreat.EnemyChanged
    function EnemyChanged()
    {
    }

Begin:
    Stop;
}

// @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.BreakLose
state BreakLose
{
    ignores CheckGrabbed;

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.BreakLose.BeginState
    event BeginState(name PreviousStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.BreakLose.EndState
    event EndState(name NextStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.BreakLose.Timer
    function Timer()
    {
    }
}

// @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.Hunting
state Hunting
{
    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.Hunting.BeginState
    event BeginState(name PreviousStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.Hunting.EndState
    event EndState(name NextStateName)
    {
    }

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.Hunting.PickStyle
    function PickStyle()
    {
    }

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.Hunting.FinishedMove
    function FinishedMove()
    {
    }

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.Hunting.EnemyChanged
    function EnemyChanged()
    {
    }

    // @STUB(M6) @SYS-BOT-COMBAT legacy:KF2Bot.Hunting.Timer
    function Timer()
    {
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
