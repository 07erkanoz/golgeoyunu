import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/levels.dart';

void main() {
  test('oynanış sırası bütün bölümleri birer kez içerir', () {
    expect(levelOrder.toSet(), {for (var i = 0; i < levels.length; i++) i});
    expect(levelOrder.length, levels.length);
  });

  test('sıradaki bölüm sıraya göre; son bölümden sonra yok', () {
    for (var i = 0; i + 1 < levelOrder.length; i++) {
      expect(nextLevel(levelOrder[i]), levelOrder[i + 1]);
    }
    expect(nextLevel(levelOrder.last), isNull);
  });

  test('eski kayıttaki en ileri yer yeni sırada aynı bölüme düşer', () {
    // 1. sürümde yer = kimlik: Konya (13) açılmış bir kayıt Konya'yı açık
    // tutar, araya giren bölümler de açılır.
    expect(levelOrder[migrateOrderPosition(13, 1)], 13);
    expect(levelOrder[migrateOrderPosition(4, 1)], 4);
    expect(migrateOrderPosition(-3, 1), 0);
    expect(levelOrder[migrateOrderPosition(99, 1)], 13);
  });
}
