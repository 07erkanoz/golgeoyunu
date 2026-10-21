// Mitoloji taslakları: Umay ağacı, Gökbörü, Ak Ana, Tulpar, Umay kuşu, Kam,
// Ayaz Ata, Albastı. `flutter test tools/preview/myth_preview_test.dart`
// (çıktı: build/gallery/mitoloji.png)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/myth.dart';

Future<void> _fonts() async {
  final loader = FontLoader('Roboto');
  final file = File('/usr/share/fonts/noto/NotoSans-Regular.ttf');
  if (file.existsSync()) {
    loader.addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
  }
  await loader.load();
}

void main() {
  test('mitoloji taslakları', () async {
    await _fonts();
    const w = 1600.0;
    const h = 900.0;
    const t = 1.3;
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    // Perde: kandille aydınlanan sıcak bez.
    c.drawRect(
      const ui.Rect.fromLTWH(0, 0, w, h),
      ui.Paint()
        ..shader = ui.Gradient.radial(
          const ui.Offset(w / 2, h / 2),
          w * 0.7,
          [
            const ui.Color(0xFFE8B070),
            const ui.Color(0xFF8A4A22),
            const ui.Color(0xFF2A140A),
          ],
          [0, 0.55, 1],
        ),
    );
    final items = <(String, double, void Function(ui.Canvas))>[
      ('Umay ağacı (uyanmış)', 1.15, (c) => MythPainter.umayTree(c, t)),
      ('Gökbörü', 1.25, (c) => MythPainter.gokboru(c, t, step: 0.2)),
      ('Ak Ana', 1.1, (c) => MythPainter.akAna(c, t)),
      ('Tulpar', 1.05, (c) => MythPainter.tulpar(c, t)),
      ('Umay kuşu (Hüma)', 1.2, (c) => MythPainter.umayBird(c, t)),
      ('Kam ve davulu', 1.25, (c) => MythPainter.kam(c, t)),
      ('Ayaz Ata', 1.1, (c) => MythPainter.ayazAta(c, t)),
      ('Albastı', 1.1, (c) => MythPainter.albasti(c, t)),
    ];
    for (var i = 0; i < items.length; i++) {
      final (name, scale, draw) = items[i];
      final cx = (i % 4) * w / 4 + w / 8;
      final base = (i ~/ 4) * h / 2 + h / 2 - 60;
      c.save();
      c.translate(cx, base);
      c.scale(scale);
      draw(c);
      c.restore();
      final pb =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(
                fontSize: 18,
                fontFamily: 'Roboto',
                textAlign: ui.TextAlign.center,
              ),
            )
            ..pushStyle(ui.TextStyle(color: const ui.Color(0xFF1A0B05)))
            ..addText(name);
      final para = pb.build()
        ..layout(const ui.ParagraphConstraints(width: w / 4));
      c.drawParagraph(para, ui.Offset(cx - w / 8, base + 22));
    }
    final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/gallery').createSync(recursive: true);
    File('build/gallery/mitoloji.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  });
}
