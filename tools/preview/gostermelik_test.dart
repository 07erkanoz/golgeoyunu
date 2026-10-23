// Göstermelik önizlemesi: perde başlıkları deri levha olarak.
// `flutter test tools/preview/gostermelik_test.dart`
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/perde.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Roboto');
    for (final f in ['NotoSans-Black.ttf', 'NotoSans-Regular.ttf']) {
      final file = File('/usr/share/fonts/noto/$f');
      if (file.existsSync()) {
        loader.addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
      }
    }
    await loader.load();
    PerdePainter.debugFontFamily = 'Roboto';
  });
  for (final (name, title, k) in [
    ('gostermelik_1', 'BEŞİNCİ PERDE · ÖTÜKEN', 1.0),
    ('gostermelik_2', 'XIV · ÖTÜKEN ORMANI', 1.0),
    ('gostermelik_3', 'XIV · ÖTÜKEN ORMANI', 0.45),
  ]) {
    test(name, () async {
      const size = Size(1280, 720);
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      PerdePainter.paint(c, size, PerdeScene.otuken, 3, 3.5, 1);
      PerdePainter.gostermelik(c, PerdePainter.screenRect(size), title, 3, k);
      final img = await rec.endRecording().toImage(1280, 720);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      Directory('build/preview').createSync(recursive: true);
      File('build/preview/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }
}
