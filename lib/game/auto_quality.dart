import 'package:flutter/scheduler.dart';

import '../settings.dart';
import 'golge_game.dart';
import 'palette.dart';
import 'realism.dart';
import 'strings.dart';

/// Otomatik kalite: cihaz zorlanırsa (kareler uzun süre geç çiziliyorsa)
/// önce ışık ve derinlik, o da yetmezse ağır grafik katmanları kendiliğinden
/// kapanır. Zayıf ekran kartları ve ısınıp yavaşlayan telefonlar için.
///
/// Oyuncu ayarlardan bir şeyi elle yeniden açarsa o oturumda bir daha
/// karışılmaz.
class AutoQuality {
  AutoQuality(this.game);

  final GolgeGame game;

  /// Bir kare bundan uzun sürerse "geç" sayılır (≈ 40 kare/sn altı).
  static const int slowMicros = 25000;

  /// Bu kadar kare toplanınca karar verilir.
  static const int window = 240;

  /// Pencerede geç karelerin oranı bunu aşarsa bir kademe düşülür.
  static const double slowShare = 0.3;

  /// Bölüm başında ya da bir kademe düşüldükten sonra ölçülmeyen süre
  /// (yükleme, önbellek doldurma).
  static const double settle = 3;

  /// Oyuncu ayarı elle değiştirdi: bu oturumda kendiliğinden düşürme yok.
  static bool userChose = false;

  bool _listening = false;
  double _wait = settle;
  int _frames = 0;
  int _slow = 0;

  bool get _measuring =>
      Settings.autoQuality &&
      !userChose &&
      !game.menuMode.value &&
      !game.paused &&
      !game.cinematic &&
      game.player != null;

  void attach() {
    if (_listening) return;
    try {
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
      _listening = true;
    } catch (_) {
      // Uygulama dışı (yalın oyun testleri): kare ölçümü yok.
    }
  }

  void detach() {
    if (!_listening) return;
    _listening = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
  }

  /// Bölüm yüklenince: ilk saniyeler sayılmaz.
  void restart() {
    _wait = settle;
    _frames = 0;
    _slow = 0;
  }

  void tick(double dt) {
    if (!_measuring) {
      _wait = settle;
      return;
    }
    if (_wait > 0) _wait -= dt;
  }

  void _onTimings(List<FrameTiming> timings) {
    if (!_measuring || _wait > 0) return;
    for (final t in timings) {
      _frames++;
      if (t.totalSpan.inMicroseconds > slowMicros) _slow++;
    }
    if (_frames < window) return;
    final share = _slow / _frames;
    _frames = 0;
    _slow = 0;
    if (share > slowShare) stepDown();
  }

  /// Bir kademe düşer; düşülecek bir şey kalmadıysa false.
  bool stepDown() {
    if (Realism.on && realismHere(game)) {
      Realism.on = false;
      game.narration.whisper(S.of('autoQualityLight'));
    } else if (!Settings.lowGraphics) {
      Settings.lowGraphics = true;
      Settings.save();
      game.narration.whisper(S.of('autoQualityLow'));
    } else {
      return false;
    }
    restart();
    return true;
  }
}
