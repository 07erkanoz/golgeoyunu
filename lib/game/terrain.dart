import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'golge_game.dart';
import 'level.dart';
import 'levels.dart';
import 'palette.dart';

/// Arazinin bir dilimi: önceden çizilmiş resim ve kapladığı alan.
class _Chunk {
  _Chunk(this.bounds, this.picture);

  final Rect bounds;
  final Picture picture;
}

/// Bölümü 16 karelik dilimlere böler (yatay bölümlerde sütun, dikeylerde
/// satır dilimleri). Her karede yalnızca ekranda görünen dilimler çizilir:
/// uzun bölümlerde dahili ekran kartları için büyük fark.
List<_Chunk> _chunked(
  Level lv,
  Picture Function(Level, int c0, int c1, int r0, int r1) build,
) {
  const size = 16;
  const pad = kTile * 6; // süslemeler (kök, kemer) dilim dışına taşar
  final out = <_Chunk>[];
  if (lv.vertical) {
    for (var r0 = 0; r0 < lv.height; r0 += size) {
      final r1 = math.min(r0 + size - 1, lv.height - 1);
      out.add(
        _Chunk(
          Rect.fromLTRB(
            -pad,
            r0 * kTile - pad,
            lv.pixelWidth + pad,
            (r1 + 1) * kTile + pad,
          ),
          build(lv, 0, lv.width - 1, r0, r1),
        ),
      );
    }
  } else {
    for (var c0 = 0; c0 < lv.width; c0 += size) {
      final c1 = math.min(c0 + size - 1, lv.width - 1);
      out.add(
        _Chunk(
          Rect.fromLTRB(
            c0 * kTile - pad,
            -pad,
            (c1 + 1) * kTile + pad,
            lv.pixelHeight + pad,
          ),
          build(lv, c0, c1, 0, lv.height - 1),
        ),
      );
    }
  }
  return out;
}

void _drawVisible(Canvas canvas, List<_Chunk> chunks, Rect view) {
  for (final c in chunks) {
    if (c.bounds.overlaps(view)) canvas.drawPicture(c.picture);
  }
}

/// Arazi dilim dilim önceden çizilir; her karede yalnızca görünenler basılır.
class TerrainComponent extends Component with HasGameReference<GolgeGame> {
  TerrainComponent(this._level)
    : _chunks = _chunked(_level, _buildTerrain),
      super(priority: 0);

  final Level _level;
  final List<_Chunk> _chunks;
  static final _ink = Paint()..color = kInk;

  @override
  void render(Canvas canvas) {
    final lv = _level;
    final theme = lv.def.theme;
    // Haritanın dışı: yanlar (ve kapalı mekânlarda tavanın üstü) dolu kaya.
    if (theme != LevelTheme.sky && theme != LevelTheme.kaf) {
      const m = 3000.0;
      canvas.drawRect(Rect.fromLTRB(-m, -m, 0, lv.pixelHeight + m), _ink);
      canvas.drawRect(
        Rect.fromLTRB(lv.pixelWidth, -m, lv.pixelWidth + m, lv.pixelHeight + m),
        _ink,
      );
      if (theme.indoor) {
        canvas.drawRect(Rect.fromLTRB(-m, -m, lv.pixelWidth + m, 0.5), _ink);
      }
    }
    _drawVisible(canvas, _chunks, game.camera.visibleWorldRect);
  }
}

/// Oyuncunun önünde çizilenler (uzun otlar, ön sütunlar): gizlenme yerlerini
/// görsel olarak da örter.
class ForegroundComponent extends Component with HasGameReference<GolgeGame> {
  ForegroundComponent(Level level)
    : _chunks = _chunked(level, _buildForeground),
      super(priority: 30);

  final List<_Chunk> _chunks;

  @override
  void render(Canvas canvas) =>
      _drawVisible(canvas, _chunks, game.camera.visibleWorldRect);
}

math.Random _rng(int c, int r, [int salt = 0]) =>
    math.Random(c * 7919 + r * 104729 + salt * 31337 + 17);

Picture _buildTerrain(Level lv, int c0, int c1, int r0, int r1) {
  final rec = PictureRecorder();
  final canvas = Canvas(rec);
  final ink = Paint()..color = kInk;
  final line = Paint()
    ..color = kInk
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final cloud = Paint()..color = kCloud;
  final theme = lv.def.theme;

  for (var r = r0; r <= r1; r++) {
    for (var c = c0; c <= c1; c++) {
      final x = c * kTile;
      final y = r * kTile;
      final rnd = _rng(c, r);
      switch (lv.cell(c, r)) {
        case '#' when lv.isIce(c, r):
          _iceBlock(canvas, lv, c, r, x, y, rnd);
        case '#':
          canvas.drawRect(
            Rect.fromLTWH(x - 0.5, y - 0.5, kTile + 1, kTile + 1),
            ink,
          );
          if (theme == LevelTheme.ark) _hullPlanks(canvas, lv, c, r, x, y);
          if (r > 0 && !lv.solid(c, r - 1) && theme != LevelTheme.cistern) {
            _topDressing(canvas, theme, x, y, rnd, ink, line);
          }
          if (r + 1 < lv.height &&
              !lv.solid(c, r + 1) &&
              theme != LevelTheme.cistern) {
            if (theme.snowy) {
              _icicles(canvas, x, y, rnd);
            } else if (theme == LevelTheme.ark || theme == LevelTheme.peri) {
              // Ahşap ve tüf: altından bir şey sarkmaz.
            } else if (theme == LevelTheme.cave) {
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
            // Ahşap gövdenin kenarında kaya tümsekleri olmaz.
            if (theme == LevelTheme.ark) break;
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
          } else if (theme == LevelTheme.ark) {
            _beam(canvas, x, y, rnd);
          } else if (theme.snowy) {
            canvas.drawRect(Rect.fromLTWH(x - 0.5, y, kTile + 1, 7), ink);
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(x - 1, y - 3, kTile + 2, 5),
                const Radius.circular(2.5),
              ),
              Paint()..color = _snowCap,
            );
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
        case '|' when theme == LevelTheme.konya:
          // Şehirde tırmanılan yerler ahşap merdivendir.
          line.strokeWidth = 2.4;
          canvas.drawLine(Offset(x + 8, y), Offset(x + 8, y + kTile), line);
          canvas.drawLine(
            Offset(x + kTile - 8, y),
            Offset(x + kTile - 8, y + kTile),
            line,
          );
          line.strokeWidth = 2;
          for (final k in [6.0, 22.0]) {
            canvas.drawLine(
              Offset(x + 8, y + k),
              Offset(x + kTile - 8, y + k),
              line,
            );
          }
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
  if (theme == LevelTheme.cistern) _cisternVaults(canvas, lv, c0, c1);
  return rec.endRecording();
}

const _snowCap = Color(0xFFC8D2E2);

/// Kayanın üst yüzü: çimen, kar, zümrüt kristal, tüf ya da tahta.
void _topDressing(
  Canvas canvas,
  LevelTheme theme,
  double x,
  double y,
  math.Random rnd,
  Paint ink,
  Paint line,
) {
  if (theme.snowy) {
    // Kar örtüsü: yuvarlak kenarlı, yer yer kabaran yığıntılar.
    final snow = Paint()..color = _snowCap;
    canvas.drawRect(Rect.fromLTWH(x - 0.5, y - 1, kTile + 1, 4), snow);
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + rnd.nextDouble() * kTile, y),
          width: 8 + rnd.nextDouble() * 12,
          height: 4 + rnd.nextDouble() * 3,
        ),
        snow,
      );
    }
    return;
  }
  if (theme == LevelTheme.ark) {
    // Taşlaşmış ahşap: tahta birleşim çizgileri.
    final seam = Paint()
      ..color = const Color(0xFF2A190E)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(x, y + 1), Offset(x + kTile, y + 1), seam);
    if (rnd.nextDouble() < 0.5) {
      canvas.drawCircle(Offset(x + rnd.nextDouble() * kTile, y + 4), 1.2, seam);
    }
    return;
  }
  if (theme == LevelTheme.peri) {
    // Yumuşak tüf: aşınmış, dalgalı üst kenar.
    final tuff = Paint()..color = const Color(0xFF3A2620);
    for (var i = 0; i < 2; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + rnd.nextDouble() * kTile, y + 1),
          width: 14 + rnd.nextDouble() * 10,
          height: 5,
        ),
        tuff,
      );
    }
    return;
  }
  if (theme == LevelTheme.kaf) {
    // Zümrüt kristaller.
    final crystal = Paint()..color = const Color(0xFF2E8A6E);
    for (var i = 0; i < 2; i++) {
      if (rnd.nextDouble() < 0.4) continue;
      final cx = x + rnd.nextDouble() * kTile;
      final ht = 5 + rnd.nextDouble() * 9;
      canvas.drawPath(
        Path()
          ..moveTo(cx - 3, y + 1)
          ..lineTo(cx, y - ht)
          ..lineTo(cx + 3, y + 1)
          ..close(),
        crystal,
      );
    }
  }
  // Çimen.
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
        ..quadraticBezierTo(bx + lean * 0.2, y - h * 0.6, bx + lean, y - h),
      line,
    );
  }
}

/// Donmuş su: yarı saydam, mavimsi, içinde çatlaklar; üstü parlar.
void _iceBlock(
  Canvas canvas,
  Level lv,
  int c,
  int r,
  double x,
  double y,
  math.Random rnd,
) {
  final rect = Rect.fromLTWH(x - 0.5, y - 0.5, kTile + 1, kTile + 1);
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomLeft, [
        const Color(0xFF6E86A8),
        const Color(0xFF1C2638),
      ]),
  );
  final crack = Paint()
    ..color = const Color(0xFFC8D8EC).withValues(alpha: 0.35)
    ..strokeWidth = 1;
  final sx = x + rnd.nextDouble() * kTile;
  canvas.drawLine(
    Offset(sx, y + 4),
    Offset(sx + (rnd.nextDouble() - 0.5) * 16, y + kTile - 4),
    crack,
  );
  if (r > 0 && !lv.solid(c, r - 1)) {
    canvas.drawLine(
      Offset(x, y + 1),
      Offset(x + kTile, y + 1),
      Paint()
        ..color = const Color(0xFFEAF2FF).withValues(alpha: 0.8)
        ..strokeWidth = 1.6,
    );
  }
}

/// Saçaktan sarkan buz sarkıtları.
void _icicles(Canvas canvas, double x, double y, math.Random rnd) {
  final ice = Paint()..color = const Color(0xFF8FA4C0).withValues(alpha: 0.8);
  for (var i = 0; i < 3; i++) {
    if (rnd.nextDouble() < 0.35) continue;
    final sx = x + rnd.nextDouble() * (kTile - 6);
    final len = 6 + rnd.nextDouble() * 14;
    canvas.drawPath(
      Path()
        ..moveTo(sx, y + kTile - 1)
        ..lineTo(sx + 4, y + kTile - 1)
        ..lineTo(sx + 2, y + kTile + len)
        ..close(),
      ice,
    );
  }
}

/// Gemi içi: kalın ahşap kiriş ve çivileri.
void _beam(Canvas canvas, double x, double y, math.Random rnd) {
  canvas.drawRect(
    Rect.fromLTWH(x - 0.5, y, kTile + 1, 9),
    Paint()..color = const Color(0xFF1A0F09),
  );
  canvas.drawLine(
    Offset(x, y + 1),
    Offset(x + kTile, y + 1),
    Paint()
      ..color = const Color(0xFF6A4428).withValues(alpha: 0.5)
      ..strokeWidth = 1,
  );
  if (rnd.nextDouble() < 0.5) {
    canvas.drawCircle(
      Offset(x + 6 + rnd.nextDouble() * 20, y + 5),
      1.3,
      Paint()..color = const Color(0xFF3A2414),
    );
  }
}

/// Gemi gövdesi: dolu kareler üst üste bindirilmiş kalaslardır. Her kalas
/// sırasının ek yerleri kaydırılır, eklerde ağaç çiviler; havaya bakan
/// kenarlar fenerin ışığını hafifçe yakalar.
void _hullPlanks(Canvas canvas, Level lv, int c, int r, double x, double y) {
  const plank = kTile / 4;
  final wood = Paint()..color = const Color(0xFF140B07);
  final seam = Paint()
    ..color = const Color(0xFF050302)
    ..strokeWidth = 1;
  final grain = Paint()
    ..color = const Color(0xFF1C110A)
    ..strokeWidth = 0.6;
  canvas.drawRect(Rect.fromLTWH(x, y, kTile, kTile), wood);
  for (var i = 0; i < 4; i++) {
    final row = r * 4 + i;
    final py = y + i * plank;
    canvas.drawLine(Offset(x, py), Offset(x + kTile, py), seam);
    canvas.drawLine(
      Offset(x, py + plank * 0.55),
      Offset(x + kTile, py + plank * 0.55),
      grain,
    );
    // Ek yeri: her sırada 112 pikselde bir, sıradan sıraya kayar.
    final joint = (row * 47) % 112;
    final jx = ((x - joint) / 112).ceil() * 112.0 + joint;
    if (jx >= x && jx < x + kTile) {
      canvas.drawLine(Offset(jx, py), Offset(jx, py + plank), seam);
      canvas.drawCircle(Offset(jx + 2.5, py + plank / 2), 0.9, grain);
      canvas.drawCircle(Offset(jx - 2.5, py + plank / 2), 0.9, grain);
    }
  }
  // Havaya bakan kenar: ince ışık çizgisi.
  final lit = Paint()
    ..color = const Color(0xFF5A3A22).withValues(alpha: 0.55)
    ..strokeWidth = 1.2;
  if (!lv.solid(c, r - 1) && r > 0) {
    canvas.drawLine(Offset(x, y + 0.6), Offset(x + kTile, y + 0.6), lit);
  }
  if (!lv.solid(c, r + 1) && r + 1 < lv.height) {
    // Güverte altı: kalın bir kiriş payı.
    canvas.drawRect(
      Rect.fromLTWH(x, y + kTile - 5, kTile, 5),
      Paint()..color = const Color(0xFF0B0604),
    );
  }
}

/// Gemi ambarının direği: tavandaki kirişten tabana iner, demir çemberli;
/// tepesinde iki eğik destek (diz). Saklanma yeri olarak oyuncunun önünde.
void _mast(Canvas canvas, double cx, double top, double bottom) {
  const hw = 12.0;
  canvas.drawRect(
    Rect.fromLTRB(cx - hw, top - 2, cx + hw, bottom),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx - hw, 0),
        Offset(cx + hw, 0),
        const [Color(0xFF3A2414), Color(0xFF20130B), Color(0xFF0C0705)],
        const [0, 0.45, 1],
      ),
  );
  // Ağaç lifleri.
  final grain = Paint()
    ..color = const Color(0xFF0A0604).withValues(alpha: 0.6)
    ..strokeWidth = 0.8;
  for (final gx in [-6.0, -1.5, 4.0, 8.0]) {
    canvas.drawLine(Offset(cx + gx, top), Offset(cx + gx + 0.6, bottom), grain);
  }
  // Tepede iki eğik diz: kirişe bağlanır.
  final knee = Paint()..color = const Color(0xFF170D07);
  for (final s in [-1.0, 1.0]) {
    canvas.drawPath(
      Path()
        ..moveTo(cx + s * hw, top + 34)
        ..lineTo(cx + s * hw, top + 22)
        ..lineTo(cx + s * (hw + 26), top)
        ..lineTo(cx + s * (hw + 40), top)
        ..close(),
      knee,
    );
  }
  // Demir çemberler ve perçinler.
  final band = Paint()..color = const Color(0xFF241A16);
  final rivet = Paint()..color = const Color(0xFF6A5040);
  for (var y = top + 48; y < bottom - 20; y += 64) {
    canvas.drawRect(
      Rect.fromLTRB(cx - hw - 1.5, y, cx + hw + 1.5, y + 5),
      band,
    );
    for (final rx in [-7.0, 0.0, 7.0]) {
      canvas.drawCircle(Offset(cx + rx, y + 2.5), 0.9, rivet);
    }
  }
  // Tabanda halat yumağı.
  final rope = Paint()
    ..color = const Color(0xFF2A1C10)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;
  for (var i = 0; i < 3; i++) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 15, bottom - 3 - i * 3.2),
        width: 20 - i * 3,
        height: 5,
      ),
      rope,
    );
  }
}

const _stone = Color(0xFF150C09);
const _rim = Color(0xFF8A4A2A);

/// Tavan kemerleri ve oyuncunun arkasında kalan sütunlar. Kemerler her beş
/// karede bir sütuna oturur; harita `I` sütunlarını da aynı hizaya koyar.
void _cisternVaults(Canvas canvas, Level lv, int c0, int c1) {
  final ceiling = _ceilingBottom(lv, 1);
  final ink = Paint()..color = kInk;
  const span = kTile * 5;
  for (var x = kTile * 1.5; x < lv.pixelWidth; x += span) {
    if (x < c0 * kTile || x >= (c1 + 1) * kTile) continue;
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
    // Sütun kendi altındaki zemine (ya da suya) iner; zeminin önüne taşmaz.
    final top = _ceilingBottom(lv, c);
    final floor = _floorTop(lv, c, top ~/ kTile);
    if (!hasFront && floor > top + 80) {
      _column(canvas, x, top + 40, floor, back: true);
    }
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

Picture _buildForeground(Level lv, int c0, int c1, int r0, int r1) {
  final rec = PictureRecorder();
  final canvas = Canvas(rec);
  final blade = Paint()
    ..color = kInk
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  for (var r = r0; r <= r1; r++) {
    for (var c = c0; c <= c1; c++) {
      if (lv.cell(c, r) == 'I' && lv.def.theme == LevelTheme.ark) {
        if (r > 0 && lv.cell(c, r - 1) == 'I') continue;
        _mast(
          canvas,
          c * kTile + kTile / 2,
          _ceilingBottom(lv, c),
          _floorTop(lv, c, r + 1),
        );
        continue;
      }
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
class WaterComponent extends Component with HasGameReference<GolgeGame> {
  WaterComponent(this.level) : super(priority: 26) {
    for (var c = 0; c < level.width; c++) {
      for (var r = 0; r < level.height; r++) {
        if (level.cell(c, r) != 'w') continue;
        _surface[c] = r * kTile;
        // Suyun dibi: altında kaya ya da boşluk başlıyorsa orada biter.
        var b = r;
        while (b + 1 < level.height && level.cell(c, b + 1) == 'w') {
          b++;
        }
        _floor[c] = b + 1 >= level.height
            ? level.pixelHeight + 400
            : (b + 1) * kTile.toDouble();
        break;
      }
      for (var r = 0; r < level.height; r++) {
        if (level.cell(c, r) == 'I') _columns.add(c * kTile + kTile / 2);
      }
    }
  }

  final Level level;
  final _surface = <int, double>{};
  final _floor = <int, double>{};
  final _columns = <double>[];
  final _bodies = <double, Paint>{};
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    if (_surface.isEmpty) return;
    final view = game.camera.visibleWorldRect;
    final cMin = math.max(0, (view.left / kTile).floor() - 1);
    final cMax = math.min(level.width - 1, (view.right / kTile).ceil() + 1);
    final visible = [
      for (var c = cMin; c <= cMax; c++)
        if (_surface[c] case final top?) MapEntry(c, top),
    ];
    for (final MapEntry(key: c, value: top) in visible) {
      final bottom = _floor[c] ?? level.pixelHeight + 400;
      final rect = Rect.fromLTRB(
        c * kTile - 0.5,
        top,
        (c + 1) * kTile + 0.5,
        bottom,
      );
      final body = _bodies.putIfAbsent(
        top,
        () => Paint()
          ..shader = ui.Gradient.linear(Offset(0, top), Offset(0, top + 90), [
            const Color(0xF0381A10),
            const Color(0xFF0A0504),
          ]),
      );
      canvas.drawRect(rect, body);
    }
    final glint = Paint()..strokeWidth = 1.3;
    for (final MapEntry(key: c, value: top) in visible) {
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
      if (cx < view.left - kTile || cx > view.right + kTile) continue;
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
