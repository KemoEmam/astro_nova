import 'package:flutter/material.dart';

import 'package:astro_nova/src/game/astro_nova_game.dart';
import 'package:astro_nova/src/game/level_manager.dart';
import 'package:astro_nova/src/ui/styles.dart';

/// Level progress bar during waves; boss HP bar (with name) during fights.
class LevelBar extends StatelessWidget {
  const LevelBar({super.key, required this.game});

  final AstroNovaGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double?>(
      valueListenable: game.bossHealth,
      builder: (_, bossHp, _) {
        if (bossHp != null) {
          return Row(
            children: [
              ValueListenableBuilder<String?>(
                valueListenable: game.bossName,
                builder: (_, name, _) => Text(
                  name ?? '',
                  style: neon(11, color: const Color(0xFFFF5252)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _bar(bossHp, const Color(0xFFFF5252))),
            ],
          );
        }
        return Row(
          children: [
            ValueListenableBuilder<int>(
              valueListenable: game.level,
              builder: (_, level, _) => Text(
                'LV $level/${LevelManager.maxLevel}',
                style: neon(11, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ValueListenableBuilder<double>(
                valueListenable: game.levelProgress,
                builder: (_, progress, _) => _bar(progress, kAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _bar(double value, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 6,
        backgroundColor: Colors.white10,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}
