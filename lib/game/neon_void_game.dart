import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:shared_preferences/shared_preferences.dart';

import 'components/enemy.dart';
import 'components/enemy_spawner.dart';
import 'components/player.dart';
import 'components/power_up.dart';
import 'components/bullet.dart';
import 'components/starfield.dart';

enum GameState { menu, playing, paused, gameOver }

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

  static const _highScoreKey = 'highScore';
  static const startingLives = 3;

  GameState state = GameState.menu;
  final score = ValueNotifier<int>(0);
  final lives = ValueNotifier<int>(startingLives);
  final highScore = ValueNotifier<int>(0);

  Player? player;
  EnemySpawner? _spawner;

  @override
  Future<void> onLoad() async {
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(worldWidth, worldHeight),
    );
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();

    world.add(Starfield());
    world.add(_DragPad());

    final prefs = await SharedPreferences.getInstance();
    highScore.value = prefs.getInt(_highScoreKey) ?? 0;

    overlays.add(overlayMenu);
  }

  void startGame() {
    // Clear any leftovers from a previous run.
    world.removeAll(world.children.query<Enemy>());
    world.removeAll(world.children.query<Bullet>());
    world.removeAll(world.children.query<PowerUp>());
    _spawner?.removeFromParent();
    player?.removeFromParent();

    score.value = 0;
    lives.value = startingLives;

    player = Player();
    _spawner = EnemySpawner();
    world.add(player!);
    world.add(_spawner!);

    state = GameState.playing;
    overlays
      ..remove(overlayMenu)
      ..remove(overlayGameOver)
      ..add(overlayHud);
    resumeEngine();
  }

  void addScore(int points) {
    if (state != GameState.playing) return;
    score.value += points;
  }

  void loseLife() {
    lives.value--;
    if (lives.value <= 0) {
      _gameOver();
    }
  }

  void _gameOver() {
    state = GameState.gameOver;
    player?.removeFromParent();
    player = null;
    _spawner?.removeFromParent();
    _spawner = null;

    if (score.value > highScore.value) {
      highScore.value = score.value;
      SharedPreferences.getInstance()
          .then((prefs) => prefs.setInt(_highScoreKey, score.value));
    }

    overlays
      ..remove(overlayHud)
      ..add(overlayGameOver);
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
        );

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (game.state == GameState.playing) {
      game.player?.moveBy(event.localDelta);
    }
  }
}
