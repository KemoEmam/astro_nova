import 'dart:math';

import 'package:flame/components.dart';

import '../neon_void_game.dart';
import 'enemy.dart';

/// Level-driven spawner. The [LevelManager] toggles [enabled] (off during
/// boss fights) and calls [configureForLevel] on every level change.
///
/// Difficulty ramps smoothly across the whole campaign: spawn interval,
/// enemy speed, spawn mix, and bonus HP all scale with the level while
/// staying beatable — the player's weapon curve grows faster.
class EnemySpawner extends Component with HasGameReference<NeonVoidGame> {
  final _random = Random();
  double _sinceLastSpawn = 0;

  bool enabled = false;
  int _level = 1;
  double _interval = 1.2;
  int _bonusHp = 0;
  double _speedMultiplier = 1.0;

  void configureForLevel(int level) {
    _level = level;
    _interval = max(0.52, 1.2 - 0.075 * (level - 1));
    _speedMultiplier = 1.0 + 0.045 * (level - 1);
    _bonusHp = level < 4 ? 0 : (level - 1) ~/ 3;
  }

  @override
  void update(double dt) {
    if (!enabled) return;
    _sinceLastSpawn += dt;
    if (_sinceLastSpawn >= _interval) {
      _sinceLastSpawn = 0;
      _spawn();
    }
  }

  void _spawn() {
    final type = _pickType();
    final margin = type.radius + 4;
    game.spawn(Enemy(
      type: type,
      position: Vector2(
        margin + _random.nextDouble() * (NeonVoidGame.worldWidth - margin * 2),
        -type.radius * 2,
      ),
      bonusHp: _bonusHp,
      speedMultiplier: _speedMultiplier,
    ));
  }

  /// Weighted spawn table. New enemy types unlock every 3 levels (darter at
  /// 3, splitter at 6, phantom at 9) and each type's weight keeps growing
  /// after it unlocks; drifters absorb whatever weight is left.
  EnemyType _pickType() {
    final weights = <EnemyType, double>{
      EnemyType.tank: 0.04 + 0.022 * _level,
      EnemyType.weaver: 0.10 + 0.035 * _level,
      if (_level >= 3) EnemyType.darter: 0.10 + 0.02 * (_level - 3),
      if (_level >= 6) EnemyType.splitter: 0.08 + 0.02 * (_level - 6),
      if (_level >= 9) EnemyType.phantom: 0.10 + 0.03 * (_level - 9),
    };
    var roll = _random.nextDouble();
    for (final entry in weights.entries) {
      if (roll < entry.value) return entry.key;
      roll -= entry.value;
    }
    return EnemyType.drifter;
  }
}
