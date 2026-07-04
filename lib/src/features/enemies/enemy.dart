import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'package:astro_nova/src/game/astro_nova_game.dart';
import 'package:astro_nova/src/core/palette.dart';
import 'package:astro_nova/src/features/combat/bullet.dart';
import 'package:astro_nova/src/features/combat/explosion.dart';
import 'package:astro_nova/src/features/powerups/power_up.dart';

enum EnemyType {
  /// Slow straight-line faller. Cannon fodder.
  drifter(hp: 1, speed: 90, score: 10, color: Palette.enemyDrifter, radius: 16),

  /// Fast sine-wave weaver, harder to lead.
  weaver(hp: 2, speed: 140, score: 25, color: Palette.enemyWeaver, radius: 14),

  /// Slow bullet sponge. Big score payout.
  tank(hp: 6, speed: 45, score: 60, color: Palette.enemyTank, radius: 24),

  /// Unlocks at level 3: narrow arrow that accelerates as it falls.
  darter(hp: 1, speed: 150, score: 20, color: Color(0xFF64FFDA), radius: 12),

  /// Unlocks at level 6: pentagon that splits into two drifters on death.
  splitter(hp: 3, speed: 70, score: 40, color: Color(0xFF448AFF), radius: 20),

  /// Unlocks at level 9: ghostly orb that phases in and out while strafing.
  phantom(hp: 2, speed: 60, score: 50, color: Color(0xFFE0E0E0), radius: 15);

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
    with HasGameReference<AstroNovaGame>
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

    switch (type) {
      case EnemyType.darter:
        // Accelerates the longer it falls.
        position.y += type.speed * speedMultiplier * (1 + _age * 0.9) * dt;
      case EnemyType.weaver:
        position.y += type.speed * speedMultiplier * dt;
        position.x += sin(_age * 4 + _waveOffset) * 90 * dt;
      case EnemyType.phantom:
        position.y += type.speed * speedMultiplier * dt;
        position.x += sin(_age * 2.2 + _waveOffset) * 140 * dt;
      default:
        position.y += type.speed * speedMultiplier * dt;
    }
    position.x = position.x.clamp(type.radius, AstroNovaGame.worldWidth - type.radius);

    if (position.y > AstroNovaGame.worldHeight + height) {
      removeFromParent();
    }
  }

  @override
  void takeHit(int damage) {
    // Invulnerable until fully on screen — stops high-tier weapons from
    // clearing spawns before the player ever sees them.
    if (position.y < type.radius) return;
    // Phantoms can only be hurt while mostly phased in.
    if (type == EnemyType.phantom && _phaseAlpha < 0.5) return;
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
      color: _themedColor(),
      count: type == EnemyType.tank ? 40 : 22,
    ));
    if (type == EnemyType.splitter) {
      for (final dx in const [-22.0, 22.0]) {
        game.spawn(Enemy(
          type: EnemyType.drifter,
          position: position + Vector2(dx, 6),
          speedMultiplier: speedMultiplier * 1.25,
        ));
      }
    }
    PowerUp.maybeDrop(game, position.clone());
    removeFromParent();
  }

  double get _phaseAlpha => type == EnemyType.phantom
      ? 0.25 + 0.75 * sin(_age * 3 + _waveOffset).abs()
      : 1.0;

  /// Base color blended toward the level theme's accent, so the same enemy
  /// type looks different in every sector of the campaign.
  Color _themedColor() =>
      Color.lerp(type.color, game.theme.accent, 0.35)!;

  @override
  void render(Canvas canvas) {
    final r = type.radius;
    final center = Offset(r, r);
    var color = _hitFlash > 0
        ? Color.lerp(_themedColor(), const Color(0xFFFFFFFF), _hitFlash)!
        : _themedColor();
    final alpha = _phaseAlpha;

    final glow = Paint()
      ..color = color.withValues(alpha: 0.45 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final stroke = Paint()
      ..color = color.withValues(alpha: alpha)
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
    // Phantoms get an inner ghost-ring.
    if (type == EnemyType.phantom) {
      canvas.drawCircle(
        center,
        r * 0.45,
        Paint()
          ..color = color.withValues(alpha: 0.5 * alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
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
        return _polygon(6, r, c, startAngle: pi / 6);
      case EnemyType.darter:
        // Narrow downward arrow.
        return Path()
          ..moveTo(c.dx, c.dy + r)
          ..lineTo(c.dx - r * 0.45, c.dy - r)
          ..lineTo(c.dx, c.dy - r * 0.55)
          ..lineTo(c.dx + r * 0.45, c.dy - r)
          ..close();
      case EnemyType.splitter:
        return _polygon(5, r, c, startAngle: -pi / 2);
      case EnemyType.phantom:
        return Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.9));
    }
  }

  Path _polygon(int sides, double r, Offset c, {double startAngle = 0}) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final a = startAngle + i * 2 * pi / sides;
      final p = Offset(c.dx + r * cos(a), c.dy + r * sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }
}
