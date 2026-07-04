import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astro_nova/src/features/powerups/buffs.dart';
import 'package:astro_nova/src/features/environment/background.dart';
import 'package:astro_nova/src/features/bosses/boss.dart';
import 'package:astro_nova/src/features/combat/bullet.dart';
import 'package:astro_nova/src/features/effects/effects.dart';
import 'package:astro_nova/src/features/enemies/enemy.dart';
import 'package:astro_nova/src/features/enemies/enemy_spawner.dart';
import 'package:astro_nova/src/features/player/player.dart';
import 'package:astro_nova/src/features/environment/starfield.dart';
import 'package:astro_nova/src/game/level_manager.dart';
import 'package:astro_nova/src/core/level_theme.dart';

enum GameState { menu, playing, paused, gameOver, victory }

class AstroNovaGame extends FlameGame
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

  /// Timed run-buffs from Boss Cores; the HUD sidebar renders this list.
  final activeBuffs = ValueNotifier<List<ActiveBuff>>([]);

  double get fireRateScale =>
      activeBuffs.value.fold(1.0, (v, b) => v * b.fireRateFactor);
  int get bonusDamage =>
      activeBuffs.value.fold(0, (v, b) => v + b.bonusDamage);
  bool get magnet => activeBuffs.value.any((b) => b.magnet);
  double get scoreMultiplier =>
      activeBuffs.value.fold(1.0, (v, b) => v * b.scoreFactor);

  int maxLivesCurrent = maxLives;

  // Bad-luck protection: guarantees at least one weapon drop per level
  // (reset by the LevelManager on every level start).
  int killsSinceWeaponDrop = 0;
  bool weaponDroppedThisLevel = false;

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
    activeBuffs.value = [];
    maxLivesCurrent = maxLives;
    killsSinceWeaponDrop = 0;
    weaponDroppedThisLevel = false;

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

  /// Applies the given level's Boss Core relic as a timed buff and returns
  /// it for the pickup announcement.
  ActiveBuff applyBossRelic(int relicLevel) {
    final buff = bossRelicFor(relicLevel);
    activeBuffs.value = [...activeBuffs.value, buff];
    return buff;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Tick down active buffs; a fresh list assignment notifies the HUD.
    if (state == GameState.playing && activeBuffs.value.isNotEmpty) {
      for (final buff in activeBuffs.value) {
        buff.remaining -= dt;
      }
      activeBuffs.value =
          activeBuffs.value.where((b) => b.remaining > 0).toList();
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
    with DragCallbacks, HasGameReference<AstroNovaGame> {
  _DragPad()
      : super(
          size: Vector2(AstroNovaGame.worldWidth, AstroNovaGame.worldHeight),
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
