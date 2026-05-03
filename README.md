# Crash Doctor

**Bannerlord crash analyzer & one-click tune-up.** Reads your crash dumps and
tells you in plain language what to fix — in Russian or English. Then applies
the most common Windows / driver / engine tweaks for you. No internet, no
telemetry, no Harmony patches, no dependencies on other mods.

[🇷🇺 Русская версия ниже](#crash-doctor-русский)

---

## What it does

When Bannerlord crashes, it dumps logs into
`C:\ProgramData\Mount and Blade II Bannerlord\crashes\<timestamp>\`.
Crash Doctor reads them, matches against a rule base of 40+ known issues
(GPU misroute, page-file exhaustion, shader-cache OOM, TOR-specific bugs,
mod-load issues, …) and shows you exactly what to do.

It now also helps you **apply** the fix — see Tune-Up below.

## Three tabs in the main menu

- **Crashes** — list of recent crashes with severity colour, and the
  diagnosis on the right (title, severity, numbered fix steps, evidence
  source link).
- **Tune-Up** — semi-automatic remediation modules. Each card shows what
  is wrong, what will change, and lets you Apply / Roll back. UAC consent
  appears once per operation.
- **History** — every Apply / Rollback you've done, with timestamp and
  result. Rolled-back entries stay visible with a green "rolled back" badge.

## Tune-Up modules

| What it fixes | UAC | Reboot | Reversible |
|---|:---:|:---:|:---:|
| **Pagefile** auto-managed → 40/60 GB on a drive of your choice | yes | yes | yes |
| **TdrDelay = 60 s** (most useful tweak for TOR / shader-OOM) | yes | yes | yes |
| **Shader cache clear** (vanilla + TOR-aware popup) | no | no | — |
| **Disk space audit** + one-click Disk Cleanup | no | no | — |
| **Old crash dump cleanup** | no | no | — |
| **engine_config.txt → terrain_quality** optimization | no | no | yes |
| **Unblock DLLs** (NTFS Zone.Identifier) for every mod | no | no | — |
| **Disable Fullscreen Optimizations** for Bannerlord.exe | no | no | yes |
| **Game DVR / Xbox Game Bar off** (HKLM + HKCU) | yes | no | yes |
| **Background apps audit** + one-click Task Manager | no | no | — |
| **OneDrive Documents detection** (incl. pinned mode) | no | no | — |
| **Recommended load order** (display only) | no | no | — |

Every reversible change is recorded, and the History tab can roll it back.
Registry changes are backed up as `.reg` files under your **user Documents**
folder before being touched (not the Workshop folder — Steam re-validation
would wipe state there).

## Install

1. Subscribe on [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3717685432) — Steam downloads the mod automatically.
   Or download `CrashDoctor.zip` from the [Releases](../../releases) page.
2. Open the Bannerlord launcher → enable **Crash Doctor** → click Play.
3. Main menu → **Crash Doctor** button.

If extracting manually, the final layout is:
```
<Bannerlord>/Modules/CrashDoctor/
    SubModule.xml
    bin/Win64_Shipping_Client/CrashDoctor.dll
    ModuleData/
    GUI/
```

**Bannerlord supported:** v1.2.x – v1.3.15. Steam build only (Game Pass / MS
Store not supported by the engine API).

**No dependencies.** Crash Doctor does not require Harmony, ButterLib, BLSE
or MCM. It deliberately runs even on broken mod stacks so you can diagnose
exactly when other mods can't load.

## Usage

| Button | What it does |
|---|---|
| Refresh | Re-scans crash folders / re-detects Tune-Up state |
| Apply | Applies the selected Tune-Up module (UAC consent if needed) |
| Rollback | (History tab) Reverts a previously applied change |
| Open folder | Opens the selected crash's folder in Explorer |
| Open log folder | Opens `Modules/CrashDoctor/` |
| Copy / Export | Visible only when no rule matched — copies/saves the diagnosis text |
| Clear... | Sends crash logs to Recycle Bin (with safety dialog) |
| Close | Closes the screen (ESC works too) |

## Why crashes don't disappear

Bannerlord wipes `ProgramData/.../crashes/` on every launch — that's its
own behaviour, not a bug in Crash Doctor. On the **first start of the mod**
we replace that path with a directory junction pointing to
`Modules/CrashDoctor/cache/`. The native crash dumper still writes to
`ProgramData/.../crashes/`, but the bytes physically land in our cache.
When Bannerlord clears the directory on the next launch, it removes only
the junction — the actual crash files survive.

No admin rights, no scheduled tasks, no separate executable.

## Sending unknown crashes for analysis

If a rule doesn't match, click **Export** in the right pane and send the
`.txt` to our Telegram channel: [@CodeRickTg](https://t.me/CodeRickTg).
We add a rule for it; everyone benefits in the next mod update.

## License

MIT — see [LICENSE](LICENSE). You can copy, modify and redistribute, but
you must keep the copyright notice and credit the authors.

---

# Crash Doctor (русский)

**Анализатор крашей Bannerlord и one-click тюнинг системы.** Читает дампы и
человеческим языком объясняет что чинить — на русском или английском (зависит
от языка игры). Теперь умеет ещё и применять типовые твики Windows / драйверов
/ движка за тебя. Без интернета, без телеметрии, без Harmony-патчей и без
зависимостей от других модов.

## Что делает

Когда Bannerlord падает, он сваливает логи в
`C:\ProgramData\Mount and Blade II Bannerlord\crashes\<дата>\`.
Crash Doctor читает их, прогоняет через базу из 40+ известных причин
(GPU не та, заканчивается файл подкачки, OOM при компиляции шейдеров, TOR-баги,
конфликты модов и т.д.) и показывает что делать.

Теперь умеет ещё и **применять** фикс — см. Tune-Up ниже.

## Три таба в главном меню

- **Диагностика крашей** — список крашей с цветом критичности и диагноз
  справа (заголовок, уровень, шаги фикса, ссылка на источник).
- **Настройка системы** (Tune-Up) — модули полу-автоматической ремедиации.
  Карточка показывает что не так, что изменится, кнопки «Применить» /
  «Откатить». UAC consent — один раз на операцию.
- **Журнал** — каждое применение / откат с таймстампом и результатом.
  Откатанные записи остаются видимыми с зелёной плашкой «откат: HH:MM».

## Что чинит Tune-Up

| Твик | UAC | Reboot | Откат |
|---|:---:|:---:|:---:|
| **Файл подкачки** auto → 40/60 ГБ на выбранном диске | да | да | да |
| **TdrDelay = 60 с** (главный твик от крашей TOR по таймауту GPU и OOM шейдеров) | да | да | да |
| **Очистка shader cache** (vanilla + TOR-aware) | нет | нет | — |
| **Аудит свободного места** + быстрый запуск «Очистки диска» | нет | нет | — |
| **Очистка старых dump-файлов** | нет | нет | — |
| **engine_config.txt → terrain_quality** оптимизация | нет | нет | да |
| **Unblock DLLs** (NTFS Zone.Identifier) для всех модов | нет | нет | — |
| **Disable Fullscreen Optimizations** для Bannerlord.exe | нет | нет | да |
| **Game DVR / Xbox Game Bar off** (HKLM + HKCU) | да | нет | да |
| **Аудит фоновых приложений** + быстрый запуск Диспетчера задач | нет | нет | — |
| **Детект Documents в OneDrive** (включая pinned-режим) | нет | нет | — |
| **Рекомендованный порядок загрузки** (только отображение) | нет | нет | — |

Каждое обратимое изменение записывается, и вкладка «Журнал» умеет откатывать.
Перед изменением реестра делается `.reg`-бэкап в твоей пользовательской папке
**Documents** (не в Workshop folder — Steam re-validation бы её затёр).

## Установка

1. Подпишись на [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3717685432) — Steam скачает мод автоматически.
   Или скачай `CrashDoctor.zip` с вкладки [Releases](../../releases).
2. В лаунчере Bannerlord включи **Crash Doctor** → нажми Play.
3. Главное меню → кнопка **Crash Doctor**.

При ручной распаковке структура должна быть такой:
```
<Bannerlord>/Modules/CrashDoctor/
    SubModule.xml
    bin/Win64_Shipping_Client/CrashDoctor.dll
    ModuleData/
    GUI/
```

**Поддерживается Bannerlord:** v1.2.x – v1.3.15. Только Steam-версия. Game
Pass / MS Store не поддерживаются движком.

**Без зависимостей.** Не требует Harmony, ButterLib, BLSE или MCM. Сделано
специально так, чтобы работать даже когда другие моды поломались — именно
тогда тебе и нужен анализ.

## Кнопки

| Кнопка | Что делает |
|---|---|
| Обновить | Пересканировать папки с крашами / пере-Detect Tune-Up |
| Применить | Применить выбранный модуль Tune-Up (UAC consent при необходимости) |
| Откатить | (Журнал) Отменить ранее применённое изменение |
| Открыть папку | Открыть папку выбранного краша в Проводнике |
| Папка логов | Открыть `Modules/CrashDoctor/` |
| Скопировать / Экспорт | Видны только если краш не распознан |
| Очистить... | Удалить логи в Корзину Windows (с диалогом) |
| Закрыть | Закрыть экран (ESC тоже работает) |

## Почему крашы больше не теряются

Bannerlord чистит `ProgramData/.../crashes/` при каждом старте — это его
поведение, а не баг мода. **На первом запуске мода** мы заменяем эту папку
на directory junction, ссылающуюся на `Modules/CrashDoctor/cache/`. Нативный
crash dumper по-прежнему пишет по старому пути, но физически файлы оказываются
в нашей папке. Когда Bannerlord чистит папку на следующем запуске — он
удаляет только junction, а реальные файлы остаются.

Без админ-прав, без планировщика задач, без отдельного приложения.

## Отправка нераспознанных крашей

Если правило не сматчилось — жми **Экспорт** в правой колонке и пришли .txt
в наш Telegram-канал: [@CodeRickTg](https://t.me/CodeRickTg). Мы добавим
правило, в следующем апдейте оно поедет всем.

## Лицензия

MIT — см. [LICENSE](LICENSE). Можно копировать, изменять и распространять, но
нужно сохранить копирайт и указать авторов.
