class EcholonBroadcastHandler extends BroadcastHandler config(Game) hidecategories(Navigation, Movement, Collision);

var BroadcastHandler MainHandle;
var EcholonMut mut;

static final function SpawnBBHandle(EcholonMut M)
{
    local EcholonBroadcastHandler B;

    B = M.Spawn(Class'EcholonBot.EcholonBroadcastHandler');
    B.mut = M;
    B.MainHandle = M.WorldInfo.Game.BroadcastHandler;
    M.WorldInfo.Game.BroadcastHandler = B;
}

function UpdateSentText()
{
    MainHandle.UpdateSentText();
}

function bool AllowsBroadcast(Actor broadcaster, int InLen)
{
    if (MainHandle == None)
    {
        return false;
    }
    return MainHandle.AllowsBroadcast(broadcaster, InLen);
}

function Broadcast(Actor Sender, coerce string msg, optional name Type)
{
    MainHandle.Broadcast(Sender, msg, Type);
}

function BroadcastTeam(Controller Sender, coerce string msg, optional name Type)
{
    MainHandle.BroadcastTeam(Sender, msg, Type);
}

event AllowBroadcastLocalized(Actor Sender, Class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
    MainHandle.AllowBroadcastLocalized(Sender, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
}

event AllowBroadcastLocalizedTeam(int TeamIndex, Actor Sender, Class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
    MainHandle.AllowBroadcastLocalizedTeam(TeamIndex, Sender, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
}

defaultproperties
{
}
