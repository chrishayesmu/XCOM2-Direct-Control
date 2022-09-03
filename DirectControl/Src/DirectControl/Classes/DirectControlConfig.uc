class DirectControlConfig extends UIScreenListener
    config(DirectControlConfig);

var config int ConfigVersion;

var config bool bPlayerControlsAlienTurn;
var config bool bPlayerControlsUnactivatedAliens;

var config bool bPlayerControlsLostTurn;
var config bool bPlayerControlsUnactivatedLost;

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

    Page = ConfigAPI.NewSettingsPage("Direct Control");
    Page.SetSaveHandler(SaveButtonClicked);

    Group = Page.AddGroup('DirectControlGeneralSettings', "General");
    Group.AddCheckbox(nameof(bPlayerControlsAlienTurn),         "Control Alien Turn",      "", bPlayerControlsAlienTurn,         PlayerControlsAlienTurnSaveHandler);
    Group.AddCheckbox(nameof(bPlayerControlsUnactivatedAliens), "Control Inactive Aliens", "", bPlayerControlsUnactivatedAliens, PlayerControlsUnactivatedAliensTurnSaveHandler);
    Group.AddCheckbox(nameof(bPlayerControlsLostTurn),          "Control Lost Turn",       "", bPlayerControlsLostTurn,          PlayerControlsLostTurnSaveHandler);
    Group.AddCheckbox(nameof(bPlayerControlsUnactivatedLost),   "Control Inactive Lost",   "", bPlayerControlsUnactivatedLost,   PlayerControlsUnactivatedLostTurnSaveHandler);

    Page.ShowSettings();
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
}

`MCM_API_BasicCheckboxSaveHandler(PlayerControlsAlienTurnSaveHandler, bPlayerControlsAlienTurn);
`MCM_API_BasicCheckboxSaveHandler(PlayerControlsUnactivatedAliensTurnSaveHandler, bPlayerControlsUnactivatedAliens);
`MCM_API_BasicCheckboxSaveHandler(PlayerControlsLostTurnSaveHandler, bPlayerControlsLostTurn);
`MCM_API_BasicCheckboxSaveHandler(PlayerControlsUnactivatedLostTurnSaveHandler, bPlayerControlsUnactivatedLost);