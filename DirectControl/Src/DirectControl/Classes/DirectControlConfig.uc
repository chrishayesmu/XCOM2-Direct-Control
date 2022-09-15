class DirectControlConfig extends UIScreenListener
    config(DirectControlConfig);

var config int ConfigVersion;

/////////////////////////////////////////////////
// Base mod config: team control
/////////////////////////////////////////////////

var config bool bPlayerControlsAlienTurn;
var config bool bPlayerControlsUnactivatedAliens;

var config bool bPlayerControlsResistanceTurn;
var config bool bPlayerControlsUnactivatedResistance;

var config bool bPlayerControlsLostTurn;
var config bool bPlayerControlsUnactivatedLost;

var config bool bPlayerControlsTeamOneTurn;
var config bool bPlayerControlsUnactivatedTeamOne;

var config bool bPlayerControlsTeamTwoTurn;
var config bool bPlayerControlsUnactivatedTeamTwo;

var config bool bForceControlledUnitsToRun;

/////////////////////////////////////////////////
// Base mod config: turn timer
/////////////////////////////////////////////////

var config bool bShowTurnTimer;
var config bool bTurnTimerShowsActiveTeam;

/////////////////////////////////////////////////
// Submod config: ADVENT Reinforcements
/////////////////////////////////////////////////

var config bool  bAdventReinforcements_EnableSubmod;
var config float fAdventReinforcements_ReinforcementPlacementRange;
var config bool  bAdventReinforcements_RequireSquadLosToTargetTile;

var const localized string strPageHeader;

var const localized string strGeneralGroupHeader;
var const localized string strLabelPlayerControlsAlienTurn;
var const localized string strTooltipPlayerControlsAlienTurn;
var const localized string strLabelPlayerControlsUnactivatedAliens;
var const localized string strTooltipPlayerControlsUnactivatedAliens;
var const localized string strLabelPlayerControlsResistanceTurn;
var const localized string strTooltipPlayerControlsResistanceTurn;
var const localized string strLabelPlayerControlsUnactivatedResistance;
var const localized string strTooltipPlayerControlsUnactivatedResistance;
var const localized string strLabelPlayerControlsLostTurn;
var const localized string strTooltipPlayerControlsLostTurn;
var const localized string strLabelPlayerControlsUnactivatedLost;
var const localized string strTooltipPlayerControlsUnactivatedLost;
var const localized string strLabelPlayerControlsTeamOneTurn;
var const localized string strTooltipPlayerControlsTeamOneTurn;
var const localized string strLabelPlayerControlsUnactivatedTeamOne;
var const localized string strTooltipPlayerControlsUnactivatedTeamOne;
var const localized string strLabelPlayerControlsTeamTwoTurn;
var const localized string strTooltipPlayerControlsTeamTwoTurn;
var const localized string strLabelPlayerControlsUnactivatedTeamTwo;
var const localized string strTooltipPlayerControlsUnactivatedTeamTwo;
var const localized string strLabelForceControlledUnitsToRun;
var const localized string strTooltipForceControlledUnitsToRun;

var const localized string strTurnTimerGroupHeader;
var const localized string strLabelTurnTimerEnabled;
var const localized string strTooltipTurnTimerEnabled;
var const localized string strLabelTurnTimerShowsActiveTeam;
var const localized string strTooltipTurnTimerShowsActiveTeam;

var const localized string strAdventReinforcementsGroupHeader;
var const localized string strLabelAdventReinforcementsEnabled;
var const localized string strTooltipAdventReinforcementsEnabled;
var const localized string strLabelAdventReinforcementsPlacementRange;
var const localized string strTooltipAdventReinforcementsPlacementRange;
var const localized string strLabelAdventReinforcementsRequireLos;
var const localized string strTooltipAdventReinforcementsRequireLos;

`include(DirectControl/Src/ModConfigMenuAPI/MCM_API_Includes.uci)
`include(DirectControl/Src/ModConfigMenuAPI/MCM_API_CfgHelpers.uci)

`MCM_CH_VersionChecker(class'DirectControlConfigDefaults'.default.ConfigVersion, ConfigVersion);

event OnInit(UIScreen Screen)
{
	if (MCM_API(Screen) != none)
    {
		`MCM_API_Register(Screen, ClientModCallback);
	}
}

function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
    local MCM_API_SettingsPage Page;
    local MCM_API_SettingsGroup Group;

    LoadSavedSettings();

    Page = ConfigAPI.NewSettingsPage(strPageHeader);
    Page.SetSaveHandler(SaveButtonClicked);

    Group = Page.AddGroup('DirectControlGeneralSettings', strGeneralGroupHeader);
    Group.AddCheckbox(nameof(bPlayerControlsAlienTurn),             strLabelPlayerControlsAlienTurn,             strTooltipPlayerControlsAlienTurn,             bPlayerControlsAlienTurn,             PlayerControlsAlienTurnSaveHandler);
    Group.AddCheckbox(nameof(bPlayerControlsUnactivatedAliens),     strLabelPlayerControlsUnactivatedAliens,     strTooltipPlayerControlsUnactivatedAliens,     bPlayerControlsUnactivatedAliens,     PlayerControlsUnactivatedAliensTurnSaveHandler);
    Group.AddCheckbox(nameof(bPlayerControlsResistanceTurn),        strLabelPlayerControlsResistanceTurn,        strTooltipPlayerControlsResistanceTurn,        bPlayerControlsResistanceTurn,        PlayerControlsResistanceTurnSaveHandler);
    Group.AddCheckbox(nameof(bPlayerControlsUnactivatedResistance), strLabelPlayerControlsUnactivatedResistance, strTooltipPlayerControlsUnactivatedResistance, bPlayerControlsUnactivatedResistance, PlayerControlsUnactivatedResistanceTurnSaveHandler);
    Group.AddCheckbox(nameof(bPlayerControlsLostTurn),              strLabelPlayerControlsLostTurn,              strTooltipPlayerControlsLostTurn,              bPlayerControlsLostTurn,              PlayerControlsLostTurnSaveHandler);
    Group.AddCheckbox(nameof(bPlayerControlsUnactivatedLost),       strLabelPlayerControlsUnactivatedLost,       strTooltipPlayerControlsUnactivatedLost,       bPlayerControlsUnactivatedLost,       PlayerControlsUnactivatedLostTurnSaveHandler);
    Group.AddCheckbox(nameof(bPlayerControlsTeamOneTurn),           strLabelPlayerControlsTeamOneTurn,           strTooltipPlayerControlsTeamOneTurn,           bPlayerControlsTeamOneTurn,           PlayerControlsTeamOneTurnSaveHandler);
    Group.AddCheckbox(nameof(bPlayerControlsUnactivatedTeamOne),    strLabelPlayerControlsUnactivatedTeamOne,    strTooltipPlayerControlsUnactivatedTeamOne,    bPlayerControlsUnactivatedTeamOne,    PlayerControlsUnactivatedTeamOneTurnSaveHandler);
    Group.AddCheckbox(nameof(bPlayerControlsTeamTwoTurn),           strLabelPlayerControlsTeamTwoTurn,           strTooltipPlayerControlsTeamTwoTurn,           bPlayerControlsTeamTwoTurn,           PlayerControlsTeamTwoTurnSaveHandler);
    Group.AddCheckbox(nameof(bPlayerControlsUnactivatedTeamTwo),    strLabelPlayerControlsUnactivatedTeamTwo,    strTooltipPlayerControlsUnactivatedTeamTwo,    bPlayerControlsUnactivatedTeamTwo,    PlayerControlsUnactivatedTeamTwoTurnSaveHandler);
    Group.AddCheckbox(nameof(bForceControlledUnitsToRun),           strLabelForceControlledUnitsToRun,           strTooltipForceControlledUnitsToRun,           bForceControlledUnitsToRun,           ForceInactiveUnitsToRunSaveHandler);

    Group = Page.AddGroup('DirectControlTurnTimerSettings', strTurnTimerGroupHeader);
    Group.AddCheckbox(nameof(bShowTurnTimer),            strLabelTurnTimerEnabled,         strTooltipTurnTimerEnabled,         bShowTurnTimer,            TurnTimerEnabledSaveHandler);
    Group.AddCheckbox(nameof(bTurnTimerShowsActiveTeam), strLabelTurnTimerShowsActiveTeam, strTooltipTurnTimerShowsActiveTeam, bTurnTimerShowsActiveTeam, TurnTimerShowsTeamSaveHandler);

    if (class'DirectControlUtils'.static.IsModActive('WOTCAdventReinforcements'))
    {
        AddSubmodSettings_AdventReinforcements(Page);
    }

    Page.ShowSettings();
}

private function AddSubmodSettings_AdventReinforcements(MCM_API_SettingsPage Page)
{
    local MCM_API_SettingsGroup Group;

    Group = Page.AddGroup('DirectControlSubmodSettings_AdventReinforcements', strAdventReinforcementsGroupHeader);
    Group.AddCheckbox(nameof(bAdventReinforcements_EnableSubmod),                strLabelAdventReinforcementsEnabled,        strTooltipAdventReinforcementsEnabled,                  bAdventReinforcements_EnableSubmod,                AdventReinforcements_EnableSubmodSaveHandler);
    Group.AddCheckbox(nameof(bAdventReinforcements_RequireSquadLosToTargetTile), strLabelAdventReinforcementsRequireLos,     strTooltipAdventReinforcementsRequireLos,               bAdventReinforcements_RequireSquadLosToTargetTile, AdventReinforcements_RequireSquadLosSaveHandler);
    Group.AddSlider(nameof(fAdventReinforcements_ReinforcementPlacementRange),   strLabelAdventReinforcementsPlacementRange, strTooltipAdventReinforcementsPlacementRange, 0, 50, 1, fAdventReinforcements_ReinforcementPlacementRange, AdventReinforcements_PlacementRangeSaveHandler);
}

private function LoadSavedSettings()
{
    bPlayerControlsAlienTurn = `DC_CFG(bPlayerControlsAlienTurn);
    bPlayerControlsUnactivatedAliens = `DC_CFG(bPlayerControlsUnactivatedAliens);
    bPlayerControlsResistanceTurn = `DC_CFG(bPlayerControlsResistanceTurn);
    bPlayerControlsUnactivatedResistance = `DC_CFG(bPlayerControlsUnactivatedResistance);
    bPlayerControlsLostTurn = `DC_CFG(bPlayerControlsLostTurn);
    bPlayerControlsUnactivatedLost = `DC_CFG(bPlayerControlsUnactivatedLost);
    bPlayerControlsTeamOneTurn = `DC_CFG(bPlayerControlsTeamOneTurn);
    bPlayerControlsUnactivatedTeamOne = `DC_CFG(bPlayerControlsUnactivatedTeamOne);
    bPlayerControlsTeamTwoTurn = `DC_CFG(bPlayerControlsTeamTwoTurn);
    bPlayerControlsUnactivatedTeamTwo = `DC_CFG(bPlayerControlsUnactivatedTeamTwo);
    bForceControlledUnitsToRun = `DC_CFG(bForceControlledUnitsToRun);

    bShowTurnTimer = `DC_CFG(bShowTurnTimer);
    bTurnTimerShowsActiveTeam = `DC_CFG(bTurnTimerShowsActiveTeam);

    bAdventReinforcements_EnableSubmod = `DC_CFG(bAdventReinforcements_EnableSubmod);
    fAdventReinforcements_ReinforcementPlacementRange = `DC_CFG(fAdventReinforcements_ReinforcementPlacementRange);
    bAdventReinforcements_RequireSquadLosToTargetTile = `DC_CFG(bAdventReinforcements_RequireSquadLosToTargetTile);

    if (class'DirectControlConfigDefaults'.default.ConfigVersion > default.ConfigVersion)
    {
        default.ConfigVersion = class'DirectControlConfigDefaults'.default.ConfigVersion;
        self.SaveConfig();
    }
}

private function SaveButtonClicked(MCM_API_SettingsPage Page)
{
    ConfigVersion = `MCM_CH_GetCompositeVersion();
    SaveConfig();

    class'X2DownloadableContentInfo_DirectControl'.static.OnConfigChanged();
}

`MCM_API_BasicCheckboxSaveHandler(PlayerControlsAlienTurnSaveHandler, bPlayerControlsAlienTurn);
`MCM_API_BasicCheckboxSaveHandler(PlayerControlsUnactivatedAliensTurnSaveHandler, bPlayerControlsUnactivatedAliens);
`MCM_API_BasicCheckboxSaveHandler(PlayerControlsResistanceTurnSaveHandler, bPlayerControlsResistanceTurn);
`MCM_API_BasicCheckboxSaveHandler(PlayerControlsUnactivatedResistanceTurnSaveHandler, bPlayerControlsUnactivatedResistance);
`MCM_API_BasicCheckboxSaveHandler(PlayerControlsLostTurnSaveHandler, bPlayerControlsLostTurn);
`MCM_API_BasicCheckboxSaveHandler(PlayerControlsUnactivatedLostTurnSaveHandler, bPlayerControlsUnactivatedLost);
`MCM_API_BasicCheckboxSaveHandler(PlayerControlsTeamOneTurnSaveHandler, bPlayerControlsTeamOneTurn);
`MCM_API_BasicCheckboxSaveHandler(PlayerControlsUnactivatedTeamOneTurnSaveHandler, bPlayerControlsUnactivatedTeamOne);
`MCM_API_BasicCheckboxSaveHandler(PlayerControlsTeamTwoTurnSaveHandler, bPlayerControlsTeamTwoTurn);
`MCM_API_BasicCheckboxSaveHandler(PlayerControlsUnactivatedTeamTwoTurnSaveHandler, bPlayerControlsUnactivatedTeamTwo);
`MCM_API_BasicCheckboxSaveHandler(ForceInactiveUnitsToRunSaveHandler, bForceControlledUnitsToRun);

`MCM_API_BasicCheckboxSaveHandler(TurnTimerEnabledSaveHandler, bShowTurnTimer);
`MCM_API_BasicCheckboxSaveHandler(TurnTimerShowsTeamSaveHandler, bTurnTimerShowsActiveTeam);

`MCM_API_BasicCheckboxSaveHandler(AdventReinforcements_EnableSubmodSaveHandler, bAdventReinforcements_EnableSubmod);
`MCM_API_BasicSliderSaveHandler(AdventReinforcements_PlacementRangeSaveHandler, fAdventReinforcements_ReinforcementPlacementRange);
`MCM_API_BasicCheckboxSaveHandler(AdventReinforcements_RequireSquadLosSaveHandler, bAdventReinforcements_RequireSquadLosToTargetTile);