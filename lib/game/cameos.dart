import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'audio.dart';
import 'gokboru.dart' show standRow;
import 'golge_game.dart';
import 'level.dart';
import 'myth_figures.dart';
import 'myth_shapes.dart';
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

/// Su İyesi: haznenin yüzünde, suyun altından bakan soluk bir yüz; ışığı
/// suyun içinden vanalara doğru akar.
class WaterFace extends Component with HasGameReference<GolgeGame> {
  WaterFace(this.basin) : super(priority: 27);

  final WaterBasin basin;
  double _t = 0;

  double get alpha => _t < 1.6
      ? _t / 1.6
      : _t < 7
      ? 1
      : math.max(0, 1 - (_t - 7) / 2);

  Offset get face =>
      Offset(basin.area.center.dx, basin.surface + 22 + math.sin(_t) * 1.5);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > 9) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = alpha;
    if (a <= 0) return;
    final c = face;
    // Halkalar.
    for (var i = 0; i < 3; i++) {
      final u = (_t * 0.35 + i / 3) % 1;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.dx, basin.surface),
          width: 20 + u * 90,
          height: 3 + u * 5,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = const Color(0xFFCFF4F0)
              .withValues(alpha: 0.6 * a * (1 - u)),
      );
    }
    // Yüz: Ak Ana çiziminin başı, suyun altında yatay, dalgalı.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(1.5 + math.sin(_t * 2.3) * 0.04, 1.05);
    canvas.translate(0, 92);
    canvas.clipRect(const Rect.fromLTRB(-20, -104, 20, -82));
    canvas.drawPath(
      MythShapes.akAna,
      Paint()
        ..color = const Color(0xFF9EE6DC).withValues(alpha: 0.6 * a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      MythShapes.akAna,
      Paint()..color = const Color(0xFFDFFAF6).withValues(alpha: 0.75 * a),
    );
    final eye = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2A6A66).withValues(alpha: 0.8 * a);
    for (final x in [-2.1, 2.1]) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(x, -92.6), width: 2, height: 1.4),
        0.2,
        math.pi - 0.4,
        false,
        eye,
      );
    }
    canvas.restore();
    // Işık suyun içinden vanalara akar.
    for (final v in game.world.children.whereType<Valve>()) {
      final to = Offset(v.position.x, v.position.y - 8);
      if ((to.dx - c.dx).abs() > basin.area.width + 6 * kTile) continue;
      final u = ((_t - 1.6) / 2.4).clamp(0.0, 1.0);
      final head = Offset.lerp(c, to, u)!;
      canvas.drawLine(
        c,
        head,
        Paint()
          ..shader = ui.Gradient.linear(c, head, [
            const Color(0x00CFF4F0),
            const Color(0xFFCFF4F0).withValues(alpha: 0.7 * a),
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
                .withValues(alpha: 0.8 * a * pulse),
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
