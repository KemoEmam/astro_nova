import 'package:flutter/material.dart';

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
            'drag or WASD / arrows to move · auto-fire',
            style: _neon(13, color: Colors.white70),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: game.score,
              builder: (_, score, _) =>
                  Text('$score', style: _neon(26, weight: FontWeight.bold)),
            ),
            const Spacer(),
            ValueListenableBuilder<int>(
              valueListenable: game.lives,
              builder: (_, lives, _) => Row(
                children: List.generate(
                  lives.clamp(0, NeonVoidGame.startingLives),
                  (_) => const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.favorite, color: _accent, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.pause, color: Colors.white70),
              onPressed: game.togglePause,
            ),
          ],
        ),
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
            const SizedBox(height: 16),
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
