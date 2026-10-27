// XV · Ak Ana'nın Denizi: suyun altında yüzüş ve nefes; hava cebi, akıntı,
// denizanası, mürekkep, fenerbalığı, kaplumbağa, kol ve kapı, sandalın
// feneri, kabarcık sütunu, Ak Ana.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/deniz.dart';
import 'package:golge/game/deniz_koy.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/erlik.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/maps.dart';
import 'package:golge/game/player.dart';

const _sea = 20;

void run(GolgeGame game, double s) {
  for (var i = 0; i < (s * 60).round(); i++) {
    game.update(1 / 60);
  }
}

Future<Player> load(GolgeGame game, {bool calm = true}) async {
  game.onGameResize(Vector2(1280, 720));
  game.debugLoadLevel(_sea);
  await game.ready();
  game.cinematic = false;
  if (calm) {
    // Kural testleri tek düzeneği dener: başka canlılar karışmasın.
    for (final c in game.world.children.toList()) {
      if (c is AnglerHunter ||
          c is StingingJelly ||
          c is LanternBoat ||
          c is Kormos ||
          c is SeaCurrent) {
        c.removeFromParent();
      }
    }
    await game.ready();
  }
  return game.player!;
}

/// Sâye'yi bir hücrenin ortasına koyar.
void put(Player p, double c, double r) {
  p.position.setValues(
    (c + 0.5) * kTile - Player.w / 2,
    (r + 0.5) * kTile - Player.h / 2,
  );
  p.velocity.setZero();
}

void main() {
  test('bölüm sırada Ötüken ile Erlik arasında', () {
    expect(levels[_sea].title, 'XV · AK ANA\'NIN DENİZİ');
    expect(levels[_sea].theme, LevelTheme.sea);
    final i = levelOrder.indexOf(_sea);
    expect(levelOrder[i - 1], 17);
    expect(levelOrder[i + 1], 14);
    // Eski kayıttaki yer yeni sıraya çevrilir: Erlik'te kalan Erlik'te.
    expect(levelOrder[migrateOrderPosition(14, 7)], 14);
    expect(interludeText(_sea), isNotEmpty);
    expect(bridgeText(_sea), isNotEmpty);
  });

  testWithGame<GolgeGame>(
    'suyun altında nefes azalır, havada dolar',
    GolgeGame.new,
    (game) async {
      final p = await load(game);
      put(p, 270, 22);
      run(game, 0.2);
      expect(p.swimming, isTrue);
      run(game, 5);
      expect(game.breath, closeTo(1 - 5.2 / GolgeGame.breathTime, 0.04));
      // Hava cebinde (kıyısında durur) nefes dolar.
      final (c0, r0, c1, r1) = kDenizAir.first;
      put(p, c1 - 1.0, r1 - 1.0);
      run(game, 1.5);
      expect(p.swimming, isFalse);
      expect(game.breath, greaterThan(0.99));
    },
  );

  testWithGame<GolgeGame>('nefes bitince bir an sonra bayılır', GolgeGame.new, (
    game,
  ) async {
    final p = await load(game);
    put(p, 270, 22);
    run(game, 0.2);
    game.breath = 0;
    run(game, GolgeGame.drownTime - 0.5);
    expect(p.isDead, isFalse, reason: 'önce bulanır');
    run(game, 1);
    expect(p.isDead, isTrue);
    expect(p.deathCause, DeathCause.water);
  });

  testWithGame<GolgeGame>(
    'yukarı yüzen hava cebine çıkar, kıyıya tutunur',
    GolgeGame.new,
    (game) async {
      final p = await load(game);
      final (c0, r0, c1, r1) = kDenizAir.first;
      put(p, c0 + 2.0, r1 + 3.0);
      run(game, 0.2);
      expect(p.swimming, isTrue);
      // Cebin açık suyuna doğru yukarı: yüzeyde başı dışarıda süzülür,
      // nefes alır; kulaçla (kıyıya doğru) sudan çıkar.
      game.controls.keyboard.up = true;
      run(game, 2.5);
      game.controls.keyboard.up = false;
      expect(p.swimming, isTrue, reason: 'yüzeyde süzülür');
      expect(game.level.surfaceAbove(p.center.x, p.center.y), isNotNull);
      game.breath = 0.5;
      run(game, 0.5);
      expect(game.breath, greaterThan(0.6), reason: 'yüzeyde nefes alır');
      // Yüzeyde kıyıya doğru yüzer, kıyının dibinde kulaçla çıkar.
      game.controls.keyboard.right = true;
      run(game, 1.0);
      game.controls.keyboard.jump = true;
      run(game, 0.05);
      game.controls.keyboard.jump = false;
      run(game, 1.2);
      game.controls.keyboard.right = false;
      run(game, 1.0);
      expect(p.swimming, isFalse, reason: 'sudan çıktı');
      expect(p.isDead, isFalse);
      expect(
        p.state == PlayerState.normal && p.onGround ||
            p.state == PlayerState.hang ||
            p.state == PlayerState.climbUp,
        isTrue,
        reason:
            'kıyıya bastı ya da tutundu (${p.state}, ${p.position / kTile})',
      );
    },
  );

  testWithGame<GolgeGame>('kulaç süzülerek ilerletir', GolgeGame.new, (
    game,
  ) async {
    final p = await load(game);
    put(p, 40, 15);
    run(game, 0.3);
    final x0 = p.center.x;
    game.controls.keyboard.jump = true;
    run(game, 0.05);
    game.controls.keyboard.jump = false;
    run(game, 1.2);
    expect(p.center.x - x0, greaterThan(2 * kTile), reason: 'tek kulaç');
  });

  testWithGame<GolgeGame>('akıntı akış yönünde iter', GolgeGame.new, (
    game,
  ) async {
    final p = await load(game, calm: false);
    for (final c in game.world.children.toList()) {
      if (c is AnglerHunter || c is StingingJelly || c is Kormos) {
        c.removeFromParent();
      }
    }
    await game.ready();
    put(p, 440, 28);
    run(game, 1.5);
    expect(p.center.x, lessThan(437 * kTile), reason: 'sola taşındı');
  });

  testWithGame<GolgeGame>(
    'denizanası sokar: savurur, nefesten alır',
    GolgeGame.new,
    (game) async {
      final p = await load(game);
      final jelly = StingingJelly(150, 20, 0);
      game.world.add(jelly);
      await game.ready();
      put(p, 300, 26);
      run(game, 0.3);
      p.position.setValues(jelly.position.x - Player.w / 2, jelly.position.y);
      p.velocity.setZero();
      final before = game.breath;
      run(game, 0.1);
      expect(game.breath, lessThan(before - 0.1));
      expect(p.velocity.length, greaterThan(100));
    },
  );

  testWithGame<GolgeGame>(
    'fenerbalığı ışığındakini yutar; mürekkep saklar',
    GolgeGame.new,
    (game) async {
      final p = await load(game);
      final fish = AnglerHunter(150, 20, 0);
      game.world.add(fish);
      await game.ready();
      run(game, 0.1);
      // Yemin ışığında: önce mürekkebin içinde.
      void beside() {
        final l = fish.lure;
        p.position.setValues(l.x - Player.w / 2 + 40.0 * fish.dir, l.y + 10);
        p.velocity.setZero();
      }

      beside();
      game.world.add(InkCloud(p.center.clone()));
      await game.ready();
      run(game, 0.6);
      beside();
      run(game, 0.6);
      expect(fish.hunting, isFalse, reason: 'mürekkepte görünmez');
      expect(p.isDead, isFalse);
      // Mürekkep dağılınca görür ve yutar.
      run(game, InkCloud.life);
      for (var i = 0; i < 40 && !p.isDead; i++) {
        beside();
        run(game, 0.1);
      }
      expect(p.isDead, isTrue);
    },
  );

  testWithGame<GolgeGame>('yosun saklar', GolgeGame.new, (game) async {
    final p = await load(game);
    final kelp = game.world.children.whereType<Kelp>().firstWhere(
      (k) => k.front && k.tall > 3 * kTile,
    );
    p.position.setValues(
      kelp.position.x - Player.w / 2,
      kelp.position.y - kelp.tall * 0.5,
    );
    p.velocity.setZero();
    run(game, 0.1);
    expect(p.swimming, isTrue);
    expect(p.hidden, isTrue);
  });

  testWithGame<GolgeGame>(
    'kaplumbağa sırtında yolun sonuna taşır',
    GolgeGame.new,
    (game) async {
      final p = await load(game);
      final t = game.world.children.whereType<SeaTurtle>().first;
      p.position.setValues(
        t.position.x - Player.w / 2,
        t.position.y - Player.h / 2,
      );
      p.velocity.setZero();
      run(game, 0.2);
      expect(t.carrying, isTrue);
      run(game, 8);
      expect(t.carrying, isFalse);
      final end = t.path.last;
      expect((p.center - end).length, lessThan(7 * kTile));
    },
  );

  testWithGame<GolgeGame>(
    'cepteki kol alt koridorun kapısını açar',
    GolgeGame.new,
    (game) async {
      final p = await load(game);
      final lever = game.world.children.whereType<Lever>().first;
      final gate = game.world.children.whereType<Gate>().first;
      p.position.setFrom(
        Level.standOn(
          Vector2(lever.position.x, lever.position.y - kTile),
          Player.w,
          Player.h,
        ),
      );
      p.velocity.setZero();
      run(game, 0.5);
      expect(p.swimming, isFalse);
      game.controls.keyboard.up = true;
      run(game, 0.1);
      game.controls.keyboard.up = false;
      run(game, 0.5);
      expect(lever.pulled, isTrue);
      expect(gate.opening, isTrue);
    },
  );

  testWithGame<GolgeGame>(
    'sandalın fenerinin ışığında görünen yakalanır',
    GolgeGame.new,
    (game) async {
      final p = await load(game);
      final boat = LanternBoat(30, 31, game.level.seaTop!);
      game.world.add(boat);
      await game.ready();
      run(game, 0.1);
      for (var i = 0; i < 60 && !p.isDead; i++) {
        final at = boat.lamp + Vector2(0, 3 * kTile);
        p.position.setValues(at.x - Player.w / 2, at.y - Player.h / 2);
        p.velocity.setZero();
        run(game, 1 / 30);
        if (!boat.lit(p.center)) continue;
      }
      expect(p.isDead, isTrue);
      expect(p.deathCause, DeathCause.light);
    },
  );

  testWithGame<GolgeGame>(
    'kabarcık sütunu nefes verir, yukarı taşır',
    GolgeGame.new,
    (game) async {
      final p = await load(game);
      final vent = game.world.children.whereType<BubbleVent>().first;
      p.position.setValues(vent.base.x - Player.w / 2, vent.base.y - 3 * kTile);
      p.velocity.setZero();
      game.breath = 0.3;
      final y0 = p.center.y;
      run(game, 0.6);
      expect(game.breath, greaterThan(0.3));
      expect(p.center.y, lessThan(y0 - 10));
    },
  );

  testWithGame<GolgeGame>(
    'Ak Ana yükselir: ak nefes, Körmösler dağılır',
    GolgeGame.new,
    (game) async {
      final p = await load(game, calm: false);
      for (final c in game.world.children.toList()) {
        if (c is AnglerHunter || c is StingingJelly) c.removeFromParent();
      }
      await game.ready();
      final ak = game.world.children.whereType<AkAnaSea>().first;
      expect(game.world.children.whereType<Kormos>(), isNotEmpty);
      p.position.setValues(
        ak.position.x - Player.w / 2,
        ak.position.y - 6 * kTile,
      );
      p.velocity.setZero();
      run(game, 0.2);
      expect(game.akNefes, isTrue);
      run(game, 2);
      expect(game.world.children.whereType<Kormos>(), isEmpty);
      final b = game.breath;
      run(game, 3);
      expect(game.breath, greaterThanOrEqualTo(b), reason: 'ak nefes azalmaz');
    },
  );

  testWithGame<GolgeGame>(
    'Kişi\'nin taşına sudan çıkılır, öbür yandan yeniden dalınır',
    GolgeGame.new,
    (game) async {
      final p = await load(game);
      put(p, 491, kDenizSurface + 2.0);
      run(game, 0.3);
      expect(p.swimming, isTrue);
      game.controls.keyboard.up = true;
      run(game, 2);
      game.controls.keyboard
        ..up = false
        ..right = true;
      run(game, 0.8);
      game.controls.keyboard.jump = true;
      run(game, 0.05);
      game.controls.keyboard.jump = false;
      // Yüzüş hızlandı: taşa daha erken varır; sağ tuşu bırakılmazsa taşın
      // öbür ucundan suya iner.
      run(game, 0.75);
      game.controls.keyboard.right = false;
      run(game, 1.0);
      expect(p.swimming, isFalse, reason: 'taşın üstünde');
      expect(p.onGround, isTrue, reason: '${p.state} ${p.position / kTile}');
      expect(p.center.x, greaterThan(494 * kTile));
      // Öbür yana yürüyüp yeniden suya.
      game.controls.keyboard.right = true;
      run(game, 2);
      game.controls.keyboard.right = false;
      run(game, 0.5);
      expect(p.swimming, isTrue);
      expect(p.center.x, greaterThan(499 * kTile));
    },
  );

  testWithGame<GolgeGame>(
    'Yunus Koyu: basılı tutulan kulaç hızlı yüzdürür, nefes çabuk biter',
    GolgeGame.new,
    (game) async {
      final p = await load(game);
      put(p, 110, 20);
      run(game, 0.2);
      game.controls.keyboard.right = true;
      run(game, 1.5);
      final cruise = p.velocity.length;
      final b0 = game.breath;
      game.controls.keyboard.jump = true;
      run(game, 1.5);
      expect(p.boosting, isTrue);
      expect(p.velocity.length, greaterThan(cruise + 60));
      final used = b0 - game.breath;
      expect(used, greaterThan(1.5 / GolgeGame.breathTime * 1.4));
      game.controls.keyboard
        ..jump = false
        ..right = false;
    },
  );

  testWithGame<GolgeGame>(
    'Yunus Koyu: hızla yüzeye çıkan sıçrar, takla atar; gökte kara kaz',
    GolgeGame.new,
    (game) async {
      final p = await load(game);
      put(p, 120, 16);
      run(game, 0.2);
      game.controls.keyboard
        ..up = true
        ..jump = true;
      var top = p.center.y;
      for (var i = 0; i < 120; i++) {
        run(game, 1 / 60);
        top = top < p.center.y ? top : p.center.y;
      }
      game.controls.keyboard
        ..up = false
        ..jump = false;
      final surface = kDenizSurface * kTile;
      expect(surface - top, greaterThan(3 * kTile), reason: 'sudan sıçradı');
      expect(game.secretSeen('karaKaz'), isTrue);
      run(game, 2);
      expect(p.swimming, isTrue, reason: 'suya döndü');
    },
  );

  testWithGame<GolgeGame>(
    'Yunus Koyu: yunusların yanında hızlanılır',
    GolgeGame.new,
    (game) async {
      final p = await load(game);
      final pod = game.world.children.whereType<DolphinPod>().first;
      run(game, 0.5);
      put(p, kDenizDolphins.first.$1 + 4.0, kDenizDolphins.first.$3.toDouble());
      var boosted = false;
      for (var i = 0; i < 600 && !boosted; i++) {
        run(game, 1 / 60);
        boosted = p.dolphinBoost > 0;
      }
      expect(pod.isMounted, isTrue);
      expect(boosted, isTrue);
    },
  );

  testWithGame<GolgeGame>(
    'Yunus Koyu: açık midyenin incisi nefes verir',
    GolgeGame.new,
    (game) async {
      final p = await load(game);
      final clam = game.world.children.whereType<PearlClam>().first;
      game.breathe(-0.6);
      while (clam.open < 1) {
        run(game, 0.05);
      }
      p.position.setValues(clam.x - Player.w / 2, clam.y - 9 - Player.h / 2);
      p.velocity.setZero();
      run(game, 0.1);
      expect(clam.hasPearl, isFalse);
      expect(game.breath, greaterThan(0.95));
    },
  );

  testWithGame<GolgeGame>(
    'Yunus Koyu: batık geminin sandığı ateşböceği verir',
    GolgeGame.new,
    (game) async {
      final p = await load(game);
      final chest = game.world.children.whereType<TreasureChest>().first;
      final before = game.world.children.whereType<FireflySwarm>().length;
      p.position.setValues(chest.x - Player.w / 2, chest.y - 20 - Player.h / 2);
      p.velocity.setZero();
      run(game, 0.2);
      expect(chest.opened, isTrue);
      expect(game.world.children.whereType<FireflySwarm>().length, before + 3);
    },
  );

  testWithGame<GolgeGame>(
    'Yunus Koyu: balık sürüsü ardına takılır',
    GolgeGame.new,
    (game) async {
      final p = await load(game);
      final shoal = game.world.children.whereType<FriendlyShoal>().first;
      put(p, kDenizShoal.$1.toDouble(), kDenizShoal.$2.toDouble());
      run(game, 0.5);
      expect(shoal.following, isTrue);
      game.controls.keyboard.right = true;
      run(game, 3);
      game.controls.keyboard.right = false;
      run(game, 1.5);
      expect(shoal.following, isTrue);
    },
  );

  testWithGame<GolgeGame>(
    'kıyıdaki Umay ağacı bölümün ilk rivayetini anlatır',
    GolgeGame.new,
    (game) async {
      await load(game);
      game.narration.resetScene();
      final tree = game.level.checkpointCells.reduce(
        (a, b) => a.x < b.x ? a : b,
      );
      final p = game.player!;
      p.position.setFrom(Level.standOn(tree, Player.w, Player.h));
      p.velocity.setZero();
      final text = levels[_sea].whisperTexts[1];
      var heard = false;
      for (var i = 0; i < 60 * 5 && !heard; i++) {
        game.update(1 / 60);
        // Sessiz test ortamında yazı parça parça akar.
        heard = game.narration.debugWhispers.any(
          (w) => text.startsWith(w.split(';').first),
        );
      }
      expect(heard, isTrue);
    },
  );
}
