# Changelog — Crash Doctor

Все изменения с последней публикации на Steam Workshop.

Формат: один блок на «оформленную» версию (то, что попадёт в Steam). Точные точечные
бамп-релизы между ними сведены в один блок, чтобы не плодить шум для подписчиков.

---

## v1.3.10 — More crash patterns + late-game health + reliability fixes (2026-05-03)

Накопительный релиз поверх v1.3.2. 18 новых правил, 2 новых Tune-Up модуля, переработанная
работа с шейдер-кэшем и набор сервисных починок.

### Новые правила (всего +18)

Добавлены по реальным crash-репортам и интегрированному каталогу
`docs/crash_catalog_2026-05-02.txt` (BL-001…BL-100 + TOR-001…TOR-110 + LATE-001…LATE-025
+ BUTR/BLSE/Harmony):

**GPU**
- `gpu.create_texture_array_invalidarg` — `rglGPU_device::create_texture_array failed at
  d3d_device_->CreateTexture2D!` (E_INVALIDARG / «Параметр задан неверно»). Битый клиент
  на AMD Radeon RX 9070 XT + TOR + Battle Size 400. Fix: понизить Battle Size, закрыть
  VR-runtime'ы (Oculus/SteamVR держат 1.5–3 ГБ VRAM compositor-резерва), снять
  armor-моды, AMD Adrenalin профиль (выкл AFMF/Anti-Lag/HYPR-RX), DX11 ↔ DX12 toggle.
- `gpu.shader_compile_x3004_tbn` — HLSL X3004 «undeclared identifier '_TBN'» в
  `particle_shading.rsh` после апдейта движка (BL-001/002).
- `gpu.create_shader_resource_view_fail` — `CreateShaderResourceView failed at create_gpu_buffer`
  на тяжёлых TOR-локациях. Tessellation overflow → device suspended (TOR-007).

**Native / runtime**
- `native.access_violation_taleworlds` — `AccessViolationException + Source=TaleWorlds.MountAndBlade`
  на 1.2.10/1.2.11. Ванильная регрессия движка (BL-032).
- `native.stack_overflow` — `0xC00000FD STATUS_STACK_OVERFLOW`, recursive AI loop
  (BannerBearer / troop upgrade), фикшено ванилой в 1.1.0 (BL-034).
- `native.lordshall_div_by_zero` — `LordsHallFightMissionController + DivideByZero` на
  специфических осадных сценах (BL-040).

**Сейв / late-game**
- `save.warparty_clan_late_game` — `WarPartyComponent.get_Clan / OnFinalize / PreAfterLoad` NRE
  при загрузке сейва после смерти кланов. Fix: Null Hero Fix (Nexus 4728) + апдейт Diplomacy
  (BL-013 / LATE-003).
- `save.pregnancy_baby_npe` — `HeroCreator.DeliverOffSpring → PregnancyCampaignBehavior`
  на компаньоне редкой культуры. Fix: Baby Of Rare Culture Crash Fix (Nexus 9487) (LATE-014).

**TOR**
- `tor.assimilation_swap_troops` — `IndexOutOfRange + AssimilationCampaignBehavior.SwapTroopsIfNeeded`
  на bind/summon wraiths в Hunger Woods. Fix: TOR Assimilation Crash Fix (Nexus 8872) (TOR-015).
- `tor.party_size_limit_npe_with_ig` — `PartySizeLimitModel.GetPartyMemberSizeLimit` NRE на
  TOR + Improved Garrisons. Fix: TOR-IG Party Size Fix (Nexus 8884) (TOR-091).
- `tor.ds_battle_results_invalid_cast` — `InvalidCastException + DSBattleLogic.ShowBattleResults`
  на TOR + Distinguished Service. Fix: DS Compatibility Patch (Nexus 8874) (TOR-093).
- `tor.windsofmagic_access_violation` — `0xC0000005 + WindsOfMagic / SpellCast` на массовых
  вампирских осадных кастах. Fix: Particle Detail/Quality Low + убрать RTS Camera + WITM 1.13a
  (TOR-021/022).

**BUTR-стек**
- `harmony.stray_dll_in_main_bin` — лишний `0Harmony.dll` в `<game>/bin/Win64_Shipping_Client/`
  ломает версионную проверку загрузчика.
- `blse.format_exception_locale` — `ConstantDefinition.GetValue_Patch2 + FormatException`
  на BLSE 1.6.4 при не-en-US локалях. Fix: даунгрейд до 1.6.3.
- `butterlib.string_reader_settings` — битый JSON настроек ButterLib
  (`StringReader.ctor + SettingsProvider`). Fix: удалить
  `Documents/Mount and Blade II Bannerlord/Configs/ModSettings/ButterLib/`.
- `mcm.prefab_injector_field_info` — `PrefabInjector + ArgumentNullException fieldInfo`
  на MCM 4.0.7 / 5.0.4. Fix: апдейт до MCM 4.3.13 / 5.0.5+.

**Hardware**
- `hw.gpu_vram_likely_low` — DXDIAG показывает <6 ГБ выделенной VRAM. С учётом DXDIAG-bug на
  RDNA3/4 (RX 7000/9000) и high-end NVIDIA: первый шаг fix-инструкции «если у тебя на
  самом деле 7900/9070/4080/4090 — игнорируй карточку». Иначе советы понизить Texture
  Quality + Texture Budget + закрыть VRAM-eaters.

### Новые Tune-Up модули

**M2.2 GraphicsConfigChanged.** Авто-детектор пользовательских изменений настроек графики.
На старте мода снимает snapshot 35 графических ключей `engine_config.txt` в
`<Documents>/Mount and Blade II Bannerlord/CrashDoctor/state/engine_config_snapshot.txt`.
При следующем открытии Tune-Up — diff с текущим конфигом. Если игрок что-то изменил
в Options → Graphics — карточка появляется с одной кнопкой: очистить кэш шейдеров +
синхронизировать snapshot. После Apply UI явно требует REBOOT + Build Shader Cache,
потому что иначе следующий запуск падает на splash-screen с имперским солдатом
(старый кэш под старые настройки).

**M5.8 HeavyVramApps.** Сканер запущенных процессов на тяжёлых VRAM-консумеров.
33 имени, evidence-based ранжирование:
- **Worst** (1.5+ ГБ даже idle): Oculus / Meta Quest Link (`OVRServer_x64`), SteamVR
  (`vrcompositor`, `vrserver`), Mixed Reality Portal, Virtual Desktop Streamer; Ollama,
  LM Studio; DaVinci Resolve, Premiere Pro, After Effects, Topaz Video AI.
- **High** (0.5–4 ГБ): Blender, Photoshop, Lightroom, OBS Studio, NVIDIA Broadcast / ShadowPlay,
  XSplit, Epic Games Launcher.
- **Medium**: Chrome, Edge, Firefox, Brave, Opera, Discord (HW accel + overlay), Teams,
  Wallpaper Engine.

Если найден хоть один Worst-tier — severity escalates до Critical. Apply открывает
Task Manager (не убиваем сами — VR-runtime cold-kill может залипить шлем до перезагрузки).

**M5.9 LateGameHealth.** Look-ahead диагностика поздней кампании. Читает live
`Campaign.Current` (через TaleWorlds API): день кампании, живых героев, уничтожённых
королевств, активных войн на королевстве игрока. Срабатывает по порогам из
`docs/crash_catalog_2026-05-02.txt`:
- Hero bloat — 800+ → Warning
- Snowball — destroyed/total ≥ 0.4 при day < 200 → Warning
- War cascade — 3+ войн на королевстве игрока → Info
- Long campaign — день 500+ при 600+ героях → Info

Apply открывает в браузере страницу самого релевантного fix-мода на NexusMods:
hero bloat → Heroes Must Die (1164), snowball/war cascade → Diplomacy (832),
long campaign → Death Reduced (2497). Карточка скрыта когда `Campaign.Current == null`
(чистое главное меню без загруженного сейва).

### Изменения в M3.3 EngineConfig

`Apply` теперь:
1. Меняет `terrain_quality` (с backup'ом — как раньше).
2. **Сразу же** удаляет shader cache (`ProgramData/Shaders` + `compressed_shaders_cache.sack` +
   per-module `.sack` файлы → Корзина).
3. `NeedsReboot=true` → reboot-banner на табе.
4. UI-сообщение явно требует **обязательную последовательность**: REBOOT → запустить
   игру → Главное меню → Build Shader Cache → ждать 20–60 мин.

Корень: до v1.3.10 M3.3 менял `terrain_quality`, но не трогал кэш. Кэш под старое
значение → следующий запуск hit a mismatch → краш на splash screen. Юзеры
сообщали «после фикса Crash Doctor игра не запускается».

### Recovery doc

`docs/Recovery_If_Game_Wont_Start.md` — manual инструкция для случая, когда мод уже
не открыть (игра упала на splash). Шаги: удалить engine_config.txt, удалить три места
shader cache, Steam Verify, reboot, Build Shader Cache. Для NVIDIA — fallback на
NVIDIA Optimize. Линкуется в Workshop description в секции «If the game won't launch».

### CrashCollector — читает все rgl_log_errors

Папка краша часто содержит несколько последовательных запусков (ПИД 5136, 8144, 8312…).
Watchdog коррелирует с конкретным PID, но текстовая ошибка движка может быть в
`rgl_log_errors_<другой_PID>.txt`. Раньше мы читали только `rgl_log_<watchdog_PID>.txt`
и пропускали ошибки. Теперь `CrashCollector.BuildContext()` сливает все
`rgl_log_errors_*.txt` в `SignificantLogLines` — правила видят полную картину сессии.

### ElevatedExec — захват stderr

`Verb=runas` + `UseShellExecute=true` (требуется для UAC) запрещают redirect stdout/stderr,
поэтому когда elevated PowerShell скрипт падал и писал
`[Console]::Error.WriteLine($_.Exception.Message)` — сообщение терялось, юзер видел голое
«Elevated helper exited with code 1». Фикс: `RunPowerShell` теперь автоматически инжектит
prelude, перенаправляющий `[Console]::Error` в temp-файл, читает его после
`WaitForExit` и кладёт в `r.ErrorMessage`. Все four call-site (M1.1 Apply+Rollback,
M2.5 Apply+Rollback, M5.5 × 2) теперь показывают точную причину сбоя в UI.

### YAML-аудит как pre-flight gate

В `tests/CrashDoctor.Tests/YamlRuleLoaderTests.cs` добавлен тест
`All_module_data_yaml_files_parse_cleanly` — на каждом запуске прогоняет все
`Mod/CrashDoctor/ModuleData/**/*.yaml` через YamlDotNet и фейлит билд при первом
синтаксическом баге. Поймал скрытый баг в `gpu.yaml` v1.3.2 — escape-последовательности
`\P`, `\S`, `\D`, `\M` в double-quoted YAML строках ломали парсинг ВСЕГО файла gpu.yaml,
все `gpu.*` правила тихо выкидывались. Заменил `\` на `/` в путях (Windows понимает оба).

### Сервисные починки

- **Удаление крашей: «удалилось только 1 из N»**. Junction redirect делает
  `BannerlordCrashesDir → CrashCacheDir` физически одной папкой. Каждая crash-папка
  enumerate'илась дважды — по разным путям. Цикл удалял первую → junction уводил на
  физ-target, вторая итерация silent `continue`. Итого реально удалена половина.
  Фикс в `RecycleBinDeleter.CleanupCrashesFolders` и `M14_DumpCleanup.Detect`:
  skip путей с атрибутом `ReparsePoint` — junction'ные пути перечислены отдельно от
  физ-target'ов.
- **M2.1 Clear shader cache** больше не показывается как «найдено 1» при отсутствии
  крэш-маркеров в логах. Если за последние 30 дней нет shader-OOM/X3004/`DXGI_ERROR_DEVICE_REMOVED` —
  карточка скрыта (`Status=Healthy`). Раньше карточка появлялась всегда с Severity.Info
  и припиской «не обязательно» — нарушало принцип «recommendations only when relevant».
- **YAML escape bug в `gpu.yaml`** (см. выше) — все 6 `gpu.*` правил снова работают.
- **Universal scope** — релиз позиционируется как crash-аналайзер для **любого мода
  Bannerlord** (не только TOR). Правила без TOR-зависимости работают на ваниле и
  любых других модах; TOR-specific правила гейтятся через `module_list: TOR_Core`.

### Совместимость

Bannerlord v1.2.x – v1.3.15. Steam build only. M5.9 LateGameHealth требует
`TaleWorlds.CampaignSystem` — добавлен в csproj reference. Зависимостей от других
модов нет: Harmony, ButterLib, BLSE, MCM не требуются.

---

## v1.3.2 — Tune-Up & Remediation (2026-05-02)

Большой релиз. С v1.0.10 (на котором висит Steam Workshop) Crash Doctor превратился из
«читалки крашей» в полноценный инструмент диагностики **+ полу-автоматической
ремедиации**. Окно теперь — три таба: `Crashes`, `Tune-Up`, `History`.

### Tune-Up — 13 модулей полу-автоматической ремедиации

Каждый модуль: `Detect` → `Preview` (diff) → `Apply` → `Rollback`. Перед изменениями —
снимок реестра в `.reg`-бэкап (для UAC-операций) или копия файла. История с откатом —
на табе `History`.

| Id | Что делает | UAC | Reboot | Reversible |
|----|-----------|-----|--------|------------|
| **M1.1** | Pagefile auto-managed → 40/60 ГБ на выбранном диске | да | да | да |
| **M1.3** | Disk space check + быстрый запуск `cleanmgr` | нет | нет | — |
| **M1.4** | Очистка старых dump-файлов из `Bannerlord\crashes\` | нет | нет | — |
| **M2.1** | Очистка shader cache (vanilla + TOR-aware popup) | нет | нет | — |
| **M2.5** | TdrDelay = 60 s в HKLM (фикс GPU shader-OOM в TOR) | да | да | да |
| **M3.2** | Detection: Documents в OneDrive (включая pinned-режим) | нет | нет | — |
| **M3.3** | `engine_config.txt` → terrain_quality оптимизация | нет | нет | да |
| **M3.7** | Unblock DLLs (NTFS Zone.Identifier ADS) для всех модов | нет | нет | — |
| **M4.1** | BLSE / ButterLib / Harmony / MCM версии (read-only) | нет | нет | — |
| **M5.4** | Disable Fullscreen Optimizations для Bannerlord.exe | нет | нет | да |
| **M5.5** | Game DVR / Xbox Game Bar полностью off (HKLM+HKCU) | да | нет | да |
| **M5.7** | Background apps audit + быстрый запуск `taskmgr` | нет | нет | — |
| **M3.5** | Load order инструкция (read-only, без auto-rewrite) | нет | нет | — |

### Архитектура

- `IRemediationModule` — интерфейс с `Detect/Preview/Apply/Rollback`. `DetectionResult`
  имеет статус `NotApplicable / Healthy / NeedsAction / AlreadyApplied / Failed`.
- `RemediationContext` — общий блок с `Lang`, путями игры, `BannerlordDocumentsDir`,
  `StateDir`, `BackupsDir`, `BusyTracker`-sink для прогресс-репортинга из модулей.
- `RemediationHistoryStore` — JSON-журнал в
  `<Documents>\Mount and Blade II Bannerlord\CrashDoctor\state\history.json`. Вне
  Workshop folder — Steam re-validation иначе восстанавливает файлы.
- `RemediationHistoryStore.Clear()` — сохраняет неоткатанные reversible-записи (чтобы
  юзер не потерял возможность Rollback).
- Recommendations YAML: `ModuleData/recommendations/m{Id}_*.yaml` — длинные тексты
  (description + 4-5 шагов фикса) для каждого модуля, отделены от C#-кода.

### UAC и progress UI

- `ElevatedExec` — единая обёртка `Verb=runas` для `powershell.exe` / `reg.exe`. Один
  UAC consent dialog на операцию, Bannerlord не нужно elevated, никаких helper-exe в
  составе мода (memory rule).
- `BusyTracker` + `Task.Run` — Apply бежит на ThreadPool, UI читает прогресс в
  `TickFrame()`. Heartbeat-таймер плавно двигает bar даже когда модуль не репортит.
- Полноэкранный progress-overlay: имя модуля, детали («Удаление C:\foo (123 МБ)»),
  зелёный bar с процентами, тёмный backdrop.
- `RemediationFeedback` — единый popup для Apply / Rollback с `onDismissed`-callback
  для re-scan'а после закрытия (M3.2).
- `ApplyResult.FailLocalized(en, ru)` — двуязычные ошибки (UAC declined, помощник
  упал, файл не найден и т.д.).

### Reboot / Steam handling

- Reboot-pending banner на табе Tune-Up после Apply/Rollback с `NeedsReboot=true`.
- `ResolveStateDir` фолбэчит на Workshop folder если `Documents` не резолвится, но по
  умолчанию пишет в Documents — Steam re-validation Workshop folder убивает файлы.
- Миграция legacy state из Workshop → Documents (одноразовая, на старте).

### TOR-специфика

- `TorDetector` — сканит `<game>\Modules\` И `<workshop>\261550\<id>\` (Workshop folders
  имеют числовые имена, читаем `SubModule.xml`).
- M2.1 popup перед очисткой shader cache: предупреждает если найден TOR — после очистки
  TOR требует 10–50 минут перекомпиляции при следующем запуске.
- Новое правило `gpu.shader_compile_oom`: ловит `out of memory during compilation`,
  `pdb append failed`, `debug info append failed`, OOM-паттерны
  `pbr_metallic.rs` / `faceshader_high.rs`. 8 шагов фикса.

### UI / Gauntlet

- Кнопка `Показать все` в Crashes больше не закрыта под `(dev)`-build flag.
- Black overlay: `Color=` на Widget vs `Brush.Color=` на TextWidget (правильный паттерн
  Gauntlet — без Sprite заливка прозрачна).
- ScrollablePanel правильный паттерн (`ClipRect` + `InnerPanel` + `ScrollbarWidget`)
  на Tune-Up и History tabs.
- Auto-refresh при переключении табов.
- Author credit `by Phoenix · t.me/CodeRickTg` снизу слева.
- Полная локализация (en + ru) для всех новых ключей: 46 новых строк в
  `str_crashdoctor_strings.xml` / `*-rus.xml`.

### Build / publish hygiene

- `dotnet build` пишет напрямую в `steamapps\workshop\content\261550\3717685432\` —
  не в `Mod/CrashDoctor/`. Bannerlord грузит мод именно оттуда.
- Новый MSBuild target `StripPdbFromWorkshop`: удаляет `CrashDoctor.pdb` и legacy
  `Launch_with_backup.bat` из Workshop folder после каждого build (privacy: `.pdb`
  содержит абсолютные пути с именем dev-машины).
- XSD-валидация `SubModule.xml` против vendored BUTR-схем (`docs/butr/SubModule.xsd`)
  перед каждым Build — ловим typos в attribute names при компиляции, не в Bannerlord.
- `SubModule.PurgeOwnPdbFile()` runtime safety-net: на старте мода удаляет `.pdb`
  рядом с DLL для уже опубликованных билдов.

### Известные ограничения (см. `TODO.md`)

- Pagefile rollback потерян у пользователей с v1.2.x (clear до v1.3.1 не сохранял
  reversible записи). Workaround: `sysdm.cpl` → Виртуальная память → Авто.
- M4.1 временно скрыт в `BuildRemediationModules` — пользователь хочет проверить
  вручную нужен ли он перед re-enable.
- M3.5 (Load Order) переведён в display-only режим: vanilla launcher переписывает
  `LauncherData.xml` на каждом запуске, auto-write бесполезен.

---

## v1.0.10 — strip .pdb (2026-04-30)

Hotfix перед публикацией: `.pdb`-файлы содержат абсолютные пути с именем
dev-машины, нельзя публиковать в Steam Workshop / GitHub.

- `.gitignore`: добавлен `*.pdb` без исключений.
- `Mod/CrashDoctor/bin/Win64_Shipping_Client/CrashDoctor.pdb` снят с git tracking
  через `git rm --cached`.
- `SubModule.PurgeOwnPdbFile()` — runtime удаление `.pdb` на старте мода
  (defence-in-depth для уже опубликованных билдов).
- v1.0.10 bumped в `csproj` и `SubModule.xml` синхронно.

## v1.0.9 — junction redirect, force-crash test (2026-04-29)

- Junction `ProgramData/.../crashes` → `Modules/CrashDoctor/cache/` чтобы Bannerlord
  не вайпал крэш-файлы при каждом запуске.
- Force-crash test button (dev-only).
- Telegram-only fallback для нераспознанных крашей в Copy/Export.

## v1.0.4 — localization, dialog, cleanup (2026-04-28)

- Полный перевод UI и диагнозов на en + ru.
- Confirmation dialog перед Clear.
- Telegram-header в начале каждого Copy/Export.
- Display версии мода в UI footer.

## v1.0.0 — initial release (2026-04-27)

- Two-pane Gauntlet UI в главном меню (список крашей слева, диагноз справа).
- 34+ YAML-правил (`gpu.yaml`, `tor.yaml`, `modules.yaml`, `memory.yaml`, `assets.yaml`,
  `hardware.yaml`, `saves.yaml`).
- Парсинг `crashes/<ts>/` (crash_tags, watchdog_log, rgl_log, engine_config,
  BannerlordConfig, module_list, опционально crash_report.json/.html).
- Cleanup в Recycle Bin (Microsoft.VisualBasic.FileIO).
- Без зависимостей: ни Harmony, ни ButterLib, ни BLSE — мод работает даже когда
  другие моды поломаны.
