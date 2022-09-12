class UIScreenListener_ChosenReveal extends UIScreenListener;

event OnInit(UIScreen Screen)
{
    // We use this UISL when a Chosen is first spawned into a mission. Normally the AI player would handle this, but for some reason the Chosen
    // don't belong to an AIGroup when initially spawned, which breaks how the AI player handles new turns. Since this screen can also be opened
    // manually, we make sure it's actually the alien turn.
    if (UIChosenReveal(Screen) != none && `DC_CFG(bPlayerControlsAlienTurn) && class'DirectControlUtils'.static.GetActivePlayer().TeamFlag == eTeam_Alien)
    {
        `DC_LOG("Going to set player controller to eTeam_Alien");

        class'DirectControlUtils'.static.SetControllingPlayerTeam(eTeam_Alien);
    }
}