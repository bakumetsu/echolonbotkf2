// Player controller for a spectating human: playtest mode (the human watches the bots from the start) and
// normal play (the human is dead). EcholonMut swaps it in from InitMutator. Everything that changes the stock
// behaviour sits in state Spectating, so a living player is unchanged. Stock spectating cannot target bots
// (KFGameInfo.CanSpectate wants a PlayerController owner), so the spectator keys are routed to the mutator instead:
// left click = previous bot, right click = next bot, camera-mode key (middle click) = third person ->
// first person -> free turning orbit around the bot, mouse wheel = camera distance, Space = free fly on/off.
class EcholonSpectatorPC extends KFPlayerController;

const ZOOM_MIN = 100.0;            // wheel zoom: camera distance range and step (uu)
const ZOOM_MAX = 600.0;
const ZOOM_STEP = 25.0;
const ZOOM_THIRD_PERSON_DEFAULT = 120.0;   // stock third person back offset (KFThirdPersonCameraMode OffsetMid.X)

var transient EcholonMut PlaytestMut;
var transient float LastFreeFlyToggle;   // RealTimeSeconds of the last Space toggle (debounce)
var transient float ZoomDist;            // wheel-zoomed camera distance, 0 = never zoomed (stock distances)
var transient float NextWatchCheck;      // normal play: next time the watched bot is checked
var transient array<int> SavedWheelIdx;      // PlayerInput.Bindings slots whose command SetWheelBinds replaced
var transient array<string> SavedWheelCmd;   // ...and what they were

final function EcholonMut GetPlaytestMut()
{
    local EcholonMut M;

    if (PlaytestMut == None)
    {
        foreach WorldInfo.DynamicActors(class'EcholonMut', M)
        {
            PlaytestMut = M;
            break;
        }
    }
    return PlaytestMut;
}

// Mouse wheel zoom. The wheel is bound to weapon select in KFInput.ini, which means nothing to a spectator.
// While the playtest runs, the wheel bindings are pointed at the two exec functions below in memory only
// (Input.SetBind would SaveConfig and rewrite KFInput.ini); RestoreWheelBinds puts them back before the quit.
final function SetWheelBinds()
{
    local int I;

    if (PlayerInput == None || SavedWheelIdx.Length > 0)
        return;
    for (I = 0; I < PlayerInput.Bindings.Length; I++)
    {
        if (PlayerInput.Bindings[I].Name == 'MouseScrollUp' || PlayerInput.Bindings[I].Name == 'MouseScrollDown')
        {
            SavedWheelIdx.AddItem(I);
            SavedWheelCmd.AddItem(PlayerInput.Bindings[I].Command);
            PlayerInput.Bindings[I].Command = (PlayerInput.Bindings[I].Name == 'MouseScrollUp') ? "PlaytestZoomIn" : "PlaytestZoomOut";
        }
    }
    if (GetPlaytestMut() != None)
        PlaytestMut.EchelonLog("SPECTATE_WHEEL_BIND slots=" $ string(SavedWheelIdx.Length));
}

final function RestoreWheelBinds()
{
    local int I;

    if (PlayerInput == None || SavedWheelIdx.Length == 0)
        return;
    for (I = 0; I < SavedWheelIdx.Length; I++)
    {
        if (SavedWheelIdx[I] < PlayerInput.Bindings.Length)
            PlayerInput.Bindings[SavedWheelIdx[I]].Command = SavedWheelCmd[I];
    }
    if (GetPlaytestMut() != None)
        PlaytestMut.EchelonLog("SPECTATE_WHEEL_RESTORE slots=" $ string(SavedWheelIdx.Length));
    SavedWheelIdx.Length = 0;
    SavedWheelCmd.Length = 0;
}

// Wheel up = closer, wheel down = further; third person and the free turning orbit only.
exec function PlaytestZoomIn()
{
    ZoomStep(-ZOOM_STEP);
}

exec function PlaytestZoomOut()
{
    ZoomStep(ZOOM_STEP);
}

final function ZoomStep(float Delta)
{
    if (!IsInState('Spectating') || PlayerCamera == None || GetPlaytestMut() == None
        || PlaytestMut.bPlaytestFreeFly || PlaytestMut.PlaytestCamMode == 'FirstPerson')
        return;
    if (ZoomDist <= 0.0)
        ZoomDist = (PlaytestMut.PlaytestCamMode == 'Orbit') ? PlayerCamera.FreeCamDistance : ZOOM_THIRD_PERSON_DEFAULT;
    ZoomDist = FClamp(ZoomDist + Delta, ZOOM_MIN, ZOOM_MAX);
    ApplyZoom();
    PlaytestMut.EchelonLog("PLAYTEST_CAMERA_ZOOM dist=" $ string(int(ZoomDist)));
}

// Puts ZoomDist on both cameras: the orbit camera distance and the third person back offset (scaled from the
// stock offsets). Does nothing until the wheel has been used, so the stock distances stay as they were.
final function ApplyZoom()
{
    local KFThirdPersonCamera TPCam;
    local GameThirdPersonCameraMode.ViewOffsetData Off;
    local float Scale;

    if (ZoomDist <= 0.0 || KFPlayerCamera(PlayerCamera) == None)
        return;
    PlayerCamera.FreeCamDistance = ZoomDist;
    TPCam = KFThirdPersonCamera(KFPlayerCamera(PlayerCamera).ThirdPersonCam);
    if (TPCam != None)
    {
        Off = class'KFThirdPersonCameraMode'.static.GetDefaultOffset();
        Scale = ZoomDist / ZOOM_THIRD_PERSON_DEFAULT;
        Off.OffsetHigh.X *= Scale;
        Off.OffsetMid.X *= Scale;
        Off.OffsetLow.X *= Scale;
        TPCam.SetViewOffset(Off);
    }
}

// Back to the stock camera distances (the camera objects outlive the spectating state; a living player's third
// person camera must not keep the zoom). ZoomDist is kept for the next time the human spectates.
final function ResetZoomCameras()
{
    local KFThirdPersonCamera TPCam;
    local float DefaultFreeCam;

    if (KFPlayerCamera(PlayerCamera) == None)
        return;
    DefaultFreeCam = class'KFPlayerCamera'.default.FreeCamDistance;
    PlayerCamera.FreeCamDistance = DefaultFreeCam;
    TPCam = KFThirdPersonCamera(KFPlayerCamera(PlayerCamera).ThirdPersonCam);
    if (TPCam != None)
        TPCam.SetViewOffset(class'KFThirdPersonCameraMode'.static.GetDefaultOffset());
}

event Destroyed()
{
    RestoreWheelBinds();
    super.Destroyed();
}

// Space: free fly on/off. Reached from the Jump exec in state Spectating, and from PlayerTick in case the
// key goes through PlayerInput.Jump (bPressedJump) instead; the debounce keeps both paths from cancelling out.
final function RequestFreeFlyToggle()
{
    if (WorldInfo.RealTimeSeconds - LastFreeFlyToggle < 0.3)
        return;
    LastFreeFlyToggle = WorldInfo.RealTimeSeconds;
    if (GetPlaytestMut() != None)
        PlaytestMut.PlaytestToggleFreeFly(self);
}

event PlayerTick(float DeltaTime)
{
    local Pawn Watched;

    if (IsInState('Spectating'))
    {
        if (bPressedJump)
        {
            bPressedJump = false;
            RequestFreeFlyToggle();
        }
        // Normal play (playtest mode has its own tick): move off a dead or missing watched bot, once a second.
        // A living human teammate being watched is left alone, so this only acts on a dead target or none.
        if (WorldInfo.TimeSeconds >= NextWatchCheck && GetPlaytestMut() != None && !PlaytestMut.bPlaytest
            && !PlaytestMut.bPlaytestFreeFly)
        {
            NextWatchCheck = WorldInfo.TimeSeconds + 1.0;
            Watched = Pawn(ViewTarget);
            if (Watched == None || !Watched.IsAliveAndWell())
                PlaytestMut.PlaytestStepCamera(self, 1);
        }
    }
    super.PlayerTick(DeltaTime);
}

// Stock RecieveChatMessage puts "Spectator" in front of a spectator's message, but GetChatChannel has
// already added "<Spectator>", so chat showed "Spectator <Spectator> Name: msg". Keep the channel tag only.
function RecieveChatMessage(PlayerReplicationInfo PRI, string ChatMessage, name Type, optional float MsgLifeTime)
{
    if (MyGFxHUD == None || MyGFxHUD.HudChatBox == None)
        return;

    if (PRI != None && PRI.bAdmin)
    {
        ChatMessage = class'KFLocalMessage'.default.AdminString $ ChatMessage;
        MyGFxHUD.HudChatBox.AddChatMessage(ChatMessage, class'KFLocalMessage'.default.PriorityColor);
    }
    else
    {
        MyGFxHUD.HudChatBox.AddChatMessage(ChatMessage, class'KFLocalMessage'.default.SayColor);
    }
}

state Spectating
{
    // The wheel is weapon select for a living player: it becomes the camera zoom only while spectating, and the
    // original bindings and camera distances come back when the spectating ends (respawn) or the controller goes.
    event BeginState(Name PreviousStateName)
    {
        Super.BeginState(PreviousStateName);
        SetWheelBinds();
    }

    event EndState(Name NextStateName)
    {
        RestoreWheelBinds();
        ResetZoomCameras();
        if (GetPlaytestMut() != None)
        {
            PlaytestMut.bPlaytestFreeFly = false;
            PlaytestMut.PlaytestLastWatched = None;
        }
        Super.EndState(NextStateName);
    }

    exec function Jump()
    {
        RequestFreeFlyToggle();
    }

    exec function SpectateNextPlayer()
    {
        ClearTimer(nameOf(SpectateNextPlayer));
        if (GetPlaytestMut() != None)
            PlaytestMut.PlaytestStepCamera(self, 1, true);
    }

    exec function SpectatePreviousPlayer()
    {
        ClearTimer(nameOf(SpectateNextPlayer));
        if (GetPlaytestMut() != None)
            PlaytestMut.PlaytestStepCamera(self, -1, true);
    }

    exec function SpectateChangeCamMode()
    {
        if (GetPlaytestMut() != None)
            PlaytestMut.PlaytestToggleCamMode(self);
    }
}
