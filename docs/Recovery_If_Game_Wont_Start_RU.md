# Восстановление: игра не запускается после Crash Doctor

Это происходит, если ты:
- понизил **в игре** Texture / Shader / Shadow Quality по совету Crash Doctor
- применил карточку **M3.3 Engine Config** (или любую другую, меняющую графику)
- не выполнил полную перекомпиляцию кэша шейдеров после изменения

Симптом — игра падает на заставке с имперским солдатом или сразу после клика «Continue».
Корень — старый кэш шейдеров был собран под прежние графические настройки, а игра
теперь пытается загрузить его под новые. Mismatch → crash.

Crash Doctor открыть нельзя, потому что игра не стартует. Ниже — ручные шаги.

## Шаг 1. Удалить engine_config.txt

Bannerlord пересоздаст его с дефолтами при следующем запуске.

```
Documents\Mount and Blade II Bannerlord\Configs\engine_config.txt
```

Если до этого ты делал Apply M3.3 — там лежит backup в `Documents\Mount and Blade II
Bannerlord\Configs\backups\` или в каталоге CrashDoctor\backups\. Можно либо удалить
файл, либо вернуть из backup'а — на запуск это не повлияет.

## Шаг 2. Удалить кэш шейдеров

Три места, удалить **все три**:

1. **ProgramData (главное)** — целая папка:
   ```
   C:\ProgramData\Mount and Blade II Bannerlord\Shaders\
   ```
2. **Игровая папка** — один файл:
   ```
   <Bannerlord install>\Shaders\D3D11\compressed_shaders_cache.sack
   ```
   где `<Bannerlord install>` — Steam-папка игры (обычно
   `C:\Program Files (x86)\Steam\steamapps\common\Mount & Blade II Bannerlord\`).

3. **Per-module sacks** — для каждого мода в `Modules/`:
   ```
   <Bannerlord install>\Modules\<ModName>\Shaders\D3D11\compressed_shaders_cache.sack
   <Bannerlord install>\Modules\<ModName>\Shaders\D3D11\compressed_shader.cache.sack
   ```
   Удалить везде где есть.

Можно отправлять в Корзину — восстанавливаются обратно если что.

## Шаг 3. Проверить целостность игры (опционально)

Если игра всё ещё не стартует после шагов 1–2:

```
Steam → Bannerlord → Properties → Installed Files → Verify integrity of game files
```

Steam дополнит недостающие нативные файлы (10–30 секунд проверки).

## Шаг 4. Перезагрузить ПК

Холодная перезагрузка очищает page file и любые занятые дескрипторы. Не «Sign out»,
а полноценный Restart.

## Шаг 5. Запустить игру и собрать шейдеры

1. Запусти Bannerlord через лаунчер с тем же набором модов.
2. **В главном меню** нажми **«Build Shader Cache»** (или зайди Continue — игра
   сама запустит сборку).
3. Жди **20–60 минут**. На TOR + кастомные моды может быть и дольше.
4. **Не закрывай игру** во время сборки. Она **НЕ зависла** — компилятор гонит
   сотни шейдеров последовательно.
5. Не открывай Chrome / Discord / браузеры в это время — они отнимают VRAM, и
   компилятор может не успеть в TDR-окно.

## Шаг 6. NVIDIA: восстановить настройки через GeForce Experience

Только если ничего из выше не помогло и ты на NVIDIA-карте.

1. Открой **NVIDIA app** (или **GeForce Experience**, если стоит старая версия).
2. Вкладка **Graphics** → найди **Mount & Blade II: Bannerlord**.
3. Нажми **Optimize** (выкрути ползунок чуть ниже Recommended если карта слабая).
4. Перезапусти игру.

Это перезаписывает настройки графики через NVIDIA-профиль. Аналог для AMD —
**AMD Adrenalin → Gaming → Bannerlord → Reset to Defaults**.

## Если всё равно не запускается

Признак — даже после всех шагов crash на splash. Тогда не графика виновата.
Проверь:
- модлист — не сломан ли (один из недавно добавленных модов мог приехать битым)
- BLSE / ButterLib / Bannerlord.Harmony — все в актуальных версиях
- логи в `C:\ProgramData\Mount and Blade II Bannerlord\logs\` — последний
  `rgl_log_*.txt` и `watchdog_log_*.txt` отдай в чат поддержки

## Профилактика на будущее

Каждый раз, когда меняешь графические настройки (через Crash Doctor или вручную
в игре):

1. Применил изменение.
2. **ПЕРЕЗАГРУЗИЛ ПК.**
3. Запустил игру → Главное меню → **Build Shader Cache** → подождал 20–60 минут.
4. Только потом загружай сейв.

Если пропустить шаги 2 или 3 — наступишь на эти грабли снова.
