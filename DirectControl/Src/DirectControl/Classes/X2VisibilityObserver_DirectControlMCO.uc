class X2VisibilityObserver_DirectControlMCO extends X2VisibilityObserver;

/// <summary>
/// Called when an active visualization system becomes idle. At the moment this is a catch all that is supposed to fix up any incorrect visibility
/// state on the pawns and visualizers. We are going to want to move away from this approach and let the individual visualizers do this, but this can
/// remain as a validation step to warn when the game state and visualizer disagree.
/// </summary>
event OnVisualizationIdle()
{
	local X2TacticalGameRuleset Ruleset;
	local array<StateObjectReference> Viewers;
	local int IndexViewers;
	local X2GameRulesetVisibilityInterface ViewerOfTarget;
	local int LocalPlayerID;
	local XComGameStateHistory History;
	local Actor Visualizer;
	local XComGameState_BaseObject TargetState;
	local X2GameRulesetVisibilityInterface TargetInterface;
	local bool bAnyLocalViewers;
	local XComGameState_Unit UnitState;
	local bool bIsUnitStateRemovedFromPlay;
	local GameRulesCache_VisibilityInfo VisInfo;

	Ruleset = `TACTICALRULES;
	History = `XCOMHISTORY;

	LocalPlayerID = Ruleset.GetLocalClientPlayerObjectID();

	foreach History.IterateByClassType(class'XComGameState_BaseObject', TargetState)
	{
		TargetInterface = X2GameRulesetVisibilityInterface(TargetState);
		if (TargetInterface != none)
		{
			UnitState = XComGameState_Unit(TargetState);
			Visualizer = History.GetGameStateForObjectID(TargetState.ObjectID).GetVisualizer();

			bAnyLocalViewers = UnitState != none && class'X2TacticalVisibilityHelpers'.static.IsUnitAlwaysVisibleToLocalPlayer(UnitState);

			if(bAnyLocalViewers == false)
			{
				if(!Ruleset.VisibilityMgr.GetVisibilityInfo(TargetState.ObjectID, TargetState.ObjectID, VisInfo, -1))
				{
					//This visualizer is unknown to the visibility system, yet has a visibility interface. This shouldn't be happening, but right now is relegated to demo direct mode so
					//isn't too serious... default these to visible
					bAnyLocalViewers = true;
				}
				else
				{
					Viewers.Length = 0;
					Ruleset.VisibilityMgr.GetAllViewersOfTarget(TargetState.ObjectID, Viewers, class'XComGameState_BaseObject', -1, class'X2TacticalVisibilityHelpers'.default.LivingGameplayVisibleFilter);
					for(IndexViewers = 0; IndexViewers < Viewers.Length; ++IndexViewers)
					{
						ViewerOfTarget = X2GameRulesetVisibilityInterface(History.GetGameStateForObjectID(Viewers[IndexViewers].ObjectID));
						if(LocalPlayerID == ViewerOfTarget.GetAssociatedPlayerID())
						{
							if(Visualizer != none)
							{
								bAnyLocalViewers = true;
								break;
							}
						}
					}
				}
			}

			if (Visualizer != none)
			{
				// Check to see if this is a XComGameState_Unit and do unit specific processing
				bIsUnitStateRemovedFromPlay = false;

				if (UnitState != none)
				{
					if (UnitState.bRemovedFromPlay || UnitState.bRemoved)
					{
						bIsUnitStateRemovedFromPlay = true;
					}
				}

                // DC: don't automatically show all units when bAllowSelectAll is enabled
				if(!bIsUnitStateRemovedFromPlay && TargetInterface.ForceModelVisible() != eForceNotVisible &&
					(bAnyLocalViewers || (TargetInterface.ForceModelVisible() == eForceVisible)))
				{
					Visualizer.SetVisibleToTeams(eTeam_All);
				}
				else
				{
					Visualizer.SetVisibleToTeams(eTeam_None);
				}
			}
		}
	}
}

/// <summary>
/// Called by visualizer code when it decides that an entity should re-evaluate its visibility situation
/// </summary>
event VisualizerUpdateVisibility(Actor Visualizer, out TTile NewTile)
{
	local FOWTileStatus TileStatus;
	local BYTE GameplayFlags;
	local X2VisualizerInterface VisualizerInterface;
	local X2GameRulesetVisibilityInterface VisibilityViewerInterface;
	local XComGameState_BaseObject GameStateObject;
	local EForceVisibilitySetting ForcedVisible;

	VisualizerInterface = X2VisualizerInterface(Visualizer);
	if (VisualizerInterface != none)
	{
		GameStateObject = `XCOMHISTORY.GetGameStateForObjectID(VisualizerInterface.GetVisualizedStateReference().ObjectID);
		VisibilityViewerInterface = X2GameRulesetVisibilityInterface(GameStateObject);

		if (VisibilityViewerInterface != none)
		{
			ForcedVisible = VisibilityViewerInterface.ForceModelVisible();
		}
	}

    // DC: don't force units to be visible when bAllowSelectAll is true
	if (ForcedVisible == eForceVisible)
	{
		Visualizer.SetVisibleToTeams(eTeam_All);
	}
	else if (ForcedVisible == eForceNotVisible)
	{
		Visualizer.SetVisibleToTeams(eTeam_None);
	}
	else
	{
		`XWORLD.GetTileFOWValue(NewTile, TileStatus, GameplayFlags);

		if (TileStatus == eFOWTileStatus_Seen)
		{
			if (GameplayFlags != 0)
			{
				Visualizer.SetVisibleToTeams(eTeam_All);
			}
			else
			{
				Visualizer.SetVisibleToTeams(eTeam_None);
			}
		}
		else
		{
			Visualizer.SetVisibleToTeams(eTeam_None);
		}
	}
}
