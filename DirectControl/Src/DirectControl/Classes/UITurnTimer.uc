class UITurnTimer extends UIPanel
    config(DirectControlUI);

struct TLabelPosition
{
    var int X;
    var int Y;
};

var config TLabelPosition Position;

var const localized string strTimerTextWithTeam;
var const localized string strTimerTextWithoutTeam;
var const localized string strAlienTurn;
var const localized string strLostTurn;
var const localized string strXComTurn;

var private UIBGBox m_bgBox;
var private UIText m_txtTimer;

var private float m_fTurnTimeElapsed;
var private string m_strActiveTeam;

simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
    local Object ThisObj;

    super.InitPanel(InitName, InitLibID);

    SetPosition(Position.X, Position.Y);
    SetSize(134, 30);

	m_bgBox = Spawn(class'UIBGBox', self).InitBG('', 0, 0);
	m_bgBox.SetAlpha(0.85);

    m_txtTimer = Spawn(class'UIText', self);
	m_txtTimer.InitText('', "", /* InitTitleFont */ false, OnLabelTextSizeRealized);
    m_txtTimer.SetPosition(3.5, 1.5);

    ThisObj = self;
    `XEVENTMGR.RegisterForEvent(ThisObj, 'DirectControlConfigChanged', OnConfigChanged, ELD_Immediate);
    `XEVENTMGR.RegisterForEvent(ThisObj, 'PlayerTurnBegun', OnPlayerTurnBegun, ELD_OnStateSubmitted);

    SetActiveTeamText();

    if (!ShouldShow())
    {
        Hide();
    }

    return self;
}

event Tick(float fDeltaT)
{
    m_fTurnTimeElapsed += fDeltaT;

    UpdateTimerText();
}

private function OnLabelTextSizeRealized()
{
    m_bgBox.SetSize(m_txtTimer.Width + 12, m_txtTimer.Height + 8);

    SetPosition(Position.X + m_bgBox.Width / 2, Position.Y);
}

private function EventListenerReturn OnConfigChanged(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    if (ShouldShow())
    {
        Show();
    }
    else
    {
        Hide();
    }

    return ELR_NoInterrupt;
}

private function EventListenerReturn OnPlayerTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComGameState_Player PlayerState;

    m_fTurnTimeElapsed = 0.0f;

    PlayerState = XComGameState_Player(EventSource);

    if (!class'DirectControlUtils'.static.IsLocalPlayer(PlayerState.TeamFlag))
    {
        Hide();
    }
    else
    {
        Show();
    }

    SetActiveTeamText(PlayerState);

    return ELR_NoInterrupt;
}

private function SetActiveTeamText(optional XComGameState_Player PlayerState)
{
    if (PlayerState == none)
    {
        PlayerState = class'DirectControlUtils'.static.GetActivePlayer();
    }

    switch (PlayerState.TeamFlag)
    {
        case eTeam_Alien:
            m_strActiveTeam = strAlienTurn;
            break;
        case eTeam_TheLost:
            m_strActiveTeam = strLostTurn;
            break;
        case eTeam_XCom:
            m_strActiveTeam = strXComTurn;
            break;
        default:
            m_strActiveTeam = "";
            break;
    }
}

private function bool ShouldShow()
{
    local XComGameState_Player PlayerState;

    if (!`DC_CFG(bShowTurnTimer))
    {
        return false;
    }

    PlayerState = class'DirectControlUtils'.static.GetActivePlayer();

    if (PlayerState == none || !class'DirectControlUtils'.static.IsLocalPlayer(PlayerState.TeamFlag))
    {
        return false;
    }

    return true;
}

private function UpdateTimerText()
{
    local string strDisplayText, strTimerText;
    local int iMinutes, iSeconds;

    iMinutes = int(m_fTurnTimeElapsed / 60.0f);
    iSeconds = int(m_fTurnTimeElapsed) % 60;

    strTimerText = iMinutes >= 10 ? string(iMinutes) : "0" $ iMinutes;
    strTimerText $= ":";
    strTimerText $= iSeconds >= 10 ? string(iSeconds) : "0" $ iSeconds;

    strDisplayText = `DC_CFG(bTurnTimerShowsActiveTeam) ? strTimerTextWithTeam : strTimerTextWithoutTeam;
    strDisplayText = Repl(strDisplayText, "<Time/>", strTimerText);
    strDisplayText = Repl(strDisplayText, "<Team/>", m_strActiveTeam);

    m_txtTimer.SetText(strDisplayText, OnLabelTextSizeRealized);
}