import 'package:flutter/material.dart';

import 'package:astro_nova/src/features/bosses/boss.dart';
import 'package:astro_nova/src/game/astro_nova_game.dart';
import 'package:astro_nova/src/game/level_manager.dart';
import 'package:astro_nova/src/ui/styles.dart';

/// Always-visible campaign map at the bottom of the HUD: 10 boss stations
/// from start to finish. The traveled part of the track glows, cleared
/// stations flip to gold stars, the current one pulses in its boss color,
/// and the ship marker slides smoothly with wave progress.
class CampaignMap extends StatefulWidget {
  const CampaignMap({super.key, required this.game});

  final AstroNovaGame game;

  @override
  State<CampaignMap> createState() => _CampaignMapState();
}

class _CampaignMapState extends State<CampaignMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return ValueListenableBuilder<int>(
      valueListenable: game.level,
      builder: (_, level, _) => ValueListenableBuilder<double>(
        valueListenable: game.levelProgress,
        builder: (_, progress, _) => AnimatedBuilder(
          animation: _pulse,
          builder: (_, _) => SizedBox(
            height: 48,
            child: LayoutBuilder(
              builder: (_, constraints) {
                const count = LevelManager.maxLevel;
                final width = constraints.maxWidth - 24;
                // Stations and ship share the SAME (count - 1) segments, so
                // the marker lands exactly on a station at phase boundaries.
                double xFor(double seg) =>
                    12 + width * (seg / (count - 1)).clamp(0.0, 1.0);
                final shipSeg = (level - 1) + progress.clamp(0.0, 1.0);
                final shipX = xFor(shipSeg);
                final p = _pulse.value;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Base track.
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 31,
                      child: Container(height: 2, color: Colors.white12),
                    ),
                    // Glowing traveled section.
                    Positioned(
                      left: 12,
                      top: 30,
                      child: Container(
                        width: (shipX - 12).clamp(0.0, width),
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: const LinearGradient(
                            colors: [kAccent, kGold],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kAccent.withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Boss stations (diamonds in each boss's color).
                    for (var i = 0; i < count; i++)
                      Positioned(
                        left: xFor(i.toDouble()) - 8,
                        top: 24,
                        child: _Station(
                          color: bossSpecs[i].color,
                          cleared: i < level - 1,
                          current: i == level - 1,
                          pulse: p,
                        ),
                      ),
                    // Ship marker with engine glow.
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      left: shipX - 9,
                      top: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kAccent.withValues(alpha: 0.5 + 0.3 * p),
                              blurRadius: 8 + 4 * p,
                            ),
                          ],
                        ),
                        child: Transform.rotate(
                          angle: 1.5708, // travelling left → right
                          child: const Icon(Icons.navigation,
                              color: kAccent, size: 18),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Station extends StatelessWidget {
  const _Station({
    required this.color,
    required this.cleared,
    required this.current,
    required this.pulse,
  });

  final Color color;
  final bool cleared;
  final bool current;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final size = current ? 15.0 + 3.0 * pulse : (cleared ? 15.0 : 12.0);
    return SizedBox(
      width: 16,
      height: 16,
      child: Center(
        child: Transform.rotate(
          angle: 0.7854, // diamond
          child: Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              color: cleared
                  ? kGold
                  : (current
                      ? color.withValues(alpha: 0.25 + 0.3 * pulse)
                      : Colors.transparent),
              border: Border.all(
                color: cleared
                    ? kGold
                    : (current ? color : color.withValues(alpha: 0.45)),
                width: current ? 2.2 : 1.4,
              ),
              boxShadow: cleared || current
                  ? [
                      BoxShadow(
                        color: (cleared ? kGold : color).withValues(
                            alpha: cleared ? 0.7 : 0.4 + 0.4 * pulse),
                        blurRadius: cleared ? 7 : 6 + 6 * pulse,
                      ),
                    ]
                  : null,
            ),
            child: cleared
                ? Transform.rotate(
                    angle: -0.7854,
                    child:
                        const Icon(Icons.star, size: 8, color: Colors.black),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
