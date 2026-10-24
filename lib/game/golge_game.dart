import 'dart:io' show ProcessInfo;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import 'atmosphere.dart';
import 'audio.dart';
import 'auto_quality.dart';
import 'anlatim_plani.dart';
import 'entrance.dart';
import 'feedback.dart';
import 'shadow_decoy.dart';
import 'vistas.dart';
import 'creatures.dart';
import 'frame_pacer.dart';
import 'mechanics.dart';
import 'entities.dart';
import 'level.dart';
import 'lighting.dart';
import 'shadow_art.dart';
import 'shafts.dart';
import 'ski_decor.dart';
import 'ski_fx.dart';
import 'ski_light.dart';
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
import 'giant_puppet.dart';
import 'gok_katlari.dart';
import 'gokboru.dart';
import 'cameos.dart';
import 'erlik.dart';
import 'ergenekon.dart';
import 'heavens.dart';
import 'myth_cards.dart';
import 'nemrut.dart';
import 'otuken.dart';
import 'ski.dart';
import 'wind.dart';
import 'winter.dart';
import 'puzzles.dart';
import 'realism.dart';
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

  /// Cihaz zorlanırsa ağır görselleri kendiliğinden kapatır.
  late final AutoQuality autoQuality = AutoQuality(this);

  /// Masaüstünde kare sınırı (bkz. [FramePacer]).
  late final FramePacer pacer = FramePacer(this);

  /// Oyun bekliyor mu (panel açık). Motorun döngüsü kare sınırı için ayrıca
  /// durdurulabildiğinden motorun "paused" bayrağından ayrı tutulur.
  bool get held => _held;
  bool _held = false;

  void _setHeld(bool v) {
    if (v == _held) return;
    _held = v;
    if (pacer.active) return;
    if (v) {
      pauseEngine();
    } else {
      resumeEngine();
    }
  }

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

  /// Kayakta havada geçen yükseliş (takla ipucu için).
  double _skiAirHint = 0;

  /// Kayak kamerasının açılması (0 yakın) ve dikey izleyişi.
  double _skiOpen = 0;
  double _skiCamY = double.nan;
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

  /// Erlik'in katı: Sâye Çalkuyruk'un sırtında.
  bool onHorse = false;

  /// Kavanoza giren kutlar kavanozu parlatır (ışık yarıçapı çarpanı):
  /// Körmösler daha uzaktan görür, ışık tahtaları daha uzaktan yanar.
  double get jarBoost =>
      1 +
      0.3 * world.children.whereType<KutCage>().where((k) => k.freed).length;

  /// Tulpar'ın sırtında: havada zıplayınca kanat çırpılır.
  bool flying = false;

  /// Çalkuyruk (ya da kanatlı Tulpar) Sâye'yi sırtına alır.
  void mountHorse({bool winged = false}) {
    if (onHorse) return;
    onHorse = true;
    flying = winged;
    GameAudio.instance.play('land', volume: 0.7);
    GameAudio.instance.play('gust', volume: 0.6);
    if (winged) {
      once('tulparMount', S.of('tulparMount'), story: false);
      meetMyth('tulpar');
    } else {
      once('calkuyruk', S.of('calkuyrukMount'), story: false);
      meetMyth('erTostuk');
    }
  }

  /// Karanlık bölgede bir ateşböceğinin sönme süresi.
  static const darkDrain = 6.5;

  /// Ateşböceği kalmayınca karanlığın yutma süresi.
  static const darkSwallow = 4.5;

  double _darkT = 0;
  bool _darkWarned = false;

  /// Kayak bölümünün yamacı (kayak bölümü değilse yok).
  SkiSurface? skiSurface;

  /// Kayak efektleri (kar tozu, takla yazıları, kut hızı).
  SkiFx? skiFx;

  /// Kayak pistinde ilerleyiş (0 baş, 1 son): göğün ve karın ışığı buna
  /// göre döner.
  double get skiProgress {
    final w = level.pixelWidth;
    if (w <= 0) return 0;
    return (camera.viewfinder.position.x / w).clamp(0.0, 1.0);
  }

  /// Kayak pistinin o anki ışığı.
  SkiLight get skiLight =>
      SkiLight.at(skiProgress, avalanche: level.def.variant == 2);

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
    // Nemrut görselleri arka planda yüklenir; gelene dek kod çizimi kullanılır.
    NemrutImages.load();
    GiantPuppet.load();
    ShadowArt.load();
    camera.viewfinder.anchor = Anchor.center;
    camera.backdrop = Backdrop();
    effects = ScreenEffects();
    narration = Narration();
    camera.viewport.addAll([effects, narration]);
    autoQuality.attach();
    pacer.apply();
    _enterMenu();
    // Geliştirici ölçümü: doğrudan bir bölümle açılır (DEV ve START_LEVEL).
    if (const bool.fromEnvironment('DEV') && _startLevel >= 0) {
      debugLoadLevel(_startLevel);
    }
  }

  /// Deneme yapısında F3: ölçüm göstergesi (kare sayısı, kare süresi,
  /// bellek, grafik modu). Yarım saniyede bir yenilenir.
  /// Ölçüm göstergesi (ayarda kaydedilir).
  bool get perfShown => Settings.perf;
  set perfShown(bool v) => Settings.perf = v;
  String perfText = '';
  double _perfT = 0;
  int _perfFrames = 0;

  void _updatePerf(double dt) {
    _perfT += dt;
    _perfFrames++;
    if (_perfT < 0.5) return;
    final fps = (_perfFrames / _perfT).round();
    _perfT = 0;
    _perfFrames = 0;
    final mb = (ProcessInfo.currentRss / 1048576).round();
    final gfx = Settings.lowGraphics ? 'düşük' : 'yüksek';
    final light = realismHere(this) ? 'ışık açık' : 'ışık kapalı';
    // Çalışan çizici: shader filtresi yalnız Impeller'da desteklenir.
    final renderer = ui.ImageFilter.isShaderFilterSupported
        ? 'Impeller'
        : 'Skia';
    perfText =
        '$fps kare/sn · çizim ${autoQuality.workMs.toStringAsFixed(1)} ms · '
        'bellek $mb MB · çizici $renderer · grafik $gfx · $light\n'
        'anlatım ${GameAudio.instance.voiceStatus}';
  }

  static const _startLevel = int.fromEnvironment(
    'START_LEVEL',
    defaultValue: -1,
  );

  /// Geliştirici ölçümü: Sâye kendi kendine sağa yürür, ara ara zıplar.
  static const _autoWalk =
      bool.fromEnvironment('DEV') && bool.fromEnvironment('AUTOWALK');
  double _autoT = 0;

  @override
  void onRemove() {
    autoQuality.detach();
    pacer.dispose();
    super.onRemove();
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
    overlays.remove(recentOverlay);
    _settingsShown = false;
    recentOpen = false;
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
    if (index < 0 ||
        index >= levels.length ||
        orderOf(index) > Settings.unlocked) {
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
              !w.startsWith('hint:$index:') &&
              !(w.startsWith('event:') && _eventLevel(w) == '$index'),
        ),
      );
    fireflies = startFireflies;
    // Kanatlar Kule'de (2. bölüm) bulunur: ondan önceki bölümler kanatsız,
    // sonrakiler kanatla oynanır (öğretim dengesi bozulmasın).
    wingsCollected = orderOf(index) >= 2;
    _respawn = null;
    _puzzle = null;
    _leaveMenu();
    _buildLevel(index);
    _saveProgress();
    cinematic = false;
    effects.setFade(1, kInk);
    effects.fadeTo(0, 1.4);
    _showLevelTitle();
    _startEntrance();
  }

  /// Olay anahtarındaki bölüm ("event:ad:bölüm:…"); biçime uymayan eski
  /// anahtarlarda null (bölüm başlatmayı düşürmesin).
  static String? _eventLevel(String key) {
    final parts = key.split(':');
    return parts.length > 2 ? parts[2] : null;
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
    _setHeld(false);
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

  /// Ağaç yerine oba konan kontrol noktaları: ilerleyiş sırasıyla, daha önce
  /// dikilmiş bir ağaçla aynı ekrana düşenler (ağaçlar yan yana dizilmesin).
  Set<Vector2> get _cairns {
    final ks = [...level.checkpointCells]
      ..sort((a, b) => level.progressOf(a).compareTo(level.progressOf(b)));
    final trees = <Vector2>[];
    final out = <Vector2>{};
    for (final k in ks) {
      final near = trees.any(
        (t) => (t.x - k.x).abs() < 28 * kTile && (t.y - k.y).abs() < 16 * kTile,
      );
      if (near) {
        out.add(k);
      } else {
        trees.add(k);
      }
    }
    return out;
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
    // Ötüken'in ışık alanlarının başında en az üç: ışık köprüsü kurulabilsin.
    final glade = level.def.glades.any(
      (z) => Rect.fromLTRB(
        (z.$1 - 8) * kTile.toDouble(),
        (z.$2 - 8) * kTile.toDouble(),
        (z.$3 + 9) * kTile.toDouble(),
        (z.$4 + 9) * kTile.toDouble(),
      ).contains(Offset(r.x, r.y)),
    );
    if (glade) fireflies = math.max(fireflies, 3);
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
    _playPerde('prologue', prologueText, PerdeScene.prologue, () {
      cinematic = false;
      effects.fadeTo(0, 1.8);
      _showLevelTitle();
      _startEntrance();
    });
  }

  /// Bölüme ilk girişte giriş anı (düşüş, süzülüş, iniş, beliriş; yoksa
  /// düz başlangıç). Yeniden doğarken ve "Devam" ile oynamaz.
  void _startEntrance() {
    final kind = entranceFor(levelIndex);
    final start = _respawn;
    if (kind == null || start == null || player == null) return;
    world.add(Entrance(kind, start.clone()));
  }

  /// Testler için: bölümün giriş anını oynatır.
  void debugEntrance() => _startEntrance();

  /// Bölümün pahalı önbellekleri (arazi dilimleri, yakın katman şekilleri)
  /// ekran kapalıyken hazırlanır.
  void _prewarm(int index) {
    final lv = Level(levels[index]);
    warmTerrain(lv);
    final kind = depthKind(lv);
    if (kind != null && Realism.on && !Settings.lowGraphics) {
      NearLayer.warm(kind);
    }
  }

  /// Testler için: önceden hazırlama.
  void debugPrewarm(int index) => _prewarm(index);

  /// Perde oynatılır ve izlenmiş sayılır; ayarlarda "gördüğüm perdeleri
  /// atla" açıksa daha önce izlenmiş perde atlanır (Hikâye'de izlenebilir).
  void _playPerde(
    String key,
    List<String> lines,
    PerdeScene? scene,
    VoidCallback done,
  ) {
    if (Settings.skipSeenPerde && Settings.seenPerde.contains(key)) {
      done();
      return;
    }
    if (Settings.seenPerde.add(key)) Settings.save();
    narration.playCinematic(lines, done, instantBlack: true, scene: scene);
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
  static const recentOverlay = 'recent';

  /// "Az önce" paneli: kaçırılan hikâye ve ipucu yeniden okunur; açıkken
  /// oyun bekler.
  bool recentOpen = false;

  void toggleRecent() {
    if (menuMode.value) return;
    if (!recentOpen && _settingsShown) return;
    recentOpen = !recentOpen;
    if (recentOpen) {
      controls.resetAll();
      _showOverlay(recentOverlay);
    } else {
      overlays.remove(recentOverlay);
    }
    _syncPanels();
  }

  /// Ayarlar paneli açık mı (bindirme kayıtlı olmasa da: testlerde).
  bool _settingsShown = false;

  /// Açık panel var mı: oyun ancak hiçbiri açık değilken yürür. Duraklama
  /// tek tek açma/kapama çağrılarından değil, bu durumdan türer (iki panel
  /// üst üste açılıp biri kapanınca oyun arkada yürümesin).
  bool get panelOpen => recentOpen || _settingsShown;

  void _syncPanels() {
    settingsOpen.value = panelOpen;
    if (menuMode.value) return;
    if (panelOpen) {
      if (!held) {
        _setHeld(true);
        GameAudio.instance.pauseAll();
      }
    } else {
      onFocusGame?.call();
      if (held) {
        _setHeld(false);
        GameAudio.instance.resumeAll();
      }
    }
  }

  /// Ayarlar açık mı (dokunmatik düğmeler bu sırada gizlenir).
  final settingsOpen = ValueNotifier<bool>(false);

  /// Masaüstünde tam ekranı açıp kapatır (main.dart bağlar).
  void Function()? onToggleFullscreen;

  /// Klavye odağını oyuna geri verir (main.dart bağlar). Menüde bir düğmeye
  /// tıklanınca odak o düğmede kalır; menü kapanınca oyun tuşları duymaz.
  void Function()? onFocusGame;

  void toggleSettings() {
    _settingsShown = !_settingsShown;
    if (_settingsShown) {
      // Basılı kalan tuş ya da parmak menü kapanınca oyuncuyu yürütmesin.
      controls.resetAll();
      _showOverlay(settingsOverlay);
    } else {
      overlays.remove(settingsOverlay);
      // Menüde ayarlar kapanınca odak yine oyuna (menü tuşlarına) döner.
      if (menuMode.value) onFocusGame?.call();
    }
    _syncPanels();
  }

  /// Bölüm verisindeki Gözcü ayarı (haritadaki `g`nin sütun ve satırıyla).
  WatcherProfile? _watcherProfile(Vector2 cell) {
    final c = (cell.x / kTile).round();
    final r = (cell.y / kTile).round();
    for (final (wc, wr, p) in level.def.watchers) {
      if (wc == c && wr == r) return p;
    }
    return null;
  }

  /// Bölüm verisindeki kaya ayarı (haritadaki kayanın sütun ve satırıyla).
  RockProfile? _rockProfile(Vector2 cell) {
    final c = (cell.x / kTile).round();
    final r = (cell.y / kTile).round();
    for (final (rc, rr, p) in level.def.rocks) {
      if (rc == c && rr == r) return p;
    }
    return null;
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

  /// İpucu gösterilince Defter'e yazılan efsaneler.
  static const _hintLegends = {
    'medusa': 'medusa',
    'shield': 'medusa',
    'wings': 'hezarfen',
    'feather': 'simurg',
    'ring': 'peri',
    'semazen': 'sebiArus',
    'glade': 'karabasan',
    'karabasan': 'karabasan',
    'deer': 'akGeyik',
    'rootDrum': 'kam',
    'starWheel': 'demirKazik',
    'karakci': 'demirKazik',
    'yel': 'yelAna',
    'yada': 'yelAna',
    'lightning': 'sugeToyon',
  };

  void _updateBard(double dt) {
    if (_bardIn < 0) return;
    _bardIn -= dt;
    if (_bardIn >= 0) return;
    if (_bardLevel == levelIndex && !menuMode.value) {
      once('bard:$levelIndex', level.def.bardText);
      // Bölümün kendi efsaneleri (yerin ve hikâyenin) Defter'e yazılır.
      for (final id in level.def.legends) {
        meetMyth(id);
      }
    }
  }

  /// Testler için: gerçek bölümlerin yerine küçük deneme haritaları.
  static List<LevelDef>? debugLevels;

  void _buildLevel(int index, {bool respawn = false, bool withPlayer = true}) {
    world.removeAll(world.children.toList());
    autoQuality.restart();
    // Yeni bir bölüme geçerken (ölüp yeniden doğmada değil) eski bölümün
    // bekleyen metinleri atılır.
    if (!respawn || index != levelIndex) {
      narration.resetScene();
      // Başka bölüme geçerken önceki bölümün bulmaca durumu atılır.
      _puzzle = null;
      _fails.clear();
      _nearKey = null;
    }
    _atCheckpoint = null;
    levelIndex = index;
    // Oynanan en ileri bölüm açılır (bölüm listesi için).
    if (withPlayer && orderOf(index) > Settings.unlocked) {
      Settings.unlocked = orderOf(index);
      Settings.save();
    }
    level = Level((debugLevels ?? levels)[index]);
    final ski = level.def.skiSurface;
    skiSurface = ski == null ? null : SkiSurface(ski);
    skiFx = null;
    if (!respawn || _respawn == null) {
      _respawn = Level.standOn(level.playerStart, Player.w, Player.h);
      _darkWarned = false;
      _checkpointFireflies = fireflies;
    }
    if (respawn) _ensureFireflies();

    world.addAll(
      restorePuzzle([
        TerrainComponent(level),
        if (SurfaceEdge.wants(level.def.theme)) SurfaceEdge(level),
        UsePrompt(),
        LightingLayer(),
        LightShafts(),
        RealismLayer(),
        NearLayer(),
        ForegroundComponent(level),
        WindCurrents(),
        WaterComponent(level),
        ExitPortal(level.exitCell),
        for (final k in level.checkpointCells)
          UmayTree(
            k,
            headroom: _headroom(k),
            small: _cairns.contains(k),
            // Kayakta ağaç yerine oba (taş yığını, çaputlu direk): karın
            // üstüne oturur.
            cairn: skiSurface != null,
            groundY: switch (skiSurface?.at(k.x + kTile / 2)) {
              final double y => y + 3,
              _ => null,
            },
            // Yolun son ağacı (Konya'da) çiçek açar.
            bloom:
                level.def.theme == LevelTheme.konya &&
                level.progressOf(k) ==
                    level.checkpointCells
                        .map(level.progressOf)
                        .reduce(math.max),
          ),
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
        if (level.def.gokboruRun) SkiGuide(),
        for (final g in level.guardCells) Guard(g),
        for (final c in level.crateCells) Crate(c),
        for (final l in level.leverCells) Lever(l),
        for (final (col, top, bottom) in level.gates) Gate(col, top, bottom),
        ?_guideBird(),
        for (final f in level.fireflyCells)
          FireflySwarm(
            f,
            regrow: level.def.theme == LevelTheme.forest ? 9 : null,
          ),
        for (final (c, vertical) in level.movingCells)
          MovingRock(
            c,
            vertical: vertical,
            profile: _rockProfile(c) ?? const RockProfile(),
          ),
        for (final c in level.crumbleCells) CrumbleRock(c),
        ..._lifts(),
        for (final c in level.batCells)
          if (level.def.theme.snowy)
            Wolf(c)
          else if (level.def.theme == LevelTheme.underworld)
            Kormos(c)
          else
            BatRoost(c),
        for (final c in level.kutCells) KutCage(c),
        for (final c in level.thinIceCells) ThinIce(c),
        for (final c in level.crowCells) Crow(c),
        for (final c in level.watcherCells)
          Watcher(c, profile: _watcherProfile(c)),
        if (level.def.theme == LevelTheme.heavens)
          for (final c in level.wingsCells) TulparMount(c)
        else if (level.def.theme == LevelTheme.underworld)
          for (final c in level.wingsCells) Calkuyruk(c)
        else if (!wingsCollected)
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
          FireVent(
            level.ventCells[i],
            phase: i * 1.1,
            ignites: level.def.theme == LevelTheme.ergenekon,
          ),
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
        for (final (c, r, kind) in level.def.vistas)
          VistaPoint(
            Vector2((c + 0.5) * kTile, (r + 0.5) * kTile.toDouble()),
            kind,
          ),
        for (final (c, r) in level.def.shadowStones)
          ShadowStone(Vector2(c * kTile.toDouble(), r * kTile.toDouble())),
        for (final (c, r, n) in level.glowRuns)
          PhasePlank(Vector2(c * kTile, r * kTile.toDouble()), n, shade: false),
        // Kandilci yolu: yalnız Kandilcinin feneriyle belirir.
        for (final (c, r, n) in level.def.coldRuns)
          PhasePlank(
            Vector2(c * kTile.toDouble(), r * kTile.toDouble()),
            n,
            shade: false,
            cold: true,
          ),
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
        if (level.def.theme == LevelTheme.heavens ||
            (level.def.theme == LevelTheme.forest &&
                level.rottenRuns.isNotEmpty))
          KamDrum(),
        for (final (c, r, n) in level.rottenRuns)
          if (level.def.theme == LevelTheme.heavens ||
              level.def.theme == LevelTheme.forest)
            DrumCloud(
              Vector2(c * kTile.toDouble(), r * kTile.toDouble()),
              n,
              // Dört sütun arayla dizilen bulutlar sırayla belirir.
              group: (c ~/ 4) % 2,
            )
          else if (level.def.theme == LevelTheme.ergenekon)
            MoltenChannel(
              Vector2(c * kTile.toDouble(), r * kTile.toDouble()),
              n,
              phase: _moltenPhase(c),
            )
          else
            RottenPlank(c, r, n),
        ..._forges(),
        for (final (c0, r0, c1, r1) in level.def.scorch)
          ScorchZone(
            Rect.fromLTRB(
              c0 * kTile.toDouble(),
              r0 * kTile.toDouble(),
              (c1 + 1) * kTile.toDouble(),
              (r1 + 1) * kTile.toDouble(),
            ),
          ),
        ..._otuken(),
        ..._gokKatlari(),
        for (final (c0, r0, c1, r1) in level.def.mists)
          MistZone(
            Rect.fromLTRB(
              c0 * kTile.toDouble(),
              r0 * kTile.toDouble(),
              (c1 + 1) * kTile.toDouble(),
              (r1 + 1) * kTile.toDouble(),
            ),
          ),
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
          else if (level.def.theme == LevelTheme.heavens)
            // Erlik'in fırtınası: Sâye Tulpar'a binince soldan gelir.
            StormWall(level.chaseStart!, level.chaseEnd!)
          else if (level.def.theme == LevelTheme.ergenekon)
            // Dağ erir: akkor demir aşağıdan yükselir.
            // Kat kat tırmanışa göre ağır yükselir (bacalarda beklenir).
            LightFlood(
              level.chaseStart!,
              level.chaseTop!,
              molten: true,
              maxSpeed: 20,
            )
          else if (level.def.theme == LevelTheme.underworld)
            // Erlik'in karanlığı: Sâye Çalkuyruk'a binince yükselir.
            LightFlood(
              level.chaseStart!,
              level.chaseTop!,
              dark: true,
              wake: () => onHorse,
            )
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
        if (skiSurface != null) SkiDecor(skiSurface!, level.def.skiDecor),
        if (skiSurface != null)
          SkiDecor(skiSurface!, level.def.skiDecor, front: true),
        if (skiSurface != null) skiFx = SkiFx(),
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
    onHorse = false;
    flying = false;
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

  /// Kandilci yolu yalnız Kandilcinin feneriyle (halesi ve konisi) yanar.
  bool coldLitAt(Vector2 at) {
    for (final g in world.children.whereType<Guard>()) {
      if (g.falling) continue;
      final lantern = g.lanternWorld;
      final d = at - lantern;
      if (d.length2 < 70 * 70 && level.lineOfSight(lantern, at)) return true;
      final ahead = d.x * g.facing;
      if (ahead > 0 &&
          ahead < g.coneRange &&
          d.y.abs() < ahead * 0.5 + 34 &&
          level.lineOfSight(lantern, at)) {
        return true;
      }
    }
    return false;
  }

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

  /// Akan demir kanallarının döngü kayması: yan yana kanallar sırayla
  /// (soldan sağa 1,1 sn arayla) katılaşır; adadan adaya dalgayla geçilir.
  double _moltenPhase(int col) {
    final cols = [for (final (c, _, _) in level.rottenRuns) c]..sort();
    final i = cols.indexOf(col);
    return ((-(i < 0 ? 0 : i) * 1.1) % MoltenChannel.period +
            MoltenChannel.period) %
        MoltenChannel.period;
  }

  /// Ergenekon: demir damarları ve onlara bağlı körükler (her körük en
  /// yakın damara).
  /// Göğün Katları: Yıldız Katı'nın çarkları ve Yedi Karakçı.
  Iterable<Component> _gokKatlari() sync* {
    Vector2 at(int c, int r) =>
        Vector2((c + 0.5) * kTile, (r + 0.5) * kTile.toDouble());
    for (final (c, r, radius, count, period, kind) in level.def.wheels) {
      final pivot = at(c, r);
      final n = kind == 1 ? 2 : count;
      yield StarPivot(pivot, great: kind == 1);
      for (var i = 0; i < n; i++) {
        yield StarPlatform(
          pivot: pivot,
          radius: radius * kTile,
          period: period,
          phase: i * 2 * math.pi / n,
          horse: kind == 1 ? i : null,
        );
      }
    }
    for (final (c0, r0, c1, r1, dir) in level.def.yel) {
      yield YelZone(
        Rect.fromLTRB(
          c0 * kTile.toDouble(),
          r0 * kTile.toDouble(),
          (c1 + 1) * kTile.toDouble(),
          (r1 + 1) * kTile.toDouble(),
        ),
        dir: dir,
      );
    }
    for (final c in level.yadaCells) {
      yield YadaStone(c);
    }
    if (level.def.stormSteps.isNotEmpty || level.def.strikes.isNotEmpty) {
      yield StormSky();
    }
    for (final (c, r, n) in level.def.stormSteps) {
      yield StormStep(at(c, r) - Vector2.all(kTile / 2), n);
    }
    for (final (c, r, phase) in level.def.strikes) {
      yield LightningStrike(at(c, r) - Vector2.all(kTile / 2), phase: phase);
    }
    for (final (c, r, radius, period) in level.def.karakci) {
      yield YediKarakci(
        pivot: at(c, r),
        radius: radius * kTile,
        period: period,
      );
    }
  }

  /// Ötüken: yaprak arasından ışık düşen alanlar, Ak Geyik ve kökleri,
  /// Hayat Ağacı'nın sonunda dağılan Karabasan.
  Iterable<Component> _otuken() sync* {
    if (level.def.theme != LevelTheme.forest) return;
    for (final (c0, r0, c1, r1, wind) in level.def.glades) {
      final area = Rect.fromLTRB(
        c0 * kTile.toDouble(),
        r0 * kTile.toDouble(),
        (c1 + 1) * kTile.toDouble(),
        (r1 + 1) * kTile.toDouble(),
      );
      yield GladeZone(area, [
        for (final b in level.gladeBeamCells)
          if (area.contains(Offset(b.x + kTile / 2, b.y + kTile / 2)))
            b.x + kTile / 2,
      ], wind: wind);
    }
    for (final c in level.deerCells) {
      yield AkGeyik(c);
    }
    final plates = [...level.deerPlateCells]
      ..sort((a, b) => a.x.compareTo(b.x));
    for (var i = 0; i < plates.length; i++) {
      yield DeerPlate(plates[i], last: i == plates.length - 1);
    }
    final tree = level.def.lifeTree;
    if (tree != null) {
      final (c0, r0, c1, r1) = tree;
      final rect = Rect.fromLTRB(
        c0 * kTile.toDouble(),
        r0 * kTile.toDouble(),
        (c1 + 1) * kTile.toDouble(),
        (r1 + 1) * kTile.toDouble(),
      );
      yield TreeOfLife(rect);
      yield TreeCrown(
        Offset(rect.center.dx + 2 * kTile, rect.top - 9 * kTile),
        11 * kTile,
      );
    }
    if (level.lockCells.isNotEmpty && level.def.glades.isNotEmpty) {
      final (c0, _, c1, r1, _) = level.def.glades.last;
      yield KarabasanEnd(
        // Ağacın dibi: alanın son satırı zemindir.
        Vector2((c0 + c1 + 1) / 2 * kTile, r1 * kTile.toDouble()),
      );
    }
  }

  Iterable<Component> _forges() sync* {
    final veins = [for (final (c, t, b) in level.ironVeins) IronVein(c, t, b)];
    if (veins.isEmpty) return;
    final counts = <IronVein, int>{};
    final pumps = <IronVein, List<Bellows>>{};
    for (final (c, r, order) in level.def.bellows) {
      final b = Bellows(
        Vector2(c * kTile.toDouble(), r * kTile.toDouble()),
        order,
      );
      IronVein? best;
      var bestD = double.infinity;
      for (final v in veins) {
        final d = (v.forge - b.position.toOffset()).distance;
        if (d < bestD) {
          bestD = d;
          best = v;
        }
      }
      b.vein = best;
      if (order > 0) {
        counts[best!] = (counts[best] ?? 0) + 1;
        (pumps[best] ??= []).add(b);
      }
      yield b;
    }
    for (final (c0, r0, c1, r1) in level.def.interiors) {
      yield IronInterior(
        Rect.fromLTRB(
          c0 * kTile.toDouble(),
          r0 * kTile.toDouble(),
          (c1 + 1) * kTile.toDouble(),
          (r1 + 1) * kTile.toDouble(),
        ),
      );
    }
    final nv = level.def.nevruz;
    if (nv != null) {
      yield NevruzAnvil(
        Vector2(nv.$1 * kTile.toDouble(), nv.$2 * kTile.toDouble()),
      );
    }
    // Soldan sağa damar biçimleri (ritim, kömür sandığı) ve ritimli
    // damarın başında Demirci'nin örsü.
    final sorted = [...veins]..sort((a, b) => a.forge.dx.compareTo(b.forge.dx));
    for (var i = 0; i < sorted.length && i < level.def.forges.length; i++) {
      final (rhythm, fuel) = level.def.forges[i];
      final v = sorted[i];
      v.rhythm = rhythm;
      v.fuelNeeded = fuel;
      if (rhythm) {
        // Örs körüklerin yanında: çekiç ekranda görünsün, vuruşu duyulsun
        // (ocağın dibindeyken körüklerden yirmi kare uzakta kalıyordu).
        final near = pumps[v];
        final a = Anvil(
          _anvilSpot(near) ?? Vector2(v.forge.dx - 6.5 * kTile, v.forge.dy),
        );
        v.anvil = a;
        yield a;
      }
    }
    for (final v in veins) {
      v.bellowsCount = counts[v] ?? 1;
      yield v;
    }
  }

  /// Görev satırı: oyuncu çok adımlı bir düzeneğin alanındaysa o anki adım.
  String? _objective(Player p) {
    for (final v in world.children.whereType<IronVein>()) {
      if (v.opening) continue;
      final pumps = world.children.whereType<Bellows>().where(
        (b) => b.vein == v && b.order > 0,
      );
      if (pumps.isEmpty) continue;
      final left = pumps.map((b) => b.position.x).reduce(math.min);
      final x = p.center.x;
      if (x < left - 10 * kTile || x > v.forge.dx + 4 * kTile) continue;
      if ((p.center.y - v.forge.dy).abs() > 14 * kTile) continue;
      final steps = <String>[
        if (v.fuelNeeded > 0)
          Hints.fill(
            Hints.text('goalFuel')
                .replaceAll('{n}', '${math.min(v.fuel, v.fuelNeeded)}')
                .replaceAll('{need}', '${v.fuelNeeded}'),
          ),
        Hints.text('goalLight'),
        if (v.rhythm)
          Hints.text('goalBeat')
              .replaceAll('{heat}', '${(v.heat * 100).round()}')
        else
          Hints.text('goalOrder').replaceAll('{next}', '${v.next}'),
      ];
      final at = v.fuelNeeded > 0 && !v.fueled
          ? 0
          : !v.lit
          ? steps.length - 2
          : steps.length - 1;
      return '${Hints.text('goalForge')} · ${at + 1}/${steps.length} · '
          '${steps[at]}';
    }
    return null;
  }

  /// Ritimli ocağın örsü için yer: körüklerin sağında, zemine oturan ilk
  /// boş sütun.
  Vector2? _anvilSpot(List<Bellows>? pumps) {
    if (pumps == null || pumps.isEmpty) return null;
    final low = pumps.reduce((a, b) => a.position.y >= b.position.y ? a : b);
    final right = pumps.map((b) => b.position.x).reduce(math.max);
    final row = (low.position.y / kTile).round();
    for (var c = (right / kTile).floor() + 3; c < level.width - 1; c++) {
      if (level.solid(c, row) && !level.solid(c, row - 1)) {
        return Vector2((c + 0.5) * kTile, row * kTile.toDouble());
      }
    }
    return null;
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
    _hintStep();
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
        final next = nextLevel(levelIndex);
        if (next != null) {
          void enter() {
            _buildLevel(next);
            // Yeni bölüme girer girmez kaydedilir (ilk kontrol noktasına
            // varmadan uygulama kapansa da bölüm kaybolmasın).
            _saveProgress();
            cinematic = false;
            _transitioning = false;
            effects.fadeTo(0, 1.8);
            _showLevelTitle();
            _startEntrance();
          }

          // Bölüm arasında perdede bir gölge oyunu oynanır.
          final interlude = interludeText(next);
          if (interlude.isEmpty) {
            enter();
          } else {
            effects.setFade(1, kInk);
            // Ekran kapalıyken yeni bölümün araziyi ve yakın katmanı önceden
            // hazırlanır: perdeden oyuna geçiş takılmasın.
            _prewarm(next);
            _playPerde('$next', interlude, interludeScene(next), enter);
          }
          return;
        }
        final ending = epilogueText;
        // Oyun bitti: tiyatronun son perdesi bundan sonra açılır.
        Settings.finished = true;
        Settings.save();
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
    narration.whisper(S.of('wings'), story: false);
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
      // Yalnız oynanış sırasındaki sözler burada söylenir; rivayetler Umay
      // ağacında, fazlası Defter'de.
      final place = whisperPlace(levelIndex, i).$1;
      if (i < level.def.whisperTexts.length &&
          (place == WhisperPlace.yazi || place == WhisperPlace.tehlike)) {
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
    autoQuality.tick(dt);
    autoQuality.countStep();
    if (perfShown) _updatePerf(dt);
    if (_autoWalk && !menuMode.value) {
      _autoT += dt;
      controls.keyboard
        ..right = true
        ..jump = (_autoT % 1.2) < 0.4;
      cinematic = false;
    }
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
    narration.objective = cinematic ? null : _objective(p);
    if (!cinematic && !p.isDead) {
      _checkStoryPoints(p);
      _updateTension(p, dt);
      _updateHints(p, dt);
      _updateBard(dt);
      _updateTreeTales(p, dt);
      _updateSurprises(p);
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

  // ---------------------------------------------------- sırlar, sürprizler
  // Küçük sürprizler oyun başına bir kez olur (kayıtla); bulunan sırlar
  // oyundan oyuna kalır, Defter'de sayılır (bkz. docs/SIRLAR_PLANI.md).

  /// Bu oyunda bu sürpriz oldu mu.
  bool secretSeen(String name) => eventSeen('sir:$levelIndex:$name');

  /// Sürpriz oldu: bu oyunda bir daha olmaz, sır sayacına eklenir.
  void foundSecret(String name) {
    markEvent('sir:$levelIndex:$name');
    if (Settings.secrets.add('$levelIndex:$name')) Settings.save();
  }

  /// Şu an sürpriz için güvenli mi: tehlike yok, perde ya da giriş yok.
  bool get calmMoment =>
      !cinematic &&
      threat < 0.1 &&
      !world.children.whereType<Guard>().any(
        (g) => g.state == GuardState.alert || g.state == GuardState.chase,
      );

  /// [story] false: oynanışı da anlatan söz (düzeneğin şiiri, kovalamaca,
  /// binek); hikâye fısıltıları kapalıyken de söylenir.
  void once(String key, String text, {bool hint = false, bool story = true}) {
    final id = 'once:$key';
    if (_whispersShown.contains(id)) return;
    _whispersShown.add(id);
    if (hint) {
      narration.hint(text, queue: true);
    } else {
      narration.whisper(text, story: story);
    }
  }

  /// İpucunu (gösterilmediyse) sıraya koyar: tarama beklenmeden, başka bir
  /// söz araya girmeden önce söylenmesi gerekenler için.
  void _queueHint(String key) {
    final id = 'hint:$levelIndex:$key';
    if (_whispersShown.contains(id)) return;
    _whispersShown.add(id);
    narration.hint(Hints.text(key), queue: true);
  }

  // ------------------------------------------------- Umay ağacı rivayetleri

  /// Oyuncunun ağacın yanında kıpırdamadan durduğu süre.
  double _still = 0;

  /// Rivayet anlatan ağaç (uzaklaşınca anlatım kısılır).
  Vector2? _tellingTree;

  /// Bu bölümde ağaçlarda anlatılacak rivayetler: (fısıltı sırası, ağaç
  /// sütunu).
  Iterable<(int, int)> get _tales sync* {
    final plan = whisperPlan[levelIndex];
    if (plan == null) return;
    for (final MapEntry(key: i, value: (place, col)) in plan.entries) {
      if (place == WhisperPlace.agac && col != null) yield (i, col);
    }
  }

  /// Sâye bir Umay ağacının yanında bir süre durursa ağaç o yerin
  /// rivayetini anlatır (sırayla, her biri bir kez); uzaklaşınca susar.
  /// Küçük sürprizler (S1): sakin anlarda, bölüm başına bir kez.
  void _updateSurprises(Player p) {
    if (!calmMoment || p.isDead) return;
    // S1a · Utangaç gölge: Yerebatan'da, ilk kontrol noktasından sonra,
    // koşarken birden durunca.
    if (level.def.theme == LevelTheme.cistern &&
        p.justStoppedRunning &&
        !p.hidden &&
        !secretSeen('utangac') &&
        level.checkpointCells.isNotEmpty &&
        p.center.x > level.checkpointCells.first.x + 4 * kTile &&
        _clearAhead(p, 3 * kTile)) {
      if (p.shadowShy()) foundSecret('utangac');
    }
  }

  /// Sâye'nin önü (baktığı yönde) [reach] boyunca ön plan sütunu ya da duvar
  /// olmadan açık mı: önden geçen gölge sürprizi görünsün.
  bool _clearAhead(Player p, double reach) {
    final row = ((p.position.y + Player.h / 2) / kTile).floor();
    for (var d = 0.0; d <= reach; d += kTile / 2) {
      final c = ((p.center.x + p.facing * d) / kTile).floor();
      for (final r in [row - 1, row]) {
        final ch = level.cell(c, r);
        if (ch == 'I' || ch == '#') return false;
      }
    }
    return true;
  }

  void _updateTreeTales(Player p, double dt) {
    final told = _tellingTree;
    if (told != null && (told.x + kTile / 2 - p.center.x).abs() > 6 * kTile) {
      GameAudio.instance.stopVoice(clearQueue: true);
      _tellingTree = null;
    }
    Vector2? tree;
    for (final cell in level.checkpointCells) {
      if ((cell.x + kTile / 2 - p.center.x).abs() < 2.5 * kTile &&
          (cell.y - p.center.y).abs() < 3 * kTile) {
        tree = cell;
      }
    }
    final moving = p.velocity.x.abs() > 20 || !p.onGround;
    _still = tree == null || moving ? 0 : _still + dt;
    if (tree == null) return;
    final col = (tree.x / kTile).round();
    final waiting = [
      for (final (i, c) in _tales)
        if ((c - col).abs() <= 1 &&
            !_whispersShown.contains('$levelIndex:tale:$i'))
          i,
    ]..sort();
    if (waiting.isEmpty) return;
    // İlk kez: ağacın yanında durunca anlatacağı söylenir (ipucu simgesi).
    _queueHint('treeTale');
    if (_still < 1.2 || GameAudio.instance.voiceBusy) return;
    final i = waiting.first;
    if (i >= level.def.whisperTexts.length) return;
    _whispersShown.add('$levelIndex:tale:$i');
    narration.whisper(level.def.whisperTexts[i]);
    _tellingTree = tree;
    _still = 0.6;
  }

  /// Bu bir kezlik söz söylendi mi (testler için)?
  bool onceShown(String key) => _whispersShown.contains('once:$key');

  /// Bu ipucu gösterildi mi (testler için)?
  bool hintShown(String key) =>
      _whispersShown.contains('hint:$levelIndex:$key');

  /// İlk karşılaşmada düzeneğin nasıl kullanıldığını söyler (bir kez;
  /// kayıtla hatırlanır).
  void _updateHints(Player p, double dt) {
    _nearAge += dt;
    _hintScan += dt;
    if (_hintScan < 0.3) return;
    _hintScan = 0;
    // İpucu her bölümde, o bölümdeki ilk karşılaşmada bir kez söylenir
    // (önceden bütün oyunda bir kezdi: ileriki bölümlerde hiç çıkmıyordu).
    void show(String key) {
      final id = 'hint:$levelIndex:$key';
      if (_whispersShown.contains(id)) return;
      // Ekranda başka ipucu varsa bu sıraya girer; gösterildiği an
      // gösterilmiş sayılır (oyuncu o arada geçip gitse de çıkar).
      narration.hint(
        Hints.text(key),
        onShown: () {
          if (!_whispersShown.add(id)) return;
          // Düzeneğin ardındaki efsane Defter'e yazılır.
          final legend = _hintLegends[key];
          if (legend != null) meetMyth(legend);
        },
      );
    }

    bool near(PositionComponent c, double dx, [double? dy]) {
      final r = c.toRect();
      final d = r.center - Offset(p.center.x, p.center.y);
      return d.dx.abs() < dx * kTile + r.width / 2 &&
          d.dy.abs() < (dy ?? dx) * kTile + r.height / 2;
    }

    if (skiSurface != null) {
      show('ski');
      // Uzunca bir uçuşta takla öğütlenir.
      if (!p.onGround && p.velocity.y < -60) _skiAirHint += 0.3;
      if (_skiAirHint > 0.6) show('flip');
    }
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
        Kormos k when near(k, 7, 5) => 'kormos',
        KutCage k when near(k, 3, 3) && !k.freed => 'kut',
        Calkuyruk c when near(c, 5, 4) && !onHorse => 'horse',
        IronVein v when near(v, 6, 4) && !v.lit => 'forge',
        IronVein v when v.fuelNeeded > 0 && !v.fueled && near(v, 10, 4) =>
          'fuel',
        Bellows b when near(b, 4, 3) && (b.vein?.rhythm ?? false) =>
          'bellowsBeat',
        Bellows b when near(b, 4, 3) && b.order > 0 => 'bellows',
        NevruzAnvil n when near(n, 5, 3) => 'nevruz',
        MoltenChannel m when near(m, 4, 3) => 'molten',
        DrumCloud d
            when near(d, 4, 3) && level.def.theme == LevelTheme.forest =>
          'rootDrum',
        DrumCloud d when near(d, 4, 3) => 'drum',
        GladeZone z
            when z.area
                .inflate(kTile)
                .contains(Offset(p.center.x, p.center.y)) =>
          'glade',
        AkGeyik g when near(g, 8, 5) && !g.leaving => 'deer',
        StarPlatform k when near(k, 5, 5) => 'starWheel',
        YediKarakci k when (k.pivot - p.center).length < 10 * kTile =>
          'karakci',
        YelZone z
            when z.area
                .inflate(2 * kTile)
                .contains(Offset(p.center.x, p.center.y)) =>
          'yel',
        YadaStone y when near(y, 4, 3) => 'yada',
        LightningStrike l when near(l, 8, 6) => 'lightning',
        StormStep k when near(k, 6, 5) => 'lightning',
        DeerPlate d when near(d, 6, 5) && !d.woke => 'deerPlate',
        Karabasan k when k.awake => 'karabasan',
        ScorchZone z
            when z.area
                .inflate(2 * kTile)
                .contains(Offset(p.center.x, p.center.y)) =>
          'scorch',
        TulparMount t when near(t, 5, 4) && !onHorse => 'tulpar',
        Valve v when near(v, 4, 3) => 'valve',
        PerdeCord k when near(k, 4, 3) => 'cord',
        ShadowStone k when near(k, 4, 3) => 'shadowStone',
        PhasePlank k when k.cold && near(k, 5, 4) => 'coldBridge',
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
        StormWall w when w.awake => 'storm',
        Avalanche a when a.awake => 'avalanche',
        LooseBoulder b when near(b, 3, 6) => 'boulder',
        MistZone m
            when m.area
                .inflate(2 * kTile)
                .contains(Offset(p.center.x, p.center.y)) =>
          'mist',
        MagnetZone m when m.covers(p.center.x + 4 * kTile) => 'magnet',
        _ => null,
      };
      if (key != null) {
        _nearKey = key;
        _nearAge = 0;
        show(key);
      }
    }
  }

  /// Son yakınında olunan düzenek (ipucu anahtarı) ve ondan bu yana geçen
  /// süre: ölüm onun başında mı oldu?
  String? _nearKey;
  double _nearAge = 99;

  /// Bu bölümde düzenek başına ölüm sayısı (ipucunun basamakları için).
  final _fails = <String, int>{};

  /// İpucunun basamakları: ilk karşılaşmada davranış (ilk ipucu), aynı
  /// düzenekte ikinci ölümde ilişki, üçüncüde istenince açılan çözüm.
  void _hintStep() {
    final key = _nearKey;
    if (key == null || _nearAge > 5) return;
    final n = (_fails[key] ?? 0) + 1;
    _fails[key] = n;
    if (n == 2) {
      final rel = Hints.relation(key);
      if (rel.isNotEmpty) narration.hint(rel, queue: true);
    } else if (n == 3) {
      final sol = Hints.solution(key);
      if (sol.isNotEmpty) {
        narration.rememberSolution(sol);
        narration.hint(S.of('solutionReady'), queue: true);
      }
    }
  }

  /// Testler için: bu düzenekte kaç kez ölündü.
  int failsAt(String key) => _fails[key] ?? 0;

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
      once('darkZone$levelIndex', S.of('darkZone'), story: false);
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

  // ------------------------------------------------------- kamera odağı
  // "Ne yaptım, ne değişti": oyuncu bir düzeneği oynatınca kamera sonucu
  // gösterir. İkisi bir ekrana sığıyorsa (ip ve perde, kol ve kapı) kamera
  // aralarına geçip hafifçe açılır: sebep ve sonuç tek karede. Sığmıyorsa
  // sonuca gider, sonuç bitene dek bekler (kapı açılıp yolda ışık akana
  // dek), Sâye'ye döner. Oyuncu bu arada yürümeyi sürdürür. Kovalamacada,
  // Karabasan yakındayken odak yok.
  Vector2? _focusAt;
  double _focusT = 0;
  double _focusLen = 0;
  static const _focusIn = 0.45;
  static const _focusOut = 0.55;

  /// Odak sürerken istenen yakınlaştırma çarpanı (1: değişmez).
  double _focusZoom = 1;
  double _focusZoomS = 1;

  /// Kamera [at] noktasına odaklanır; [hold] orada kalış süresi.
  void focus(Vector2 at, {double hold = 0.9}) {
    final p = player;
    if (p == null || p.isDead || cinematic) return;
    if (threat > 0.3) return;
    if (world.children.whereType<Guard>().any(
          (g) => g.state == GuardState.chase,
        )) {
      return;
    }
    // Aynı yere süren odak yeniden başlamaz, yalnız uzar.
    final cur = _focusAt;
    if (cur != null && _focusT > 0 && (cur - at).length < kTile * 2) {
      _focusT = math.max(_focusT, hold + _focusOut);
      _focusLen = math.max(_focusLen, _focusT);
      return;
    }
    _focusAt = at.clone();
    _focusLen = _focusIn + hold + _focusOut;
    _focusT = _focusLen;
  }

  /// Eski ad (kol): kapıya bakış.
  void peek(Vector2 at) => focus(at);

  // ------------------------------------------------------- manzara anı
  /// Süren manzara (yoksa null) ve başlangıcından beri geçen süre.
  String? vistaKind;
  double vistaT = 0;

  /// Büyük manzara: kamera açılıp yukarı bakar, uzakta yerin manzarası
  /// belirir, yer adı yazılır (vistas.dart).
  void startVista(String kind, Vector2 at) {
    if (vistaKind != null) return;
    final id = 'vista:$levelIndex:$kind';
    if (!_whispersShown.add(id)) return;
    vistaKind = kind;
    vistaT = 0;
    narration.showArea(vistaCaption(kind));
    GameAudio.instance.play('memory', volume: 0.45);
    focus(at - Vector2(0, 5 * kTile), hold: vistaLength - 1.2);
  }

  /// Kameranın suyu göstermek için indiği pay (yumuşatılmış).
  double _waterLook = 0;

  /// Sâye'nin altında, ekranın genişliği içinde ve bir ekran boyu yakında
  /// suyun yüzeyi (yoksa null).
  double? _waterBelow(Player p, double halfH) {
    final pc = (p.center.x / kTile).floor();
    final pr = (p.center.y / kTile).floor();
    final maxR = math.min(level.height - 1, pr + (halfH * 2 / kTile).ceil());
    double? top;
    // Vanayla dolup boşalan hazneler (Yerebatan'ın kuyusu): çekilen su da
    // görünsün, dibe varıp vardığı seçilsin.
    final x0 = (pc - 7) * kTile.toDouble();
    final x1 = (pc + 8) * kTile.toDouble();
    for (final b in world.children.whereType<WaterBasin>()) {
      if (b.area.right < x0 || b.area.left > x1) continue;
      if (b.surface < p.center.y) continue;
      if (b.surface - p.center.y > halfH * 2) continue;
      if (top == null || b.surface < top) top = b.surface;
    }
    for (var c = pc - 7; c <= pc + 7; c++) {
      if (c < 0 || c >= level.width) continue;
      for (var r = math.max(0, pr); r <= maxR; r++) {
        if (level.cell(c, r) != 'w') continue;
        final y = r * kTile.toDouble();
        if (top == null || y < top) top = y;
        break;
      }
    }
    return top;
  }

  /// Dev perdenin önünde kamera perdeyi bütünüyle çerçeveler (0 – 1) ve
  /// gerekirse açılır: telefonun basık ekranında perdenin üstü kesiliyordu.
  double _perdeFrame = 0;
  double _perdeZoom = 1;
  Rect? _perdeRect;

  void _updateCamera(Player p, double dt) {
    if (vistaKind != null) {
      vistaT += dt;
      if (vistaT > vistaLength) vistaKind = null;
    }
    final view = camera.viewport.size;
    if (view.x == 0 || view.y == 0) return;
    Rect? perde;
    for (final g in world.children.whereType<GiantPerde>()) {
      final r = Rect.fromLTWH(
        g.position.x,
        g.position.y - g.size.y,
        g.size.x,
        g.size.y,
      );
      if (p.center.x > r.left - 2 * kTile &&
          p.center.x < r.right + 2 * kTile &&
          (p.center.y - r.bottom).abs() < 3 * kTile) {
        perde = r;
      }
    }
    if (perde != null) _perdeRect = perde;
    _perdeFrame = approach(_perdeFrame, perde != null ? 1 : 0, dt, 0.45);
    // Limbo gibi uzak bir kamera: ekranda yaklaşık 20 kare yükseklik.
    // Kayakta hız ve havada kalış görüşü açar (Alto gibi): yamaç önünde
    // uzar, atlayışın inişi görünür.
    final ski = skiSurface;
    if (ski != null) {
      final sp = (p.velocity.x.abs() / 640).clamp(0.0, 1.0);
      final air = p.onGround ? 0.0 : 1.0;
      _skiOpen = approach(_skiOpen, sp * 0.35 + air * 0.25, dt, 0.6);
    } else {
      _skiOpen = 0;
    }
    final want =
        view.y /
        (kTile * math.min(tilesTall, level.height.toDouble())) *
        _closeUp *
        (1 + 0.05 * threat) /
        (1 + _skiOpen);
    _zoomS = _snapCamera || _zoomS <= 0
        ? want
        : approach(_zoomS, want, dt, 0.3);
    // Odakta sebep ve sonuç birlikte görünsün diye hafif açılış (bir önceki
    // karenin isteği; titremesin diye yumuşatılır).
    _focusZoomS = approach(_focusZoomS, _focusZoom, dt, 0.25);
    // Manzara anında kamera açılır.
    final vista = vistaKind == null ? 0.0 : vistaEnvelope(vistaT);
    // Perdenin boyu ve altında bir kare zemin ekrana sığsın.
    final pr = _perdeRect;
    if (pr != null) {
      final fit = math.min(
        1.0,
        view.y / _zoomS / 2 / (pr.height / 2 + 1.4 * kTile),
      );
      _perdeZoom = 1 + (fit - 1) * _perdeFrame;
    }
    final zoom = _zoomS * _focusZoomS * (1 - 0.2 * vista) * _perdeZoom;
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
    // Altta su varsa (sarnıç, bataklık, tufan) yüzeyi ekranın altında
    // görünsün: alçak ekranlarda (telefon) yolun kenarı boşluğa değil suya
    // açılır. Sâye ekranın üst yarısından çıkmaz.
    final water = _waterBelow(p, halfH);
    var wantDown = 0.0;
    if (water != null) {
      final need = water + kTile * 1.4 - (target.y + halfH);
      final room = p.center.y - kTile * 2.5 - (target.y - halfH);
      wantDown = need.clamp(0.0, math.max(0.0, room));
    }
    // Perdenin önünde suya bakılmaz; perde çerçevelenir.
    _waterLook = approach(_waterLook, wantDown * (1 - _perdeFrame), dt, 0.5);
    target.y += _waterLook;
    if (pr != null && _perdeFrame > 0) {
      final e = _perdeFrame * _perdeFrame * (3 - 2 * _perdeFrame);
      target.y += (pr.center.dy + 0.6 * kTile - target.y) * e;
    }
    if (ski != null) {
      // Kayakta: önündeki yamaca bakar; Sâye ekranın sol üst üçte birinde,
      // gideceği iniş görünür.
      final aheadX = p.center.x + _lookAhead * 1.6;
      final ahead = ski.at(aheadX) ?? p.center.y;
      final mid = p.center.y * 0.55 + ahead * 0.45;
      _skiCamY = _skiCamY.isNaN || _snapCamera
          ? mid
          : approach(_skiCamY, mid, dt, 0.25);
      // Alto gibi: yamaç ekranın alt yarısında, üstte gök ve sıradağlar.
      target
        ..x = p.center.x + _lookAhead * 1.6
        ..y = _skiCamY - halfH * 0.32;
    }
    final focusAt = _focusAt;
    _focusZoom = 1;
    if (focusAt != null && _focusT > _focusOut) {
      // Odak sürerken tehlike doğarsa kamera hemen (yumuşakça) Sâye'ye döner:
      // oyuncu kendini görmeden yakalanmasın.
      final danger =
          p.isDead ||
          threat > 0.3 ||
          world.children.whereType<Guard>().any(
            (g) => g.state == GuardState.alert || g.state == GuardState.chase,
          );
      if (danger) _focusT = _focusOut;
    }
    if (focusAt != null && _focusT > 0) {
      _focusT -= dt;
      // Git, bekle, dön: 0 → 1 → 0, yumuşak.
      final gone = _focusLen - _focusT;
      final w = gone < _focusIn
          ? gone / _focusIn
          : _focusT < _focusOut
          ? math.max(0.0, _focusT) / _focusOut
          : 1.0;
      final e = w * w * (3 - 2 * w);
      // İkisi birlikte sığar mı: Sâye ile sonucun arası, kenarlardan pay.
      final mid = (p.center + focusAt) / 2;
      final needW = (p.center.x - focusAt.x).abs() / 2 + kTile * 3;
      final needH = (p.center.y - focusAt.y).abs() / 2 + kTile * 3;
      // Odağın açılışından önceki görüşe göre (yoksa açıldıkça sığar
      // görünür, kamera salınırdı).
      final fit = math.min(
        view.x / _zoomS / 2 / needW,
        view.y / _zoomS / 2 / needH,
      );
      if (fit >= 0.78) {
        // Sebep ve sonuç tek karede; gerekirse biraz açılır.
        target.setFrom(target + (mid - target) * e);
        _focusZoom = 1 + (math.min(1.0, fit) - 1) * e;
      } else {
        target.setFrom(target + (focusAt - target) * e);
      }
      if (_focusT <= 0) _focusAt = null;
    }
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
        if (_settingsShown) {
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
      if (recentOpen) {
        if (esc || event.logicalKey == LogicalKeyboardKey.keyI) toggleRecent();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyI &&
          !narration.inCinematic) {
        toggleRecent();
        return KeyEventResult.handled;
      }
      // H: ipucu simgesi (yanıksa bekleyen ipucu, değilse son ipucu).
      if (event.logicalKey == LogicalKeyboardKey.keyH) {
        narration.revealHint();
        return KeyEventResult.handled;
      }
      if (esc && narration.inCinematic && !_settingsShown) {
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
      if (held) return KeyEventResult.handled;
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
        debugLoadLevel(nextLevel(levelIndex) ?? levelOrder.first);
        _showLevelTitle();
      }
      // Geliştirici kısayolu: C yakın plan (ekran görüntüsü için).
      if (const bool.fromEnvironment('DEV') &&
          event.logicalKey == LogicalKeyboardKey.keyC) {
        _closeUp = _closeUp == 1 ? 3 : 1;
      }
      // Deneme yapısında L ışık ve derinlik denemesini açar/kapar.
      if (Cartoon.trialBuild && event.logicalKey == LogicalKeyboardKey.f3) {
        perfShown = !perfShown;
        Settings.save();
      }
      if (Cartoon.trialBuild && event.logicalKey == LogicalKeyboardKey.keyL) {
        Realism.on = !Realism.on;
        Settings.realism = Realism.on;
        Settings.save();
        if (Realism.on) AutoQuality.userChose = true;
      }
      // Deneme yapısında K karikatürize görsel denemesini açar/kapar
      // (şimdilik yalnız Yerebatan).
      if (Cartoon.trialBuild && event.logicalKey == LogicalKeyboardKey.keyK) {
        Cartoon.on = !Cartoon.on;
        Settings.texture = Cartoon.on;
        Settings.save();
      }
      // Geliştirici kısayolu: , ve . Yerebatan denemesinin tonunu
      // koyulaştırır / açar (ayarlar panelinde değeri görünür).
      if (Cartoon.trialBuild &&
          (event.logicalKey == LogicalKeyboardKey.comma ||
              event.logicalKey == LogicalKeyboardKey.period)) {
        final d = event.logicalKey == LogicalKeyboardKey.comma ? -0.05 : 0.05;
        Cartoon.tone = (Cartoon.tone + d).clamp(0.0, 1.0);
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
