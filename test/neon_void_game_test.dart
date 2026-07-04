import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_void/game/components/bullet.dart';
import 'package:neon_void/game/components/enemy.dart';
import 'package:neon_void/game/neon_void_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<NeonVoidGame> pumpGame(WidgetTester tester) async {
  final game = NeonVoidGame();
  await tester.pumpWidget(
    GameWidget(
      game: game,
      overlayBuilderMap: {
        for (final name in [
          NeonVoidGame.overlayMenu,
          NeonVoidGame.overlayHud,
          NeonVoidGame.overlayPause,
          NeonVoidGame.overlayGameOver,
        ])
          name: (_, NeonVoidGame _) => const SizedBox(),
      },
    ),
  );
  await game.loaded;
  await tester.pump();
  return game;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('loads into menu state with the menu overlay shown',
      (tester) async {
    final game = await pumpGame(tester);
    expect(game.state, GameState.menu);
    expect(game.overlays.isActive(NeonVoidGame.overlayMenu), isTrue);
  });

  testWidgets('startGame spawns the player and switches to the HUD',
      (tester) async {
    final game = await pumpGame(tester);
    game.startGame();
    await tester.pump();

    expect(game.state, GameState.playing);
    expect(game.player, isNotNull);
    expect(game.overlays.isActive(NeonVoidGame.overlayHud), isTrue);
    expect(game.overlays.isActive(NeonVoidGame.overlayMenu), isFalse);
    expect(game.lives.value, NeonVoidGame.startingLives);
    expect(game.score.value, 0);
  });

  testWidgets('killing an enemy awards its score value', (tester) async {
    final game = await pumpGame(tester);
    game.startGame();
    game.update(0);

    final enemy = Enemy(type: EnemyType.drifter, position: Vector2(200, 100));
    await game.world.add(enemy);
    game.update(0);

    enemy.takeHit(1);
    game.update(0);

    expect(game.score.value, EnemyType.drifter.score);
    expect(enemy.isMounted, isFalse);
  });

  testWidgets('tank survives hits until its HP is depleted', (tester) async {
    final game = await pumpGame(tester);
    game.startGame();
    game.update(0);

    final tank = Enemy(type: EnemyType.tank, position: Vector2(200, 100));
    await game.world.add(tank);
    game.update(0);

    for (var i = 0; i < EnemyType.tank.hp - 1; i++) {
      tank.takeHit(1);
    }
    game.update(0);
    expect(tank.isMounted, isTrue);

    tank.takeHit(1);
    game.update(0);
    expect(game.score.value, EnemyType.tank.score);
  });

  testWidgets('bullets despawn above the top of the world', (tester) async {
    final game = await pumpGame(tester);
    game.startGame();
    game.update(0);

    final bullet = Bullet(position: Vector2(200, 10));
    await game.world.add(bullet);
    game.update(0);

    game.update(1.0); // more than enough time to fly off-screen
    game.update(0);
    expect(bullet.isMounted, isFalse);
  });

  testWidgets('losing all lives ends the game and shows game over',
      (tester) async {
    final game = await pumpGame(tester);
    game.startGame();
    game.update(0);

    for (var i = 0; i < NeonVoidGame.startingLives; i++) {
      game.loseLife();
    }
    expect(game.state, GameState.gameOver);
    expect(game.overlays.isActive(NeonVoidGame.overlayGameOver), isTrue);
    expect(game.overlays.isActive(NeonVoidGame.overlayHud), isFalse);
  });
}
