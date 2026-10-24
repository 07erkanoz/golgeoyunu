// Yıldız Katı önizlemesi: dönen yıldız çarkı, Demir Kazık'a bağlı atlar,
// Yedi Karakçı. `flutter test tools/preview/yildiz_kati_test.dart`
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

List<String> _map({bool yada = false}) {
  const w = 64, h = 30;
  final g = List.generate(h, (_) => List.filled(w, '.'));
  void island(int c0, int c1, int top) {
    for (var c = c0; c <= c1; c++) {
      g[top][c] = '#';
      g[top + 1][c] = '#';
    }
  }

  island(0, 9, 22);
  island(20, 27, 14);
  island(48, 63, 8);
  g[21][3] = 'P';
  if (yada) g[21][7] = 'c';
  return [for (final r in g) r.join()];
}

Future<void> _shot(GolgeGame game, String name) async {
  game.narration.resetScene();
  final rec = ui.PictureRecorder();
  game.render(ui.Canvas(rec));
  final img = await rec.endRecording().toImage(1280, 720);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  Directory('build/preview').createSync(recursive: true);
  File('build/preview/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  setUpAll(yaziTipiYukle);
  for (final (name, col, row, t, kind) in [
    ('yildiz_1_cark', 8.0, 21, 2.0, 0),
    ('yildiz_2_kazik', 26.0, 13, 5.0, 0),
    ('yel_1_soluk', 6.0, 21, 3.9, 1),
    ('simsek_1_yildirim', 5.0, 21, 2.0, 2),
  ]) {
    testWithGame<GolgeGame>(name, GolgeGame.new, (game) async {
      Cartoon.on = true;
      Realism.on = true;
      GolgeGame.debugLevels = [
        switch (kind) {
          0 => LevelDef(
            title: 'x',
            subtitle: '',
            theme: LevelTheme.heavens,
            map: _map(),
            wings: true,
            wheels: const [(14, 17, 4, 3, 9, 0), (38, 11, 2.5, 2, 6, 1)],
            karakci: const [(38, 11, 4.5, -16)],
            skies: const [(0, 1)],
          ),
          1 => LevelDef(
            title: 'x',
            subtitle: '',
            theme: LevelTheme.heavens,
            map: _map(yada: true),
            wings: true,
            yel: const [(0, 4, 40, 21, -1)],
            skies: const [(0, 2)],
          ),
          _ => LevelDef(
            title: 'x',
            subtitle: '',
            theme: LevelTheme.heavens,
            map: _map(),
            wings: true,
            stormSteps: const [(11, 20, 3), (16, 18, 3), (21, 16, 2)],
            strikes: const [(7, 21, 4.6 - 0.25 - 1.95)],
            skies: const [(0, 5)],
          ),
        },
      ];
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(0);
      await game.ready();
      game.cinematic = false;
      final p = game.player!;
      p.position.setFrom(
        Level.standOn(Vector2(col * kTile, row * kTile), Player.w, Player.h),
      );
      for (var i = 0; i < (t * 60).round(); i++) {
        game.update(1 / 60);
      }
      await _shot(game, name);
      GolgeGame.debugLevels = null;
      Cartoon.on = false;
      Realism.on = false;
    });
  }
}
