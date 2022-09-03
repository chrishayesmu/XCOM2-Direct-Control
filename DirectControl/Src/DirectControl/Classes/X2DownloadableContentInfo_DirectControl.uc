class X2DownloadableContentInfo_DirectControl extends X2DownloadableContentInfo;

// TODO delete
exec function DebugBorder()
{
    `DC_LOG("bUIHidden = " $ class'XComWorldData'.static.GetWorldData().Volume.BorderComponent.bUIHidden);
    `DC_LOG("bCustomHidden = " $ class'XComWorldData'.static.GetWorldData().Volume.BorderComponent.bCustomHidden);
    `DC_LOG("bCinematicHidden = " $ class'XComWorldData'.static.GetWorldData().Volume.BorderComponent.bCinematicHidden);
    `DC_LOG("LastUnit = " $ class'XComWorldData'.static.GetWorldData().Volume.BorderComponent.LastUnit);

    `DC_LOG("m_kPathingPawn.LastActiveUnit = " $ XComTacticalController(`LOCALPLAYERCONTROLLER).m_kPathingPawn.LastActiveUnit);
    `DC_LOG("XComTacticalController.m_kActiveUnit = " $ XComTacticalController(`LOCALPLAYERCONTROLLER).m_kActiveUnit);

    XComTacticalController(`LOCALPLAYERCONTROLLER).m_kPathingPawn.SetActive(XComTacticalController(`LOCALPLAYERCONTROLLER).m_kActiveUnit);

    class'XComWorldData'.static.GetWorldData().Volume.BorderComponent.LastUnit = XComTacticalController(`LOCALPLAYERCONTROLLER).m_kActiveUnit;

    class'XComWorldData'.static.GetWorldData().Volume.BorderComponent.SetCustomHidden(true);
    class'XComWorldData'.static.GetWorldData().Volume.BorderComponent.SetCustomHidden(false);
}