// Uzun perde satırı cümle cümle akar: her parça kısa, kahramanların
// sözleri ayrı parça, parçalar sırayla görünür.
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/narration.dart';

void main() {
  test('açılışın uzun satırları kısa parçalara bölünür', () {
    for (final line in [...prologue, ...prologueEn]) {
      // Cümle ortasından bölünmez; tek uzun cümle de telefonda iki satıra
      // sığar.
      for (final c in Narration.chunks(line, max: 100)) {
        expect(c.length, lessThanOrEqualTo(120), reason: c);
      }
    }
    final first = Narration.chunks(prologue[0], max: 100);
    expect(first.last, '“Eğlence mi istersin? Al sana eğlence!”');
    expect(first[first.length - 2], '“Hay Hak! Yâr bana bir eğlence…”');
  });

  test('satırın ilerleyişine göre parça seçilir', () {
    final line = prologue[0];
    final parts = Narration.chunks(line, max: 100);
    expect(Narration.chunkAt(line, 0), parts.first);
    expect(Narration.chunkAt(line, 0.999), parts.last);
    // Kısa satır olduğu gibi kalır.
    expect(Narration.chunkAt(prologue[3], 0.5), prologue[3]);
  });
}
