// Ayarlar panelinin önizlemesi (masaüstü ve dokunmatik):
// `flutter test tools/preview/settings_preview_test.dart`
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/strings.dart';
import 'package:golge/ui/settings_panel.dart';

Future<void> _font() async {
  final loader = FontLoader('Preview');
  final data = File('/usr/share/fonts/noto/NotoSans-Regular.ttf')
      .readAsBytesSync();
  loader.addFont(Future.value(ByteData.view(data.buffer)));
  await loader.load();
  final icons = FontLoader('MaterialIcons');
  final iconPath =
      '${Platform.environment['FLUTTER_ROOT'] ?? ''}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
  if (File(iconPath).existsSync()) {
    icons.addFont(
      Future.value(ByteData.view(File(iconPath).readAsBytesSync().buffer)),
    );
    await icons.load();
  }
}

void main() {
  for (final (name, touch) in [
    ('ayarlar_masaustu', false),
    ('ayarlar_dokunmatik', true),
  ]) {
    testWidgets('$name önizleme', (tester) async {
      await tester.runAsync(_font);
      S.lang = Lang.tr;
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Preview'),
          ),
          home: DefaultTextStyle(
            style: const TextStyle(fontFamily: 'Preview'),
            child: RepaintBoundary(
              key: key,
              child: Container(
                color: const Color(0xFF0A0706),
                child: Material(
                  type: MaterialType.transparency,
                  child: SettingsPanel(
                    game: GolgeGame(),
                    canFullscreen: !touch,
                    onFullscreen: (_) {},
                    onLanguage: () {},
                    canTouch: touch,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await boundary.toImage();
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        Directory('build/preview').createSync(recursive: true);
        File('build/preview/$name.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      });
    });
  }
}
