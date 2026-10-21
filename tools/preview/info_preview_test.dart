// Hikâye ve Hakkında sayfalarının önizlemesi (gerçek yazı tipiyle):
// `flutter test tools/preview/info_preview_test.dart`
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/settings.dart';
import 'package:golge/ui/info_pages.dart';

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
  for (final (name, page) in [
    ('hikaye', const StoryPage()),
    ('hakkinda', const AboutPage()),
    ('defter', const MemoryBookPage(memories: {'0:0', '0:2', '1:0', '2:1'})),
  ]) {
    testWidgets('$name önizleme', (tester) async {
      await tester.runAsync(_font);
      Settings.unlocked = 2;
      tester.view.physicalSize = const Size(460, 1100);
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
                color: const Color(0xFF140C09),
                padding: const EdgeInsets.all(28),
                child: SingleChildScrollView(child: page),
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
