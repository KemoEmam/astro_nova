import 'package:flutter/material.dart';

import 'package:astro_nova/src/core/palette.dart';
import 'package:astro_nova/src/game/astro_nova_game.dart';
import 'package:astro_nova/src/ui/styles.dart';
import 'package:astro_nova/src/ui/widgets/buff_sidebar.dart';
import 'package:astro_nova/src/ui/widgets/campaign_map.dart';
import 'package:astro_nova/src/ui/widgets/level_bar.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.game});

  final AstroNovaGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: game.score,
                  builder: (_, score, _) =>
                      Text('$score', style: neon(24, weight: FontWeight.bold)),
                ),
                const Spacer(),
                ValueListenableBuilder<int>(
                  valueListenable: game.lives,
                  builder: (_, lives, _) => Row(
                    children: List.generate(
                      lives.clamp(0, 8), // HULL COREs can raise the cap
                      (_) => const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.favorite, color: kAccent, size: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.pause, color: Colors.white70),
                  onPressed: game.togglePause,
                ),
              ],
            ),
            const SizedBox(height: 2),
            LevelBar(game: game),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: game.weaponLevel,
                  builder: (_, w, _) => _chip('W$w', Palette.powerUpWeapon),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<int>(
                  valueListenable: game.shieldCharges,
                  builder: (_, s, _) => s > 0
                      ? _chip('S$s', Palette.powerUpShield)
                      : const SizedBox.shrink(),
                ),
                const Spacer(),
                BuffSidebar(game: game),
              ],
            ),
            const Spacer(),
            CampaignMap(game: game),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.8)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
