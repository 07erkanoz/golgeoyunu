import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/kukla.dart';
import 'package:golge/game/perde.dart';
import 'package:golge/game/shadow_art.dart';
import 'package:golge/game/tasvir_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('kamera', () async {
    await TasvirImages.load();
    await ShadowArt.load();
    await SayeKukla.load();
    final out = ui.PictureRecorder();
    final oc = ui.Canvas(out);
    Future<void> run(int row, PerdeScene scene, int? bridge, List<double> at, double end, double lineLen) async {
      var k = 0;
      for (var i = 0; i <= (end * 60).round(); i++) {
        final t = i / 60;
        final rec = ui.PictureRecorder();
        PerdePainter.paint(ui.Canvas(rec), const ui.Size(960, 540), scene, t, t / lineLen, 1, bridge: bridge);
        final pic = rec.endRecording();
        if (k < at.length && t >= at[k]) {
          oc.save();
          oc.translate(k * 320.0, row * 180.0);
          oc.scale(1 / 3);
          oc.drawPicture(pic);
          oc.restore();
          k++;
        }
      }
    }
    await run(0, PerdeScene.galata, 0, [2, 6, 10, 13], 14, 10.5);
    await run(1, PerdeScene.prologue, null, [44, 50, 55, 62], 63, 8);
    await run(2, PerdeScene.mirror, null, [2, 6, 9, 12], 13, 10.5);
    final img = await out.endRecording().toImage(1280, 540);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/preview/kamera.png').writeAsBytesSync(png!.buffer.asUint8List());
  }, timeout: const Timeout(Duration(minutes: 10)));
}
