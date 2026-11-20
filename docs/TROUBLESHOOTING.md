# Troubleshooting

### Zoomed-in cards (deck builder, crafting, opening packs) are black boxes
SuperDepth3D is missing the card zoom fix, or *Near Cutoff* is 0. Re-run the installer, or apply SETUP §7, and check **Popup Fix → Near Cutoff = 0.001, Menus Only = off** in the ReShade menu.

### The battlefield suddenly looks wrong / hurts after changing the card zoom fix
Keep **Near Cutoff** tiny (0.001). Larger values (e.g. 0.02) also flatten parts of the battlefield.

### The installer says "Fingerprint mismatch"
A download didn't match the exact file the installer was tested with (the source changed, or the download was corrupted or intercepted). Nothing was installed. Try again later, or open an issue.

### The installer says "MTG Arena is running"
Close Arena completely (check the system tray) and run it again.

### Solid pink/purple screen (or solid white/grey)
That's a depth *debug view* covering the game (ReShade's DisplayDepth effect, or SuperDepth3D's Depth Map View). Open the ReShade menu (Home, or Ctrl+Alt+Home with the recommended hotkeys) and untick DisplayDepth / set Depth Map View to Off. With the recommended hotkeys, Ctrl+Alt+E turns all effects off instantly.

### Depth view is flat, or Generic Depth shows the main buffer greyed out ("Not all depth buffers are available")
Arena's **Anti-Aliasing is on**. Set **Options → Graphics → Anti-Aliasing → Off** in the game menu.

### The 3D looks "wrong everywhere" — shapes in the wrong places, like badly placed masks
Arena's depth buffer is **upside down**. Set SuperDepth3D **Depth Map Flip = On**. Check with Depth Map View: your side of the battlefield should be nearest, at the bottom, and your opponent's side farther away at the top, and your pet's shape where the pet actually is.

### Everything looks flat / sunken into the screen
Arena's camera sees the whole battlefield within a thin depth range. The preset already has Near Plane Adjustment at its 250 maximum — raise **Depth Adjustment** and **Zero Parallax Distance** instead.

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
