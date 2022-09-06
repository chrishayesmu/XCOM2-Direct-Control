class DirectControlConfig extends UIScreenListener
    config(DirectControlConfig);

var config int ConfigVersion;

/////////////////////////////////////////////////
// Base mod config
/////////////////////////////////////////////////

var config bool bPlayerControlsAlienTurn;
var config bool bPlayerControlsUnactivatedAliens;

var config bool bPlayerControlsLostTurn;
var config bool bPlayerControlsUnactivatedLost;

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
var const localized string strLabelPlayerControlsLostTurn;
var const localized string strTooltipPlayerControlsLostTurn;
var const localized string strLabelPlayerControlsUnactivatedLost;
var const localized string strTooltipPlayerControlsUnactivatedLost;

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
    Group.AddCheckbox(nameof(bPlayerControlsAlienTurn),         strLabelPlayerControlsAlienTurn,         strTooltipPlayerControlsAlienTurn,         bPlayerControlsAlienTurn,         PlayerControlsAlienTurnSaveHandler);
    Group.AddCheckbox(nameof(bPlayerControlsUnactivatedAliens), strLabelPlayerControlsUnactivatedAliens, strTooltipPlayerControlsUnactivatedAliens, bPlayerControlsUnactivatedAliens, PlayerControlsUnactivatedAliensTurnSaveHandler);
    Group.AddCheckbox(nameof(bPlayerControlsLostTurn),          strLabelPlayerControlsLostTurn,          strTooltipPlayerControlsLostTurn,          bPlayerControlsLostTurn,          PlayerControlsLostTurnSaveHandler);
    Group.AddCheckbox(nameof(bPlayerControlsUnactivatedLost),   strLabelPlayerControlsUnactivatedLost,   strTooltipPlayerControlsUnactivatedLost,   bPlayerControlsUnactivatedLost,   PlayerControlsUnactivatedLostTurnSaveHandler);

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
`MCM_API_BasicCheckboxSaveHandler(PlayerControlsLostTurnSaveHandler, bPlayerControlsLostTurn);
`MCM_API_BasicCheckboxSaveHandler(PlayerControlsUnactivatedLostTurnSaveHandler, bPlayerControlsUnactivatedLost);

`MCM_API_BasicCheckboxSaveHandler(AdventReinforcements_EnableSubmodSaveHandler, bAdventReinforcements_EnableSubmod);
`MCM_API_BasicSliderSaveHandler(AdventReinforcements_PlacementRangeSaveHandler, fAdventReinforcements_ReinforcementPlacementRange);
`MCM_API_BasicCheckboxSaveHandler(AdventReinforcements_RequireSquadLosSaveHandler, bAdventReinforcements_RequireSquadLosToTargetTile);