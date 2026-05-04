# Crash Doctor — Recovery Console

A standalone PowerShell rescue tool for the case Crash Doctor's in-game UI cannot help: **Bannerlord won't launch at all.**

When the game starts, the in-game `M22 Graphics Config Changed` module catches a stale shader cache before it crashes you — but only if the game starts. If the launcher closes immediately, the splash crashes on the imperial-soldier screen, or "Play" does nothing, the in-game mod never loads. That's where this script comes in.

> 🇷🇺 **Русская версия — ниже.**

---

## When to use

Run `recovery.ps1` if **any** of these are true:

- You changed in-game graphics settings (Shader Quality, Texture Quality, resolution, DLSS), saved, exited — and now the game crashes on launch / on the splash screen.
- You added or updated a mod, and now the launcher closes the second you press "Play".
- You reinstalled Bannerlord through Steam and **the same crash still happens** — Steam reinstall does not touch user data in `Documents\Mount and Blade II Bannerlord\` and `C:\ProgramData\Mount and Blade II Bannerlord\`. The bad config / corrupt shader cache survives a reinstall.
- You see "Bannerlord stopped working" with no further detail and don't know where to start.

If the game launches but crashes mid-session, you don't need this script — open Crash Doctor in-game and use the regular UI.

---

## How to run

Open **PowerShell** (`Win+R` → type `powershell` → Enter) and paste this single line:

```powershell
irm https://phxc2v.github.io/CrashDoctor/r.ps1 | iex
```

That's it. The script:
- needs no admin rights (everything is in user-space),
- needs no execution policy change (`iex` evaluates inline code, not a `.ps1` file),
- downloads no executable to disk — just runs in your current PowerShell session.

You can also run the local copy that ships with the mod, located at:
```
C:\Program Files (x86)\Steam\steamapps\workshop\content\261550\3717685432\recovery.ps1
```
With:
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Program Files (x86)\Steam\steamapps\workshop\content\261550\3717685432\recovery.ps1"
```

The local copy is useful if you have no internet or your network blocks GitHub.

---

## Menu options

The script opens with a diagnostic dump (where everything lives, latest crash dump folders, whether Bannerlord is currently running) and a menu:

| # | Action | What it does | When to pick it |
|---|---|---|---|
| 1 | Reset graphics config | Sends `Documents\Mount and Blade II Bannerlord\Configs\engine_config.txt` to the Recycle Bin. Bannerlord regenerates it with default values on next launch. | You changed Shader Quality / resolution / DLSS / etc. and the game won't start. **First option to try** for this case. |
| 2 | Clear shader caches | Deletes shader caches from all three locations: `C:\ProgramData\Mount and Blade II Bannerlord\Shaders\`, `<game>\Shaders\D3D11\compressed_shaders_cache.sack`, and per-module shader sacks (TOR, Harmony, etc.). Game rebuilds them via "Build Shader Cache" in main menu (10–60 minutes). | The game crashes on the splash screen with the imperial soldier, or you see "Missing shader" spam in the rgl_log before the crash. |
| 3 | Full reset | Combines actions 1 and 2 plus removes `BannerlordConfig.txt` (key bindings, language, launcher window state). Save files and Workshop subscriptions are NOT touched. | The game won't launch and you don't know which of 1 or 2 to pick. This is the safe nuclear option. |
| 4 | Disable all third-party mods | Rewrites `LauncherData.xml` to leave only vanilla modules enabled (Native, SandBoxCore, Sandbox, BirthAndDeath, CustomBattle, StoryMode, Multiplayer, NavalDLC, FastMode). Backup of the original is saved next to it. | A new mod broke the launcher, but you can't open the launcher to disable mods through the UI. After the game launches in vanilla mode, re-enable mods one group at a time to find the culprit. |
| 5 | Show diagnostic info | Prints all detected paths, which files exist, which crash dump folders are most recent, whether Bannerlord is currently running. Non-destructive. | You want to inspect state before doing anything. |
| 6 | Open crashes folder | Opens `C:\ProgramData\Mount and Blade II Bannerlord\crashes\` in Explorer. | You want to grab a recent dump folder to send to Crash Doctor's developer for analysis. |
| 0 | Quit | Exits the script. | When you're done. |

---

## Safety

Everything destructive goes to the **Recycle Bin**, not directly deleted. If something looks wrong, restore from Recycle Bin. The script:

- prompts `[y/N]` before any destructive action,
- refuses to act if Bannerlord (or its launcher) is currently running,
- backs up `LauncherData.xml` to a timestamped `.cd-backup-YYYYMMDD-HHMMSS` file before rewriting it,
- treats missing files as "skip", never errors,
- never edits the registry,
- never touches your save files or Workshop subscriptions.

---

## Troubleshooting

**"running scripts is disabled on this system"**
You ran the script as a `.ps1` file from disk and your ExecutionPolicy is `Restricted`. Use the `irm | iex` form instead — it bypasses the policy because the code is inline. If you must run from disk: `powershell -ExecutionPolicy Bypass -File ".\recovery.ps1"`.

**"Bannerlord IS currently running — close it before any reset"**
The launcher process is still alive. Close it from the system tray (right-click → Exit), and also close Steam from the tray (right-click → Exit) — Steam keeps Bannerlord-related background processes around for a while.

**`GameDir` shows empty in diagnostic**
The script could not find Bannerlord in any Steam library. Either Steam is installed in a non-standard location (set the `STEAM_INSTALL` environment variable as a workaround, then re-run), or Bannerlord is not installed via Steam (shader cache still works via `ProgramData`). Action 2 still cleans the `ProgramData` cache without `GameDir`.

**Cyrillic path detected (e.g. `C:\Users\...\OneDrive\Документы\...`)**
Expected. Windows MyDocuments resolves to whatever Documents path your locale and OneDrive setup defined. The script handles Cyrillic, OneDrive-redirected, and standard paths uniformly.

---

# Recovery Console — на русском

**Standalone PowerShell-скрипт для случая когда Crash Doctor (in-game) помочь не может:** игра вообще не запускается, мод не грузится.

## Когда запускать

Запускай `recovery.ps1` если:

- Поменял настройки графики в игре (качество шейдеров, разрешение, DLSS), сохранил, вышел — и теперь игра крашится на запуске / на splash-screen.
- Добавил или обновил мод — лаунчер закрывается сразу как нажал "Play".
- Полностью переустановил Bannerlord через Steam, но **тот же краш повторяется** — Steam при удалении игры **не трогает** `Documents\Mount and Blade II Bannerlord\` и `C:\ProgramData\Mount and Blade II Bannerlord\` (это user data). Битый конфиг и сломанный кэш шейдеров переживают переустановку.
- Видишь "Bannerlord stopped working" без подробностей и не знаешь с чего начать.

Если игра запускается и крашится в процессе игры — этот скрипт не нужен, открой Crash Doctor внутри игры через обычный интерфейс.

## Как запустить

Открой **PowerShell** (`Win+R` → `powershell` → Enter) и вставь одну строку:

```powershell
irm https://phxc2v.github.io/CrashDoctor/r.ps1 | iex
```

Всё. Скрипту:
- **не нужны** права админа (всё в user-space),
- **не нужно** менять ExecutionPolicy (`iex` запускает inline-код, не `.ps1` файл),
- ничего не качается на диск — выполнение в текущей PowerShell-сессии.

Можно запустить локальную копию (она ставится вместе с модом):
```
C:\Program Files (x86)\Steam\steamapps\workshop\content\261550\3717685432\recovery.ps1
```
Команда:
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Program Files (x86)\Steam\steamapps\workshop\content\261550\3717685432\recovery.ps1"
```
Локальная копия полезна если нет интернета или провайдер блокирует GitHub.

## Пункты меню

Скрипт сначала выводит диагностику (где что лежит, последние crash dump папки, запущен ли Bannerlord) и меню:

| # | Действие | Что делает | Когда выбирать |
|---|---|---|---|
| 1 | Reset graphics config | Отправляет `engine_config.txt` в **Корзину**. Bannerlord пересоздаст с дефолтными значениями на следующем запуске. | Менял качество шейдеров / разрешение / DLSS — и игра не стартует. **Первое что пробовать** в этом сценарии. |
| 2 | Clear shader caches | Удаляет кэш шейдеров со всех 3 мест: `C:\ProgramData\Mount and Blade II Bannerlord\Shaders\`, `<игра>\Shaders\D3D11\compressed_shaders_cache.sack`, и per-module sack-файлы (TOR, Harmony, и т.д.). Игра пересоберёт через "Build Shader Cache" в главном меню (10–60 минут). | Краш на splash-screen с имперским солдатом, или в логе rgl_log полно "Missing shader" перед крашем. |
| 3 | Full reset | Объединяет 1 + 2 плюс удаляет `BannerlordConfig.txt` (key bindings, язык, состояние окна лаунчера). Сейвы и подписки Workshop НЕ трогает. | Игра не стартует и непонятно что выбрать — 1 или 2. Это безопасный nuclear option. |
| 4 | Disable all third-party mods | Переписывает `LauncherData.xml` оставляя включёнными только vanilla-модули (Native, SandBoxCore, Sandbox, BirthAndDeath, CustomBattle, StoryMode, Multiplayer, NavalDLC, FastMode). Бэкап оригинала рядом. | Новый мод сломал лаунчер, но через UI лаунчера моды отключить не получается. После того как игра запустится в vanilla-режиме — включай моды по группам и ищи виновника. |
| 5 | Show diagnostic info | Все обнаруженные пути, какие файлы существуют, последние crash dumps, запущен ли Bannerlord. Ничего не меняет. | Хочешь посмотреть состояние перед действиями. |
| 6 | Open crashes folder | Открывает `C:\ProgramData\Mount and Blade II Bannerlord\crashes\` в Explorer. | Хочешь забрать свежий dump чтобы отправить разработчику Crash Doctor на анализ. |
| 0 | Quit | Выход. | Закончил. |

## Безопасность

Всё деструктивное идёт в **Корзину**, а не удаляется навсегда. Если что-то пошло не так — восстанови из Корзины. Скрипт:

- спрашивает `[y/N]` перед любым деструктивным действием,
- отказывается работать если Bannerlord (или лаунчер) запущен,
- делает бэкап `LauncherData.xml` в файл `.cd-backup-YYYYMMDD-HHMMSS` ДО переписывания,
- отсутствие файла = пропуск, без ошибки,
- не трогает реестр,
- не трогает сейвы и подписки Workshop.

## Troubleshooting

**"running scripts is disabled on this system"**
Запустил скрипт как `.ps1` с диска, ExecutionPolicy = `Restricted`. Используй форму `irm | iex` — она обходит политику (код inline, не файл). Если очень надо с диска: `powershell -ExecutionPolicy Bypass -File ".\recovery.ps1"`.

**"Bannerlord IS currently running — close it before any reset"**
Лаунчер ещё жив. Закрой его из системного трея (ПКМ → Exit), и закрой Steam там же (ПКМ → Exit) — Steam держит фоновые процессы Bannerlord ещё некоторое время.

**`GameDir` пустой в диагностике**
Скрипт не нашёл Bannerlord ни в одной Steam-библиотеке. Либо Steam установлен в нестандартное место (тогда скрипту надо помочь — выставить `STEAM_INSTALL` env var и перезапустить), либо Bannerlord не из Steam (кэш в `ProgramData` всё равно чистится). Действие 2 работает без `GameDir` — просто почистит ProgramData-часть.

**Кириллический путь (например `C:\Users\...\OneDrive\Документы\...`)**
Так и должно быть. Windows MyDocuments резолвит в тот путь который задала локаль и настройки OneDrive. Скрипт работает с кириллицей, OneDrive-redirect и стандартными путями одинаково.
