// Yunus Koyu: hareketli önizleme (yüzüş, yunuslar, sudan sıçrayış, kara kaz).
// `flutter test tools/preview/deniz_koy_video_test.dart` →
// build/preview/koy/k_<n>.png (ffmpeg ile videoya çevrilir).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';

import 'yazi_tipi.dart';

void main() {
  setUpAll(yaziTipiYukle);
  testWithGame<GolgeGame>(
    'Yunus Koyu video',
    GolgeGame.new,
    timeout: const Timeout(Duration(minutes: 10)),
    (game) async {
      Cartoon.on = true;
      Realism.on = true;
      Cartoon.tone = 0.35;
      game.onGameResize(Vector2(960, 540));
      game.debugLoadLevel(20);
      await game.ready();
      game.cinematic = false;
      final dir = Directory('build/preview/koy')..createSync(recursive: true);
      for (final f in dir.listSync()) {
        f.deleteSync();
      }
      final p = game.player!;
      p.position.setValues(96 * kTile, 12 * kTile);
      p.velocity.setZero();
      game.debugSnapCamera();
      final k = game.controls.keyboard;
      var n = 0;
      Future<void> play(double s, {bool shoot = true}) async {
        for (var i = 0; i < (s * 60).round(); i++) {
          game.update(1 / 60);
          if (shoot && i % 2 == 0) {
            game.narration.resetScene();
            final rec = ui.PictureRecorder();
            game.render(ui.Canvas(rec));
            final img = await rec.endRecording().toImage(960, 540);
            final png = await img.toByteData(format: ui.ImageByteFormat.png);
            File('${dir.path}/k_${(n++).toString().padLeft(4, '0')}.png')
                .writeAsBytesSync(png!.buffer.asUint8List());
          }
        }
      }

      // Balık sürüsüne dokun, sağa yüz.
      k.right = true;
      await play(1.2);
      // Basılı kulaçla hızlı yüzüş: biraz dal, sonra dümdüz yukarı fırla.
      k.jump = true;
      k.down = true;
      await play(0.4);
      k.down = false;
      k.right = false;
      k.up = true;
      await play(1.3);
      k.right = true;
      await play(0.3);
      k.up = false;
      k.jump = false;
      await play(1.8);
      // Bir daha, yunusların yanında.
      k.down = true;
      await play(0.9);
      k.down = false;
      k.right = false;
      k.jump = true;
      k.up = true;
      await play(1.5);
      k.right = true;
      await play(0.3);
      k.up = false;
      k.jump = false;
      await play(2.0);
      k.right = false;
    },
  );
}
