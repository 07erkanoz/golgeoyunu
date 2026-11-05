// Renk ve doku: Kule (II). Oyunun kendi dilinde, gölge oyunu siluetiyle:
// kulenin duvarı karanlık bir mürekkep silüeti, ışık yalnız oyulmuş
// yerlerden sızar (pencere, kafes, Karagöz tasvirlerindeki gibi oyma
// delikler). Kule kat kat değişir: dipte zindan (parmaklıklı küçük
// pencereler, ardında mahzenlerin közü), ortada kemerli pencereler, göz
// pencereler, örülmüş kemerler ve duvara oyulmuş merdivenler, tepede geniş
// açık kemerler, çan ve kargalar. Zemin ve kirişler mürekkep siluet; ince
// sıcak kenar ışığı ve oyma süsle. Bölümün karanlığına dokunulmaz: fenerler,
// kavanoz ve ışık delikleri seçik kalır.
//
// Duvar parçaları (kat × çeşit) birer kez resme çevrilir; her karede yalnız
// kopyalanır. Arazi zaten dilim dilim önbellekte.
import 'dart:math' as math;
import 'dart:ui';

import 'level.dart';

/// Duvarın mürekkebi: arazinin mürekkebinden bir ton açık (önündeki taşlar
/// ve kirişler ondan ayrılsın).
const _wallInk = Color(0xFF160C08);

/// Oyma çizgiler (taş derzleri, merdiven): mürekkebe oyulmuş, ışık almayan.
const _carve = Color(0xFF3A2216);

/// Oyulmuş kenarın ince ılık ışığı.
const _rim = Color(0x80E09A60);

Color _lerp(int a, int b, double t) =>
    Color.lerp(Color(a), Color(b), t.clamp(0.0, 1.0))!;

/// [i]. öğe için 0..1 arası kararlı rastgele sayı.
double _hash(int i, [int salt = 0]) {
  var x = (i * 374761393 + salt * 668265263) & 0x7fffffff;
  x = ((x ^ (x >> 13)) * 1274126177) & 0x7fffffff;
  return (x & 0xffff) / 0xffff;
}

/// Kulenin katı: dipte zindan, ortada kule gövdesi, tepede çan katı.
enum _Floor { dungeon, body, belfry }

Path _arch(Rect r) => Path()
  ..moveTo(r.left, r.bottom)
  ..lineTo(r.left, r.top + r.width / 2)
  ..arcToPoint(
    Offset(r.right, r.top + r.width / 2),
    radius: Radius.circular(r.width / 2),
  )
  ..lineTo(r.right, r.bottom)
  ..close();

/// Duvarın bir parçası: mürekkep, oyulmuş delikler saydam (ardındaki ışık ve
/// şehir ayrıca çizilir), üstünde oyma çizgiler ve kenar ışığı.
class _WallTile {
  _WallTile(this.floor, this.variant, this.w, this.h);

  final _Floor floor;
  final int variant;
  final double w;
  final double h;
  Image? _image;
  Picture? _picture;

  /// Işığın sızdığı açıklıklar (pencereler) ve pencerelerin alt kenarı
  /// (şehir silüeti oraya oturur).
  final holes = <Rect>[];

  void draw(Canvas c, Offset at) {
    final img = _image;
    if (img != null) {
      c.drawImage(img, at, Paint()..filterQuality = FilterQuality.low);
      return;
    }
    c.save();
    c.translate(at.dx, at.dy);
    c.drawPicture(_picture!);
    c.restore();
  }

  void prepare() {
    _picture = _record();
    try {
      _image = _picture!.toImageSync(w.ceil(), h.ceil());
    } catch (_) {
      // Resme çevrilemiyorsa (bazı test ortamları) kayıt oynatılır.
    }
  }

  void dispose() {
    _image?.dispose();
    _picture?.dispose();
  }

  Picture _record() {
    final rec = PictureRecorder();
    final c = Canvas(rec);
    final bounds = Rect.fromLTWH(0, 0, w, h);
    final cut = Path(); // ışığın geçtiği her yer
    final bars = <Rect>[]; // parmaklıklı açıklıklar
    final r = math.Random(floor.index * 97 + variant * 13 + 5);
    switch (floor) {
      case _Floor.dungeon:
        // Yüksekte küçük, parmaklıklı mazgal pencereler; biri bazen örülü.
        for (var i = 0; i < 2; i++) {
          final x = w * (0.18 + 0.5 * i) + r.nextDouble() * w * 0.08;
          final win = Rect.fromLTWH(x, h * 0.2, w * 0.12, h * 0.2);
          if (variant == 2 && i == 1) continue;
          holes.add(win);
          bars.add(win);
          cut.addPath(_arch(win), Offset.zero);
        }
      case _Floor.body:
        switch (variant) {
          case 0:
            // Tek uzun kemer.
            final win = Rect.fromLTWH(w * 0.38, h * 0.16, w * 0.22, h * 0.5);
            holes.add(win);
            cut.addPath(_arch(win), Offset.zero);
          case 1:
            // Ortası sütunlu çift kemer.
            for (var i = 0; i < 2; i++) {
              final win = Rect.fromLTWH(
                w * (0.3 + 0.2 * i),
                h * 0.2,
                w * 0.16,
                h * 0.42,
              );
              holes.add(win);
              cut.addPath(_arch(win), Offset.zero);
            }
          default:
            // Göz pencere (yuvarlak, oyma kafesli).
            final o = Rect.fromCircle(
              center: Offset(w * 0.5, h * 0.36),
              radius: h * 0.15,
            );
            holes.add(o);
            cut.addOval(o);
        }
      case _Floor.belfry:
        // Geniş açık kemerler.
        for (var i = 0; i < 2; i++) {
          final win = Rect.fromLTWH(
            w * (0.08 + 0.5 * i),
            h * 0.1,
            w * 0.36,
            h * 0.66,
          );
          holes.add(win);
          cut.addPath(_arch(win), Offset.zero);
        }
    }
    // Pencerelerin çevresinde Karagöz tasvirlerindeki gibi oyma delik
    // dizisi: ışık noktalar hâlinde sızar.
    for (final win in holes) {
      if (floor == _Floor.dungeon) continue;
      final round = floor == _Floor.body && variant >= 2;
      final n = round ? 16 : 11;
      for (var k = 0; k < n; k++) {
        final Offset p;
        if (round) {
          final a = k / n * 2 * math.pi;
          p =
              win.center +
              Offset(math.cos(a), math.sin(a)) * (win.width / 2 + 9);
        } else {
          // Kemerin üstünde yay boyunca.
          final a = math.pi + k / (n - 1) * math.pi;
          final rad = win.width / 2 + 9;
          p =
              Offset(win.center.dx, win.top + win.width / 2) +
              Offset(math.cos(a), math.sin(a)) * rad;
        }
        cut.addOval(Rect.fromCircle(center: p, radius: k.isEven ? 2.4 : 1.6));
      }
    }
    c.save();
    c.clipPath(
      Path.combine(PathOperation.difference, Path()..addRect(bounds), cut),
    );
    c.drawRect(bounds, Paint()..color = _wallInk);
    // Taş derzleri: iri bloklar, oyulmuş çizgi.
    final joint = Paint()
      ..color = _carve
      ..strokeWidth = 1.2;
    final bh = h / 8;
    for (var row = 0; row < 8; row++) {
      final y = row * bh;
      c.drawLine(Offset(0, y), Offset(w, y), joint);
      final shift = row.isOdd ? w / 6 : 0.0;
      for (var x = shift; x < w; x += w / 3) {
        c.drawLine(Offset(x, y), Offset(x, y + bh), joint);
      }
    }
    // Ortadaki katlarda duvara oyulmuş merdiven: basamakların üst kenarı
    // ılık ışık alır (kulede yukarı çıkan yol).
    if (floor == _Floor.body && variant != 1) {
      final rim = Paint()
        ..color = _rim
        ..strokeWidth = 1.3;
      final up = variant == 0 ? -1.0 : 1.0;
      final stepW = w * 0.06, stepH = h * 0.05;
      var x = up < 0 ? w * 0.94 : w * 0.02;
      var y = h * 0.96;
      for (var k = 0; k < 10; k++) {
        final p = Path()
          ..moveTo(x, y)
          ..lineTo(x, y - stepH)
          ..lineTo(x - up * stepW, y - stepH);
        c.drawPath(
          p,
          Paint()
            ..color = _carve
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        c.drawLine(
          Offset(x, y - stepH),
          Offset(x - up * stepW, y - stepH),
          rim,
        );
        x -= up * stepW;
        y -= stepH;
      }
    }
    c.restore();
    // Parmaklıklar (mürekkep), açıklıkların kenar ışığı, eşikler.
    final ink = Paint()
      ..color = _wallInk
      ..strokeWidth = 2.6;
    for (final b in bars) {
      for (var k = 1; k < 4; k++) {
        final x = b.left + b.width * k / 4;
        c.drawLine(Offset(x, b.top), Offset(x, b.bottom), ink);
      }
      c.drawLine(
        Offset(b.left, b.top + b.height * 0.55),
        Offset(b.right, b.top + b.height * 0.55),
        ink,
      );
    }
    final rimPaint = Paint()
      ..color = _rim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final win in holes) {
      if (floor == _Floor.body && variant >= 2) {
        c.drawOval(win.inflate(1), rimPaint);
        // Göz pencerenin oyma kafesi: altı kollu yıldız.
        final star = Paint()
          ..color = _wallInk
          ..strokeWidth = 2.4;
        for (var k = 0; k < 3; k++) {
          final a = k * math.pi / 3;
          final d = Offset(math.cos(a), math.sin(a)) * win.width / 2;
          c.drawLine(win.center - d, win.center + d, star);
        }
        c.drawCircle(win.center, win.width * 0.12, Paint()..color = _wallInk);
      } else {
        c.drawPath(_arch(win.inflate(1)), rimPaint);
        c.drawRect(
          Rect.fromLTWH(win.left - 4, win.bottom, win.width + 8, 4),
          Paint()..color = _carve,
        );
      }
    }
    // Ortası sütunlu çift kemerde ince sütun.
    if (floor == _Floor.body && variant == 1) {
      final mid = (holes[0].right + holes[1].left) / 2;
      c.drawRect(
        Rect.fromLTWH(
          mid - 3,
          holes[0].top + holes[0].width / 2,
          6,
          holes[0].height,
        ),
        Paint()..color = _wallInk,
      );
    }
    return rec.endRecording();
  }
}

final _tiles = <(int, int), _WallTile>{};
double _tileH = 0;

_WallTile _tile(_Floor floor, int variant, double w, double h) {
  if (_tileH != h) {
    for (final t in _tiles.values) {
      t.dispose();
    }
    _tiles.clear();
    _tileH = h;
  }
  return _tiles[(floor.index, variant)] ??= _WallTile(floor, variant, w, h)
    ..prepare();
}

/// Pencereden görünen şehir: kubbeler, minareler, damlar (tek dizi).
Path _skyline(double width, double h, int seed) {
  final p = Path()..moveTo(0, h);
  var x = 0.0;
  var i = seed * 11;
  while (x < width) {
    final kind = _hash(i, 1);
    final base = h * (0.55 + 0.25 * _hash(i, 2));
    if (kind < 0.3) {
      final r = h * (0.18 + 0.1 * _hash(i, 3));
      p
        ..lineTo(x, base)
        ..lineTo(x + r * 0.2, base)
        ..arcToPoint(Offset(x + r * 2.2, base), radius: Radius.circular(r))
        ..lineTo(x + r * 2.4, base);
      final mx = x + r * 2.6, mw = h * 0.035;
      final top = base - h * (0.5 + 0.2 * _hash(i, 4));
      p
        ..lineTo(mx, base)
        ..lineTo(mx, top + mw * 2)
        ..lineTo(mx + mw / 2, top)
        ..lineTo(mx + mw, top + mw * 2)
        ..lineTo(mx + mw, base);
      x = mx + mw + h * 0.05;
    } else if (kind < 0.55) {
      final mw = h * 0.035;
      final top = base - h * (0.45 + 0.2 * _hash(i, 5));
      p
        ..lineTo(x, base)
        ..lineTo(x, top + mw * 2)
        ..lineTo(x + mw / 2, top)
        ..lineTo(x + mw, top + mw * 2)
        ..lineTo(x + mw, base);
      x += mw + h * 0.06;
    } else {
      final w = h * (0.14 + 0.12 * _hash(i, 6));
      p
        ..lineTo(x, base)
        ..lineTo(x + w / 2, base - h * 0.08)
        ..lineTo(x + w, base);
      x += w;
    }
    i++;
  }
  return p
    ..lineTo(width, h)
    ..close();
}

final _skylines = <int, Path>{};

/// Kule'nin arka planı (ekran uzayında). [height]: kamera bölümde ne kadar
/// yukarıda (0 dip, 1 tepe); [levelH]: bölümün boyu (dünya birimi).
void paintKuleBackdrop(
  Canvas canvas,
  double w,
  double h,
  Offset cam,
  double height,
  double t,
  double levelH,
) {
  final rect = Rect.fromLTWH(0, 0, w, h);
  // Perdenin ışığı (bölümün eski gökleri): tırmandıkça açılan pas rengi
  // alacakaranlık. Yalnız oyuklardan görünür.
  canvas.drawRect(
    rect,
    Paint()
      ..shader = Gradient.linear(rect.topCenter, rect.bottomCenter, [
        _lerp(0xFF4A2418, 0xFFD07A45, height),
        _lerp(0xFF2A140E, 0xFF8A3E22, height),
      ]),
  );
  const par = 0.3;
  final tw = (h * 0.72).roundToDouble(), th = (h * 0.6).roundToDouble();
  final ox = cam.dx * par, oy = cam.dy * par;
  final c0 = (ox / tw).floor(), r0 = (oy / th).floor();
  for (var row = r0; row * th - oy < h; row++) {
    final top = row * th - oy;
    // Bu sıranın kulede nerede olduğu: 0 tepe, 1 dip.
    final f = ((row + 0.5) * th / (levelH * par)).clamp(0.0, 1.0);
    final floor = f > 0.82
        ? _Floor.dungeon
        : (f < 0.16 ? _Floor.belfry : _Floor.body);
    // Oyukların ardı: dipte mahzenlerin közü, yukarıda şehir.
    if (floor == _Floor.dungeon) {
      final flick = 0.75 + 0.25 * math.sin(t * 7 + row) * math.sin(t * 3.1);
      canvas.drawRect(
        Rect.fromLTWH(0, top, w, th),
        Paint()
          ..shader = Gradient.linear(
            Offset(0, top + th * 0.15),
            Offset(0, top + th * 0.5),
            [
              Color.fromRGBO(255, 120, 50, 0.55 * flick),
              const Color(0x00FF7832),
            ],
          ),
      );
    } else {
      final sh = th * (floor == _Floor.belfry ? 0.3 : 0.24);
      final base = top + th * (floor == _Floor.belfry ? 0.76 : 0.62);
      final path = _skylines[row % 4] ??= _skyline(900, sh, row % 4);
      final sky = Paint()..color = const Color(0xE6120A08);
      final sx = -(cam.dx * 0.1 + row * 260) % 900;
      for (var x = sx - 900; x < w; x += 900) {
        canvas.save();
        canvas.translate(x, base - sh);
        canvas.drawPath(path, sky);
        canvas.restore();
      }
      if (floor == _Floor.belfry) {
        // Kargalar: kulenin tepesinde dolanır.
        final crow = Paint()
          ..color = const Color(0xFF120A08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8;
        for (var k = 0; k < 4; k++) {
          final cx = (k * 260 + t * (16 + k * 4) - cam.dx * 0.12) % (w + 80);
          final cy = top + th * (0.22 + 0.07 * k) + math.sin(t * 1.3 + k) * 6;
          final f2 = math.sin(t * 6 + k) * 3;
          canvas.drawPath(
            Path()
              ..moveTo(cx - 7, cy - f2)
              ..quadraticBezierTo(cx - 3, cy - 4, cx, cy)
              ..quadraticBezierTo(cx + 3, cy - 4, cx + 7, cy - f2),
            crow,
          );
        }
      }
    }
    for (var col = c0; col * tw - ox < w; col++) {
      final v = (_hash(row * 31 + col, 7) * 3).floor();
      _tile(floor, v, tw, th).draw(canvas, Offset(col * tw - ox, top));
    }
    // Çan katında, bir kemerde asılı çan.
    if (floor == _Floor.belfry && row.isEven) {
      final bx = (c0 + 1) * tw - ox + tw * 0.26;
      final by = top + th * 0.2;
      final swing = math.sin(t * 0.9 + row) * 0.06;
      canvas.save();
      canvas.translate(bx, by);
      canvas.rotate(swing);
      final bell = Path()
        ..moveTo(-3, 0)
        ..lineTo(3, 0)
        ..quadraticBezierTo(5, 18, 20, 38)
        ..lineTo(-20, 38)
        ..quadraticBezierTo(-5, 18, -3, 0)
        ..close();
      canvas.drawLine(
        Offset(0, -th * 0.1),
        Offset.zero,
        Paint()
          ..color = _wallInk
          ..strokeWidth = 2,
      );
      canvas.drawPath(bell, Paint()..color = _wallInk);
      canvas.drawLine(
        const Offset(-19, 37),
        const Offset(19, 37),
        Paint()
          ..color = _rim
          ..strokeWidth = 1.4,
      );
      canvas.restore();
    }
  }
  // Tavandan sarkan zincirler ve düğümlü ipler (parallaks 0.45).
  const near = 0.45;
  final iron = Paint()
    ..color = const Color(0xFF241C1C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4;
  final ironLit = Paint()
    ..color = const Color(0x557A6A60)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final rope = Paint()
    ..color = const Color(0xFF2A1A12)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 3;
  const spacing = 380.0;
  final first = (cam.dx * near / spacing).floor() - 1;
  for (var i = first; i * spacing - cam.dx * near < w + spacing; i++) {
    final x = i * spacing - cam.dx * near + _hash(i, 11) * 160;
    final len = h * (0.25 + 0.3 * _hash(i, 12));
    final sway = math.sin(t * 0.7 + i) * 3;
    if (_hash(i, 13) < 0.5) {
      final links = (len / 11).floor();
      for (var k = 0; k < links; k++) {
        final y = k * 11.0;
        final xx = x + sway * y / len;
        final r = k.isEven
            ? Rect.fromCenter(center: Offset(xx, y), width: 6, height: 12)
            : Rect.fromCenter(center: Offset(xx, y), width: 2.4, height: 12);
        canvas.drawOval(r, iron);
        if (k.isEven) canvas.drawOval(r.deflate(1.2), ironLit);
      }
      canvas.drawCircle(Offset(x + sway, len + 9), 9, iron..strokeWidth = 3);
      canvas.drawCircle(Offset(x + sway, len + 9), 9, ironLit);
      iron.strokeWidth = 2.4;
    } else {
      final p = Path()..moveTo(x, 0);
      for (var k = 1; k <= 10; k++) {
        final y = len * k / 10;
        p.lineTo(x + sway * k / 10 + math.sin(k * 1.3 + i) * 2, y);
      }
      canvas.drawPath(p, rope);
      canvas.drawCircle(
        Offset(x + sway * 0.5, len * 0.5),
        3.4,
        Paint()..color = const Color(0xFF1E120C),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + sway, len + 7),
          width: 10,
          height: 14,
        ),
        rope..strokeWidth = 2.4,
      );
      rope.strokeWidth = 3;
    }
  }
}

/// Kule'nin bir arazi hücresi; çizdiyse true.
bool paintKuleTile(
  Canvas canvas,
  Level lv,
  int c,
  int r,
  double x,
  double y,
  math.Random rnd,
) {
  switch (lv.cell(c, r)) {
    case '#':
      _stone(canvas, lv, c, r, x, y, rnd);
      return true;
    case '=':
      _beam(canvas, lv, c, r, x, y, rnd);
      return true;
    case '|':
      _chain(canvas, x, y, r);
      return true;
  }
  return false;
}

/// Taş: mürekkep siluet, iri blok derzleri oyulmuş; üstü açıksa ince ılık
/// kenar ışığı, arada oyma bir süs (dört nokta) ışığı sızdırır.
void _stone(
  Canvas canvas,
  Level lv,
  int c,
  int r,
  double x,
  double y,
  math.Random rnd,
) {
  const t = kTile;
  canvas.drawRect(
    Rect.fromLTWH(x - 0.5, y - 0.5, t + 1, t + 1),
    Paint()..color = const Color(0xFF0A0706),
  );
  final joint = Paint()
    ..color = const Color(0xFF1E120C)
    ..strokeWidth = 1.1;
  // İri bloklar: her satır bir hücre boyu, iki satırda bir yarım kaydırma.
  if (r.isEven) canvas.drawLine(Offset(x, y), Offset(x + t, y), joint);
  if ((c + (r ~/ 2)).isEven) {
    canvas.drawLine(Offset(x, y), Offset(x, y + t), joint);
  }
  final top = r > 0 && !lv.solid(c, r - 1);
  if (top) {
    canvas.drawLine(
      Offset(x, y + 0.8),
      Offset(x + t, y + 0.8),
      Paint()
        ..color = const Color(0x8CE09A60)
        ..strokeWidth = 1.4,
    );
  }
  for (final side in [-1, 1]) {
    if (lv.solid(c + side, r)) continue;
    final ex = side < 0 ? x + 0.6 : x + t - 0.6;
    canvas.drawLine(
      Offset(ex, y),
      Offset(ex, y + t),
      Paint()
        ..color = const Color(0x40E09A60)
        ..strokeWidth = 1,
    );
  }
  if (rnd.nextDouble() < 0.12 && !top) {
    final p = Offset(x + t / 2, y + t / 2);
    final hole = Paint()..color = const Color(0x66E08850);
    for (final d in const [
      Offset(0, -4),
      Offset(4, 0),
      Offset(0, 4),
      Offset(-4, 0),
    ]) {
      canvas.drawCircle(p + d, 1.1, hole);
    }
  }
}

/// İnce basamak: mürekkep kiriş, üst kenarı ılık ışıklı, boyunca üçgen
/// oyma delikler; uçlarında duvara giren takoz silüeti.
void _beam(
  Canvas canvas,
  Level lv,
  int c,
  int r,
  double x,
  double y,
  math.Random rnd,
) {
  const t = kTile;
  final left = lv.cell(c - 1, r) != '=';
  final right = lv.cell(c + 1, r) != '=';
  final ink = Paint()..color = const Color(0xFF0A0706);
  final board = Rect.fromLTRB(
    x - (left ? 2 : 0.5),
    y,
    x + t + (right ? 2 : 0.5),
    y + 7,
  );
  canvas.drawRect(board, ink);
  canvas.drawLine(
    Offset(board.left + 1, y + 0.8),
    Offset(board.right - 1, y + 0.8),
    Paint()
      ..color = const Color(0x8CE09A60)
      ..strokeWidth = 1.3,
  );
  final hole = Paint()..color = const Color(0x59E08850);
  for (var k = 0; k < 3; k++) {
    final cx = x + 6 + k * 10.0;
    canvas.drawPath(
      Path()
        ..moveTo(cx - 2, y + 5)
        ..lineTo(cx + 2, y + 5)
        ..lineTo(cx, y + 2.6)
        ..close(),
      hole,
    );
  }
  for (final (open, ex, dir) in [
    (left, board.left, 1.0),
    (right, board.right, -1.0),
  ]) {
    if (!open) continue;
    final bx = ex + dir * 4;
    canvas.drawPath(
      Path()
        ..moveTo(bx, y + 7)
        ..lineTo(bx + dir * 9, y + 7)
        ..quadraticBezierTo(bx + dir * 4, y + 12, bx + dir * 2, y + 20)
        ..lineTo(bx, y + 20)
        ..close(),
      ink,
    );
  }
}

/// Tutunulan yer: demir zincir (halkaları sırayla dik ve yan).
void _chain(Canvas canvas, double x, double y, int r) {
  final cx = x + kTile / 2;
  final iron = Paint()
    ..color = const Color(0xFF2A2628)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;
  final lit = Paint()
    ..color = const Color(0x887E787C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.9;
  for (var k = 0; k < 4; k++) {
    final yy = y + 4 + k * 8.0;
    final front = (r * 4 + k).isEven;
    final o = Rect.fromCenter(
      center: Offset(cx, yy),
      width: front ? 6 : 2.2,
      height: 10.5,
    );
    canvas.drawOval(o, iron);
    if (front) canvas.drawOval(o.deflate(1.1), lit);
  }
}
