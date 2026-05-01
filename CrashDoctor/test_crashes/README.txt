This folder is for manually placed crash folders for testing rules.

Drop a folder here named like a real Bannerlord crash:
    test_crashes/
      └── 2026-05-01_19.43.58/   <- folder name = timestamp
          ├── crash_tags.txt
          ├── rgl_log_NNNNN.txt
          ├── watchdog_log_NNNNN.txt
          ├── engine_config.txt
          ├── BannerlordConfig.txt
          ├── module_list.txt
          └── crash_report.json   (optional, BUTR ButterLib)

dump.dmp is NOT needed — Crash Doctor never parses it. Skip it
to save disk space.

Crash Doctor scans this folder alongside ProgramData/.../crashes
and Modules/CrashDoctor/cache, so any folder placed here will
appear in the UI list immediately on next Refresh.
