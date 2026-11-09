import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Oyunda ve hikâye perdelerinde kullanılan Kandilci çizimleri.
abstract final class KandilciArt {
  static final _images = <String, ui.Image>{};
  static bool get ready => _images.length == 4;
  static ui.Image image(String key) => _images[key]!;

  static Future<void> load() async {
    if (ready) return;
    const keys = ['guard_body', 'lantern', 'leg_near', 'leg_far'];
    final pairs = await Future.wait(
      keys.map((key) async {
        final data = await rootBundle.load('assets/art/kandilci/$key.png');
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        try {
          return (key, (await codec.getNextFrame()).image);
        } finally {
          codec.dispose();
        }
      }),
    );
    _images.addEntries(pairs.map((p) => MapEntry(p.$1, p.$2)));
  }

  static void draw(ui.Canvas c, String key, ui.Rect dest) {
    final img = image(key);
    c.drawImageRect(
      img,
      ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      dest,
      _paint,
    );
  }

  static final _paint = ui.Paint()..filterQuality = ui.FilterQuality.medium;
}
