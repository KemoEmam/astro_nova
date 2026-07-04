import 'package:flutter/material.dart';

import 'package:astro_nova/src/features/powerups/buffs.dart';
import 'package:astro_nova/src/game/astro_nova_game.dart';

/// Right-side stack of active Boss Core buffs: icon, name, effect line, and
/// a countdown bar that fades out over the final two seconds.
class BuffSidebar extends StatelessWidget {
  const BuffSidebar({super.key, required this.game});

  final AstroNovaGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ActiveBuff>>(
      valueListenable: game.activeBuffs,
      builder: (_, buffs, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [for (final buff in buffs) _BuffChip(buff: buff)],
      ),
    );
  }
}

class _BuffChip extends StatelessWidget {
  const _BuffChip({required this.buff});

  final ActiveBuff buff;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: (buff.remaining / 2).clamp(0.0, 1.0),
      child: Container(
        width: 132,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black45,
          border: Border.all(color: buff.color.withValues(alpha: 0.8)),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
                color: buff.color.withValues(alpha: 0.25), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(buff.icon, color: buff.color, size: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    buff.name,
                    style: TextStyle(
                      color: buff.color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              buff.blurb,
              style: const TextStyle(color: Colors.white70, fontSize: 8.5),
            ),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (buff.remaining / buff.duration).clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(buff.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
