class U005 extends Actor;

state Waiting
{
Begin:
    GotoState('Idle');
Other:
    Stop;
}

state Idle
{
}
