// Telefonda perdenin en uzun satırı "Atla" düğmesine değmez.
// `flutter test tools/preview/perde_atla_test.dart` → build/preview/perde_atla.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/levels.dart';
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
  testWithGame<GolgeGame>('perde atla', GolgeGame.new, (game) async {
    game.onGameResize(Vector2(870, 391));
    game.debugLoadLevel(0);
    await game.ready();
    final lines = [...prologueText]..sort((a, b) => b.length - a.length);
    game.narration.playCinematic(
      [lines.first, 'SON'],
      () {},
      instantBlack: true,
      scene: PerdeScene.prologue,
    );
    for (var i = 0; i < 150; i++) {
      game.update(1 / 60);
    }
    final rec = ui.PictureRecorder();
    game.render(ui.Canvas(rec));
    final img = await rec.endRecording().toImage(870, 391);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File(
      'build/preview/perde_atla.png',
    ).writeAsBytesSync(png!.buffer.asUint8List());
  });
}
