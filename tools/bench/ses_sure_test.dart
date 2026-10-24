// Ses motorunun bildirdiği anlatım süreleri gerçek sürelerle aynı mı
// (LoadMode.disk, oyundaki gibi). `flutter test tools/bench/ses_sure_test.dart`
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('anlatım süreleri', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.path,
        );
    final s = SoLoud.instance;
    await s.init(automaticCleanup: true);
    final files = Directory('assets/voice/tr').listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    var worst = 0.0;
    var shortN = 0;
    for (final f in files.take(60)) {
      final name = f.uri.pathSegments.last;
      final src = await s.loadAsset('assets/voice/tr/$name', mode: LoadMode.disk);
      final len = s.getLength(src).inMilliseconds / 1000;
      final probe = Process.runSync('ffprobe', [
        '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', f.path,
      ]).stdout.toString().trim();
      final real = double.parse(probe);
      final d = real - len;
      if (d > 0.3) shortN++;
      if (d.abs() > worst.abs()) worst = d;
      if (d.abs() > 0.3) {
        // ignore: avoid_print
        print('$name motor ${len.toStringAsFixed(2)} gerçek ${real.toStringAsFixed(2)}');
      }
      await s.disposeSource(src);
    }
    // ignore: avoid_print
    print('kısa okunan $shortN / 60, en büyük fark ${worst.toStringAsFixed(2)} sn');
    s.deinit();
  });
}
