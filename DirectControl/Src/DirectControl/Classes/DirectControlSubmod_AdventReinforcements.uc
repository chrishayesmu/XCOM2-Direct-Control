class DirectControlSubmod_AdventReinforcements extends Object
    abstract;

const TARGET_TEMPLATE_NAME = 'AdventCommander_CallReinforcements';

static function OnPostTemplatesCreated()
{
    local X2AbilityTemplateManager AbilityMgr;
	local X2AbilityTemplate Template;

    AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
    Template = AbilityMgr.FindAbilityTemplate('AdventCommander_CallReinforcements');

    if (Template == none)
    {
        `DC_LOG("Didn't find the ability template '" $ TARGET_TEMPLATE_NAME $ "'. Taking no action.");
        return;
    }

    // If this setting is changed via MCM, the template may already have been changed. We need to handle putting it back
    // to default in that case.
    if (`DC_CFG(bAdventReinforcements_EnableSubmod))
    {
        `DC_LOG("Ability template '" $ TARGET_TEMPLATE_NAME $ "' located, and submod enabled. Modifying targeting criteria.");
        ReplaceAbilityWithDCVersion(Template);
    }
    else
    {
        `DC_LOG("Ability template '" $ TARGET_TEMPLATE_NAME $ "' located, and submod disabled. Restoring ability to default.");
        ResetAbilityToBaseVersion(Template);
    }
}

private static function ReplaceAbilityWithDCVersion(X2AbilityTemplate Template)
{
	local X2AbilityTarget_Cursor CursorTarget;
	local X2Effect_CommanderReinforcements_DirectControl ReinforceEffect;

	Template.TargetingMethod = class'X2TargetingMethod_Teleport';

	CursorTarget = new class'X2AbilityTarget_Cursor';
    CursorTarget.FixedAbilityRange = `DC_CFG(fAdventReinforcements_ReinforcementPlacementRange);
    CursorTarget.bRestrictToSquadsightRange = `DC_CFG(bAdventReinforcements_RequireSquadLosToTargetTile);
	Template.AbilityTargetStyle = CursorTarget;

    // Remove the default ability effect of spawning reinforcements somewhere nearby, in favor of ours
    Template.AbilityShooterEffects.Remove(0, Template.AbilityShooterEffects.Length);

	ReinforceEffect = new class'X2Effect_CommanderReinforcements_DirectControl';
	Template.AddShooterEffect(ReinforceEffect);
}

private static function ResetAbilityToBaseVersion(X2AbilityTemplate Template)
{
	local X2Effect_CommanderReinforcements ReinforceEffect;

	Template.TargetingMethod = class'X2AbilityTemplate'.default.TargetingMethod;
    Template.AbilityTargetStyle = class'X2Ability'.default.SelfTarget;

    Template.AbilityShooterEffects.Remove(0, Template.AbilityShooterEffects.Length);

	ReinforceEffect = new class'X2Effect_CommanderReinforcements';
	Template.AddShooterEffect(ReinforceEffect);
}