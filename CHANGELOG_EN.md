# Changelog — Crash Doctor

All changes since the last Steam Workshop publish.

Format: one block per "shipped" version (the one that lands in Steam). Point
bump-releases between them are folded into one block to avoid noise for
subscribers.

> 🇷🇺 Russian version: [`CHANGELOG.md`](CHANGELOG.md)

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
