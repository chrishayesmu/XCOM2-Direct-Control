class X2EventListener_DirectControl extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2DataTemplate> Templates;
    local CHEventListenerTemplate Template;

    `CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'X2EventListener_DirectControl');

    Template.RegisterInTactical = true;
    Template.AddCHEvent('AbilityActivated', OnAbilityVisualizationBegin_ForceUnitToRun, ELD_OnVisualizationBlockStarted);
    Template.AddCHEvent('PlayerTurnBegun', OnPlayerTurnBegun, ELD_OnStateSubmitted, 99); // needs to occur before reinforcement spawns do
    Template.AddCHEvent('SpawnReinforcementsComplete', OnSpawnReinforcementsComplete_SwapToXCOM, ELD_Immediate);
    Template.AddCHEvent('SpawnReinforcementsComplete', OnSpawnReinforcementsComplete_SwapToActiveTeam, ELD_OnVisualizationBlockCompleted);
    //Template.AddCHEvent('OnUnitBeginPlay', OnUnitBeginPlay_CheckForLostSwarms, ELD_OnStateSubmitted); // TODO
    Template.AddCHEvent('OnUnitBeginPlay', OnUnitBeginPlay_VisStarted, ELD_OnVisualizationBlockStarted);
    Template.AddCHEvent('UnitDied', OnUnitDied, ELD_Immediate);

    Templates.AddItem(Template);

    return Templates;
}

private static function EventListenerReturn OnAbilityVisualizationBegin_ForceUnitToRun(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local int Index;
    local array<X2Action> ActionNodes;
    local X2Action_Move MoveNode;
    local XComGameState_Ability AbilityState;
    local XComGameState_Unit UnitState;
    local XComGameStateVisualizationMgr VisualizationMgr;
    local XGUnit UnitVisualizer;

    AbilityState = XComGameState_Ability(EventData);
    UnitState = XComGameState_Unit(EventSource);
    VisualizationMgr = `XCOMVISUALIZATIONMGR;

    if (AbilityState.GetMyTemplateName() != 'StandardMove')
    {
        return ELR_NoInterrupt;
    }

    if (!`DC_CFG(bForceControlledUnitsToRun))
    {
        return ELR_NoInterrupt;
    }

    // Only make units run if they're being controlled by the player; otherwise they can walk the normal way
    if (!class'DirectControlUtils'.static.IsPlayerControllingUnit(UnitState))
    {
        return ELR_NoInterrupt;
    }

    // Player units always run, so skip them
    UnitVisualizer = XGUnit(UnitState.GetVisualizer());

    if (UnitVisualizer == none || !UnitVisualizer.IsAI())
    {
        return ELR_NoInterrupt;
    }

    // Iterate all active movement nodes and force them to run instead of walk
    VisualizationMgr.GetNodesOfType(VisualizationMgr.VisualizationTree, class'X2Action_Move', ActionNodes, UnitState.GetVisualizer());

    for (Index = 0; Index < ActionNodes.Length; Index++)
    {
        MoveNode = X2Action_Move(ActionNodes[Index]);
        MoveNode.bShouldUseWalkAnim = false;
    }

    return ELR_NoInterrupt;
}

private static function EventListenerReturn OnSpawnReinforcementsComplete_SwapToActiveTeam(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComTacticalController kLocalPC;
    local XComGameState_Player PlayerState;
    local XComGameState_AIReinforcementSpawner ReinforcementSpawner;

    ReinforcementSpawner = XComGameState_AIReinforcementSpawner(EventSource);

    if (class'DirectControlUtils'.static.PodSpawnContainsChosen(ReinforcementSpawner.SpawnInfo))
    {
        `DC_LOG("Pod contains Chosen, not changing controlling player");

        return ELR_NoInterrupt;
    }

    PlayerState = class'DirectControlUtils'.static.GetActivePlayer();

    `DC_LOG("Reinforcements are done spawning; active team is " $ PlayerState.TeamFlag);

    if (class'DirectControlUtils'.static.IsLocalPlayer(PlayerState.TeamFlag))
    {
        `DC_LOG("Player is local; switching controlling player");

        `CHEATMGR.bAllowSelectAll = true;

        kLocalPC = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
        kLocalPC.SetControllingPlayer(PlayerState);
        kLocalPC.SetTeamType(PlayerState.TeamFlag);
    }

    return ELR_NoInterrupt;
}

private static function EventListenerReturn OnSpawnReinforcementsComplete_SwapToXCOM(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComTacticalController kLocalPC;
    local XComGameState_Player PlayerState;
    local XComGameState_AIReinforcementSpawner ReinforcementSpawner;

    ReinforcementSpawner = XComGameState_AIReinforcementSpawner(EventSource);

    if (class'DirectControlUtils'.static.PodSpawnContainsChosen(ReinforcementSpawner.SpawnInfo))
    {
        `DC_LOG("Pod contains Chosen, not changing controlling player");

        return ELR_NoInterrupt;
    }

    `DC_LOG("Reinforcements are spawning; switching controlling player to XCOM");

    `CHEATMGR.bAllowSelectAll = false;
    PlayerState = class'DirectControlUtils'.static.GetPlayerForTeam(eTeam_XCom);

    kLocalPC = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
    kLocalPC.SetControllingPlayer(PlayerState);
    kLocalPC.SetTeamType(PlayerState.TeamFlag);

    return ELR_NoInterrupt;
}

private static function EventListenerReturn OnUnitBeginPlay_CheckForLostSwarms(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComTacticalController kLocalPC;
    local XComGameState_Player PlayerState;
    local XComGameState_Unit UnitState;

    UnitState = XComGameState_Unit(EventSource);

    if (UnitState.GetTeam() != eTeam_TheLost || !class'DirectControlUtils'.static.IsUnitSpawningAsReinforcements(UnitState.ObjectID))
    {
        return ELR_NoInterrupt;
    }

    `DC_LOG("Lost reinforcements are spawning; switching controlling player to XCOM");

    `CHEATMGR.bAllowSelectAll = false;
    PlayerState = class'DirectControlUtils'.static.GetPlayerForTeam(eTeam_XCom);

    // TODO: nothing is switching the player back after this; problematic if a swarm spawns during the alien turn

    kLocalPC = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
    kLocalPC.SetControllingPlayer(PlayerState);
    kLocalPC.SetTeamType(PlayerState.TeamFlag);

    return ELR_NoInterrupt;
}

// Checks for a Chosen unit entering play. The Chosen reveal cinematic breaks horribly if the controlling player at the time is not
// the XCom team's player, so we take care of that here. We then need to set the controlling player correctly after the reveal is
// done, which is handled using a UISL elsewhere to check for the UIChosenReveal screen.
private static function EventListenerReturn OnUnitBeginPlay_VisStarted(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComTacticalController kLocalPC;
    local XComGameState_Player PlayerState;
    local XComGameState_Unit UnitState;

    UnitState = XComGameState_Unit(EventSource);

    if (UnitState.IsChosen())
    {
        `DC_LOG("Chosen unit vis beginning! Setting controlling player to XCOM");

        `CHEATMGR.bAllowSelectAll = false;
        PlayerState = class'DirectControlUtils'.static.GetPlayerForTeam(eTeam_XCom);

        kLocalPC = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
        kLocalPC.SetControllingPlayer(PlayerState);
        kLocalPC.SetTeamType(PlayerState.TeamFlag);
    }

    return ELR_NoInterrupt;
}

static function EventListenerReturn OnUnitDied(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local bool bTeamHasLivingUnit;
    local XComTacticalController kLocalPC;
    local XComGameStateHistory History;
    local XComGameState_Unit EvtUnitState, UnitState;
    local XComGameState_Player PlayerState;

    History = `XCOMHISTORY;

    kLocalPC = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
    EvtUnitState = XComGameState_Unit(EventSource);

    if (EvtUnitState.GetTeam() != kLocalPC.m_eTeam)
    {
        `DC_LOG("Dead unit does not belong to the currently controlled team. No event handling needed.");
        return ELR_NoInterrupt;
    }

    bTeamHasLivingUnit = false;

    // If this unit is the last one on its team, we need to switch control before the player wrongly loses the mission
    foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
    {
        if (UnitState.ObjectID == EvtUnitState.ObjectID)
        {
            continue;
        }

        if (UnitState.GetTeam() != EvtUnitState.GetTeam())
        {
            continue;
        }

        // TODO: find the true conditions for losing
        if (UnitState.IsAlive() && !UnitState.bRemovedFromPlay)
        {
            bTeamHasLivingUnit = true;
            break;
        }
    }

    if (!bTeamHasLivingUnit)
    {
        `DC_LOG("No units remain alive on team " $ EvtUnitState.GetTeam() $ ". Changing controlling player to XCOM.");
        PlayerState = class'DirectControlUtils'.static.GetPlayerForTeam(eTeam_XCom);
        kLocalPC.SetControllingPlayer(PlayerState);
        kLocalPC.SetTeamType(PlayerState.TeamFlag);
    }
    else
    {
        `DC_LOG("Team " $ EvtUnitState.GetTeam() $ " still has living units. Not changing controlling player.");
    }

    return ELR_NoInterrupt;
}

// At the start of each turn, checks whether the active player is going to be
// human-controlled, and sets up the game environment accordingly.
private static function EventListenerReturn OnPlayerTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComTacticalController kLocalPC;
    local XComGameState_Player PlayerState;

    PlayerState = XComGameState_Player(EventSource);

    `CHEATMGR.bAllowSelectAll = (`DC_CFG(bPlayerControlsAlienTurn) && PlayerState.TeamFlag == eTeam_Alien)
                             || (`DC_CFG(bPlayerControlsLostTurn)  && PlayerState.TeamFlag == eTeam_TheLost);

    kLocalPC = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());

    // If the player won't be controlling this team, we set the controller back to the XCOM team, so that the
    // XCOM player doesn't get to see more than they're supposed to
    if (!`CHEATMGR.bAllowSelectAll && PlayerState.TeamFlag != eTeam_XCom)
    {
        `DC_LOG("Player won't be controlling team " $ PlayerState.TeamFlag);
        PlayerState = class'DirectControlUtils'.static.GetPlayerForTeam(eTeam_XCom);
    }

    `DC_LOG("Setting controlling player to team " $ PlayerState.TeamFlag);
    kLocalPC.SetControllingPlayer(PlayerState);
    kLocalPC.SetTeamType(PlayerState.TeamFlag);

    return ELR_NoInterrupt;
}
