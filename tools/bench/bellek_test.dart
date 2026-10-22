// Bellek sızıntısı taraması: bölümü bir süre oynatıp her kare çizer;
// bellek ve bileşen sayılarının nasıl büyüdüğünü yazar.
// `flutter test tools/bench/bellek_test.dart --dart-define=LV=5`
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/golge_game.dart';
import 'package:golge/game/level.dart';
import 'package:golge/game/palette.dart';
import 'package:golge/game/player.dart';
import 'package:golge/settings.dart';

const _lv = int.fromEnvironment('LV', defaultValue: 5);
const _low = bool.fromEnvironment('LOW');

Map<String, int> _census(Component root) {
  final out = <String, int>{};
  void walk(Component c) {
    final k = c.runtimeType.toString();
    out[k] = (out[k] ?? 0) + 1;
    c.children.forEach(walk);
  }

  walk(root);
  return out;
}

void main() {
  testWithGame<GolgeGame>('bellek', GolgeGame.new, (game) async {
    Cartoon.on = true;
    Realism.on = true;
    Settings.lowGraphics = _low;
    game.onGameResize(Vector2(1280, 720));
    game.debugLoadLevel(_lv);
    await game.ready();
    game.cinematic = false;
    final keys = game.controls.keyboard;
    Map<String, int>? first;
    final w = game.level.width;
    for (var s = 0; s <= 60; s++) {
      // Her saniye bölümün bir başka yerine: hepsi dolaşılır.
      final p = game.player;
      if (p != null && !p.isDead) {
        final col = (s / 60 * (w - 4)).clamp(2, w - 3).toDouble();
        p.position.setFrom(
          Level.standOn(Vector2(col * kTile, p.position.y), Player.w, Player.h),
        );
      }
      for (var f = 0; f < 60; f++) {
        keys.right = (s ~/ 6).isEven;
        keys.left = !keys.right;
        game.cinematic = false;
        game.update(1 / 60);
        final rec = ui.PictureRecorder();
        game.render(ui.Canvas(rec));
        rec.endRecording().dispose();
      }
      if (s % 10 == 0) {
        final c = _census(game);
        first ??= c;
        final grew = c.entries
            .where((e) => e.value > (first![e.key] ?? 0) + 20)
            .map((e) => '${e.key}:${first![e.key] ?? 0}→${e.value}')
            .join(' ');
        // ignore: avoid_print
        print(
          '${s}s RSS ${(ProcessInfo.currentRss / 1048576).round()} MB, '
          'bileşen ${c.values.fold(0, (a, b) => a + b)} $grew',
        );
      }
    }
  });
}
