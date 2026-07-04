import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'package:astro_nova/src/core/palette.dart';
import 'package:astro_nova/src/game/astro_nova_game.dart';
import 'package:astro_nova/src/ui/overlays/game_over_overlay.dart';
import 'package:astro_nova/src/ui/overlays/hud_overlay.dart';
import 'package:astro_nova/src/ui/overlays/menu_overlay.dart';
import 'package:astro_nova/src/ui/overlays/pause_overlay.dart';
import 'package:astro_nova/src/ui/overlays/victory_overlay.dart';

void main() {
  runApp(const AstroNovaApp());
}

class AstroNovaApp extends StatelessWidget {
  const AstroNovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AstroNova',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: Palette.background,
        body: GameWidget<AstroNovaGame>.controlled(
          gameFactory: AstroNovaGame.new,
          overlayBuilderMap: {
            AstroNovaGame.overlayMenu: (_, game) => MenuOverlay(game: game),
            AstroNovaGame.overlayHud: (_, game) => HudOverlay(game: game),
            AstroNovaGame.overlayPause: (_, game) => PauseOverlay(game: game),
            AstroNovaGame.overlayGameOver: (_, game) =>
                GameOverOverlay(game: game),
            AstroNovaGame.overlayVictory: (_, game) =>
                VictoryOverlay(game: game),
          },
        ),
      ),
    );
  }
}
