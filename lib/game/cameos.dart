import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'audio.dart';
import 'gokboru.dart' show standRow;
import 'golge_game.dart';
import 'level.dart';
import 'myth_figures.dart';
import 'nemrut.dart';
import 'puzzles.dart';
import 'strings.dart';

/// Mevcut bölümlere serpiştirilen kısa, bir kezlik görünüşler
/// (docs/MITOLOJI.md §4). Hiçbiri oynanışı zorlaştırmaz; ilk görülünce
/// Defter > Efsaneler'de kartı açılır.
///
/// Türler ve (sütun, satır) anlamı:
/// - `suIyesi`: su haznesinin başında kıpırdamadan bekleyene su yüzünde bir
///   yüz belirir, vanaları gösterir (konum kullanılmaz: en yakın hazne).
/// - `tulpar`: Sâye bu sütunu geçince gökte kanatlı bir at geçer.
/// - `ayazAta`: hücrenin yakınına gelince tipide bir an belirir.
/// - `akAna`: tufan başlayınca bu sütunda sudan yükselir, yolu aydınlatır.
/// - `basat`: taş dev yıkılınca ozan dizesi (konum kullanılmaz).
/// - `albasti`: bu hücreden başlayan mağarada uzun kıpırdamayanın ardında
///   kızıl bir gölge belirir, ışığını çeker; hücrenin solundaki demir nalın
///   yanına yaklaşamaz.
/// - `erlik`: hücrenin yakınında yerin dibinden boğuk bir ses.
/// - `erTostuk`: hücrenin duvarında Er Töştük'ün atlı gölgesi belirir.
/// - `demirci`: ocağın başında örsünü döven Demirci.
/// - `asena`: mağaranın ağzında yatan ak boz dişi kurt (sığınak).
class CameoWarden extends Component with HasGameReference<GolgeGame> {
  CameoWarden(this.cameos);

  final List<(String, int, int)> cameos;

  double _still = 0;
  Vector2? _stillAt;

  String _key(String kind) => 'cameo:${game.levelIndex}:$kind';

  void _say(String key) {
    game.once('cameo:$key', S.of('cameo_$key'));
  }

  @override
  void update(double dt) {
    super.update(dt);
    final p = game.player;
    if (p == null || p.isDead || game.cinematic) return;
    // Kıpırdamadan bekleme süresi (Su İyesi, Albastı).
    final at = _stillAt;
    if (at == null || (p.center - at).length > 6 || !p.onGround) {
      _stillAt = p.center.clone();
      _still = 0;
    } else {
      _still += dt;
    }
    for (final (kind, c, r) in cameos) {
      if (game.eventSeen(_key(kind))) continue;
      final cell = Vector2((c + 0.5) * kTile, (r + 0.5) * kTile);
      final d = p.center - cell;
      switch (kind) {
        case 'suIyesi':
          final basin = _nearestBasin(p.center);
          if (basin == null || _still < 2.5) break;
          final zone = basin.area.inflate(5 * kTile);
          if (!zone.contains(Offset(p.center.x, p.center.y))) break;
          game.markEvent(_key(kind));
          game.world.add(WaterFace(basin));
          _say(kind);
          game.meetMyth(kind);
        case 'tulpar':
          if (p.center.x < cell.x) break;
          game.markEvent(_key(kind));
          game.world.add(TulparFlight());
          _say(kind);
          game.meetMyth(kind);
        case 'ayazAta':
          if (d.x.abs() > 10 * kTile || d.y.abs() > 5 * kTile) break;
          game.markEvent(_key(kind));
          final row = standRow(game.level, c, r) ?? r;
          game.world.add(
            Apparition(
              Vector2((c + 0.5) * kTile, (row + 1) * kTile.toDouble()),
              draw: MythFigures.ayazAta,
              drawScale: 0.55,
              facing: p.center.x < cell.x ? -1 : 1,
              glow: const Color(0xFFBFE0F4),
              hold: 3.5,
            ),
          );
          GameAudio.instance.play('gust', volume: 0.6, minGapMs: 2000);
          _say(kind);
          game.meetMyth(kind);
        case 'akAna':
          WaterBasin? flood;
          for (final b in game.world.children.whereType<WaterBasin>()) {
            if (b.flooding) flood = b;
          }
          if (flood == null) break;
          game.markEvent(_key(kind));
          game.world.add(AkAnaRise(flood, cell.x));
          _say(kind);
          game.meetMyth(kind);
        case 'basat':
          final fell = game.world.children.whereType<StoneGiant>().any(
            (g) => g.fallen,
          );
          if (!fell) break;
          game.markEvent(_key(kind));
          _say(kind);
          game.meetMyth(kind);
        case 'albasti':
          final shoe = Vector2((c - 5 + 0.5) * kTile, (r - 1.5) * kTile);
          final inCave =
              p.center.x > (c - 6) * kTile &&
              p.center.x < (c + 27) * kTile &&
              (p.center.y - cell.y).abs() < 3 * kTile;
          if (!inCave) break;
          if (game.world.children.whereType<Horseshoe>().isEmpty) {
            game.world.add(Horseshoe(shoe));
          }
          // Demir nalın yanına yaklaşamaz.
          if ((p.center - shoe).length < 5 * kTile) break;
          if (_still < 4) break;
          game.markEvent(_key(kind));
          game.world.add(AlbastiShade());
          _say(kind);
          game.meetMyth(kind);
        case 'kam' || 'ulgen':
          if (d.x.abs() > 9 * kTile || d.y.abs() > 5 * kTile) break;
          game.markEvent(_key(kind));
          final row = standRow(game.level, c, r) ?? r;
          game.world.add(
            Apparition(
              Vector2((c + 0.5) * kTile, (row + 1) * kTile.toDouble()),
              draw: kind == 'kam' ? MythFigures.kam : MythFigures.ulgenLight,
              drawScale: kind == 'kam' ? 0.36 : 1,
              facing: p.center.x < cell.x ? -1 : 1,
              glow: kind == 'kam'
                  ? const Color(0xFFFF9A3A)
                  : const Color(0xFFFFF4D0),
              hold: kind == 'kam' ? 600 : 12,
            ),
          );
          _say(kind);
          game.meetMyth(kind);
        case 'gokKat':
          if (d.x.abs() > 6 * kTile || d.y.abs() > 6 * kTile) break;
          game.markEvent(_key(kind));
          _say(kind);
          game.meetMyth('ayAtaGunAna');
        case 'demirci' || 'asena':
          if (d.x.abs() > 9 * kTile || d.y.abs() > 4 * kTile) break;
          game.markEvent(_key(kind));
          final row = standRow(game.level, c, r) ?? r;
          game.world.add(
            Apparition(
              Vector2((c + 0.5) * kTile, (row + 1) * kTile.toDouble()),
              draw: kind == 'asena' ? MythFigures.asena : MythFigures.demirci,
              drawScale: kind == 'asena' ? 0.42 : 0.36,
              facing: p.center.x < cell.x ? -1 : 1,
              glow: kind == 'asena'
                  ? const Color(0xFFF0E0B8)
                  : const Color(0xFFFF8A3A),
              hold: kind == 'asena' ? 600 : 14,
            ),
          );
          _say(kind);
          game.meetMyth(kind);
        case 'erTostuk':
          if (d.x.abs() > 8 * kTile || d.y.abs() > 4 * kTile) break;
          game.markEvent(_key(kind));
          game.world.add(
            Apparition(
              Vector2(cell.x, cell.y + kTile / 2),
              draw: MythFigures.erTostukShadow,
              drawScale: 0.9,
              facing: p.center.x < cell.x ? -1 : 1,
              glow: const Color(0xFFFFE0A0),
              hold: 5,
              fadeIn: 2,
              fadeOut: 2.5,
            ),
          );
          _say(kind);
          game.meetMyth('erTostuk');
        case 'erlik':
          if (d.x.abs() > 3 * kTile || d.y.abs() > 3 * kTile) break;
          game.markEvent(_key(kind));
          GameAudio.instance.play('growl', volume: 0.35);
          GameAudio.instance.play('murmur', volume: 0.5);
          _say(kind);
          game.meetMyth(kind);
      }
    }
  }

  WaterBasin? _nearestBasin(Vector2 at) {
    WaterBasin? best;
    var bestD = double.infinity;
    for (final b in game.world.children.whereType<WaterBasin>()) {
      final d = (b.area.center.dx - at.x).abs();
      if (d < bestD) {
        bestD = d;
        best = b;
      }
    }
    return best;
  }
}

/// Bir efsane varlığının kısa görünüşü: belirir, bekler, söner.
class Apparition extends PositionComponent with HasGameReference<GolgeGame> {
  Apparition(
    Vector2 feet, {
    required this.draw,
    required this.drawScale,
    required this.glow,
    this.facing = 1,
    this.fadeIn = 1.4,
    this.hold = 3,
    this.fadeOut = 2,
  }) : super(position: feet, anchor: Anchor.bottomCenter, priority: 16);

  final void Function(Canvas, double) draw;
  final double drawScale;
  final Color glow;
  final int facing;
  final double fadeIn;
  final double hold;
  final double fadeOut;

  double _t = 0;
  double alpha = 0;

  Offset get glowCenter => Offset(position.x, position.y - 45 * drawScale);
  double get glowRadius => 110 * drawScale + 40;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t < fadeIn) {
      alpha = _t / fadeIn;
    } else if (_t < fadeIn + hold) {
      alpha = 1;
    } else {
      alpha = math.max(0, 1 - (_t - fadeIn - hold) / fadeOut);
      if (alpha <= 0) removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (alpha <= 0) return;
    // Saydamlık tek katmanda: varlığın kendi çizimi değişmeden söner.
    canvas.saveLayer(
      Rect.fromCenter(center: Offset.zero, width: 400, height: 400),
      Paint()..color = Color.fromRGBO(0, 0, 0, alpha * 0.85),
    );
    canvas.scale(facing * drawScale, drawScale);
    draw(canvas, _t);
    canvas.restore();
  }
}

/// Su İyesi: haznenin ortasında sudan beline kadar yükselen, sudan
/// yapılmış gibi yeşil-mavi ışıklı bir kadın. Uzun saçları su yüzüne
/// yayılır; eliyle vanayı gösterir, ışığı suyun içinden vanaya akar; sonra
/// yeniden suya çekilir.
class WaterFace extends Component with HasGameReference<GolgeGame> {
  WaterFace(this.basin) : super(priority: 27);

  final WaterBasin basin;
  double _t = 0;

  static const double rise = 1.6;
  static const double stay = 7.5;
  static const double sink = 1.8;
  static const double drawScale = 0.72;

  /// Sudan çıkış (0: suyun altında, 1: belden yukarısı dışarıda).
  double get _up {
    if (_t < rise) {
      final u = _t / rise;
      return u * u * (3 - 2 * u);
    }
    if (_t < rise + stay) return 1;
    final u = ((_t - rise - stay) / sink).clamp(0.0, 1.0);
    return 1 - u * u * (3 - 2 * u);
  }

  double get alpha => _up;

  Offset get _at => Offset(basin.area.center.dx, basin.surface);

  /// Gösterdiği vana: önce boşaltan (bulmaca onunla başlar), en yakını.
  Valve? get _valve {
    Valve? best;
    var bestD = double.infinity;
    for (final v in game.world.children.whereType<Valve>()) {
      final d = (v.position.x - _at.dx).abs() + (v.fill ? 2000 : 0);
      if (d < bestD) {
        bestD = d;
        best = v;
      }
    }
    return best;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > rise + stay + sink) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final up = _up;
    if (up <= 0) return;
    final s = basin.surface;
    final x = _at.dx;
    const sc = drawScale;
    // Bel (silüette -50) su yüzünde; çıkarken aşağıdan yükselir.
    final feetY = s + 50 * sc + (1 - up) * 60 * sc;
    const water = Color(0xFF9EE8DC);
    // Suyun içinden gelen yeşil-mavi ışık.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, s - 10), width: 120, height: 70),
      Paint()
        ..shader = ui.Gradient.radial(Offset(x, s - 10), 60, [
          water.withValues(alpha: 0.35 * up),
          water.withValues(alpha: 0),
        ]),
    );
    // Su yüzüne yayılan uzun saçlar.
    final hair = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4
      ..color = const Color(0xFFCFF4EE).withValues(alpha: 0.6 * up);
    for (var i = 0; i < 8; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final k = (i ~/ 2) + 1;
      final len = (18 + k * 9) * up;
      final path = Path()..moveTo(x + side * 4, s);
      for (var j = 1; j <= 8; j++) {
        final u = j / 8;
        path.lineTo(
          x + side * (4 + len * u),
          s + 1.5 + math.sin(_t * 2 + u * 6 + i) * 1.6 * u,
        );
      }
      canvas.drawPath(path, hair);
    }
    // Beden: belden yukarısı suyun üstünde.
    final body = MythFigures.akAnaSilhouette;
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(x - 80, s - 120, x + 80, s + 0.5));
    canvas.translate(x, feetY);
    canvas.scale(sc);
    canvas.drawPath(
      body,
      Paint()
        ..color = water.withValues(alpha: 0.55 * up)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, -100),
          const Offset(0, -50),
          [
            const Color(0xFFE8FFFA).withValues(alpha: 0.92 * up),
            water.withValues(alpha: 0.7 * up),
          ],
        ),
    );
    // Başından omuzlarına dökülen saç.
    canvas.drawPath(
      Path()
        ..moveTo(-6, -98)
        ..cubicTo(-9, -104, 9, -104, 6, -98)
        ..cubicTo(10, -86, 12, -70, 9, -54)
        ..lineTo(-9, -54)
        ..cubicTo(-12, -70, -10, -86, -6, -98)
        ..close(),
      Paint()..color = const Color(0xFFB8EDE4).withValues(alpha: 0.75 * up),
    );
    canvas.restore();
    // Suyun altındaki yansıma.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, s + 8), width: 26, height: 10),
      Paint()..color = water.withValues(alpha: 0.25 * up),
    );
    // Halkalar.
    for (var i = 0; i < 3; i++) {
      final u = (_t * 0.35 + i / 3) % 1;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, s),
          width: 24 + u * 100,
          height: 3 + u * 6,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = const Color(0xFFCFF4F0)
              .withValues(alpha: 0.6 * up * (1 - u)),
      );
    }
    // Vanayı gösteren kol ve vanaya akan ışık.
    final v = _valve;
    if (v != null && _t > rise * 0.7) {
      final shoulder = Offset(x, feetY - 80 * sc);
      final to = Offset(v.position.x, v.position.y - 8);
      final dir = (to - shoulder) / (to - shoulder).distance;
      final arm = Paint()
        ..color = const Color(0xFFE8FFFA).withValues(alpha: 0.85 * up)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(shoulder, shoulder + dir * 22, arm);
      final u = ((_t - rise) / 2.2).clamp(0.0, 1.0);
      final from = shoulder + dir * 22;
      final head = Offset.lerp(from, to, u)!;
      canvas.drawLine(
        from,
        head,
        Paint()
          ..shader = ui.Gradient.linear(from, head, [
            const Color(0x00CFF4F0),
            const Color(0xFFCFF4F0).withValues(alpha: 0.7 * up),
          ])
          ..strokeWidth = 1.6,
      );
      if (u >= 1) {
        final pulse = 0.6 + 0.4 * math.sin(_t * 5);
        canvas.drawCircle(
          to,
          14,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = const Color(0xFFCFF4F0)
                .withValues(alpha: 0.8 * up * pulse),
        );
      }
    }
  }
}

/// Tulpar: fırtınalı göğün yüksek bir yerinden dörtnala, kanat çırparak
/// geçen kanatlı at (önsezi). Kameraya göre konumlanır.
class TulparFlight extends Component with HasGameReference<GolgeGame> {
  TulparFlight() : super(priority: 1);

  static const double duration = 5;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect;
    final u = _t / duration;
    final x = view.right + 70 - (view.width + 140) * u;
    final y = view.top + view.height * 0.24 + math.sin(u * math.pi * 3) * 10;
    final a = math.min(1.0, math.min(u * 4, (1 - u) * 4)) * 0.8;
    canvas.saveLayer(
      Rect.fromCenter(center: Offset(x, y), width: 200, height: 160),
      Paint()..color = Color.fromRGBO(0, 0, 0, a),
    );
    canvas.translate(x, y + 30);
    canvas.scale(-0.5, 0.5);
    MythFigures.tulpar(canvas, _t * 2.2);
    canvas.restore();
  }
}

/// Ak Ana: tufan suyu yükselirken suyun içinden yükselen ak ışık; yükselen
/// suyla birlikte çıkar, çevresini aydınlatır.
class AkAnaRise extends PositionComponent with HasGameReference<GolgeGame> {
  AkAnaRise(this.basin, double x)
    : super(position: Vector2(x, basin.surface), priority: 27);

  final WaterBasin basin;
  static const double drawScale = 0.5;
  double _t = 0;
  double alpha = 0;

  Offset get glowCenter => Offset(position.x, position.y - 40 * drawScale);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    alpha = _t < 2 ? _t / 2 : (_t < 10 ? 1 : math.max(0, 1 - (_t - 10) / 2));
    if (_t > 12) removeFromParent();
    // Su çizgisi Ak Ana'nın belinde (çizimde -30): yükselen suyla gelir;
    // ilk iki saniyede sudan çıkar.
    final rise = (1 - math.min(1, _t / 2)) * 40;
    position.y = basin.surface + 30 * drawScale + rise;
  }

  @override
  void render(Canvas canvas) {
    if (alpha <= 0) return;
    canvas.saveLayer(
      Rect.fromCenter(center: Offset.zero, width: 200, height: 200),
      Paint()..color = Color.fromRGBO(0, 0, 0, alpha),
    );
    canvas.scale(drawScale);
    MythFigures.akAna(canvas, _t);
    canvas.restore();
  }
}

/// Albastı: uzun süre kıpırdamayan Sâye'nin ardında beliren kızıl gölge;
/// kavanozun ışığını çeker. Sâye birkaç adım uzaklaşınca dağılır.
class AlbastiShade extends PositionComponent with HasGameReference<GolgeGame> {
  AlbastiShade() : super(anchor: Anchor.bottomCenter, priority: 19);

  static const double drawScale = 0.42;
  Vector2? _anchor;
  double _t = 0;
  double alpha = 0;
  bool _leaving = false;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (p == null) return;
    _anchor ??= p.center.clone();
    if (!_leaving) {
      position.setValues(p.center.x - p.facing * 24, p.position.y + p.size.y);
      if ((p.center - _anchor!).length > 2.5 * kTile || p.isDead || _t > 14) {
        _leaving = true;
        GameAudio.instance.play('fizzle', volume: 0.5);
      }
    }
    alpha = _leaving
        ? math.max(0, alpha - dt * 1.6)
        : math.min(0.8, alpha + dt * 0.45);
    // Işığı çeker.
    game.jarSteal = alpha / 0.8;
    if (_leaving && alpha <= 0) {
      game.jarSteal = 0;
      removeFromParent();
    }
  }

  @override
  void onRemove() {
    game.jarSteal = 0;
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    if (alpha <= 0) return;
    canvas.saveLayer(
      Rect.fromLTWH(-40, -60, 80 + size.x, 80),
      Paint()..color = Color.fromRGBO(0, 0, 0, alpha),
    );
    final f = (game.player?.facing ?? 1).toDouble();
    canvas.translate(0, math.sin(_t * 1.3) * 1.2);
    canvas.scale(f * drawScale, drawScale);
    MythFigures.albasti(canvas, _t);
    canvas.restore();
  }
}

/// Mağara girişinde duvara çakılmış demir nal: Albastı yanına yaklaşamaz.
class Horseshoe extends PositionComponent {
  Horseshoe(Vector2 at) : super(position: at, priority: 6);

  @override
  void render(Canvas canvas) {
    final iron = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF5A5A5E);
    canvas.drawArc(
      const Rect.fromLTRB(-7, -6, 7, 9),
      math.pi * 0.1,
      -math.pi * 1.2,
      false,
      iron,
    );
    canvas.drawArc(
      const Rect.fromLTRB(-7, -6, 7, 9),
      math.pi * 0.1,
      -math.pi * 1.2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0xFFB8B8C0).withValues(alpha: 0.6),
    );
    final nail = Paint()..color = const Color(0xFF2A2A2E);
    for (final a in [-0.6, -1.6, -2.6, -3.6]) {
      canvas.drawCircle(
        Offset(math.cos(a + 0.4) * 7, 1.5 + math.sin(a + 0.4) * 7.5),
        0.7,
        nail,
      );
    }
    // Asıldığı çivi.
    canvas.drawCircle(const Offset(0, -9), 1.1, nail);
  }
}
