// Anlatım saati gerçek ses motoruyla: (A) oyun ve Hikâye oynatıcısı her
// karede birlikte güncellese de 7,2 sn'lik satır sonuna dek çalar; (B) ses
// motoru açılmadan istenen satır hazır olunca çalar; (C) duraklatılan satır
// kaldığı yerden sürer. `flutter test tools/bench/anlatim_saati_test.dart`
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/audio.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => Directory.systemTemp.path,
      );
  final a = GameAudio.instance;
  final line = prologueText.firstWhere((l) => l.contains('1660'));

  Future<double> playFor(double seconds, {int updatesPerFrame = 2}) async {
    final sw = Stopwatch()..start();
    var lastPlaying = 0.0;
    while (sw.elapsedMilliseconds < seconds * 1000) {
      for (var i = 0; i < updatesPerFrame; i++) {
        a.updateVoice(1 / 60);
      }
      if (a.voicePlaying) lastPlaying = sw.elapsedMilliseconds / 1000;
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    return lastPlaying;
  }

  test('anlatım saati', () async {
    Settings.voice = true;
    Settings.voiceVolume = 0.9;
    // (B) Motor açılmadan istenir.
    a.speak(line, interrupt: true);
    // ignore: avoid_print
    print('motor açılmadan: ${a.voiceStatus}');
    await a.init();
    // (A) İki döngü birlikte günceller (oyun + Hikâye oynatıcısı).
    final last = await playFor(9);
    // ignore: avoid_print
    print('"1660" satırı ${last.toStringAsFixed(2)} sn çaldı · ${a.voiceStatus}');
    expect(last, greaterThan(6.8), reason: 'satır yarıda kesilmemeli');
    expect(last, lessThan(8.2));
    // (C) Duraklatma: 3 sn çal, 2 sn dur, devam et.
    a.speak(line, interrupt: true);
    await playFor(3);
    a.pauseAll();
    await playFor(2);
    a.resumeAll();
    final rest = await playFor(6);
    // ignore: avoid_print
    print('duraklatmadan sonra ${rest.toStringAsFixed(2)} sn daha çaldı');
    expect(rest, greaterThan(3.6));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
