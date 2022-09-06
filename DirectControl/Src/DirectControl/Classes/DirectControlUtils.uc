class DirectControlUtils extends Object
    abstract;

static function XComGameState_Player GetActivePlayer()
{
	local XComGameStateHistory History;
	local XComGameStateContext_TacticalGameRule Context;
	local StateObjectReference PlayerRef;

	History = `XCOMHISTORY;

    // Iterate history looking for the most recent turn begin
	foreach History.IterateContextsByClassType(class'XComGameStateContext_TacticalGameRule', Context)
	{
		if (Context.GameRuleType == eGameRule_PlayerTurnBegin)
		{
			PlayerRef = Context.PlayerRef;
            break;
		}
	}

    return XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(PlayerRef.ObjectID));
}

static function XComGameState_Player GetPlayerForTeam(ETeam TeamFlag)
{
	local XComGameStateHistory History;
	local XComGameStateContext_TacticalGameRule Context;
    local XComGameState_Player PlayerState;
	local StateObjectReference PlayerRef;

	History = `XCOMHISTORY;

    // Iterate history to get the most recent state for the given player team
	foreach History.IterateContextsByClassType(class'XComGameStateContext_TacticalGameRule', Context)
	{
		if (Context.GameRuleType == eGameRule_PlayerTurnBegin)
		{
			PlayerRef = Context.PlayerRef;

            PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(PlayerRef.ObjectID));

            if (PlayerState.TeamFlag == TeamFlag)
            {
                return PlayerState;
            }
		}
	}

	return none;
}

static function bool IsLocalPlayer(ETeam TeamFlag)
{
    switch (TeamFlag)
    {
        case eTeam_XCom:
            return true;
        case eTeam_Alien:
            return `DC_CFG(bPlayerControlsAlienTurn);
        case eTeam_TheLost:
            return `DC_CFG(bPlayerControlsLostTurn);
        default:
            return false;
    }
}

// Function copied from the XCOM 2 subreddit wiki
static final function bool IsModActive(name ModName)
{
    local XComOnlineEventMgr    EventManager;
    local int                   Index;

    EventManager = `ONLINEEVENTMGR;

    for (Index = EventManager.GetNumDLC() - 1; Index >= 0; Index--)
    {
        if (EventManager.GetDLCNames(Index) == ModName)
        {
            return true;
        }
    }

    return false;
}

static function bool IsUnitSpawnedAsReinforcements(int UnitObjectID)
{
	local XComGameStateHistory History;
    local XComGameStateContext_ChangeContainer Context;
	local XComGameState_AIUnitData AIUnitData;

	History = `XCOMHISTORY;

    foreach History.IterateContextsByClassType(class'XComGameStateContext_ChangeContainer', Context,, true)
    {
        if (Context.ChangeInfo == class'XComGameState_AIReinforcementSpawner'.default.SpawnReinforcementsCompleteChangeDesc)
        {
            // check if this change spawned our units
            foreach Context.AssociatedState.IterateByClassType(class'XComGameState_AIUnitData', AIUnitData)
            {
                if (AIUnitData.m_iUnitObjectID == UnitObjectID)
                {
                    return true;
                }
            }
        }
    }

    return false;
}