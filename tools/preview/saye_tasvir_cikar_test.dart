// Oyundaki Sâye'yi (karikatürize; kavanozu henüz yok) büyük ölçekte saydam PNG'ye
// çizer: açılış perdesinde Sâye tasviri oyundakinin aynısı olsun.
// `flutter test tools/preview/saye_tasvir_cikar_test.dart --dart-define=CARTOON=true`
// → build/preview/saye_tasvir.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/player.dart';
import 'package:golge/settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWithGame<GolgeGame>('Sâye tasviri', GolgeGame.new, (game) async {
    game.onGameResize(Vector2(960, 540));
    game.debugLoadLevel(0);
    await game.ready();
    game.cinematic = false;
    for (var i = 0; i < 240; i++) {
      game.update(1 / 60);
    }
    for (final g in game.world.children.whereType<Guard>().toList()) {
      g.removeFromParent();
    }
    final p = game.player!;
    p.velocity.setZero();
    for (var i = 0; i < 90; i++) {
      game.update(1 / 60);
    }
    // Süs gölgeleri ve ayak ışığı çizilmesin: yalnız figür.
    Settings.lowGraphics = true;
    Player.debugNoJar = true;
    p.onGround = false;
    const scale = 16.0;
    const pad = Offset(16, 20);
    const w = (Player.w + 32) * scale;
    const h = (Player.h + 28) * scale;
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    c.scale(scale);
    c.translate(pad.dx, pad.dy);
    p.render(c);
    final img = await rec.endRecording().toImage(w.round(), h.round());
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/preview').createSync(recursive: true);
    File('build/preview/saye_tasvir.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  });
}
