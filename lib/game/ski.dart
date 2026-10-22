import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'golge_game.dart';
import 'level.dart';
import 'palette.dart';
import 'player.dart';
import 'ski_light.dart';

/// Kayak bölümlerinin pürüzsüz kar yamacı. Yükseklikler sütun başına (kare
/// cinsinden) verilir; aralar doğrusal birleştirilir. Negatif yükseklik
/// uçurumdur.
class SkiSurface {
  SkiSurface(this.rows);

  final List<double> rows;

  /// x'teki zemin yüksekliği (piksel), uçurumsa null. Sütun yükseklikleri
  /// arası Catmull-Rom eğrisiyle birleşir: yamaç köşesiz, yuvarlak akar.
  double? at(double x) {
    final f = x / kTile - 0.5;
    final i = f.floor();
    if (i < 0) return rows.first < 0 ? null : rows.first * kTile;
    // Pistin sonunun ötesi boşluk: harita dışında sonsuz yamaç uzamasın.
    if (i + 1 >= rows.length) return null;
    final a = rows[i];
    final b = rows[i + 1];
    if (a < 0 || b < 0) return null;
    final t = f - i;
    // Komşu yoksa (uçurum kenarı, pist başı) doğru çizgiyle uzatılır.
    final p0 = i > 0 && rows[i - 1] >= 0 ? rows[i - 1] : 2 * a - b;
    final p3 = i + 2 < rows.length && rows[i + 2] >= 0
        ? rows[i + 2]
        : 2 * b - a;
    final t2 = t * t;
    final t3 = t2 * t;
    final v =
        0.5 *
        (2 * a +
            (-p0 + b) * t +
            (2 * p0 - 5 * a + 4 * b - p3) * t2 +
            (-p0 + 3 * a - 3 * b + p3) * t3);
    return v * kTile;
  }

  /// x'teki eğim açısı (aşağı inen yokuş artı).
  double slope(double x) {
    final y0 = at(x - 6);
    final y1 = at(x + 6);
    if (y0 != null && y1 != null) return math.atan2(y1 - y0, 12);
    // Uçurum kenarında tek yönlü: rampanın açısı kenara dek korunur
    // (havalanış kare hızından bağımsız olsun).
    final y = at(x);
    if (y == null) return 0;
    if (y0 != null) return math.atan2(y - y0, 6);
    if (y1 != null) return math.atan2(y1 - y, 6);
    return 0;
  }
}

/// Karlı yamacın çizimi: arkada puslu çamlar, kalın kar örtüsü (üstü ışığı
/// yakalar, içine doğru gölgelenir, derinde koyulaşır), kenarında parıltılar
/// ve kayakların bıraktığı iz. Renkler günün ışığından gelir (SkiLight).
class SkiTerrain extends Component with HasGameReference<GolgeGame> {
  SkiTerrain(this.surface) : super(priority: 1);

  final SkiSurface surface;
  double _t = 0;

  /// Kayakların izi: yere değdiği yerler (dünya x'i), sıralı.
  final _track = <double>[];

  @override
  void update(double dt) {
    _t += dt;
    final p = game.player;
    if (p == null || p.isDead || !p.onGround) return;
    final x = p.center.x;
    if (_track.isEmpty || (x - _track.last).abs() > 6) {
      if (_track.isNotEmpty && x < _track.last) _track.clear();
      _track.add(x);
      if (_track.length > 1200) _track.removeRange(0, 200);
    }
  }

  @override
  void render(Canvas canvas) {
    final lt = game.skiLight;
    final view = game.camera.visibleWorldRect.inflate(80);
    final c0 = math.max(0, (view.left / kTile).floor() - 1);
    final c1 = math.min(
      surface.rows.length - 1,
      (view.right / kTile).ceil() + 1,
    );
    final bottom = view.bottom + 200;
    _pines(canvas, c0, c1, lt);
    // Uçurumların içi: dipsiz, koyu bir yarık. Üstü iki kenarı birleştiren
    // eğik çizgiden başlar ve yavaşça koyulaşır (düz bir kutu gibi gökyüzünün
    // önüne çıkıp arkadaki dağları kesmesin).
    for (var g = c0; g <= c1; g++) {
      if (surface.rows[g] >= 0 || (g > 0 && surface.rows[g - 1] < 0)) continue;
      var e = g;
      while (e < surface.rows.length && surface.rows[e] < 0) {
        e++;
      }
      final yl = (g > 0 ? surface.rows[g - 1] : surface.rows[e]) * kTile;
      final yr =
          (e < surface.rows.length ? surface.rows[e] : surface.rows[g - 1]) *
          kTile;
      final x0 = g * kTile - 2.0;
      final x1 = e * kTile + 2.0;
      final top = math.max(yl, yr) + 40;
      final path = Path()
        ..moveTo(x0, yl + 40)
        ..lineTo(x1, yr + 40)
        ..lineTo(x1, bottom)
        ..lineTo(x0, bottom)
        ..close();
      final deep = Color.lerp(lt.deep, const Color(0xFF000000), 0.6)!;
      canvas.drawPath(
        path,
        Paint()
          ..shader = Gradient.linear(
            Offset(0, math.min(yl, yr) + 40),
            Offset(0, top + 260),
            [deep.withValues(alpha: 0), deep.withValues(alpha: 0.75), deep],
            const [0, 0.55, 1],
          ),
      );
    }
    var c = c0;
    while (c <= c1) {
      if (surface.rows[c] < 0) {
        c++;
        continue;
      }
      final start = c;
      while (c <= c1 && surface.rows[c] >= 0) {
        c++;
      }
      // Kesintisiz parça: [start, c) sütunları; kenarlar sütun kenarında.
      final x0 = start * kTile.toDouble();
      final x1 = c * kTile.toDouble();
      final top = <Offset>[];
      for (var x = x0; x <= x1 + 0.1; x += 8) {
        final cx = x.clamp(x0 + kTile / 2, x1 - kTile / 2);
        final col = (cx / kTile - 0.5).round().clamp(start, c - 1);
        final y = surface.at(cx) ?? surface.rows[col] * kTile;
        top.add(Offset(x, y));
      }
      // Uçurum kenarlarında kaya yüzü ve sarkan kar saçağı.
      _snowBody(canvas, top, bottom, lt);
      if (start > 0 && surface.rows[start - 1] < 0) {
        _cliff(canvas, top.first, bottom, lt, -1);
      }
      if (c < surface.rows.length && surface.rows[c] < 0) {
        _cliff(canvas, top.last, bottom, lt, 1);
      }
      if (start > 0 && surface.rows[start - 1] < 0) {
        _cornice(canvas, top.first, lt, -1);
      }
      if (c < surface.rows.length && surface.rows[c] < 0) {
        _cornice(canvas, top.last, lt, 1);
      }
    }
    _drawTrack(canvas, lt);
  }

  /// Kar gövdesi: üstten derine katmanlar.
  void _snowBody(Canvas canvas, List<Offset> top, double bottom, SkiLight lt) {
    Path band(double d0, double d1) {
      final p = Path()..moveTo(top.first.dx, top.first.dy + d0);
      for (final q in top) {
        p.lineTo(q.dx, q.dy + d0);
      }
      for (var i = top.length - 1; i >= 0; i--) {
        p.lineTo(top[i].dx, math.min(bottom, top[i].dy + d1));
      }
      return p..close();
    }

    canvas.drawPath(band(170, bottom), Paint()..color = lt.deep);
    // Üstten derine yumuşak geçiş: ince katmanlar, renk adım adım koyulaşır.
    const n = 26;
    for (var k = n - 1; k >= 0; k--) {
      final u0 = k / n;
      final u1 = (k + 1) / n;
      final d0 = 170 * u0 * u0;
      final d1 = 170 * u1 * u1;
      final u = (u0 + u1) / 2;
      final col = u < 0.25
          ? Color.lerp(lt.snowLit, lt.snowShade, u / 0.25)!
          : Color.lerp(lt.snowShade, lt.deep, (u - 0.25) / 0.75)!;
      canvas.drawPath(band(d0, d1 + 0.8), Paint()..color = col);
    }
    // Katmanların arası yumuşasın: ince sis çizgileri.
    final edge = Path()..moveTo(top.first.dx, top.first.dy);
    for (final q in top) {
      edge.lineTo(q.dx, q.dy);
    }
    canvas.drawPath(
      edge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round
        ..color = lt.snowLit,
    );
    // Üst kenarda ince, parlak bir çizgi: yamacın kenarı gökten keskin
    // ayrılır.
    canvas.drawPath(
      edge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..color = Color.lerp(lt.snowLit, const Color(0xFFFFFFFF), 0.55)!,
    );
    // Karın içinde soluk katman çizgileri (yamaca koşut).
    for (final (d, a) in const [(26.0, 0.16), (64.0, 0.11), (118.0, 0.07)]) {
      final strata = Path()..moveTo(top.first.dx, top.first.dy + d);
      for (final q in top) {
        strata.lineTo(q.dx, q.dy + d);
      }
      canvas.drawPath(
        strata,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = lt.snowLit.withValues(alpha: a),
      );
    }
    // Işığı yakalayan parıltılar: kenarda göz kırpan kristaller.
    final glint = Paint();
    for (var i = 0; i < top.length; i++) {
      final q = top[i];
      final seed = (q.dx / 8).round();
      final h = (seed * 2654435761) & 0xffff;
      if (h % 5 != 0) continue;
      final tw = math.sin(_t * (1.5 + (h % 7) * 0.4) + h) * 0.5 + 0.5;
      if (tw < 0.55) continue;
      glint.color = Color.lerp(
        lt.sun,
        const Color(0xFFFFFFFF),
        0.5,
      )!.withValues(alpha: (tw - 0.55) * 2);
      final d = 3.0 + (h % 11);
      final c = Offset(q.dx, q.dy + d);
      canvas.drawCircle(c, 0.9 + (tw - 0.55) * 2, glint);
    }
  }

  /// Uçurumun kaya yüzü: kenardan aşağı, girintili çıkıntılı; derine doğru
  /// koyulaşır. [side] -1 sol kenar (uçurum solda), 1 sağ kenar.
  void _cliff(Canvas canvas, Offset lip, double bottom, SkiLight lt, int side) {
    // Yamacın düz kesik kenarını örten, uçuruma doğru taşan kaya çıkıntıları.
    final face = Path()..moveTo(lip.dx - side * 2, lip.dy + 4);
    var k = 0;
    for (var y = lip.dy + 10; y < bottom; y += 22, k++) {
      final h = ((lip.dx.round() * 31 + k * 17) % 13).toDouble();
      face.lineTo(lip.dx + side * (2 + h), y);
      face.lineTo(lip.dx + side * (h * 0.4), y + 11);
    }
    face
      ..lineTo(lip.dx - side * 2, bottom)
      ..close();
    canvas.drawPath(
      face,
      Paint()
        ..shader = Gradient.linear(Offset(0, lip.dy), Offset(0, lip.dy + 360), [
          Color.lerp(lt.snowShade, lt.deep, 0.45)!,
          lt.deep,
        ]),
    );
  }

  /// Kenardan sarkan kar saçağı.
  void _cornice(Canvas canvas, Offset lip, SkiLight lt, int side) {
    final p = Path()
      ..moveTo(lip.dx - side * 26, lip.dy - 1)
      ..quadraticBezierTo(
        lip.dx + side * 4,
        lip.dy - 3,
        lip.dx + side * 9,
        lip.dy + 4,
      )
      ..quadraticBezierTo(
        lip.dx + side * 6,
        lip.dy + 14,
        lip.dx - side * 4,
        lip.dy + 10,
      )
      ..quadraticBezierTo(
        lip.dx - side * 14,
        lip.dy + 8,
        lip.dx - side * 26,
        lip.dy + 6,
      )
      ..close();
    canvas.drawPath(
      p,
      Paint()..color = Color.lerp(lt.snowLit, lt.snowShade, 0.15)!,
    );
    // Saçaktan sarkan buz sarkıtları.
    final ice = Paint()..color = lt.snowLit.withValues(alpha: 0.85);
    for (var i = 0; i < 3; i++) {
      final ix = lip.dx - side * (i * 6.0) + side * 3;
      canvas.drawPath(
        Path()
          ..moveTo(ix - 1.6, lip.dy + 9)
          ..lineTo(ix + 1.6, lip.dy + 9)
          ..lineTo(ix, lip.dy + 16 + i * 3)
          ..close(),
        ice,
      );
    }
  }

  /// Kayak izi: karın üst kenarının hemen altında iki ince çizgi.
  void _drawTrack(Canvas canvas, SkiLight lt) {
    if (_track.length < 2) return;
    final view = game.camera.visibleWorldRect;
    final path = Path();
    var open = false;
    for (final x in _track) {
      if (x < view.left - 40 || x > view.right + 40) {
        open = false;
        continue;
      }
      final y = surface.at(x);
      if (y == null) {
        open = false;
        continue;
      }
      if (!open) {
        path.moveTo(x, y + 2.5);
        open = true;
      } else {
        path.lineTo(x, y + 2.5);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = lt.snowShade.withValues(alpha: 0.75),
    );
  }

  /// Yamacın arkasındaki çamlar: Alto'daki gibi ince, uzun, koyu siluetler
  /// (kat kat sarkan dallar); ormanlarda sık, başka yerde seyrek; boyları
  /// değişir. Göğün rengine hafifçe karışır.
  void _pines(Canvas canvas, int c0, int c1, SkiLight lt) {
    final body = Color.lerp(
      Color.lerp(lt.deep, const Color(0xFF000000), 0.35)!,
      lt.skyLow,
      0.12,
    )!;
    final tree = Paint()..color = body;
    final forests = [
      for (final (k, c) in game.level.def.skiDecor)
        if (k == 'forest') (c, c + 70),
    ];
    bool inForest(int i) => forests.any((f) => i >= f.$1 && i < f.$2);
    for (var i = c0; i <= c1; i++) {
      if (surface.rows[i] < 0) continue;
      final hv = ((i * 2654435761) & 0xffff) / 65535.0;
      if (hv > (inForest(i) ? 0.62 : 0.14)) continue;
      final x = (i + 0.5) * kTile + (hv * 23 % 11 - 5);
      final y = surface.at(x);
      if (y == null) continue;
      final h = 64.0 + ((i * 131) % 70);
      drawAltoPine(canvas, x, y + 10, h, tree);
    }
  }
}

/// İnce çam silueti (Alto gibi): tepeden aşağı genişleyen, uçları sarkan
/// dal katları.
void drawAltoPine(Canvas canvas, double x, double base, double h, Paint p) {
  const tiers = 6;
  final top = base - h;
  final right = <Offset>[Offset(x, top)];
  for (var k = 0; k < tiers; k++) {
    final u0 = k / tiers;
    final u1 = (k + 1) / tiers;
    final y1 = top + h * 0.86 * u1;
    final half = h * (0.07 + 0.17 * u1);
    // Dal ucu biraz aşağı sarkar, iç köşe yukarıda kalır.
    right.add(Offset(x + half, y1 + h * 0.025));
    if (k < tiers - 1) {
      right.add(
        Offset(x + half * 0.42, top + h * 0.86 * (u0 + u1) / 2 + h * 0.05),
      );
    }
  }
  final path = Path()..moveTo(x, top);
  for (final q in right.skip(1)) {
    path.lineTo(q.dx, q.dy);
  }
  // Gövde.
  path
    ..lineTo(x + h * 0.025, base - h * 0.12)
    ..lineTo(x + h * 0.025, base)
    ..lineTo(x - h * 0.025, base)
    ..lineTo(x - h * 0.025, base - h * 0.12);
  for (final q in right.reversed.skip(0)) {
    if (q.dx == x) break;
    path.lineTo(2 * x - q.dx, q.dy);
  }
  path.close();
  canvas.drawPath(path, p);
}

/// Karın içinden çıkan kaya: kayarken üstünden atlanmalı. Çamlardan ayrı
/// dursun diye önde, iri, koyu ve sıcak tonlu; üstünde kar, ışık yanında
/// parlak kenar, önünde karın kabardığı yer.
class SkiRock extends PositionComponent with HasGameReference<GolgeGame> {
  SkiRock(this.col, this.surface)
    : super(
        position: Vector2(
          (col + 0.5) * kTile - 14,
          (surface.rows[col]) * kTile - 22,
        ),
        size: Vector2(28, 24),
        priority: 18,
      );

  final int col;
  final SkiSurface surface;

  @override
  void render(Canvas canvas) {
    final lt = game.skiLight;
    // Çizim, çarpışma kutusundan biraz büyük ve yere gömülü.
    final ground =
        (surface.at(position.x + 14) ?? position.y + 22) - position.y;
    canvas.save();
    canvas.translate(14, ground);
    final body = Path()
      ..moveTo(-19, 2)
      ..lineTo(-16, -12)
      ..lineTo(-8, -24)
      ..lineTo(3, -28)
      ..lineTo(13, -21)
      ..lineTo(19, -6)
      ..lineTo(18, 2)
      ..close();
    canvas.drawPath(
      body.shift(const Offset(3, 2)),
      Paint()..color = const Color(0xFF000000).withValues(alpha: 0.3),
    );
    canvas.drawPath(
      body,
      Paint()
        ..shader = Gradient.linear(
          const Offset(-18, -24),
          const Offset(18, 2),
          [const Color(0xFF5A4A44), const Color(0xFF221A1C)],
        ),
    );
    // Kırık yüzeyler.
    final facet = Paint()
      ..color = const Color(0xFF130E10).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(
      Path()
        ..moveTo(-8, -24)
        ..lineTo(-2, -10)
        ..lineTo(10, -4)
        ..moveTo(-2, -10)
        ..lineTo(-12, -2),
      facet,
    );
    // Işık tarafında kenar.
    canvas.drawPath(
      Path()
        ..moveTo(-16, -12)
        ..lineTo(-8, -24)
        ..lineTo(3, -28),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = lt.sun.withValues(alpha: 0.7),
    );
    // Üstünde kar.
    canvas.drawPath(
      Path()
        ..moveTo(-12, -18)
        ..lineTo(-8, -24)
        ..lineTo(3, -28)
        ..lineTo(13, -21)
        ..lineTo(6, -20)
        ..lineTo(-1, -23)
        ..lineTo(-6, -18)
        ..close(),
      Paint()..color = lt.snowLit,
    );
    // Dibinde kabaran kar.
    canvas.drawOval(
      const Rect.fromLTRB(-24, -3, 24, 5),
      Paint()..color = Color.lerp(lt.snowLit, lt.snowShade, 0.2)!,
    );
    canvas.restore();
  }
}

/// Kütükten çit: üstüne konulup kayılır (uçurumları geçmek için).
class SkiRail extends PositionComponent {
  SkiRail(int col, int row, int tiles)
    : super(
        // Üstü, uçurumun kenarındaki kar hizasında: dümdüz kayılarak çıkılır.
        position: Vector2(col * kTile.toDouble(), (row + 1) * kTile - 1),
        size: Vector2(tiles * kTile.toDouble(), 6),
        priority: 18,
      );

  double get top => position.y;

  @override
  void render(Canvas canvas) {
    final wood = Paint()
      ..color = const Color(0xFF241810)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(2, 2), Offset(size.x - 2, 2), wood);
    for (var x = 8.0; x < size.x; x += 40) {
      canvas.drawLine(Offset(x, 2), Offset(x - 4, 40), wood..strokeWidth = 3);
    }
    canvas.drawLine(
      const Offset(2, -1),
      Offset(size.x - 2, -1),
      Paint()
        ..color = const Color(0xFFDCE4F0).withValues(alpha: 0.8)
        ..strokeWidth = 2,
    );
  }
}

/// Manyetik Tepe: içinde kar yokuş yukarı akar (göz yanılır mı, dağ mı
/// çeker, kimse bilmez).
class MagnetZone extends Component with HasGameReference<GolgeGame> {
  MagnetZone(this.from, this.to) : super(priority: 2);

  final double from;
  final double to;
  double _t = 0;

  bool covers(double x) => x >= from && x <= to;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final s = game.skiSurface;
    if (s == null) return;
    // Yokuş yukarı süzülen ince parıltılar.
    final p = Paint()..color = const Color(0xFFB8E0FF).withValues(alpha: 0.5);
    for (var i = 0; i < 24; i++) {
      final k = ((i * 0.37 + _t * 0.25) % 1.0);
      final x = to - (to - from) * k;
      final y = s.at(x);
      if (y == null) continue;
      canvas.drawCircle(Offset(x, y - 10 - (i % 5) * 6), 1.4, p);
    }
  }
}

/// Çığ: arkadan gelen bir kar duvarı. Yakalarsa karanlık. Bitiş çizgisinde
/// dağılır.
class Avalanche extends PositionComponent with HasGameReference<GolgeGame> {
  Avalanche(this.startX, this.endX) : super(priority: 24);

  final double startX;
  final double endX;
  bool _awake = false;
  bool _gone = false;
  double _speed = 0;
  double _t = 0;
  double _fade = 0;

  bool get awake => _awake && !_gone;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (p == null) return;
    if (_gone) {
      _fade = math.max(0, _fade - dt);
      if (_fade <= 0) removeFromParent();
      return;
    }
    if (!_awake) {
      if (p.center.x > startX && !p.isDead) {
        _awake = true;
        position.x = p.center.x - 700;
        _speed = 230;
        GameAudio.instance.play('thunder');
        game.scare(0.8);
        game.narration.whisper('…');
      }
      return;
    }
    _fade = math.min(1, _fade + dt);
    if (p.center.x > endX) {
      _gone = true;
      GameAudio.instance.dread(0);
      return;
    }
    if (p.isDead) return;
    _speed = math.min(440, _speed + dt * 14);
    position.x += _speed * dt;
    // Çok geride kalmasın.
    position.x = math.max(position.x, p.center.x - 760);
    position.y = (game.skiSurface?.at(position.x) ?? position.y);
    final gap = p.center.x - position.x;
    game.shake(((300 - gap) / 300).clamp(0.0, 1.0) * 6);
    GameAudio.instance.dread(((700 - gap) / 600).clamp(0.2, 1.0));
    if (gap < 30) p.die(cause: DeathCause.dark);
  }

  @override
  void render(Canvas canvas) {
    if (!_awake) return;
    final a = _fade;
    final lt = game.skiLight;
    // Kabaran toz kar dalgası: önü yuvarlanan, arkası yamaca karışan; içten
    // dışa açık-koyu katmanlar, kıvrılan tepeler.
    final back = Paint()
      ..shader = Gradient.linear(const Offset(0, -260), const Offset(0, 40), [
        lt.snowShade.withValues(alpha: 0.0),
        lt.snowShade.withValues(alpha: 0.85 * a),
      ]);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-1100, -240, -60, 500),
        const Radius.circular(140),
      ),
      back..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    for (var layer = 0; layer < 3; layer++) {
      final col = Color.lerp(lt.snowLit, lt.snowShade, 0.5 - layer * 0.22)!;
      final paint = Paint()
        ..color = col.withValues(alpha: (0.55 + layer * 0.15) * a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0 - layer * 3);
      for (var i = 0; i < 9; i++) {
        final k = i / 8;
        // Önden geriye: öndekiler küçük ve alçak, ortadakiler en yüksek.
        final x = -k * 520 + layer * 10;
        final h = 60 + math.sin(k * math.pi) * 170 - layer * 18;
        final churn = math.sin(_t * (2.4 + i * 0.3) + i * 1.7 + layer);
        final r = 46 + 22 * math.sin(k * math.pi) + churn * 7;
        canvas.drawCircle(Offset(x + churn * 6, -h + r * 0.6), r, paint);
      }
    }
    // Ön kenardan savrulan toz.
    final dust = Paint()..color = lt.snowLit.withValues(alpha: 0.6 * a);
    for (var i = 0; i < 26; i++) {
      final u = ((i * 0.37 + _t * 0.9) % 1.0);
      final y = -20 - (i * 13 % 160);
      canvas.drawCircle(
        Offset(30 + u * 90, y + u * 30 + math.sin(_t * 3 + i) * 6),
        1.2 + (1 - u) * 2.4,
        dust,
      );
    }
  }
}

/// Kayakçının çizimi için yardımcı: tahta.
void drawSkis(Canvas canvas, Offset feet, double len) {
  final board = Paint()
    ..color = kInk
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(
    feet.translate(-len * 0.45, 0),
    feet.translate(len * 0.5, 0),
    board,
  );
  canvas.drawLine(
    feet.translate(len * 0.5, 0),
    feet.translate(len * 0.62, -3),
    board,
  );
}

/// Kayak için kar tozu.
void drawSpray(Canvas canvas, Offset at, double speed, double t) {
  if (speed < 120) return;
  final p = Paint()..color = const Color(0xFFF2F6FA).withValues(alpha: 0.6);
  for (var i = 0; i < 6; i++) {
    final k = ((t * 3 + i * 0.17) % 1.0);
    canvas.drawCircle(
      at.translate(-k * 30 - i * 2, -k * 14 * (i % 3 + 1) * 0.5),
      1.5 + (1 - k) * 2,
      p,
    );
  }
}
