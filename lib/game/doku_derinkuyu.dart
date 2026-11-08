// Derinkuyu'nun renk ve doku katmanları (CARTOON açıkken): yumuşak tüfe
// oyulmuş yer altı şehri, kâğıt oyma katmanlarla. Uzakta kat kat oyulmuş
// odaların kapı ağızları ve basamaklar, ortada kemerli bir sıra ayak,
// kemerlerin dibinde yuvarlak sürgü taşları, ayaklarda kandil nişleri;
// yakında oyma tavan. Işık aşağıdan, közden gelir; karanlık korunur,
// bulanıklık yok.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'level.dart';

double _hash(int i, [int salt = 0]) {
  final v = math.sin(i * 127.1 + salt * 311.7) * 43758.5453;
  return v - v.floorToDouble();
}

const _ember = Color(0xFFFFB070);
const _flame = Color(0xFFFFC27A);
final _drop = Paint()..color = const Color(0x59000000);

/// [cam]: kameranın dünya konumu; [t]: kandillerin titremesi için zaman.
void paintDerinkuyuBackdrop(
  Canvas c,
  double w,
  double h,
  double camX,
  double camY,
  double t,
) {
  final dy = -camY * 0.05;
  _farWall(c, w, h, camX * 0.08, dy, t);
  _arcade(c, w, h, camX * 0.2, dy, t);
  _ceiling(c, w, h, camX * 0.35, dy);
}

/// Uzak duvar: kat kat oyulmuş odaların karanlık kapı ağızları, aralarında
/// oyma basamaklar; bazı odalarda kandil.
void _farWall(Canvas c, double w, double h, double off, double dy, double t) {
  c.drawRect(
    Rect.fromLTWH(0, 0, w, h),
    Paint()
      ..shader = Gradient.linear(
        Offset(0, h * 0.1),
        Offset(0, h),
        const [Color(0xFF1A0D08), Color(0xFF3E1E14), Color(0xFF6A301C)],
        const [0, 0.55, 1],
      ),
  );
  // Tüfün yumuşak kuşakları.
  final band = Paint()..color = const Color(0xFF000000).withValues(alpha: 0.12);
  for (var k = 0; k < 5; k++) {
    final y0 = h * (0.2 + k * 0.17) + dy;
    final p = Path()..moveTo(0, y0);
    for (var x = 0.0; x <= w + 20; x += 20) {
      p.lineTo(x, y0 + math.sin((x + off) * 0.012 + k * 2) * 6);
    }
    for (var x = w + 20; x >= 0; x -= 20) {
      p.lineTo(x, y0 + 14 + math.sin((x + off) * 0.017 + k) * 5);
    }
    p.close();
    c.drawPath(p, band);
  }
  const cw = 150.0;
  final hole = Paint()..color = const Color(0xFF0B0504);
  final lip = Paint()
    ..color = _ember.withValues(alpha: 0.3)
    ..strokeWidth = 1.2;
  final step = Paint()..color = const Color(0xFF1A0C08);
  for (var i = ((off - cw) / cw).floor(); i * cw - off < w + cw; i++) {
    final x0 = i * cw - off;
    for (var row = 0; row < 2; row++) {
      if (_hash(i, row) < 0.25) continue;
      final aw = 18 + _hash(i, row + 4) * 16;
      final ah = aw * 1.55;
      final ax = x0 + 20 + _hash(i, row + 8) * (cw - 60);
      final ab = h * (0.42 + row * 0.27) + dy;
      final r = Rect.fromLTWH(ax, ab - ah, aw, ah);
      c.drawRRect(
        RRect.fromRectAndCorners(
          r,
          topLeft: Radius.circular(aw / 2),
          topRight: Radius.circular(aw / 2),
        ),
        hole,
      );
      c.drawLine(Offset(r.left - 2, ab), Offset(r.right + 2, ab), lip);
      if (_hash(i, row + 12) < 0.2) {
        final f = 0.8 + 0.2 * math.sin(t * 7 + i * 3.1 + row);
        final lc = Offset(r.center.dx, ab - 4);
        c.drawCircle(
          lc,
          aw * 0.5,
          Paint()..color = _flame.withValues(alpha: 0.1 * f),
        );
        c.drawCircle(
          lc,
          1.6,
          Paint()..color = _flame.withValues(alpha: 0.85 * f),
        );
      }
      // Oyma basamaklar: üst sıradaki kapıdan aşağı inen merdiven.
      if (row == 0 && _hash(i, 20) < 0.4) {
        final dir = _hash(i, 21) < 0.5 ? -1.0 : 1.0;
        final sp = Path()..moveTo(r.center.dx, ab);
        var sx = r.center.dx;
        var sy = ab;
        for (var s = 0; s < 8; s++) {
          sx += dir * 7;
          sp.lineTo(sx, sy);
          sy += 6;
          sp.lineTo(sx, sy);
        }
        sp
          ..lineTo(sx, sy + 4)
          ..lineTo(r.center.dx, ab + 4)
          ..close();
        c.drawPath(sp, step);
      }
    }
  }
}

/// Orta katman: kemerli ayaklar sırası. Kemerlerin içi uzak duvara açılır;
/// ayaklarda keski izleri ve kandil nişleri, bazı kemerlerin dibinde
/// yuvarlak sürgü taşı.
void _arcade(Canvas c, double w, double h, double off, double dy, double t) {
  const cw = 260.0;
  const body = Color(0xFF1E0F0A);
  final top = h * 0.16 + dy;
  final mass = Path()..fillType = PathFillType.evenOdd;
  final rims = Path();
  final doors = <(Offset, double, int)>[];
  final niches = <(Offset, int)>[];
  for (var i = ((off - cw) / cw).floor(); i * cw - off < w + cw; i++) {
    final x0 = i * cw - off;
    mass.addRect(Rect.fromLTRB(x0 - 0.5, top, x0 + cw + 0.5, h));
    final pier = 50 + _hash(i, 1) * 30;
    final ax = x0 + pier;
    final aw = cw - pier;
    final spring = top + h * (0.2 + _hash(i, 2) * 0.08);
    final arch = Path()
      ..moveTo(ax, h + 2)
      ..lineTo(ax, spring)
      ..arcToPoint(Offset(ax + aw, spring), radius: Radius.circular(aw / 2))
      ..lineTo(ax + aw, h + 2)
      ..close();
    mass.addPath(arch, Offset.zero);
    rims
      ..moveTo(ax, h * 0.92)
      ..lineTo(ax, spring)
      ..arcToPoint(Offset(ax + aw, spring), radius: Radius.circular(aw / 2));
    if (_hash(i, 3) < 0.35) {
      doors.add((Offset(ax + aw * 0.18, h * 0.9 + dy * 0.5), aw * 0.26, i));
    }
    if (_hash(i, 4) < 0.45) {
      niches.add((Offset(x0 + pier / 2, top + h * 0.34), i));
    }
  }
  c.save();
  c.translate(3, 4);
  c.drawPath(mass, _drop);
  c.restore();
  c.drawPath(mass, Paint()..color = body);
  // Ayakların keski izleri (kemer boşluğuna taşmasın): küçük bir desen
  // resmi duvar şekline boyanır. Eskiden binlerce çizgi her karede kemerli
  // şekille kırpılarak çiziliyordu; Skia'da kare bir buçuk saniyeye
  // çıkıyordu.
  c.drawPath(
    mass,
    Paint()
      ..filterQuality = FilterQuality.low
      ..shader = ImageShader(
        _chiselTile(),
        TileMode.repeated,
        TileMode.repeated,
        Float64List.fromList([
          1,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          1,
          0,
          -off,
          top - 1,
          0,
          1,
        ]),
      ),
  );
  // Közün ışığı ayakların dibine vurur.
  c.drawPath(
    mass,
    Paint()
      ..shader = Gradient.linear(Offset(0, h * 0.6), Offset(0, h), [
        const Color(0x00000000),
        _ember.withValues(alpha: 0.12),
      ]),
  );
  c.drawPath(
    rims,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _ember.withValues(alpha: 0.4),
  );
  // Kandil nişleri.
  for (final (p, i) in niches) {
    final r = Rect.fromCenter(center: p, width: 14, height: 20);
    c.drawRRect(
      RRect.fromRectAndCorners(
        r,
        topLeft: const Radius.circular(7),
        topRight: const Radius.circular(7),
      ),
      Paint()..color = const Color(0xFF0A0504),
    );
    final f = 0.85 + 0.15 * math.sin(t * 9 + i * 2.3) * math.sin(t * 3.7 + i);
    c.drawCircle(
      Offset(p.dx, p.dy + 4),
      16,
      Paint()..color = _flame.withValues(alpha: 0.09 * f),
    );
    // Kandil ve alevi.
    c.drawOval(
      Rect.fromCenter(center: Offset(p.dx, p.dy + 8), width: 8, height: 3),
      Paint()..color = const Color(0xFF3A2216),
    );
    final fl = Path()
      ..moveTo(p.dx, p.dy + 7)
      ..quadraticBezierTo(p.dx - 2.4, p.dy + 4, p.dx, p.dy + 1 - 1.5 * f)
      ..quadraticBezierTo(p.dx + 2.4, p.dy + 4, p.dx, p.dy + 7)
      ..close();
    c.drawPath(fl, Paint()..color = _flame.withValues(alpha: 0.9));
    c.drawLine(
      Offset(r.left - 1, r.bottom),
      Offset(r.right + 1, r.bottom),
      Paint()
        ..color = _ember.withValues(alpha: 0.35)
        ..strokeWidth = 1.2,
    );
  }
  // Sürgü taşları: kemerin dibine yaslı, ortası delik iri taş tekerlek.
  for (final (p, r, i) in doors) {
    final ctr = Offset(p.dx, p.dy - r);
    c.drawCircle(ctr + const Offset(3, 4), r, _drop);
    c.drawCircle(ctr, r, Paint()..color = const Color(0xFF26140D));
    c.drawCircle(
      ctr,
      r * 0.72,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF120906),
    );
    c.drawCircle(ctr, r * 0.16, Paint()..color = const Color(0xFF0A0504));
    c.drawArc(
      Rect.fromCircle(center: ctr, radius: r - 0.8),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _ember.withValues(alpha: 0.35),
    );
    // Kırık kenar.
    if (_hash(i, 9) < 0.5) {
      c.drawPath(
        Path()
          ..moveTo(ctr.dx + r * 0.6, ctr.dy - r * 0.8)
          ..lineTo(ctr.dx + r * 0.9, ctr.dy - r * 0.2)
          ..lineTo(ctr.dx + r * 1.05, ctr.dy - r * 0.55)
          ..close(),
        Paint()..color = const Color(0xFF1E0F0A),
      );
    }
  }
}

/// Yakın katman: oyma tavan, basamak basamak kesilmiş alt kenarı közün
/// ışığını yakalar.
void _ceiling(Canvas c, double w, double h, double off, double dy) {
  const cw = 120.0;
  final p = Path()..moveTo(-10, 0);
  final edge = Path();
  var first = true;
  for (var i = ((off - cw) / cw).floor(); i * cw - off < w + cw; i++) {
    final x0 = i * cw - off;
    final y = h * (0.07 + _hash(i, 31) * 0.06) + dy;
    final mid = x0 + cw * (0.3 + _hash(i, 32) * 0.4);
    final y2 = y + (_hash(i, 33) - 0.5) * 16;
    for (final pt in [
      Offset(x0, y),
      Offset(mid, y),
      Offset(mid + 4, y2),
      Offset(x0 + cw, y2),
    ]) {
      p.lineTo(pt.dx, pt.dy);
      if (first) {
        edge.moveTo(pt.dx, pt.dy);
        first = false;
      } else {
        edge.lineTo(pt.dx, pt.dy);
      }
    }
  }
  p
    ..lineTo(w + 10, 0)
    ..close();
  c.save();
  c.translate(3, 4);
  c.drawPath(p, _drop);
  c.restore();
  c.drawPath(p, Paint()..color = const Color(0xFF110806));
  c.drawPath(
    edge,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = _ember.withValues(alpha: 0.22),
  );
}

/// Zemin: tüfe vurulmuş keski izleri (sıra sıra kısa oyuklar, dünyada
/// süren), yüzeye yakın sıcak tüf rengi, üstte aşınmış taban dudağı;
/// tavan karolarının alt kenarı közün ışığını alır.
void paintDerinkuyuTile(
  Canvas c,
  Level lv,
  int col,
  int row,
  double x,
  double y,
) {
  const t = kTile;
  var depth = 0;
  while (depth < 3 && row - depth - 1 >= 0 && lv.solid(col, row - depth - 1)) {
    depth++;
  }
  var below = 0;
  while (below < 3 &&
      row + below + 1 < lv.height &&
      lv.solid(col, row + below + 1)) {
    below++;
  }
  final near = math.min(depth, below);
  final top = row > 0 && !lv.solid(col, row - 1);
  final bottom = row + 1 < lv.height && !lv.solid(col, row + 1);
  final left = !lv.solid(col - 1, row);
  final right = !lv.solid(col + 1, row);
  final tile = Rect.fromLTWH(x, y, t, t);
  if (near < 3) {
    final a = 1 - near / 3;
    c.save();
    c.clipRect(tile);
    c.drawRect(
      tile,
      Paint()..color = const Color(0xFF2A160E).withValues(alpha: 0.65 * a),
    );
    // Keski izleri: yarım ay oyuklar, sıra sıra kaydırılmış (elle oyulmuş
    // tüf), dünyada süren.
    final mark = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFF0E0705).withValues(alpha: 0.7 * a);
    final glint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = _ember.withValues(alpha: 0.12 * a);
    const gy = 8.0;
    const gx = 10.0;
    for (var n = (y / gy).floor(); n * gy < y + t + gy; n++) {
      final shift = (n.isEven ? 0.0 : gx / 2);
      for (
        var m = ((x - shift) / gx).floor() - 1;
        m * gx + shift < x + t + gx;
        m++
      ) {
        final mx = m * gx + shift;
        final my = n * gy;
        if (_hash(m * 31 + n, 5) < 0.25) continue;
        final r = Rect.fromCenter(center: Offset(mx, my), width: 8, height: 6);
        c.drawArc(r, 0.2, math.pi - 0.4, false, mark);
        c.drawArc(
          r.shift(const Offset(0, 1.2)),
          0.4,
          math.pi - 0.8,
          false,
          glint,
        );
      }
    }
    c.restore();
  }
  if (left) {
    c.drawLine(
      Offset(x + 0.7, y + (top ? 5 : 0)),
      Offset(x + 0.7, y + t),
      Paint()
        ..color = _ember.withValues(alpha: 0.16)
        ..strokeWidth = 1.1,
    );
  }
  if (bottom) {
    // Tavanın alt kenarı aşağıdaki közü yakalar.
    c.drawLine(
      Offset(x, y + t - 0.8),
      Offset(x + t, y + t - 0.8),
      Paint()
        ..color = _ember.withValues(alpha: 0.22)
        ..strokeWidth = 1.2,
    );
  }
  if (!top) return;
  // Aşınmış taban dudağı: ayak basa basa yuvarlanmış açık tüf.
  double lower(double wx) =>
      y + 4 + math.sin(wx * 0.21) * 1.0 + math.sin(wx * 0.08 + 1) * 0.9;
  double upper(double wx) => y - 0.8 - math.max(0, math.sin(wx * 0.06)) * 1.2;
  final x0 = left ? x - 1 : x - 0.5;
  final x1 = right ? x + t + 1 : x + t + 0.5;
  final lip = Path()..moveTo(x0, upper(x0));
  for (var wx = x0; wx <= x1; wx += 2) {
    lip.lineTo(wx, upper(wx));
  }
  lip.lineTo(x1, upper(x1));
  if (right) lip.quadraticBezierTo(x1 + 1, y + 2, x1 - 1, y + 5);
  for (var wx = x1 - 1; wx >= x0; wx -= 2) {
    lip.lineTo(wx, lower(wx));
  }
  if (left) lip.quadraticBezierTo(x0 - 1, y + 2, x0, upper(x0));
  lip.close();
  c.drawPath(lip, Paint()..color = const Color(0xFF4A2A1C));
  final rim = Path()..moveTo(x0, upper(x0));
  for (var wx = x0; wx <= x1; wx += 2) {
    rim.lineTo(wx, upper(wx));
  }
  c.drawPath(
    rim,
    Paint()
      ..color = _ember.withValues(alpha: 0.42)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke,
  );
}

/// Keski izi deseni: 11 piksel aralıklı dokuz sıra, her sıra bir öncekinden
/// 4 piksel kaymış kısa eğik çizgiler (eski çizimin aynısı).
Image? _chisel;
Image _chiselTile() => _chisel ??= () {
  final rec = PictureRecorder();
  final c = Canvas(rec);
  final p = Paint()
    ..color = const Color(0xFF331A11)
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;
  for (var r = 0; r < 9; r++) {
    final y = r * 11.0;
    final x0 = -((r * 4) % 9).toDouble();
    for (var x = x0 - 9; x < 18; x += 9) {
      c.drawLine(Offset(x, y), Offset(x + 3, y + 4), p);
    }
  }
  return rec.endRecording().toImageSync(9, 99);
}();
