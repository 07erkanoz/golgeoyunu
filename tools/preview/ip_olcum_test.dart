// İp ölçümü: aralık ve uzunluğa göre iple geçiş (Ötüken tasarımı için).
// `flutter test tools/preview/ip_olcum_test.dart`
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';

import 'yazi_tipi.dart';

List<String> _map(int gap, int len, int n, {int drop = 0, int land = 3}) {
  const h = 30, f = 22;
  final w = 12 + gap * (n + 1) + 20;
  final g = List.generate(h, (_) => List.filled(w, '.'));
  for (var c = 0; c < 10; c++) {
    for (var r = f; r < h; r++) {
      g[r][c] = '#';
    }
  }
  final end = 11 + gap * (n - 1) + land;
  for (var c = end + 1; c < w; c++) {
    for (var r = f + drop; r < h; r++) {
      g[r][c] = '#';
    }
  }
  for (var c = 9; c < end + 2; c++) {
    g[f - len - 2][c] = '#';
  }
  for (var i = 0; i < n; i++) {
    final c = 11 + gap * i;
    for (var r = f - len - 1; r < f - 1; r++) {
      g[r][c] = 'S';
    }
  }
  g[f - 1][3] = 'P';
  g[f - 1 + drop][w - 3] = 'E';
  return [for (final r in g) r.join()];
}

void main() {
  setUpAll(yaziTipiYukle);
  for (final gap in [5, 6, 7]) {
    for (final len in [6, 8]) {
      for (final rel in [0.4, 0.6, 0.8, 1.0]) {
        testWithGame<GolgeGame>('g$gap L$len r$rel', GolgeGame.new, (
          game,
        ) async {
          final m = _map(gap, len, 3);
          GolgeGame.debugLevels = [
            LevelDef(
              title: 'x',
              subtitle: '',
              theme: LevelTheme.forest,
              map: m,
              noWings: true,
            ),
          ];
          game.onGameResize(Vector2(1280, 720));
          game.debugLoadLevel(0);
          await game.ready();
          game.cinematic = false;
          final p = game.player!;
          final k = game.controls.keyboard;
          final goal = (11 + gap * 2 + 3) * kTile;
          var ok = false;
          var ropes = 0;
          var last = false;
          var minA = 0.0;
          for (var i = 0; i < 60 * 30; i++) {
            final sw = p.state == PlayerState.swing;
            if (sw && !last) {
              ropes++;
              minA = 0;
            }
            if (sw) minA = p.ropeAngle < minA ? p.ropeAngle : minA;
            last = sw;
            if (!sw && p.onGround && p.position.x > 9.4 * kTile) k.jump = true;
            if (sw) {
              k
                ..right = p.ropeOmega >= 0
                ..left = p.ropeOmega < 0
                ..jump =
                    p.ropeAngle > rel && p.ropeOmega > 0 && minA < -rel * 0.6;
            } else {
              k
                ..right = true
                ..left = false;
              if (!p.onGround) k.jump = false;
            }
            game.update(1 / 60);
            if (p.isDead) break;
            if (p.onGround && p.position.x > goal) {
              ok = true;
              break;
            }
          }
          // ignore: avoid_print
          print(
            'SONUC gap=$gap len=$len rel=$rel ok=$ok ropes=$ropes x=${(p.position.x / kTile).toStringAsFixed(1)}',
          );
          GolgeGame.debugLevels = null;
        });
      }
    }
  }
}
