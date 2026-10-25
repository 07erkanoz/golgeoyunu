// Oyunun açılış girişi: telefon boyunda anlar.
// `flutter test tools/preview/giris_intro_test.dart` → build/preview/intro_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/perde.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  test('giriş anları', () async {
    PerdePainter.debugFontFamily = 'Roboto';
    const size = Size(870, 391);
    // Menüde perdenin yeri (bu ekran boyunda, main_menu.dart düzeninden).
    const menu = Rect.fromLTWH(54.8, 61, 408, 253);
    final times = (Platform.environment['ANLAR'] ?? '1.0,2.2,3.6,5.2,6.7,8.7,9.7,10.6,11.7')
        .split(',')
        .map(double.parse);
    var n = 0;
    for (final t in times) {
      final rec = ui.PictureRecorder();
      PerdePainter.paintIntro(
        Canvas(rec),
        size,
        t,
        'GÖLGE OYUNU',
        'Hayal perdesinde bir gölgenin yolculuğu',
        target: menu,
        creditLabel: 'Hayalî',
        creditName: 'Erkan Öz',
      );
      final img = await rec.endRecording().toImage(870, 391);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/intro_${n++}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }
  });
}
