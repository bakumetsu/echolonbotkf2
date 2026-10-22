// Player controller used only in playtest mode (EcholonMut swaps it in from InitMutator when the map URL
// has ?Playtest=1). Stock spectating cannot target bots (KFGameInfo.CanSpectate wants a PlayerController
// owner), so the spectator keys are routed to the mutator instead:
// left click = previous bot, right click = next bot, camera-mode key (middle click) = first/third person.
class EcholonSpectatorPC extends KFPlayerController;

var transient EcholonMut PlaytestMut;

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

state Spectating
{
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
