import 'package:flutter/material.dart';

import 'package:astro_nova/src/core/palette.dart';
import 'package:astro_nova/src/game/astro_nova_game.dart';
import 'package:astro_nova/src/ui/styles.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});

  final AstroNovaGame game;

  @override
  Widget build(BuildContext context) {
    final isNewHighScore =
        game.score.value >= game.highScore.value && game.score.value > 0;
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GAME OVER',
              style: neon(44,
                  weight: FontWeight.bold, color: Palette.enemyDrifter),
            ),
            const SizedBox(height: 12),
            Text('REACHED LEVEL ${game.level.value}',
                style: neon(14, color: Colors.white70)),
            const SizedBox(height: 8),
            Text('SCORE  ${game.score.value}', style: neon(22)),
            if (isNewHighScore) ...[
              const SizedBox(height: 8),
              Text('NEW HIGH SCORE!',
                  style: neon(16, color: Palette.powerUpWeapon)),
            ],
            const SizedBox(height: 36),
            NeonButton(label: 'PLAY AGAIN', onPressed: game.startGame),
          ],
        ),
      ),
    );
  }
}
