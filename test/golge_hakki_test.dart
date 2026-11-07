// Gölge hakkı: Sâye gölgesini gölge taşı olmadan da gönderebilir; elde en
// çok iki; bölümde gölgenin sırları (gölge oyunu, utangaç gölge, Karagöz)
// ilk görüldüğünde birer tane verir; kayıtta saklanır.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/shadow_decoy.dart';
import 'package:golge/settings.dart';

Future<void> _kur(GolgeGame game) async {
  game.onGameResize(Vector2(1280, 720));
  game.debugLoadLevel(0);
  await game.ready();
  game.cinematic = false;
  // Sâye yere otursun.
  for (var i = 0; i < 30; i++) {
    game.update(1 / 60);
  }
}

void main() {
  testWithGame<GolgeGame>(
    'en çok iki hak; gölge oyunu bir hak verir',
    GolgeGame.new,
    (game) async {
      await _kur(game);
      game.shadowCharges = 0;
      game.foundSecret('golgeOyunu');
      expect(game.shadowCharges, 1);
      game.foundSecret('golgeOyunu');
      expect(game.shadowCharges, 1, reason: 'ikinci kez vermez');
      game.gainShadowCharge();
      game.gainShadowCharge();
      expect(game.shadowCharges, GolgeGame.maxShadowCharges);
    },
  );

  testWithGame<GolgeGame>(
    'Karagöz ve utangaç gölge hak verir; eller doluysa ateşböceği',
    GolgeGame.new,
    (game) async {
      await _kur(game);
      game.shadowCharges = 0;
      final f0 = game.fireflies;
      game.foundSecret('karagoz');
      expect(game.shadowCharges, 1);
      expect(game.fireflies, f0, reason: 'hak verdi, ateşböceği değil');
      game.foundSecret('utangac');
      expect(game.shadowCharges, 2);
      // Eller dolu: Karagöz yine ödülsüz kalmaz.
      game.debugLoadLevel(1);
      await game.ready();
      game.shadowCharges = GolgeGame.maxShadowCharges;
      final f1 = game.fireflies;
      game.foundSecret('karagoz');
      expect(game.shadowCharges, GolgeGame.maxShadowCharges);
      expect(game.fireflies, f1 + 1);
      // Gölge oyunu eller doluyken bir şey vermez (boş durmak ödüllenmez).
      final f2 = game.fireflies;
      game.foundSecret('golgeOyunu');
      expect(game.fireflies, f2);
    },
  );

  testWithGame<GolgeGame>(
    'hakla gölge her yerden gönderilir, hak azalır',
    GolgeGame.new,
    (game) async {
      await _kur(game);
      final p = game.player!;
      expect(p.onGround, isTrue);
      game.shadowCharges = 0;
      expect(game.sendShadowCharge(), isFalse, reason: 'hak yokken olmaz');
      game.shadowCharges = 2;
      expect(game.sendShadowCharge(), isTrue);
      expect(game.shadowCharges, 1);
      expect(p.shadowSent, isTrue);
      await game.ready();
      expect(game.world.children.whereType<ShadowDecoy>(), isNotEmpty);
      expect(game.sendShadowCharge(), isFalse, reason: 'gölge zaten gitmiş');
      expect(game.shadowCharges, 1);
    },
  );

  test('kayıtta gölge hakları saklanır (eski kayıtta sıfır)', () {
    final d = SaveData(
      level: 3,
      x: 10,
      y: 20,
      memories: const [],
      whispers: const [],
      fireflies: 2,
      wings: true,
      shadows: 2,
    );
    expect(SaveData.decode(d.encode())!.shadows, 2);
    final old = d.encode().replaceAll('"shadows":2,', '');
    expect(SaveData.decode(old)!.shadows, 0);
  });
}
