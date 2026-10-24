// Anlatım şeridi önizlemesi (telefon boyu): düzeneğin dört satırlık şiiri
// tek blok değil, satır satır akar; ekranda en çok iki satır kalır.
// `flutter test tools/preview/yazi_akisi_test.dart` → build/preview/yazi_<n>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/hints.dart';
import 'package:golge/game/palette.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Roboto');
    for (final f in ['NotoSans-Regular', 'NotoSans-Italic']) {
      final b = File('/usr/share/fonts/noto/$f.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(b.buffer)));
    }
    await loader.load();
  });
  testWithGame<GolgeGame>('yazı akışı', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    Cartoon.tone = 0.35;
    game.onGameResize(Vector2(770, 346));
    game.debugLoadLevel(0);
    await game.ready();
    for (final g in game.world.children.whereType<Guard>().toList()) {
      g.removeFromParent();
    }
    await game.ready();
    void run(double s) {
      for (var i = 0; i < (s * 60).round(); i++) {
        game.update(1 / 60);
      }
    }

    Future<void> shot(String name) async {
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      final img = await rec.endRecording().toImage(770, 346);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/yazi_$name.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    run(1);
    game.narration.resetScene();
    game.narration.whisper(Hints.poem('shield'), story: false);
    game.narration.whisper(
      'Hatıra · Perdenin önünde ilk adımımı attığımda gülmüştü: '
      '"Gölgen senden önce yürüyor."',
    );
    for (final (n, t) in [('1', 1.2), ('2', 3.0), ('3', 4.0), ('4', 5.0)]) {
      run(t);
      await shot(n);
    }
  });
}
