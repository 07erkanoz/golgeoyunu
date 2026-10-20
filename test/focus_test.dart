import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/strings.dart';
import 'package:golge/main.dart';

void main() {
  testWidgets('menüden oyuna geçince klavye odağı oyuna döner', (tester) async {
    S.lang = Lang.tr;
    await tester.pumpWidget(const GolgeApp());
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text(S.of('newGame')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text(S.of('newGame')), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'oyun');
  });
}
