import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import 'atmosphere.dart';
import 'entities.dart';
import 'level.dart';
import 'lighting.dart';
import 'levels.dart';
import 'narration.dart';
import 'palette.dart';
import 'player.dart';
import 'terrain.dart';

class Buttons {
  bool left = false;
  bool right = false;
  bool up = false;
  bool down = false;
  bool jump = false;
  bool cover = false;
}

/// Klavye ve dokunmatik girişin birleşimi.
class Controls {
  final keyboard = Buttons();
  final touch = Buttons();

  bool get left => keyboard.left || touch.left;
  bool get right => keyboard.right || touch.right;
  bool get up => keyboard.up || touch.up;
  bool get down => keyboard.down || touch.down;
  bool get jump => keyboard.jump || touch.jump;
  bool get cover => keyboard.cover || touch.cover;

  /// Ateşböceği salma tek seferlik bir eylem: tuşa basıldığı an kuyruğa girer,
  /// oyuncu bir sonraki karede tüketir.
  bool _lureQueued = false;
  void queueLure() => _lureQueued = true;
  bool takeLure() {
    final queued = _lureQueued;
    _lureQueued = false;
    return queued;
  }
}

class GolgeGame extends FlameGame with KeyboardEvents {
  final controls = Controls();

  late Level level;
  int levelIndex = 0;
  Player? player;
  Vector2? _respawn;

  late final ScreenEffects effects;
  late final Narration narration;

  /// Sinematik ya da geçiş sırasında oyuncu girdisi kapalıdır.
  bool cinematic = true;
  bool _transitioning = false;
  bool _snapCamera = true;
  bool _prevJump = false;
  double _closeUp = 1;
  int _devStop = 0;

  /// Kavanozdaki ateşböcekleri: salınınca azalır, zamanla yenilenir.
  static const maxFireflies = 3;
  int fireflies = maxFireflies;
  double _fireflyRegen = 0;

  final _memories = <String>{};
  final _whispersShown = <String>{};

  int get memoryCount => _memories.length;
  int get memoryTotal => levels.fold(0, (sum, l) => sum + l.memories.length);

  @override
  Color backgroundColor() => kInk;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.center;
    camera.backdrop = Backdrop();
    effects = ScreenEffects();
    narration = Narration();
    camera.viewport.addAll([effects, narration]);
    _buildLevel(0);
    _startPrologue();
  }

  void _startPrologue() {
    cinematic = true;
    effects.setFade(1, kInk);
    narration.playCinematic(prologue, () {
      cinematic = false;
      effects.fadeTo(0, 1.8);
      _showLevelTitle();
    }, instantBlack: true);
  }

  /// Testler ve geliştirme kısayolu için: hikâyeyi atlayıp bölümü yükler.
  void debugLoadLevel(int index) {
    _buildLevel(index);
    cinematic = false;
    effects.setFade(0, kInk);
    narration.playCinematic(const [], () {});
  }

  void _showLevelTitle() =>
      narration.showTitle(level.def.title, level.def.subtitle);

  void _buildLevel(int index, {bool respawn = false}) {
    world.removeAll(world.children.toList());
    levelIndex = index;
    level = Level(levels[index]);
    if (!respawn || _respawn == null) {
      _respawn = Level.standOn(level.playerStart, Player.w, Player.h);
    }

    world.addAll([
      TerrainComponent(level),
      LightingLayer(),
      ForegroundComponent(level),
      WaterComponent(level),
      ExitPortal(level.exitCell),
      for (final g in level.guardCells) Guard(g),
      for (final b in level.birdCells)
        Bird(b, level.exitCell + Vector2(kTile / 2, -kTile)),
      for (var i = 0; i < level.memoryCells.length; i++)
        if (!_memories.contains('$index:$i'))
          MemoryShard(level.memoryCells[i], i),
    ]);
    player = Player(_respawn!.clone());
    world.add(player!);
    _snapCamera = true;
  }

  // --------------------------------------------------------------- olaylar

  void onPlayerDied() {
    if (_transitioning) return;
    _transitioning = true;
    effects.fadeTo(
      1,
      0.8,
      color: kInk,
      onDone: () {
        _buildLevel(levelIndex, respawn: true);
        effects.fadeTo(0, 0.7);
        _transitioning = false;
      },
    );
  }

  void onExitReached() {
    if (_transitioning) return;
    _transitioning = true;
    cinematic = true;
    effects.fadeTo(
      1,
      1.4,
      color: kLight,
      onDone: () {
        final next = levelIndex + 1;
        if (next < levels.length) {
          _buildLevel(next);
          cinematic = false;
          _transitioning = false;
          effects.fadeTo(0, 1.8);
          _showLevelTitle();
          return;
        }
        narration.playCinematic(
          [
            ...epilogue.take(epilogue.length - 1),
            'Toplanan hatıralar: $memoryCount / $memoryTotal',
            epilogue.last,
          ],
          () {
            _memories.clear();
            _whispersShown.clear();
            effects.setFade(1, kInk);
            _buildLevel(0);
            _transitioning = false;
            _startPrologue();
          },
        );
      },
    );
  }

  /// Oyuncu kavanozdan bir ateşböceği salar; Kandilciler ışığa yönelir.
  void releaseFirefly(Vector2 from, int direction) {
    if (fireflies <= 0) return;
    fireflies--;
    _fireflyRegen = 0;
    world.add(FireflyLure(from, direction));
    narration.pulseFireflies();
  }

  void collectMemory(int index) {
    if (!_memories.add('$levelIndex:$index')) return;
    final lines = level.def.memories;
    if (index < lines.length) narration.whisper(lines[index]);
    narration.pulseCounter();
  }

  void _checkStoryPoints(Player p) {
    final c = p.center;
    bool near(Vector2 cell, double rx, double ry) {
      final d = c - (cell + Vector2.all(kTile / 2));
      return d.x.abs() < rx && d.y.abs() < ry;
    }

    for (final (i, cell) in level.triggers) {
      final key = '$levelIndex:$i';
      if (_whispersShown.contains(key) || !near(cell, 48, 80)) continue;
      _whispersShown.add(key);
      if (i < level.def.whispers.length) {
        narration.whisper(level.def.whispers[i]);
      }
    }
    for (final cell in level.checkpointCells) {
      if (near(cell, 40, 60)) {
        _respawn = Level.standOn(cell, Player.w, Player.h);
      }
    }
  }

  // ---------------------------------------------------------------- döngü

  @override
  void update(double dt) {
    super.update(dt);
    final jump = controls.jump;
    if (narration.inCinematic && jump && !_prevJump) narration.skip();
    _prevJump = jump;

    if (fireflies < maxFireflies) {
      _fireflyRegen += dt;
      if (_fireflyRegen > 10) {
        _fireflyRegen = 0;
        fireflies++;
        narration.pulseFireflies();
      }
    }

    final p = player;
    if (p == null || !p.isMounted) return;
    if (!cinematic && !p.isDead) _checkStoryPoints(p);
    _updateCamera(p, dt);
  }

  void _updateCamera(Player p, double dt) {
    final view = camera.viewport.size;
    if (view.x == 0 || view.y == 0) return;
    final zoom =
        view.y / (kTile * math.min(15.5, level.height.toDouble())) * _closeUp;
    camera.viewfinder.zoom = zoom;

    final target = p.center + Vector2(p.facing * 40, -24);
    final halfW = view.x / zoom / 2;
    final halfH = view.y / zoom / 2;
    target.x = level.pixelWidth <= halfW * 2
        ? level.pixelWidth / 2
        : target.x.clamp(halfW, level.pixelWidth - halfW);
    target.y = level.pixelHeight <= halfH * 2
        ? level.pixelHeight / 2
        : target.y.clamp(halfH, level.pixelHeight - halfH);

    final pos = camera.viewfinder.position;
    if (_snapCamera) {
      camera.viewfinder.position = target;
      _snapCamera = false;
    } else {
      final k = 1 - math.exp(-dt * 5);
      camera.viewfinder.position = pos + (target - pos) * k;
    }
  }

  // ---------------------------------------------------------------- klavye

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    bool any(List<LogicalKeyboardKey> ks) => ks.any(keysPressed.contains);
    controls.keyboard
      ..left = any([LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA])
      ..right = any([LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD])
      ..up = any([LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyW])
      ..down = any([LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS])
      ..jump = any([LogicalKeyboardKey.space, LogicalKeyboardKey.keyZ])
      ..cover = any([
        LogicalKeyboardKey.shiftLeft,
        LogicalKeyboardKey.shiftRight,
        LogicalKeyboardKey.keyQ,
      ]);
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyF ||
          event.logicalKey == LogicalKeyboardKey.keyX) {
        controls.queueLure();
      }
      if (event.logicalKey == LogicalKeyboardKey.enter &&
          narration.inCinematic) {
        narration.skip();
      }
      if (event.logicalKey == LogicalKeyboardKey.keyR && !cinematic) {
        player?.die();
      }
      // Geliştirici kısayolu: --dart-define=DEV=true ile N bir sonraki bölüm.
      if (const bool.fromEnvironment('DEV') &&
          event.logicalKey == LogicalKeyboardKey.keyN) {
        debugLoadLevel((levelIndex + 1) % levels.length);
        _showLevelTitle();
      }
      // Geliştirici kısayolu: C yakın plan (ekran görüntüsü için).
      if (const bool.fromEnvironment('DEV') &&
          event.logicalKey == LogicalKeyboardKey.keyC) {
        _closeUp = _closeUp == 1 ? 3 : 1;
      }
      // Geliştirici kısayolu: V karakter stilini değiştirir.
      if (const bool.fromEnvironment('DEV') &&
          event.logicalKey == LogicalKeyboardKey.keyV) {
        Player.jarStyle = !Player.jarStyle;
      }
      // Geliştirici kısayolu: T sıradaki hikâye noktasına ışınlar.
      if (const bool.fromEnvironment('DEV') &&
          event.logicalKey == LogicalKeyboardKey.keyT) {
        final stops = level.triggers.map((t) => t.$2).toList()
          ..sort((a, b) => a.x.compareTo(b.x));
        if (stops.isNotEmpty && player != null) {
          player!.position.setFrom(
            Level.standOn(stops[_devStop++ % stops.length], Player.w, Player.h),
          );
          _snapCamera = true;
        }
      }
    }
    return KeyEventResult.handled;
  }
}
