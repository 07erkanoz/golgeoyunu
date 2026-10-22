import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'level.dart';
import 'myth_figures.dart';
import 'persist.dart';

/// Umay ağacı: her kontrol noktasında duran, çaputlu ak kayın
/// (docs/MITOLOJI.md §2). Dokununca uyanır: çaputlar rüzgârla kalkar, taç
/// ışır; Sâye öldüğünde en son uyandırdığı ağacın dibinden kalkar. Uyanmış
/// ağaç kayıtta uyanık kalır.
class UmayTree extends PositionComponent with Persistent {
  UmayTree(
    this.cell, {
    required double headroom,
    this.bloom = false,
    this.small = false,
    this.cairn = false,
    double? groundY,
  }) : scaleK = cairn
           ? 0.9
           : small
           ? math.min(_fit(headroom), 0.75)
           : _fit(headroom),
       super(anchor: Anchor.bottomCenter, priority: 4) {
    position = Vector2(cell.x + kTile / 2, groundY ?? cell.y + kTile);
    size = Vector2(108 * scaleK, 112 * scaleK);
  }

  /// Ağaç yerine oba (taş yığını, direğinde çaputlar): karlı yamaçlarda.
  final bool cairn;

  /// Aynı ekrana düşen ikinci kayıt noktası: aynı ağacın genç, küçük bir
  /// eşi (iki büyük ağaç yan yana dizilmesin). Kayıt noktası olarak aynıdır.
  final bool small;

  /// Ağacın durduğu kontrol noktası hücresi (sol üst köşe).
  final Vector2 cell;

  /// Son ağaç (Konya): uyanınca çiçek açar.
  final bool bloom;

  /// Çizim ölçeği: tavan alçaksa ağaç küçülür (dar sarnıçta fidan gibi).
  final double scaleK;

  // Ağacın boyu (çaputlar ve tacın tepesi) yaklaşık 86 birim.
  static double _fit(double headroom) =>
      ((headroom - 6) / 86).clamp(0.42, 1.2).toDouble();

  bool _awake = false;
  double _lit = 0;
  double _t = 0;

  bool get awake => _awake;

  /// 0: uyuyan, 1: uyanmış (geçiş yumuşak).
  double get lit => _lit;

  /// Işığın merkezi (dünyada): tacın ortası.
  Offset get glowCenter => Offset(position.x, position.y - 48 * scaleK);

  /// Işığın yarıçapı: uyurken yalnız yeri belli olacak kadar.
  double get glowRadius => (50 + 90 * _lit) * scaleK;

  /// Sâye dokundu: ağaç uyanır (zaten uyanıksa bir şey olmaz).
  void wake() {
    if (_awake) return;
    _awake = true;
    GameAudio.instance.play('bell', volume: 0.45);
    GameAudio.instance.play('breath', volume: 0.35);
  }

  @override
  String get persistKind => 'umay';

  @override
  Object? captureState() => _awake ? 1 : null;

  /// Ağaç hiçbir zaman dünyadan kalkmaz (eski kayıtlarda kaydı olmasa da).
  @override
  Iterable<Component> restoreState(Object? state, {required bool present}) {
    if (state == 1) {
      _awake = true;
      _lit = 1;
    }
    return [this];
  }

  @override
  void update(double dt) {
    _t += dt;
    final target = _awake ? 1.0 : 0.0;
    if (_lit != target) {
      final step = dt / 1.4;
      _lit = _lit < target
          ? math.min(target, _lit + step)
          : math.max(target, _lit - step);
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    // Kökler toprağın içinde kalır: zeminin altı çizilmez.
    canvas.clipRect(Rect.fromLTWH(-size.x, -size.y, size.x * 3, size.y * 2));
    canvas.translate(size.x / 2, size.y);
    canvas.scale(scaleK);
    // Uyanırken ışık önce yükselir, ardından çaputlar kalkar.
    if (cairn) {
      _drawCairn(canvas, _t, _ease(_lit));
    } else {
      MythFigures.umayTree(canvas, _t, lit: _ease(_lit), bloom: bloom);
    }
    canvas.restore();
  }

  /// Oba: üst üste yığılmış taşlar (üstleri karlı), ortasında ince bir
  /// direk, direğe bağlı ak, gök, kızıl ve sarı çaputlar. Uyanınca çaputlar
  /// rüzgârla kalkar, taşların arası ışır.
  static void _drawCairn(Canvas c, double t, double lit) {
    final stone = Paint()..color = const Color(0xFF2E2C3A);
    final edge = Paint()..color = const Color(0xFF4A4858);
    final snow = Paint()..color = const Color(0xFFE6ECF6);
    // Işık: taşların dibinden yukarı.
    if (lit > 0) {
      c.drawCircle(
        const Offset(0, -30),
        60,
        Paint()
          ..shader = Gradient.radial(const Offset(0, -30), 60, [
            const Color(0xFFFFE2A8).withValues(alpha: 0.45 * lit),
            const Color(0x00FFE2A8),
          ]),
      );
    }
    // Taşlar: aşağıdan yukarı küçülür.
    for (final (x, y, w, h) in const [
      (-14.0, -6.0, 20.0, 12.0),
      (6.0, -6.0, 22.0, 13.0),
      (-4.0, -15.0, 22.0, 12.0),
      (-12.0, -24.0, 14.0, 10.0),
      (5.0, -24.0, 13.0, 10.0),
      (-3.0, -32.0, 14.0, 9.0),
    ]) {
      final r = Rect.fromCenter(center: Offset(x, y), width: w, height: h);
      c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(h * 0.45)), stone);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(r.left + 2, r.top + 1, r.width - 5, 3),
          const Radius.circular(2),
        ),
        edge,
      );
      // Taşın üstünde kar.
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(r.left + 1, r.top - 1.5, r.width - 2, 3.5),
          const Radius.circular(2),
        ),
        snow,
      );
    }
    // Direk.
    c.drawLine(
      const Offset(0, -34),
      const Offset(1, -78),
      Paint()
        ..color = const Color(0xFF3A2A20)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    // Çaputlar: rüzgârda dalgalanır; uyanınca yukarı kalkar ve parlar.
    const colors = [
      Color(0xFFF2F2F0),
      Color(0xFF5C8AD8),
      Color(0xFFC84838),
      Color(0xFFE8B840),
    ];
    for (var i = 0; i < 4; i++) {
      final ky = -74.0 + i * 7;
      final lift = -0.25 - 0.55 * lit;
      final path = Path()..moveTo(1, ky);
      final len = 22.0 + i * 2;
      for (var s = 1; s <= 6; s++) {
        final u = s / 6;
        final wave = math.sin(t * 5 + i * 1.3 - u * 4) * 3 * u;
        path.lineTo(1 + len * u, ky + len * u * (0.55 + lift) + wave);
      }
      for (var s = 6; s >= 0; s--) {
        final u = s / 6;
        final wave = math.sin(t * 5 + i * 1.3 - u * 4) * 3 * u;
        path.lineTo(1 + len * u, ky + 3.2 + len * u * (0.55 + lift) + wave);
      }
      path.close();
      c.drawPath(
        path,
        Paint()
          ..color = Color.lerp(colors[i], const Color(0xFFFFF4D8), 0.3 * lit)!,
      );
    }
  }

  static double _ease(double x) => x * x * (3 - 2 * x);
}
