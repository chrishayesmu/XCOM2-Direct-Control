class UITurnTimer extends UIPanel
    config(DirectControlUI);

struct TLabelPosition
{
    var int X;
    var int Y;
};

var config TLabelPosition Position;

var private UIBGBox m_bgBox;
var private UIText m_txtTimer;

var private float m_fTurnTimeElapsed;

simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
    local Object ThisObj;

    super.InitPanel(InitName, InitLibID);

    SetPosition(Position.X, Position.Y);
    SetSize(134, 30);

	m_bgBox = Spawn(class'UIBGBox', self).InitBG('', 0, 0, self.Width, self.Height);
	m_bgBox.SetAlpha(0.85);

    m_txtTimer = Spawn(class'UIText', self);
	m_txtTimer.InitText('', "00:00 Elapsed", /* InitTitleFont */ false, OnLabelTextSizeRealized);
    m_txtTimer.SetPosition(3.5, 1.5);

    ThisObj = self;
    `XEVENTMGR.RegisterForEvent(ThisObj, 'PlayerTurnBegun', OnPlayerTurnBegun, ELD_OnStateSubmitted);

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
}

private function UpdateTimerText()
{
    local string strTimerText;
    local int iMinutes, iSeconds;

    iMinutes = int(m_fTurnTimeElapsed / 60.0f);
    iSeconds = int(m_fTurnTimeElapsed) % 60;

    strTimerText = iMinutes >= 10 ? string(iMinutes) : "0" $ iMinutes;
    strTimerText $= ":";
    strTimerText $= iSeconds >= 10 ? string(iSeconds) : "0" $ iSeconds;
    strTimerText $= " Elapsed";

    m_txtTimer.SetText(strTimerText);
}

private function EventListenerReturn OnPlayerTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComGameState_Player PlayerState;

    m_fTurnTimeElapsed = 0.0f;

    PlayerState = XComGameState_Player(EventSource);

    if ((!`DC_CFG(bPlayerControlsAlienTurn) && PlayerState.TeamFlag == eTeam_Alien)
     || (!`DC_CFG(bPlayerControlsLostTurn)  && PlayerState.TeamFlag == eTeam_TheLost)
     || PlayerState.TeamFlag == eTeam_Resistance
     || PlayerState.TeamFlag == eTeam_Neutral)
    {
        Hide();
    }
    else
    {
        Show();
    }

    return ELR_NoInterrupt;
}