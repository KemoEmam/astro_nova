import 'package:flutter/material.dart';

import 'package:astro_nova/src/core/palette.dart';
import 'package:astro_nova/src/game/astro_nova_game.dart';
import 'package:astro_nova/src/ui/styles.dart';

class MenuOverlay extends StatelessWidget {
  const MenuOverlay({super.key, required this.game});

  final AstroNovaGame game;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('ASTRONOVA', style: neon(52, weight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '10 levels · 10 bosses · one run',
            style: neon(14, color: Colors.white),
          ),
          const SizedBox(height: 32),
          // Control schemes — mouse/touch first, it's the easier way to play.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _ControlCard(
                icon: Icons.mouse,
                title: 'MOUSE / TOUCH',
                subtitle: 'drag to fly',
                recommended: true,
              ),
              SizedBox(width: 12),
              _ControlCard(
                icon: Icons.keyboard,
                title: 'KEYBOARD',
                subtitle: 'WASD / arrows',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('auto-fire · Esc or P to pause',
              style: neon(11, color: Colors.white54)),
          const SizedBox(height: 32),
          NeonButton(label: 'START', onPressed: game.startGame),
          const SizedBox(height: 24),
          ValueListenableBuilder<int>(
            valueListenable: game.highScore,
            builder: (_, high, _) => Text(
              'HIGH SCORE  $high',
              style: neon(16, color: Palette.powerUpWeapon),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.recommended = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final color = recommended ? kAccent : Colors.white60;
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black38,
        border: Border.all(color: color.withValues(alpha: 0.8), width: recommended ? 2 : 1),
        borderRadius: BorderRadius.circular(8),
        boxShadow: recommended
            ? [BoxShadow(color: kAccent.withValues(alpha: 0.35), blurRadius: 12)]
            : null,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 6),
          Text(title,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
          if (recommended) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: kAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text('RECOMMENDED',
                  style: TextStyle(
                      color: kAccent,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ),
          ],
        ],
      ),
    );
  }
}
