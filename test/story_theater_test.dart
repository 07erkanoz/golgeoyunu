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

  test('hepsi açıkken önsöz, bölüm perdeleri ve son', () {
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
