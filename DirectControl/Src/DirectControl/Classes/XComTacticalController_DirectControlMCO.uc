class XComTacticalController_DirectControlMCO extends XComTacticalController;

/// <summary>
/// Out of a list of units eligible for selection, selects the one that is immediately next in the list to the currently selected unit in the specified direction
/// </summary>
simulated function bool Visualizer_CycleToNextAvailableUnit(int Direction)
{
	local array<XComGameState_Unit> EligibleUnits;
	local XComGameState_Unit SelectNewUnit;
	local XComGameState_Unit CurrentUnit;
	local bool bActionsAvailable;
	local int NumGroupMembers, MemberIndex, CurrentUnitIndex;
	local X2TacticalGameRuleset TacticalRules;

	if (`TUTORIAL != none)
	{
		// Disable unit cycling in tutorial
		return false;
	}

	TacticalRules = `TACTICALRULES;

    // DC: base logic is to allow control of all units if bAllowSelectAll is set; we always allow control
    // of the active player's units, and use event listeners to change who the controlled player is instead
    ControllingPlayerVisualizer.GetUnits(EligibleUnits, , true);

	// Not allowed to switch if the currently controlled unit is being forced to take an action next
	CurrentUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ControllingUnit.ObjectID));

	if (CurrentUnit != none && CurrentUnit.ReflexActionState == eReflexActionState_SelectAction )
	{
		return false;
	}

	NumGroupMembers = EligibleUnits.Length;

	CurrentUnitIndex = Clamp(EligibleUnits.Find(CurrentUnit), 0, NumGroupMembers - 1);

	for (MemberIndex = 1; MemberIndex < NumGroupMembers; ++MemberIndex)
	{
		SelectNewUnit = EligibleUnits[(NumGroupMembers + CurrentUnitIndex + MemberIndex * Direction) % NumGroupMembers];

        // TODO: alien units get actions in some sort of pod-dependent order, find that
		bActionsAvailable = TacticalRules.UnitHasActionsAvailable(SelectNewUnit);

        // DC: removed logic here which would allow selecting units even with no action points if bAllowSelectAll is set

		if (bActionsAvailable && Visualizer_SelectUnit(SelectNewUnit))
		{
			return true;
		}
	}

	return false;
}

/// <summary>
/// This method informs the controller that it needs to give up control over units. Usually done as a result
/// of a player finishing their unit actions phase.
/// </summary>
simulated function Visualizer_ReleaseControl()
{
	local array<XComGameState_Unit> Units;
	local int CurrentSelectedIndex;

	// Mark all units we control as inactive
	ControllingPlayerVisualizer.GetUnits(Units);
	for( CurrentSelectedIndex = 0; CurrentSelectedIndex < Units.Length; ++CurrentSelectedIndex )
	{
		XGUnit(Units[CurrentSelectedIndex].GetVisualizer()).GotoState('Inactive');
	}

	// DC: remove logic for changing the input state based on the team; unneeded for us

	// Resetting this to 0 stops the ability containers getting updated for a unit that is just going to be switched off of again
	ControllingUnit.ObjectID = 0;

	GetPres().UpdateConcealmentShader(true);
}

/// <summary>
/// This method marks the indicated unit state's visualizer as 'active'. This is a purely visual designation,
/// guiding the Unit's 3d UI, camera behavior, etc.
/// Returns true if the unit could be selected
/// </summary>
simulated function bool Visualizer_SelectUnit(XComGameState_Unit SelectedUnit)
{
	//local GameRulesCache_Unit OutCacheData;
	local XComGameState_Player PlayerState;
	local XGPlayer PlayerVisualizer;
	local XCom3DCursor kCursor;
	local bool bUnitWasAlreadySelected;

	if (SelectedUnit.GetMyTemplate().bNeverSelectable) //Somewhat special-case handling Mimic Beacons, which need (for gameplay) to appear alive and relevant
	{
		return false;
	}

	if( SelectedUnit.GetMyTemplate().bIsCosmetic ) //Cosmetic units are not allowed to be selected
	{
		return false;
	}

	if (SelectedUnit.ControllingPlayerIsAI())
	{
		// Update concealment markers when AI unit is selected because the PathingPawn is hidden and concealment tiles won't update so it remains visible
		m_kPathingPawn.UpdateConcealmentTiles();
	}

    // DC: don't allow selecting panicked units even when bAllowSelectAll is true
	if (SelectedUnit.bPanicked) //Panicked units are not allowed to be selected
		return false;

	//Dead, unconscious, and bleeding-out units should not be selectable.
	if (SelectedUnit.IsDead() || SelectedUnit.IsIncapacitated())
		return false;

	if(!`TACTICALRULES.AllowVisualizerSelection())
		return false;

	bUnitWasAlreadySelected = (SelectedUnit.ObjectID == ControllingUnit.ObjectID);

	`PRES.ShowFriendlySquadStatistics();

	PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(SelectedUnit.ControllingPlayer.ObjectID));
	PlayerVisualizer = XGPlayer(PlayerState.GetVisualizer());

	//@TODO - rmcfall - twiddling the old game play code to make it behave. Should the visualizer have this state?
	if( ControllingUnitVisualizer != none )
	{
		ControllingUnitVisualizer.Deactivate();
	}

	bJustSwitchedUnits = true;
	//Set our local cache variables for tracking what unit is selected
	ControllingUnit = SelectedUnit.GetReference();
	ControllingUnitVisualizer = XGUnit(SelectedUnit.GetVisualizer());

	//Support legacy variables
	m_kActiveUnit = ControllingUnitVisualizer;

	// Set the bFOWTextureBufferIsDirty to be true
	`XWORLD.bFOWTextureBufferIsDirty = true;

	//@TODO - rmcfall - evaluate whether XGPlayer should be involved with selection
	PlayerVisualizer.SetActiveUnit( XGUnit(SelectedUnit.GetVisualizer()) );

	//@TODO - rmcfall - the system here is twiddling the old game play code to make it behavior. Think about a better way to interact with the UI / Input.
	if(`XENGINE.IsMultiplayerGame())
	{
		// TTP#394: multiplayer games cannot pass true in as it will set the input state to active for the non controlling player.
		SetInputState('ActiveUnit_Moving', false); //Sets the state of XComTacticalInput, which maps mouse/kb/controller inputs to game engine methods
	}
	else
	{
		SetInputState('ActiveUnit_Moving', true); //Sets the state of XComTacticalInput, which maps mouse/kb/controller inputs to game engine methods
	}
	ControllingUnitVisualizer.GotoState('Active'); //The unit visualizer 'Active' state enables pathing ( adds an XGAction_Path ), displays cover icons, etc.
	kCursor = XCom3DCursor( Pawn );
	kCursor.MoveToUnit( m_kActiveUnit.GetPawn() );
	m_bChangedUnitHasntMovedCursor = true;
	kCursor.SetPhysics( PHYS_Flying );
	//kCursor.SetCollision( false, false );
	kCursor.bCollideWorld = false;
	if(GetStateName() != 'PlayerWalking' && GetStateName() != 'PlayerDebugCamera')
	{
		GotoState('PlayerWalking');
	}

	// notify the visualization manager that the unit changed so that UI etc. listeners can update themselves.
	// all of the logic above us should eventually be refactored to operate off of this callback
	`XCOMVISUALIZATIONMGR.NotifyActiveUnitChanged(SelectedUnit);

	// Check to trigger any tutorial moment events when selecting a new unit
	CheckForTutorialMoments(SelectedUnit);

	if( !bUnitWasAlreadySelected )
	{
		SelectedUnit.DisplayActionPointInfoFlyover();
	}

	return true;
}