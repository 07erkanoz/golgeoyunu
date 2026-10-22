import 'dart:math' as math;
import 'dart:ui';

import 'fairy_chimney_shapes.dart';

/// Bir peri bacası öbeğinin renkleri: tüf gövde, gölge yanı, şapka taşı.
class ChimneyTones {
  const ChimneyTones(this.body, this.shade, this.cap);

  final Color body;

  /// Gövdenin güneşe ters (sağ) yanı.
  final Color shade;
  final Color cap;
}

/// Siluetin bir bacası: gövde ve şapka birlikte, pencereleri ayrı; boyu 1,
/// tabanın ortası (0, 0).
class _Piece {
  _Piece(this.shape, this.cap, this.windows, this.width);

  final Path shape;
  final Path cap;
  final List<Path> windows;
  final double width;
}

Path _decode(List<double> d) {
  final p = Path();
  var i = 0;
  while (i < d.length) {
    switch (d[i].toInt()) {
      case 0:
        p.moveTo(d[i + 1], d[i + 2]);
        i += 3;
      case 1:
        p.lineTo(d[i + 1], d[i + 2]);
        i += 3;
      case 2:
        p.cubicTo(d[i + 1], d[i + 2], d[i + 3], d[i + 4], d[i + 5], d[i + 6]);
        i += 7;
      default:
        p.close();
        i += 1;
    }
  }
  return p;
}

/// [0..2]: soldaki, ortadaki, sağdaki baca; [3]: üçü birden.
final List<_Piece> _pieces = () {
  final bodies = [for (final d in fairyArtBodies) _decode(d)];
  final caps = [for (final d in fairyArtCaps) _decode(d)];
  final windows = [for (final d in fairyArtWindows) _decode(d)];
  // Pencere, ortası hangi gövdenin içindeyse onundur.
  final mine = [for (var i = 0; i < 3; i++) <Path>[]];
  for (final w in windows) {
    final c = w.getBounds().center;
    final i = [
      2,
      1,
      0,
    ].firstWhere((i) => bodies[i].contains(c), orElse: () => 1);
    mine[i].add(w);
  }
  _Piece piece(List<int> which) {
    var bounds = Rect.zero;
    for (final i in which) {
      final b = bodies[i].getBounds().expandToInclude(caps[i].getBounds());
      bounds = bounds == Rect.zero ? b : bounds.expandToInclude(b);
    }
    final shift = Offset(-bounds.center.dx, -bounds.bottom);
    final shape = Path();
    final cap = Path();
    final win = <Path>[];
    for (final i in which) {
      shape.addPath(bodies[i], shift);
      cap.addPath(caps[i], shift);
      win.addAll(mine[i].map((w) => w.shift(shift)));
    }
    return _Piece(shape, cap, win, bounds.width / bounds.height);
  }

  return [
    piece([0]),
    piece([1]),
    piece([2]),
    piece([0, 1, 2]),
  ];
}();

/// Kapadokya peri bacaları, gölge oyunu silueti olarak (Nevit Dilmen'in
/// çiziminden, bkz. fairy_chimney_shapes.dart): yukarı doğru köşeli
/// incelen tüf konileri, tepelerinde eğik duran ağızlı şapka taşı,
/// gövdelerde kandille aydınlanan oyma pencereler. [peaks] 3 ise
/// üçlü öbek, değilse o kadar tek baca yan yana.
///
/// [base]: tabanın ortası; [height]: en uzun bacanın boyu.
void drawFairyCluster(
  Canvas c,
  Offset base,
  double height,
  ChimneyTones tones,
  math.Random rnd, {
  int peaks = 3,
  double openings = 0.5,
  Color? lit,
  double blur = 0,
}) {
  final parts = <(_Piece, double, double)>[]; // (parça, x kayması, boy)
  if (peaks >= 3) {
    parts.add((_pieces[3], 0, height));
  } else {
    var x = 0.0;
    for (var k = 0; k < peaks; k++) {
      final p = _pieces[rnd.nextInt(3)];
      final h = height * (k == 0 ? 1 : 0.65 + rnd.nextDouble() * 0.25);
      if (k > 0) x += height * p.width * 0.45;
      parts.add((p, x, h));
    }
  }
  final mid = parts.length > 1 ? parts.last.$2 / 2 : 0.0;
  // Uzun olan arkada kalsın.
  parts.sort((a, b) => b.$3.compareTo(a.$3));
  for (final (p, dx, h) in parts) {
    final flip = rnd.nextBool();
    final stretch = 0.85 + rnd.nextDouble() * 0.3;
    c.save();
    c.translate(base.dx + dx - mid, base.dy);
    c.scale(h * stretch * (flip ? -1 : 1), h);
    final mask = blur > 0 ? MaskFilter.blur(BlurStyle.normal, blur / h) : null;
    // Gövde: güneşe bakan yan açık, öbür yan gölgeli.
    final half = p.width / 2;
    c.drawPath(
      p.shape,
      Paint()
        ..maskFilter = mask
        ..shader = Gradient.linear(
          Offset(flip ? half : -half, 0),
          Offset(flip ? -half : half, 0),
          [tones.body, tones.body, tones.shade],
          const [0, 0.45, 1],
        ),
    );
    c.drawPath(
      p.cap,
      Paint()
        ..color = tones.cap
        ..maskFilter = mask,
    );
    // Pencereler: asıl çizimdeki gibi aydınlık oyuklar (kandil ışığı).
    if (openings > 0 && lit != null) {
      final glow = Paint()
        ..color = lit
        ..maskFilter = mask;
      for (final w in p.windows) {
        if (rnd.nextDouble() < openings) c.drawPath(w, glow);
      }
    }
    c.restore();
  }
}
