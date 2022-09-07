class XComTacticalSoundManager_DirectControlMCO extends XComTacticalSoundManager;

function EvaluateTacticalMusicState()
{
	local X2TacticalGameRuleset Ruleset;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XGUnit Unit;
	local XComGameState_Player LocalPlayerState;
	local XComGameState_Player PlayerState;
	local int NumAlertedEnemiesPrevious;
	local int NumSpecialUnitsPrevious;
	local int NumSpecialUnitsEngagedPrevious;
	local name MusicDynamicOverrideSwitch;

	Ruleset = `TACTICALRULES;
	History = `XCOMHISTORY;

	//Get the game state representing the local player
    // DC: our local player changes all the time and breaks things. We just use the XCOM player and accept that this would
    // break multiplayer; it's probably far from the only thing in DC that does so.
	LocalPlayerState = class'DirectControlUtils'.static.GetPlayerForTeam(eTeam_XCom);

	//Sync our internally tracked count of alerted enemies with the state of the game
	NumAlertedEnemiesPrevious = NumAlertedEnemies;
	NumAlertedEnemies = 0;

	//Sync internal Chosen counts with the state of the game
	NumSpecialUnitsPrevious = NumSpecialUnits;
	NumSpecialUnitsEngagedPrevious = NumSpecialUnitsEngaged;
	NumSpecialUnits = 0;
	NumSpecialUnitsEngaged = 0;

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		//Discover whether this unit is an enemy
		PlayerState = XComGameState_Player(History.GetGameStateForObjectID(UnitState.GetAssociatedPlayerID()));
		if (PlayerState != none && LocalPlayerState.IsEnemyPlayer(PlayerState) && PlayerState.TeamFlag != eTeam_Neutral)
		{
			//If the enemy unit is higher than green alert (hunting or fighting),
			// Changed to only trigger on red alert.  Yellow alert can happen too frequently for cases of not being sighted. (Jumping through window, Protect Device mission)
			// Also, Terror missions the aliens are killing civilians while in green alert, this way combat music is purely a they have seen you case.

			//Get the currently visualized state for this unit (so we don't read into the future)
			Unit = XGUnit(UnitState.GetVisualizer());

			if (Unit != none)
			{
				UnitState = Unit.GetVisualizedGameState();

				if (UnitState != none && UnitState.IsAlive())
				{
					if (UnitState.GetCurrentStat(eStat_AlertLevel) > 1)
					{
						++NumAlertedEnemies;
					}

					DetermineSpecialUnitMusicState(UnitState, MusicDynamicOverrideSwitch);
				}
			}
		}
	}

	if (NumAlertedEnemiesPrevious > 0 && NumAlertedEnemies == 0)
	{
		//Transition out of combat
		SetSwitch('TacticalCombatState', 'Explore');

		// Select the music set when transitioning from combat to explore and not the other way so that it's only set
		// once per explore-combat cycle and so that explore and combat music pieces that need to match can do so
		SelectRandomTacticalMusicSet();
	}
	else if (NumAlertedEnemiesPrevious == 0 && NumAlertedEnemies > 0)
	{
		//Transition into combat
		SetSwitch('TacticalCombatState', 'Combat');

		// No need to select a random music set here because this is done when starting ambience and when transitioning from combat to explore
		NumCombatEvents++;

		if (NumCombatEvents == 1)
		{
			foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
			{
				Unit = XGUnit(UnitState.GetVisualizer());

				if (Unit != None && Unit.m_eTeam == eTeam_Neutral)
				{
					Unit.IdleStateMachine.CheckForStanceUpdate();
				}
			}
		}
	}

	// Set special unit switches and states in Wwise
	if (NumSpecialUnits == 1)
	{
		if (NumSpecialUnitsPrevious != 1
			|| (NumSpecialUnitsEngagedPrevious != 1 && NumSpecialUnitsEngaged == 1)
			|| bFirstEvalOnLoad)
		{
			SetSwitch('TacticalMusicDynamicOverride', MusicDynamicOverrideSwitch);
		}
	}
	else if (NumSpecialUnitsPrevious == 1)
	{
		SetSwitch('TacticalMusicDynamicOverride', 'NoDynamicOverride');

		if (bFirstEvalOnLoad)
		{
			// This Wwise state is used by animsets and matinees to time music transitions
			SetState('SpecialUnitRevealed', 'false');
		}
	}

	if (bFirstEvalOnLoad)
	{
		bFirstEvalOnLoad = false;
	}
}