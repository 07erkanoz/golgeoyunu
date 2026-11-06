// Nemrut'un renk ve doku katmanları (CARTOON açıkken): Kule ve kar
// bölümlerindeki kâğıt oyma dil. Tümülüs çakıl taşından oyma bir koni
// (sıra sıra oyulmuş çakıllar, sol yamacında ay ya da şafak ışığı, doruğunda
// kar), önünde katman katman karlı teraslar. Gece ve şafak paleti olduğu
// gibi kalır; bulanıklık yok.
import 'dart:math' as math;
import 'dart:ui';

import 'doku_kar.dart' show paintSnowBlanket;
import 'level.dart';
import 'nemrut.dart' show NemrutArt, NemrutHead;

double _hash(int i, [int salt = 0]) {
  final v = math.sin(i * 127.1 + salt * 311.7) * 43758.5453;
  return v - v.floorToDouble();
}

final _drop = Paint()..color = const Color(0x4D000000);

/// Tümülüs: [tx] tepe noktasının x'i, [dawn] 0 gece, 1 gün doğumu.
void paintNemrutTumulus(Canvas c, double w, double h, double tx, double dawn) {
  final body = Path()
    ..moveTo(tx - w * 0.5, h * 0.7)
    ..quadraticBezierTo(tx - w * 0.1, h * 0.36, tx - w * 0.012, h * 0.342)
    ..quadraticBezierTo(tx, h * 0.338, tx + w * 0.012, h * 0.342)
    ..quadraticBezierTo(tx + w * 0.1, h * 0.36, tx + w * 0.5, h * 0.7)
    ..close();
  final fill = Color.lerp(
    const Color(0xFF1E1828),
    const Color(0xFF5A3838),
    dawn,
  )!;
  c.drawPath(body.shift(const Offset(4, 5)), _drop);
  c.drawPath(body, Paint()..color = fill);
  c.save();
  c.clipPath(body);
  // Işığın vurmadığı sağ yamaç bir ton koyu.
  c.drawRect(
    Rect.fromLTRB(tx + w * 0.004, h * 0.3, tx + w * 0.55, h * 0.72),
    Paint()..color = const Color(0x2A000000),
  );
  // Oyulmuş çakıl sıraları: koninin eğimine uyan yaylar boyunca küçük
  // taşlar; aşağı indikçe iri ve seyrek.
  final pebble = Paint()
    ..color = Color.lerp(fill, const Color(0xFF000000), 0.35)!;
  final lit = Paint()
    ..color = Color.lerp(fill, const Color(0xFFE8D8C8), 0.18 + 0.12 * dawn)!;
  for (var row = 0; row < 9; row++) {
    final f = (row + 1) / 10; // tepeden aşağı
    final y = h * (0.35 + 0.34 * f);
    final half = w * 0.5 * math.pow(f, 1.6) + w * 0.012;
    final n = (half / (6 + 10 * f)).floor();
    for (var k = -n; k <= n; k++) {
      final x = tx + k * half / math.max(1, n);
      final r = (1.2 + 2.2 * f) * (0.7 + 0.5 * _hash(row * 97 + k, 3));
      final dy = (_hash(row * 31 + k, 5) - 0.5) * 6 * f;
      final p = Offset(x, y + dy + (k / math.max(1, n)).abs() * 4 * f);
      c.drawOval(
        Rect.fromCenter(center: p, width: r * 2.4, height: r * 1.4),
        pebble,
      );
      // Taşın üst kenarı ışık alır (ışık soldan).
      if (x < tx) {
        c.drawLine(
          p + Offset(-r * 0.8, -r * 0.5),
          p + Offset(r * 0.4, -r * 0.7),
          lit..strokeWidth = 0.9,
        );
      }
    }
  }
  // Doruğun karı (gece): dişli alt kenar.
  if (dawn < 0.9) {
    final snow = Path()..moveTo(tx - w * 0.2, h * 0.3);
    const teeth = 9;
    for (var k = 0; k <= teeth; k++) {
      final t = k / teeth;
      final x = tx - w * 0.07 + w * 0.14 * t;
      final y = h * (0.37 + (k.isOdd ? 0.018 : 0.006) * (1 + _hash(k, 9)));
      snow.lineTo(x, y);
    }
    snow
      ..lineTo(tx + w * 0.2, h * 0.3)
      ..close();
    c.drawPath(
      snow,
      Paint()
        ..color = const Color(0xFF8A8EA8).withValues(alpha: 0.85 * (1 - dawn)),
    );
  }
  c.restore();
  // Sol yamaçta ışığın kenarı.
  final rim = Path()
    ..moveTo(tx - w * 0.3, h * 0.6)
    ..quadraticBezierTo(tx - w * 0.1, h * 0.36, tx - w * 0.012, h * 0.342)
    ..quadraticBezierTo(tx, h * 0.338, tx + w * 0.006, h * 0.341);
  c.drawPath(
    rim,
    Paint()
      ..color = Color.lerp(
        const Color(0xFFDCE0FF),
        const Color(0xFFFFD2A0),
        dawn,
      )!.withValues(alpha: 0.4)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke,
  );
}

/// Karlı teraslar: iki kâğıt katman, tümsekli üst kenarda ışık.
void paintNemrutTerraces(
  Canvas c,
  double w,
  double h, {
  required double offset,
  required double dawn,
}) {
  for (final (k, base, amp, par, tone) in [
    (0, h * 0.73, 10.0, 0.6, 0.0),
    (1, h * 0.78, 16.0, 1.0, 1.0),
  ]) {
    final off = offset * par;
    const step = 90.0;
    final path = Path()..moveTo(-20, h + 20);
    var i = (off / step).floor() - 1;
    var x = i * step - off;
    path.lineTo(x, base);
    final rimPath = Path()..moveTo(x, base);
    while (x < w + step) {
      final nx = x + step;
      final top = base - amp * (0.4 + 0.6 * _hash(i, 31 + k));
      final ny = base - amp * 0.3 * _hash(i + 1, 41 + k);
      path.quadraticBezierTo(x + step / 2, top, nx, ny);
      rimPath.quadraticBezierTo(x + step / 2, top, nx, ny);
      x = nx;
      i++;
    }
    path
      ..lineTo(x, h + 20)
      ..close();
    final fill = Color.lerp(
      Color.lerp(const Color(0xFF4A4E66), const Color(0xFF3A3A54), tone)!,
      Color.lerp(const Color(0xFFC0A49A), const Color(0xFFA88A84), tone)!,
      dawn,
    )!;
    c.drawPath(path.shift(const Offset(0, -3)), _drop);
    c.drawPath(path, Paint()..color = fill);
    c.drawPath(
      rimPath,
      Paint()
        ..color = Color.lerp(
          const Color(0xFFDCE0FF),
          const Color(0xFFFFE0B8),
          dawn,
        )!.withValues(alpha: 0.4)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
  }
}

/// Oturan dev tanrı (uzak terasta), kâğıt oyma: basamaklı kaide, taş taht,
/// dizlerinde elleri, giysisinde oyma kıvrımlar, gövdesinde çatlaklar,
/// omuzlarında ve dizlerinde kar; başı düşmüşse boynu dişli kırık. Işık
/// soldan (ay ya da şafak). [x] ortası, [base] kaidenin dibi, [s] ölçek.
void paintSeatedGod(
  Canvas c,
  double x,
  double base,
  double s,
  Color stone, {
  required bool headOn,
  required bool tiara,
  required double dawn,
  int seed = 0,
}) {
  // Heykel taşı tümülüsten bir ton açık: önünde seçilsin.
  stone = Color.lerp(stone, const Color(0xFF5A5268), 0.3)!;
  final fill = Paint()..color = stone;
  final carve = Paint()
    ..color = Color.lerp(stone, const Color(0xFF000000), 0.5)!
    ..strokeWidth = 1.3 * s
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final light = Color.lerp(
    const Color(0xFFDCE0FF),
    const Color(0xFFFFD2A0),
    dawn,
  )!;
  final rim = Paint()
    ..color = light.withValues(alpha: 0.5)
    ..strokeWidth = 1.5 * s
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final snow = Paint()
    ..color = Color.lerp(
      const Color(0xFF9AA2BC),
      const Color(0xFFE8CCC0),
      dawn,
    )!;
  double X(double v) => x + v * s;
  double Y(double v) => base - v * s;

  // Bütün siluet: kaide, taht, beden (gölgesi ardına düşsün).
  final plinth = Path()
    ..addRect(Rect.fromLTRB(X(-74), Y(14), X(74), Y(0)))
    ..addRect(Rect.fromLTRB(X(-64), Y(28), X(64), Y(14)));
  // Taht bedenin ardında: alçak sırtlık ve iki yanda kol dayanakları.
  final throne = Path()
    ..addRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(X(-46), Y(176), X(46), Y(28)),
        topLeft: Radius.circular(8 * s),
        topRight: Radius.circular(8 * s),
      ),
    )
    ..addRect(Rect.fromLTRB(X(-62), Y(112), X(-40), Y(28)))
    ..addRect(Rect.fromLTRB(X(40), Y(112), X(62), Y(28)));
  // Beden önden: bacaklar (iki kalın sütun, ayaklar dışa), kucak, gövde,
  // yuvarlak omuzlar; kollar yanlarda inip ellerle dizlere konar.
  final body = Path()
    ..moveTo(X(-40), Y(28))
    ..lineTo(X(-40), Y(34))
    ..lineTo(X(-36), Y(118))
    ..quadraticBezierTo(X(-40), Y(132), X(-44), Y(140))
    ..quadraticBezierTo(X(-46), Y(196), X(-56), Y(224))
    ..quadraticBezierTo(X(-56), Y(246), X(-28), Y(248))
    ..lineTo(X(28), Y(248))
    ..quadraticBezierTo(X(56), Y(246), X(56), Y(224))
    ..quadraticBezierTo(X(46), Y(196), X(44), Y(140))
    ..quadraticBezierTo(X(40), Y(132), X(36), Y(118))
    ..lineTo(X(40), Y(34))
    ..lineTo(X(40), Y(28))
    ..close();
  final all = Path()
    ..addPath(plinth, Offset.zero)
    ..addPath(throne, Offset.zero)
    ..addPath(body, Offset.zero);
  c.drawPath(all.shift(Offset(4 * s, 5 * s)), _drop);
  c.drawPath(plinth, fill);
  // Taht bir ton koyu: beden önünde seçilsin.
  c.drawPath(
    throne,
    Paint()..color = Color.lerp(stone, const Color(0xFF000000), 0.22)!,
  );
  // Tahtın oyma çerçevesi.
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTRB(X(-58), Y(104), X(-44), Y(36)),
      Radius.circular(3 * s),
    ),
    carve,
  );
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTRB(X(44), Y(104), X(58), Y(36)),
      Radius.circular(3 * s),
    ),
    carve,
  );
  c.drawPath(body, fill);
  // Kollar: omuzdan dirseğe, önkol dizlere uzanır; eller dizlerde.
  for (final side in const [-1.0, 1.0]) {
    final arm = Path()
      ..moveTo(X(side * 46), Y(228))
      ..quadraticBezierTo(X(side * 58), Y(190), X(side * 52), Y(150))
      ..quadraticBezierTo(X(side * 44), Y(132), X(side * 22), Y(128))
      ..lineTo(X(side * 20), Y(140))
      ..quadraticBezierTo(X(side * 38), Y(146), X(side * 40), Y(162))
      ..quadraticBezierTo(X(side * 40), Y(196), X(side * 34), Y(226))
      ..close();
    c.drawPath(arm, fill);
    c.drawPath(arm, carve);
    // El: dizin üstünde yuvarlak.
    c.drawOval(
      Rect.fromCenter(
        center: Offset(X(side * 21), Y(132)),
        width: 14 * s,
        height: 10 * s,
      ),
      fill,
    );
  }
  // Giysinin oyma kıvrımları: bacaklar boyunca, göğüste V yaka.
  for (final fx in const [-26.0, -14.0, 14.0, 26.0]) {
    c.drawLine(Offset(X(fx), Y(40)), Offset(X(fx * 0.9), Y(112)), carve);
  }
  c.drawLine(Offset(X(0), Y(36)), Offset(X(0), Y(118)), carve);
  c.drawPath(
    Path()
      ..moveTo(X(-20), Y(240))
      ..quadraticBezierTo(X(0), Y(214), X(20), Y(240)),
    carve,
  );
  c.drawLine(Offset(X(-40), Y(140)), Offset(X(40), Y(140)), carve);
  // Çatlaklar: gövdede kırık çizgiler.
  for (var k = 0; k < 2; k++) {
    var px = X(-30 + 60 * _hash(seed * 7 + k, 11));
    var py = Y(200 - 60 * _hash(seed * 7 + k, 13));
    final crack = Path()..moveTo(px, py);
    for (var j = 0; j < 4; j++) {
      px += (_hash(seed * 31 + k * 5 + j, 17) - 0.5) * 16 * s;
      py += (6 + 8 * _hash(seed * 31 + k * 5 + j, 19)) * s;
      crack.lineTo(px, py);
    }
    c.drawPath(crack, carve);
  }
  if (headOn) {
    c.save();
    c.translate(x, Y(244));
    NemrutArt.head(
      c,
      tiara ? NemrutHead.antiochos : NemrutHead.zeus,
      150 * s,
      flat: stone,
    );
    c.restore();
  } else {
    // Kırık boyun: dişli kenar.
    final neck = Path()..moveTo(X(-16), Y(244));
    for (var k = 0; k <= 6; k++) {
      neck.lineTo(
        X(-16 + 32 * k / 6),
        Y(250 + (k.isEven ? 8 : 2) + 4 * _hash(seed + k, 23)),
      );
    }
    neck
      ..lineTo(X(16), Y(244))
      ..close();
    c.drawPath(neck, fill);
    c.drawPath(neck, rim);
  }
  // Kar: omuzlarda, kucakta, dizlerde, basamaklarda (tümsekli ince örtü).
  void cap(double l, double r, double y, double t) {
    final p = Path()..moveTo(X(l), Y(y));
    for (var k = 0; k <= 6; k++) {
      p.lineTo(
        X(l + (r - l) * k / 6),
        Y(y + t * (0.6 + 0.6 * _hash(seed + k + l.toInt(), 29))),
      );
    }
    p
      ..lineTo(X(r), Y(y - 1.5))
      ..lineTo(X(l), Y(y - 1.5))
      ..close();
    c.drawPath(p, snow);
  }

  cap(-55, -22, 240, 4);
  cap(22, 55, 240, 4);
  cap(-40, 40, 141, 3.5);
  cap(-64, 64, 28, 3);
  cap(-74, 74, 14, 3);
  // Işık soldan: sol kenarlarda dar kenar ışığı.
  c.drawLine(Offset(X(-74), Y(14)), Offset(X(-74), Y(1)), rim);
  c.drawLine(Offset(X(-62), Y(112)), Offset(X(-62), Y(30)), rim);
  c.drawPath(
    Path()
      ..moveTo(X(-44), Y(140))
      ..quadraticBezierTo(X(-46), Y(196), X(-56), Y(224))
      ..quadraticBezierTo(X(-56), Y(246), X(-28), Y(248)),
    rim,
  );
}

/// Heykellerin dibine dağılmış kırık taş parçaları.
void paintRubble(
  Canvas c,
  double x,
  double base,
  double s,
  Color stone,
  int seed,
) {
  final fill = Paint()..color = stone;
  final edge = Paint()
    ..color = const Color(0xFFDCE0FF).withValues(alpha: 0.25)
    ..strokeWidth = 1 * s
    ..style = PaintingStyle.stroke;
  for (var k = 0; k < 5; k++) {
    final px = x + (_hash(seed * 13 + k, 3) - 0.5) * 150 * s;
    final r = (5 + 9 * _hash(seed * 13 + k, 5)) * s;
    final p = Path()..moveTo(px - r, base);
    final n = 5;
    for (var j = 1; j < n; j++) {
      final a = math.pi * j / n;
      final rr = r * (0.7 + 0.5 * _hash(seed * 7 + k * 3 + j, 7));
      p.lineTo(px - math.cos(a) * rr, base - math.sin(a) * rr * 0.8);
    }
    p
      ..lineTo(px + r, base)
      ..close();
    c.drawPath(p, fill);
    c.drawLine(
      Offset(px - r * 0.9, base - r * 0.3),
      Offset(px - r * 0.3, base - r * 0.75),
      edge,
    );
  }
}

/// Nemrut'un zemin karosu, olağan çizimin üstüne: iri kesme taş bloklar
/// (64×32), oyulmuş derzler; her bloğun üst ve sol kenarı ışık alır, alt ve
/// sağı gölgede; köşeler yer yer kırık, kimi blokta Kommagene yıldızı
/// kabartması. Üstü açıksa kalın kar örtüsü.
void paintNemrutTile(Canvas c, Level lv, int col, int row, double x, double y) {
  const t = kTile;
  var depth = 0;
  while (depth < 3 && row - depth - 1 >= 0 && lv.solid(col, row - depth - 1)) {
    depth++;
  }
  if (depth < 3) {
    final a = 1 - depth / 3;
    // Blok: iki karo eninde, bir karo boyunda; sıralar yarım kayık.
    final bx = (col + (row.isOdd ? 1 : 0)) ~/ 2;
    final leftEdge = (col + (row.isOdd ? 1 : 0)).isEven;
    final lit = Paint()
      ..color = const Color(0xFFB8B0D0).withValues(alpha: 0.16 * a)
      ..strokeWidth = 1.2;
    final dark = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.55 * a)
      ..strokeWidth = 1.6;
    // Üst kenar ışık, alt kenar oyuk.
    c.drawLine(Offset(x, y + 1.2), Offset(x + t, y + 1.2), lit);
    c.drawLine(Offset(x, y + t - 0.8), Offset(x + t, y + t - 0.8), dark);
    if (leftEdge) {
      c.drawLine(Offset(x + 0.8, y), Offset(x + 0.8, y + t), dark);
      c.drawLine(Offset(x + 2.2, y + 1), Offset(x + 2.2, y + t - 2), lit);
      // Kırık köşe.
      if (_hash(bx * 7 + row, 41) < 0.35) {
        c.drawPath(
          Path()
            ..moveTo(x, y)
            ..lineTo(x + 5 + 4 * _hash(bx + row, 43), y)
            ..lineTo(x, y + 4 + 4 * _hash(bx + row, 47))
            ..close(),
          Paint()..color = const Color(0xFF000000).withValues(alpha: 0.6 * a),
        );
      }
    } else if (_hash(bx * 5 + row, 53) < 0.12 && depth >= 1) {
      // Kommagene yıldızı: bloğun ortasında (iki karonun ekinde) oyma.
      final cc = Offset(x, y + t / 2);
      final star = Path();
      for (var k = 0; k < 16; k++) {
        final r = k.isEven ? 7.0 : 3.0;
        final an = k * math.pi / 8 - math.pi / 2;
        final p = cc + Offset(math.cos(an) * r, math.sin(an) * r);
        k == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
      }
      star.close();
      c.drawPath(
        star,
        Paint()
          ..color = const Color(0xFF000000).withValues(alpha: 0.45 * a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      c.drawPath(
        star.shift(const Offset(-0.8, -0.8)),
        lit..style = PaintingStyle.stroke,
      );
    }
  }
  if (row > 0 && !lv.solid(col, row - 1)) {
    paintSnowBlanket(c, lv, col, row, x, y);
  }
}
