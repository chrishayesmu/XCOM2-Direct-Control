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

/// <summary>
/// Checks whether the specified team has had a turn yet in this battle.
/// </summary>
static function bool HasTeamHadATurn(ETeam TeamFlag)
{
    local XComGameStateHistory History;
    local XComGameStateContext_TacticalGameRule Context;
    local XComGameState_Player PlayerState;

    History = `XCOMHISTORY;

    // Iterate history looking for a turn begin for the given team
    foreach History.IterateContextsByClassType(class'XComGameStateContext_TacticalGameRule', Context)
    {
        if (Context.GameRuleType != eGameRule_PlayerTurnBegin)
        {
            continue;
        }

        PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(Context.PlayerRef.ObjectID));

        if (PlayerState.TeamFlag == TeamFlag)
        {
            return true;
        }
    }

    return false;
}

static function bool IsLocalPlayer(ETeam TeamFlag)
{
    switch (TeamFlag)
    {
        case eTeam_XCom:
            return true;
        case eTeam_Alien:
            return `DC_CFG(bPlayerControlsAlienTurn);
        case eTeam_Resistance:
            return `DC_CFG(bPlayerControlsResistanceTurn);
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

static function bool IsPlayerControllingUnit(XComGameState_Unit UnitState)
{
    if (!IsLocalPlayer(UnitState.GetTeam()))
    {
        return false;
    }

    if (UnitState.IsUnrevealedAI())
    {
        switch (UnitState.GetTeam())
        {
            case eTeam_Alien:
                return `DC_CFG(bPlayerControlsUnactivatedAliens);
            case eTeam_Resistance:
                return `DC_CFG(bPlayerControlsUnactivatedResistance);
            case eTeam_TheLost:
                return `DC_CFG(bPlayerControlsUnactivatedLost);
            default:
                return false;
        }
    }

    return true;
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

/// <summary>
/// Checks whether a unit is, at this moment, in the process of spawning as reinforcements. If the turn has changed
/// since spawning, they are not considered to be currently spawning.
/// </summary>
static function bool IsUnitSpawningAsReinforcements(int UnitObjectID)
{
    local XComGameStateHistory History;
    local XComGameStateContext_ChangeContainer Context, ReinforcementContext;
    local XComGameStateContext_TacticalGameRule GameRuleContext;
    local XComGameState_AIUnitData AIUnitData;

    History = `XCOMHISTORY;

    // Look for a reinforcement game state containing our unit
    foreach History.IterateContextsByClassType(class'XComGameStateContext_ChangeContainer', Context,, true)
    {
        if (Context.ChangeInfo == class'XComGameState_AIReinforcementSpawner'.default.SpawnReinforcementsCompleteChangeDesc)
        {
            // check if this change spawned our units
            foreach Context.AssociatedState.IterateByClassType(class'XComGameState_AIUnitData', AIUnitData)
            {
                if (AIUnitData.m_iUnitObjectID == UnitObjectID)
                {
                    ReinforcementContext = Context;
                    break;
                }
            }
        }

        if (ReinforcementContext != none)
        {
            break;
        }
    }

    if (ReinforcementContext == none)
    {
        return false;
    }

    // Now see if there's any start-of-turn contexts which come after our reinforcement context
    foreach History.IterateContextsByClassType(class'XComGameStateContext_TacticalGameRule', GameRuleContext,, true)
    {
        // Stop iterating once we've predated our reinforcement spawn event
        if (GameRuleContext.EventChainStartIndex < ReinforcementContext.EventChainStartIndex)
        {
            break;
        }

        if (GameRuleContext.GameRuleType == eGameRule_PlayerTurnBegin)
        {
            // Some reinforcements spawn at the start of the enemy turn; if these events are in the same chain, then the unit is currently
            // spawning as reinforcements, otherwise they spawned on an earlier turn
            return GameRuleContext.EventChainStartIndex == ReinforcementContext.EventChainStartIndex;
        }
    }

    return true;
}

static function bool PodSpawnContainsChosen(PodSpawnInfo SpawnInfo)
{
    local name CharName;
    local XGUnit Unit;
    local XComGameStateHistory History;
    local XComGameState_Unit UnitState;

    History = `XCOMHISTORY;

    if (SpawnInfo.Team != eTeam_Alien)
    {
        return false;
    }

    foreach SpawnInfo.SpawnedPod.m_arrMember(Unit)
    {
        UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Unit.ObjectID));

        if (UnitState.IsChosen())
        {
            return true;
        }
    }

    foreach SpawnInfo.SelectedCharacterTemplateNames(CharName)
    {
        switch (CharName)
        {
            case 'ChosenAssassin':
            case 'ChosenAssassinM2':
            case 'ChosenAssassinM3':
            case 'ChosenAssassinM4':
            case 'ChosenSniper':
            case 'ChosenSniperM2':
            case 'ChosenSniperM3':
            case 'ChosenSniperM4':
            case 'ChosenWarlock':
            case 'ChosenWarlockM2':
            case 'ChosenWarlockM3':
            case 'ChosenWarlockM4':
                return true;
        }
    }

    return false;
}

static function SetControllingPlayerTeam(ETeam TeamFlag)
{
    local XComTacticalController kLocalPC;
    local XComGameState_Player PlayerState;

    `DC_LOG("Setting controlling player team to " $ TeamFlag);

    PlayerState = GetPlayerForTeam(TeamFlag);

    `CHEATMGR.bAllowSelectAll = TeamFlag != eTeam_XCom;

    kLocalPC = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
    kLocalPC.SetControllingPlayer(PlayerState);
    kLocalPC.SetTeamType(PlayerState.TeamFlag);
}