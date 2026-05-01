# Changelog

All notable changes to Crash Doctor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
