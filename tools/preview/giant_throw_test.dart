// Taş devin taş atışı: kaldırma (kulak örtülü), işaret, uçuş, basamak.
// `flutter test tools/preview/giant_throw_test.dart` → build/preview/dev_at_*.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/nemrut.dart';
import 'package:golge/game/player.dart';

Future<void> shot(GolgeGame game, String name) async {
  final rec = ui.PictureRecorder();
  game.render(ui.Canvas(rec));
  final img = await rec.endRecording().toImage(1280, 720);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  Directory('build/preview').createSync(recursive: true);
  File('build/preview/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  setUpAll(() async {
    final bytes = File(
      '/usr/share/fonts/noto/NotoSans-Regular.ttf',
    ).readAsBytesSync();
    await (FontLoader(
      'Roboto',
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  });
  testWithGame<GolgeGame>('dev taş atar', GolgeGame.new, (game) async {
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(7);
    await game.ready();
    game.cinematic = false;
    final giant = game.world.children.whereType<StoneGiant>().first;
    final p = game.player!;
    p.position.setFrom(
      Level.standOn(
        Vector2(giant.position.x - 8 * kTile, 19 * kTile),
        Player.w,
        Player.h,
      ),
    );
    game.debugCloseUp = 1.0;
    var n = 0;
    String? last;
    for (var i = 0; i < 60 * 12 && n < 5; i++) {
      game.update(1 / 60);
      final stones = game.world.children.whereType<ThrownStone>();
      final steps = game.world.children.whereType<StoneStep>();
      final marks = game.world.children.whereType<ThrowMark>();
      final tag = stones.isNotEmpty
          ? 'ucus'
          : (marks.isNotEmpty
                ? 'kaldir'
                : (steps.isNotEmpty ? 'basamak' : null));
      if (tag != null && tag != last) {
        // Evrenin ortasına doğru bekle, sonra çek.
        for (var k = 0; k < (tag == 'kaldir' ? 40 : 18); k++) {
          game.update(1 / 60);
        }
        await shot(game, 'dev_at_${n}_$tag');
        n++;
        last = tag;
      }
      if (p.isDead) break;
    }
  });
}
