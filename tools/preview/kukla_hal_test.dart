// Yeni Sâye (A1) kuklası özel hâllerde: Kaf'ta kanatla süzülme, Palandöken'de
// kayak, Ak Ana'da yüzme. Her biri birkaç an, Sâye 4 kat yakından.
// `flutter test tools/preview/kukla_hal_test.dart --dart-define=CARTOON=true`
// → build/preview/kukla_hal/<bölüm>_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/kukla.dart';
import 'package:golge/game/palette.dart';

import 'yazi_tipi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(yaziTipiYukle);
  final dir = Directory('build/preview/kukla_hal')..createSync(recursive: true);
  for (final (name, index, keys) in [
    ('kaf', 3, {'right', 'jump'}),
    ('palandoken', 9, {'right'}),
    ('akana', 20, {'right', 'jump'}),
  ]) {
    testWithGame<GolgeGame>('kukla hâli $name', GolgeGame.new, (game) async {
      Cartoon.on = true;
      Realism.on = true;
      Cartoon.tone = 0.35;
      await SayeKukla.load();
      game.onGameResize(Vector2(960, 540));
      game.debugLoadLevel(index);
      await game.ready();
      game.cinematic = false;
      final p = game.player!;
      final k = game.controls.keyboard;
      var n = 0;
      for (var f = 0; f < 60 * 6; f++) {
        // Zıplayıp basılı tutar (kanatla süzülür), arada bırakır.
        k
          ..right = keys.contains('right')
          ..jump = keys.contains('jump') && (f % 90) < 70
          ..down = name == 'akana' && f % 120 < 30;
        game.update(1 / 60);
        if (f % 45 != 44) continue;
        game.narration.resetScene();
        final rec = ui.PictureRecorder();
        final c = ui.Canvas(rec);
        final vf = game.camera.viewfinder;
        final at = (p.center - vf.position) * vf.zoom + Vector2(480, 270);
        c.translate(240, 240);
        c.scale(4);
        c.translate(-at.x, -at.y);
        game.render(c);
        final img = await rec.endRecording().toImage(480, 480);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('${dir.path}/${name}_${n++}.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
        // ignore: avoid_print
        print('$name ${p.state} yüzüyor=${p.swimming} süzülüyor=${p.gliding} '
            'kayak=${p.skiing} kukla=${p.kuklaOn}');
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  }
}
