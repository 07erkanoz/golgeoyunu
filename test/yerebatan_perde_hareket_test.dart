import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/kukla.dart';
import 'package:golge/game/rig.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Yerebatan çıkışında el tutar ve basan ayak yerinde kalır', () async {
    await SayeKukla.load();
    expect(SayeKukla.ready, isTrue);
    final saye = SayeKukla();
    final input = KuklaInput()
      ..naturalMotion = true
      ..exactArms = true
      ..ledgeContact = true
      ..grip = const V(-22 / 3.24, 0)
      ..mode = KuklaMode.hang
      ..light = 0;
    saye.step(1 / 60, input);
    final wrist = saye.hand;
    expect((wrist - input.grip).distance, lessThan(1.7));

    input.mode = KuklaMode.climbUp;
    V? plantedToe;
    late V settlingShoulder;
    for (var frame = 0; frame <= 100; frame++) {
      saye.step(1 / 60, input..climb = frame / 100);
      if (frame <= 55) {
        expect(
          (saye.hand - wrist).distance,
          lessThan(0.8),
          reason: 'kare $frame',
        );
      }
      if (frame >= 58) {
        final toe = saye.soles[1];
        expect(toe.dy, closeTo(0, 0.18), reason: 'kare $frame');
        expect(toe.dx, greaterThan(input.grip.dx));
        plantedToe ??= toe;
        expect(
          (toe - plantedToe).distance,
          lessThan(0.2),
          reason: 'kare $frame',
        );
      }
      if (frame == 82) settlingShoulder = saye.shoulder;
    }
    final standing = saye.shoulder;
    expect(saye.soles.every((point) => point.dy.abs() < 0.18), isTrue);
    expect(saye.soles[1].dx - saye.soles[3].dx, greaterThan(1.2));
    expect(standing.dy, lessThan(settlingShoulder.dy - 2));
    expect(standing.dx, inInclusiveRange(saye.soles[2].dx, saye.soles[1].dx));
    saye.step(
      1 / 60,
      input
        ..mode = KuklaMode.ground
        ..ledgeContact = false,
    );
    expect((saye.shoulder - standing).distance, lessThan(0.2));
  });
}
