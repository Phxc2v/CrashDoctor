# Changelog — Crash Doctor

Все изменения с последней публикации на Steam Workshop.

Формат: один блок на «оформленную» версию (то, что попадёт в Steam). Точные точечные
бамп-релизы между ними сведены в один блок, чтобы не плодить шум для подписчиков.

> 🇬🇧 English version: [`CHANGELOG_EN.md`](CHANGELOG_EN.md)

---

## 2026-05-09 — Настройки сохраняются, поддержка ваниллы, чистка ложных предупреждений

> Видимая версия мода остаётся `v1.4.0` навсегда. Эта запись описывает внутренний билд.

**Оптимизация теперь работает на любой сборке, не только на TOR.**

Раньше окно оптимизации появлялось только если установлен The Old Realms. Теперь
работает на ванильном Bannerlord и любом моде:

- На карте кампании по `Ctrl+O` показать/скрыть окно, по `Ctrl+P` — включить/выключить
  оптимизацию мгновенно, без перезапуска игры. Любая сборка — окно появится сразу.
- По умолчанию оптимизация **выключена**. Включаешь сам кнопкой в Crash Doctor или
  `Ctrl+P` на карте. До нажатия — мод не делает ничего, нагрузки нет.
- Подсказка «Скрыть / показать: Ctrl+O» теперь видна прямо в окне над строкой
  «ОПТИМИЗАЦИЯ ВКЛ/ВЫКЛ» — обе горячие клавиши на виду.

**Твой выбор переживает обновления мода.**

Включил оптимизацию, скрыл окно через `Ctrl+O`, поменял какие-то настройки —
всё пишется в папку `Documents\Mount and Blade II Bannerlord\CrashDoctor\state\`.
Steam при обновлении мода сюда не лезет, поэтому при апдейте ничего не сбрасывается.
Раньше настройки лежали в папке мода, и Steam затирал их при каждом обновлении.

**Сравнение FPS «с оптимизацией / без» теперь не врёт.**

Раньше через 12 секунд после `Ctrl+P` уже писалось «оптимизация вредит, −11 FPS».
Это были не цифры оптимизации — просто видеокарта только прогрелась, кэш шейдеров
ещё разогревался. Теперь сравнение ждёт 5 минут реальной игры в каждом режиме
(включено / выключено) и только потом показывает разницу. До этого пишет
«Замер: ещё 4 мин в ВКЛ + 2 мин в ВЫКЛ» — чтобы было понятно что мод работает,
а не сломан.

**«Сэкономлено CPU: 12 345 раз» вместо «Сэкономлено: 99%».**

Старый текст «99%» никто не понимал — % от чего? Теперь понятно: видеокарте
не пришлось делать N лишних расчётов, что и есть прирост FPS.

**HUD меняет язык вместе с игрой.**

Раньше если в настройках Bannerlord переключить язык — окно оптимизации
оставалось на старом языке, пока полностью не перезапустишь игру. Теперь язык
HUD обновляется автоматически, через пару секунд после смены.

**Больше не показывается CAUTION при каждом запуске.**

Лаунчер ругался: «Crash Doctor зависит от Bannerlord.Harmony v2.4.0.0, у тебя
v2.4.2.0 — ты уверен?». Это происходило при каждом обновлении Harmony,
потому что лаунчер сверяет версию очень строго (даже разный последний номер
триггерит предупреждение). Теперь привязка к Harmony перенесена в раздел,
который видят BLSE / Vortex, но не видит ванильный лаунчер. Никаких CAUTION,
порядок загрузки моду по-прежнему правильный.

**Новые правила распознавания крашей:**

- **Утечка видеокарты при долгой непрерывной игре.** Триггер — флаг
  `GPU Crash` в crash_tags + время игры больше 3 часов. На картах NVIDIA
  RTX 50-серии (Blackwell) и AMD RX 9000 (RDNA 4) драйвер постепенно течёт
  памятью; через 3+ часа начинаются падения с ошибкой `create_texture_array`.
  Совет: выходить из игры на рабочий стол каждые 2-3 часа (не в главное
  меню — именно полностью), обновить драйвер, мониторить расход видеопамяти
  в Диспетчере задач.
- Старое правило про `CreateTexture2D` расширено третьей причиной — той же
  утечкой на RTX 50-серии — с конкретными настройками для NVIDIA: панель
  управления → Bannerlord.exe → выключить DLSS Frame Generation, поставить
  «Prefer maximum performance», поставить Game Ready 580.x+.
- Движок правил научился сравнивать «больше чем» / «меньше чем» в значениях
  crash-логов и правильно читать дробные числа на русской Windows (где
  десятичная запятая, а не точка).

**Определение видеокарты на ноутбуках с двумя GPU.**

На игровых ноутбуках (Lenovo Legion, ASUS ROG, MSI, Razer) у дискретной
карты RTX 4060 Laptop / 4070 Laptop и подобных Windows показывает только
3 ГБ видеопамяти вместо реальных 8-12 ГБ. Это известный баг, не реальный
дефицит. Раньше Crash Doctor пугался и писал «мало VRAM, играть нельзя» —
теперь автоматически определяет ноут с гибридной графикой и не пугается.
На стационарных ПК поведение прежнее.

**Чистка вкладки «Настройка системы»:**

- **M1.5 (чистка временных файлов):** плашка больше не висит когда чистить
  нечего. Раньше она показывалась всегда когда в `%TEMP%` больше 1 ГБ —
  даже если все файлы свежие и ничего удалить нельзя. Теперь появляется
  только когда есть реально старый мусор (200+ МБ файлов старше 7 дней).
  Если нажал «Применить» а все старые файлы оказались заняты другими
  программами — плашка прячется до перезапуска игры.
- **M5.6 (Windows ждёт перезагрузку):** больше не появляется через 30 секунд
  после включения ПК. Crash Doctor смотрит сколько работает Windows — если
  меньше 10 минут, считает что это остатки прошлой загрузки, а не реальная
  отложенная перезагрузка. Также убран один из сигналов — он почти всегда
  «горит» на здоровой системе из-за рутинной работы Windows и постоянно
  давал ложное срабатывание.
- **M2.1 (очистка кэша шейдеров):** теперь умеет снимать «только чтение»
  с папок Steam Workshop. Steam иногда помечает скачанные файлы как
  read-only — при удалении выскакивало «отказано в доступе». Теперь если
  в логах Bannerlord видно много ошибок про шейдеры, Crash Doctor сам
  снимает эту метку перед удалением.

**Счётчик «Найдено N проблем» теперь показывает правду.**

Раньше под надписью «Найдено 3 проблемы» список бывал пустой — потому что
счётчик считал и скрытые карточки (которые юзер раньше пометил как
«Игнорировать»). Теперь число в надписи всегда совпадает с тем что видно
на экране.

**Зависшая плашка прогресса при нажатии «Применить» с внешним приложением.**

Жалоба: нажал «Применить» на карточке «закрыть программы, жрущие память» —
открывается Диспетчер задач, игра уходит на задний план, возвращаешься в
игру а плашка прогресса висит и не закрывается. Двойная защита:

- 6 модулей, чей «Применить» открывает Диспетчер задач / Очистку диска /
  браузер / Проводник, переведены на быстрый путь — плашка прогресса
  для них **вообще не показывается**: M1.2, M1.3, M3.2, M4.1, M5.7, M5.8, M5.9.
- Дополнительно: если плашка по какой-то причине застряла больше чем на
  30 секунд — она автоматически сама закрывается. Защита от любых будущих
  ошибок такого рода.

**Тесты:**

- Было 49, стало 57 — все проходят. Новый реальный краш с RTX 5070 Blackwell
  от 2026-05-08 как контрольный пример.
- Сборка чистая, мод задеплоен в папку Steam Workshop автоматом.

---

## 2026-05-08 — PerfTuneUp integration: Optimization section (internal build)

> Видимая версия мода остаётся `v1.4.0` навсегда (Bannerlord сравнивает её с save-файлом;
> на TOR любое изменение ломает игру). Эта запись описывает внутренний билд.

**Что нового — Optimization (PerfTuneUp):**

Новая секция «Оптимизация» во вкладке Tune-Up — opt-in performance throttle для карты
кампании. 5 механизмов, каждый независимо тогглируемый:
- Далёкие отряды: ранний выход почасового тика далёких невидимых отрядов (самый большой выигрыш FPS)
- Города и замки: распределение тиков (деревни не трогаем, продовольствие в порядке)
- ИИ далёких отрядов: ограничение тиков до 2 Hz
- Анимации далёких отрядов: прореживание визуальных кадров (по умолчанию OFF — риск флика)
- Внутриигровой HUD: статистика, hotkey **Ctrl+O**, EN/RU (auto-detect)

**Гейтинг секции:** показывается только при загруженном The Old Realms / EE1700, либо
если пользователь явно включил «Всегда показывать» в advanced. Если Bannerlord.Harmony
не установлен — секция показывает CTA с кнопкой открытия Workshop.

**Coexistence** со stand-alone Performance Optimizer (GodlyAnnihilator): детект через
Harmony id `performance.mod.bannerlord`, наши overlapping-патчи silently skip'аются.

**Архитектура / изоляция:** drop-in subsystem `CrashDoctor.PerfTuneUp` в
`CSharpMod/CrashDoctor/PerfTuneUp/`. Не зависит от остального CrashDoctor (только
`System.*`, `TaleWorlds.*`, `HarmonyLib`). Единственный мост — `IPerfHost`,
реализован в `CrashDoctor.Performance.PerfHostAdapter`.

**Зависимость:** `Bannerlord.Harmony` добавлен как `Optional="true"` в SubModule.xml.
Если у пользователя его нет, Crash Doctor грузится как раньше; PerfTuneUp молча отключается.

**Известное:** в Bannerlord debug-mode `Ctrl+O` забинден на «Score» (DebugHotKeyCategory).
В release-сборке не активен. Если конфликт — переназначить через `HudHotkeyKey` / `HudHotkeyModifier`
в `CrashDoctorSettings.xml`.

---

## v1.4.1 — Splash «двойной лоадер» предупреждение (2026-05-05)

После применения M2.1 / M2.2 / M3.3 (всё что чистит shader cache) первый
запуск Bannerlord показывает прогресс-бар на splash-экране **дважды**:
сначала загрузка модулей (норма, быстро), потом перекомпиляция шейдеров
(до часа). Игроки путают второй проход с зависанием и закрывают игру —
получают дальнейшие проблемы и негативный отзыв в Workshop.

Расширили post-Apply сообщения в трёх модулях явной строчкой про два
прохода: «Полоса прогресса заполнится ДВАЖДЫ. Долгий второй проход — это
шейдеры, не зависание. Не закрывай игру». Аналогично в Preview-нотах
M3.3 (engine_config). Никаких функциональных изменений.

---

## v1.4.0 — Tune-Up Phase 2: 11 new modules + bundle export + Ignore (2026-05-04)

**Новые модули ремедиации (10):** `M1.2 RAM check`, `M1.5 TEMP cleanup`, `M2.3 GPU info`,
`M2.4 Bad driver`, `M2.6 GPU vendor cache`, `M3.6 Dependency graph`, `M4.2 SHA-256
integrity`, `M5.2 VC++ Redistributable`, `M5.3 .NET Runtime`, `M5.6 Pending reboot`,
`M6.1 DirectX runtime`, `M6.2 HwSchMode`. Покрытие категорий 1–6 из ТЗ-2 закрыто
на ≈80%.

**Crash bundle export.** Кнопка Export теперь создаёт ZIP с полной папкой краша
(crash_tags + rgl_log + module_list + watchdog + minidump до 100 МБ) + наш
`diagnosis.txt` + двуязычный `READ_ME_FIRST.txt` с инструкцией куда отправить.
Имя файла говорит само за себя: `crashdoctor_unrecognised_<ts>.zip` если краш
не распознан, `crashdoctor_bundle_<ts>.zip` если да. Старый text-only export
оставался бесполезным когда диагнозов 0 — теперь поддержке отправляется всё
сырьё.

**Кнопка «Игнорировать» на Tune-Up карточках.** Persistent ignore-list в
`state/ignored_recommendations.json`, ключ — fingerprint детекта (severity +
summary + sorted evidence lines). При изменении состояния fingerprint меняется,
карточка возвращается на экран. Apply success стирает ignores для модуля.

**Парсер модулей выдерживает ранние крэши.** `CrashCollector.BuildModules` теперь
fallback'ится на парсинг `[Runtime][Arguments][..._MODULES_*A*B*..._MODULES_]` если
секция `Used Modules` отсутствует (Bannerlord не успевает её записать когда падает
на module init). Без fallback все правила с `module_list:` молча промахивались на
этих крэшах — отсюда «не распознан» на конфликтах вроде NavalDLC + TOR_Core.

**iGPU detection через rgl_log.** Новое правило `hw.igpu_actually_selected` матчит
строку `Selected graphics adapter: [N] <name>` — это authoritative источник, а не
порядок устройств в DxDiag. На машинах где DxDiag перечисляет iGPU как
`Display Devices 0`, но игра реально рендерится на дискретке, ложно-позитива
больше не будет.

**Whitelist карт где DxDiag врёт VRAM.** RTX 4070+/4080/4090, RTX 3080 Ti/3090,
RX 7700+/7800+/7900, RX 9070, Arc A770/B580 — все имеют ≥12 ГБ физически, но
DxDiag иногда репортит 3-4 ГБ из-за uint32 saturation в `Win32_VideoController.
AdapterRAM`. `SystemMatcher.MatchGpuField('vram_mb')` для `lt`/`lte` теперь
скипает эти карты (false-positive `hw.gpu_vram_likely_low` на реальном RTX 4080
Laptop был как раз об этом).

**Новые crash-rule'ы (8):**
- `tor.naval_dlc_conflict` — Naval DLC (War Sails) несовместим с TOR
- `assets.tpac_corrupted_workshop_mod` — `.tpac` пакет повреждён, evidence
  показывает Workshop ID мода
- `assets.tpac_oversized_pool` — pack > 256 МБ memory pool limit
- `assets.file_read_failed_verify_install` — generic IO fail
- `game.conversation_nre_executecontinue` — NRE в диалоге, типичный
  CharacterReload/BannerCraft конфликт
- `engine.team_index_invalid_burst` — combat-mod team registration storm
- `game.integrity_check_failed` — `Game Integrity is Achieved = False`
- `mods.heavy_stack_with_tor` — TOR + 5+ unofficial мода (через новый
  `module_list: { count_above: "5", excluding_official: "true" }` matcher)

**`UnhandledExceptionHandler`.** Регистрируется на `OnSubModuleLoad` ДО любых
наших операций. Слушает `AppDomain.UnhandledException` + `FirstChanceException`,
пишет managed stack в `crashdoctor.log` без swallow'инга. Throttle на 200
first-chance per session, фильтр `TaleWorlds.*` шумных catches.

**MSBuild target `SyncSubModuleXmlVersion`.** `<Version>` в csproj автоматически
синкается в `<Version value="vX.Y.Z" />` `SubModule.xml` через `BeforeTargets="Build"`.
Memory rule `feedback_version_bump_two_places` теперь автоматизирована.

**UI / UX фиксы.**
- Apply скрывается на informational модулях (M1.2 RAM, M2.3 GPU info) — нечего
  применять, кнопка убирает confusion
- UAC-required + URL-only модули запускаются sync, без BusyTracker overlay —
  раньше overlay застревал, потому что UAC dialog / браузер отнимал фокус и
  `OnFrameTick` приостанавливался
- Описание crash-карточки имеет фикс высоту, не наезжает на Fix steps
- M2.6 GPU vendor cache использует прямой `File.Delete` — VB.FileSystem ранее
  показывала Windows access-denied dialog'и на драйвер-locked файлах
- M1.2 RAM теперь читает WMI Win32_PhysicalMemory.Capacity первой — точное
  число DIMM-планок (16384 MB), не reduced-by-firmware-reservation значение

**Recovery doc bilingual split.** `docs/Recovery_If_Game_Wont_Start_EN.md` +
`_RU.md`. README.md ссылается на нужную версию по языку секции.

**Public README fix.** Битая ссылка `docs/Recovery_If_Game_Wont_Start.md` на
public github перезалита на `docs/RECOVERY.md` (commit `077d8bf..d01e4bd`).

---

## v1.3.12 — .tpac async I/O fault detection (2026-05-04)

Новое правило `assets.tpac_async_read_burst` — детектит классическую сигнатуру
ошибки асинхронного чтения сжатых ассетов Bannerlord. Когда движок не может
прочитать `.tpac` (битый файл / антивирус блокирует / I/O ошибка диска), он
спамит warning `Trying to make partial read on compressed asset data` десятки-
сотни раз перед managed-исключением CLR (`0xE0434352`). У реальных клиентов
с TOR + большими Workshop-модами этот паттерн встречается регулярно.

Триггер — ≥ 100 вхождений partial-read warning в логе. Severity: critical,
confidence: medium (мы знаем сигнатуру, но первопричин 4 — Verify integrity,
переподписка на Workshop, антивирус-исключение, `chkdsk`).

**Bonus fix в матчере:** `LogLineMatcher` теперь корректно понимает дедуп-
суффикс `(×N)`, который вешает `LogNormalizer.DedupConsecutive` на серии
одинаковых строк. Без этого `count_at_least` видел 1 hit вместо N для любого
паттерна с одинаковым текстом — потенциально шатало `gpu.shader_cache_corrupt`
и любые будущие burst-правила.

Также `Trying to make partial read on compressed asset` и `Unable to open
file for asynchronous read` добавлены в `LogNormalizer.SignificantTokens` —
теперь эти строки попадают в `SignificantLogLines`, не только в Last200
fallback.

---

## v1.3.11 — Translation completeness patch (2026-05-03)

Hotfix накопившихся переводов сразу после v1.3.10:

- **Опечатка в RU recommendations**: в `m33_engine_config.yaml:50` была неловкая
  смесь латиницы и кириллицы — `resуверный backup`. Должно быть `резервная копия`.
  Исправлено.
- **17 английских error messages теперь имеют RU-пары.** Везде где код ловил
  `Exception ex` и возвращал `ApplyResult.FailLocalized(ex.Message, "Внутренняя
  ошибка: " + ex.Message)`, английская сторона показывала голый `ex.Message`
  без префикса, а русская — с «Внутренняя ошибка:». Симметризовано на
  `"Internal error: " + ex.Message`.
- **13 orphan `ApplyResult.Fail()` в M14 / M21 / M33 / M35 / M37** заменены на
  `ApplyResult.FailLocalized(en, ru)`. Раньше:
  - M14 / M21 / M37 Rollback (`"is not reversible from Crash Doctor"`)
  - M33 Apply / Rollback validation messages
  - M35 Apply / Rollback validation messages
  Теперь у каждого failure-message есть русская пара.

Никаких функциональных изменений — только переводы. Билд / тесты без регрессий.

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
