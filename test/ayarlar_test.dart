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
