import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'golge_game.dart';

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
