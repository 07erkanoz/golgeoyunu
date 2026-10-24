// Ayarların hepsi kaydedilir; gizli dokunuşla her şey açılınca Hikâye
// tiyatrosu sonuna dek oynar.
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/perde.dart';
import 'package:golge/settings.dart';
import 'package:golge/ui/story_theater.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('deneme ayarları kaydedilir ve yeniden açılışta uygulanır', () async {
    Settings.debugReopen();
    SharedPreferences.setMockInitialValues({});
    await Settings.load();
    Settings.texture = false;
    Settings.realism = false;
    Settings.perf = true;
    Settings.tone = 0.35;
    Settings.allOpen = true;
    await Settings.save();
    // "Yeniden açılış": bellek varsayılana döner, sonra diskten okunur.
    Settings.texture = true;
    Settings.realism = true;
    Settings.perf = false;
    Settings.tone = 0;
    Settings.allOpen = false;
    await Settings.load();
    expect(Settings.texture, isFalse);
    expect(Settings.realism, isFalse);
    expect(Settings.perf, isTrue);
    expect(Settings.tone, closeTo(0.35, 1e-9));
    expect(Settings.allOpen, isTrue);
    expect(Settings.unlocked, levelOrder.length - 1);
    if (Cartoon.trialBuild) {
      expect(Cartoon.on, isFalse);
      expect(Realism.on, isFalse);
    }
  });

  test(
    'ilk açılışta varsayılanlar: ton 35, parlaklık 85, grafik yüksek',
    () async {
      Settings.debugReopen();
      SharedPreferences.setMockInitialValues({});
      Settings.lowGraphics = true;
      await Settings.load();
      expect(Settings.tone, closeTo(0.35, 1e-9));
      expect(Settings.brightness, closeTo(0.85, 1e-9));
      expect(Settings.lowGraphics, isFalse);
      expect(Settings.realism, Cartoon.trialBuild);
      expect(Settings.texture, Cartoon.trialBuild);
    },
  );

  test(
    'eski kayıt bir kez yeni varsayılanlara çekilir, sonra seçim kalır',
    () async {
      Settings.debugReopen();
      SharedPreferences.setMockInitialValues({
        'flutter.tone': 0.0,
        'flutter.brightness': 1.3,
        'flutter.low_graphics': true,
        'flutter.realism': false,
        'flutter.music': 0.2,
        'flutter.auto_quality': true,
      });
      await Settings.load();
      expect(Settings.tone, closeTo(0.35, 1e-9));
      expect(Settings.brightness, closeTo(0.85, 1e-9));
      expect(Settings.lowGraphics, isFalse);
      expect(Settings.realism, Cartoon.trialBuild);
      expect(Settings.music, closeTo(0.2, 1e-9));
      // Oyuncu yeniden değiştirir: artık her açılışta seçimi gelir.
      Settings.tone = 0.6;
      Settings.brightness = 1.1;
      Settings.lowGraphics = true;
      await Settings.save();
      Settings.tone = 0;
      Settings.brightness = 1;
      Settings.lowGraphics = false;
      await Settings.load();
      expect(Settings.tone, closeTo(0.6, 1e-9));
      expect(Settings.brightness, closeTo(1.1, 1e-9));
      expect(Settings.lowGraphics, isTrue);
    },
  );

  test('her şey açıkken Hikâye tiyatrosu son perdeye dek oynar', () {
    Settings.finished = false;
    Settings.allOpen = true;
    Settings.unlocked = levelOrder.length - 1;
    final acts = StoryTheater.acts();
    expect(acts.last.$1, PerdeScene.epilogue);
    expect(StoryTheater.complete, isTrue);
    // Bütün bölümlerin perdeleri de içinde.
    for (final lv in levelOrder.skip(1)) {
      final scene = interludeScene(lv);
      if (scene == null || interludeText(lv).isEmpty) continue;
      expect(acts.any((a) => a.$2 == interludeText(lv)), isTrue, reason: '$lv');
    }
    Settings.allOpen = false;
  });
}
