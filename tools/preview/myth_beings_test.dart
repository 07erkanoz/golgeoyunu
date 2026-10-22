// Gerçek siluetlerden çizilen Umay ağacı, Umay kuşu, Ak Ana, Ayaz Ata, Kam,
// Albastı. `flutter test tools/preview/myth_beings_test.dart`
// (build/gallery/mitoloji_varliklar.png)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/myth_figures.dart';

void main() {
  test('Mitoloji varlıkları', () async {
    final loader = FontLoader('Roboto');
    final f = File('/usr/share/fonts/noto/NotoSans-Regular.ttf');
    if (f.existsSync()) {
      loader.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
    }
    await loader.load();
    const w = 1800.0;
    const h = 1300.0;
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    c.drawRect(
      const ui.Rect.fromLTWH(0, 0, w, h),
      ui.Paint()
        ..shader = ui.Gradient.linear(
          const ui.Offset(0, 0),
          const ui.Offset(0, h),
          [
            const ui.Color(0xFF070A16),
            const ui.Color(0xFF16203A),
            const ui.Color(0xFF241E2A),
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
        ..layout(const ui.ParagraphConstraints(width: 440));
      c.drawParagraph(para, ui.Offset(cx - 220, y));
    }

    void draw(double x, double y, double s, void Function(ui.Canvas) fn) {
      c.save();
      c.translate(x, y);
      c.scale(s);
      fn(c);
      c.restore();
    }

    // Üst sıra: Umay ağacı (uyuyan, uyanmış) toprağın üstünde, kökleri altta.
    const g1 = 470.0;
    c.drawRect(
      const ui.Rect.fromLTWH(0, g1, w * 0.5, 150),
      ui.Paint()..color = const ui.Color(0xCC0A0806),
    );
    draw(w * 0.13, g1, 4.2, (c) => MythFigures.umayTree(c, 1.0, lit: 0));
    label('Umay ağacı · uyuyan', w * 0.13, g1 + 160);
    draw(w * 0.37, g1, 4.2, (c) => MythFigures.umayTree(c, 1.0, lit: 1));
    label('Umay ağacı · dokununca uyanır', w * 0.37, g1 + 160);
    draw(w * 0.63, 330, 3.2, (c) => MythFigures.umayBird(c, 1.0));
    label('Umay kuşu · süzülür', w * 0.63, 360);
    draw(w * 0.87, 420, 3.0, (c) => MythFigures.umayBird(c, 1.0, glide: false));
    label('Umay kuşu · iner', w * 0.87, 440);
    // Alt sıra.
    const g2 = 1170.0;
    c.drawRect(
      const ui.Rect.fromLTWH(0, g2, w, 6),
      ui.Paint()..color = const ui.Color(0xFF05060C),
    );
    final row = <(String, void Function(ui.Canvas))>[
      ('Ak Ana · ilk sudan yükselir', (c) => MythFigures.akAna(c, 1.0)),
      ('Ayaz Ata', (c) => MythFigures.ayazAta(c, 1.0)),
      ('Kam · davul çalar', (c) => MythFigures.kam(c, 0.88)),
      ('Albastı', (c) => MythFigures.albasti(c, 1.0)),
    ];
    for (var i = 0; i < row.length; i++) {
      final cx = w / 8 + i * w / 4;
      draw(cx, g2, 4.2, row[i].$2);
      label(row[i].$1, cx, g2 + 20);
    }
    final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/gallery').createSync(recursive: true);
    File('build/gallery/mitoloji_varliklar.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  });
}
