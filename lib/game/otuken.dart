import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'audio.dart';
import 'deer_rig.dart';
import 'entities.dart';
import 'golge_game.dart';
import 'heavens.dart';
import 'level.dart';
import 'myth_figures.dart';
import 'persist.dart';
import 'player.dart';
import 'puzzles.dart';
import 'strings.dart';

// XIV · Ötüken Ormanı (docs/UZATMA_PLANI.md): yaprak arasından düşen ışık,
// gölgede bekleyen Karabasan, Ak Geyik ve kökleri, Hayat Ağacı'nın tepesinde
// aşağı indirilen güneş.

/// Bir noktayı aydınlatan ateşböceği var mı (salınan, hâlâ parlayan)?
bool lureLights(GolgeGame game, Offset at, {double radius = 3.2 * kTile}) {
  for (final l in game.world.children.whereType<FireflyLure>()) {
    if (!l.glowing) continue;
    if ((Offset(l.position.x, l.position.y) - at).distance < radius) {
      return true;
    }
  }
  return false;
}

/// Yaprak arasından ışık düşen orman: ışıkta güvendesin, gölgede Karabasan
/// bekler. Gölgede kalınca karanlıktan eller uzanır, göğüs daralır; çok
/// kalan yutulur. Rüzgâr esince huzmeler kayar (önce yapraklar hışırdar),
/// bulut geçince huzmeler sırayla söner (önce titrer).
class GladeZone extends PositionComponent with HasGameReference<GolgeGame> {
  GladeZone(this.area, this.beams, {required this.wind}) : super(priority: 23);

  final Rect area;

  /// Huzmelerin yere değdiği yerin x'i (dünya).
  final List<double> beams;

  /// 0 durgun, 1 huzmeler kayar, 2 huzmeler sırayla söner.
  final int wind;

  double _t = 0;
  bool _awake = false;

  /// 0-1: gölgede geçen süre; 1 olunca Karabasan yutar.
  double dread = 0;

  /// Bir kez ışığa giren kuralı öğrenmiştir (ilk seferde daha yavaş dolar).
  bool _learned = false;
  bool _inside = false;
  double _rustleT = 0;

  /// Alanın altı çoğunlukla zemin mi (karanlığın aşağı erimesine gerek yok).
  late final bool _groundBelow = () {
    final r = (area.bottom / kTile).floor();
    final c0 = (area.left / kTile).floor();
    final c1 = (area.right / kTile).ceil();
    var solid = 0;
    for (var c = c0; c < c1; c++) {
      if (game.level.solid(c, r)) solid++;
    }
    return solid > (c1 - c0) * 0.6;
  }();

  /// Huzmenin yarı genişliği.
  static const double half = 1.5 * kTile;

  /// Gölgede bu kadar saniye kalan yutulur.
  static const double dreadTime = 1.6;
  static const double swayTiles = 2.5;
  static const double swayPeriod = 7.0;
  static const double pulsePeriod = 4.2;

  static double _ease(double v) => v * v * (3 - 2 * v);

  /// Rüzgârlı alanda huzmelerin kayması (-1..1).
  double get _sway {
    final u = (_t % swayPeriod) / swayPeriod * 2;
    if (u < 0.74) return -1;
    if (u < 1.0) return -1 + 2 * _ease((u - 0.74) / 0.26);
    if (u < 1.74) return 1;
    return 1 - 2 * _ease((u - 1.74) / 0.26);
  }

  /// Rüzgâr esmek üzere: yapraklar hışırdar (0-1).
  double get rustle {
    if (wind != 1) return 0;
    final u = (_t % swayPeriod) / swayPeriod * 2;
    for (final start in [0.74, 1.74]) {
      final d = start - u;
      if (d > 0 && d < 0.26) return 1 - d / 0.26;
      if (d <= 0 && d > -0.26) return 1;
    }
    return 0;
  }

  /// Huzmelerin eğikliği: yerden yukarı çıktıkça sola kayma (piksel başına).
  /// Ağaç gibi yüksek alanlarda huzme dik iner (yoksa yukarıdaki dallarda
  /// görünen ışıkla güvenli yer birbirini tutmaz).
  double get slant => area.height > area.width ? 0 : 0.18;

  /// Huzmenin [y] yüksekliğindeki x'i (çizimle aynı eğiklik).
  double beamXAt(int i, double y) =>
      beamX(i) - slant * math.max(0, area.bottom - kTile - y);

  double beamX(int i) => beams[i] + (wind == 1 ? _sway * swayTiles * kTile : 0);

  /// Huzmenin gücü: 1 tam, 0 sönük. Sönmeden önce titrer.
  double beamOn(int i) {
    if (wind != 2) return 1;
    final ph = (_t + (i.isOdd ? pulsePeriod / 2 : 0)) % pulsePeriod;
    if (ph < 2.0) return 1;
    if (ph < 2.6) return 0.72 + 0.28 * math.cos((ph - 2.0) * 26);
    if (ph < 2.9) return 0.72 * (1 - (ph - 2.6) / 0.3);
    if (ph < 3.9) return 0;
    return (ph - 3.9) / 0.3;
  }

  /// Huzmenin daha kaç saniye yanacağı (sönen alanlarda; öbürlerinde hep).
  double litLeft(int i) {
    if (wind != 2) return double.infinity;
    final ph = (_t + (i.isOdd ? pulsePeriod / 2 : 0)) % pulsePeriod;
    // Güç 0.5'in altına 2.75'te iner, 4.05'te yeniden çıkar.
    if (ph < 2.75) return 2.75 - ph;
    if (ph >= 4.05) return 2.75 + pulsePeriod - ph;
    return 0;
  }

  /// x'e huzme düşüyor mu?
  bool beamCovers(double x, [double? y]) {
    for (var i = 0; i < beams.length; i++) {
      final on = beamOn(i);
      if (on < 0.5) continue;
      final bx = y == null ? beamX(i) : beamXAt(i, y);
      if ((x - bx).abs() < half * (0.6 + 0.4 * on)) return true;
    }
    return false;
  }

  /// Nokta aydınlık mı: huzme, ateşböceği ya da (istenirse) Ak Geyik'in
  /// ışığı.
  bool lit(Offset at, {bool deer = true}) {
    if (!area.contains(at)) return true;
    if (beamCovers(at.dx, at.dy)) return true;
    if (lureLights(game, at)) return true;
    if (deer) {
      for (final d in game.world.children.whereType<AkGeyik>()) {
        if (d.shines(at)) return true;
      }
    }
    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final p = game.player;
    if (!_awake &&
        p != null &&
        area.inflate(4 * kTile).contains(Offset(p.center.x, p.center.y))) {
      _awake = true;
    }
    if (_awake) _t += dt;
    // Rüzgâr öncesi hışırtı duyulur (yakındaysa).
    final r = rustle;
    if (r > 0 && r < 1 && _awake) {
      _rustleT -= dt;
      if (_rustleT <= 0 && _inside) {
        _rustleT = 2;
        GameAudio.instance.play('gust', volume: 0.35, minGapMs: 1500);
      }
    }
    if (p == null || p.isDead) {
      dread = 0;
      return;
    }
    final at = Offset(p.center.x, p.center.y);
    final inside = area.contains(at);
    if (!inside) {
      if (_inside) GameAudio.instance.dread(0);
      _inside = false;
      dread = math.max(0, dread - dt * 1.5);
      return;
    }
    _inside = true;
    if (lit(at)) {
      _learned = true;
      dread = math.max(0, dread - dt * 1.2);
    } else {
      game.once('gladeDark', S.of('gladeDark'), hint: true);
      dread += dt / (_learned ? dreadTime : dreadTime * 1.9);
      if (dread >= 1) {
        dread = 0;
        GameAudio.instance.play('growl', volume: 0.9);
        p.die(cause: DeathCause.dark);
      }
    }
    GameAudio.instance.dread((dread * 0.95).clamp(0.0, 1.0));
  }

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect;
    if (!view.overlaps(area.inflate(2 * kTile))) return;
    final layer = Rect.fromLTRB(
      math.max(area.left - kTile, view.left - 40),
      math.max(area.top - 2 * kTile, view.top - 40),
      math.min(area.right + kTile, view.right + 40),
      math.min(area.bottom + 8, view.bottom + 40),
    );
    if (layer.width <= 0 || layer.height <= 0) return;
    final ground = area.bottom - kTile;
    // Yaprak örtüsünün gölgesi; huzmeler onu deler.
    canvas.saveLayer(layer, Paint());
    canvas.drawRect(
      layer,
      Paint()
        ..shader = ui.Gradient.linear(layer.topCenter, layer.bottomCenter, [
          const Color(0xFF02060A).withValues(alpha: 0.86),
          const Color(0xFF040A0C).withValues(alpha: 0.72),
        ]),
    );
    final cut = Paint()..blendMode = BlendMode.dstOut;
    final skew = (ground - layer.top) * slant;
    for (var i = 0; i < beams.length; i++) {
      final on = beamOn(i);
      if (on <= 0.01) continue;
      final x = beamX(i);
      final w = half * (0.6 + 0.4 * on);
      cut.shader = ui.Gradient.linear(
        Offset(x - w * 1.3, 0),
        Offset(x + w * 1.3, 0),
        [
          const Color(0x00000000),
          Color.fromRGBO(0, 0, 0, on),
          Color.fromRGBO(0, 0, 0, on),
          const Color(0x00000000),
        ],
        const [0, 0.22, 0.78, 1],
      );
      canvas.drawPath(
        Path()
          ..moveTo(x - w * 1.3 - skew, layer.top)
          ..lineTo(x + w * 1.3 - skew, layer.top)
          ..lineTo(x + w * 1.3, ground + 8)
          ..lineTo(x - w * 1.3, ground + 8)
          ..close(),
        cut,
      );
    }
    // Ateşböceği ve Ak Geyik de karanlığı deler.
    for (final l in game.world.children.whereType<FireflyLure>()) {
      if (!l.glowing) continue;
      final c = Offset(l.position.x, l.position.y);
      canvas.drawCircle(
        c,
        2.8 * kTile,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..shader = ui.Gradient.radial(
            c,
            2.8 * kTile,
            const [Color(0xFF000000), Color(0xCC000000), Color(0x00000000)],
            const [0, 0.6, 1],
          ),
      );
    }
    for (final d in game.world.children.whereType<AkGeyik>()) {
      final c = d.glowCenter;
      canvas.drawCircle(
        c,
        AkGeyik.glow,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..shader = ui.Gradient.radial(c, AkGeyik.glow, [
            Color.fromRGBO(0, 0, 0, 0.9 * d.alpha),
            const Color(0x00000000),
          ]),
      );
    }
    // Kenarlarda erir.
    canvas.drawRect(
      layer,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          Offset(area.left - kTile, 0),
          Offset(area.right + kTile, 0),
          const [
            Color(0x00000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0x00000000),
          ],
          const [0, 0.07, 0.93, 1],
        ),
    );
    canvas.restore();
    // Alanın altında (çukur, bataklık) karanlık birden kesilmesin: erir.
    // Altı zeminse gerek yok (yoksa zeminin üstünde kenarlı bir şerit kalır).
    final below = Rect.fromLTRB(
      layer.left,
      ground + 8,
      layer.right,
      ground + 8 + 5 * kTile,
    );
    if (!_groundBelow) {
      canvas.drawRect(
        below,
        Paint()
          ..shader = ui.Gradient.linear(below.topCenter, below.bottomCenter, [
            const Color(0xFF040A0C).withValues(alpha: 0.72),
            const Color(0x00040A0C),
          ]),
      );
    }

    // Basılacak kökler karanlıkta da seçilsin: üstlerinde soluk yosun.
    final rim = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final d in game.world.children.whereType<DrumCloud>()) {
      final r = d.toRect();
      if (!r.overlaps(layer)) continue;
      final y = r.top + 2 + (1 - d.shown) * 26;
      rim.color = const Color(0xFFC8E0A0).withValues(alpha: 0.55 * d.shown);
      canvas.drawLine(Offset(r.left + 2, y), Offset(r.right - 2, y), rim);
    }

    // Huzmeler: sabah ışığı, içinde polen ve toz.
    final ray = Paint()..blendMode = BlendMode.plus;
    final mote = Paint();
    for (var i = 0; i < beams.length; i++) {
      final on = beamOn(i);
      if (on <= 0.01) continue;
      final x = beamX(i);
      final w = half * (0.6 + 0.4 * on);
      ray.shader = ui.Gradient.linear(
        Offset(0, layer.top),
        Offset(0, ground + 8),
        [
          const Color(0xFFFFF2B8).withValues(alpha: 0.08 * on),
          const Color(0xFFFFE9A0).withValues(alpha: 0.3 * on),
        ],
      );
      canvas.drawPath(
        Path()
          ..moveTo(x - w * 0.9 - skew, layer.top)
          ..lineTo(x + w * 0.9 - skew, layer.top)
          ..lineTo(x + w, ground + 8)
          ..lineTo(x - w, ground + 8)
          ..close(),
        ray,
      );
      // Yerde ışık lekesi.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, ground + 2),
          width: w * 2.4,
          height: 14,
        ),
        Paint()
          ..shader = ui.Gradient.radial(Offset(x, ground + 2), w * 1.2, [
            const Color(0xFFFFF0B0).withValues(alpha: 0.7 * on),
            const Color(0x00FFF0B0),
          ]),
      );
      for (var k = 0; k < 7; k++) {
        final h = ((i * 7 + k) * 40503) & 0xffff;
        final u = (_t * (0.05 + (h % 5) * 0.01) + (h % 97) / 97) % 1.0;
        final my = ground - u * (ground - layer.top);
        final mx =
            x -
            skew * (1 - (my - layer.top) / (ground - layer.top)) +
            ((h % 100) / 50 - 1) * w * 0.7 +
            math.sin(_t + k) * 5;
        mote.color = const Color(0xFFFFF8D8).withValues(alpha: 0.6 * on);
        canvas.drawCircle(Offset(mx, my), 1.3, mote);
      }
    }
    // Rüzgâr öncesi düşen yapraklar.
    final rs = rustle;
    if (rs > 0) {
      final leaf = Paint()
        ..color = const Color(0xFF9DC46A).withValues(alpha: 0.8 * rs);
      for (var k = 0; k < 14; k++) {
        final h = (k * 2654435761) & 0xffff;
        final lx = area.left + (h % 1000) / 1000 * area.width;
        final fall = (_t * (0.5 + (h % 7) * 0.08) + (h % 13) / 13) % 1.0;
        final ly = area.top + fall * (ground - area.top);
        canvas.save();
        canvas.translate(lx + math.sin(_t * 3 + k) * 14, ly);
        canvas.rotate(_t * 4 + k);
        canvas.drawOval(const Rect.fromLTWH(-3, -1.5, 6, 3), leaf);
        canvas.restore();
      }
    }
    _renderWatchers(canvas, ground);
    _renderDread(canvas);
  }

  /// Gölgede bekleyen gözler: ışıksız yerlerde ara ara açılıp kapanır.
  void _renderWatchers(Canvas canvas, double ground) {
    final eye = Paint();
    final n = (area.width / (5 * kTile)).floor();
    for (var k = 0; k < n; k++) {
      final h = ((k + 3) * 2246822519) & 0xffff;
      final x = area.left + (k + 0.5) * area.width / n + (h % 60) - 30;
      if (beamCovers(x) || beamCovers(x + 12) || beamCovers(x - 12)) continue;
      final y = ground - (1.2 + (h % 30) / 10) * kTile;
      final cyc = (_t * 0.35 + (h % 89) / 89) % 1.0;
      final open = cyc < 0.45 ? math.sin(cyc / 0.45 * math.pi) : 0.0;
      if (open <= 0.02) continue;
      eye.color = const Color(0xFFE8DCC8).withValues(alpha: 0.55 * open);
      for (final dx in [-6.0, 6.0]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x + dx, y),
            width: 6,
            height: 2.6 * open,
          ),
          eye,
        );
      }
    }
  }

  /// Gölgede kalınca Karabasan yaklaşır: karanlıktan kollar uzanır, iki göz
  /// açılır.
  void _renderDread(Canvas canvas) {
    final p = game.player;
    if (p == null || dread <= 0.02) return;
    // En yakın ışığın öbür yanından gelir.
    var nearest = p.center.x + 200;
    var best = double.infinity;
    for (var i = 0; i < beams.length; i++) {
      final d = (beamX(i) - p.center.x).abs();
      if (d < best) {
        best = d;
        nearest = beamX(i);
      }
    }
    final side = p.center.x >= nearest ? 1.0 : -1.0;
    final k = _ease(dread.clamp(0.0, 1.0));
    final origin = Offset(
      p.center.x + side * (4.2 - 2.4 * k) * kTile,
      p.center.y - 6,
    );
    canvas.drawCircle(
      origin,
      70 + 30 * k,
      Paint()
        ..shader = ui.Gradient.radial(origin, 70 + 30 * k, [
          const Color(0xFF020101).withValues(alpha: 0.85 * k),
          const Color(0x00020101),
        ]),
    );
    final arm = Paint()
      ..color = const Color(0xFF020101).withValues(alpha: 0.92 * k)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final target = Offset(p.center.x, p.center.y);
    for (var i = 0; i < 5; i++) {
      final reach = k * (0.75 + 0.06 * i);
      Offset at(double u) {
        final base = Offset.lerp(origin, target, u * reach)!;
        return base +
            Offset(
              0,
              (i - 2) * 9 * (1 - u) +
                  10 * math.sin(_t * 6 + i * 1.7 - u * 4) * u,
            );
      }

      for (var seg = 0; seg < 4; seg++) {
        arm.strokeWidth = (7 - i % 3 * 1.4) * (1 - seg / 4 * 0.7);
        canvas.drawLine(at(seg / 4), at((seg + 1) / 4), arm);
      }
    }
    final eye = Paint()
      ..color = const Color(0xFFE8DCC8).withValues(alpha: 0.85 * k);
    for (final dx in [-7.0, 7.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: origin + Offset(dx - side * 6, -12),
          width: 8,
          height: 3.4 * k,
        ),
        eye,
      );
    }
  }
}

/// Ak Geyik: ışığa gelir, salınan ateşböceğini izler; karanlığa adım atmaz.
/// Yakındaysa ve aynı hizadaysa Sâye'nin ardından yürür. Kutlu toynağı
/// geyik köklerini uyandırır ([DeerPlate]). Son köke basınca yolu gösterip
/// ışığa sıçrar ve kaybolur.
class AkGeyik extends PositionComponent
    with HasGameReference<GolgeGame>, Persistent {
  AkGeyik(Vector2 cell)
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile),
        priority: 17,
      );

  /// Çizim ölçeği (iskelet omuzda ~70 birim).
  static const double drawScale = 0.55;

  /// Çevresini aydınlattığı yarıçap.
  static const double glow = 1.6 * kTile;

  static const double walkSpeed = 92;
  static const double trotSpeed = 140;

  double _t = 0;
  double _phase = 0;
  int facing = 1;
  double _graze = 0;
  double _alert = 0;
  double _idle = 0;
  bool moving = false;

  /// Karanlığın kıyısında durup ürküyor.
  double _balk = 0;

  /// Vedası: 0 değil, sıçrayıp ışığa karışıyor (0-1).
  double _leave = 0;
  bool gone = false;
  double alpha = 1;
  bool _met = false;
  bool _following = false;

  @override
  String get persistKind => 'akGeyik';

  @override
  Object? captureState() => gone ? -1 : position.x.round();

  @override
  Iterable<Component> restoreState(Object? state, {required bool present}) {
    if (state == -1) return const [];
    if (state is num) position.x = state.toDouble();
    return [this];
  }

  Offset get glowCenter => Offset(position.x, position.y - 1.2 * kTile);

  bool shines(Offset at) =>
      !gone && _leave == 0 && (at - glowCenter).distance < glow;

  bool get leaving => _leave > 0;

  /// Son köke bastı: Sâye yolu geçince vedalaşır.
  bool farewell = false;

  /// Ayağının altındaki zeminin üstü (dünya y) ya da yoksa null.
  double? _groundAt(double x) {
    final c = (x / kTile).floor();
    final r0 = ((position.y - kTile * 1.2) / kTile).floor();
    for (var r = r0; r < r0 + 3; r++) {
      if (game.level.solid(c, r)) return r * kTile.toDouble();
    }
    return null;
  }

  bool _blocked(double x) {
    final c = (x / kTile).floor();
    final r = ((position.y - 1) / kTile).floor();
    // Bir kareden yüksek basamak ya da duvar.
    if (game.level.solid(c, r - 1) || game.level.solid(c, r - 2)) return true;
    for (final g in game.world.children.whereType<Gate>()) {
      if (!g.solid) continue;
      final rect = g.toRect();
      if (x > rect.left - 6 &&
          x < rect.right + 6 &&
          position.y - 2 * kTile < rect.bottom &&
          position.y > rect.top) {
        return true;
      }
    }
    return false;
  }

  /// Gideceği yer karanlık bir orman alanının içinde mi?
  bool _darkAt(double x) {
    final at = Offset(x, position.y - kTile);
    for (final z in game.world.children.whereType<GladeZone>()) {
      if (z.area.contains(at) && !z.lit(at, deer: false)) return true;
    }
    return false;
  }

  /// İki kare içinde (kısa bir karanlığın hemen ardında) ışık var mı?
  bool _lightJustAhead(double x, int dir) {
    for (var k = 1; k <= 4; k++) {
      final at = x + dir * (0.9 + k * 0.5) * kTile;
      if (!_darkAt(at)) return true;
    }
    return false;
  }

  /// Yakındaki en yakın aydınlık yer (8 kare içinde); eşitse [prefer]'e
  /// doğru olan.
  double? _nearestLight(double prefer) {
    double? best;
    var bestD = double.infinity;
    for (var k = 1; k <= 32; k++) {
      for (final dir in [1, -1]) {
        final x = position.x + dir * k * 0.25 * kTile;
        if (_darkAt(x) || _groundAt(x) == null) continue;
        final d = (x - position.x).abs() + ((prefer - x).sign == dir ? 0 : 8);
        if (d < bestD) {
          bestD = d;
          best = x + dir * 0.6 * kTile;
        }
      }
      if (best != null) break;
    }
    return best;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (gone) return;
    final p = game.player;
    if (_leave > 0) {
      _leave = math.min(1, _leave + dt * 0.55);
      position.x += facing * 150 * dt;
      position.y -= (90 - 160 * _leave) * dt;
      alpha = (1 - _leave).clamp(0.0, 1.0);
      if (_leave >= 1) {
        gone = true;
        removeFromParent();
      }
      return;
    }
    if (p == null) return;
    final dx = p.center.x - position.x;
    final dy = p.center.y - (position.y - kTile);
    if (!_met && dx.abs() < 12 * kTile && dy.abs() < 6 * kTile) {
      _met = true;
      game.meetMyth('akGeyik');
    }
    if (farewell && dx > 3 * kTile) {
      _leave = 0.001;
      facing = 1;
      GameAudio.instance.play('memory', volume: 0.6);
      return;
    }
    // Hedef: parlayan ateşböceği, yoksa yakındaki Sâye.
    double? target;
    var fast = false;
    FireflyLure? lure;
    var lureD = double.infinity;
    for (final l in game.world.children.whereType<FireflyLure>()) {
      if (!l.glowing) continue;
      final ldx = l.position.x - position.x;
      final ldy = l.position.y - (position.y - kTile);
      // En taze ışığı izler (yeni salınan ateşböceği yolu gösterir).
      if (ldx.abs() < 12 * kTile &&
          ldy.abs() < 9 * kTile &&
          (lure == null || l.age < lure.age)) {
        lureD = ldx.abs();
        lure = l;
      }
    }
    // Sâye'nin ardından: yakınken başlar, çok uzaklaşınca ya da başka bir
    // kata çıkınca bırakır.
    if (_following) {
      if (dx.abs() > 14 * kTile || dy.abs() > 4 * kTile || p.isDead) {
        _following = false;
      }
    } else if (dx.abs() < 7 * kTile && dy.abs() < 2.5 * kTile && !p.isDead) {
      _following = true;
    }
    if (lure != null) {
      target = lure.position.x;
      fast = lureD > 2 * kTile;
    } else if (!farewell && _following && dx.abs() > 2.2 * kTile) {
      target = p.center.x - dx.sign * 1.8 * kTile;
      fast = dx.abs() > 4 * kTile;
    }
    if (farewell) target = null;
    // Karanlıkta kaldıysa (ateşböceği söndü) en yakın ışığa kaçar; Sâye'nin
    // yanındaki ışık öncelikli.
    var fleeing = false;
    if (target == null && !farewell && _darkAt(position.x)) {
      final light = _nearestLight(p.center.x);
      if (light != null) {
        target = light;
        fast = true;
        fleeing = true;
      }
    }
    moving = false;
    _alert = math.max(0, _alert - dt);
    if (target != null && (target - position.x).abs() > 0.35 * kTile) {
      final dir = (target - position.x).sign.toInt();
      facing = dir;
      final speed = fast ? trotSpeed : walkSpeed;
      final nx = position.x + dir * speed * dt;
      final lead = nx + dir * 0.9 * kTile;
      final ground = _groundAt(lead);
      if (_blocked(lead) || ground == null) {
        _alert = 1;
      } else if (!fleeing && _darkAt(lead) && !_lightJustAhead(nx, dir)) {
        // Karanlığa adım atmaz: durur, ürker. (Bir buçuk kareden kısa bir
        // karanlığın ardında ışık varsa sıçrar geçer.)
        _balk = 1;
        _alert = 1;
      } else {
        position.x = nx;
        moving = true;
        _phase += speed * dt / (DeerRig.walkStride * drawScale);
      }
    }
    // Zemine otur (bir kare iner ya da çıkar).
    final g = _groundAt(position.x);
    if (g != null) position.y += (g - position.y) * math.min(1, dt * 14);
    _balk = math.max(0, _balk - dt * 0.8);
    if (moving) {
      _idle = 0;
      _graze = math.max(0, _graze - dt * 3);
    } else {
      _idle += dt;
      final want = _idle > 2.5 && _alert <= 0 ? 1.0 : 0.0;
      _graze += (want - _graze) * math.min(1, dt * 1.5);
    }
  }

  @override
  void render(Canvas canvas) {
    if (gone) return;
    canvas.save();
    // Ürkünce yerinde titrer.
    final shiver = _balk > 0 ? math.sin(_t * 40) * 1.2 * _balk : 0.0;
    canvas.translate(shiver, 0);
    canvas.scale(facing * drawScale, drawScale);
    MythFigures.akGeyik(
      canvas,
      _t,
      _phase,
      alpha: alpha,
      leap: _leave > 0 ? math.min(1, _leave * 3) : 0,
      graze: _graze,
      alert: math.max(_alert, _balk),
      still: !moving && _leave == 0,
    );
    canvas.restore();
  }
}

/// Geyik kökü: Ak Geyik üstüne basınca uyanır ve en yakın kapıyı açar
/// (kapı açık kalır). Sâye'nin ağırlığı yetmez: kökler yalnız kutlu
/// toynağı tanır.
class DeerPlate extends PositionComponent
    with HasGameReference<GolgeGame>, Persistent {
  DeerPlate(Vector2 cell, {this.last = false})
    : super(position: Vector2(cell.x, cell.y + kTile), priority: 15);

  /// Bölümün son kökü: geyik ona basınca vedalaşır.
  final bool last;
  bool woke = false;
  double _glow = 0;
  double _t = 0;

  @override
  String get persistKind => 'deerPlate';

  @override
  Object? captureState() => woke ? 1 : null;

  @override
  Iterable<Component> restoreState(Object? state, {required bool present}) {
    if (state == 1) {
      woke = true;
      _glow = 1;
    }
    return [this];
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (woke) {
      _glow = math.min(1, _glow + dt * 2);
      return;
    }
    for (final d in game.world.children.whereType<AkGeyik>()) {
      if (d.leaving || d.gone) continue;
      if ((d.position.x - (position.x + kTile / 2)).abs() < 0.8 * kTile &&
          (d.position.y - position.y).abs() < 10) {
        _wake(d);
      }
    }
  }

  void _wake(AkGeyik d) {
    woke = true;
    GameAudio.instance.play('grind', volume: 0.6);
    GameAudio.instance.play('gate', volume: 0.7);
    Gate? best;
    var bestD = double.infinity;
    for (final g in game.world.children.whereType<Gate>()) {
      final dd = (g.position - position).length;
      if (dd < bestD && !g.opening) {
        bestD = dd;
        best = g;
      }
    }
    best?.opening = true;
    if (last) d.farewell = true;
  }

  @override
  void render(Canvas canvas) {
    // Yerden çıkan kıvrık kök; uyanınca yeşil-altın ışır.
    final root = Paint()
      ..color = Color.lerp(
        const Color(0xFF2A1E12),
        const Color(0xFF4A3A1E),
        _glow,
      )!
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final x0 = 4.0 + i * 11;
      root.strokeWidth = 4 - i * 0.6;
      canvas.drawPath(
        Path()
          ..moveTo(x0, 2)
          ..quadraticBezierTo(x0 + 6, -8 - 4 * _glow, x0 + 12, 1),
        root,
      );
    }
    final pulse = 0.5 + 0.5 * math.sin(_t * 2.4);
    final a = woke ? 0.55 * _glow : 0.18 + 0.12 * pulse;
    canvas.drawOval(
      const Rect.fromLTWH(-4, -10, kTile + 8, 16),
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(kTile / 2, -2),
          kTile * 0.8,
          [
            const Color(0xFFE8F0B0).withValues(alpha: a),
            const Color(0x00E8F0B0),
          ],
        ),
    );
    // Toynak izi: geyiğin basacağı yer.
    if (!woke) {
      final mark = Paint()
        ..color = const Color(0xFFF2EEC8)
            .withValues(alpha: 0.35 + 0.25 * pulse);
      for (final dx in [-3.0, 3.0]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(kTile / 2 + dx, -3),
            width: 4,
            height: 7,
          ),
          mark,
        );
      }
    }
  }
}

/// Hayat Ağacı'nın sonu: güneş kilidi yanınca ışık gövdeden köklere akar,
/// aşağıda bekleyen Karabasan bir çığlıkla dağılır.
class KarabasanEnd extends PositionComponent with HasGameReference<GolgeGame> {
  KarabasanEnd(this.base) : super(priority: 46);

  /// Ağacın dibi (Karabasan'ın yükseldiği yer, dünya).
  final Vector2 base;
  SunLock? _lock;
  double _t = -1;

  static const double duration = 4.2;

  @override
  void onMount() {
    super.onMount();
    if (game.eventSeen('karabasanEnd')) removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lock ??= game.world.children.whereType<SunLock>().firstOrNull;
    final lock = _lock;
    if (lock == null) return;
    if (_t < 0) {
      if (!lock.open) return;
      _t = 0;
      game.markEvent('karabasanEnd');
      GameAudio.instance.play('growl', volume: 1);
      GameAudio.instance.dread(0);
      game.scare(0.6, sting: false);
      game.meetMyth('hayatAgaci');
      // Ormanın gölgesi kalkar: bütün huzmeler artık güvenli.
      for (final z in game.world.children.whereType<GladeZone>().toList()) {
        z.removeFromParent();
      }
    }
    _t += dt;
    if (_t > 0.6 && _t < 0.7) GameAudio.instance.play('shatter', volume: 0.7);
    if (_t > duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_t < 0) return;
    final lock = _lock;
    if (lock == null) return;
    final k = (_t / duration).clamp(0.0, 1.0);
    // Işık sütunu: kilitten köklere iner.
    final top = lock.position.y;
    final fall = math.min(1.0, _t / 0.9);
    final bottom = top + (base.y - top) * fall;
    final x = base.x;
    final a = (1 - math.max(0, (_t - 2.6) / 1.6)).clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTRB(x - 70, top, x + 70, bottom),
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.linear(Offset(x - 70, 0), Offset(x + 70, 0), [
          const Color(0x00FFF0C0),
          const Color(0xFFFFF0C0).withValues(alpha: 0.55 * a),
          const Color(0x00FFF0C0),
        ]),
    );
    // Karabasan: ağacın dibinde yükselir, ışık değince parçalanır.
    if (fall < 1 || k < 0.9) {
      final rise = math.min(1.0, _t / 0.6);
      final shred = math.max(0.0, (_t - 0.8) / 2.4).clamp(0.0, 1.0);
      final c = Offset(x, base.y - 2.4 * kTile * rise);
      final ink = Paint()
        ..color = const Color(0xFF020101).withValues(alpha: 0.95 * (1 - shred));
      for (var i = 0; i < 26; i++) {
        final h = (i * 2654435761) & 0xffff;
        final ang = (h % 628) / 100;
        final dist = (20 + (h % 50)) * (1 + shred * 5);
        final r = (26 - (h % 14)) * (1 - shred * 0.8);
        canvas.drawCircle(
          c +
              Offset(math.cos(ang) * dist, math.sin(ang) * dist * 0.7) +
              Offset(0, -shred * 80 * ((h % 7) / 7)),
          r,
          ink,
        );
      }
      final eye = Paint()
        ..color = const Color(0xFFE8DCC8).withValues(alpha: 0.9 * (1 - shred));
      for (final dx in [-12.0, 12.0]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: c + Offset(dx, -18),
            width: 10,
            height: 5 * (1 - shred),
          ),
          eye,
        );
      }
    }
  }
}

/// Hayat Ağacı'nın gövdesi: dev bir ak kayın. Kabuğunda kara izler, dibinde
/// toprağa yayılan kökler, gövdesine bağlanmış ak ve al çaputlar.
class TreeOfLife extends PositionComponent with HasGameReference<GolgeGame> {
  TreeOfLife(this.trunk) : super(priority: 1);

  final Rect trunk;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect;
    if (!view.overlaps(trunk.inflate(8 * kTile))) return;
    final l = trunk.left;
    final r = trunk.right;
    final top = trunk.top;
    final bottom = trunk.bottom;
    final w = r - l;
    // Kökler: gövdenin dibinden toprağa yayılan, gittikçe incelen payandalar;
    // kabuk renginden toprağın rengine koyulaşır.
    for (final (side, reach, lift, thick) in [
      (-1.0, 4.6, 2.6, 30.0),
      (-1.0, 2.6, 1.6, 18.0),
      (1.0, 4.0, 2.4, 26.0),
      (1.0, 2.2, 1.4, 16.0),
    ]) {
      final x0 = side < 0 ? l + 10 : r - 10;
      final tip = Offset(x0 + side * reach * kTile, bottom + 4);
      final y0 = bottom - lift * kTile;
      final root = Path()
        ..moveTo(x0, y0)
        ..quadraticBezierTo(
          x0 + side * reach * kTile * 0.35,
          bottom - thick * 0.6,
          tip.dx,
          tip.dy,
        )
        ..lineTo(tip.dx - side * thick * 0.9, bottom + 8)
        ..quadraticBezierTo(
          x0 + side * thick * 0.4,
          bottom + 6,
          x0 - side * thick,
          bottom + 6,
        )
        ..close();
      canvas.drawPath(
        root,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(x0, y0),
            tip,
            const [Color(0xFFD8D2BE), Color(0xFF8A826C), Color(0xFF2A2418)],
            const [0, 0.45, 1],
          ),
      );
      // Kabuğun kara izleri kökte de sürer.
      final mark = Paint()..color = const Color(0xFF1C1814);
      for (var k = 1; k < 4; k++) {
        final t = k / 4;
        final at = Offset.lerp(Offset(x0, y0 + thick * 0.5), tip, t)!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: at, width: 10 - k * 2.0, height: 2.4),
            const Radius.circular(1.2),
          ),
          mark,
        );
      }
    }
    // Gövde: aşağıda genişleyen, ışığa bakan yanı ak, öbür yanı gölgeli.
    final body = Path()
      ..moveTo(l + 6, top)
      ..lineTo(r - 6, top)
      ..quadraticBezierTo(r, (top + bottom) / 2, r + 18, bottom)
      ..lineTo(l - 18, bottom)
      ..quadraticBezierTo(l, (top + bottom) / 2, l + 6, top)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(l, 0),
          Offset(r, 0),
          const [Color(0xFFF4F0E2), Color(0xFFE2DCC8), Color(0xFF9C9684)],
          const [0, 0.55, 1],
        ),
    );
    canvas.save();
    canvas.clipPath(body);
    // Kayın kabuğunun yatay kara izleri ve düğümleri.
    final mark = Paint()..color = const Color(0xFF1C1814);
    for (var i = 0; i < 90; i++) {
      final h = (i * 2654435761) & 0xffffff;
      final y = top + (h % 1000) / 1000 * (bottom - top);
      final x = l - 10 + ((h >> 10) % 1000) / 1000 * (w + 20);
      final len = 10.0 + (h % 23);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, len, 2.2 + (h % 3)),
          const Radius.circular(2),
        ),
        mark,
      );
    }
    for (var i = 0; i < 5; i++) {
      final y = top + (i + 0.6) / 5.5 * (bottom - top);
      final x = l + w * (0.25 + 0.5 * ((i * 37) % 10) / 10);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 18, height: 10),
        mark,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 9, height: 4),
        Paint()..color = const Color(0xFF6C6450),
      );
    }
    // Gölgeli yan.
    canvas.drawRect(
      Rect.fromLTRB(l + w * 0.6, top, r + 20, bottom),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(l + w * 0.6, 0),
          Offset(r + 20, 0),
          const [Color(0x00000000), Color(0x88000000)],
        ),
    );
    canvas.restore();
    // Çaputlar: gövdeye sarılı ak ve al bezler; uçları rüzgârda.
    for (var i = 0; i < 4; i++) {
      final y = top + (i + 0.8) / 4.6 * (bottom - top);
      final red = i.isOdd;
      final cloth = Paint()
        ..color = red ? const Color(0xFFB8322A) : const Color(0xFFF8F4EA);
      canvas.drawRect(Rect.fromLTRB(l - 4, y, r + 4, y + 5), cloth);
      // Düğümden aşağı sarkan iki kısa bez ucu; rüzgârda hafifçe sallanır.
      for (final k in [0.0, 1.0]) {
        final sway = math.sin(_t * 2.2 + i + k) * 2.5;
        final x = l + 2 + k * 5;
        canvas.drawPath(
          Path()
            ..moveTo(x - 2, y + 4)
            ..lineTo(x + 2, y + 4)
            ..lineTo(x + 2 + sway, y + 16 - k * 3)
            ..lineTo(x - 1.5 + sway, y + 17 - k * 3)
            ..close(),
          cloth,
        );
      }
    }
  }
}

/// Hayat Ağacı'nın tacı: tepedeki ayna salonunun ardında, gövdenin üstünde
/// açılan dev yaprak kubbesi; arasından güneş sızar.
class TreeCrown extends PositionComponent with HasGameReference<GolgeGame> {
  TreeCrown(this.middle, this.radius) : super(priority: -1);

  final Offset middle;
  final double radius;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect;
    if (!view.overlaps(Rect.fromCircle(center: middle, radius: radius * 1.4))) {
      return;
    }
    // Dallar: gövdenin tepesinden yelpaze gibi açılır.
    final limb = Paint()
      ..color = const Color(0xFF1E1A12)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final base = middle + Offset(0, radius * 0.75);
    for (var i = 0; i < 7; i++) {
      final a = -math.pi / 2 + (i - 3) * 0.42;
      final end = base + Offset(math.cos(a), math.sin(a)) * radius * 1.1;
      limb.strokeWidth = 16 - (i - 3).abs() * 3.0;
      canvas.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(
            base.dx + (end.dx - base.dx) * 0.3,
            base.dy - radius * 0.5,
            end.dx,
            end.dy,
          ),
        limb,
      );
    }
    // Yaprak kubbesi: üst üste yuvarlak öbekler, kenarı ışıklı.
    final leaf = Paint();
    for (var i = 0; i < 26; i++) {
      final h = (i * 2246822519) & 0xffff;
      final ang = (h % 628) / 100;
      final d = radius * (0.25 + (h % 70) / 100);
      final c =
          middle + Offset(math.cos(ang) * d * 1.35, math.sin(ang) * d * 0.7);
      final rr = radius * (0.22 + (h % 18) / 100);
      leaf.color = Color.lerp(
        const Color(0xFF1C3418),
        const Color(0xFF3E6A2C),
        (h % 100) / 100,
      )!;
      canvas.drawCircle(c, rr, leaf);
    }
    // Yaprak arasından sızan ışık.
    final glint = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 18; i++) {
      final h = (i * 40503) & 0xffff;
      final c =
          middle +
          Offset(
            ((h % 200) / 100 - 1) * radius * 1.2,
            (((h >> 7) % 100) / 100 - 0.6) * radius * 0.8,
          );
      final tw = 0.5 + 0.5 * math.sin(_t * 1.3 + i);
      glint.color = const Color(0xFFFFF0B0).withValues(alpha: 0.25 * tw);
      canvas.drawCircle(c, 6 + (h % 5), glint);
    }
  }
}
