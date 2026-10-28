// Gökyolu: lodos ve poyrazın çizgileri bölgenin kenarında yumuşak söner mi.
// `flutter test tools/preview/lodos_cizgi_test.dart` → build/preview/lc_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  final tag = Platform.environment['ETIKET'] ?? 'yeni';
  testWithGame<GolgeGame>('lodos', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    Cartoon.tone = 0.35;
    game.onGameResize(Vector2(960, 540));
    game.debugLoadLevel(2);
    await game.ready();
    game.cinematic = false;
    final p = game.player!;
    p.position.setFrom(
      Level.standOn(Vector2(320 * kTile, 7 * kTile), Player.w, Player.h),
    );
    p.velocity.setZero();
    game.debugSnapCamera();
    for (var i = 0; i < 90; i++) {
      game.update(1 / 60);
    }
    game.narration.resetScene();
    final rec = ui.PictureRecorder();
    game.render(ui.Canvas(rec));
    final img = await rec.endRecording().toImage(960, 540);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/preview/lc_$tag.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}
