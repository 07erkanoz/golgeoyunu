// Küçük sürprizler: utangaç gölge (Yerebatan) ve taş bekçi (Nemrut).
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/surprises.dart';
import 'package:golge/settings.dart';

void run(GolgeGame game, double s) {
  for (var i = 0; i < (s * 60).round(); i++) {
    game.update(1 / 60);
  }
}

void main() {
  setUp(Settings.secrets.clear);

  testWithGame<GolgeGame>('taş bekçi görmediğinde poz değiştirir, '
      'üçüncüde Sâye\'yi taklit eder', GolgeGame.new, (game) async {
    game.onGameResize(Vector2(1280, 720));
    final li = levels.indexWhere(
      (d) => d.surprises.any((s) => s.$1 == 'tasBekci'),
    );
    game.debugLoadLevel(li);
    await game.ready();
    for (final g in game.world.children.whereType<Guard>().toList()) {
      g.removeFromParent();
    }
    await game.ready();
    final p = game.player!;
    final statue = game.world.children.whereType<TasBekci>().first;
    p.position.setFrom(
      Level.standOn(
        Vector2(statue.position.x - 4 * kTile, statue.position.y - kTile),
        Player.w,
        Player.h,
      ),
    );
    run(game, 3);
    // Bakarken kıpırdamaz.
    p.facing = 1;
    run(game, 2);
    expect(statue.pose, 0);
    for (var turn = 1; turn <= 3; turn++) {
      p.facing = -1; // sırtını döner
      run(game, 1);
      p.facing = 1; // geri bakar
      run(game, 0.3);
      expect(statue.pose, turn, reason: '$turn. dönüşte yeni poz');
    }
    expect(game.secretSeen('tasBekci'), isTrue);
    expect(Settings.secrets, contains('$li:tasBekci'));
    // Sonra hep taklitte kalır.
    p.facing = -1;
    run(game, 2);
    expect(statue.pose, 3);
  });
}
