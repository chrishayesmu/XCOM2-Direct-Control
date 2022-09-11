class DirectControlConfigDefaults extends Object
    config(DirectControlConfigDefaults);

var config int ConfigVersion;

/////////////////////////////////////////////////
// Base mod config: team control
/////////////////////////////////////////////////

var config bool bPlayerControlsAlienTurn;
var config bool bPlayerControlsUnactivatedAliens;

var config bool bPlayerControlsLostTurn;
var config bool bPlayerControlsUnactivatedLost;

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