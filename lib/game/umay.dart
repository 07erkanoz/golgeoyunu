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
  }) : scaleK = small ? math.min(_fit(headroom), 0.75) : _fit(headroom),
       super(anchor: Anchor.bottomCenter, priority: 4) {
    position = Vector2(cell.x + kTile / 2, cell.y + kTile);
    size = Vector2(108 * scaleK, 112 * scaleK);
  }

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
    MythFigures.umayTree(canvas, _t, lit: _ease(_lit), bloom: bloom);
    canvas.restore();
  }

  static double _ease(double x) => x * x * (3 - 2 * x);
}
