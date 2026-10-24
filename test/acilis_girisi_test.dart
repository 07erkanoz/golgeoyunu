// Açılış girişi: ilk açılışta menünün üstünde oynar, dokununca atlanır,
// bir kez izlenince sonraki açılışlarda gelmez.
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/strings.dart';
import 'package:golge/main.dart';
import 'package:golge/settings.dart';
import 'package:golge/ui/intro.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> wait(WidgetTester tester, double seconds) async {
  for (var i = 0; i < (seconds * 10).round(); i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('ilk açılışta giriş oynar; atlanınca menü kalır ve bir daha '
      'gelmez', (tester) async {
    S.lang = Lang.tr;
    Settings.debugReopen();
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const GolgeApp());
    await wait(tester, 1);
    expect(find.byType(IntroOverlay), findsOneWidget);
    // Ses motoru testte yok: giriş en çok 4 sn bekleyip başlar.
    await wait(tester, 3);
    await tester.tap(find.textContaining(S.of('skipPerde')));
    await wait(tester, 2.5);
    expect(find.byType(IntroOverlay), findsNothing);
    expect(Settings.introSeen, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('intro_seen'), isTrue);
    expect(find.text(S.of('newGame')), findsOneWidget);
  });

  testWidgets('giriş baştan sona oynar, sonunda menü gelir', (tester) async {
    S.lang = Lang.tr;
    Settings.debugReopen();
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const GolgeApp());
    await wait(tester, 4 + 13);
    expect(find.byType(IntroOverlay), findsNothing);
    expect(find.text(S.of('newGame')), findsOneWidget);
  });
}
