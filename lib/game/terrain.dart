import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'golge_game.dart';
import 'level.dart';
import 'levels.dart';
import 'palette.dart';
import '../settings.dart';

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

/// Bölümlerin dilimleri: en çok iki bölüm (oynanan ve perde altında önceden
/// hazırlanan sıradaki). Arazi yalnızca haritaya bağlı: ölüp yeniden doğunca
/// (aynı bölüm) yeniden çizilmez. Eskiden tek yuvaydı: perdenin altında eski
/// bölüm çizildikçe sıradakinin hazırlığı silinip geçişte yeniden çiziliyordu.
class _ChunkCache {
  static bool _cartoon = false;
  static double _tone = -1;

  /// Bölüm → (tür → dilimler); sıra son kullanımı izler (sondaki en yeni).
  static final _levels = <LevelDef, Map<String, List<_Chunk>>>{};
  static const _slots = 2;

  static void _release(Map<String, List<_Chunk>> lists) {
    for (final list in lists.values) {
      for (final c in list) {
        c.picture.dispose();
      }
    }
  }

  static List<_Chunk> of(
    String kind,
    Level lv,
    Picture Function(Level, int c0, int c1, int r0, int r1) build,
  ) {
    if (_cartoon != Cartoon.on || (Cartoon.on && _tone != Cartoon.toneStep)) {
      _cartoon = Cartoon.on;
      _tone = Cartoon.toneStep;
      _levels.values.forEach(_release);
      _levels.clear();
    }
    var lists = _levels[lv.def];
    if (lists == null) {
      while (_levels.length >= _slots) {
        final oldest = _levels.keys.first;
        _release(_levels.remove(oldest)!);
      }
      lists = _levels[lv.def] = {};
    } else if (!identical(_levels.keys.last, lv.def)) {
      // En yeni kullanılan sona.
      _levels.remove(lv.def);
      _levels[lv.def] = lists;
    }
    return lists[kind] ??= _chunked(lv, build);
  }

  /// Testler için: bir bölümün dilim listesi.
  static List<_Chunk>? debugList(LevelDef def, String kind) =>
      _levels[def]?[kind];
}

/// Testler için: [def]'in arazi dilimleri önbellekte mi (aynı nesne).
Object? debugTerrainChunks(LevelDef def) =>
    _ChunkCache.debugList(def, 'terrain');

/// Bölümün arazi ve ön plan dilimlerini önceden çizer (perde öncesi, ekran
/// kapalıyken): bölüm kurulurken çizmek geçişi takıltıyordu.
void warmTerrain(Level lv) {
  _ChunkCache.of('terrain', lv, _buildTerrain);
  _ChunkCache.of('fore', lv, _buildForeground);
}

void _drawVisible(Canvas canvas, List<_Chunk> chunks, Rect view) {
  for (final c in chunks) {
    if (c.bounds.overlaps(view)) canvas.drawPicture(c.picture);
  }
}

/// Arazi dilim dilim önceden çizilir; her karede yalnızca görünenler basılır.
class TerrainComponent extends Component with HasGameReference<GolgeGame> {
  TerrainComponent(this._level) : super(priority: 0) {
    _chunks;
  }

  final Level _level;
  // Önbellekten her karede alınır: görsel deneme açılıp kapanınca yeniden
  // çizilir (aynı bölümde tek bir sözlük bakışı).
  List<_Chunk> get _chunks => _ChunkCache.of('terrain', _level, _buildTerrain);
  static final _ink = Paint()..color = kInk;

  @override
  void render(Canvas canvas) {
    final lv = _level;
    final theme = lv.def.theme;
    // Haritanın dışı: yanlar (ve kapalı mekânlarda tavanın üstü) dolu kaya.
    if (!theme.airy) {
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
    if (theme == LevelTheme.ergenekon) _pitShade(canvas);
    _drawVisible(canvas, _chunks, game.camera.visibleWorldRect);
  }

  /// Zemin hizası: sütunlarda en sık rastlanan ilk katı karo.
  late final int _groundRow = () {
    final lv = _level;
    final count = <int, int>{};
    for (var c = 0; c < lv.width; c++) {
      for (var r = 0; r < lv.height; r++) {
        if (lv.solid(c, r)) {
          count[r] = (count[r] ?? 0) + 1;
          break;
        }
      }
    }
    return count.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }();

  /// Açık havada zemindeki çukurların içi karanlık: arkadaki vadi (çayır,
  /// ırmak) çukurdan görünüp düz bir yeşil blok gibi durmasın.
  void _pitShade(Canvas canvas) {
    final lv = _level;
    final view = game.camera.visibleWorldRect;
    final g = _groundRow;
    final top = g * kTile.toDouble();
    final c0 = math.max(0, (view.left / kTile).floor());
    final c1 = math.min(lv.width - 1, (view.right / kTile).ceil());
    const deep = Color(0xFF0D0A09);
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, top),
        Offset(0, top + 2.5 * kTile),
        [deep.withValues(alpha: 0.8), deep],
      );
    var c = c0;
    while (c <= c1) {
      if (lv.solid(c, g)) {
        c++;
        continue;
      }
      final start = c;
      while (c <= c1 && !lv.solid(c, g)) {
        c++;
      }
      canvas.drawRect(
        Rect.fromLTRB(
          start * kTile.toDouble(),
          top,
          c * kTile.toDouble(),
          lv.pixelHeight + 400,
        ),
        paint,
      );
    }
  }
}

/// Oyuncunun önünde çizilenler (uzun otlar, ön sütunlar): gizlenme yerlerini
/// görsel olarak da örter.
class ForegroundComponent extends Component with HasGameReference<GolgeGame> {
  ForegroundComponent(this._level) : super(priority: 30) {
    _chunks;
  }

  final Level _level;
  List<_Chunk> get _chunks => _ChunkCache.of('fore', _level, _buildForeground);

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
  final cartoon = Cartoon.on && theme == LevelTheme.cistern;
  if (cartoon) ink.color = Cartoon.stone;

  for (var r = r0; r <= r1; r++) {
    for (var c = c0; c <= c1; c++) {
      final x = c * kTile;
      final y = r * kTile;
      final rnd = _rng(c, r);
      switch (lv.cell(c, r)) {
        case '#' when lv.isIce(c, r):
          _iceBlock(canvas, lv, c, r, x, y, rnd);
        case '#' when cartoon:
          _cartoonStone(canvas, lv, c, r, x, y, rnd);
          for (final side in [-1, 1]) {
            if (lv.solid(c + side, r)) continue;
            final ex = side < 0 ? x : x + kTile;
            for (var i = 0; i < 2; i++) {
              canvas.drawCircle(
                Offset(ex, y + 4 + rnd.nextDouble() * (kTile - 8)),
                1.5 + rnd.nextDouble() * 2.5,
                ink,
              );
            }
          }
        case '#':
          canvas.drawRect(
            Rect.fromLTWH(x - 0.5, y - 0.5, kTile + 1, kTile + 1),
            ink,
          );
          // Doku denemesi: bölümün malzemesi (orijinal koyu renklerde).
          if (Cartoon.on && lv.def.skiSurface == null) {
            _themedBody(canvas, lv, theme, c, r, x, y, rnd);
          }
          if (theme == LevelTheme.ark) _hullPlanks(canvas, lv, c, r, x, y);
          // Zeminin yüzü: üst kenarda ışık alan ince bir şerit; taşın
          // içine doğru söner (zemin karanlıkta da seçilsin).
          if (r > 0 && !lv.solid(c, r - 1)) {
            _surfaceLight(canvas, theme, x, y, rnd);
          }
          // Sarnıçta ve yerin altında taşın üstünde ot bitmez.
          if (r > 0 &&
              !lv.solid(c, r - 1) &&
              theme != LevelTheme.cistern &&
              theme != LevelTheme.underworld) {
            _topDressing(canvas, theme, x, y, rnd, ink, line);
          }
          if (r + 1 < lv.height &&
              !lv.solid(c, r + 1) &&
              theme != LevelTheme.cistern) {
            if (theme.snowy) {
              _icicles(canvas, x, y, rnd);
            } else if (theme == LevelTheme.ark || theme == LevelTheme.peri) {
              // Ahşap ve tüf: altından bir şey sarkmaz.
            } else if (theme == LevelTheme.cave ||
                theme == LevelTheme.underworld) {
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
            _beam(
              canvas,
              x,
              y,
              rnd,
              left: lv.cell(c - 1, r) != '=',
              right: lv.cell(c + 1, r) != '=',
            );
          } else if (theme.snowy) {
            canvas.drawRect(Rect.fromLTWH(x - 0.5, y, kTile + 1, 7), ink);
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(x - 1, y - 3, kTile + 2, 5),
                const Radius.circular(2.5),
              ),
              Paint()..color = _snowCap,
            );
          } else if (theme == LevelTheme.nemrut) {
            // Kırık kaide taşı: yontulmuş, kenarı kopuk, üstü düz (basılan
            // yüzey öteki tahtalarla aynı yerde).
            final left = lv.cell(c - 1, r) != '=';
            final right = lv.cell(c + 1, r) != '=';
            final slab = Path()
              ..moveTo(x - 0.5, y)
              ..lineTo(x + kTile + 0.5, y)
              ..lineTo(x + kTile + 0.5 - (right ? 3 : 0), y + 9)
              ..lineTo(x + kTile * 0.6, y + 10 + rnd.nextDouble() * 2)
              ..lineTo(x + kTile * 0.25, y + 9 + rnd.nextDouble() * 2)
              ..lineTo(x - 0.5 + (left ? 3 : 0), y + 9)
              ..close();
            canvas.drawPath(slab, Paint()..color = const Color(0xFF3A2C34));
            canvas.drawLine(
              Offset(x - 0.5, y + 0.8),
              Offset(x + kTile + 0.5, y + 0.8),
              Paint()
                ..color = const Color(0xFF8A7480)
                ..strokeWidth = 1.2,
            );
            // Çatlak ve oyma çizgi.
            line
              ..strokeWidth = 0.9
              ..color = const Color(0xFF1A1218);
            final cx = x + 6 + rnd.nextDouble() * (kTile - 12);
            canvas.drawPath(
              Path()
                ..moveTo(cx, y + 1.5)
                ..lineTo(cx + 2, y + 5)
                ..lineTo(cx - 1, y + 9),
              line,
            );
            line.color = kInk;
          } else if (theme == LevelTheme.forest) {
            // Yaşayan dal: kabuklu, hafif kıvrık; uçlarında filiz.
            final left = lv.cell(c - 1, r) != '=';
            final right = lv.cell(c + 1, r) != '=';
            final bark = Paint()..color = const Color(0xFF2A1E14);
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(x - 0.5, y, kTile + 1, 7),
                Radius.circular(left || right ? 3.5 : 1),
              ),
              bark,
            );
            canvas.drawLine(
              Offset(x, y + 0.8),
              Offset(x + kTile, y + 0.8),
              Paint()
                ..color = const Color(0xFF6A5A38)
                ..strokeWidth = 1,
            );
            line
              ..strokeWidth = 0.8
              ..color = const Color(0xFF140E08);
            for (var i = 0; i < 2; i++) {
              final bx = x + 4 + rnd.nextDouble() * (kTile - 8);
              canvas.drawLine(Offset(bx, y + 2.5), Offset(bx + 5, y + 4), line);
            }
            line.color = kInk;
            final leaf = Paint()..color = const Color(0xFF4E7A3A);
            for (final end in [if (left) x + 2, if (right) x + kTile - 2]) {
              canvas.drawLine(
                Offset(end, y + 3),
                Offset(end + (end < x + 16 ? -5 : 5), y - 4),
                Paint()
                  ..color = const Color(0xFF2A1E14)
                  ..strokeWidth = 1.2,
              );
              canvas.drawOval(
                Rect.fromCenter(
                  center: Offset(end + (end < x + 16 ? -6 : 6), y - 5),
                  width: 6,
                  height: 3.4,
                ),
                leaf,
              );
            }
            if (rnd.nextDouble() < 0.4) {
              canvas.drawOval(
                Rect.fromCenter(
                  center: Offset(x + 8 + rnd.nextDouble() * 16, y + 9),
                  width: 5,
                  height: 3,
                ),
                leaf,
              );
            }
          } else if (theme == LevelTheme.sky || theme == LevelTheme.heavens) {
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
  if (theme == LevelTheme.forest) {
    // Orman: yosunlu üst kenar, gür ot, eğrelti yaprakları, ak çiçekler.
    final moss = Paint()..color = const Color(0xFF3E6A2A);
    canvas.drawRect(Rect.fromLTWH(x - 0.5, y - 1, kTile + 1, 4), moss);
    final grass = Paint()
      ..color = const Color(0xFF4E8030)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 7; i++) {
      final gx = x + rnd.nextDouble() * kTile;
      final gh = 4 + rnd.nextDouble() * 8;
      canvas.drawLine(
        Offset(gx, y + 1),
        Offset(gx + (rnd.nextDouble() - 0.5) * 5, y - gh),
        grass,
      );
    }
    if (rnd.nextDouble() < 0.35) {
      // Eğrelti: kavisli sap, iki yanında yaprakçıklar.
      final fx = x + rnd.nextDouble() * kTile;
      final fern = Paint()
        ..color = const Color(0xFF2E5A24)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      final dir = rnd.nextBool() ? 1.0 : -1.0;
      for (var k = 0; k < 6; k++) {
        final t = k / 6;
        final p0 = Offset(fx + dir * t * 12, y - t * 14 + t * t * 6);
        canvas.drawLine(p0, p0 + Offset(-4 + dir * 2, -4), fern);
        canvas.drawLine(p0, p0 + Offset(4 + dir * 2, -3), fern);
      }
    }
    if (rnd.nextDouble() < 0.2) {
      canvas.drawCircle(
        Offset(x + rnd.nextDouble() * kTile, y - 5),
        1.6,
        Paint()..color = const Color(0xFFF2EEDA),
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
/// Gemide basılan kalas: karanlık ambarda ve suyun üstünde seçilsin diye
/// açık renkli ahşap; üst kenarı fenerin ışığını yakalar, altına gölge
/// düşer, uçlarında duvara çakılı takozlar.
void _beam(
  Canvas canvas,
  double x,
  double y,
  math.Random rnd, {
  bool left = false,
  bool right = false,
}) {
  // Altındaki gölge.
  canvas.drawRect(
    Rect.fromLTWH(x - 0.5, y + 9, kTile + 1, 5),
    Paint()
      ..shader = Gradient.linear(Offset(x, y + 9), Offset(x, y + 14), [
        const Color(0xFF000000).withValues(alpha: 0.45),
        const Color(0x00000000),
      ]),
  );
  // Kalas gövdesi: üstü açık, altı koyu ahşap.
  canvas.drawRect(
    Rect.fromLTWH(x - 0.5, y, kTile + 1, 9),
    Paint()
      ..shader = Gradient.linear(Offset(x, y), Offset(x, y + 9), [
        const Color(0xFF7A5232),
        const Color(0xFF3A2414),
      ]),
  );
  // Fenerin ışığını yakalayan üst kenar.
  canvas.drawLine(
    Offset(x - 0.5, y + 0.8),
    Offset(x + kTile + 0.5, y + 0.8),
    Paint()
      ..color = const Color(0xFFE0A15F).withValues(alpha: 0.85)
      ..strokeWidth = 1.6,
  );
  // Ahşap damarı ve ek yeri.
  canvas.drawLine(
    Offset(x + 2, y + 5),
    Offset(x + kTile - 3, y + 5.4),
    Paint()
      ..color = const Color(0xFF2A190D).withValues(alpha: 0.6)
      ..strokeWidth = 0.6,
  );
  if (rnd.nextDouble() < 0.5) {
    canvas.drawCircle(
      Offset(x + 6 + rnd.nextDouble() * 20, y + 4.5),
      1.3,
      Paint()..color = const Color(0xFF2A190D),
    );
  }
  // Uçlarda duvara çakılı takoz.
  final bracket = Paint()..color = const Color(0xFF4A2C17);
  for (final (on, ex, dir) in [(left, x, 1.0), (right, x + kTile, -1.0)]) {
    if (!on) continue;
    canvas.drawPath(
      Path()
        ..moveTo(ex, y + 9)
        ..lineTo(ex + dir * 9, y + 9)
        ..lineTo(ex, y + 19)
        ..close(),
      bracket,
    );
    canvas.drawLine(
      Offset(ex + dir * 2, y),
      Offset(ex + dir * 2, y + 9),
      Paint()
        ..color = const Color(0xFF1A0F09)
        ..strokeWidth = 1,
    );
  }
}

/// Gemi gövdesi: dolu kareler üst üste bindirilmiş kalaslardır. Her kalas
/// sırasının ek yerleri kaydırılır, eklerde ağaç çiviler; havaya bakan
/// kenarlar fenerin ışığını hafifçe yakalar.
void _hullPlanks(Canvas canvas, Level lv, int c, int r, double x, double y) {
  const plank = kTile / 4;
  // Derinde koyulaşan ahşap: yüzeye yakın kalaslar sıcak, aşağısı karanlık.
  var depth = 0;
  while (depth < 4 && r - depth - 1 >= 0 && lv.solid(c, r - depth - 1)) {
    depth++;
  }
  final k = depth / 4;
  final wood = Paint()
    ..color = Color.lerp(const Color(0xFF3A2212), const Color(0xFF140B07), k)!;
  final seam = Paint()
    ..color = const Color(0xFF080402)
    ..strokeWidth = 1;
  final grain = Paint()
    ..color = Color.lerp(const Color(0xFF241409), const Color(0xFF0E0704), k)!
    ..strokeWidth = 0.6;
  canvas.drawRect(Rect.fromLTWH(x, y, kTile, kTile), wood);
  for (var i = 0; i < 4; i++) {
    final row = r * 4 + i;
    final py = y + i * plank;
    // Her kalas kendi tonunda.
    final t = ((row * 2654435761) >> 7) % 3;
    if (t != 1) {
      canvas.drawRect(
        Rect.fromLTWH(x, py, kTile, plank),
        Paint()
          ..color = (t == 0 ? const Color(0xFF000000) : const Color(0xFF6A4226))
              .withValues(alpha: 0.12 * (1 - k)),
      );
    }
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
    ..color = const Color(0xFFB07A48).withValues(alpha: 0.7)
    ..strokeWidth = 1.6;
  if (!lv.solid(c, r - 1) && r > 0) {
    // Güverte kalası: üstü fenerle aydınlık.
    canvas.drawRect(
      Rect.fromLTWH(x, y, kTile, plank),
      Paint()..color = const Color(0xFF5A3820),
    );
    canvas.drawLine(Offset(x, y + 0.8), Offset(x + kTile, y + 0.8), lit);
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
  final cartoon = Cartoon.on;
  final ink = Paint()..color = cartoon ? Cartoon.stoneDeep : kInk;
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
    if (cartoon) {
      // Kemerin ışık alan alt kenarı.
      canvas.drawPath(
        Path()
          ..moveTo(x, ceiling + 64)
          ..quadraticBezierTo(
            x + span / 2,
            ceiling - 24,
            x + span,
            ceiling + 64,
          ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = Cartoon.archRim,
      );
    }
    final c = (x / kTile).floor();
    var hasFront = false;
    for (var r = 0; r < lv.height; r++) {
      if (lv.cell(c, r) == 'I') hasFront = true;
    }
    // Sütun kendi altındaki zemine (ya da suya) iner; zeminin önüne taşmaz.
    final top = _ceilingBottom(lv, c);
    final floor = _floorTop(lv, c, top ~/ kTile);
    if (!hasFront && floor > top + 80) {
      _column(canvas, x, top + 40, floor, back: true, cartoon: cartoon);
    }
  }
}

/// Tavan kemerlerine oturan arka sütunlar (ışık denemesi kenarlarını
/// yakmak için): [_cisternVaults] ile aynı yerler.
List<Rect> cisternBackColumns(Level lv) {
  final out = <Rect>[];
  const span = kTile * 5;
  for (var x = kTile * 1.5; x < lv.pixelWidth; x += span) {
    final c = (x / kTile).floor();
    var hasFront = false;
    for (var r = 0; r < lv.height; r++) {
      if (lv.cell(c, r) == 'I') hasFront = true;
    }
    final top = _ceilingBottom(lv, c);
    final floor = _floorTop(lv, c, top ~/ kTile);
    if (!hasFront && floor > top + 80) {
      out.add(Rect.fromLTRB(x - 11, top + 52, x + 11, floor - 8));
    }
  }
  return out;
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

/// Nemrut'un dikili taşı (dexiosis steli): Antiochos'un bir tanrıyla
/// tokalaştığı kabartma. Oyuncunun önünde durur; ardında saklanılır.
void _stele(Canvas canvas, double x, double floor) {
  const w = 1.7 * kTile;
  const h = 3.6 * kTile;
  final top = floor - h;
  final slab = Path()
    ..moveTo(x - w / 2, floor)
    ..lineTo(x - w / 2, top + 14)
    ..lineTo(x, top)
    ..lineTo(x + w / 2, top + 14)
    ..lineTo(x + w / 2, floor)
    ..close();
  canvas.drawPath(slab, Paint()..color = const Color(0xFF14111A));
  // Kabartmanın çerçevesi.
  final relief = Paint()
    ..color = const Color(0xFF2A2433)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;
  canvas.drawRect(
    Rect.fromLTRB(x - w / 2 + 6, top + 20, x + w / 2 - 6, floor - 8),
    relief,
  );
  // Tokalaşan iki figür: solda tiaralı kral, sağda tanrı.
  final fig = Paint()..color = const Color(0xFF2A2433);
  for (final side in const [-1.0, 1.0]) {
    final fx = x + side * 11;
    canvas.drawPath(
      Path()
        ..moveTo(fx - 6, floor - 10)
        ..lineTo(fx - 5, top + 52)
        ..quadraticBezierTo(fx, top + 46, fx + 5, top + 52)
        ..lineTo(fx + 6, floor - 10)
        ..close(),
      fig,
    );
    canvas.drawCircle(Offset(fx, top + 40), 5, fig);
    // Kralın uzun tiarası, tanrının ışınlı tacı.
    if (side < 0) {
      canvas.drawPath(
        Path()
          ..moveTo(fx - 5, top + 38)
          ..lineTo(fx - 1, top + 22)
          ..lineTo(fx + 5, top + 38)
          ..close(),
        fig,
      );
    } else {
      for (var k = -2; k <= 2; k++) {
        canvas.drawLine(
          Offset(fx + k * 2.0, top + 36),
          Offset(fx + k * 3.0, top + 29),
          Paint()
            ..color = const Color(0xFF2A2433)
            ..strokeWidth = 1.2,
        );
      }
    }
  }
  // Uzanan eller ortada buluşur.
  canvas.drawLine(
    Offset(x - 6, top + 60),
    Offset(x + 6, top + 60),
    Paint()
      ..color = const Color(0xFF2A2433)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round,
  );
  // Tepesinde kar.
  canvas.drawPath(
    Path()
      ..moveTo(x - w / 2 - 1, top + 15)
      ..lineTo(x, top - 1)
      ..lineTo(x + w / 2 + 1, top + 15)
      ..lineTo(x + w / 2 - 3, top + 17)
      ..lineTo(x, top + 4)
      ..lineTo(x - w / 2 + 3, top + 17)
      ..close(),
    Paint()..color = const Color(0xFFB8C2D4),
  );
}

void _column(
  Canvas canvas,
  double cx,
  double top,
  double bottom, {
  bool back = false,
  bool cartoon = false,
}) {
  if (cartoon) {
    _cartoonColumn(canvas, cx, top, bottom, back: back);
    return;
  }
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
      if (lv.cell(c, r) == 'I' && lv.def.theme == LevelTheme.nemrut) {
        if (r > 0 && lv.cell(c, r - 1) == 'I') continue;
        _stele(canvas, c * kTile + kTile / 2, _floorTop(lv, c, r + 1));
        continue;
      }
      if (lv.cell(c, r) == 'I') {
        final top = _ceilingBottom(lv, c);
        final floor = _floorTop(lv, c, r + 1);
        final fr = (floor / kTile).round();
        final cx = c * kTile + kTile / 2;
        final cartoon = Cartoon.on && lv.def.theme == LevelTheme.cistern;
        if (fr < lv.height && lv.cell(c, fr) == 'w') {
          // Sudaki sütun yüzeyde bitmez, suya girer ve derinde solar: salın
          // (ve üstündeki Sâye'nin) önünde kalır, ikisi birlikte ardında
          // saklanır.
          const depth = 44.0;
          final area = Rect.fromLTRB(cx - 40, top, cx + 40, floor + depth);
          canvas.saveLayer(area, Paint());
          _column(canvas, cx, top + 40, floor + depth, cartoon: cartoon);
          canvas.drawRect(
            area,
            Paint()
              ..blendMode = BlendMode.dstIn
              ..shader = ui.Gradient.linear(
                Offset(cx, floor),
                Offset(cx, floor + depth),
                const [Color(0xFF000000), Color(0x00000000)],
              ),
          );
          canvas.restore();
          continue;
        }
        _column(canvas, cx, top + 40, floor, cartoon: cartoon);
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
  bool get _cartoon => Cartoon.on && level.def.theme == LevelTheme.cistern;

  /// Ötüken'in bataklığı: koyu yeşil su, yosun yeşili parıltı.
  bool get _bog => level.def.theme == LevelTheme.forest;

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

  /// Sarnıç suyunun serin tonu (yeşile çalan koyu mavi).
  static const _cool = Color(0xF0173236);

  final Level level;
  final _surface = <int, double>{};
  final _floor = <int, double>{};
  final _columns = <double>[];
  final _bodies = <double, Paint>{};
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  /// Işık ve derinlik denemesi: su üstündeki sahne aynalanır, hafifçe
  /// salınır, derinde kararır; yüzeyde kayan parıltılar ve ince bir sis.
  /// Aynalanan arazi ve ön sütunlar önceden çizilmiş dilimlerdir (ucuz).
  void _reflect(Canvas canvas, List<MapEntry<int, double>> visible) {
    if (visible.isEmpty) return;
    final terrain = _ChunkCache.of('terrain', level, _buildTerrain);
    final fore = _ChunkCache.of('fore', level, _buildForeground);
    // Aynı yükseklikteki komşu su sütunları tek şerit.
    final runs = <(double, double, double)>[];
    for (final MapEntry(key: c, value: top) in visible) {
      final x0 = c * kTile.toDouble();
      if (runs.isNotEmpty && runs.last.$3 == top && runs.last.$2 == x0) {
        runs[runs.length - 1] = (runs.last.$1, x0 + kTile, top);
      } else {
        runs.add((x0, x0 + kTile, top));
      }
    }
    const depth = 72.0;
    for (final (x0, x1, top) in runs) {
      final area = Rect.fromLTRB(x0, top, x1, top + depth);
      final mirror = Rect.fromLTRB(x0 - 40, top - depth - 12, x1 + 40, top);
      // Tek ayna geçişi (eskiden sekiz şerit ayrı ayrı çiziliyordu: her
      // karede sahnenin sekiz kopyası). Hafif yatay salınım dalgayı verir.
      canvas.saveLayer(area, Paint()..color = const Color(0x70000000));
      canvas.translate(math.sin(_t * 1.6) * 1.2, 2 * top);
      canvas.scale(1, -1);
      _drawVisible(canvas, terrain, mirror);
      _drawVisible(canvas, fore, mirror);
      canvas.restore();
      // Yüzeyde kayan ince parıltılar: dalga.
      final glint = Paint()
        ..color = const Color(0x30E8B888)
        ..strokeWidth = 1;
      for (var k = 0; k < 4; k++) {
        final gy = top + 6 + k * 13.0;
        final len = 26.0 + k * 8;
        final period = (x1 - x0) + len;
        final gx = x0 + ((_t * (14 + k * 5) + k * 53) % period) - len;
        canvas.drawLine(
          Offset(math.max(x0, gx), gy),
          Offset(math.min(x1, gx + len), gy),
          glint,
        );
      }
      // Derinde aynanın üstüne suyun koyuluğu iner.
      canvas.drawRect(
        area,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, top),
            Offset(0, top + depth),
            [const Color(0x00000000), const Color(0xC00A0504)],
          ),
      );
      // Yüzeyde ince sis.
      canvas.drawRect(
        Rect.fromLTRB(x0, top - 26, x1, top + 16),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, top - 26),
            Offset(0, top + 16),
            [
              const Color(0x00D8A07A),
              const Color(0x22D8A07A),
              const Color(0x00D8A07A),
            ],
            const [0, 0.6, 1],
          ),
      );
    }
  }

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
        top + (_cartoon ? 0.25 + Cartoon.toneStep * 0.1 : 0),
        () => Paint()
          ..shader = ui.Gradient.linear(Offset(0, top), Offset(0, top + 90), [
            // Sarnıcın suyu taşın sıcak renginden serin bir tonla ayrılır:
            // küçük ekranda da zeminle karışmaz.
            if (_cartoon)
              Color.lerp(Cartoon.water, _cool, 0.6)!
            else if (_bog)
              const Color(0xF0263A22)
            else
              Color.lerp(const Color(0xF0381A10), _cool, 0.55)!,
            if (_cartoon)
              Cartoon.waterDeep
            else if (_bog)
              const Color(0xFF060C06)
            else
              const Color(0xFF0A0504),
          ]),
      );
      canvas.drawRect(rect, body);
    }
    if (Realism.on &&
        !Realism.debugNoReflect &&
        !Settings.lowGraphics &&
        level.def.theme == LevelTheme.cistern) {
      _reflect(canvas, visible);
    }
    final glint = Paint()..strokeWidth = 1.3;
    for (final MapEntry(key: c, value: top) in visible) {
      final x = c * kTile;
      for (var i = 0; i < 3; i++) {
        final phase = _t * (0.8 + i * 0.3) + c * 1.7 + i * 2.1;
        final y = top + 3 + i * 9 + math.sin(phase) * 1.5;
        final len = 6 + 6 * (0.5 + 0.5 * math.sin(phase * 1.3));
        final gx = x + ((c * 13 + i * 11) % 24) + math.sin(_t * 0.5 + c) * 3;
        glint.color =
            (_cartoon
                    ? Cartoon.glint
                    : _bog
                    ? const Color(0xFFD8E8A0)
                    : const Color(0xFFE8915A))
                .withValues(
                  alpha: (0.35 - i * 0.1) * (0.6 + 0.4 * math.sin(phase * 2)),
                );
        canvas.drawLine(Offset(gx, y), Offset(gx + len, y), glint);
      }
    }
    // Sütunların su üstündeki dalgalı yansımaları.
    final reflection = Paint()
      ..color = (_cartoon ? Cartoon.stone : const Color(0xFF050302)).withValues(
        alpha: 0.55,
      );
    for (final cx in _columns) {
      if (cx < view.left - kTile || cx > view.right + kTile) continue;
      final top = _surface[(cx / kTile).floor()];
      if (top == null) continue;
      for (var y = top + 2; y < top + 60; y += 4) {
        final dx = math.sin(_t * 2 + y * 0.3) * 2.5;
        canvas.drawRect(Rect.fromLTWH(cx - 10 + dx, y, 20, 3), reflection);
      }
    }
    // Su yüzünün ince ışığı: yalnız suyun olduğu sütunlarda (önceden bütün
    // bölüm boyunca, kayaların üstünden de geçen bir çizgiydi).
    final edge = Paint()
      ..color =
          (_cartoon
                  ? Cartoon.lip
                  : _bog
                  ? const Color(0xFF9AB870)
                  : const Color(0xFFC0703A))
              .withValues(alpha: _cartoon ? 0.8 : 0.55)
      ..strokeWidth = 2;
    // Kenarın altında ince bir ışık ve dalgalanan yüzey: telefonda da
    // suyun nerede başladığı seçilir, taş zeminle karışmaz.
    final sheen = Paint()
      ..color = edge.color.withValues(alpha: _cartoon ? 0.22 : 0.16);
    edge.style = PaintingStyle.stroke;
    final runs = <(double, double, double)>[];
    for (final MapEntry(key: c, value: top) in visible) {
      final x0 = c * kTile.toDouble();
      canvas.drawRect(Rect.fromLTWH(x0, top, kTile.toDouble(), 6), sheen);
      if (runs.isNotEmpty && runs.last.$3 == top && runs.last.$2 == x0) {
        runs[runs.length - 1] = (runs.last.$1, x0 + kTile, top);
      } else {
        runs.add((x0, x0 + kTile, top));
      }
    }
    for (final (x0, x1, top) in runs) {
      final wave = Path()..moveTo(x0, top + 1);
      for (var x = x0 + 4; x <= x1; x += 4) {
        wave.lineTo(x, top + 1 + math.sin(x * 0.13 + _t * 2.2) * 1.3);
      }
      canvas.drawPath(wave, edge);
    }
  }
}

/// Temanın zemin ışığı: kenarı yalayan rengin tonu.
Color _surfaceTint(LevelTheme t) => switch (t) {
  LevelTheme.cistern => const Color(0xFFC07A44),
  LevelTheme.cave => const Color(0xFFC0602E),
  LevelTheme.cliffs => const Color(0xFFC08A62),
  LevelTheme.sky || LevelTheme.kaf => const Color(0xFFE0A070),
  LevelTheme.snow ||
  LevelTheme.nemrut ||
  LevelTheme.konya => const Color(0xFF9AB4D0),
  LevelTheme.ark => const Color(0xFFB8885A),
  LevelTheme.peri => const Color(0xFFD09A70),
  LevelTheme.underworld => const Color(0xFF8A6AC0),
  LevelTheme.ergenekon => const Color(0xFF8AA070),
  LevelTheme.heavens => const Color(0xFFE8E0F0),
  LevelTheme.forest => const Color(0xFFA8D27A),
  LevelTheme.sea => const Color(0xFF8FD6CC),
};

/// Üst yüzün ışığı ve ince taş dokusu.
void _surfaceLight(
  Canvas canvas,
  LevelTheme theme,
  double x,
  double y,
  math.Random rnd,
) {
  final tint = _surfaceTint(theme);
  canvas.drawRect(
    Rect.fromLTWH(x - 0.5, y, kTile + 1, 22),
    Paint()
      ..shader = ui.Gradient.linear(Offset(x, y), Offset(x, y + 22), [
        tint.withValues(alpha: 0.42),
        tint.withValues(alpha: 0),
      ]),
  );
  canvas.drawRect(
    Rect.fromLTWH(x - 0.5, y, kTile + 1, 2),
    Paint()..color = tint.withValues(alpha: 0.75),
  );
  // Taş dokusu: yüzeye yakın birkaç kısa çatlak ve çakıl.
  final grain = Paint()
    ..color = tint.withValues(alpha: 0.28)
    ..strokeWidth = 1;
  for (var i = 0; i < 3; i++) {
    final gx = x + 3 + rnd.nextDouble() * (kTile - 8);
    final gy = y + 4 + rnd.nextDouble() * 9;
    canvas.drawLine(
      Offset(gx, gy),
      Offset(gx + 3 + rnd.nextDouble() * 4, gy + 1),
      grain,
    );
  }
}

// --------------------------------------------------------- görsel deneme

/// Karikatürize taş: sıcak kahve gövde, sıra sıra taş derzleri; yüzeyde
/// ışık alan kalın bir dudak (basılacak kenar tek bakışta okunur).
void _cartoonStone(
  Canvas canvas,
  Level lv,
  int c,
  int r,
  double x,
  double y,
  math.Random rnd,
) {
  final top = r > 0 && !lv.solid(c, r - 1);
  // Yüzeyden derinlik (0 = üst karo): taş derinleştikçe koyulaşır, derz
  // kaybolur; göz yalnız basılacak kenarda kalır.
  var depth = 0;
  while (depth < 4 && r - depth - 1 >= 0 && lv.solid(c, r - depth - 1)) {
    depth++;
  }
  final deep = depth >= 2;
  canvas.drawRect(
    Rect.fromLTWH(x - 0.5, y - 0.5, kTile + 1, kTile + 1),
    Paint()
      ..color = Color.lerp(
        Cartoon.stone,
        Cartoon.stoneBottom,
        (depth / 3).clamp(0.0, 1.0),
      )!,
  );
  if (depth >= 3) return;
  // Derzler: yarım karo kaymalı taş sıraları.
  final seam = Paint()
    ..color = Cartoon.seam.withValues(alpha: deep ? 0.25 : 0.55)
    ..strokeWidth = 1.2;
  for (var row = 0; row < 2; row++) {
    final sy = y + row * 16.0 + (top ? 8 : 0);
    if (sy > y + kTile - 2) continue;
    canvas.drawLine(Offset(x, sy), Offset(x + kTile, sy), seam);
    final off = (r + row).isEven ? 0.0 : 16.0;
    final vx = x + off + 8 * rnd.nextDouble() * 0.2;
    canvas.drawLine(
      Offset(vx, sy),
      Offset(vx, math.min(sy + 16, y + kTile)),
      seam,
    );
  }
  if (!top) return;
  // Üst dudak: aydınlık bant, en üstte sıcak çizgi, altında koyu kesik.
  canvas.drawRect(
    Rect.fromLTWH(x - 0.5, y, kTile + 1, 6),
    Paint()..color = Cartoon.lip,
  );
  canvas.drawRect(
    Rect.fromLTWH(x - 0.5, y, kTile + 1, 1.8),
    Paint()..color = Cartoon.lipHot,
  );
  canvas.drawRect(
    Rect.fromLTWH(x - 0.5, y + 6, kTile + 1, 1.6),
    Paint()..color = Cartoon.seam.withValues(alpha: 0.8),
  );
  // Dudakta birkaç çentik.
  final notch = Paint()..color = Cartoon.stone.withValues(alpha: 0.5);
  for (var i = 0; i < 2; i++) {
    final nx = x + 4 + rnd.nextDouble() * (kTile - 10);
    canvas.drawRect(
      Rect.fromLTWH(nx, y + 2.5, 3 + rnd.nextDouble() * 3, 1.4),
      notch,
    );
  }
}

/// Karikatürize sütun: kalın gövde, iri başlık ve kaide, ışık alan sol
/// kenar, tavus gözü oymaları.
void _cartoonColumn(
  Canvas canvas,
  double cx,
  double top,
  double bottom, {
  bool back = false,
}) {
  final hw = back ? 10.0 : 15.0;
  final body = back
      ? (Paint()..color = Cartoon.backCol)
      : (Paint()
          ..shader = ui.Gradient.linear(
            Offset(cx - hw, 0),
            Offset(cx + hw, 0),
            Cartoon.colGrad,
            const [0, 0.42, 1],
          ));
  final cap = Paint()..color = back ? Cartoon.backCol : Cartoon.stone;
  final capW = back ? 5.0 : 12.0;
  canvas.drawRect(Rect.fromLTRB(cx - hw, top, cx + hw, bottom), body);
  // Başlık: iki kademe.
  canvas.drawPath(
    Path()
      ..moveTo(cx - hw - capW, top)
      ..lineTo(cx + hw + capW, top)
      ..lineTo(cx + hw + 4, top + 10)
      ..lineTo(cx + hw, top + 18)
      ..lineTo(cx - hw, top + 18)
      ..lineTo(cx - hw - 4, top + 10)
      ..close(),
    cap,
  );
  canvas.drawRect(
    Rect.fromLTRB(cx - hw - capW, top, cx + hw + capW, top + 2.5),
    Paint()..color = Cartoon.lip.withValues(alpha: back ? 0.35 : 0.8),
  );
  // Kaide.
  canvas.drawRect(
    Rect.fromLTRB(cx - hw - 6, bottom - 12, cx + hw + 6, bottom),
    cap,
  );
  canvas.drawRect(
    Rect.fromLTRB(cx - hw - 6, bottom - 12, cx + hw + 6, bottom - 10),
    Paint()..color = Cartoon.lip.withValues(alpha: back ? 0.3 : 0.7),
  );
  if (back) return;
  canvas.drawLine(
    Offset(cx - hw + 1.5, top + 18),
    Offset(cx - hw + 1.5, bottom - 12),
    Paint()
      ..color = Cartoon.lip.withValues(alpha: 0.55)
      ..strokeWidth = 2.5,
  );
  final eye = Paint()
    ..color = Cartoon.lip.withValues(alpha: 0.45)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;
  for (var y = top + 46; y < bottom - 36; y += 40) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, y), width: 12, height: 20),
      eye,
    );
    canvas.drawCircle(
      Offset(cx, y),
      2,
      Paint()..color = Cartoon.lip.withValues(alpha: 0.4),
    );
  }
}

// --------------------------------------------------------- doku denemesi

/// Bölümün malzemesi: (gövdenin yüzeye yakın rengi, ayrıntı rengi).
/// Koyu kalır (orijinal siluet); ayrıntı yalnız yüzeye yakın karolarda.
(Color, Color) _bodyTones(LevelTheme theme) => switch (theme) {
  LevelTheme.snow => (const Color(0xFF161B28), const Color(0xFF2C374C)),
  LevelTheme.peri => (const Color(0xFF26160E), const Color(0xFF4A2C1C)),
  LevelTheme.konya => (const Color(0xFF141824), const Color(0xFF283044)),
  LevelTheme.cliffs => (const Color(0xFF22130E), const Color(0xFF3E2418)),
  LevelTheme.cave => (const Color(0xFF24130B), const Color(0xFF42281A)),
  LevelTheme.ark => (const Color(0xFF1E120A), const Color(0xFF3A2414)),
  LevelTheme.nemrut => (const Color(0xFF1A1622), const Color(0xFF332C40)),
  LevelTheme.kaf => (const Color(0xFF0B201B), const Color(0xFF1C5444)),
  LevelTheme.underworld => (const Color(0xFF110B1A), const Color(0xFF34265A)),
  LevelTheme.ergenekon => (const Color(0xFF151518), const Color(0xFF2E3038)),
  LevelTheme.sky => (const Color(0xFF26140F), const Color(0xFF46281C)),
  LevelTheme.heavens => (const Color(0xFF131828), const Color(0xFF2A3450)),
  LevelTheme.cistern => (Cartoon.stone, Cartoon.seam),
  LevelTheme.forest => (const Color(0xFF16200F), const Color(0xFF2C3E1E)),
  LevelTheme.sea => (const Color(0xFF0A1C20), const Color(0xFF1A3C40)),
};

/// Doku denemesi (kayak bölümleri hariç): karonun gövdesi bölümün malzemesiyle (yüzeyden derine
/// koyulaşır), üstüne malzemenin işlemesi: kesme taş derzleri, tüf
/// katmanları, kaya çatlakları, keski izleri, maden damarları. Konya'da
/// yüzeyin hemen altında çini kuşak, Kapadokya'da oyma güvercinlik.
void _themedBody(
  Canvas canvas,
  Level lv,
  LevelTheme theme,
  int c,
  int r,
  double x,
  double y,
  math.Random rnd,
) {
  var depth = 0;
  while (depth < 4 && r - depth - 1 >= 0 && lv.solid(c, r - depth - 1)) {
    depth++;
  }
  if (depth >= 4) return;
  final (body, detail) = _bodyTones(theme);
  final fade = 1 - depth / 4;
  // Karo içinde yumuşak geçiş (üst kenarı bir üstteki karonun alt kenarıyla
  // aynı renk): basamak basamak bant ve karo izi kalmaz.
  canvas.drawRect(
    Rect.fromLTWH(x - 0.5, y - 0.5, kTile + 1, kTile + 1),
    Paint()
      ..isAntiAlias = false
      ..shader = ui.Gradient.linear(Offset(x, y), Offset(x, y + kTile), [
        Color.lerp(kInk, body, fade)!,
        Color.lerp(kInk, body, math.max(0, fade - 0.25))!,
      ]),
  );
  final a = 0.75 * fade;
  final line = Paint()
    ..color = detail.withValues(alpha: a)
    ..strokeWidth = 1.3
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  // Karonun dünyadaki yeri: desen karodan karoya kesintisiz sürsün.
  double wave(double wx, double k) =>
      math.sin(wx * 0.045 + k) * 2.2 + math.sin(wx * 0.11 + k * 2) * 1.2;
  switch (theme) {
    case LevelTheme.konya || LevelTheme.nemrut:
      // Kesme taş: Nemrut'ta iri bloklar, Konya'da düzgün sıralar.
      final h = theme == LevelTheme.nemrut ? 32.0 : 16.0;
      final w = theme == LevelTheme.nemrut ? 64.0 : 32.0;
      for (var sy = (y / h).ceil() * h; sy < y + kTile; sy += h) {
        canvas.drawLine(Offset(x, sy), Offset(x + kTile, sy), line);
      }
      final course = (y / h).floor();
      final off = course.isEven ? 0.0 : w / 2;
      for (var vx = ((x - off) / w).ceil() * w + off; vx < x + kTile; vx += w) {
        final top = math.max(y, course * h);
        canvas.drawLine(
          Offset(vx, top),
          Offset(vx, math.min(y + kTile, course * h + h)),
          line,
        );
      }
      if (theme == LevelTheme.konya && depth == 0) {
        // Çini kuşak: firuze zemin, ak benekler, ince lacivert kenar.
        final band = Rect.fromLTWH(x - 0.5, y + 9, kTile + 1, 6);
        canvas.drawRect(band, Paint()..color = const Color(0xCC1E6A78));
        final dot = Paint()..color = const Color(0xCC9ADCE0);
        for (var dx = 4.0; dx < kTile; dx += 8) {
          canvas.drawCircle(Offset(x + dx, y + 12), 1.3, dot);
        }
        final edge = Paint()
          ..color = const Color(0xCC14244A)
          ..strokeWidth = 1;
        canvas.drawLine(Offset(x, y + 9), Offset(x + kTile, y + 9), edge);
        canvas.drawLine(Offset(x, y + 15), Offset(x + kTile, y + 15), edge);
      }
    case LevelTheme.peri || LevelTheme.sky || LevelTheme.heavens:
      // Tüf ve tortu katmanları: dünyada süren dalgalı yatay çizgiler.
      for (var band = 0; band < 3; band++) {
        final by = y + 6 + band * 10.0;
        final p = Path()..moveTo(x, by + wave(x, band + r * 3.0));
        for (var dx = 4.0; dx <= kTile; dx += 4) {
          p.lineTo(x + dx, by + wave(x + dx, band + r * 3.0));
        }
        canvas.drawPath(p, line);
      }
      if (theme == LevelTheme.peri && depth >= 1 && rnd.nextDouble() < 0.14) {
        // Oyma güvercinlik: küçük kemerli karanlık oyuk.
        final hx = x + 8 + rnd.nextDouble() * (kTile - 16);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(hx - 4, y + 10, 8, 11),
            topLeft: const Radius.circular(4),
            topRight: const Radius.circular(4),
          ),
          Paint()..color = kInk.withValues(alpha: 0.9),
        );
      }
    case LevelTheme.snow || LevelTheme.cliffs || LevelTheme.forest:
      // Kaya: köşeli, kırık çatlaklar.
      for (var i = 0; i < 2; i++) {
        if (rnd.nextDouble() < 0.35) continue;
        var px = x + rnd.nextDouble() * kTile;
        var py = y + 3 + rnd.nextDouble() * 10;
        final p = Path()..moveTo(px, py);
        for (var k = 0; k < 3; k++) {
          px += (rnd.nextDouble() - 0.5) * 14;
          py += 4 + rnd.nextDouble() * 7;
          p.lineTo(px, py);
        }
        canvas.drawPath(p, line);
      }
      if (theme == LevelTheme.snow && depth == 0) {
        // Buz parıltısı: yüzeyin altında birkaç ince ak çizgi.
        final ice = Paint()
          ..color = const Color(0x557CA0C8)
          ..strokeWidth = 1;
        final gx = x + rnd.nextDouble() * (kTile - 10);
        canvas.drawLine(Offset(gx, y + 7), Offset(gx + 8, y + 9), ice);
      }
    case LevelTheme.cave:
      // Yumuşak tüfe vurulmuş keski izleri: kısa, eğik, sıra sıra.
      for (var row = 0; row < 3; row++) {
        for (var k = 0; k < 3; k++) {
          if (rnd.nextDouble() < 0.3) continue;
          final sx = x + 3 + k * 10 + rnd.nextDouble() * 3;
          final sy = y + 5 + row * 10;
          canvas.drawLine(Offset(sx, sy), Offset(sx + 4, sy + 5), line);
        }
      }
    case LevelTheme.kaf ||
        LevelTheme.underworld ||
        LevelTheme.ergenekon ||
        LevelTheme.sea:
      // Maden damarları: kıvrımlı ince çizgi, Kaf'ta zümrüt, Erlik'te mor,
      // Ergenekon'da kızgın demir.
      final glow = switch (theme) {
        LevelTheme.kaf => const Color(0xFF3ACF9A),
        LevelTheme.underworld => const Color(0xFF8A6ACF),
        _ => const Color(0xFFE0642A),
      };
      if (rnd.nextDouble() < 0.55) {
        var px = x + rnd.nextDouble() * kTile;
        var py = y + 2.0;
        final p = Path()..moveTo(px, py);
        while (py < y + kTile) {
          px += (rnd.nextDouble() - 0.5) * 10;
          py += 5 + rnd.nextDouble() * 4;
          p.lineTo(px, py);
        }
        // Parıltı bulanıklık filtresiyle değil, üst üste iki geniş, soluk
        // çizgiyle: kaya karolarının yarısında bulunan bu damarlar her
        // karede yeniden oynatılıyor; yüzlerce bulanıklık telefonda Kaf'ı,
        // Erlik'i, Ergenekon'u takıltıyordu.
        for (final (width, a) in const [(6.0, 0.07), (3.4, 0.11)]) {
          canvas.drawPath(
            p,
            Paint()
              ..color = glow.withValues(alpha: a * fade)
              ..strokeWidth = width
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..style = PaintingStyle.stroke,
          );
        }
        canvas.drawPath(
          p,
          Paint()
            ..color = glow.withValues(alpha: 0.55 * fade)
            ..strokeWidth = 1.1
            ..style = PaintingStyle.stroke,
        );
      }
    case LevelTheme.ark:
      // Ağaç lifi: tahtaların boyunca ince dalgalı çizgiler.
      for (var k = 0; k < 3; k++) {
        final gy = y + 5 + k * 9 + rnd.nextDouble() * 3;
        final p = Path()..moveTo(x, gy);
        for (var dx = 4.0; dx <= kTile; dx += 4) {
          p.lineTo(x + dx, gy + math.sin((x + dx) * 0.2 + k) * 0.8);
        }
        canvas.drawPath(p, line..strokeWidth = 0.8);
      }
    case LevelTheme.cistern:
      break;
  }
}
