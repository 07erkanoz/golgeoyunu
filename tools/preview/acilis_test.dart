// Yeni açılış perdesinin sahneleri (docs/oneri/ACILIS_PERDESI.md).
// `flutter test tools/preview/acilis_test.dart` → build/preview/acilis_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/perde.dart';
import 'package:golge/game/shadow_art.dart';
import 'package:golge/game/tasvir_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('açılış perdesi', () async {
    await TasvirImages.load();
    await ShadowArt.load();
    expect(TasvirImages.saye, isNotNull, reason: TasvirImages.lastError);
    // Başlık için yazı tipi (oyunda sistemin yazı tipi).
    final loader = FontLoader('Roboto');
    for (final f in ['NotoSans-Black.ttf', 'NotoSans-Regular.ttf']) {
      final file = File('/usr/share/fonts/noto/$f');
      if (file.existsSync()) {
        loader.addFont(
          Future.value(ByteData.view(file.readAsBytesSync().buffer)),
        );
      }
    }
    await loader.load();
    PerdePainter.debugFontFamily = 'Roboto';
    // Başlığın gömülü yazı tipi (oyunda pubspec'ten gelir).
    await (FontLoader(
      'Rakkas',
    )..addFont(rootBundle.load('assets/fonts/Rakkas-Regular.ttf'))).load();
    Directory('build/preview').createSync(recursive: true);
    // Satır başına 8 saniye.
    const at = [
      0.02, 0.04, 0.12, 0.3, 0.5, 0.62, 0.7, 0.9, //
      1.05, 1.2, 1.4, 1.55, 1.7, 1.9, //
      2.06, 2.2, 2.3, 2.5, 2.55, 2.68, 2.8, 2.92, //
      3.06, 3.12, 3.2, 3.3, 3.45, 3.6, 3.75, 3.9, //
      4.1, 4.3, 4.45, 4.6, 4.75, 4.92, //
      5.08, 5.15, 5.25, 5.33, 5.4, 5.5, 5.6, 5.7, 5.76, 5.85, 5.95, //
      6.05, 6.2, 6.35, 6.5, 6.65, 6.8, 6.95,
    ];
    for (var i = 0; i < at.length; i++) {
      final rec = ui.PictureRecorder();
      PerdePainter.paint(
        ui.Canvas(rec),
        const ui.Size(1280, 720),
        PerdeScene.prologue,
        at[i] * 8,
        at[i],
        1,
      );
      final img = await rec.endRecording().toImage(1280, 720);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/acilis_$i.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }
  });
}
