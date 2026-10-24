// Ogg Vorbis sesleri ses motoruyla gerçekten yüklenip çözülüyor mu, süreleri
// asılla aynı mı. `flutter test tools/bench/ogg_yukleme_test.dart`
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('ogg sesler', () async {
    // Test ortamında path_provider eklentisi yok: geçici klasör verilir.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.path,
        );
    final s = SoLoud.instance;
    await s.init(automaticCleanup: true);
    final files = Directory('assets/audio')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.ogg'))
        .toList();
    var ok = 0;
    for (final f in files) {
      final name = f.uri.pathSegments.last;
      final src = await s.loadAsset('assets/audio/$name', mode: LoadMode.memory);
      final len = s.getLength(src).inMilliseconds / 1000;
      final wav = File('assets_src/audio/${name.replaceAll('.ogg', '.wav')}');
      // Asıl WAV'ın süresi: 44 bayt başlık, 16 bit mono 44,1 kHz.
      final want = (wav.lengthSync() - 44) / 2 / 44100;
      // ignore: avoid_print
      print('$name ${len.toStringAsFixed(3)} sn (asıl ${want.toStringAsFixed(3)})');
      expect((len - want).abs(), lessThan(0.02), reason: name);
      // Çalınabiliyor mu.
      final h = s.play(src, volume: 0);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(s.getIsValidVoiceHandle(h), isTrue, reason: name);
      s.stop(h);
      ok++;
    }
    expect(ok, files.length);
    s.deinit();
  });
}
