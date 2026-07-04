# Neon Void 🚀

A neon-styled vertical space shooter built with **Flutter** and the **[Flame](https://flame-engine.org/) game engine**. All graphics are vector-rendered in code — no sprite assets, just `Canvas`, glow effects, and particles.

> **[▶ Play it in your browser](https://karim-elemam.github.io/neon_void/)** *(GitHub Pages, deployed by CI)*

<!-- TODO: record a gameplay GIF and drop it here -->
<!-- ![gameplay](docs/gameplay.gif) -->

## Gameplay

- **Move:** drag anywhere (mobile) or WASD / arrow keys (desktop & web)
- **Fire:** automatic
- **Pause:** `Esc` / `P` or the HUD button
- Survive escalating waves of three enemy types:

| Enemy | Shape | Behaviour | HP | Score |
|---|---|---|---|---|
| Drifter | pink triangle | falls straight | 1 | 10 |
| Weaver | orange diamond | fast sine-wave strafe | 2 | 25 |
| Tank | purple hexagon | slow bullet sponge, HP ring | 6 | 60 |

Kills have a 12% chance to drop a power-up: **W** upgrades your weapon (up to a triple-shot), **S** grants a one-hit shield. Getting hit resets your weapon. High score persists between sessions.

## Architecture

The interesting part for fellow devs — how the game is put together:

```
lib/
├── main.dart                     # GameWidget + overlay routing
├── game/
│   ├── neon_void_game.dart       # FlameGame: camera, state machine, score/lives
│   ├── palette.dart              # single source of truth for the art direction
│   └── components/
│       ├── player.dart           # input (keyboard + drag), auto-fire, i-frames
│       ├── enemy.dart            # 3 types as an enhanced enum (hp/speed/score/shape)
│       ├── enemy_spawner.dart    # time-based difficulty ramp + weighted spawn table
│       ├── bullet.dart           # active hitbox, despawns off-screen
│       ├── power_up.dart         # drop table + pickup effects
│       ├── explosion.dart        # pure-particle radial bursts (no textures)
│       └── starfield.dart        # 3-layer parallax, wraps instead of respawning
└── ui/
    └── overlays.dart             # menu / HUD / pause / game-over as Flutter widgets
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

- [ ] Boss waves every 90 seconds
- [ ] Enemy projectiles
- [ ] SFX + music (`flame_audio`)
- [ ] Online leaderboard

## License

MIT
