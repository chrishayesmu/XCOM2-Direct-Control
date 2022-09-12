class XGAIPlayer_TheLost_DirectControlMCO extends XGAIPlayer_TheLost;

function Init(bool bLoading = false)
{
    super.Init(bLoading);

    // In case we're loading a save made during a Lost turn, we need to set the controlling team
    if (class'DirectControlUtils'.static.GetActivePlayer().TeamFlag == eTeam_TheLost && class'DirectControlUtils'.static.IsLocalPlayer(eTeam_TheLost))
    {
        class'DirectControlUtils'.static.SetControllingPlayerTeam(eTeam_TheLost);
    }
}

simulated function OnBeginTurnVisualized(int InitiativeObjectID)
{
	local array<int> GroupMemberIDs;
	local XComGameState_AIGroup GroupState;

    // Logic copied from XGPlayer.OnBeginTurnVisualized: don't change controllers until we have a group ready to use, because that tends
    // to break a lot of things, including unit visibility and fog of war
	GroupState = XComGameState_AIGroup(`XCOMHISTORY.GetGameStateForObjectID(InitiativeObjectID));

	if ( (GroupState != None && GroupState.bSummoningSicknessCleared && GroupState.GetLivingMembers(GroupMemberIDs)) || `REPLAY.bInTutorial )
    {
        if (class'DirectControlUtils'.static.IsLocalPlayer(eTeam_TheLost))
        {
            class'DirectControlUtils'.static.SetControllingPlayerTeam(eTeam_TheLost);
        }
    }

    super.OnBeginTurnVisualized(InitiativeObjectID);
}

/// <summary>
/// Called by the rules engine each time it evaluates whether any units have available actions "ActionsAvailable()".
///
///The passed-in Unit state is not used by the AI player. Instead, it works from a list of units which are available to perform actions. The list only
///contains units which have available actions. In each call to 'OnUnitActionPhase_ActionsAvailable', the first element in the list is removed and
///processed. Processing the element entails running that unit's behavior logic which should submit an action to the tactical rule set.
///
///This process whittles the list of units to move down to 0. When the list reaches zero it means that all the AI units have had a chance to run
///their behavior logic, and the DecisionIteration variable is incremented. At this point, the list of units to move is repopulated based on the
///current state of the game and the process repeats.
///
///The process will repeat until either no units remain which can take moves or the iteration count climbs too high. If the iteration count climbs too
///hight it indicates that there are errors in the action logic which are allowing actions to be used indefinitely.
/// </summary>
/// <param name="bWithAvailableActions">The first unit state with available actions</param>
simulated function OnUnitActionPhase_ActionsAvailable(XComGameState_Unit UnitState)
{
	local GameRulesCache_Unit DummyCachedActionData;
	local XComGameState_Unit CheatUnitState;

	if (m_bSkipAI)
	{
		EndTurn(ePlayerEndTurnType_AI);
		return;
	}

	// Cheat to force only a specific unit to run their behavior this turn.  Everyone else skips their turn.
	if (`CHEATMGR != None && `CHEATMGR.SkipAllAIExceptUnitID > 0)
	{
		CheatUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(`CHEATMGR.SkipAllAIExceptUnitID));

		if (!(CheatUnitState.bRemovedFromPlay
			|| CheatUnitState.IsDead()
			|| CheatUnitState.IsUnconscious()
			|| CheatUnitState.IsBleedingOut()
			|| CheatUnitState.IsStasisLanced()
			|| CheatUnitState.bDisabled)
			&& CheatUnitState.NumAllActionPoints() > 0)
		{
			DummyCachedActionData.UnitObjectRef.ObjectID = `CHEATMGR.SkipAllAIExceptUnitID;
			UnitsToMove.Length = 0;
			UnitsToMove.AddItem(DummyCachedActionData);
			TryBeginNextUnitTurn();
		}
		else
		{
			EndTurn(ePlayerEndTurnType_AI);
			return;
		}
	}

	if (m_ePhase != eAAP_SequentialMovement && UnitsToMove.Length == 0)
	{
		++DecisionIteration;
		GatherUnitsToMove();
	}

	if (UnitsToMove.Length == 0 && !IsScampering())
	{
        // The Lost turn overlay normally won't hide, but it's blocking the ability bar
        if (`PRES.m_kTurnOverlay.IsShowingTheLostTurn())
        {
            SetTimer(2.0f, /* inBLoop */ false, 'HideTheLostTurn', `PRES.m_kTurnOverlay);
        }

		super.OnUnitActionPhase_ActionsAvailable(UnitState); //Pretend we are a normal human player
		return;
	}

    if (!`PRES.m_kTurnOverlay.IsShowingTheLostTurn())
    {
        `PRES.m_kTurnOverlay.ShowTheLostTurn();
    }

	TryBeginNextUnitTurn();
}

simulated function OnUnitActionPhaseFinished_NextPlayer()
{
	`DC_LOG("OnUnitActionPhaseFinished_NextPlayer: setting team to XCOM");
	class'DirectControlUtils'.static.SetControllingPlayerTeam(eTeam_XCom);
}

simulated function GatherUnitsToMove()
{
    local bool bCachedAllowSelectAll;
    local int Index;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
    bCachedAllowSelectAll = `CHEATMGR.bAllowSelectAll;

    // We want to use the superclass method to decide how to move unactivated pods, but it will just return immediately
    // if bAllowSelectAll is on, so quickly toggle it off first
    `CHEATMGR.bAllowSelectAll = false;
    super.GatherUnitsToMove();
    `CHEATMGR.bAllowSelectAll = bCachedAllowSelectAll;

    // If the player isn't controlling this team, then we're done; let the AI handle it from here
    if (!class'DirectControlUtils'.static.IsLocalPlayer(eTeam_TheLost))
    {
        return;
    }

    for (Index = 0; Index < UnitsToMove.Length; Index++)
    {
        UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitsToMove[Index].UnitObjectRef.ObjectID));

        // Remove any active AI so that the player can move them
        if (class'DirectControlUtils'.static.IsPlayerControllingUnit(UnitState))
        {
            UnitsToMove.Remove(Index, 1);
            Index--;
        }
    }
}