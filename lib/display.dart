import 'package:flutter/foundation.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

/// Android'de ekran standart (en düşük, genellikle 60 Hz) yenileme hızında
/// tutulur. Yüksek yenileme hızı seçeneği kaldırıldı. Masaüstünde ekran
/// zaten kendi hızında çizilir.
Future<void> applyRefreshRate() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await FlutterDisplayMode.setLowRefreshRate();
  } catch (_) {
    // Desteklemeyen cihazda varsayılan hız kalır.
  }
}
