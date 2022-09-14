Allows PvP campaign battles by giving full control of AI to the player. [b]This is [u]local multiplayer only[/u], not online! To play online, you will need to use a screen sharing application such as [url=https://parsec.app/]Parsec[/url].[/b]

[h1]How it works[/h1]
Direct Control overrides the game's logic so that, when XCOM's turn ends, the player remains in control and takes over the enemy forces. You control them just like XCOM's soldiers - you see what they see, decide where they go, and pick who they shoot. At this point, you hand control over to your opponent and watch them scheme against you.

You have options for which teams are controlled (Aliens and/or The Lost for now), and whether the player controls unactivated pods or not. If not, inactive pods will follow their normal AI, including any AI mods you have on.

There are a few places where enemy gameplay isn't identical to XCOM's; make sure to check out the [url=https://steamcommunity.com/workshop/filedetails/discussion/2862951793/3473986888163595252/]Known Issues[/url] thread.

Want to see it in action? Check out a mission from the legendary Beaglerush's [url=https://youtu.be/r6swkgqrE5Q?t=874]new multiplayer campaign[/url].

[h1]How does pod activation work?[/h1]
If the player isn't controlling inactive pods, then pod activation works exactly as normal. If they are in control, then [b]pods will not scamper when activated[/b]. You don't want to set up your forces in a neat firing line, then watch them all run away from it at the first sign of trouble. The exception is that pods will scamper on the first turn of battle if activated, so that they aren't standing out in the open dumbly while XCOM guns them down.

Reinforcement pods will always scamper when they spawn, and the AI controls this. That includes Advent dropships, Lost swarms, Chosen spawning in, Faceless emerging from civs, etc.

[h1]How do the Chosen and Alien Rulers work?[/h1]
The Chosen and Alien Rulers were never meant to be human-controlled, so a lot of their abilities aren't configured or localized properly by default. Direct Control updates them with proper localization text and config, so you don't have a bunch of abilities called "ERROR". Currently, localization is English only.

[b]Note:[/b] while Alien Rulers do work, the human player does not control their Ruler Reactions. The AI will still be in charge of those.

[h1]Can I remove this mod mid-campaign?[/h1]
Yes, but only when loading a save from the Geoscape. If you remove this mod and try to load a mid-battle save, your game will crash.

[h1]Why is this listed as beta?[/h1]
While this mod is running very smoothly, I haven't tested every scenario, especially with other mods. If you're running a heavily modded campaign, some issues may arise. Please report them if so!

[h1]Compatibility with the ADVENT Reinforcements mod[/h1]
[url=https://steamcommunity.com/sharedfiles/filedetails/?id=1133952445]ADVENT Reinforcements[/url] is a really cool mod that gives Advent Officers the ability to periodically call in reinforcement units. By itself, the reinforcements are called in to a position based on XCOM's location and a few other factors. If you're using this mod with Direct Control, there's special configuration to change this ability to be targeted. This means the controlling player can choose exactly where they want reinforcements to spawn. (This is an optional feature; you can keep the original behavior if you wish.)

[h1]AML reports that Direct Control is conflicting with another mod![/h1]
As noted below, Direct Control overrides a lot of classes. Check [url=https://steamcommunity.com/workshop/filedetails/discussion/2862951793/3473986888164159684/]this thread[/url] to see if your conflict is listed, along with steps to resolve it. If not, please report the conflict [url=https://steamcommunity.com/workshop/filedetails/discussion/2862951793/3473986888164155935/]here[/url].

[h1]Class overrides[/h1]
Direct Control overrides a lot of base game classes in order to make things work smoothly. This may cause conflicts with other mods. Most of these overrides can be disabled, at the cost of losing some quality-of-life. Check out [b]XComEngine.ini[/b] for an explanation of exactly what each override does, and what will happen if you disable it.

These are the overridden classes:

[code]
XGAIPlayer
XGAIPlayer_TheLost
XComTacticalController
X2VisibilityObserver
XComGameState_AIGroup
X2Camera_FollowMouseCursor
XComTacticalSoundManager
X2AbilityToHitCalc_RollStatTiers
[/code]

[h1]Credits[/h1]
Thanks to [url=https://www.twitch.tv/beagsandjam/]Beaglerush[/url] for testing this with me both on and off stream and providing feedback. Also thanks to his Twitch chat for their feedback, and in particular [b]Britarnya[/b], who came up with the idea to make the turn timer much more useful.

If you like my work and want to support me, feel free to toss me a few dollars on [url=https://www.patreon.com/SwfDelicious]Patreon[/url] - it's greatly appreciated!