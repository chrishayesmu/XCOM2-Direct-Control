class X2EventListener_DirectControl extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2DataTemplate> Templates;
    local CHEventListenerTemplate Template;

    `CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'X2EventListener_DirectControl');

    Template.RegisterInTactical = true;
    Template.AddCHEvent('AbilityActivated', OnAbilityVisualizationBegin_ForceUnitToRun, ELD_OnVisualizationBlockStarted);
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