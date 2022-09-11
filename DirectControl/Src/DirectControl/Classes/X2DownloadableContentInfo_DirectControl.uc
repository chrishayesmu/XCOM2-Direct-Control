class X2DownloadableContentInfo_DirectControl extends X2DownloadableContentInfo;

static function OnConfigChanged()
{
    `DC_LOG("Config modified; notifying submods for changes");

    // Some submods will need to make changes whenever config changes
    class'DirectControlSubmod_AdventReinforcements'.static.OnPostTemplatesCreated();

    // Fire off a generic event as well for places that can utilize it
    `XEVENTMGR.TriggerEvent('DirectControlConfigChanged');
}

static event OnPostTemplatesCreated()
{
    class'DirectControlSubmod_AdventReinforcements'.static.OnPostTemplatesCreated();
}