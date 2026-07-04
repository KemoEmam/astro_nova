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
  int _bossCount = 1;
  int _bossesRemaining = 0;

  /// Wave phase length: very short early so the campaign hooks fast, growing
  /// toward the level-10 maximum (~11s at level 1, ~31s at level 10).
  double get _waveDuration => 9.0 + game.level.value * 2.2;

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
  /// finale. Multi-boss fights pull in the previous levels' bosses at
  /// reduced HP, each patrolling its own lane.
  List<BossSpec> get _lineup {
    final level = game.level.value;
    if (level == 5) return [bossSpecs[3], bossSpecs[4]];
    if (level == 10) return [bossSpecs[7], bossSpecs[9], bossSpecs[8]];
    return [bossSpecs[level - 1]];
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
      subtitle: '${lineup.map((s) => s.name).join(' + ')} APPROACHING',
      color: lineup.last.color,
      lifespan: 2.0,
      flashing: true,
    ));
  }

  void _spawnBosses() {
    final lineup = _lineup;
    _bossCount = lineup.length;
    _bossesRemaining = lineup.length;

    final n = lineup.length;
    final laneWidth = NeonVoidGame.worldWidth / n;
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
    game.bossName.value = lineup.map((s) => s.name).join(' + ');
  }

  /// Aggregate HP bar across all living bosses in the fight.
  void updateBossBar() {
    final bosses = game.runRoot.children.query<Boss>();
    final total =
        bosses.fold<double>(0, (sum, b) => sum + b.healthFraction);
    game.bossHealth.value = (total / _bossCount).clamp(0.0, 1.0);
  }

  void onBossDefeated() {
    if (phase != LevelPhase.boss) return;
    _bossesRemaining--;
    updateBossBar();
    if (_bossesRemaining > 0) return;

    game.bossHealth.value = null;
    game.bossName.value = null;
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
