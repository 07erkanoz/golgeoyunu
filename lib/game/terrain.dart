import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'level.dart';
import 'levels.dart';
import 'palette.dart';

/// Arazinin tamamı tek seferde bir Picture'a çizilir; her karede sadece
/// o resim basılır.
class TerrainComponent extends Component {
  TerrainComponent(Level level)
    : _picture = _buildTerrain(level),
      super(priority: 0);

  final Picture _picture;

  @override
  void render(Canvas canvas) => canvas.drawPicture(_picture);
}

/// Oyuncunun önünde çizilen uzun otlar: gizlenme alanlarını görsel olarak da
/// örter.
class ForegroundComponent extends Component {
  ForegroundComponent(Level level)
    : _picture = _buildForeground(level),
      super(priority: 30);

  final Picture _picture;

  @override
  void render(Canvas canvas) => canvas.drawPicture(_picture);
}

math.Random _rng(int c, int r, [int salt = 0]) =>
    math.Random(c * 7919 + r * 104729 + salt * 31337 + 17);

Picture _buildTerrain(Level lv) {
  final rec = PictureRecorder();
  final canvas = Canvas(rec);
  final ink = Paint()..color = kInk;
  final line = Paint()
    ..color = kInk
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final cloud = Paint()..color = kCloud;
  final theme = lv.def.theme;

  // Haritanın dışı: yanlar (ve kapalı mekânlarda tavanın üstü) dolu kaya.
  if (theme != LevelTheme.sky) {
    const m = 3000.0;
    canvas.drawRect(Rect.fromLTRB(-m, -m, 0, lv.pixelHeight + m), ink);
    canvas.drawRect(
      Rect.fromLTRB(lv.pixelWidth, -m, lv.pixelWidth + m, lv.pixelHeight + m),
      ink,
    );
    if (theme == LevelTheme.cistern || theme == LevelTheme.cave) {
      canvas.drawRect(Rect.fromLTRB(-m, -m, lv.pixelWidth + m, 0.5), ink);
    }
  }

  for (var r = 0; r < lv.height; r++) {
    for (var c = 0; c < lv.width; c++) {
      final x = c * kTile;
      final y = r * kTile;
      final rnd = _rng(c, r);
      switch (lv.cell(c, r)) {
        case '#':
          canvas.drawRect(
            Rect.fromLTWH(x - 0.5, y - 0.5, kTile + 1, kTile + 1),
            ink,
          );
          if (r > 0 && !lv.solid(c, r - 1) && theme != LevelTheme.cistern) {
            for (var i = 0; i < 3; i++) {
              canvas.drawCircle(
                Offset(x + rnd.nextDouble() * kTile, y + 2),
                2 + rnd.nextDouble() * 3,
                ink,
              );
            }
            line.strokeWidth = 1.4;
            for (var i = 0; i < 7; i++) {
              final bx = x + rnd.nextDouble() * kTile;
              final h = 3 + rnd.nextDouble() * 8;
              final lean = (rnd.nextDouble() - 0.5) * 7;
              canvas.drawPath(
                Path()
                  ..moveTo(bx, y + 1)
                  ..quadraticBezierTo(
                    bx + lean * 0.2,
                    y - h * 0.6,
                    bx + lean,
                    y - h,
                  ),
                line,
              );
            }
          }
          if (r + 1 < lv.height &&
              !lv.solid(c, r + 1) &&
              theme != LevelTheme.cistern) {
            if (theme == LevelTheme.cave) {
              for (var i = 0; i < 2; i++) {
                if (rnd.nextDouble() < 0.4) continue;
                final sx = x + rnd.nextDouble() * (kTile - 8);
                final w = 4 + rnd.nextDouble() * 6;
                final len = 6 + rnd.nextDouble() * 16;
                canvas.drawPath(
                  Path()
                    ..moveTo(sx, y + kTile - 1)
                    ..lineTo(sx + w, y + kTile - 1)
                    ..lineTo(sx + w / 2, y + kTile + len)
                    ..close(),
                  ink,
                );
              }
            } else {
              line.strokeWidth = 1.2;
              for (var i = 0; i < 3; i++) {
                final sx = x + rnd.nextDouble() * kTile;
                final len = 6 + rnd.nextDouble() * 26;
                final sway = (rnd.nextDouble() - 0.5) * 8;
                canvas.drawPath(
                  Path()
                    ..moveTo(sx, y + kTile - 1)
                    ..cubicTo(
                      sx + sway,
                      y + kTile + len * 0.3,
                      sx - sway,
                      y + kTile + len * 0.7,
                      sx + sway * 0.5,
                      y + kTile + len,
                    ),
                  line,
                );
              }
            }
          }
          for (final side in [-1, 1]) {
            if (lv.solid(c + side, r)) continue;
            final ex = side < 0 ? x : x + kTile;
            for (var i = 0; i < 2; i++) {
              canvas.drawCircle(
                Offset(ex, y + rnd.nextDouble() * kTile),
                2 + rnd.nextDouble() * 3,
                ink,
              );
            }
          }
        case '=':
          if (theme == LevelTheme.cistern) {
            _walkway(canvas, lv, c, r, rnd);
          } else if (theme == LevelTheme.sky) {
            for (var i = 0; i < 4; i++) {
              canvas.drawCircle(
                Offset(
                  x + 4 + i * 8 + rnd.nextDouble() * 4,
                  y + 8 + rnd.nextDouble() * 3,
                ),
                7 + rnd.nextDouble() * 5,
                cloud,
              );
            }
            canvas.drawRect(Rect.fromLTWH(x, y + 2, kTile, 12), cloud);
          } else {
            canvas.drawRect(Rect.fromLTWH(x - 0.5, y, kTile + 1, 7), ink);
            for (var i = 0; i < 2; i++) {
              final sx = x + rnd.nextDouble() * kTile;
              canvas.drawCircle(
                Offset(sx, y + 7),
                2 + rnd.nextDouble() * 2,
                ink,
              );
            }
            line.strokeWidth = 1.1;
            final hx = x + rnd.nextDouble() * kTile;
            canvas.drawLine(
              Offset(hx, y + 6),
              Offset(hx + 2, y + 12 + rnd.nextDouble() * 10),
              line,
            );
          }
        case '^':
          for (var i = 0; i < 4; i++) {
            final sx = x + i * 8;
            final h = 12 + rnd.nextDouble() * 9;
            canvas.drawPath(
              Path()
                ..moveTo(sx, y + kTile)
                ..lineTo(sx + 8, y + kTile)
                ..lineTo(sx + 4 + (rnd.nextDouble() - 0.5) * 3, y + kTile - h)
                ..close(),
              ink,
            );
          }
        case 'D':
          _medusa(
            canvas,
            Offset(x + kTile / 2, y + kTile / 2 + 4),
            c.isOdd ? math.pi / 2 : math.pi,
          );
        case '|':
          line.strokeWidth = 2.2;
          final vine = Path();
          for (var i = 0; i <= 8; i++) {
            final yy = y + i * 4;
            final xx = x + kTile / 2 + math.sin(yy / 9) * 3;
            i == 0 ? vine.moveTo(xx, yy) : vine.lineTo(xx, yy);
          }
          canvas.drawPath(vine, line);
          for (var i = 0; i < 2; i++) {
            final yy = y + 8 + i * 16;
            final side = (r + i).isEven ? 1.0 : -1.0;
            final lx = x + kTile / 2 + math.sin(yy / 9) * 3;
            canvas.save();
            canvas.translate(lx + side * 4, yy);
            canvas.rotate(side * 0.6);
            canvas.drawOval(const Rect.fromLTWH(-4, -2, 8, 4), ink);
            canvas.restore();
          }
      }
    }
  }
  if (theme == LevelTheme.cistern) _cisternVaults(canvas, lv);
  return rec.endRecording();
}

const _stone = Color(0xFF150C09);
const _rim = Color(0xFF8A4A2A);

/// Tavan kemerleri ve oyuncunun arkasında kalan sütunlar. Kemerler her beş
/// karede bir sütuna oturur; harita `I` sütunlarını da aynı hizaya koyar.
void _cisternVaults(Canvas canvas, Level lv) {
  final ceiling = _ceilingBottom(lv, 1);
  final water = _floorTop(lv, 1, ceiling ~/ kTile);
  final ink = Paint()..color = kInk;
  const span = kTile * 5;
  for (var x = kTile * 1.5; x < lv.pixelWidth; x += span) {
    canvas.drawPath(
      Path()
        ..moveTo(x, ceiling - 1)
        ..lineTo(x, ceiling + 64)
        ..quadraticBezierTo(x + span / 2, ceiling - 24, x + span, ceiling + 64)
        ..lineTo(x + span, ceiling - 1)
        ..close(),
      ink,
    );
    final c = (x / kTile).floor();
    var hasFront = false;
    for (var r = 0; r < lv.height; r++) {
      if (lv.cell(c, r) == 'I') hasFront = true;
    }
    if (!hasFront) _column(canvas, x, ceiling + 40, water, back: true);
  }
}

double _ceilingBottom(Level lv, int c) {
  var r = 0;
  while (r < lv.height && lv.solid(c, r)) {
    r++;
  }
  return r * kTile;
}

double _floorTop(Level lv, int c, int fromRow) {
  for (var r = fromRow; r < lv.height; r++) {
    final ch = lv.cell(c, r);
    if (ch == 'w' || ch == 'D' || ch == '#') return r * kTile;
  }
  return lv.pixelHeight;
}

void _column(
  Canvas canvas,
  double cx,
  double top,
  double bottom, {
  bool back = false,
}) {
  final body = Paint()..color = back ? const Color(0xFF1C100B) : _stone;
  const hw = 11.0;
  canvas.drawRect(
    Rect.fromLTRB(cx - hw, top, cx + hw, bottom),
    back
        ? body
        : (Paint()
            ..shader = ui.Gradient.linear(
              Offset(cx - hw, 0),
              Offset(cx + hw, 0),
              const [Color(0xFF3A2216), Color(0xFF1E110B), Color(0xFF0C0605)],
              const [0, 0.45, 1],
            )),
  );
  canvas.drawPath(
    Path()
      ..moveTo(cx - hw - 8, top)
      ..lineTo(cx + hw + 8, top)
      ..lineTo(cx + hw, top + 12)
      ..lineTo(cx - hw, top + 12)
      ..close(),
    body,
  );
  canvas.drawRect(
    Rect.fromLTRB(cx - hw - 4, bottom - 8, cx + hw + 4, bottom),
    body,
  );
  final rim = Paint()
    ..color = _rim.withValues(alpha: back ? 0.25 : 0.55)
    ..strokeWidth = 2;
  canvas.drawLine(
    Offset(cx - hw + 1, top + 12),
    Offset(cx - hw + 1, bottom - 8),
    rim,
  );
  // Yerebatan sütunlarındaki "tavus gözü" oymaları.
  if (!back) {
    final eye = Paint()
      ..color = _rim.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var y = top + 40; y < bottom - 30; y += 34) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, y), width: 9, height: 14),
        eye,
      );
    }
  }
}

void _walkway(Canvas canvas, Level lv, int c, int r, math.Random rnd) {
  final x = c * kTile;
  final y = r * kTile;
  final wood = Paint()..color = const Color(0xFF120A07);
  canvas.drawRect(Rect.fromLTWH(x - 0.5, y, kTile + 1, 6), wood);
  final post = Paint()
    ..color = const Color(0xFF120A07)
    ..strokeWidth = 2.5;
  final water = _floorTop(lv, c, r + 1);
  canvas.drawLine(Offset(x + 6, y + 6), Offset(x + 6, water), post);
  // Korkuluk.
  final rail = Paint()
    ..color = const Color(0xFF120A07)
    ..strokeWidth = 1.6;
  canvas.drawLine(Offset(x, y - 18), Offset(x + kTile, y - 18), rail);
  canvas.drawLine(Offset(x + 6, y), Offset(x + 6, y - 18), rail);
  canvas.drawLine(
    Offset(x, y - 17),
    Offset(x + kTile, y - 17),
    Paint()
      ..color = _rim.withValues(alpha: 0.25)
      ..strokeWidth = 0.8,
  );
}

void _medusa(Canvas canvas, Offset c, double rotation) {
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.rotate(rotation);
  final stone = Paint()..color = const Color(0xFF2A1911);
  final carve = Paint()
    ..color = const Color(0xFF9A5A36).withValues(alpha: 0.6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round;
  // Yılan saçlar.
  for (var i = 0; i < 9; i++) {
    final a = -math.pi * 0.9 + i * (math.pi * 1.8 / 8);
    final p0 = Offset(math.cos(a) * 14, math.sin(a) * 14);
    final p1 = Offset(math.cos(a) * 24, math.sin(a) * 24);
    final bend = Offset(-math.sin(a) * 5, math.cos(a) * 5);
    canvas.drawPath(
      Path()
        ..moveTo(p0.dx, p0.dy)
        ..quadraticBezierTo(
          (p0 + p1).dx / 2 + bend.dx,
          (p0 + p1).dy / 2 + bend.dy,
          p1.dx,
          p1.dy,
        ),
      Paint()
        ..color = const Color(0xFF2A1911)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }
  canvas.drawOval(const Rect.fromLTRB(-16, -19, 16, 19), stone);
  canvas.drawArc(
    const Rect.fromLTRB(-9, -8, -2, -2),
    math.pi,
    math.pi,
    false,
    carve,
  );
  canvas.drawArc(
    const Rect.fromLTRB(2, -8, 9, -2),
    math.pi,
    math.pi,
    false,
    carve,
  );
  canvas.drawCircle(const Offset(-5.5, -4), 1.2, carve);
  canvas.drawCircle(const Offset(5.5, -4), 1.2, carve);
  canvas.drawLine(const Offset(0, -3), const Offset(-1.5, 5), carve);
  canvas.drawArc(
    const Rect.fromLTRB(-6, 6, 6, 12),
    0.2,
    math.pi - 0.4,
    false,
    carve,
  );
  canvas.drawOval(const Rect.fromLTRB(-16, -19, 16, 19), carve);
  canvas.restore();
}

Picture _buildForeground(Level lv) {
  final rec = PictureRecorder();
  final canvas = Canvas(rec);
  final blade = Paint()
    ..color = kInk
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  for (var r = 0; r < lv.height; r++) {
    for (var c = 0; c < lv.width; c++) {
      if (lv.cell(c, r) == 'I') {
        final top = _ceilingBottom(lv, c);
        _column(
          canvas,
          c * kTile + kTile / 2,
          top + 40,
          _floorTop(lv, c, r + 1),
        );
        continue;
      }
      if (lv.cell(c, r) != '~') continue;
      final rnd = _rng(c, r, 3);
      final ground = (r + 1) * kTile;
      for (var i = 0; i < 22; i++) {
        final bx = c * kTile - 6 + rnd.nextDouble() * (kTile + 12);
        final h = 28 + rnd.nextDouble() * 30;
        final lean = (rnd.nextDouble() - 0.5) * 22;
        blade.strokeWidth = 1.5 + rnd.nextDouble() * 2.5;
        canvas.drawPath(
          Path()
            ..moveTo(bx, ground + 2)
            ..quadraticBezierTo(
              bx + lean * 0.15,
              ground - h * 0.55,
              bx + lean,
              ground - h,
            ),
          blade,
        );
      }
      canvas.drawRect(
        Rect.fromLTWH(c * kTile - 4, ground - 14, kTile + 8, 16),
        Paint()..color = kInk,
      );
    }
  }
  return rec.endRecording();
}

/// Sarnıcın suyu: oyuncunun önünde çizilir, düşen her şeyi yutar.
class WaterComponent extends Component {
  WaterComponent(this.level) : super(priority: 26) {
    for (var c = 0; c < level.width; c++) {
      for (var r = 0; r < level.height; r++) {
        if (level.cell(c, r) != 'w') continue;
        _surface[c] = r * kTile;
        break;
      }
      for (var r = 0; r < level.height; r++) {
        if (level.cell(c, r) == 'I') _columns.add(c * kTile + kTile / 2);
      }
    }
  }

  final Level level;
  final _surface = <int, double>{};
  final _columns = <double>[];
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    if (_surface.isEmpty) return;
    final bottom = level.pixelHeight + 400;
    final body = Paint();
    for (final MapEntry(key: c, value: top) in _surface.entries) {
      final rect = Rect.fromLTRB(
        c * kTile - 0.5,
        top,
        (c + 1) * kTile + 0.5,
        bottom,
      );
      body.shader = ui.Gradient.linear(Offset(0, top), Offset(0, top + 90), [
        const Color(0xF0381A10),
        const Color(0xFF0A0504),
      ]);
      canvas.drawRect(rect, body);
    }
    final glint = Paint()..strokeWidth = 1.3;
    for (final MapEntry(key: c, value: top) in _surface.entries) {
      final x = c * kTile;
      for (var i = 0; i < 3; i++) {
        final phase = _t * (0.8 + i * 0.3) + c * 1.7 + i * 2.1;
        final y = top + 3 + i * 9 + math.sin(phase) * 1.5;
        final len = 6 + 6 * (0.5 + 0.5 * math.sin(phase * 1.3));
        final gx = x + ((c * 13 + i * 11) % 24) + math.sin(_t * 0.5 + c) * 3;
        glint.color = const Color(0xFFE8915A).withValues(
          alpha: (0.35 - i * 0.1) * (0.6 + 0.4 * math.sin(phase * 2)),
        );
        canvas.drawLine(Offset(gx, y), Offset(gx + len, y), glint);
      }
    }
    // Sütunların su üstündeki dalgalı yansımaları.
    final reflection = Paint()
      ..color = const Color(0xFF050302).withValues(alpha: 0.55);
    for (final cx in _columns) {
      final top = _surface[(cx / kTile).floor()];
      if (top == null) continue;
      for (var y = top + 2; y < top + 60; y += 4) {
        final dx = math.sin(_t * 2 + y * 0.3) * 2.5;
        canvas.drawRect(Rect.fromLTWH(cx - 10 + dx, y, 20, 3), reflection);
      }
    }
    canvas.drawLine(
      Offset(0, _surface.values.first),
      Offset(level.pixelWidth, _surface.values.first),
      Paint()
        ..color = const Color(0xFFC0703A).withValues(alpha: 0.25)
        ..strokeWidth = 1,
    );
  }
}
