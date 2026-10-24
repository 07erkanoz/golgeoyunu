// Kestirme taraması: her bölümde "akılsız" oynayışlar (yalnız sağa koş,
// koşup sürekli zıpla, parmak ucunda yürü, koşup ateşböceği saç) ne kadar
// ilerliyor, hangi tehditlerin önünden geçiyor, nerede ölüyor.
// `flutter test tools/preview/kestirme_tarama_test.dart` →
// build/preview/kestirme_tarama.txt
import 'dart:io';

import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/creatures.dart';
import 'package:golge/game/entities.dart';
import 'package:golge/game/erlik.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/nemrut.dart';
import 'package:golge/game/winter.dart';

import 'yazi_tipi.dart';

const double _dt = 1 / 60;
const double _limit = 90;

enum Kestirme { kos, ziplaKos, parmakUcu, atesBocegi }

String _ad(Kestirme k) => switch (k) {
  Kestirme.kos => 'sağa koş',
  Kestirme.ziplaKos => 'koş + zıpla',
  Kestirme.parmakUcu => 'parmak ucu',
  Kestirme.atesBocegi => 'koş + ateşböceği',
};

void main() {
  setUpAll(yaziTipiYukle);
  final out = StringBuffer();
  tearDownAll(() {
    Directory('build/preview').createSync(recursive: true);
    File('build/preview/kestirme_tarama.txt').writeAsStringSync(out.toString());
  });
  for (final lv in levelOrder) {
    if (lv == 9 || lv == 10) continue; // kayak bölümleri
    for (final k in Kestirme.values) {
      testWithGame<
        GolgeGame
      >('${levels[lv].title} · ${_ad(k)}', GolgeGame.new, (game) async {
        game.debugLoadLevel(lv);
        await game.ready();
        game.cinematic = false;
        final width = game.level.width;
        // Tehditler: başlangıçtaki yerleri.
        final threats = <(String, double)>[
          for (final c in game.world.children)
            switch (c) {
              Guard g => ('Kandilci', g.position.x),
              Watcher w => ('Gözcü', w.position.x),
              StoneGiant s => ('taş dev', s.position.x),
              Wolf w => ('kurt', w.position.x),
              Kormos m => ('Körmös', m.position.x),
              _ => ('', -1.0),
            },
        ]..removeWhere((t) => t.$1.isEmpty);
        final passed = <int>{};
        final deaths = <String>[];
        var maxX = 0.0;
        // Dikey bölümler (Kule) için: başlangıçtan ne kadar yükseldi.
        final startY = game.player?.center.y ?? 0;
        var minY = startY;
        var reachedExit = false;
        var wasDead = false;
        final keys = game.controls.keyboard;
        for (var t = 0.0; t < _limit; t += _dt) {
          if (game.levelIndex != lv) {
            reachedExit = true;
            break;
          }
          final p = game.player;
          if (p == null) {
            game.update(_dt);
            continue;
          }
          keys
            ..right = true
            ..sneak = k == Kestirme.parmakUcu;
          if (k == Kestirme.ziplaKos) {
            keys.jump = (t % 0.5) < 0.3;
          }
          if (k == Kestirme.atesBocegi && (t % 2.0) < _dt) {
            game.controls.queueLure();
          }
          game.cinematic = false;
          game.update(_dt);
          if (p.isDead && !wasDead) {
            deaths.add('${(p.center.x / kTile).round()}:${p.deathCause.name}');
          }
          wasDead = p.isDead;
          if (!p.isDead) {
            maxX = p.center.x > maxX ? p.center.x : maxX;
            minY = p.center.y < minY ? p.center.y : minY;
            for (var i = 0; i < threats.length; i++) {
              if (p.center.x > threats[i].$2 + 2 * kTile) passed.add(i);
            }
          }
        }
        keys.release();
        final kinds = <String, (int, int)>{};
        for (var i = 0; i < threats.length; i++) {
          final (n, _) = threats[i];
          final (a, b) = kinds[n] ?? (0, 0);
          kinds[n] = (a + (passed.contains(i) ? 1 : 0), b + 1);
        }
        final threatTxt = kinds.entries
            .map((e) => '${e.key} ${e.value.$1}/${e.value.$2}')
            .join(', ');
        final line =
            '${levels[lv].title.padRight(22)} | ${_ad(k).padRight(17)} | '
            'ilerleme %${(maxX / kTile / width * 100).round()}'
            '${game.level.height > 3 * width ? ' (yükseklik %${((startY - minY) / startY * 100).round()})' : ''}'
            '${reachedExit ? ' ÇIKIŞ' : ''} | ölüm ${deaths.length}'
            '${deaths.isEmpty ? '' : ' (${deaths.take(4).join(' ')})'} | '
            'geçilen: $threatTxt';
        out.writeln(line);
        // ignore: avoid_print
        print(line);
      });
    }
  }
}
