# MTG Arena in glasses-free 3D on Acer SpatialLabs

Play **Magic: The Gathering Arena** in glasses-free 3D on an **Acer SpatialLabs** display (tested on the Predator SpatialLabs View 27, PSV27-2).

Acer's SpatialLabs TrueGame doesn't support Arena, so this uses community tools plus a tuned preset:

| Tool | Role |
|---|---|
| [ReShade](https://reshade.me) (add-on build) | Post-processing injector |
| [SuperDepth3D](https://github.com/BlueSkyDefender/Depth3D) by BlueSkyDefender | Builds left/right views from Arena's depth buffer (side-by-side) |
| [3DGameBridge / srReshade](https://github.com/JoeyAnthony/3DGameBridgeProjects) by Janthony & DinnerBram | Weaves the side-by-side image for the SpatialLabs lens + eye tracking |
| **This repo** | One-click installer, setup guide, the Arena-specific fixes, a ready-made preset and a restore script |

No game files are modified. The only code change is a small **pop-up fix** the installer applies to your downloaded copy of SuperDepth3D (see below).

## What the 3D looks like

The 3D comes from Arena's real depth buffer: the table tilts into the screen, and the board frame, decks and companions (e.g. pets at the side) have real depth. Battlefield cards, your hand and the menus aren't in the depth buffer — they're drawn flat on top and take the depth of the table under them, so nothing floats through the UI and no masks are used.

## Easiest way: the installer

1. Download the latest **`mtga-spatiallabs-3d.zip`** from [Releases](../../releases) and unzip it anywhere.
2. Close MTG Arena.
3. Double-click **`Install.cmd`** and press **Y**.

It finds your Arena folder (Steam or standalone; it asks if it can't), downloads ReShade 6.6.2, srReshade v2.1.0 and SuperDepth3D v4.2.5 from their **official sources**, checks every download against a known SHA-256 fingerprint, backs up any existing ReShade files, and installs everything with the tuned preset and hotkeys. Nothing third-party is bundled in this repo.

Then, in Arena, set **Options → Graphics: Anti-Aliasing Off, Motion Blur Off, 3840×2160** and move the window to the 3D monitor (Win+Shift+Arrow).

To remove it, double-click **`Uninstall.cmd`** (restores your backed-up files).

| In game | |
|---|---|
| Ctrl+Alt+Home | ReShade menu |
| Ctrl+Alt+R | Reload effects/preset |
| Ctrl+Alt+E | 3D effect on/off |
| Ctrl+Alt+2 | SpatialLabs lens on/off |

## The things that make or break it

1. **Arena's Anti-Aliasing must be Off** (Options → Graphics). With it on, ReShade couldn't use Arena's depth buffer in our testing.
2. **Arena's depth buffer is upside down.** SuperDepth3D needs **Depth Map Flip = On** (the preset does this). Without it, near and far are mirrored top-to-bottom and everything looks wrong.
3. **Deck builder pop-ups need the pop-up fix.** In the deck builder / crafting screens Arena draws card previews with a depth of almost zero. SuperDepth3D reads that as "right against your nose", and at a strong 3D setting the pop-out is so big they turn into **black boxes**. The installer adds a *Popup Fix* (Near Cutoff 0.02, Menus Only on): on screens with no 3D scene behind them, anything that near is drawn flat at screen depth. It switches itself off whenever the battlefield is on screen, so gameplay depth is never touched (an always-on version flattened parts of the board and was hard on the eyes).

## Manual setup

1. Follow **[docs/SETUP.md](docs/SETUP.md)**.
2. Use the preset in **[preset/MTGA-SpatialLabs-3D.ini](preset/MTGA-SpatialLabs-3D.ini)** (SETUP §4 explains how, plus a restore script).
3. Problems? **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)**.

## Disclaimers

- Not affiliated with Acer, Leia/Dimenco, Wizards of the Coast, ReShade, or the authors of the tools above. All credit for those tools goes to their authors.
- ReShade is a client-side visual post-processor. We're not aware of an official Wizards of the Coast position on it; it's still third-party software, so **use at your own risk** (consider not using it in paid events).
- Tested with: MTG Arena (Steam, Unity 6, DirectX 11), ReShade 6.6.2 add-on build, SuperDepth3D v4.2.5, srReshade v2.1.0, SpatialLabs Experience Center 1.3.279, Windows 11, RTX 3080 Laptop GPU, PSV27-2 at 3840×2160 over HDMI. Other versions may differ.
- Magic: The Gathering Arena is a trademark of Wizards of the Coast LLC. SpatialLabs is a trademark of Acer Inc. All other trademarks belong to their owners.

## License

The installer, guides, preset and scripts in this repository are released under the [MIT License](LICENSE). ReShade, SuperDepth3D and 3DGameBridge remain under their own licenses.
