import 'package:flame/components.dart';

import 'components/boss.dart';
import 'components/effects.dart';
import 'components/enemy_bullet.dart';
import 'level_theme.dart';
import 'neon_void_game.dart';

enum LevelPhase { intro, waves, bossIntro, boss, cleared }

/// Drives the 10-level campaign: wave phase with a visible progress bar,
/// then a cinematic boss intro, the boss fight, a clear banner, and on to
/// the next level (or victory after level 10).
class LevelManager extends Component with HasGameReference<NeonVoidGame> {
  static const maxLevel = 10;

  LevelPhase phase = LevelPhase.intro;
  double _phaseTime = 0;

  /// Wave phase length: very short early so the campaign hooks fast, growing
  /// toward the level-10 maximum (~12s at level 1, ~32s at level 10).
  double get _waveDuration => 10.0 + game.level.value * 2.2;

  @override
  void onMount() {
    super.onMount();
    _enterLevel();
  }

  void _enterLevel() {
    phase = LevelPhase.intro;
    _phaseTime = 0;
    game.levelProgress.value = 0;
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
          game.spawn(Boss(spec: bossSpecs[game.level.value - 1]));
        }
      case LevelPhase.boss:
        break; // waiting on onBossDefeated
      case LevelPhase.cleared:
        if (_phaseTime >= 2.4) {
          _nextLevel();
        }
    }
  }

  void _startBossIntro() {
    phase = LevelPhase.bossIntro;
    _phaseTime = 0;
    game.levelProgress.value = 1;
    game.spawner?.enabled = false;
    final spec = bossSpecs[game.level.value - 1];
    game.shake(5);
    game.spawn(CinematicBanner(
      title: '! WARNING !',
      subtitle: '${spec.name} APPROACHING',
      color: spec.color,
      lifespan: 2.0,
      flashing: true,
    ));
  }

  void onBossDefeated() {
    if (phase != LevelPhase.boss) return;
    phase = LevelPhase.cleared;
    _phaseTime = 0;

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
