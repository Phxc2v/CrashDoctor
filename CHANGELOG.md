# Changelog

All notable changes to Crash Doctor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
