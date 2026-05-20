# Changelog — Crash Doctor

All changes since the last Steam Workshop publish.

Format: one block per "shipped" version (the one that lands in Steam). Point
bump-releases between them are folded into one block to avoid noise for
subscribers.

> 🇷🇺 Russian version: [`CHANGELOG.md`](CHANGELOG.md)

---

## Next publish — Pin Bannerlord to the high-performance GPU on hybrid-graphics laptops

> Visible mod version stays `v1.4.0` forever.

A targeted update: a new Tune-Up card for laptops with two graphics
adapters (Intel integrated + NVIDIA / AMD discrete). Crash Doctor notices
when Bannerlord rendered on the weak integrated GPU and, in one click,
pins the game to the discrete one.

---

### New: pin Bannerlord to the high-performance GPU on laptops (Tune-Up card)

A new card shows up in **System Tune-Up** when:
1. The PC has **both** an integrated GPU (Intel UHD / Iris, AMD Vega /
   Radeon Graphics) **and** a discrete GPU (NVIDIA GeForce / RTX / GTX,
   AMD Radeon RX / Pro, Intel Arc).
2. The most recent crash reports show that the display output went
   through the integrated GPU while the discrete one stayed idle,
   **or** terrain shader compilation flooded the log with «Missing
   shader from sack: pbr_terrain» (the classic stale-Intel-UHD-driver
   symptom).

«Apply» writes a single per-user registry entry telling Windows to
launch `Bannerlord.exe` on the **high-performance GPU**. Same as the
button under **Settings → System → Display → Graphics → Bannerlord →
High performance**, but you do not have to hunt the exe down by hand.

Why: on hybrid-graphics laptops the monitor output is usually wired
through the integrated GPU, and without an explicit pin the game
renders on it — even if there is an RTX 3050 or RX 6700M sitting
right next to it. The integrated GPU cannot handle The Old Realms
terrain shaders; in the first big battle or siege you get a
crash-on-VRAM-exhaustion followed by a corrupted save (the crash
catches the game mid-save-write).

No admin rights, no Windows reboot — just restart Bannerlord itself
for the new GPU to take effect. If nothing changes, the laptop BIOS
may have a hard MUX switch or a «discrete only» mode that overrides
the Windows preference. The card is reversible: rollback restores the
previous registry value.

The card does not show up on desktops with a single GPU or on laptops
where the display is already routed through the discrete GPU — we do
not push «helpful suggestions just in case».

---

### Fixed: "rebuild shaders" advice on terrain crashes no longer repeats uselessly

When the game crashed while drawing a terrain tile (the typical log:
dozens of "Missing shader from sack: pbr_terrain" lines in a row →
D3D11 access violation), Crash Doctor used to give one and the same
recommendation — press "Build Shader Cache" in the main menu. For most
players that worked on the first try. But for players with a corrupt
sack file (Steam download was interrupted, antivirus took a bite out
of the file, a Workshop mod download stalled), rebuilding the cache
did nothing: "Build Shader Cache" builds the user cache **from** those
same sack files, so a corrupt source yields a corrupt cache no matter
how many times you rebuild.

Crash Doctor now tells two cases apart by log content:

- **Cache was never built** (the log has no `read_compressed_shader_cache_package`
  read line) — recommendation: "Build Shader Cache" in the main menu.
  This is the case that gets fixed on the first try.
- **Cache was built, but the sack file is corrupt** (the read line is
  present, yet the shaders inside are missing) — the recommendation
  order is inverted: first **Steam → Game Properties → Installed Files
  → Verify Integrity**, then re-subscribe to TOR_Core / TOR_Environment
  / TOR_Armory in the Workshop (Workshop content often downloads only
  partially), and only after that a verification "Build Shader Cache".
  For brand-new GPUs (RTX 50-series, RX 9000-series) we also flag a
  driver rollback through DDU — the newest drivers occasionally fail
  to compile specific TOR shader permutations and cache the failure
  inside the sack.

Why the split: a player with a corrupt sack would have been rebuilding
shaders 4–5 times running into the exact same crash. The right step —
Steam Verify — is now the **first** and most prominent item, not the
third in a generic list.

---

### Fixed: «rebuild shader cache» card no longer fires on harmless settings

The «Graphics settings changed — clear shader cache before next launch»
card used to pop up after **any** change to nearly 40 different graphics
keys: switching resolution, toggling window mode, enabling dynamic
resolution, switching FXAA → TAA, any post-processing toggle (bloom /
vignette / depth of field / motion blur / chromatic aberration etc.),
changing anisotropic texture filtering, picking a DLSS mode, adjusting
character or environment detail.

The problem: none of those settings actually invalidates compiled
shaders — the engine applies them at runtime (as per-view scene
parameters / per-view postfx / SwapChain state). The card was asking
players to reboot and burn 20–60 minutes rebuilding shaders **for
nothing**.

The card now only fires on the 9 settings whose change can legitimately
require a rebuild: shader quality, terrain quality, shadow quality
(filtering + technique), foliage, water, lighting, tessellation, and
overall texture quality. Change anything else (for example, switch your
monitor resolution from 1920×1080 to 2560×1440 or enable dynamic
resolution) — Crash Doctor no longer suggests a rebuild, because it
isn't needed there.

---

## 2026-05-15 — Built-in save cleaner, Mods tab, Ctrl+D in-game save analysis, defensive guards, Windows TEMP relocation, support author button

> Visible mod version stays `v1.4.0` forever.

Large update: a full **built-in save cleaner** (previously we just pointed
people at an external Save Cleaner on Nexus), a new **Mods tab** that
analyses every installed module and flags issues, a **Ctrl+D** hotkey that
opens save analysis directly from a loaded campaign, three new **optional
defensive guards**, a new Tune-Up card that **relocates Windows TEMP** to a
free drive, and a **Support author** button with wallet addresses.

---

### New: built-in save cleaner

Previously, when a save had grown bloated (50+ MB, orphan parties from
removed mods), Crash Doctor could only recommend installing a separate
**Save Cleaner** mod from Nexus. Now cleaning runs **inside Crash Doctor** —
no extra mod needed.

What gets cleaned:
- **Abandoned crafted items** — items that lost their owner after a
  crafting mod was removed.
- **Glitched parties** — mobile parties with no `PartyComponent` or with
  no live faction binding (typical leftover of a removed mod).
- **Corrupted log entries** — journal events holding null references to
  heroes / settlements.
- **Per-mod wipe** — tick the mods to wipe in the list, the cleaner
  removes every object owned by those mods in one pass.

The algorithm is conservative: the original `.sav` is **never overwritten**.
Crash Doctor always writes a new file: `CrashDoctor_cleaned_<date>.sav`.
If anything goes wrong, the original is intact — reload it and carry on.

Adapted from **JungleDruid / bannerlord-save-cleaner** (MIT licence, the
licence file ships inside the mod: `Saves/Cleaner/LICENSE-SaveCleaner.txt`).

---

### New: Mods tab

A fifth tab in the Crash Doctor main menu. Analyses **every installed
module** (not just active ones) and surfaces:

- **Load issues**: missing dependencies, version mismatches, blocked DLLs
  (Windows MOTW), dependency-graph cycles.
- **Save safety**: mods that write to the save via `SaveableTypeDefiner` —
  these cannot be safely added or removed mid-campaign.
- **Module type**: pure content (XML / assets), Harmony code, BLSE plugin,
  etc.
- **Size**: see at a glance which mods are heavy.

Each row is clickable — a popup shows the full report: DLLs, dependencies,
analyser warnings, Workshop / Nexus link (if we recognised the mod).

---

### New: Ctrl+D — save analysis from inside the campaign

Until now, diagnosing a save meant exiting to the main menu. Now `Ctrl+D`
works straight from the map / town / mission:

- If a campaign is loaded → opens a dedicated **save analysis screen**:
  size, day, gold, party, mod list recorded in the save, plus buttons for
  the built-in cleaner (see above) and for wiping specific mods out of the
  save.
- If at the main menu → opens the usual Crash Doctor screen.

Handy when a save starts crashing or stuttering — you don't have to quit
just to check "what's in this save".

---

### New: three optional defensive guards

Three toggles appeared in Crash Doctor **Settings**. All **off by default** —
opt in only after running into a problem they address:

- **"Catch UI exceptions"** — wraps UI methods (inventory, encyclopedia,
  party screens) in a Harmony finalizer. If a third-party mod throws while
  rendering UI — the game shows a red error instead of dying. Strictly UI
  methods, never touches gameplay logic.
- **"Swallow mod exceptions"** — opt-in list of mods whose exceptions
  inside mission / campaign code are silently swallowed. Lets you keep
  playing when one known-buggy mod would otherwise crash the whole game.
- **"Log native crashes"** — installs a Windows VEH (Vectored Exception
  Handler). When the game dies on a native AV / heap corruption / stack
  overflow, `crashdoctor.log` gets a timestamped line with the exception
  code **before** TaleWorlds shows its crash dialog. Without this, native
  crashes are only visible in `.dmp` files.

Plus always-on (no toggle):
- **Emergency save** — on unhandled exception, the mod attempts a
  last-ditch save to `CrashDoctor_Emergency_<timestamp>.sav` before the
  game dies. Often rescues 2-3 hours of progress.
- **Late-game speed cap** — after the first native AV in the current
  session, or once the world hits ≥ 800 parties, the mod refuses x8 speed
  (a known TaleWorlds race between HourlyTick phases that deref-nulls on
  x8 in late-game). x4 still works.
- **Patch conflict detection** — startup self-test checks whether another
  mod has overridden our Harmony patches. If conflicts are found, the
  Crash Doctor main-menu button stays enabled but its tooltip lists what's
  conflicting.

---

### New: Windows TEMP relocation (Tune-Up card)

A new card appears in **System Tune-Up** when:
1. The drive holding `%TEMP%` has **less than 40 GB free**.
2. Another fixed drive has **more than 100 GB free**.

Apply creates `<BigDrive>:\Temp\<your username>` and updates the user's
`TMP` and `TEMP` environment variables to point at the new path. The
system-wide TEMP (shared across all users) is **not touched** — admin
rights are not required.

Why: Bannerlord's shader compiler writes intermediate files into `%TEMP%`
during "Build Shader Cache" and runtime shader recompiles. On a tight
system drive this fails with **out of disk space** errors that surface as
"pdb append failed" / "debug info append failed" — looks like shader bugs,
but really TEMP is full.

After Apply, **you MUST sign out of Windows and sign back in** (or
reboot) — environment changes only take effect for new logon sessions.
Bannerlord launched in the current session keeps using the old TEMP.
Reversible: rollback writes the previous value back.

---

### New: Support author button

Bottom-right of the Crash Doctor window now has a **Support the author**
button. The popup contains:

- **USDT Tron** — click copies the address to clipboard.
- **USDT ERC-20** — click copies the address to clipboard.
- (A Russian-card donation link is shown in the Russian localisation only.)

Plus a plain note: everything I make ships for free for everyone at the
same time. No pay-to-win updates, no donor-only content, no paying to skip
release queues. Donating is purely optional — it just keeps me going on
everything that's planned.

The `by Phoenix · t.me/CodeRickTg` line in the bottom-left is now
**clickable** — opens the Telegram channel in your browser.

---

### New crash rules for late-game

A new `late_game.yaml` collects patterns specific to long campaigns
(day 700+):

- Native AV without managed stack on x8 speed (see "Late-game speed cap"
  above — the mod now blocks this preemptively).
- Cascade crashes from orphan clans in `KingdomDecisionProposalBehavior`.
- Heavy saves (≥ 50 MB) → hint: "try the built-in cleaner, see Ctrl+D".

---

### Fixed

- **Mods showed up as "not loaded"** in the "Wipe mods from the save"
  dialog even when they were actually enabled — the mod was checking for a
  .NET assembly, but content-only mods (TOR_Armory, TOR_Environment,
  FastMode, LoreHardcore, the Russian translation) ship no DLL of their
  own. We now consult the same list the launcher uses —
  `ModuleHelper.GetActiveModules`.
- **TOR career-perk crash failed to match** when `rgl_log` was empty and
  the data came only from a BUTR report (BLSE without log capture). The
  `tor.career_perk_npe` rule now triggers on either source.
- **Save cleanup could silently report "0 objects removed"** if every
  cleanup addon refused to run during PreClean (e.g. on a broken campaign).
  Now it explicitly fails instead of falsely reporting success.
- **Duplicate entries accumulating in the "Swallow mod exceptions" list**:
  every save would persist the same mod id twice if it was already
  duplicated. Now dedup runs before write.
- **Stale `.tmp` files** in the settings folder after a crash mid-write.
  The temp filename is now unique per write, and old orphan `.tmp.*`
  siblings get swept on the next save.

---

### Under the hood

- `recovery.ps1` and `docs/r.ps1` **removed** from the mod — PowerShell
  scripts inside the mod are now banned by an internal rule (AV / Defender
  liked to flag them). Recovery instructions remain in `docs/RECOVERY.md`.
- `M21_ShaderCache` tests updated to match the 2026-05-10 change (scans
  `crashes/` instead of `logs/`).
- Save Cleaner adapter: the whole subsystem lives in
  `CSharpMod/CrashDoctor/Saves/Cleaner/`, adapted from
  JungleDruid/bannerlord-save-cleaner (MIT) — `LICENSE-SaveCleaner.txt`
  ships next to the code.
- Diagnostics guard subsystem (`Diagnostics/NativeCrashGuard.cs`,
  `UIErrorGuard.cs`, `ModSwallowGuard.cs`, `EmergencySaveService.cs`,
  `LateGameSpeedCap.cs`, `PatchConflictDetector.cs`) — Harmony patches
  strictly wrapped in try/catch with log, no unhandled exceptions leaking
  out of our code.

---

## 2026-05-10 — New Saves tab, late-game crash rules, performance subsystem removed

> Visible mod version stays `v1.4.0` forever.

**New: Saves tab.**

Crash Doctor can now diagnose your save files **before you load them** —
just reads the JSON header of each `.sav`, no campaign launch needed. Shows
up as a fourth main-menu tab next to Crashes, System Tune-Up, and History.

Each card shows: file name, date, size, campaign day, hero level, gold,
party size. Below that — the modlist diff between what was saved and what's
currently active in your launcher:

- **"Installed but not selected"** — the mod is installed, just unticked.
  One-click button enables them in the launcher.
- **"Not installed at all"** — recorded in the save but absent from your
  launcher entirely. Button copies the IDs to clipboard so you can search
  them on Steam Workshop / Nexus.
- **"Selected but not in save"** — added to an existing campaign. Some are
  documented-safe (Harmony, ButterLib, MCM — purely runtime), others are
  not — for known unsafe-to-add mods (CalradianClans, BannerKings) we
  surface a warning ("not save-game compatible — start a new campaign").
- **"Version drift"** — the mod's version in the save differs from what's
  installed now.

Plus several live heuristics:

- **Save body ≥ 50 MB** — almost always means orphan-party leftovers from
  removed mods; recommends installing **Save Cleaner** (Nexus #7763).
- **Bannerlord major-version mismatch** — saves made on 1.2.x and 1.3.x
  are not save-compatible.
- **Iron Man** — always recommends a backup before loading (a load crash
  deletes the file).
- **Known save-defining mods absent** — if the save references a mod that
  writes to the save via `SaveableTypeDefiner` (PlayerSettlement,
  BannerKings, TOR_Core, Dramalord, Diplomacy, ImprovedGarrisons,
  CalradianClans) and that mod isn't installed now, we show the URL where
  to re-install it.
- **Late-game milestone (day ≥ 700, size ≥ 25 MB)** — known risk of
  orphan-clan crashes (KingdomDecision NRE) in long-running campaigns.

Per-card buttons: enable missing mods, disable extras, copy IDs to
clipboard, open Save System Fix on Nexus (#1925) when there are absent
mods, open Save Cleaner on Nexus (#7763) when bloat is detected, make a
`.bak` backup, show in Explorer, send to Recycle Bin.

---

**New crash recognition rules:**

- **TOR Assimilation IndexOutOfRange** — late-game TOR crash on settlement
  faction transitions. Recommends installing the "TOR Assimilation Fix"
  mod from Nexus.
- **KingdomDecision on dead clan** — late vanilla (day 700+) daily-tick NRE
  on a reference to an eliminated clan. Solutions: Save Cleaner, or load a
  save from 1-2 days earlier.
- **Governor change on Bannerlord 1.2.7** — known regression in the Naval
  DLC build, fixed in 1.3.x. Recommends updating the game.

---

**FPS optimization module removed.**

The optimization module (the "Optimization" tab + the in-game HUD on
`Ctrl+O` / `Ctrl+P`) has been **fully removed**.

Reason: on large late-game saves (3000+ parties on TOR / EE1700) testing
showed the FPS gain was either absent or net-negative due to Bannerlord's
internal architectural ceiling. The popular **Performance Optimizer** mod
hits the same ceiling for the same reason. Rather than ship the illusion
of optimization, we drop the feature.

- All Harmony patches removed: `HourlyTickParty`, `HourlyTickSettlement`,
  `MobilePartyAi.Tick`, `MobilePartyVisual.Tick`, Romance state cache,
  distant-faction AI throttle, NPC matchmaking throttle.
- "Optimization" tab gone from the Crash Doctor menu.
- In-game FPS HUD removed. `Ctrl+O` / `Ctrl+P` no longer do anything.
- All optimization settings removed from `user_settings.xml` (legacy
  `<PerfTuneUp>` sections are silently ignored — nothing to migrate).
- `Bannerlord.Harmony` is no longer required.

What **still works**:
- Crash log recognition with detailed bilingual diagnostics.
- "System tune-up" tab with automated remediation cards (RAM, disk,
  drivers, shader cache, and more).
- History of applied fixes with rollback support.
- The new Saves tab (see above).
- `recovery.ps1` for the case when the game won't even launch.

Technical bonus: the in-game HUD overlay technique is preserved as a
guide for future mods in `docs/Gauntlet_HUD_Overlay.md`.

---

## 2026-05-09 — Optimization HUD, new crash rules, false-positive cleanup

> Visible mod version stays `v1.4.0` forever.

**New — Optimization HUD + Performance tab in Crash Doctor.**

Optional feature for users seeing FPS drops on big mod stacks (TOR, EE1700)
or just lots of parties on the map. **OFF by default** — the user opts in,
the mod doesn't push anything.

- A small overlay in the top-right of the campaign map shows live counters,
  FPS sparkline, and an A/B "with optimization vs without" comparison.
- `Ctrl+P` — toggle the throttle in real time, no restart needed.
- `Ctrl+O` — show / hide the overlay. Both hotkeys hinted in the panel itself.
- Your choice persists in `Documents\Mount and Blade II Bannerlord\CrashDoctor\state\`
  and survives any future mod update.
- Works on vanilla Bannerlord and any mod-mix, not only on The Old Realms.

What the throttle does when enabled:
- **Distant parties:** skip the hourly tick for invisible far-away parties
  (biggest FPS win).
- **Settlements:** distant towns and castles tick less often. Villages tick
  as before, food production is unaffected.
- **Distant AI:** far-away parties think 2 Hz instead of every frame.
- **Distant visuals:** far-away party animations update less often
  (OFF by default — minor flicker risk).

The A/B comparison line waits **5 minutes of activity in BOTH ON and OFF**
states before showing a delta. Until then it reads "Measuring: 4m more in
ON + 2m more in OFF". Stops the "−11 FPS, optimization hurts" line that
used to appear 12 seconds after Ctrl+P, when really only the GPU clock was
still ramping up.

The HUD switches language with the game — toggle EN/RU in Bannerlord
Options and the panel relabels on the next refresh tick (no game restart).

**Requires `Bannerlord.Harmony`** (free, on Steam Workshop). Without it
Crash Doctor still loads; the Performance tab shows a button to install
Harmony.

---

**No more `CAUTION: Crash Doctor depends on Bannerlord.Harmony(...)` dialog
on every launch.**

The vanilla TaleWorlds launcher compares the version pin strictly across
all 4 components, so every Harmony patch release was triggering the dialog.
Moved Harmony pinning to the BUTR community-extension element — vanilla
launcher ignores it, BLSE / Vortex / BUTR launchers still honor the load
order. Net result: no dialog on any Harmony version.

**New crash rules.**

- **GPU driver leak on long uninterrupted sessions.** On NVIDIA RTX 50-series
  (Blackwell) and AMD RX 9000 (RDNA 4) cards the driver gradually leaks
  memory; after 3+ hours the game crashes with a `create_texture_array`
  error. Crash Doctor now recognises this combo (GPU Crash flag + App Run
  Time > 3 h) and advises: quit to desktop every 2–3 hours (not just to
  the main menu — fully exit the process), update the GPU driver, monitor
  VRAM in Task Manager.
- The existing `CreateTexture2D` rule got a third trigger — same Blackwell
  long-session leak — with NVIDIA-specific steps (NVCP → Bannerlord.exe →
  off DLSS Frame Generation, Power management = Prefer maximum performance,
  Game Ready 580.x+).
- Rule engine learned to compare "greater than" / "less than" on crash-log
  values and to read fractional numbers correctly on Russian Windows
  (where the decimal separator is comma, not period).

**Hybrid-graphics laptops no longer get a false "low VRAM" warning.**

On gaming laptops with two GPUs (Lenovo Legion, ASUS ROG, MSI, Razer)
Windows under-reports the discrete card's VRAM as 3 GB even when the
real card is 8–12 GB (RTX 4060 / 4070 / 4080 Laptop). This is a known
Windows reporting bug, not a real shortage. Crash Doctor now detects
the hybrid-graphics setup and skips the low-VRAM warning. Desktop
behaviour is unchanged.

**Tune-Up false-positive cleanup.**

- **Temp cleanup card** no longer hangs around when there's nothing to
  delete. The card used to surface whenever `%TEMP%` was over 1 GB —
  even if every file was fresh and Apply skipped them all. Now the card
  only shows when ≥200 MB of files older than 7 days exist (something
  Apply can actually delete). If every stale file is locked by another
  process during Apply, the card stays hidden until the next Bannerlord
  launch.
- **Pending-reboot card** no longer fires 30 seconds after powering on
  the PC. Crash Doctor now checks how long Windows has been up — under
  10 minutes, the card treats any signals as stale leftovers from the
  previous boot. Also dropped one signal that's almost always non-empty
  on a healthy system.
- **Shader cache cleanup** can now strip the ReadOnly attribute from
  Steam Workshop folders. Steam occasionally pins downloaded files
  read-only and `SendToRecycleBin` was failing with access denied. If
  the Bannerlord log shows lots of missing-shader messages, Crash Doctor
  removes the attribute first.

**"Found N issues" counter no longer lies.**

Earlier the status line said "Found 3 issues" with an empty list under
it because the counter included cards the user had marked "Ignore". The
number now matches what's actually on screen.

**Stuck progress overlay after Apply launches an external app — fixed.**

Reported pattern: Apply on "close memory-hogging apps" → Task Manager
opens → Bannerlord loses focus → returning to the game showed the
progress overlay still up, refusing to close. Double protection:

- 6 cards whose Apply opens Task Manager / Disk Cleanup / browser /
  Explorer were moved to a fast path — the overlay is **never shown**
  for them.
- Watchdog: if the overlay sits for more than 30 seconds without an
  update, it self-closes. Catches any future regression.

**"CPU work saved: 12,345 times" replaces opaque "Total saved: 99%".**

The old line displayed in the optimization HUD was confusing — % of
what, exactly? The new line is concrete: that many times the CPU
didn't have to do extra work, which is the FPS gain.

---

## v1.4.1 — Splash "double loader" warning (2026-05-05)

After applying M2.1 / M2.2 / M3.3 (any module that wipes the shader cache)
the next Bannerlord launch fills the splash-screen progress bar **twice**:
modules first (normal, fast), then a long shader recompile (up to an hour).
Players mistake the second pass for a freeze, kill the game, and leave a
negative Workshop review.

Extended the post-Apply messages in those three modules with an explicit
line about the two passes: "Progress bar will fill TWICE. The slow second
pass is the shader recompile, not a freeze. Don't kill the game." Same
note added to M3.3's Preview text. No functional changes.

---

## v1.4.0 — Tune-Up Phase 2: 11 new modules + bundle export + Ignore (2026-05-04)

**New remediation modules (10):** `M1.2 RAM check`, `M1.5 TEMP cleanup`,
`M2.3 GPU info`, `M2.4 Bad driver`, `M2.6 GPU vendor cache`, `M3.6 Dependency
graph`, `M4.2 SHA-256 integrity`, `M5.2 VC++ Redistributable`, `M5.3 .NET
Runtime`, `M5.6 Pending reboot`, `M6.1 DirectX runtime`, `M6.2 HwSchMode`.
Coverage of categories 1–6 from the original roadmap is now ~80%.

**Crash bundle export.** The Export button now produces a ZIP with the full
crash folder (crash_tags + rgl_log + module_list + watchdog + minidump up to
100 MB) plus our `diagnosis.txt` and a bilingual `READ_ME_FIRST.txt` with
instructions on where to send it. Filename signals state —
`crashdoctor_unrecognised_<ts>.zip` when no rule matched,
`crashdoctor_bundle_<ts>.zip` when one or more did. The old text-only export
was useless on unrecognised crashes — support team now gets the raw artifacts.

**Ignore button on Tune-Up cards.** Persistent ignore-list at
`state/ignored_recommendations.json`, key = detection fingerprint
(severity + summary + sorted evidence lines). When state changes the
fingerprint differs and the card returns. Successful Apply wipes ignores
for that module.

**Module parser handles early-stage crashes.** `CrashCollector.BuildModules`
now falls back to parsing `[Runtime][Arguments][..._MODULES_*A*B*..._MODULES_]`
when the `Used Modules` section is missing (Bannerlord doesn't write it when
it crashes during module init). Without this fallback every `module_list:`-
based rule silently missed on those crashes — that's why "not recognised" used
to show on conflicts like NavalDLC + TOR_Core.

**iGPU detection via rgl_log.** New rule `hw.igpu_actually_selected` matches
the line `Selected graphics adapter: [N] <name>` — that's the authoritative
source, not the order of devices in DxDiag. On machines where DxDiag lists the
iGPU as `Display Devices 0` while the game actually renders on the dGPU, no
more false positives.

**Whitelist of cards DxDiag misreports VRAM on.** RTX 4070+/4080/4090, RTX
3080 Ti/3090, RX 7700+/7800+/7900, RX 9070, Arc A770/B580 — all have ≥12 GB
physically, but DxDiag sometimes reports 3–4 GB due to uint32 saturation in
`Win32_VideoController.AdapterRAM`. `SystemMatcher.MatchGpuField('vram_mb')`
now skips `lt`/`lte` for these cards (false-positive `hw.gpu_vram_likely_low`
on a real RTX 4080 Laptop is exactly what triggered this).

**8 new crash rules:**
- `tor.naval_dlc_conflict` — Naval DLC (War Sails) is incompatible with TOR
- `assets.tpac_corrupted_workshop_mod` — `.tpac` pack corrupted, evidence
  shows the mod's Workshop ID
- `assets.tpac_oversized_pool` — pack > 256 MB memory pool limit
- `assets.file_read_failed_verify_install` — generic IO fail
- `game.conversation_nre_executecontinue` — NRE in dialogue, typical
  CharacterReload / BannerCraft conflict
- `engine.team_index_invalid_burst` — combat-mod team registration storm
- `game.integrity_check_failed` — `Game Integrity is Achieved = False`
- `mods.heavy_stack_with_tor` — TOR + 5+ unofficial mods (via the new
  `module_list: { count_above: "5", excluding_official: "true" }` matcher)

**`UnhandledExceptionHandler`.** Registered at `OnSubModuleLoad` BEFORE any of
our other operations. Listens to `AppDomain.UnhandledException` +
`FirstChanceException`, writes managed stacks to `crashdoctor.log` without
swallowing. Throttled at 200 first-chance per session, filters TaleWorlds.*
expected catches.

**MSBuild target `SyncSubModuleXmlVersion`.** csproj `<Version>` automatically
syncs into `<Version value="vX.Y.Z" />` of `SubModule.xml` via
`BeforeTargets="Build"`. The old "bump version in two files" rule is now
automated.

**UI / UX fixes.**
- Apply button hidden on informational modules (M1.2 RAM, M2.3 GPU info) —
  nothing to apply, the button only added confusion
- UAC-required + URL-only modules run synchronously, without the BusyTracker
  overlay — the overlay used to freeze on screen because the UAC dialog /
  browser launch stole focus from Bannerlord and `OnFrameTick` paused
- Crash-card description has a fixed-height ceiling, no longer overlaps the
  Fix steps list below it
- M2.6 GPU vendor cache uses `File.Delete` directly — `VB.FileSystem.
  DeleteDirectory` used to pop Windows access-denied dialogs on
  driver-locked files
- M1.2 RAM now reads WMI Win32_PhysicalMemory.Capacity first — DIMM-accurate
  number (16384 MB), not the firmware-reservation-reduced
  GlobalMemoryStatusEx value

**Recovery doc bilingual split.** `docs/Recovery_If_Game_Wont_Start_EN.md` +
`_RU.md`. README.md links to the appropriate version per language section.

**Public README fix.** Broken link `docs/Recovery_If_Game_Wont_Start.md` on
public GitHub redirected to `docs/RECOVERY.md` (commit `077d8bf..d01e4bd`).

---

## v1.3.12 — .tpac async I/O fault detection (2026-05-04)

New rule `assets.tpac_async_read_burst` detects the classic Bannerlord
async-read-of-compressed-asset failure signature. When the engine can't read
a `.tpac` file (corrupted file / antivirus blocking / disk I/O error), it
spams the warning `Trying to make partial read on compressed asset data`
dozens to hundreds of times before the CLR managed exception (`0xE0434352`).
On real-world TOR + heavy Workshop-mod installs this pattern shows up
regularly.

Trigger: ≥ 100 occurrences of the partial-read warning in the log. Severity:
critical, confidence: medium (we know the signature, but there are 4 root
causes — Verify integrity, re-subscribe to Workshop, AV exclusion, `chkdsk`).

**Bonus matcher fix:** `LogLineMatcher` now correctly understands the dedup
suffix `(×N)` that `LogNormalizer.DedupConsecutive` appends to series of
identical lines. Without it `count_at_least` saw 1 hit instead of N for any
pattern with identical text — could have flapped `gpu.shader_cache_corrupt`
and any future burst rules.

`Trying to make partial read on compressed asset` and `Unable to open file
for asynchronous read` were also added to `LogNormalizer.SignificantTokens`
so they land in `SignificantLogLines`, not just the Last200 fallback.

---

## v1.3.11 — Translation completeness patch (2026-05-03)

Hotfix of accumulated translation bugs immediately after v1.3.10:

- **Typo in RU recommendations**: in `m33_engine_config.yaml:50` there was an
  awkward Latin/Cyrillic mix — `resуверный backup`. Should have been
  `резервная копия`. Fixed.
- **17 English error messages now have RU pairs.** Wherever the code caught
  `Exception ex` and returned `ApplyResult.FailLocalized(ex.Message,
  "Внутренняя ошибка: " + ex.Message)`, the English side showed bare
  `ex.Message` without a prefix while the Russian one had "Внутренняя
  ошибка:". Symmetrized to `"Internal error: " + ex.Message`.
- **13 orphan `ApplyResult.Fail()` in M14 / M21 / M33 / M35 / M37** replaced
  with `ApplyResult.FailLocalized(en, ru)`. Previously:
  - M14 / M21 / M37 Rollback (`"is not reversible from Crash Doctor"`)
  - M33 Apply / Rollback validation messages
  - M35 Apply / Rollback validation messages
  Every failure-message now has a Russian pair.

No functional changes — translations only. Build / tests clean.

## v1.3.10 — More crash patterns + late-game health + reliability fixes (2026-05-03)

Cumulative release on top of v1.3.2. 18 new rules, 2 new Tune-Up modules,
reworked shader-cache flow, and a stack of reliability fixes.

### New rules (+18 total)

Added based on real crash reports and the integrated catalog
`docs/crash_catalog_2026-05-02.txt` (BL-001…BL-100 + TOR-001…TOR-110 +
LATE-001…LATE-025 + BUTR/BLSE/Harmony):

**GPU**
- `gpu.create_texture_array_invalidarg` — `rglGPU_device::create_texture_array
  failed at d3d_device_->CreateTexture2D!` (E_INVALIDARG / "invalid
  parameter"). Real-world client on AMD Radeon RX 9070 XT + TOR + Battle
  Size 400. Fix: lower Battle Size, close VR runtimes (Oculus / SteamVR
  hold 1.5–3 GB VRAM compositor reservation), drop armor-mods, AMD Adrenalin
  profile (disable AFMF / Anti-Lag / HYPR-RX), DX11 ↔ DX12 toggle.
- `gpu.shader_compile_x3004_tbn` — HLSL X3004 "undeclared identifier '_TBN'"
  in `particle_shading.rsh` after an engine update (BL-001/002).
- `gpu.create_shader_resource_view_fail` — `CreateShaderResourceView failed at
  create_gpu_buffer` on heavy TOR locations. Tessellation overflow → device
  suspended (TOR-007).

**Native / runtime**
- `native.access_violation_taleworlds` — `AccessViolationException +
  Source=TaleWorlds.MountAndBlade` on 1.2.10 / 1.2.11. Vanilla engine
  regression (BL-032).
- `native.stack_overflow` — `0xC00000FD STATUS_STACK_OVERFLOW`, recursive AI
  loop (BannerBearer / troop upgrade), fixed in vanilla 1.1.0 (BL-034).
- `native.lordshall_div_by_zero` — `LordsHallFightMissionController +
  DivideByZero` on specific siege scenes (BL-040).

**Save / late-game**
- `save.warparty_clan_late_game` — `WarPartyComponent.get_Clan / OnFinalize /
  PreAfterLoad` NRE on save load after clan deaths. Fix: Null Hero Fix (Nexus
  4728) + update Diplomacy (BL-013 / LATE-003).
- `save.pregnancy_baby_npe` — `HeroCreator.DeliverOffSpring →
  PregnancyCampaignBehavior` on a rare-culture companion. Fix: Baby Of Rare
  Culture Crash Fix (Nexus 9487) (LATE-014).

**TOR**
- `tor.assimilation_swap_troops` — `IndexOutOfRange +
  AssimilationCampaignBehavior.SwapTroopsIfNeeded` on bind/summon wraiths in
  Hunger Woods. Fix: TOR Assimilation Crash Fix (Nexus 8872) (TOR-015).
- `tor.party_size_limit_npe_with_ig` — `PartySizeLimitModel.
  GetPartyMemberSizeLimit` NRE on TOR + Improved Garrisons. Fix: TOR-IG Party
  Size Fix (Nexus 8884) (TOR-091).
- `tor.ds_battle_results_invalid_cast` — `InvalidCastException +
  DSBattleLogic.ShowBattleResults` on TOR + Distinguished Service. Fix: DS
  Compatibility Patch (Nexus 8874) (TOR-093).
- `tor.windsofmagic_access_violation` — `0xC0000005 + WindsOfMagic /
  SpellCast` on mass vampire siege casts. Fix: Particle Detail/Quality Low +
  remove RTS Camera + WITM 1.13a (TOR-021/022).

**BUTR stack**
- `harmony.stray_dll_in_main_bin` — stray `0Harmony.dll` in
  `<game>/bin/Win64_Shipping_Client/` breaks the loader's version check.
- `blse.format_exception_locale` — `ConstantDefinition.GetValue_Patch2 +
  FormatException` on BLSE 1.6.4 with non-en-US locales. Fix: downgrade to
  1.6.3.
- `butterlib.string_reader_settings` — corrupt ButterLib settings JSON
  (`StringReader.ctor + SettingsProvider`). Fix: delete
  `Documents/Mount and Blade II Bannerlord/Configs/ModSettings/ButterLib/`.
- `mcm.prefab_injector_field_info` — `PrefabInjector + ArgumentNullException
  fieldInfo` on MCM 4.0.7 / 5.0.4. Fix: update to MCM 4.3.13 / 5.0.5+.

**Hardware**
- `hw.gpu_vram_likely_low` — DXDIAG reports < 6 GB dedicated VRAM. With
  awareness of the DXDIAG bug on RDNA3/4 (RX 7000/9000) and high-end NVIDIA:
  the first fix step says "if you actually have a 7900/9070/4080/4090,
  ignore this card". Otherwise tips on lowering Texture Quality + Texture
  Budget + closing VRAM-eaters.

### New Tune-Up modules

**M2.2 GraphicsConfigChanged.** Auto-detector of user-side graphics changes.
On mod startup snapshots 35 graphics keys from `engine_config.txt` into
`<Documents>/Mount and Blade II Bannerlord/CrashDoctor/state/
engine_config_snapshot.txt`. Next time Tune-Up opens — diff against current
config. If the player changed something in Options → Graphics, the card
appears with one button: clear shader cache + sync snapshot. After Apply the
UI explicitly demands REBOOT + Build Shader Cache, because otherwise the next
launch crashes on the imperial-soldier splash (old cache vs new settings).

**M5.8 HeavyVramApps.** Scanner of running processes for heavy VRAM consumers.
33 names, evidence-based ranking:
- **Worst** (1.5+ GB even idle): Oculus / Meta Quest Link
  (`OVRServer_x64`), SteamVR (`vrcompositor`, `vrserver`), Mixed Reality
  Portal, Virtual Desktop Streamer; Ollama, LM Studio; DaVinci Resolve,
  Premiere Pro, After Effects, Topaz Video AI.
- **High** (0.5–4 GB): Blender, Photoshop, Lightroom, OBS Studio, NVIDIA
  Broadcast / ShadowPlay, XSplit, Epic Games Launcher.
- **Medium**: Chrome, Edge, Firefox, Brave, Opera, Discord (HW accel +
  overlay), Teams, Wallpaper Engine.

If at least one Worst-tier is found, severity escalates to Critical. Apply
opens Task Manager (we don't kill VR runtimes ourselves — cold-killing them
can lock the headset until reboot).

**M5.9 LateGameHealth.** Look-ahead diagnostic for late campaigns. Reads live
`Campaign.Current` (via TaleWorlds API): campaign day, alive heroes,
destroyed kingdoms, active wars on the player's kingdom. Fires per thresholds
from `docs/crash_catalog_2026-05-02.txt`:
- Hero bloat — 800+ → Warning
- Snowball — destroyed/total ≥ 0.4 with day < 200 → Warning
- War cascade — 3+ wars on player's kingdom → Info
- Long campaign — day 500+ with 600+ heroes → Info

Apply opens the most relevant fix-mod page on NexusMods in the browser:
hero bloat → Heroes Must Die (1164), snowball / war cascade → Diplomacy (832),
long campaign → Death Reduced (2497). Card hidden when
`Campaign.Current == null` (clean main menu without a save loaded).

### Changes to M3.3 EngineConfig

`Apply` now:
1. Changes `terrain_quality` (with backup — same as before).
2. **Immediately** deletes the shader cache (`ProgramData/Shaders` +
   `compressed_shaders_cache.sack` + per-module `.sack` files → Recycle Bin).
3. `NeedsReboot=true` → reboot banner on the tab.
4. UI message explicitly demands the **mandatory sequence**: REBOOT → launch
   game → Main Menu → Build Shader Cache → wait 20–60 minutes.

Root cause: before v1.3.10, M3.3 changed `terrain_quality` but didn't touch
the cache. Cache for the old value → next launch hit a mismatch → splash-
screen crash. Users reported "after Crash Doctor's fix the game won't start".

### Recovery doc

`docs/Recovery_If_Game_Wont_Start.md` — manual instructions for the case
when the in-game UI is unreachable (game crashed on splash). Steps: delete
engine_config.txt, delete the three shader-cache locations, Steam Verify,
reboot, Build Shader Cache. NVIDIA fallback via NVIDIA Optimize. Linked from
the Workshop description in the "If the game won't launch" section.

### CrashCollector reads all rgl_log_errors

The crash folder often contains several consecutive launches (PIDs 5136,
8144, 8312…). The watchdog correlates to a specific PID, but the engine's
text error can be in `rgl_log_errors_<another_PID>.txt`. We used to read
only `rgl_log_<watchdog_PID>.txt` and miss errors. Now
`CrashCollector.BuildContext()` merges all `rgl_log_errors_*.txt` into
`SignificantLogLines` — rules see the full session picture.

### ElevatedExec — stderr capture

`Verb=runas` + `UseShellExecute=true` (required for UAC) prohibit stdout/
stderr redirection, so when an elevated PowerShell script failed and wrote
`[Console]::Error.WriteLine($_.Exception.Message)` the message was lost; the
user saw the bare "Elevated helper exited with code 1". Fix: `RunPowerShell`
now automatically injects a prelude that redirects `[Console]::Error` to a
temp file, reads it after `WaitForExit`, and puts it in `r.ErrorMessage`.
All four call-sites (M1.1 Apply+Rollback, M2.5 Apply+Rollback, M5.5 × 2)
now show the precise failure cause in the UI.

### YAML audit as pre-flight gate

A new test `All_module_data_yaml_files_parse_cleanly` in
`tests/CrashDoctor.Tests/YamlRuleLoaderTests.cs` runs every
`Mod/CrashDoctor/ModuleData/**/*.yaml` through YamlDotNet on every build and
fails on the first syntax bug. Caught a hidden bug in `gpu.yaml` v1.3.2 —
escape sequences `\P`, `\S`, `\D`, `\M` in double-quoted YAML strings broke
parsing of the entire `gpu.yaml`, all `gpu.*` rules silently dropped.
Replaced `\` with `/` in paths (Windows accepts both).

### Reliability fixes

- **Crash deletion: "only 1 of N deleted"**. The junction redirect makes
  `BannerlordCrashesDir → CrashCacheDir` physically the same folder. Each
  crash folder was enumerated twice — under different paths. The loop deleted
  the first one → the junction redirected to the physical target, the
  second iteration silently `continue`'d. Net result: half actually deleted.
  Fix in `RecycleBinDeleter.CleanupCrashesFolders` and `M14_DumpCleanup.
  Detect`: skip paths with the `ReparsePoint` attribute — junction paths
  enumerate separately from physical targets.
- **M2.1 Clear shader cache** no longer shows "1 finding" in the absence of
  crash markers in the logs. If the last 30 days has no shader-OOM / X3004 /
  `DXGI_ERROR_DEVICE_REMOVED`, the card is hidden (`Status=Healthy`).
  Previously the card always appeared with Severity.Info and a "not
  required" disclaimer — violated "recommendations only when relevant".
- **YAML escape bug in `gpu.yaml`** (see above) — all 6 `gpu.*` rules work
  again.
- **Universal scope** — release positioned as a crash analyzer for **any
  Bannerlord mod** (not just TOR). TOR-independent rules work on vanilla
  and any mod set; TOR-specific rules gate via `module_list: TOR_Core`.

### Compatibility

Bannerlord v1.2.x – v1.3.15. Steam build only. M5.9 LateGameHealth requires
`TaleWorlds.CampaignSystem` — added to csproj reference. No mod
dependencies: Harmony, ButterLib, BLSE, MCM not required.

---

## v1.3.2 — Tune-Up & Remediation (2026-05-02)

Big release. From v1.0.10 (the version stuck on Steam Workshop) Crash Doctor
turned from a "crash reader" into a full diagnostic + **semi-automatic
remediation** tool. The window is now three tabs: `Crashes`, `Tune-Up`,
`History`.

### Tune-Up — 13 semi-automatic remediation modules

Each module: `Detect` → `Preview` (diff) → `Apply` → `Rollback`. Before any
change — registry snapshot to `.reg` backup (for UAC operations) or a file
copy. History with rollback on the `History` tab.

| Id | What it does | UAC | Reboot | Reversible |
|----|-----------|-----|--------|------------|
| **M1.1** | Pagefile auto-managed → 40/60 GB on the chosen drive | yes | yes | yes |
| **M1.3** | Disk space check + one-click `cleanmgr` launcher | no | no | — |
| **M1.4** | Old crash-dump cleanup from `Bannerlord\crashes\` | no | no | — |
| **M2.1** | Shader cache clear (vanilla + TOR-aware popup) | no | no | — |
| **M2.5** | TdrDelay = 60 s in HKLM (fix for shader-OOM in TOR) | yes | yes | yes |
| **M3.2** | Detection: Documents on OneDrive (incl. pinned mode) | no | no | — |
| **M3.3** | `engine_config.txt` → terrain_quality optimization | no | no | yes |
| **M3.7** | Unblock DLLs (NTFS Zone.Identifier ADS) for every mod | no | no | — |
| **M4.1** | BLSE / ButterLib / Harmony / MCM versions (read-only) | no | no | — |
| **M5.4** | Disable Fullscreen Optimizations for Bannerlord.exe | no | no | yes |
| **M5.5** | Game DVR / Xbox Game Bar full off (HKLM + HKCU) | yes | no | yes |
| **M5.7** | Background apps audit + one-click `taskmgr` launcher | no | no | — |
| **M3.5** | Load order instructions (read-only, no auto-rewrite) | no | no | — |

### Architecture

- `IRemediationModule` — interface with `Detect/Preview/Apply/Rollback`.
  `DetectionResult` has status `NotApplicable / Healthy / NeedsAction /
  AlreadyApplied / Failed`.
- `RemediationContext` — shared block with `Lang`, game paths,
  `BannerlordDocumentsDir`, `StateDir`, `BackupsDir`, `BusyTracker` sink
  for progress reporting from modules.
- `RemediationHistoryStore` — JSON journal at
  `<Documents>\Mount and Blade II Bannerlord\CrashDoctor\state\history.json`.
  Outside the Workshop folder — Steam re-validation would otherwise
  restore files.
- `RemediationHistoryStore.Clear()` — preserves un-rolled-back reversible
  entries (so the user doesn't lose Rollback ability).
- Recommendation YAML: `ModuleData/recommendations/m{Id}_*.yaml` — long
  texts (description + 4-5 fix steps) for each module, separated from the
  C# code.

### UAC and progress UI

- `ElevatedExec` — single `Verb=runas` wrapper for `powershell.exe` /
  `reg.exe`. One UAC consent dialog per operation, Bannerlord doesn't need
  to be elevated, no helper-exe in the mod (memory rule).
- `BusyTracker` + `Task.Run` — Apply runs on the ThreadPool, UI reads
  progress in `TickFrame()`. A heartbeat timer moves the bar smoothly
  even when a module doesn't report.
- Full-screen progress overlay: module name, details ("Deleting C:\foo
  (123 MB)"), green progress bar with percentage, dark backdrop.
- `RemediationFeedback` — single popup for Apply / Rollback with an
  `onDismissed` callback for re-scan after close (M3.2).
- `ApplyResult.FailLocalized(en, ru)` — bilingual errors (UAC declined,
  helper crashed, file not found, etc.).

### Reboot / Steam handling

- Reboot-pending banner on the Tune-Up tab after Apply/Rollback with
  `NeedsReboot=true`.
- `ResolveStateDir` falls back to the Workshop folder if `Documents` is
  unresolvable, but by default writes to Documents — Steam re-validation of
  the Workshop folder kills files.
- One-time migration of legacy state from Workshop → Documents on startup.

### TOR specifics

- `TorDetector` — scans `<game>\Modules\` AND `<workshop>\261550\<id>\`
  (Workshop folders have numeric names, we read `SubModule.xml`).
- M2.1 popup before clearing the shader cache: warns if TOR is detected —
  after a clear, TOR requires 10–50 minutes of recompilation on next launch.
- New rule `gpu.shader_compile_oom`: catches `out of memory during
  compilation`, `pdb append failed`, `debug info append failed`, OOM
  patterns `pbr_metallic.rs` / `faceshader_high.rs`. 8 fix steps.

### UI / Gauntlet

- The "Show all" button in Crashes is no longer hidden behind a `(dev)`
  build flag.
- Black overlay: `Color=` on a Widget vs `Brush.Color=` on a TextWidget
  (correct Gauntlet pattern — without a Sprite the fill is transparent).
- Correct ScrollablePanel pattern (`ClipRect` + `InnerPanel` +
  `ScrollbarWidget`) on Tune-Up and History tabs.
- Auto-refresh on tab switch.
- Author credit `by Phoenix · t.me/CodeRickTg` on the bottom-left.
- Full localization (en + ru) for all new keys: 46 new strings in
  `str_crashdoctor_strings.xml` / `*-rus.xml`.

### Build / publish hygiene

- `dotnet build` writes directly to
  `steamapps\workshop\content\261550\3717685432\` — not to
  `Mod/CrashDoctor/`. Bannerlord loads the mod from there.
- New MSBuild target `StripPdbFromWorkshop`: removes `CrashDoctor.pdb` and
  legacy `Launch_with_backup.bat` from the Workshop folder after every
  build (privacy: `.pdb` contains absolute paths with the dev-machine
  username).
- XSD validation of `SubModule.xml` against vendored BUTR schemas
  (`docs/butr/SubModule.xsd`) before every Build — catches typos in
  attribute names at compile time, not at Bannerlord launch.
- `SubModule.PurgeOwnPdbFile()` runtime safety net: deletes `.pdb` next to
  the DLL on mod startup, for already-published builds.

### Known limitations (see `TODO.md`)

- Pagefile rollback lost for users on v1.2.x (clear before v1.3.1 didn't
  preserve reversible entries). Workaround: `sysdm.cpl` → Virtual Memory
  → Auto.
- M4.1 temporarily hidden in `BuildRemediationModules` — user wants to
  manually verify it's needed before re-enabling.
- M3.5 (Load Order) moved to display-only mode: vanilla launcher rewrites
  `LauncherData.xml` on every launch, auto-write is useless.

---

## v1.0.10 — strip .pdb (2026-04-30)

Hotfix before publish: `.pdb` files contain absolute paths with the dev-
machine name and can't be published to Steam Workshop / GitHub.

- `.gitignore`: `*.pdb` added without exceptions.
- `Mod/CrashDoctor/bin/Win64_Shipping_Client/CrashDoctor.pdb` removed from
  git tracking via `git rm --cached`.
- `SubModule.PurgeOwnPdbFile()` — runtime deletion of `.pdb` on mod
  startup (defence-in-depth for already-published builds).
- v1.0.10 bumped synchronously in `csproj` and `SubModule.xml`.

## v1.0.9 — junction redirect, force-crash test (2026-04-29)

- Junction `ProgramData/.../crashes` → `Modules/CrashDoctor/cache/` so
  Bannerlord doesn't wipe crash files on every launch.
- Force-crash test button (dev-only).
- Telegram-only fallback for unrecognised crashes in Copy/Export.

## v1.0.4 — localization, dialog, cleanup (2026-04-28)

- Full UI and diagnosis translation to en + ru.
- Confirmation dialog before Clear.
- Telegram header at the start of every Copy/Export.
- Mod version display in UI footer.

## v1.0.0 — initial release (2026-04-27)

- Two-pane Gauntlet UI in the main menu (crash list on the left, diagnosis
  on the right).
- 34+ YAML rules (`gpu.yaml`, `tor.yaml`, `modules.yaml`, `memory.yaml`,
  `assets.yaml`, `hardware.yaml`, `saves.yaml`).
- Parsing of `crashes/<ts>/` (crash_tags, watchdog_log, rgl_log,
  engine_config, BannerlordConfig, module_list, optionally
  crash_report.json/.html).
- Cleanup to the Recycle Bin (Microsoft.VisualBasic.FileIO).
- No dependencies: neither Harmony nor ButterLib nor BLSE — the mod works
  even when other mods are broken.
