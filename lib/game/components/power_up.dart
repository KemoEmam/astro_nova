import 'dart:math';
import 'dart:ui' hide TextStyle;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/painting.dart' show FontWeight, TextStyle;

import '../neon_void_game.dart';
import '../palette.dart';
import '../weapon.dart';

enum PowerUpType {
  weapon(Palette.powerUpWeapon, 'W'),
  shield(Palette.powerUpShield, 'S');

  const PowerUpType(this.color, this.glyph);

  final Color color;
  final String glyph;
}

class PowerUp extends PositionComponent with HasGameReference<NeonVoidGame> {
  PowerUp({required this.type, required Vector2 position})
      : super(position: position, size: Vector2.all(28), anchor: Anchor.center);

  final PowerUpType type;
  double _age = 0;

  static const _fallSpeed = 80.0;
  static final _random = Random();

  /// Rolls the drop chance; call on every enemy kill.
  ///
  /// Drops get rarer both as the campaign advances and as the player's
  /// upgrades stack up, so the power curve stays under control while early
  /// levels shower the player with toys.
  static void maybeDrop(NeonVoidGame game, Vector2 position) {
    final level = game.level.value;
    final weaponLevel = game.weaponLevel.value;
    final shieldLevel = game.player?.shieldLevel ?? 0;

    // Bad-luck protection: if too many kills go by in a level without a
    // weapon drop, force one so the player never reaches a boss dry.
    game.killsSinceWeaponDrop++;
    if (!game.weaponDroppedThisLevel && game.killsSinceWeaponDrop >= 8) {
      _drop(game, PowerUpType.weapon, position);
      return;
    }

    final base = 0.21 - 0.011 * (level - 1);
    final upgradePenalty =
        1.0 - (weaponLevel - 1) / 70.0 - shieldLevel / 20.0;
    final chance = (base * upgradePenalty).clamp(0.04, 0.21);
    if (_random.nextDouble() >= chance) return;

    // Weight the type toward whichever upgrade track is further from its cap
    // (weapon track scaled down so its 30 tiers don't drown out the shield).
    final weaponWeight = (maxWeaponLevel - weaponLevel) / 4.0 + 2.0;
    final shieldWeight = (maxShieldLevel - shieldLevel) + 2.0;
    final roll = _random.nextDouble() * (weaponWeight + shieldWeight);
    final type = roll < weaponWeight ? PowerUpType.weapon : PowerUpType.shield;
    _drop(game, type, position);
  }

  static void _drop(NeonVoidGame game, PowerUpType type, Vector2 position) {
    if (type == PowerUpType.weapon) {
      game.weaponDroppedThisLevel = true;
      game.killsSinceWeaponDrop = 0;
    }
    game.spawn(PowerUp(type: type, position: position));
  }

  @override
  void onLoad() {
    add(CircleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    _age += dt;
    position.y += _fallSpeed * dt;

    // MAGNET CORE relic: pickups get pulled toward the player.
    final playerPos = game.player?.position;
    if (game.magnet && playerPos != null) {
      final toPlayer = playerPos - position;
      if (toPlayer.length < 400) {
        position += toPlayer.normalized() * 240 * dt;
      }
    }

    if (position.y > NeonVoidGame.worldHeight + height) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final center = (size / 2).toOffset();
    final pulse = 0.85 + 0.15 * sin(_age * 6);
    final r = width / 2 * pulse;

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = type.color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = type.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final textPainter = TextPaint(
      style: TextStyle(
        color: type.color,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.render(canvas, type.glyph, center.toVector2(),
        anchor: Anchor.center);
  }
}
