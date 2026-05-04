# Crash Doctor — Bannerlord Crash Analyzer & Tune-Up

A standalone diagnostic mod for **Mount & Blade II: Bannerlord**. Reads your crash
dumps, explains in plain English what went wrong, and applies common Windows /
driver / engine fixes in one click.

Designed for **any modded setup** — vanilla, TOR (The Old Realms), Diplomacy,
Calradia Expanded, RBM, Banner Kings, anything. No internet, no telemetry, no
Harmony patches, no dependencies.

> **Steam Workshop:** [3717685432](https://steamcommunity.com/sharedfiles/filedetails/?id=3717685432)
> **Compatibility:** Bannerlord v1.2.x – v1.3.15 (Steam build only — Game Pass /
> MS Store not supported).

---

## What it does

Three tabs from the Bannerlord main menu:

### 🔬 Crash diagnosis
Scans `C:\ProgramData\Mount and Blade II Bannerlord\crashes\` and the BUTR HTML
crash reports if you have BLSE/ButterLib. Matches every crash against ~60 YAML
rules covering:

- **GPU / DirectX:** integrated-GPU misroute, DXGI device removed/hung, shader
  cache corruption, shader-compile OOM (TOR `pbr_metallic.rs` / `faceshader_high.rs`),
  D3D11 texture-array E_INVALIDARG (RX 9070 XT + heavy mod loads),
  CreateShaderResourceView fail (TOR tessellation overflow), HLSL X3004 `_TBN`.
- **Native runtime:** AccessViolationException in TaleWorlds.MountAndBlade
  (1.2.10/1.2.11 regression), STATUS_STACK_OVERFLOW recursive AI loop,
  LordsHall DivByZero.
- **Save / late-game:** WarPartyComponent NRE on save load (Null Hero Fix
  Nexus 4728), pregnancy crash on rare-culture companion (Baby Of Rare Culture
  Nexus 9487), MBObjectManager.GetObject NRE.
- **TOR-specific:** Assimilation IndexOutOfRange (Hunger Woods / wraith bind —
  Nexus 8872), TOR + Improved Garrisons PartySize NRE (Nexus 8884), TOR +
  Distinguished Service InvalidCast (Nexus 8874), Winds of Magic AV on mass
  vampire siege casts, CareerPerkMissionBehavior, GraveyardNightWatch,
  TORagentApplyDamageModel.
- **BUTR stack:** stray `0Harmony.dll` in main bin, BLSE 1.6.4 locale
  FormatException (downgrade to 1.6.3), corrupt ButterLib settings JSON,
  MCM PrefabInjector ArgumentNullException.
- **Hardware:** RAM/VRAM below thresholds (with DXDIAG-bug awareness for RDNA3/4
  cards reporting 3072 MB on 16 GB GPUs), GPU driver 18+ months old, OS too old,
  page file exhausted.
- **Modules:** could-not-load DLL, BadImageFormatException, dependency mismatch,
  TypeLoadException, MissingMethodException, Harmony PatchException.

Each diagnosis ships a title, plain-language explanation, evidence link, and a
prioritized list of fix steps (in-game settings → game config → driver → Windows
→ BIOS — never sysadmin-grade jargon).

### 🛠 System tune-up
**16 semi-automatic remediation modules**. Each card: Detect → Preview (diff)
→ Apply → Rollback. Registry writes are backed up as `.reg` files in your user
Documents folder before being touched. Reversible items are journaled.

| Id | What it does | UAC | Reboot | Reversible |
|----|-----------|-----|--------|------------|
| **M1.1** | Page file auto-managed → 40/60 GB on the drive of your choice | yes | yes | yes |
| **M1.3** | Disk space audit + one-click `cleanmgr` launcher | no | no | — |
| **M1.4** | Old crash-dump cleanup (junction-aware so deletion is exact) | no | no | — |
| **M2.1** | Shader cache clear (TOR-aware popup; only fires when crash markers exist) | no | no | — |
| **M2.2** | Auto-detect: graphics settings changed in-game → clear cache before next launch | no | yes | — |
| **M2.5** | TdrDelay = 60 s in HKLM (most useful tweak for shader-OOM crashes in TOR) | yes | yes | yes |
| **M3.2** | Detection: Documents on OneDrive (incl. pinned mode that breaks save reads) | no | no | — |
| **M3.3** | `engine_config.txt` → terrain_quality fix; auto-clears shader cache | no | yes | yes |
| **M3.7** | Unblock DLLs (NTFS Zone.Identifier ADS) for every installed mod | no | no | — |
| **M4.1** | BLSE / ButterLib / Harmony / MCM versions display (read-only) | no | no | — |
| **M5.4** | Disable Fullscreen Optimizations for Bannerlord.exe | no | no | yes |
| **M5.5** | Game DVR / Xbox Game Bar full off (HKLM + HKCU) | yes | no | yes |
| **M5.7** | Background apps audit — RTSS, MSI Afterburner, Discord, OBS, Nahimic, SignalRGB, iCUE | no | no | — |
| **M5.8** | Heavy VRAM apps scan — VR runtimes, AI tools, video editors, browsers, OBS | no | no | — |
| **M5.9** | Late-game campaign health — day, hero count, snowball, war cascade (live `Campaign.Current`) | no | no | — |
| **M3.5** | Recommended load order display | no | no | — |

### 📜 History
Every Apply / Rollback is journaled with timestamp and result. Rolled-back
entries stay visible with a green "rolled back HH:MM" badge. Reversible entries
are preserved when the history is cleared so `.reg` backups don't get orphaned.

---

## Installation

1. Subscribe on the [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3717685432).
2. Bannerlord launcher → enable **Crash Doctor** → Play.
3. Main menu → **Crash Doctor** button.

**No dependencies.** Does not require Harmony, ButterLib, BLSE, or MCM.
Designed to run even when other mods are broken.

---

## After the next crash

When the game asks whether to create a dump — click **Yes**. Wait for the log
window, close it, restart the game, open Crash Doctor — your crash will be
analyzed. Click **No** and the mod has nothing to read.

If no rule matches your crash, click **Export** in the Crashes tab and send the
`.txt` to the Telegram channel below — we add a rule and your next same-kind
crash gets recognized for everyone.

---

## If the game won't launch

After lowering Texture / Shader / Shadow Quality (either via Crash Doctor's
advice or directly in Options → Graphics) the game can crash on the imperial-
soldier splash. The shader cache was built against the old settings; the new
settings need a fresh build. Crash Doctor's M2.2 module catches this
automatically when you next open the menu, but if the game won't even start —
follow [`docs/RECOVERY.md`](docs/RECOVERY.md):

1. Delete `Documents\Mount and Blade II Bannerlord\Configs\engine_config.txt`
2. Delete `C:\ProgramData\Mount and Blade II Bannerlord\Shaders\` (entire folder)
3. Delete `<Bannerlord install>\Shaders\D3D11\compressed_shaders_cache.sack`
   and any `<install>\Modules\<ModName>\Shaders\D3D11\*.sack`
4. Steam → Bannerlord → Properties → Installed Files → Verify integrity
5. Reboot the PC
6. Launch the game → Main Menu → **Build Shader Cache** → wait 20–60 minutes

NVIDIA fallback: GeForce Experience / NVIDIA app → Graphics → Bannerlord →
Optimize. AMD: Adrenalin → Gaming → Bannerlord → Reset to Defaults.

---

## How crash data is preserved

On first start the mod replaces the engine's crashes folder with a directory
junction into our cache. Bannerlord wipes only the junction at next launch —
files survive. No admin rights, no helper exe.

State (history JSON, `.reg` backups, `engine_config_snapshot.txt`) lives in
`<Documents>\Mount and Blade II Bannerlord\CrashDoctor\state\` — Steam re-validation
of the Workshop folder would otherwise wipe it.

---

## Privacy

- No internet calls. The mod never connects to anything.
- No telemetry.
- No data collection.
- Crash data stays on your machine. You explicitly **Export** it (a `.txt` file)
  to send for analysis — nothing leaves automatically.
- Registry writes (M1.1 Pagefile, M2.5 TdrDelay, M5.5 GameDVR) are backed up to
  `.reg` files in your Documents folder before being touched. Reversible from
  the History tab.
- `.pdb` debug symbols are stripped at build time and at runtime (`PurgeOwnPdbFile`)
  because they leak the dev-machine username via embedded paths.

---

## Reporting unrecognized crashes

If Crash Doctor doesn't recognize a crash:

1. Open the Crashes tab → pick the crash.
2. Click **Export**.
3. Send the resulting `.txt` to the Telegram channel:
   [https://t.me/CodeRickTg](https://t.me/CodeRickTg)

We add a YAML rule to the catalog, push an update, and your next same-kind
crash gets a diagnosis.

---

## License

MIT. See [`LICENSE`](LICENSE).

The catalog of crash rules in `Mod/CrashDoctor/ModuleData/rules/*.yaml` is
freely usable in derivative diagnostic tools — please credit
[`docs/crash_catalog_2026-05-02.txt`](docs/crash_catalog_2026-05-02.txt) as the
source if you republish.

---

## Build from source

```
dotnet build CSharpMod/CrashDoctor/CrashDoctor.csproj -c Release
```

The `OutputPath` writes the DLL directly into your Steam Workshop folder
(`C:\Program Files (x86)\Steam\steamapps\workshop\content\261550\3717685432\bin\Win64_Shipping_Client\`).
`AfterTargets="Build"` deploys SubModule.xml, GUI, and ModuleData files. A
StripPdbFromWorkshop target removes `.pdb` / `.bat` / `.log` /
`PIRACY_LIMITATIONS.md` from the deployed folder. XSD validation of
SubModule.xml runs against vendored BUTR schemas.

```
dotnet test tests/CrashDoctor.Tests/CrashDoctor.Tests.csproj
```

34 tests covering YAML rule parsing, crash collector parsing, BUTR HTML
crash-report parsing, rule engine matching against fixture crashes, and a
pre-flight gate that loads every YAML in `ModuleData/` through YamlDotNet to
catch syntax bugs before they hit production.

---

# Crash Doctor — Анализатор крашей и Tune-Up для Bannerlord

Standalone-мод диагностики для **Mount & Blade II: Bannerlord**. Читает дампы
крашей и человеческим языком объясняет что чинить, плюс в один клик применяет
типовые твики Windows / драйверов / движка.

Подходит для **любой модной сборки** — ванила, TOR (The Old Realms), Diplomacy,
Calradia Expanded, RBM, Banner Kings и т.д. Без интернета, без телеметрии,
без Harmony-патчей, без зависимостей.

> **Steam Workshop:** [3717685432](https://steamcommunity.com/sharedfiles/filedetails/?id=3717685432)
> **Совместимость:** Bannerlord v1.2.x – v1.3.15 (только Steam-версия).

## Что делает

Три вкладки в главном меню:

- **Диагностика крашей** — ~60 YAML-правил под GPU/DirectX, native runtime, save
  / late-game, TOR, BUTR-стек, hardware, модули.
- **Настройка системы (Tune-Up)** — 16 модулей полу-автоматической ремедиации.
  Каждый: Detect → Preview → Apply → Rollback. Реестровые записи сохраняются
  в `.reg`-бэкапы в Documents до изменения.
- **Журнал** — каждое Apply/Rollback с таймстампом и откатом.

## Установка

1. Подпишись в [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3717685432).
2. Лаунчер Bannerlord → включи **Crash Doctor** → Play.
3. Главное меню → кнопка **Crash Doctor**.

## Если игра не запускается

После понижения Texture/Shader Quality (через Crash Doctor или вручную в
Options → Graphics) игра может упасть на splash-screen — кэш шейдеров под
старые настройки. M2.2 ловит это автоматически, но если игра уже не
запускается — см. [`docs/RECOVERY.md`](docs/RECOVERY.md).

## Сообщить о нераспознанном краше

Crashes tab → Export → отправь `.txt` в Telegram-канал
[https://t.me/CodeRickTg](https://t.me/CodeRickTg). Добавим правило в каталог и
выпустим апдейт.

## Лицензия

MIT. См. [`LICENSE`](LICENSE).
