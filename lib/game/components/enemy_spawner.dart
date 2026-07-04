import 'dart:math';

import 'package:flame/components.dart';

import '../neon_void_game.dart';
import 'enemy.dart';

/// Level-driven spawner. The [LevelManager] toggles [enabled] (off during
/// boss fights) and calls [configureForLevel] on every level change.
///
/// Difficulty curve: gentle through level 7, a modest bump for 8-10 so the
/// finale feels earned but stays beatable.
class EnemySpawner extends Component with HasGameReference<NeonVoidGame> {
  final _random = Random();
  double _sinceLastSpawn = 0;

  bool enabled = false;
  double _interval = 1.2;
  double _weaverWeight = 0.12;
  double _tankWeight = 0.05;
  int _bonusHp = 0;
  double _speedMultiplier = 1.0;

  void configureForLevel(int level) {
    if (level <= 7) {
      _interval = 1.25 - 0.06 * level;
      _bonusHp = 0;
      _speedMultiplier = 1.0 + 0.02 * (level - 1);
    } else {
      _interval = 0.82 - 0.08 * (level - 7);
      _bonusHp = 1;
      _speedMultiplier = 1.15 + 0.05 * (level - 8);
    }
    _weaverWeight = 0.10 + 0.03 * level;
    _tankWeight = 0.04 + 0.02 * level;
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

  EnemyType _pickType() {
    final roll = _random.nextDouble();
    if (roll < _tankWeight) return EnemyType.tank;
    if (roll < _tankWeight + _weaverWeight) return EnemyType.weaver;
    return EnemyType.drifter;
  }
}
