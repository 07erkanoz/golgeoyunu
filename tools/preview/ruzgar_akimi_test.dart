// Rüzgâr akımlarının (`r`) uçları: hava sütunu yumuşakça solar mı.
// `flutter test tools/preview/ruzgar_akimi_test.dart` → build/preview/ra_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  final tag = Platform.environment['ETIKET'] ?? 'yeni';
  for (final (lv, c, r) in [(2, 19.0, 10.0), (3, 24.0, 9.0), (8, 208.0, 8.0)]) {
    testWithGame<GolgeGame>('akım $lv', GolgeGame.new, (game) async {
      Cartoon.on = true;
      Realism.on = true;
      Cartoon.tone = 0.35;
      game.onGameResize(Vector2(960, 540));
      game.debugLoadLevel(lv);
      await game.ready();
      game.cinematic = false;
      final p = game.player!;
      p.position.setValues((c + 6) * kTile, r * kTile);
      p.velocity.setZero();
      game.debugSnapCamera();
      for (var i = 0; i < 50; i++) {
        game.update(1 / 60);
      }
      game.narration.resetScene();
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(960, 540);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/ra_${tag}_$lv.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    });
  }
}
