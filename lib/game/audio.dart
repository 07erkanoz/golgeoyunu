import 'dart:math' as math;

import 'package:flame_audio/flame_audio.dart';

import '../settings.dart';
import 'levels.dart';

/// Oyunun sesleri: ortam döngüleri, Karabasan'ın gümbürtüsü ve efektler.
/// Sesler `tools/synth_sounds.py` ile sentezlenir.
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
    'thunder',
  ];

  // Döngüler `loopLongAudio` ile çalar: Android'de `loop` SoundPool kullanır
  // ve SoundPool uzun sesleri ilk birkaç saniyede keser; menü müziği ve ortam
  // sesleri o kırpılmış parçayı baştan başa döndürüyordu.
  bool _ready = false;

  /// Menü müziği yüklendi mi (efektlerden önce hazır olur).
  bool _musicReady = false;

  /// Her efekt için önceden hazırlanmış, sabit sayıda oynatıcı: oyun
  /// sırasında asla yenisi kurulmaz ya da silinmez (Windows'ta kurulum anında
  /// takılma, Android'de biriken yerel oynatıcılar çökme yapıyordu). Android'de
  /// kısa efektler SoundPool'da (lowLatency) çalar: tek bir hafif havuz,
  /// onlarca MediaPlayer yerine.
  final _sfx = <String, _Sfx>{};
  static const _frequent = {
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
    'land',
    'jump',
    'creak',
  };

  /// Tekdüze olmasın diye birden çok varyasyonu olan sesler.
  static const _variants = {'step': 4, 'step_wood': 3, 'step_snow': 4};
  final _rnd = math.Random();
  final _lastVariant = <String, int>{};
  AudioPlayer? _music;
  bool _musicWanted = false;
  bool _musicStarting = false;
  AudioPlayer? _ambient;
  String? _ambientName;
  String? _wantedAmbient;
  AudioPlayer? _ney;
  bool _neyWanted = false;

  /// Seviyesi sürekli değişen döngüler: Karabasan'ın gümbürtüsü, saklanırken
  /// kalp atışı, Kandilcilerin mırıltısı.
  final _dread = _LoopChannel('karabasan.wav');
  final _heart = _LoopChannel('heartbeat.wav');
  final _murmur = _LoopChannel('murmur.wav');
  late final _loops = [_dread, _heart, _murmur];

  /// Saklanırken ortam sesi boğuklaşır (0 = normal, 1 = tamamen kısık).
  double _duck = 0;
  final _lastPlayed = <String, int>{};

  /// Yüklenemeyen ses dosyaları (tanı için).
  final failed = <String>[];

  /// Her dosya ayrı korunur: biri yüklenemese de müzik ve öteki sesler çalar.
  Future<void> init() async {
    Future<void> guard(String what, Future<void> Function() f) async {
      try {
        await f();
      } catch (e) {
        failed.add(what);
        _log('yüklenemedi $what: $e');
      }
    }

    // Android'de her oynatıcı varsayılan olarak ses odağını kendine alır;
    // oyunun kendi sesleri (müzik, ortam, efektler) birbirinin odağını
    // çalınca müzik duraklayıp baştan başlıyordu. Hepsi odak istemeden
    // birlikte çalar.
    await guard(
      'ses bağlamı',
      () => AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
            .build(),
      ),
    );
    // Menü müziği her şeyden önce: efektler yüklenirken bekletmesin.
    await guard('menu_theme.mp3', () async {
      await FlameAudio.audioCache.load('menu_theme.mp3');
      _musicReady = true;
      if (_musicWanted) menuMusic(true);
    });
    for (final f in [
      for (final e in _effects) '$e.wav',
      'amb_cistern.wav',
      'amb_wind.wav',
      'amb_sky.wav',
      'amb_snow.wav',
      'amb_ark.wav',
      'amb_konya.wav',
      'amb_cave.wav',
      'karabasan.wav',
      'heartbeat.wav',
      'murmur.wav',
      'perde_ney.wav',
    ]) {
      await guard(f, () => FlameAudio.audioCache.load(f));
    }
    for (final e in _effects) {
      if (failed.contains('$e.wav')) continue;
      await guard(e, () async {
        _sfx[e] = await _Sfx.create('$e.wav', _frequent.contains(e) ? 3 : 1);
      });
    }
    _ready = true;
    await guard('başlangıç döngüsü', () async {
      if (_neyWanted) {
        perde(true);
      } else if (_musicWanted) {
        menuMusic(true);
      } else {
        final wanted = _wantedAmbient;
        if (wanted != null) await _startAmbient(wanted);
      }
    });
  }

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
    final sfx = _sfx[name];
    if (sfx == null) return;
    _log('çal $name');
    sfx.play((volume * Settings.effects).clamp(0.0, 1.0));
  }

  /// Bölümün temasına uygun ortam döngüsü.
  void ambientFor(LevelTheme theme) {
    final name = switch (theme) {
      LevelTheme.cistern => 'amb_cistern',
      LevelTheme.cave => 'amb_cave',
      LevelTheme.ark => 'amb_ark',
      LevelTheme.cliffs || LevelTheme.peri => 'amb_wind',
      LevelTheme.sky || LevelTheme.kaf => 'amb_sky',
      LevelTheme.snow || LevelTheme.nemrut => 'amb_snow',
      LevelTheme.konya => 'amb_konya',
    };
    _wantedAmbient = name;
    if (_ready && !_musicWanted && !_neyWanted) _startAmbient(name);
  }

  /// Ana menü müziği; açılınca ortam sesi susar, kapanınca geri gelir.
  void menuMusic(bool on) {
    _musicWanted = on;
    if (!_musicReady) return;
    if (on) {
      _stopAmbient();
      dread(0);
      if (_music != null || _musicStarting) return;
      _musicStarting = true;
      _log('döngü menu_theme');
      FlameAudio.loopLongAudio('menu_theme.mp3', volume: Settings.music)
          .then((p) {
            _music = p;
            _musicStarting = false;
            if (!_musicWanted) {
              _drop(p);
              _music = null;
            }
          })
          .catchError((_) {
            _musicStarting = false;
          });
    } else {
      _drop(_music);
      _music = null;
      final wanted = _wantedAmbient;
      if (wanted != null) _startAmbient(wanted);
    }
  }

  /// Perde sahnelerinin neyi: çalarken ortam sesi susar.
  void perde(bool on) {
    _neyWanted = on;
    if (!_ready) return;
    if (on) {
      if (_ney != null) return;
      _stopAmbient();
      dread(0);
      _log('döngü perde_ney');
      FlameAudio.loopLongAudio('perde_ney.wav', volume: Settings.music)
          .then((p) {
            if (!_neyWanted || _ney != null) {
              _drop(p);
              return;
            }
            _ney = p;
          })
          .catchError((_) {});
    } else {
      _drop(_ney);
      _ney = null;
      final wanted = _wantedAmbient;
      if (wanted != null && !_musicWanted) _startAmbient(wanted);
    }
  }

  /// Ortam döngüsünün kuşağı: yüklenirken yeni bir istek gelirse geç kalan
  /// yükleme kendini susturur (iki döngü üst üste çalmasın, sahipsiz bir
  /// döngü menüde bile sürmesin).
  int _ambientGen = 0;

  /// Durdurup yerel oynatıcıyı serbest bırakır (Android'de oynatıcılar
  /// sınırlıdır; bırakılmayan her biri birikir).
  static void _drop(AudioPlayer? p) {
    if (p == null) return;
    p.dispose().catchError((_) {});
  }

  void _stopAmbient() {
    _ambientGen++;
    _drop(_ambient);
    _ambient = null;
    _ambientName = null;
  }

  Future<void> _startAmbient(String name) async {
    if (_ambientName == name) return;
    _stopAmbient();
    _ambientName = name;
    final gen = _ambientGen;
    try {
      _log('döngü $name');
      final p = await FlameAudio.loopLongAudio(
        '$name.wav',
        volume: _ambientVolume,
      );
      if (gen != _ambientGen || _musicWanted || _neyWanted) {
        _drop(p);
        return;
      }
      _ambient = p;
    } catch (_) {
      if (gen == _ambientGen) _ambientName = null;
    }
  }

  /// Karabasan'ın gümbürtüsü: 0 = yok, 1 = ensende.
  void dread(double level) => _set(_dread, level);

  /// Saklanırken duyulan kalp atışı: tehlike yaklaştıkça yükselir.
  void heartbeat(double level) => _set(_heart, level * 0.9);

  /// En yakın Kandilci'nin mırıltısı.
  void murmur(double level) => _set(_murmur, level * 0.6);

  /// Saklanırken ortam sesini kısar.
  void duck(double amount) {
    amount = amount.clamp(0.0, 1.0);
    if ((amount - _duck).abs() < 0.04) return;
    _duck = amount;
    _ambient?.setVolume(_ambientVolume);
  }

  double get _ambientVolume => Settings.ambience * 0.8 * (1 - 0.65 * _duck);

  void _set(_LoopChannel ch, double level) {
    if (!_ready) return;
    ch.set(level.clamp(0.0, 1.0));
  }

  void applyVolumes() {
    _music?.setVolume(Settings.music);
    _ney?.setVolume(Settings.music);
    _ambient?.setVolume(_ambientVolume);
    for (final l in _loops) {
      l.refresh();
    }
  }

  void pauseAll() {
    _ney?.pause();
    _ambient?.pause();
    for (final l in _loops) {
      l.pause();
    }
  }

  void resumeAll() {
    _ney?.resume();
    _ambient?.resume();
    for (final l in _loops) {
      l.resume();
    }
  }

  /// Sahne değişince bütün gerilim döngüleri susar.
  void silenceLoops() {
    for (final l in _loops) {
      _set(l, 0);
    }
    duck(0);
  }
}

/// Bir efektin sabit oynatıcıları; sırayla kullanılır (aynı ses üst üste
/// gelirse en eskisi baştan başlar).
class _Sfx {
  _Sfx(this._players);

  final List<AudioPlayer> _players;
  int _next = 0;

  static Future<_Sfx> create(String file, int count) async {
    final players = <AudioPlayer>[];
    for (var i = 0; i < count; i++) {
      final p = AudioPlayer()..audioCache = FlameAudio.audioCache;
      try {
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setSource(AssetSource(file));
        players.add(p);
      } catch (_) {
        p.dispose().catchError((_) {});
      }
    }
    return _Sfx(players);
  }

  void play(double volume) {
    if (_players.isEmpty) return;
    final p = _players[_next];
    _next = (_next + 1) % _players.length;
    () async {
      try {
        await p.stop();
        await p.setVolume(volume);
        await p.resume();
      } catch (_) {}
    }();
  }
}

/// Seviyesi değişen bir döngü: 0'a inince durur, yükselince yeniden başlar.
class _LoopChannel {
  _LoopChannel(this.file);

  final String file;
  AudioPlayer? player;
  bool _starting = false;
  bool _paused = false;
  double _level = 0;
  int _lastVolume = 0;

  double get _volume => (_level * Settings.effects).clamp(0.0, 1.0);

  /// Tek bir oynatıcı bir kez kurulur; sessizken duraklar, gerekince devam
  /// eder. (Her seferinde yenisini kurmak Android'de yerel oynatıcıları
  /// tüketip uygulamayı çökertiyordu.)
  void set(double level) {
    if ((level - _level).abs() < 0.03 && (level > 0 || _level == 0)) return;
    _level = level;
    final p = player;
    if (level <= 0) {
      if (p != null && !_paused) {
        _paused = true;
        p.pause().catchError((_) {});
      }
      return;
    }
    if (p == null) {
      if (_starting) return;
      _starting = true;
      GameAudio._log('döngü $file');
      FlameAudio.loopLongAudio(file, volume: _volume)
          .then((p) {
            player = p;
            _starting = false;
            _paused = false;
            // Başlarken seviye düştüyse duraklat.
            if (_level <= 0) {
              _paused = true;
              p.pause().catchError((_) {});
            } else {
              p.setVolume(_volume).catchError((_) {});
            }
          })
          .catchError((_) {
            _starting = false;
          });
      return;
    }
    // Ses düzeyi en çok saniyede ~12 kez gönderilir (120 Hz'de her karede
    // yerel oynatıcıya çağrı yağmasın).
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_paused || now - _lastVolume > 80) {
      _lastVolume = now;
      p.setVolume(_volume).catchError((_) {});
    }
    if (_paused) {
      _paused = false;
      p.resume().catchError((_) {});
    }
  }

  void refresh() => player?.setVolume(_volume).catchError((_) {});

  void pause() => player?.pause().catchError((_) {});

  void resume() {
    if (!_paused && _level > 0) player?.resume().catchError((_) {});
  }
}
