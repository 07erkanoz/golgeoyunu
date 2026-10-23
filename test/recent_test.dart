import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/hints.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/player.dart';
import 'package:golge/game/narration.dart';

import 'physics_test.dart' show run;

void main() {
  testWithGame<GolgeGame>(
    'az önce: anlatılan hikâye ve ipucu saklanır; panel açılınca oyun bekler',
    GolgeGame.new,
    (game) async {
      game.debugLoadLevel(0);
      await game.ready();
      game.cinematic = false;
      run(game, 0.2);
      game.narration.whisper('Bir fısıltı.');
      game.narration.hint('Bir ipucu', queue: true);
      run(game, 1);
      final kinds = game.narration.recent.map((l) => l.kind).toList();
      expect(kinds, containsAll([RecentKind.story, RecentKind.hint]));
      expect(
        game.narration.recent.any((l) => l.text == 'Bir fısıltı.'),
        isTrue,
      );
      game.toggleRecent();
      expect(game.held, isTrue);
      expect(game.settingsOpen.value, isTrue);
      game.toggleRecent();
      expect(game.held, isFalse);
      expect(game.settingsOpen.value, isFalse);
    },
  );
  testWithGame<GolgeGame>(
    'iki panel: biri kapanınca öbürü açıkken oyun duraklı kalır',
    GolgeGame.new,
    (game) async {
      game.debugLoadLevel(0);
      await game.ready();
      game.cinematic = false;
      run(game, 0.2);
      game.toggleSettings();
      expect(game.held, isTrue);
      // Ayarlar açıkken "Az önce" açılmaz.
      game.toggleRecent();
      expect(game.recentOpen, isFalse);
      game.toggleSettings();
      expect(game.held, isFalse);
      game.toggleRecent();
      expect(game.held, isTrue);
      // "Az önce" açıkken ayarlar açılıp kapanırsa oyun yine bekler.
      game.toggleSettings();
      game.toggleSettings();
      expect(game.held, isTrue);
      expect(game.settingsOpen.value, isTrue);
      game.toggleRecent();
      expect(game.held, isFalse);
      expect(game.settingsOpen.value, isFalse);
    },
  );
  testWithGame<GolgeGame>(
    'ipucu basamakları: ikinci ölümde ilişki, üçüncüde katlı çözüm',
    GolgeGame.new,
    (game) async {
      game.debugLoadLevel(0);
      await game.ready();
      game.cinematic = false;
      final g = game.world.children.whereType<Guard>().first;
      Future<void> dieNearGuard() async {
        final p = game.player!;
        p.position.setFrom(
          Level.standOn(
            Vector2(g.position.x - 6 * kTile, g.position.y),
            Player.w,
            Player.h,
          ),
        );
        run(game, 0.5);
        game.player!.die();
        run(game, 2.5);
        await game.ready();
      }

      await dieNearGuard();
      expect(game.failsAt('guard'), 1);
      await dieNearGuard();
      expect(game.failsAt('guard'), 2);
      expect(
        game.narration.recent.any((l) => l.text == Hints.relation('guard')),
        isTrue,
        reason: 'ikinci ölümde ilişki ipucu',
      );
      expect(
        game.narration.recent.any((l) => l.kind == RecentKind.solution),
        isFalse,
      );
      await dieNearGuard();
      expect(
        game.narration.recent
            .where((l) => l.kind == RecentKind.solution)
            .map((l) => l.text),
        [Hints.solution('guard')],
        reason: 'üçüncüde çözüm katlı olarak panelde',
      );
    },
  );
  testWithGame<GolgeGame>(
    'anlatım gecikmez ve kopmaz: art arda gelen satırlar alt yazı gibi akar, çok bayatlayan panele düşer',
    GolgeGame.new,
    (game) async {
      game.debugLoadLevel(0);
      await game.ready();
      game.cinematic = false;
      game.narration.resetScene();
      final long = 'Hatıra · ${'uzun bir hatıra satırı ' * 9}';
      final lines = [for (final x in 'ABCDEFG'.split('')) '$long $x'];
      for (final t in lines) {
        game.narration.whisper(t);
      }
      run(game, 0.1);
      expect(game.narration.debugWhisper, lines[0]);
      // Bir saniye sonra ikinci satır beklemeden alta gelir, ilki üstte sürer.
      run(game, 1.1);
      expect(game.narration.debugWhispers, [lines[0], lines[1]]);
      final shown = <String>{};
      for (var t = 0.0; t < 80; t += 0.1) {
        run(game, 0.1);
        shown.addAll(game.narration.debugWhispers);
      }
      expect(game.narration.debugWhisper, isNull, reason: 'kuyruk boşaldı');
      expect(
        shown,
        containsAll(lines.take(5)),
        reason: 'art arda beş hikâye satırı kaybolmaz',
      );
      expect(
        shown.contains(lines.last),
        isFalse,
        reason: 'çok geride kalan satır ekrana gelmez',
      );
      final story = game.narration.recent
          .where((l) => l.kind == RecentKind.story)
          .map((l) => l.text);
      expect(story, containsAll(lines), reason: 'hepsi panelde okunur');
    },
  );
  testWithGame<GolgeGame>(
    'efsane kartı karşılaşma anında gelir; hikâye satırını kesmez, bekletmez',
    GolgeGame.new,
    (game) async {
      game.debugLoadLevel(0);
      await game.ready();
      game.cinematic = false;
      game.narration.resetScene();
      run(game, 7); // bölüm başlığı kapansın
      const a = 'Sâye ağaca dokundu; dallar kıpırdadı.';
      const b = 'Uzakta bir kandil yandı.';
      game.narration.whisper(a);
      run(game, 1);
      expect(game.narration.debugWhisper, a);
      game.meetMyth('umay');
      game.narration.whisper(b);
      run(game, 0.2);
      expect(game.narration.debugMyth, isNotNull, reason: 'kart hemen açılır');
      expect(
        game.narration.debugWhispers,
        [a, b],
        reason: 'hikâye satırı sürer, yenisi beklemeden altına gelir',
      );
    },
  );
}
