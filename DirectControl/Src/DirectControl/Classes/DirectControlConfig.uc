class DirectControlConfig extends UIScreenListener
    config(DirectControlConfig);

// LOAD_CFG(Cfg, Ver) will compare the version number stored in the non-default values to Ver. If the non-default config has been saved since
// version Ver was set up, the non-default value is used; otherwise, the default value is used.
`define LOAD_CFG(CfgName, MinVersion) (class'DirectControlConfig'.default.ConfigVersion >= `MinVersion ? class'DirectControlConfig'.default.`CfgName : class'DirectControlConfigDefaults'.default.`CfgName)

var config int ConfigVersion;

/////////////////////////////////////////////////
// Base mod config: team control
/////////////////////////////////////////////////

var config bool bPlayerControlsAlienTurn;
var config bool bPlayerControlsUnactivatedAliens;

var config bool bPlayerControlsChosenTurn;

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
var const localized string strLabelPlayerControlsChosenTurn;
var const localized string strTooltipPlayerControlsChosenTurn;
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

static function bool PlayerControlsChosen()
{
    // Chosen control setting was first added in our config version 5
    return `LOAD_CFG(bPlayerControlsChosenTurn, 5);
}

function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
    local MCM_API_Setting Setting;
    local MCM_API_SettingsPage Page;
    local MCM_API_SettingsGroup Group;

    LoadSavedSettings();

    Page = ConfigAPI.NewSettingsPage(strPageHeader);
    Page.SetSaveHandler(SaveButtonClicked);

    // Group: general settings
    Group = Page.AddGroup('DirectControlGeneralSettings', strGeneralGroupHeader);

    Setting = Group.AddCheckbox(nameof(bPlayerControlsAlienTurn), strLabelPlayerControlsAlienTurn,         strTooltipPlayerControlsAlienTurn,         bPlayerControlsAlienTurn,         PlayerControlsAlienTurnSaveHandler, DisableNextTwoSettingsWhenFalseHandler);
    Group.AddCheckbox(nameof(bPlayerControlsUnactivatedAliens),   strLabelPlayerControlsUnactivatedAliens, strTooltipPlayerControlsUnactivatedAliens, bPlayerControlsUnactivatedAliens, PlayerControlsUnactivatedAliensTurnSaveHandler);
    Group.AddCheckbox(nameof(bPlayerControlsChosenTurn), strLabelPlayerControlsChosenTurn, strTooltipPlayerControlsChosenTurn, bPlayerControlsChosenTurn, PlayerControlsChosenTurnSaveHandler);
    DisableNextTwoSettingsWhenFalseHandler(Setting, bPlayerControlsAlienTurn);

    Setting = Group.AddCheckbox(nameof(bPlayerControlsResistanceTurn), strLabelPlayerControlsResistanceTurn,        strTooltipPlayerControlsResistanceTurn,        bPlayerControlsResistanceTurn,        PlayerControlsResistanceTurnSaveHandler, DisableNextSettingWhenFalseHandler);
    Group.AddCheckbox(nameof(bPlayerControlsUnactivatedResistance),    strLabelPlayerControlsUnactivatedResistance, strTooltipPlayerControlsUnactivatedResistance, bPlayerControlsUnactivatedResistance, PlayerControlsUnactivatedResistanceTurnSaveHandler);
    DisableNextSettingWhenFalseHandler(Setting, bPlayerControlsResistanceTurn);

    Setting = Group.AddCheckbox(nameof(bPlayerControlsLostTurn), strLabelPlayerControlsLostTurn,        strTooltipPlayerControlsLostTurn,        bPlayerControlsLostTurn,        PlayerControlsLostTurnSaveHandler, DisableNextSettingWhenFalseHandler);
    Group.AddCheckbox(nameof(bPlayerControlsUnactivatedLost),    strLabelPlayerControlsUnactivatedLost, strTooltipPlayerControlsUnactivatedLost, bPlayerControlsUnactivatedLost, PlayerControlsUnactivatedLostTurnSaveHandler);
    DisableNextSettingWhenFalseHandler(Setting, bPlayerControlsLostTurn);

    Setting = Group.AddCheckbox(nameof(bPlayerControlsTeamOneTurn), strLabelPlayerControlsTeamOneTurn,        strTooltipPlayerControlsTeamOneTurn,        bPlayerControlsTeamOneTurn,        PlayerControlsTeamOneTurnSaveHandler, DisableNextSettingWhenFalseHandler);
    Group.AddCheckbox(nameof(bPlayerControlsUnactivatedTeamOne),    strLabelPlayerControlsUnactivatedTeamOne, strTooltipPlayerControlsUnactivatedTeamOne, bPlayerControlsUnactivatedTeamOne, PlayerControlsUnactivatedTeamOneTurnSaveHandler);
    DisableNextSettingWhenFalseHandler(Setting, bPlayerControlsTeamOneTurn);

    Setting = Group.AddCheckbox(nameof(bPlayerControlsTeamTwoTurn), strLabelPlayerControlsTeamTwoTurn,        strTooltipPlayerControlsTeamTwoTurn,        bPlayerControlsTeamTwoTurn,        PlayerControlsTeamTwoTurnSaveHandler, DisableNextSettingWhenFalseHandler);
    Group.AddCheckbox(nameof(bPlayerControlsUnactivatedTeamTwo),    strLabelPlayerControlsUnactivatedTeamTwo, strTooltipPlayerControlsUnactivatedTeamTwo, bPlayerControlsUnactivatedTeamTwo, PlayerControlsUnactivatedTeamTwoTurnSaveHandler);
    DisableNextSettingWhenFalseHandler(Setting, bPlayerControlsTeamTwoTurn);

    Group.AddCheckbox(nameof(bForceControlledUnitsToRun), strLabelForceControlledUnitsToRun, strTooltipForceControlledUnitsToRun, bForceControlledUnitsToRun, ForceInactiveUnitsToRunSaveHandler);

    // Group: turn timer settings
    Group = Page.AddGroup('DirectControlTurnTimerSettings', strTurnTimerGroupHeader);

    Setting = Group.AddCheckbox(nameof(bShowTurnTimer),  strLabelTurnTimerEnabled,         strTooltipTurnTimerEnabled,         bShowTurnTimer,            TurnTimerEnabledSaveHandler, DisableNextSettingWhenFalseHandler);
    Group.AddCheckbox(nameof(bTurnTimerShowsActiveTeam), strLabelTurnTimerShowsActiveTeam, strTooltipTurnTimerShowsActiveTeam, bTurnTimerShowsActiveTeam, TurnTimerShowsTeamSaveHandler);
    DisableNextSettingWhenFalseHandler(Setting, bShowTurnTimer);

    if (class'DirectControlUtils'.static.IsModActive('WOTCAdventReinforcements'))
    {
        AddSubmodSettings_AdventReinforcements(Page);
    }

    Page.ShowSettings();
}

private function AddSubmodSettings_AdventReinforcements(MCM_API_SettingsPage Page)
{
    local MCM_API_Setting Setting;
    local MCM_API_SettingsGroup Group;

    Group = Page.AddGroup('DirectControlSubmodSettings_AdventReinforcements', strAdventReinforcementsGroupHeader);

    Setting = Group.AddCheckbox(nameof(bAdventReinforcements_EnableSubmod),      strLabelAdventReinforcementsEnabled,        strTooltipAdventReinforcementsEnabled,                  bAdventReinforcements_EnableSubmod,                AdventReinforcements_EnableSubmodSaveHandler, DisableNextTwoSettingsWhenFalseHandler);
    Group.AddCheckbox(nameof(bAdventReinforcements_RequireSquadLosToTargetTile), strLabelAdventReinforcementsRequireLos,     strTooltipAdventReinforcementsRequireLos,               bAdventReinforcements_RequireSquadLosToTargetTile, AdventReinforcements_RequireSquadLosSaveHandler);
    Group.AddSlider(nameof(fAdventReinforcements_ReinforcementPlacementRange),   strLabelAdventReinforcementsPlacementRange, strTooltipAdventReinforcementsPlacementRange, 0, 50, 1, fAdventReinforcements_ReinforcementPlacementRange, AdventReinforcements_PlacementRangeSaveHandler);
    DisableNextTwoSettingsWhenFalseHandler(Setting, bAdventReinforcements_EnableSubmod);
}

private function DisableNextSettingWhenFalseHandler(MCM_API_Setting Setting, bool Value)
{
    local int Index;
    local MCM_API_Setting CurrentSetting;
    local MCM_API_SettingsGroup ParentGroup;

    ParentGroup = Setting.GetParentGroup();

    for (Index = 0; Index < ParentGroup.GetNumberOfSettings(); Index++)
    {
        CurrentSetting = ParentGroup.GetSettingByIndex(Index);

        if (CurrentSetting != Setting)
        {
            continue;
        }

        CurrentSetting = ParentGroup.GetSettingByIndex(Index + 1);
        CurrentSetting.SetEditable(Value);
        return;
    }
}

private function DisableNextTwoSettingsWhenFalseHandler(MCM_API_Setting Setting, bool Value)
{
    local int Index;
    local MCM_API_Setting CurrentSetting;
    local MCM_API_SettingsGroup ParentGroup;

    ParentGroup = Setting.GetParentGroup();

    for (Index = 0; Index < ParentGroup.GetNumberOfSettings(); Index++)
    {
        CurrentSetting = ParentGroup.GetSettingByIndex(Index);

        if (CurrentSetting != Setting)
        {
            continue;
        }

        CurrentSetting = ParentGroup.GetSettingByIndex(Index + 1);
        CurrentSetting.SetEditable(Value);

        CurrentSetting = ParentGroup.GetSettingByIndex(Index + 2);
        CurrentSetting.SetEditable(Value);

        return;
    }
}

private function LoadSavedSettings()
{
    // Settings dating back to config version 1
    bPlayerControlsAlienTurn = `LOAD_CFG(bPlayerControlsAlienTurn, 1);
    bPlayerControlsUnactivatedAliens = `LOAD_CFG(bPlayerControlsUnactivatedAliens, 1);
    bPlayerControlsResistanceTurn = `LOAD_CFG(bPlayerControlsResistanceTurn, 1);
    bPlayerControlsUnactivatedResistance = `LOAD_CFG(bPlayerControlsUnactivatedResistance, 1);
    bPlayerControlsLostTurn = `LOAD_CFG(bPlayerControlsLostTurn, 1);
    bPlayerControlsUnactivatedLost = `LOAD_CFG(bPlayerControlsUnactivatedLost, 1);
    bPlayerControlsTeamOneTurn = `LOAD_CFG(bPlayerControlsTeamOneTurn, 1);
    bPlayerControlsUnactivatedTeamOne = `LOAD_CFG(bPlayerControlsUnactivatedTeamOne, 1);
    bPlayerControlsTeamTwoTurn = `LOAD_CFG(bPlayerControlsTeamTwoTurn, 1);
    bPlayerControlsUnactivatedTeamTwo = `LOAD_CFG(bPlayerControlsUnactivatedTeamTwo, 1);
    bForceControlledUnitsToRun = `LOAD_CFG(bForceControlledUnitsToRun, 1);

    bShowTurnTimer = `LOAD_CFG(bShowTurnTimer, 1);
    bTurnTimerShowsActiveTeam = `LOAD_CFG(bTurnTimerShowsActiveTeam, 1);

    bAdventReinforcements_EnableSubmod = `LOAD_CFG(bAdventReinforcements_EnableSubmod, 1);
    fAdventReinforcements_ReinforcementPlacementRange = `LOAD_CFG(fAdventReinforcements_ReinforcementPlacementRange, 1);
    bAdventReinforcements_RequireSquadLosToTargetTile = `LOAD_CFG(bAdventReinforcements_RequireSquadLosToTargetTile, 1);

    // Settings dating back to config version 5
    bPlayerControlsChosenTurn = PlayerControlsChosen();

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
`MCM_API_BasicCheckboxSaveHandler(PlayerControlsChosenTurnSaveHandler, bPlayerControlsChosenTurn);
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