import 'package:flutter/material.dart';

import 'package:astro_nova/src/game/astro_nova_game.dart';
import 'package:astro_nova/src/ui/styles.dart';

class VictoryOverlay extends StatelessWidget {
  const VictoryOverlay({super.key, required this.game});

  final AstroNovaGame game;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'VOID CLEARED',
              style: neon(42,
                  weight: FontWeight.bold, color: const Color(0xFFEEFF41)),
            ),
            const SizedBox(height: 8),
            Text('ALL 10 BOSSES DEFEATED',
                style: neon(14, color: Colors.white)),
            const SizedBox(height: 16),
            Text('FINAL SCORE  ${game.score.value}', style: neon(24)),
            const SizedBox(height: 36),
            NeonButton(label: 'PLAY AGAIN', onPressed: game.startGame),
          ],
        ),
      ),
    );
  }
}
