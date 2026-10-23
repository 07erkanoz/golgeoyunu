// Ayarlar sayfasının önizlemesi (gerçek yazı tipiyle), her sekme:
// `flutter test tools/preview/ayarlar_preview_test.dart`
// → build/preview/ayarlar_<boyut>_<sekme>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/strings.dart';
import 'package:golge/main.dart';

Future<void> _fonts() async {
  final loader = FontLoader('Roboto');
  for (final f in [
    'NotoSans-Regular.ttf',
    'NotoSans-Italic.ttf',
    'NotoSans-Light.ttf',
    'NotoSans-Bold.ttf',
  ]) {
    final file = File('/usr/share/fonts/noto/$f');
    if (file.existsSync()) {
      loader.addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
    }
  }
  await loader.load();
}

void main() {
  for (final (label, size) in [
    ('masaustu', const Size(1280, 720)),
    ('telefon', const Size(870, 391)),
  ]) {
    testWidgets('ayarlar $label', (tester) async {
      await tester.runAsync(_fonts);
      S.lang = Lang.tr;
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(const GolgeApp());
      Future<void> settle() async {
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      Future<void> shot(String name) async {
        await tester.runAsync(() async {
          final layer =
              tester.binding.renderViews.first.debugLayer! as OffsetLayer;
          final img = await layer.toImage(Offset.zero & size);
          final png = await img.toByteData(format: ui.ImageByteFormat.png);
          File(
            'build/preview/ayarlar_${label}_$name.png',
          ).writeAsBytesSync(png!.buffer.asUint8List());
        });
      }

      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(find.text(S.of('settings')).first);
      await settle();
      for (final tab in [
        'tabSound',
        'tabDisplay',
        'tabGame',
        'tabLicenses',
      ]) {
        await tester.tap(find.text(S.of(tab)).last);
        await settle();
        await shot(tab);
      }
    });
  }
}
