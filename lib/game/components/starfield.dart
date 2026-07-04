import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../neon_void_game.dart';
import '../palette.dart';

class _Star {
  _Star(this.position, this.speed, this.radius, this.color);

  final Vector2 position;
  final double speed;
  final double radius;
  final Color color;
}

/// Three-layer parallax starfield. Stars scroll downward at layer-specific
/// speeds and wrap back to the top, so the field never needs respawning.
class Starfield extends Component with HasGameReference<NeonVoidGame> {
  Starfield({this.starsPerLayer = 40});

  final int starsPerLayer;
  final List<_Star> _stars = [];
  final _random = Random();

  static const _layers = [
    (speed: 25.0, radius: 1.0, color: Palette.starDim),
    (speed: 55.0, radius: 1.5, color: Palette.starDim),
    (speed: 110.0, radius: 2.2, color: Palette.starBright),
  ];

  @override
  void onLoad() {
    for (final layer in _layers) {
      for (var i = 0; i < starsPerLayer; i++) {
        _stars.add(_Star(
          Vector2(
            _random.nextDouble() * NeonVoidGame.worldWidth,
            _random.nextDouble() * NeonVoidGame.worldHeight,
          ),
          layer.speed * (0.8 + _random.nextDouble() * 0.4),
          layer.radius,
          layer.color,
        ));
      }
    }
  }

  @override
  void update(double dt) {
    for (final star in _stars) {
      star.position.y += star.speed * dt;
      if (star.position.y > NeonVoidGame.worldHeight) {
        star.position.y = 0;
        star.position.x = _random.nextDouble() * NeonVoidGame.worldWidth;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint();
    for (final star in _stars) {
      paint.color = star.color;
      canvas.drawCircle(star.position.toOffset(), star.radius, paint);
    }
  }
}
