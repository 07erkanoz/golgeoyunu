// Taş devin görünüşü ve hareketi: yana bakan, parça parça taş muhafız
// (baş ve Nemrut başlığı, gövde, omuzlar, kollar, bacaklar). Çizim ve yürüyüş
// verisi assets/art/giant_art.json ve giant_walk.json'dan bir kez yüklenir;
// parçalar bir kez ui.Picture olarak kaydedilir, her karede yalnız basılır.
//
// Oyunun kuralları (kulak, üç vuruş, taş atma, köprü) StoneGiant'tadır; bu
// sınıf yalnız o durumlara göre pozu kurar ve çizer.
import 'dart:convert';
import 'dart:io' show File;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;

double _num(dynamic v, [double fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  final s = v.toString();
  return s.endsWith('%')
      ? double.parse(s.substring(0, s.length - 1)) / 100
      : double.parse(s);
}

ui.Color _hex(String s, [double opacity = 1]) =>
    ui.Color(int.parse(s.substring(1), radix: 16) | 0xff000000)
        .withAlpha((opacity * 255).round().clamp(0, 255));

/// Vektör parçaları: JSON bir kez okunur, her parça bir ui.Picture olur.
class GiantArt {
  GiantArt(this._src) {
    final parts = _src['parts'] as Map<String, dynamic>;
    for (final id in parts.keys) {
      final rec = ui.PictureRecorder();
      _node(ui.Canvas(rec), parts[id], 1);
      _pictures[id] = rec.endRecording();
    }
  }

  final Map<String, dynamic> _src;
  final _pictures = <String, ui.Picture>{};

  void draw(ui.Canvas c, String id) {
    final p = _pictures[id];
    if (p != null) c.drawPicture(p);
  }

  ui.Path _path(dynamic n) {
    final p = ui.Path();
    final a = n['a'] as Map<String, dynamic>;
    if (n['tag'] == 'ellipse') {
      return p..addOval(
        ui.Rect.fromCenter(
          center: ui.Offset(_num(a['cx']), _num(a['cy'])),
          width: 2 * _num(a['rx']),
          height: 2 * _num(a['ry']),
        ),
      );
    }
    for (final dynamic row in n['ops'] as List) {
      final v = (row as List).skip(1).map(_num).toList();
      switch (row[0]) {
        case 'M':
          p.moveTo(v[0], v[1]);
        case 'L':
          p.lineTo(v[0], v[1]);
        case 'Q':
          p.quadraticBezierTo(v[0], v[1], v[2], v[3]);
        case 'C':
          p.cubicTo(v[0], v[1], v[2], v[3], v[4], v[5]);
        case 'Z':
          p.close();
      }
    }
    return p;
  }

  ui.Paint _paint(String value, List box, double opacity) {
    final paint = ui.Paint()..isAntiAlias = true;
    if (!value.startsWith('url(')) return paint..color = _hex(value, opacity);
    final g = _src['gradients'][value.substring(5, value.length - 1)];
    final a = g['a'];
    final x = _num(box[0]), y = _num(box[1]);
    final w = _num(box[2]), h = _num(box[3]);
    final colors = <ui.Color>[];
    final stops = <double>[];
    for (final st in g['stops'] as List) {
      colors.add(
        _hex(
          st['stop-color'] ?? '#000000',
          _num(st['stop-opacity'], 1) * opacity,
        ),
      );
      stops.add(_num(st['offset']));
    }
    if (g['kind'] == 'linearGradient') {
      paint.shader = ui.Gradient.linear(
        ui.Offset(x + _num(a['x1']) * w, y + _num(a['y1']) * h),
        ui.Offset(x + _num(a['x2'], 1) * w, y + _num(a['y2']) * h),
        colors,
        stops,
      );
    } else {
      paint.shader = ui.Gradient.radial(
        ui.Offset(x + _num(a['cx'], .5) * w, y + _num(a['cy'], .5) * h),
        math.max(.001, _num(a['r'], .5) * math.max(w, h)),
        colors,
        stops,
      );
    }
    return paint;
  }

  void _node(ui.Canvas c, dynamic n, double inherited) {
    final a = n['a'] as Map<String, dynamic>;
    final opacity = inherited * _num(a['opacity'], 1);
    c.save();
    final tr = a['transform'];
    if (tr != null) {
      for (final m in RegExp(
        r'(translate|rotate|scale)\(([^)]+)\)',
      ).allMatches(tr as String)) {
        final v = m[2]!
            .trim()
            .split(RegExp(r'[ ,]+'))
            .map(double.parse)
            .toList();
        switch (m[1]) {
          case 'translate':
            c.translate(v[0], v.length > 1 ? v[1] : 0);
          case 'rotate':
            c.rotate(v[0] * math.pi / 180);
          case 'scale':
            c.scale(v[0], v.length > 1 ? v[1] : v[0]);
        }
      }
    }
    final clip = a['clip-path'];
    if (clip != null) {
      final id = (clip as String).substring(5, clip.length - 1);
      final paths = _src['clips']?[id] as List?;
      if (paths != null && paths.isNotEmpty) c.clipPath(_path(paths.first));
    }
    if (n['tag'] == 'g') {
      for (final child in n['children'] as List) {
        _node(c, child, opacity);
      }
    } else if (n['tag'] == 'path' || n['tag'] == 'ellipse') {
      final p = _path(n);
      final box = n['box'] as List;
      final fill = a['fill'] ?? '#000000';
      if (fill != 'none') c.drawPath(p, _paint(fill, box, opacity));
      final stroke = a['stroke'];
      if (stroke != null && stroke != 'none') {
        c.drawPath(
          p,
          _paint(stroke, box, opacity)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = _num(a['stroke-width'], 1)
            ..strokeCap = a['stroke-linecap'] == 'round'
                ? ui.StrokeCap.round
                : ui.StrokeCap.butt
            ..strokeJoin = a['stroke-linejoin'] == 'round'
                ? ui.StrokeJoin.round
                : ui.StrokeJoin.miter,
        );
      }
    }
    c.restore();
  }
}

/// Bir anlık duruş (sağa bakan yerel çerçevede; ayak tabanı y=0, baş -y).
/// Bacak noktaları ve gövde kökü dünyada, kollar gövde çerçevesindedir.
class GiantPose {
  GiantPose({
    required this.body,
    required this.angle,
    required this.headAngle,
    required this.near,
    required this.far,
    required this.hipN,
    required this.hipF,
    required this.kneeN,
    required this.kneeF,
    required this.ankleN,
    required this.ankleF,
    required this.armN,
    required this.armF,
  });

  ui.Offset body;
  double angle;
  double headAngle;
  ui.Offset near, far;
  ui.Offset hipN, hipF, kneeN, kneeF, ankleN, ankleF;
  List<ui.Offset> armN, armF;

  static ui.Offset _p(dynamic v) => ui.Offset(_num(v[0]), _num(v[1]));

  factory GiantPose.fromJson(Map<String, dynamic> j) => GiantPose(
    body: _p(j['body']),
    angle: _num(j['angle']),
    headAngle: _num(j['headAngle']),
    near: _p(j['near']),
    far: _p(j['far']),
    hipN: _p(j['hipN']),
    hipF: _p(j['hipF']),
    kneeN: _p(j['kneeN']),
    kneeF: _p(j['kneeF']),
    ankleN: _p(j['ankleN']),
    ankleF: _p(j['ankleF']),
    armN: [for (final q in j['armN'] as List) _p(q)],
    armF: [for (final q in j['armF'] as List) _p(q)],
  );

  GiantPose copy() => GiantPose(
    body: body,
    angle: angle,
    headAngle: headAngle,
    near: near,
    far: far,
    hipN: hipN,
    hipF: hipF,
    kneeN: kneeN,
    kneeF: kneeF,
    ankleN: ankleN,
    ankleF: ankleF,
    armN: [...armN],
    armF: [...armF],
  );

  static ui.Offset _l(ui.Offset a, ui.Offset b, double t) => a + (b - a) * t;
  static double _d(double a, double b, double t) => a + (b - a) * t;

  /// İki duruşun arası.
  static GiantPose lerp(GiantPose a, GiantPose b, double t) => GiantPose(
    body: _l(a.body, b.body, t),
    angle: _d(a.angle, b.angle, t),
    headAngle: _d(a.headAngle, b.headAngle, t),
    near: _l(a.near, b.near, t),
    far: _l(a.far, b.far, t),
    hipN: _l(a.hipN, b.hipN, t),
    hipF: _l(a.hipF, b.hipF, t),
    kneeN: _l(a.kneeN, b.kneeN, t),
    kneeF: _l(a.kneeF, b.kneeF, t),
    ankleN: _l(a.ankleN, b.ankleN, t),
    ankleF: _l(a.ankleF, b.ankleF, t),
    armN: [for (var i = 0; i < 3; i++) _l(a.armN[i], b.armN[i], t)],
    armF: [for (var i = 0; i < 3; i++) _l(a.armF[i], b.armF[i], t)],
  );
}

/// Devin duruş kuran ve çizen kuklası. Durumu her karede StoneGiant verir.
class GiantPuppet {
  GiantPuppet._(this.art, this._walk);

  static GiantPuppet? _shared;

  /// Çizim ve yürüyüş verisini bir kez yükler (bütün devler paylaşır).
  /// Yüklendiyse hemen bir kukla (bekletmeden), yoksa null.
  static GiantPuppet? cached() => _shared?._clone();

  static Future<GiantPuppet> load() async {
    final shared = _shared;
    if (shared != null) return shared._clone();
    final art = GiantArt(await _json('assets/art/giant_art.json'));
    final walk = await _json('assets/art/giant_walk.json');
    final frames = [
      for (final f in walk['frames'] as List)
        GiantPose.fromJson(f as Map<String, dynamic>),
    ];
    final p = GiantPuppet._(art, frames);
    _shared = p;
    return p._clone();
  }

  GiantPuppet _clone() => GiantPuppet._(art, _walk);

  /// Varlık dosyası; varlık yükleyicisi kurulmamışsa (yalın oyun testleri)
  /// dosyadan okunur.
  static Future<Map<String, dynamic>> _json(String path) async {
    String text;
    try {
      text = await rootBundle.loadString(path);
    } catch (_) {
      text = await File(path).readAsString();
    }
    return jsonDecode(text) as Map<String, dynamic>;
  }

  final GiantArt art;
  final List<GiantPose> _walk;

  /// Bir yürüyüş döngüsünde alınan yol (yerel birim).
  static const double cycle = 57.2;

  // Kemik boyları (çizim parçalarının boyu).
  static const double _thigh = 47, _shin = 45, _upper = 58, _fore = 56;

  /// Çizimin oyundaki ölçeği (başlığın tepesi ~ -333 birim).
  static const double scale = 0.9;

  /// Devrilirken dönme ekseni (yerel x; sağa bakan çerçevede).
  static const double pivotX = 42;

  /// Elinde tuttuğu kayanın yarıçapı (yerel birim).
  static const double boulderR = 34;

  double _dist = 0;
  int facing = 1;

  /// Yürüdükçe ilerler; ayak yerde kaymaz.
  void walk(double dx) => _dist += dx.abs();

  GiantPose _walkPose() {
    final n = _walk.length - 1;
    final f = (_dist / cycle % 1) * n;
    final i = f.floor();
    return GiantPose.lerp(_walk[i], _walk[math.min(i + 1, n)], f - i);
  }

  static double _ease(double t) {
    final v = t.clamp(0.0, 1.0);
    return v * v * (3 - 2 * v);
  }

  static ui.Offset _rot(ui.Offset p, double a) => ui.Offset(
    p.dx * math.cos(a) - p.dy * math.sin(a),
    p.dx * math.sin(a) + p.dy * math.cos(a),
  );

  /// İki kemikli eklem: [a] kökten [b] uca; [bend] +1 eklem öne (+x),
  /// -1 geriye kırılır.
  static ui.Offset _joint(
    ui.Offset a,
    ui.Offset b,
    double l1,
    double l2,
    int bend,
  ) {
    final v = b - a;
    final raw = v.distance;
    final d = raw.clamp((l1 - l2).abs() + .01, l1 + l2 - .01);
    final u = raw < 1e-4 ? const ui.Offset(0, 1) : v / raw;
    final along = (l1 * l1 - l2 * l2 + d * d) / (2 * d);
    final side = math.sqrt(math.max(0, l1 * l1 - along * along));
    final n = ui.Offset(-u.dy, u.dx);
    final k1 = a + u * along + n * side;
    final k2 = a + u * along - n * side;
    return (k1.dx > k2.dx) == (bend > 0) ? k1 : k2;
  }

  /// Gövde çerçevesindeki noktanın yerel yeri ve tersi.
  static ui.Offset _toLocal(GiantPose p, ui.Offset q) =>
      _rot(q, p.angle) + p.body;
  static ui.Offset _toBody(GiantPose p, ui.Offset q) =>
      _rot(q - p.body, -p.angle);

  /// Kolu omuzdan bileğe ([wrist] yerel çerçevede) uzatır.
  static void _reach(GiantPose p, bool near, ui.Offset wrist, {int bend = -1}) {
    final arm = near ? p.armN : p.armF;
    final s = arm[0];
    final w = _toBody(p, wrist);
    final v = w - s;
    final reach = _upper + _fore - 2;
    final ww = v.distance > reach ? s + v / v.distance * reach : w;
    arm[1] = _joint(s, ww, _upper, _fore, bend);
    arm[2] = ww;
  }

  /// Bacakları kalça ve bileğe göre yeniden kurar (diz öne kırılır).
  static void _legs(GiantPose p) {
    p.kneeN = _joint(p.hipN, p.ankleN, _thigh, _shin, 1);
    p.kneeF = _joint(p.hipF, p.ankleF, _thigh, _shin, 1);
  }

  /// Çömelme: kalçalar iner, gövde leğen kemiğinin çevresinde öne eğilir
  /// (gövde kalçadan kopmaz), ayaklar yerde kalır, dizler bükülür.
  static void _crouch(GiantPose p, double c, {double lean = .55}) {
    const pelvis = ui.Offset(0, -100);
    final drop = ui.Offset(0, 52 * c);
    final hip = _toLocal(p, pelvis) + drop;
    p.angle += lean * c;
    p.body = hip - _rot(pelvis, p.angle);
    p.hipN += drop;
    p.hipF += drop;
    _legs(p);
  }

  // ------------------------------------------------------------ durumlar

  /// Durum: [stagger] (kalan sn), taş atma ([throwStage] 0 yok, 1 kaldırma,
  /// 2 savurma, 3 toparlanma; [throwK] o evrenin 0–1 ilerleyişi), [flinch]
  /// (başın kaçışı), [fall] (null değilse devrilme: çarpmaya kadar 0–1),
  /// [afterImpact] (çarpmadan sonra geçen sn).
  GiantPose? _fallPose;

  GiantPose pose({
    double stagger = 0,
    int throwStage = 0,
    double throwK = 0,
    double flinch = 0,
  }) {
    final base = _walkPose();
    final p = base.copy();
    p.headAngle += flinch;
    if (stagger > 0) {
      // Kulağına giren ışık: baş geri kaçar, el kulağa gider, gövde
      // geriye sendeleyip ağırca toparlanır.
      final t = 2.4 - stagger;
      final hit = _ease(t / .18) * (1 - _ease((t - 1.6) / .8));
      p.headAngle -= .32 * hit;
      p.angle -= .1 * hit;
      p.body += ui.Offset(-5 * hit, 3 * hit);
      final ear = _toLocal(
        p,
        _rot(const ui.Offset(-1, -29), p.headAngle) + const ui.Offset(3, -216),
      );
      final rest = _toLocal(p, base.armN[2]);
      _reach(
        p,
        true,
        ui.Offset.lerp(rest, ear + const ui.Offset(14, 18), hit)!,
      );
      _reach(
        p,
        false,
        _toLocal(p, base.armF[2]) + ui.Offset(-12 * hit, -16 * hit),
      );
      return p;
    }
    if (throwStage == 0) return p;
    // Taş atma: eğilip iki eliyle yerden kaya koparır, başının üstüne
    // kaldırır, öne savurur, toparlanır.
    final ground = const ui.Offset(66, -34);
    final over = const ui.Offset(-8, -336);
    final front = const ui.Offset(96, -196);
    late ui.Offset hands;
    var c = 0.0;
    switch (throwStage) {
      case 1:
        final k = throwK;
        if (k < .35) {
          c = _ease(k / .35);
          hands = ui.Offset.lerp(_toLocal(p, base.armN[2]), ground, c)!;
        } else if (k < .45) {
          c = 1;
          hands = ground;
        } else {
          final u = _ease((k - .45) / .55);
          c = 1 - u;
          hands = _arc(ground, over, u);
        }
      case 2:
        final u = _ease(throwK / .5);
        hands = _arc(over, front, u, lift: -40);
        p.angle += .16 * u;
      default:
        final u = _ease(throwK / .55);
        hands = ui.Offset.lerp(front, _toLocal(p, base.armN[2]), u)!;
        p.angle += .16 * (1 - u);
    }
    _crouch(p, c);
    _reach(p, true, hands + const ui.Offset(6, 0));
    _reach(p, false, hands + const ui.Offset(-10, -4));
    return p;
  }

  /// Bir yay boyunca [a]'dan [b]'ye (kolun döner gibi kalkması).
  static ui.Offset _arc(ui.Offset a, ui.Offset b, double u, {double lift = 0}) {
    final m = (a + b) / 2 + ui.Offset(-50, lift);
    return a * ((1 - u) * (1 - u)) + m * (2 * u * (1 - u)) + b * (u * u);
  }

  /// Taş atmada kayanın yeri (yerel), elde yoksa null.
  ui.Offset? boulder(GiantPose p, int throwStage, double throwK) {
    if (throwStage != 1 || throwK < .35) return null;
    final a = _toLocal(p, p.armN[2]);
    final b = _toLocal(p, p.armF[2]);
    final m = (a + b) / 2;
    // Kaya ellerin arasında, kaldırırken ellerin üstünde durur.
    return m + ui.Offset(0, -boulderR * .55);
  }

  /// Kulağın yerel yeri (kuklanın çizim çerçevesinde, ölçeksiz).
  ui.Offset earOf(GiantPose p) => _toLocal(
    p,
    _rot(const ui.Offset(-1, -29), p.headAngle) + const ui.Offset(3, -216),
  );

  // ------------------------------------------------------------ çizim

  void _bone(ui.Canvas c, String id, ui.Offset a, ui.Offset b, double len) {
    final v = b - a;
    c.save();
    c.translate(a.dx, a.dy);
    c.rotate(math.atan2(v.dy, v.dx) - math.pi / 2);
    c.scale(1, v.distance / len);
    art.draw(c, id);
    c.restore();
  }

  void _leg(
    ui.Canvas c,
    ui.Offset hip,
    ui.Offset knee,
    ui.Offset ankle,
    ui.Offset foot,
  ) {
    _bone(c, 'thigh', hip, knee, _thigh);
    _bone(c, 'shin', knee, ankle, _shin);
    c.save();
    c.translate(foot.dx, foot.dy);
    art.draw(c, 'foot');
    c.restore();
  }

  void _arm(ui.Canvas c, List<ui.Offset> a) {
    _bone(c, 'upper-arm', a[0], a[1], _upper);
    _bone(c, 'forearm', a[1], a[2], _fore);
    c.save();
    c.translate(a[2].dx, a[2].dy);
    c.rotate(math.atan2(a[2].dy - a[1].dy, a[2].dx - a[1].dx) - math.pi / 2);
    art.draw(c, 'hand');
    c.restore();
  }

  void _body(ui.Canvas c, GiantPose p) {
    c.translate(p.body.dx, p.body.dy);
    c.rotate(p.angle);
  }

  /// Duruşu sağa bakan yerel çerçevede çizer (aynalamayı çağıran yapar).
  void drawPose(ui.Canvas c, GiantPose p, {ui.Offset? boulderAt}) {
    c.save();
    _body(c, p);
    _arm(c, p.armF);
    art.draw(c, 'shoulder-right');
    c.restore();
    _leg(c, p.hipF, p.kneeF, p.ankleF, p.far);
    c.save();
    _body(c, p);
    art.draw(c, 'torso');
    c.restore();
    _leg(c, p.hipN, p.kneeN, p.ankleN, p.near);
    c.save();
    _body(c, p);
    c.translate(3, -216);
    c.rotate(p.headAngle);
    c.translate(-3, 216);
    art.draw(c, 'head');
    art.draw(c, 'ear');
    c.restore();
    if (boulderAt != null) drawBoulder(c, boulderAt, boulderR);
    c.save();
    _body(c, p);
    _arm(c, p.armN);
    art.draw(c, 'shoulder-left');
    c.restore();
  }

  /// Devrilmenin açısı: önce geriye bir sallanır, sonra hızlanarak düşer;
  /// yere çarpınca bir kez seker. [t] çarpmaya kadar 0–1, [after] sonrası sn.
  static double fallAngle(double t, double after) {
    final s = t * 1.25;
    if (after <= 0) {
      if (s < .3) return -.07 * math.sin(math.pi * s / .3);
      return math.pi / 2 * math.pow(((s - .3) / .95).clamp(0, 1), 2.3);
    }
    final bounce =
        (.075 *
                math.sin(math.pi * math.min(1.0, after / .22)) *
                math.exp(-after * 5))
            .abs();
    return math.pi / 2 - bounce;
  }

  /// Devrilirken dondurulmuş duruş (vuruş anındaki duruş).
  void freezeForFall(GiantPose p) => _fallPose ??= p;
  GiantPose get fallPose => _fallPose ??= _walkPose();

  /// Kayayı çizer: köşeli taş, üstünde soluk ışık.
  static void drawBoulder(ui.Canvas c, ui.Offset at, double r) {
    final path = ui.Path();
    const pts = [
      (-1.0, -.35),
      (-.45, -.95),
      (.4, -1.0),
      (1.0, -.3),
      (.85, .55),
      (.2, 1.0),
      (-.7, .8),
    ];
    for (var i = 0; i < pts.length; i++) {
      final q = at + ui.Offset(pts[i].$1 * r, pts[i].$2 * r);
      i == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
    }
    path.close();
    c.drawPath(path, ui.Paint()..color = const ui.Color(0xFF6E6560));
    c.drawPath(
      path,
      ui.Paint()
        ..color = const ui.Color(0xFF2E2A30)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    c.drawLine(
      at + ui.Offset(-.5 * r, -.75 * r),
      at + ui.Offset(.45 * r, -.8 * r),
      ui.Paint()
        ..color = const ui.Color(0x99D8CCB8)
        ..strokeWidth = 2.5,
    );
    c.drawLine(
      at + ui.Offset(-.1 * r, -.4 * r),
      at + ui.Offset(.25 * r, .4 * r),
      ui.Paint()
        ..color = const ui.Color(0xFF2E2A30)
        ..strokeWidth = 1.5,
    );
  }
}
