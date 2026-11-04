// Bir köprü perdesi baştan sona, saniyede FPS kare: Sâye'nin perdede
// yürüyüşünü (adımın ilerleyişe uyması, ayağın kaymaması) denetlemek için.
// `KOPRU=8 SATIR=3 SURE=8 flutter test tools/preview/perde_yuruyus_test.dart
// --dart-define=CARTOON=true` → build/preview/perde_yuruyus/%04d.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/kukla.dart';
import 'package:golge/game/perde.dart';
import 'package:golge/game/shadow_art.dart';
import 'package:golge/game/tasvir_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('perde yürüyüşü', () async {
    await TasvirImages.load();
    await ShadowArt.load();
    await SayeKukla.load();
    final env = Platform.environment;
    final bridge = int.parse(env['KOPRU'] ?? '8');
    final lines = int.parse(env['SATIR'] ?? '3');
    final secs = double.parse(env['SURE'] ?? '8');
    final fps = int.parse(env['FPS'] ?? '30');
    final dir = Directory('build/preview/perde_yuruyus')
      ..createSync(recursive: true);
    for (final f in dir.listSync()) {
      f.deleteSync();
    }
    final n = (lines * secs * fps).round();
    for (var i = 0; i < n; i++) {
      final t = i / fps;
      final rec = ui.PictureRecorder();
      PerdePainter.paint(
        ui.Canvas(rec),
        const ui.Size(960, 540),
        PerdeScene.prologue,
        t,
        t / secs,
        1,
        bridge: bridge,
        bridgeLines: lines,
      );
      final img = await rec.endRecording().toImage(960, 540);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('${dir.path}/${i.toString().padLeft(4, '0')}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
