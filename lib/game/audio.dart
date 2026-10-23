import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_soloud/flutter_soloud.dart';

import '../settings.dart';
import 'levels.dart';

/// Oyunun sesleri: arka plan (menü müziği, perde neyi ya da bölümün ortam
/// sesi), seviyesi değişen gerilim döngüleri ve efektler.
///
/// Hepsi tek bir yerel ses motorunda (SoLoud, FFI ile) karışır: sesler açılışta
/// bir kez yüklenir; çalmak, susturmak, ses düzeyini değiştirmek beklemesiz,
/// doğrudan çağrılardır. (Önceki düzende her ses Android'in ayrı bir
/// oynatıcısıydı; her ayak sesi kanal üstünden üç istek demekti ve oynatıcılar
/// her cihazda başka türlü davranıyordu.)
///
/// `init` çağrılana kadar sessizdir; testler böylece ses aygıtına dokunmaz.
class GameAudio {
  GameAudio._();

  static final instance = GameAudio._();

  /// `--dart-define=AUDIO_LOG=true` ile her çalınan sesi yazar (hata arama).
  static void _log(String s) {
    // ignore: avoid_print
    if (const bool.fromEnvironment('AUDIO_LOG')) print('[ses] $s');
  }

  static const _effects = [
    'step_1',
    'step_2',
    'step_3',
    'step_4',
    'step_wood_1',
    'step_wood_2',
    'step_wood_3',
    'step_snow_1',
    'step_snow_2',
    'step_snow_3',
    'step_snow_4',
    'jump',
    'land',
    'firefly',
    'pickup',
    'memory',
    'suspect',
    'alert',
    'bats',
    'crow',
    'lever',
    'gate',
    'crumble',
    'death',
    'splash',
    'throw',
    'glide',
    'creak',
    'shatter',
    'breath',
    'fizzle',
    'chain',
    'gust',
    'bell',
    'grind',
    'fire',
    'fire_warn',
    'sting',
    'growl',
    'howl',
    'drum',
    'thunder',
    'bird_1',
    'bird_2',
    'bird_3',
    'bird_4',
  ];

  /// Uzun döngüler diskten akar (belleği şişirmesin); kısa efektler bellekte.
  static const _streamed = [
    'amb_cistern.wav',
    'amb_wind.wav',
    'amb_sky.wav',
    'amb_snow.wav',
    'amb_ark.wav',
    'amb_konya.wav',
    'amb_cave.wav',
    'amb_forest.wav',
    'karabasan.wav',
    'heartbeat.wav',
    'murmur.wav',
  ];

  /// Tekdüze olmasın diye birden çok varyasyonu olan sesler.
  static const _variants = {
    'step': 4,
    'step_wood': 3,
    'step_snow': 4,
    'bird': 4,
  };
  final _rnd = math.Random();
  final _lastVariant = <String, int>{};
  final _lastPlayed = <String, int>{};

  SoLoud get _s => SoLoud.instance;

  /// Yüklenmiş sesler: dosya adı (uzantısız) → kaynak.
  final _src = <String, AudioSource>{};

  bool _ready = false;

  /// Yüklenemeyen ses dosyaları (tanı için).
  final failed = <String>[];

  // ------------------------------------------------------------ arka plan

  /// Tek bir arka plan sesi çalar: menü müziği, perde neyi ya da bölümün
  /// ortam sesi. Değişince eskisi yumuşakça söner, yenisi yumuşakça gelir.
  bool _musicWanted = false;
  bool _neyWanted = false;
  String? _wantedAmbient;
  SoundHandle? _bed;
  String? _bedName;
  bool _paused = false;

  /// Saklanırken ortam sesi boğuklaşır (0 = normal, 1 = tamamen kısık).
  double _duck = 0;

  String? get _desiredBed => _musicWanted
      ? 'menu_theme'
      : _neyWanted
      ? 'perde_ney'
      : _wantedAmbient;

  double get _ambientVolume => Settings.ambience * 0.8 * (1 - 0.65 * _duck);

  double _bedVolume(String name) => name == 'menu_theme' || name == 'perde_ney'
      ? Settings.music
      : _ambientVolume;

  static const _fadeIn = Duration(milliseconds: 900);
  static const _fadeOut = Duration(milliseconds: 600);

  void _updateBed() {
    if (!_ready) return;
    final want = _desiredBed;
    if (want == _bedName && _bedAlive) return;
    _fadeOutBed();
    if (want == null) return;
    final src = _src[want];
    if (src == null) return; // yüklenince yeniden denenir
    try {
      final h = _s.play(src, volume: 0, looping: true, paused: _paused);
      _s.fadeVolume(h, _bedVolume(want), _fadeIn);
      _bed = h;
      _bedName = want;
      _log('arka plan $want');
    } catch (e) {
      _log('arka plan çalınamadı $want: $e');
    }
  }

  bool get _bedAlive {
    final h = _bed;
    return h != null && _safe(() => _s.getIsValidVoiceHandle(h), false);
  }

  void _fadeOutBed() {
    final h = _bed;
    _bed = null;
    _bedName = null;
    if (h == null) return;
    _safe(() {
      _s.fadeVolume(h, 0, _fadeOut);
      _s.scheduleStop(h, _fadeOut);
    }, null);
  }

  void _setBedVolume() {
    final h = _bed;
    final name = _bedName;
    if (h == null || name == null) return;
    _safe(() => _s.setVolume(h, _bedVolume(name)), null);
  }

  /// Bölümün temasına uygun ortam döngüsü.
  void ambientFor(LevelTheme theme) {
    _wantedAmbient = switch (theme) {
      LevelTheme.cistern => 'amb_cistern',
      LevelTheme.cave || LevelTheme.underworld => 'amb_cave',
      LevelTheme.ark => 'amb_ark',
      LevelTheme.cliffs ||
      LevelTheme.peri ||
      LevelTheme.ergenekon => 'amb_wind',
      LevelTheme.sky || LevelTheme.kaf || LevelTheme.heavens => 'amb_sky',
      LevelTheme.snow || LevelTheme.nemrut => 'amb_snow',
      LevelTheme.konya => 'amb_konya',
      LevelTheme.forest => 'amb_forest',
    };
    _updateBed();
  }

  /// Ana menü müziği; açılınca ortam sesi susar, kapanınca geri gelir.
  void menuMusic(bool on) {
    _musicWanted = on;
    if (on) dread(0);
    _updateBed();
  }

  /// Perde sahnelerinin neyi: çalarken ortam sesi susar.
  void perde(bool on) {
    _neyWanted = on;
    if (on) dread(0);
    _updateBed();
  }

  /// Saklanırken ortam sesini kısar.
  void duck(double amount, {bool force = false}) {
    amount = amount.clamp(0.0, 1.0);
    if ((amount - _duck).abs() < 0.02 && !force) return;
    _duck = amount;
    if (_bedName?.startsWith('amb_') ?? false) _setBedVolume();
  }

  // ---------------------------------------------------- gerilim döngüleri

  final _dread = _LoopChannel('karabasan');
  final _heart = _LoopChannel('heartbeat');
  final _murmur = _LoopChannel('murmur');
  late final _loops = [_dread, _heart, _murmur];

  /// Karabasan'ın gümbürtüsü: 0 = yok, 1 = ensende.
  void dread(double level) => _set(_dread, level);

  /// Saklanırken duyulan kalp atışı: tehlike yaklaştıkça yükselir.
  void heartbeat(double level) => _set(_heart, level * 0.9);

  /// En yakın Kandilci'nin mırıltısı.
  void murmur(double level) => _set(_murmur, level * 0.6);

  void _set(_LoopChannel ch, double level) {
    if (!_ready) return;
    ch.set(this, level.clamp(0.0, 1.0));
  }

  /// Sahne değişince bütün gerilim döngüleri susar.
  void silenceLoops() {
    if (_ready) {
      for (final l in _loops) {
        l.hush();
      }
    }
    duck(0, force: true);
  }

  /// Eski düzenden kalan çağrı: sesler zaten açılışta yüklenir.
  void prewarmLoops() {}

  // ------------------------------------------------------------ efektler

  /// Bir efekt çalar; aynı efekt [minGapMs] içinde tekrar çalınmaz.
  void play(String name, {double volume = 1, int minGapMs = 60}) {
    if (!_ready || Settings.effects <= 0) return;
    final count = _variants[name];
    if (count != null) {
      // Aynı varyasyon art arda gelmesin.
      var v = _rnd.nextInt(count);
      if (v == _lastVariant[name]) v = (v + 1) % count;
      _lastVariant[name] = v;
      name = '${name}_${v + 1}';
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - (_lastPlayed[name] ?? 0) < minGapMs) return;
    _lastPlayed[name] = now;
    final src = _src[name];
    if (src == null) return;
    _log('çal $name');
    _safe(
      () => _s.play(src, volume: (volume * Settings.effects).clamp(0.0, 1.0)),
      null,
    );
  }

  // ------------------------------------------------------- genel denetim

  void applyVolumes() {
    if (!_ready) return;
    _setBedVolume();
    for (final l in _loops) {
      l.refresh();
    }
  }

  /// Ayarlar açıkken ya da uygulama arka plandayken her şey bekler.
  void pauseAll() {
    _paused = true;
    _pauseHandles(true);
  }

  void resumeAll() {
    _paused = false;
    _pauseHandles(false);
  }

  void _pauseHandles(bool pause) {
    if (!_ready) return;
    final h = _bed;
    if (h != null) _safe(() => _s.setPause(h, pause), null);
    for (final l in _loops) {
      l.pause(pause);
    }
  }

  /// Yerel motora yapılan bir çağrı; motor kapanmışsa ya da ses geçersizse
  /// oyun durmaz.
  static T _safe<T>(T Function() f, T fallback) {
    try {
      return f();
    } catch (e) {
      _log('hata: $e');
      return fallback;
    }
  }

  // ------------------------------------------------------------- yükleme

  /// Motoru açar ve bütün sesleri yükler. Her dosya ayrı korunur: biri
  /// yüklenemese de öteki sesler çalar.
  Future<void> init() async {
    try {
      if (!_s.isInitialized) await _s.init();
      // Aynı anda çalabilecek ses sayısı (efektler, döngüler, arka plan).
      _s.setMaxActiveVoiceCount(32);
    } catch (e) {
      failed.add('ses motoru');
      _log('ses motoru açılamadı: $e');
      return;
    }
    _ready = true;
    Future<void> load(String file, LoadMode mode) async {
      final name = file.substring(0, file.lastIndexOf('.'));
      try {
        _src[name] = await _s.loadAsset('assets/audio/$file', mode: mode);
      } catch (e) {
        failed.add(file);
        _log('yüklenemedi $file: $e');
      }
    }

    // Önce menü müziği ve perde: açılışta hemen duyulsun.
    await load('menu_theme.mp3', LoadMode.disk);
    await load('perde_ney.wav', LoadMode.disk);
    _updateBed();
    for (final e in _effects) {
      await load('$e.wav', LoadMode.memory);
    }
    for (final f in _streamed) {
      await load(f, LoadMode.disk);
    }
    // Yükleme sürerken istenmiş olanlar şimdi başlar.
    _updateBed();
    applyVolumes();
  }
}

/// Seviyesi sürekli değişen bir döngü: duyulur olunca başlar, ses düzeyi
/// doğrudan ayarlanır; bir süre sessiz kalınca durur.
class _LoopChannel {
  _LoopChannel(this.name);

  final String name;
  SoundHandle? _h;
  double _level = 0;
  double _sent = -1;
  int _silentAt = 0;

  SoLoud get _s => SoLoud.instance;

  double get _volume => (_level * Settings.effects).clamp(0.0, 1.0);

  void set(GameAudio a, double level) {
    _level = level;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (level <= 0) {
      // Önce yalnızca kısılır; uzun süre sessiz kalırsa durur.
      if (_sent > 0) {
        _silentAt = now;
        _apply();
      } else if (_h != null && now - _silentAt > 4000) {
        _stop();
      }
      return;
    }
    if (!_alive) {
      final src = a._src[name];
      if (src == null) return;
      _h = GameAudio._safe<SoundHandle?>(
        () => _s.play(src, volume: _volume, looping: true, paused: a._paused),
        null,
      );
      _sent = _volume;
      return;
    }
    if ((_volume - _sent).abs() > 0.01) _apply();
  }

  bool get _alive {
    final h = _h;
    return h != null &&
        GameAudio._safe(() => _s.getIsValidVoiceHandle(h), false);
  }

  void _apply() {
    final h = _h;
    if (h == null) return;
    _sent = _volume;
    GameAudio._safe(() => _s.setVolume(h, _sent), null);
  }

  void refresh() {
    if (_level > 0) _apply();
  }

  void pause(bool pause) {
    final h = _h;
    if (h != null) GameAudio._safe(() => _s.setPause(h, pause), null);
  }

  void hush() {
    _level = 0;
    _stop();
  }

  void _stop() {
    final h = _h;
    _h = null;
    _sent = -1;
    if (h != null) GameAudio._safe(() => unawaited(_s.stop(h)), null);
  }
}
