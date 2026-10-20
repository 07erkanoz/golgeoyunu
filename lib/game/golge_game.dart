import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import 'atmosphere.dart';
import 'audio.dart';
import 'creatures.dart';
import 'mechanics.dart';
import 'entities.dart';
import 'level.dart';
import 'lighting.dart';
import 'levels.dart';
import 'narration.dart';
import 'perde.dart';
import 'palette.dart';
import 'player.dart';
import 'legends.dart';
import 'nemrut.dart';
import 'winter.dart';
import 'puzzles.dart';
import '../settings.dart';
import 'strings.dart';
import 'terrain.dart';

class Buttons {
  bool left = false;
  bool right = false;
  bool up = false;
  bool down = false;
  bool jump = false;
  bool sneak = false;
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
  bool get sneak => keyboard.sneak || touch.sneak;

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
  int _debugScene = 0;
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

  /// Önizleme ve ekran görüntüsü için yakın plan (1 = normal).
  set debugCloseUp(double v) => _closeUp = v;

  /// Ekranda görünen kare yüksekliği: masaüstünde Limbo gibi uzak, telefon
  /// gibi alçak ekranlarda çocuk seçilebilsin diye daha yakın.
  double get tilesTall => camera.viewport.size.y < 520 ? 13 : 20;
  double _lookAhead = 0;
  final _rnd = math.Random();
  int _devStop = 0;

  /// Kavanozdaki ateşböcekleri: salınınca azalır, zamanla yenilenir.
  static const maxFireflies = 5;
  static const startFireflies = 2;
  int fireflies = startFireflies;

  // ------------------------------------------------------------- gerilim

  /// Ekrana yansıyan tehlike (0-1): Kandilci şüphesi, Gözcü, Karabasan.
  double threat = 0;

  /// Saklanma (0-1): sesler boğuklaşır, renkler solar.
  double hideAmount = 0;

  /// Kavanozun ışık gücü: karanlık bölgede ateşböcekleri azaldıkça söner.
  double jarStrength = 1;

  /// Karanlık bölgede bir ateşböceğinin sönme süresi.
  static const darkDrain = 6.5;

  /// Ateşböceği kalmayınca karanlığın yutma süresi.
  static const darkSwallow = 4.5;

  double _darkT = 0;
  bool _darkWarned = false;

  /// Deprem (0-1): Nemrut'ta ara ara yer sarsılır.
  double quake = 0;

  /// Tipinin şiddeti (0-1): fırtınalı bölümlerde ara ara bastırır.
  double blizzard = 0;
  double _stormT = 0;
  bool _stormWarned = false;
  double _chainT = 25;

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
    _enterMenu();
  }

  // ---------------------------------------------------------------- ana menü

  static const menuOverlay = 'menu';

  /// Ana menü açık mı: arkada oyunun dünyası oynar, oyuncu yoktur.
  final menuMode = ValueNotifier<bool>(true);
  double _menuT = 0;

  void _showOverlay(String name) {
    if (overlays.registeredOverlays.contains(name)) overlays.add(name);
  }

  void _enterMenu() {
    menuMode.value = true;
    cinematic = true;
    _transitioning = false;
    _menuT = 0;
    narration.playCinematic(const [], () {});
    final saved = SaveGame.current;
    _buildLevel(saved?.level ?? 0, withPlayer: false);
    effects.setFade(1, kInk);
    effects.fadeTo(0, 1.6);
    GameAudio.instance.menuMusic(true);
    overlays.remove(settingsOverlay);
    settingsOpen.value = false;
    _showOverlay(menuOverlay);
  }

  void _leaveMenu() {
    menuMode.value = false;
    overlays.remove(menuOverlay);
    GameAudio.instance.menuMusic(false);
  }

  /// Baştan başlar; varsa kayıt silinir.
  void startNewGame() {
    SaveGame.clear();
    _memories.clear();
    _whispersShown.clear();
    fireflies = startFireflies;
    wingsCollected = false;
    _respawn = null;
    _leaveMenu();
    _buildLevel(0);
    _saveProgress();
    _startPrologue();
  }

  /// Kaldığın yerden: son kontrol noktasında, toplananlarla birlikte.
  void continueGame() {
    final save = SaveGame.current;
    if (save == null) {
      startNewGame();
      return;
    }
    _memories
      ..clear()
      ..addAll(save.memories);
    _whispersShown
      ..clear()
      ..addAll(save.whispers);
    fireflies = save.fireflies;
    wingsCollected = save.wings;
    _respawn = Vector2(save.x, save.y);
    _leaveMenu();
    _buildLevel(save.level.clamp(0, levels.length - 1), respawn: true);
    cinematic = false;
    effects.setFade(1, kInk);
    effects.fadeTo(0, 1.4);
    _showLevelTitle();
  }

  /// Oyundan ana menüye: önce ilerlemeyi kaydeder.
  void backToMenu() {
    _saveProgress();
    if (paused) resumeEngine();
    GameAudio.instance.resumeAll();
    _enterMenu();
  }

  void _saveProgress() {
    final r = _respawn;
    if (menuMode.value || r == null) return;
    SaveGame.write(
      SaveData(
        level: levelIndex,
        x: r.x,
        y: r.y,
        memories: _memories.toList(),
        whispers: _whispersShown.toList(),
        fireflies: fireflies,
        wings: wingsCollected,
      ),
    );
  }

  void _updateMenuCamera(double dt) {
    _menuT += dt;
    final view = camera.viewport.size;
    if (view.x == 0 || view.y == 0) return;
    final zoom =
        view.y / (kTile * math.min(tilesTall, level.height.toDouble()));
    camera.viewfinder.zoom = zoom;
    final halfW = view.x / zoom / 2;
    final halfH = view.y / zoom / 2;
    // Bölümün içinde ağır ağır gidip gelen bir bakış.
    final k = 0.5 - 0.5 * math.cos(_menuT * 0.035);
    final spanX = math.max(0.0, level.pixelWidth - halfW * 2);
    final spanY = math.max(0.0, level.pixelHeight - halfH * 2);
    final target = level.vertical
        ? Vector2(level.pixelWidth / 2, level.pixelHeight - halfH - spanY * k)
        : Vector2(halfW + spanX * k, level.pixelHeight - halfH - spanY * 0.15);
    if (_snapCamera) {
      camera.viewfinder.position = target;
      _snapCamera = false;
    } else {
      final pos = camera.viewfinder.position;
      camera.viewfinder.position =
          pos + (target - pos) * (1 - math.exp(-dt * 2));
    }
  }

  void _startPrologue() {
    cinematic = true;
    effects.setFade(1, kInk);
    narration.playCinematic(
      prologueText,
      () {
        cinematic = false;
        effects.fadeTo(0, 1.8);
        _showLevelTitle();
      },
      instantBlack: true,
      scene: PerdeScene.prologue,
    );
  }

  /// Testler ve geliştirme kısayolu için: hikâyeyi atlayıp bölümü yükler.
  void debugLoadLevel(int index) {
    menuMode.value = false;
    overlays.remove(menuOverlay);
    _buildLevel(index);
    cinematic = false;
    effects.setFade(0, kInk);
    narration.playCinematic(const [], () {});
  }

  // ---------------------------------------------------------------- ayarlar

  static const settingsOverlay = 'settings';

  /// Ayarlar açık mı (dokunmatik düğmeler bu sırada gizlenir).
  final settingsOpen = ValueNotifier<bool>(false);

  /// Masaüstünde tam ekranı açıp kapatır (main.dart bağlar).
  void Function()? onToggleFullscreen;

  void toggleSettings() {
    if (overlays.isActive(settingsOverlay)) {
      overlays.remove(settingsOverlay);
      settingsOpen.value = false;
      if (!menuMode.value) {
        resumeEngine();
        GameAudio.instance.resumeAll();
      }
    } else {
      // Basılı kalan tuşlar menü kapanınca oyuncuyu yürütmesin.
      controls.keyboard
        ..left = false
        ..right = false
        ..up = false
        ..down = false
        ..jump = false
        ..sneak = false;
      _showOverlay(settingsOverlay);
      settingsOpen.value = true;
      if (!menuMode.value) {
        pauseEngine();
        GameAudio.instance.pauseAll();
      }
    }
  }

  void _showLevelTitle() => narration.showTitle(
    level.def.titleText,
    level.def.subtitleText,
    level.def.placeText,
  );

  /// Testler için: gerçek bölümlerin yerine küçük deneme haritaları.
  static List<LevelDef>? debugLevels;

  void _buildLevel(int index, {bool respawn = false, bool withPlayer = true}) {
    world.removeAll(world.children.toList());
    levelIndex = index;
    level = Level((debugLevels ?? levels)[index]);
    if (!respawn || _respawn == null) {
      _respawn = Level.standOn(level.playerStart, Player.w, Player.h);
      _darkWarned = false;
    }

    world.addAll([
      TerrainComponent(level),
      LightingLayer(),
      ForegroundComponent(level),
      WaterComponent(level),
      ExitPortal(level.exitCell),
      for (final g in level.guardCells) Guard(g),
      for (final c in level.crateCells) Crate(c),
      for (final l in level.leverCells) Lever(l),
      for (final (col, top, bottom) in level.gates) Gate(col, top, bottom),
      ?_guideBird(),
      for (final f in level.fireflyCells) FireflySwarm(f),
      for (final (c, vertical) in level.movingCells)
        MovingRock(c, vertical: vertical),
      for (final c in level.crumbleCells) CrumbleRock(c),
      ..._lifts(),
      for (final c in level.batCells)
        if (level.def.theme.snowy) Wolf(c) else BatRoost(c),
      for (final c in level.thinIceCells) ThinIce(c),
      for (final c in level.crowCells) Crow(c),
      for (final c in level.watcherCells) Watcher(c),
      for (final c in level.wingsCells) WingsPickup(c),
      for (final c in level.glimpseCells) KarabasanGlimpse(c),
      for (final c in level.icicleCells) FallingIcicle(c),
      for (final c in level.medusaCells) MedusaHead(c),
      for (var i = 0; i < level.starCells.length; i++)
        StarStone(level.starCells[i], i),
      for (final c in level.reliefCells) HoroscopeRelief(c),
      for (final c in level.boulderCells) LooseBoulder(c),
      for (final (c, kind) in level.statueCells) Colossus(c, kind: kind),
      for (final c in level.giantCells) StoneGiant(c),
      if (level.def.quakes) QuakeClock(),
      for (final z in level.rainZones) RainZone(z),
      for (final c in level.shieldCells) ShieldCrate(c),
      for (final c in level.raftCells) Raft(c),
      for (var i = 0; i < level.ventCells.length; i++)
        FireVent(level.ventCells[i], phase: i * 1.1),
      for (final c in level.balloonCells) LanternBalloon(c),
      for (final c in level.featherCells) SimurgFeather(c),
      for (final c in level.altarCells) FeatherAltar(c),
      for (final c in level.bellCells) WindBell(c),
      for (final c in level.ruinCells) MonasteryRuin(c),
      for (final c in level.perdeCells) GiantPerde(c),
      for (final (c, r, n) in level.glowRuns)
        PhasePlank(Vector2(c * kTile, r * kTile.toDouble()), n, shade: false),
      for (final (c, r, n) in level.shadeRuns)
        PhasePlank(Vector2(c * kTile, r * kTile.toDouble()), n, shade: true),
      for (final (c, r, n) in level.rottenRuns) RottenPlank(c, r, n),
      ..._basins(),
      for (final c in level.drainValves) Valve(c, fill: false),
      for (final c in level.fillValves) Valve(c, fill: true),
      for (final (c, slash) in level.mirrorCells) Mirror(c, slash: slash),
      for (final c in level.lockCells) SunLock(c),
      for (final c in level.beamCells) SunBeam(c),
      for (final (c, r, n) in level.ropes) SwingRope(c, r, n),
      for (var i = 0; i < level.animalCells.length; i++)
        AnimalCrate(
          level.animalCells[i],
          AnimalKind.values[i % AnimalKind.values.length],
        ),
      for (var i = 0; i < level.pedestalCells.length; i++)
        Pedestal(
          level.pedestalCells[i],
          AnimalKind.values[i % AnimalKind.values.length],
        ),
      if (level.chaseStart != null && level.chaseEnd != null)
        Karabasan(level.chaseStart!, level.chaseEnd!),
      for (var i = 0; i < level.memoryCells.length; i++)
        if (!_memories.contains('$index:$i'))
          MemoryShard(level.memoryCells[i], i),
    ]);
    GameAudio.instance.ambientFor(level.def.theme);
    GameAudio.instance.silenceLoops();
    threat = 0;
    hideAmount = 0;
    blizzard = 0;
    quake = 0;
    _stormT = 0;
    jarStrength = 1;
    _darkT = 0;
    if (withPlayer) {
      player = Player(_respawn!.clone());
      world.add(player!);
    } else {
      player = null;
    }
    _snapCamera = true;
  }

  /// Su hazneleri ve içlerindeki yüzen tahtalar: başlangıç su seviyesi
  /// tahtanın satırıdır (tahta yoksa hazne boş başlar).
  Iterable<Component> _basins() sync* {
    for (final area in level.basins) {
      final floats = [
        for (final f in level.floatCells)
          if (area.contains(Offset(f.x + 1, f.y + 1))) f,
      ];
      final start = floats.isEmpty ? area.bottom - 6 : floats.first.y + kTile;
      final basin = WaterBasin(area, start: start);
      yield basin;
      for (final f in floats) {
        yield FloatPlank(f, basin);
      }
    }
  }

  /// Bir noktaya ışık değiyor mu: açık kavanoz (çömelmemiş, saklanmamış),
  /// ateşböceği, Kandilci feneri ve konisi, güneş huzmesi.
  bool litAt(Vector2 at) {
    final p = player;
    if (p != null && p.isMounted && !p.isDead && !p.crouching && !p.hidden) {
      final (pos, r) = p.light;
      if ((pos - at).length < r * 0.7) return true;
    }
    for (final c in world.children) {
      switch (c) {
        case FireflyLure l when l.glowing:
          if ((l.position - at).length < 110) return true;
        case Guard g when !g.falling:
          final lantern = g.lanternWorld;
          final d = at - lantern;
          if (d.length < 70) return true;
          final ahead = d.x * g.facing;
          if (ahead > 0 &&
              ahead < g.coneRange &&
              d.y.abs() < ahead * 0.5 + 34) {
            return true;
          }
        case SunBeam b:
          if (b.lights(Offset(at.x, at.y))) return true;
        case LanternBalloon b:
          if (b.inBeam(at)) return true;
        case FireVent v when v.burning:
          if ((v.position - at).length < 90) return true;
      }
    }
    return false;
  }

  /// Asansör kefeleri soldan sağa eşleşir: her A, sıradaki Y ile.
  Iterable<Component> _lifts() sync* {
    final count = math.min(level.liftA.length, level.liftB.length);
    for (var i = 0; i < count; i++) {
      final a = LiftPan(level.liftA[i]);
      final b = LiftPan(level.liftB[i]);
      yield a;
      yield b;
      yield BalanceLift(a, b);
    }
  }

  Bird? _guideBird() {
    if (level.birdCells.isEmpty) return null;
    final stops = [
      for (final b in level.birdCells)
        Vector2(b.x + kTile / 2, b.y + kTile - 1),
    ]..sort((a, b) => level.progressOf(a).compareTo(level.progressOf(b)));
    final start = Bird.startFor(stops, _respawn!, level.progressOf);
    return Bird(
      stops,
      level.exitCell + Vector2(kTile / 2, kTile - 4),
      start: start,
    );
  }

  // --------------------------------------------------------------- olaylar

  void onPlayerDied() {
    if (_transitioning) return;
    _transitioning = true;
    GameAudio.instance.silenceLoops();
    void respawn() {
      _buildLevel(levelIndex, respawn: true);
      effects.fadeTo(0, 0.7);
      _transitioning = false;
    }

    switch (player?.deathCause) {
      case DeathCause.light:
        // Fenerin soğuk ışığı ekranı kaplar, kavanoz kırılır, karanlık.
        effects.fadeTo(
          0.94,
          0.22,
          color: const Color(0xFFE4FFF8),
          onDone: () {
            GameAudio.instance.play('shatter');
            effects.setFade(1, kInk);
            effects.after(0.9, respawn);
          },
        );
      case DeathCause.stone:
        // Taşa döner: renk çekilir, griye kesilir, sonra karanlık.
        effects.fadeTo(
          0.85,
          0.6,
          color: const Color(0xFF6A6460),
          onDone: () {
            effects.setFade(1, kInk);
            effects.after(0.6, respawn);
          },
        );
      case DeathCause.dark:
        // Karanlık ağır ağır yutar.
        effects.fadeTo(
          1,
          1.3,
          color: kInk,
          onDone: () {
            effects.after(0.4, respawn);
          },
        );
      default:
        effects.fadeTo(1, 0.8, color: kInk, onDone: respawn);
    }
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
          void enter() {
            _buildLevel(next);
            cinematic = false;
            _transitioning = false;
            effects.fadeTo(0, 1.8);
            _showLevelTitle();
          }

          // Bölüm arasında perdede bir gölge oyunu oynanır.
          final interlude = interludeText(next);
          if (interlude.isEmpty) {
            enter();
          } else {
            effects.setFade(1, kInk);
            narration.playCinematic(
              interlude,
              enter,
              instantBlack: true,
              scene: interludeScene(next),
            );
          }
          return;
        }
        final ending = epilogueText;
        narration.playCinematic(
          [
            ...ending.take(ending.length - 1),
            '${S.of('memoriesGathered')}: $memoryCount / $memoryTotal',
            ending.last,
          ],
          () {
            _memories.clear();
            _whispersShown.clear();
            effects.setFade(1, kInk);
            _buildLevel(0);
            _transitioning = false;
            _startPrologue();
          },
          instantBlack: true,
          scene: PerdeScene.epilogue,
        );
      },
    );
  }

  /// Oyuncunun çıkardığı ses: yakındaki Kandilciler duyar ve o yöne bakar.
  void makeNoise(Vector2 at, double radius, {Component? source}) {
    world.add(NoiseRing(at, radius));
    for (final c in world.children.toList()) {
      if (c == source) continue;
      switch (c) {
        case Guard g:
          g.hear(at, radius);
        case BatRoost b:
          b.hear(at, radius);
        case Crow k:
          k.hear(at, radius);
      }
    }
  }

  /// Hezarfen'in kanatları: bu bölümden sonra süzülmek mümkün.
  bool wingsCollected = false;

  void collectWings() {
    wingsCollected = true;
    GameAudio.instance.play('memory');
    narration.whisper(S.of('wings'));
  }

  double _shake = 0;

  /// Kamerayı sarsar (Karabasan, çöken kayalar).
  void shake(double amount) => _shake = math.max(_shake, amount);

  /// Oyuncu kavanozdan bir ateşböceği salar; Kandilciler ışığa yönelir.
  void releaseFirefly(Vector2 from, int direction) {
    if (fireflies <= 0) return;
    fireflies--;
    GameAudio.instance.play('throw');
    GameAudio.instance.play('firefly', volume: 0.6);
    world.add(FireflyLure(from, direction));
    narration.pulseFireflies();
  }

  void gainFirefly() {
    fireflies = math.min(maxFireflies, fireflies + 1);
    GameAudio.instance.play('pickup');
    narration.pulseFireflies();
  }

  void collectMemory(int index) {
    if (!_memories.add('$levelIndex:$index')) return;
    _saveProgress();
    GameAudio.instance.play('memory');
    final lines = level.def.memoryTexts;
    if (index < lines.length) narration.whisper(lines[index]);
    narration.pulseCounter();
  }

  void _checkStoryPoints(Player p) {
    final c = p.center;
    bool near(Vector2 cell, double rx, double ry) {
      final d = c - (cell + Vector2.all(kTile / 2));
      return d.x.abs() < rx && d.y.abs() < ry;
    }

    for (final cell in level.floodCells) {
      if (!near(cell, 48, 200)) continue;
      WaterBasin? best;
      var bestD = double.infinity;
      for (final b in world.children.whereType<WaterBasin>()) {
        final d = (b.area.center.dx - cell.x).abs();
        if (d < bestD) {
          bestD = d;
          best = b;
        }
      }
      best?.startFlood();
    }
    final areas = level.def.areaTexts;
    for (var i = 0; i < level.placeCells.length && i < areas.length; i++) {
      final key = '$levelIndex:p$i';
      if (_whispersShown.contains(key) || !near(level.placeCells[i], 64, 120)) {
        continue;
      }
      _whispersShown.add(key);
      narration.showArea(areas[i]);
    }
    for (final (i, cell) in level.triggers) {
      final key = '$levelIndex:$i';
      if (_whispersShown.contains(key) || !near(cell, 48, 80)) continue;
      _whispersShown.add(key);
      if (i < level.def.whisperTexts.length) {
        narration.whisper(level.def.whisperTexts[i]);
      }
    }
    for (final cell in level.checkpointCells) {
      if (near(cell, 40, 60)) {
        final spot = Level.standOn(cell, Player.w, Player.h);
        if (_respawn != spot) {
          _respawn = spot;
          _saveProgress();
        }
      }
    }
  }

  // ---------------------------------------------------------------- döngü

  @override
  void update(double dt) {
    super.update(dt);
    if (menuMode.value) {
      _updateMenuCamera(dt);
      return;
    }
    final jump = controls.jump;
    if (narration.inCinematic && jump && !_prevJump) narration.skip();
    _prevJump = jump;

    final p = player;
    if (p == null || !p.isMounted) return;
    if (!cinematic && !p.isDead) {
      _checkStoryPoints(p);
      _updateTension(p, dt);
    } else {
      threat = math.max(0, threat - dt * 2);
      hideAmount = math.max(0, hideAmount - dt * 2);
    }
    _updateCamera(p, dt);
  }

  void _updateTension(Player p, double dt) {
    var raw = 0.0;
    var nearest = 0.0;
    var murmur = 0.0;
    for (final c in world.children) {
      switch (c) {
        case Guard g:
          final d = (g.center - p.center).length;
          final near = ((440 - d) / 340).clamp(0.0, 1.0);
          final hunting =
              g.state == GuardState.alert || g.state == GuardState.chase;
          raw = math.max(raw, hunting ? 1.0 : g.suspicion);
          nearest = math.max(nearest, near);
          if (!hunting && !g.distracted) murmur = math.max(murmur, near);
        case Watcher w:
          raw = math.max(raw, w.suspicion);
        case LanternBalloon b:
          raw = math.max(raw, b.suspicion);
        case Karabasan k:
          if (k.awake) raw = math.max(raw, 0.7);
      }
    }
    final k = 1 - math.exp(-dt * 3);
    threat += (raw - threat) * k;
    hideAmount += ((p.hidden ? 1.0 : 0.0) - hideAmount) * k;

    final audio = GameAudio.instance;
    // Saklanırken kalp atışı: Kandilci ne kadar yakınsa o kadar güçlü.
    final heart = p.hidden
        ? math.max(nearest, threat) * 0.9 + 0.1
        : math.max(0.0, threat - 0.45) * 1.6;
    audio.heartbeat(heart.clamp(0.0, 1.0));
    audio.murmur(murmur * (1 - hideAmount * 0.4));
    audio.duck(hideAmount);

    // Uzaktan zincir sesleri: sarnıçta ve mağarada ara sıra.
    _chainT -= dt;
    if (_chainT <= 0) {
      _chainT = 22 + _rnd.nextDouble() * 30;
      final theme = level.def.theme;
      if (theme.indoor) {
        audio.play('chain', volume: 0.18 + _rnd.nextDouble() * 0.15);
      }
    }

    _updateDarkZone(p, dt);
    _updateStorm(dt);
  }

  /// Şimşek: ekranı bir anlığına beyaza boğar, her şey görünür.
  double lightning = 0;
  double _boltT = 6;
  double _thunderIn = -1;

  /// Tipi döngüsü: ~15 saniyede bir, birkaç saniye bastırıp diner. Gökte
  /// ise fırtına şimşekle gelir.
  void _updateStorm(double dt) {
    lightning = math.max(0, lightning - dt * 3);
    if (_thunderIn > 0) {
      _thunderIn -= dt;
      if (_thunderIn <= 0) GameAudio.instance.play('thunder', volume: 0.8);
    }
    if (!level.def.storm) {
      blizzard = 0;
      return;
    }
    if (!level.def.theme.snowy) {
      blizzard = 0;
      _boltT -= dt;
      if (_boltT <= 0) {
        _boltT = 8 + _rnd.nextDouble() * 7;
        lightning = 1;
        _thunderIn = 0.3 + _rnd.nextDouble() * 0.8;
      }
      return;
    }
    _stormT += dt;
    const period = 15.0;
    final k = (_stormT % period) / period;
    // 0.6-0.66 artar, 0.66-0.86 sürer, 0.86-0.92 diner.
    final target = k < 0.6
        ? 0.0
        : k < 0.66
        ? (k - 0.6) / 0.06
        : k < 0.86
        ? 1.0
        : k < 0.92
        ? 1 - (k - 0.86) / 0.06
        : 0.0;
    if (blizzard < 0.05 && target > 0.05) {
      GameAudio.instance.play('gust', volume: 0.8, minGapMs: 4000);
      if (!_stormWarned) {
        _stormWarned = true;
        narration.whisper(S.of('blizzard'));
      }
    }
    blizzard = target;
  }

  /// Karanlık bölge: ışığı yer. Ateşböcekleri birer birer söner; hiç
  /// kalmayınca karanlık Sâye'yi yutar.
  void _updateDarkZone(Player p, double dt) {
    final dark = level.inDarkZone(p.center);
    final target = dark ? 0.3 + 0.7 * (fireflies / maxFireflies) : 1.0;
    jarStrength += (target - jarStrength) * (1 - math.exp(-dt * 2));
    if (!dark) {
      _darkT = 0;
      return;
    }
    if (!_darkWarned) {
      _darkWarned = true;
      narration.whisper(S.of('darkZone'));
    }
    _darkT += dt;
    if (fireflies > 0) {
      if (_darkT >= darkDrain) {
        _darkT = 0;
        fireflies--;
        GameAudio.instance.play('fizzle');
        narration.pulseFireflies();
      }
    } else if (_darkT >= darkSwallow) {
      _darkT = 0;
      p.die(cause: DeathCause.dark);
    }
  }

  void _updateCamera(Player p, double dt) {
    final view = camera.viewport.size;
    if (view.x == 0 || view.y == 0) return;
    // Limbo gibi uzak bir kamera: ekranda yaklaşık 20 kare yükseklik.
    final zoom =
        view.y /
        (kTile * math.min(tilesTall, level.height.toDouble())) *
        _closeUp *
        (1 + 0.05 * threat);
    camera.viewfinder.zoom = zoom;

    // Gidilen yöne doğru ileriyi gösterir; hızlandıkça daha çok.
    _lookAhead +=
        ((p.facing * 60 + p.velocity.x * 0.35) - _lookAhead) *
        (1 - math.exp(-dt * 1.5));
    final target = p.center + Vector2(_lookAhead, -20);
    final halfW = view.x / zoom / 2;
    final halfH = view.y / zoom / 2;
    target.x = level.pixelWidth <= halfW * 2
        ? level.pixelWidth / 2
        : target.x.clamp(halfW, level.pixelWidth - halfW);
    target.y = level.pixelHeight <= halfH * 2
        ? level.pixelHeight / 2
        : target.y.clamp(halfH, level.pixelHeight - halfH);

    if (_shake > 0.05) {
      target.add(
        Vector2(
          (_rnd.nextDouble() - 0.5) * _shake * 2,
          (_rnd.nextDouble() - 0.5) * _shake * 2,
        ),
      );
      _shake *= math.pow(0.02, dt).toDouble();
    }
    final pos = camera.viewfinder.position;
    if (_snapCamera) {
      camera.viewfinder.position = target;
      _snapCamera = false;
    } else {
      final k = 1 - math.exp(-dt * 3.2);
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
      ..sneak = any([
        LogicalKeyboardKey.shiftLeft,
        LogicalKeyboardKey.shiftRight,
        LogicalKeyboardKey.keyQ,
      ]);
    if (menuMode.value) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.escape &&
          overlays.isActive(settingsOverlay)) {
        toggleSettings();
      }
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) {
      // Sahne sürerken Esc perdeyi atlar (ayarlar dişli simgesinden açılır).
      if (event.logicalKey == LogicalKeyboardKey.escape &&
          narration.inCinematic &&
          !overlays.isActive(settingsOverlay)) {
        narration.skipAll();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        toggleSettings();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.f11) {
        onToggleFullscreen?.call();
        return KeyEventResult.handled;
      }
      if (paused) return KeyEventResult.handled;
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
      // Geliştirici kısayolu: P perde sahnelerini sırayla oynatır.
      if (const bool.fromEnvironment('DEV') &&
          event.logicalKey == LogicalKeyboardKey.keyP &&
          !narration.inCinematic) {
        final scene =
            PerdeScene.values[_debugScene++ % PerdeScene.values.length];
        final lines = switch (scene) {
          PerdeScene.prologue => prologueText,
          PerdeScene.epilogue => epilogueText,
          _ => interludeText(
            [for (var i = 0; i < 20; i++) i]
                .firstWhere((i) => interludeScene(i) == scene, orElse: () => 1),
          ),
        };
        cinematic = true;
        narration.playCinematic(lines, () => cinematic = false, scene: scene);
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
