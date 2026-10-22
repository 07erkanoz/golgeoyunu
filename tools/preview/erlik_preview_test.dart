// Erlik'in Katı varlıkları: Körmös, Çalkuyruk, kut kafesi.
// `flutter test tools/preview/erlik_preview_test.dart` (build/gallery/erlik_varliklar.png)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/myth_figures.dart';

void main() {
  test('Erlik varlıkları', () async {
    final loader = FontLoader('Roboto');
    final f = File('/usr/share/fonts/noto/NotoSans-Regular.ttf');
    if (f.existsSync()) {
      loader.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
    }
    await loader.load();
    const w = 1600.0;
    const h = 700.0;
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    c.drawRect(
      const ui.Rect.fromLTWH(0, 0, w, h),
      ui.Paint()
        ..shader = ui.Gradient.linear(
          const ui.Offset(0, 0),
          const ui.Offset(0, h),
          [
            const ui.Color(0xFF0E0A14),
            const ui.Color(0xFF1C1424),
            const ui.Color(0xFF08060A),
          ],
          [0, 0.6, 1],
        ),
    );
    void label(String s, double cx, double y) {
      final pb =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(
                fontSize: 22,
                fontFamily: 'Roboto',
                textAlign: ui.TextAlign.center,
              ),
            )
            ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFD8E2F0)))
            ..addText(s);
      final para = pb.build()
        ..layout(const ui.ParagraphConstraints(width: 400));
      c.drawParagraph(para, ui.Offset(cx - 200, y));
    }

    const g = 560.0;
    c.drawRect(
      const ui.Rect.fromLTWH(0, g, w, 8),
      ui.Paint()..color = const ui.Color(0xFF050307),
    );
    void draw(double x, double y, double s, void Function(ui.Canvas) fn) {
      c.save();
      c.translate(x, y);
      c.scale(s);
      fn(c);
      c.restore();
    }

    draw(200, g, 3.4, (c) => MythFigures.kormos(c, 1.0));
    draw(470, g, 3.4, (c) => MythFigures.kormos(c, 2.2, reach: 1));
    label('Körmös · bekler / ışığa uzanır', 335, g + 20);
    draw(860, g, 3.6, (c) => MythFigures.calkuyruk(c, 1.0));
    label('Çalkuyruk', 860, g + 20);
    draw(1230, g, 5, (c) => MythFigures.kutCage(c, 1.0));
    draw(1430, g, 5, (c) => MythFigures.kutCage(c, 1.0, open: 1));
    label('Kut kafesi · dolu / açılmış', 1330, g + 20);
    final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/gallery').createSync(recursive: true);
    File('build/gallery/erlik_varliklar.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  });
}
