import 'dart:ui';

import 'package:flame/components.dart';

import '../astro_nova_game.dart';

/// Full-screen backdrop that smoothly lerps to the current level theme's
/// background color, so level transitions feel like flying into a new region.
class Background extends PositionComponent
    with HasGameReference<AstroNovaGame> {
  Background()
      : super(
          size: Vector2(AstroNovaGame.worldWidth, AstroNovaGame.worldHeight),
          priority: -10,
        );

  Color? _current;

  @override
  void update(double dt) {
    final target = game.theme.background;
    _current = Color.lerp(_current ?? target, target, (dt * 1.5).clamp(0, 1));
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = _current ?? game.theme.background);
  }
}
