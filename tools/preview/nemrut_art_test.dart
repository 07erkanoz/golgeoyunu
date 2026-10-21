// Nemrut heykelleri tek başına: beş baş, kartal, oturan tanrı.
// `flutter test tools/preview/nemrut_art_test.dart` → build/gallery/nemrut_art.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/nemrut.dart';

void main() {
  test('nemrut heykelleri', () async {
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    c.drawRect(
      const ui.Rect.fromLTWH(0, 0, 1600, 900),
      ui.Paint()..color = const ui.Color(0xFF3A2A40),
    );
    var x = 120.0;
    for (final k in NemrutHead.values) {
      c.save();
      c.translate(x, 380);
      NemrutArt.head(c, k, 300);
      c.restore();
      x += 230;
    }
    c.save();
    c.translate(1300, 380);
    NemrutArt.eagle(c, 280);
    c.restore();
    c.save();
    c.translate(120, 860);
    c.scale(1.4);
    NemrutArt.seated(c);
    c.restore();
    c.save();
    c.translate(600, 860);
    c.scale(1.4);
    NemrutArt.seated(c, head: NemrutHead.antiochos);
    c.restore();
    c.drawLine(
      const ui.Offset(0, 860),
      const ui.Offset(1600, 860),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
    expect(kTile, 32);
    final img = await rec.endRecording().toImage(1600, 900);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/gallery').createSync(recursive: true);
    File('build/gallery/nemrut_art.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  });
}
