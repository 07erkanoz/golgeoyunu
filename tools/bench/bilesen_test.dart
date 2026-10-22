// Bileşen bileşen çizim maliyeti (yazılım çizici, göreli): her dünya
// bileşeni ve kamera katmanı ayrı bir resme çizilir, süresi ölçülür.
// `flutter test tools/bench/bilesen_test.dart --dart-define=LV=0`
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/palette.dart';

const _lv = int.fromEnvironment('LV');

Future<double> _time(void Function(ui.Canvas) draw) async {
  var best = double.infinity;
  for (var k = 0; k < 5; k++) {
    final sw = Stopwatch()..start();
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    draw(c);
    final img = await rec.endRecording().toImage(1280, 720);
    await img.toByteData();
    img.dispose();
    final t = sw.elapsedMicroseconds / 1000;
    if (t < best) best = t;
  }
  return best;
}

void main() {
  testWithGame<GolgeGame>('bilesen', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(_lv);
    await game.ready();
    game.cinematic = false;
    for (var i = 0; i < 60; i++) {
      game.update(1 / 60);
    }
    final empty = await _time((c) {});
    final rows = <(String, double)>[];
    final whole = await _time(game.render);
    // Dünya bileşenleri kameranın dönüşümüyle çizilir.
    final cam = game.camera;
    for (final comp
        in game.world.children.toList()
          ..sort((a, b) => a.priority.compareTo(b.priority))) {
      final t = await _time((c) {
        c.save();
        c.translate(640, 360);
        c.scale(cam.viewfinder.zoom);
        c.translate(-cam.viewfinder.position.x, -cam.viewfinder.position.y);
        comp.renderTree(c);
        c.restore();
      });
      rows.add(('${comp.runtimeType}#${comp.priority}', t - empty));
    }
    final bd = cam.backdrop;
    rows.add(('backdrop', await _time(bd.renderTree) - empty));
    for (final v in cam.viewport.children) {
      rows.add((
        'viewport ${v.runtimeType}',
        await _time(v.renderTree) - empty,
      ));
    }
    final merged = <String, double>{};
    for (final (k, v) in rows) {
      final key = k.split('#').first;
      merged[key] = (merged[key] ?? 0) + v;
    }
    final sorted = merged.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // ignore: avoid_print
    print('bütün kare ${(whole - empty).toStringAsFixed(1)} ms (boş $empty)');
    for (final e in sorted.take(14)) {
      // ignore: avoid_print
      print('  ${e.key.padRight(28)} ${e.value.toStringAsFixed(1)} ms');
    }
  });
}
