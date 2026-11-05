// Bölümlerin başından birer ekran görüntüsü (doku denemeleri için).
// `BOLUM=0,1,2 flutter test tools/preview/bolum_goruntu_test.dart
// --dart-define=CARTOON=true` → build/preview/bolum/<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/atmosphere.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/kukla.dart';
import 'package:golge/game/palette.dart';

import 'yazi_tipi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(yaziTipiYukle);
  final levels = (Platform.environment['BOLUM'] ?? '0,1,2')
      .split(',')
      .map(int.parse);
  for (final n in levels) {
    testWithGame<GolgeGame>('bölüm $n', GolgeGame.new, (game) async {
      Cartoon.on = true;
      Realism.on = true;
      Cartoon.tone = 0.35;
      game.onGameResize(Vector2(1280, 720));
      await SayeKukla.load();
      game.debugLoadLevel(n);
      await game.ready();
      game.cinematic = false;
      // YER=sütun,satır: Sâye oraya konur (bölümün başka bir yeri).
      final at = Platform.environment['YER'];
      if (at != null) {
        final [c, r] = at.split(',').map(double.parse).toList();
        game.player!.position.setValues(c * 32, r * 32);
      }
      // Bölüm açılışının kararması geçsin.
      final wait = double.parse(Platform.environment['BEKLE'] ?? '6');
      for (var i = 0; i < wait * 60; i++) {
        game.update(1 / 60);
      }
      final k = game.controls.keyboard..right = true;
      for (var i = 0; i < 90; i++) {
        game.update(1 / 60);
      }
      k.right = false;
      for (var i = 0; i < 60; i++) {
        game.update(1 / 60);
      }
      game.narration.resetScene();
      // Açılışın kararması (perde kalkarken) bitmiş olsun.
      for (final e in game.descendants().whereType<ScreenEffects>()) {
        e.fade = 0;
      }
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(1280, 720);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory('build/preview/bolum')..createSync(recursive: true);
      File('${dir.path}/$n.png').writeAsBytesSync(png!.buffer.asUint8List());
    }, timeout: const Timeout(Duration(minutes: 5)));
  }
}
