import 'package:flutter/material.dart';

import 'package:astro_nova/src/game/astro_nova_game.dart';
import 'package:astro_nova/src/ui/styles.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.game});

  final AstroNovaGame game;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PAUSED', style: neon(40, weight: FontWeight.bold)),
            const SizedBox(height: 32),
            NeonButton(label: 'RESUME', onPressed: game.togglePause),
          ],
        ),
      ),
    );
  }
}
