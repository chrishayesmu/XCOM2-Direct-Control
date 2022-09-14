class X2Camera_FollowMouseCursor_DirectControlMCO extends X2Camera_FollowMouseCursor;

function Activated(TPOV CurrentPOV, X2Camera PreviousActiveCamera, X2Camera_LookAt LastActiveLookAtCamera)
{
	local XComGameStateHistory History;
	local XComTacticalController LocalController;
	local XComGameState_Unit ActiveUnit;
	local XCom3DCursor Cursor;
	local X2EventManager EventManager;
	local Object ThisObj;

	super(X2Camera_LookAt).Activated(CurrentPOV, PreviousActiveCamera, LastActiveLookAtCamera);

	if (PreviousActiveCamera != none)
	{
		PreviousActiveCamera.GetCameraFocusPoints(PreviousCamerasVisFocusPoints);
	}
	else
	{
		PreviousCamerasVisFocusPoints.Length = 0;
	}

	// kill any leftover scroll amount
	RemainingEdgeScroll.X = 0;
	RemainingEdgeScroll.Y = 0;

	LocalController = XComTacticalController(`BATTLE.GetALocalPlayerController());

	if (LastActiveLookAtCamera != none && LocalController != none && LocalController.bManuallySwitchedUnitsWhileVisualizerBusy == false)
	{
		// make our desired look at the same as the previous look at point, we don't do this if have just manually switched units so the lookat tranitions to the new unit
		LookAt = LastActiveLookAtCamera.GetCameraLookat();
	}

	// scroll to the currently active unit if it is offscreen and it's the human player's turn and the visualizer is idle
    // DC: change ControllingPlayerIsAI to our own version
	if(!class'XComGameStateVisualizationMgr'.static.VisualizerBusy())
	{
		History = `XCOMHISTORY;
		ActiveUnit = XComGameState_Unit(History.GetGameStateForObjectID(LocalController.GetActiveUnitStateRef().ObjectID));
		if(ActiveUnit != none
			&& !ControllingPlayerIsAI(ActiveUnit)
			&& ActiveUnit.ControllingPlayer == GetActivePlayer())
		{
			CenterOnUnitIfOffscreen(ActiveUnit);
		}
	}

	if(X2Camera_OTSTargeting(PreviousActiveCamera) != none)
	{
		// when returning from a targeting camera, snap the camera to the unit lookat from
		// the get go so we don't blend and interpolate at the same time.
		CurrentLookAt = GetCameraLookat();
	}

	// whenever we get control back, set the 3D cursor's pathing floor to be the floor we are looking at
	Cursor = `CURSOR;
	Cursor.m_iRequestedFloor = Cursor.WorldZToFloor(LookAt);
	Cursor.m_iLastEffectiveFloorIndex = Cursor.m_iRequestedFloor;

	MoveAbilitySubmitted = false;

	EventManager = `XEVENTMGR;
	ThisObj = self;
	EventManager.RegisterForEvent(ThisObj, 'CameraFocusActiveUnit', OnCameraFocusUnit, ELD_Immediate);
	EventManager.RegisterForEvent(ThisObj, 'AbilityActivated', OnAbilityActivated, ELD_Immediate, , );
	EventManager.RegisterForEvent(ThisObj, 'PlayerTurnEnded', OnTurnEnded, ELD_OnVisualizationBlockStarted, , );
	EventManager.RegisterForEvent(ThisObj, 'OnResetCamera', OnResetCamera);
}

// This function copied from FreeCameraRotation
function Deactivated() // override base class function to unsubscribe from reset cam event
{
	local Object ThisObj;

	super.Deactivated();
	ThisObj = self;
	`XEVENTMGR.UnRegisterFromEvent(ThisObj, 'OnResetCamera');
}

function GetCameraFocusPoints(out array<TFocusPoints> OutFocusPoints)
{
	local XComGameState_Player PlayerState;
	local X2TacticalGameRuleset RuleSet;
	local XComGameStateHistory History;

	Super(X2Camera_LookAt).GetCameraFocusPoints(OutFocusPoints);

	RuleSet = `TACTICALRULES;
	History = `XCOMHISTORY;
	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(RuleSet.GetCachedUnitActionPlayerRef().ObjectID));

    // DC: use our version of IsLocalPlayer
	if (PlayerState != none && !class'DirectControlUtils'.static.IsLocalPlayer(PlayerState.TeamFlag))
	{
		OutFocusPoints = PreviousCamerasVisFocusPoints;
	}
}

function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit UnitState;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != none)
	{
		if (AbilityContext.InputContext.AbilityTemplateName == 'StandardMove')
		{
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));

            // DC: change ControllingPlayerIsAI to our own version
			if (UnitState != none && !ControllingPlayerIsAI(UnitState) && UnitState.ControllingPlayer == GetActivePlayer())
			{
				// A move action was just submitted, will cause disabling of focuspointexpiry so building vis doesnt fluctuate
				//while we are waiting for the camera to switch to the follow moving unit camera
				MoveAbilitySubmitted = true;
			}
		}
	}
	return ELR_NoInterrupt;
}

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit)
{
	super(X2Camera_LookAt).OnActiveUnitChanged(NewActiveUnit);

	MoveAbilitySubmitted = false;

	if (!ControllingPlayerIsAI(NewActiveUnit))
	{
		CenterOnUnitIfOffscreen(NewActiveUnit);
		LastPlayerControlledUnit = NewActiveUnit;
	}
	else
	{
		CenterOnUnitIfOffscreen(LastPlayerControlledUnit);
	}
}

function EventListenerReturn OnCameraFocusUnit(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComTacticalController LocalController;
	local XComGameStateHistory History;
	local XComGameState_Unit ActiveUnit;

	LocalController = XComTacticalController(`BATTLE.GetALocalPlayerController());
	if(LocalController != none && !class'XComGameStateVisualizationMgr'.static.VisualizerBusy())
	{
		History = `XCOMHISTORY;
		ActiveUnit = XComGameState_Unit(History.GetGameStateForObjectID(LocalController.GetActiveUnitStateRef().ObjectID));

        // DC: change ControllingPlayerIsAI to our own version
		if(ActiveUnit != none
			&& !ControllingPlayerIsAI(ActiveUnit)
			&& ActiveUnit.ControllingPlayer == GetActivePlayer())
		{
			CenterOnUnitIfOffscreen(ActiveUnit);
		}
	}

	return ELR_NoInterrupt;
}

// This function modified from FreeCameraRotation
function ZoomCamera(float Amount) // override look at cam function to be able to limit zoom in factor
{
    // If FreeCameraRotation is in use, which has a conflicting MCO, then use its config values here
    if (class'DirectControlUtils'.static.IsModActive('FreeCameraRotation'))
    {
        `DC_LOG("FreeCameraRotation is active");
	    TargetZoom = FClamp(TargetZoom + Amount, class'X2Camera_FollowMouseCursor_FreeCameraRotation'.default.MIN_ZOOM_MULT, 1.0);
    }
    else
    {
        super.ZoomCamera(Amount);
    }
}

// This function copied from FreeCameraRotation
function ResetToDefault() // reset target values to default human turn values
{
	TargetZoom = 0.0f;
	TargetRotation.Yaw = HumanTurnYaw * DegToUnrRot;
	TargetRotation.Pitch = HumanTurnPitch * DegToUnrRot;
	TargetRotation.Roll = HumanTurnRoll * DegToUnrRot;
}

// This function copied from FreeCameraRotation
function EventListenerReturn OnResetCamera(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData) // process reset cam event
{
	ResetToDefault();
	return ELR_NoInterrupt;
}

private function bool ControllingPlayerIsAI(XComGameState_Unit UnitState)
{
    if (!UnitState.ControllingPlayerIsAI())
    {
        return false;
    }

	return !class'DirectControlUtils'.static.IsPlayerControllingUnit(UnitState);
}