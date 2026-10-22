import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/auto_quality.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/settings.dart';

void main() {
  testWithGame<GolgeGame>(
    'Zorlanan cihazda önce ışık-derinlik, sonra ağır grafik kapanır',
    GolgeGame.new,
    (game) async {
      final realism = Realism.on;
      final low = Settings.lowGraphics;
      addTearDown(() {
        Realism.on = realism;
        Settings.lowGraphics = low;
        AutoQuality.userChose = false;
      });
      Realism.on = true;
      Settings.lowGraphics = false;
      game.debugLoadLevel(0);
      await game.ready();
      expect(game.autoQuality.stepDown(), isTrue);
      expect(Realism.on, isFalse);
      expect(Settings.lowGraphics, isFalse);
      expect(game.autoQuality.stepDown(), isTrue);
      expect(Settings.lowGraphics, isTrue);
      expect(game.autoQuality.stepDown(), isFalse);
    },
  );
}
