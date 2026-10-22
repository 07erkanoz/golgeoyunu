// Ergenekon ilk ocak: körükler, yanında Demirci, ısı çubukları.
// `flutter test tools/preview/korur_test.dart` → build/preview/korur.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/ergenekon.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

void main() {
  setUpAll(() async {
    final bytes = File('/usr/share/fonts/noto/NotoSans-Regular.ttf')
        .readAsBytesSync();
    await (FontLoader(
      'Roboto',
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  });
  testWithGame<GolgeGame>('korur', GolgeGame.new, (game) async {
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(15);
    await game.ready();
    game.cinematic = false;
    final v = game.world.children.whereType<IronVein>().firstWhere(
      (v) => v.rhythm,
    );
    v
      ..lit = true
      ..heat = 0.45;
    final b = game.world.children.whereType<Bellows>().firstWhere(
      (b) => b.vein == v && b.order > 0,
    );
    game.player!.position.setFrom(
      Level.standOn(
        Vector2(b.position.x - kTile, b.position.y - 2 * kTile),
        Player.w,
        Player.h,
      ),
    );
    for (var i = 0; i < 90; i++) {
      game.update(1 / 60);
    }
    game.narration.resetScene();
    final rec = ui.PictureRecorder();
    game.render(ui.Canvas(rec));
    final img = await rec.endRecording().toImage(1280, 720);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/preview/korur.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}
