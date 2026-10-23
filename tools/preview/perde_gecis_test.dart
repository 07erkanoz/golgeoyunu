// Perdeden dünyaya geçiş: perdenin son karesi Sâye'ye doğru büyüyüp
// çözülür. `flutter test tools/preview/perde_gecis_test.dart`
// → build/preview/gecis_<n>.png ve docs/onizleme/perde_gecis.jpg için kareler.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/perde.dart';

void main() {
  setUpAll(() async {
    final bytes = File(
      '/usr/share/fonts/noto/NotoSans-Regular.ttf',
    ).readAsBytesSync();
    await (FontLoader(
      'Roboto',
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  });
  testWithGame<GolgeGame>('geçiş', GolgeGame.new, (game) async {
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(17);
    await game.ready();
    for (var i = 0; i < 30; i++) {
      game.update(1 / 60);
    }
    game.effects.setFade(1, kInk);
    game.narration.playCinematic(
      interludeText(17),
      () => game.effects.fadeTo(0, 1.8),
      instantBlack: true,
      scene: PerdeScene.otuken,
    );
    game.narration.skipAll();
    var n = 0;
    Future<void> shot() async {
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(1280, 720);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File(
        'build/preview/gecis_${n++}.png',
      ).writeAsBytesSync(png!.buffer.asUint8List());
    }

    for (var i = 0; i < 200 && !game.narration.inPerdeOut; i++) {
      game.update(1 / 60);
    }
    await game.ready();
    for (final steps in [1, 20, 20, 20, 20, 30]) {
      for (var i = 0; i < steps; i++) {
        game.update(1 / 60);
      }
      await shot();
    }
  });
}
