import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

import 'physics_test.dart' show run;

void main() {
  testWithGame<GolgeGame>(
    'Ülgen\'in Kapısı: Tulpar\'la uçuş parkuru fırtınaya yakalanmadan geçilir',
    GolgeGame.new,
    (game) async {
      game.debugLoadLevel(18);
      await game.ready();
      game.cinematic = false;
      run(game, 0.2);
      final p = game.player!;
      p.position.setFrom(
        Level.standOn(Vector2(189 * kTile, 30 * kTile), Player.w, Player.h),
      );
      run(game, 0.5);
      expect(game.onHorse, isTrue);
      // Sütun açıklıklarının ortası (satır): x sütununa göre hedef.
      double targetRow(double x) {
        final c = x / kTile;
        if (c < 199) return 26;
        if (c < 208) return 26;
        if (c < 218) return 17;
        if (c < 228) return 22;
        if (c < 238) return 15;
        if (c < 248) return 24;
        if (c < 258) return 18;
        return 28;
      }

      game.controls.keyboard.right = true;
      var maxX = 0.0;
      var flapT = 0.0;
      for (var i = 0; i < 60 * 30; i++) {
        final ty = targetRow(p.center.x + 3 * kTile) * kTile;
        flapT -= 1 / 60;
        final wantFlap = p.center.y > ty && p.velocity.y > -120 && flapT <= 0;
        game.controls.keyboard.jump = wantFlap;
        if (wantFlap) flapT = 0.25;
        run(game, 1 / 60);
        game.controls.keyboard.jump = false;
        if (p.center.x > maxX) maxX = p.center.x;
        if (p.isDead) break;
        if (p.center.x > 267 * kTile) break;
      }
      expect(maxX, greaterThan(267 * kTile));
    },
  );
}
