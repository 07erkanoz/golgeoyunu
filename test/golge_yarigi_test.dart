// Gölge yarığı (Kar Yolu): kapının kolu kapalı bir odada; yarıktan yalnız
// gölge geçer. Setin üstündeki gölge taşından gönderilen gölge kolu çeker,
// kapı açılır; Sâye setin altından kapıya, kapıdan öteye geçer.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/shadow_decoy.dart';

void main() {
  testWithGame<GolgeGame>(
    'gölge yarıktan geçer, kolu çeker; Sâye geçer',
    GolgeGame.new,
    (game) async {
      game.onGameResize(Vector2(1280, 720));
      final li = levels.indexWhere((d) => d.shadowCracks.isNotEmpty);
      expect(li, greaterThanOrEqualTo(0));
      game.debugLoadLevel(li);
      await game.ready();
      game.cinematic = false;
      for (final g in game.world.children.whereType<Guard>().toList()) {
        g.removeFromParent();
      }
      await game.ready();
      final (c, r0, _) = game.level.def.shadowCracks.first;
      // Sâye yarıktan geçemez.
      expect(game.level.solid(c, r0), isTrue);
      final stone = game.world.children.whereType<ShadowStone>().firstWhere(
        (s) => (s.position.x / kTile).floor() == c - 3,
      );
      final p = game.player!;
      p.position.setValues(
        stone.position.x - Player.w / 2,
        stone.position.y - Player.h,
      );
      p.velocity.setZero();
      for (var i = 0; i < 20; i++) {
        game.update(1 / 60);
      }
      expect(p.onGround, isTrue);
      // Sağa bakarak gölgeyi taştan gönder.
      game.controls.keyboard.right = true;
      game.update(1 / 60);
      game.controls.keyboard.right = false;
      p.position.x = stone.position.x - Player.w / 2;
      stone.use();
      expect(p.steeringShadow, isTrue, reason: 'oyuncu gölgeyi yürütür');
      final lever = game.world.children.whereType<Lever>().reduce(
        (a, b) =>
            (a.position.x - stone.position.x).abs() <
                (b.position.x - stone.position.x).abs()
            ? a
            : b,
      );
      // Gölgeyi sağa yürüt: yarıktan geçince dikenli çukurun üstünden atla,
      // sonra basamağa zıpla. Sâye yerinden kıpırdamaz.
      final saye = p.position.x;
      final k = game.controls.keyboard;
      k.right = true;
      var lastX = p.shadowFeet.x;
      for (var i = 0; i < 60 * 8 && !lever.pulled; i++) {
        final x = p.shadowFeet.x;
        final atPit = x > (c + 1) * kTile - 10 && x < (c + 1) * kTile;
        final stuck = i > 5 && (x - lastX).abs() < 0.01;
        k.jump = atPit || stuck;
        lastX = x;
        game.update(1 / 60);
      }
      k.right = k.jump = false;
      expect(p.position.x, closeTo(saye, 1), reason: 'Sâye donuk kaldı');
      expect(lever.pulled, isTrue, reason: 'gölge yarıktan geçip kolu çekti');
      // Kolu çeken gölge kendiliğinden döner: denetim Sâye'ye geçer.
      expect(p.steeringShadow, isTrue);
      for (var i = 0; i < 60; i++) {
        game.update(1 / 60);
      }
      expect(p.steeringShadow, isFalse, reason: 'kolu çeken gölge döndü');
      // Kapı açılsın; Sâye setin altından kapıya yürüyüp geçer.
      for (var i = 0; i < 60 * 3; i++) {
        game.update(1 / 60);
      }
      p.position.setFrom(
        Level.standOn(
          // Setin solundaki zeminde: çıkıntının altından geçide yürür.
          Vector2((c - 10) * kTile.toDouble(), 19 * kTile.toDouble()),
          Player.w,
          Player.h,
        ),
      );
      p.velocity.setZero();
      game.controls.keyboard.right = true;
      for (var i = 0; i < 60 * 6; i++) {
        game.update(1 / 60);
      }
      game.controls.keyboard.right = false;
      expect(p.isDead, isFalse);
      expect(p.position.x, greaterThan(333 * kTile), reason: 'kapıdan geçti');
    },
  );

  testWithGame<GolgeGame>(
    'zeminden çıkıntıya, oradan setin üstündeki gölge taşına çıkılır',
    GolgeGame.new,
    (game) async {
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(levels.indexWhere((d) => d.shadowCracks.isNotEmpty));
      await game.ready();
      game.cinematic = false;
      for (final g in game.world.children.whereType<Guard>().toList()) {
        g.removeFromParent();
      }
      final (c, _, _) = game.level.def.shadowCracks.first;
      final stone = game.world.children.whereType<ShadowStone>().firstWhere(
        (s) => (s.position.x / kTile).floor() == c - 3,
      );
      final p = game.player!;
      p.position.setFrom(
        Level.standOn(
          Vector2((c - 10) * kTile.toDouble(), 19 * kTile.toDouble()),
          Player.w,
          Player.h,
        ),
      );
      p.velocity.setZero();
      for (var i = 0; i < 20; i++) {
        game.update(1 / 60);
      }
      // Sağa koşar; çıkıntının dibinde zıplar (çıkıntıya), oradan sete.
      final k = game.controls.keyboard;
      k.right = true;
      var jumps = 0;
      for (var i = 0; i < 60 * 5 && !stone.canUse(p.center); i++) {
        final ledge = (c - 7) * kTile.toDouble();
        final wantJump =
            p.onGround &&
            ((jumps == 0 && p.center.x > ledge - 20) ||
                (jumps == 1 && p.center.x > ledge + kTile * 1.3));
        if (wantJump) jumps++;
        k.jump = wantJump || (!p.onGround && p.velocity.y < 0);
        game.update(1 / 60);
      }
      k.right = k.jump = false;
      expect(stone.canUse(p.center), isTrue, reason: 'taşa varıldı');
    },
  );

  testWithGame<GolgeGame>(
    'zıplamadan yürüyen gölge dikenli çukurda dağılır',
    GolgeGame.new,
    (game) async {
      game.onGameResize(Vector2(1280, 720));
      game.debugLoadLevel(levels.indexWhere((d) => d.shadowCracks.isNotEmpty));
      await game.ready();
      game.cinematic = false;
      final (c, _, _) = game.level.def.shadowCracks.first;
      final stone = game.world.children.whereType<ShadowStone>().firstWhere(
        (s) => (s.position.x / kTile).floor() == c - 3,
      );
      final p = game.player!;
      p.position.setValues(
        stone.position.x - Player.w / 2,
        stone.position.y - Player.h,
      );
      p.velocity.setZero();
      for (var i = 0; i < 20; i++) {
        game.update(1 / 60);
      }
      game.controls.keyboard.right = true;
      game.update(1 / 60);
      p.position.x = stone.position.x - Player.w / 2;
      stone.use();
      var shattered = false;
      for (var i = 0; i < 60 * 4 && !shattered; i++) {
        game.update(1 / 60);
        if (p.shadowSent && !p.steeringShadow) shattered = true;
      }
      game.controls.keyboard.right = false;
      expect(shattered, isTrue, reason: 'dikene düşen gölge dağıldı');
      final lever = game.world.children.whereType<Lever>().firstWhere(
        (l) => (l.position.x / kTile).floor() == c + 3,
      );
      expect(lever.pulled, isFalse);
    },
  );
}
