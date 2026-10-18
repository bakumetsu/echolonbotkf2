class EcholonBroadcastHandler extends BroadcastHandler config(Game) hidecategories(Navigation, Movement, Collision);

var BroadcastHandler MainHandle;
var EcholonMut mut;

// @STUB(M1) - legacy:KF2BotBroadcastHandle.SpawnBBHandle
static final function SpawnBBHandle(EcholonMut M)
{
}

// @STUB(M1) - legacy:KF2BotBroadcastHandle.UpdateSentText
function UpdateSentText()
{
}

// @STUB(M1) - legacy:KF2BotBroadcastHandle.AllowsBroadcast
function bool AllowsBroadcast(Actor broadcaster, int InLen)
{
}

// @STUB(M1) - legacy:KF2BotBroadcastHandle.Broadcast
function Broadcast(Actor Sender, coerce string msg, optional name Type)
{
}

// @STUB(M1) - legacy:KF2BotBroadcastHandle.BroadcastTeam
function BroadcastTeam(Controller Sender, coerce string msg, optional name Type)
{
}

// @STUB(M1) - legacy:KF2BotBroadcastHandle.AllowBroadcastLocalized
event AllowBroadcastLocalized(Actor Sender, Class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
}

// @STUB(M1) - legacy:KF2BotBroadcastHandle.AllowBroadcastLocalizedTeam
event AllowBroadcastLocalizedTeam(int TeamIndex, Actor Sender, Class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
}

defaultproperties
{
}
