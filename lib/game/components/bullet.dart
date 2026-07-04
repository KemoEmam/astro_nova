import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../neon_void_game.dart';
import '../palette.dart';

/// Anything a player bullet can hurt (regular enemies and bosses).
abstract interface class Damageable {
  void takeHit(int damage);
  Vector2 get position;
  bool get isMounted;
}

class Bullet extends PositionComponent
    with CollisionCallbacks, HasGameReference<NeonVoidGame> {
  Bullet({
    required Vector2 position,
    Vector2? direction,
    this.damage = 1,
    this.pierce = 0,
    this.homing = false,
  }) : super(
          position: position,
          size: Vector2(3.0 + damage * 1.5, 12.0 + damage * 3),
          anchor: Anchor.center,
        ) {
    _velocity = (direction ?? Vector2(0, -1)).normalized() * _speed;
  }

  final int damage;
  int pierce;
  final bool homing;
  late Vector2 _velocity;

  static const _speed = 620.0;
  static const _homingTurnRate = 5.5; // rad/s

  static final _glowPaint = Paint()
    ..color = Palette.bullet.withValues(alpha: 0.5)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final _corePaint = Paint()..color = Palette.bullet;
  static final _homingGlow = Paint()
    ..color = const Color(0xFFFF6E40).withValues(alpha: 0.6)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  static final _homingCore = Paint()..color = const Color(0xFFFFAB91);

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
        position.y > NeonVoidGame.worldHeight + 30 ||
        position.x < -30 ||
        position.x > NeonVoidGame.worldWidth + 30) {
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
    final rect = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(2));
    canvas.drawRRect(rect, homing ? _homingGlow : _glowPaint);
    canvas.drawRRect(rect.deflate(1), homing ? _homingCore : _corePaint);
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
