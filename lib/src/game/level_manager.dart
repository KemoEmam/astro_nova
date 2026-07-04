import 'package:flame/components.dart';

import 'package:astro_nova/src/features/bosses/boss.dart';
import 'package:astro_nova/src/features/bosses/boss_core.dart';
import 'package:astro_nova/src/features/effects/effects.dart';
import 'package:astro_nova/src/features/combat/enemy_bullet.dart';
import 'package:astro_nova/src/features/powerups/power_up.dart';
import 'package:astro_nova/src/core/level_theme.dart';
import 'package:astro_nova/src/game/astro_nova_game.dart';

enum LevelPhase { intro, waves, bossIntro, boss, cleared }

/// Drives the 10-level campaign: wave phase with a visible progress bar,
/// then a cinematic boss intro, the boss fight, a clear banner, and on to
/// the next level (or victory after level 10).
class LevelManager extends Component with HasGameReference<AstroNovaGame> {
  static const maxLevel = 10;

  LevelPhase phase = LevelPhase.intro;
  double _phaseTime = 0;
  int _bossCount = 1;

  /// Wave phase length: very short early so the campaign hooks fast, growing
  /// toward the level-10 maximum (~9s at level 1, ~29s at level 10).
  double get _waveDuration => 7.0 + game.level.value * 2.2;

  @override
  void onMount() {
    super.onMount();
    _enterLevel();
  }

  void _enterLevel() {
    phase = LevelPhase.intro;
    _phaseTime = 0;
    game.levelProgress.value = 0;
    game.killsSinceWeaponDrop = 0;
    game.weaponDroppedThisLevel = false;
    final theme = game.theme;
    game.spawn(CinematicBanner(
      title: 'LEVEL ${game.level.value}',
      subtitle: theme.name,
      color: theme.accent,
      lifespan: 1.8,
    ));
  }

  @override
  void update(double dt) {
    _phaseTime += dt;
    switch (phase) {
      case LevelPhase.intro:
        if (_phaseTime >= 1.2) {
          phase = LevelPhase.waves;
          _phaseTime = 0;
          game.spawner?.enabled = true;
        }
      case LevelPhase.waves:
        game.levelProgress.value = (_phaseTime / _waveDuration).clamp(0.0, 1.0);
        if (_phaseTime >= _waveDuration) {
          _startBossIntro();
        }
      case LevelPhase.bossIntro:
        if (_phaseTime >= 2.0) {
          phase = LevelPhase.boss;
          _phaseTime = 0;
          _spawnBosses();
        }
      case LevelPhase.boss:
        break; // waiting on onBossDefeated
      case LevelPhase.cleared:
        if (_phaseTime >= 2.4) {
          _nextLevel();
        }
    }
  }

  /// Boss lineup per level: level 5 is a twin fight, level 10 a triple
  /// finale — always identical copies of that level's boss, each patrolling
  /// its own lane at reduced HP.
  List<BossSpec> get _lineup {
    final level = game.level.value;
    final spec = bossSpecs[level - 1];
    final count = switch (level) { 5 => 2, 10 => 3, _ => 1 };
    return List.filled(count, spec);
  }

  String get _lineupTitle {
    final lineup = _lineup;
    return lineup.length == 1
        ? lineup.first.name
        : '${lineup.first.name} x${lineup.length}';
  }

  void _startBossIntro() {
    phase = LevelPhase.bossIntro;
    _phaseTime = 0;
    game.levelProgress.value = 1;
    game.spawner?.enabled = false;
    final lineup = _lineup;
    game.shake(5);
    game.spawn(CinematicBanner(
      title: '! WARNING !',
      subtitle: '$_lineupTitle APPROACHING',
      color: lineup.last.color,
      lifespan: 2.0,
      flashing: true,
    ));

    // Backstop for the drop guarantee: if the whole wave phase ended with no
    // weapon drop (few kills, all misses), hand one over during the warning
    // cinematic so the player never faces a boss dry.
    if (!game.weaponDroppedThisLevel) {
      game.weaponDroppedThisLevel = true;
      game.spawn(PowerUp(
        type: PowerUpType.weapon,
        position: Vector2(AstroNovaGame.worldWidth / 2, 60),
      ));
    }
  }

  void _spawnBosses() {
    final lineup = _lineup;
    _bossCount = lineup.length;

    final n = lineup.length;
    final laneWidth = AstroNovaGame.worldWidth / n;
    final hpScale = switch (n) { 1 => 1.0, 2 => 0.62, _ => 0.48 };
    for (var i = 0; i < n; i++) {
      game.spawn(Boss(
        spec: lineup[i],
        centerX: laneWidth * (i + 0.5),
        amplitude: n == 1 ? 130 : laneWidth / 2 - lineup[i].radius - 8,
        hpScale: hpScale,
      ));
    }
    game.bossHealth.value = 1.0;
    game.bossName.value = _lineupTitle;
  }

  /// Aggregate HP bar across all living bosses in the fight.
  void updateBossBar() {
    final bosses = game.runRoot.children.query<Boss>();
    final total =
        bosses.fold<double>(0, (sum, b) => sum + b.healthFraction);
    game.bossHealth.value = (total / _bossCount).clamp(0.0, 1.0);
  }

  void onBossDefeated(Vector2 position) {
    if (phase != LevelPhase.boss) return;
    updateBossBar();
    // Count the bosses actually still fighting — robust against
    // simultaneous deaths (shockwaves, piercing shots) and deferred
    // component removal. The Core drops only when the LAST one falls.
    final stillFighting = game.runRoot.children
        .query<Boss>()
        .where((b) => !b.isDefeated)
        .length;
    if (stillFighting > 0) return;

    game.bossHealth.value = null;
    game.bossName.value = null;
    phase = LevelPhase.cleared;
    _phaseTime = 0;

    // One Boss Core per fight, dropped where the last boss died.
    game.spawn(BossCore(
      relicLevel: game.level.value,
      position: Vector2(
        position.x.clamp(30, AstroNovaGame.worldWidth - 30),
        position.y.clamp(60, AstroNovaGame.worldHeight / 2),
      ),
    ));

    // Clear leftover boss projectiles so the break between levels is safe.
    final leftovers = game.runRoot.children.query<EnemyBullet>().toList();
    for (final bullet in leftovers) {
      bullet.removeFromParent();
    }

    game.healLife();
    final isLast = game.level.value >= maxLevel;
    game.spawn(CinematicBanner(
      title: isLast ? 'VOID CLEARED' : 'LEVEL ${game.level.value} CLEAR',
      subtitle: isLast ? '' : '+1 HULL RESTORED',
      color: game.theme.accent,
      lifespan: 2.2,
    ));
  }

  void _nextLevel() {
    if (game.level.value >= maxLevel) {
      game.victory();
      return;
    }
    game.level.value++;
    game.spawner?.configureForLevel(game.level.value);
    _enterLevel();
  }

  LevelTheme get theme => levelThemes[game.level.value - 1];
}
