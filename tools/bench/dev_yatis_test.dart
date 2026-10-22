// Devrilmiş kuklanın yatış ölçüsü: her sütunda gövdenin üst kenarı (köprü
// yüksekliğini çizime oturtmak için). `flutter test tools/bench/dev_yatis_test.dart`
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/giant_puppet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('yatış', () async {
    final puppet = await GiantPuppet.load();
    for (final facing in [1, -1]) {
      for (final ph in [0.0, 13.0, 28.0, 41.0]) {
        puppet.walk(ph);
        final p = puppet.pose();
        const s = GiantPuppet.scale;
        const px = GiantPuppet.pivotX * s;
        final rec = ui.PictureRecorder();
        final c = ui.Canvas(rec);
        // Zemin y=300, devin ortası x=100.
        c.translate(100 + px, 300);
        c.rotate(GiantPuppet.fallAngle(1, 5));
        c.translate(-px, 0);
        c.scale(facing * s, s);
        puppet.drawPose(c, p);
        final img = await rec.endRecording().toImage(600, 320);
        final bytes = (await img.toByteData())!;
        int? top(int x) {
          for (var y = 0; y < 320; y++) {
            if (bytes.getUint8((y * 600 + x) * 4 + 3) > 40) return y;
          }
          return null;
        }
        var minX = 600, maxX = 0;
        final tops = <String>[];
        for (var x = 0; x < 600; x++) {
          final t = top(x);
          if (t == null) continue;
          minX = x < minX ? x : minX;
          maxX = x > maxX ? x : maxX;
          if (x % 25 == 0) tops.add('${x - 100}:${300 - t}');
        }
        // ignore: avoid_print
        print('yön $facing evre $ph: x ${minX - 100}..${maxX - 100}  üst $tops');
      }
    }
  });
}
