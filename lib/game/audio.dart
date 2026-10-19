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

  static const _effects = [
    'step_1',
    'step_2',
    'step_3',
    'step_4',
    'step_wood_1',
    'step_wood_2',
    'step_wood_3',
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
  ];

  bool _ready = false;

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
    'land',
    'jump',
    'creak',
  };

  /// Tekdüze olmasın diye birden çok varyasyonu olan sesler.
  static const _variants = {'step': 4, 'step_wood': 3};
  final _rnd = math.Random();
  final _lastVariant = <String, int>{};
  AudioPlayer? _music;
  bool _musicWanted = false;
  bool _musicStarting = false;
  AudioPlayer? _ambient;
  String? _ambientName;
  String? _wantedAmbient;
  AudioPlayer? _dread;
  bool _dreadStarting = false;
  double _dreadLevel = 0;
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
      await FlameAudio.audioCache.loadAll([
        for (final e in _effects) '$e.wav',
        'amb_cistern.wav',
        'amb_wind.wav',
        'amb_sky.wav',
        'karabasan.wav',
        'menu_theme.mp3',
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
      if (_musicWanted) {
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
    pool
        .start(volume: (volume * Settings.effects).clamp(0.0, 1.0))
        .catchError((_) => () async {});
  }

  /// Bölümün temasına uygun ortam döngüsü.
  void ambientFor(LevelTheme theme) {
    final name = switch (theme) {
      LevelTheme.cistern || LevelTheme.cave => 'amb_cistern',
      LevelTheme.cliffs => 'amb_wind',
      LevelTheme.sky => 'amb_sky',
    };
    _wantedAmbient = name;
    if (_ready && !_musicWanted) _startAmbient(name);
  }

  /// Ana menü müziği; açılınca ortam sesi susar, kapanınca geri gelir.
  void menuMusic(bool on) {
    _musicWanted = on;
    if (!_ready) return;
    if (on) {
      _ambient?.stop();
      _ambient = null;
      _ambientName = null;
      dread(0);
      if (_music != null || _musicStarting) return;
      _musicStarting = true;
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

  Future<void> _startAmbient(String name) async {
    if (_ambientName == name && _ambient != null) return;
    _ambientName = name;
    try {
      await _ambient?.stop();
      _ambient = await FlameAudio.loop(
        '$name.wav',
        volume: Settings.ambience * 0.8,
      );
    } catch (_) {}
  }

  /// Karabasan'ın gümbürtüsü: 0 = yok, 1 = ensende.
  void dread(double level) {
    if (!_ready) return;
    level = level.clamp(0.0, 1.0);
    if ((level - _dreadLevel).abs() < 0.03) return;
    _dreadLevel = level;
    if (level <= 0) {
      _dread?.stop();
      _dread = null;
      return;
    }
    final vol = (level * Settings.effects).clamp(0.0, 1.0);
    if (_dread == null) {
      if (_dreadStarting) return;
      _dreadStarting = true;
      FlameAudio.loop('karabasan.wav', volume: vol)
          .then((p) {
            _dread = p;
            _dreadStarting = false;
            // Başlarken tehdit geçmişse hemen sustur.
            if (_dreadLevel <= 0) {
              p.stop();
              _dread = null;
            }
          })
          .catchError((_) {
            _dreadStarting = false;
          });
    } else {
      _dread!.setVolume(vol);
    }
  }

  void applyVolumes() {
    _music?.setVolume(Settings.music);
    _ambient?.setVolume(Settings.ambience * 0.8);
    _dread?.setVolume((_dreadLevel * Settings.effects).clamp(0.0, 1.0));
  }

  void pauseAll() {
    _ambient?.pause();
    _dread?.pause();
  }

  void resumeAll() {
    _ambient?.resume();
    _dread?.resume();
  }
}
