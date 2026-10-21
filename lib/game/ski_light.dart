import 'dart:math' as math;
import 'dart:ui';

/// Kayak yamacında günün ışığı: pistte ilerledikçe gök değişir (Palandöken
/// gün batımında başlar, geceden geçer, şafakta biter; Çığ fırtınalı bir
/// alacakaranlıkta). Kar, gökyüzünün rengini yansıtır.
class SkiLight {
  const SkiLight({
    required this.skyTop,
    required this.skyMid,
    required this.skyLow,
    required this.snowLit,
    required this.snowShade,
    required this.deep,
    required this.sun,
    required this.ridge,
    required this.night,
  });

  final Color skyTop;
  final Color skyMid;
  final Color skyLow;

  /// Işık alan karın rengi (yamacın üst kenarı).
  final Color snowLit;

  /// Gölgedeki kar (yamacın içine doğru).
  final Color snowShade;

  /// Karın altındaki derinlik.
  final Color deep;

  /// Güneşin ya da ayın ışığı (parıltılar, kenar ışığı).
  final Color sun;

  /// Uzak dağların rengi.
  final Color ridge;

  /// 0 gündüz, 1 gece: yıldızlar, ay, şehir ışıkları.
  final double night;

  static SkiLight lerp(SkiLight a, SkiLight b, double t) => SkiLight(
    skyTop: Color.lerp(a.skyTop, b.skyTop, t)!,
    skyMid: Color.lerp(a.skyMid, b.skyMid, t)!,
    skyLow: Color.lerp(a.skyLow, b.skyLow, t)!,
    snowLit: Color.lerp(a.snowLit, b.snowLit, t)!,
    snowShade: Color.lerp(a.snowShade, b.snowShade, t)!,
    deep: Color.lerp(a.deep, b.deep, t)!,
    sun: Color.lerp(a.sun, b.sun, t)!,
    ridge: Color.lerp(a.ridge, b.ridge, t)!,
    night: a.night + (b.night - a.night) * t,
  );

  /// Palandöken: gün batımı → alacakaranlık → gece → şafak → sabah.
  static const _palandoken = <(double, SkiLight)>[
    (
      0.0,
      SkiLight(
        skyTop: Color(0xFF2C3264),
        skyMid: Color(0xFFB0587A),
        skyLow: Color(0xFFF4AE62),
        snowLit: Color(0xFFFFE4CC),
        snowShade: Color(0xFF9A88B8),
        deep: Color(0xFF3A2E50),
        sun: Color(0xFFFFC27A),
        ridge: Color(0xFF6A4E7A),
        night: 0,
      ),
    ),
    (
      0.24,
      SkiLight(
        skyTop: Color(0xFF151A3E),
        skyMid: Color(0xFF4E3A72),
        skyLow: Color(0xFFC46E74),
        snowLit: Color(0xFFD8CCE6),
        snowShade: Color(0xFF5E6094),
        deep: Color(0xFF232448),
        sun: Color(0xFFFF9A7A),
        ridge: Color(0xFF3E3462),
        night: 0.45,
      ),
    ),
    (
      0.48,
      SkiLight(
        skyTop: Color(0xFF040918),
        skyMid: Color(0xFF0C1832),
        skyLow: Color(0xFF233A62),
        snowLit: Color(0xFFB8CCEE),
        snowShade: Color(0xFF3C4E7C),
        deep: Color(0xFF141C36),
        sun: Color(0xFFCFE0FF),
        ridge: Color(0xFF1C2A4A),
        night: 1,
      ),
    ),
    (
      0.72,
      SkiLight(
        skyTop: Color(0xFF14204A),
        skyMid: Color(0xFF6A5C98),
        skyLow: Color(0xFFF2A2A0),
        snowLit: Color(0xFFFFDCE4),
        snowShade: Color(0xFF7C80B8),
        deep: Color(0xFF2C2C56),
        sun: Color(0xFFFFB8A0),
        ridge: Color(0xFF4E4A82),
        night: 0.4,
      ),
    ),
    (
      1.0,
      SkiLight(
        skyTop: Color(0xFF4E86C6),
        skyMid: Color(0xFF9CC6EA),
        skyLow: Color(0xFFF6E4C6),
        snowLit: Color(0xFFFFFFFF),
        snowShade: Color(0xFF9CB6DA),
        deep: Color(0xFF48607E),
        sun: Color(0xFFFFF0C8),
        ridge: Color(0xFF7896BC),
        night: 0,
      ),
    ),
  ];

  /// Çığ: fırtınalı, soğuk bir alacakaranlık; sonunda bulutlar aralanır.
  static const _cig = <(double, SkiLight)>[
    (
      0.0,
      SkiLight(
        skyTop: Color(0xFF2A3448),
        skyMid: Color(0xFF66728C),
        skyLow: Color(0xFFB4BCCC),
        snowLit: Color(0xFFF2F6FC),
        snowShade: Color(0xFF8E9AB2),
        deep: Color(0xFF38425A),
        sun: Color(0xFFE6EEF8),
        ridge: Color(0xFF5A6680),
        night: 0.1,
      ),
    ),
    (
      0.7,
      SkiLight(
        skyTop: Color(0xFF1E2638),
        skyMid: Color(0xFF4C5670),
        skyLow: Color(0xFF8E98B0),
        snowLit: Color(0xFFDDE4F0),
        snowShade: Color(0xFF6E7A94),
        deep: Color(0xFF283044),
        sun: Color(0xFFC8D6EA),
        ridge: Color(0xFF424C66),
        night: 0.3,
      ),
    ),
    (
      1.0,
      SkiLight(
        skyTop: Color(0xFF34466E),
        skyMid: Color(0xFF8C8AAE),
        skyLow: Color(0xFFF0C4A4),
        snowLit: Color(0xFFFFEEE2),
        snowShade: Color(0xFF8C94B8),
        deep: Color(0xFF34385A),
        sun: Color(0xFFFFD0A8),
        ridge: Color(0xFF5A5A82),
        night: 0.1,
      ),
    ),
  ];

  /// Pistte [progress] (0 baş, 1 son) için ışık.
  static SkiLight at(double progress, {required bool avalanche}) {
    final keys = avalanche ? _cig : _palandoken;
    final p = progress.clamp(0.0, 1.0);
    for (var i = 0; i < keys.length - 1; i++) {
      final (a, la) = keys[i];
      final (b, lb) = keys[i + 1];
      if (p <= b) {
        final t = (p - a) / (b - a);
        return lerp(la, lb, t * t * (3 - 2 * t));
      }
    }
    return keys.last.$2;
  }

  /// Güneşin gökteki yeri (ekran oranı; y > 1 ufkun altı). Palandöken'de
  /// başta batar, sonda doğar.
  static Offset sunAt(double progress) {
    final p = progress.clamp(0.0, 1.0);
    if (p < 0.5) {
      // Batış: 0.62 → 1.15 (ufkun altına).
      final k = p / 0.3;
      return Offset(0.78 - 0.1 * k, 0.6 + 0.55 * math.min(1, k));
    }
    // Doğuş: 0.7'de ufukta, sonda yüksekte.
    final k = ((p - 0.66) / 0.34).clamp(0.0, 1.0);
    return Offset(0.25 + 0.15 * k, 1.12 - 0.82 * k);
  }

  /// Ayın yeri: gecenin ortasında en yüksekte.
  static Offset moonAt(double progress) {
    final k = ((progress - 0.2) / 0.62).clamp(0.0, 1.0);
    return Offset(0.85 - 0.6 * k, 0.75 - math.sin(k * math.pi) * 0.6);
  }
}
