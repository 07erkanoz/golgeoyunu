// Perde sesleri gerçek ses motoruyla: Yerebatan'ın çıkışından Kule perdesine
// geçilir, her satırın sesi çalınıyor mu yazılır.
// `flutter test --dart-define=AUDIO_LOG=true tools/bench/perde_ses_test.dart`
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/audio.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => Directory.systemTemp.path,
      );
  testWithGame<GolgeGame>('Kule perdesi sesli', GolgeGame.new, (game) async {
    await GameAudio.instance.init();
    // ignore: avoid_print
    print('ses motoru hazır, yüklenemeyen: ${GameAudio.instance.failed}');
    Settings.voice = true;
    Settings.voiceVolume = 0.9;
    Settings.subtitles = false;
    Settings.skipSeenPerde = false;
    game.onGameResize(Vector2(870, 391));
    game.debugLoadLevel(0);
    await game.ready();
    game.onExitReached();
    var t = 0.0;
    var spoke = 0;
    var wasBusy = false;
    // Telefon gibi: arada bir uzun takılma (ekran kartı) ve yavaş yükleme.
    var frame = 0;
    while (t < 140 && game.levelIndex == 0) {
      frame++;
      final dt = frame % 45 == 0 ? 0.6 : 1 / 30;
      game.update(dt);
      t += dt;
      final busy = GameAudio.instance.voiceBusy;
      if (busy && !wasBusy) spoke++;
      wasBusy = busy;
      await Future<void>.delayed(Duration(milliseconds: frame % 45 == 0 ? 250 : 1));
    }
    // ignore: avoid_print
    print('perde bitti: ${t.toStringAsFixed(0)} sn, ses başlayan satır $spoke, bölüm ${game.levelIndex}');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
