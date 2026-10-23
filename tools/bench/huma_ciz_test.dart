import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/myth_figures.dart';

void main() {
  test('hüma çiz', () async {
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    c.drawRect(const ui.Rect.fromLTWH(0, 0, 900, 360), ui.Paint()..color = const ui.Color(0xFF203048));
    c.save();
    c.translate(200, 250);
    c.scale(3);
    MythFigures.umayBird(c, 1.0);
    c.restore();
    c.save();
    c.translate(650, 330);
    c.scale(3);
    MythFigures.umayBird(c, 1.0, glide: false);
    c.restore();
    final img = await rec.endRecording().toImage(900, 360);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/preview/huma_simdi.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}
