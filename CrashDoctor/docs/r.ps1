# =============================================================================
# Bannerlord Crash Doctor — Recovery Console
# =============================================================================
# Use this when Bannerlord won't launch and the in-game Crash Doctor mod can't
# help (because the game itself doesn't start, the mod never loads).
#
# Run from PowerShell (Win+R → "powershell" → Enter):
#
#   irm https://raw.githubusercontent.com/Phxc2v/CrashDoctor/main/recovery.ps1 | iex
#
# Everything this script deletes goes to the Recycle Bin, not /dev/null —
# you can always restore from there if something looks wrong.
# =============================================================================

$ErrorActionPreference = 'Continue'
$script:CD_VERSION = '1.0'

Add-Type -AssemblyName Microsoft.VisualBasic | Out-Null

function Write-Banner {
    Clear-Host
    Write-Host ''
    Write-Host '  ============================================================' -ForegroundColor Cyan
    Write-Host '   Bannerlord Crash Doctor — Recovery Console v' -NoNewline -ForegroundColor Cyan
    Write-Host $script:CD_VERSION -ForegroundColor White
    Write-Host '   For when Bannerlord won''t launch at all.' -ForegroundColor Cyan
    Write-Host '  ============================================================' -ForegroundColor Cyan
    Write-Host ''
}

function Write-Ok       ($msg) { Write-Host "  [OK]   $msg" -ForegroundColor Green }
function Write-Warn     ($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Err      ($msg) { Write-Host "  [ERR]  $msg" -ForegroundColor Red }
function Write-Info     ($msg) { Write-Host "  [..]   $msg" -ForegroundColor Gray }
function Write-Section  ($msg) { Write-Host ''; Write-Host "-- $msg" -ForegroundColor Cyan }

# -----------------------------------------------------------------------------
# Path detection
# -----------------------------------------------------------------------------

function Get-BannerlordDocuments {
    $docs = [Environment]::GetFolderPath('MyDocuments')
    if (-not $docs) { return $null }
    $bl = Join-Path $docs 'Mount and Blade II Bannerlord'
    if (Test-Path $bl) { return $bl }
    return $bl  # may not exist yet, return target anyway for messages
}

function Get-BannerlordProgramData {
    $pd = [Environment]::GetFolderPath('CommonApplicationData')
    if (-not $pd) { return $null }
    return Join-Path $pd 'Mount and Blade II Bannerlord'
}

function Get-SteamInstallPath {
    foreach ($key in @(
        'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam',
        'HKLM:\SOFTWARE\Valve\Steam',
        'HKCU:\SOFTWARE\Valve\Steam'
    )) {
        try {
            $v = (Get-ItemProperty -Path $key -ErrorAction Stop).InstallPath
            if ($v -and (Test-Path $v)) { return $v }
        } catch { }
    }
    return $null
}

function Get-BannerlordGameDir {
    # The Steam install folder is "Mount & Blade II Bannerlord" (with &), while
    # user data dirs use "Mount and Blade II Bannerlord" (with "and"). Probe both
    # — Steam might rename it some day, mirrors might use either form.
    $folderNames = @('Mount & Blade II Bannerlord', 'Mount and Blade II Bannerlord')

    $steam = Get-SteamInstallPath
    if (-not $steam) { return $null }

    foreach ($n in $folderNames) {
        $candidate = Join-Path $steam "steamapps\common\$n"
        if (Test-Path $candidate) { return $candidate }
    }

    # Walk every library listed in libraryfolders.vdf and probe for the game
    # folder. Cheaper than parsing nested VDF blocks (which need a real parser
    # — regex can't reliably handle the nesting).
    $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
    if (-not (Test-Path $vdf)) { return $null }

    $content = Get-Content $vdf -Raw
    foreach ($m in [regex]::Matches($content, '"path"\s*"([^"]+)"')) {
        $libPath = $m.Groups[1].Value -replace '\\\\', '\'
        foreach ($n in $folderNames) {
            $candidate = Join-Path $libPath "steamapps\common\$n"
            if (Test-Path $candidate) { return $candidate }
        }
    }
    return $null
}

function Get-Paths {
    [pscustomobject]@{
        Documents       = Get-BannerlordDocuments
        ProgramData     = Get-BannerlordProgramData
        GameDir         = Get-BannerlordGameDir
        ConfigsDir      = (Join-Path (Get-BannerlordDocuments) 'Configs')
        EngineConfig    = (Join-Path (Get-BannerlordDocuments) 'Configs\engine_config.txt')
        BannerlordCfg   = (Join-Path (Get-BannerlordDocuments) 'Configs\BannerlordConfig.txt')
        LauncherData    = (Join-Path (Get-BannerlordDocuments) 'Configs\LauncherData.xml')
        ProgramDataShaders = (Join-Path (Get-BannerlordProgramData) 'Shaders')
        CrashesDir      = (Join-Path (Get-BannerlordProgramData) 'crashes')
        LogsDir         = (Join-Path (Get-BannerlordProgramData) 'logs')
    }
}

# -----------------------------------------------------------------------------
# Safety helpers
# -----------------------------------------------------------------------------

function Test-BannerlordRunning {
    $names = @('Bannerlord', 'Bannerlord.Native', 'TaleWorlds.MountAndBlade.Launcher',
               'TaleWorlds.MountAndBlade.Launcher.WPF', 'BannerLord_Launcher_BLSE')
    foreach ($n in $names) {
        if (Get-Process -Name $n -ErrorAction SilentlyContinue) { return $true }
    }
    return $false
}

function Confirm-NoGameRunning {
    if (Test-BannerlordRunning) {
        Write-Err 'Bannerlord (or its launcher) is running. Close it completely first.'
        Write-Info 'Tip: also exit Steam from the system tray (right-click → Exit), not just the window.'
        return $false
    }
    return $true
}

function Send-ToRecycle {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        Write-Info "skip (not present): $Path"
        return $false
    }
    try {
        $item = Get-Item $Path -Force
        if ($item.PSIsContainer) {
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(
                $Path, 'OnlyErrorDialogs', 'SendToRecycleBin')
        } else {
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
                $Path, 'OnlyErrorDialogs', 'SendToRecycleBin')
        }
        Write-Ok "moved to Recycle Bin: $Path"
        return $true
    } catch {
        Write-Err "could not delete '$Path' — $($_.Exception.Message)"
        return $false
    }
}

function Confirm-Action {
    param([string]$Prompt)
    Write-Host ''
    Write-Host "  $Prompt " -NoNewline -ForegroundColor Yellow
    Write-Host '[y/N]: ' -NoNewline -ForegroundColor White
    $a = Read-Host
    return ($a -eq 'y' -or $a -eq 'Y')
}

function Pause-Continue {
    Write-Host ''
    Write-Host '  Press Enter to return to menu...' -ForegroundColor DarkGray -NoNewline
    Read-Host | Out-Null
}

# -----------------------------------------------------------------------------
# Actions
# -----------------------------------------------------------------------------

function Action-ResetGraphics {
    param($P)
    Write-Section 'Reset graphics config (engine_config.txt only)'
    Write-Info 'Effect: deletes engine_config.txt. Bannerlord will regenerate it with default'
    Write-Info '        values on next launch. Use this if a setting change broke the game.'
    Write-Host ''
    Write-Info "Target: $($P.EngineConfig)"
    if (-not (Test-Path $P.EngineConfig)) {
        Write-Warn 'engine_config.txt not found — nothing to do.'
        return
    }
    if (-not (Confirm-Action 'Move engine_config.txt to Recycle Bin?')) {
        Write-Info 'cancelled.'; return
    }
    if (-not (Confirm-NoGameRunning)) { return }
    Send-ToRecycle $P.EngineConfig | Out-Null
    Write-Host ''
    Write-Ok 'Done. Launch Bannerlord normally — it will write a fresh engine_config.txt.'
}

function Action-ClearShaderCaches {
    param($P)
    Write-Section 'Clear shader caches (all 3 locations)'
    Write-Info 'Effect: removes precompiled shader caches. The game will rebuild them on next'
    Write-Info '        launch via "Build Shader Cache" in main menu. Takes 10–60 minutes.'
    Write-Host ''
    $targets = @()
    if ($P.ProgramDataShaders) { $targets += $P.ProgramDataShaders }
    if ($P.GameDir) {
        $targets += (Join-Path $P.GameDir 'Shaders\D3D11\compressed_shaders_cache.sack')
    }
    # Per-module shader sacks (TOR, etc.) — they ship their own caches.
    if ($P.GameDir) {
        $modulesDir = Join-Path $P.GameDir 'Modules'
        if (Test-Path $modulesDir) {
            Get-ChildItem -Path $modulesDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                foreach ($name in @('compressed_shader.cache.sack','compressed_shaders_cache.sack')) {
                    $f = Join-Path $_.FullName "Shaders\D3D11\$name"
                    if (Test-Path $f) { $targets += $f }
                }
            }
        }
    }
    if ($targets.Count -eq 0) {
        Write-Warn 'No shader caches found — nothing to clear.'
        return
    }
    foreach ($t in $targets) { Write-Info "found: $t" }
    Write-Host ''
    if (-not (Confirm-Action "Move all $($targets.Count) item(s) to Recycle Bin?")) {
        Write-Info 'cancelled.'; return
    }
    if (-not (Confirm-NoGameRunning)) { return }
    foreach ($t in $targets) { Send-ToRecycle $t | Out-Null }
    Write-Host ''
    Write-Ok 'Done. Launch Bannerlord, then Main Menu → Build Shader Cache (10–60 min).'
    Write-Warn 'Do NOT close the game while shader cache is rebuilding.'
}

function Action-FullReset {
    param($P)
    Write-Section 'Full reset (graphics config + launcher config + shader caches)'
    Write-Warn 'This removes engine_config.txt, BannerlordConfig.txt, and ALL shader caches.'
    Write-Warn 'Your key bindings, language, and graphics settings will be reset.'
    Write-Warn 'Save files and mod subscriptions are NOT touched.'
    Write-Host ''
    if (-not (Confirm-Action 'Proceed with full reset?')) {
        Write-Info 'cancelled.'; return
    }
    if (-not (Confirm-NoGameRunning)) { return }
    Send-ToRecycle $P.EngineConfig  | Out-Null
    Send-ToRecycle $P.BannerlordCfg | Out-Null
    Action-ClearShaderCaches -P $P
}

function Action-DisableAllMods {
    param($P)
    Write-Section 'Disable all third-party mods (vanilla-only mode)'
    Write-Info 'Edits LauncherData.xml: keeps Native + SandBoxCore + Sandbox + BirthAndDeath +'
    Write-Info 'CustomBattle + StoryMode + Multiplayer enabled, disables everything else.'
    Write-Info 'Use this when a mod conflict prevents launch.'
    Write-Host ''
    if (-not (Test-Path $P.LauncherData)) {
        Write-Err "LauncherData.xml not found at $($P.LauncherData)"
        return
    }
    if (-not (Confirm-Action 'Rewrite LauncherData.xml to vanilla-only?')) {
        Write-Info 'cancelled.'; return
    }
    if (-not (Confirm-NoGameRunning)) { return }

    # Backup the original to Recycle Bin via copy + send-original.
    $bak = "$($P.LauncherData).cd-backup-$(Get-Date -f 'yyyyMMdd-HHmmss')"
    Copy-Item $P.LauncherData $bak -Force
    Write-Ok "backup saved: $bak"

    [xml]$xml = Get-Content $P.LauncherData
    $vanilla = @('Native','SandBoxCore','Sandbox','BirthAndDeath',
                 'CustomBattle','StoryMode','Multiplayer','NavalDLC','FastMode')
    $changed = 0
    foreach ($node in $xml.SelectNodes('//UserModData')) {
        $id = $node.Id
        $want = $vanilla -contains $id
        $current = ($node.IsSelected -eq 'true')
        if ($want -ne $current) {
            $node.IsSelected = ([string]$want).ToLower()
            $changed++
        }
    }
    $xml.Save($P.LauncherData)
    Write-Ok "LauncherData.xml updated, $changed entry/entries changed."
    Write-Host ''
    Write-Info 'If the game launches now, re-enable mods one group at a time'
    Write-Info 'through the launcher to find the culprit.'
}

function Action-Diagnostic {
    param($P)
    Write-Section 'Diagnostic info'
    Write-Host ''
    Write-Info "Bannerlord Documents:    $($P.Documents)"
    Write-Info "  exists:                $(Test-Path $P.Documents)"
    Write-Info "Bannerlord ProgramData:  $($P.ProgramData)"
    Write-Info "  exists:                $(Test-Path $P.ProgramData)"
    Write-Info "Bannerlord game dir:     $(if ($P.GameDir) { $P.GameDir } else { '(not detected)' })"
    Write-Host ''
    Write-Info 'Files of interest:'
    foreach ($pair in @(
        @('engine_config.txt    ', $P.EngineConfig),
        @('BannerlordConfig.txt ', $P.BannerlordCfg),
        @('LauncherData.xml     ', $P.LauncherData),
        @('ProgramData\Shaders\ ', $P.ProgramDataShaders)
    )) {
        $exists = Test-Path $pair[1]
        $tag = if ($exists) { '[present]' } else { '[absent] ' }
        $colour = if ($exists) { 'Green' } else { 'DarkGray' }
        Write-Host "  $tag  $($pair[0]) -> $($pair[1])" -ForegroundColor $colour
    }
    Write-Host ''
    if (Test-Path $P.CrashesDir) {
        $latest = Get-ChildItem -Path $P.CrashesDir -Directory -ErrorAction SilentlyContinue |
                  Sort-Object LastWriteTime -Descending | Select-Object -First 3
        if ($latest) {
            Write-Info 'Latest crash dump folders:'
            foreach ($d in $latest) {
                Write-Host ('    {0}  ({1:yyyy-MM-dd HH:mm})' -f $d.Name, $d.LastWriteTime) -ForegroundColor White
            }
        } else {
            Write-Info 'No crash dump folders found.'
        }
    }
    Write-Host ''
    if (Test-BannerlordRunning) {
        Write-Warn 'Bannerlord IS currently running — close it before any reset.'
    } else {
        Write-Ok 'Bannerlord is not running.'
    }
}

function Action-OpenCrashesFolder {
    param($P)
    if (Test-Path $P.CrashesDir) {
        Start-Process explorer.exe $P.CrashesDir
        Write-Ok "Opened $($P.CrashesDir) in Explorer."
    } else {
        Write-Warn "Crashes folder doesn't exist yet: $($P.CrashesDir)"
    }
}

# -----------------------------------------------------------------------------
# Menu
# -----------------------------------------------------------------------------

function Show-Menu {
    Write-Host ''
    Write-Host '  Pick an action:' -ForegroundColor White
    Write-Host '    1) Reset graphics config only         (engine_config.txt → Recycle Bin)' -ForegroundColor Gray
    Write-Host '    2) Clear shader caches                (3 locations)' -ForegroundColor Gray
    Write-Host '    3) Full reset                         (1 + 2 + BannerlordConfig.txt)' -ForegroundColor Gray
    Write-Host '    4) Disable all third-party mods       (vanilla-only LauncherData.xml)' -ForegroundColor Gray
    Write-Host '    5) Show diagnostic info               (where everything lives)' -ForegroundColor Gray
    Write-Host '    6) Open crashes folder in Explorer' -ForegroundColor Gray
    Write-Host '    0) Quit' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  Choice: ' -NoNewline -ForegroundColor White
    return Read-Host
}

# -----------------------------------------------------------------------------
# Main loop
# -----------------------------------------------------------------------------
# Guard so dot-sourcing the script (`. .\recovery.ps1`) loads helpers without
# entering the menu — useful for testing path detection. Both direct execution
# (`.\recovery.ps1`) and `irm <url> | iex` set InvocationName to something
# other than '.', so they fire the menu normally.

if ($MyInvocation.InvocationName -ne '.') {
    Write-Banner
    $paths = Get-Paths
    Action-Diagnostic -P $paths

    while ($true) {
        $choice = Show-Menu
        switch ($choice) {
            '1' { Action-ResetGraphics       -P $paths; Pause-Continue; Write-Banner }
            '2' { Action-ClearShaderCaches   -P $paths; Pause-Continue; Write-Banner }
            '3' { Action-FullReset           -P $paths; Pause-Continue; Write-Banner }
            '4' { Action-DisableAllMods      -P $paths; Pause-Continue; Write-Banner }
            '5' { Action-Diagnostic          -P $paths; Pause-Continue; Write-Banner }
            '6' { Action-OpenCrashesFolder   -P $paths; Pause-Continue; Write-Banner }
            '0' { Write-Host ''; Write-Ok 'Bye.'; return }
            default { Write-Warn 'unknown choice.' }
        }
    }
}
