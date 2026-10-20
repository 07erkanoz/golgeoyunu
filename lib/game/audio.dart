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
    'thunder',
  ];

  bool _ready = false;

  /// Menü müziği yüklendi mi (efektlerden önce hazır olur).
  bool _musicReady = false;

  /// Her efekt için önceden hazırlanmış oynatıcılar: çalarken yeni oynatıcı
  /// oluşturulmaz (Windows'ta bu, ses anında takılmaya yol açar).
  final _pools = <String, AudioPool>{};
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

  Future<void> init() async {
    try {
      // Android'de her oynatıcı varsayılan olarak ses odağını kendine alır;
      // oyunun kendi sesleri (müzik, ortam, efektler) birbirinin odağını
      // çalınca müzik duraklayıp baştan başlıyordu. Hepsi odak istemeden
      // birlikte çalar.
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
            .build(),
      );
      // Menü müziği her şeyden önce: efektler yüklenirken bekletmesin.
      await FlameAudio.audioCache.load('menu_theme.mp3');
      _musicReady = true;
      if (_musicWanted) menuMusic(true);
      await FlameAudio.audioCache.loadAll([
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
      ]);
      await Future.wait([
        for (final e in _effects)
          FlameAudio.createPool(
            '$e.wav',
            minPlayers: _frequent.contains(e) ? 3 : 1,
            maxPlayers: _frequent.contains(e) ? 4 : 2,
          ).then((pool) => _pools[e] = pool),
      ]);
      _ready = true;
      if (_neyWanted) {
        perde(true);
      } else if (_musicWanted) {
        menuMusic(true);
      } else {
        final wanted = _wantedAmbient;
        if (wanted != null) await _startAmbient(wanted);
      }
    } catch (_) {
      _ready = false;
    }
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
    final pool = _pools[name];
    if (pool == null) return;
    _log('çal $name');
    pool
        .start(volume: (volume * Settings.effects).clamp(0.0, 1.0))
        .catchError((_) => () async {});
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
      FlameAudio.loop('menu_theme.mp3', volume: Settings.music)
          .then((p) {
            _music = p;
            _musicStarting = false;
            if (!_musicWanted) {
              p.stop();
              _music = null;
            }
          })
          .catchError((_) {
            _musicStarting = false;
          });
    } else {
      _music?.stop();
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
      FlameAudio.loop('perde_ney.wav', volume: Settings.music)
          .then((p) {
            if (!_neyWanted || _ney != null) {
              p.stop();
              return;
            }
            _ney = p;
          })
          .catchError((_) {});
    } else {
      _ney?.stop();
      _ney = null;
      final wanted = _wantedAmbient;
      if (wanted != null && !_musicWanted) _startAmbient(wanted);
    }
  }

  /// Ortam döngüsünün kuşağı: yüklenirken yeni bir istek gelirse geç kalan
  /// yükleme kendini susturur (iki döngü üst üste çalmasın, sahipsiz bir
  /// döngü menüde bile sürmesin).
  int _ambientGen = 0;

  void _stopAmbient() {
    _ambientGen++;
    _ambient?.stop();
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
      final p = await FlameAudio.loop('$name.wav', volume: _ambientVolume);
      if (gen != _ambientGen || _musicWanted || _neyWanted) {
        await p.stop();
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
      l.player?.pause();
    }
  }

  void resumeAll() {
    _ney?.resume();
    _ambient?.resume();
    for (final l in _loops) {
      l.player?.resume();
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

/// Seviyesi değişen bir döngü: 0'a inince durur, yükselince yeniden başlar.
class _LoopChannel {
  _LoopChannel(this.file);

  final String file;
  AudioPlayer? player;
  bool _starting = false;
  double _level = 0;

  double get _volume => (_level * Settings.effects).clamp(0.0, 1.0);

  void set(double level) {
    if ((level - _level).abs() < 0.03 && (level > 0 || _level == 0)) return;
    _level = level;
    if (level <= 0) {
      player?.stop();
      player = null;
      return;
    }
    if (player == null) {
      if (_starting) return;
      _starting = true;
      GameAudio._log('döngü $file');
      FlameAudio.loop(file, volume: _volume)
          .then((p) {
            player = p;
            _starting = false;
            // Başlarken seviye düştüyse hemen sustur.
            if (_level <= 0) {
              p.stop();
              player = null;
            } else {
              p.setVolume(_volume);
            }
          })
          .catchError((_) {
            _starting = false;
          });
    } else {
      player!.setVolume(_volume);
    }
  }

  void refresh() => player?.setVolume(_volume);
}
