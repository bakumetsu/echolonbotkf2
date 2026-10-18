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

// @STUB(M1) - legacy:KF2BotChat.GetNextChatDelay
final function float GetNextChatDelay()
{
}

// @STUB(M1) - legacy:KF2BotChat.UpdateSentText
function UpdateSentText()
{
}

// @STUB(M1) - legacy:KF2BotChat.PickPresetSentence
final function string PickPresetSentence()
{
}

// @STUB(M1) - legacy:KF2BotChat.DoBotChat
final function bool DoBotChat()
{
}

// @STUB(M1) - legacy:KF2BotChat.BotChatterTimer
function BotChatterTimer()
{
}

// @STUB(M1) - legacy:KF2BotChat.AllowsBroadcast
function bool AllowsBroadcast(Actor broadcaster, int InLen)
{
}

// @STUB(M1) - legacy:KF2BotChat.BroadcastText
function BroadcastText(PlayerReplicationInfo SenderPRI, PlayerController Receiver, coerce string msg, optional name Type)
{
}

// @STUB(M1) - legacy:KF2BotChat.BroadcastLocalized
function BroadcastLocalized(Actor Sender, PlayerController Receiver, Class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
}

// @STUB(M1) - legacy:KF2BotChat.ResolveSenderPC
final function PlayerController ResolveSenderPC(Actor Sender)
{
}

// @STUB(M1) - legacy:KF2BotChat.CheckDebugTrigger
final function CheckDebugTrigger(Actor Sender, coerce string msg, name Type)
{
}

// @STUB(M1) - legacy:KF2BotChat.Broadcast
function Broadcast(Actor Sender, coerce string msg, optional name Type)
{
}

// @STUB(M1) - legacy:KF2BotChat.BroadcastTeam
function BroadcastTeam(Controller Sender, coerce string msg, optional name Type)
{
}

// @STUB(M1) - legacy:KF2BotChat.AllowBroadcastLocalized
event AllowBroadcastLocalized(Actor Sender, Class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
}

// @STUB(M1) - legacy:KF2BotChat.AllowBroadcastLocalizedTeam
event AllowBroadcastLocalizedTeam(int TeamIndex, Actor Sender, Class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
}

defaultproperties
{
}
