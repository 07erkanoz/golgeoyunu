// Bütün perdelerin ve Hikâye köprülerinin her satırı iki anda (satırın
// başı ve sonu): resimlerin anlatıma uyup uymadığını denetlemek için.
// `flutter test tools/preview/perde_denetim_test.dart` → build/preview/denetim/
// (tools/preview/perde_denetim_sayfa.py metinle birleştirip sayfa yapar).
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/perde.dart';

Future<void> _shot(String path, void Function(ui.Canvas) paint) async {
  final rec = ui.PictureRecorder();
  paint(ui.Canvas(rec));
  final img = await rec.endRecording().toImage(480, 270);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  test('perde denetimi', () async {
    final dir = Directory('build/preview/denetim')..createSync(recursive: true);
    for (final f in dir.listSync()) {
      f.deleteSync();
    }
    final index = <Map<String, Object>>[];
    Future<void> act(String key, PerdeScene scene, List<String> lines,
        {int? bridge}) async {
      for (var k = 0; k < lines.length; k++) {
        final shots = <String>[];
        for (final f in [0.2, 0.85]) {
          final p = '${dir.path}/${key.replaceAll(':', '_')}_${k}_${(f * 100).round()}.png';
          await _shot(p, (c) {
            PerdePainter.paint(c, const ui.Size(480, 270), scene,
                (k + f) * 4.4, k + f, 1,
                bridge: bridge, bridgeLines: lines.length);
          });
          shots.add(p);
        }
        index.add({'act': key, 'line': k, 'text': lines[k], 'shots': shots});
      }
    }

    var order = 0;
    String n(String s) => '${(order++).toString().padLeft(2, '0')}_$s';
    await act(n('prologue'), PerdeScene.prologue, prologue);
    PerdeScene last = PerdeScene.prologue;
    for (var o = 0; o < levelOrder.length; o++) {
      final lv = levelOrder[o];
      final scene = interludeScene(lv);
      if (scene != null && interludes[lv].isNotEmpty) {
        await act(n('perde:$lv'), scene, interludes[lv]);
        last = scene;
      }
      if (bridges[lv].isNotEmpty) {
        await act(n('kopru:$lv'), last, bridges[lv], bridge: lv);
      }
    }
    await act(n('epilogue'), PerdeScene.epilogue, epilogue);
    File('${dir.path}/index.json')
        .writeAsStringSync(const JsonEncoder.withIndent(' ').convert(index));
  });
}
