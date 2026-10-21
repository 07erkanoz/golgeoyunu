import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/erlik.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/konya.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';

import 'physics_test.dart' show run, keys;

/// Körmöslü, kafesli küçük bir yeraltı odası ve atla çıkılan kuyu.
const _room = [
  '##################################################',
  '#....................................######......#',
  '#....................................#....#......#',
  '#....................................#....#......#',
  '#....................................#....#......#',
  '#....................................#....#..E...#',
  '#....................................#.....#######',
  '#....................................#Z..........#',
  '#.......b...............H............#...........#',
  '#.......................H............#...........#',
  '#.P..............a......H.......W.z..#...........#',
  '##################################################',
];

Future<void> _load(GolgeGame game) async {
  GolgeGame.debugLevels = [
    const LevelDef(
      title: 'ERLİK',
      subtitle: '',
      theme: LevelTheme.underworld,
      map: _room,
    ),
  ];
  game.debugLoadLevel(0);
  await game.ready();
  game.cinematic = false;
  run(game, 0.2);
}

void _standAt(GolgeGame game, int col) {
  game.player!.position.setFrom(
    Level.standOn(Vector2(col * kTile, 10 * kTile), Player.w, Player.h),
  );
}

void main() {
  tearDown(() {
    GolgeGame.debugLevels = null;
    keys(GolgeGame()).down = false;
  });

  testWithGame<GolgeGame>(
    'Körmös açık kavanoza süzülür; kavanoz örtülünce yuvasına döner',
    GolgeGame.new,
    (game) async {
      await _load(game);
      final k = game.world.children.whereType<Kormos>().single;
      _standAt(game, 13);
      run(game, 0.3);
      expect(k.hunting, isTrue, reason: 'açık kavanozu görür');
      final d0 = (k.position - game.player!.center).length;
      run(game, 0.5);
      expect((k.position - game.player!.center).length, lessThan(d0));
      game.controls.keyboard.down = true;
      run(game, 0.5);
      expect(k.hunting, isFalse, reason: 'örtülü kavanozu göremez');
      game.controls.keyboard.down = false;
    },
  );

  testWithGame<GolgeGame>(
    'Körmös dokunduğu çocuğun ışığını söndürür',
    GolgeGame.new,
    (game) async {
      await _load(game);
      _standAt(game, 10);
      var died = false;
      for (var i = 0; i < 120 && !died; i++) {
        run(game, 1 / 60);
        died = game.player!.isDead;
      }
      expect(died, isTrue);
    },
  );

  testWithGame<GolgeGame>(
    'ateşböceği Körmösü kavanozdan uzağa çeker',
    GolgeGame.new,
    (game) async {
      await _load(game);
      final k = game.world.children.whereType<Kormos>().single;
      _standAt(game, 14);
      game.world.add(FireflyLure(Vector2(3 * kTile, 6 * kTile), -1));
      run(game, 1.5);
      expect(k.position.x, lessThan(8 * kTile), reason: 'ateşböceğine döner');
      expect(game.player!.isDead, isFalse);
    },
  );

  testWithGame<GolgeGame>(
    'kut kafesi açılınca kapı açılır, kavanoz parlar; kayıtta açık kalır',
    GolgeGame.new,
    (game) async {
      await _load(game);
      game.world.children.whereType<Kormos>().single.removeFromParent();
      expect(game.jarBoost, 1);
      final light0 = game.player!.light.$2;
      _standAt(game, 17);
      run(game, 0.2);
      game.controls.keyboard.up = true;
      run(game, 0.1);
      game.controls.keyboard.up = false;
      run(game, 2);
      final cage = game.world.children.whereType<KutCage>().single;
      expect(cage.freed, isTrue);
      expect(game.world.children.whereType<Gate>().single.opening, isTrue);
      expect(game.jarBoost, greaterThan(1.2));
      expect(game.player!.light.$2, greaterThan(light0 * 1.2));
      expect(game.mythsSeen, contains('kut'));
    },
  );

  testWithGame<GolgeGame>(
    'Çalkuyruk\'a binince sıçrayış yükselir, kanat yok, karanlık yükselir',
    GolgeGame.new,
    (game) async {
      await _load(game);
      game.world.children.whereType<Kormos>().single.removeFromParent();
      final p = game.player!;
      expect(p.hasWings, isFalse, reason: 'yerin altında kanat açılmaz');
      // Atsız zıplayış.
      _standAt(game, 30);
      run(game, 0.3);
      final y0 = p.position.y;
      game.controls.keyboard.jump = true;
      var top = y0;
      for (var i = 0; i < 40; i++) {
        run(game, 1 / 60);
        top = top < p.position.y ? top : p.position.y;
      }
      game.controls.keyboard.jump = false;
      final plain = y0 - top;
      run(game, 1);
      // Ata bin.
      _standAt(game, 32);
      run(game, 0.3);
      expect(game.onHorse, isTrue);
      expect(game.mythsSeen, contains('erTostuk'));
      final flood = game.world.children.whereType<LightFlood>().single;
      expect(flood.dark, isTrue);
      run(game, 0.2);
      expect(flood.awake, isTrue, reason: 'binince karanlık yükselir');
      final y1 = p.position.y;
      game.controls.keyboard.jump = true;
      var top1 = y1;
      for (var i = 0; i < 50; i++) {
        run(game, 1 / 60);
        top1 = top1 < p.position.y ? top1 : p.position.y;
      }
      game.controls.keyboard.jump = false;
      expect(y1 - top1, greaterThan(plain * 1.8));
    },
  );
}
