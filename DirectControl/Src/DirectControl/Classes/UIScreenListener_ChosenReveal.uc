class UIScreenListener_ChosenReveal extends UIScreenListener;

event OnInit(UIScreen Screen)
{
    local XComTacticalController kLocalPC;
    local XComGameState_Player PlayerState;

    if (UIChosenReveal(Screen) != none && `DC_CFG(bPlayerControlsAlienTurn))
    {
        `DC_LOG("Going to set player controller to eTeam_Alien");

        // TODO make sure it's the alien turn; the player can bring up this screen manually
        PlayerState = class'DirectControlUtils'.static.GetPlayerForTeam(eTeam_Alien);

        `CHEATMGR.bAllowSelectAll = true;

        kLocalPC = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
        kLocalPC.SetControllingPlayer(PlayerState);
        kLocalPC.SetTeamType(PlayerState.TeamFlag);
    }
}