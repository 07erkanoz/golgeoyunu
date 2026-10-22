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

  /// Karenin hazırlığı ya da ekran kartı işi bundan uzun sürerse "geç"
  /// sayılır (≈ 45 kare/sn altı). Kare başından ekrana çıkışa kadarki süre
  /// kullanılmaz: kareler üst üste işlendiği için akıcı oyunda da uzar.
  static const int slowMicros = 22000;

  /// Bu kadar kare toplanınca karar verilir.
  static const int window = 240;

  /// Pencerede geç karelerin oranı bunu aşarsa bir kademe düşülür.
  static const double slowShare = 0.3;

  /// Bölüm başında ya da bir kademe düşüldükten sonra ölçülmeyen süre
  /// (yükleme, önbellek doldurma, ekran kartının ilk gölgelendirici
  /// derlemeleri).
  static const double settle = 6;

  /// Kademe düşmek için üst üste bu kadar yavaş pencere gerekir (kısa bir
  /// takılma ayarları düşürmesin).
  static const int slowWindows = 2;

  /// Oyuncu ayarı elle değiştirdi: bu oturumda kendiliğinden düşürme yok.
  static bool userChose = false;

  bool _listening = false;
  double _wait = settle;
  int _frames = 0;
  int _slow = 0;
  int _slowRun = 0;

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
    _slowRun = 0;
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
      final work = t.buildDuration > t.rasterDuration
          ? t.buildDuration
          : t.rasterDuration;
      if (work.inMicroseconds > slowMicros) _slow++;
    }
    if (_frames < window) return;
    final share = _slow / _frames;
    _frames = 0;
    _slow = 0;
    _slowRun = share > slowShare ? _slowRun + 1 : 0;
    if (_slowRun >= slowWindows) stepDown();
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
