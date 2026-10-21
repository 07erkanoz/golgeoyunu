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
import 'shafts.dart';
import 'levels.dart';
import 'narration.dart';
import 'perde.dart';
import 'persist.dart';
import 'palette.dart';
import 'player.dart';
import 'konya.dart';
import 'hints.dart';
import 'legends.dart';
import 'umay.dart';
import 'gokboru.dart';
import 'cameos.dart';
import 'myth_cards.dart';
import 'nemrut.dart';
import 'ski.dart';
import 'wind.dart';
import 'winter.dart';
import 'puzzles.dart';
import 'rig.dart';
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

  /// Basılı tutulan yön ve zıplama bırakılır.
  void release() {
    left = false;
    right = false;
    up = false;
    down = false;
    jump = false;
  }
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

  /// Bütün girdi kaynakları birlikte temizlenir: menü/ayar açılışı, odak
  /// kaybı, uygulamanın arka plana alınması, kontrol modunun değişmesi.
  /// Klavyede parmak ucu basılı tutulur, o da bırakılır; dokunmatikte bir
  /// anahtardır ve korunur (simgesi de aynı durumu gösterir).
  void resetAll() {
    keyboard
      ..release()
      ..sneak = false;
    touch.release();
    _lureQueued = false;
  }

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
  /// gibi alçak ekranlarda çocuk seçilebilsin diye daha yakın. Ekran boyuyla
  /// kesintisiz değişir (önceden 520 pikselde 13'ten 20'ye sıçrıyordu:
  /// pencereyi boyutlandırırken ya da tablet döndürünce dünya birden
  /// küçülüyordu).
  double get tilesTall =>
      (13 + (camera.viewport.size.y - 380) * (7 / 340)).clamp(13.0, 20.0);
  double _lookAhead = 0;

  /// Yumuşatılmış yakınlık (boyut değişiminde kamera sıçramaz).
  double _zoomS = 0;

  /// Kameranın dikeyde izlediği zemin: zıplarken kamera inip çıkmaz;
  /// oyuncu bir bandın dışına çıkınca (yüksek kat, derin düşüş) peşinden
  /// gider.
  double _camFloor = double.nan;
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

  /// Albastı kavanozun ışığını çekiyor (0-1).
  double jarSteal = 0;

  /// Karanlık bölgede bir ateşböceğinin sönme süresi.
  static const darkDrain = 6.5;

  /// Ateşböceği kalmayınca karanlığın yutma süresi.
  static const darkSwallow = 4.5;

  double _darkT = 0;
  bool _darkWarned = false;

  /// Kayak bölümünün yamacı (kayak bölümü değilse yok).
  SkiSurface? skiSurface;

  bool inMagnet(double x) =>
      world.children.whereType<MagnetZone>().any((m) => m.covers(x));

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

  /// Hatıra defteri için: kayıttakiler ve bu oturumda bulunanlar.
  Set<String> get collectedMemories => {
    ...?SaveGame.current?.memories,
    ..._memories,
  };

  /// Defter > Efsaneler: karşılaşılan mitolojik varlıklar (kayıttakiler ve
  /// bu oturumda görülenler).
  Set<String> get mythsSeen => {
    for (final w in [...?SaveGame.current?.whispers, ..._whispersShown])
      if (w.startsWith('myth:')) w.substring(5),
  };

  /// Bir varlıkla ilk karşılaşma: Defter'de kartı açılır, oyuncuya söylenir.
  void meetMyth(String id) {
    final key = 'myth:$id';
    if (_whispersShown.contains(key)) return;
    final card = MythCard.byId(id);
    if (card == null) return;
    _whispersShown.add(key);
    narration.showMyth(card.name, card.who);
  }

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
    // Bozuk bir kayıt menünün kurulmasını engellemesin.
    _buildLevel(
      (saved?.level ?? 0).clamp(0, levels.length - 1),
      withPlayer: false,
    );
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
    onFocusGame?.call();
    GameAudio.instance.menuMusic(false);
  }

  /// Baştan başlar; varsa kayıt silinir.
  void startNewGame() {
    // Oyun yüklenmeden gelen tıklama yok sayılır (menü yarım kurulu kalmasın).
    if (!isLoaded || !menuMode.value) return;
    SaveGame.clear();
    _memories.clear();
    _whispersShown.clear();
    fireflies = startFireflies;
    wingsCollected = false;
    _respawn = null;
    _puzzle = null;
    _leaveMenu();
    _buildLevel(0);
    _saveProgress();
    _startPrologue();
  }

  /// Bölüm listesinden: açılmış bir bölümü baştan oynar. Toplanan hatıralar
  /// korunur; o bölümün fısıltıları ve yer adları yeniden anlatılır.
  void startChapter(int index) {
    if (!isLoaded || !menuMode.value) return;
    if (index < 0 || index >= levels.length || index > Settings.unlocked) {
      return;
    }
    final save = SaveGame.current;
    _memories
      ..clear()
      ..addAll(save?.memories ?? const []);
    _whispersShown
      ..clear()
      ..addAll(
        (save?.whispers ?? const []).where(
          (w) =>
              !w.startsWith('$index:') &&
              !(w.startsWith('event:') && w.split(':')[2] == '$index'),
        ),
      );
    fireflies = startFireflies;
    // Kanatlar Kule'de (2. bölüm) bulunur: ondan önceki bölümler kanatsız,
    // sonrakiler kanatla oynanır (öğretim dengesi bozulmasın).
    wingsCollected = index >= 2;
    _respawn = null;
    _puzzle = null;
    _leaveMenu();
    _buildLevel(index);
    _saveProgress();
    cinematic = false;
    effects.setFade(1, kInk);
    effects.fadeTo(0, 1.4);
    _showLevelTitle();
  }

  /// Kaldığın yerden: son kontrol noktasında, toplananlarla birlikte.
  void continueGame() {
    if (!isLoaded || !menuMode.value) return;
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
    _puzzle = save.puzzle.isEmpty ? null : save.puzzle;
    _checkpointFireflies = save.fireflies;
    _leaveMenu();
    _buildLevel(save.level.clamp(0, levels.length - 1), respawn: true);
    // Kayıttaki konum bu bölümün içinde değilse bölüm başından.
    final r = _respawn!;
    if (r.x < 0 ||
        r.y < 0 ||
        r.x > level.pixelWidth ||
        r.y > level.pixelHeight) {
      _respawn = Level.standOn(level.playerStart, Player.w, Player.h);
      player?.position.setFrom(_respawn!);
    }
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

  /// Uygulama arka plana alınırken: son kontrol noktası kaydedilir.
  Future<void> saveNow() => _saveProgress();

  Future<void> _saveProgress() {
    final r = _respawn;
    if (menuMode.value || r == null) return SaveGame.flush();
    return SaveGame.write(
      SaveData(
        level: levelIndex,
        x: r.x,
        y: r.y,
        memories: _memories.toList(),
        whispers: _whispersShown.toList(),
        fireflies: fireflies,
        wings: wingsCollected,
        puzzle: _puzzle ?? const {},
      ),
    );
  }

  /// Son kontrol noktasındaki bulmaca durumu (null: bölüm başı).
  Map<String, Object?>? _puzzle;

  /// Kontrol noktasına dokunulduğunda elde olan ateşböceği: ölünce bundan
  /// azıyla dönülmez (karanlık geçiş kaynaksız kalmasın).
  int _checkpointFireflies = 0;

  /// Şu an üstünde durulan kontrol noktası (yanından geçerken her kare
  /// yeniden kaydetmesin).
  Vector2? _atCheckpoint;

  /// Kontrol noktasına dokunuldu: konum, bulmaca durumu ve elde olanlar
  /// saklanır.
  void _reachCheckpoint(Vector2 cell) {
    // Umay ağacı uyanır (bulmaca durumuyla birlikte uyanık saklanır).
    for (final t in world.children.whereType<UmayTree>()) {
      if (t.cell.x == cell.x && t.cell.y == cell.y) {
        t.wake();
        // Önce ağacın ne olduğu, sonra Defter'e yazıldığı söylenir.
        _queueHint('umay');
        meetMyth('umay');
      }
    }
    _respawn = Level.standOn(cell, Player.w, Player.h);
    _puzzle = capturePuzzle(world.children);
    _checkpointFireflies = fireflies;
    _saveProgress();
  }

  /// Kontrol noktası hücresinin üstündeki boşluk (piksel): ağaç tavana
  /// sığacak kadar büyür.
  double _headroom(Vector2 cell) {
    final c = (cell.x / kTile).floor();
    final r0 = (cell.y / kTile).floor();
    var rows = 1;
    for (var r = r0 - 1; r >= 0 && rows < 5; r--) {
      if (level.solid(c, r) || level.solid(c - 1, r) || level.solid(c + 1, r)) {
        break;
      }
      rows++;
    }
    return rows * kTile;
  }

  /// Testler için: kontrol noktasına dokunulmuş gibi şimdiki düzeni saklar.
  void debugCheckpoint() => _reachCheckpoint(
    Vector2(player!.position.x, player!.position.y + Player.h - kTile),
  );

  /// Yeniden doğarken: kontrol noktasındaki kadar ateşböceği; karanlığın
  /// içinde ya da kıyısında doğuluyorsa en az iki (yolu görecek kadar).
  void _ensureFireflies() {
    fireflies = math.max(fireflies, _checkpointFireflies);
    final r = _respawn;
    if (r == null) return;
    final near = level.darkZones.any(
      (z) => z.inflate(6 * kTile).contains(Offset(r.x, r.y)),
    );
    if (near) fireflies = math.max(fireflies, startFireflies);
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

  /// Klavye odağını oyuna geri verir (main.dart bağlar). Menüde bir düğmeye
  /// tıklanınca odak o düğmede kalır; menü kapanınca oyun tuşları duymaz.
  void Function()? onFocusGame;

  void toggleSettings() {
    if (overlays.isActive(settingsOverlay)) {
      overlays.remove(settingsOverlay);
      settingsOpen.value = false;
      onFocusGame?.call();
      if (!menuMode.value) {
        resumeEngine();
        GameAudio.instance.resumeAll();
      }
    } else {
      // Basılı kalan tuş ya da parmak menü kapanınca oyuncuyu yürütmesin.
      controls.resetAll();
      _showOverlay(settingsOverlay);
      settingsOpen.value = true;
      if (!menuMode.value) {
        pauseEngine();
        GameAudio.instance.pauseAll();
      }
    }
  }

  /// Testler için: bölüm başlığını (ve ardından ozan dizesini) gösterir.
  void debugShowTitle() => _showLevelTitle();

  void _showLevelTitle() {
    narration.showTitle(
      level.def.titleText,
      level.def.subtitleText,
      level.def.placeText,
    );
    // Başlık söndükten sonra ozanın dizesi (bölüm başına bir kez).
    final line = level.def.bardText;
    if (line.isEmpty || _whispersShown.contains('once:bard:$levelIndex')) {
      return;
    }
    _bardIn = 5.6;
    _bardLevel = levelIndex;
  }

  /// Ozan dizesine kalan süre (yoksa negatif).
  double _bardIn = -1;
  int _bardLevel = -1;

  void _updateBard(double dt) {
    if (_bardIn < 0) return;
    _bardIn -= dt;
    if (_bardIn >= 0) return;
    if (_bardLevel == levelIndex && !menuMode.value) {
      once('bard:$levelIndex', level.def.bardText);
    }
  }

  /// Testler için: gerçek bölümlerin yerine küçük deneme haritaları.
  static List<LevelDef>? debugLevels;

  void _buildLevel(int index, {bool respawn = false, bool withPlayer = true}) {
    world.removeAll(world.children.toList());
    // Yeni bir bölüme geçerken (ölüp yeniden doğmada değil) eski bölümün
    // bekleyen metinleri atılır.
    if (!respawn || index != levelIndex) {
      narration.resetScene();
      // Başka bölüme geçerken önceki bölümün bulmaca durumu atılır.
      _puzzle = null;
    }
    _atCheckpoint = null;
    levelIndex = index;
    // Oynanan en ileri bölüm açılır (bölüm listesi için).
    if (withPlayer && index > Settings.unlocked) {
      Settings.unlocked = index;
      Settings.save();
    }
    level = Level((debugLevels ?? levels)[index]);
    final ski = level.def.skiSurface;
    skiSurface = ski == null ? null : SkiSurface(ski);
    if (!respawn || _respawn == null) {
      _respawn = Level.standOn(level.playerStart, Player.w, Player.h);
      _darkWarned = false;
      _checkpointFireflies = fireflies;
    }
    if (respawn) _ensureFireflies();

    world.addAll(
      restorePuzzle([
        TerrainComponent(level),
        LightingLayer(),
        LightShafts(),
        ForegroundComponent(level),
        WindCurrents(),
        WaterComponent(level),
        ExitPortal(level.exitCell),
        for (final k in level.checkpointCells)
          UmayTree(k, headroom: _headroom(k)),
        for (final (c0, c1, r) in level.def.pawTrails)
          ?PawTrail.build(level, c0, c1, r),
        if (level.def.gokboruGuard ||
            level.def.gokboruHelp ||
            level.def.gokboruWatch.isNotEmpty)
          GokboruWarden(
            guard: level.def.gokboruGuard,
            help: level.def.gokboruHelp,
            watch: level.def.gokboruWatch,
            leadTo: level.def.gokboruLead,
          ),
        if (level.def.cameos.isNotEmpty) CameoWarden(level.def.cameos),
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
        if (!wingsCollected)
          for (final c in level.wingsCells) WingsPickup(c),
        for (final c in level.glimpseCells) KarabasanGlimpse(c),
        for (var i = 0; i < level.def.echoes.length; i++)
          EchoSteps(level.def.echoes[i].$1, level.def.echoes[i].$2, stage: i),
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
        for (final c in level.shieldCells)
          if (level.def.theme == LevelTheme.cave)
            MillStone(c)
          else
            ShieldCrate(c),
        for (final c in level.ringCells) FairyRing(c),
        for (final c in level.raftCells) Raft(c),
        for (var i = 0; i < level.ventCells.length; i++)
          FireVent(level.ventCells[i], phase: i * 1.1),
        for (final c in level.balloonCells) LanternBalloon(c),
        for (final c in level.featherCells) SimurgFeather(c),
        for (final c in level.altarCells) FeatherAltar(c),
        for (final c in level.bellCells) WindBell(c),
        for (final c in level.ruinCells) MonasteryRuin(c),
        for (final c in level.perdeCells) ...[
          GiantPerde(c, puzzle: level.eyeStoneCells.isNotEmpty),
          // Bulmacalı perdenin ipi sol kenarında.
          if (level.eyeStoneCells.isNotEmpty) PerdeCord(c - Vector2(kTile, 0)),
        ],
        for (final c in level.eyeStoneCells) EyeStone(c),
        for (final (c, r, n) in level.glowRuns)
          PhasePlank(Vector2(c * kTile, r * kTile.toDouble()), n, shade: false),
        // Gölge köprüsü ikişer karelik parçalardan: ışık yalnızca değdiği
        // parçayı siler (tek parça olunca ışığın bir ucu bütün köprüyü
        // siliyordu; iki gözcülü köprü hiç geçilemiyordu).
        for (final (c, r, n) in level.shadeRuns)
          for (var k = 0; k < n; k += 2)
            PhasePlank(
              Vector2((c + k) * kTile, r * kTile.toDouble()),
              math.min(2, n - k),
              shade: true,
            ),
        for (final (c, r, n) in level.rottenRuns) RottenPlank(c, r, n),
        ..._basins(),
        for (final c in level.drainValves) Valve(c, fill: false),
        for (final c in level.fillValves) Valve(c, fill: true),
        for (final (c, slash) in level.mirrorCells) Mirror(c, slash: slash),
        for (final c in level.lockCells) SunLock(c),
        for (final c in level.beamCells) SunBeam(c),
        for (final (c, r, n) in level.ropes) SwingRope(c, r, n),
        for (var i = 0; i < level.animalCells.length; i++)
          AnimalCrate(level.animalCells[i], _kind(level.def.animalKinds, i)),
        // Kefenin üstündeki gölgeler terazinin parçasıdır (_lifts kurar).
        for (var i = 0; i < level.pedestalCells.length; i++)
          if (_panBelow(level.pedestalCells[i]) == null)
            Pedestal(level.pedestalCells[i], _kind(level.def.shadowKinds, i)),
        if (level.chaseStart != null && level.chaseEnd != null)
          if (skiSurface != null)
            Avalanche(level.chaseStart!, level.chaseEnd!)
          else if (level.def.theme == LevelTheme.konya)
            LightFlood(level.chaseStart!, level.chaseTop!)
          else
            Karabasan(level.chaseStart!, level.chaseEnd!),
        for (var i = 0; i < level.semazenCells.length; i++)
          Semazen(level.semazenCells[i], index: i),
        for (var i = 0; i < level.chandelierCells.length; i++)
          ..._chandelier(level.chandelierCells[i], i),
        for (var i = 0; i < level.lampCells.length; i++)
          GreatLamp(level.lampCells[i], index: i),
        // İki fener aynı şerefedeyse aralarında bir minare yükselir.
        if (level.lampCells.length >= 2)
          MinaretCap(
            Vector2(
              (level.lampCells[0].x + level.lampCells[1].x) / 2 + kTile / 2,
              level.lampCells[0].y - kTile - 24,
            ),
          ),
        if (skiSurface != null) SkiTerrain(skiSurface!),
        if (skiSurface != null)
          for (final c in level.skiRocks) SkiRock(c, skiSurface!),
        for (final (c, r, n) in level.skiRails) SkiRail(c, r, n),
        for (final (a, b) in level.def.magnet)
          MagnetZone(a * kTile.toDouble(), (b + 1) * kTile.toDouble()),
        for (var i = 0; i < level.memoryCells.length; i++)
          if (!_memories.contains('$index:$i'))
            MemoryShard(level.memoryCells[i], i),
      ], _puzzle),
    );
    GameAudio.instance.ambientFor(level.def.theme);
    GameAudio.instance.silenceLoops();
    GameAudio.instance.prewarmLoops();
    threat = 0;
    hideAmount = 0;
    blizzard = 0;
    quake = 0;
    _stormT = 0;
    jarStrength = 1;
    jarSteal = 0;
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
  Iterable<Component> _chandelier(Vector2 cell, int index) sync* {
    final c = Chandelier(cell, index: index);
    yield c;
    yield* c.planks;
  }

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

  /// Kapalı bir kapı bu alanı kesiyor mu (Kandilci, kurt geçemez).
  bool closedGateAt(Rect r) => world.children.whereType<Gate>().any(
    (g) => g.solid && g.toRect().overlaps(r),
  );

  /// Bir noktaya ışık değiyor mu: açık kavanoz (çömelmemiş, saklanmamış),
  /// ateşböceği, Kandilci feneri ve konisi, güneş huzmesi. Kaya duvar ışığı
  /// keser: duvarın ardındaki tahta yanmaz (güneş huzmesi ve uçan fener kendi
  /// ışınlarını zaten duvarda keser).
  /// Bu karenin ışık kaynakları (tahtalar her karede çok kez sorar; bütün
  /// dünyayı her seferinde dolaşmasın).
  final _lights = <Component>[];
  int _lightsFrame = -1;
  int _frame = 0;

  bool litAt(Vector2 at) {
    bool reaches(Vector2 from, double radius) {
      final dx = from.x - at.x;
      final dy = from.y - at.y;
      return dx * dx + dy * dy < radius * radius && level.lineOfSight(from, at);
    }

    if (_lightsFrame != _frame) {
      _lightsFrame = _frame;
      _lights
        ..clear()
        ..addAll(
          world.children.where(
            (c) =>
                c is FireflyLure ||
                c is Guard ||
                c is SunBeam ||
                c is LanternBalloon ||
                c is FireVent,
          ),
        );
    }
    final p = player;
    if (p != null && p.isMounted && !p.isDead && !p.crouching && !p.hidden) {
      final (pos, r) = p.light;
      if (reaches(pos, r * 0.7)) return true;
    }
    for (final c in _lights) {
      if (!c.isMounted) continue;
      switch (c) {
        case FireflyLure l when l.glowing:
          if (reaches(l.position, 110)) return true;
        case Guard g when !g.falling:
          final lantern = g.lanternWorld;
          final d = at - lantern;
          if (reaches(lantern, 70)) return true;
          final ahead = d.x * g.facing;
          if (ahead > 0 &&
              ahead < g.coneRange &&
              d.y.abs() < ahead * 0.5 + 34 &&
              level.lineOfSight(lantern, at)) {
            return true;
          }
        case SunBeam b:
          if (b.lights(Offset(at.x, at.y))) return true;
        case LanternBalloon b:
          if (b.inBeam(at)) return true;
        case FireVent v when v.burning:
          if (reaches(v.position, 90)) return true;
      }
    }
    return false;
  }

  AnimalKind _kind(List<int> kinds, int i) {
    final k = i < kinds.length ? kinds[i] : i;
    return AnimalKind.values[k % AnimalKind.values.length];
  }

  /// Gölge hücresinin hemen altındaki kefe hücresi (terazi), yoksa null.
  Vector2? _panBelow(Vector2 shadow) {
    for (final p in [...level.liftA, ...level.liftB]) {
      if ((p.x - shadow.x).abs() < 1 && (p.y - shadow.y - kTile).abs() < 1) {
        return p;
      }
    }
    return null;
  }

  /// Kefenin üstündeki gölgenin türü (terazi değilse null).
  AnimalKind? _panShadow(Vector2 pan) {
    for (var i = 0; i < level.pedestalCells.length; i++) {
      final s = level.pedestalCells[i];
      if ((pan.x - s.x).abs() < 1 && (pan.y - s.y - kTile).abs() < 1) {
        return _kind(level.def.shadowKinds, i);
      }
    }
    return null;
  }

  /// Asansör kefeleri soldan sağa eşleşir: her A, sıradaki Y ile. İki
  /// kefesinin üstünde de hayvan gölgesi olan çift terazidir: kefeler
  /// altlarındaki çukur kadar iner, eşit yükte hizalanır.
  Iterable<Component> _lifts() sync* {
    final count = math.min(level.liftA.length, level.liftB.length);
    for (var i = 0; i < count; i++) {
      final a = LiftPan(level.liftA[i]);
      final b = LiftPan(level.liftB[i]);
      yield a;
      yield b;
      final kindA = _panShadow(level.liftA[i]);
      final kindB = _panShadow(level.liftB[i]);
      if (kindA != null && kindB != null) {
        var travel = 4;
        for (final pan in [level.liftA[i], level.liftB[i]]) {
          final c = (pan.x / kTile).floor();
          final r0 = (pan.y / kTile).floor();
          for (var r = r0 + 1; r <= r0 + 4 && r < level.height; r++) {
            if (level.solid(c, r) || level.solid(c + 1, r)) {
              travel = math.min(travel, r - r0 - 1);
              break;
            }
          }
        }
        final lift = BalanceLift(a, b, travel: travel * kTile, levelling: true);
        final scale = ArkScale(lift, kindA, kindB);
        yield lift;
        yield scale;
        // Kol: sol kefenin solundaki rafın üstünde.
        yield ScaleCrank(
          scale,
          Vector2(a.base.x - kTile / 2, a.base.y - 2 * kTile),
        );
        continue;
      }
      // İnen kefe suya gömülmesin: suyun bir kare üstünde durur.
      var travel = 4;
      for (final pan in [level.liftA[i], level.liftB[i]]) {
        final c = (pan.x / kTile).floor();
        final r0 = (pan.y / kTile).floor();
        for (var r = r0 + 1; r <= r0 + 4 && r < level.height; r++) {
          if (level.cell(c, r) == 'w' || level.cell(c + 1, r) == 'w') {
            travel = math.min(travel, r - r0 - 1);
            break;
          }
        }
      }
      yield BalanceLift(a, b, travel: travel * kTile);
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
          // Sakin efektlerde göz alan beyaz yerine soluk bir gri.
          color: Settings.calmEffects
              ? const Color(0xFF5E6A68)
              : const Color(0xFFE4FFF8),
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
            // Yeni bölüme girer girmez kaydedilir (ilk kontrol noktasına
            // varmadan uygulama kapansa da bölüm kaybolmasın).
            _saveProgress();
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
            // Perde kapanır: ana menüye dönülür, kayıt (son bölüm) korunur.
            _transitioning = false;
            _enterMenu();
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
  void shake(double amount) =>
      _shake = math.max(_shake, amount * Settings.flashScale);

  double _slow = 0;

  /// Korku anı: ekran nabzı, sarsıntı, istenirse korku vurgusu sesi ve
  /// kısa bir ağır çekim.
  void scare(double amount, {bool sting = true, bool slow = false}) {
    effects.scare(amount);
    shake(10 * amount);
    threat = math.max(threat, amount);
    if (sting) GameAudio.instance.play('sting', volume: amount, minGapMs: 1500);
    if (slow) _slow = 0.45;
    player?.shadowFright(amount);
  }

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
      // Konya: semâhaneye girerken neyzen ilk nefesini üfler.
      if (level.def.theme == LevelTheme.konya && i == areas.length - 2) {
        GameAudio.instance.play('perde_ney', volume: 0.8);
      }
    }
    for (final (i, cell) in level.triggers) {
      final key = '$levelIndex:$i';
      if (_whispersShown.contains(key) || !near(cell, 48, 80)) continue;
      _whispersShown.add(key);
      if (i < level.def.whisperTexts.length) {
        narration.whisper(level.def.whisperTexts[i]);
      }
    }
    Vector2? touching;
    for (final cell in level.checkpointCells) {
      if (near(cell, 40, 60)) touching = cell;
    }
    // Her dokunuşta (yanına yeniden gelince de) yeniden saklanır: geri dönüp
    // çözülen düzenekler de kayda girer.
    if (touching != null && touching != _atCheckpoint) {
      _reachCheckpoint(touching);
    }
    _atCheckpoint = touching;
  }

  // ---------------------------------------------------------------- döngü

  @override
  void update(double dt) {
    // Tek oyun saati: bütün dünya (oyuncu, Kandilci, su, ışık seli) aynı
    // adımla ilerler. Yavaş cihazdaki uzun kare en çok 1/30 saniyelik eşit
    // parçalara bölünür; böylece düşük FPS'te Kandilci oyuncudan hızlı
    // yaşamaz. Uygulama kesintisi gibi çok uzun boşluk telafi edilmez.
    if (!dt.isFinite || dt < 0) dt = 0;
    dt = math.min(dt, maxFrame);
    // Korku anında zaman kısa bir süre ağırlaşır.
    if (_slow > 0) {
      _slow -= dt;
      dt *= 0.35;
    }
    final steps = math.max(1, (dt / maxStep - 1e-9).ceil());
    for (var i = 0; i < steps; i++) {
      _frame++;
      super.update(dt / steps);
    }
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
      _updateHints(p, dt);
      _updateBard(dt);
    } else {
      threat = math.max(0, threat - dt * 2);
      hideAmount = math.max(0, hideAmount - dt * 2);
    }
    _updateCamera(p, dt);
  }

  double _hintScan = 0;

  /// Bir simülasyon adımının en uzun süresi.
  static const double maxStep = 1 / 30;

  /// Bir karede telafi edilen en uzun süre (bundan uzun kesinti duraklama
  /// sayılır).
  static const double maxFrame = 0.1;

  /// Olay mesajı: kayıt başına bir kez gösterilir; ölüp yeniden denerken
  /// tekrarlanmaz. [hint] ise üstte ipucu olarak sıraya girer.
  /// Bir kez görülmesi gereken sahne olayları (dev perde, karanlıktaki
  /// gözler): kayda yazılır, ölüp yeniden doğunca ya da devam edince
  /// yeniden oynamaz.
  bool eventSeen(String key) => _whispersShown.contains('event:$key');
  void markEvent(String key) => _whispersShown.add('event:$key');

  void once(String key, String text, {bool hint = false}) {
    final id = 'once:$key';
    if (_whispersShown.contains(id)) return;
    _whispersShown.add(id);
    if (hint) {
      narration.hint(text, queue: true);
    } else {
      narration.whisper(text);
    }
  }

  /// İpucunu (gösterilmediyse) sıraya koyar: tarama beklenmeden, başka bir
  /// söz araya girmeden önce söylenmesi gerekenler için.
  void _queueHint(String key) {
    final id = 'hint:$key';
    if (_whispersShown.contains(id)) return;
    _whispersShown.add(id);
    narration.hint(Hints.text(key), queue: true);
    final poem = Hints.poem(key);
    if (poem.isNotEmpty) once('poem:$key', poem);
  }

  /// Bu bir kezlik söz söylendi mi (testler için)?
  bool onceShown(String key) => _whispersShown.contains('once:$key');

  /// Bu ipucu gösterildi mi (testler için)?
  bool hintShown(String key) => _whispersShown.contains('hint:$key');

  /// İlk karşılaşmada düzeneğin nasıl kullanıldığını söyler (bir kez;
  /// kayıtla hatırlanır).
  void _updateHints(Player p, double dt) {
    _hintScan += dt;
    if (_hintScan < 0.3) return;
    _hintScan = 0;
    void show(String key) {
      final id = 'hint:$key';
      if (_whispersShown.contains(id)) return;
      // Ekran doluysa gösterilmiş sayılmaz; oyuncu hâlâ yakındaysa sonraki
      // taramada yeniden denenir (geçip gittiyse sonra çıkmaz).
      if (!narration.hint(Hints.text(key))) return;
      _whispersShown.add(id);
      // Bazı düzeneklerin kuralı bir de şiirle, hikâyenin içinde anlatılır.
      final poem = Hints.poem(key);
      if (poem.isNotEmpty) once('poem:$key', poem);
    }

    bool near(PositionComponent c, double dx, [double? dy]) {
      final r = c.toRect();
      final d = r.center - Offset(p.center.x, p.center.y);
      return d.dx.abs() < dx * kTile + r.width / 2 &&
          d.dy.abs() < (dy ?? dx) * kTile + r.height / 2;
    }

    if (skiSurface != null) show('ski');
    if (p.hasWings && !p.onGround && p.velocity.y > 60) show('glide');
    final pc = (p.center.x / kTile).floor();
    final pr = (p.center.y / kTile).floor();
    for (var c = pc - 3; c <= pc + 3; c++) {
      for (var r = pr - 2; r <= pr + 2; r++) {
        switch (level.cell(c, r)) {
          case '|':
            show('climb');
          case 'I' || '~':
            show('hide');
          case 'r':
            if ((c - pc).abs() < 2) show('wind');
        }
      }
    }
    for (final comp in world.children) {
      final key = switch (comp) {
        PhasePlank k when near(k, 4, 3) =>
          k.shade ? 'shadePlank' : 'lightPlank',
        Guard g when near(g, 9, 3) => 'guard',
        ShieldCrate s when near(s, 5, 3) => 'shield',
        MillStone m when near(m, 5, 3) => 'millstone',
        AnimalCrate a when near(a, 4, 3) => 'animal',
        Crate k when near(k, 3, 2) => 'crate',
        Lever l when near(l, 4, 4) => 'lever',
        UmayTree u when near(u, 3, 3) => 'umay',
        PawTrail t when near(t, 4, 3) => 'gokboruTrail',
        Valve v when near(v, 4, 3) => 'valve',
        PerdeCord k when near(k, 4, 3) => 'cord',
        ArkScale s when near(s.lift.a, 6, 4) || near(s.lift.b, 6, 4) => 'scale',
        EyeStone e when near(e, 5, 3) => 'eyeStone',
        Mirror m when near(m, 5, 4) => 'mirror',
        LiftPan l when near(l, 4, 3) => 'lift',
        RottenPlank k when near(k, 4, 3) => 'rotten',
        CrumbleRock k when near(k, 3, 3) => 'crumble',
        FireflySwarm f when near(f, 4, 3) => 'fireflyPickup',
        WingsPickup w when near(w, 5, 4) => 'wings',
        SwingRope s
            when (s.anchor.x - p.center.x).abs() < 6 * kTile &&
                p.center.y > s.anchor.y - kTile &&
                p.center.y < s.anchor.y + s.length + 3 * kTile =>
          'rope',
        BatRoost b when near(b, 6, 5) => 'bats',
        Crow k when near(k, 6, 4) => 'crow',
        Watcher w when near(w, 9, 8) => 'watcher',
        MedusaHead m when near(m, 11, 3) => 'medusa',
        Raft k when near(k, 4, 3) => 'raft',
        FireVent v when near(v, 6, 4) => 'vent',
        LanternBalloon b when near(b, 8, 8) => 'balloon',
        SimurgFeather f when near(f, 6, 5) => 'feather',
        FairyRing k when near(k, 4, 3) => 'ring',
        WindBell b when near(b, 6, 4) => 'bell',
        StarStone s when near(s, 5, 3) => 'star',
        StoneGiant g when near(g, 11, 6) => 'giant',
        Wolf w when near(w, 9, 4) => 'wolf',
        ThinIce i when near(i, 3, 2) => 'ice',
        FallingIcicle i when near(i, 5, 6) => 'icicle',
        Semazen s when near(s, 6, 3) => 'semazen',
        Chandelier c when near(c, 9, 7) => 'chandelier',
        GreatLamp l when near(l, 16, 22) => 'lamp',
        LightFlood f when f.awake => 'flood',
        _ => null,
      };
      if (key != null) show(key);
    }
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
        once('blizzard', S.of('blizzard'));
      }
    }
    blizzard = target;
  }

  /// Karanlık bölge: ışığı yer. Ateşböcekleri birer birer söner; hiç
  /// kalmayınca karanlık Sâye'yi yutar.
  void _updateDarkZone(Player p, double dt) {
    final dark = level.inDarkZone(p.center);
    final target =
        (dark ? 0.3 + 0.7 * (fireflies / maxFireflies) : 1.0) *
        (1 - 0.6 * jarSteal);
    jarStrength += (target - jarStrength) * (1 - math.exp(-dt * 2));
    if (!dark) {
      _darkT = 0;
      return;
    }
    if (!_darkWarned) {
      _darkWarned = true;
      once('darkZone$levelIndex', S.of('darkZone'));
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
    final want =
        view.y /
        (kTile * math.min(tilesTall, level.height.toDouble())) *
        _closeUp *
        (1 + 0.05 * threat);
    _zoomS = _snapCamera || _zoomS <= 0
        ? want
        : approach(_zoomS, want, dt, 0.3);
    final zoom = _zoomS;
    camera.viewfinder.zoom = zoom;

    // Gidilen yöne doğru ileriyi gösterir; hızlandıkça daha çok.
    _lookAhead +=
        ((p.facing * 60 + p.velocity.x * 0.35) - _lookAhead) *
        (1 - math.exp(-dt * 1.5));
    final halfW = view.x / zoom / 2;
    final halfH = view.y / zoom / 2;
    // Dikey: basılan zemine göre; zıplama, ip ve kenara tutunma kamerayı
    // oynatmaz. Bandın dışına çıkınca (ya da düşerken) izler.
    final y = p.center.y;
    if (_snapCamera || _camFloor.isNaN) _camFloor = y;
    final band = halfH * 0.32;
    if (p.onGround || p.isDead) {
      _camFloor = approach(_camFloor, y, dt, 0.18);
    } else if (y < _camFloor - band) {
      _camFloor = y + band;
    } else if (y > _camFloor + band * 0.5) {
      _camFloor = y - band * 0.5;
    }
    final target = Vector2(p.center.x + _lookAhead, _camFloor - 20);
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
    // Klavye ve oyun kumandası (Android'de kumanda tuşları buradan gelir:
    // yön tuşları ok, A zıpla, Y tırman, X ateşböceği, B ya da omuz tuşları
    // parmak ucu, Start ayarlar).
    controls.keyboard
      ..left = any([LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA])
      ..right = any([LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD])
      ..up = any([
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.gameButtonY,
      ])
      ..down = any([LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS])
      ..jump = any([
        LogicalKeyboardKey.space,
        LogicalKeyboardKey.keyZ,
        LogicalKeyboardKey.gameButtonA,
      ])
      ..sneak = any([
        LogicalKeyboardKey.shiftLeft,
        LogicalKeyboardKey.shiftRight,
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.gameButtonB,
        LogicalKeyboardKey.gameButtonLeft1,
        LogicalKeyboardKey.gameButtonRight1,
      ]);
    // Kumandanın Start/Select tuşu Esc gibidir.
    final esc =
        event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.gameButtonStart ||
        event.logicalKey == LogicalKeyboardKey.gameButtonSelect;
    if (menuMode.value) {
      if (event is KeyDownEvent && esc) {
        if (overlays.isActive(settingsOverlay)) {
          toggleSettings();
        } else if (SaveGame.current != null) {
          // Ana menüde Esc: kaldığın yerden devam.
          continueGame();
        }
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) {
      // Sahne sürerken Esc perdeyi atlar (ayarlar dişli simgesinden açılır).
      if (esc && narration.inCinematic && !overlays.isActive(settingsOverlay)) {
        narration.skipAll();
        return KeyEventResult.handled;
      }
      if (esc) {
        toggleSettings();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.f11) {
        onToggleFullscreen?.call();
        return KeyEventResult.handled;
      }
      if (paused) return KeyEventResult.handled;
      if (event.logicalKey == LogicalKeyboardKey.keyF ||
          event.logicalKey == LogicalKeyboardKey.keyX ||
          event.logicalKey == LogicalKeyboardKey.gameButtonX) {
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
