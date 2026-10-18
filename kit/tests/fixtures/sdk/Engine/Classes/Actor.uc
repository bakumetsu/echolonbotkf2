class Actor extends Object native;

const MAX_THING = 4;

var float LifeSpan;

native final function SetTimer(float InRate, optional bool inbLoop, optional Name inTimerFunc='Timer', optional Object inObj);
native final iterator function AllActors(class<Actor> BaseClass, out Actor A);
event Destroyed();
