// Açılış girişinin sesleri gerçek ses motoruyla: girişin beklediği sesler
// (kibrit, ney…) bütün efektlerden önce yüklenir; ne zaman hazır oldukları
// ölçülür. `flutter test tools/bench/giris_sesleri_test.dart`
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/audio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => Directory.systemTemp.path,
      );
  final a = GameAudio.instance;

  test('giriş sesleri önce yüklenir', () async {
    final sw = Stopwatch()..start();
    double? ready;
    double? allLoaded;
    final done = a.init().then(
      (_) => allLoaded = sw.elapsedMilliseconds / 1000,
    );
    while (allLoaded == null && sw.elapsed.inSeconds < 60) {
      if (ready == null && a.introReady) ready = sw.elapsedMilliseconds / 1000;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await done;
    // ignore: avoid_print
    print(
      'giriş hazır: ${ready?.toStringAsFixed(2)} sn · bütün sesler: '
      '${allLoaded?.toStringAsFixed(2)} sn · kibrit ${a.has('match')}',
    );
    expect(ready, isNotNull);
    expect(ready!, lessThan(allLoaded!));
    expect(a.has('match'), isTrue);
  });
}
