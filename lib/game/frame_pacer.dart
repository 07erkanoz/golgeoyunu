import 'dart:async';

import 'package:flutter/foundation.dart';

import '../settings.dart';
import 'golge_game.dart';

/// Masaüstünde kare sınırı: 144-165 Hz ekranlarda oyun saniyede 144-165
/// kez baştan çiziliyordu (oyunun mantığı zaten 60 adımla işler). Windows'ta
/// çizim ANGLE çevirmeninden geçtiği için ekran kartı boşuna yoruluyor, oyun
/// takılıyordu. Sınır açıkken motorun kendi döngüsü durur; kareleri bu
/// sınıf, ekranın hızını tam bölen ve 60'a en yakın aralıkla tetikler
/// (144 Hz → 72, 165 Hz → 55, 240 Hz → 60).
///
/// "Yüksek yenileme hızı" ayarı açıksa sınır yoktur.
class FramePacer {
  FramePacer(this.game);

  final GolgeGame game;

  Timer? _timer;
  final _clock = Stopwatch();
  int _last = 0;

  bool get active => _timer != null;

  /// Masaüstünde ve yüksek yenileme kapalıyken sınır uygulanır.
  static bool get wanted =>
      !kIsWeb &&
      !(const bool.fromEnvironment('DEV') &&
          const bool.fromEnvironment('NOPACER')) &&
      !Settings.highRefresh &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Ekranın yenileme hızını tam bölen, 60'a en yakın kare hızı.
  static double targetFps(double hz) {
    if (!hz.isFinite || hz < 30) return 60;
    final n = (hz / 60).round().clamp(1, 8);
    return hz / n;
  }

  double get _displayHz {
    try {
      return PlatformDispatcher.instance.views.first.display.refreshRate;
    } catch (_) {
      return 60;
    }
  }

  /// Ayara göre sınırı açar ya da kapatır.
  void apply() {
    if (wanted) {
      _start();
    } else {
      _stop();
    }
  }

  void _start() {
    if (active) return;
    final fps = targetFps(_displayHz);
    game.pauseEngine();
    _clock
      ..reset()
      ..start();
    _last = 0;
    _timer = Timer.periodic(
      Duration(microseconds: (1e6 / fps).round()),
      (_) => _tick(),
    );
  }

  void _stop() {
    final t = _timer;
    if (t == null) return;
    t.cancel();
    _timer = null;
    if (!game.held) game.resumeEngine();
  }

  void _tick() {
    final now = _clock.elapsedMicroseconds;
    final dt = (now - _last) / 1e6;
    _last = now;
    // Duraklatılmışken (panel açık) zaman donar, kare çizilmez.
    if (game.held) return;
    game.stepEngine(stepTime: dt);
  }

  void dispose() => _stop();
}
