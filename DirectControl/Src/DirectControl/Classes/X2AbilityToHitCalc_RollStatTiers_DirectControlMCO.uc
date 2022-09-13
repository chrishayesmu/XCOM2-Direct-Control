class X2AbilityToHitCalc_RollStatTiers_DirectControlMCO extends X2AbilityToHitCalc_RollStatTiers;

function int GetHitChance(XComGameState_Ability kAbility, AvailableTarget kTarget, optional out ShotBreakdown m_ShotBreakdown, optional bool bDebugLog = false)
{
    local int FinalHitChance;
    local ShotBreakdown EmptyBreakdown;

	FinalHitChance = super.GetHitChance(kAbility, kTarget, m_ShotBreakdown, bDebugLog);

    m_ShotBreakdown = EmptyBreakdown;
    AddModifier(FinalHitChance, kAbility.GetMyTemplate().LocFriendlyName, m_ShotBreakdown, eHit_Success, bDebugLog);

	return FinalHitChance;
}