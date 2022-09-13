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

    ModifyBaseGameAbilities();
}

private static function ModifyBaseGameAbilities()
{
    local int Index;
    local X2AbilityTemplateManager AbilityMgr;
	local X2AbilityTemplate Template;

    AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

    /////////////////////////////////////////////
    // Abilities common to all Chosen
    /////////////////////////////////////////////

    // Triggered-only ability
    Template = AbilityMgr.FindAbilityTemplate('ChosenExtractKnowledge');
    Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;

    // Triggered-only ability
    Template = AbilityMgr.FindAbilityTemplate('ChosenKidnap');
    Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;

    // Special ability which normally doesn't show, but should be accessible to players
    Template = AbilityMgr.FindAbilityTemplate('ChosenSummonFollowers');
    Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.bDontDisplayInAbilitySummary = false;
    Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_advent_commandaura";

    /////////////////////////////////////////////
    // Chosen Assassin abilities
    /////////////////////////////////////////////

    // Triggered-only ability
    Template = AbilityMgr.FindAbilityTemplate('VanishingWindReveal');
    Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
    RemoveInputTriggersOfType(Template, 'X2AbilityTrigger_PlayerInput');

    // Triggered-only ability
    Template = AbilityMgr.FindAbilityTemplate('VanishingWind_Scamper');
    Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
    RemoveInputTriggersOfType(Template, 'X2AbilityTrigger_PlayerInput');

    /////////////////////////////////////////////
    // Chosen Hunter abilities
    /////////////////////////////////////////////

    // The Hunter has a Killzone ability that he can't actually use, because it costs his weapon AP plus 1,
    // and his weapon AP is 2. We remove the additional AP so it's actually usable.
    Template = AbilityMgr.FindAbilityTemplate('HunterKillzone');

	for (Index = 0; Index < Template.AbilityCosts.Length; Index++)
	{
		if (Template.AbilityCosts[Index].IsA('X2AbilityCost_ActionPoints'))
		{
			X2AbilityCost_ActionPoints(Template.AbilityCosts[Index]).iNumPoints = 0;
			break;
		}
	}

    // Triggered-only ability
    Template = AbilityMgr.FindAbilityTemplate('TrackingShot');
    Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
    RemoveInputTriggersOfType(Template, 'X2AbilityTrigger_PlayerInput');

    // Tracking Shot has a curious condition: it can't be used unless a certain amount of alien units are engaged.
    // This AI restriction doesn't make sense for us, so we remove it.
    // TODO: if the alien team isn't being controlled, this changes the Hunter's behavior
    // TODO: we are temporarily hiding Tracking Shot. Normally the follow-up shot is fired by an AI routine,
    // which obviously doesn't occur for us, so the ability is useless. Re-enable Tracking Shot when we find an alternative.
    Template = AbilityMgr.FindAbilityTemplate('TrackingShotMark');
    Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
    RemoveShooterConditionsOfType(Template, 'X2Condition_BattleState');

    /////////////////////////////////////////////
    // Chosen Warlock abilities
    /////////////////////////////////////////////

    // Only available when Spectral Army is active
    Template = AbilityMgr.FindAbilityTemplate('EndSpectralArmy');
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
}

private static function RemoveInputTriggersOfType(X2AbilityTemplate Template, name TriggerType)
{
    local int Index;

    for (Index = 0; Index < Template.AbilityTriggers.Length; Index++)
    {
        if (Template.AbilityTriggers[Index].IsA(TriggerType))
        {
            Template.AbilityTriggers.Remove(Index, 1);
            Index--;
        }
    }
}

private static function RemoveShooterConditionsOfType(X2AbilityTemplate Template, name ConditionType)
{
    local int Index;

    for (Index = 0; Index < Template.AbilityShooterConditions.Length; Index++)
    {
        if (Template.AbilityShooterConditions[Index].IsA(ConditionType))
        {
            Template.AbilityShooterConditions.Remove(Index, 1);
            Index--;
        }
    }
}

exec function DCDebugBorder()
{
    local XComWorldData WorldData;
    local XComTacticalController kLocalPC;
    local XComTacticalInput TacticalInput;

    WorldData = class'XComWorldData'.static.GetWorldData();
    kLocalPC = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
    TacticalInput = XComTacticalInput(kLocalPC.PlayerInput);

    class'Helpers'.static.OutputMsg("WorldData.Volume.BorderComponent.bCustomHidden = " $ WorldData.Volume.BorderComponent.bCustomHidden);
    class'Helpers'.static.OutputMsg("WorldData.Volume.BorderComponent.bCinematicHidden = " $ WorldData.Volume.BorderComponent.bCinematicHidden);
    class'Helpers'.static.OutputMsg("WorldData.Volume.BorderComponent.bUIHidden = " $ WorldData.Volume.BorderComponent.bUIHidden);
    class'Helpers'.static.OutputMsg("WorldData.Volume.BorderComponent.LastUnit = " $ WorldData.Volume.BorderComponent.LastUnit);
    class'Helpers'.static.OutputMsg("CAMERASTACK.ActiveCameraHidesBorder() = " $ `CAMERASTACK.ActiveCameraHidesBorder());
    class'Helpers'.static.OutputMsg("kLocalPC.m_kPathingPawn.m_bVisible = " $ kLocalPC.m_kPathingPawn.m_bVisible);
    class'Helpers'.static.OutputMsg("kLocalPC.GetInputState() = " $ kLocalPC.GetInputState());

    WorldData.Volume.BorderComponent.SetCustomHidden(false);
    WorldData.Volume.BorderComponentDashing.SetCustomHidden(false);
}