import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_void/game/components/boss.dart';
import 'package:neon_void/game/components/boss_core.dart';
import 'package:neon_void/game/components/bullet.dart';
import 'package:neon_void/game/components/enemy.dart';
import 'package:neon_void/game/components/power_up.dart';
import 'package:neon_void/game/level_manager.dart';
import 'package:neon_void/game/level_theme.dart';
import 'package:neon_void/game/neon_void_game.dart';
import 'package:neon_void/game/weapon.dart';
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
          NeonVoidGame.overlayVictory,
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

  test('campaign data is complete: 10 themes, 10 bosses, 30 weapon tiers', () {
    expect(levelThemes.length, LevelManager.maxLevel);
    expect(bossSpecs.length, LevelManager.maxLevel);
    expect(weaponLevels.length, maxWeaponLevel);
    expect(shieldNames.length, maxShieldLevel);
  });

  testWidgets('loads into menu state with the menu overlay shown',
      (tester) async {
    final game = await pumpGame(tester);
    expect(game.state, GameState.menu);
    expect(game.overlays.isActive(NeonVoidGame.overlayMenu), isTrue);
  });

  testWidgets('startGame resets the run and switches to the HUD',
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
    expect(game.level.value, 1);
    expect(game.weaponLevel.value, 1);
  });

  testWidgets('killing an enemy awards its score value', (tester) async {
    final game = await pumpGame(tester);
    game.startGame();
    game.update(0);

    final enemy = Enemy(type: EnemyType.drifter, position: Vector2(200, 100));
    await game.runRoot.add(enemy);
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
    await game.runRoot.add(tank);
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
    await game.runRoot.add(bullet);
    game.update(0);

    game.update(1.0); // more than enough time to fly off-screen
    game.update(0);
    expect(bullet.isMounted, isFalse);
  });

  testWidgets('boss defeat advances the campaign to the next level',
      (tester) async {
    final game = await pumpGame(tester);
    game.startGame();
    game.update(0);

    // Fast-forward: intro (1.2s) + waves for level 1.
    game.update(1.3);
    game.update(20.0);
    game.update(0);
    expect(game.levelManager, isNotNull);

    // Boss intro (2s) then the boss spawns.
    game.update(2.1);
    game.update(0);
    final boss = game.runRoot.children.query<Boss>().toList();
    expect(boss, hasLength(1));

    boss.first.takeHit(0); // still entering — no damage registered
    // Let it finish the fly-in, then burst it down.
    game.update(3.0);
    boss.first.takeHit(bossSpecs[0].hp);
    game.update(0);

    // The fight drops exactly one Boss Core.
    game.update(0);
    expect(game.runRoot.children.query<BossCore>(), hasLength(1));

    // Cleared phase → next level after the banner.
    game.update(2.5);
    game.update(0);
    expect(game.level.value, 2);
    expect(game.state, GameState.playing);
  });

  testWidgets('pity system guarantees a weapon drop within 8 dry kills',
      (tester) async {
    final game = await pumpGame(tester);
    game.startGame();
    game.update(0);

    // 8 kills with no weapon drop → the 8th forces one.
    for (var i = 0; i < 8; i++) {
      final enemy =
          Enemy(type: EnemyType.drifter, position: Vector2(200, 100));
      await game.runRoot.add(enemy);
      game.update(0);
      enemy.takeHit(1);
      game.update(0);
    }
    final weaponDrops = game.runRoot.children
        .query<PowerUp>()
        .where((p) => p.type == PowerUpType.weapon);
    expect(weaponDrops, isNotEmpty);
    expect(game.weaponDroppedThisLevel, isTrue);
  });

  testWidgets('boss relics apply timed run buffs that expire', (tester) async {
    final game = await pumpGame(tester);
    game.startGame();
    game.update(0);

    expect(game.applyBossRelic(1), 'OVERCLOCK');
    expect(game.fireRateScale, closeTo(0.75, 0.001));
    expect(game.applyBossRelic(3), 'AMP CORE');
    expect(game.bonusDamage, 1);
    expect(game.applyBossRelic(2), 'MAGNET CORE');
    expect(game.magnet, isTrue);
    expect(game.activeBuffs.value, hasLength(3));

    // All buffs expire after their timers run out.
    game.update(50);
    expect(game.activeBuffs.value, isEmpty);
    expect(game.fireRateScale, 1.0);
    expect(game.bonusDamage, 0);
    expect(game.magnet, isFalse);
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

  testWidgets('victory flow triggers after clearing level 10', (tester) async {
    final game = await pumpGame(tester);
    game.startGame();
    game.update(0);
    game.level.value = LevelManager.maxLevel;
    game.victory();

    expect(game.state, GameState.victory);
    expect(game.overlays.isActive(NeonVoidGame.overlayVictory), isTrue);
  });
}
