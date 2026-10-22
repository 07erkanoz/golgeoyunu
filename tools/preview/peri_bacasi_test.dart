// Peri bacası silueti tek başına: üçlü öbek ve tek bacalar.
// `flutter test tools/preview/peri_bacasi_test.dart` → build/preview/peri_bacasi.png
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/fairy_chimney.dart';

void main() {
  test('peri_bacasi', () async {
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    c.drawRect(
      const ui.Rect.fromLTWH(0, 0, 1600, 700),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
    const tones = ChimneyTones(
      ui.Color(0xFF241F1C),
      ui.Color(0xFF241F1C),
      ui.Color(0xFF241F1C),
    );
    drawFairyCluster(
      c,
      const ui.Offset(330, 650),
      500,
      tones,
      math.Random(1),
      openings: 1,
      lit: const ui.Color(0xFFE6E6E6),
    );
    for (var k = 0; k < 3; k++) {
      drawFairyCluster(
        c,
        ui.Offset(800 + k * 280.0, 650),
        450,
        tones,
        math.Random(k),
        peaks: 1,
        openings: 1,
        lit: const ui.Color(0xFFE6E6E6),
      );
    }
    final img = await rec.endRecording().toImage(1600, 700);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/preview').createSync(recursive: true);
    File('build/preview/peri_bacasi.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  });
}
