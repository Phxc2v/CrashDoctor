# Crash Doctor — Bannerlord Crash Analyzer & Tune-Up

A standalone diagnostic mod for **Mount & Blade II: Bannerlord**. Reads your crash
dumps, explains in plain English what went wrong, and applies common Windows /
driver / engine fixes in one click.

Designed for **any modded setup** — vanilla, TOR (The Old Realms), Diplomacy,
Calradia Expanded, RBM, Banner Kings, anything. No internet, no telemetry,
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

Seven tabs from the Bannerlord main menu — Crashes, System Tune-Up, History,
Saves, Mods, **Crash Fixes**, Settings. (A prior "Optimization" tab was removed
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

The **Mods** tab lists installed mods in the **same order as your launcher** (load
order), with conflict / missing-dependency / load-order badges; problem mods are
highlighted but no longer reshuffle the list.

### 🔬 Crash diagnosis
Scans `C:\ProgramData\Mount and Blade II Bannerlord\crashes\` and the BUTR HTML
crash reports if you have BLSE/ButterLib. Matches every crash against **99 YAML
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
**26 semi-automatic remediation modules**. Each card: Detect → Preview (diff)
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
| **M3.2** | Detection: Documents on OneDrive (incl. pinned mode that breaks save reads) | no | no | — |
| **M3.3** | `engine_config.txt` → terrain_quality fix; auto-clears shader cache | no | yes | yes |
| **M3.6** | Mod-dependency audit — missing deps / version mismatches / duplicates / conflicts, reported in plain "what's wrong → what to do" lines | no | no | — |
| **M3.7** | Unblock DLLs (NTFS Zone.Identifier ADS) for every installed mod | no | no | — |
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
saved them from a crash.

**Every one of these is listed on the Crash Fixes tab** with its own on/off
checkbox and a live status badge — turn off just the one that misbehaves on
your setup. All on by default; off-choices persist (diff-only) across restarts.
A shared `PatchCatalog` is the single source of truth feeding both the installer
(`SafetyNetCoordinator`) and the UI, so the list, install state and toggles can
never drift.

| Fix | What it does |
|---|---|
| **`WageModelNRESafetyPatch`** (TOR) | Three guards on `TOR_Core.Models.TORPartyWageModel` (`CalculateCharacterWageCache`, `GetCharacterWage`, `GetTotalWage`). Returns wage = 0 instead of crashing on a null-culture character. |
| **`FoodConsumptionNRESafetyPatch`** (TOR) | Finalizer on `TORMobilePartyFoodConsumptionModel.CalculateDailyFoodConsumptionf`. Same dangling-character source, on the food-consumption tick. |
| **`AiHourlyTickNRESafetyPatch`** | Reflection-based finalizer on every `AiHourlyTick` in `TaleWorlds.CampaignSystem.CampaignBehaviors.AiBehaviors` (`AiPatrolling`, `AiVisitSettlement`, `AiMilitia`, …). The offending party skips that tick; the game continues. |
| **`IssueBaseNRESafetyPatch`** | Prefix sanitizer + finalizer on `IssueBase.AlternativeSolutionEndWithSuccess`. Scrubs `AlternativeSolutionSentTroops` so the inner `FindAll` lambda never sees a null `Character`; the issue retries next day on a clean roster. |
| **`VictoryCheerAVSafetyPatch`** | Guard on `AgentVictoryLogic.ChooseWeaponToCheerWithCheerAndUpdateTimer` — validates the agent *before* the cheer, so a freed/dangling agent (common with combat overhauls like RBM or summon/raise-dead mods) simply skips it; managed exceptions from corrupt equipment are caught via a reverse-patch wrapper. The end-of-battle AccessViolation is prevented up front — an AV is uncatchable on the game's .NET runtime. |
| **`BehaviorFlankAiWeightSafetyPatch`** | Finalizer on vanilla `BehaviorFlank.GetAiWeight` — returns 0 priority instead of an NRE when the targeted formation vanishes mid-calculation. |
| **`InventoryUseItemSafetyPatch`** (TOR) | Transpiler + finalizer on `SPItemVMExtension.ExecuteUseItem`: swaps the brittle `Type.GetType` for an all-assemblies resolver (fixes the enchantment-book "choose a hero" popup not opening) and swallows any other inventory-use-script exception. |
| **`UICommandSafetyPatch`** | Universal finalizer on the Gauntlet `ViewModel.ExecuteCommand` choke point — a misbehaving menu/UI button shows a message instead of crashing the game. |
| **`GarrisonStarvingNullSafetyPatch`** | Prefix on `Helpers.SettlementHelper.IsGarrisonStarving`: returns `false` for a null settlement (orphaned garrison) instead of letting `Clan.AfterLoad` dereference it on save load. Installed in `OnGameStart` (before `OnGameLoaded`) so it guards the very first load. |
| **`TorMountStatusEffectSafetyPatch`** (TOR) | Signature-aware guard on `AgentDrivenPropertiesExtensions.SetDynamicMountMovementProperties` — re-syncs the mount base values (older TOR) or just swallows the `ArgumentException` (newer TOR) so a mounted unit doesn't crash the battle every frame. Inert on TOR builds that already fixed the root cause. |
| **`TorAbilityAiCastNRESafetyPatch`** (TOR) | Guard on TOR's ability AI-cast path (`CalculateAICastMatrixFrame`): when RTS/free (commander) camera detaches the hero, a spell cast is routed through the AI path that expects data the hero doesn't have; the spell is cast as the hero instead of crashing the battle. |
| **`SellPrisonersUnderflowSafetyPatch`** | Finalizer on `SellPrisonersAction.ApplyInternal` — swallows the `MBUnderFlowException` when a desynced prison roster goes below zero during a town auto-sell; the party skips that one sale. |
| **`EncounterMenuInitSafetyPatch`** | Prefix + finalizer on `EncounterGameMenuBehavior.game_menu_encounter_on_init`. When a save made mid-encounter loads without a restored `PlayerEncounter` (`Current` and `MainParty.MapEvent` both null), vanilla init dereferences the null encounter (`StartBattle`/`Update`) and crashes the load; instead the player is returned to the campaign map via `GameMenu.ExitToLast()`. *Deferred to game start* — the target type's static init reads `GameTexts`, so patching it at the main menu would poison it (see note below the table). |
| **`ColumnFormationSpawnSafetyPatch`** | Prefix on `ColumnFormation.GetLocalPositionOfUnitOrDefault(int)`. Vanilla reads element `[1]` of the column's vanguard-file position list unconditionally — an `ArgumentOutOfRangeException` that kills the whole battle tick when reinforcements spawn into a column formation with no soldiers left at its head (common with marching-reinforcement mods like Immersive Battlefields or RTS Camera's column order). The guard returns `null` instead, so the caller falls back to the default spawn frame. |
| **`TorAudioRegisterSoundSafetyPatch`** (TOR) | Finalizer on `TOR_Core.Audio.TORAudioManager.RegisterSound`, which builds NAudio.Vorbis with no try/catch. When a .NET library NAudio needs (`System.Memory`, normally provided by the game runtime or ButterLib) can't load on the player's setup, the OGG ctor throws `FileNotFoundException` and crashes the campaign — e.g. a TOR music event on the hourly tick while walking the map. The guard swallows it and returns failure, so the sound is skipped (`CreateSoundInstance` returns null, which `PlayMusic` already null-checks) and the game continues. The matching rule `tor.audio_dependency_missing` explains the missing-library root cause and the fix (verify game files / install ButterLib). |
| **`SiegeLeaderlessPartyNRESafetyPatch`** | Prefix on `SiegeEventManager.StartSiegeEvent(Settlement, MobileParty)`. When the besieging party has no leader hero (`LeaderHero == null`) the default `EncounterModel.GetLeaderOfSiegeEvent` returns null and `BesiegerCamp.AddSiegePartyInternal` dereferences it. Fires only for a leaderless besieger (autonomous Bandit-Militias-class parties); the impossible siege simply doesn't start, no state is half-built. Normal lord sieges are untouched. |
| **`MovementOrderIsApplicableNRESafetyPatch`** | Finalizer on vanilla `MovementOrder.IsApplicable(Formation)`. During siege auto-deploy (`SiegeDeploymentHandler.AutoDeployTeamUsingTeamAI` → `Team.Tick` → `FormationAI.FindBestBehavior` → `PrecalculateMovementOrder` → `CreateNewOrderWorldPositionMT`) the AI re-checks each formation's movement order; `IsApplicable` switches on the order kind and dereferences `TargetEntity`/`TargetFormation`/`_targetAgent` with no null guard. A formation carrying an order whose target has gone null (destroyed machine, emptied formation, removed agent between phases) NREs the whole mission tick before the assault starts. Returns `__result = false` on the NRE — exactly what the method returns for a destroyed target, so the caller drops the stale order and falls back to a default world position. Swallows only NRE; self-heals next tick. Does not depend on TOR. |
| **`TorPartyUpgraderNRESafetyPatch`** (TOR) | Finalizer on `TORPartyUpgraderCampaignBehavior.UpgradeReadyTroops(PartyBase)`. TOR's daily auto-upgrade filters the roster with `!t.Character.IsHero && t.Character.UpgradeTargets.Length != 0`; a broken troop (null `Character`/`UpgradeTargets`) crashes the whole daily tick. The finalizer isolates it to one party, which skips its upgrade; other parties continue. |
| **`VictoryReactionRetreatNRESafetyPatch`** | Finalizer on `AgentVictoryLogic.SetTimersOfVictoryReactionsOnRetreat(BattleSideEnum)`. The end-of-battle retreat-cheer selection filters agents with `agent.IsHuman && agent.IsAIControlled && agent.Team.Side == side`; an AI human agent with a null `Team` (mid-battle summon/raise-dead with no team assigned) NREs the mission tick. Swallows only the NRE — the load-bearing side effects run before it, so only the cosmetic cheer is skipped. |
| **`PartyTrainingNRESafetyPatch`** | Finalizer on `MobilePartyTrainingBehavior.OnDailyTickParty(MobileParty)`. The training-XP model (`DefaultPartyTrainingModel.GetEffectiveDailyExperience`, via TOR's override) reads per-troop fields; a troop with invalid data (e.g. null culture) NREs the daily tick. The affected party skips its training; the game continues. Backstop to the root fix below. |
| **`SimulatedBattleHitNRESafetyPatch`** | Finalizer on the private `MapEvent.SimulateSingleTroopHit(BattleSideEnum, …)`. The engine auto-resolves AI-vs-AI map battles every tick; `MapEventSide.ApplySimulatedHitRewardToSelectedTroop` dereferences the striker troop's `FirstBattleEquipment` as its first statement. A **dangling troop** (a `CharacterObject` that no longer resolves — classic leftover after a custom-troop mod like Special Troops Plus / FireArchers is removed, once AI lords have recruited those units) makes the striker null and NREs the whole campaign-map tick. The finalizer drops just that one simulated hit (`__result = false`); the `SimulateBattleRound` loop resolves the battle from the remaining valid troops. Root fix is `DanglingTroopCleanerBehavior` (below) + a re-save. |
| **`CharacterDataFallbackPatch`** (TOR) | Single-point root fix for the "malformed troop" cascade: postfixes on the `CharacterObject.Culture`, `CharacterObject.UpgradeTargets` **and `CharacterObject.FirstBattleEquipment`** getters. A live, registered troop (seen: TOR's `tor_gs_trolls`, `race="troll"`) has these fields correct in XML but null at **runtime**, and every consumer that reads them NREs in a different method (wages, food, auto-upgrade, training, assimilation `SwapTroopsIfNeeded`, garrison XP `PartyBase.OnXpChanged`, auto-resolve combat `MapEventSide.ApplySimulatedHitRewardToSelectedTroop`). The postfixes substitute a fallback culture (`aserai`) / an empty upgrade array / an empty `Equipment` at the one place every system reads the field — killing the whole cascade at the source. Read-only; never writes the backing field or save state. Getters resolved with `DeclaredOnly` to avoid the `new`-shadowed `Culture` ambiguity. Also carries a diagnostic that logs the call stack if anything ever *writes* null into these fields, to pin the upstream root (empirically 100% correlated with the LoreHardcore data mod). |
| **`SaveMetaDataDuplicateKeyGuard`** | Postfix on `SaveHandler.GetSaveMetaData` (the same method `ModListScrubPatch` postfixes; Harmony composes both). `MBSaveLoad.GetSaveMetaData` feeds every `CampaignSaveMetaDataArgs.OtherData` entry — plus `ApplicationVersion`/`CreationTime` — into `Dictionary.Add`, which throws `ArgumentException` ("same key has already been added") on a duplicate. Vanilla supplies 15 distinct keys, so a base game never throws; a third-party mod patching the metadata builder to append its own entry can inject a duplicate (or a key colliding with the reserved `Modules`/`Module_*`/`ApplicationVersion`/`CreationTime`), crashing **every** save (auto/quick/manual). The guard de-duplicates `OtherData` (keep-first, ordinal) and drops reserved-key collisions before the engine's `Add` loop — reproducing the dictionary the engine would have built, so the save's metadata is otherwise unchanged. `__result` is rebuilt only when something is actually removed (zero overhead on normal saves). Does not depend on TOR. |
| **`EffectiveRelationNullHeroNRESafetyPatch`** | Prefix on `DefaultDiplomacyModel.GetEffectiveRelation(Hero, Hero)`. On the hourly map tick `Army.ThinkAboutCohesionBoost` → `CalculatePartyInfluenceCost` calls `armyLeaderParty.LeaderHero.GetRelation(party.LeaderHero)`; a member party with no leader (`party.LeaderHero == null`) hands a null hero into the diplomacy model, which guards its outputs but not its inputs, so `GetHeroesForEffectiveRelation` dereferences `hero.Clan` and NREs the whole campaign tick. Returns `__result = 0` (no relation) when either hero is null — matching the same-clan branch that already returns 0 — so the leaderless party contributes no influence cost and the army continues. Two valid heroes run vanilla unchanged. Comes from mods that spawn hero-less map parties the AI absorbs into armies (e.g. RealmsForgotten / RFMonsters). Does not depend on TOR. |
| **`TroopRosterCountUnderflowSafetyPatch`** | Prefix on `TroopRoster.AddToCountsAtIndex(index, ref countChange, ref woundedCountChange, …)` — the single funnel every roster add/remove routes through. It does `data[index].Number += countChange` with no floor, so a caller asking to remove more troops than the element holds drives `Number` below zero and the `set_Number` setter throws `MBUnderFlowException`, killing the campaign tick. The prefix clamps an over-large negative `countChange`/`woundedCountChange` to exactly empty (`-current`); the original then floors the element at 0 and its own `removeDepleted` branch drops the emptied row — the intended "remove all, no more" outcome. **Universal**, not mod-specific: vanilla always checks the count before removing so the clamp is a no-op for healthy calls; it catches the whole class of negative-count crashes (first seen via TOR's unclamped Wood Elf dryad recruitment, `TORAIRecruitmentCampaignBehavior.cs:196`). Does not depend on TOR. |
| **`SkillTrainerLeaveNullHeroSafetyPatch`** (TOR) | Prefix on `TOR_Core.CampaignMechanics.SkillTrainerBehavior.LeaveTraining(Hero)`. After a settlement is taken by siege/rebellion, `SettlementOwnerChanged` ends training for every companion tracked in `_heroesInTraining` there, resolving the hero via `Hero.MainHero.Clan.Heroes.FirstOrDefault(x => x.StringId == key)`. That returns null once the companion has left the player's clan (died/captured/dismissed) but his id is still in the dictionary — TOR never prunes the stale entry — and `LeaveTraining` dereferences `hero.CurrentSettlement` on the null hero, NREing the campaign tick (and re-firing on every later siege of that town). Returns `false` (skip original) only when `hero == null`; a valid hero runs vanilla unchanged. The dictionary is deliberately left alone (the caller is mid-`foreach` over it). Only active with TOR loaded. |
| **`PartySkillExercisedNRESafetyPatch`** | Finalizer on the private `DefaultSkillLevelingManager.OnPartySkillExercised(MobileParty, SkillObject, float, PartyRole)` — the single funnel every party skill-XP grant routes through (trade, governing, raids, surgery, training, tactics, scouting, charm, auto-resolve rewards…). It does `party.GetEffectiveRoleHolder(role)` and null-checks the resulting holder but **not `party`**; in auto-resolve, surgery XP is granted via `OnSurgeryApplied(party.MobileParty, …)` and a struck troop belonging to a `PartyBase` with a null `MobileParty` (settlement/garrison party, or one left by a removed mod) hands it a null party → NRE → whole map tick dies. The `_Patch1` frame shows XP-overhaul mods (BetterExperience/BetterCore) also patch it, so a finalizer covers both null-party and a throwing mod patch. The method is void, so a swallow just skips that one XP grant. **Universal**, not mod-specific; no-op for healthy calls. |
| **`GainRenownNullClanNRESafetyPatch`** | Prefix on the private `GainRenownAction.ApplyInternal(Hero, float, bool)` — the single funnel for all renown awards (battle wins, quests, tournaments, cheats). It does `hero.Clan.AddRenown(…)` with no null-check on `hero` or `hero.Clan`; an auto-resolved battle won by a party led by a clanless/null hero (bandit/mod-spawned hero, leaderless party, clanless lord left by a removed mod) NREs the whole map tick. Returns `false` (skip original) when `hero == null` or `hero.Clan == null` — there is no clan to receive the renown, so skipping is the correct no-op; a valid hero+clan runs vanilla unchanged. **Universal**, not mod-specific. |
| **`EndCaptivityNullCaptorNRESafetyPatch`** | Prefix on the private `PlayerCaptivity.EndCaptivityInternal()`. The defeated-party loot path (`MapEvent.LootDefeatedPartyPrisoners` → `EndCaptivityAction.ApplyInternal` → `PlayerCaptivity.EndCaptivity`) releases every prisoner of an auto-resolved battle's beaten party, including the main hero; `EndCaptivityInternal` does `this._captorParty.IsActive` with no null-check. `_captorParty` is null exactly when `PlayerCaptivity.IsCaptive` is false — a double-release, or a captivity/enlistment mod (e.g. Enlistment) that moved the player in/out of parties without routing through `StartCaptivity` — so the deref NREs the whole map tick. Returns `false` (skip original) when the captor party is null (nothing to release); first best-effort re-activates the main party if it was left inactive, so the player is never frozen. A healthy capture (non-null captor) runs vanilla unchanged. **Universal**, not mod-specific. |
| **`ClanUpdateStrengthNRESafetyPatch`** | Finalizer on `Clan.UpdateCurrentStrength()` — runs inside `Clan.AfterLoad` during **save loading**. It sums each party's `EstimatedStrength` → party morale → `GetEffectivePartyLeaderForSkill`, which for a leaderless party returns the first troop's `CharacterObject`; `BasicCharacterObject.GetSkillValue` then does `DefaultCharacterSkills.Skills.GetPropertyValue(skill)` with no null-check, so a malformed troop with null skill data (broken/overhaul troop e.g. ROT units, or one left by a removed mod) NREs **and the whole save fails to load**. The finalizer swallows it; `CurrentTotalStrength` is just a cache recomputed at runtime, so `AfterLoad` continues and the save opens. Targets the save-load chokepoint rather than the very hot `CharacterObject.GetSkillValue` leaf. **Universal**, not mod-specific; no-op for healthy saves. |
| **`HeroClearChangedPerksNRESafetyPatch`** | Finalizer on the private `Hero.ClearChangedPerks()` — runs inside `Hero.AfterLoad` during **save loading**. `AfterLoad` does `if (IsAlive) ClearChangedPerks()`, and `ClearChangedPerks` iterates `this._heroPerks.GetProperties()` with no null-check (unlike `IsPerkRegistered`, which guards `_heroPerks`). A save holding an **alive hero whose `_heroPerks` is null** (a broken/under-initialised hero left by a hero/clan/perk mod — perk overhauls like JackOfAllTrades, or clan/hero-spawning mods like Retinues / RaiseYourBanner / HousesCalradia) NREs the read **and the whole save fails to load**. The finalizer swallows it; the skipped cleanup only zeroes sub-threshold perks (cosmetic, and moot on an already-broken hero), so `AfterLoad` continues and the save opens. **Universal**, not mod-specific; no-op for healthy saves. |
| **`DanglingTroopCleanerBehavior`** | `OnSessionLaunched` scan: drops roster elements whose `Character` is null or **no longer registered in `MBObjectManager`** (a mod unregistered it without scrubbing rosters) across every party, settlement and active issue, and **removes orphaned garrison parties** (`IsGarrison && CurrentSettlement == null`) so a re-save heals the campaign. Live modded troops that merely lack a culture are NOT touched; every removal is logged by `StringId`. Listed on the Crash Fixes tab as **"Fix broken troops on save load"**. |
| **`NavalShipUpgradeNullClanNRESafetyPatch`** (Naval DLC) | Prefix on the third-party `NavalDLC.CampaignBehaviors.ShipUpgradeCampaignBehavior.GetChanceToUpgradeShipForLord(Hero)`. The mod's `DailyTickPartyEvent` auto-upgrades AI ships each day and computes an upgrade chance from `hero.Clan.Tier`, but only guards `party.LeaderHero == null` — never that the leader *has* a clan. A party led by a clanless hero (TOR special/summoned/undead lords, or another mod spawning parties under clanless heroes) makes `hero.Clan.Tier` NRE the whole daily map tick. Returns `__result = 0f` (no upgrade chance) when `hero`/`hero.Clan` is null, so that party skips its ship upgrade and the tick continues; a real lord runs vanilla unchanged. Signature confirmed by decompiling the shipped `NavalDLC.dll`. Self-skips (shown *Skipped*) when Naval DLC isn't loaded. |
| **`SafetyNetMessenger`** | Five-language toast helper used by the guards above. Picks EN/RU/ZH/ZHT/TR by `BannerlordConfig.Language` (Traditional Chinese falls back to Simplified, then English), amber (catch) or green (cleanup), one toast per category per 60 s. (Always on — infrastructure.) |

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
- No telemetry.
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
Calradia Expanded, RBM, Banner Kings и т.д. Без интернета, без телеметрии,
без Harmony-патчей, без зависимостей.

> **Steam Workshop:** [3717685432](https://steamcommunity.com/sharedfiles/filedetails/?id=3717685432)
> **Совместимость:** Bannerlord **v1.2.x – v1.4.x** — в одной установке есть
> загрузчик, который при запуске определяет версию игры и подгружает подходящую
> сборку, поэтому одна и та же подписка работает на 1.2.x, 1.3.15 и 1.4.5. Работает
> и со Steam, **и** с ручной (не-Steam) установкой (Game Pass / MS Store по-прежнему
> не поддерживаются — у них другие бинарники игры). Модуль Bannerlord.Harmony нужен
> для «живых» защит; ядро (анализ крашей) грузится и работает и без него.

## Что делает

Семь вкладок в главном меню — Диагностика крашей, Настройка системы, Журнал,
Сейвы, Моды, **Фиксы крашей**, Настройки. (Раньше была «Оптимизация»; убрана
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

Вкладка **«Моды»** показывает установленные моды **в том же порядке, что и в
лаунчере** (порядок загрузки), с пометками конфликтов / недостающих зависимостей /
порядка загрузки; проблемные моды подсвечены, но больше не перетасовывают список.

- **Диагностика крашей** — **99 YAML-правил** под GPU/DirectX (включая авторитетный
  детект iGPU из rgl_log + whitelist карт где DxDiag врёт VRAM), native runtime,
  повреждённые `.tpac` ассеты, save / late-game, mission / engine (NRE в диалогах,
  team-index шторм), TOR (включая Naval DLC + TOR conflict, Assimilation
  IndexOutOfRange), мод-стек (TOR + 5+ неофициальных), BUTR-стек, hardware,
  модули (включая аудит графа зависимостей SubModule.xml). Парсер модулей
  переживает ранние крэши через fallback на `[Runtime][Arguments]` когда секция
  «Used Modules» отсутствует в crash_tags.txt.
- **Настройка системы (Tune-Up)** — **26 модулей** полу-автоматической ремедиации.
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
