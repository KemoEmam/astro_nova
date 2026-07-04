import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../astro_nova_game.dart';
import 'bullet.dart';
import 'enemy.dart';
import 'enemy_bullet.dart';
import 'explosion.dart';

enum BossMovement { strafe, figure8, dive, teleport }

enum BossAttack { aimed, radial, spiral, spread, summon }

class BossSpec {
  const BossSpec({
    required this.name,
    required this.color,
    required this.hp,
    required this.radius,
    required this.points,
    this.star = false,
    required this.movement,
    required this.attacks,
    required this.attackInterval,
    required this.bulletSpeed,
  });

  final String name;
  final Color color;
  final int hp;
  final double radius;

  /// Polygon vertex count; with [star] true it renders as a star instead.
  final int points;
  final bool star;
  final BossMovement movement;
  final List<BossAttack> attacks;
  final double attackInterval;
  final double bulletSpeed;
}

/// One hand-tuned boss per level. HP and attack pressure climb steadily
/// through the whole campaign — the player's 30-tier weapon curve grows
/// faster, so fights stay beatable while feeling meaner each level.
const bossSpecs = <BossSpec>[
  BossSpec(name: 'SENTINEL', color: Color(0xFFFF4081), hp: 70, radius: 30, points: 3, movement: BossMovement.strafe, attacks: [BossAttack.aimed], attackInterval: 1.7, bulletSpeed: 150),
  BossSpec(name: 'TWIN FANG', color: Color(0xFFFF6E40), hp: 105, radius: 30, points: 4, star: true, movement: BossMovement.strafe, attacks: [BossAttack.spread, BossAttack.aimed], attackInterval: 1.65, bulletSpeed: 160),
  BossSpec(name: 'HEXEN', color: Color(0xFF69F0AE), hp: 145, radius: 32, points: 6, movement: BossMovement.figure8, attacks: [BossAttack.radial, BossAttack.aimed], attackInterval: 1.7, bulletSpeed: 150),
  BossSpec(name: 'WIDOW', color: Color(0xFFFFAB40), hp: 190, radius: 30, points: 5, star: true, movement: BossMovement.strafe, attacks: [BossAttack.aimed, BossAttack.spread], attackInterval: 1.5, bulletSpeed: 170),
  BossSpec(name: 'BULWARK', color: Color(0xFF448AFF), hp: 240, radius: 40, points: 8, movement: BossMovement.strafe, attacks: [BossAttack.radial, BossAttack.summon, BossAttack.spread], attackInterval: 1.5, bulletSpeed: 160),
  BossSpec(name: 'PHANTOM', color: Color(0xFFE040FB), hp: 290, radius: 28, points: 6, star: true, movement: BossMovement.teleport, attacks: [BossAttack.aimed, BossAttack.spread], attackInterval: 1.35, bulletSpeed: 180),
  BossSpec(name: 'VORTEX', color: Color(0xFF64FFDA), hp: 345, radius: 32, points: 7, star: true, movement: BossMovement.figure8, attacks: [BossAttack.spiral], attackInterval: 0.48, bulletSpeed: 170),
  BossSpec(name: 'REAPER', color: Color(0xFFFF5252), hp: 400, radius: 30, points: 5, star: true, movement: BossMovement.dive, attacks: [BossAttack.spread, BossAttack.aimed, BossAttack.radial], attackInterval: 1.2, bulletSpeed: 195),
  BossSpec(name: 'HYDRA', color: Color(0xFFFFD740), hp: 460, radius: 36, points: 9, movement: BossMovement.figure8, attacks: [BossAttack.radial, BossAttack.summon, BossAttack.spread, BossAttack.aimed], attackInterval: 1.1, bulletSpeed: 205),
  BossSpec(name: 'VOID PRIME', color: Color(0xFFEEFF41), hp: 540, radius: 42, points: 8, star: true, movement: BossMovement.teleport, attacks: [BossAttack.spiral, BossAttack.radial, BossAttack.aimed], attackInterval: 0.95, bulletSpeed: 220),
];

class Boss extends PositionComponent
    with HasGameReference<AstroNovaGame>
    implements Damageable {
  Boss({
    required this.spec,
    double? centerX,
    this.amplitude = 130,
    this.hpScale = 1.0,
  })  : centerX = centerX ?? AstroNovaGame.worldWidth / 2,
        super(
          position: Vector2(centerX ?? AstroNovaGame.worldWidth / 2, -80),
          size: Vector2.all(spec.radius * 2),
          anchor: Anchor.center,
          priority: 10,
        );

  final BossSpec spec;

  /// Patrol center / sway amplitude — narrowed for multi-boss fights so
  /// bosses hold their own lane instead of stacking.
  final double centerX;
  final double amplitude;

  /// HP multiplier (<1 in multi-boss fights to keep total HP fair).
  final double hpScale;

  late int _maxHp;
  late int _hp;

  /// True once this boss has died (set before deferred removal completes,
  /// so "how many bosses are still fighting" checks are race-free).
  bool isDefeated = false;

  double get healthFraction => (_hp / _maxHp).clamp(0.0, 1.0);
  double _age = 0;
  double _hitFlash = 0;
  double _attackTimer = 0;
  double _spiralAngle = 0;
  double _teleportTimer = 0;
  int _attackIndex = 0;
  bool _entering = true;

  static const _baseY = 140.0;
  final _random = Random();

  @override
  void onLoad() {
    add(CircleHitbox(collisionType: CollisionType.passive));
    // Per-level HP growth: steeper past level 3, steeper again past level 5
    // to keep pace with the Boss Core buff windows. Shaved by a global 0.92
    // to keep fights snappy.
    final level = game.level.value;
    final growth = 1 +
        0.05 * (level - 1) +
        (level > 3 ? 0.03 * (level - 3) : 0) +
        (level >= 5 ? 0.08 * (level - 4) : 0);
    _maxHp = (spec.hp * hpScale * 0.92 * growth).round();
    _hp = _maxHp;
  }

  @override
  void update(double dt) {
    _age += dt;
    _hitFlash = max(0, _hitFlash - dt * 6);

    if (_entering) {
      // Cinematic fly-in.
      position.y += (_baseY - position.y) * min(1, dt * 2.2);
      if (position.y > _baseY - 4) {
        _entering = false;
        game.shake(6);
      }
      return;
    }

    _move(dt);

    _attackTimer += dt;
    if (_attackTimer >= spec.attackInterval) {
      _attackTimer = 0;
      _attack(spec.attacks[_attackIndex % spec.attacks.length]);
      _attackIndex++;
    }
  }

  void _move(double dt) {
    final cx = centerX;
    final amp = amplitude;
    switch (spec.movement) {
      case BossMovement.strafe:
        position.x = cx + sin(_age * 0.9) * amp;
        position.y = _baseY + sin(_age * 1.7) * 12;
      case BossMovement.figure8:
        position.x = cx + sin(_age * 1.1) * amp;
        position.y = _baseY + sin(_age * 2.2) * 45;
      case BossMovement.dive:
        position.x = cx + sin(_age * 1.2) * amp;
        position.y = _baseY + max(0.0, sin(_age * 0.8)) * 200;
      case BossMovement.teleport:
        _teleportTimer += dt;
        if (_teleportTimer >= 2.4) {
          _teleportTimer = 0;
          position.x = (cx + (_random.nextDouble() * 2 - 1) * amp)
              .clamp(spec.radius, AstroNovaGame.worldWidth - spec.radius);
          position.y = _baseY + _random.nextDouble() * 60;
          game.shake(3);
        }
    }
  }

  void _attack(BossAttack attack) {
    final playerPos = game.player?.position;
    switch (attack) {
      case BossAttack.aimed:
        if (playerPos == null) return;
        final dir = (playerPos - position).normalized();
        _shoot(dir * spec.bulletSpeed);
      case BossAttack.spread:
        for (var i = -2; i <= 2; i++) {
          final a = pi / 2 + i * 0.28; // fanned around straight down
          _shoot(Vector2(cos(a), sin(a)) * spec.bulletSpeed);
        }
      case BossAttack.radial:
        for (var i = 0; i < 12; i++) {
          final a = i * pi / 6 + _age;
          _shoot(Vector2(cos(a), sin(a)) * spec.bulletSpeed * 0.85);
        }
      case BossAttack.spiral:
        _spiralAngle += 0.5;
        for (var i = 0; i < 3; i++) {
          final a = _spiralAngle + i * 2 * pi / 3;
          _shoot(Vector2(cos(a), sin(a)) * spec.bulletSpeed * 0.9);
        }
      case BossAttack.summon:
        for (var i = 0; i < 3; i++) {
          game.spawn(Enemy(
            type: EnemyType.drifter,
            position: Vector2(60.0 + i * 140, -20),
          ));
        }
    }
  }

  void _shoot(Vector2 velocity) {
    game.spawn(EnemyBullet(
      position: position.clone(),
      velocity: velocity,
      color: spec.color,
    ));
  }

  @override
  void takeHit(int damage) {
    if (_entering) return; // invincible during the fly-in
    _hp -= damage;
    _hitFlash = 1;
    game.levelManager?.updateBossBar();
    if (_hp <= 0) {
      _die();
    }
  }

  void _die() {
    if (isDefeated) return;
    isDefeated = true;
    game.addScore(150 + 100 * game.level.value);
    game.shake(14);
    game.spawn(explosion(
      position: position.clone(),
      color: spec.color,
      count: 70,
      speed: 260,
    ));
    removeFromParent();
    game.levelManager?.onBossDefeated(position.clone());
  }

  @override
  void render(Canvas canvas) {
    final r = spec.radius;
    final center = Offset(r, r);
    final color = _hitFlash > 0
        ? Color.lerp(spec.color, const Color(0xFFFFFFFF), _hitFlash)!
        : spec.color;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_age * 0.6);
    canvas.translate(-center.dx, -center.dy);

    final path = _shapePath(r, center);
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.restore();

    // Pulsing core (not rotated).
    canvas.drawCircle(
      center,
      r * 0.28 * (1 + 0.12 * sin(_age * 5)),
      Paint()..color = color.withValues(alpha: 0.85),
    );
  }

  Path _shapePath(double r, Offset c) {
    final path = Path();
    final n = spec.points;
    if (spec.star) {
      for (var i = 0; i < n * 2; i++) {
        final radius = i.isEven ? r : r * 0.5;
        final a = -pi / 2 + i * pi / n;
        final p = Offset(c.dx + radius * cos(a), c.dy + radius * sin(a));
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
    } else {
      for (var i = 0; i < n; i++) {
        final a = -pi / 2 + i * 2 * pi / n;
        final p = Offset(c.dx + r * cos(a), c.dy + r * sin(a));
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }
}
