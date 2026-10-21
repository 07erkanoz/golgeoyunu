// Gemi hayvanları: oyma heykel ve duvar gölgesi.
// `flutter test tools/preview/ark_animals_test.dart` → build/gallery/gemi_hayvanlar.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/ark_animals.dart';

void main() {
  test('gemi hayvanları', () async {
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    c.drawRect(const ui.Rect.fromLTWH(0, 0, 1800, 760), ui.Paint()..color = const ui.Color(0xFF3A2414));
    var x = 150.0;
    for (final k in ArkAnimal.kinds) {
      c.save();
      c.translate(x, 340);
      c.scale(2.6);
      drawCarvedAnimal(c, k);
      c.restore();
      c.save();
      c.translate(x, 700);
      c.scale(2.6);
      drawAnimalShadow(c, k, const ui.Color(0xCC0A0503));
      c.restore();
      x += 290;
    }
    final img = await rec.endRecording().toImage(1800, 760);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/gallery').createSync(recursive: true);
    File('build/gallery/gemi_hayvanlar.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}
