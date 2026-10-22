import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/perde.dart';
import 'package:golge/settings.dart';
import 'package:golge/ui/story_theater.dart';

void main() {
  test('hiçbir yer açılmamışken yalnız önsöz oynar', () {
    Settings.unlocked = 0;
    SaveGame.current = null;
    final acts = StoryTheater.acts();
    expect(acts.length, 1);
    expect(acts.first.$1, PerdeScene.prologue);
  });

  test('son bölüme ulaşmak sonu açmaz; oyun bitince açılır', () {
    Settings.unlocked = levelOrder.length - 1;
    Settings.finished = false;
    SaveGame.current = null;
    final acts = StoryTheater.acts();
    expect(acts.last.$1, isNot(PerdeScene.epilogue));
    expect(StoryTheater.complete, isFalse);
  });

  test('hepsi açıkken önsöz, bölüm perdeleri ve son', () {
    Settings.finished = true;
    Settings.unlocked = levelOrder.length - 1;
    SaveGame.current = null;
    final acts = StoryTheater.acts();
    expect(acts.first.$1, PerdeScene.prologue);
    expect(acts.last.$1, PerdeScene.epilogue);
    final scenes = acts.map((a) => a.$1).toList();
    for (final s in [
      PerdeScene.galata,
      PerdeScene.skyroad,
      PerdeScene.kaf,
      PerdeScene.ergenekon,
      PerdeScene.gok,
    ]) {
      expect(scenes, contains(s));
    }
    // Her perdenin satırı var.
    for (final a in acts) {
      expect(a.$2, isNotEmpty);
    }
  });

  test('her geçilen bölümün ardından köprü; metinler eksiksiz', () {
    expect(bridges.length, levels.length);
    expect(bridgesEn.length, levels.length);
    for (var i = 0; i < bridges.length; i++) {
      expect(bridges[i], isNotEmpty, reason: 'köprü $i');
      expect(bridgesEn[i].length, bridges[i].length, reason: 'köprü $i');
    }
    Settings.unlocked = 3;
    Settings.finished = false;
    SaveGame.current = null;
    final acts = StoryTheater.acts();
    final bridged = acts.where((a) => a.$4 != null).map((a) => a.$4);
    expect(bridged, [levelOrder[0], levelOrder[1], levelOrder[2]]);
    // Köprü, bölümünün perdesinden hemen sonra gelir.
    Settings.unlocked = levelOrder.length - 1;
    Settings.finished = true;
    final all = StoryTheater.acts();
    expect(all[all.length - 2].$4, levelOrder.last);
  });

  testWidgets('tiyatro dokunmayla ilerler, perde geçilir, kapanır', (
    tester,
  ) async {
    Settings.unlocked = 3;
    SaveGame.current = null;
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(home: StoryTheater(onClose: () => closed = true)),
    );
    await tester.pump(const Duration(seconds: 2));
    for (var i = 0; i < 6; i++) {
      await tester.tapAt(const Offset(400, 300));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.tap(find.byType(TextButton).first);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byType(TextButton).last);
    await tester.pump();
    expect(closed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
