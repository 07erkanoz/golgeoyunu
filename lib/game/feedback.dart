import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'golge_game.dart';
import 'level.dart';
import 'levels.dart';

/// Oyuncuya "ne oldu, neden oldu, ne değişti" diyen küçük görsel tepkiler:
/// inişte toz, kopacak taştan dökülen kırıntı, koldan kapıya akan ışık.
/// Hepsi kısa ömürlü ve ucuzdur; düşük grafikte de görünür (bilgi taşırlar).

/// Bir avuç toz ya da kırıntı: yana savrulur ya da aşağı dökülür, söner.
class DustPuff extends Component {
  DustPuff(
    Vector2 at, {
    this.color = const Color(0xFF8C7A66),
    int count = 10,
    double spread = 60,
    this.falling = false,
    int seed = 0,
  }) : _at = Offset(at.x, at.y),
       super(priority: 24) {
    final rnd = math.Random(seed ^ at.x.toInt() ^ (at.y.toInt() << 8));
    for (var i = 0; i < count; i++) {
      final side = i.isEven ? 1.0 : -1.0;
      _bits.add((
        Offset(side * rnd.nextDouble() * 6, 0),
        falling
            ? Offset((rnd.nextDouble() - 0.5) * 20, 20 + rnd.nextDouble() * 40)
            : Offset(
                side * (spread * 0.4 + rnd.nextDouble() * spread),
                -(8 + rnd.nextDouble() * 26),
              ),
        0.5 + rnd.nextDouble() * 0.4,
        1.5 + rnd.nextDouble() * 2.5,
      ));
    }
  }

  final Offset _at;
  final Color color;
  final bool falling;

  /// (çıkış, hız, ömür, boy)
  final _bits = <(Offset, Offset, double, double)>[];
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    if (_t > 1.0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint();
    for (final (o, v, life, r) in _bits) {
      final k = (_t / life).clamp(0.0, 1.0);
      if (k >= 1) continue;
      final slow = falling ? _t : (1 - math.exp(-_t * 4)) / 4;
      final p =
          _at + o + v * slow + Offset(0, falling ? 90 * _t * _t : 20 * _t * _t);
      paint.color = color.withValues(alpha: 0.75 * (1 - k));
      canvas.drawCircle(p, r * (falling ? 0.9 : 1.2 + k * 2), paint);
    }
  }
}

/// Koldan kapıya akan ışık: kol çekilince bir ışık topu kavisle kapıya
/// gider, vardığında kapıda bir an parlar (hangi kolun hangi kapıyı
/// açtığı görülür).
class LinkPulse extends Component {
  LinkPulse(Vector2 from, Vector2 to)
    : _from = Offset(from.x, from.y),
      _to = Offset(to.x, to.y),
      super(priority: 24);

  final Offset _from;
  final Offset _to;
  double _t = 0;

  /// Yolculuk süresi: uzaklığa göre, 0,5 – 1,1 sn.
  double get _travel => ((_to - _from).distance / 900).clamp(0.5, 1.1);

  Offset _at(double k) {
    // Hafif yukarı kavis: düz çizgi değil, bir akış.
    final mid =
        Offset.lerp(_from, _to, 0.5)! +
        Offset(0, -math.min(120.0, (_to - _from).distance * 0.25));
    final a = Offset.lerp(_from, mid, k)!;
    final b = Offset.lerp(mid, _to, k)!;
    return Offset.lerp(a, b, k)!;
  }

  @override
  void update(double dt) {
    _t += dt;
    if (_t > _travel + 0.7) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = (_t / _travel).clamp(0.0, 1.0);
    const warm = Color(0xFFFFD08A);
    if (_t <= _travel) {
      // Kuyruk: geride kalan birkaç sönük nokta.
      for (var i = 0; i < 6; i++) {
        final kk = (k - i * 0.04).clamp(0.0, 1.0);
        final p = _at(kk);
        canvas.drawCircle(
          p,
          4.0 - i * 0.5,
          Paint()..color = warm.withValues(alpha: 0.7 - i * 0.1),
        );
      }
      final head = _at(k);
      canvas.drawCircle(
        head,
        18,
        Paint()
          ..shader = ui.Gradient.radial(head, 18, [
            warm.withValues(alpha: 0.55),
            warm.withValues(alpha: 0),
          ]),
      );
      return;
    }
    // Vardı: kapıda kısa bir parıltı.
    final g = 1 - ((_t - _travel) / 0.7).clamp(0.0, 1.0);
    canvas.drawCircle(
      _to,
      70,
      Paint()
        ..shader = ui.Gradient.radial(_to, 70, [
          warm.withValues(alpha: 0.7 * g),
          warm.withValues(alpha: 0),
        ]),
    );
  }
}

/// Ateşböceğinin ışığı hedefe akar: kısa bir parlama, içe çekilen
/// kıvılcımlar ve genişleyen bir halka.
class LightAbsorb extends Component {
  LightAbsorb(Vector2 at) : _at = Offset(at.x, at.y), super(priority: 24);

  final Offset _at;
  double _t = 0;
  static const _len = 0.8;

  @override
  void update(double dt) {
    _t += dt;
    if (_t > _len) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = (_t / _len).clamp(0.0, 1.0);
    const warm = Color(0xFFFFD592);
    canvas.drawCircle(
      _at,
      34 + 20 * k,
      Paint()
        ..shader = ui.Gradient.radial(_at, 34 + 20 * k, [
          warm.withValues(alpha: 0.6 * (1 - k)),
          warm.withValues(alpha: 0),
        ]),
    );
    canvas.drawCircle(
      _at,
      8 + 40 * k,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = warm.withValues(alpha: 0.7 * (1 - k)),
    );
    // İçe çekilen kıvılcımlar: ışık hedefe girer.
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + 0.3;
      final r = 30 * (1 - k);
      canvas.drawCircle(
        _at + Offset(math.cos(a) * r, math.sin(a) * r),
        1.6,
        Paint()..color = const Color(0xFFFFF4D6).withValues(alpha: 1 - k),
      );
    }
  }
}

/// Kandilci ışığı fark edince fenerinden ona uzanan kısa bakış çizgisi.
class GazeLine extends Component {
  GazeLine(Vector2 from, this.target)
    : _from = Offset(from.x, from.y),
      super(priority: 24);

  final Offset _from;
  final PositionComponent target;
  double _t = 0;
  static const _len = 0.9;

  @override
  void update(double dt) {
    _t += dt;
    if (_t > _len || !target.isMounted) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = (_t / _len).clamp(0.0, 1.0);
    final to = Offset(target.position.x, target.position.y);
    final grow = math.min(1.0, _t / 0.25);
    final end = Offset.lerp(_from, to, grow)!;
    final paint = Paint()
      ..color = const Color(0xFFBFE6FF).withValues(alpha: 0.55 * (1 - k))
      ..strokeWidth = 1.4;
    // Kesik çizgi: bakışın yönü.
    final d = end - _from;
    final n = (d.distance / 10).floor();
    for (var i = 0; i < n; i += 2) {
      canvas.drawLine(_from + d * (i / n), _from + d * ((i + 1) / n), paint);
    }
  }
}

/// Açılan yolda ilerleyen ışık: kapıdan geçip birkaç kare ileriye akar,
/// yerde ince bir iz bırakır ve söner (yeni yol buradan).
class PathLight extends Component {
  PathLight(Vector2 from, this.dir)
    : _from = Offset(from.x, from.y),
      super(priority: 24);

  final Offset _from;
  final double dir;
  double _t = 0;
  static const _len = 1.6;
  static const _reach = 240.0;

  @override
  void update(double dt) {
    _t += dt;
    if (_t > _len) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = (_t / _len).clamp(0.0, 1.0);
    final ease = 1 - math.pow(1 - k, 2).toDouble();
    final head = _from + Offset(dir * _reach * ease, 0);
    const warm = Color(0xFFFFD592);
    final fade = k < 0.7 ? 1.0 : 1 - (k - 0.7) / 0.3;
    canvas.drawLine(
      _from,
      head,
      Paint()
        ..shader = ui.Gradient.linear(_from, head, [
          warm.withValues(alpha: 0),
          warm.withValues(alpha: 0.55 * fade),
        ])
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      head,
      16,
      Paint()
        ..shader = ui.Gradient.radial(head, 16, [
          warm.withValues(alpha: 0.6 * fade),
          warm.withValues(alpha: 0),
        ]),
    );
  }
}

/// Karda ayak izi: birkaç saniye kalır, yavaşça kar örter.
class Footprint extends Component {
  Footprint(Vector2 at, this.left)
    : _at = Offset(at.x + (left ? -2 : 2), at.y - 1),
      super(priority: 15);

  final Offset _at;
  final bool left;
  double _t = 0;
  static const _len = 6.0;

  @override
  void update(double dt) {
    _t += dt;
    if (_t > _len) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = 1 - (_t / _len).clamp(0.0, 1.0);
    canvas.drawOval(
      Rect.fromCenter(center: _at, width: 6, height: 2.4),
      Paint()..color = const Color(0xFF6E7C8C).withValues(alpha: 0.55 * a),
    );
  }
}

/// Basılabilir yüzeylerin üst kenarı: koyu zeminin arka plana karıştığı
/// temalarda (uçurum, mağara) ince ılık bir çizgi ve altında hafif bir ışık;
/// telefonda iniş yeri seçilsin. Yalnız ekrandaki kareler çizilir.
class SurfaceEdge extends Component with HasGameReference<GolgeGame> {
  SurfaceEdge(this.level) : super(priority: 3);

  final Level level;

  /// Kenar çizgisi isteyen temalar.
  static bool wants(LevelTheme t) =>
      t == LevelTheme.cliffs || t == LevelTheme.cave;

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect;
    final c0 = math.max(0, (view.left / kTile).floor());
    final c1 = math.min(level.width - 1, (view.right / kTile).ceil());
    final r0 = math.max(1, (view.top / kTile).floor());
    final r1 = math.min(level.height - 1, (view.bottom / kTile).ceil());
    final line = Paint()
      ..color = const Color(0xFFC89A62).withValues(alpha: 0.6)
      ..strokeWidth = 1.6;
    final glow = Paint()
      ..color = const Color(0xFFC89A62).withValues(alpha: 0.14);
    for (var c = c0; c <= c1; c++) {
      for (var r = r0; r <= r1; r++) {
        if (!level.solid(c, r) || level.solid(c, r - 1)) continue;
        final x = c * kTile.toDouble();
        final y = r * kTile.toDouble();
        canvas.drawRect(Rect.fromLTWH(x, y, kTile.toDouble(), 5), glow);
        canvas.drawLine(Offset(x, y + 0.8), Offset(x + kTile, y + 0.8), line);
      }
    }
  }
}

/// Sâye'nin ayak altında ılık bir ışık lekesi: koyu sahnede durduğu yer
/// seçilsin (karakterin kendisi parlamaz; gölge kimliği korunur).
void drawFootGlow(Canvas canvas, Offset feet, double alpha) {
  if (alpha <= 0.01) return;
  final rect = Rect.fromCenter(center: feet, width: 46, height: 10);
  canvas.drawOval(
    rect,
    Paint()
      ..shader = ui.Gradient.radial(feet, 23, [
        const Color(0xFFFFC98A).withValues(alpha: 0.45 * alpha),
        const Color(0x00FFC98A),
      ]),
  );
}

extension FeedbackGame on GolgeGame {
  /// Bir noktada toz kaldırır.
  void dust(Vector2 at, {Color? color, int count = 10, bool falling = false}) {
    world.add(
      DustPuff(
        at,
        color: color ?? const Color(0xFF8C7A66),
        count: count,
        falling: falling,
      ),
    );
  }
}
