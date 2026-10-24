// Sarmaşıktan bırakınca nereye inilir: hedef yüksekliği ve bırakış biçimine
// göre ilk basılan sütun (Ötüken parkurlarının tasarımı için).
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

List<String> _map(int rise) {
  const h = 34, f = 24, w = 60;
  final g = List.generate(h, (_) => List.filled(w, '.'));
  for (var c = 0; c < 10; c++) {
    for (var r = f; r < h; r++) {
      g[r][c] = '#';
    }
  }
  // Uzun zemin: sarmaşıktan 3 kare sonra, [rise] kare yüksek.
  for (var c = 14; c < w; c++) {
    for (var r = f - rise; r < h; r++) {
      g[r][c] = '#';
    }
  }
  for (var r = f - 9; r < f - 1; r++) {
    g[r][11] = 'S';
  }
  g[f - 1][3] = 'P';
  return [for (final r in g) r.join()];
}

void main() {
  setUpAll(yaziTipiYukle);
  for (final rise in [0, 1, 2, 3]) {
    for (final eager in [true, false]) {
      for (final rel in [0.2, 0.4, 0.6, 0.8, 1.0]) {
        testWithGame<GolgeGame>('r$rise $eager $rel', GolgeGame.new, (
          game,
        ) async {
          GolgeGame.debugLevels = [
            LevelDef(
              title: 'x',
              subtitle: '',
              theme: LevelTheme.forest,
              map: _map(rise),
              noWings: true,
            ),
          ];
          game.onGameResize(Vector2(1280, 720));
          game.debugLoadLevel(0);
          await game.ready();
          game.cinematic = false;
          final p = game.player!;
          final k = game.controls.keyboard;
          var minA = 0.0;
          var held = false;
          var swung = false;
          double? land;
          for (var i = 0; i < 60 * 20; i++) {
            final sw = p.state == PlayerState.swing;
            if (sw && !held) minA = 0;
            held = sw;
            if (sw) {
              swung = true;
              minA = p.ropeAngle < minA ? p.ropeAngle : minA;
              k
                ..right = p.ropeOmega >= 0
                ..left = p.ropeOmega < 0
                ..jump =
                    p.ropeAngle > rel &&
                    p.ropeOmega > 0 &&
                    (eager || minA < -rel * 0.6);
            } else {
              k
                ..right = !swung
                ..left = false;
              if (!swung && p.onGround && p.position.x > 9.4 * kTile) {
                k.jump = true;
              }
              if (!p.onGround && p.velocity.y > 0) k.jump = false;
            }
            game.update(1 / 60);
            if (swung && !sw && p.onGround) {
              land = p.center.x / kTile;
              break;
            }
            if (p.isDead) break;
          }
          // ignore: avoid_print
          print(
            'INIS yükseklik=$rise ${eager ? 'ilk' : 'pompa'} açı=$rel iniş=${land?.toStringAsFixed(1) ?? 'yok'} (ipten ${land == null ? '-' : (land - 11.5).toStringAsFixed(1)})',
          );
          GolgeGame.debugLevels = null;
        });
      }
    }
  }
}
