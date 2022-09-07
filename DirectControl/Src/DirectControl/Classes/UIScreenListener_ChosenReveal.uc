class UIScreenListener_ChosenReveal extends UIScreenListener;

event OnInit(UIScreen Screen)
{
    local XComTacticalController kLocalPC;
    local XComGameState_Player PlayerState;

    // We use this UISL when a Chosen is first spawned into a mission. If the player controller is set to control aliens when that happens,
    // a lot of stuff breaks. An event listener changes the controller to the XCOM team, and then this UISL sets control back to aliens when
    // the screen is closed. Since this screen can also be opened manually, we make sure it's actually the alien turn.
    if (UIChosenReveal(Screen) != none && `DC_CFG(bPlayerControlsAlienTurn) && class'DirectControlUtils'.static.GetActivePlayer().TeamFlag == eTeam_Alien)
    {
        `DC_LOG("Going to set player controller to eTeam_Alien");

        PlayerState = class'DirectControlUtils'.static.GetPlayerForTeam(eTeam_Alien);

        `CHEATMGR.bAllowSelectAll = true;

        kLocalPC = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
        kLocalPC.SetControllingPlayer(PlayerState);
        kLocalPC.SetTeamType(PlayerState.TeamFlag);
    }
}