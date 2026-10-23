// Ana menünün önizlemesi (gerçek yazı tipiyle):
// `flutter test tools/preview/menu_preview_test.dart`
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/strings.dart';
import 'package:golge/main.dart';
import 'package:golge/settings.dart';

Future<void> _fonts() async {
  final loader = FontLoader('Roboto');
  for (final f in [
    'NotoSans-Regular.ttf',
    'NotoSans-Italic.ttf',
    'NotoSans-Black.ttf',
    'NotoSans-Light.ttf',
    'NotoSans-Bold.ttf',
  ]) {
    final file = File('/usr/share/fonts/noto/$f');
    if (file.existsSync()) {
      loader.addFont(
        Future.value(ByteData.view(file.readAsBytesSync().buffer)),
      );
    }
  }
  await loader.load();
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
    final img = await layer.toImage(const Rect.fromLTWH(0, 0, 1280, 720));
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/preview').createSync(recursive: true);
    File('build/preview/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('ana menü önizleme', (tester) async {
    await tester.runAsync(_fonts);
    S.lang = Lang.tr;
    Settings.unlocked = const int.fromEnvironment('UNLOCKED');
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(const GolgeApp());
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _shot(tester, 'ana_menu');
    Future<void> settle() async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.tap(find.text(S.of('about')).first);
    await settle();
    await _shot(tester, 'menu_hakkinda');
    await tester.tap(find.text(S.of('back')).last);
    await settle();
    await tester.tap(find.text(S.of('book')).first);
    await settle();
    await _shot(tester, 'menu_defter_hikaye');
    await tester.tap(find.text(S.of('memoriesTab')));
    await settle();
    await _shot(tester, 'menu_defter_hatira');
    await tester.tap(find.text(S.of('legendsTab')));
    await settle();
    await _shot(tester, 'menu_defter_efsane');
    await tester.tap(find.text(S.of('back')).last);
    await settle();
    if (Settings.unlocked >= 1) {
      await tester.tap(find.text(S.of('chapters')));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await _shot(tester, 'bolumler');
    }
  });
}
