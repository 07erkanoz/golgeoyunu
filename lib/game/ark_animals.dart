import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';

/// Nuh'un Gemisi'nin hayvanları: yumuşak eğrili, gerçek oranlı siluetler.
/// Ayaklar 0'da, sağa bakar. Oyma heykeller ve duvara düşen gölgeler aynı
/// biçimleri kullanır.
class ArkAnimal {
  ArkAnimal({
    required this.body,
    required this.farLegs,
    this.overlay,
    this.strokes = const [],
    required this.eye,
  });

  /// Gövde, baş ve yakın bacaklar.
  final Path body;

  /// Arkada kalan bacaklar (bir ton koyu).
  final Path farLegs;

  /// Yele, kulak gibi gövdenin üstünde ayrı oyulan parça.
  final Path? overlay;

  /// Kuyruk, boynuz gibi çizgiyle çizilen parçalar: (yol, kalınlık).
  final List<(Path, double)> strokes;

  final Offset eye;

  /// Bütün biçim (gölge için).
  late final Path silhouette = () {
    var p = Path.combine(PathOperation.union, body, farLegs);
    if (overlay != null) p = Path.combine(PathOperation.union, p, overlay!);
    return p;
  }();

  static final Map<String, ArkAnimal> _cache = {};

  static ArkAnimal of(String kind) => _cache[kind] ??= _build(kind);

  static const kinds = [
    'lion',
    'elephant',
    'giraffe',
    'deer',
    'horse',
    'camel',
  ];
}

/// Kapalı Catmull-Rom eğrisi: noktalardan yumuşak bir dış hat.
Path _smooth(List<Offset> p) {
  final n = p.length;
  final path = Path()..moveTo(p[0].dx, p[0].dy);
  for (var i = 0; i < n; i++) {
    final p0 = p[(i - 1 + n) % n];
    final p1 = p[i];
    final p2 = p[(i + 1) % n];
    final p3 = p[(i + 2) % n];
    final c1 = p1 + (p2 - p0) / 6;
    final c2 = p2 - (p3 - p1) / 6;
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return path..close();
}

/// Açık eğri (kuyruk, boynuz).
Path _curve(List<Offset> p) {
  final path = Path()..moveTo(p[0].dx, p[0].dy);
  for (var i = 0; i < p.length - 1; i++) {
    final p0 = p[math.max(0, i - 1)];
    final p1 = p[i];
    final p2 = p[i + 1];
    final p3 = p[math.min(p.length - 1, i + 2)];
    final c1 = p1 + (p2 - p0) / 6;
    final c2 = p2 - (p3 - p1) / 6;
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return path;
}

List<Offset> _o(List<double> v) => [
  for (var i = 0; i < v.length; i += 2) Offset(v[i], v[i + 1]),
];

Path _join(List<Path> ps) {
  var out = ps.first;
  for (final p in ps.skip(1)) {
    out = Path.combine(PathOperation.union, out, p);
  }
  return out;
}

/// Aslanın gür yelesi: başın arkasından ve altından dalgalı, sivri
/// tutamlarla; yüz önde açık kalır.
Path _mane() {
  const cx = 28.0;
  const cy = -37.0;
  final pts = <Offset>[];
  const n = 14;
  for (var i = 0; i <= n; i++) {
    final th = (60 + i * 240 / n) * math.pi / 180;
    final r = i.isEven ? 1.0 : 0.88;
    pts.add(Offset(cx + 21 * r * math.cos(th), cy + 19 * r * math.sin(th)));
  }
  for (var i = 6; i >= 0; i--) {
    final th = (-60 + i * 120 / 6) * math.pi / 180;
    pts.add(Offset(cx + 9 + 8 * math.cos(th), cy + 11 * math.sin(th)));
  }
  return _smooth(pts);
}

ArkAnimal _build(String kind) {
  switch (kind) {
    case 'lion':
      return ArkAnimal(
        body: _smooth(
          _o([
            -34, -35, -22, -39, -6, -38, 8, -38, 14, -40, //
            17, -45, 24, -51, 32, -51, 38, -47, 41, -45, //
            45, -41, 49, -36, 50, -33, 48, -30, 44, -28, //
            40, -26, 34, -22, 32, -16, 31, -6, 33, -2, //
            35, -0.6, 25, -0.4, 24, -4, 24, -12, 22, -20, //
            12, -22, 0, -21, -12, -22, -16, -22, -17, -12, //
            -14, -3, -12, -0.6, -22, -0.4, -24, -5, -26, -12, //
            -32, -18, -36, -26,
          ]),
        ),
        farLegs: _join([
          _smooth(
            _o([
              18,
              -20,
              19,
              -6,
              21,
              -1.5,
              22,
              -0.4,
              12,
              -0.4,
              12,
              -5,
              13,
              -18,
            ]),
          ),
          _smooth(
            _o([
              -4,
              -22,
              -5,
              -10,
              -2,
              -2,
              -1,
              -0.4,
              -10,
              -0.4,
              -12,
              -6,
              -13,
              -18,
            ]),
          ),
        ]),
        overlay: _mane(),
        strokes: [
          (_curve(_o([-34, -33, -42, -30, -47, -20, -47, -12])), 2.6),
          (
            Path()..addOval(
              Rect.fromCenter(
                center: const Offset(-47, -11),
                width: 6,
                height: 8,
              ),
            ),
            0,
          ),
        ],
        eye: const Offset(43, -39),
      );
    case 'elephant':
      return ArkAnimal(
        body: _smooth(
          _o([
            -34, -30, -32, -44, -22, -54, -6, -58, 10, -57, //
            22, -54, 30, -56, 38, -54, 44, -48, 47, -40, //
            48, -28, 48, -16, 49, -8, 52, -4, 51, -1, //
            46, -2, 44, -8, 43, -20, 41, -30, 37, -32, //
            33, -30, 30, -24, 30, -14, 31, -2, 32, -0.4, //
            21, -0.4, 21, -10, 20, -18, 10, -20, -4, -19, //
            -14, -20, -16, -18, -16, -4, -15, -0.4, -27, -0.4, //
            -28, -6, -30, -16, -33, -22,
          ]),
        ),
        farLegs: _join([
          _smooth(_o([14, -20, 15, -2, 16, -0.4, 6, -0.4, 6, -10, 5, -18])),
          _smooth(
            _o([-4, -20, -4, -2, -3, -0.4, -13, -0.4, -13, -10, -12, -19]),
          ),
        ]),
        overlay: _smooth(
          _o([21, -52, 30, -53, 35, -46, 34, -34, 28, -27, 21, -29, 18, -40]),
        ),
        strokes: [
          (_curve(_o([-33, -38, -38, -30, -38, -20])), 1.8),
          (_curve(_o([36, -31, 42, -27, 47, -30])), 3),
        ],
        eye: const Offset(39, -46),
      );
    case 'giraffe':
      return ArkAnimal(
        body: _smooth(
          _o([
            -24, -60, -14, -63, 0, -66, 12, -69, 18, -76, //
            24, -88, 29, -98, 31, -102, 36, -104, 42, -102, //
            50, -96, 53, -92, 51, -89, 44, -89, 38, -92, //
            33, -88, 28, -78, 25, -66, 24, -58, 22, -52, //
            22, -44, 23, -26, 24, -6, 25, -1.5, 26, -0.4, //
            19.5, -0.4, 19, -6, 18, -26, 17, -46, 10, -50, //
            -4, -50, -12, -52, -14, -50, -13, -30, -12, -8, //
            -11, -1.5, -10, -0.4, -16, -0.4, -17, -8, -19, -26, //
            -22, -38, -25, -48,
          ]),
        ),
        farLegs: _join([
          _smooth(
            _o([
              12,
              -48,
              13,
              -26,
              14,
              -6,
              15,
              -0.4,
              9,
              -0.4,
              9,
              -6,
              8,
              -26,
              8,
              -46,
            ]),
          ),
          _smooth(
            _o([
              -4,
              -50,
              -4,
              -30,
              -2,
              -8,
              -1,
              -0.4,
              -7,
              -0.4,
              -8,
              -8,
              -9,
              -30,
              -10,
              -48,
            ]),
          ),
        ]),
        strokes: [
          (_curve(_o([34, -103, 33, -110])), 2),
          (_curve(_o([38, -103, 38, -110])), 2),
          (
            Path()
              ..addOval(
                Rect.fromCircle(center: const Offset(33, -110.5), radius: 1.8),
              )
              ..addOval(
                Rect.fromCircle(center: const Offset(38, -110.5), radius: 1.8),
              ),
            0,
          ),
          (_curve(_o([32, -100, 27, -102])), 2.2),
          (_curve(_o([-24, -58, -28, -46, -29, -34])), 1.4),
        ],
        eye: const Offset(43, -98),
      );
    case 'deer':
      final antler = _curve(_o([24, -61, 22, -70, 18, -80, 14, -86]));
      return ArkAnimal(
        body: _smooth(
          _o([
            -20, -38, -8, -40, 6, -40, 12, -42, 16, -48, //
            20, -56, 22, -60, 27, -62, 32, -58, 34, -55, //
            31, -53, 26, -53, 22, -52, 20, -46, 18, -38, //
            17, -30, 18, -14, 19, -2, 20, -0.4, 15.5, -0.4, //
            15, -2, 14, -14, 13, -28, 6, -30, -6, -30, //
            -10, -30, -10, -20, -12, -12, -10, -2, -9, -0.4, //
            -13.5, -0.4, -14, -2, -16, -12, -17, -20, -20, -28, //
            -22, -34,
          ]),
        ),
        farLegs: _join([
          _smooth(
            _o([
              8,
              -30,
              9,
              -14,
              10,
              -2,
              11,
              -0.4,
              6.5,
              -0.4,
              6,
              -2,
              5,
              -14,
              4,
              -28,
            ]),
          ),
          _smooth(
            _o([
              -3,
              -30,
              -3,
              -20,
              -5,
              -12,
              -3,
              -2,
              -2,
              -0.4,
              -6.5,
              -0.4,
              -7,
              -2,
              -9,
              -12,
              -9,
              -22,
            ]),
          ),
        ]),
        strokes: [
          (antler, 2),
          (_curve(_o([21, -74, 26, -80])), 1.6),
          (_curve(_o([18, -80, 22, -88])), 1.6),
          (_curve(_o([15, -84, 9, -88])), 1.4),
          (antler.shift(const Offset(-4, 1)), 1.6),
          (_curve(_o([23, -62, 18, -66])), 2.4),
          (_curve(_o([-20, -37, -23, -33])), 2.4),
        ],
        eye: const Offset(28, -58),
      );
    case 'horse':
      return ArkAnimal(
        body: _smooth(
          _o([
            -30, -40, -18, -44, 0, -44, 12, -46, 18, -50, //
            24, -58, 30, -66, 34, -70, 38, -69, 44, -64, //
            50, -56, 51, -52, 47, -50, 41, -53, 35, -55, //
            28, -48, 26, -40, 25, -32, 26, -12, 27, -2, //
            29, -0.4, 22.5, -0.4, 22, -4, 21, -14, 19, -32, //
            8, -34, -8, -34, -14, -34, -14, -24, -16, -14, //
            -13, -2, -11, -0.4, -17, -0.4, -19, -4, -21, -14, //
            -22, -24, -28, -30, -32, -36,
          ]),
        ),
        farLegs: _join([
          _smooth(
            _o([
              12,
              -32,
              13,
              -12,
              14,
              -2,
              16,
              -0.4,
              9.5,
              -0.4,
              9,
              -4,
              8,
              -14,
              7,
              -30,
            ]),
          ),
          _smooth(
            _o([
              -4,
              -34,
              -4,
              -24,
              -6,
              -14,
              -3,
              -2,
              -1,
              -0.4,
              -7,
              -0.4,
              -9,
              -4,
              -11,
              -14,
              -10,
              -26,
            ]),
          ),
        ]),
        overlay: _smooth(_o([18, -52, 26, -64, 33, -72, 30, -62, 24, -52])),
        strokes: [
          (_curve(_o([-30, -40, -40, -34, -43, -22, -41, -12])), 3.2),
          (_curve(_o([35, -69, 34, -75])), 2),
        ],
        eye: const Offset(41, -62),
      );
    default: // deve
      return ArkAnimal(
        body: _smooth(
          _o([
            -30, -40, -24, -50, -14, -58, -6, -62, 4, -58, //
            12, -50, 18, -48, 24, -46, 30, -44, 36, -48, //
            40, -56, 44, -60, 50, -60, 54, -56, 53, -52, //
            46, -52, 41, -46, 38, -38, 28, -34, 24, -30, //
            25, -14, 26, -2, 28, -0.4, 21.5, -0.4, 20, -4, //
            19, -14, 18, -28, 8, -32, -8, -32, -14, -32, //
            -15, -20, -14, -2, -12, -0.4, -19, -0.4, -20, -4, //
            -22, -20, -26, -30, -31, -36,
          ]),
        ),
        farLegs: _join([
          _smooth(
            _o([
              12,
              -30,
              13,
              -14,
              14,
              -2,
              16,
              -0.4,
              9.5,
              -0.4,
              8,
              -4,
              7,
              -14,
              6,
              -28,
            ]),
          ),
          _smooth(
            _o([
              -4,
              -32,
              -5,
              -20,
              -4,
              -2,
              -2,
              -0.4,
              -9,
              -0.4,
              -10,
              -4,
              -11,
              -20,
              -10,
              -30,
            ]),
          ),
        ]),
        strokes: [
          (_curve(_o([-30, -38, -34, -30, -34, -22])), 1.6),
          (_curve(_o([46, -60, 45, -64])), 2),
        ],
        eye: const Offset(49, -57),
      );
  }
}

/// Oyma ahşap hayvan: üstten vuran fener ışığı, liflenmiş ahşap, keski izleri,
/// gövdenin altında gölge.
void drawCarvedAnimal(Canvas c, String kind, {double glow = 0}) {
  final a = ArkAnimal.of(kind);
  final b = a.silhouette.getBounds();
  const lit = Color(0xFFE2B07A);
  const mid = Color(0xFF8A5530);
  const dark = Color(0xFF341A0C);
  const far = Color(0xFF3E2414);
  // Arka bacaklar.
  c.drawPath(a.farLegs, Paint()..color = far);
  // Kuyruk ve boynuzlar (gövdenin arkasında kalsın).
  for (final (p, w) in a.strokes) {
    if (w == 0) {
      c.drawPath(p, Paint()..color = mid);
    } else {
      c.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..color = mid,
      );
    }
  }
  void carved(Path p, {double shade = 0}) {
    // Üst kenar ışıkta: önce ışık rengi, üstüne aşağı kaydırılmış orta ton.
    c.drawPath(p, Paint()..color = lit);
    c.save();
    c.clipPath(p);
    c.drawPath(
      p.shift(const Offset(0.6, 2.2)),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, b.top),
          Offset(0, b.bottom),
          [
            Color.lerp(mid, lit, 0.25 - shade)!,
            Color.lerp(mid, dark, 0.35 + shade)!,
            dark,
          ],
          const [0, 0.6, 1],
        ),
    );
    // Ahşap lifleri: gövde boyunca dalgalı ince çizgiler.
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = dark.withValues(alpha: 0.45);
    for (var y = b.top + 3; y < b.bottom; y += 3.2) {
      final g = Path()..moveTo(b.left, y);
      for (var x = b.left; x <= b.right; x += 4) {
        g.lineTo(x, y + math.sin(x * 0.18 + y * 0.7) * 0.9);
      }
      c.drawPath(g, grain);
    }
    // Keski izleri: kısa, açık çentikler.
    final chip = Paint()
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round
      ..color = lit.withValues(alpha: 0.35);
    for (var i = 0; i < 18; i++) {
      final h = (i * 2654435761) & 0xffff;
      final x = b.left + (h % 997) / 997 * b.width;
      final y = b.top + ((h >> 4) % 991) / 991 * b.height;
      c.drawLine(Offset(x, y), Offset(x + 2.2, y - 1.2), chip);
    }
    c.restore();
  }

  carved(a.body);
  if (a.overlay != null) {
    // Yele / kulak: ayrı oyulmuş, kenarı derin bir oyukla ayrılır.
    c.drawPath(
      a.overlay!,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = dark.withValues(alpha: 0.7),
    );
    carved(a.overlay!, shade: 0.1);
  }
  // Göz: oyuk.
  c.drawCircle(a.eye, 1.4, Paint()..color = const Color(0xFF1E1008));
  if (glow > 0) {
    // Eşine kavuştu: ılık bir ışık.
    c.drawPath(
      a.silhouette,
      Paint()
        ..color = const Color(0xFFFFD08A).withValues(alpha: 0.35 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }
}

/// Hayvanın duvara düşen gölgesi: yumuşak kenarlı, tek parça.
void drawAnimalShadow(Canvas c, String kind, Color color, {double blur = 2.5}) {
  final a = ArkAnimal.of(kind);
  final p = Paint()
    ..color = color
    ..maskFilter = blur > 0 ? MaskFilter.blur(BlurStyle.normal, blur) : null;
  c.drawPath(a.silhouette, p);
  for (final (s, w) in a.strokes) {
    if (w == 0) {
      c.drawPath(s, p);
    } else {
      c.drawPath(
        s,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..maskFilter = p.maskFilter,
      );
    }
  }
}
