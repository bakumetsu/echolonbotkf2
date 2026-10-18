class EcholonBotLogic extends EcholonBotBase hidecategories(Navigation);

// @STUB(M5c) @SYS-LOGIC-HEAL legacy:KF2BotLogic.CheckShouldHealMate
final function bool CheckShouldHealMate()
{
}

// @STUB(M5c) @SYS-LOGIC-HEAL legacy:KF2BotLogic.CheckMedicGunHeal
final function bool CheckMedicGunHeal()
{
}

// @STUB(M5c) @SYS-LOGIC-HEAL legacy:KF2BotLogic.CheckShouldSelfHeal
final function bool CheckShouldSelfHeal()
{
}

// @STUB(M5c) @SYS-LOGIC-UTIL legacy:KF2BotLogic.ShouldNadeEnemies
final function bool ShouldNadeEnemies()
{
}

// @STUB(M5c) @SYS-LOGIC-GRUNTMOVE legacy:KF2BotLogic.CheckGrabbed
function CheckGrabbed()
{
}

// @STUB(M5c) @SYS-LOGIC-GRUNTMOVE legacy:KF2BotLogic.UpdateGruntOffset
function UpdateGruntOffset()
{
}

// @STUB(M5c) @SYS-LOGIC-GRUNTMOVE legacy:KF2BotLogic.ApplyZStep
function vector ApplyZStep(vector T)
{
}

// @STUB(M5c) @SYS-LOGIC-GRUNTMOVE legacy:KF2BotLogic.RequestReroute
function RequestReroute()
{
}

// @STUB(M5c) @SYS-LOGIC-WATCHDOG legacy:KF2BotLogic.PromotionGapTimer
function PromotionGapTimer()
{
}

// @STUB(M5c) @SYS-LOGIC-HEAL legacy:KF2BotLogic.CanAffordHeal
function bool CanAffordHeal(int Type)
{
}

// @STUB(M5c) @SYS-LOGIC-HEAL legacy:KF2BotLogic.HealFail
function HealFail()
{
}

// @STUB(M5c) @SYS-LOGIC-HEAL legacy:KF2BotLogic.HealSuccess
function HealSuccess()
{
}

// @STUB(M5c) @SYS-LOGIC-HEAL legacy:KF2BotLogic.VerifyWeapon
function VerifyWeapon()
{
}

// @STUB(M5c) @SYS-LOGIC-HEAL legacy:KF2BotLogic.HealTimeOut
function HealTimeOut()
{
}

// @STUB(M5c) @SYS-LOGIC-GRUNTMOVE legacy:KF2BotLogic.ConsumePathToken
function bool ConsumePathToken()
{
}

// @STUB(M5c) @SYS-LOGIC-WATCHDOG legacy:KF2BotLogic.GruntDecisionTimer
function GruntDecisionTimer()
{
}

// @STUB(M5c) @SYS-LOGIC-WATCHDOG legacy:KF2BotLogic.IdleWatchdogTimer
function IdleWatchdogTimer()
{
}

// @STUB(M5c) @SYS-LOGIC-WATCHDOG legacy:KF2BotLogic.IdleWatchdog
function IdleWatchdog()
{
}

// @STUB(M5c) @SYS-LOGIC-WATCHDOG legacy:KF2BotLogic.ProcessOverwatchPhase
function ProcessOverwatchPhase()
{
}

// @STUB(M5c) @SYS-LOGIC-MOVEVAL legacy:KF2BotLogic.FollowCheckExit
function bool FollowCheckExit()
{
}

// @STUB(M5c) @SYS-LOGIC-DEATH legacy:KF2BotLogic.PawnDied
function PawnDied(Pawn inPawn)
{
}

// @STUB(M5c) @SYS-LOGIC-DEATH legacy:KF2BotLogic.ActivatePlayerDiedSequenceEvents
final function ActivatePlayerDiedSequenceEvents()
{
}

// @STUB(M5c) @SYS-LOGIC-UTIL legacy:KF2BotLogic.PickRetreatMove
final function PickRetreatMove()
{
}

// @STUB(M5c) @SYS-LOGIC-UTIL legacy:KF2BotLogic.FindCollectable
final function bool FindCollectable()
{
}

// @STUB(M5c) @SYS-LOGIC-UTIL legacy:KF2BotLogic.NotifyJumpApex
event NotifyJumpApex()
{
}

// @STUB(M5c) @SYS-LOGIC-UTIL legacy:KF2BotLogic.GetAIInfo
function string GetAIInfo()
{
}

// @STUB(M5c) @SYS-LOGIC-DEATH legacy:KF2BotLogic.ReplicatedEvent
simulated event ReplicatedEvent(name VarName)
{
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
