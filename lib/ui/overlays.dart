import 'package:flutter/material.dart';

import '../game/buffs.dart';
import '../game/components/boss.dart';
import '../game/level_manager.dart';
import '../game/neon_void_game.dart';
import '../game/palette.dart' as game_palette;

const _accent = Color(0xFF00E5FF);

TextStyle _neon(double size, {Color color = _accent, FontWeight? weight}) {
  return TextStyle(
    color: color,
    fontSize: size,
    fontWeight: weight ?? FontWeight.w600,
    letterSpacing: 2,
    shadows: [Shadow(color: color.withValues(alpha: 0.8), blurRadius: 12)],
  );
}

class _NeonButton extends StatelessWidget {
  const _NeonButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _accent,
        side: const BorderSide(color: _accent, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text(label, style: _neon(18)),
    );
  }
}

class MenuOverlay extends StatelessWidget {
  const MenuOverlay({super.key, required this.game});

  final NeonVoidGame game;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('NEON VOID', style: _neon(52, weight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '10 levels · 10 bosses · one run',
            style: _neon(14, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'drag or WASD / arrows to move · auto-fire',
            style: _neon(12, color: Colors.white70),
          ),
          const SizedBox(height: 40),
          _NeonButton(label: 'START', onPressed: game.startGame),
          const SizedBox(height: 24),
          ValueListenableBuilder<int>(
            valueListenable: game.highScore,
            builder: (_, high, _) => Text(
              'HIGH SCORE  $high',
              style: _neon(16, color: game_palette.Palette.powerUpWeapon),
            ),
          ),
        ],
      ),
    );
  }
}

class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.game});

  final NeonVoidGame game;

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
                      Text('$score', style: _neon(24, weight: FontWeight.bold)),
                ),
                const Spacer(),
                ValueListenableBuilder<int>(
                  valueListenable: game.lives,
                  builder: (_, lives, _) => Row(
                    children: List.generate(
                      lives.clamp(0, 8), // HULL COREs can raise the cap

                      (_) => const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.favorite, color: _accent, size: 18),
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
            _LevelBar(game: game),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: game.weaponLevel,
                  builder: (_, w, _) => _chip(
                      'W$w', game_palette.Palette.powerUpWeapon),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<int>(
                  valueListenable: game.shieldCharges,
                  builder: (_, s, _) => s > 0
                      ? _chip('S$s', game_palette.Palette.powerUpShield)
                      : const SizedBox.shrink(),
                ),
                const Spacer(),
                _BuffSidebar(game: game),
              ],
            ),
            const Spacer(),
            _CampaignMap(game: game),
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

/// Right-side stack of active Boss Core buffs: name + countdown bar that
/// fades out over the final two seconds.
class _BuffSidebar extends StatelessWidget {
  const _BuffSidebar({required this.game});

  final NeonVoidGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ActiveBuff>>(
      valueListenable: game.activeBuffs,
      builder: (_, buffs, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final buff in buffs)
            Opacity(
              opacity: (buff.remaining / 2).clamp(0.0, 1.0),
              child: Container(
                width: 120,
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  border:
                      Border.all(color: buff.color.withValues(alpha: 0.8)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buff.name,
                      style: TextStyle(
                        color: buff.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (buff.remaining / buff.duration)
                            .clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation(buff.color),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Always-visible campaign map at the bottom of the HUD: 10 boss stations
/// from start to finish. The traveled part of the track glows, cleared
/// stations flip to gold stars, the current one pulses in its boss color,
/// and the ship marker slides smoothly with wave progress.
class _CampaignMap extends StatefulWidget {
  const _CampaignMap({required this.game});

  final NeonVoidGame game;

  @override
  State<_CampaignMap> createState() => _CampaignMapState();
}

class _CampaignMapState extends State<_CampaignMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  static const _gold = Color(0xFFFFD740);

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
                            colors: [_accent, _gold],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _accent.withValues(alpha: 0.6),
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
                        child: _station(
                          bossSpecs[i].color,
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
                              color: _accent.withValues(alpha: 0.5 + 0.3 * p),
                              blurRadius: 8 + 4 * p,
                            ),
                          ],
                        ),
                        child: Transform.rotate(
                          angle: 1.5708, // travelling left → right
                          child:
                              const Icon(Icons.navigation, color: _accent, size: 18),
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

  Widget _station(Color color,
      {required bool cleared, required bool current, required double pulse}) {
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
                  ? _gold
                  : (current
                      ? color.withValues(alpha: 0.25 + 0.3 * pulse)
                      : Colors.transparent),
              border: Border.all(
                color: cleared
                    ? _gold
                    : (current ? color : color.withValues(alpha: 0.45)),
                width: current ? 2.2 : 1.4,
              ),
              boxShadow: cleared || current
                  ? [
                      BoxShadow(
                        color: (cleared ? _gold : color)
                            .withValues(alpha: cleared ? 0.7 : 0.4 + 0.4 * pulse),
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

/// Level progress bar during waves; boss HP bar (with name) during fights.
class _LevelBar extends StatelessWidget {
  const _LevelBar({required this.game});

  final NeonVoidGame game;

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
                  style: _neon(11, color: const Color(0xFFFF5252)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _bar(bossHp, const Color(0xFFFF5252)),
              ),
            ],
          );
        }
        return Row(
          children: [
            ValueListenableBuilder<int>(
              valueListenable: game.level,
              builder: (_, level, _) => Text(
                'LV $level/${LevelManager.maxLevel}',
                style: _neon(11, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ValueListenableBuilder<double>(
                valueListenable: game.levelProgress,
                builder: (_, progress, _) => _bar(progress, _accent),
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

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.game});

  final NeonVoidGame game;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PAUSED', style: _neon(40, weight: FontWeight.bold)),
            const SizedBox(height: 32),
            _NeonButton(label: 'RESUME', onPressed: game.togglePause),
          ],
        ),
      ),
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});

  final NeonVoidGame game;

  @override
  Widget build(BuildContext context) {
    final isNewHighScore = game.score.value >= game.highScore.value &&
        game.score.value > 0;
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GAME OVER',
              style: _neon(44,
                  weight: FontWeight.bold,
                  color: game_palette.Palette.enemyDrifter),
            ),
            const SizedBox(height: 12),
            Text('REACHED LEVEL ${game.level.value}',
                style: _neon(14, color: Colors.white70)),
            const SizedBox(height: 8),
            Text('SCORE  ${game.score.value}', style: _neon(22)),
            if (isNewHighScore) ...[
              const SizedBox(height: 8),
              Text(
                'NEW HIGH SCORE!',
                style:
                    _neon(16, color: game_palette.Palette.powerUpWeapon),
              ),
            ],
            const SizedBox(height: 36),
            _NeonButton(label: 'PLAY AGAIN', onPressed: game.startGame),
          ],
        ),
      ),
    );
  }
}

class VictoryOverlay extends StatelessWidget {
  const VictoryOverlay({super.key, required this.game});

  final NeonVoidGame game;

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
              style: _neon(42,
                  weight: FontWeight.bold, color: const Color(0xFFEEFF41)),
            ),
            const SizedBox(height: 8),
            Text('ALL 10 BOSSES DEFEATED',
                style: _neon(14, color: Colors.white)),
            const SizedBox(height: 16),
            Text('FINAL SCORE  ${game.score.value}', style: _neon(24)),
            const SizedBox(height: 36),
            _NeonButton(label: 'PLAY AGAIN', onPressed: game.startGame),
          ],
        ),
      ),
    );
  }
}
