import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show HSVColor;
import 'package:flutter/services.dart';

import 'package:astro_nova/src/game/astro_nova_game.dart';
import 'package:astro_nova/src/core/palette.dart';
import 'package:astro_nova/src/features/player/weapon.dart';
import 'package:astro_nova/src/features/bosses/boss.dart';
import 'package:astro_nova/src/features/bosses/boss_core.dart';
import 'package:astro_nova/src/features/combat/bullet.dart';
import 'package:astro_nova/src/features/effects/effects.dart';
import 'package:astro_nova/src/features/enemies/enemy.dart';
import 'package:astro_nova/src/features/combat/enemy_bullet.dart';
import 'package:astro_nova/src/features/combat/explosion.dart';
import 'package:astro_nova/src/features/powerups/power_up.dart';

class Player extends PositionComponent
    with
        KeyboardHandler,
        CollisionCallbacks,
        HasGameReference<AstroNovaGame> {
  Player()
      : super(
          size: Vector2(36, 42),
          anchor: Anchor.center,
          position: Vector2(
            AstroNovaGame.worldWidth / 2,
            AstroNovaGame.worldHeight - 90,
          ),
          priority: 20,
        );

  static const _moveSpeed = 320.0;
  static const _invulnerableDuration = 1.6;
  static const _shieldRegenInterval = 10.0;

  final Vector2 _keyboardDirection = Vector2.zero();
  double _fireCooldown = 0;
  double _invulnerable = 0;
  double _regenTimer = 0;
  double _time = 0;

  /// Shield tier collected so far (0-5); determines charge capacity + perks.
  int shieldLevel = 0;
  int _shieldCharges = 0;

  bool get isInvulnerable => _invulnerable > 0;

  WeaponSpec get _weapon => weaponLevels[game.weaponLevel.value - 1];

  @override
  void onLoad() {
    add(RectangleHitbox(collisionType: CollisionType.active));
  }

  @override
  void update(double dt) {
    _time += dt;
    position += _keyboardDirection.normalized() * _moveSpeed * dt;
    position.clamp(
      Vector2(width / 2, height / 2),
      Vector2(
        AstroNovaGame.worldWidth - width / 2,
        AstroNovaGame.worldHeight - height / 2,
      ),
    );

    _invulnerable = _invulnerable > 0 ? _invulnerable - dt : 0;

    // ETERNAL AEGIS perk: charges slowly regenerate.
    if (shieldRegenerates(shieldLevel) && _shieldCharges < shieldLevel) {
      _regenTimer += dt;
      if (_regenTimer >= _shieldRegenInterval) {
        _regenTimer = 0;
        _setShieldCharges(_shieldCharges + 1);
      }
    }

    _fireCooldown -= dt;
    if (_fireCooldown <= 0) {
      _fire();
      _fireCooldown = _weapon.fireInterval * game.fireRateScale;
    }
  }

  /// Called from drag input; [delta] is already in world coordinates.
  void moveBy(Vector2 delta) {
    position += delta;
  }

  void _fire() {
    final nose = position - Vector2(0, height / 2);
    final weapon = _weapon;
    for (final shot in weapon.shots) {
      final rad = shot.angleDeg * pi / 180;
      game.spawn(Bullet(
        position: nose + Vector2(shot.dx, shot.dy),
        direction: Vector2(sin(rad), -cos(rad)),
        damage: shot.damage + game.bonusDamage,
        pierce: shot.pierce,
        homing: shot.homing,
        color: weapon.color,
        shape: weapon.shape,
      ));
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
    } else if (other is Boss) {
      _takeDamage();
    } else if (other is EnemyBullet) {
      other.removeFromParent();
      _takeDamage();
    } else if (other is PowerUp) {
      _collect(other);
    } else if (other is BossCore) {
      final buff = game.applyBossRelic(other.relicLevel);
      game.addScore(250);
      _announce(buff.name, buff.color);
      game.spawn(FloatingText(
        buff.blurb,
        position: position - Vector2(0, 22),
        color: buff.color,
        fontSize: 11,
        lifespan: 1.4,
      ));
      game.shake(4);
      other.removeFromParent();
    }
  }

  /// GUARD CORE relic: bumps the shield tier (or refills charges at cap).
  void grantShieldTier() {
    if (shieldLevel < maxShieldLevel) {
      shieldLevel++;
    }
    _setShieldCharges(shieldLevel);
  }

  void _collect(PowerUp powerUp) {
    switch (powerUp.type) {
      case PowerUpType.weapon:
        if (game.weaponLevel.value < maxWeaponLevel) {
          game.weaponLevel.value++;
          _announce(_weapon.name, Palette.powerUpWeapon);
        } else {
          game.addScore(100);
          _announce('+100', Palette.powerUpWeapon);
        }
      case PowerUpType.shield:
        if (shieldLevel < maxShieldLevel) {
          shieldLevel++;
          _setShieldCharges(shieldLevel);
          _announce(shieldNames[shieldLevel - 1], Palette.powerUpShield);
        } else {
          _setShieldCharges(shieldLevel); // refill
          game.addScore(100);
          _announce('SHIELD RESTORED', Palette.powerUpShield);
        }
    }
    powerUp.removeFromParent();
  }

  void _announce(String text, Color color) {
    game.spawn(FloatingText(
      text,
      position: position - Vector2(0, 40),
      color: color,
    ));
  }

  void _setShieldCharges(int value) {
    _shieldCharges = value.clamp(0, shieldLevel);
    game.shieldCharges.value = _shieldCharges;
  }

  void _takeDamage() {
    if (isInvulnerable) return;
    if (_shieldCharges > 0) {
      _setShieldCharges(_shieldCharges - 1);
      _invulnerable = 0.6;
      // NOVA GUARD perk: absorbing a hit detonates a shockwave.
      if (shieldHasShockwave(shieldLevel)) {
        final radius = shieldShockwaveRadius(shieldLevel);
        game.spawn(ShockwaveRing(
          position: position.clone(),
          maxRadius: radius,
          color: Palette.shield,
        ));
        for (final enemy
            in game.runRoot.children.query<Enemy>().toList()) {
          if (enemy.position.distanceTo(position) <= radius) {
            enemy.die();
          }
        }
      }
      return;
    }
    game.weaponLevel.value = max(1, game.weaponLevel.value - 3);
    _invulnerable = _invulnerableDuration;
    game.shake(8);
    game.spawn(explosion(
      position: position.clone(),
      color: Palette.player,
      count: 30,
    ));
    game.loseLife();
  }

  /// At max shield tier the ship transforms: hue-cycling hull + aura.
  bool get _isAscended => shieldLevel >= maxShieldLevel;

  @override
  void render(Canvas canvas) {
    // Blink while invulnerable.
    if (isInvulnerable && (_invulnerable * 10).floor().isEven) return;

    final w = width;
    final h = height;
    final center = Offset(w / 2, h / 2);
    final hullColor = _isAscended
        ? HSVColor.fromAHSV(1, (_time * 90) % 360, 0.55, 1).toColor()
        : Palette.player;

    // ETERNAL AEGIS aura: slow-breathing halo behind the ship.
    if (_isAscended) {
      canvas.drawCircle(
        center,
        w * (1.05 + 0.1 * sin(_time * 3)),
        Paint()
          ..color = hullColor.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    final ship = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h * 0.85)
      ..lineTo(w * 0.5, h * 0.68)
      ..lineTo(0, h * 0.85)
      ..close();

    canvas.drawPath(
      ship,
      Paint()
        ..color = hullColor.withValues(alpha: 0.5)
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, _isAscended ? 12 : 8),
    );
    canvas.drawPath(
      ship,
      Paint()
        ..color = hullColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _isAscended ? 3 : 2.5,
    );
    // Engine core.
    canvas.drawCircle(
      Offset(w / 2, h * 0.55),
      _isAscended ? 4.5 : 3.5,
      Paint()..color = _isAscended ? hullColor : Palette.playerCore,
    );

    // Shield ring: one orbiting arc segment per remaining charge.
    if (_shieldCharges > 0) {
      final radius = w * 0.85;
      const gap = 0.18;
      final sweep = (2 * pi / max(1, shieldLevel)) - gap;
      final spin = _time * (_isAscended ? 2.2 : 1.2);
      final arcColor = _isAscended ? hullColor : Palette.shield;
      for (var i = 0; i < _shieldCharges; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -pi / 2 + spin + i * (sweep + gap),
          sweep,
          false,
          Paint()
            ..color = arcColor.withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }
  }
}
