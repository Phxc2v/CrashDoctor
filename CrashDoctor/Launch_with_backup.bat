@echo off
REM Crash Doctor — pre-launch wrapper.
REM Backs up C:\ProgramData\Mount and Blade II Bannerlord\crashes\* into our cache
REM before starting Bannerlord (which wipes that folder on launch),
REM then backs up again on exit (in case the game crashed during this session).

setlocal EnableDelayedExpansion

set "PROGRAMDATA_CRASHES=%ProgramData%\Mount and Blade II Bannerlord\crashes"
set "PROGRAMDATA_LOGS=%ProgramData%\Mount and Blade II Bannerlord\logs"
set "MOD_DIR=%~dp0"
set "CACHE_DIR=%MOD_DIR%cache"

if not exist "%CACHE_DIR%" mkdir "%CACHE_DIR%"

REM Find Bannerlord launcher in default Steam path or via env override
set "BANNERLORD_DIR=%BANNERLORD_DIR%"
if "%BANNERLORD_DIR%"=="" set "BANNERLORD_DIR=C:\Program Files (x86)\Steam\steamapps\common\Mount & Blade II Bannerlord"
set "LAUNCHER=%BANNERLORD_DIR%\bin\Win64_Shipping_Client\Bannerlord.Launcher.exe"
if not exist "%LAUNCHER%" set "LAUNCHER=%BANNERLORD_DIR%\bin\Win64_Shipping_Client\TaleWorlds.MountAndBlade.Launcher.exe"

echo === Crash Doctor pre-launch backup ===
if exist "%PROGRAMDATA_CRASHES%" (
    echo [1/3] Backing up existing crashes from ProgramData...
    xcopy /E /I /Y /Q "%PROGRAMDATA_CRASHES%\*" "%CACHE_DIR%\" >nul 2>&1
    if !ERRORLEVEL! NEQ 0 (
        echo       WARNING: xcopy returned !ERRORLEVEL! — continuing anyway
    ) else (
        echo       OK
    )
) else (
    echo [1/3] ProgramData\crashes does not exist yet — skipped
)

if not exist "%LAUNCHER%" (
    echo [ERROR] Bannerlord launcher not found at:
    echo         %LAUNCHER%
    echo         Set BANNERLORD_DIR environment variable to your install path.
    pause
    exit /b 1
)

echo [2/3] Starting Bannerlord — wait for the game to fully exit before this window closes
start "" /wait "%LAUNCHER%"

echo [3/3] Game closed. Backing up post-session crashes...
if exist "%PROGRAMDATA_CRASHES%" (
    xcopy /E /I /Y /Q "%PROGRAMDATA_CRASHES%\*" "%CACHE_DIR%\" >nul 2>&1
    echo       OK
) else (
    echo       ProgramData\crashes is empty — nothing to back up
)

echo [4/4] Purging .dmp memory dumps from cache (saves ~1 GB each)...
del /S /Q "%CACHE_DIR%\*.dmp" >nul 2>&1

echo Done. Cache size:
dir /-c /s "%CACHE_DIR%" 2>nul | find "File(s)"

endlocal
