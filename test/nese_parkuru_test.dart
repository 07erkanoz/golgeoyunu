// Neşe paketi: zıpzıpa düşen fırlar, iki zıplayışta ışık dizisi toplanır
// (alkış, sır); Sâye durunca gölgesi bir hayvana dönüşür; Umay ağacında
// kuşlar başına konar; Karagöz ile Hacivat oynar ve bir yer gösterir.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/joy.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/perde.dart';
import 'package:golge/game/player.dart';
import 'package:golge/settings.dart';

void run(GolgeGame game, double s) {
  for (var i = 0; i < (s * 60).round(); i++) {
    game.update(1 / 60);
  }
}

Future<Player> load(GolgeGame game, int li) async {
  game.onGameResize(Vector2(1280, 720));
  game.debugLoadLevel(li);
  await game.ready();
  for (final g in game.world.children.whereType<Guard>().toList()) {
    g.removeFromParent();
  }
  await game.ready();
  return game.player!;
}

void main() {
  setUp(Settings.secrets.clear);

  test('bölümlerin çoğunda bir neşe parkuru ve Karagöz perdesi var', () {
    var courses = 0;
    var stages = 0;
    for (final d in levels) {
      if (d.skiMarks != null) continue;
      final lv = Level(d);
      final spots = findJoySpots(lv);
      if (spots.isNotEmpty) courses++;
      if (findKaragozSpot(lv, spots) != null) stages++;
    }
    expect(courses, greaterThanOrEqualTo(10));
    expect(stages, greaterThanOrEqualTo(10));
  });

  for (final li in [5, 13, 17]) {
    testWithGame<GolgeGame>(
      'parkur: iki zıplayışta ışıklar toplanır ($li)',
      GolgeGame.new,
      (game) async {
        final p = await load(game, li);
        final pads = game.world.children.whereType<Bouncer>().toList()
          ..sort((a, b) => a.position.x.compareTo(b.position.x));
        final lights = game.world.children.whereType<JoyLights>().first;
        final first = pads.first;
        // İlk zıpzıpın biraz üstünden düşer, sağa koşarak.
        p.position.setValues(
          first.position.x - Player.w / 2,
          first.position.y - first.top - Player.h - 40,
        );
        p.velocity.setValues(0, 0);
        game.controls.keyboard.right = true;
        var bounced = false;
        for (var i = 0; i < 60 * 3; i++) {
          game.update(1 / 60);
          if (p.velocity.y < -600) bounced = true;
        }
        game.controls.keyboard.right = false;
        expect(bounced, isTrue);
        final got = lights.taken.where((t) => t).length;
        expect(
          lights.done,
          isTrue,
          reason: 'alınan $got/${lights.points.length}',
        );
        expect(game.secretSeen('parkur0'), isTrue);
      },
    );
  }

  testWithGame<GolgeGame>(
    'gölge oyunu: durunca gölge hayvan olur, kıpırdayınca biter',
    GolgeGame.new,
    (game) async {
      final p = await load(game, 0);
      p.position.setFrom(
        Level.standOn(
          Vector2(23 * kTile.toDouble(), 13 * kTile.toDouble()),
          Player.w,
          Player.h,
        ),
      );
      run(game, GolgeGame.playIdle + 1.5);
      expect(p.shadowPlaying, isTrue);
      expect(game.secretSeen('golgeOyunu'), isTrue);
      game.controls.keyboard.right = true;
      run(game, 1);
      game.controls.keyboard.right = false;
      expect(p.shadowPlaying, isFalse);
    },
  );

  testWithGame<GolgeGame>(
    'gölge oyunu düzeneğin yanında başlamaz; oynayan gölge yol göstermeye '
    'gider',
    GolgeGame.new,
    (game) async {
      final p = await load(game, 0);
      // Yerebatan'ın ilk kolunun yanında: sıradaki adım var, oyun yok.
      final lever = game.world.children.whereType<Lever>().first;
      p.position.setFrom(
        Level.standOn(
          lever.position - Vector2(2 * kTile.toDouble(), kTile.toDouble()),
          Player.w,
          Player.h,
        ),
      );
      run(game, GolgeGame.playIdle + 3);
      expect(game.guide.current, isNotNull);
      expect(p.shadowPlaying, isFalse);
      // Oynayan gölge yol gösterme çağrısında oyunu bırakır.
      expect(p.shadowPlay(ShadowAnimal.rabbit), isTrue);
      expect(p.guideShadow(lever.position.clone()), isTrue);
      expect(p.shadowPlaying, isFalse);
      expect(p.shadowGuiding, isTrue);
    },
  );

  testWithGame<GolgeGame>(
    'Umay ağacında durunca kuşlar konar, kıpırdayınca uçar',
    GolgeGame.new,
    (game) async {
      final p = await load(game, 0);
      final cell = game.level.checkpointCells[1];
      p.position.setFrom(
        Level.standOn(cell + Vector2(kTile * 1.0, 0), Player.w, Player.h),
      );
      final birds = game.world.children.whereType<UmayBirds>().firstWhere(
        (b) => (b.crown.x - cell.x).abs() < kTile * 2,
      );
      run(game, 6);
      expect(birds.perched, 2);
      game.controls.keyboard.right = true;
      run(game, 0.3);
      game.controls.keyboard.right = false;
      expect(birds.perched, 0);
    },
  );

  testWithGame<GolgeGame>(
    'Karagöz ile Hacivat oynar, sonunda bir yer gösterir',
    GolgeGame.new,
    (game) async {
      final p = await load(game, 0);
      final stage = game.world.children.whereType<KaragozSahne>().first;
      expect(stage.target, isNotNull);
      p.position.setFrom(
        Level.standOn(
          stage.position - Vector2(kTile * 1.5, kTile.toDouble()),
          Player.w,
          Player.h,
        ),
      );
      run(game, 1.5);
      expect(stage.playing, isTrue);
      run(game, karagozLength + 1);
      expect(stage.playing, isFalse);
      expect(game.secretSeen('karagoz'), isTrue);
    },
  );
}
