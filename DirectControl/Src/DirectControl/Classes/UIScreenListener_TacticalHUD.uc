class UIScreenListener_TacticalHUD extends UIScreenListener;

event OnInit(UIScreen Screen)
{
    local UITacticalHud TacticalHud;

    TacticalHud = UITacticalHud(Screen);

    if (TacticalHud == none)
    {
        return;
    }

    if (HasUITurnTimerPanel())
    {
        return;
    }

    Screen.Spawn(class'UITurnTimer', Screen).InitPanel();
}

protected function bool HasUITurnTimerPanel()
{
    local UITurnTimer TurnTimer;

    foreach `XCOMGAME.AllActors(class'UITurnTimer', TurnTimer)
    {
        return true;
    }

    return false;
}