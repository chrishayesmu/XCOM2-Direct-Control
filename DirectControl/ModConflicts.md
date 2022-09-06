# Known mod conflicts

This file lists out known conflicts and possible resolutions for various mods. Don't expect this list to be comprehensive; these are only the ones which I've personally encountered and resolved.

## Free Camera Rotation

Direct Control and Free Camera Rotation both override the same class, `X2Camera_FollowMouseCursor`. This class override must be disabled in Free Camera Rotation. Direct Control contains special compatibility to ensure that this will not remove any of Free Camera Rotation's functionality.

To remove the override, open Free Camera Rotation's `Config/XComEngine.ini` and find this line:

```
+ModClassOverrides=(BaseGameClass="X2Camera_FollowMouseCursor", ModClass="FreeCameraRotation.X2Camera_FollowMouseCursor_FreeCameraRotation")
```

Add a semicolon (`;`) at the start of the line to comment it out, removing the override. **Do not** remove any other override in this file, or you will break Free Camera Rotation and it will not work properly.

**If you do not remove this override:** neither mod may work properly, and you will suffer very large drops in frame rate due to the conflict.