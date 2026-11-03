// İlk açılışta giriş yok: oyun doğrudan ana menüyle açılır (açılış perdesi
// "Yeni oyun"la oynar).
import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/strings.dart';
import 'package:golge/main.dart';
import 'package:golge/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ilk açılışta doğrudan menü gelir', (tester) async {
    S.lang = Lang.tr;
    Settings.debugReopen();
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const GolgeApp());
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text(S.of('newGame')), findsOneWidget);
    expect(find.textContaining(S.of('skipPerde')), findsNothing);
  });
}
