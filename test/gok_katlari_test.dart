// Göğün katlarının yeni düzenekleri: yıldız çarkı, Yedi Karakçı, Yel Ana'nın
// soluğu ve yada taşı.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/gok_katlari.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';

const _dt = 1 / 60;

List<String> _flat({int w = 60, String extra = ''}) {
  const h = 24, f = 18;
  final g = List.generate(h, (_) => List.filled(w, '.'));
  for (var c = 0; c < w; c++) {
    for (var r = f; r < h; r++) {
      g[r][c] = '#';
    }
  }
  g[f - 1][2] = 'P';
  if (extra.isNotEmpty) g[f - 1][20] = extra;
  return [for (final r in g) r.join()];
}

Future<Player> _load(
  GolgeGame game,
  LevelDef def, {
  required double col,
  int row = 17,
}) async {
  GolgeGame.debugLevels = [def];
  game.onGameResize(Vector2(1280, 720));
  game.debugLoadLevel(0);
  await game.ready();
  game.cinematic = false;
  final p = game.player!;
  p.position.setFrom(
    Level.standOn(Vector2(col * kTile, row * kTile), Player.w, Player.h),
  );
  return p;
}

void _run(GolgeGame game, double s) {
  for (var t = 0.0; t < s; t += _dt) {
    game.update(_dt);
  }
}

void main() {
  tearDown(() => GolgeGame.debugLevels = null);

  LevelDef windy({int dir = -1, String extra = ''}) => LevelDef(
    title: 'x',
    subtitle: '',
    theme: LevelTheme.heavens,
    map: _flat(extra: extra),
    wings: true,
    yel: [(5, 4, 55, 17, dir)],
  );

  testWithGame<GolgeGame>('Yel Ana önden eserken ayakta duranı iter', GolgeGame.new, (
    game,
  ) async {
    final p = await _load(game, windy(), col: 30);
    final x0 = p.position.x;
    _run(game, YelZone.period + 0.5);
    expect(p.position.x, lessThan(x0 - 3 * kTile));
  });

  testWithGame<GolgeGame>('çömelen soluktan etkilenmez', GolgeGame.new, (
    game,
  ) async {
    final p = await _load(game, windy(), col: 30);
    final x0 = p.position.x;
    game.controls.keyboard.down = true;
    _run(game, YelZone.period + 0.5);
    game.controls.keyboard.down = false;
    expect((p.position.x - x0).abs(), lessThan(4));
  });

  testWithGame<GolgeGame>('yada taşı soluğun yönünü çevirir', GolgeGame.new, (
    game,
  ) async {
    final p = await _load(game, windy(extra: 'c'), col: 20);
    final z = game.world.children.whereType<YelZone>().single;
    expect(z.dir, -1);
    _run(game, 0.3);
    game.controls.keyboard.up = true;
    _run(game, 0.15);
    game.controls.keyboard.up = false;
    expect(z.dir, 1);
    final x0 = p.position.x;
    _run(game, YelZone.period + 0.5);
    expect(p.position.x, greaterThan(x0 + 3 * kTile));
  });

  testWithGame<GolgeGame>('yıldız üstündekini taşır', GolgeGame.new, (
    game,
  ) async {
    final def = LevelDef(
      title: 'x',
      subtitle: '',
      theme: LevelTheme.heavens,
      map: _flat(),
      wheels: const [(30, 8, 3, 1, 8, 0)],
    );
    final p = await _load(game, def, col: 2);
    final star = game.world.children.whereType<StarPlatform>().single;
    _run(game, 0.05);
    // Yıldızın üstüne koy, bir süre birlikte dön.
    p.position.setValues(
      star.position.x + star.size.x / 2 - Player.w / 2,
      star.position.y - Player.h,
    );
    p.velocity.setZero();
    final start = star.position.clone();
    _run(game, 1.0);
    expect((star.position - start).length, greaterThan(kTile));
    expect(p.position.y + Player.h, closeTo(star.position.y, 6));
    expect((p.center.x - star.center.x).abs(), lessThan(kTile));
  });

  testWithGame<GolgeGame>('Yedi Karakçı değeni düşürür', GolgeGame.new, (
    game,
  ) async {
    final def = LevelDef(
      title: 'x',
      subtitle: '',
      theme: LevelTheme.heavens,
      map: _flat(),
      karakci: const [(30, 10, 3, 20)],
    );
    final p = await _load(game, def, col: 2);
    final k = game.world.children.whereType<YediKarakci>().single;
    _run(game, 0.05);
    final s = k.stars.first;
    p.position.setValues(s.x - Player.w / 2, s.y - Player.h / 2);
    p.velocity.setZero();
    _run(game, 0.1);
    expect(p.isDead, isTrue);
  });
}
