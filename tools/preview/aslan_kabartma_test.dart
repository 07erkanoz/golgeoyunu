// Aslan Horoskobu kabartması, büyük boyda.
// `flutter test tools/preview/aslan_kabartma_test.dart` → build/preview/aslan.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/nemrut.dart';

void main() {
  test('aslan', () async {
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    c.drawRect(
      const ui.Rect.fromLTWH(0, 0, 840, 620),
      ui.Paint()..color = const ui.Color(0xFF241C2C),
    );
    c.translate(36, 580);
    c.scale(4);
    HoroscopeRelief(Vector2.zero()).render(c);
    final img = await rec.endRecording().toImage(840, 620);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/preview/aslan.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}
