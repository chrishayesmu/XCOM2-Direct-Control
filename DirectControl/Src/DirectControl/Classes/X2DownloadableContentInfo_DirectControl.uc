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
    local bool bPresent;
    local int Index;
    local X2Effect_GrantActionPoints ActionPointsEffect;
    local X2Condition_Visibility VisibilityCondition;
    local X2AbilityTemplateManager AbilityMgr;
	local X2AbilityTemplate Template;

    `DC_LOG("Modifying base game abilities for greater compatibility with Direct Control..");

    AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

    /////////////////////////////////////////////
    // Abilities common to all Chosen
    /////////////////////////////////////////////

    // Hide the innate "cannot be killed" ability of Chosen from showing in bottom left passive list
    Template = AbilityMgr.FindAbilityTemplate('ChosenDefeatedSustain');
    X2Effect_Sustain(Template.AbilityTargetEffects[0]).bDisplayInUI = false;

    // Triggered-only ability
    Template = AbilityMgr.FindAbilityTemplate('ChosenExtractKnowledge');
    Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;

    // Triggered-only ability
    Template = AbilityMgr.FindAbilityTemplate('ChosenKidnap');
    Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;

    // Special ability which normally doesn't show, but should be accessible to players
    Template = AbilityMgr.FindAbilityTemplate('ChosenSummonFollowers');
    Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
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

    // Incorrect image
    Template = AbilityMgr.FindAbilityTemplate('Farsight');
    Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_farsight";
    X2Effect_Persistent(Template.AbilityTargetEffects[0]).IconImage = Template.IconImage;

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

    Template = AbilityMgr.FindAbilityTemplate('TrackingShotMark');

    // Don't Move A Muscle (internal name TrackingShotReversal) changes how Tracking Shot Mark works, making it compatible
    // with Direct Control. Otherwise, we need to disable it.
    if (class'DirectControlUtils'.static.IsModActive('TrackingShotReversal'))
    {
        bPresent = false;

        // Tracking Shot Mark has no LoS requirement, so we need to add one; add a check in case this isn't
        // the first time we're iterating templates
	    for (Index = 0; Index < Template.AbilityTargetConditions.Length; Index++)
        {
            if (Template.AbilityTargetConditions[Index].IsA('X2Condition_Visibility') && X2Condition_Visibility(Template.AbilityTargetConditions[Index]).bRequireLOS)
            {
                bPresent = true;
                break;
            }
        }

        if (!bPresent)
        {
            VisibilityCondition = new class'X2Condition_Visibility';
            VisibilityCondition.bRequireLOS = true;
            Template.AbilityTargetConditions.AddItem(VisibilityCondition);
        }

        // We also make it a turn-ending action, since it makes no sense to set up for a shot and then move around, potentially losing LoS
	    for (Index = 0; Index < Template.AbilityCosts.Length; Index++)
        {
            if (Template.AbilityCosts[Index].IsA('X2AbilityCost_ActionPoints'))
            {
                X2AbilityCost_ActionPoints(Template.AbilityCosts[Index]).bConsumeAllPoints = true;
                break;
            }
        }
    }
    else
    {
        // Tracking Shot has a curious condition: it can't be used unless a certain amount of alien units are engaged.
        // This AI restriction doesn't make sense for us, so we remove it.
        // TODO: if the alien team isn't being controlled, this changes the Hunter's behavior
        // TODO: we are temporarily hiding Tracking Shot. Normally the follow-up shot is fired by an AI routine,
        // which obviously doesn't occur for us, so the ability is useless. Re-enable Tracking Shot when we find an alternative.
        Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
        RemoveShooterConditionsOfType(Template, 'X2Condition_BattleState');
    }

    /////////////////////////////////////////////
    // Chosen Warlock abilities
    /////////////////////////////////////////////

    // Only available when Spectral Army is active
    Template = AbilityMgr.FindAbilityTemplate('EndSpectralArmy');
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;

    /////////////////////////////////////////////
    // Abilities common to all Rulers
    /////////////////////////////////////////////

    // Incorrect image
    Template = AbilityMgr.FindAbilityTemplate('AlienRulerCallForEscape');

    // Need to make sure Alien Hunters is installed/enabled before we access its templates
    if (Template == none)
    {
        `DC_LOG("Alien Hunters DLC doesn't appear to be installed. Ending template modification here.");
        return;
    }

    Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_adventpsiwitch_dimensionrift";

    /////////////////////////////////////////////
    // Archon King abilities
    /////////////////////////////////////////////

    Template = AbilityMgr.FindAbilityTemplate('IcarusDropSlam');
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;

    /////////////////////////////////////////////
    // Berserker Queen abilities
    /////////////////////////////////////////////

    Template = AbilityMgr.FindAbilityTemplate('QueenDevastatingPunch');
    Template.ShotHUDPriority = 0;

    Template = AbilityMgr.FindAbilityTemplate('Quake');
	Template.IconImage = "img:///UILibrary_DLC2Images.UIPerk_beserker_quake";
    Template.ShotHUDPriority = 1;

    Template = AbilityMgr.FindAbilityTemplate('Faithbreaker');
    Template.ShotHUDPriority = 2;

    /////////////////////////////////////////////
    // Viper King abilities
    /////////////////////////////////////////////

	// Bind is misconfigured and doesn't give an AP that can be used to end it, like regular Viper bind does
	ActionPointsEffect = new class'X2Effect_GrantActionPoints';
	ActionPointsEffect.NumActionPoints = 1;
	ActionPointsEffect.PointType = class'X2CharacterTemplateManager'.default.EndBindActionPoint;

    // Viper King bind is set up wrong in a few ways
    Template = AbilityMgr.FindAbilityTemplate('KingBind');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_viper_bind";
	Template.AddShooterEffect(ActionPointsEffect);
    FixViperKingBind(Template);

    // The sustained version of the bind is also incorrect; it has an AP cost, which prevents it from firing
    Template = AbilityMgr.FindAbilityTemplate('KingBindSustained');
	Template.AddShooterEffect(ActionPointsEffect);
    Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_SustainedEffect');
    Template.AbilityCosts.Length = 0;
    RemoveInputTriggersOfType(Template, 'X2AbilityTrigger_PlayerInput');

    // Incorrect image
    Template = AbilityMgr.FindAbilityTemplate('Frostbite');
	Template.IconImage = "img:///UILibrary_DLC2Images.UIPerk_freezingbreath";
}

private static function FixViperKingBind(X2AbilityTemplate Template)
{
    local int Index;
    local X2Effect_ViperBindSustained SustainedEffect;

    // Seems like they forgot to put the ability name on the bind effect, so it always ends after one turn
    for (Index = 0; Index < Template.AbilityTargetEffects.Length; Index++)
    {
        SustainedEffect = X2Effect_ViperBindSustained(Template.AbilityTargetEffects[Index]);

        if (SustainedEffect != none)
        {
            SustainedEffect.SustainedAbilityName = 'KingBindSustained';
        }
    }
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