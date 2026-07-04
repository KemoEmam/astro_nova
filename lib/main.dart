import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/neon_void_game.dart';
import 'game/palette.dart';
import 'ui/overlays.dart';

void main() {
  runApp(const NeonVoidApp());
}

class NeonVoidApp extends StatelessWidget {
  const NeonVoidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Void',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: Palette.background,
        body: GameWidget<NeonVoidGame>.controlled(
          gameFactory: NeonVoidGame.new,
          overlayBuilderMap: {
            NeonVoidGame.overlayMenu: (_, game) => MenuOverlay(game: game),
            NeonVoidGame.overlayHud: (_, game) => HudOverlay(game: game),
            NeonVoidGame.overlayPause: (_, game) => PauseOverlay(game: game),
            NeonVoidGame.overlayGameOver: (_, game) =>
                GameOverOverlay(game: game),
          },
        ),
      ),
    );
  }
}
