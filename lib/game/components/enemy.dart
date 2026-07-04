import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../neon_void_game.dart';
import '../palette.dart';
import 'bullet.dart';
import 'explosion.dart';
import 'power_up.dart';

enum EnemyType {
  /// Slow straight-line faller. Cannon fodder.
  drifter(hp: 1, speed: 90, score: 10, color: Palette.enemyDrifter, radius: 16),

  /// Fast sine-wave weaver, harder to lead.
  weaver(hp: 2, speed: 140, score: 25, color: Palette.enemyWeaver, radius: 14),

  /// Slow bullet sponge. Big score payout.
  tank(hp: 6, speed: 45, score: 60, color: Palette.enemyTank, radius: 24);

  const EnemyType({
    required this.hp,
    required this.speed,
    required this.score,
    required this.color,
    required this.radius,
  });

  final int hp;
  final double speed;
  final int score;
  final Color color;
  final double radius;
}

class Enemy extends PositionComponent
    with HasGameReference<NeonVoidGame>
    implements Damageable {
  Enemy({
    required this.type,
    required Vector2 position,
    int bonusHp = 0,
    this.speedMultiplier = 1.0,
  })  : maxHp = type.hp + bonusHp,
        _hp = type.hp + bonusHp,
        super(
          position: position,
          size: Vector2.all(type.radius * 2),
          anchor: Anchor.center,
        );

  final EnemyType type;
  final int maxHp;
  final double speedMultiplier;
  int _hp;
  double _age = 0;
  double _hitFlash = 0;
  late final double _waveOffset = Random().nextDouble() * 2 * pi;

  @override
  void onLoad() {
    add(CircleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    _age += dt;
    _hitFlash = max(0, _hitFlash - dt * 6);
    position.y += type.speed * speedMultiplier * dt;
    if (type == EnemyType.weaver) {
      position.x += sin(_age * 4 + _waveOffset) * 90 * dt;
      position.x = position.x.clamp(type.radius, NeonVoidGame.worldWidth - type.radius);
    }
    if (position.y > NeonVoidGame.worldHeight + height) {
      removeFromParent();
    }
  }

  @override
  void takeHit(int damage) {
    // Invulnerable until fully on screen — stops high-tier weapons from
    // clearing spawns before the player ever sees them.
    if (position.y < type.radius) return;
    _hp -= damage;
    _hitFlash = 1;
    if (_hp <= 0) {
      die();
    }
  }

  /// Kill from gameplay (bullet, ramming the player, or a shield shockwave):
  /// score, explosion, possible power-up drop.
  void die() {
    game.addScore(type.score);
    game.spawn(explosion(
      position: position.clone(),
      color: type.color,
      count: type == EnemyType.tank ? 40 : 22,
    ));
    PowerUp.maybeDrop(game, position.clone());
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final r = type.radius;
    final center = Offset(r, r);
    final color = _hitFlash > 0
        ? Color.lerp(type.color, const Color(0xFFFFFFFF), _hitFlash)!
        : type.color;

    final glow = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = _shapePath(r, center);
    canvas.drawPath(path, glow);
    canvas.drawPath(path, stroke);

    // Tanks show remaining HP as an inner ring that shrinks with damage.
    if (type == EnemyType.tank) {
      canvas.drawCircle(
        center,
        r * 0.5 * (_hp / maxHp),
        Paint()..color = color.withValues(alpha: 0.6),
      );
    }
  }

  Path _shapePath(double r, Offset c) {
    switch (type) {
      case EnemyType.drifter:
        // Downward-pointing triangle.
        return Path()
          ..moveTo(c.dx, c.dy + r)
          ..lineTo(c.dx - r * 0.9, c.dy - r * 0.7)
          ..lineTo(c.dx + r * 0.9, c.dy - r * 0.7)
          ..close();
      case EnemyType.weaver:
        // Diamond.
        return Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r * 0.75, c.dy)
          ..lineTo(c.dx, c.dy + r)
          ..lineTo(c.dx - r * 0.75, c.dy)
          ..close();
      case EnemyType.tank:
        // Hexagon.
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final a = pi / 6 + i * pi / 3;
          final p = Offset(c.dx + r * cos(a), c.dy + r * sin(a));
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        return path..close();
    }
  }
}
