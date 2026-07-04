import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import 'package:astro_nova/src/game/astro_nova_game.dart';

class _Star {
  _Star(this.position, this.speed, this.radius, this.layer);

  final Vector2 position;
  final double speed;
  final double radius;
  final int layer;
}

/// Three-layer parallax starfield. Stars scroll downward at layer-specific
/// speeds and wrap back to the top; colors follow the current level theme.
class Starfield extends Component with HasGameReference<AstroNovaGame> {
  Starfield({this.starsPerLayer = 40}) : super(priority: -5);

  final int starsPerLayer;
  final List<_Star> _stars = [];
  final _random = Random();

  static const _layers = [
    (speed: 25.0, radius: 1.0),
    (speed: 55.0, radius: 1.5),
    (speed: 110.0, radius: 2.2),
  ];

  @override
  void onLoad() {
    for (var layer = 0; layer < _layers.length; layer++) {
      for (var i = 0; i < starsPerLayer; i++) {
        _stars.add(_Star(
          Vector2(
            _random.nextDouble() * AstroNovaGame.worldWidth,
            _random.nextDouble() * AstroNovaGame.worldHeight,
          ),
          _layers[layer].speed * (0.8 + _random.nextDouble() * 0.4),
          _layers[layer].radius,
          layer,
        ));
      }
    }
  }

  @override
  void update(double dt) {
    for (final star in _stars) {
      star.position.y += star.speed * dt;
      if (star.position.y > AstroNovaGame.worldHeight) {
        star.position.y = 0;
        star.position.x = _random.nextDouble() * AstroNovaGame.worldWidth;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final theme = game.theme;
    final paint = Paint();
    for (final star in _stars) {
      paint.color = star.layer < 2 ? theme.starDim : theme.starBright;
      canvas.drawCircle(star.position.toOffset(), star.radius, paint);
    }
  }
}
