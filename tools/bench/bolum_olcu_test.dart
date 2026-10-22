// Bölüm ölçüleri: genişlik, yükseklik, kontrol noktası, düzenek sayıları.
// `flutter test tools/bench/bolum_olcu_test.dart`
import 'package:flame_test/flame_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/levels.dart';

void main() {
  testWithGame<GolgeGame>('ölçü', GolgeGame.new, (game) async {
    for (final lv in levelOrder) {
      game.debugLoadLevel(lv);
      await game.ready();
      final kinds = <String, int>{};
      for (final c in game.world.children) {
        final k = c.runtimeType.toString();
        kinds[k] = (kinds[k] ?? 0) + 1;
      }
      const skip = {
        'TerrainComponent', 'ForegroundComponent', 'LightingLayer',
        'RealismLayer', 'NearLayer', 'Player', 'WaterComponent',
        'LightShafts', 'WindCurrents', 'PerdeCord', 'Bird', 'ExitPortal',
      };
      final parts = (kinds.entries.where((e) => !skip.contains(e.key)).toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .map((e) => '${e.key}×${e.value}')
          .join(' ');
      // ignore: avoid_print
      print(
        '${levels[lv].title.padRight(22)} ${game.level.width}×${game.level.height} '
        '| $parts',
      );
    }
  });
}
