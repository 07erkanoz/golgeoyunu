import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';

/// Kare ölçümü (geliştirici göstergesi ve FPSLOG): son karelerin çizim işi.
///
/// Eskiden "otomatik kalite" de buradaydı: kareler uzun süre geç çizilince
/// ışığı ve grafiği kendiliğinden düşürüyordu. Telefonda sık sık gereksiz
/// yere kalite düşürdüğü için kaldırıldı; kalite yalnız oyuncunun ayarıdır.
class FrameMeter {
  bool _listening = false;

  /// Son karelerin ortalama çizim işi (ms): ölçüm göstergesi için.
  double workMs = 0;

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

  // Geliştirici ölçümü: saniyede çizilen kare sayısı (FPSLOG).
  static const _fpsLog =
      bool.fromEnvironment('DEV') && bool.fromEnvironment('FPSLOG');
  int _logFrames = 0;
  final _logClock = Stopwatch()..start();
  int _steps = 0;

  /// Oyun adımı sayacı (ölçüm için).
  void countStep() {
    if (_fpsLog) _steps++;
  }

  void _onTimings(List<FrameTiming> timings) {
    if (_fpsLog) {
      _logFrames += timings.length;
      final s = _logClock.elapsedMilliseconds / 1000;
      if (s >= 5) {
        // ignore: avoid_print
        print(
          '[kare] çizilen ${(_logFrames / s).toStringAsFixed(1)}/sn, '
          'oyun adımı ${(_steps / s).toStringAsFixed(1)}/sn, çizici '
          '${ui.ImageFilter.isShaderFilterSupported ? 'Impeller' : 'Skia'}',
        );
        _logFrames = 0;
        _steps = 0;
        _logClock.reset();
      }
    }
    for (final t in timings) {
      final w = t.buildDuration > t.rasterDuration
          ? t.buildDuration
          : t.rasterDuration;
      workMs = workMs * 0.9 + w.inMicroseconds / 1000 * 0.1;
    }
  }
}
