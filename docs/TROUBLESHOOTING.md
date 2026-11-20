# Troubleshooting

### Solid pink/purple screen (or solid white/grey)
That's a depth *debug view* covering the game (ReShade's DisplayDepth effect, or SuperDepth3D's Depth Map View). Open the ReShade menu (Home, or Ctrl+Alt+Home with the recommended hotkeys) and untick DisplayDepth / set Depth Map View to Off. With the recommended hotkeys, Ctrl+Alt+E turns all effects off instantly.

### Depth view is flat, or Generic Depth shows the main buffer greyed out ("Not all depth buffers are available")
Arena's **Anti-Aliasing is on**. Set **Options → Graphics → Anti-Aliasing → Off** in the game menu.

### The 3D looks "wrong everywhere" — shapes in the wrong places, like badly placed masks
Arena's depth buffer is **upside down**. Set SuperDepth3D **Depth Map Flip = On**. Check with Depth Map View: the near table edge should be at the bottom, the far side at the top, and your companion's shape where the companion actually is.

### Everything looks flat / sunken into the screen
Arena's camera sees the whole table within a thin depth range. The preset already has Near Plane Adjustment at its 250 maximum — raise **Depth Adjustment** and **Zero Parallax Distance** instead.

### The screen looks like two stretched halves overlapping
SuperDepth3D is **off** while the 3D lens is on. Enable SuperDepth3D in the effect list. After a crash, ReShade once saved the preset with no effects enabled (`Techniques=` empty) — run `Restore-3D-Settings.cmd` (see SETUP §4) and reload.

### The reload key doesn't seem to work
Hold the keys for a moment rather than tapping. You can confirm a reload in `ReShade.log` (a new "Successfully compiled ... SuperDepth3D" line).

### Arena opens on the wrong monitor
Click it and press **Win+Shift+Left/Right Arrow**.

### Ghosting
- Make sure Motion Blur is off.
- Check Acer's Model Viewer looks clean (viewing distance ~60–90 cm, face well lit, nothing blocking the eye-tracking camera).
- Lower Depth Adjustment / Zero Parallax Distance.
