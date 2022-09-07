class X2EventListener_DirectControl extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2DataTemplate> Templates;
    local CHEventListenerTemplate Template;

    `CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'X2EventListener_DirectControl');

    Template.RegisterInTactical = true;
    Template.AddCHEvent('PlayerTurnBegun', OnPlayerTurnBegun, ELD_OnStateSubmitted);
	Template.AddCHEvent('OnUnitBeginPlay', OnUnitBeginPlay_CheckForLostSwarms, ELD_OnStateSubmitted);
	Template.AddCHEvent('OnUnitBeginPlay', OnUnitBeginPlay_VisStarted, ELD_OnVisualizationBlockStarted);
	Template.AddCHEvent('UnitDied', OnUnitDied, ELD_Immediate);

    Templates.AddItem(Template);

    return Templates;
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

    `DC_LOG("OnUnitDied: Event = " $ Event $ ", EventData = " $ EventData $ ", EventSource = " $ EventSource);

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
