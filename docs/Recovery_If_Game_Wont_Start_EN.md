# Recovery: game won't start after Crash Doctor

This happens if you:
- lowered **in-game** Texture / Shader / Shadow Quality on Crash Doctor's advice
- applied the **M3.3 Engine Config** card (or any other card that changes graphics)
- did not do a full shader-cache rebuild after the change

The symptom: game crashes on the splash screen with the imperial soldier, or
right after you click "Continue".
The root cause: the old shader cache was built against the previous graphics
settings, and the game now tries to load it under the new ones. Mismatch → crash.

You can't open Crash Doctor because the game won't start. Manual steps below.

## Step 1. Delete engine_config.txt

Bannerlord will recreate it with defaults on next launch.

```
Documents\Mount and Blade II Bannerlord\Configs\engine_config.txt
```

If you ran Apply on M3.3 earlier, a backup lives in `Documents\Mount and Blade II
Bannerlord\Configs\backups\` or in the `CrashDoctor\backups\` folder. You can either
delete the file or restore it from backup — neither affects the launch.

## Step 2. Delete the shader cache

Three locations, delete **all three**:

1. **ProgramData (the main one)** — the whole folder:
   ```
   C:\ProgramData\Mount and Blade II Bannerlord\Shaders\
   ```
2. **Game folder** — one file:
   ```
   <Bannerlord install>\Shaders\D3D11\compressed_shaders_cache.sack
   ```
   where `<Bannerlord install>` is the Steam game folder (typically
   `C:\Program Files (x86)\Steam\steamapps\common\Mount & Blade II Bannerlord\`).

3. **Per-module sacks** — for every mod under `Modules/`:
   ```
   <Bannerlord install>\Modules\<ModName>\Shaders\D3D11\compressed_shaders_cache.sack
   <Bannerlord install>\Modules\<ModName>\Shaders\D3D11\compressed_shader.cache.sack
   ```
   Delete wherever they exist.

Recycle Bin is fine — restorable if anything goes sideways.

## Step 3. Verify game integrity (optional)

If the game still won't start after steps 1–2:

```
Steam → Bannerlord → Properties → Installed Files → Verify integrity of game files
```

Steam will replace any missing native files (10–30 seconds of checks).

## Step 4. Reboot the PC

A cold restart clears the page file and any held handles. Not "Sign out" —
a full Restart.

## Step 5. Launch the game and build shaders

1. Launch Bannerlord through the launcher with the same mod set.
2. **From the main menu** click **"Build Shader Cache"** (or hit Continue —
   the game will start the build itself).
3. Wait **20–60 minutes**. On TOR + custom mods it can be longer.
4. **Don't close the game** during the build. It is **NOT frozen** — the
   compiler is grinding through hundreds of shaders sequentially.
5. Don't open Chrome / Discord / browsers during this time — they steal VRAM
   and the compiler can miss the TDR window.

## Step 6. NVIDIA: restore settings via GeForce Experience

Only if none of the above helped and you're on an NVIDIA card.

1. Open **NVIDIA app** (or **GeForce Experience** if you're on the older one).
2. **Graphics** tab → find **Mount & Blade II: Bannerlord**.
3. Click **Optimize** (drag the slider a notch below Recommended if your card
   is weak).
4. Restart the game.

This rewrites graphics settings through the NVIDIA profile. The AMD analogue is
**AMD Adrenalin → Gaming → Bannerlord → Reset to Defaults**.

## If it still won't start

Symptom — even after every step, crash on splash. Then graphics aren't the
culprit. Check:
- the mod list — wasn't anything broken (a recently-added mod could have arrived
  corrupted)
- BLSE / ButterLib / Bannerlord.Harmony — all on current versions
- logs in `C:\ProgramData\Mount and Blade II Bannerlord\logs\` — send the latest
  `rgl_log_*.txt` and `watchdog_log_*.txt` to the support chat

## Prevention going forward

Every time you change graphics settings (through Crash Doctor or by hand
in-game):

1. Apply the change.
2. **REBOOT THE PC.**
3. Launch the game → Main Menu → **Build Shader Cache** → wait 20–60 minutes.
4. Only then load a save.

Skip steps 2 or 3 — and you'll step on this rake again.
