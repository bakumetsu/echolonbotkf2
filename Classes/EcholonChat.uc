class EcholonChat extends BroadcastHandler config(EcholonChat) hidecategories(Navigation, Movement, Collision);

// Constants: generated from contracts/constants.json (D2). Edit there, not here.
const CUR_CHAT_CONFIGVER = 2;

var config int ConfigVer;
var BroadcastHandler NextHandle;
var config string _Separator1;
var() config bool bBotsChat;
var config string _Separator2;
var() config array<string> PresetSentences;
var config string _Separator3;
var() config float ChatIntervalMin;
var() config float ChatIntervalMax;
var config string _Separator4;
var() config string DebugTriggerWord;

function PostBeginPlay()
{
    InitConfigDefaults();

    if (!bBotsChat)
    {
        Destroy();
        return;
    }

    NextHandle = WorldInfo.Game.BroadcastHandler;
    WorldInfo.Game.BroadcastHandler = self;

    SetTimer(GetNextChatDelay(), false, 'BotChatterTimer');
}

final function InitConfigDefaults()
{
    if (ConfigVer == CUR_CHAT_CONFIGVER)
    {
        return;
    }

    ConfigVer = CUR_CHAT_CONFIGVER;

    _Separator1 = "--- GENERAL ---";
    _Separator2 = "--- CHAT LINES ---";
    _Separator3 = "--- TIMING ---";
    _Separator4 = "--- DEBUG TRIGGER ---";

    bBotsChat = true;
    ChatIntervalMin = 30.0;
    ChatIntervalMax = 90.0;
    DebugTriggerWord = "!botchat";

    PresetSentences.Length = 0;
    PresetSentences.AddItem("Watch out, more zeds incoming!");
    PresetSentences.AddItem("Nice shot!");
    PresetSentences.AddItem("I'm low on ammo.");
    PresetSentences.AddItem("Heads up, big one coming.");
    PresetSentences.AddItem("Anyone need healing?");
    PresetSentences.AddItem("Let's stick together.");
    PresetSentences.AddItem("That was close...");
    PresetSentences.AddItem("Trader's open, grab your gear.");
    PresetSentences.AddItem("On your six!");
    PresetSentences.AddItem("Reloading!");

    SaveConfig();
}

final function float GetNextChatDelay()
{
    local float Lo, Hi;

    Lo = FMax(ChatIntervalMin, 1.0);
    Hi = FMax(ChatIntervalMax, Lo);
    return Lo + (FRand() * (Hi - Lo));
}

function UpdateSentText()
{
    if(NextHandle != None)
    {
        NextHandle.UpdateSentText();
    }
    else
    {
        super.UpdateSentText();
    }
}

final function string PickPresetSentence()
{
    if (PresetSentences.Length == 0)
    {
        return "";
    }
    return PresetSentences[Rand(PresetSentences.Length)];
}

final function bool DoBotChat()
{
    local EcholonBot B, PickedBot;
    local int NumFound, PickIndex;
    local string S;
    local PlayerController PC;

    if (WorldInfo.Game.NumBots <= 0)
    {
        return false;
    }

    NumFound = 0;
    foreach WorldInfo.AllControllers(class'EcholonBot', B)
    {
        NumFound++;
    }
    if (NumFound == 0)
    {
        return false;
    }

    PickIndex = Rand(NumFound);
    foreach WorldInfo.AllControllers(class'EcholonBot', B)
    {
        if (PickIndex == 0)
        {
            PickedBot = B;
            break;
        }
        PickIndex--;
    }
    if (PickedBot == None)
    {
        return false;
    }

    S = PickPresetSentence();
    if (S == "")
    {
        return false;
    }

    foreach WorldInfo.AllControllers(class'PlayerController', PC)
    {
        PC.TeamMessage(PickedBot.PlayerReplicationInfo, S, 'Say');
    }
    return true;
}

function BotChatterTimer()
{
    SetTimer(GetNextChatDelay(), false, 'BotChatterTimer');
    DoBotChat();
}

function bool AllowsBroadcast(Actor broadcaster, int InLen)
{
    if(NextHandle != None)
    {
        return NextHandle.AllowsBroadcast(broadcaster, InLen);
    }
    return super.AllowsBroadcast(broadcaster, InLen);
}

function BroadcastText(PlayerReplicationInfo SenderPRI, PlayerController Receiver, coerce string msg, optional name Type)
{
    if (NextHandle != None)
    {
        NextHandle.BroadcastText(SenderPRI, Receiver, msg, Type);
    }
    else
    {
        super.BroadcastText(SenderPRI, Receiver, msg, Type);
    }
}

function BroadcastLocalized(Actor Sender, PlayerController Receiver, Class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
    if (NextHandle != None)
    {
        NextHandle.BroadcastLocalized(Sender, Receiver, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
    }
    else
    {
        super.BroadcastLocalized(Sender, Receiver, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
    }
}

final function PlayerController ResolveSenderPC(Actor Sender)
{
    local Pawn P;
    local PlayerController PC;

    PC = PlayerController(Sender);
    if (PC != None)
    {
        return PC;
    }
    P = Pawn(Sender);
    if (P != None)
    {
        PC = PlayerController(P.Controller);
        if (PC != None)
        {
            return PC;
        }
    }
    return None;
}

final function CheckDebugTrigger(Actor Sender, coerce string msg, name Type)
{
    local PlayerController SenderPC;

    if (!bBotsChat || DebugTriggerWord == "")
    {
        return;
    }
    if ((Type != 'Say') && (Type != 'TeamSay'))
    {
        return;
    }
    if (Left(msg, Len(DebugTriggerWord)) ~= DebugTriggerWord)
    {
        SenderPC = ResolveSenderPC(Sender);
        if (DoBotChat())
        {
            if (SenderPC != None)
            {
                SenderPC.ClientMessage("[BotChat] Trigger received - a bot just chatted.");
            }
        }
        else if (SenderPC != None)
        {
            if (WorldInfo.Game.NumBots <= 0)
            {
                SenderPC.ClientMessage("[BotChat] Trigger received, but there are no active bots.");
            }
            else
            {
                SenderPC.ClientMessage("[BotChat] Trigger received, but no PresetSentences are configured.");
            }
        }
    }
}

function Broadcast(Actor Sender, coerce string msg, optional name Type)
{
    CheckDebugTrigger(Sender, msg, Type);

    if(NextHandle != None)
    {
        NextHandle.Broadcast(Sender, msg, Type);
    }
    else
    {
        super.Broadcast(Sender, msg, Type);
    }
}

function BroadcastTeam(Controller Sender, coerce string msg, optional name Type)
{
    CheckDebugTrigger(Sender, msg, Type);

    if (NextHandle != None)
    {
        NextHandle.BroadcastTeam(Sender, msg, Type);
    }
    else
    {
        super.BroadcastTeam(Sender, msg, Type);
    }
}

event AllowBroadcastLocalized(Actor Sender, Class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
    if(NextHandle != None)
    {
        NextHandle.AllowBroadcastLocalized(Sender, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
    }
    else
    {
        super.AllowBroadcastLocalized(Sender, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
    }
}

event AllowBroadcastLocalizedTeam(int TeamIndex, Actor Sender, Class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
    if (NextHandle != None)
    {
        NextHandle.AllowBroadcastLocalizedTeam(TeamIndex, Sender, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
    }
    else
    {
        super.AllowBroadcastLocalizedTeam(TeamIndex, Sender, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
    }
}

defaultproperties
{
}
