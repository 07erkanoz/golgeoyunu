import 'package:flutter/foundation.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'settings.dart';

/// Telefon 90/120 Hz ve üstünü destekliyorsa ayara göre en yüksek ya da
/// en düşük yenileme hızını seçer. Masaüstünde ekran zaten kendi hızında
/// çizilir.
Future<void> applyRefreshRate() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    if (Settings.highRefresh) {
      await FlutterDisplayMode.setHighRefreshRate();
    } else {
      await FlutterDisplayMode.setLowRefreshRate();
    }
  } catch (_) {
    // Desteklemeyen cihazda varsayılan hız kalır.
  }
}
