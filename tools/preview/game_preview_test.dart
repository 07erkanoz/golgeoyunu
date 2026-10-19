// Oyun içi önizleme: `flutter test tools/preview` ile build/preview/ altına
// yakın plan PNG'ler yazar (Sâye, Hüdhüd, Kandilci'nin feneri).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

Future<void> shot(GolgeGame game, String name) async {
  final rec = ui.PictureRecorder();
  game.render(ui.Canvas(rec));
  final img = await rec.endRecording().toImage(1280, 720);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  File('build/preview/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
}

void step(GolgeGame game, double seconds) {
  for (var t = 0.0; t < seconds; t += 1 / 60) {
    game.update(1 / 60);
  }
}

void main() {
  testWithGame<GolgeGame>('oyun içi önizlemeler', GolgeGame.new, (game) async {
    Directory('build/preview').createSync(recursive: true);
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(0);
    await game.ready();
    game.cinematic = false;
    game.debugCloseUp = 3;
    final p = game.player!;
    final bird = game.world.children.whereType<Bird>().first;
    p.position.setFrom(
      Level.standOn(
        Vector2(bird.position.x - 5.5 * kTile, bird.position.y - kTile),
        Player.w,
        Player.h,
      ),
    );
    step(game, 1.2);
    await shot(game, 'oyun_saye_hudhud');

    game.controls.keyboard.right = true;
    step(game, 0.45);
    await shot(game, 'oyun_saye_kosar');
    game.controls.keyboard.right = false;

    final g = game.world.children.whereType<Guard>().first;
    p.position.setFrom(
      Level.standOn(
        Vector2(g.position.x - 7 * kTile, g.position.y),
        Player.w,
        Player.h,
      ),
    );
    game.debugCloseUp = 2;
    step(game, 1.0);
    g
      ..state = GuardState.patrol
      ..suspicion = 0;
    await shot(game, 'oyun_kandilci_sakin');
    g.suspicion = 0.7;
    await shot(game, 'oyun_kandilci_suphe');
    g.state = GuardState.alert;
    await shot(game, 'oyun_kandilci_gordu');
  });
}
