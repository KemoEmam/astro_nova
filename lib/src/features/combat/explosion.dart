import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';

final _random = Random();

/// Radial particle burst used for every kill and player death.
/// Pure `Particle` API — no textures, just glowing circles that decay.
ParticleSystemComponent explosion({
  required Vector2 position,
  required Color color,
  int count = 24,
  double speed = 160,
}) {
  return ParticleSystemComponent(
    position: position,
    particle: Particle.generate(
      count: count,
      lifespan: 0.6,
      generator: (i) {
        final angle = _random.nextDouble() * 2 * pi;
        final magnitude = speed * (0.3 + _random.nextDouble() * 0.7);
        final direction = Vector2(cos(angle), sin(angle));
        return AcceleratedParticle(
          speed: direction * magnitude,
          acceleration: direction * -magnitude * 0.8,
          child: ComputedParticle(
            renderer: (canvas, particle) {
              final opacity = (1 - particle.progress).clamp(0.0, 1.0);
              canvas.drawCircle(
                Offset.zero,
                2.5 * (1 - particle.progress * 0.6),
                Paint()
                  ..color = color.withValues(alpha: opacity)
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
              );
            },
          ),
        );
      },
    ),
  );
}
