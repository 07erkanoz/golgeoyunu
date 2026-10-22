// Ergenekon ocakları: damarlar, körükler ve eşleşmeleri.
// `flutter test tools/bench/korur_yoklama_test.dart`
import 'package:flame_test/flame_test.dart';
import 'package:golge/game/ergenekon.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';

void main() {
  testWithGame<GolgeGame>('ocaklar', GolgeGame.new, (game) async {
    game.debugLoadLevel(15);
    await game.ready();
    final veins = game.world.children.whereType<IronVein>().toList()
      ..sort((a, b) => a.forge.dx.compareTo(b.forge.dx));
    for (final (i, v) in veins.indexed) {
      // ignore: avoid_print
      print(
        'damar $i: sütun ${(v.forge.dx / kTile).floor()} ritim ${v.rhythm} '
        'kömür ${v.fuelNeeded} körük sayısı ${v.bellowsCount}',
      );
    }
    for (final b in game.world.children.whereType<Bellows>()) {
      // ignore: avoid_print
      print(
        '  körük sütun ${(b.position.x / kTile).floor()} satır '
        '${(b.position.y / kTile).floor() - 1} sıra ${b.order} → damar '
        '${veins.indexOf(b.vein!)}',
      );
    }
  });
}
