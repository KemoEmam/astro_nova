import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import '../neon_void_game.dart';
import '../palette.dart';
import 'bullet.dart';
import 'enemy.dart';
import 'explosion.dart';
import 'power_up.dart';

class Player extends PositionComponent
    with
        KeyboardHandler,
        CollisionCallbacks,
        HasGameReference<NeonVoidGame> {
  Player()
      : super(
          size: Vector2(36, 42),
          anchor: Anchor.center,
          position: Vector2(
            NeonVoidGame.worldWidth / 2,
            NeonVoidGame.worldHeight - 90,
          ),
        );

  static const _moveSpeed = 320.0;
  static const _fireInterval = 0.16;
  static const _invulnerableDuration = 1.6;
  static const maxWeaponLevel = 3;

  final Vector2 _keyboardDirection = Vector2.zero();
  double _fireCooldown = 0;
  double _invulnerable = 0;
  int weaponLevel = 1;
  bool hasShield = false;

  bool get isInvulnerable => _invulnerable > 0;

  @override
  void onLoad() {
    add(RectangleHitbox(collisionType: CollisionType.active));
  }

  @override
  void update(double dt) {
    position += _keyboardDirection.normalized() * _moveSpeed * dt;
    position.clamp(
      Vector2(width / 2, height / 2),
      Vector2(
        NeonVoidGame.worldWidth - width / 2,
        NeonVoidGame.worldHeight - height / 2,
      ),
    );

    _invulnerable = _invulnerable > 0 ? _invulnerable - dt : 0;

    _fireCooldown -= dt;
    if (_fireCooldown <= 0) {
      _fire();
      _fireCooldown = _fireInterval;
    }
  }

  /// Called from drag input; [delta] is already in world coordinates.
  void moveBy(Vector2 delta) {
    position += delta;
  }

  void _fire() {
    final nose = position - Vector2(0, height / 2);
    switch (weaponLevel) {
      case 1:
        game.world.add(Bullet(position: nose));
      case 2:
        game.world.add(Bullet(position: nose + Vector2(-9, 4)));
        game.world.add(Bullet(position: nose + Vector2(9, 4)));
      default:
        game.world.add(Bullet(position: nose));
        game.world.add(Bullet(position: nose + Vector2(-12, 8)));
        game.world.add(Bullet(position: nose + Vector2(12, 8)));
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keyboardDirection.setValues(
      (keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
              keysPressed.contains(LogicalKeyboardKey.keyD)
          ? 1.0
          : 0.0) -
          (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
                  keysPressed.contains(LogicalKeyboardKey.keyA)
              ? 1.0
              : 0.0),
      (keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
              keysPressed.contains(LogicalKeyboardKey.keyS)
          ? 1.0
          : 0.0) -
          (keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
                  keysPressed.contains(LogicalKeyboardKey.keyW)
              ? 1.0
              : 0.0),
    );
    return true;
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Enemy) {
      other.die();
      _takeDamage();
    } else if (other is PowerUp) {
      _collect(other);
    }
  }

  void _collect(PowerUp powerUp) {
    switch (powerUp.type) {
      case PowerUpType.weapon:
        if (weaponLevel < maxWeaponLevel) {
          weaponLevel++;
        } else {
          game.addScore(50); // already maxed — consolation points
        }
      case PowerUpType.shield:
        hasShield = true;
    }
    powerUp.removeFromParent();
  }

  void _takeDamage() {
    if (isInvulnerable) return;
    if (hasShield) {
      hasShield = false;
      _invulnerable = 0.5;
      return;
    }
    weaponLevel = 1;
    _invulnerable = _invulnerableDuration;
    game.world.add(explosion(
      position: position.clone(),
      color: Palette.player,
      count: 30,
    ));
    game.loseLife();
  }

  @override
  void render(Canvas canvas) {
    // Blink while invulnerable.
    if (isInvulnerable && (_invulnerable * 10).floor().isEven) return;

    final w = width;
    final h = height;
    final ship = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h * 0.85)
      ..lineTo(w * 0.5, h * 0.68)
      ..lineTo(0, h * 0.85)
      ..close();

    canvas.drawPath(
      ship,
      Paint()
        ..color = Palette.player.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      ship,
      Paint()
        ..color = Palette.player
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // Engine core.
    canvas.drawCircle(
      Offset(w / 2, h * 0.55),
      3.5,
      Paint()..color = Palette.playerCore,
    );

    if (hasShield) {
      canvas.drawCircle(
        Offset(w / 2, h / 2),
        w * 0.85,
        Paint()
          ..color = Palette.shield.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }
}
