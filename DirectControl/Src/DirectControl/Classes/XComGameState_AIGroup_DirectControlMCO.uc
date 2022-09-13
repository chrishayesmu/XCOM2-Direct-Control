class XComGameState_AIGroup_DirectControlMCO extends XComGameState_AIGroup;

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
    local bool bUnitIsSurprised;
    local X2TacticalGameRuleset Rules;

    History = `XCOMHISTORY;

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

        // DC: if there's no one eligible to scamper, we still need to mark the group as having scampered, or other game logic can break
        if (NumScamperers == 0)
        {
            `DC_LOG("No scamperers found in this group: submitting fake scamper state. Group state is " $ self);
            SubmitFakeScamperState();
            return;
        }

        //////////////////////////////////////////////////////////////
        // Kick off the BT scamper actions

        //Find the AI player data object
        AIPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());
        `assert(AIPlayer != none);
        TargetStateObject = XComGameState_Unit(History.GetGameStateForObjectID(RevealInstigatorUnitObjectID));

        // Give the units their scamper action points
        NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Add Scamper Action Points");
        foreach Scamperers(Ref)
        {
            NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Ref.ObjectID));
            if( NewUnitState.IsAbleToAct() )
            {
                NewUnitState.ActionPoints.Length = 0;
                NumActionPoints = NewUnitState.GetNumScamperActionPoints();
                for (i = 0; i < NumActionPoints; ++i)
                {
                    NewUnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint); //Give the AI one free action point to use.
                }

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
    local bool bIsTeamPlayerControlled;

    // If the player is responsible for controlling inactive units, and these aren't reinforcements, don't scamper.
    // Reinforcements are allowed to scamper because they otherwise have no action points and won't be controllable
    // on the turn that they spawn.
    bIsTeamPlayerControlled = (`DC_CFG(bPlayerControlsAlienTurn) && `DC_CFG(bPlayerControlsUnactivatedAliens) && UnitStateObject.GetTeam() == eTeam_Alien)
                           || (`DC_CFG(bPlayerControlsLostTurn)  && `DC_CFG(bPlayerControlsUnactivatedLost)   && UnitStateObject.GetTeam() == eTeam_TheLost);

    if (bIsTeamPlayerControlled && UnitStateObject.IsChosen() && !class'DirectControlUtils'.static.IsUnitSpawnedAsReinforcements(UnitStateObject.ObjectID))
    {
        // Chosen have to be allowed to scamper or they break
        return true;
    }

    if (bIsTeamPlayerControlled && !class'DirectControlUtils'.static.IsUnitSpawningAsReinforcements(UnitStateObject.ObjectID))
    {
        // Only prevent scamper if the team has had a turn to position their troops; otherwise they'll just be stuck out in
        // the open with no chance for counterplay
        if (class'DirectControlUtils'.static.HasTeamHadATurn(UnitStateObject.GetTeam()))
        {
            return false;
        }
    }

    // DC: same as vanilla logic but allow player-controlled units to scamper
    return UnitStateObject.IsAlive() &&
         (!UnitStateObject.IsIncapacitated()) &&
           UnitStateObject.bTriggerRevealAI &&
          !UnitStateObject.IsPanicked() &&
          !UnitStateObject.IsUnitAffectedByEffectName(class'X2AbilityTemplateManager'.default.PanickedName) &&
          !UnitStateObject.IsUnitAffectedByEffectName(class'X2AbilityTemplateManager'.default.BurrowedName) &&
         (`CHEATMGR == None || !`CHEATMGR.bAbortScampers);
}

private function SubmitFakeScamperState()
{
    local XComGameState NewGameState;
    local XComGameState_AIGroup NewGroupState;

    NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Direct Control: Fake Scamper State");

    NewGroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', ObjectID));
    NewGroupState.bProcessedScamper = true;
    NewGroupState.bPendingScamper = false;
    NewGroupState.bSummoningSicknessCleared = true;

    `TACTICALRULES.SubmitGameState(NewGameState);
}