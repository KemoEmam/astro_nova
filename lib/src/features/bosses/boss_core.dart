import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'package:astro_nova/src/game/astro_nova_game.dart';

/// Boss-only reward: exactly one core drops per boss fight (when the last
/// boss of the level dies). Collecting it grants that level's unique
/// permanent run-buff. The player handles the collision side.
class BossCore extends PositionComponent with HasGameReference<AstroNovaGame> {
  BossCore({required Vector2 position, required this.relicLevel})
      : super(position: position, size: Vector2.all(34), anchor: Anchor.center, priority: 25);

  /// Level whose relic this core grants — captured at drop time so a core
  /// collected during the level transition still gives the right reward.
  final int relicLevel;

  double _age = 0;
  static const _fallSpeed = 35.0;
  static const _color = Color(0xFFFFD740);

  @override
  void onLoad() {
    add(CircleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    _age += dt;
    position.y += _fallSpeed * dt;

    // Cores always drift gently toward the player; with the MAGNET CORE
    // relic (like all pickups) they snap in hard.
    final playerPos = game.player?.position;
    if (playerPos != null) {
      final toPlayer = playerPos - position;
      final range = game.magnet ? 400.0 : 220.0;
      final pull = game.magnet ? 260.0 : 90.0;
      if (toPlayer.length < range) {
        position += toPlayer.normalized() * pull * dt;
      }
    }

    if (position.y > AstroNovaGame.worldHeight + height) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final center = (size / 2).toOffset();
    final pulse = 1 + 0.12 * sin(_age * 5);
    final r = width / 2 * pulse;

    // Halo.
    canvas.drawCircle(
      center,
      r * 1.5,
      Paint()
        ..color = _color.withValues(alpha: 0.25 + 0.1 * sin(_age * 3))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Rotating 8-point star.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_age * 1.8);
    final star = Path();
    for (var i = 0; i < 16; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final a = i * pi / 8;
      final p = Offset(radius * cos(a), radius * sin(a));
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    canvas.drawPath(
      star,
      Paint()
        ..color = _color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      star,
      Paint()
        ..color = _color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();

    // White-hot center.
    canvas.drawCircle(center, r * 0.22, Paint()..color = const Color(0xFFFFFFFF));
  }
}
