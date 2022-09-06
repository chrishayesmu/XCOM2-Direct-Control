class X2Effect_CommanderReinforcements_DirectControl extends X2Effect;

// Copied from ADVENT Reinforcement's X2Effect_CommanderReinforcements, and modified to apply the call-in to a specific
// location, rather than letting the reinforcement spawner choose the location.
simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject Target, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComTacticalMissionManager MissionManager;
    local Vector ReinforcementLocation;
	local ConfigurableEncounter Encounter;
	local bool bFound;
	local string DebugText;

	MissionManager = `TACTICALMISSIONMGR;
    ReinforcementLocation = ApplyEffectParameters.AbilityInputContext.TargetLocations[0];

	foreach MissionManager.ConfigurableEncounters(Encounter)
	{
		if (class'X2Effect_CommanderReinforcements'.default.ReinforcementsID == Encounter.EncounterID)
		{
			bFound = true;
			break;
		}

		DebugText = DebugText $ Encounter.EncounterID $ "\n";
	}

	if (bFound)
	{
		class'XComGameState_AIReinforcementSpawner'.static.InitiateReinforcements(class'X2Effect_CommanderReinforcements'.default.ReinforcementsID,
                                                                                  /* OverrideCountdown */,
                                                                                  /* OverrideTargetLocation */ true,
                                                                                  ReinforcementLocation,
                                                                                  /* IdealSpawnTilesOffset */,
                                                                                  NewGameState);
	}
	else
	{
		`Log("Failed to find EncounterID:" @ class'X2Effect_CommanderReinforcements'.default.ReinforcementsID @ "\nValid EncounterIDs:\n" @ DebugText);
	}
}