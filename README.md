# NEONLINE — Life in the Sprawl

Godot 4.3+ mobile life-simulation template (BitLife-style core loop) with an **original cyberpunk setting**. All world names, factions and IP are generated for this template — no third-party trademarks are used anywhere.

> ⚠️ This is a **starter template**, not a shipped game: monetization/ads/analytics are stubs by design so you can plug your own SDKs in.

---

## 1. Core loop (what the player does)

```
Age +1 year  →  stats drift / paycheck / death check
     │            → eligible event card drawn (bottom sheet)
     ▼
Player picks an option → effects applied → life feed grows
     ▼
Spend the year: Actions tab (gym, net-cafe, grey runs…)
Assets tab (jobs, schools, chrome implants)
     ▼
Repeat until FLATLINE → new life (soft meta persists via saves/analytics)
```

Feature parity checklist vs. the genre standard:

| Feature | Status | Where |
|---|---|---|
| Year-by-year aging sim | ✅ | `game_state.gd` |
| Choice-driven event cards | ✅ | `event_engine.gd` + `data/events.json` (12 sample events) |
| Stats (Health/IQ/Cool/Body/Empathy) + Happiness/Karma | ✅ | `data/stats.json` |
| Careers w/ requirements, promotion, performance | ✅ | `data/jobs.json`, Assets tab |
| Education tiers & enrollment | ✅ | `data/schools.json` |
| Cyberware market w/ rejection risk | ✅ | `data/implants.json` |
| Activities with cost/cooldown/risk rolls | ✅ | `data/activities.json` |
| Relationships / people affinity | ✅ | `data/people.json` |
| Life-history feed | ✅ | Life tab |
| Death & legacy/new life | ✅ | `_on_death` bottom sheet |
| Save slots + autosave on backgrounding | ✅ | `save_system.gd` |
| Light/Dark theme, persisted | ✅ | `theme_manager.gd` |
| Ads / IAP / analytics / notifications | 🟡 stubs | runtime autoloads |

## 2. UI standards followed (mobile)

- **4pt spacing scale**, type scale, radius & elevation tokens in `scripts/runtime/palette.gd` (single source of truth).
- **≥44dp touch targets** everywhere (`TOUCH_MIN`), 56–72px bars.
- **Bottom tab navigation** (5 tabs) + top app bar pattern → `scenes/shell.tscn`.
- **Bottom sheets** for modals/event cards, **snackbars/toasts** for feedback, **progress bars** for stats — all built by `ui_kit.gd`.
- Portrait-locked, `canvas_items` stretch + safe-area aware insets (`ThemeManager.safe_margins()`).
- Two full themes: *Midnight Grid* (dark) / *Daylight Protocol* (light) with live re-skin.

## 3. Project layout

```
project.godot            # portrait, GL Compatibility, autoloads, custom theme
export_presets.cfg       # Android, iOS, Web, Linux, Windows
icon.svg
data/*.json              # ALL game content (world, stats, jobs, events…)
themes/base_theme.tres
scenes/                  # boot / shell / game / settings (.tscn, script-driven)
scripts/runtime/         # autoload singletons + design tokens + UIKit
scripts/ui/              # screens
docs/                    # this guide, architecture, roadmap
addons/                  # drop real SDK plugins here later
```

Autoload order (in `project.godot`): ThemeManager → SignalBus → AudioManager → DataService → GameState → SaveSystem → EventEngine → Analytics → AdManager → IAPManager → Notifier.

## 4. Run it

1. Open Godot 4.3+ → *Import* → select this folder.
2. Press ▶ (F5). Main scene: `res://scenes/boot.tscn`.
3. Desktop preview works at 440×956; test phone ergonomics with *Project → Project Settings → Display* or a device build.

### Export builds

- **Android**: install export templates, set `package/unique_name`, add debug keystore path in preset 0, then `Editor → Export APK/APK+AAB signed`. Gradle build off by default (no plugins needed for the stub layer); enable it when adding SDKs.
- **iOS**: fill team id / signing in preset 1, export Xcode project, build via Xcode.
- **Web**: preset 2 → host `builds/web/` behind HTTPS (SharedArrayBuffer not required).

## 5. Extend without touching code

- **New event**: append to `data/events.json` (schema documented at the top of `event_engine.gd`). Supports age gates, stat ranges, karma gates, flags (`has_job`, `implant:<id>`), one-shot events and risky branches.
- **New job/school/implant/activity/person**: same idea — pure JSON.
- **New screen**: instantiate `shell.tscn`, connect `tab_selected`, build content with `NLUI` helpers.

## 6. Production TODO (before release)

- [ ] Replace synth SFX/music with real assets (`assets/audio/…`, hooks inside `audio_manager.gd`).
- [ ] Wire AdMob/Unity Ads behind `ad_manager.gd`; Play Billing behind `iap_manager.gd` (gradle build ON).
- [ ] Firebase/Amplitude sink in `analytics.gd.flush()`.
- [ ] Real fonts/icons (currently unicode glyphs) + app icon set.
- [ ] Balance pass: tune decay/death curves in `game_state.gd` against playtest retention.
- [ ] Localization: wrap UI strings with `tr()`, add CSV translations.

## 7. Setting bible (original, cyberpunk-flavored)

**Neon Bay Megalopolis, 2087.** Six districts (Neon Row … Grid Nine), five power blocs: Helix Dynamics Conglomerate, Free Net Collective, Ashen Cartel, Municipal Peace Engine, Ghostwire Couriers. Currency: ₢ credits. Tone: street-level survival, chrome vs. flesh, corporate feudalism — every name here is invented for this template.
