<#
.SYNOPSIS
    One-click installer for MTG Arena glasses-free 3D on Acer SpatialLabs displays.

.DESCRIPTION
    Downloads each component from its OFFICIAL source (nothing third-party is bundled in this repo),
    verifies every download against a pinned SHA-256 fingerprint, and sets up:
      - ReShade 6.6.2 (add-on build)            from reshade.me           -> dxgi.dll
      - 3DGameBridge srReshade v2.1.0           from its GitHub release   -> srReshade_v2.1.0.addon64
      - SuperDepth3D v4.2.5 (+ Overwatch.fxh)   from BlueSkyDefender/Depth3D at a pinned commit
      - ReShade.fxh / ReShadeUI.fxh             from crosire/reshade-shaders at a pinned commit
      - The tuned MTGA preset, recommended hotkeys and a restore script.
    Existing files are backed up first. Run with -Uninstall to remove everything and restore backups.

.PARAMETER GamePath
    MTGA folder (the one containing MTGA.exe). Auto-detected for Steam and the standalone install.

.PARAMETER Uninstall
    Remove the 3D mod and restore any backed-up files.

.PARAMETER Yes
    Don't ask for confirmation.
#>
[CmdletBinding()]
param(
    [string]$GamePath,
    [switch]$Uninstall,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ---------------------------------------------------------------- pinned sources
$Depth3DCommit = '5d92db3f55a140042880b8ab91cb1d55a31f68fb'
$ShadersCommit = 'fd0022170615ce0d8162d219bff07232fa6dd84f'
$Sources = @(
    @{ Name = 'ReShade 6.6.2 (add-on build)'; Url = 'https://reshade.me/downloads/ReShade_Setup_6.6.2_Addon.exe'; File = 'ReShade_Setup_6.6.2_Addon.exe'
       Sha256 = '208D710E21E15CD871FE37256BF97AAD587620B4602C389453B7E099B7BA3217' },
    @{ Name = '3DGameBridge srReshade v2.1.0'; Url = 'https://github.com/JoeyAnthony/3DGameBridgeProjects/releases/download/v2.1.0/srReshade.zip'; File = 'srReshade.zip'
       Sha256 = '42AB6B79358EE6EA05A77E4793E1F5A1A13C8264C5F24BD090D0AC01FEECBE7B' },
    @{ Name = 'SuperDepth3D v4.2.5 (BlueSkyDefender)'; Url = "https://raw.githubusercontent.com/BlueSkyDefender/Depth3D/$Depth3DCommit/Shaders/SuperDepth3D.fx"; File = 'SuperDepth3D.fx'
       Sha256 = '8EECAC12F629BA5285F94262B66D0CF9A4F46B3413DA6A0917027B1E49EBF8F8' },
    @{ Name = 'Overwatch.fxh (SuperDepth3D profiles)'; Url = "https://raw.githubusercontent.com/BlueSkyDefender/Depth3D/$Depth3DCommit/Shaders/Overwatch.fxh"; File = 'Overwatch.fxh'
       Sha256 = '758549C78588CC6827996D3E0030A2D23311950E494F97ECDD3832C02875EBB4' },
    @{ Name = 'ReShade.fxh (crosire)'; Url = "https://raw.githubusercontent.com/crosire/reshade-shaders/$ShadersCommit/Shaders/ReShade.fxh"; File = 'ReShade.fxh'
       Sha256 = '6DABFBBAF968C3871905D2EA17F96572FF7B1CEC01310B5D0E5252B66B30174F' },
    @{ Name = 'ReShadeUI.fxh (crosire)'; Url = "https://raw.githubusercontent.com/crosire/reshade-shaders/$ShadersCommit/Shaders/ReShadeUI.fxh"; File = 'ReShadeUI.fxh'
       Sha256 = '78ADF672DF47460297EB9FE6DD238D2AAFA24510B52B84FEB1A745DFF70EB901' }
)

$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $Here
$PresetSource = Join-Path $RepoRoot 'preset\MTGA-SpatialLabs-3D.ini'
$RestoreSource = Join-Path $RepoRoot 'tools\Restore-3D-Settings.cmd'
$ManifestName = '_mtga3d_installed.txt'

function Say($msg, $color = 'Gray') { Write-Host $msg -ForegroundColor $color }

# ---------------------------------------------------------------- find MTGA
function Find-MTGA {
    $cands = New-Object System.Collections.Generic.List[string]
    $steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamPath
    if ($steam) {
        $cands.Add((Join-Path $steam 'steamapps\common\MTGA'))
        $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
        if (Test-Path $vdf) {
            foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"')) {
                $cands.Add((Join-Path ($m.Groups[1].Value -replace '\\\\', '\') 'steamapps\common\MTGA'))
            }
        }
    }
    $cands.Add("$env:ProgramFiles\Wizards of the Coast\MTGA")
    $cands.Add("${env:ProgramFiles(x86)}\Wizards of the Coast\MTGA")
    foreach ($c in $cands) { if ($c -and (Test-Path (Join-Path $c 'MTGA.exe'))) { return (Resolve-Path $c).ProviderPath } }
    return $null
}

if (-not $GamePath) { $GamePath = Find-MTGA }
if (-not $GamePath -or -not (Test-Path (Join-Path $GamePath 'MTGA.exe'))) {
    Say 'Could not find MTG Arena automatically.' Yellow
    $GamePath = Read-Host 'Paste the full path of your MTGA folder (the one containing MTGA.exe)'
    if (-not (Test-Path (Join-Path $GamePath 'MTGA.exe'))) { throw "MTGA.exe not found in '$GamePath'." }
}
$GamePath = (Resolve-Path $GamePath).ProviderPath
Say "MTG Arena folder: $GamePath" Cyan

$running = Get-Process MTGA -ErrorAction SilentlyContinue | Where-Object { -not $_.Path -or $_.Path -like (Join-Path $GamePath '*') }
if ($running) { throw 'MTG Arena is running. Close it and run the installer again.' }

$Manifest = Join-Path $GamePath $ManifestName

# ---------------------------------------------------------------- uninstall
if ($Uninstall) {
    if (-not (Test-Path $Manifest)) { Say 'The 3D mod does not appear to be installed (no install record found).' Yellow; return }
    $lines = Get-Content $Manifest
    $backup = ($lines | Where-Object { $_ -like 'BACKUP=*' } | Select-Object -First 1) -replace '^BACKUP=', ''
    foreach ($rel in ($lines | Where-Object { $_ -like 'FILE=*' } | ForEach-Object { $_ -replace '^FILE=', '' })) {
        $p = Join-Path $GamePath $rel
        if (Test-Path $p) { Set-ItemProperty $p -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue; Remove-Item $p -Force }
    }
    foreach ($d in 'reshade-shaders\Shaders\Depth3D', 'reshade-shaders\Shaders', 'reshade-shaders\Textures', 'reshade-shaders') {
        $p = Join-Path $GamePath $d
        if ((Test-Path $p) -and -not (Get-ChildItem $p -Force)) { Remove-Item $p -Force }
    }
    if ($backup -and (Test-Path (Join-Path $GamePath $backup))) {
        Get-ChildItem (Join-Path $GamePath $backup) -File | ForEach-Object { Copy-Item $_.FullName (Join-Path $GamePath $_.Name) -Force }
        Say "Restored your previous files from $backup." Green
    }
    Remove-Item $Manifest -Force
    Say 'MTG Arena 3D mod removed.' Green
    return
}

# ---------------------------------------------------------------- confirm
Say ''
Say 'This will download (from official sources) and install:' White
foreach ($s in $Sources) { Say ("  - {0}`n      {1}" -f $s.Name, $s.Url) }
Say 'Every download is checked against a known SHA-256 fingerprint.'
Say 'Existing ReShade files in the MTGA folder are backed up first.'
Say ''
Say 'Note: ReShade is third-party software. Use at your own risk (consider not using it in paid events).' Yellow
if (-not $Yes) {
    $ans = Read-Host 'Continue? (Y/N)'
    if ($ans -notmatch '^[Yy]') { Say 'Cancelled.'; return }
}

# ---------------------------------------------------------------- download + verify
$tmp = Join-Path $env:TEMP ("mtga3d-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $tmp | Out-Null
try {
    foreach ($s in $Sources) {
        $out = Join-Path $tmp $s.File
        Say "Downloading $($s.Name)..."
        Invoke-WebRequest -Uri $s.Url -OutFile $out -UseBasicParsing
        $h = (Get-FileHash $out -Algorithm SHA256).Hash
        if ($h -ne $s.Sha256) { throw "Fingerprint mismatch for $($s.Name). Expected $($s.Sha256), got $h. Nothing was installed." }
    }

    # ReShade64.dll from the self-extracting setup (Windows tar reads it)
    Push-Location $tmp
    $winTar = Join-Path $env:SystemRoot 'System32\tar.exe'
    try { & $winTar -xf 'ReShade_Setup_6.6.2_Addon.exe' 'ReShade64.dll' } finally { Pop-Location }
    if (-not (Test-Path (Join-Path $tmp 'ReShade64.dll'))) { throw 'Could not extract ReShade64.dll from the ReShade setup.' }
    Expand-Archive (Join-Path $tmp 'srReshade.zip') (Join-Path $tmp 'sr') -Force

    # Popup fix: Arena draws pop-ups (card previews, rewards) with a depth of ~0. SuperDepth3D reads that as
    # "touching the viewer's nose" and the huge pop-out turns them black. Anything nearer than the cutoff is
    # drawn flat at screen depth instead. Applied locally to the official file (SuperDepth3D isn't redistributed).
    $sdPath = Join-Path $tmp 'SuperDepth3D.fx'
    $sd = [IO.File]::ReadAllText($sdPath)
    $uniforms = "`t// [POPUP-FIX BEGIN]`n" +
        "`tuniform float Popup_Near_Cutoff < ui_type = `"slider`"; ui_min = 0.0; ui_max = 0.5; ui_step = 0.001; ui_label = `" Near Cutoff`"; ui_tooltip = `"Anything nearer than this is drawn flat at screen depth. Fixes pop-ups (card previews, rewards) turning black. 0 = off.`"; ui_category = `"Popup Fix`"; > = 0.02;`n" +
        "`tuniform float Popup_Far_Cutoff < ui_type = `"slider`"; ui_min = 0.5; ui_max = 1.0; ui_step = 0.001; ui_label = `" Far Cutoff`"; ui_tooltip = `"Anything farther than this is drawn flat at screen depth. 1 = off.`"; ui_category = `"Popup Fix`"; > = 1.0;`n" +
        "`tuniform bool Popup_Menus_Only < ui_label = `" Menus Only`"; ui_tooltip = `"Only apply the cutoff on screens without a 3D scene (deck builder, crafting), so the battlefield is never touched.`"; ui_category = `"Popup Fix`"; > = true;`n" +
        "`tbool Popup_Empty(float2 uv) { float r = tex2Dlod(DepthBuffer, float4(uv,0,0)).x; return (Depth_Map == 1 ? r : 1.0 - r) < 0.0001; }`n" +
        "`tbool Popup_MenuScene() { return Popup_Empty(float2(0.1,0.1)) && Popup_Empty(float2(0.9,0.1)) && Popup_Empty(float2(0.1,0.9)) && Popup_Empty(float2(0.9,0.9)) && Popup_Empty(float2(0.5,0.08)) && Popup_Empty(float2(0.5,0.92)); }`n" +
        "`t// [POPUP-FIX END]`n"
    $clamp = "`t`t// [POPUP-FIX BEGIN]`n" +
        "`t`tif (((Popup_Near_Cutoff > 0.0 && zBuffer < Popup_Near_Cutoff) || (Popup_Far_Cutoff < 1.0 && zBuffer > Popup_Far_Cutoff)) && (!Popup_Menus_Only || Popup_MenuScene()))`n" +
        "`t`t`tzBuffer = Zero_Parallax_Distance;`n" +
        "`t`t// [POPUP-FIX END]`n"
    $re1 = [regex]'(?m)^\tfloat Depth\(float2 texcoord\)\r?$'
    $re2 = [regex]'(?m)(^\t\t\tzBuffer = Two_Ch_zBuffer\.x;\r?\n)(?=\t\t#if ALM == 1)'
    if ($re1.Matches($sd).Count -ne 1 -or $re2.Matches($sd).Count -ne 1) { throw 'SuperDepth3D.fx did not have the expected layout for the popup fix.' }
    $sd = $re1.Replace($sd, { param($m) $uniforms + $m.Value }, 1)
    $sd = $re2.Replace($sd, { param($m) $m.Groups[1].Value + $clamp }, 1)
    [IO.File]::WriteAllText($sdPath, $sd, (New-Object System.Text.UTF8Encoding($false)))

    # ------------------------------------------------------------ backup
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupRel = "_mtga3d_backup_$stamp"
    $backupDir = Join-Path $GamePath $backupRel
    $toBackup = 'dxgi.dll', 'ReShade.ini', 'ReShadePreset.ini'
    $backedUp = $false
    foreach ($f in $toBackup) {
        $p = Join-Path $GamePath $f
        if (Test-Path $p) {
            if (-not $backedUp) { New-Item -ItemType Directory $backupDir | Out-Null; $backedUp = $true }
            Copy-Item $p $backupDir
        }
    }

    # ------------------------------------------------------------ install
    $sh = Join-Path $GamePath 'reshade-shaders\Shaders'
    New-Item -ItemType Directory -Force (Join-Path $sh 'Depth3D'), (Join-Path $GamePath 'reshade-shaders\Textures') | Out-Null
    $installed = New-Object System.Collections.Generic.List[string]
    function Put($src, $rel) {
        $dst = Join-Path $GamePath $rel
        if (Test-Path $dst) { Set-ItemProperty $dst -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue }
        Copy-Item $src $dst -Force
        $installed.Add($rel)
    }
    Put (Join-Path $tmp 'ReShade64.dll') 'dxgi.dll'
    Put (Join-Path $tmp 'sr\srReshade_v2.1.0.addon64') 'srReshade_v2.1.0.addon64'
    Put (Join-Path $tmp 'sr\DO_NOT_ENABLE.addonfx') 'reshade-shaders\Shaders\DO_NOT_ENABLE.addonfx'
    Put (Join-Path $tmp 'ReShade.fxh') 'reshade-shaders\Shaders\ReShade.fxh'
    Put (Join-Path $tmp 'ReShadeUI.fxh') 'reshade-shaders\Shaders\ReShadeUI.fxh'
    Put (Join-Path $tmp 'SuperDepth3D.fx') 'reshade-shaders\Shaders\Depth3D\SuperDepth3D.fx'
    Put (Join-Path $tmp 'Overwatch.fxh') 'reshade-shaders\Shaders\Depth3D\Overwatch.fxh'

    $iniText = @'
[3DGameBridge]
disable_3d_when_no_user_present=false
disable_3d_when_no_user_present_additional_grace_duration_in_ms=0
enable_overlay_workaround=true
toggle_sr_key=0x31\;ctrl\;alt
toggle_lens_key=0x32\;ctrl\;alt
toggle_3d_key=0x33\;ctrl\;alt
toggle_lens_and_3d_key=0x34\;ctrl\;alt
toggle_latency_mode_key=0x35\;ctrl\;alt

[GENERAL]
EffectSearchPaths=.\reshade-shaders\Shaders\**
TextureSearchPaths=.\reshade-shaders\Textures\**
PresetPath=.\ReShadePreset.ini
PerformanceMode=0
PreprocessorDefinitions=RESHADE_DEPTH_LINEARIZATION_FAR_PLANE=1000.0,RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN=0,RESHADE_DEPTH_INPUT_IS_REVERSED=1,RESHADE_DEPTH_INPUT_IS_LOGARITHMIC=0

[INPUT]
ForceShortcutModifiers=1
KeyOverlay=36,1,0,1
KeyReload=82,1,0,1
KeyEffects=69,1,0,1

[OVERLAY]
TutorialProgress=4

[STYLE]
FontSize=22.000000
'@
    $enc = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText((Join-Path $GamePath 'ReShade.ini'), ($iniText -replace "`r?`n", "`r`n"), $enc)
    $installed.Add('ReShade.ini')

    Put $PresetSource 'ReShadePreset.ini'
    Put $PresetSource 'MTGA-SpatialLabs-3D.ini'
    Set-ItemProperty (Join-Path $GamePath 'MTGA-SpatialLabs-3D.ini') -Name IsReadOnly -Value $true
    Put $RestoreSource 'Restore-3D-Settings.cmd'

    $rec = @("INSTALLED=$stamp")
    if ($backedUp) { $rec += "BACKUP=$backupRel" }
    $rec += $installed | ForEach-Object { "FILE=$_" }
    [IO.File]::WriteAllLines($Manifest, $rec, $enc)
}
finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Say ''
Say 'Installed!' Green
Say ''
Say 'Before playing, in MTG Arena: Options (gear) -> Graphics:' White
Say '   Anti-Aliasing = Off   (required, otherwise there is no 3D depth)'
Say '   Motion Blur   = Off'
Say '   Resolution    = 3840x2160, on your SpatialLabs monitor (Win+Shift+Arrow moves the window)'
Say ''
Say 'Keys in game:  Ctrl+Alt+Home = ReShade menu   Ctrl+Alt+R = reload   Ctrl+Alt+E = effects on/off   Ctrl+Alt+2 = 3D lens on/off'
Say 'If your settings ever get messed up, double-click Restore-3D-Settings.cmd in the MTGA folder.'
Say 'To remove the mod, run Uninstall.cmd from this installer folder.'
