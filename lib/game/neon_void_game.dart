import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:shared_preferences/shared_preferences.dart';

import 'components/background.dart';
import 'components/boss.dart';
import 'components/bullet.dart';
import 'components/effects.dart';
import 'components/enemy.dart';
import 'components/enemy_spawner.dart';
import 'components/player.dart';
import 'components/starfield.dart';
import 'level_manager.dart';
import 'level_theme.dart';

enum GameState { menu, playing, paused, gameOver, victory }

class NeonVoidGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents {
  /// Logical resolution: portrait 1:2. The viewport letterboxes everything
  /// else, so gameplay is identical on phones, desktop, and web.
  static const worldWidth = 400.0;
  static const worldHeight = 800.0;

  static const overlayMenu = 'menu';
  static const overlayHud = 'hud';
  static const overlayPause = 'pause';
  static const overlayGameOver = 'gameOver';
  static const overlayVictory = 'victory';

  static const _highScoreKey = 'highScore';
  static const startingLives = 3;
  static const maxLives = 4;

  GameState state = GameState.menu;
  final score = ValueNotifier<int>(0);
  final lives = ValueNotifier<int>(startingLives);
  final highScore = ValueNotifier<int>(0);
  final level = ValueNotifier<int>(1);
  final levelProgress = ValueNotifier<double>(0);
  final weaponLevel = ValueNotifier<int>(1);
  final shieldCharges = ValueNotifier<int>(0);

  /// 0..1 while a boss is alive, null otherwise (drives the HUD boss bar).
  final bossHealth = ValueNotifier<double?>(null);
  final bossName = ValueNotifier<String?>(null);

  // Permanent run-buffs granted by Boss Cores (one unique relic per level).
  double fireRateScale = 1.0;
  int bonusDamage = 0;
  bool magnet = false;
  double scoreMultiplier = 1.0;
  int maxLivesCurrent = maxLives;

  Player? player;
  EnemySpawner? spawner;
  LevelManager? levelManager;
  late final CameraShake _cameraShake;

  /// Per-run container: everything belonging to the current run lives here
  /// so a restart is a single subtree swap.
  Component? _runRoot;
  Component get runRoot => _runRoot!;

  LevelTheme get theme => levelThemes[(level.value - 1).clamp(0, 9)];

  @override
  Future<void> onLoad() async {
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(worldWidth, worldHeight),
    );
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();

    world.add(Background());
    world.add(Starfield());
    world.add(_DragPad());
    _cameraShake = CameraShake();
    add(_cameraShake);

    final prefs = await SharedPreferences.getInstance();
    highScore.value = prefs.getInt(_highScoreKey) ?? 0;

    overlays.add(overlayMenu);
  }

  void spawn(Component component) => _runRoot?.add(component);

  /// Homing-bullet targets: everything alive that can be damaged.
  Iterable<Damageable> get targets sync* {
    final root = _runRoot;
    if (root == null) return;
    yield* root.children.query<Enemy>();
    yield* root.children.query<Boss>();
  }

  void startGame() {
    _runRoot?.removeFromParent();
    final root = Component();
    _runRoot = root;
    world.add(root);

    score.value = 0;
    lives.value = startingLives;
    level.value = 1;
    levelProgress.value = 0;
    weaponLevel.value = 1;
    shieldCharges.value = 0;
    bossHealth.value = null;
    bossName.value = null;
    fireRateScale = 1.0;
    bonusDamage = 0;
    magnet = false;
    scoreMultiplier = 1.0;
    maxLivesCurrent = maxLives;

    player = Player();
    spawner = EnemySpawner()..configureForLevel(1);
    levelManager = LevelManager();
    root.add(player!);
    root.add(spawner!);
    root.add(levelManager!);

    state = GameState.playing;
    overlays
      ..remove(overlayMenu)
      ..remove(overlayGameOver)
      ..remove(overlayVictory)
      ..add(overlayHud);
    resumeEngine();
  }

  void addScore(int points) {
    if (state != GameState.playing) return;
    score.value += (points * scoreMultiplier).round();
  }

  void loseLife() {
    lives.value--;
    if (lives.value <= 0) {
      _endRun(won: false);
    }
  }

  void healLife() {
    if (lives.value < maxLivesCurrent) {
      lives.value++;
    } else {
      addScore(150);
    }
  }

  /// Applies the given level's Boss Core relic and returns its name for
  /// the pickup announcement. One unique permanent buff per level.
  String applyBossRelic(int relicLevel) {
    switch (relicLevel) {
      case 1:
        fireRateScale *= 0.9;
        return 'OVERCLOCK CORE';
      case 2:
        magnet = true;
        return 'MAGNET CORE';
      case 3:
        maxLivesCurrent++;
        healLife();
        return 'HULL CORE';
      case 4:
        bonusDamage++;
        return 'AMP CORE';
      case 5:
        scoreMultiplier += 0.5;
        return 'GREED CORE';
      case 6:
        fireRateScale *= 0.9;
        return 'OVERCLOCK CORE II';
      case 7:
        player?.grantShieldTier();
        return 'GUARD CORE';
      case 8:
        bonusDamage++;
        return 'AMP CORE II';
      case 9:
        maxLivesCurrent++;
        healLife();
        return 'HULL CORE II';
      default:
        addScore(2000);
        return 'VOID HEART';
    }
  }

  void victory() => _endRun(won: true);

  void shake(double intensity) => _cameraShake.shake(intensity);

  void _endRun({required bool won}) {
    state = won ? GameState.victory : GameState.gameOver;
    player?.removeFromParent();
    player = null;
    spawner?.removeFromParent();
    spawner = null;
    levelManager?.removeFromParent();
    levelManager = null;
    bossHealth.value = null;
    bossName.value = null;

    if (score.value > highScore.value) {
      highScore.value = score.value;
      SharedPreferences.getInstance()
          .then((prefs) => prefs.setInt(_highScoreKey, score.value));
    }

    overlays
      ..remove(overlayHud)
      ..add(won ? overlayVictory : overlayGameOver);
  }

  void togglePause() {
    if (state == GameState.playing) {
      state = GameState.paused;
      pauseEngine();
      overlays.add(overlayPause);
    } else if (state == GameState.paused) {
      state = GameState.playing;
      overlays.remove(overlayPause);
      resumeEngine();
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.escape ||
            event.logicalKey == LogicalKeyboardKey.keyP)) {
      togglePause();
      return KeyEventResult.handled;
    }
    return super.onKeyEvent(event, keysPressed);
  }
}

/// Invisible full-world pad that translates drags into player movement.
/// Lives in the world so drag deltas arrive already in world coordinates.
class _DragPad extends PositionComponent
    with DragCallbacks, HasGameReference<NeonVoidGame> {
  _DragPad()
      : super(
          size: Vector2(NeonVoidGame.worldWidth, NeonVoidGame.worldHeight),
          position: Vector2.zero(),
          priority: -1,
        );

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (game.state == GameState.playing) {
      game.player?.moveBy(event.localDelta);
    }
  }
}
