import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'package:astro_nova/src/game/astro_nova_game.dart';
import 'package:astro_nova/src/core/palette.dart';
import 'package:astro_nova/src/features/player/weapon.dart';

/// Anything a player bullet can hurt (regular enemies and bosses).
abstract interface class Damageable {
  void takeHit(int damage);
  Vector2 get position;
  bool get isMounted;
}

class Bullet extends PositionComponent
    with CollisionCallbacks, HasGameReference<AstroNovaGame> {
  Bullet({
    required Vector2 position,
    Vector2? direction,
    this.damage = 1,
    this.pierce = 0,
    this.homing = false,
    this.color = Palette.bullet,
    this.shape = BulletShape.bolt,
  }) : super(
          position: position,
          size: Vector2(3.0 + damage * 1.5, 12.0 + damage * 3),
          anchor: Anchor.center,
        ) {
    _velocity = (direction ?? Vector2(0, -1)).normalized() * _speed;
    if (shape == BulletShape.beam) size.y += 10;
    if (shape == BulletShape.orb) size.x += 3;
  }

  final int damage;
  int pierce;
  final bool homing;
  final Color color;
  final BulletShape shape;
  late Vector2 _velocity;

  static const _speed = 620.0;
  static const _homingTurnRate = 5.5; // rad/s
  static const _homingColor = Color(0xFFFFAB91);

  @override
  void onLoad() {
    add(RectangleHitbox(collisionType: CollisionType.active));
  }

  @override
  void update(double dt) {
    if (homing) _steer(dt);
    position += _velocity * dt;
    angle = atan2(_velocity.x, -_velocity.y);
    if (position.y < -30 ||
        position.y > AstroNovaGame.worldHeight + 30 ||
        position.x < -30 ||
        position.x > AstroNovaGame.worldWidth + 30) {
      removeFromParent();
    }
  }

  void _steer(double dt) {
    Damageable? nearest;
    var nearestDist = double.infinity;
    for (final target in game.targets) {
      final d = target.position.distanceToSquared(position);
      if (d < nearestDist) {
        nearestDist = d;
        nearest = target;
      }
    }
    if (nearest == null) return;

    final desired = (nearest.position - position)..normalize();
    final current = _velocity.normalized();
    final currentAngle = atan2(current.y, current.x);
    final desiredAngle = atan2(desired.y, desired.x);
    var diff = desiredAngle - currentAngle;
    while (diff > pi) {
      diff -= 2 * pi;
    }
    while (diff < -pi) {
      diff += 2 * pi;
    }
    final turn = diff.clamp(-_homingTurnRate * dt, _homingTurnRate * dt);
    final newAngle = currentAngle + turn;
    _velocity = Vector2(cos(newAngle), sin(newAngle)) * _speed;
  }

  @override
  void render(Canvas canvas) {
    final drawColor = homing ? _homingColor : color;
    final glow = Paint()
      ..color = drawColor.withValues(alpha: 0.55)
      ..maskFilter = MaskFilter.blur(
          BlurStyle.normal, shape == BulletShape.beam ? 7 : 4);
    final core = Paint()..color = drawColor;

    switch (homing ? BulletShape.diamond : shape) {
      case BulletShape.bolt:
        final rect = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(2));
        canvas.drawRRect(rect, glow);
        canvas.drawRRect(rect.deflate(1), core);
      case BulletShape.diamond:
        final path = Path()
          ..moveTo(width / 2, 0)
          ..lineTo(width, height / 2)
          ..lineTo(width / 2, height)
          ..lineTo(0, height / 2)
          ..close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, core);
      case BulletShape.orb:
        final center = Offset(width / 2, height / 2);
        canvas.drawCircle(center, width * 0.9, glow);
        canvas.drawCircle(center, width * 0.55, core);
        canvas.drawCircle(center, width * 0.25,
            Paint()..color = const Color(0xFFFFFFFF));
      case BulletShape.beam:
        final rect = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(3));
        canvas.drawRRect(rect.inflate(2), glow);
        canvas.drawRRect(rect, core);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(width * 0.3, 2, width * 0.4, height - 4),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFFFFFFFF),
        );
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Damageable) {
      (other as Damageable).takeHit(damage);
      if (pierce <= 0) {
        removeFromParent();
      } else {
        pierce--;
      }
    }
  }
}
