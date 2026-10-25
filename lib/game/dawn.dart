import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'golge_game.dart';
import 'level.dart';

// ================================================================ Şafak
//
// VIII · Gün Doğumu, "Şafağın Gölgeleri": güneş doğudan doğar, oturan
// tanrıların uzun gölgeleri batıya düşer. Kandilciler yalnız gölgede
// yürür, güneşe adım atmaz; güneşte duranı gözleri kamaşıp görmez. Güneş
// yükseldikçe gölgeler kısalır: sabreden güneşte bekler, gölgeyi Kandilci
// uzaktayken geçer ya da tanrının omzundan aşar.

class DawnShadows extends PositionComponent with HasGameReference<GolgeGame> {
  DawnShadows(this.c0, this.c1) : super(priority: 6);

  final int c0;
  final int c1;

  /// Güneşin yükselişi (0 şafak, 1 kuşluk) bu kadar saniye sürer.
  static const double rise = 75;

  /// Gölgenin boyu (kare): şafakta en uzun, kuşlukta en kısa.
  static const double longest = 17;
  static const double shortest = 3;

  double _t = 0;
  bool _started = false;

  /// Önizleme ve testler için: güneşin yükselişi (0-1) elle verilir.
  double? debugRise;

  /// Tanrı heykellerinin batı kenarları (dünya x) ve zemin.
  late final List<double> _statues = () {
    final lv = game.level;
    final out = <double>[];
    for (var r = 0; r < lv.height; r++) {
      for (var c = c0; c <= c1; c++) {
        if (lv.def.map[r].length > c && lv.def.map[r][c] == '?') {
          out.add(c * kTile.toDouble());
        }
      }
    }
    return out;
  }();

  late final double _floor = () {
    final lv = game.level;
    final c = (c0 + 2).clamp(0, lv.width - 1);
    for (var r = 0; r < lv.height; r++) {
      if (lv.solid(c, r)) return r * kTile.toDouble();
    }
    return lv.height * kTile.toDouble();
  }();

  /// Güneşin yükselişi (0-1).
  double get sun {
    final d = debugRise;
    if (d != null) return d;
    final k = (_t / rise).clamp(0.0, 1.0);
    return k * k * (3 - 2 * k);
  }

  /// Gölgenin şu anki boyu (piksel).
  double get shadowLength =>
      (longest + (shortest - longest) * sun) * kTile.toDouble();

  /// x noktası bir tanrının gölgesinde mi (zemin hizasında).
  bool inShadow(double x) {
    if (x < c0 * kTile || x > (c1 + 1) * kTile) return false;
    for (final s in _statues) {
      // Heykelin kendisi ve batısına uzanan gölge.
      if (x <= s + 6 * kTile && x >= s - shadowLength) return true;
    }
    return false;
  }

  /// x noktası şafak alanında ve güneşte mi.
  bool sunlit(double x) =>
      x >= c0 * kTile && x <= (c1 + 1) * kTile && !inShadow(x);

  @override
  void update(double dt) {
    super.update(dt);
    final p = game.player;
    if (!_started && p != null && p.center.x > (c0 + 3) * kTile) {
      _started = true;
    }
    if (_started) _t += dt;
  }

  /// x şafak alanının içinde mi.
  bool covers(double x) => x >= c0 * kTile && x <= (c1 + 1) * kTile;

  @override
  void render(Canvas canvas) {
    final left = c0 * kTile.toDouble();
    final right = (c1 + 1) * kTile.toDouble();
    final top = _floor - 14 * kTile;
    final k = sun;
    // Doğan güneş: alanın doğu ucunda, ufuktan yükselir.
    final sunAt = Offset(right - 2 * kTile, _floor - (2.5 + 8 * k) * kTile);
    canvas.drawCircle(
      sunAt,
      150,
      Paint()
        ..shader = Gradient.radial(sunAt, 150, [
          const Color(0xFFFFD08A).withValues(alpha: 0.55),
          const Color(0xFFFF9A50).withValues(alpha: 0.18),
          const Color(0x00FF9A50),
        ], const [0, 0.35, 1]),
    );
    canvas.drawCircle(
      sunAt,
      22,
      Paint()..color = const Color(0xFFFFE6B0).withValues(alpha: 0.95),
    );
    // Güneş ışığı: doğudan vuran sıcak, alçak ışık.
    canvas.drawRect(
      Rect.fromLTRB(left, top, right, _floor),
      Paint()
        ..shader = Gradient.linear(
          Offset(right, top),
          Offset(left, _floor),
          [
            const Color(0xFFFFC27A).withValues(alpha: 0.14 + 0.08 * k),
            const Color(0xFFFF9A50).withValues(alpha: 0.03),
          ],
        ),
    );
    // Tanrıların gölgeleri: heykelin ardındaki taşa uzanan yumuşak
    // karanlık (güneş alçakken uzun ve yüksek), zeminde seçik kenarlı bant
    // (oyunun kuralı: Kandilciler yalnız burada yürür).
    final len = shadowLength;
    for (final s in _statues) {
      final base = s + 6 * kTile;
      final end = math.max(left, s - len);
      final h = 10 * kTile * (0.55 + 0.45 * k);
      final body = Path()
        ..moveTo(base, _floor)
        ..lineTo(base, _floor - h * 0.85)
        ..quadraticBezierTo(s, _floor - h, s - len * 0.3, _floor - h * 0.7)
        ..lineTo(end, _floor - h * 0.18)
        ..lineTo(end, _floor)
        ..close();
      canvas.drawPath(
        body,
        Paint()
          ..shader = Gradient.linear(
            Offset(base, _floor),
            Offset(end, _floor - h * 0.5),
            [
              const Color(0xFF140A10).withValues(alpha: 0.5),
              const Color(0xFF140A10).withValues(alpha: 0.28),
            ],
          ),
      );
      // Zemindeki gölge bandı ve ucunda güneşin keskin sınırı.
      canvas.drawRect(
        Rect.fromLTRB(end, _floor - 5, base, _floor + 3),
        Paint()..color = const Color(0xFF0C060A).withValues(alpha: 0.8),
      );
      canvas.drawLine(
        Offset(end, _floor - 7),
        Offset(end, _floor + 3),
        Paint()
          ..color = const Color(0xFFFFD08A).withValues(alpha: 0.7)
          ..strokeWidth = 2,
      );
    }
  }
}
