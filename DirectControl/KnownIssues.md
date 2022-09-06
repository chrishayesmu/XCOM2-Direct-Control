# Known Issues

## Enemy units can't see their movement range

The border that normally shows the limits of a blue/yellow move are not visible on the enemy turn. You can still see the movement preview by hovering a destination tile, as usual.

## Unactivated aliens can't preview cover

Since they aren't active, they can't take cover, and they won't see cover icons when hovering cover-adjacent tiles. If moved to a cover-adjacent tile and then activated, they will take cover like normal.

## Chosen Assassin is invisible

The Chosen Assassin's cloak hides her from XCOM, and it's still active during the enemy turn. While the enemy player can move the Assassin as normal, you won't be able to see her until she is uncloaked.

## Controlling Chosen units with no action points

Sometimes the game will give you control of a unit who has no Action Points. Generally this is because they have a 0 AP ability. This often happens with Chosen because they aren't controllable in the base game, so no one bothered to worry about these things. Use the end turn hotkey when this comes up.

## Chosen unit abilities/buffs have limited/no localization

Unfortunately, you can't control the Chosen in any way during the base game, so no one bothered localizing their abilities. You may have to use trial-and-error to figure them out.

## Can't switch units between different pods

When controlling the aliens, you have to finish with one pod first before controlling the next. You can finish with a pod either by using all of their action points, or by pressing the end turn hotkey (default: Backspace). This is because alien units aren't given action points until their pod's turn comes up.

## Can't switch units while an enemy is acting

When an XCOM soldier is moving, you can press tab to switch to another soldier without watching the whole move animation. You cannot do this when controlling enemy units. The switch to another unit is blocked for unknown reasons.

## Player loses control of alien turn when a Lost swarm spawns

If the aliens cause a Lost swarm to spawn (e.g. by using explosives), the rest of the alien turn may be played out by AI. This is because we have to change which team is being controlled when a Lost swarm spawns, or else the swarm will be invisible for some reason. Switching control back in time to finish the current turn has not been worked out yet, but subsequent turns will work normally.

## Alien Rulers do \<X broken thing\>

I don't own Alien Rulers and haven't tested them. They might do all kinds of broken stuff, especially with regards to ruler reactions.

## Target icons and preview aren't colored right for enemy units

They are often gray instead of being red or yellow. I don't currently know why this is.

## Loading mid-tactical saves misses some alien turns

Cause is completely unknown, but skipping a few turns will eventually make the alien turn (and Direct Control) work properly.