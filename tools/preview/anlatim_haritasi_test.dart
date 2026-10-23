// Bölüm bölüm anlatım haritası: her fısıltının tetiklendiği sütun, en yakın
// Umay ağacına (kontrol noktası) uzaklığı; hatıralar. Anlatımın sese ve
// yazıya dağıtımını planlamak için.
// `flutter test tools/preview/anlatim_haritasi_test.dart` → build/ses/harita.json
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/strings.dart';
import 'package:golge/game/voice.dart';

void main() {
  test('harita', () {
    S.lang = Lang.tr;
    final out = <Map<String, Object?>>[];
    for (final i in levelOrder) {
      final def = levels[i];
      final lv = Level(def);
      final trees = [for (final c in lv.checkpointCells) (c.x / kTile).round()];
      final ws = def.whisperTexts;
      final whispers = <Map<String, Object?>>[];
      for (final (n, cell) in lv.triggers) {
        if (n < 0 || n >= ws.length) continue;
        final col = (cell.x / kTile).round();
        final near = trees.isEmpty
            ? null
            : trees.map((t) => (t - col).abs()).reduce((a, b) => a < b ? a : b);
        whispers.add({
          'i': n,
          'id': voiceId(ws[n]),
          'col': col,
          'agac': near,
          'text': ws[n],
        });
      }
      whispers.sort((a, b) => (a['col'] as int).compareTo(b['col'] as int));
      out.add({
        'bolum': i,
        'sira': levelOrder.indexOf(i),
        'ad': def.titleText,
        'genislik': lv.width,
        'agaclar': trees,
        'ozan': def.bardText,
        'fisiltilar': whispers,
        'hatiralar': [
          for (final m in def.memoryTexts) {'id': voiceId(m), 'text': m},
        ],
      });
    }
    Directory('build/ses').createSync(recursive: true);
    File('build/ses/harita.json').writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert(out),
    );
  });
}
