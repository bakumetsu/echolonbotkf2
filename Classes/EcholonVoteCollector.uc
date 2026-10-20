// Skip-trader vote that counts human players only (playtest request, 2026-10-19).
// Stock KFVoteCollector counts every player record, bots included; bots never vote, so a vote
// started with bots in the game could only pass on its timer, if at all. EcholonMut installs this
// collector unless bBotsCountInSkipTraderVote is set.
class EcholonVoteCollector extends KFVoteCollector within KFGameReplicationInfo;

// Players who can vote: not spectators, not zed players, not bots.
// Echolon bots clear PRI.bBot (EcholonBotBase.InitPlayerReplicationInfo), so bBot alone counts them
// as humans; a human's PRI is owned by a PlayerController, a bot's by its AI controller.
function int CountHumanVoters()
{
	local array<KFPlayerReplicationInfo> PRIs;
	local int i, Count;

	GetKFPRIArray(PRIs, , false);
	for (i = 0; i < PRIs.Length; i++)
	{
		if (PRIs[i] != None && !PRIs[i].bBot && PlayerController(PRIs[i].Owner) != None)
		{
			Count++;
		}
	}
	return Count;
}

function bool ShouldConcludeSkipTraderVote()
{
	local int NumHumans;

	NumHumans = CountHumanVoters();
	return (NumHumans > 0 && (YesVotes + NoVotes >= NumHumans || NoVotes > 0));
}

// Stock ConcludeVoteSkipTrader with the pass rule counting humans only.
reliable server function ConcludeVoteSkipTrader()
{
	local array<KFPlayerReplicationInfo> PRIs;
	local int i, NumHumans;
	local KFGameInfo KFGI;

	KFGI = KFGameInfo(WorldInfo.Game);

	if (bIsSkipTraderVoteInProgress)
	{
		GetKFPRIArray(PRIs, , false);
		for (i = 0; i < PRIs.Length; i++)
		{
			if (PRIs[i] != None)
			{
				PRIs[i].HideSkipTraderVote();
			}
		}

		NumHumans = CountHumanVoters();
		SetTimer(0.f, true, nameof(UpdateTimer), self);

		if (NoVotes > 0)
		{
			bIsFailedVoteTimerActive = true;
			SetTimer(KFGI.TimeBetweenFailedVotes, false, nameof(ClearFailedVoteFlag), self);
			KFGI.BroadcastLocalized(KFGI, class'KFLocalMessage', LMT_SkipTraderVoteFailed);
		}
		else if (NumHumans > 0 && YesVotes >= NumHumans)
		{
			SkipTraderTime();
			ResetSkipTraderVote();
			KFGI.BroadcastLocalized(KFGI, class'KFLocalMessage', LMT_SkipTraderTimeSuccess);
		}
		else
		{
			bIsFailedVoteTimerActive = true;
			SetTimer(KFGI.TimeBetweenFailedVotes, false, nameof(ClearFailedVoteFlag), self);
			KFGI.BroadcastLocalized(KFGI, class'KFLocalMessage', LMT_SkipTraderVoteFailed);
		}

		bIsSkipTraderVoteInProgress = false;
		CurrentSkipTraderVote.PlayerPRI = None;
		CurrentSkipTraderVote.PlayerID = class'PlayerReplicationInfo'.default.UniqueId;
		YesVotes = 0;
		NoVotes = 0;
	}
}

defaultproperties
{
}
