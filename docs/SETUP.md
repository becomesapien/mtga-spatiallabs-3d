# Setup guide

> **Shortcut:** the [one-click installer](../README.md#easiest-way-the-installer) does sections 3–7 for you. You still need sections 1–2.

Target: MTG Arena on Steam (tested; the standalone launcher should work the same), DirectX 11, on an Acer SpatialLabs display at 3840×2160.

## 1. SpatialLabs display

1. Connect the monitor with a video cable **and** its USB cable (the USB carries the eye-tracking camera).
2. Make it your **main display** at **3840×2160**.
3. Install **SpatialLabs Experience Center** from Acer's support page for your model.
4. Sanity check: SpatialLabs **Model Viewer** should look clean. If it ghosts, fix the display/eye tracking first.

## 2. Arena graphics settings (critical)

In Arena: **Options (gear) → Graphics**:

| Setting | Value | Why |
|---|---|---|
| **Anti-Aliasing** | **Off** | Required — with it on, ReShade's Generic Depth showed the main depth buffer greyed out ("Not all depth buffers are available") |
| **Motion Blur** | **Off** | Blur without matching depth causes ghosting |
| Resolution | **3840×2160** | Native resolution of the 3D monitor |
| Full Screen | On | What we used |

Change these in the in-game menu — editing Arena's registry settings alone didn't stick in our testing.

Arena may open on another monitor. Click it and press **Win+Shift+Left/Right Arrow** to move it to the 3D display (it usually stays there; repeat if needed).

## 3. ReShade (add-on build)

1. Download **ReShade with full add-on support** from [reshade.me](https://reshade.me) (we used 6.6.2).
2. Run the installer, select `MTGA.exe` in your MTGA folder (Steam: `...\steamapps\common\MTGA\`), choose **DirectX 10/11/12**.
3. Effects page: select **SuperDepth3D** (Depth3D).
4. Add-ons page: select **"3DGameBridge by Janthony & DinnerBram"**.
   - Not listed? Download `srReshade.zip` (v2.1.0) from the [3DGameBridge releases](https://github.com/JoeyAnthony/3DGameBridgeProjects/releases) and put `srReshade_v2.1.0.addon64` next to `MTGA.exe`.
5. In the ReShade effect list, leave the **SR (DO_NOT_ENABLE.addonfx)** entry **unchecked** — only SuperDepth3D should be enabled.

## 4. Preset

1. Copy [`preset/MTGA-SpatialLabs-3D.ini`](../preset/MTGA-SpatialLabs-3D.ini) into your MTGA folder and keep it as your clean copy (optionally right-click → Properties → Read-only).
2. Copy [`tools/Restore-3D-Settings.cmd`](../tools/Restore-3D-Settings.cmd) into the same folder and double-click it. It copies the clean preset over `ReShadePreset.ini` (ReShade's default preset file).
3. Start Arena (or press the ReShade reload key in game).

Run the restore script again any time your settings get messed up.

Key values (SuperDepth3D v4.2.5 labels):

| Setting | Value |
|---|---|
| 3D Display Mode | Side by Side |
| Depth Map Selection | DM1 Reversed |
| **Depth Map Flip** | **On** (Arena's depth is upside down) |
| Near Plane Adjustment | 250 (slider maximum) |
| Depth Adjustment | 59.2 |
| Separation | 0.125 |
| Zero Parallax Distance | 0.038 |
| ZPD Balance | 0.02 |

Tune Depth Adjustment / Zero Parallax Distance to taste (if you change them in the overlay, ReShade saves them to `ReShadePreset.ini`; update your clean copy if you want to keep them).

## 5. Depth buffer

With Anti-Aliasing off, ReShade's **Add-ons → Generic Depth** automatically picks the right buffer (the 3840×2160 D32S8 one with the most draw calls). Leave "Copy depth buffer before clear operations" off.

## 6. Hotkeys (optional, recommended)

With Arena closed, open `ReShade.ini` in the MTGA folder and **edit the existing lines** under `[INPUT]` and `[3DGameBridge]` so they read as below (don't add duplicate sections; ReShade rewrites this file, so comments won't survive):

```ini
[INPUT]
KeyOverlay=36,1,0,1
KeyReload=82,1,0,1
KeyEffects=69,1,0,1

[3DGameBridge]
toggle_sr_key=0x31\;ctrl\;alt
toggle_lens_key=0x32\;ctrl\;alt
toggle_3d_key=0x33\;ctrl\;alt
toggle_lens_and_3d_key=0x34\;ctrl\;alt
toggle_latency_mode_key=0x35\;ctrl\;alt
```

Key format: `<virtual-key code>,<ctrl>,<shift>,<alt>`. We found no conflicts with Arena using Ctrl+Alt.

| Key | Action |
|---|---|
| Ctrl+Alt+Home | ReShade menu |
| Ctrl+Alt+R | Reload ReShade (hold the keys briefly) |
| Ctrl+Alt+E | All effects on/off |
| Ctrl+Alt+1 | SR on/off |
| Ctrl+Alt+2 | 3D lens on/off |
| Ctrl+Alt+3 | SuperDepth3D on/off |
| Ctrl+Alt+4 | Lens + SuperDepth3D together (first press may turn both off) |
| Ctrl+Alt+5 | Weaver latency mode (not saved between launches) |

A copy is in [`config/ReShade-keys.ini`](../config/ReShade-keys.ini).

## 7. Pop-up fix (deck builder card previews turning black)

In the deck builder and crafting screens, Arena draws card previews with a depth of almost zero, which SuperDepth3D treats as extremely close. At a strong 3D setting they get pushed so far apart that they show up as black boxes. The fix: on screens with **no 3D scene** (six spots near the screen edges all have empty depth), anything nearer than a small cutoff is drawn flat at screen depth. The battlefield always has depth at those spots, so in games the fix is off and the board is untouched.

> Don't use a plain always-on cutoff: Arena's board partly falls under 0.02 with this preset's Near Plane of 250, so it flattens chunks of the table and is hard on the eyes.

The installer applies this automatically. To do it by hand, edit `reshade-shaders\Shaders\Depth3D\SuperDepth3D.fx` (v4.2.5):

1. Directly above the line `float Depth(float2 texcoord)`, add:
   ```hlsl
   uniform float Popup_Near_Cutoff < ui_type = "slider"; ui_min = 0.0; ui_max = 0.5; ui_step = 0.001; ui_label = " Near Cutoff"; ui_category = "Popup Fix"; > = 0.02;
   uniform float Popup_Far_Cutoff < ui_type = "slider"; ui_min = 0.5; ui_max = 1.0; ui_step = 0.001; ui_label = " Far Cutoff"; ui_category = "Popup Fix"; > = 1.0;
   uniform bool Popup_Menus_Only < ui_label = " Menus Only"; ui_category = "Popup Fix"; > = true;
   bool Popup_Empty(float2 uv) { float r = tex2Dlod(DepthBuffer, float4(uv,0,0)).x; return (Depth_Map == 1 ? r : 1.0 - r) < 0.0001; }
   bool Popup_MenuScene() { return Popup_Empty(float2(0.1,0.1)) && Popup_Empty(float2(0.9,0.1)) && Popup_Empty(float2(0.1,0.9)) && Popup_Empty(float2(0.9,0.9)) && Popup_Empty(float2(0.5,0.08)) && Popup_Empty(float2(0.5,0.92)); }
   ```
2. Inside that function, right after the line `zBuffer = Two_Ch_zBuffer.x;` (just before `#if ALM == 1`), add:
   ```hlsl
   if (((Popup_Near_Cutoff > 0.0 && zBuffer < Popup_Near_Cutoff) || (Popup_Far_Cutoff < 1.0 && zBuffer > Popup_Far_Cutoff)) && (!Popup_Menus_Only || Popup_MenuScene()))
       zBuffer = Zero_Parallax_Distance;
   ```
3. Reload (Ctrl+Alt+R). The preset sets `Popup_Near_Cutoff=0.02`; previews were fixed from 0.01 up in our testing.
