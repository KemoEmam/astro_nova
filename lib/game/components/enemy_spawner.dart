import 'dart:math';

import 'package:flame/components.dart';

import '../neon_void_game.dart';
import 'enemy.dart';

/// Spawns enemies on a timer whose interval shrinks as the run goes on,
/// and shifts the type distribution toward tougher enemies over time.
class EnemySpawner extends Component with HasGameReference<NeonVoidGame> {
  final _random = Random();
  double _elapsed = 0;
  double _sinceLastSpawn = 0;

  static const _startInterval = 1.1;
  static const _minInterval = 0.35;

  /// Seconds it takes to ramp from start to max difficulty.
  static const _rampDuration = 90.0;

  double get _difficulty => min(1, _elapsed / _rampDuration);

  double get _interval =>
      _startInterval - (_startInterval - _minInterval) * _difficulty;

  @override
  void update(double dt) {
    _elapsed += dt;
    _sinceLastSpawn += dt;
    if (_sinceLastSpawn >= _interval) {
      _sinceLastSpawn = 0;
      _spawn();
    }
  }

  void _spawn() {
    final type = _pickType();
    final margin = type.radius + 4;
    game.world.add(Enemy(
      type: type,
      position: Vector2(
        margin + _random.nextDouble() * (NeonVoidGame.worldWidth - margin * 2),
        -type.radius * 2,
      ),
    ));
  }

  EnemyType _pickType() {
    // Weights drift from all-drifters early to a mixed field late.
    final weaverWeight = 0.15 + 0.25 * _difficulty;
    final tankWeight = 0.05 + 0.20 * _difficulty;
    final roll = _random.nextDouble();
    if (roll < tankWeight) return EnemyType.tank;
    if (roll < tankWeight + weaverWeight) return EnemyType.weaver;
    return EnemyType.drifter;
  }
}
