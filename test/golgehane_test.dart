// S2a · Unutulmuş Gölgehane (Yerebatan): taş gibi boyanmış perde, ardında
// ustanın odası; üç tasvir oynayınca ustanın tasvirinden bir parça.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/golgehane.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/player.dart';
import 'package:golge/settings.dart';

void run(GolgeGame game, double s) {
  for (var i = 0; i < (s * 60).round(); i++) {
    game.update(1 / 60);
  }
}

Future<(GolgeGame, Player, GolgehaneKapi, GolgehaneSahne, int)> load(
  GolgeGame game,
) async {
  game.onGameResize(Vector2(1280, 720));
  final li = levels.indexWhere(
    (d) => d.surprises.any((s) => s.$1 == 'golgehane'),
  );
  game.debugLoadLevel(li);
  await game.ready();
  for (final g in game.world.children.whereType<Guard>().toList()) {
    g.removeFromParent();
  }
  await game.ready();
  run(game, 3);
  return (
    game,
    game.player!,
    game.world.children.whereType<GolgehaneKapi>().first,
    game.world.children.whereType<GolgehaneSahne>().first,
    li,
  );
}

void put(Player p, double col, double row) {
  p.position.setFrom(
    Level.standOn(Vector2(col * kTile, row * kTile), Player.w, Player.h),
  );
  p.velocity.setZero();
}

void main() {
  setUp(Settings.secrets.clear);

  testWithGame<GolgeGame>(
    'yolun sonundaki boşluğa düşen sahanlığa konar, '
    'perde aralanır; yanından suya düşen yine ölür',
    GolgeGame.new,
    (game) async {
      final (_, p, kapi, sahne, _) = await load(game);
      expect(kapi.opened, isFalse);
      expect(sahne.lit, isFalse, reason: 'oda aralanmadan ışık sızmaz');
      // Boşluğun üstünden bırakılır.
      p.position.setValues(155.5 * kTile - Player.w / 2, 12.2 * kTile);
      p.velocity.setZero();
      run(game, 1.5);
      expect(p.isDead, isFalse);
      expect(p.onGround, isTrue);
      expect((p.position.y + Player.h) / kTile, closeTo(16, 0.05));
      expect(kapi.opened, isTrue);
      run(game, 1);
      expect(kapi.open, 1);
      expect(sahne.lit, isTrue);
      // Sahanlığın solunda su: düşen ölür.
      p.position.setValues(153.5 * kTile - Player.w / 2, 15.2 * kTile);
      p.velocity.setZero();
      run(game, 1.5);
      expect(p.isDead, isTrue);
      expect(p.deathCause, DeathCause.water);
    },
  );

  testWithGame<GolgeGame>(
    'yaklaşana içeriden kısık çan: bir kez, '
    'sonra on beş saniye susar',
    GolgeGame.new,
    (game) async {
      final (_, p, kapi, _, _) = await load(game);
      put(p, 148, 13);
      run(game, 0.5);
      expect(kapi.debugCalled, 0);
      put(p, 152, 13);
      run(game, 0.5);
      expect(kapi.debugCalled, 1);
      put(p, 148, 13);
      run(game, 1);
      put(p, 152, 13);
      run(game, 1);
      expect(kapi.debugCalled, 1);
    },
  );

  testWithGame<GolgeGame>(
    'kandile yaklaşan gölge büyür; üç tasvir oynayınca '
    'parça belirir, alınınca sır sayılır',
    GolgeGame.new,
    (game) async {
      final (_, p, kapi, sahne, li) = await load(game);
      final tasvirler = game.world.children
          .whereType<GolgehaneTasvir>()
          .toList();
      expect(tasvirler, hasLength(3));
      // Aralanmadan tasvirlere dokunulmaz.
      put(p, tasvirler[0].position.x / kTile - 0.5, 18);
      run(game, 0.3);
      expect(tasvirler[0].canUse(p.center), isFalse);
      put(p, 155.5, 15);
      run(game, 1.5);
      expect(kapi.opened, isTrue);
      expect(
        GolgehaneSahne.shadowScale(10),
        greaterThan(GolgehaneSahne.shadowScale(150)),
      );
      // Kandili sağa iter.
      put(p, 159.5, 18);
      run(game, 0.5);
      final before = sahne.lampX;
      game.controls.keyboard.right = true;
      run(game, 1.2);
      game.controls.keyboard.right = false;
      expect(sahne.lampX, greaterThan(before + kTile));
      for (final t in tasvirler) {
        put(p, t.position.x / kTile - 0.5, 18);
        run(game, 0.3);
        expect(t.canUse(p.center), isTrue);
        t.use();
        run(game, GolgehaneSahne.playLen + 0.2);
      }
      expect(sahne.played, {0, 1, 2});
      expect(sahne.pieceT, greaterThanOrEqualTo(0));
      expect(game.secretSeen('golgehane'), isFalse);
      put(p, (sahne.position.x + sahne.screen.center.dx) / kTile - 0.5, 18);
      run(game, 1.2);
      expect(game.secretSeen('golgehane'), isTrue);
      expect(Settings.secrets, contains('$li:golgehane'));
      expect(p.isDead, isFalse);
    },
  );
}
