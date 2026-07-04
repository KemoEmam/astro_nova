// Deterministic screenshot generator for the README:
//   flutter test test/tools/generate_screenshots_test.dart
// Pumps the real game to exact timestamps and saves PNGs to docs/screenshots.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astro_nova/src/core/palette.dart';
import 'package:astro_nova/src/game/astro_nova_game.dart';
import 'package:astro_nova/src/ui/overlays/game_over_overlay.dart';
import 'package:astro_nova/src/ui/overlays/hud_overlay.dart';
import 'package:astro_nova/src/ui/overlays/menu_overlay.dart';
import 'package:astro_nova/src/ui/overlays/pause_overlay.dart';
import 'package:astro_nova/src/ui/overlays/victory_overlay.dart';

Future<void> _loadRealFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  final fontDir = '$flutterRoot/bin/cache/artifacts/material_fonts';
  Future<ByteData> bytes(String file) async {
    final b = await File('$fontDir/$file').readAsBytes();
    return ByteData.view(b.buffer);
  }

  final roboto = FontLoader('Roboto')
    ..addFont(bytes('Roboto-Regular.ttf'))
    ..addFont(bytes('Roboto-Bold.ttf'))
    ..addFont(bytes('Roboto-Medium.ttf'));
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(bytes('MaterialIcons-Regular.otf'));
  await icons.load();
}

Future<void> _capture(WidgetTester tester, Key key, String path) async {
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
    final image = await boundary.toImage(pixelRatio: 2.0);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(png!.buffer.asUint8List());
  });
}

/// Advance the game [seconds] in 16ms steps.
Future<void> _play(WidgetTester tester, double seconds) async {
  final steps = (seconds * 1000 / 16).round();
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  testWidgets('generate README screenshots', (tester) async {
    SharedPreferences.setMockInitialValues({'highScore': 48210});
    await tester.runAsync(_loadRealFonts);

    tester.view.physicalSize = const Size(860, 1720);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    const key = Key('shot');
    final game = AstroNovaGame();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(useMaterial3: true),
          home: Scaffold(
            backgroundColor: Palette.background,
            body: GameWidget<AstroNovaGame>(
              game: game,
              overlayBuilderMap: {
                AstroNovaGame.overlayMenu: (_, g) => MenuOverlay(game: g),
                AstroNovaGame.overlayHud: (_, g) => HudOverlay(game: g),
                AstroNovaGame.overlayPause: (_, g) => PauseOverlay(game: g),
                AstroNovaGame.overlayGameOver: (_, g) =>
                    GameOverOverlay(game: g),
                AstroNovaGame.overlayVictory: (_, g) =>
                    VictoryOverlay(game: g),
              },
            ),
          ),
        ),
      ),
    );
    await game.loaded;
    await _play(tester, 1.0);
    await _capture(tester, key, 'docs/screenshots/menu.png');

    // Mid-wave action with an upgraded loadout.
    game.startGame();
    game.weaponLevel.value = 7;
    await _play(tester, 8.0);
    await _capture(tester, key, 'docs/screenshots/gameplay.png');

    // Boss warning cinematic (waves end at ~9.7s + 1.2s intro).
    await _play(tester, 4.0);
    await _capture(tester, key, 'docs/screenshots/warning.png');

    // Boss fight with buffs and shields active for a full HUD showcase.
    game.applyBossRelic(1);
    game.applyBossRelic(3);
    game.player?.grantShieldTier();
    game.player?.grantShieldTier();
    await _play(tester, 5.0);
    await _capture(tester, key, 'docs/screenshots/boss.png');

    expect(File('docs/screenshots/boss.png').existsSync(), isTrue);
  });
}
