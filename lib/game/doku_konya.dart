// Konya'nın renk ve doku katmanları (CARTOON açıkken): Kule ve kar
// bölümlerindeki kâğıt oyma dil. Karlı gecede üç kat şehir: uzakta düz
// damlı evler, ortada çıkmalı evler, önde kasnaklı kubbeli camiler ve
// şerefeli minareler. Ay sağda: kubbelerin, minarelerin ve damların sağ
// kenarı ay ışığını yakalar; damlarda ve kubbelerde kar, pencerelerde mum.
// Gece paleti korunur; bulanıklık yok.
import 'dart:math' as math;
import 'dart:ui';

import 'doku_kar.dart' show paintSnowBlanket;
import 'level.dart';

const _moonRim = Color(0xFF9AACD0);
const _snow = Color(0xFF6A7894);
const _candle = Color(0xFFFFC27A);
final _drop = Paint()..color = const Color(0x4D000000);

void _repeat(
  double w,
  double off,
  double spacing,
  int salt,
  void Function(double x, math.Random r) draw,
) {
  for (
    var i = ((off - spacing) / spacing).floor();
    i * spacing - off < w + spacing;
    i++
  ) {
    draw(i * spacing - off, math.Random(i * 92821 + salt));
  }
}

/// [base]: ufuk çizgisi (ekranda); [camX]: kameranın dünya x'i.
void paintKonyaCity(Canvas c, double w, double h, double base, double camX) {
  // Uzak evler: alçak, sık, düz damlı; damlarında ince kar.
  _repeat(w, camX * 0.04, 70, 11, (x, r) {
    final hh = 10 + r.nextDouble() * 14;
    final ww = 40 + r.nextDouble() * 34;
    _house(c, x, base + 6, ww, hh, const Color(0xFF1A2236), r, far: true);
  });
  // Ortadaki evler: iki katlı, çıkmalı, kiremit yerine düz kar damlı.
  _repeat(w, camX * 0.07, 130, 7, (x, r) {
    final hh = 20 + r.nextDouble() * 24;
    final ww = 50 + r.nextDouble() * 46;
    _house(c, x, base + 14, ww, hh, const Color(0xFF111728), r);
  });
  // Önde camiler.
  _repeat(w, camX * 0.1, 360, 2, (x, r) {
    _mosque(c, x, base + 10, 40 + r.nextDouble() * 30, r);
  });
}

void _house(
  Canvas c,
  double x,
  double base,
  double ww,
  double hh,
  Color body,
  math.Random r, {
  bool far = false,
}) {
  final rect = Rect.fromLTWH(x, base - hh, ww, hh + 30);
  final bay = !far && r.nextDouble() < 0.5;
  final bayR = Rect.fromLTWH(
    x + ww * (0.2 + r.nextDouble() * 0.3),
    base - hh - 2,
    ww * 0.4,
    hh * 0.42,
  );
  c.drawRect(rect.shift(const Offset(3, 4)), _drop);
  c.drawRect(rect, Paint()..color = body);
  if (bay) {
    // Ahşap çıkma: üst kat dışarı taşar, altında eğik payandalar.
    c.drawRect(bayR.inflate(3), Paint()..color = body);
    final strut = Paint()
      ..color = body
      ..strokeWidth = 2;
    c.drawLine(
      Offset(bayR.left - 2, bayR.bottom + 3),
      Offset(bayR.left + 5, bayR.bottom + 10),
      strut,
    );
    c.drawLine(
      Offset(bayR.right + 2, bayR.bottom + 3),
      Offset(bayR.right - 5, bayR.bottom + 10),
      strut,
    );
  }
  // Pencereler: kemerli, bazılarında mum.
  final n = (ww / 16).floor();
  for (var k = 0; k < n; k++) {
    final lit = r.nextDouble() < (far ? 0.25 : 0.35);
    final wx = x + 6 + k * (ww - 10) / n;
    final wy = base - hh + (far ? 4 : 8);
    final wr = RRect.fromRectAndCorners(
      Rect.fromLTWH(wx, wy, far ? 3 : 4, far ? 4 : 7),
      topLeft: const Radius.circular(2),
      topRight: const Radius.circular(2),
    );
    c.drawRRect(
      wr,
      Paint()
        ..color = lit
            ? _candle.withValues(alpha: far ? 0.5 : 0.75)
            : const Color(0xFF070A12),
    );
  }
  // Damda kar ve ay ışığı alan sağ kenar.
  final top = bay ? math.min(rect.top, bayR.top - 3) : rect.top;
  final snow = Path()
    ..moveTo(x - 2, rect.top + 1)
    ..lineTo(x - 1, rect.top - 2.5);
  for (var sx = x; sx <= x + ww; sx += 4) {
    snow.lineTo(sx, rect.top - 2.5 - math.sin(sx * 0.2) * 0.8);
  }
  snow
    ..lineTo(x + ww + 2, rect.top + 1)
    ..close();
  c.drawPath(snow, Paint()..color = far ? _snow.withValues(alpha: 0.6) : _snow);
  if (bay) {
    c.drawRect(
      Rect.fromLTWH(bayR.left - 4, bayR.top - 6, bayR.width + 8, 3),
      Paint()..color = _snow,
    );
  }
  c.drawLine(
    Offset(x + ww - 0.6, top),
    Offset(x + ww - 0.6, base),
    Paint()
      ..color = _moonRim.withValues(alpha: far ? 0.2 : 0.3)
      ..strokeWidth = 1,
  );
  // Baca ve dumanı.
  if (!far && r.nextDouble() < 0.5) {
    final cx = x + ww * (0.15 + r.nextDouble() * 0.6);
    c.drawRect(Rect.fromLTWH(cx, rect.top - 9, 5, 9), Paint()..color = body);
    c.drawRect(
      Rect.fromLTWH(cx - 1, rect.top - 11, 7, 2.5),
      Paint()..color = _snow,
    );
  }
}

/// Kasnaklı kubbe, yan yarım kubbeler, revak, iki şerefeli minare.
void _mosque(Canvas c, double x, double base, double rr, math.Random r) {
  const body = Color(0xFF0C1020);
  final fill = Paint()..color = body;
  final rim = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..color = _moonRim.withValues(alpha: 0.5);
  final drumH = rr * 0.35;
  final hallTop = base - rr * 0.85;
  final shape = Path()
    // Harim (gövde) ve revak.
    ..addRect(Rect.fromLTRB(x - rr * 1.25, hallTop, x + rr * 1.25, base + 30))
    // Kasnak.
    ..addRect(
      Rect.fromLTRB(x - rr * 0.82, hallTop - drumH, x + rr * 0.82, hallTop + 1),
    )
    // Ana kubbe.
    ..addArc(
      Rect.fromCircle(center: Offset(x, hallTop - drumH), radius: rr * 0.82),
      math.pi,
      math.pi,
    );
  // Yan yarım kubbeler.
  for (final s in [-1.0, 1.0]) {
    shape.addArc(
      Rect.fromCircle(
        center: Offset(x + s * rr * 0.9, hallTop),
        radius: rr * 0.34,
      ),
      math.pi,
      math.pi,
    );
  }
  // Minareler: kaide, gövde, şerefe, üst gövde, külah.
  final mins = <(double, double)>[];
  for (final s in [-1.0, 1.0]) {
    final mx = x + s * (rr * 1.25 + 14);
    final mh = rr * 3.4 * (0.95 + r.nextDouble() * 0.1);
    mins.add((mx, mh));
    shape
      ..addRect(Rect.fromLTRB(mx - 6, base - mh * 0.18, mx + 6, base + 30))
      ..addPath(
        Path()
          ..moveTo(mx - 5, base - mh * 0.18)
          ..lineTo(mx - 4, base - mh * 0.92)
          ..lineTo(mx + 4, base - mh * 0.92)
          ..lineTo(mx + 5, base - mh * 0.18)
          ..close(),
        Offset.zero,
      )
      ..addRect(
        Rect.fromLTRB(mx - 8.5, base - mh * 0.7 - 3, mx + 8.5, base - mh * 0.7),
      )
      ..addPath(
        Path()
          ..moveTo(mx - 5, base - mh * 0.92)
          ..lineTo(mx, base - mh - rr * 0.5)
          ..lineTo(mx + 5, base - mh * 0.92)
          ..close(),
        Offset.zero,
      );
  }
  c.save();
  c.translate(3, 4);
  c.drawPath(shape, _drop);
  c.restore();
  c.drawPath(shape, fill);
  // Kar: ana kubbenin tepesinde, yarım kubbelerde, harim damında, şerefede
  // ve külahların dibinde.
  final snow = Paint()..color = _snow;
  final dc = Offset(x, hallTop - drumH);
  c.drawArc(
    Rect.fromCircle(center: dc, radius: rr * 0.82 + 1),
    math.pi * 1.22,
    math.pi * 0.56,
    true,
    snow,
  );
  c.drawArc(
    Rect.fromCircle(center: dc, radius: rr * 0.82 - 3.5),
    math.pi * 1.2,
    math.pi * 0.6,
    true,
    fill,
  );
  for (final s in [-1.0, 1.0]) {
    c.drawArc(
      Rect.fromCircle(
        center: Offset(x + s * rr * 0.9, hallTop),
        radius: rr * 0.34 + 1,
      ),
      math.pi * 1.25,
      math.pi * 0.5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = _snow,
    );
  }
  c.drawRect(
    Rect.fromLTWH(x - rr * 1.25 - 1.5, hallTop - 2.5, rr * 2.5 + 3, 2.5),
    snow,
  );
  // Ay ışığı: kubbelerin sağ omzu, gövdenin ve minarelerin sağ kenarı.
  c.drawArc(
    Rect.fromCircle(center: dc, radius: rr * 0.82),
    math.pi * 1.62,
    math.pi * 0.38,
    false,
    rim,
  );
  c.drawLine(
    Offset(x + rr * 1.25 - 0.7, hallTop),
    Offset(x + rr * 1.25 - 0.7, base),
    rim,
  );
  final window = Paint()..color = _candle.withValues(alpha: 0.75);
  final dim = Paint()..color = const Color(0xFF060810);
  for (final (mx, mh) in mins) {
    c.drawLine(
      Offset(mx + 4.2, base - mh * 0.9),
      Offset(mx + 5.2, base - mh * 0.2),
      rim,
    );
    c.drawRect(
      Rect.fromLTRB(
        mx - 9.5,
        base - mh * 0.7 - 5,
        mx + 9.5,
        base - mh * 0.7 - 3,
      ),
      snow,
    );
    c.drawRect(
      Rect.fromLTRB(
        mx - 5.5,
        base - mh * 0.92 - 1.5,
        mx + 5.5,
        base - mh * 0.92,
      ),
      snow,
    );
    // Alem.
    c.drawLine(
      Offset(mx, base - mh - rr * 0.5),
      Offset(mx, base - mh - rr * 0.5 - 7),
      Paint()
        ..color = const Color(0xFFB8A060)
        ..strokeWidth = 1.4,
    );
    // Şerefede kandil.
    if (r.nextDouble() < 0.6) {
      c.drawCircle(Offset(mx, base - mh * 0.7 - 6), 1.5, window);
    }
  }
  // Ana kubbenin alemi.
  c.drawLine(
    Offset(x, dc.dy - rr * 0.82),
    Offset(x, dc.dy - rr * 0.82 - 12),
    Paint()
      ..color = const Color(0xFFB8A060)
      ..strokeWidth = 1.8,
  );
  // Kasnak pencereleri ve revak kemerleri.
  for (var k = -2; k <= 2; k++) {
    final wx = x + k * rr * 0.28;
    final on = r.nextDouble() < 0.6;
    c.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(wx - 2, hallTop - drumH * 0.75, 4, drumH * 0.5),
        topLeft: const Radius.circular(2),
        topRight: const Radius.circular(2),
      ),
      on ? window : dim,
    );
  }
  final arches = 5;
  for (var k = 0; k < arches; k++) {
    final ax = x - rr * 1.05 + k * rr * 2.1 / (arches - 1);
    final aw = rr * 0.3;
    final on = r.nextDouble() < 0.45;
    c.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(ax - aw / 2, base - rr * 0.45, aw, rr * 0.45 + 2),
        topLeft: Radius.circular(aw / 2),
        topRight: Radius.circular(aw / 2),
      ),
      on ? (Paint()..color = _candle.withValues(alpha: 0.55)) : dim,
    );
  }
}

/// Zemin: Selçuklu kesme taşı. Dünyada süren sıra sıra bloklar (her sıra
/// yarım kaydırılmış), derz çizgileri ve ay ışığı alan sağ kenarlar;
/// yüzeye yakın renk, derinde mürekkep. Üstü açıksa kalın kar örtüsü.
void paintKonyaTile(Canvas c, Level lv, int col, int row, double x, double y) {
  const t = kTile;
  var depth = 0;
  while (depth < 3 && row - depth - 1 >= 0 && lv.solid(col, row - depth - 1)) {
    depth++;
  }
  final top = row > 0 && !lv.solid(col, row - 1);
  final right = !lv.solid(col + 1, row);
  if (depth < 3) {
    final a = 1 - depth / 3;
    final tile = Rect.fromLTWH(x, y, t, t);
    c.save();
    c.clipRect(tile);
    c.drawRect(
      tile,
      Paint()..color = const Color(0xFF1A2032).withValues(alpha: 0.7 * a),
    );
    final joint = Paint()
      ..color = const Color(0xFF05070C).withValues(alpha: 0.8 * a)
      ..strokeWidth = 1.2;
    final lit = Paint()
      ..color = _moonRim.withValues(alpha: 0.12 * a)
      ..strokeWidth = 1;
    const bh = 16.0;
    const bw = 40.0;
    for (var n = (y / bh).floor(); n * bh < y + t; n++) {
      final yy = n * bh;
      c.drawLine(Offset(x, yy), Offset(x + t, yy), joint);
      c.drawLine(Offset(x, yy + 1.2), Offset(x + t, yy + 1.2), lit);
      final shift = n.isEven ? 0.0 : bw / 2;
      for (var m = ((x - shift) / bw).floor(); m * bw + shift < x + t; m++) {
        final jx = m * bw + shift;
        if (jx < x) continue;
        c.drawLine(Offset(jx, yy), Offset(jx, yy + bh), joint);
        c.drawLine(Offset(jx - 1.2, yy + 1), Offset(jx - 1.2, yy + bh), lit);
      }
    }
    c.restore();
  }
  if (right) {
    c.drawLine(
      Offset(x + t - 0.7, y + (top ? 5 : 0)),
      Offset(x + t - 0.7, y + t),
      Paint()
        ..color = _moonRim.withValues(alpha: 0.2)
        ..strokeWidth = 1,
    );
  }
  if (top) paintSnowBlanket(c, lv, col, row, x, y);
}
