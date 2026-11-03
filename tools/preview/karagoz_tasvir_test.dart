// Gerçek Karagöz ve Hacivat tasvirleriyle küçük güldürü, birkaç anı.
// `flutter test tools/preview/karagoz_tasvir_test.dart`
// → build/preview/karagoz_tasvir.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/perde.dart';
import 'package:golge/game/tasvir_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Karagöz tasvirleri', () async {
    await TasvirImages.load();
    expect(TasvirImages.ready, isTrue, reason: '${TasvirImages.lastError}');
    const times = [0.6, 1.5, 2.6, 3.7, 4.4, 5.4, 6.6];
    const cw = 420.0, ch = 320.0;
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    for (var i = 0; i < times.length; i++) {
      final o = ui.Offset((i % 4) * cw, (i ~/ 4) * ch);
      final r = ui.Rect.fromLTWH(o.dx + 6, o.dy + 6, cw - 12, ch - 12);
      c.drawRect(
        r,
        ui.Paint()
          ..shader = ui.Gradient.radial(r.center, cw * 0.6, const [
            ui.Color(0xFFF6D49A),
            ui.Color(0xFFB8803E),
          ]),
      );
      c.save();
      c.clipRect(r);
      paintKaragozHacivat(
        c,
        ui.Offset(r.center.dx, r.bottom - 10),
        230,
        times[i],
      );
      c.restore();
    }
    final img = await rec.endRecording().toImage(
      (cw * 4).toInt(),
      (ch * 2).toInt(),
    );
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/preview/karagoz_tasvir.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  });
}
