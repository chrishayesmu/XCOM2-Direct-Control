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
var const localized string strResistanceTurn;
var const localized string strTeamOneTurn;
var const localized string strTeamTwoTurn;
var const localized string strXComTurn;

var private UIBGBox m_bgBox;
var private UIText m_txtTimer;

var private int m_iCurrentTurnNumber;
var private float m_fTurnTimeElapsed;
var private string m_strActiveTeam;
var private string m_strActiveTeamColor;

simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
    local Object ThisObj;

    super.InitPanel(InitName, InitLibID);

    SetPosition(Position.X, Position.Y);
    SetSize(134, 30);

    m_bgBox = Spawn(class'UIBGBox', self).InitBG('', 0, 0);
    m_bgBox.SetAlpha(0.95);

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

    // Cache the turn number so we aren't calculating it every frame
    m_iCurrentTurnNumber = GetCurrentTurnNumber();

    return self;
}

event Tick(float fDeltaT)
{
    m_fTurnTimeElapsed += fDeltaT;

    UpdateTimerText();
}

private function int GetCurrentTurnNumber()
{
    local int Index, NumPlayers, NumTurnStarts;
    local XComGameStateHistory History;
    local XComGameStateContext_TacticalGameRule Context;
    local XComGameState_Player PlayerState;
    local XComGameState_BattleData BattleData;

    // We can't assume XCOM is the first team to act because mods can change that,
    // so just look at the total number of players and turns
    History = `XCOMHISTORY;
    BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

    for (Index = 0; Index < BattleData.PlayerTurnOrder.Length; Index++)
    {
        PlayerState = XComGameState_Player(History.GetGameStateForObjectID(BattleData.PlayerTurnOrder[Index].ObjectID));

        if (PlayerState != None)
        {
            NumPlayers++;
        }
    }

    foreach History.IterateContextsByClassType(class'XComGameStateContext_TacticalGameRule', Context)
    {
        if (Context.GameRuleType == eGameRule_PlayerTurnBegin)
        {
            NumTurnStarts++;
        }
    }

    return 1 + (NumTurnStarts / NumPlayers);
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
    m_iCurrentTurnNumber = GetCurrentTurnNumber();

    PlayerState = XComGameState_Player(EventSource);

    `DC_LOG("Player turn changed to team " $ PlayerState.TeamFlag);

    if (ShouldShow(PlayerState))
    {
        Show();
    }
    else
    {
        Hide();
    }

    SetActiveTeamText(PlayerState);

    return ELR_NoInterrupt;
}

private function SetActiveTeamText(optional XComGameState_Player PlayerState)
{
	local XComLWTuple OverrideTuple;

    if (PlayerState == none)
    {
        PlayerState = class'DirectControlUtils'.static.GetActivePlayer();
    }

    switch (PlayerState.TeamFlag)
    {
        case eTeam_Alien:
            m_strActiveTeam = strAlienTurn;
            m_strActiveTeamColor = class'UIUtilities_Colors'.static.ConvertWidgetColorToHTML(eColor_Alien);
            break;
        case eTeam_Resistance:
            m_strActiveTeam = strResistanceTurn;
            m_strActiveTeamColor = class'UIUtilities_Colors'.static.ConvertWidgetColorToHTML(eColor_Xcom);
            break;
        case eTeam_One:
            m_strActiveTeam = strTeamOneTurn;
            m_strActiveTeamColor = class'UIUtilities_Colors'.static.ConvertWidgetColorToHTML(eColor_White);
            break;
        case eTeam_Two:
            m_strActiveTeam = strTeamTwoTurn;
            m_strActiveTeamColor = class'UIUtilities_Colors'.static.ConvertWidgetColorToHTML(eColor_White);
            break;
        case eTeam_TheLost:
            m_strActiveTeam = strLostTurn;
            m_strActiveTeamColor = class'UIUtilities_Colors'.static.ConvertWidgetColorToHTML(eColor_TheLost);
            break;
        case eTeam_XCom:
            m_strActiveTeam = strXComTurn;
            m_strActiveTeamColor = class'UIUtilities_Colors'.static.ConvertWidgetColorToHTML(eColor_Xcom);
            break;
        default:
            m_strActiveTeam = "";
            m_strActiveTeamColor = "";
            break;
    }

    // Give mods a chance to override what we show, especially if they add new teams
    OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'DirectControl_OverrideTeamNameAndColor';
	OverrideTuple.Data.Add(3);

	OverrideTuple.Data[0].kind = XComLWTVString;
    OverrideTuple.Data[0].s = m_strActiveTeam;

    OverrideTuple.Data[1].kind = XComLWTVString;
    OverrideTuple.Data[1].s = m_strActiveTeamColor;

    OverrideTuple.Data[2].kind = XComLWTVObject;
    OverrideTuple.Data[2].o = PlayerState;

	`XEVENTMGR.TriggerEvent('DirectControl_OverrideTeamNameAndColor', OverrideTuple, PlayerState, none);

    m_strActiveTeam = OverrideTuple.Data[0].s;
    m_strActiveTeamColor = OverrideTuple.Data[1].s;
}

private function bool ShouldShow(optional XComGameState_Player PlayerState)
{
    if (!`DC_CFG(bShowTurnTimer))
    {
        return false;
    }

    if (PlayerState == none)
    {
        PlayerState = class'DirectControlUtils'.static.GetActivePlayer();
    }

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

    if (`DC_CFG(bTurnTimerShowsActiveTeam))
    {
        strDisplayText = Repl(strDisplayText, "<Team/>", m_strActiveTeam);
        strDisplayText = Repl(strDisplayText, "<TurnNumber/>", m_iCurrentTurnNumber);
    }

    strDisplayText = "<font color='#" $ m_strActiveTeamColor $ "'>" $ strDisplayText $ "</font>";

    m_txtTimer.SetText(strDisplayText, OnLabelTextSizeRealized);
}