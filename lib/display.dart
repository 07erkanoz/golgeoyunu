import 'package:flutter/foundation.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'settings.dart';

/// Android'de ayara göre ekranın en yüksek (90/120 Hz ve üstü) ya da en
/// düşük (genellikle 60 Hz) yenileme hızı seçilir. Masaüstünde ekran zaten
/// kendi hızında çizilir.
Future<void> applyRefreshRate() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    if (Settings.highRefresh) {
      await FlutterDisplayMode.setHighRefreshRate();
      return;
    }
    await FlutterDisplayMode.setLowRefreshRate();
  } catch (_) {
    // Desteklemeyen cihazda varsayılan hız kalır.
  }
}
