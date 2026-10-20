// Başlatma ikonu: `flutter test tools/preview/icon_test.dart` ile
// build/icon/ altına üç katman yazılır (tam ikon, arka plan, ön plan);
// boyutlar tools/make_icons.py ile çıkarılır.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/perde.dart';

const _size = 1024.0;

/// Kandille aydınlanan bez perde ve zemin.
void _background(ui.Canvas c) {
  const full = ui.Rect.fromLTWH(0, 0, _size, _size);
  const center = ui.Offset(_size * 0.5, _size * 0.52);
  c.drawRect(
    full,
    ui.Paint()
      ..shader = ui.Gradient.radial(
        center,
        _size * 0.78,
        const [
          ui.Color(0xFFFFD9A0),
          ui.Color(0xFFF2B46A),
          ui.Color(0xFFB8692F),
          ui.Color(0xFF4A2210),
        ],
        const [0, 0.2, 0.55, 1],
      ),
  );
  final weave = ui.Paint()
    ..color = const ui.Color(0x0D000000)
    ..strokeWidth = 2;
  for (var y = 3.0; y < _size; y += 7) {
    c.drawLine(ui.Offset(0, y), ui.Offset(_size, y), weave);
  }
  c.drawRect(
    const ui.Rect.fromLTWH(0, _size * 0.775, _size, _size * 0.3),
    ui.Paint()..color = const ui.Color(0xFF1A0B05),
  );
}

/// Sâye, kavanozunun ışığı ve hilal: güvenli dairenin içinde.
void _foreground(ui.Canvas c) {
  const scale = 6.2;
  const feet = ui.Offset(_size * 0.46, _size * 0.78);
  final jar = feet + const ui.Offset(26 * scale, -26 * scale);
  c.drawCircle(
    jar,
    120,
    ui.Paint()
      ..shader = ui.Gradient.radial(jar, 120, [
        const ui.Color(0xD0FFF0C8),
        const ui.Color(0x00FFC870),
      ]),
  );
  c.save();
  c.translate(feet.dx, feet.dy);
  c.scale(scale);
  PerdePainter.drawSaye(
    c,
    ui.Paint()..color = const ui.Color(0xFF140805),
    ui.Paint()..color = const ui.Color(0xFFFFF0C8),
    0.6,
  );
  c.restore();
  const moon = ui.Offset(_size * 0.67, _size * 0.25);
  c.drawPath(
    ui.Path.combine(
      ui.PathOperation.difference,
      ui.Path()..addOval(ui.Rect.fromCircle(center: moon, radius: 30)),
      ui.Path()..addOval(
        ui.Rect.fromCircle(center: moon + const ui.Offset(13, -7), radius: 25),
      ),
    ),
    ui.Paint()..color = const ui.Color(0xFF1A0B05),
  );
}

Future<void> _write(void Function(ui.Canvas) draw, String path) async {
  final rec = ui.PictureRecorder();
  draw(ui.Canvas(rec));
  final img = await rec.endRecording().toImage(_size.toInt(), _size.toInt());
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  test('ikon', () async {
    Directory('build/icon').createSync(recursive: true);
    await _write(_background, 'build/icon/background_1024.png');
    await _write(_foreground, 'build/icon/foreground_1024.png');
    await _write((c) {
      _background(c);
      _foreground(c);
    }, 'build/icon/icon_1024.png');
  });
}
