import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../astro_nova_game.dart';

/// Boss projectile. The player handles the collision side.
class EnemyBullet extends PositionComponent
    with HasGameReference<AstroNovaGame> {
  EnemyBullet({
    required Vector2 position,
    required this.velocity,
    required this.color,
  }) : super(position: position, size: Vector2.all(11), anchor: Anchor.center);

  final Vector2 velocity;
  final Color color;

  @override
  void onLoad() {
    add(CircleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    position += velocity * dt;
    if (position.y > AstroNovaGame.worldHeight + 30 ||
        position.y < -30 ||
        position.x < -30 ||
        position.x > AstroNovaGame.worldWidth + 30) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final center = (size / 2).toOffset();
    canvas.drawCircle(
      center,
      width / 2,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(center, width / 3.2, Paint()..color = color);
  }
}
