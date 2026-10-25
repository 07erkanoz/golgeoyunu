// Ak Ana'nın Denizi: yüzüş ve su altı önizlemesi.
// `flutter test tools/preview/deniz_test.dart`
// → build/preview/deniz/yuzus_<n>.png (GIF kareleri), sig.png, dip.png
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/deniz.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/terrain.dart';

import 'yazi_tipi.dart';

const _w = 120;
const _h = 64;
const _surfaceRow = 4;

/// Deneme haritası: solda sığlık (taban ~22. satır, kemerli bir kaya),
/// sağda derin bir çukur (taban ~60. satır).
List<String> _map() {
  final rows = List.generate(_h, (_) => List.filled(_w, '.'));
  for (var c = 0; c < _w; c++) {
    final shallow = c < 74;
    final floor = shallow
        ? 22 + (math.sin(c / 7) * 1.4 + math.sin(c / 3.1) * 0.6).round()
        : 58 + (math.sin(c / 5) * 1.5).round();
    for (var r = floor; r < _h; r++) {
      rows[r][c] = '#';
    }
  }
  // Uçurum: sığlıktan çukura inen kaya.
  for (var r = 22; r < 58; r++) {
    final edge = 74 + ((r - 22) * 0.12 + math.sin(r / 3) * 1.2).round();
    for (var c = 70; c < edge; c++) {
      rows[r][c] = '#';
    }
  }
  // Kemer: sığlıkta bir kaya köprüsü.
  for (var c = 44; c <= 54; c++) {
    for (var r = 16; r <= 17; r++) {
      rows[r][c] = '#';
    }
  }
  for (var r = 16; r < 22; r++) {
    rows[r][44] = '#';
    rows[r][45] = '#';
  }
  for (var c = 0; c < _w; c++) {
    rows[_h - 1][c] = '#';
  }
  for (var r = 0; r < _h; r++) {
    rows[r][0] = '#';
    rows[r][_w - 1] = '#';
  }
  rows[11][8] = 'P';
  return [for (final r in rows) r.join()];
}

Future<void> _shot(
  GolgeGame game,
  String name,
  int w,
  int h, {
  Vector2? focus,
  double zoom = 1,
}) async {
  game.narration.resetScene();
  final rec = ui.PictureRecorder();
  final canvas = ui.Canvas(rec);
  final vf = game.camera.viewfinder;
  final keepZoom = vf.zoom;
  final keepPos = vf.position.clone();
  if (focus != null) {
    // Sâye'ye yakın plan: kamera bu kare için yaklaşır (vektörel, net).
    vf.zoom = keepZoom * zoom;
    vf.position = focus;
  }
  final zSet = vf.zoom;
  game.render(canvas);
  if (name.endsWith('040')) {
    File('build/preview/deniz/zoom.txt').writeAsStringSync(
      'önce $keepZoom, ayarlanan $zSet, çizimden sonra ${vf.zoom}',
    );
  }
  vf.zoom = keepZoom;
  vf.position = keepPos;
  final img = await rec.endRecording().toImage(w, h);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  File('build/preview/deniz/$name.png')
      .writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  setUpAll(yaziTipiYukle);
  tearDown(() => GolgeGame.debugLevels = null);

  testWithGame<GolgeGame>(
    'deniz önizleme',
    GolgeGame.new,
    timeout: const Timeout(Duration(minutes: 8)),
    (game) async {
      Directory('build/preview/deniz').createSync(recursive: true);
      Cartoon.on = true;
      Realism.on = true;
      Cartoon.tone = 0.35;
      GolgeGame.debugLevels = [
        LevelDef(
          title: 'AK ANA',
          subtitle: '',
          theme: LevelTheme.kaf,
          map: _map(),
        ),
      ];
      const vw = 960;
      const vh = 540;
      game.onGameResize(Vector2(vw.toDouble(), vh.toDouble()));
      game.debugLoadLevel(0);
      await game.ready();
      game.cinematic = false;
      const surface = _surfaceRow * kTile;
      game.world.addAll([
        SeaWater(surface),
        SeaTint(surface),
        SeaShafts(surface),
        SeaMotes(),
        FishSchool(Vector2(34 * kTile, 12 * kTile), count: 34),
        FishSchool(Vector2(60 * kTile, 9 * kTile), count: 18, seed: 5),
        for (var i = 0; i < 34; i++)
          Kelp(
            Vector2((2 + i * 2.0 + (i % 3) * 0.7) * kTile, 21.7 * kTile),
            150 + (i * 37 % 120).toDouble(),
            front: i % 4 == 1,
            seed: i * 1.7,
          ),
        for (var i = 0; i < 9; i++)
          Jellyfish(
            Vector2((80 + i * 4.3) * kTile, (38 + (i * 5 % 13)) * kTile),
            seed: i * 0.37,
            bigness: 0.8 + (i % 3) * 0.2,
          ),
        AnglerFish(Vector2(104 * kTile, 53 * kTile)),
      ]);
      // Denemede yalnız kaya ve Sâye kalır: temanın süsleri (sarkıtlar,
      // neşe ışıkları, perde köşesi) bu suya ait değil.
      for (final c in game.world.children.toList()) {
        if (c is TerrainComponent ||
            c is Player ||
            c is SeaWater ||
            c is SeaTint ||
            c is SeaShafts ||
            c is SeaMotes ||
            c is FishSchool ||
            c is Kelp ||
            c is Jellyfish ||
            c is AnglerFish) {
          continue;
        }
        c.removeFromParent();
      }
      await game.ready();
      final p = game.player!;
      p.swimming = true;
      game.debugSnapCamera();
      final k = game.controls.keyboard;

      // GIF: yüksek çözünürlükte çizilir, Sâye'nin çevresi kesilir.
      game.onGameResize(Vector2(vw.toDouble(), vh.toDouble()));
      game.debugSnapCamera();
      final track = <String>[];
      // Yüzüş: dur → sağa yüz → üç kulaç → çapraz aşağı → süzül → yukarı.
      var frame = 0;
      var t = 0.0;
      const fps = 60;
      final strokes = [2.2, 3.3, 4.4, 5.0, 7.0];
      for (var i = 0; i < 9.4 * fps; i++) {
        k.right = t > 1.6 && t < 5.7;
        k.down = t > 4.7 && t < 5.7;
        k.up = t > 6.8 && t < 7.9;
        k.jump = strokes.any((s) => t >= s && t < s + 0.05);
        game.update(1 / fps);
        t += 1 / fps;
        if (i % 4 == 0) {
          final sp = p.center.clone();
          track.add('${sp.x.toStringAsFixed(1)},${sp.y.toStringAsFixed(1)}');
          await _shot(
            game,
            'yuzus_${(frame++).toString().padLeft(3, '0')}',
            vw,
            vh,
            focus: sp,
            zoom: 3,
          );
        }
      }
      k
        ..right = false
        ..down = false
        ..up = false
        ..jump = false;

      File('build/preview/deniz/iz.txt').writeAsStringSync(track.join('\n'));
      game.onGameResize(Vector2(vw.toDouble(), vh.toDouble()));
      // Sığlık: yosun ormanında, sürünün yanında bir kulaç.
      p.position.setValues(30 * kTile, 14 * kTile);
      p.velocity.setValues(80, 0);
      game.debugSnapCamera();
      for (var i = 0; i < 40; i++) {
        game.update(1 / 60);
      }
      k.jump = true;
      game.update(1 / 60);
      k.jump = false;
      for (var i = 0; i < 18; i++) {
        game.update(1 / 60);
      }
      await _shot(game, 'sig', vw, vh);

      // Karanlık dip: denizanaları ve fenerbalığı.
      p.position.setValues(92 * kTile, 50 * kTile);
      p.velocity.setValues(40, 10);
      game.debugSnapCamera();
      for (var i = 0; i < 80; i++) {
        game.update(1 / 60);
      }
      await _shot(game, 'dip', vw, vh);
    },
  );
}
