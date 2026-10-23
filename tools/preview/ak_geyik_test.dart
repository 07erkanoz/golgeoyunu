// Ak Geyik önizlemesi: yürüyüş kareleri, otlama, dikkat, sıçrayış.
// `flutter test tools/preview/ak_geyik_test.dart` → build/preview/ak_geyik.png
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/myth_figures.dart';

void main() {
  test('ak geyik', () async {
    const w = 1400.0, h = 520.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, h), const [
          Color(0xFF1E3A2E),
          Color(0xFF6E9466),
          Color(0xFFD2DCA0),
        ], const [0, 0.6, 1]),
    );
    void at(double x, double y, double s, void Function() f) {
      c.save();
      c.translate(x, y);
      c.scale(s);
      f();
      c.restore();
    }

    for (var i = 0; i < 6; i++) {
      at(120 + i * 210.0, 230, 1.3, () => MythFigures.akGeyik(c, i * 0.3, i / 6));
    }
    at(160, 480, 1.3, () => MythFigures.akGeyik(c, 0, 0, graze: 1, still: true));
    at(420, 480, 1.3, () => MythFigures.akGeyik(c, 0, 0, alert: 1, still: true));
    at(700, 480, 1.3, () => MythFigures.akGeyik(c, 0, 0.2, leap: 1));
    // Ölçek: oyundaki boyda (0.55) Sâye boyunda bir çubuk (28 px).
    at(1000, 480, 0.55 * 2, () => MythFigures.akGeyik(c, 0, 0.3));
    c.drawRect(
      const Rect.fromLTWH(1150, 480 - 56, 16, 56),
      Paint()..color = const Color(0xFF000000),
    );
    final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/preview').createSync(recursive: true);
    File('build/preview/ak_geyik.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}
