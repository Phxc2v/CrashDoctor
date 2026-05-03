# Changelog

All notable changes to Crash Doctor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.2] — 2026-05-03

Major release. Crash Doctor is no longer just a crash reader — it now applies
the most common Windows / driver / engine fixes for you. The window has
**three tabs**: Crashes (the old diagnoser), Tune-Up (the new fixer),
History (audit log with one-click rollback).

### Added

- **Tune-Up tab — 13 semi-automatic remediation modules.** Each card shows
  what is wrong, what will change, and lets you Apply / Roll back. Detect
  → Preview → Apply → Rollback contract; reversible changes are journaled
  and undoable.
  - **M1.1 Pagefile** — switches the page file from auto-managed to a 40/60 GB
    range on a drive of your choice. The single most useful fix for
    out-of-memory shader compilation crashes in TOR. UAC required, reboot
    required, reversible.
  - **M2.5 TdrDelay = 60 s** (HKLM) — second most useful tweak for TOR /
    GPU timeout crashes. UAC, reboot, reversible.
  - **M2.1 Shader cache clear** — clears Bannerlord's shader cache; the
    confirmation popup warns if TOR is installed (10–50 min of recompilation
    on next launch).
  - **M3.7 Unblock DLLs** — strips NTFS Zone.Identifier streams from every
    installed mod's DLL. Fixes silent SmartScreen blocks that look like
    "mod not loading at all".
  - **M5.5 Game DVR / Xbox Game Bar off** (HKLM + HKCU). UAC, reversible.
  - **M5.4 Disable Fullscreen Optimizations** for Bannerlord.exe. HKCU only,
    no UAC, reversible.
  - **M1.4 Old crash dump cleanup** — frees disk by removing oldest dumps,
    keeping the most recent N for diagnostics.
  - **M1.3 Disk space audit** — reports free space on the game drive, warns
    below 20 GB, one-click launches `cleanmgr.exe`.
  - **M3.3 engine_config.txt → terrain_quality** optimization (file edit
    with backup, reversible).
  - **M5.7 Background apps audit** — scans Discord overlay, OneDrive sync,
    GeForce Experience, etc. Shows a sorted list, one-click opens Task Manager.
  - **M3.2 OneDrive Documents detection** — read-only check (catches the
    pinned-file mode that breaks save reads).
  - **M4.1 BLSE / ButterLib / Harmony / MCM versions** — read-only display
    of installed dependency mod versions (currently hidden, slated for v1.4).
  - **M3.5 Recommended load order** — display only (the launcher rewrites
    `LauncherData.xml` on every launch, so auto-write is pointless).
- **History tab.** Every Apply / Rollback is timestamped and stored in
  `Documents\Mount and Blade II Bannerlord\CrashDoctor\state\history.json`
  (NOT in the Workshop folder — Steam re-validation would wipe it).
  Rolled-back entries stay visible with a green "rolled back HH:MM" badge;
  reversible non-rolled-back entries are preserved when the history is
  cleared so `.reg` backups don't get orphaned.
- **One-shot UAC consent** for registry tweaks. We launch `powershell.exe`
  / `reg.exe` with `Verb=runas`. Bannerlord itself does not need to be
  elevated, no helper executable ships with the mod.
- **Async Apply with progress overlay.** Apply runs on a background thread;
  a full-screen overlay shows the module name, current step ("Deleting
  C:\foo (123 MB)"), and a green progress bar. Heartbeat keeps the bar
  moving even when the module doesn't report explicit progress.
- **Bilingual error messages.** Every Apply failure carries both English
  and Russian wording; the popup picks the right one from the game language.
- **TOR-aware shader cache clear popup.** Detects TOR installs in both
  `<game>/Modules/` and `<workshop>/261550/<id>/` and warns that re-creating
  the shader cache takes 10–50 minutes on next launch.
- **New crash rule** `gpu.shader_compile_oom` matching `out of memory during
  compilation`, `pdb append failed`, `debug info append failed`, and the
  TOR-specific OOM patterns `pbr_metallic.rs` / `faceshader_high.rs`.
  Eight numbered fix steps (in plain English / Russian).
- **Build hygiene:** new MSBuild target `StripPdbFromWorkshop` removes
  `.pdb` and the legacy `Launch_with_backup.bat` from the Workshop folder
  after every build. `SubModule.PurgeOwnPdbFile()` is the runtime
  safety-net for already-published builds.

### Changed

- **UI layout:** the screen is now a **3-tab window** (Crashes / Tune-Up /
  History) instead of a 2-pane crash list. Auto-refresh on every tab switch.
- **`.reg` backups** for every UAC registry write. Stored under
  `Documents\Mount and Blade II Bannerlord\CrashDoctor\state\backups\`,
  named `<timestamp>_<module-id>\hklm.reg` (or `hkcu.reg`).
- **Localization expanded** with 46 new strings covering Tune-Up, History,
  reboot pending, badges, and progress overlay (full English + Russian).
  Russian fixes: `cd_checkbox_off` no longer renders 1 character wider
  than `cd_checkbox_on`; `cd_tuneup_evidence_header` is now distinct from
  `cd_details_header` ("Что нашли:" vs "Подробности:");
  `cd_tuneup_btn_show_actionable` reads as a button ("Только проблемы"),
  not a section header.
- **Author credit** "by Phoenix · t.me/CodeRickTg" in the bottom-left of
  the screen.

### Fixed

- After a successful Rollback in the History tab, the entry now stays
  visible with a green "rolled back HH:MM" badge instead of silently
  disappearing — the Rollback button is hidden, but you get visual
  confirmation that the rollback actually happened.
- ScrollablePanel binding pattern across Tune-Up and History
  (`ClipRect` + `InnerPanel` + `ScrollbarWidget`) — the panels now scroll
  reliably.
- Shader cache rule no longer false-positives on benign `compile_shader:`
  log lines. Removed the bare filename matchers (`pbr_metallic.rs`,
  `faceshader_high.rs`, `particle_shading.rs`, `rglgpu_device::lock_texture`)
  that hit normal compile lines, kept the explicit OOM markers and DXGI
  error codes (`0x887A0005/0006/0020`, `dxgi_error_device_removed`).

### Removed

- `Launch_with_backup.bat` — superseded by the directory junction added
  in v1.0.9 (the junction makes pre-launch backups unnecessary).

## [1.0.10] — 2026-05-02

### Fixed

- `.pdb` debug symbols no longer ship in the Workshop bundle. They contain
  absolute paths with the build user's name, which is a privacy leak.
  `SubModule.OnSubModuleLoad` now also deletes any `.pdb` it finds next to
  the DLL on startup as a safety-net for already-installed copies.

## [1.0.9] — 2026-05-01

### Added
- **Directory junction** at `ProgramData\Mount and Blade II Bannerlord\crashes`
  → `Modules\CrashDoctor\cache`. Created on `OnSubModuleLoad` via `mklink /J`
  (no admin rights). Bannerlord native crash dumper writes to the junction,
  files physically land in our cache, and the next-launch wipe deletes only
  the junction — content survives. Existing subfolders are migrated into cache
  before the junction is created.
- **Force-crash test button** ("Сгенерировать краш") — hidden by default,
  toggled via `ModuleData/CrashDoctorSettings.xml`:
  ```xml
  <ShowForceCrashButton>true</ShowForceCrashButton>
  ```
  Calls `kernel32!RaiseException(0xC0000005, NONCONTINUABLE)` — real native
  access violation. Bannerlord's `SetUnhandledExceptionFilter` catches it
  and runs the crash dumper. Used to verify the redirect actually works.
  `Environment.FailFast` is managed-only and skips the native filter.
- Footer label "Crash Doctor vX.Y.Z · build YYYY-MM-DD HH:mm:ss" so users
  can see which version is loaded.

### Changed
- **Unrecognized-crash text rewritten** for both EN and RU. Only directs
  users to the Telegram channel `https://t.me/CodeRickTg` (no more Discord,
  TaleWorlds Forum or Reddit refs).
- "Fix steps:" header and list are now hidden for unrecognized crashes
  (new `HasFixSteps` property).

### Fixed
- v1.0.5..1.0.6: `ExecuteForceCrash` was missing from VM (silent edit
  failure in an earlier build) — button binding pointed to a non-existent
  method and clicks did nothing. Wired correctly now.
- v1.0.7: switched from `Environment.FailFast` to `RaiseException` —
  the former is managed-only and skips Bannerlord's crash dumper.
- Localization restructured to vanilla TaleWorlds layout
  `ModuleData/Languages/`. Old file name conflicted with Native and
  failed to load — that's why RU/EN appeared mixed before.
- Cleanup `IsProtected()` no longer falsely shields working subfolders
  (`test_crashes/`, `cache/`, `exports/`); whitelisted explicitly.
- `_selected = null` reset after Clear so Copy/Export disappear properly.
- Read-only / hidden / system attributes stripped from files **and**
  subdirectories before sending to Recycle Bin.
- Windows "File In Use" popup no longer appears — `UICancelOption.DoNothing`
  + silent IOException handling + `*_<currentPID>.txt` skipped.

## [1.0.4] — 2026-05-01

### Added
- Live preview in clear dialog: "Will delete: N of M crash folders".
- Footer label with version + build timestamp ("Crash Doctor v1.0.4 · build YYYY-MM-DD HH:mm:ss").
- Telegram channel header line at the top of every Copy/Export output.
- `test_crashes/` folder for drop-in fixture testing of new rules.

### Changed
- Localization moved to vanilla TaleWorlds layout `ModuleData/Languages/`
  with unique file name `str_crashdoctor_strings.xml` (the previous
  `std_module_strings_xml.xml` clashed with Native and silently failed
  to load — that's why RU/EN appeared mixed before).
- Default of "Keep last 3 crashes" is now OFF — the button does what it says.
- Copy / Export buttons visible **only** for unrecognized crashes (avoids
  duplicate spam to the analysis channel).
- Confirmation dialog now uses an opaque popup canvas + 85% black overlay
  (was see-through before).

### Fixed
- `IsProtected()` falsely matched any path containing `Modules/CrashDoctor`,
  which silently protected our own working subfolders. Now whitelists
  `test_crashes/`, `cache/`, `exports/` for deletion while still guarding
  `bin/`, `ModuleData/`, `GUI/`, `Localization/`.
- After cleanup, the right pane was still showing the deleted crash's
  diagnosis with Copy/Export visible — `_selected` is now reset properly.
- Read-only / hidden / system attributes are stripped from files **and**
  subdirectories before sending to Recycle Bin.
- `GC.Collect()` before delete to release our own short-lived file handles
  (CrashCollector reads files just before user clicks Delete).
- Windows "File In Use" popup no longer shown — `UICancelOption.DoNothing`
  + silent IOException catch + per-file detailed Logger.Warn.
- File handles of the running game's own logs (`*_<pid>.txt`) are
  detected by name and skipped without trying to delete them.

## [1.0.0] — 2026-05-01

### Added
- First public release.
- Reads crash artifacts from `ProgramData/.../crashes` and from
  `Modules/CrashDoctor/cache/` (engine dump path redirect).
- 34 starter rules across categories: gpu (4), memory (2), modules (6),
  saves (2), assets (3), hardware (6), tor (11).
- BUTR Crash Report parser (Schema v14, JSON + HTML fallback).
- Two-pane Gauntlet UI in main menu with severity-coloured diagnoses
  and numbered fix steps.
- Full localization for English and Russian (UI + diagnosis texts).
- Recycle Bin cleanup with confirmation dialog (keep last 3, delete
  `.dmp`, 2-second anti-misclick timer).
- Diagnosis export to `.txt` for unrecognized crashes — sends to
  the Telegram analysis channel for new rules.
- Auto-purge of `.dmp` files (1 GB+ each) at every load.
- `Launch_with_backup.bat` wrapper to backup crashes before launching
  Bannerlord (covers cleanup that happens before the mod loads).
