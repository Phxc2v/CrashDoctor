# Crash Doctor — Bannerlord Crash Analyzer & Tune-Up

A standalone diagnostic mod for **Mount & Blade II: Bannerlord**. Reads your crash
dumps, explains in plain English what went wrong, and applies common Windows /
driver / engine fixes in one click.

Designed for **any modded setup** — vanilla, TOR (The Old Realms), Diplomacy,
Calradia Expanded, RBM, Banner Kings, anything. No internet,
no dependencies.

> **Steam Workshop:** [3717685432](https://steamcommunity.com/sharedfiles/filedetails/?id=3717685432)
> **Compatibility:** Bannerlord **v1.2.x – v1.4.x** — one install carries a
> version-dispatching loader that detects your game version at startup and loads the
> matching build, so the same subscription works on 1.2.x, 1.3.15 and 1.4.5. Works on
> Steam **and** non-Steam / manual installs (Game Pass / MS Store still unsupported —
> different game binaries). The Bannerlord.Harmony module is needed for the live
> protections; the core crash analysis loads and works even with it off.

---

## What it does

Eight tabs from the Bannerlord main menu — Crashes, System Tune-Up, History,
Saves, Mods, **Crash Fixes**, **Prevented**, Settings. (A prior "Optimization" tab was removed
2026-05-10 after late-game testing showed Bannerlord's architectural ceiling
makes throttle-style FPS optimization non-viable.)

The **Crash Fixes** tab lists every runtime anti-crash guard the mod installs —
each with an on/off checkbox, a plain-language description and a live status
badge (Active / Off / Not needed here — required mod not loaded / Install error). All
fixes are on by default; you can disable any single one if it misbehaves on
your setup, without touching the rest. Two buttons — **Enable all** / **Disable all** —
flip every applicable fix at once (fixes for mods you don't have are left untouched,
shown as "Not needed here"). Your choice is saved immediately. Fixes are **grouped
into labeled sections** — Battle & missions, Campaign map, Saving & loading,
Interface, and The Old Realms (TOR) — so you can see at a glance what each group
is for; the **TOR section is hidden entirely when The Old Realms isn't installed**
(and the "Active: X of Y" counter ignores those hidden fixes).

The **Prevented** tab is the journal of crashes the mod actually stopped for you. Every
time a guard fires you get a one-line in-game toast, and that toast is gone in seconds;
the journal keeps it. One row per distinct problem, with a repeat counter, the real and
in-game date, the mod that was blamed (when it can be pinned down), and — the useful part —
**the game data involved**: the troop and its missing culture, the party, hero, clan,
settlement, army, formation, save-metadata key. The object id usually tells you which mod
the broken data came from without opening `crashdoctor.log`. The journal is cumulative and
survives restarts (it lives in your Documents, not in the mod folder, so mod updates don't
wipe it). **Copy report** puts the whole thing on the clipboard, ready to hand to the author
of the offending mod; **Clear journal** wipes it. The same list is available **without leaving
your campaign** — press `Ctrl+Alt+D` in game.

The **Mods** tab lists installed mods in the **same order as your launcher** (load
order), with conflict / missing-dependency / load-order badges; problem mods are
highlighted but no longer reshuffle the list. Each active mod is also checked for
**compatibility with the game build you're running** — a mod that references game
types absent from this Bannerlord version was built for a different version and is
flagged red "Incompatible with this game build" before it can crash. Only the code
actually loaded for the current version is checked (mods shipping a separate build
per version aren't falsely flagged), and multi-version framework libraries (Harmony,
ButterLib, MCM, UIExtenderEx, BLSE) are excluded.

Every active mod is also checked for whether it is **usable as installed**: every DLL
its `SubModule.xml` declares (both `<DLLName>` and `<Assemblies>`) must actually be
on disk, and every library those DLLs reference must be installed *and* switched on.
Two things this catches that nothing else does — a mod the engine skipped because its
DLL wasn't there (it is not running at all, whatever the launcher shows: the player's
"this mod does nothing"), and a missing library that will throw the moment the mod
reaches the code needing it. Reported by name: *"ROT-Core.dll needs
'Bannerlord.ButterLib' — not installed (comes with ButterLib)"*. A library that is
installed but merely un-ticked is called out as such, since the fix is one checkbox.
Read as metadata only (Mono.Cecil, in-memory) — no mod code runs, no file is locked.
Findings also go into `crashdoctor.log` at every launch and into the `report.txt` of
any crash, under **SETUP PROBLEM**. Missing libraries belonging to ordinary gameplay
mods are reported one notch softer, because .NET resolves assemblies lazily and an
optional integration never triggers the load.

What this deliberately does *not* try to catch: a mod whose DLL cannot be loaded at
all (blocked by Windows, corrupt, 32-bit, built for .NET Core) or whose missing
library is used in a type signature. The engine loads every module's assemblies in
one pass and only then runs any mod's code, so those kill the game before Crash
Doctor — or any other mod — exists. Catching them needs a check that runs before the
game does.

Colours: red — cannot load / incompatible build, yellow — Harmony conflict / load
order, orange — missing dependency, grey — disabled.

### 🔬 Crash diagnosis
Scans `C:\ProgramData\Mount and Blade II Bannerlord\crashes\` and the BUTR HTML
crash reports if you have BLSE/ButterLib. Matches every crash against **143 YAML
rules** covering:

- **GPU / DirectX:** integrated-GPU misroute, DXGI device removed/hung, shader
  cache corruption, shader-compile OOM (TOR `pbr_metallic.rs` / `faceshader_high.rs`),
  D3D11 texture-array E_INVALIDARG (RX 9070 XT + heavy mod loads),
  CreateShaderResourceView fail (TOR tessellation overflow), HLSL X3004 `_TBN`,
  iGPU detected as the rendering adapter (read from rgl_log Selected adapter,
  not DxDiag — no false positives on laptops where DxDiag listed iGPU first).
- **Native runtime:** AccessViolationException in TaleWorlds.MountAndBlade
  (1.2.10/1.2.11 regression), STATUS_STACK_OVERFLOW recursive AI loop,
  LordsHall DivByZero.
- **Asset corruption:** `.tpac` async-read failures with the Workshop ID of the
  broken mod surfaced in evidence; oversized .tpac > pool limit; generic
  `File read failed! Please try to verify your installation`.
- **Save / late-game:** WarPartyComponent NRE on save load (Null Hero Fix
  Nexus 4728), pregnancy crash on rare-culture companion (Baby Of Rare Culture
  Nexus 9487), MBObjectManager.GetObject NRE.
- **Mission / engine:** conversation NRE in `MissionConversationVM.ExecuteContinue`
  (typical CharacterReload / BannerCraft conflict), team-index storm from
  combat-mod registration bugs (RBM, PartialParry, custom factions), Bannerlord's
  own `Game Integrity is Achieved = False` integrity flag.
- **TOR-specific:** Assimilation IndexOutOfRange (Hunger Woods / wraith bind —
  Nexus 8872), TOR + Improved Garrisons PartySize NRE (Nexus 8884), TOR +
  Distinguished Service InvalidCast (Nexus 8874), Winds of Magic AV on mass
  vampire siege casts, CareerPerkMissionBehavior, GraveyardNightWatch,
  TORagentApplyDamageModel, **Naval DLC ("War Sails") + TOR conflict**.
- **Mod stack:** TOR + 5 or more unofficial modules (count-based — works
  regardless of which BUTR libs are loaded).
- **BUTR stack:** stray `0Harmony.dll` in main bin, BLSE 1.6.4 locale
  FormatException (downgrade to 1.6.3), corrupt ButterLib settings JSON,
  MCM PrefabInjector ArgumentNullException.
- **Hardware:** RAM/VRAM below thresholds (with a whitelist for cards DxDiag
  misreports — RTX 4070+/4080/4090, RX 7700+/7900, RX 9070, Arc A770/B580 —
  no false positives), GPU driver 18+ months old, OS too old, page file
  exhausted.
- **Modules:** could-not-load DLL, BadImageFormatException, dependency mismatch,
  TypeLoadException, MissingMethodException, Harmony PatchException, **missing
  hard dependencies detected before launch via SubModule.xml dependency-graph
  audit**.

Each diagnosis ships a title, plain-language explanation, evidence link, and a
prioritized list of fix steps (in-game settings → game config → driver → Windows
→ BIOS — never sysadmin-grade jargon).

The module-list parser falls back to parsing `[Runtime][Arguments]` when the
`Used Modules` section is missing in `crash_tags.txt` — Bannerlord doesn't
write that section when it crashes during module init, exactly when conflict
detection matters most. Without the fallback every `module_list:`-based rule
silently missed on these early-stage crashes.

### 🛠 System tune-up
**28 semi-automatic remediation modules**. Each card: Detect → Preview (diff)
→ Apply / Ignore / Rollback. Registry writes are backed up as `.reg` files in
your user Documents folder before being touched. Reversible items are journaled.

The **Ignore** button on every card is persistent — it records a fingerprint
of the detection (severity + summary + sorted evidence) and hides the card
until that fingerprint changes. Successful Apply wipes ignores for that
module so a new state surfaces on its merits.

| Id | What it does | UAC | Reboot | Reversible |
|----|-----------|-----|--------|------------|
| **M1.1** | Page file auto-managed → 40/60 GB on the drive of your choice | yes | yes | yes |
| **M1.2** | RAM check (DIMM-accurate via WMI; 16 GB hard floor for TOR) | no | no | — |
| **M1.3** | Disk space audit + one-click `cleanmgr` launcher | no | no | — |
| **M1.4** | Old crash-dump cleanup (junction-aware so deletion is exact) | no | no | — |
| **M1.5** | `%TEMP%` cleanup — silent per-file, files older than 7 days | no | no | — |
| **M2.1** | Bannerlord shader cache clear (TOR-aware popup; only fires when crash markers exist) | no | no | — |
| **M2.2** | Auto-detect: graphics settings changed in-game → clear cache before next launch | no | yes | — |
| **M2.3** | GPU info — accurate VRAM via registry `HardwareInformation.qwMemorySize` (no DxDiag uint32 saturation) | no | no | — |
| **M2.4** | Bad GPU driver detector — community manifest of known-bad versions | no | no | — |
| **M2.5** | TdrDelay = 60 s in HKLM (most useful tweak for shader-OOM crashes in TOR) | yes | yes | yes |
| **M2.6** | GPU vendor cache cleanup — NVIDIA DXCache/GLCache, AMD DxCache/DXC, Intel ShaderCache | no | no | — |
| **M2.9** | Repair broken Windows TEMP path — repoints TMP/TEMP back to the Windows default when they point at a renamed/removed drive (universal, not TOR-only) | no | yes | yes |
| **M3.2** | Detection: Documents on OneDrive (incl. pinned mode that breaks save reads) | no | no | — |
| **M3.3** | `engine_config.txt` → terrain_quality fix; auto-clears shader cache | no | yes | yes |
| **M3.6** | Mod-dependency audit — missing deps / version mismatches / duplicates / conflicts, reported in plain "what's wrong → what to do" lines | no | no | — |
| **M3.7** | Unblock DLLs (NTFS Zone.Identifier ADS) for every installed mod | no | no | — |
| **M3.8** | Clear FDS_ShaderCache's XML skip-list (`fds_xml_blacklist.txt`) — that mod blacklists any game XML that errors once and then skips loading it, silently dropping data and crashing other mods on load | no | no | — |
| **M4.1** | BLSE / ButterLib / Harmony / MCM versions display (read-only) | no | no | — |
| **M4.2** | SHA-256 integrity check (manifest-driven, hidden until populated) | no | no | — |
| **M5.2** | VC++ 2015-2022 x64 Redistributable check | no | no | — |
| **M5.3** | .NET Framework 4.7.2+ check (registry NDP\v4\Full Release DWORD) | no | no | — |
| **M5.4** | Disable Fullscreen Optimizations for Bannerlord.exe | no | no | yes |
| **M5.5** | Game DVR / Xbox Game Bar full off (HKLM + HKCU) | yes | no | yes |
| **M5.6** | Pending-reboot detection (CBS RebootPending, WindowsUpdate RebootRequired, PFRO) | no | yes | — |
| **M5.7** | Background apps audit — RTSS, MSI Afterburner, Discord, OBS, Nahimic, SignalRGB, iCUE | no | no | — |
| **M5.8** | Heavy VRAM apps scan — VR runtimes, AI tools, video editors, browsers, OBS | no | no | — |
| **M5.9** | Late-game campaign health — day, hero count, snowball, war cascade (live `Campaign.Current`) | no | no | — |
| **M6.1** | DirectX 11 runtime + feature level probe (D3D11CreateDevice) | no | no | — |
| **M6.2** | HwSchMode (Hardware-Accelerated GPU Scheduling) state — TOR-risky combo flag | no | yes | — |

Note: the shader / pagefile / GPU-timeout cards — **M1.1** (pagefile), **M2.1**
(shader cache), **M2.2** (graphics-change → rebuild), **M2.5** (TdrDelay), **M2.7**
(`%TEMP%` relocation) and **M3.3** (`engine_config.txt` TOR-incompatible values) —
only appear when **The Old Realms** is installed.
They exist for TOR's huge custom shader set (multi-GB compiles, large pagefile,
raised GPU timeout); vanilla and other modpacks don't need them, so they stay
hidden there instead of nagging. The manual **"Clean shader cache"** button is the
one exception — it stays available to everyone (it's still useful after a GPU
driver change or DX-preset switch).

Note: Crash Doctor does **not** touch Windows Defender or antivirus exclusions
in any way — it never adds, removes, or reads AV exclusion lists. Antivirus
configuration is left entirely to the user.

`M3.5` recommended load order is implemented but currently **not registered** —
it ships in the source tree but stays hidden in the UI until the launcher
rewrite handling is robust enough.

### 📜 History
Every Apply / Rollback is journaled with timestamp and result. Rolled-back
entries stay visible with a green "rolled back HH:MM" badge. Reversible entries
are preserved when the history is cleared so `.reg` backups don't get orphaned.

### 💾 Saves
Reads the JSON header of every `.sav` in your `Game Saves` folder and diffs
its mod list against your current `LauncherData.xml` — without loading the
campaign. Each card shows day, hero, gold, party size, and surfaces:

- mods recorded in the save but not selected (one-click enable in launcher),
- mods recorded but not installed at all (clipboard-copy of IDs),
- mods selected now but absent from the save (one-click disable),
- version drift between save and active install,
- size bloat (≥50 MB → suggest **Save Cleaner** Nexus #7763, ≥100 MB severe),
- Bannerlord major-version mismatch (1.2.x save in 1.3.x install),
- Iron Man flag (always recommend backup-before-load),
- known save-breaking-when-removed mods (PlayerSettlement, BannerKings,
  TOR_Core, Dramalord, CalradianClans, Diplomacy, ImprovedGarrisons —
  surfaced with the URL where to re-install),
- known not-safe-to-add-mid-campaign mods (CalradianClans, BannerKings),
- late-game heuristic — day ≥ 700 + size ≥ 25 MB warns about orphan-clan
  KingdomDecision crashes that hit long campaigns.

Verdict severity is proportionate, not panic: a save only turns **red** ("load
will very likely crash") when a mod that actually persists campaign data is
missing (the known save-breaking list above). Every other difference — a missing
cosmetic/utility/translation mod, an extra mod, a version drift — is an **amber**
warning ("the game will warn about missing modules, but the save should load —
back it up first"), because removing those doesn't crash the load.

Per-save action buttons: enable missing mods, disable extra mods, copy IDs to
clipboard, open Save System Fix on Nexus (#1925), open Save Cleaner on Nexus
(#7763), `.bak` backup, show in Explorer, send to Recycle Bin. Fully offline
— no Bannerlord runtime touched, so it works in the main menu *before* the
crashing save is loaded.

### 🛡 Runtime crash prevention

A layer of generic safety nets that intercept the most common crashes — many
caused by **other mods leaving "dangling" units in party rosters or issue
sent-troops lists** (typical pattern: another mod creates a temporary hero,
drops it into a foreign party, then deletes the hero without scrubbing the
roster — the next AI hourly tick or daily issue-completion crashes on the null
reference), plus save-load, end-of-battle, inventory and prisoner-sell crashes.
Each catch shows an in-game toast (EN / RU / 简体中文 / 繁體中文 / Türkçe based on
game locale, rate-limited per category) so the player sees Crash Doctor actively
saved them from a crash. When the crash was thrown by a mod's own code, the toast
also names it — *"Possibly caused by mod: X v1.2"* — read from the stack frame the
exception came from and that module's `SubModule.xml`. When the throw happened in
the game's own code the line is omitted entirely: a mod further down the call path
is never named, because it may have simply forwarded the call.

**Every one of these is listed on the Crash Fixes tab** with its own on/off
checkbox and a live status badge — turn off just the one that misbehaves on
your setup. All on by default; off-choices persist (diff-only) across restarts.
A shared `PatchCatalog` is the single source of truth feeding both the installer
(`SafetyNetCoordinator`) and the UI, so the list, install state and toggles can
never drift.

**On game 1.2 a few of them stay dormant, by design.** One subscription serves 1.2.x, 1.3.15 and
1.4.x, and some of the crashes below simply cannot happen on 1.2 — the method, the type or the whole
feature does not exist there yet, so the guard resolves nothing and reports **Skipped** rather than
Failed. Nothing is broken and nothing is missing: there is no crash to catch. On 1.2 that applies to
`ClanLeftKingdomNullOldKingdom`, `DefaultTroopTraitsNRE`, `SimulatedBattleHitNRE`,
`ArmyGatheringSettlementNRE`, `ColumnFormationSpawn`, `IntersectRayPolygonNull`,
`MissionLocationLogicRemoveNRE`, `ThumbnailReleaseCacheNRE`, `LootItemChancesNRE`,
`HeroClearChangedPerksNRE`, `ClanNavalCapabilityNullTemplate`, `ChangePartyLeaderNullParty` (there
the base method is an empty stub, so a guard could only ever report a crash that never happened) and
`SelfSaveModuleCheckSuppressor` — the last one is a real gap rather than a non-issue: 1.2 players see
the launcher's "modules changed" note after a Crash Doctor update.

| Fix | What it does |
|---|---|
| **`WageModelNRESafetyPatch`** (TOR) | Three guards on `TOR_Core.Models.TORPartyWageModel` (`CalculateCharacterWageCache`, `GetCharacterWage`, `GetTotalWage`). Returns wage = 0 instead of crashing on a null-culture character. |
| **`PartyWageNRESafetyPatch`** | The same crash in the **vanilla** `DefaultPartyWageModel`, which the TOR guard above never covered. `GetTotalWage` walks a party's roster on the daily clan-finance tick (`ClanVariablesCampaignBehavior.DailyTickClan` → `DefaultClanFinanceModel.CalculateClanGoldChange` → `MobileParty.TotalWage`) and dereferences four things unguarded: a troop's `Culture`, the troop object itself, `CurrentSettlement.Owner.Culture` in the garrison branch (`Owner` is `OwnerClan.Leader` — null for a leaderless clan that still holds fiefs) and `LeaderHero.Clan.Kingdom`. Any of them empty and the save gets stuck at the day boundary. Finalizer returns wage = 0 for that one party (no morale penalty either — vanilla's `paymentAmount < wage` guard is false at 0) plus a prefix null-guard on `GetCharacterWage`; the log records the exact troop / party / settlement it found. **Universal**, not mod-specific; no-op on healthy saves. |
| **`CraftingTownOrderNRESafetyPatch`** | Prefix on `CraftingCampaignBehavior.CreateTownOrder`, which supplies a `return` the base game forgot: the method checks `orderOwner.CurrentSettlement == null \|\| !IsTown`, writes a `Debug.Print` about it, then dereferences `orderOwner.CurrentSettlement.Town` on the very next line anyway. The owner is a random pick from the settlement's `HeroesWithoutParty` plus the leaders of the parties standing there, so the trigger is a hero the town still lists while the hero's own `CurrentSettlement` is null — a desync left by a mod that moves heroes around. Skipping costs one smithing order that day; all three callers reserve the slot beforehand, so the next daily tick fills it. **Universal**, not mod-specific. |
| **`MapEventEndRosterSafetyPatch`** | Finalizer on `MapEventSide.HandleMapEventEndForPartyInternal`, where the game mutates a list while lazily enumerating it: `LinQuick.WhereQ` captures `source.Count` once before the first `yield` and then indexes the live list, `TroopRoster.GetTroopRoster()` returns the live internal list rather than a copy, and the `foreach` body calls `KillCharacterAction.ApplyByBattle`, which removes the killed hero from that same roster — so the next indexed read runs off the end with an `ArgumentOutOfRangeException`. Instead of swallowing (which would skip the party-destruction check, `RemoveZeroCounts` and the visual refresh that follow the loop) the finalizer **re-runs the original**, bounded to 4 attempts: heroes killed on the previous pass no longer satisfy `IsAlive`, so the walk converges and the game's own tail logic runs unchanged. Retry is gated on the exact signature (`ArgumentOutOfRangeException` raised through `LinQuick`); any other failure is swallowed without a re-run. **Universal**; shows up mostly with mods that make heroes truly die in battle. |
| **`FoodConsumptionNRESafetyPatch`** (TOR) | Finalizer on `TORMobilePartyFoodConsumptionModel.CalculateDailyFoodConsumptionf`. Same dangling-character source, on the food-consumption tick. |
| **`AiHourlyTickNRESafetyPatch`** | Reflection-based finalizer on every `AiHourlyTick` in `TaleWorlds.CampaignSystem.CampaignBehaviors.AiBehaviors` (`AiPatrolling`, `AiVisitSettlement`, `AiMilitia`, …). The offending party skips that tick; the game continues. |
| **`IssueBaseNRESafetyPatch`** | Prefix sanitizer + finalizer on `IssueBase.AlternativeSolutionEndWithSuccess`. Scrubs `AlternativeSolutionSentTroops` so the inner `FindAll` lambda never sees a null `Character`; if something still throws, the finalizer swallows it and the caller finishes the issue normally (`TryToMakeTroopsReturn` + `IssueFinalized` sit after the throw site), so only the rest of that one payout is lost instead of the whole campaign tick. |
| **`VictoryCheerAVSafetyPatch`** | Guard on `AgentVictoryLogic.ChooseWeaponToCheerWithCheerAndUpdateTimer` — validates the agent *before* the cheer, so a freed/dangling agent (common with combat overhauls like RBM or summon/raise-dead mods) simply skips it; managed exceptions from corrupt equipment are caught via a reverse-patch wrapper. The end-of-battle AccessViolation is prevented up front — an AV is uncatchable on the game's .NET runtime. |
| **`BehaviorFlankAiWeightSafetyPatch`** | Finalizer on vanilla `BehaviorFlank.GetAiWeight` — returns 0 priority instead of an NRE when the targeted formation vanishes mid-calculation. |
| **`InventoryUseItemSafetyPatch`** (TOR) | Transpiler + finalizer on `SPItemVMExtension.ExecuteUseItem`: swaps the brittle `Type.GetType` for an all-assemblies resolver (fixes the enchantment-book "choose a hero" popup not opening) and swallows any other inventory-use-script exception. |
| **`UICommandSafetyPatch`** | Universal finalizer on the Gauntlet `ViewModel.ExecuteCommand` choke point — a misbehaving menu/UI button shows a message instead of crashing the game. |
| **`GarrisonStarvingNullSafetyPatch`** | Prefix on `Helpers.SettlementHelper.IsGarrisonStarving`: returns `false` for a null settlement (orphaned garrison) instead of letting `Clan.AfterLoad` dereference it on save load. Installed in `OnGameStart` (before `OnGameLoaded`) so it guards the very first load. |
| **`PartyHealingNRESafetyPatch`** | Finalizers on vanilla `DefaultPartyHealingModel.GetDailyHealingForRegulars` / `GetDailyHealingHpForHeroes`. In the regulars calculation every settlement access is null-checked except the two in the garrison branch (`mobileParty.CurrentSettlement.IsStarving` / `.IsTown`), so a garrison with no settlement — orphaned, or temporarily out on a sally-out — kills the quarter-daily party tick, 4× per game day, seconds after every load. The guard returns a `0` `ExplainedNumber` (carrying the caller's `includeDescriptions`), so that party neither heals nor takes starvation damage on that one tick and the tick completes; the method mutates no campaign state, so nothing is half-written. Arguments are read positionally — the signature is `(MobileParty, bool)` on 1.2.x and `(PartyBase, bool, bool)` on 1.3.15+. The log line tells an orphan apart from a sally-out. |
| **`TorMountStatusEffectSafetyPatch`** (TOR) | Signature-aware guard on `AgentDrivenPropertiesExtensions.SetDynamicMountMovementProperties` — re-syncs the mount base values (older TOR) or just swallows the `ArgumentException` (newer TOR) so a mounted unit doesn't crash the battle every frame. Inert on TOR builds that already fixed the root cause. |
| **`TorAbilityAiCastNRESafetyPatch`** (TOR) | Guard on TOR's ability AI-cast path (`CalculateAICastMatrixFrame`): when RTS/free (commander) camera detaches the hero, a spell cast is routed through the AI path that expects data the hero doesn't have; the spell is cast as the hero instead of crashing the battle. |
| **`SellPrisonersUnderflowSafetyPatch`** | Finalizer on `SellPrisonersAction.ApplyInternal` — swallows the `MBUnderFlowException` when a desynced prison roster goes below zero during a town auto-sell; the party skips that one sale. |
| **`EncounterMenuInitSafetyPatch`** | Prefix + finalizer on **two** sibling `EncounterGameMenuBehavior` on-init callbacks — `game_menu_encounter_on_init` (the encounter menu) and `game_menu_town_outside_on_init` (the "at the gate, entry denied" menu). When a save made at either menu loads without a restored `PlayerEncounter` (`PlayerEncounter.Current` null), vanilla dereferences the null encounter — `encounter_on_init` via `StartBattle`/`Update`, `town_outside_on_init` via `PlayerEncounter.EncounterSettlement.Name` (the getter returns null when `Current` is null) — and crashes the load; instead the player is returned to the campaign map via `GameMenu.ExitToLast()`. A healthy load has `Current != null`, so the guard is a no-op and vanilla runs. *Deferred to game start* — the target type's static init reads `GameTexts`, so patching it at the main menu would poison it (see note below the table). |
| **`ColumnFormationSpawnSafetyPatch`** | Prefix on `ColumnFormation.GetLocalPositionOfUnitOrDefault(int)`. Vanilla reads element `[1]` of the column's vanguard-file position list unconditionally — an `ArgumentOutOfRangeException` that kills the whole battle tick when reinforcements spawn into a column formation with no soldiers left at its head (common with marching-reinforcement mods like Immersive Battlefields or RTS Camera's column order). The guard returns `null` instead, so the caller falls back to the default spawn frame. |
| **`OrderOfBattleTooltipSafetyPatch`** | Finalizer on the base `OrderOfBattleVM.GetAgentTooltip(Agent)` — the commander tooltip built when the deployment screen asks which formation the player will lead. The method null-checks the agent and the banner, then reads `bannerComponent.BannerEffect.Name` (and `GetBannerEffectBonus()`) with no check at all. `BannerComponent.Deserialize` sets that field from `MBObjectManager.Instance.GetObject<BannerEffect>(node.Attributes["effect"].Value)`, which returns **null** for an id no loaded module defines — a typo, an effect from a removed module, or an item file made for another game version. Such a banner is otherwise fully functional, so the crash is its only symptom, and it repeats on every battle where the banner is carried (the fight never starts). On game 1.2 the same block also reads `FormationBanner.Name` unguarded; 1.3+ wrap it in `TextObject.IsNullOrEmpty`. Checked across `TaleWorlds.MountAndBlade.ViewModelCollection`, `TaleWorlds.MountAndBlade`, `TaleWorlds.CampaignSystem` and `SandBox.ViewModelCollection`: this is the **only** unguarded read of `BannerEffect` in the game — everything else compares it and survives a null. The finalizer returns an **empty, never null** `List<TooltipProperty>`: SandBox's `SPOrderOfBattleVM` override calls the base and then `.Add()`s to the result, so a null would just move the crash one frame up; `OrderOfBattleHeroItemVM.RefreshValues` only caches the list for a `BasicTooltipViewModel`, so an empty one is a valid tooltip. The banner item is logged by `StringId`, which names the mod that shipped it. **Universal**, not mod-specific. |
| **`TorAudioRegisterSoundSafetyPatch`** (TOR) | Finalizer on `TOR_Core.Audio.TORAudioManager.RegisterSound`, which builds NAudio.Vorbis with no try/catch. When a .NET library NAudio needs (`System.Memory`, normally provided by the game runtime or ButterLib) can't load on the player's setup, the OGG ctor throws `FileNotFoundException` and crashes the campaign — e.g. a TOR music event on the hourly tick while walking the map. The guard swallows it and returns failure, so the sound is skipped (`CreateSoundInstance` returns null, which `PlayMusic` already null-checks) and the game continues. The matching rule `tor.audio_dependency_missing` explains the missing-library root cause and the fix (verify game files / install ButterLib). |
| **`SiegeLeaderlessPartyNRESafetyPatch`** | Prefix on `SiegeEventManager.StartSiegeEvent(Settlement, MobileParty)`. When the besieging party has no leader hero (`LeaderHero == null`) the default `EncounterModel.GetLeaderOfSiegeEvent` returns null and `BesiegerCamp.AddSiegePartyInternal` dereferences it. Fires only for a leaderless besieger (autonomous Bandit-Militias-class parties); the impossible siege simply doesn't start, no state is half-built. Normal lord sieges are untouched. |
| **`SiegeCompletedNullOwnerSafetyPatch`** | Prefix on the private `ChangeOwnerOfSettlementAction.ApplyInternal(Settlement, Hero newOwner, Hero capturerHero, ChangeOwnerOfSettlementDetail)`. When a siege is **won**, `KingdomManager.SiegeCompleted` sets the new owner to `(capturerParty.MapFaction as Kingdom)?.Leader ?? capturerParty.MapFaction.Leader`; a kingdom whose ruler was executed/died with no heir (or a leaderless minor faction/clan) that kept besieging makes that **null**, and for a fortification `ApplyInternal` runs `settlement.Town.OwnerClan = newOwner.Clan` with no null-check — NREing the whole campaign tick the instant the siege resolves (`MapEvent.FinalizeEventAux` → `Campaign.Tick`). The prefix fires ONLY for a fortification with `newOwner == null` (a null owner is legitimate for a village and vanilla already guards it there): it substitutes `capturerHero` — the hero who actually captured the settlement — so it transfers to the conqueror's clan, the intended outcome minus the null; falling back to the current owner's leader, and skipping the transfer entirely if nothing valid exists (settlement keeps its old owner rather than crash). A non-null owner runs vanilla unchanged. Triggered by mods that leave a kingdom/clan leaderless (execution/death/rebellion mods); base-game bug, not TOR. **Universal**, not mod-specific. |
| **`ChangePartyLeaderNullPartyNRESafetyPatch`** | Prefix on the base-game `PartyComponent.ChangePartyLeader(Hero)`. When a clan is liquidated on the daily tick (`FactionDiscontinuationCampaignBehavior.DailyTickClan` → `DestroyClanAction.ApplyInternal` → `KillCharacterAction.MakeDead`), the dying leader's party is handed to a new leader; `MobileParty.ChangePartyLeader` forwards to `this.PartyComponent.ChangePartyLeader`, whose body dereferences the component's own `{ get; private set; }` back-reference `MobileParty` with no null-check (first at `this.MobileParty.MemberRoster.Contains(...)`, then at `this.MobileParty.MapEvent`). `MobileParty` is the ONLY unguarded ref-deref in the method (`Leader` is a null/field getter, `MemberRoster` on a live party was just iterated by `MakeDead`), so a party whose component was detached / half-torn-down during liquidation reads it back **null** and NREs the whole map tick the instant the dying faction's clan is removed. The prefix fires ONLY when `__instance.MobileParty == null` — the one state where every line of the method would crash — and skips the original (a detached party can't change leader anyway); the clan removal in `MakeDead` continues. A live party runs vanilla unchanged. On game 1.2 the guard deliberately does not install at all: there the base method is `virtual` with a body of a single `ret` and all the logic lives in the overrides, so the crash cannot occur — and a prefix could only ever report a prevented crash that never happened. Base-game bug triggered by mod/save state (seen on the Europe 1100 total conversion); **universal**, not mod-specific. |
| **`ClanLeftKingdomNullOldKingdomNRESafetyPatch`** | Prefix on the private `CharacterRelationCampaignBehavior.OnClanChangedKingdom(Clan, Kingdom oldKingdom, Kingdom, ChangeKingdomActionDetail, bool)`. When an AI clan leaves a kingdom on the daily tick (`DiplomaticBartersBehavior.DailyTickClan` → `ConsiderClanLeaveKingdom` → `LeaveKingdomAsClanBarterable.Apply` → `ChangeKingdomAction.ApplyInternal`), the handler applies the leave penalty (−20, −40 on rebellion) via `foreach (Clan c in oldKingdom.Clans)` with **no null-check**. `oldKingdom` is `clan.Kingdom` as captured when the action started, and it can be **null**: `DailyTickClan` tests `clan.Kingdom != null` on the *ticked* clan, but `Apply()` acts on `OriginalOwner.Clan` — i.e. `clan.Leader.Clan` — a different, possibly kingdomless clan once a mod has moved that leader hero (Dramalord, KeepYourClanMembersAfterMarriage, Titles, PlayerSwitcher, ChildrenExpanded). `ApplyInternal` survives the null (its settlement-transfer loop, the only `kingdom` deref, is empty for a landless clan) and dispatches the event, so the whole daily tick dies in the relation handler. That vanilla *expects* a null here is proven by its own `CheckIfPartyIconIsDirty`, which writes `oldKingdom ?? clan` a few lines earlier. The prefix fires ONLY when `oldKingdom == null` (or `clan == null`) and skips the original — there is no kingdom to lose relation with, so the penalty has no target; the vanilla loop is **not** reimplemented and the −20/−40 constants are not relied on. A non-null kingdom runs vanilla unchanged. Verified against the shipped **1.4.7** `CampaignSystem` (body identical in 1.3.x); the null-hero alternative is ruled out because `ChangeRelationAction.ApplyInternal` (112 bytes of IL, past the JIT inline limit) is absent from the stack. Base-game bug triggered by mod state; **universal**, not mod-specific. |
| **`ClanNavalCapabilityNullTemplateSafetyPatch`** | Prefix on the vanilla getter `Clan.HasNavalNavigationCapability`. The getter is `DefaultPartyTemplate.ShipHulls.Count > 0`, where `DefaultPartyTemplate` is `_defaultPartyTemplate ?? Culture.DefaultPartyTemplate` and `ShipHulls` is only initialised in `PartyTemplateObject.Deserialize` (from XML) — so a clan whose culture/template carries no ship-hull data makes the getter **NRE**. TOR's beastmen (Ungors/Gors) are bandit factions with no naval data, so every time such a party is destroyed after a battle, `BanditSpawnCampaignBehavior.MobilePartyDestroyed` → `IsLooterFaction` reads the getter and crashes the whole campaign tick (`OnMobilePartyDestroyed` → `MapEvent.FinalizeEventAux` → `Campaign.Tick`). The prefix resolves the template exactly the way vanilla does — so a clan carrying its own `_defaultPartyTemplate` never touches `Culture`, and a null `Culture` there is not a problem at all — and returns `__result = false` only when that resolution actually throws or leaves the template/`ShipHulls` null (no ships ⇒ genuinely no naval capability — the semantically correct answer, and every clan-level consumer just picks land navigation / looter classification on false, none dereferences or serialises it). A clan with a valid template runs vanilla unchanged — the guard's branch is reachable only on the exact input where vanilla already NREs. Base-game bug triggered by mod data; **universal**, not mod-specific. |
| **`ArmyGatheringSettlementNRESafetyPatch`** | Prefix + state-repairing finalizer on the private `Army.FindBestGatheringSettlementAndMoveTheLeader(Settlement)`. When a siege starts on the very fortification an army is still gathering at, `Army.OnSiegeStarted` makes the army re-pick its rally point; the scan accepts only fortifications that aren't under siege, carry no `MapEvent`, aren't the besieged settlement and sit far enough away, and when nothing qualifies the fallback `SettlementHelper.FindNearestFortificationToMobileParty` **can return null** — vanilla reads `settlement.GatePosition` off it anyway and NREs the whole map tick (`StartSettlementEncounter` → `StartSiegeEvent` → `OnSiegeEventStarted` → `Campaign.Tick`). The prefix skips the method when `Army.Kingdom` is null (the other unguarded site, `this.Kingdom.Settlements`); the finalizer swallows the NRE **and restores the rally point**, because `this.AiBehaviorObject = settlement;` executes one line before the throw and would otherwise leave the army with a null target that `Army.IsAnotherEnemyBesiegingTarget` (hourly), `LordConversationsCampaignBehavior` and `DefaultNotificationsCampaignBehavior` dereference unguarded — trading one crash for another. The restore runs only when the field actually ended up null. The army keeps gathering where it was and its AI re-thinks next tick; vanilla explicitly handles a besieged rally target (`MoveLeaderToGatheringLocationIfNeeded` checks `IsUnderSiege`). Cold path, **universal**, no-op for healthy games. |
| **`IntersectRayPolygonNullSafetyPatch`** | Prefix on vanilla `TaleWorlds.Library.MBMath.IntersectRayWithPolygon(Vec2, Vec2, MBList<Vec2>, out Vec2)`. At the start of a battle, during the deploy phase, each spawning troop's position is projected back inside its team's deployment zone (`SpawnTroop` → `Agent.set_Formation` → `ProjectPositionToDeploymentBoundaries` → `GetPathDeploymentBoundaryIntersection`). That helper reads `polygon.Count` with no null-check, and the deployment code hands it a null boundary polygon (`IsPositionInsideDeploymentBoundaries` returns the stub tuple `("", null)`) when the path's start point is inside no deployment boundary — a scene whose deployment-frame origin sits just outside its own zones — killing the whole mission tick before the battle starts. The prefix fires ONLY when `polygon` is null: it sets `intersectionPoint = rayOrigin` and `__result = false` and skips the original — exactly the method's own "no edge intersects" outcome (the caller discards the bool and reads only the out Vec2, so the troop just deploys near its start). Any non-null polygon runs vanilla untouched. Intermittent and scene-geometry dependent, not faction-specific (client saw it entering a beastmen battle after many fine ones). **Universal**, not mod-specific. |
| **`MovementOrderIsApplicableNRESafetyPatch`** | Finalizer on vanilla `MovementOrder.IsApplicable(Formation)`. During siege auto-deploy (`SiegeDeploymentHandler.AutoDeployTeamUsingTeamAI` → `Team.Tick` → `FormationAI.FindBestBehavior` → `PrecalculateMovementOrder` → `CreateNewOrderWorldPositionMT`) the AI re-checks each formation's movement order; `IsApplicable` switches on the order kind and dereferences `TargetEntity`/`TargetFormation`/`_targetAgent` with no null guard. A formation carrying an order whose target has gone null (destroyed machine, emptied formation, removed agent between phases) NREs the whole mission tick before the assault starts. Returns `__result = false` on the NRE — exactly what the method returns for a destroyed target, so the caller drops the stale order and falls back to a default world position. Swallows only NRE; self-heals next tick. Does not depend on TOR. |
| **`MissionLocationLogicRemoveNRESafetyPatch`** | Prefix + finalizer on `SandBox.Missions.MissionLogics.MissionLocationLogic.OnRemoveBehavior`. When you leave a town/village/castle location, the mission state is popped (`MissionState.OnFinalize` → `Mission.RemoveMissionBehavior` → `OnRemoveBehavior`) and the teardown's first statement loops over `LocationComplex.Current.GetListOfLocations()` with no null guard. `LocationComplex.Current` is `PlayerEncounter.LocationEncounter != null ? …Settlement.LocationComplex : null`, so on a state-pop ordering race (leaving the settlement while the encounter is ending) it returns null and the loop NREs the whole tick meant to return you to the map. The prefix runs vanilla unchanged when the complex is present; when it's null it performs the one load-bearing side-effect — `CampaignEventDispatcher.Instance.RemoveListeners(__instance)` — and skips the original (the loop has no complex to clean, `base.OnRemoveBehavior()` is an empty virtual). The finalizer swallows an NRE thrown for any other reason and best-effort runs the listener cleanup, so the mission finalizes instead of crashing. Does not depend on TOR. |
| **`CleanScreensTeardownNRESafetyPatch`** | Finalizer on `TaleWorlds.ScreenSystem.ScreenManager.CleanScreens`. When the game tears the whole session down (`MBGameManager.EndGame` → `GameStateManager.CleanStates` → `OnCleanStates` → `CleanScreens`, on the main sync-context tick) it iterates the screen stack; a screen that is already null/half-destroyed is dereferenced and the NRE crashes to desktop instead of dropping to the main menu. Seen after a successful assault on a besieger camp where a broken siege state (map shows "besiegers -0") forces `EndGame`. The finalizer swallows **only** the `NullReferenceException` so the teardown completes and the game lands on the main menu (the last save is intact), then queues a one-time main-menu inquiry explaining what happened. This is a **symptom** guard — the primary fault is the broken siege event (not in this stack). TOR's own `ToMainMenuClearAllFix` wraps `CleanScreens` but re-throws; this one actually swallows. Does not depend on TOR. Listed on the Crash Fixes tab (id `cleanscreens_teardown`). |
| **`TorPartyUpgraderNRESafetyPatch`** (TOR) | Finalizer on `TORPartyUpgraderCampaignBehavior.UpgradeReadyTroops(PartyBase)`. TOR's daily auto-upgrade filters the roster with `!t.Character.IsHero && t.Character.UpgradeTargets.Length != 0`; a broken troop (null `Character`/`UpgradeTargets`) crashes the whole daily tick. The finalizer isolates it to one party, which skips its upgrade; other parties continue. |
| **`VictoryReactionRetreatNRESafetyPatch`** | Finalizer on `AgentVictoryLogic.SetTimersOfVictoryReactionsOnRetreat(BattleSideEnum)`. The end-of-battle retreat-cheer selection filters agents with `agent.IsHuman && agent.IsAIControlled && agent.Team.Side == side`; an AI human agent with a null `Team` (mid-battle summon/raise-dead with no team assigned) NREs the mission tick. Swallows only the NRE — the load-bearing side effects run before it, so only the cosmetic cheer is skipped. |
| **`PartyTrainingNRESafetyPatch`** | Finalizer on `MobilePartyTrainingBehavior.OnDailyTickParty(MobileParty)`. The training-XP model (`DefaultPartyTrainingModel.GetEffectiveDailyExperience`, via TOR's override) reads per-troop fields; a troop with invalid data (e.g. null culture) NREs the daily tick. The affected party skips its training; the game continues. Backstop to the root fix below. |
| **`PartyUpgradeWageDivideByZeroSafetyPatch`** | Finalizer on the vanilla `PartyUpgraderCampaignBehavior.UpgradeReadyTroops(PartyBase)`. Capping how many soldiers an AI party's wage budget allows, `GetPossibleUpgradeTargets` divides by `Wage(upgradeTarget) - Wage(source)` with **no zero check** — while the two neighbouring divisions in the same method (`upgradeXpCost`, `upgradeGoldCost`) are guarded. The difference is zero whenever a higher-tier troop is paid the same: `DefaultPartyWageModel` pays by tier (1/2/3/5/8/12/17, flat 23 past 6) and multiplies mercenaries by 1.5 truncated to int, so mercenary T1→regular T2 and mercenary T4→regular T5 both divide by zero, any mod raising `MaxCharacterTier` makes every tier ≥7 equal, and a replaced wage model can equalise any pair. With a zero difference the branch's own condition reduces to `TotalWage > PaymentLimit`, so it only fires for a party already over its budget — hence the rarity. Swallows **only** `DivideByZeroException` (anything else propagates untouched); the throw happens before `UpgradeTroop` mutates the roster, so no half-applied upgrade is possible, the behavior's `SyncData` is empty, and the method returns early for `PartyBase.MainParty` so the player's party never reaches it. That AI party skips the rest of its auto-upgrade for one tick. Body verified identical in the shipped **1.3.15** and **1.4.7** `CampaignSystem`, where `UpgradeReadyTroops` has exactly two callers and no other assembly references it. Base-game bug; **universal**, not mod-specific. TOR's port of the same method added `&& !IsWageLimitExceeded()`, which is immune. |
| **`SimulatedBattleHitNRESafetyPatch`** | Finalizer on the private `MapEvent.SimulateSingleTroopHit(BattleSideEnum, …)`. The engine auto-resolves AI-vs-AI map battles every tick; `MapEventSide.ApplySimulatedHitRewardToSelectedTroop` dereferences the striker troop's `FirstBattleEquipment` as its first statement. A **dangling troop** (a `CharacterObject` that no longer resolves — classic leftover after a custom-troop mod like Special Troops Plus / FireArchers is removed, once AI lords have recruited those units) makes the striker null and NREs the whole campaign-map tick. The finalizer drops just that one simulated hit (`__result = false`); the `SimulateBattleRound` loop resolves the battle from the remaining valid troops. Root fix is `DanglingTroopCleanerBehavior` (below) + a re-save. |
| **`DefaultTroopTraitsNRESafetyPatch`** | Finalizer on `TaleWorlds.Core.AgentOriginUtilities.GetDefaultTroopTraits(BasicCharacterObject, out …)` — the funnel the game uses to read a troop's weapon slots (0..4) and set its default AI traits (thrown/spear/shield/heavy-armor). The vanilla loop only guards `IsEmpty` (`Item == null`) and then reads `Item.PrimaryWeapon.WeaponClass` with no further check, so a **non-weapon item in a weapon slot** (armor / a horse / a broken item, where `PrimaryWeapon` is null) NREs. A missing/unresolved item id does **not** crash — that slot reads empty and is skipped; it takes a *resolved* non-weapon item in a weapon slot, which custom-troop editors (My Little Warband and the like) can place there, baked into the save. The same read crashes troop deployment at battle start (`PartyGroupTroopSupplier.SupplyTroops` → `CheckDeployment` → `BattleDeploymentMissionController`), recruiting, the Party screen, and the mod's own unit editor. The finalizer swallows the NRE — the four `out` flags are false-initialised before the loop, so the troop just gets plain default traits and the game continues; healthy troops never throw and keep exactly vanilla's values. Offending troop id logged. **Universal**, not mod-specific; not a hot path (troop supply / screen open). |
| **`CharacterDataFallbackPatch`** (TOR) | Single-point root fix for the "malformed troop" cascade: postfixes on the `CharacterObject.Culture`, `CharacterObject.UpgradeTargets` **and `CharacterObject.FirstBattleEquipment`** getters. A live, registered troop (seen: TOR's `tor_gs_trolls`, `race="troll"`) has these fields correct in XML but null at **runtime**, and every consumer that reads them NREs in a different method (wages, food, auto-upgrade, training, assimilation `SwapTroopsIfNeeded`, garrison XP `PartyBase.OnXpChanged`, auto-resolve combat `MapEventSide.ApplySimulatedHitRewardToSelectedTroop`). The postfixes substitute a fallback culture (`aserai`) / an empty upgrade array / a per-character empty `Equipment` (one instance each — `Equipment` is mutable, so a shared one would let any consumer that writes a slot corrupt it for every broken troop at once) at the one place every system reads the field — killing the whole cascade at the source. Read-only; never writes the backing field or save state. Getters resolved with `DeclaredOnly` to avoid the `new`-shadowed `Culture` ambiguity. Also carries a diagnostic that logs the call stack if anything ever *writes* null into these fields, to pin the upstream root (empirically 100% correlated with the LoreHardcore data mod). |
| **`SaveMetaDataDuplicateKeyGuard`** | Postfix on `SaveHandler.GetSaveMetaData` (the same method `ModListScrubPatch` postfixes; Harmony composes both). `MBSaveLoad.GetSaveMetaData` feeds every `CampaignSaveMetaDataArgs.OtherData` entry — plus `ApplicationVersion`/`CreationTime` — into `Dictionary.Add`, which throws `ArgumentException` ("same key has already been added") on a duplicate. Vanilla supplies 15 distinct keys, so a base game never throws; a third-party mod patching the metadata builder to append its own entry can inject a duplicate (or a key colliding with the reserved `Modules`/`Module_*`/`ApplicationVersion`/`CreationTime`), crashing **every** save (auto/quick/manual). The guard de-duplicates `OtherData` (keep-first, ordinal) and drops reserved-key collisions before the engine's `Add` loop — reproducing the dictionary the engine would have built, so the save's metadata is otherwise unchanged. `__result` is rebuilt only when something is actually removed (zero overhead on normal saves). Does not depend on TOR. |
| **`SelfSaveModuleCheckSuppressor`** | Postfix on `SandBox.SandBoxSaveHelper.CheckMetaDataCompatibilityErrors` — the single helper both the load-time "modules changed" inquiry and the corrupted-file check funnel through. For each save-recorded module it compares `Module_<id>` against the installed `ModuleInfo.Version` and emits `ModuleCheckResultType.VersionMismatch` on any diff (plus `ModuleAddedToGame`/`ModuleRemovedFromGame`). Since Crash Doctor's build number now moves every update (so it's visible in the launcher), every old save would list Crash Doctor under version-mismatch on load. The postfix drops **every** result whose `ModuleId == "CrashDoctor"`, regardless of type — safe with zero caveats because Crash Doctor registers no `SaveableTypeDefiner` state, so its version/presence can never affect deserialisation. Every other mod's result is untouched. Resolves the SandBox type by name (no compile-time dependency), so one source runs on 1.2 (v12) and 1.3+ (v13). Does not depend on TOR. Listed on the Crash Fixes tab (id `self_save_module_check`). |
| **`EffectiveRelationNullHeroNRESafetyPatch`** | Prefix on `DefaultDiplomacyModel.GetEffectiveRelation(Hero, Hero)`. On the hourly map tick `Army.ThinkAboutCohesionBoost` → `CalculatePartyInfluenceCost` calls `armyLeaderParty.LeaderHero.GetRelation(party.LeaderHero)`; a member party with no leader (`party.LeaderHero == null`) hands a null hero into the diplomacy model, which guards its outputs but not its inputs, so `GetHeroesForEffectiveRelation` dereferences `hero.Clan` and NREs the whole campaign tick. Returns `__result = 0` (no relation) when either hero is null — matching the same-clan branch that already returns 0 — so the leaderless party contributes no influence cost and the army continues. Two valid heroes run vanilla unchanged. Comes from mods that spawn hero-less map parties the AI absorbs into armies (e.g. RealmsForgotten / RFMonsters). Does not depend on TOR. |
| **`TroopRosterCountUnderflowSafetyPatch`** | Prefix on `TroopRoster.AddToCountsAtIndex(index, ref countChange, ref woundedCountChange, …)` — the single funnel every roster add/remove routes through. It does `data[index].Number += countChange` with no floor, so a caller asking to remove more troops than the element holds drives `Number` below zero and the `set_Number` setter throws `MBUnderFlowException`, killing the campaign tick. The prefix clamps an over-large negative `countChange`/`woundedCountChange` to exactly empty (`-current`); the original then floors the element at 0 and its own `removeDepleted` branch drops the emptied row — the intended "remove all, no more" outcome. **Universal**, not mod-specific: vanilla always checks the count before removing so the clamp is a no-op for healthy calls; it catches the whole class of negative-count crashes (first seen via TOR's unclamped Wood Elf dryad recruitment, `TORAIRecruitmentCampaignBehavior.cs:196`). Does not depend on TOR. **Since 1.8.7.6 the same prefix also handles `index < 0`**, which is a different crash at the same funnel: `TroopRoster.RemoveTroop` calls `FindIndexOfTroop`, gets `-1` when the troop is not in that roster and forwards it unchecked, and `AddToCountsAtIndex` reads `data[index].Character` on its **first** line → `IndexOutOfRangeException` (client crash `9f176929`, 1.4.7, reached through `MapEvent.LootDefeatedPartyPrisoners`, which walks the **live** prisoner list while `RemoveTroop` deletes by the index of the first match rather than the loop's own — a roster holding the same `CharacterObject` twice shifts underneath it; two TOR career-button call sites pass `FindIndexOfTroop` in unchecked as well). The prefix skips the original and returns `-1`. Safe because there is **no** working path with a negative index — vanilla always throws on line 1, nothing has been mutated yet, and the return value is discarded by all 26 call sites in the game and TOR. Deliberately **not** extended to `index >= Count`: the backing array is over-allocated so that case does not throw, and changing it would alter a path that currently runs. |
| **`SkillTrainerLeaveNullHeroSafetyPatch`** (TOR) | Prefix on `TOR_Core.CampaignMechanics.SkillTrainerBehavior.LeaveTraining(Hero)`. After a settlement is taken by siege/rebellion, `SettlementOwnerChanged` ends training for every companion tracked in `_heroesInTraining` there, resolving the hero via `Hero.MainHero.Clan.Heroes.FirstOrDefault(x => x.StringId == key)`. That returns null once the companion has left the player's clan (died/captured/dismissed) but his id is still in the dictionary — TOR never prunes the stale entry — and `LeaveTraining` dereferences `hero.CurrentSettlement` on the null hero, NREing the campaign tick (and re-firing on every later siege of that town). Returns `false` (skip original) only when `hero == null`; a valid hero runs vanilla unchanged. The dictionary is deliberately left alone (the caller is mid-`foreach` over it). Only active with TOR loaded. |
| **`PartySkillExercisedNRESafetyPatch`** | Finalizer on the private `DefaultSkillLevelingManager.OnPartySkillExercised(MobileParty, SkillObject, float, PartyRole)` — the single funnel every party skill-XP grant routes through (trade, governing, raids, surgery, training, tactics, scouting, charm, auto-resolve rewards…). It does `party.GetEffectiveRoleHolder(role)` and null-checks the resulting holder but **not `party`**; in auto-resolve, surgery XP is granted via `OnSurgeryApplied(party.MobileParty, …)` and a struck troop belonging to a `PartyBase` with a null `MobileParty` (settlement/garrison party, or one left by a removed mod) hands it a null party → NRE → whole map tick dies. The `_Patch1` frame shows XP-overhaul mods (BetterExperience/BetterCore) also patch it, so a finalizer covers both null-party and a throwing mod patch. The method is void, so a swallow just skips that one XP grant. **Universal**, not mod-specific; no-op for healthy calls. |
| **`GainRenownNullClanNRESafetyPatch`** | Prefix on the private `GainRenownAction.ApplyInternal(Hero, float, bool)` — the single funnel for all renown awards (battle wins, quests, tournaments, cheats). It does `hero.Clan.AddRenown(…)` with no null-check on `hero` or `hero.Clan`; an auto-resolved battle won by a party led by a clanless/null hero (bandit/mod-spawned hero, leaderless party, clanless lord left by a removed mod) NREs the whole map tick. Returns `false` (skip original) when `hero == null` or `hero.Clan == null` — there is no clan to receive the renown, so skipping is the correct no-op; a valid hero+clan runs vanilla unchanged. **Universal**, not mod-specific. |
| **`EndCaptivityNullCaptorNRESafetyPatch`** | Prefix on the private `PlayerCaptivity.EndCaptivityInternal()`. The defeated-party loot path (`MapEvent.LootDefeatedPartyPrisoners` → `EndCaptivityAction.ApplyInternal` → `PlayerCaptivity.EndCaptivity`) releases every prisoner of an auto-resolved battle's beaten party, including the main hero; `EndCaptivityInternal` does `this._captorParty.IsActive` with no null-check. `_captorParty` is null exactly when `PlayerCaptivity.IsCaptive` is false — a double-release, or a captivity/enlistment mod (e.g. Enlistment) that moved the player in/out of parties without routing through `StartCaptivity` — so the deref NREs the whole map tick. Returns `false` (skip original) when the captor party is null (nothing to release); first best-effort re-activates the main party if it was left inactive, so the player is never frozen. A healthy capture (non-null captor) runs vanilla unchanged. **Universal**, not mod-specific. |
| **`MapEventNullFactionSafetyPatch`** | Prefix on the internal `MapEvent.Update()` — the per-tick heartbeat of every ongoing battle. Its first statement asks whether the two sides are at war: `_sides[0].LeaderParty == null || _sides[1].LeaderParty == null || !_sides[0].LeaderParty.MapFaction.IsAtWarWith(_sides[1].LeaderParty.MapFaction)`. `LeaderParty` is null-checked, `LeaderParty.MapFaction` is not, and it is the only unguarded dereference in the whole method (`MapEventSide` even caches its own `_mapFaction` for this case, but `Update` bypasses the cache). `MobileParty.MapFaction` returns null once `ActualClan` and `LeaderHero` are both null — exactly where a **destroyed** party lands, because `MobileParty.RemoveParty` → `OnRemoveParty` nulls `ActualClan` and does **not** detach the party from its map event (vanilla relies on the caller doing it; its own save migration writes `MapEventSide = null; DestroyPartyAction.Apply(…)` in that order). Any mod that destroys a party still standing in a live battle therefore leaves the battle holding a dead leader, and the next `MapEventManager.Tick` kills the campaign; since the battle is stored in the save, the game then dies ~1 s after **every** load, with no way for the player to reach it (it belongs to AI parties). The prefix ends that battle through the public `FinalizeEvent()` and skips the original — `FinalizeEventAux` marks the event `WaitingRemoval` on its first statement, so `MapEventManager` drops it next tick even if a downstream listener throws, which repairs the save as well. Deliberately **not** done via vanilla's own "no war between the sides" path (`DiplomaticallyFinished = true`): that path walks `InvolvedParties` calling `RecalculateShortTermBehavior()` with no `IsActive` filter, and that method derefs `TargetSettlement.Party`/`TargetParty.Party` unguarded — on a removed party with a stale `DefaultBehavior` it would just move the same NRE one frame later. A player battle with a live `PlayerEncounter` is only skipped, never finalized, matching vanilla's own rule that the encounter owns that teardown. A healthy battle (both leaders present, both with a faction) returns on the two null checks and runs vanilla unchanged. **Universal**, not mod-specific. |
| **`MapEventLeaderlessSideSafetyPatch`** | Sibling of the row above, for the state one step worse: the side's leading party is not factionless but **gone**. Vanilla's `AiMilitaryBehavior.OnMapEventEnded` opens its non-retreat branch with `mapEvent.AttackerSide.LeaderParty.MobileParty` and never null-checks `LeaderParty`, although the engine checks that very field elsewhere (`MapEvent.Update`, `MapEvent.ToString`'s `AttackerSide.LeaderParty?.Name`). Two routes reach it and both kill the campaign tick: `Update` sees the missing leader → `DiplomaticallyFinished` → `FinishBattle()` → `FinalizeEventAux` (no mod needed), and anything re-assigning `PartyBase.MapEventSide` → `MapEventSide.RemovePartyInternal` → `FinalizeEvent()` mid-tick. Rather than guarding one line, the fix **repairs the invariant** with a prefix on `MapEvent.FinalizeEventAux` — the single choke point of both routes — applying vanilla's own rule for a side that loses its leader (`RemovePartyInternal` does `LeaderParty = _battleParties[0].Party`): the first party still on that side is promoted. That covers every other unguarded read in the teardown too — `SiegeCompleted(…, AttackerSide.LeaderParty.MobileParty, …)` on all siege/sally-out branches and `HandleMapEventEndForPartyInternal`'s `OtherSide.LeaderParty.LeaderHero`. `LeaderParty` has an internal setter, so the write goes through a cached `AccessTools.PropertySetter`; it is the only write in the guard and happens one statement before the event is marked `WaitingRemoval` and dropped. A side with no parties left has nothing to promote — that case falls back to a finalizer on `AiMilitaryBehavior.OnMapEventEnded`, which costs only the AI reaction (flee targets / raid resumption) and leaves the other `MapEventEnded` listeners running. The listener does not exist on game 1.2 (added in 1.3); the repair prefix carries the fix there alone. Verified against the shipped 1.4.7 `CampaignSystem.dll`. **Universal**, not mod-specific. |
| **`WarPartyFinalizeNullClanSafetyPatch`** | Prefix on `WarPartyComponent.OnFinalize()` — the last thing the engine does with a lord's or bandit's party on its way out of the world. The whole body is `Clan.OnWarPartyRemoved(this)`, where `Clan => base.Party.MobileParty.ActualClan` is read live off the party and never null-checked (byte-identical on 1.2 / 1.3.15 / 1.4.5 / 1.4.7). On a healthy first removal the clan is still there — `MobileParty.OnRemoveParty` runs `PartyComponent?.Finish()` and only *then* clears `ActualClan` — so vanilla never produces this state itself; a party cannot even be created without a clan. It reads back null in exactly two situations: the party was **already** removed once (nothing stops a second pass — `DisbandPartyAction.StartDisband` takes the `TotalManCount == 0` branch because the first `RemoveParty` emptied the roster, and `DestroyPartyAction`'s only objection to an already-dead party is a `Debug.FailedAssert`, a no-op in the shipped build), or a mod assigned `ActualClan = null` by hand (the setter notifies the clan only when swapping one non-null clan for another, so the clan is left holding a stale reference). The setting is nearly always a mod's own battle-end handler, since the game dispatches `MapEventEnded` before it destroys the wiped-out parties itself. The prefix reads the clan through the game's own property inside a `try` — so its condition is exactly the condition the original throws on, never wider — and when there is none it skips the original and unregisters the component from any clan whose `WarPartyComponents` list still holds it, which is what `OnFinalize` was there to do; leaving it in would keep a destroyed party feeding the clan's strength total and its kingdom's army bookkeeping. Both lists are `[CachedData]`, rebuilt on load, so nothing is written to the save. Healthy parties return on the first check and run vanilla unchanged. Reported once per component via a `WeakReference`, so a mod retrying the disband every tick cannot inflate the counter. Seen with BrigandBands; **universal**, not mod-specific. |
| **`ClanUpdateStrengthNRESafetyPatch`** | Finalizer on `Clan.UpdateCurrentStrength()` — on game 1.2 the very same method is named `Clan.UpdateStrength()` and the guard resolves that name too, so 1.2 saves are covered as well. Runs inside `Clan.AfterLoad` during **save loading**. It sums each party's `EstimatedStrength` → party morale → `GetEffectivePartyLeaderForSkill`, which for a leaderless party returns the first troop's `CharacterObject`; `BasicCharacterObject.GetSkillValue` then does `DefaultCharacterSkills.Skills.GetPropertyValue(skill)` with no null-check, so a malformed troop with null skill data (broken/overhaul troop e.g. ROT units, or one left by a removed mod) NREs **and the whole save fails to load**. The finalizer swallows it; `CurrentTotalStrength` is just a cache recomputed at runtime, so `AfterLoad` continues and the save opens. Targets the save-load chokepoint rather than the very hot `CharacterObject.GetSkillValue` leaf. **Universal**, not mod-specific; no-op for healthy saves. |
| **`HeroClearChangedPerksNRESafetyPatch`** | Finalizer on the private `Hero.ClearChangedPerks()` — runs inside `Hero.AfterLoad` during **save loading**. `AfterLoad` does `if (IsAlive) ClearChangedPerks()`, and `ClearChangedPerks` iterates `this._heroPerks.GetProperties()` with no null-check (unlike `IsPerkRegistered`, which guards `_heroPerks`). A save holding an **alive hero whose `_heroPerks` is null** (a broken/under-initialised hero left by a hero/clan/perk mod — perk overhauls like JackOfAllTrades, or clan/hero-spawning mods like Retinues / RaiseYourBanner / HousesCalradia) NREs the read **and the whole save fails to load**. The finalizer swallows it; the skipped cleanup only zeroes sub-threshold perks (cosmetic, and moot on an already-broken hero), so `AfterLoad` continues and the save opens. **Universal**, not mod-specific; no-op for healthy saves. |
| **`DanglingTroopCleanerBehavior`** | `OnSessionLaunched` scan: drops roster elements whose `Character` is null or **no longer registered in `MBObjectManager`** (a mod unregistered it without scrubbing rosters) across every party, settlement and active issue, and **removes orphaned garrison parties** (`IsGarrison && CurrentSettlement == null`, and only while idle — a garrison in a `MapEvent`/`SiegeEvent` is legitimately out on a sally-out and is left alone) so a re-save heals the campaign. Live modded troops that merely lack a culture are NOT touched; every removal is logged by `StringId`. Listed on the Crash Fixes tab as **"Fix broken troops on save load"**. |
| **`NavalShipUpgradeNullClanNRESafetyPatch`** (Naval DLC) | Prefix on the third-party `NavalDLC.CampaignBehaviors.ShipUpgradeCampaignBehavior.GetChanceToUpgradeShipForLord(Hero)`. The mod's `DailyTickPartyEvent` auto-upgrades AI ships each day and computes an upgrade chance from `hero.Clan.Tier`, but only guards `party.LeaderHero == null` — never that the leader *has* a clan. A party led by a clanless hero (TOR special/summoned/undead lords, or another mod spawning parties under clanless heroes) makes `hero.Clan.Tier` NRE the whole daily map tick. Returns `__result = 0f` (no upgrade chance) when `hero`/`hero.Clan` is null, so that party skips its ship upgrade and the tick continues; a real lord runs vanilla unchanged. Signature confirmed by decompiling the shipped `NavalDLC.dll`. Self-skips (shown *Skipped*) when Naval DLC isn't loaded. |
| **`SkillBonusForPartyNRESafetyPatch`** | Finalizer on `Helpers.SkillHelper.AddSkillBonusForParty` — the chokepoint every "role skill bonus" flows through (10 call sites across 7 vanilla models: loot, party speed, map visibility, healing, size limit, trade, siege). For a party with no role holder it falls back to `GetEffectivePartyLeaderForSkill`, i.e. the first troop in the roster, then reads `GetSkillValue` → `DefaultCharacterSkills.Skills.GetPropertyValue` with no null-check. A troop with null skill data (troop-overhaul mod, or one left by a removed custom-troop mod) NREs the whole campaign tick — most visibly while auto-resolve hands out loot. The swallow skips that one bonus (the number is computed without it) and logs the party + first troop id, which names the source mod. Note: a mod whose model appears in the stack (e.g. Naval DLC's battle-reward model) is *not* the culprit — it only forwards to the vanilla code that throws. **Universal**, not mod-specific. |
| **`LootItemChancesNRESafetyPatch`** | Finalizer on `DefaultBattleRewardModel.GetLootItemChancesForWinnerParties` (1.3+; the method does not exist on 1.2, where the patch self-skips). Verified against the IL of the shipped 1.4.7 assembly: the winner loop **explicitly allows** a party with no `MobileParty` (`mobileParty == null \|\| (!IsGarrison && !IsMilitia)`) — that is a settlement's own party, which is what fights when a village repels a raid or a town repels an assault — and then derefs it twice anyway, `party.MobileParty.HasPerk(Roguery.KnowHow, …)` and `defeatedParty.MobileParty.IsCaravan`, with no `IsMobile` check (the same class checks correctly in `CalculatePlunderedGoldAmountFromDefeatedParty` and `GetLootGoldChances`). The NRE lands mid-`MapEvent.CalculateAndCommitMapEventResults` and kills the campaign tick; since the unfinished battle is stored in the save, the game then crashes seconds after every load, as soon as time resumes. The finalizer recomputes the chance list null-safely — contribution share × 0.5, vanilla's own eligibility filter — so the battle finishes; only the Roguery loot multiplier is lost, and only for that battle. Safe because the vanilla method is pure (nothing is committed before the throw), it has exactly one consumer (`LootDefeatedPartyItems`, which uses the list as a probability wheel), and an empty list is a state vanilla produces itself. Reports through the same messenger, but stays silent when `SkillBonusForPartyNRESafetyPatch` just fired: it swallows the *first* throw of the same null a few instructions earlier, and one prevented crash must be counted once. Note: a mod whose loot model appears in the stack (e.g. Naval DLC's) is *not* the culprit — it only forwards to the vanilla code that throws. **Universal**, not mod-specific. |
| **`IssueCheckNRESafetyPatch`** | Finalizer on **every** `OnCheckForIssue` in `TaleWorlds.CampaignSystem.Issues` (~33 vanilla issue types). Once a day each settlement asks every quest type whether it fits one of its notables, and those hand-rolled `ConditionsHold` checks deref hero/settlement/notable data unguarded — confirmed in `GangLeaderNeedsToOffloadStolenGoodsIssueBehavior`, which reads `issueGiver.CurrentSettlement.Town.Security` one line *before* null-checking `CurrentSettlement`, and also assumes `.Town` (null in a village/castle) and a non-null `CharacterObject` on every notable. One bad notable kills the whole campaign tick with no player action ("I was just standing on the map"). Skipping one quest offer costs nothing — it can be offered again later. All types are patched, not just the reported one: they are written in the same style, so fixing one would just move the crash next door. **Universal**, not mod-specific. |
| **`NameGeneratorInitNRESafetyPatch`** | Finalizer on the private `NameGenerator.InitializeNameCodeAndCountDictionary()`, which runs during `Campaign.OnInitialize` — i.e. **while a save loads**. It walks every hero, living *and dead*, reading `FirstName`/`Name` with no null-check anywhere. One nameless hero (left by any hero-spawning mod) aborts the load, so the save stops opening permanently — and removing the culprit mod does *not* help, because its dead heroes stay serialised in the save. The game's own pass runs first and untouched; only when it throws does the finalizer swallow the exception (unhandled, the save simply never opens) and rebuild the cache — clearing `_nameCodeAndCount` first, since vanilla stopped at the first broken hero and a plain replay would double-count everyone it had already fed — then replaying both loops with null-checks and skipping the broken heroes, so the save opens. Each skipped hero is logged with its ids, which usually identifies the mod that created it. Cost: those heroes are missing from the name-frequency cache, making a generated name slightly likelier to repeat. Was a prefix until 2026-07-21, which substituted our reimplementation on *every* load, healthy saves included — as a finalizer the vanilla body stays authoritative and survives TaleWorlds changing it. **Universal**, not mod-specific. |
| **`AssignHeroEquipmentNRESafetyPatch`** | Prefix on `Helpers.EquipmentHelper.AssignHeroEquipmentFromEquipment(Hero, Equipment)`. When a kingdom's ruling clan changes, the 1.4.x `NPCEquipmentsCampaignBehavior.OnRulingClanChanged` asks `EquipmentSelectionModel` for a royal set and applies it here. The lookup keeps only rosters whose culture matches exactly **and** whose category flags *equal* the requested ones, then returns `GetRandomElement()` of the result — which on an empty list is `default(T)`, i.e. **null, silently** — and the helper derefs it on its first line (`if (equipment.IsStealth)`). Bandit/minor-faction cultures have no ruler set at all; modded cultures often have none, or carry one extra flag, which is enough to fail an equality test. It fires on the **daily tick** while a succession is being decided, so the vote never resolves and the next day crashes again — the save gets stuck rather than crashing once. The prefix skips the call only when an argument is null (the lord keeps their current gear; healthy assignments run vanilla) and logs the hero, culture and sex, which names the culture — and the mod — with no ruler set. Civil-war / bandit-kingdom / promote-to-lord mods make it far likelier, but the missing null-check is vanilla's. **Universal**, not mod-specific. |
| **`NavalShipOwnerChangedNRESafetyPatch`** (Naval DLC) | Finalizer on the third-party `NavalDLC.CampaignBehaviors.ShipTradeCampaignBehavior.OnShipOwnerChanged`. Every day the mod lets AI clans buy ships in ports; after the sale it pays the selling town's governor a perk bonus, and to do that it reads `governor.CurrentSettlement.Town` — the settlement the governor is standing in *right now* — with no null-check, even though it resolved that governor from the town it already had. A governor who is travelling, in an army or a prisoner is in no settlement, so the read NREs the whole daily clan tick. The handler is void and its only side effect (`GiveGoldAction`) sits after the throwing line, so the swallow leaves nothing half-applied; the sale itself is already committed by vanilla `ChangeShipOwnerAction.ApplyInternal` before the event fires, so only the governor's bonus is lost. Genuinely the mod's own bug (its code is the top frame) — seen on a near-vanilla 11-mod list. Signature confirmed by decompiling the shipped `NavalDLC.dll`. Self-skips (shown *Skipped*) when Naval DLC isn't loaded. |
| **`EffectivePartyLeaderSkillsNRESafetyPatch`** | Postfix on `Helpers.SkillHelper.GetEffectivePartyLeaderForSkill(PartyBase)` — the single place a broken troop can become a party's stand-in leader for skill purposes. For a party with no leader hero the helper returns `MemberRoster.GetCharacterAtIndex(0)`, and `BasicCharacterObject.GetSkillValue` then does `DefaultCharacterSkills.Skills.GetPropertyValue(skill)` with **no null-check**: a malformed troop with no skill data (overhaul troop, or one left by a removed custom-troop mod) NREs the whole campaign tick — seen via quarter-daily healing → `MobileParty.Morale` → `DefaultPartyMoraleModel.GetMoraleEffectsFromSkill`, i.e. the classic "standing on the world map doing nothing, crashes after a few seconds". The postfix returns `null` for such a troop; every vanilla consumer (party morale, `AddSkillBonusForParty`, surgeon/doctor's-oath healing bonuses, TOR's trade model) already null-checks and skips its bonus — the same outcome vanilla produces for an empty roster. Patching here rather than on the hot `CharacterObject.GetSkillValue` keeps per-troop power calculations untouched. Hero stand-ins are left alone (`Hero.GetSkillValue` returns 0 on null skill data). The troop + party are logged, which names the source mod. Runtime twin of `ClanUpdateStrengthNRESafetyPatch` (same root, save-load path). Does not depend on TOR. Listed on the Crash Fixes tab (id `effective_party_leader_skills`). |
| **`ThumbnailReleaseCacheNRESafetyPatch`** | Prefix + finalizer on the private `ImageIdentifierTextureProvider.ReleaseCache()` (`TaleWorlds.MountAndBlade.GauntletUI`), reached from that class's **finalizer** — i.e. on the .NET GC finalizer thread. `ReleaseCache` dereferences the static `ThumbnailCacheManager.Current` with no null-check, and the engine nulls that static while tearing a session down (`ThumbnailCacheManager.ClearManager` destroys every registered cache, clears `_thumbnailCaches`, then sets `Current = null`). Any item/character icon provider still on the finalizer queue at that moment hits a dead static; since there is no catch site above the finalizer thread, the process dies instantly with a two-frame stack naming no mod (seen: 1.4.6, ~60 mods, no TOR). Timing-dependent — it fires when exiting to the main menu, loading another save or quitting, and the more icons the session showed (large inventories, encyclopedia, item-adding mods) the more finalizers are queued. The prefix skips the release once `Current` (or its cache list — `ClearManager` clears the list *before* the static, and the finalizer thread runs concurrently) is gone; nothing is leaked, the caches it would release are already destroyed. The finalizer swallows **only** a `NullReferenceException` that loses the same race. No player toast: this runs on the finalizer thread during teardown, so it logs to `crashdoctor.log` only. Types resolved by name (those assemblies live in `Modules\Native\bin`). Does not depend on TOR. Listed on the Crash Fixes tab (id `thumbnail_release_cache`). |
| **`RebellionMissingCultureTemplatesSafetyPatch`** | Prefix on `RebellionsCampaignBehavior.StartRebellionEvent(Settlement)`. When a town rebels, `CreateRebelPartyAndClan` reads `settlement.Culture.RebelliousHeroTemplates` on its very first line and passes the list straight to `GetRandomElement`, with no null-check on either — so a settlement whose `Culture` did not resolve, or a `CultureObject` whose template list is null, NREs the whole daily settlement tick (BUTR `E50HP3`, 1.4.5, 48 mods incl. an `e1.5.2`-era culture mod on a `v1.4.5` game). `RebelliousHeroTemplates` is assigned in exactly one place, `CultureObject.Deserialize`, so a culture that never completed XML deserialisation keeps the default null; an **empty** list is the same fault one level down, because `Extensions.GetRandomElement` returns `default(T)` on `Count == 0` and the null then surfaces inside `CreateRebelHeroInternal` — the guard covers all three. Deliberately gated on the **caller**, not on the throwing method: swallowing inside `CreateRebelPartyAndClan` would let the rest of `StartRebellionEvent` run, converting the garrison into rebels and broadcasting `RebellionFinished` for a rebellion that produced no rebel clan. Skipping the event writes **nothing** to the save — the behaviour's `SyncData` dictionaries are only touched inside the method we refuse to enter — and `Town.InRebelliousState` is set separately from loyalty, so nothing desyncs. The town keeps its owner, garrison and militia and is rolled for rebellion again the next day. Intervenes only on positive proof; any unreadable state runs vanilla. Method and property verified present on 1.2 / 1.3.15 / 1.4.5. Does not depend on TOR. Listed on the Crash Fixes tab (id `rebellion_missing_culture_templates`). |
| **`OffspringBodyPropertiesNRESafetyPatch`** | Prefix on `Helpers.CharacterHelper.GetDynamicBodyPropertiesBetweenMinMaxRange(CharacterObject)`. Its first line is `character.BodyPropertyRange.BodyPropertyMin` with no check, and `BasicCharacterObject.BodyPropertyRange` is a **virtual `MBBodyProperty` reference** populated only during XML deserialisation (with a `RegisterPresumedObject` fallback when the file declares no face data) — so a `CharacterObject` a mod builds in **code** has it null. `DefaultHeroCreationModel.GetCharacterTemplateForOffspring` hands back the **father's or mother's own** `CharacterObject` as the newborn's template, so one modded parent kills the daily hero tick at every delivery they are part of (client crash `68325555`, 1.4.5, 68 mods, via `HeroCreator.DeliverOffSpring` ← `PregnancyCampaignBehavior.CheckOffspringToDeliver`). The prefix substitutes the engine's own `DynamicBodyProperties.Default` (weight 0.5, build 0.5 — the exact midpoint of the range it would have drawn from). Safe because there is **no** working path with a null character or range (the deref *is* the first statement), the method is a pure function that mutates nothing, and all three consumers read only `.Weight`/`.Build` — `.Age` is read by nobody. Method, `DynamicBodyProperties.Default` and `BodyPropertyRange` verified present on 1.2 / 1.3.15 / 1.4.5. **Not** covered: `HeroCreator` also reads `BodyPropertyRange.HairTags` directly when creating a notable's relative — same root, different throw site, needs its own guard if it ever appears in a report. Does not depend on TOR. Listed on the Crash Fixes tab (id `offspring_body_properties`). |
| **`RebelClanNotRegisteredSafetyPatch`** | Prefixes on `RebellionsCampaignBehavior.DailyTickClan(Clan)` and `DailyTickSettlement(Settlement)`. A clan enters the behaviour's private `_rebelClansAndDaysPassedAfterCreation` dictionary **only** through `CreateRebelPartyAndClan`, and leaves it in two places — `OnClanDestroyed`, and the 30-day conversion, which also clears `IsRebelClan`. But two reads in the daily tick index that dictionary for any clan merely *flagged* `IsRebelClan`, unguarded: the landless-clan wind-down in `DailyTickClan` (its first block *is* `ContainsKey`-guarded; its second is not) and the loyalty boost in `DailyTickSettlement`. The flag is saved on the **clan** and the dictionary on the **behaviour**, so a clan another mod created and flagged itself — or left in the save after being uninstalled (reported for Warlord's claimant clans, BUTR `R9TDAK`, 1.4.7) — is flagged but absent and `KeyNotFoundException` repeats **every day, once per clan**, forever. Under BLSE that is not a crash but a daily "continue?" prompt. The prefix skips the vanilla method for that one clan; a prefix rather than a finalizer because swallowing afterwards would leave the hero loop half-run, having already executed or removed some heroes. Cost is near zero: `DailyTickSettlement`'s first block is itself gated on `!OwnerClan.IsRebelClan` so only the loyalty boost is lost, and `DailyTickClan`'s first block was a no-op by definition. Deliberately does **not** register the clan instead — that would enrol another mod's clan in vanilla's rebel lifecycle, which renames it at 30 days and removes its landless heroes at 90. Dictionary read reflectively (private), field and both methods verified on 1.2 / 1.3.15 / 1.4.5. Does not depend on TOR. Listed on the Crash Fixes tab (id `rebel_clan_not_registered`). |
| **`SafetyNetMessenger`** | Five-language toast helper used by the guards above. Picks EN/RU/ZH/ZHT/TR by `BannerlordConfig.Language` (Traditional Chinese falls back to Simplified, then English), amber (catch) or green (cleanup), one toast per category per 60 s. The overload that takes the caught exception appends the culprit mod via `ModBlame` and folds the mod name into the rate-limit key, so two different mods tripping the same guard are two different toasts. (Always on — infrastructure.) |
| **`ModBlame`** | Attributes a caught exception to the mod that threw it, for the toast above. Walks the exception's stack, takes the **topmost** non-infrastructure frame — the frame the throw actually happened in — and reports it **only** when that frame belongs to a mod; a game-code throw yields no name at all. The label is the module's declared name and version from the `SubModule.xml` of the folder that ships the throwing assembly (resolved from the loaded assembly's path, so it works for both `Modules\` and Workshop installs), cached per assembly. Never throws — it runs inside the guards' finalizers. (Always on — infrastructure.) |

These guards are generic — TOR-specific ones (marked **TOR**) self-skip via
`AccessTools.TypeByName` when TOR isn't loaded (shown as *Skipped* on the tab),
and the rest trigger regardless of which third-party mod caused the dangling
reference. All of them need the Bannerlord.Harmony module to run; with it off
they're hidden and the core crash analysis still works. (The whole group sits
under the Crash Fixes tab; there is no separate "master" toggle in Settings.)

> **Deferred install (important).** Some targets (the UI-screen guard's view
> models, `EncounterGameMenuBehavior`) have a static initializer that reads
> `GameTexts` — which doesn't exist yet at the main menu. Patching them there
> would let the JIT run that initializer early, throw an NRE, and have .NET cache
> a `TypeInitializationException` for the whole process — poisoning every later
> campaign load. So those patches **defer** until a game session exists
> (`OnGameStart` / `OnAfterGameInitializationFinished`), when the text manager is
> live. `SafetyNetCoordinator.RetryPending()` applies anything that deferred.

---

## Crash bundle export

The **Export** button on the Crashes tab now produces a `.zip`:

```
crashdoctor_unrecognised_<ts>.zip   (when no rule matched)
crashdoctor_bundle_<ts>.zip          (when one or more rules matched)
├── READ_ME_FIRST.txt    bilingual instructions: send the whole zip
├── diagnosis.txt        text summary (RAM / GPU / modules / diagnoses)
├── crash/               full ProgramData\...\crashes\<ts>\ folder
│   ├── crash_tags.txt
│   ├── module_list.txt
│   ├── BannerlordConfig.txt
│   ├── engine_config.txt
│   ├── LauncherData.xml
│   ├── rgl_log_*.txt
│   ├── watchdog_log_*.txt
│   └── (mini-dump if < 100 MB)
└── crashdoctor.log      our own log
```

Files larger than 100 MB are skipped (full-memory dumps would be useless without
symbols anyway). The zip uses `FileShare.ReadWrite` so it doesn't fail if
Bannerlord still holds the log handle. The old text-only diagnosis was useless
on unrecognised crashes — Telegram support team needs the raw artifacts to add
a rule.

---

## Installation

1. Subscribe on the [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3717685432).
2. Bannerlord launcher → enable **Crash Doctor** → Play.
3. Main menu → **Crash Doctor** button.

Crash Doctor places itself at the **bottom** of the mod list automatically, so its
checks observe the final, fully-applied state of every other mod — no need to drag
it down by hand. One install also auto-detects your game version and runs on **1.2.x,
1.3.x and 1.4.x** from the same subscription.

**No dependencies.** Does not require Harmony, ButterLib, BLSE, or MCM.
Designed to run even when other mods are broken.

---

## Harmony module by game version

Crash Doctor itself loads with **no extra mods** — it ships its own Harmony
runtime, so the crash analysis and the System Tune-Up work even on a bare
install. The **live anti-crash protections** (the Crash Fixes tab) are the only
part that needs the separate **Bannerlord.Harmony** module enabled. When it's off,
the Crash Fixes tab shows one-click **Download Harmony** buttons (Steam + Nexus)
that point at the build matching your game version.

Harmony comes in **two builds split by game version** — install the one that
matches YOUR Bannerlord:

| Your Bannerlord | Which Harmony | Steam Workshop | Nexus (no Steam needed) |
|---|---|---|---|
| **1.2.x** (1.2.12 and older) | Harmony **v1.0.0 – v1.2.12** | [Workshop 3613449471](https://steamcommunity.com/workshop/filedetails/?id=3613449471) | [Harmony, mod 2006](https://www.nexusmods.com/mountandblade2bannerlord/mods/2006?tab=files) → **Optional files** |
| **1.3.x** (e.g. 1.3.15) | Harmony (current) | [Workshop 2859188632](https://steamcommunity.com/workshop/filedetails/?id=2859188632) | [Harmony, mod 2006](https://www.nexusmods.com/mountandblade2bannerlord/mods/2006?tab=files) → main file |
| **1.4.x** (e.g. 1.4.5) | Harmony (current) | [Workshop 2859188632](https://steamcommunity.com/workshop/filedetails/?id=2859188632) | [Harmony, mod 2006](https://www.nexusmods.com/mountandblade2bannerlord/mods/2006?tab=files) → main file |

> The **current** Harmony (Workshop 2859188632 / Nexus main file) supports game
> **v1.3.4 and newer only** — it does **not** run on 1.2.x. On 1.2.x you must use
> the separate **"v1.0.0 – v1.2.12"** build. Nexus downloads need a free Nexus
> account.

**Manual install (without Steam):** unpack the download so you end up with
`<Bannerlord>\Modules\Bannerlord.Harmony\SubModule.xml` (and
`bin\Win64_Shipping_Client\0Harmony.dll` inside it). Then in the launcher tick
**Bannerlord.Harmony** and move it **above** Crash Doctor in the list.

---

## After the next crash

When the game asks whether to create a dump — click **Yes**. Wait for the log
window, close it, restart the game, open Crash Doctor — your crash will be
analyzed. Click **No** and the mod has nothing to read.

If no rule matches your crash, click **Export** in the Crashes tab and send the
resulting `.zip` to the Telegram channel below — we add a rule and your next
same-kind crash gets recognized for everyone.

---

## If the game won't launch

After lowering Texture / Shader / Shadow Quality (either via Crash Doctor's
advice or directly in Options → Graphics) the game can crash on the imperial-
soldier splash. The shader cache was built against the old settings; the new
settings need a fresh build. Crash Doctor's M2.2 module catches this
automatically when you next open the menu, but if the game won't even start
the in-game UI is unreachable.

### Recovery steps

Follow [`docs/Recovery_If_Game_Wont_Start_EN.md`](docs/Recovery_If_Game_Wont_Start_EN.md):

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

State (history JSON, `.reg` backups, `engine_config_snapshot.txt`,
`ignored_recommendations.json`) lives in
`<Documents>\Mount and Blade II Bannerlord\CrashDoctor\state\` — Steam re-validation
of the Workshop folder would otherwise wipe it.

---

## Privacy

- No internet calls. The mod never connects to anything.
- No data collection.
- Crash data stays on your machine. You explicitly **Export** it (a `.zip`)
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
2. Click **Export** — you get a `.zip` with the full crash folder + diagnosis +
   bilingual readme.
3. Send the `.zip` to the Telegram channel:
   [https://t.me/CodeRickTg](https://t.me/CodeRickTg)

We add a YAML rule to the catalog, push an update, and your next same-kind
crash gets a diagnosis.

---

## Changelog

- English: [`CHANGELOG_EN.md`](CHANGELOG_EN.md)
- Russian: [`CHANGELOG.md`](CHANGELOG.md)

## License

MIT. See [`LICENSE`](LICENSE).

The catalog of crash rules in `Mod/CrashDoctor/ModuleData/rules/*.yaml` is
freely usable in derivative diagnostic tools — please credit
[`docs/crash_catalog_2026-05-02.txt`](docs/crash_catalog_2026-05-02.txt) as the
source if you republish.

### Third-party code

The built-in save-cleaner subsystem (`Saves/Cleaner/` in the source tree;
runs behind the **Saves** tab and the `Ctrl+D` in-campaign hotkey) is
adapted from
[**JungleDruid/bannerlord-save-cleaner**](https://github.com/JungleDruid/bannerlord-save-cleaner)
(MIT licence, copyright © 2025 JungleDruid). The original MIT licence
text is included in this repository as
[`LICENSE-SaveCleaner.txt`](LICENSE-SaveCleaner.txt). Each adapted source
file carries an in-header note pointing back at the upstream project.

---

## Build from source

```
dotnet build CSharpMod/CrashDoctor/CrashDoctor.csproj -c Release
```

The `OutputPath` writes the DLL directly into your Steam Workshop folder
(`C:\Program Files (x86)\Steam\steamapps\workshop\content\261550\3717685432\bin\Win64_Shipping_Client\`).
`AfterTargets="Build"` deploys SubModule.xml, GUI, and ModuleData files. A
`StripPdbFromWorkshop` target removes `.pdb` / `.bat` / `.log` /
`PIRACY_LIMITATIONS.md` from the deployed folder. A `SyncSubModuleXmlVersion`
target (BeforeTargets="Build") keeps `<Version value="vX.Y.Z" />` in
`SubModule.xml` synced with the csproj `<Version>` so the launcher always sees
the same version as the DLL. XSD validation of SubModule.xml runs against
vendored BUTR schemas.

```
dotnet test tests/CrashDoctor.Tests/CrashDoctor.Tests.csproj
```

Tests cover YAML rule parsing, crash collector parsing, BUTR HTML
crash-report parsing, rule engine matching against fixture crashes, and a
pre-flight gate that loads every YAML in `ModuleData/` through YamlDotNet to
catch syntax bugs before they hit production.

---

# Crash Doctor — Анализатор крашей и Tune-Up для Bannerlord

Standalone-мод диагностики для **Mount & Blade II: Bannerlord**. Читает дампы
крашей и человеческим языком объясняет что чинить, плюс в один клик применяет
типовые твики Windows / драйверов / движка.

Подходит для **любой модной сборки** — ванила, TOR (The Old Realms), Diplomacy,
Calradia Expanded, RBM, Banner Kings и т.д. Без интернета,
без зависимостей.

> **Steam Workshop:** [3717685432](https://steamcommunity.com/sharedfiles/filedetails/?id=3717685432)
> **Совместимость:** Bannerlord **v1.2.x – v1.4.x** — в одной установке есть
> загрузчик, который при запуске определяет версию игры и подгружает подходящую
> сборку, поэтому одна и та же подписка работает на 1.2.x, 1.3.15 и 1.4.5. Работает
> и со Steam, **и** с ручной (не-Steam) установкой (Game Pass / MS Store по-прежнему
> не поддерживаются — у них другие бинарники игры). Модуль Bannerlord.Harmony нужен
> для «живых» защит; ядро (анализ крашей) грузится и работает и без него.

## Что делает

Восемь вкладок в главном меню — Диагностика крашей, Настройка системы, Журнал,
Сейвы, Моды, **Фиксы крашей**, **Предотвращено**, Настройки. (Раньше была «Оптимизация»; убрана
2026-05-10 после long-run тестирования — архитектурный потолок Bannerlord не
даёт стабильно ускорить поздние кампании через throttle-патчи.)

Вкладка **«Фиксы крашей»** показывает все «живые» защиты от вылетов, которые
ставит мод: у каждой галочка вкл/выкл, понятное описание и статус (Активен /
Выключен / Здесь не требуется — нет нужного мода / Ошибка). Все включены по умолчанию;
любой фикс можно отключить по отдельности, если он мешает. Кнопки **«Включить все»** /
**«Выключить все»** переключают сразу все применимые фиксы (фиксы для неустановленных
модов не трогаются — у них статус «Здесь не требуется»). Выбор сразу сохраняется.
Фиксы **сгруппированы по разделам** — «Бой и миссии», «Карта кампании», «Загрузка и
сохранение», «Интерфейс» и «The Old Realms (TOR)», — чтобы сразу видеть, за что
отвечает каждая группа; **раздел TOR полностью скрывается, если The Old Realms не
установлен** (и счётчик «Активных: X из Y» скрытые TOR-фиксы не считает).

Вкладка **«Предотвращено»** — журнал вылетов, которые мод реально погасил. Каждое
срабатывание защиты показывает в игре однострочную подсказку, и она исчезает через
несколько секунд; журнал её сохраняет. Одна строка на каждую отдельную проблему: счётчик
повторов, реальная и игровая дата, названный мод (если его удалось определить) и — самое
полезное — **на каких игровых данных** всё произошло: боец и его отсутствующая культура,
отряд, герой, клан, поселение, армия, построение, ключ метаданных сейва. По id объекта
обычно сразу видно, из какого мода пришли битые данные, — открывать `crashdoctor.log` не
нужно. Журнал накопительный и переживает перезапуск: он лежит в «Документах», а не в папке
мода, поэтому обновления мода его не стирают. **«Скопировать отчёт»** кладёт всё в буфер
обмена (можно сразу отдать автору проблемного мода), **«Очистить журнал»** — стирает.
Тот же список доступен **не выходя из кампании** — горячая клавиша `Ctrl+Alt+D`.

Вкладка **«Моды»** показывает установленные моды **в том же порядке, что и в
лаунчере** (порядок загрузки), с пометками конфликтов / недостающих зависимостей /
порядка загрузки; проблемные моды подсвечены, но больше не перетасовывают список.
Каждый активный мод дополнительно проверяется на **совместимость с запущенной сборкой
игры** — мод, обращающийся к типам, которых в этой версии Bannerlord нет, собран под
другую версию и помечается красным «Несовместим со сборкой» ещё до вылета. Проверяется
только код, реально загруженный под текущую версию (моды с отдельной сборкой под каждую
версию ложно не помечаются), а каркасные библиотеки на несколько версий сразу (Harmony,
ButterLib, MCM, UIExtenderEx, BLSE) исключены. Цвета: красный — несовместимость сборки,
жёлтый — конфликт Harmony / порядок загрузки, оранжевый — нет зависимости, серый — выключен.

- **Диагностика крашей** — **143 YAML-правила** под GPU/DirectX (включая авторитетный
  детект iGPU из rgl_log + whitelist карт где DxDiag врёт VRAM), native runtime,
  повреждённые `.tpac` ассеты, save / late-game, mission / engine (NRE в диалогах,
  team-index шторм), TOR (включая Naval DLC + TOR conflict, Assimilation
  IndexOutOfRange), мод-стек (TOR + 5+ неофициальных), BUTR-стек, hardware,
  модули (включая аудит графа зависимостей SubModule.xml). Парсер модулей
  переживает ранние крэши через fallback на `[Runtime][Arguments]` когда секция
  «Used Modules» отсутствует в crash_tags.txt.
- **Настройка системы (Tune-Up)** — **27 модулей** полу-автоматической ремедиации.
  Каждый: Detect → Preview → Apply / Игнорировать / Rollback. Реестровые записи
  сохраняются в `.reg`-бэкапы в Documents до изменения. Кнопка **Игнорировать**
  скрывает карточку до тех пор пока её состояние реально не изменится. Карточки про
  шейдеры и файл подкачки (M1.1 подкачка, M2.1 кэш шейдеров, M2.2 пересборка после
  смены графики, M2.5 TdrDelay, M2.7 перенос `%TEMP%`, M3.3 TOR-несовместимые
  значения `engine_config.txt`) показываются **только если установлен The Old Realms** — они нужны из-за огромного набора шейдеров TOR; на
  ванили и других сборках не отвлекают. Ручная кнопка **«Очистить кэш шейдеров»** —
  исключение, доступна всем (полезна и после смены драйвера).
- **Журнал** — каждое Apply/Rollback с таймстампом и откатом.
- **Сейвы** — читает JSON-заголовок каждого `.sav` в папке Game Saves и сверяет
  список модов с текущим `LauncherData.xml`, **не загружая кампанию**. На
  карточке: день, герой, золото, отряд, и расхождения по модам — какие моды
  записаны в сейве, но не активны (включить в один клик); какие записаны, но
  вообще не установлены (скопировать IDs); какие активны, но не были в сейве
  (выключить); разные версии. Плюс эвристики: размер сейва ≥50 МБ намекает
  на orphan-parties (рекомендует Save Cleaner #7763); mismatch мажор-версии
  Bannerlord (1.2.x сейв в 1.3.x игре); Iron Man (всегда советует backup
  перед load); список известных мод-зависимостей (PlayerSettlement,
  BannerKings, TOR_Core, Dramalord, Diplomacy и т.д.) — если такой мод записан
  в сейве, но не установлен сейчас, выдаём ссылку где его взять. Late-game
  эвристика: день ≥ 700 + размер ≥ 25 МБ предупреждает о crash'ах от мёртвых
  ссылок на кланы (KingdomDecision NRE) в долгих кампаниях. Кнопки: включить/
  выключить моды, открыть Save System Fix #1925, открыть Save Cleaner #7763,
  `.bak`, проводник, удалить (Корзина). Вердикт соразмерен, без паники: **красное**
  «загрузка почти наверняка упадёт» — только когда отсутствует мод, реально
  хранящий данные в сейве (список выше: BannerKings, PlayerSettlement и т.п.); все
  прочие расхождения (косметика, перевод, лишний мод, разница версий) — **жёлтое**
  предупреждение «игра предупредит, но сейв должен загрузиться — сделай копию».

## Экспорт нераспознанного краша

Кнопка **Экспорт** на вкладке Crashes теперь делает `.zip` с полной папкой
краша (rgl_log + crash_tags + module_list + watchdog + minidump до 100 МБ) +
наш `diagnosis.txt` + двуязычный `READ_ME_FIRST.txt` с инструкцией. Отправь
архив целиком в [https://t.me/CodeRickTg](https://t.me/CodeRickTg) — поддержка
добавит правило, в следующем апдейте такой краш будет распознаваться.

## Установка

1. Подпишись в [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3717685432).
2. Лаунчер Bannerlord → включи **Crash Doctor** → Play.
3. Главное меню → кнопка **Crash Doctor**.

## Какой Harmony нужен для вашей версии игры

Сам Crash Doctor запускается **без дополнительных модов** — он несёт свой
Harmony внутри, поэтому анализ крашей и настройка системы (Tune-Up) работают
даже на чистой установке. Отдельный модуль **Bannerlord.Harmony** нужен только
для «живых» защит от вылетов (вкладка «Фиксы крашей»).

У Harmony **две сборки, разделённые по версии игры** — ставьте ту, что
соответствует ВАШЕМУ Bannerlord:

| Ваш Bannerlord | Какой Harmony | Steam Workshop | Nexus (без Steam) |
|---|---|---|---|
| **1.2.x** (1.2.12 и старше) | Harmony **v1.0.0 – v1.2.12** | [Workshop 3613449471](https://steamcommunity.com/workshop/filedetails/?id=3613449471) | [Harmony, мод 2006](https://www.nexusmods.com/mountandblade2bannerlord/mods/2006?tab=files) → раздел **Optional files** |
| **1.3.x** (например 1.3.15) | Harmony (текущий) | [Workshop 2859188632](https://steamcommunity.com/workshop/filedetails/?id=2859188632) | [Harmony, мод 2006](https://www.nexusmods.com/mountandblade2bannerlord/mods/2006?tab=files) → основной файл |
| **1.4.x** (например 1.4.5) | Harmony (текущий) | [Workshop 2859188632](https://steamcommunity.com/workshop/filedetails/?id=2859188632) | [Harmony, мод 2006](https://www.nexusmods.com/mountandblade2bannerlord/mods/2006?tab=files) → основной файл |

> **Текущий** Harmony (Workshop 2859188632 / основной файл на Nexus) работает
> только на игре **v1.3.4 и новее** — на 1.2.x он **не запустится**. Для 1.2.x
> нужна отдельная сборка **«v1.0.0 – v1.2.12»**. Для скачивания с Nexus нужен
> бесплатный аккаунт.

**Ручная установка (без Steam):** распакуйте так, чтобы получилось
`<Bannerlord>\Modules\Bannerlord.Harmony\SubModule.xml` (и внутри
`bin\Win64_Shipping_Client\0Harmony.dll`). Затем в лаунчере включите
**Bannerlord.Harmony** и поднимите его **выше** Crash Doctor в списке.

## Если игра не запускается

После понижения Texture/Shader Quality (через Crash Doctor или вручную в
Options → Graphics) игра может упасть на splash-screen — кэш шейдеров под
старые настройки. M2.2 ловит это автоматически в игре, но если игра уже
не стартует — внутриигровой UI недоступен.

### Восстановление вручную

См. [`docs/Recovery_If_Game_Wont_Start_RU.md`](docs/Recovery_If_Game_Wont_Start_RU.md).

## Сообщить о нераспознанном краше

Crashes tab → Export → отправь `.zip` в Telegram-канал
[https://t.me/CodeRickTg](https://t.me/CodeRickTg). Добавим правило в каталог и
выпустим апдейт.

## Changelog

- Русский: [`CHANGELOG.md`](CHANGELOG.md)
- English: [`CHANGELOG_EN.md`](CHANGELOG_EN.md)

## Лицензия

MIT. См. [`LICENSE`](LICENSE).

### Сторонний код

Подсистема встроенной очистки сейвов (`Saves/Cleaner/` в исходниках;
работает за вкладкой **Сейвы** и горячей клавишей `Ctrl+D` в кампании)
адаптирована из мода
[**JungleDruid/bannerlord-save-cleaner**](https://github.com/JungleDruid/bannerlord-save-cleaner)
(лицензия MIT, copyright © 2025 JungleDruid). Текст оригинальной
MIT-лицензии включён в репозитории как
[`LICENSE-SaveCleaner.txt`](LICENSE-SaveCleaner.txt). В каждом
адаптированном исходнике есть header-комментарий со ссылкой на
оригинальный проект.
