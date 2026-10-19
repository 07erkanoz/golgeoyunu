import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';

void main() {
  test('her bölümün başlangıcı, çıkışı ve hikâye satırları tutarlı', () {
    for (final def in levels) {
      final lv = Level(def);
      expect(lv.playerStart, isNot(equals(lv.exitCell)), reason: def.title);
      expect(lv.memoryCells.length, def.memories.length, reason: def.title);
      for (final (i, _) in lv.triggers) {
        expect(i, lessThan(def.whispers.length), reason: def.title);
      }
      // Oyuncu boş bir hücrede, katı zeminin üstünde başlamalı.
      final c = (lv.playerStart.x / kTile).floor();
      final r = (lv.playerStart.y / kTile).floor();
      expect(lv.solid(c, r), isFalse, reason: def.title);
      expect(lv.solid(c, r + 1), isTrue, reason: def.title);
    }
  });
}
