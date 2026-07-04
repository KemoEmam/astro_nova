import 'dart:math';
import 'dart:ui' hide TextStyle;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show FontWeight, TextStyle;

import '../astro_nova_game.dart';

/// Short-lived text that rises and fades — used for power-up names and
/// score call-outs.
class FloatingText extends PositionComponent
    with HasGameReference<AstroNovaGame> {
  FloatingText(
    this.text, {
    required Vector2 position,
    required this.color,
    this.fontSize = 14,
    this.lifespan = 1.1,
  }) : super(position: position, anchor: Anchor.center, priority: 40);

  final String text;
  final Color color;
  final double fontSize;
  final double lifespan;
  double _age = 0;

  @override
  void update(double dt) {
    _age += dt;
    position.y -= 36 * dt;
    if (_age >= lifespan) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final opacity = (1 - _age / lifespan).clamp(0.0, 1.0);
    TextPaint(
      style: TextStyle(
        color: color.withValues(alpha: opacity),
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    ).render(canvas, text, Vector2.zero(), anchor: Anchor.center);
  }
}

/// Full-screen cinematic banner: letterbox bars slide in from top/bottom
/// while a glowing title pulses in the middle. Used for boss warnings,
/// level intros, and level-clear moments.
class CinematicBanner extends PositionComponent
    with HasGameReference<AstroNovaGame> {
  CinematicBanner({
    required this.title,
    this.subtitle = '',
    required this.color,
    this.lifespan = 2.2,
    this.flashing = false,
  }) : super(priority: 60, size: Vector2(AstroNovaGame.worldWidth, AstroNovaGame.worldHeight));

  final String title;
  final String subtitle;
  final Color color;
  final double lifespan;

  /// Warning-style strobe for boss intros.
  final bool flashing;
  double _age = 0;

  @override
  void update(double dt) {
    _age += dt;
    if (_age >= lifespan) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final inOut = min(1.0, min(_age / 0.25, (lifespan - _age) / 0.25))
        .clamp(0.0, 1.0);
    final barHeight = 52.0 * inOut;
    final barPaint = Paint()..color = const Color(0xCC000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, barHeight), barPaint);
    canvas.drawRect(
        Rect.fromLTWH(0, height - barHeight, width, barHeight), barPaint);

    var alpha = inOut;
    if (flashing) {
      alpha *= 0.55 + 0.45 * sin(_age * 14).abs();
    }
    final pulse = 1 + 0.04 * sin(_age * 6);

    TextPaint(
      style: TextStyle(
        color: color.withValues(alpha: alpha),
        fontSize: 34 * pulse,
        fontWeight: FontWeight.bold,
        letterSpacing: 6,
        shadows: [Shadow(color: color.withValues(alpha: alpha), blurRadius: 18)],
      ),
    ).render(canvas, title, Vector2(width / 2, height / 2 - 14),
        anchor: Anchor.center);

    if (subtitle.isNotEmpty) {
      TextPaint(
        style: TextStyle(
          color: const Color(0xFFFFFFFF).withValues(alpha: alpha * 0.85),
          fontSize: 15,
          letterSpacing: 3,
        ),
      ).render(canvas, subtitle, Vector2(width / 2, height / 2 + 22),
          anchor: Anchor.center);
    }
  }
}

/// Expanding ring left behind when a Nova Guard shield absorbs a hit.
class ShockwaveRing extends PositionComponent {
  ShockwaveRing({required Vector2 position, required this.maxRadius, required this.color})
      : super(position: position, anchor: Anchor.center, priority: 30);

  final double maxRadius;
  final Color color;
  static const _lifespan = 0.45;
  double _age = 0;

  @override
  void update(double dt) {
    _age += dt;
    if (_age >= _lifespan) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / _lifespan).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset.zero,
      maxRadius * _easeOut(t),
      Paint()
        ..color = color.withValues(alpha: (1 - t) * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * (1 - t) + 1
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  static double _easeOut(double t) => 1 - (1 - t) * (1 - t);
}

/// Camera shake driven by decaying random jitter on the viewfinder.
/// Lives directly on the game (not the world) so it survives run resets.
class CameraShake extends Component with HasGameReference<AstroNovaGame> {
  double _intensity = 0;
  final _random = Random();

  void shake(double intensity) {
    _intensity = max(_intensity, intensity);
  }

  @override
  void update(double dt) {
    if (_intensity <= 0.1) {
      if (game.camera.viewfinder.position != Vector2.zero()) {
        game.camera.viewfinder.position = Vector2.zero();
      }
      _intensity = 0;
      return;
    }
    game.camera.viewfinder.position = Vector2(
      (_random.nextDouble() * 2 - 1) * _intensity,
      (_random.nextDouble() * 2 - 1) * _intensity,
    );
    _intensity -= _intensity * 6 * dt + 2 * dt;
  }
}
