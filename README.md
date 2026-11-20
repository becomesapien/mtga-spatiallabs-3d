# MTG Arena in glasses-free 3D on Acer SpatialLabs

Play **Magic: The Gathering Arena** in glasses-free 3D on an **Acer SpatialLabs** display (tested on the Predator SpatialLabs View 27, PSV27-2).

Acer's SpatialLabs TrueGame doesn't support Arena, so this setup combines community tools with a preset tuned for Arena:

| Tool | Role |
|---|---|
| [ReShade](https://reshade.me) (add-on build) | Post-processing injector |
| [SuperDepth3D](https://github.com/BlueSkyDefender/Depth3D) by BlueSkyDefender | Builds left/right views from Arena's depth buffer (side-by-side) |
| [3DGameBridge / srReshade](https://github.com/JoeyAnthony/3DGameBridgeProjects) by Janthony & DinnerBram | Weaves the side-by-side image for the SpatialLabs lens + eye tracking |
| **This repo** | One-click installer, setup guide, Arena-specific fixes, a tuned preset and a restore script |

No game files are modified. The only code change is a small **card zoom fix** that the installer applies to your downloaded copy of SuperDepth3D (see below).

## What you get

The depth comes from Arena's own depth buffer, so nothing is faked:

- **The battlefield** tilts away from you into the screen, with your side closest.
- **The battlefield's scenery** around the edges sits in real 3D, along with **your library, your opponent's library, avatars and pets**.
- **Permanents, your hand and the game UI** (life totals, phase stops, the *Pass* / *Next* button) aren't in the depth buffer. They're drawn flat and sit at the depth of the battlefield beneath them. Cards never clip through the UI, and no masks are used, so your hand looks natural as it rises and falls.

## Easiest way: the installer

1. Download the latest **`mtga-spatiallabs-3d.zip`** from [Releases](../../releases) and unzip it anywhere.
2. Close MTG Arena.
3. Double-click **`Install.cmd`** and press **Y**.

The installer:

- finds your Arena folder (Steam or standalone; it asks if it can't);
- downloads ReShade 6.6.2, srReshade v2.1.0 and SuperDepth3D v4.2.5 from their **official sources** and checks each against a known SHA-256 fingerprint;
- backs up any existing ReShade files;
- installs everything with the tuned preset and hotkeys.

Nothing third-party is bundled in this repo.

Then, in Arena, go to **Options → Graphics**: set **Anti-Aliasing Off**, **Motion Blur Off** and **3840×2160**. Move the window to the 3D monitor with **Win+Shift+Arrow**.

To remove it, double-click **`Uninstall.cmd`**. It restores the files that were backed up.

| In game | |
|---|---|
| Ctrl+Alt+Home | ReShade menu |
| Ctrl+Alt+R | Reload effects/preset |
| Ctrl+Alt+E | 3D effect on/off (handy on menu screens) |
| Ctrl+Alt+2 | SpatialLabs lens on/off |

## What makes or breaks it

1. **Arena's Anti-Aliasing must be Off** (Options → Graphics). With it on, ReShade couldn't read Arena's depth buffer in our testing.
2. **Arena's depth buffer is upside down.** SuperDepth3D needs **Depth Map Flip = On** (the preset does this). Without it, near and far are mirrored top to bottom and the whole battlefield looks wrong.
3. **The card zoom fix.** When you zoom in on a card (right-click in the deck builder, crafting with wildcards, or opening booster packs), Arena draws the enlarged card right at the camera lens. SuperDepth3D treats that as touching your nose. At a strong 3D setting the card is pushed so far out that it renders as a **black box**.
   - The installer adds a *Popup Fix* (Near Cutoff 0.001) that draws anything that close flat at screen depth.
   - Nothing on the battlefield is that close, so gameplay depth is untouched.
   - Keep the cutoff tight: a looser 0.02 also flattened parts of the battlefield and was hard on the eyes.

## Manual setup

1. Follow **[docs/SETUP.md](docs/SETUP.md)**.
2. Use the preset in **[preset/MTGA-SpatialLabs-3D.ini](preset/MTGA-SpatialLabs-3D.ini)** (SETUP §4 explains how, plus a restore script).
3. Problems? **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)**.

## Disclaimers

- Not affiliated with Acer, Leia/Dimenco, Wizards of the Coast, ReShade, or the authors of the tools above. All credit for those tools goes to their authors.
- ReShade is a client-side visual post-processor. We're not aware of an official Wizards of the Coast position on it. It's still third-party software, so **use at your own risk**, and consider leaving it off in paid events.
- Tested with:
  - MTG Arena (Steam, Unity 6, DirectX 11)
  - ReShade 6.6.2 add-on build, SuperDepth3D v4.2.5, srReshade v2.1.0
  - SpatialLabs Experience Center 1.3.279
  - Windows 11, RTX 3080 Laptop GPU
  - PSV27-2 at 3840×2160 over HDMI

  Other versions may behave differently.
- Magic: The Gathering Arena is a trademark of Wizards of the Coast LLC. SpatialLabs is a trademark of Acer Inc. All other trademarks belong to their owners.

## License

The installer, guides, preset and scripts in this repository are released under the [MIT License](LICENSE). ReShade, SuperDepth3D and 3DGameBridge remain under their own licenses.
