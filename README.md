# Neon Void 🚀

A neon-styled vertical space shooter built with **Flutter** and the **[Flame](https://flame-engine.org/) game engine**. All graphics are vector-rendered in code — no sprite assets, just `Canvas`, glow effects, and particles.

> **[▶ Play it in your browser](https://karim-elemam.github.io/neon_void/)** *(GitHub Pages, deployed by CI)*

<!-- TODO: record a gameplay GIF and drop it here -->
<!-- ![gameplay](docs/gameplay.gif) -->

## Gameplay

A **10-level campaign designed to be finished in one sitting** (~10 minutes): short wave phases with a visible progress bar, a unique cinematic mini-boss at the end of every level, and a new visual theme per level. Difficulty ramps smoothly from level 1 to 10 — your weapon curve grows faster, so it stays beatable.

- **Move:** drag anywhere (mobile) or WASD / arrow keys (desktop & web)
- **Fire:** automatic · **Pause:** `Esc` / `P` or the HUD button

**Enemies** — Drifter (triangle, falls straight), Weaver (diamond, sine-strafe), Tank (hexagon, bullet sponge with an HP ring), plus a new unique type every 3 levels: **Darter** (level 3, accelerating arrow), **Splitter** (level 6, pentagon that splits into two drifters on death), **Phantom** (level 9, ghost orb that's only vulnerable while phased in). Enemy colors blend toward each level's theme, so every sector looks different.

**30 weapon tiers** — generated from a progression formula so every pickup changes something real: straight barrels, widening spread pairs, homing missiles, piercing, damage, and fire rate each unlock on their own schedule, from Pulse Shot all the way to the **Void Laser**. Bullet color and shape (bolt → diamond → orb → beam) evolve through the tiers. Getting hit knocks you back three tiers.

**5 shield tiers** — Aegis I/II (charges), Nova Guard / Nova Guard+ (absorbing a hit detonates a shockwave), Eternal Aegis (charges regenerate).

**Drop economy** — power-up drop rates fall as the campaign advances *and* as your upgrades stack, so early levels shower you with toys and the endgame stays tense.

**10 bosses** — one per level, each with its own shape, color, movement pattern (strafe / figure-8 / dive / teleport), and attack mix (aimed, spread, radial, spiral, minion summon): Sentinel, Twin Fang, Hexen, Widow, Bulwark, Phantom, Vortex, Reaper, Hydra, and **VOID PRIME**. Each arrives with a flashing WARNING letterbox cinematic and screen shake — and **level 5 is a twin-boss fight, level 10 a triple-boss finale**, with each boss patrolling its own lane and a shared HP bar.

## Architecture

The interesting part for fellow devs — how the game is put together:

```
lib/
├── main.dart                     # GameWidget + overlay routing
├── game/
│   ├── neon_void_game.dart       # FlameGame: camera, run lifecycle, notifiers
│   ├── level_manager.dart        # campaign state machine (waves → boss → clear)
│   ├── level_theme.dart          # 10 per-level visual themes
│   ├── weapon.dart               # 30 generated weapon tiers + 5 shield tiers
│   ├── palette.dart              # base art-direction colors
│   └── components/
│       ├── player.dart           # input, weapon table firing, shield perks
│       ├── boss.dart             # 10 boss specs: shape, movement, attack mix
│       ├── enemy.dart            # 3 types as an enhanced enum
│       ├── enemy_spawner.dart    # level-configured intervals + spawn weights
│       ├── bullet.dart           # spread angles, piercing, homing steering
│       ├── enemy_bullet.dart     # boss projectiles
│       ├── power_up.dart         # level- and upgrade-scaled drop economy
│       ├── effects.dart          # cinematic banners, floating text, shockwaves, camera shake
│       ├── explosion.dart        # pure-particle radial bursts (no textures)
│       ├── background.dart       # theme-lerping backdrop
│       └── starfield.dart        # 3-layer parallax, theme-colored
└── ui/
    └── overlays.dart             # menu / HUD / pause / game-over / victory
```

Design decisions worth noting:

- **Fixed-resolution viewport (400×800)** — gameplay is pixel-identical across phone, desktop, and web; the viewport letterboxes the rest.
- **Flutter widgets as game UI** — menus and HUD are plain widgets driven by `ValueNotifier`s on the game class, layered over the canvas with Flame's overlay system. Best of both worlds: game loop for the world, declarative UI for the chrome.
- **Enemy types as an enhanced enum** — stats, color, and shape live in one place; adding a fourth enemy type is a ~15-line change.
- **No image assets** — every visual is `Path` + `MaskFilter.blur` glow or the `Particle` API, which keeps the repo tiny and the style consistent.

## Running locally

```bash
flutter pub get
flutter run            # or: flutter run -d chrome
flutter test
```

## Roadmap

- [x] 10-level campaign with unique bosses
- [x] Enemy projectiles + boss attack patterns
- [ ] SFX + music (`flame_audio`)
- [ ] Online leaderboard
- [ ] Endless mode after the campaign

## License

MIT
