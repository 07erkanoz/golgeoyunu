import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

/// Sabit adımlı simülasyon: oyuncuyu bir hücreye koyar, girişi uygular.
Future<Player> place(GolgeGame game, int levelIndex, int col, int row) async {
  game.debugLoadLevel(levelIndex);
  await game.ready();
  game.cinematic = false;
  final p = game.player!;
  p.position.setFrom(
    Level.standOn(Vector2(col * kTile, row * kTile), Player.w, Player.h),
  );
  return p;
}

void run(GolgeGame game, double seconds) {
  for (var t = 0.0; t < seconds; t += 1 / 60) {
    game.update(1 / 60);
  }
}

void main() {
  Buttons buttons(GolgeGame g) => g.controls.keyboard;

  testWithGame<GolgeGame>('zıplama yaklaşık 3 kare yükselir', GolgeGame.new, (
    game,
  ) async {
    final p = await place(game, 0, 3, 9);
    run(game, 0.3);
    final ground = p.position.y;
    buttons(game).jump = true;
    var minY = ground;
    for (var i = 0; i < 60; i++) {
      game.update(1 / 60);
      if (p.position.y < minY) minY = p.position.y;
    }
    final rise = ground - minY;
    expect(rise, inInclusiveRange(80, 100));
  });

  testWithGame<GolgeGame>(
    'iskeledeki boşluğun üstünden atlanabilir',
    GolgeGame.new,
    (game) async {
      final p = await place(game, 0, 10, 9);
      run(game, 0.2);
      buttons(game).right = true;
      // Kenara kadar koş, sonra zıpla.
      for (
        var i = 0;
        i < 300 && p.position.x + Player.w < 15 * kTile - 4;
        i++
      ) {
        game.update(1 / 60);
      }
      buttons(game).jump = true;
      run(game, 1.0);
      expect(p.isDead, isFalse);
      expect(p.position.x, greaterThan(17 * kTile));
    },
  );

  testWithGame<GolgeGame>(
    '3 karelik duvarda kenara tutunup tırmanır',
    GolgeGame.new,
    (game) async {
      final p = await place(game, 0, 56, 9);
      run(game, 0.2);
      buttons(game).right = true;
      run(game, 0.4); // duvara dayan
      buttons(game).jump = true;
      var grabbed = false;
      for (var i = 0; i < 90 && !grabbed; i++) {
        game.update(1 / 60);
        grabbed = p.state == PlayerState.hang;
      }
      expect(grabbed, isTrue, reason: 'kenara tutunamadı');
      buttons(game).jump = false;
      run(game, 0.1);
      buttons(game).up = true;
      run(game, 0.6);
      buttons(game).up = false;
      run(game, 0.2);
      expect(p.onGround, isTrue);
      expect(p.position.y + Player.h, closeTo(7 * kTile, 0.5));
    },
  );

  testWithGame<GolgeGame>('sarnıcın suyuna düşen boğulur', GolgeGame.new, (
    game,
  ) async {
    final p = await place(game, 0, 15, 9);
    run(game, 1.0);
    expect(p.isDead, isTrue);
  });

  testWithGame<GolgeGame>(
    'sütunun ardında duran oyuncu gizlenir',
    GolgeGame.new,
    (game) async {
      final p = await place(game, 0, 26, 9);
      run(game, 0.3);
      expect(p.hidden, isTrue);
      buttons(game).down = true;
      buttons(game).right = true;
      run(game, 0.2);
      expect(p.inShadow, isTrue);
      expect(
        p.hidden,
        isTrue,
        reason: 'sütunun ardında sürünen oyuncu gizli kalır',
      );
      buttons(game).down = false;
      run(game, 0.12);
      expect(p.hidden, isFalse, reason: 'koşan oyuncu görünür');
    },
  );

  testWithGame<GolgeGame>('sarmaşığa tutunup tırmanır', GolgeGame.new, (
    game,
  ) async {
    final p = await place(game, 1, 15, 37); // kaya çıkıntısının üstü (satır 38)
    run(game, 0.2);
    expect(p.onGround, isTrue);
    buttons(game).left = true;
    buttons(game).jump = true;
    var onVine = false;
    for (var i = 0; i < 90 && !onVine; i++) {
      game.update(1 / 60);
      onVine = p.state == PlayerState.vine;
    }
    expect(onVine, isTrue, reason: 'sarmaşığı yakalayamadı');
    buttons(game)
      ..left = false
      ..jump = false
      ..up = true;
    run(game, 4);
    // Sarmaşığın tepesine (satır 25) ulaştı.
    expect(p.position.y + Player.h / 2, lessThan(26 * kTile));
  });

  testWithGame<GolgeGame>(
    'sarmaşığın tepesinden sol çıkıntıya atlanır',
    GolgeGame.new,
    (game) async {
      final p = await place(game, 1, 12, 30);
      buttons(game).up = true;
      run(game, 0.1);
      expect(p.state, PlayerState.vine);
      run(game, 3);
      buttons(game)
        ..up = false
        ..left = true
        ..jump = true;
      run(game, 1.2);
      buttons(game)
        ..jump = false
        ..up = true;
      run(game, 0.8);
      expect(p.onGround, isTrue);
      expect(p.position.y + Player.h, closeTo(25 * kTile, 0.5));
    },
  );

  testWithGame<GolgeGame>(
    'saklanan oyuncunun önünden Kandilci geçip gider',
    GolgeGame.new,
    (game) async {
      // Kandilci 33. sütundan sola yürür; oyuncu önceden 21. sütundaki
      // sütunun ardına saklanmıştır.
      final p = await place(game, 0, 21, 9);
      run(game, 0.3);
      expect(p.hidden, isTrue);
      final guard = game.world.children.whereType<Guard>().first;
      var passed = false;
      for (var i = 0; i < 60 * 12; i++) {
        game.update(1 / 60);
        if (guard.position.x + Guard.gw < p.position.x) {
          passed = true;
        }
      }
      expect(p.isDead, isFalse);
      expect(passed, isTrue, reason: 'Kandilci oyuncunun önünden geçmeliydi');
    },
  );

  testWithGame<GolgeGame>(
    'salınan ateşböceği Kandilciyi kendine çeker',
    GolgeGame.new,
    (game) async {
      await place(game, 0, 3, 9);
      run(game, 0.2);
      final guard = game.world.children.whereType<Guard>().first;
      final before = game.fireflies;
      game.releaseFirefly(guard.position + Vector2(-120, 10), -1);
      run(game, 0.5);
      expect(game.fireflies, before - 1);
      expect(guard.state, GuardState.investigate);
    },
  );

  testWithGame<GolgeGame>(
    'kavanozu ören oyuncu yavaşlar ve ışığı kısılır',
    GolgeGame.new,
    (game) async {
      final p = await place(game, 0, 3, 9);
      run(game, 0.2);
      final open = p.light.$2;
      buttons(game)
        ..cover = true
        ..right = true;
      run(game, 0.6);
      expect(p.covering, isTrue);
      expect(p.velocity.x, lessThanOrEqualTo(Player.coverSpeed + 0.01));
      expect(p.light.$2, lessThan(open));
    },
  );
}
