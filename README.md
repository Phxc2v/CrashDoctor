# Crash Doctor

**Bannerlord crash log analyzer.** Reads your crash dumps and tells you in plain
language what to fix — in Russian or English. No internet, no telemetry, no
Harmony patches, no dependencies on other mods.

[🇷🇺 Русская версия ниже](#crash-doctor-русский)

---

## What it does

When Bannerlord crashes, it dumps logs into
`C:\ProgramData\Mount and Blade II Bannerlord\crashes\<timestamp>\`.
Crash Doctor reads them, matches against a rule base of 34+ known issues
(GPU misroute, page-file exhaustion, shader cache corruption, TOR-specific bugs,
mod-load issues, …) and shows you exactly what to do.

**Two-pane UI in the main menu:**
- Left — list of recent crashes
- Right — diagnosis with severity, description, numbered fix steps

If a crash is recognized, you see the fix. If it isn't, you can copy or
export the diagnosis as `.txt` and send it for analysis (link in-game).

## Install

1. Download `CrashDoctor.zip` from the [Releases](../../releases) page.
2. Extract into your Bannerlord `Modules/` folder. Final layout:
   ```
   <Bannerlord>/Modules/CrashDoctor/
       SubModule.xml
       bin/Win64_Shipping_Client/CrashDoctor.dll
       ModuleData/
       GUI/
   ```
3. In the Bannerlord launcher → enable **Crash Doctor** → Play.
4. Main menu → **Crash Doctor** button.

**Bannerlord supported:** v1.2.x – v1.3.15. Steam build only (Game Pass / MS Store
not supported by the engine API).

**No dependencies.** Crash Doctor does not require Harmony, ButterLib, BLSE,
or MCM. It deliberately runs even on broken mod stacks so you can diagnose
exactly when other mods can't load.

## Usage

| Button | What it does |
|---|---|
| Refresh | Re-scans crash folders |
| Open folder | Opens the selected crash's folder in Explorer |
| Open log folder | Opens `Modules/CrashDoctor/` |
| Copy / Export | Visible only when no rule matched — copies/saves the diagnosis text |
| Clear... | Sends crash logs to Recycle Bin (with safety dialog) |
| Close | Closes the screen (ESC works too) |

## Why crashes don't disappear

Bannerlord wipes `ProgramData/.../crashes/` on every launch — that's a known
behaviour and not a bug in Crash Doctor. The mod calls
`Utilities.SetDumpFolderPath()` on load to redirect *new* dumps into
`Modules/CrashDoctor/cache/`, which is outside the wipe path. Old crashes
that were in ProgramData before installing the mod will be lost on first
launch — there's nothing the mod can do about those.

For maximum safety there's `Launch_with_backup.bat` in the mod folder which
copies `ProgramData/.../crashes/*` into the cache before starting Bannerlord.
Run the game through it instead of Steam directly if you want zero loss.

## License

MIT — see [LICENSE](LICENSE). You can copy, modify and redistribute, but you
must keep the copyright notice and credit the authors.

---

# Crash Doctor (русский)

**Анализатор крашей Bannerlord.** Читает дампы и человеческим языком объясняет,
что чинить — на русском или английском (зависит от языка игры). Без интернета,
без телеметрии, без Harmony-патчей и без зависимостей от других модов.

## Что делает

Когда Bannerlord падает, он сваливает логи в
`C:\ProgramData\Mount and Blade II Bannerlord\crashes\<дата>\`.
Crash Doctor читает их, прогоняет через базу из 34+ известных причин
(GPU не та, заканчивается файл подкачки, битый кэш шейдеров, TOR-баги,
конфликты модов и т.д.) и показывает что делать.

**Две колонки в главном меню:**
- Слева — список крашей.
- Справа — диагноз: уровень критичности, описание, нумерованные шаги фикса.

Если краш распознан — видишь готовое решение. Если нет — можешь скопировать
или экспортировать диагноз и переслать на анализ в Telegram-канал
([@CodeRickTg](https://t.me/CodeRickTg)) — мы добавим правило в базу.

## Установка

1. Скачай `CrashDoctor.zip` с вкладки [Releases](../../releases).
2. Распакуй в папку `Modules/` Bannerlord. Должно быть:
   ```
   <Bannerlord>/Modules/CrashDoctor/
       SubModule.xml
       bin/Win64_Shipping_Client/CrashDoctor.dll
       ModuleData/
       GUI/
   ```
3. В лаунчере Bannerlord включи **Crash Doctor** → Play.
4. Главное меню → кнопка **Crash Doctor**.

**Поддерживается Bannerlord:** v1.2.x – v1.3.15. Только Steam-версия. Game Pass /
MS Store не поддерживаются движком.

**Без зависимостей.** Не требует Harmony, ButterLib, BLSE или MCM. Сделано
специально так, чтобы работать даже когда другие моды поломались — именно
тогда тебе и нужен анализ.

## Кнопки

| Кнопка | Что делает |
|---|---|
| Обновить | Пересканировать папки с крашами |
| Открыть папку | Открыть папку выбранного краша в Проводнике |
| Папка логов | Открыть `Modules/CrashDoctor/` |
| Скопировать / Экспорт | Видны только если краш не распознан — копируют/сохраняют диагноз |
| Очистить... | Удалить логи в Корзину Windows (с диалогом подтверждения) |
| Закрыть | Закрыть экран (ESC тоже работает) |

## Почему крашы пропадают между запусками

Bannerlord чистит `ProgramData/.../crashes/` при каждом старте — это его
поведение, а не баг мода. Мод при загрузке зовёт
`Utilities.SetDumpFolderPath()` чтобы перенаправить **новые** дампы в
`Modules/CrashDoctor/cache/` — эту папку игра не трогает. Краши которые
были в ProgramData до установки мода будут потеряны при первом запуске —
тут уже ничего не сделать.

Для максимальной надёжности в папке мода есть `Launch_with_backup.bat` —
он копирует `ProgramData/.../crashes/*` в кэш до запуска Bannerlord.
Если запускать игру через него вместо Steam напрямую — не потеряешь ничего.

## Лицензия

MIT — см. [LICENSE](LICENSE). Можно копировать, изменять и распространять, но
нужно сохранить копирайт и указать авторов.
