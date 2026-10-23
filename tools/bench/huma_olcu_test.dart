import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/myth_shapes.dart';

void main() {
  test('hüma ölçü', () {
    // ignore: avoid_print
    print('süzülüş ${MythShapes.birdGlide.getBounds()}');
    // ignore: avoid_print
    print('çırpış ${MythShapes.birdFlap.getBounds()}');
  });
}
