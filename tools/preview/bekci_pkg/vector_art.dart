import 'dart:math' as math;
import 'dart:ui' as ui;

double number(dynamic v, [double fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  final s = v.toString();
  return s.endsWith('%')
      ? double.parse(s.substring(0, s.length - 1)) / 100
      : double.parse(s);
}

ui.Color hex(String s, [double opacity = 1]) => ui.Color(
  (int.parse(s.substring(1), radix: 16) | 0xff000000),
).withAlpha((opacity * 255).round().clamp(0, 255).toInt());

/// Records the exported SVG groups once. No SVG parsing occurs per frame.
class VectorArt {
  VectorArt(this.source) {
    final parts = source['parts'] as Map<String, dynamic>;
    for (final id in parts.keys) {
      final recorder = ui.PictureRecorder();
      _node(ui.Canvas(recorder), parts[id], 1);
      _pictures[id] = recorder.endRecording();
    }
  }
  final Map<String, dynamic> source;
  final Map<String, ui.Picture> _pictures = {};

  void draw(ui.Canvas canvas, String id) {
    final picture = _pictures[id];
    if (picture != null) canvas.drawPicture(picture);
  }

  void dispose() {
    for (final picture in _pictures.values) {
      picture.dispose();
    }
  }

  ui.Path _path(dynamic n) {
    final p = ui.Path();
    final a = n['a'] as Map<String, dynamic>;
    if (n['tag'] == 'ellipse') {
      p.addOval(ui.Rect.fromCenter(
        center: ui.Offset(number(a['cx']), number(a['cy'])),
        width: 2 * number(a['rx']), height: 2 * number(a['ry']),
      ));
      return p;
    }
    for (final dynamic row in n['ops'] as List) {
      final v = (row as List).skip(1).map(number).toList();
      switch (row[0]) {
        case 'M': p.moveTo(v[0], v[1]); break;
        case 'L': p.lineTo(v[0], v[1]); break;
        case 'Q': p.quadraticBezierTo(v[0], v[1], v[2], v[3]); break;
        case 'C': p.cubicTo(v[0], v[1], v[2], v[3], v[4], v[5]); break;
        case 'Z': p.close(); break;
        default: throw FormatException('Unknown path command: ${row[0]}');
      }
    }
    return p;
  }

  ui.Paint _paint(String value, List box, double opacity) {
    final paint = ui.Paint()..isAntiAlias = true;
    if (!value.startsWith('url(')) return paint..color = hex(value, opacity);
    final id = value.substring(5, value.length - 1);
    final g = source['gradients'][id];
    final a = g['a'];
    final x = number(box[0]), y = number(box[1]);
    final w = number(box[2]), h = number(box[3]);
    final colors = <ui.Color>[];
    final stops = <double>[];
    for (final st in g['stops'] as List) {
      colors.add(hex(st['stop-color'] ?? '#000000',
          number(st['stop-opacity'], 1) * opacity));
      stops.add(number(st['offset']));
    }
    if (g['kind'] == 'linearGradient') {
      paint.shader = ui.Gradient.linear(
        ui.Offset(x + number(a['x1']) * w, y + number(a['y1']) * h),
        ui.Offset(x + number(a['x2'], 1) * w, y + number(a['y2']) * h),
        colors, stops,
      );
    } else {
      paint.shader = ui.Gradient.radial(
        ui.Offset(x + number(a['cx'], .5) * w, y + number(a['cy'], .5) * h),
        math.max(.001, number(a['r'], .5) * math.max(w, h)), colors, stops,
      );
    }
    return paint;
  }

  void _node(ui.Canvas canvas, dynamic n, double inheritedOpacity) {
    final a = n['a'] as Map<String, dynamic>;
    final opacity = inheritedOpacity * number(a['opacity'], 1);
    canvas.save();
    final transform = a['transform'];
    if (transform != null) {
      for (final m in RegExp(r'(translate|rotate|scale)\(([^)]+)\)')
          .allMatches(transform as String)) {
        final v = m[2]!.trim().split(RegExp(r'[ ,]+')).map(double.parse).toList();
        switch (m[1]) {
          case 'translate': canvas.translate(v[0], v.length > 1 ? v[1] : 0); break;
          case 'rotate': canvas.rotate(v[0] * math.pi / 180); break;
          case 'scale': canvas.scale(v[0], v.length > 1 ? v[1] : v[0]); break;
        }
      }
    }
    final clip = a['clip-path'];
    if (clip != null) {
      final id = (clip as String).substring(5, clip.length - 1);
      final paths = source['clips'][id] as List?;
      if (paths != null && paths.isNotEmpty) canvas.clipPath(_path(paths.first));
    }
    if (n['tag'] == 'g') {
      for (final child in n['children'] as List) {
        _node(canvas, child, opacity);
      }
    } else if (n['tag'] == 'path' || n['tag'] == 'ellipse') {
      final p = _path(n);
      final box = n['box'] as List;
      final fill = a['fill'] ?? '#000000';
      if (fill != 'none') canvas.drawPath(p, _paint(fill, box, opacity));
      final stroke = a['stroke'];
      if (stroke != null && stroke != 'none') {
        final paint = _paint(stroke, box, opacity)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = number(a['stroke-width'], 1)
          ..strokeCap = a['stroke-linecap'] == 'round' ? ui.StrokeCap.round : ui.StrokeCap.butt
          ..strokeJoin = a['stroke-linejoin'] == 'round' ? ui.StrokeJoin.round : ui.StrokeJoin.miter;
        canvas.drawPath(p, paint);
      }
    }
    canvas.restore();
  }
}
