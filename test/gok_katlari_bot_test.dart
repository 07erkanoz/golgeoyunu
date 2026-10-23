// Göğün Katları I ve II'nin yeni katlarını bot oynar: yıldız çarkları,
// Demir Kazık'ın atları, Yel Ana'nın soluğu ve yada taşı, şimşek basamakları.
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/gok_katlari.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';

const _dt = 1 / 60;

Future<Player> _place(GolgeGame game, int level, double col, int row) async {
  game.debugLoadLevel(level);
  await game.ready();
  game.cinematic = false;
  final p = game.player!;
  p.position.setFrom(
    Level.standOn(Vector2(col * kTile, row * kTile), Player.w, Player.h),
  );
  return p;
}

Buttons _k(GolgeGame g) => g.controls.keyboard;

String _where(Player p) =>
    '${(p.center.x / kTile).toStringAsFixed(1)},${((p.position.y + Player.h) / kTile).toStringAsFixed(1)} ${p.isDead ? 'öldü ${p.deathCause}' : p.state.name}';

/// Yıldızdan yıldıza, yıldızdan adaya: yakın geçen yıldıza atlar; yıldızın
/// üstündeyken hedefe (ada ya da daha yüksek bir yıldız) yetişebileceği an
/// atlar ve süzülür. Hedef adaya ([t0]-[t1], durulan satır [row]) basınca
/// durur.
bool _rideStars(
  GolgeGame game,
  Player p, {
  required double t0,
  required double t1,
  required int row,
  double seconds = 40,
}) {
  final k = _k(game);
  var air = 0;
  StarPlatform? leftStar;
  for (var i = 0; i < seconds * 60; i++) {
    final feet = p.position.y + Player.h;
    final x = p.center.x / kTile;
    if (p.onGround &&
        p.riding is! StarPlatform &&
        x >= t0 &&
        x <= t1 + 1 &&
        (feet / kTile - row - 1).abs() < 0.6) {
      k.release();
      return true;
    }
    final stars = game.world.children.whereType<StarPlatform>().toList();
    final thieves = game.world.children.whereType<YediKarakci>().toList();
    bool safe(Vector2 a, Vector2 b) {
      for (final th in thieves) {
        for (final s in th.stars) {
          for (var u = 0.0; u <= 1; u += 0.25) {
            final q = a + (b - a) * u;
            if ((s - q).length < 2.6 * kTile) return false;
          }
        }
      }
      return true;
    }

    if (p.onGround) {
      air = 0;
      leftStar = p.riding is StarPlatform ? p.riding as StarPlatform : null;
      k
        ..left = false
        ..right = false
        ..jump = false;
      final cur = p.riding;
      // Gidilecek yer: hedef ada ya da yükselen bir yıldız.
      Vector2? goal;
      final islandEdge = Vector2(
        (x < t0 ? t0 + 0.8 : t1 - 0.8) * kTile,
        row * kTile + kTile / 2,
      );
      final dIsland = islandEdge - p.center;
      if (dIsland.x.abs() < 5.5 * kTile &&
          dIsland.y > -1.2 * kTile &&
          dIsland.y < 6 * kTile) {
        goal = islandEdge;
      } else {
        for (final s in stars) {
          if (s == cur) continue;
          // Yıldızın yarım saniye sonraki yeri (zıplayış o kadar sürer).
          final fut = s.centerIn(0.5);
          final top = Vector2(fut.x, fut.y - 6 - Player.h / 2);
          final d = top - p.center;
          final rising = cur is StarPlatform && s.pivot != cur.pivot;
          if (d.x.abs() < 4.0 * kTile &&
              d.y > -1.6 * kTile &&
              d.y < 2.5 * kTile &&
              (cur is! StarPlatform || rising) &&
              (goal == null || d.length < (goal - p.center).length)) {
            goal = top;
          }
        }
      }
      if (goal != null && safe(p.center, goal)) {
        final dir = (goal.x - p.center.x).sign;
        k
          ..jump = true
          ..right = dir > 0
          ..left = dir < 0;
      } else if (cur is! StarPlatform) {
        // Adada: çarka bakan kenara yürü, orada bekle.
        final c = ((p.center.x + 0.8 * kTile) / kTile).floor();
        final r = (feet / kTile + 0.2).floor();
        if (game.level.solid(c, r)) k.right = true;
      }
    } else {
      air++;
      // Havada: hedefe doğru süz.
      final dir = (((t0 + t1) / 2) * kTile - p.center.x).sign;
      Vector2? best;
      for (final s in stars) {
        if (s == leftStar) continue;
        final c = s.centerIn(0.25);
        final d = c - p.center;
        if (d.length < 4 * kTile &&
            d.y > -kTile &&
            (best == null || d.length < (best - p.center).length)) {
          best = c;
        }
      }
      final aim = best != null ? (best.x - p.center.x).sign : dir;
      k
        ..right = aim > 0
        ..left = aim < 0
        ..jump = air < 40 || p.velocity.y > 0;
    }
    game.update(_dt);
    if (const bool.fromEnvironment('YIZ') && i % 10 == 0) {
      // ignore: avoid_print
      print(
        '$i ${_where(p)} on=${p.onGround} rid=${p.riding.runtimeType} j=${k.jump} r=${k.right} l=${k.left}',
      );
    }
    if (p.isDead) break;
  }
  k.release();
  return false;
}

void main() {
  group('Yıldız Katı', () {
    for (final (name, col, row, t0, t1, trow) in [
      ('tek çark', 125.0, 30, 135.0, 142.0, 21),
      ('iki ters çark', 141.0, 21, 159.0, 166.0, 8),
      ('Demir Kazık', 166.0, 8, 182.0, 192.0, 8),
    ]) {
      testWithGame<GolgeGame>(name, GolgeGame.new, (game) async {
        final p = await _place(game, 16, col, row);
        game.update(_dt);
        final ok = _rideStars(game, p, t0: t0, t1: t1, row: trow);
        // ignore: avoid_print
        print('YILDIZ $name: $ok ${_where(p)}');
        expect(ok, isTrue);
      }, timeout: const Timeout(Duration(minutes: 2)));
    }
  });

  group('Yel Katı', () {
    /// Rüzgârda koşan bot: soluk önden eserken çömelir; geniş boşlukta
    /// soluk arkadan eserken atlayıp süzülür; yada taşını gerekirse çevirir.
    bool windRun(
      GolgeGame game,
      Player p, {
      required double goal,
      required int goalRow,
      double seconds = 60,
    }) {
      final k = _k(game);
      var gliding = false;
      for (var i = 0; i < seconds * 60; i++) {
        final x = p.center.x / kTile;
        final feet = (p.position.y + Player.h) / kTile;
        if (p.onGround && x > goal && (feet - goalRow - 1).abs() < 0.6) {
          k.release();
          return true;
        }
        YelZone? zone;
        for (final z in game.world.children.whereType<YelZone>()) {
          if (z.area.inflate(kTile).contains(p.center.toOffset())) zone = z;
        }
        k.release();
        if (p.onGround) {
          gliding = false;
          final c = ((p.position.x + Player.w + 6) / kTile).floor();
          final r = (feet + 0.2).floor();
          bool floor(int cc, int rr) =>
              game.level.solid(cc, rr) || game.level.cell(cc, rr) == '=';
          // Boşluğun genişliği: aynı ya da birkaç satır aşağıdaki zemine.
          bool below(int cc) {
            for (var d = 0; d <= 5; d++) {
              if (floor(cc, r + d)) return true;
            }
            return false;
          }

          var gap = 0;
          while (gap < 30 && !below(c + gap)) {
            gap++;
          }
          final headwind = zone != null && zone.dir < 0;
          final yada = game.world.children
              .whereType<YadaStone>()
              .where((y) => (y.position.x - p.center.x).abs() < 2 * kTile)
              .firstOrNull;
          if (yada != null && zone != null && zone.dir < 0) {
            // Yada taşına yürü, yanına varınca dokun (bir kez basar).
            final dx = yada.position.x - p.center.x;
            if (dx.abs() > 0.5 * kTile) {
              k
                ..right = dx > 0
                ..left = dx < 0;
            } else {
              k.up = i.isEven;
            }
          } else if (headwind && (zone.warning || zone.blowing)) {
            k.down = true; // çömel
          } else if (gap == 0) {
            k.right = true;
          } else if (gap <= 3) {
            k
              ..right = true
              ..jump = true;
          } else {
            // Geniş boşluk: soluk arkadan esmeye başlayınca atla.
            final tail =
                zone != null &&
                zone.dir > 0 &&
                zone.blowing &&
                zone.strength > 0.3;
            if (tail) {
              k
                ..right = true
                ..jump = true;
              gliding = true;
            }
          }
        } else {
          // Hedefin üstüne gelince süzülmeyi bırakır.
          final over = x > goal - 1.5;
          k
            ..right = !over
            ..jump = (gliding && !over) || p.velocity.y < 0;
        }
        game.update(_dt);
        if (p.isDead) break;
      }
      k.release();
      return false;
    }

    for (final (name, col, row, goal, goalRow) in [
      ('arkadan soluk', 191.0, 8, 213.0, 12),
      ('önden soluk', 217.0, 12, 245.0, 15),
      ('yada taşı', 245.0, 15, 271.0, 19),
    ]) {
      testWithGame<GolgeGame>(name, GolgeGame.new, (game) async {
        final p = await _place(game, 16, col, row);
        game.update(_dt);
        final ok = windRun(game, p, goal: goal, goalRow: goalRow);
        // ignore: avoid_print
        print('YEL $name: $ok ${_where(p)}');
        expect(ok, isTrue);
      }, timeout: const Timeout(Duration(minutes: 2)));
    }
  });

  testWithGame<GolgeGame>(
    'Şimşek Katı: yıldırımdan kaçıp basamaklardan geçilir',
    GolgeGame.new,
    (game) async {
      final p = await _place(game, 18, 92, 30);
      game.update(_dt);
      final k = _k(game);
      var ok = false;
      for (var i = 0; i < 60 * 70; i++) {
        final x = p.center.x / kTile;
        if (x > 143 && p.onGround) {
          ok = true;
          break;
        }
        k.release();
        // Kızaran yerin üstündeyse ya da ona yürüyecekse bekle/çekil.
        LightningStrike? danger;
        for (final l in game.world.children.whereType<LightningStrike>()) {
          final dx = l.position.x - p.center.x;
          if ((l.warning > 0 || l.striking) &&
              dx > -1.5 * kTile &&
              dx < 2.5 * kTile) {
            danger = l;
          }
        }
        if (danger != null) {
          // Yıldırımın düşeceği yerden uzaklaş (yanındaysa geri çekil).
          if ((danger.position.x - p.center.x).abs() < 1.3 * kTile) {
            k.left = danger.position.x > p.center.x;
            k.right = !k.left;
          }
        } else if (p.onGround) {
          final feet = p.position.y + Player.h;
          // Önde basılacak yer (zemin ya da bulut basamağı) yoksa zıpla.
          bool support(double ax) {
            final c = (ax / kTile).floor();
            final r = (feet / kTile + 0.2).floor();
            if (game.level.solid(c, r)) return true;
            for (final s in game.world.children.whereType<StormStep>()) {
              if (ax >= s.position.x &&
                  ax <= s.position.x + s.size.x &&
                  (s.position.y - feet).abs() < 10) {
                return true;
              }
            }
            return false;
          }

          k.right = true;
          if (!support(p.position.x + Player.w + 8)) k.jump = true;
        } else {
          k
            ..right = true
            ..jump = p.velocity.y < 0;
        }
        game.update(_dt);
        if (const bool.fromEnvironment('SIM') && i % 10 == 0) {
          // ignore: avoid_print
          print('$i ${_where(p)} on=${p.onGround} j=${k.jump} r=${k.right} l=${k.left}');
        }
        if (p.isDead) break;
      }
      // ignore: avoid_print
      print('SIMSEK: $ok ${_where(p)}');
      expect(ok, isTrue);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
