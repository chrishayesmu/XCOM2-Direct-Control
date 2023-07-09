class XComGameState_AIGroup_DirectControlMCO extends XComGameState_AIGroup;

const DEBUG_LOGGING = false;

function ProcessReflexMoveActivate(optional name InSpecialRevealType)
{
    local XComGameStateHistory History;
    local int Index, NumScamperers, NumSurprised, i, NumActionPoints;
    local XComGameState_Unit UnitStateObject, TargetStateObject, NewUnitState;
    local XComGameState_AIGroup NewGroupState;
    local StateObjectReference Ref;
    local XGAIPlayer AIPlayer;
    local XComGameState NewGameState;
    local array<StateObjectReference> Scamperers;
    local float SurprisedChance;
    local bool bUnitIsSurprised, bIsFakeScamper;
    local X2TacticalGameRuleset Rules;
    local array<StateObjectReference> ControlledUnits;

    History = `XCOMHISTORY;

    `DC_LOG("ProcessReflexMoveActivate: bProcessedScamper = " $ bProcessedScamper, DEBUG_LOGGING);

    if( !bProcessedScamper ) // Only allow scamper once.
    {
        //First, collect a list of scampering units. Due to cheats and other mechanics this list could be empty, in which case we should just skip the following logic
        foreach m_arrMembers(Ref)
        {
            UnitStateObject = XComGameState_Unit(History.GetGameStateForObjectID(Ref.ObjectID));
            if(CanScamper(UnitStateObject))
            {
                Scamperers.AddItem(Ref);
            }
        }

        NumScamperers = Scamperers.Length;

        //////////////////////////////////////////////////////////////
        // Kick off the BT scamper actions

        //Find the AI player data object
        AIPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());
        `assert(AIPlayer != none);
        TargetStateObject = XComGameState_Unit(History.GetGameStateForObjectID(RevealInstigatorUnitObjectID));

        // DC: find the list of units which are known to be controlled by the player
        if (XGAIPlayer_DirectControlMCO(AIPlayer) != none)
        {
            `DC_LOG("ProcessReflexMoveActivate: Getting list of controlled units from XGAIPlayer_DirectControlMCO", DEBUG_LOGGING);
            ControlledUnits = XGAIPlayer_DirectControlMCO(AIPlayer).CurrentControlledUnits;
        }

        // Give the units their scamper action points
        NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Add Scamper Action Points");
        foreach Scamperers(Ref)
        {
            NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Ref.ObjectID));
            if( NewUnitState.IsAbleToAct() )
            {
                bIsFakeScamper = !DC_CanScamper(NewUnitState, ControlledUnits);
                NumActionPoints = 0;

                if (!bIsFakeScamper)
                {
                    `DC_LOG("ProcessReflexMoveActivate: Scamper for unit " $ NewUnitState.GetFullName() $ " is not fake; removing action points", DEBUG_LOGGING);
                    NewUnitState.ActionPoints.Length = 0;
                    NumActionPoints = NewUnitState.GetNumScamperActionPoints();
                }
                else
                {
                    `DC_LOG("ProcessReflexMoveActivate: Not removing action points for unit " $ NewUnitState.GetFullName(), DEBUG_LOGGING);
                }

                for (i = 0; i < NumActionPoints; ++i)
                {
                    NewUnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint); //Give the AI one free action point to use.
                }

                `DC_LOG("ProcessReflexMoveActivate: Unit " $ NewUnitState.GetFullName() $ " has " $ NumActionPoints $ " action points to use for scamper", DEBUG_LOGGING);

                if (NewUnitState.GetMyTemplate().OnRevealEventFn != none)
                {
                    NewUnitState.GetMyTemplate().OnRevealEventFn(NewUnitState);
                }
            }
            else
            {
                NewGameState.PurgeGameStateForObjectID(NewUnitState.ObjectID);
            }
        }

        NewGroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', ObjectID));
        NewGroupState.bProcessedScamper = true;
        NewGroupState.bPendingScamper = true;
        NewGroupState.SpecialRevealType = InSpecialRevealType;
        NewGroupState.bSummoningSicknessCleared = false;

        if(NewGameState.GetNumGameStateObjects() > 0)
        {
            // Now that we are kicking off a scamper Behavior Tree (latent), we need to handle the scamper clean-up on
            // an event listener that waits until after the scampering behavior decisions are made.
            for( Index = 0; Index < NumScamperers; ++Index )
            {
                UnitStateObject = XComGameState_Unit(History.GetGameStateForObjectID(Scamperers[Index].ObjectID));

                // choose which scampering units should be surprised
                // randomly choose half to be surprised
                if(PreviouslyConcealedUnitObjectIDs.Length > 0)
                {
                    if( UnitStateObject.IsGroupLeader() )
                    {
                        bUnitIsSurprised = false;
                    }
                    else
                    {
                        NumSurprised = NewGroupState.SurprisedScamperUnitIDs.Length;
                        SurprisedChance = (float(NumScamperers) * SURPRISED_SCAMPER_CHANCE - NumSurprised) / float(NumScamperers - Index);
                        bUnitIsSurprised = `SYNC_FRAND() <= SurprisedChance;
                    }

                    if(bUnitIsSurprised)
                    {
                        NewGroupState.SurprisedScamperUnitIDs.AddItem(Scamperers[Index].ObjectID);
                    }
                }

                AIPlayer.QueueScamperBehavior(UnitStateObject, TargetStateObject, bUnitIsSurprised, Index == 0);
            }

            // Start Issue #510
            //
            // Mods can't use the `OnScamperBegin` event to provide extra action points because it
            // happens too late, so we fire this custom event here instead.
            `XEVENTMGR.TriggerEvent('ProcessReflexMove', UnitStateObject, self, NewGameState);
            // End Issue #510

            Rules = `TACTICALRULES;
            Rules.SubmitGameState(NewGameState);
            `BEHAVIORTREEMGR.TryUpdateBTQueue();
        }
        else
        {
            History.CleanupPendingGameState(NewGameState);
        }
    }
}

function bool CanScamper(XComGameState_Unit UnitStateObject)
{
    // DC: same as vanilla logic but allow player-controlled units to scamper
    return UnitStateObject.IsAlive() &&
          !UnitStateObject.IsIncapacitated() &&
           UnitStateObject.bTriggerRevealAI &&
          !UnitStateObject.IsPanicked() &&
          !UnitStateObject.IsUnitAffectedByEffectName(class'X2AbilityTemplateManager'.default.PanickedName) &&
          !UnitStateObject.IsUnitAffectedByEffectName(class'X2AbilityTemplateManager'.default.BurrowedName) &&
         (`CHEATMGR == None || !`CHEATMGR.bAbortScampers);
}

// Extra logic for Direct Control: we may not want entire pods to scamper (if the player has positioned the units themselves),
// or sometimes we only want individual units in a pod to scamper (e.g. summoning a new unit into an already-active pod).
static function bool DC_CanScamper(XComGameState_Unit UnitStateObject, array<StateObjectReference> ControlledUnits)
{
    local bool bIsTeamPlayerControlled;

    `DC_LOG("DC_CanScamper: called for unit " $ UnitStateObject.GetFullName() $ " (obj ID " $ UnitStateObject.GetReference().ObjectID $ ")", DEBUG_LOGGING);
    `DC_LOG("DC_CanScamper: group membership obj ID = " $ UnitStateObject.GetGroupMembership().GetReference().ObjectID $ ". ControlledUnits.Length = " $ ControlledUnits.Length, DEBUG_LOGGING);

    // If the player is responsible for controlling inactive units, and these aren't reinforcements, don't scamper.
    // Reinforcements are allowed to scamper because they otherwise have no action points and won't be controllable
    // on the turn that they spawn.
    bIsTeamPlayerControlled = class'DirectControlUtils'.static.IsPlayerControllingUnit(UnitStateObject);

    // TODO: this can probably be cleaned up or clarified (why would a Chosen ever be spawned as reinforcements?)
    if (bIsTeamPlayerControlled && UnitStateObject.IsChosen() && !class'DirectControlUtils'.static.IsUnitSpawnedAsReinforcements(UnitStateObject.ObjectID))
    {
        // Chosen have to be allowed to scamper or they break
        return true;
    }

    if (ControlledUnits.Find('ObjectID', UnitStateObject.GetReference().ObjectID) != INDEX_NONE)
    {
        `DC_LOG("DC_CanScamper: Unit is listed as currently controlled by player, cannot scamper", DEBUG_LOGGING);
        return false;
    }

    if (bIsTeamPlayerControlled &&
        !class'DirectControlUtils'.static.IsUnitSpawningAsReinforcements(UnitStateObject.ObjectID) &&
        UnitStateObject.ShadowUnit_CopiedUnit.ObjectID == 0 /* check if unit is created by Shadowbind */)
    {
        `DC_LOG("DC_CanScamper: Unit " $ UnitStateObject.GetFullName() $ " group's summoning sickness cleared? " $ UnitStateObject.GetGroupMembership().bSummoningSicknessCleared, DEBUG_LOGGING);

        // Only prevent scamper if the team has had a turn to position their troops; otherwise they'll just be stuck out in
        // the open with no chance for counterplay
        if (UnitStateObject.GetGroupMembership().bSummoningSicknessCleared && class'DirectControlUtils'.static.HasTeamHadATurn(UnitStateObject.GetTeam()))
        {
            `DC_LOG("DC_CanScamper: cannot scamper!", DEBUG_LOGGING);
            return false;
        }
    }

    `DC_LOG("DC_CanScamper: can scamper", DEBUG_LOGGING);
    return true;
}