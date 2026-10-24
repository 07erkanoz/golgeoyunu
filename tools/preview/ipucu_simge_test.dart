// İpucu simgesi: yanık, "ben buradayım" anında ve ilk yanıştaki balonla;
// dokununca üstte görünen ipucu.
// `flutter test tools/preview/ipucu_simge_test.dart` → build/preview/ipucu_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/settings.dart';
import 'package:golge/ui/hint_button.dart';

void main() {
  testWidgets('ipucu simgesi', (tester) async {
    final bytes = File('/usr/share/fonts/noto/NotoSans-Regular.ttf')
        .readAsBytesSync();
    await (FontLoader(
      'Roboto',
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
    final icons = File(
      '/home/erkanoz/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ).readAsBytesSync();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.view(icons.buffer)))).load();
    tester.view.physicalSize = const Size(870, 391);
    tester.view.devicePixelRatio = 1;
    final game = GolgeGame();
    Settings.hintIntroSeen = false;
    final key = GlobalKey();
    final loaded = ValueNotifier(false);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Roboto'),
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: key,
          child: Stack(
            children: [
              GameWidget(game: game),
              ValueListenableBuilder<bool>(
                valueListenable: loaded,
                builder: (context, on, _) => !on
                    ? const SizedBox.shrink()
                    : Positioned(
                        top: 4,
                        right: 164,
                        child: Material(
                          type: MaterialType.transparency,
                          child: HintButton(game: game, touch: true),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    });
    await tester.runAsync(() => game.loaded);
    game.debugLoadLevel(0);
    await tester.runAsync(() => game.ready());
    loaded.value = true;
    await tester.pump();
    for (var i = 0; i < 120; i++) {
      game.update(1 / 60);
    }
    game.narration.resetScene();
    game.narration.hint(
      'yukarı sürükle Tırman · bırakmak için yön + sağ yarıya dokun',
    );
    var n = 0;
    Future<void> shot() async {
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage();
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('build/preview/ipucu_${n++}.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      });
    }

    // Balonla ilk yanış; "ben buradayım" anı; dokununca ipucu.
    await tester.pump(const Duration(milliseconds: 420));
    await shot();
    await tester.pump(const Duration(milliseconds: 2000));
    await shot();
    game.narration.revealHint();
    game.update(0.6);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await shot();
    await tester.pump(const Duration(seconds: 10));
  });
}
