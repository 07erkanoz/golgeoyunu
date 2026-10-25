import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'audio.dart';
import 'entities.dart';
import 'erlik.dart';
import 'golge_game.dart';
import 'level.dart';
import 'myth_figures.dart';
import 'palette.dart';
import 'player.dart';

// ================================================================ Ak Ana'nın Denizi
//
// Altay yaratılış anlatısındaki ilk su: başta yalnız su ve Kayra Han
// vardı; Ak Ana sudan yükselip "Yarat" dedi. Sâye Hayat Ağacı'nın
// köklerinden bu suya iner, dibinden Erlik'in katına geçer.
//
// Su hayal perdesinin diliyle çizilir: siluet kayalar, yosunlar ve
// balıklar; yukarıda açık, aşağıda koyulaşan su; yüzeyden inen ışık
// huzmeleri. Bulanıklık filtresi yok: her şey düz boya ve degrade.

/// Suyun derinliğe göre rengi: yüzeyin hemen altı açık camgöbeği, dip
/// mürekkep.
Color seaColor(double depth) {
  const stops = [
    (0.0, Color(0xFF4E9696)),
    (300.0, Color(0xFF235A63)),
    (800.0, Color(0xFF103540)),
    (1400.0, Color(0xFF07161D)),
    (2000.0, Color(0xFF030709)),
  ];
  if (depth <= 0) return stops.first.$2;
  for (var i = 0; i < stops.length - 1; i++) {
    final (d0, c0) = stops[i];
    final (d1, c1) = stops[i + 1];
    if (depth <= d1) return Color.lerp(c0, c1, (depth - d0) / (d1 - d0))!;
  }
  return stops.last.$2;
}

/// Su: görünen alanı derinliğin rengiyle doldurur (arka planın yerine);
/// yüzeyin üstünde gece göğü, yüzeyde ışıklı dalga çizgisi.
class SeaWater extends Component with HasGameReference<GolgeGame> {
  SeaWater(this.surface) : super(priority: -5);

  /// Su yüzeyinin dünya yüksekliği.
  final double surface;
  double _t = 0;

  /// Bir hava cebinin dibindeki su çizgisi.
  void _surfaceLine(Canvas canvas, double x0, double x1, double y) {
    final wave = Path()..moveTo(x0, y);
    for (var x = x0; x <= x1; x += 8) {
      wave.lineTo(x, y + math.sin(x / 19 + _t * 1.6) * 1.5);
    }
    canvas.drawPath(
      wave,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFFCFF2EA).withValues(alpha: 0.5),
    );
  }

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final v = game.camera.visibleWorldRect.inflate(4);
    if (v.top < surface) {
      canvas.drawRect(
        Rect.fromLTRB(v.left, v.top, v.right, surface),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, surface - 260),
            Offset(0, surface),
            const [Color(0xFF0B1418), Color(0xFF21393C)],
          ),
      );
    }
    final top = math.max(v.top, surface);
    if (top < v.bottom) {
      canvas.drawRect(
        Rect.fromLTRB(v.left, top, v.right, v.bottom),
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, top), Offset(0, v.bottom), [
            seaColor(top - surface),
            seaColor(v.bottom - surface),
          ]),
      );
    }
    // Hava cepleri: kayanın içinde loş hava, dibinde suyun yüzü.
    for (final a in game.level.airRects) {
      if (!a.overlaps(v)) continue;
      canvas.drawRect(
        a,
        Paint()
          ..shader = ui.Gradient.linear(a.topCenter, a.bottomCenter, const [
            Color(0xFF0A1416),
            Color(0xFF1C3438),
          ]),
      );
      _surfaceLine(canvas, a.left, a.right, a.bottom);
    }
    if (v.top < surface + 20 && v.bottom > surface - 20) {
      // Yüzeyin alt yüzü: dalgalanan parlak bir çizgi.
      final wave = Path()..moveTo(v.left, surface);
      for (var x = v.left; x <= v.right + 12; x += 12) {
        wave.lineTo(
          x,
          surface + math.sin(x / 37 + _t * 1.3) * 2 + math.sin(x / 13 - _t) * 1,
        );
      }
      canvas.drawPath(
        wave,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFCFF2EA).withValues(alpha: 0.55),
      );
      wave
        ..lineTo(v.right + 12, surface + 18)
        ..lineTo(v.left, surface + 18)
        ..close();
      canvas.drawPath(
        wave,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, surface),
            Offset(0, surface + 18),
            [
              const Color(0xFFBFEAE0).withValues(alpha: 0.28),
              const Color(0xFFBFEAE0).withValues(alpha: 0),
            ],
          ),
      );
    }
  }
}

/// Suyun rengi kayaların ve yosunların üstüne de biner (derinlikte kayalar
/// suyun içinde kaybolur); Sâye bunun üstünde, seçik kalır.
class SeaTint extends Component with HasGameReference<GolgeGame> {
  SeaTint(this.surface) : super(priority: 10);

  final double surface;

  @override
  void render(Canvas canvas) {
    final v = game.camera.visibleWorldRect.inflate(4);
    final top = math.max(v.top, surface);
    if (top >= v.bottom) return;
    // Yüzeye yakın kayalar seçik kalır; derinde suyun içinde kaybolur.
    Color tint(double y) => seaColor(
      y - surface,
    ).withValues(alpha: 0.18 + 0.42 * ((y - surface) / 1600).clamp(0.0, 1.0));
    canvas.save();
    for (final a in game.level.airRects) {
      if (a.overlaps(v)) canvas.clipRect(a, clipOp: ClipOp.difference);
    }
    canvas.drawRect(
      Rect.fromLTRB(v.left, top, v.right, v.bottom),
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, top), Offset(0, v.bottom), [
          tint(top),
          tint(v.bottom),
        ]),
    );
    canvas.restore();
  }
}

/// Yüzeyden inen ışık huzmeleri: ağır ağır salınır, derinde söner. Her
/// karede bulanıklık yok: üst üste üç saydam şerit.
class SeaShafts extends Component with HasGameReference<GolgeGame> {
  SeaShafts(this.surface) : super(priority: 34);

  final double surface;

  /// Işığın indiği en derin yer (px).
  static const double reach = 900;
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final v = game.camera.visibleWorldRect;
    if (v.top > surface + reach || v.bottom < surface) return;
    final paint = Paint()..blendMode = BlendMode.plus;
    // Huzmeler dünyaya sabit (kamera kaydıkça yerinde kalır).
    final first = (v.left / 140).floor() - 2;
    final last = (v.right / 140).ceil() + 2;
    for (var i = first; i <= last; i++) {
      final seed = (i * 7919) % 97 / 97.0;
      if (seed < 0.35) continue;
      final x = i * 140.0 + seed * 60;
      // Yalnız gökyüzüne açık suda: kaya tavanın altına ışık inmez.
      final lv = game.level;
      final col = (x / kTile).floor();
      final row = (surface / kTile).floor();
      var roofed = false;
      for (var r = 0; r <= row + 2 && !roofed; r++) {
        roofed = lv.solid(col, r);
      }
      if (roofed) continue;
      final sway = math.sin(_t * 0.35 + seed * 6) * 22;
      final w = 18 + seed * 30;
      final bright = 0.5 + 0.5 * math.sin(_t * 0.6 + seed * 9);
      for (final k in const [1.0, 0.6, 0.3]) {
        final path = Path()
          ..moveTo(x - w * k, surface)
          ..lineTo(x + w * k, surface)
          ..lineTo(x + sway + 120 + w * k * 2.2, surface + reach)
          ..lineTo(x + sway + 120 - w * k * 2.2, surface + reach)
          ..close();
        paint.shader = ui.Gradient.linear(
          Offset(0, surface),
          const Offset(0, 0) + Offset(0, surface + reach),
          [
            const Color(0xFFBFEFE2).withValues(alpha: 0.075 * bright),
            const Color(0xFFBFEFE2).withValues(alpha: 0),
          ],
        );
        canvas.drawPath(path, paint);
      }
    }
  }
}

/// Uzun yosun (dev su yosunu): dipten yükselir, sapı akışla salınır;
/// şeritli yaprakları akıntı yönünde ardına yatar, diplerinde küçük hava
/// keseleri. Önde çizilenler Sâye'yi örter: gölge gibi saklar.
class Kelp extends PositionComponent {
  Kelp(Vector2 root, this.tall, {this.front = false, this.seed = 0})
    : super(position: root, priority: front ? 31 : 14);

  final double tall;
  final bool front;
  final double seed;
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final n = (tall / 14).ceil();
    final pts = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final k = i / n;
      final x =
          math.sin(_t * 0.8 + seed * 5 - k * 2.2) * 12 * k * k +
          math.sin(_t * 0.35 + seed) * 5 * k;
      pts.add(Offset(x, -tall * k));
    }
    final color = front ? const Color(0xF0040A0B) : const Color(0xFF12383A);
    final stem = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = front ? 3.4 : 2.6
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, stem);
    final leaf = Paint()..color = color;
    for (var i = 1; i < pts.length; i++) {
      final p = pts[i];
      final k = i / pts.length;
      final side = i.isEven ? 1.0 : -1.0;
      // Yaprak akışa yatar: kökü sapta, ucu yana ve yukarı, dalgalı şerit.
      final len = (front ? 30.0 : 24.0) * (1 - k * 0.35);
      final flow = math.sin(_t * 1.1 + i * 0.7 + seed) * 0.3;
      final a = -math.pi / 2 + side * (0.95 + flow * side) + 0.25;
      final dir = Offset(math.cos(a), math.sin(a));
      final nrm = Offset(-dir.dy, dir.dx);
      final wid = front ? 4.2 : 3.4;
      final top = <Offset>[];
      final bot = <Offset>[];
      for (var j = 0; j <= 6; j++) {
        final u = j / 6;
        final ripple = math.sin(_t * 3 + u * 7 + i) * 1.6 * u;
        final c = p + dir * (len * u) + nrm * ripple;
        final half =
            wid *
            math.sin(math.min(1, u * 1.6) * math.pi * 0.5) *
            (1 - u * 0.75);
        top.add(c + nrm * half);
        bot.add(c - nrm * half);
      }
      canvas.drawPath(
        Path()..addPolygon([...top, ...bot.reversed], true),
        leaf,
      );
      // Hava kesesi.
      if (i % 2 == 1) canvas.drawCircle(p + dir * 2.5, 2.1, leaf);
    }
  }
}

/// Balık sürüsü: bir yol boyunca birlikte döner; Sâye hızla içinden
/// geçince dağılır, sonra yeniden toplanır.
class FishSchool extends Component with HasGameReference<GolgeGame> {
  FishSchool(this.home, {this.count = 28, this.spread = 70, this.seed = 1})
    : super(priority: 16);

  final Vector2 home;
  final int count;
  final double spread;
  final int seed;
  final _pos = <Vector2>[];
  final _vel = <Vector2>[];
  final _slot = <Vector2>[];
  double _t = 0;

  @override
  void onLoad() {
    final r = math.Random(seed);
    for (var i = 0; i < count; i++) {
      final a = r.nextDouble() * math.pi * 2;
      final d = math.sqrt(r.nextDouble()) * spread;
      _slot.add(Vector2(math.cos(a) * d, math.sin(a) * d * 0.45));
      _pos.add(home + _slot.last);
      _vel.add(Vector2(40, 0));
    }
  }

  /// Sürünün yolu: yatık bir sekiz çizer.
  Vector2 _center(double t) =>
      home + Vector2(math.sin(t * 0.22) * 150, math.sin(t * 0.44) * 30);

  @override
  void update(double dt) {
    _t += dt;
    final c = _center(_t);
    final ahead = _center(_t + 0.5) - c;
    final p = game.player;
    for (var i = 0; i < count; i++) {
      // Yerine (sürüdeki yuvasına) doğru çekilir; yuva gidişe göre döner.
      final ang = math.atan2(ahead.y, ahead.x);
      final s = _slot[i];
      final rot = Vector2(
        s.x * math.cos(ang) - s.y * math.sin(ang),
        s.x * math.sin(ang) + s.y * math.cos(ang),
      );
      final want = c + rot;
      final steer = (want - _pos[i])..scale(2.2);
      // Sâye yakınsa ve hızlıysa kaçar.
      if (p != null) {
        final away = _pos[i] - p.center;
        final d = away.length;
        final fast = p.velocity.length;
        final fear = fast > 70 ? 90.0 : 45.0;
        if (d < fear && d > 0.1) {
          steer.add(away..scale((fear - d) / d * 9));
        }
      }
      _vel[i].add(steer..scale(dt));
      final sp = _vel[i].length;
      if (sp > 190) _vel[i].scale(190 / sp);
      _vel[i].scale(math.exp(-dt * 1.2));
      _pos[i].add(_vel[i] * dt);
    }
  }

  @override
  void render(Canvas canvas) {
    final body = Paint()..color = const Color(0xFF0B2226);
    final glint = Paint()
      ..color = const Color(0xFFCFEFEA).withValues(alpha: 0.35)
      ..strokeWidth = 0.8;
    for (var i = 0; i < count; i++) {
      final p = _pos[i];
      final v = _vel[i];
      final a = math.atan2(v.y, v.x);
      final wag = math.sin(_t * 12 + i) * 0.35;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(a);
      final s = 0.8 + (i % 3) * 0.15;
      canvas.scale(s);
      canvas.drawPath(
        Path()
          ..moveTo(6, 0)
          ..quadraticBezierTo(2, -3, -4, -0.6)
          ..lineTo(-8, -3 + wag * 2)
          ..lineTo(-7, 0)
          ..lineTo(-8, 3 + wag * 2)
          ..lineTo(-4, 0.6)
          ..quadraticBezierTo(2, 3, 6, 0)
          ..close(),
        body,
      );
      canvas.drawLine(const Offset(-3, -0.4), const Offset(4, -1.2), glint);
      canvas.restore();
    }
  }
}

/// Suyun içinde süzülen ince tozlar (deniz karı): derinliği ve akışı
/// hissettirir.
class SeaMotes extends Component with HasGameReference<GolgeGame> {
  SeaMotes() : super(priority: 33);
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final v = game.camera.visibleWorldRect;
    final paint = Paint();
    const cell = 46.0;
    for (var gx = (v.left / cell).floor(); gx <= v.right / cell; gx++) {
      for (var gy = (v.top / cell).floor(); gy <= v.bottom / cell; gy++) {
        final h = ((gx * 73856093) ^ (gy * 19349663)) & 0xffff;
        if (h % 3 != 0) continue;
        final fx = (h % 97) / 97.0;
        final fy = (h % 89) / 89.0;
        final x = (gx + fx) * cell + math.sin(_t * 0.5 + h) * 5;
        // Ağır ağır yükselir; hücresinin içinde döner.
        final yy = (gy + (fy - _t * (0.08 + fx * 0.1)) % 1.0) * cell;
        paint.color = const Color(0xFFDDEFEA)
            .withValues(alpha: 0.12 + 0.18 * fy);
        canvas.drawCircle(Offset(x, yy), 0.6 + fx * 0.9, paint);
      }
    }
  }
}

/// Denizanası: nefes alır gibi kasılıp yükselir, gevşeyip süzülür; karanlıkta
/// soğuk bir ışık verir.
class Jellyfish extends PositionComponent {
  Jellyfish(Vector2 at, {this.seed = 0, this.bigness = 1})
    : _home = at.clone(),
      super(position: at, priority: 17);

  final Vector2 _home;
  final double seed;
  final double bigness;
  double _t = 0;

  /// İnip çıktığı yolun yarısı (px).
  double get swing => 10;

  /// Kasılma (0 gevşek, 1 kasık).
  double get pulse {
    final q = (_t * 0.55 + seed) % 1.0;
    return q < 0.25 ? math.sin(q / 0.25 * math.pi / 2) : 1 - (q - 0.25) / 0.75;
  }

  @override
  void update(double dt) {
    _t += dt;
    // Kasılınca yükselir, gevşeyince süzülüp iner.
    position.y = _home.y + math.cos(_t * 0.25 * math.pi * 2 + seed * 6) * swing;
    position.x = _home.x + math.sin(_t * 0.2 + seed * 3) * 8;
  }

  @override
  void render(Canvas canvas) {
    canvas.scale(bigness);
    final p = pulse;
    glowDot(canvas, Offset.zero, 46, const Color(0xFF9FE8FF), 0.22);
    final w = 15 - p * 4;
    final h = 10 + p * 3;
    final bell = Path()
      ..moveTo(-w, 2)
      ..quadraticBezierTo(-w, -h, 0, -h)
      ..quadraticBezierTo(w, -h, w, 2)
      ..quadraticBezierTo(w * 0.5, -1 + p * 2, 0, 1)
      ..quadraticBezierTo(-w * 0.5, -1 + p * 2, -w, 2)
      ..close();
    canvas.drawPath(
      bell,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(0, -4), w * 1.3, [
          const Color(0xFFDDF6FF).withValues(alpha: 0.85),
          const Color(0xFF7FCFEA).withValues(alpha: 0.35),
        ]),
    );
    final arm = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = const Color(0xFFBFE9F7).withValues(alpha: 0.55);
    for (var i = 0; i < 5; i++) {
      final x0 = -w * 0.7 + i * w * 0.35;
      final path = Path()..moveTo(x0, 1);
      for (var k = 1; k <= 6; k++) {
        path.lineTo(
          x0 * (1 - p * 0.25) + math.sin(_t * 2 + i + k * 0.8) * 2.5 * k / 6,
          1 + k * (5 + (1 - p) * 2),
        );
      }
      canvas.drawPath(path, arm);
    }
  }
}

/// Fenerbalığı: derinin bekçisi. Alnından sarkan yemin ışığı Kandilci
/// feneri gibi tarar; ışığına giren yutulur.
class AnglerFish extends PositionComponent {
  AnglerFish(Vector2 at, {this.facingLeft = true})
    : _home = at.clone(),
      super(position: at, priority: 18);

  final Vector2 _home;
  final bool facingLeft;
  double _t = 0;

  void tick(double dt) => _t += dt;

  @override
  void update(double dt) {
    tick(dt);
    position.x = _home.x + math.sin(_t * 0.25) * 30;
    position.y = _home.y + math.sin(_t * 0.6) * 6;
  }

  @override
  void render(Canvas canvas) {
    if (facingLeft) canvas.scale(-1, 1);
    final lure = Offset(46 + math.sin(_t * 1.3) * 3, -30 + math.cos(_t) * 2);
    // Yemin ışığı: soğuk, geniş.
    glowDot(canvas, lure, 120, kCold, 0.16);
    glowDot(canvas, lure, 26, kCold, 0.5);
    final ink = Paint()..color = const Color(0xFF020506);
    // Gövde: iri baş, kocaman ağız, sivri dişler.
    canvas.drawPath(
      Path()
        ..moveTo(-40, -6)
        ..quadraticBezierTo(-30, -30, 6, -28)
        ..quadraticBezierTo(34, -24, 40, -4)
        ..lineTo(26, 2)
        ..lineTo(38, 8)
        ..quadraticBezierTo(20, 26, -14, 20)
        ..quadraticBezierTo(-34, 14, -40, -6)
        ..moveTo(-38, -4)
        ..lineTo(-62, -18 + math.sin(_t * 3) * 4)
        ..lineTo(-56, 0)
        ..lineTo(-62, 16 + math.sin(_t * 3) * 4)
        ..close(),
      ink,
    );
    final teeth = Paint()..color = const Color(0xFFBFD8D2);
    for (var i = 0; i < 5; i++) {
      final x = 26.0 + i * 2.6;
      canvas.drawPath(
        Path()
          ..moveTo(x, 1.5)
          ..lineTo(x + 1, 6 - (i % 2) * 1.5)
          ..lineTo(x + 2, 1.5)
          ..close(),
        teeth,
      );
    }
    // Göz: küçük, soğuk.
    canvas.drawCircle(const Offset(18, -14), 2.2, Paint()..color = kCold);
    // Yemin sapı.
    canvas.drawPath(
      Path()
        ..moveTo(10, -27)
        ..quadraticBezierTo(30, -52, lure.dx, lure.dy),
      Paint()
        ..color = const Color(0xFF020506)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(lure, 3, Paint()..color = const Color(0xFFE8FFF8));
  }
}

// ================================================================ oynanış

/// Işık veren deniz canlıları: karanlık örtüde delik açar.
mixin SeaLight on Component {
  Offset get glowCenter;
  double get glowRadius;
  double get glowStrength;
}

/// Dipte bir yosun ormanı: sütun aralığına, dibin üstüne dikilir. Önde
/// çizilenler Sâye'yi saklar.
List<Kelp> kelpBed(Level lv, int c0, int c1, {int seed = 0}) {
  final out = <Kelp>[];
  final top = lv.def.seaSurface ?? 0;
  var i = 0;
  for (var x = c0 * kTile + 8.0; x < (c1 + 1) * kTile; x += 22 + (i % 3) * 5) {
    final c = (x / kTile).floor();
    // Dibi bul: yüzeyden aşağı ilk kaya; üstünde ne kadar boşluk var.
    var floor = -1;
    for (var r = top + 1; r < lv.height; r++) {
      if (lv.solid(c, r)) {
        floor = r;
        break;
      }
    }
    if (floor < 0) continue;
    var room = 0;
    for (var r = floor - 1; r > top && !lv.solid(c, r); r--) {
      room++;
    }
    final h = math.min(
      (room - 1.5) * kTile,
      (3.5 + ((i * 37 + seed * 11) % 40) / 10) * kTile,
    );
    if (h > kTile * 1.5) {
      out.add(
        Kelp(
          Vector2(x, floor * kTile + 4),
          h,
          front: i.isOdd,
          seed: i * 1.7 + seed,
        ),
      );
    }
    i++;
  }
  return out;
}

/// Kayaya çarpmadan süzülen deniz canlılarının ortak adımı.
bool _seaBlocked(Level lv, double x, double y, double rx, double ry) {
  for (final (dx, dy) in [(-rx, -ry), (rx, -ry), (-rx, ry), (rx, ry)]) {
    if (lv.solid(((x + dx) / kTile).floor(), ((y + dy) / kTile).floor())) {
      return true;
    }
  }
  return false;
}

/// Denizanası (tehlike): kasılıp yükselir, gevşeyip süzülür; dokunanı
/// sokar, geri savurur, nefesinden alır. Karanlıkta yolu da onun ışığı
/// gösterir.
class StingingJelly extends Jellyfish
    with SeaLight, HasGameReference<GolgeGame> {
  StingingJelly(int col, int row, this.travel)
    : super(
        Vector2((col + 0.5) * kTile, (row + 0.5) * kTile),
        seed: (col * 0.37 + row * 0.11) % 1.0,
        bigness: 1.1,
      );

  /// İnip çıktığı yol (kare).
  final int travel;
  double _cool = 0;

  @override
  double get swing => travel * kTile / 2;

  @override
  Offset get glowCenter => position.toOffset();
  @override
  double get glowRadius => 70;
  @override
  double get glowStrength => 0.55;

  @override
  void update(double dt) {
    super.update(dt);
    _cool -= dt;
    final p = game.player;
    if (p == null || p.isDead || _cool > 0) return;
    // Çan ve altına sarkan kollar.
    final d = p.center - position;
    final hit =
        d.x.abs() < 18 * bigness && d.y > -16 * bigness && d.y < 34 * bigness;
    if (!hit) return;
    _cool = 1.0;
    final away = d.length < 1 ? Vector2(0, 1) : d.normalized();
    p.velocity.setFrom(away * 250);
    game.breathe(-0.18);
    game.shake(4);
    GameAudio.instance.play('sting', volume: 0.35, minGapMs: 600);
    game.hint('jellyfish');
  }
}

/// Fenerbalığı: derinin bekçisi. Alnından sarkan yemin ışığına giren
/// görülür; bir an sonra fenerbalığı ağzını açıp üstüne atılır. Yosunda ya
/// da mürekkepte saklanan görülmez; salınan ateşböceği yemini başka yere
/// çeker (fenerbalığı ateşböceğini yutar, bir süre doyar).
class AnglerHunter extends AnglerFish
    with SeaLight, HasGameReference<GolgeGame> {
  AnglerHunter(int col, int row, this.range)
    : home = Vector2((col + 0.5) * kTile, (row + 0.5) * kTile),
      super(Vector2((col + 0.5) * kTile, (row + 0.5) * kTile));

  final Vector2 home;

  /// Gezindiği yarı genişlik (kare).
  final int range;

  static const double sight = 4.5 * kTile;
  static const double huntSpeed = 150;
  static const double cruise = 34;

  double _seen = 0;
  double _lost = 0;
  double _full = 0;
  double _patrolT = 0;
  bool hunting = false;
  int dir = -1;

  /// Yemin dünyadaki yeri.
  Vector2 get lure => position + Vector2(46.0 * dir, -30);

  /// Ağzın yeri.
  Vector2 get mouth => position + Vector2(30.0 * dir, 2);

  @override
  Offset get glowCenter => lure.toOffset();
  @override
  double get glowRadius => sight;
  @override
  double get glowStrength => hunting ? 0.85 : 0.65;

  @override
  bool get facingLeft => dir < 0;

  void _move(Vector2 to, double speed, double dt) {
    final d = to - position;
    final len = d.length;
    if (len < 2) return;
    final step = d / len * math.min(len, speed * dt);
    final lv = game.level;
    if (!_seaBlocked(lv, position.x + step.x, position.y + step.y, 34, 22)) {
      position.add(step);
    } else if (!_seaBlocked(lv, position.x + step.x, position.y, 34, 22)) {
      position.x += step.x;
    } else if (!_seaBlocked(lv, position.x, position.y + step.y, 34, 22)) {
      position.y += step.y;
    }
    if (step.x.abs() > 0.2) dir = step.x > 0 ? 1 : -1;
  }

  @override
  void update(double dt) {
    tick(dt);
    _full -= dt;
    final p = game.player;
    final lv = game.level;
    // Yem: salınan ateşböceği.
    FireflyLure? bait;
    if (_full <= 0) {
      var best = 9.0 * kTile;
      for (final l in game.world.children.whereType<FireflyLure>()) {
        if (!l.glowing) continue;
        final d = (l.position - position).length;
        if (d < best) {
          best = d;
          bait = l;
        }
      }
    }
    if (bait != null) {
      hunting = false;
      _seen = 0;
      _move(bait.position, huntSpeed * 0.8, dt);
      if ((mouth - bait.position).length < 24) {
        bait.removeFromParent();
        _full = 5;
        GameAudio.instance.play('growl', volume: 0.35);
      }
      return;
    }
    final visible =
        p != null &&
        !p.isDead &&
        !p.hidden &&
        (p.center - lure).length < sight &&
        lv.lineOfSight(lure, p.center);
    if (!hunting) {
      _seen = visible ? _seen + dt : math.max(0, _seen - dt * 2);
      if (_seen > 0.4 && p != null) {
        hunting = true;
        _lost = 0;
        GameAudio.instance.play('suspect', volume: 0.5, minGapMs: 1500);
        game.scare(0.5, sting: false);
        game.hint('angler');
      }
    }
    if (hunting && p != null) {
      final near = (p.center - position).length < 10 * kTile;
      _lost = (!p.hidden && near && !p.isDead) ? 0 : _lost + dt;
      if (_lost > 1.4) {
        hunting = false;
        _seen = 0;
      } else {
        _move(p.center - Vector2(30.0 * dir, 2), huntSpeed, dt);
        if (!p.isDead && (mouth - p.center).length < 22) {
          GameAudio.instance.play('growl', volume: 0.6);
          p.die(cause: DeathCause.dark);
          hunting = false;
        }
        return;
      }
    }
    // Devriye: evinin iki yanında ağır ağır.
    _patrolT += dt;
    final x =
        home.x +
        math.sin(_patrolT * cruise / (range * kTile + 1)) * range * kTile;
    _move(Vector2(x, home.y + math.sin(_patrolT * 0.6) * 6), cruise * 1.6, dt);
  }
}

/// Ahtapot: dibe yapışık durur; dokunulunca mürekkep bırakıp kaçar.
/// Mürekkep suyun içinde gölgedir: içindeki görünmez.
class Octopus extends PositionComponent with HasGameReference<GolgeGame> {
  Octopus(int col, int row)
    : super(
        position: Vector2((col + 0.5) * kTile, (row + 1) * kTile - 6),
        priority: 18,
      );

  double _t = 0;
  double _cool = 0;
  double _dart = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _cool -= dt;
    _dart = math.max(0, _dart - dt);
    final p = game.player;
    if (p == null || p.isDead || _cool > 0) return;
    if ((p.center - position).length > 26) return;
    _cool = 7;
    _dart = 1.2;
    game.world.add(InkCloud(position.clone()));
    GameAudio.instance.play('splash', volume: 0.25);
    game.hint('octopus');
  }

  @override
  void render(Canvas canvas) {
    final ink = Paint()..color = const Color(0xFF07100F);
    // Kaçarken bir an kenara fırlar, sonra yerine döner.
    final off = math.sin(_dart / 1.2 * math.pi) * 18;
    canvas.translate(off, -off * 0.6);
    final squeeze = 1 + math.sin(_t * 1.6) * 0.06;
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, -12),
        width: 22 / squeeze,
        height: 20 * squeeze,
      ),
      ink,
    );
    final arm = Paint()
      ..color = const Color(0xFF07100F)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final x0 = -8 + i * 3.2;
      final path = Path()..moveTo(x0, -4);
      for (var k = 1; k <= 5; k++) {
        final side = (i - 2.5) * 3.2;
        path.lineTo(
          x0 + side * k / 5 + math.sin(_t * 2 + i + k) * 1.6,
          -4 + k * 1.6 - (k > 3 ? (k - 3) * 1.4 : 0),
        );
      }
      arm.strokeWidth = 2.6 - i % 2 * 0.6;
      canvas.drawPath(path, arm);
    }
    final eye = Paint()..color = const Color(0xFFE8D9A8);
    canvas.drawCircle(const Offset(-4, -12), 1.6, eye);
    canvas.drawCircle(const Offset(4, -12), 1.6, eye);
  }
}

/// Mürekkep bulutu: suyun içinde birkaç saniye süren gölge.
class InkCloud extends PositionComponent {
  InkCloud(Vector2 at) : super(position: at, priority: 32);

  static const double life = 5.5;
  static const double maxRadius = 2.6 * kTile;
  double _t = 0;

  double get radius =>
      maxRadius *
      math.min(1, _t / 0.5) *
      (1 - _ramp(_t, life - 1.2, life) * 0.3);

  /// Gizler mi (dağılırken artık gizlemez).
  bool covers(Vector2 p) =>
      _t < life - 0.8 && (p - position).length < radius * 0.85;

  @override
  void update(double dt) {
    _t += dt;
    position.y -= 6 * dt;
    if (_t > life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final fade = 1 - _ramp(_t, life - 1.5, life);
    final paint = Paint();
    for (var i = 0; i < 7; i++) {
      final a = i * 0.9 + _t * 0.4;
      final o = Offset(math.cos(a), math.sin(a)) * radius * 0.35;
      paint.color = const Color(0xFF030606).withValues(alpha: 0.55 * fade);
      canvas.drawCircle(o, radius * (0.55 + (i % 3) * 0.12), paint);
    }
  }
}

double _ramp(double t, double a, double b) {
  final x = ((t - a) / (b - a)).clamp(0.0, 1.0);
  return x * x * (3 - 2 * x);
}

/// Akıntı: noktalar boyunca akar; içindeki Sâye akış yönünde itilir.
/// Kulaçla akıntıdan çıkılır; akıntıya karşı kulaç az ilerletir.
class SeaCurrent extends Component with HasGameReference<GolgeGame> {
  SeaCurrent(List<(int, int)> cells)
    : points = [
        for (final (c, r) in cells)
          Offset((c + 0.5) * kTile, (r + 0.5) * kTile),
      ],
      super(priority: 15);

  final List<Offset> points;
  static const double radius = 1.5 * kTile;
  static const double push = 540;
  static const double flow = 230;
  double _t = 0;

  late final double _total = () {
    var t = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      t += (points[i + 1] - points[i]).distance;
    }
    return t;
  }();

  /// Noktanın akışa uzaklığı ve oradaki akış yönü.
  (double, Offset) nearest(Offset p) {
    var best = double.infinity;
    var dir = const Offset(1, 0);
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final ab = points[i + 1] - a;
      final len = ab.distance;
      final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / (len * len)).clamp(
        0.0,
        1.0,
      );
      final d = (p - (a + ab * t)).distance;
      if (d < best) {
        best = d;
        dir = ab / len;
      }
    }
    return (best, dir);
  }

  @override
  void update(double dt) {
    _t += dt;
    final p = game.player;
    if (p == null || p.isDead || !p.swimming) return;
    final (d, dir) = nearest(p.center.toOffset());
    if (d > radius) return;
    // Akış hızına doğru itilir (akıştan hızlı giden yavaşlatılmaz).
    final along = p.velocity.x * dir.dx + p.velocity.y * dir.dy;
    if (along < flow) {
      final k = push * dt * (d < radius * 0.6 ? 1 : 0.5);
      p.velocity.x += dir.dx * k;
      p.velocity.y += dir.dy * k;
    }
    game.hint('current');
  }

  @override
  void render(Canvas canvas) {
    // Akan çizgiler: yol boyunca kayan ince kabarcık izleri.
    final paint = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final n = (_total / 26).floor();
    for (var i = 0; i < n; i++) {
      final s = (i * 26 + _t * flow * 0.8) % _total;
      var rem = s;
      var at = points.first;
      var dir = const Offset(1, 0);
      for (var k = 0; k < points.length - 1; k++) {
        final ab = points[k + 1] - points[k];
        final len = ab.distance;
        if (rem <= len) {
          at = points[k] + ab * (rem / len);
          dir = ab / len;
          break;
        }
        rem -= len;
      }
      final side = Offset(-dir.dy, dir.dx) * (math.sin(i * 2.3) * radius * 0.7);
      final fade = math.sin(math.pi * s / _total);
      paint.color = const Color(0xFFDDF2EE).withValues(alpha: 0.4 * fade);
      final c = at + side;
      canvas.drawLine(c, c - dir * 14, paint);
    }
  }
}

/// Dipteki kaynak: kabarcık sütunu yükselir. İçinden geçen nefes tazeler,
/// yukarı taşınır.
class BubbleVent extends Component with SeaLight, HasGameReference<GolgeGame> {
  BubbleVent(int col, int row)
    : base = Vector2((col + 0.5) * kTile, (row + 1) * kTile),
      super(priority: 16);

  final Vector2 base;
  late double top;
  double _t = 0;

  @override
  Offset get glowCenter => base.toOffset().translate(0, -10);
  @override
  double get glowRadius => 50;
  @override
  double get glowStrength => 0.35;

  @override
  void onLoad() {
    // Sütun ilk kayaya ya da suyun yüzüne dek.
    final lv = game.level;
    final c = (base.x / kTile).floor();
    var r = (base.y / kTile).floor() - 1;
    while (r > 0 &&
        !lv.solid(c, r - 1) &&
        lv.inWater(base.x, (r - 0.5) * kTile)) {
      r--;
    }
    top = r * kTile.toDouble();
  }

  bool inside(Vector2 p) =>
      (p.x - base.x).abs() < kTile * 0.7 && p.y < base.y && p.y > top;

  @override
  void update(double dt) {
    _t += dt;
    final p = game.player;
    if (p == null || p.isDead || !inside(p.center)) return;
    game.breathe(dt * 0.8);
    if (p.swimming) p.velocity.y = math.max(p.velocity.y - 420 * dt, -200);
    game.hint('bubbles');
  }

  @override
  void render(Canvas canvas) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final h = base.y - top;
    for (var i = 0; i < 26; i++) {
      final k = ((_t * (0.35 + (i % 4) * 0.05) + i / 26) % 1.0);
      final y = base.y - k * h;
      final x = base.x + math.sin(_t * 3 + i * 1.7) * 7 * (0.4 + k);
      ring.color = const Color(0xFFDDF4F0)
          .withValues(alpha: 0.55 * (1 - k * 0.6));
      canvas.drawCircle(Offset(x, y), 1.2 + (i % 3) * 0.9 + k * 1.2, ring);
    }
    canvas.drawOval(
      Rect.fromCenter(center: base.toOffset(), width: 20, height: 6),
      Paint()..color = const Color(0xFF020606),
    );
  }
}

/// Su kaplumbağası: akıntı koridorunun başında bekler. Dokunan Sâye'yi
/// sırtında yolun sonuna dek taşır; sonra ağır ağır başa döner.
class SeaTurtle extends PositionComponent with HasGameReference<GolgeGame> {
  SeaTurtle(List<(int, int)> cells)
    : path = [
        for (final (c, r) in cells)
          Vector2((c + 0.5) * kTile, (r + 0.5) * kTile),
      ],
      super(priority: 19) {
    position.setFrom(path.first);
  }

  final List<Vector2> path;
  static const double speed = 240;
  static const double back = 70;

  /// 0: bekler, 1: taşır, 2: başa döner.
  int mode = 0;
  int _seg = 0;
  double _t = 0;
  double _wait = 0;
  int dir = 1;

  bool get carrying => mode == 1;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    switch (mode) {
      case 0:
        position.y = path.first.y + math.sin(_t * 1.2) * 4;
        if (p != null &&
            !p.isDead &&
            p.swimming &&
            (p.center - position).length < 30) {
          mode = 1;
          _seg = 0;
          p.carrier = this;
          GameAudio.instance.play('glide', volume: 0.5);
          game.hint('turtle');
        }
      case 1:
        if (p == null || p.isDead) {
          mode = 2;
          return;
        }
        if (!_advance(path, speed, dt)) {
          // Yolun sonu: Sâye akışın hızıyla bırakılır.
          final d = path.last - path[path.length - 2];
          p.velocity.setFrom(d.normalized() * speed * 0.7);
          p.carrier = null;
          mode = 2;
          _wait = 1.5;
          _seg = path.length - 1;
          return;
        }
        p.position.setValues(
          position.x - Player.w / 2,
          position.y - 22 - Player.h / 2,
        );
        final d = path[math.min(_seg + 1, path.length - 1)] - position;
        if (d.length > 0.1) p.velocity.setFrom(d.normalized() * speed);
      case 2:
        _wait -= dt;
        if (_wait > 0) return;
        if (!_advance(path.reversed.toList(), back, dt, reversed: true)) {
          mode = 0;
        }
    }
  }

  /// Yolda ilerler; yol bitince false.
  bool _advance(
    List<Vector2> pts,
    double v,
    double dt, {
    bool reversed = false,
  }) {
    var seg = reversed ? (path.length - 1 - _seg) : _seg;
    var left = v * dt;
    while (seg < pts.length - 1) {
      final to = pts[seg + 1];
      final d = to - position;
      final len = d.length;
      if (len > 0.5) dir = d.x >= 0 ? 1 : -1;
      if (len > left) {
        position.add(d / len * left);
        _seg = reversed ? path.length - 1 - seg : seg;
        return true;
      }
      position.setFrom(to);
      left -= len;
      seg++;
    }
    _seg = reversed ? 0 : path.length - 1;
    return false;
  }

  @override
  void render(Canvas canvas) {
    if (dir < 0) canvas.scale(-1, 1);
    final ink = Paint()..color = const Color(0xFF071312);
    final paddle = math.sin(_t * (mode == 1 ? 7 : 2.5));
    // Yüzgeçler.
    for (final (x, s) in const [(14.0, 1.0), (-14.0, -1.0)]) {
      canvas.save();
      canvas.translate(x, 6);
      canvas.rotate(0.6 * paddle * s + 0.5);
      canvas.drawOval(const Rect.fromLTWH(-4, 0, 8, 20), ink);
      canvas.restore();
    }
    // Kabuk ve baş.
    canvas.drawOval(const Rect.fromLTWH(-26, -12, 52, 26), ink);
    canvas.drawOval(const Rect.fromLTWH(22, -4, 16, 11), ink);
    final plate = Paint()
      ..color = const Color(0xFF2E5450)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawOval(const Rect.fromLTWH(-17, -8, 34, 16), plate);
    canvas.drawLine(const Offset(-6, -11), const Offset(-6, 12), plate);
    canvas.drawLine(const Offset(7, -11), const Offset(7, 12), plate);
    canvas.drawCircle(
      const Offset(33, -1),
      1.4,
      Paint()..color = const Color(0xFFE8D9A8),
    );
  }
}

/// Yüzeyde Kandilci sandalı: ağır ağır gidip gelir; fenerinin ışığı suya
/// iner. Işıkta görünen Sâye'yi Kandilci görür.
class LanternBoat extends PositionComponent
    with SeaLight, HasGameReference<GolgeGame> {
  LanternBoat(this.c0, this.c1, double surface)
    : super(
        position: Vector2((c0 + 1) * kTile.toDouble(), surface),
        priority: 33,
      );

  final int c0;
  final int c1;
  static const double reach = 7.5 * kTile;
  static const double spread = 0.33;
  double _t = 0;
  double _seen = 0;
  int dir = 1;

  /// Fenerin yeri (sandalın önünde, suyun hemen üstünde).
  Vector2 get lamp => position + Vector2(22.0 * dir, -14);

  /// Işığın ekseni (aşağı doğru, salınır).
  double get beamAngle => math.pi / 2 + math.sin(_t * 0.7) * 0.45;

  @override
  Offset get glowCenter => lamp.toOffset();
  @override
  double get glowRadius => 90;
  @override
  double get glowStrength => 0.8;

  bool lit(Vector2 p) {
    final d = p - lamp;
    final len = d.length;
    if (len > reach || len < 1) return false;
    var a = math.atan2(d.y, d.x) - beamAngle;
    while (a > math.pi) {
      a -= 2 * math.pi;
    }
    while (a < -math.pi) {
      a += 2 * math.pi;
    }
    return a.abs() < spread;
  }

  Path beam([double k = 1]) {
    final a = beamAngle;
    final l = lamp.toOffset() - position.toOffset();
    final s = spread * k;
    return Path()
      ..moveTo(l.dx, l.dy)
      ..lineTo(l.dx + math.cos(a - s) * reach, l.dy + math.sin(a - s) * reach)
      ..lineTo(l.dx + math.cos(a + s) * reach, l.dy + math.sin(a + s) * reach)
      ..close();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    position.x += dir * 28 * dt;
    if (position.x > c1 * kTile) dir = -1;
    if (position.x < c0 * kTile) dir = 1;
    position.y = (game.level.seaTop ?? position.y) + math.sin(_t * 1.3) * 2;
    final p = game.player;
    if (p == null || p.isDead) return;
    final seen =
        !p.hidden && lit(p.center) && game.level.lineOfSight(lamp, p.center);
    _seen = seen ? _seen + dt : math.max(0, _seen - dt);
    if (seen) game.hint('boat');
    if (_seen > 0.45) {
      _seen = 0;
      p.die(cause: DeathCause.light);
    }
  }

  @override
  void render(Canvas canvas) {
    // Işık: suya inen soğuk koni.
    canvas.drawPath(
      beam(),
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(
          lamp.toOffset() - position.toOffset(),
          reach,
          [kCold.withValues(alpha: 0.22), kCold.withValues(alpha: 0)],
        ),
    );
    if (dir < 0) canvas.scale(-1, 1);
    final ink = Paint()..color = const Color(0xFF050909);
    // Sandal.
    canvas.drawPath(
      Path()
        ..moveTo(-34, -10)
        ..lineTo(34, -10)
        ..quadraticBezierTo(28, 6, 0, 6)
        ..quadraticBezierTo(-28, 6, -34, -10)
        ..close(),
      ink,
    );
    // Kandilci: oturmuş, fenerli sırık önde.
    canvas.drawOval(const Rect.fromLTWH(-12, -30, 14, 22), ink);
    canvas.drawCircle(const Offset(-5, -36), 6, ink);
    canvas.drawLine(
      const Offset(0, -24),
      const Offset(22, -20),
      Paint()
        ..color = const Color(0xFF050909)
        ..strokeWidth = 2,
    );
    glowDot(canvas, const Offset(22, -14), 28, kCold, 0.6);
    canvas.drawRect(
      Rect.fromCenter(center: const Offset(22, -14), width: 6, height: 8),
      Paint()..color = const Color(0xFFDFFFF6),
    );
  }
}

/// Ak Ana: dipteki yarığın ağzında, nefes biterken suyun kendisi ak bir
/// ışıkla kıpırdar; Ak Ana yükselir, Sâye'ye ak bir nefes verir, Körmösler
/// dağılır. Sonra yarık açılır.
class AkAnaSea extends PositionComponent
    with SeaLight, HasGameReference<GolgeGame> {
  AkAnaSea(int col, int row)
    : super(
        position: Vector2((col + 0.5) * kTile, (row + 1) * kTile),
        priority: 27,
      );

  static const double drawScale = 0.9;
  double _t = -1;
  double alpha = 0.0;
  bool get risen => _t >= 0;

  @override
  Offset get glowCenter => position.toOffset().translate(0, -60);
  @override
  double get glowRadius => 260;
  @override
  double get glowStrength => 0.95 * alpha;

  @override
  void update(double dt) {
    super.update(dt);
    final p = game.player;
    if (_t < 0) {
      if (p == null || p.isDead) return;
      if ((p.center - position).length > 9 * kTile) return;
      _t = 0;
      game.akNefes = true;
      game.breathe(1);
      game.meetMyth('akAna');
      game.scare(0.3, sting: false);
      GameAudio.instance.play('memory', volume: 0.8);
      GameAudio.instance.play('bell', volume: 0.4);
      for (final k in game.world.children.whereType<Kormos>()) {
        k.scatter();
      }
      return;
    }
    _t += dt;
    alpha = math.min(1.0, _t / 2.5);
  }

  @override
  void render(Canvas canvas) {
    if (alpha <= 0) return;
    glowDot(
      canvas,
      const Offset(0, -60),
      220,
      const Color(0xFFF4FBFF),
      0.35 * alpha,
    );
    canvas.saveLayer(
      Rect.fromCenter(center: const Offset(0, -80), width: 400, height: 400),
      Paint()..color = Color.fromRGBO(0, 0, 0, alpha.toDouble()),
    );
    final rise = (1.0 - math.min(1.0, _t / 3)) * 80;
    canvas.translate(0, rise);
    canvas.scale(drawScale);
    MythFigures.akAna(canvas, _t);
    canvas.restore();
  }
}
