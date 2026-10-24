// Önizlemelerde gerçek yazı tipi: test ortamı yazıları kare blok çizer.
// `setUpAll(yaziTipiYukle);` ile kullanılır.
import 'dart:io';

import 'package:flutter/services.dart';

Future<void> yaziTipiYukle() async {
  final loader = FontLoader('Roboto');
  for (final f in ['NotoSans-Regular', 'NotoSans-Italic', 'NotoSans-Bold']) {
    final file = File('/usr/share/fonts/noto/$f.ttf');
    if (!file.existsSync()) continue;
    final b = file.readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(b.buffer)));
  }
  await loader.load();
}
