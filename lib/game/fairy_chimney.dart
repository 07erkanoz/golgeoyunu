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

  late final Rect bounds = shape.getBounds();

  /// Doku: gövdenin güneşe bakan kenarı (sol ya da aynalıysa sağ) ve
  /// şapka taşının üst/yan kenarı, ince birer hilal.
  late final Path rimL = Path.combine(
    PathOperation.difference,
    shape,
    shape.shift(const Offset(0.008, 0.004)),
  );
  late final Path rimR = Path.combine(
    PathOperation.difference,
    shape,
    shape.shift(const Offset(-0.008, 0.004)),
  );
  late final Path capRimL = Path.combine(
    PathOperation.difference,
    cap,
    cap.shift(const Offset(0.006, 0.008)),
  );
  late final Path capRimR = Path.combine(
    PathOperation.difference,
    cap,
    cap.shift(const Offset(-0.006, 0.008)),
  );
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
  bool doku = false,
  Color sun = const Color(0xFFFFC890),
  double rimAlpha = 0.5,
}) {
  final seed = doku ? rnd.nextInt(1 << 30) : 0;
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
    if (doku) {
      // Kâğıt oyma gölgesi: siluet sağ alta düşer.
      c.save();
      c.translate(3 / (h * stretch) * (flip ? -1 : 1), 4 / h);
      c.drawPath(p.shape, _drop);
      c.drawPath(p.cap, _drop);
      c.restore();
    }
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
    if (doku) _tuff(c, p, h, stretch, flip, tones, sun, rimAlpha, seed);
    c.drawPath(
      p.cap,
      Paint()
        ..color = tones.cap
        ..maskFilter = mask,
    );
    if (doku) {
      c.drawPath(
        flip ? p.capRimR : p.capRimL,
        Paint()..color = sun.withValues(alpha: rimAlpha * 0.8),
      );
    }
    // Pencereler: asıl çizimdeki gibi aydınlık oyuklar (kandil ışığı).
    if (openings > 0 && lit != null) {
      final glow = Paint()
        ..color = lit
        ..maskFilter = mask;
      for (final w in p.windows) {
        final on = rnd.nextDouble() < openings;
        if (doku) {
          _niche(c, w.getBounds(), stretch, on ? lit : null, tones, sun);
        } else if (on) {
          c.drawPath(w, glow);
        }
      }
    }
    c.restore();
  }
}

final _drop = Paint()..color = const Color(0x4D000000);

/// Doku: tüf gövdenin kat kat çökelti bantları, aşınma oyukları, dibe
/// doğru koyulaşan gölge, şapkanın gövdeye düşen gölgesi ve güneşe bakan
/// kenarda ışık. Birimler bacanın boyuna göre (1 = boy).
void _tuff(
  Canvas c,
  _Piece p,
  double h,
  double stretch,
  bool flip,
  ChimneyTones tones,
  Color sun,
  double rimAlpha,
  int seed,
) {
  final b = p.bounds;
  final px = 1 / h;
  final r = math.Random(seed ^ (b.width * 1000).round());
  c.save();
  c.clipPath(p.shape);
  // Şapka taşının gölgesi.
  c.save();
  c.translate(0.01 * (flip ? -1 : 1), 0.03);
  c.drawPath(p.cap, Paint()..color = const Color(0x66000000));
  c.restore();
  // Tüfün yumuşak renk kuşakları: geniş, kenarları dalgalı, belli belirsiz;
  // çizgi yok (çizgi tahta gibi gösteriyordu).
  final zone = Paint()
    ..color = Color.lerp(
      tones.body,
      sun,
      0.12,
    )!.withValues(alpha: (0.1 + 0.4 * (rimAlpha - 0.25)).clamp(0.08, 0.22));
  final dim = Paint()
    ..color = tones.shade.withValues(
      alpha: (0.12 + 0.4 * (rimAlpha - 0.25)).clamp(0.1, 0.25),
    );
  const gap = 0.16;
  var k = 0;
  for (var yy = b.bottom - gap * 0.4; yy > b.top + 0.05; yy -= gap, k++) {
    final ph = r.nextDouble() * 6;
    double edge(double x, double o) =>
        yy + o + math.sin(x * 7 + ph + o * 20) * 0.018;
    final zp = Path()..moveTo(b.left, edge(b.left, 0));
    for (var x = b.left; x <= b.right; x += 0.02) {
      zp.lineTo(x, edge(x, 0));
    }
    final th = gap * (0.35 + r.nextDouble() * 0.2);
    for (var x = b.right; x >= b.left; x -= 0.02) {
      zp.lineTo(x, edge(x, -th));
    }
    zp.close();
    c.drawPath(zp, k.isEven ? zone : dim);
  }
  // Ufak oyuklar.
  final pock = Paint()..color = tones.shade.withValues(alpha: 0.5);
  for (var i = 0; i < 10; i++) {
    final x = b.left + b.width * r.nextDouble();
    final y = b.top + b.height * (0.2 + r.nextDouble() * 0.75);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(x, y),
        width: (2 + r.nextDouble() * 2) / (h * stretch),
        height: (1.5 + r.nextDouble() * 1.5) * px,
      ),
      pock,
    );
  }
  // Dibe doğru koyulaşır (tepeye bağlanır).
  c.drawRect(
    Rect.fromLTRB(b.left, b.bottom - 0.22, b.right, b.bottom + 0.01),
    Paint()
      ..shader = Gradient.linear(
        Offset(0, b.bottom - 0.22),
        Offset(0, b.bottom),
        [const Color(0x00000000), tones.shade.withValues(alpha: 0.7)],
      ),
  );
  c.restore();
  // Güneşe bakan kenarda ışık.
  c.drawPath(
    flip ? p.rimR : p.rimL,
    Paint()..color = sun.withValues(alpha: rimAlpha),
  );
}

/// Kayaya oyulmuş kemerli pencere: kandil yanıyorsa sıcak ışık, yoksa
/// karanlık oyuk; alt dudağı ışık alır.
void _niche(
  Canvas c,
  Rect wb,
  double stretch,
  Color? lit,
  ChimneyTones tones,
  Color sun,
) {
  final ww = wb.shortestSide * 0.55;
  final hh = ww * 1.45 * stretch;
  final rect = Rect.fromCenter(center: wb.center, width: ww, height: hh);
  final arch = RRect.fromRectAndCorners(
    rect,
    topLeft: Radius.elliptical(ww / 2, ww / 2 * stretch),
    topRight: Radius.elliptical(ww / 2, ww / 2 * stretch),
  );
  if (lit != null) {
    c.drawOval(
      rect.inflate(ww * 0.6),
      Paint()..color = lit.withValues(alpha: lit.a * 0.12),
    );
    c.drawRRect(arch, Paint()..color = lit.withValues(alpha: lit.a * 0.8));
  } else {
    c.drawRRect(
      arch,
      Paint()..color = Color.lerp(tones.cap, const Color(0xFF000000), 0.45)!,
    );
  }
  c.drawRect(
    Rect.fromLTWH(rect.left - ww * 0.1, rect.bottom, ww * 1.2, hh * 0.12),
    Paint()..color = sun.withValues(alpha: 0.28),
  );
}
