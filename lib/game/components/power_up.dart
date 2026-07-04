import 'dart:math';
import 'dart:ui' hide TextStyle;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/painting.dart' show TextStyle;

import '../neon_void_game.dart';
import '../palette.dart';

enum PowerUpType {
  weapon(Palette.powerUpWeapon, 'W'),
  shield(Palette.powerUpShield, 'S');

  const PowerUpType(this.color, this.glyph);

  final Color color;
  final String glyph;
}

class PowerUp extends PositionComponent with HasGameReference<NeonVoidGame> {
  PowerUp({required this.type, required Vector2 position})
      : super(position: position, size: Vector2.all(28), anchor: Anchor.center);

  final PowerUpType type;
  double _age = 0;

  static const dropChance = 0.12;
  static const _fallSpeed = 80.0;
  static final _random = Random();

  /// Rolls the drop chance; call on every enemy kill.
  static void maybeDrop(NeonVoidGame game, Vector2 position) {
    if (_random.nextDouble() < dropChance) {
      final type =
          PowerUpType.values[_random.nextInt(PowerUpType.values.length)];
      game.world.add(PowerUp(type: type, position: position));
    }
  }

  @override
  void onLoad() {
    add(CircleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    _age += dt;
    position.y += _fallSpeed * dt;
    if (position.y > NeonVoidGame.worldHeight + height) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final center = (size / 2).toOffset();
    final pulse = 0.85 + 0.15 * sin(_age * 6);
    final r = width / 2 * pulse;

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = type.color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = type.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final textPainter = TextPaint(
      style: TextStyle(
        color: type.color,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.render(canvas, type.glyph, center.toVector2(),
        anchor: Anchor.center);
  }
}
