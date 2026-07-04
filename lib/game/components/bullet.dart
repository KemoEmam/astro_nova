import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../neon_void_game.dart';
import '../palette.dart';
import 'enemy.dart';

class Bullet extends PositionComponent
    with CollisionCallbacks, HasGameReference<NeonVoidGame> {
  Bullet({required Vector2 position, this.damage = 1})
      : super(
          position: position,
          size: Vector2(4, 14),
          anchor: Anchor.center,
        );

  final int damage;
  static const _speed = 620.0;

  static final _glowPaint = Paint()
    ..color = Palette.bullet.withValues(alpha: 0.5)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final _corePaint = Paint()..color = Palette.bullet;

  @override
  void onLoad() {
    add(RectangleHitbox(collisionType: CollisionType.active));
  }

  @override
  void update(double dt) {
    position.y -= _speed * dt;
    if (position.y < -height) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(2));
    canvas.drawRRect(rect, _glowPaint);
    canvas.drawRRect(rect.deflate(1), _corePaint);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Enemy) {
      other.takeHit(damage);
      removeFromParent();
    }
  }
}
