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

  test('Ötüken Derinkuyu ile Erlik arasına girer; kayıtlar kaymaz', () {
    expect(levelOrder.indexOf(17), levelOrder.indexOf(12) + 1);
    // Ötüken ile Erlik arasında Ak Ana'nın Denizi (8. sürüm).
    expect(levelOrder.indexOf(20), levelOrder.indexOf(17) + 1);
    expect(levelOrder.indexOf(14), levelOrder.indexOf(20) + 1);
    // 4. sürümde Erlik'e (yer 13) varmış kayıt yine Erlik'te kalır.
    expect(levelOrder[migrateOrderPosition(13, 4)], 14);
    expect(levelOrder[migrateOrderPosition(12, 4)], 12);
    expect(levelOrder[migrateOrderPosition(16, 4)], 13);
  });

  test('Göğün Katları II (Ülgen\'in Kapısı) I ile Konya arasına girer', () {
    expect(levelOrder.indexOf(18), levelOrder.indexOf(16) + 1);
    expect(levelOrder.indexOf(13), levelOrder.indexOf(18) + 1);
    // 5. sürümde Konya'ya (yer 17) varmış kayıt yine Konya'da kalır.
    expect(levelOrder[migrateOrderPosition(17, 5)], 13);
    expect(levelOrder[migrateOrderPosition(16, 5)], 16);
  });

  test('Ak Ana\'nın Denizi Ötüken ile Erlik arasına girer; kayıtlar kaymaz', () {
    // 7. sürümde Erlik'e (yer 14) varmış kayıt yine Erlik'te kalır; Ötüken'de
    // kalan Ötüken'de.
    expect(levelOrder[migrateOrderPosition(14, 7)], 14);
    expect(levelOrder[migrateOrderPosition(13, 7)], 17);
    expect(levelOrder[migrateOrderPosition(19, 7)], 19);
  });
}
