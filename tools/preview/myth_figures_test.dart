// Gerçek siluetlerden çizilen Gökbörü ve Tulpar.
// `flutter test tools/preview/myth_figures_test.dart` (build/gallery/gokboru_tulpar.png)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/myth_figures.dart';

void main() {
  test('Gökbörü ve Tulpar', () async {
    final loader = FontLoader('Roboto');
    final f = File('/usr/share/fonts/noto/NotoSans-Regular.ttf');
    if (f.existsSync())
      loader.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
    await loader.load();
    const w = 1800.0;
    const h = 1150.0;
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    // Gece bozkırı: koyu gök, ufukta soluk ışık.
    c.drawRect(
      const ui.Rect.fromLTWH(0, 0, w, h),
      ui.Paint()
        ..shader = ui.Gradient.linear(
          const ui.Offset(0, 0),
          const ui.Offset(0, h),
          [
            const ui.Color(0xFF070A16),
            const ui.Color(0xFF16203A),
            const ui.Color(0xFF2A2A3A),
          ],
          [0, 0.7, 1],
        ),
    );
    void ground(double y) => c.drawRect(
      ui.Rect.fromLTWH(0, y, w, 6),
      ui.Paint()..color = const ui.Color(0xFF05060C),
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
        ..layout(const ui.ParagraphConstraints(width: 560));
      c.drawParagraph(para, ui.Offset(cx - 280, y));
    }

    ground(470);
    final poses = [
      (WolfPose.walk, 'Gökbörü · yol gösterirken'),
      (WolfPose.stand, 'Gökbörü · bekler'),
      (WolfPose.howl, 'Gökbörü · uluma (yardım)'),
    ];
    for (var i = 0; i < 3; i++) {
      final cx = w / 6 + i * w / 3;
      c.save();
      c.translate(cx, 470);
      c.scale(3.6);
      MythFigures.gokboru(c, 1.3 + i, pose: poses[i].$1);
      c.restore();
      label(poses[i].$2, cx, 490);
    }
    ground(1030);
    c.save();
    c.translate(w * 0.36, 1030);
    c.scale(3.7);
    MythFigures.tulpar(c, 0.6);
    c.restore();
    label('Tulpar · kanatlı at', w * 0.36, 1050);
    // Pençe izleri: örtülü kavanozla görünen yol.
    for (var i = 0; i < 6; i++) {
      c.save();
      c.translate(w * 0.68 + i * 70, 1010 - (i.isOdd ? 14 : 0));
      c.scale(3);
      MythFigures.pawPrint(c, 0.35 + i * 0.12);
      c.restore();
    }
    label('Gökbörü\'nün izleri (kavanoz örtülüyken)', w * 0.8, 1050);
    final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/gallery').createSync(recursive: true);
    File('build/gallery/gokboru_tulpar.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  });
}
