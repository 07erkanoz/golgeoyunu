// Yeni açılış perdesi baştan sona, sessiz taslak video için kareler.
// `flutter test tools/preview/acilis_video_test.dart --dart-define=CARTOON=true`
// → build/preview/acilis_video/%04d.png, sonra:
// `ffmpeg -framerate 15 -i build/preview/acilis_video/%04d.png -pix_fmt yuv420p acilis.mp4`
// Satır süreleri DURS ile (ör. seslerin süresi + 1,5).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/kukla.dart';
import 'package:golge/game/perde.dart';
import 'package:golge/game/shadow_art.dart';
import 'package:golge/game/tasvir_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('açılış videosu', () async {
    await TasvirImages.load();
    await ShadowArt.load();
    await SayeKukla.load();
    await (FontLoader(
      'Rakkas',
    )..addFont(rootBundle.load('assets/fonts/Rakkas-Regular.ttf'))).load();
    final dir = Directory('build/preview/acilis_video')
      ..createSync(recursive: true);
    for (final f in dir.listSync()) {
      f.deleteSync();
    }
    // FPS: kare hızı (varsayılan 15); BASLA: bu satırdan başla (0'dan).
    final fps = int.parse(Platform.environment['FPS'] ?? '15');
    // Satır süreleri (sn): DURS ortam değişkeninden (oyundaki gibi ses + 1,5;
    // başlık 5), yoksa her satır 8 sn.
    final durs = (Platform.environment['DURS'] ?? '8,8,8,8,8,8,8')
        .split(',')
        .map(double.parse)
        .toList();
    final total = durs.fold(0.0, (a, b) => a + b);
    final n = (total * fps).floor();
    final from = durs
        .take(int.parse(Platform.environment['BASLA'] ?? '0'))
        .fold(0.0, (a, b) => a + b);
    var shot = 0;
    for (var i = (from * fps).floor(); i < n; i++) {
      final t = i / fps;
      var line = 0;
      var start = 0.0;
      while (line < durs.length - 1 && t >= start + durs[line]) {
        start += durs[line];
        line++;
      }
      final progress = line + (t - start) / durs[line];
      final rec = ui.PictureRecorder();
      PerdePainter.paint(
        ui.Canvas(rec),
        const ui.Size(960, 540),
        PerdeScene.prologue,
        t,
        progress,
        1,
      );
      final img = await rec.endRecording().toImage(960, 540);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File(
        '${dir.path}/${(shot++).toString().padLeft(4, '0')}.png',
      ).writeAsBytesSync(png!.buffer.asUint8List());
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
