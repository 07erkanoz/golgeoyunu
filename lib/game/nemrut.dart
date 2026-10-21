import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'audio.dart';
import 'entities.dart';
import 'golge_game.dart';
import 'level.dart';
import 'mechanics.dart';
import 'nemrut_sprites.dart';
import 'palette.dart';
import 'persist.dart';
import 'puzzles.dart';
import 'rig.dart';
import 'strings.dart';

part 'nemrut_art.dart';

// ======================================================== Aslan Horoskobu

/// Gökteki işaretler: Aslan Horoskobu'ndaki hilal, üç gezegen ve yıldız.
enum Sign { moon, jupiter, mercury, mars, star }

/// Horoskobun istediği sıra (soldan sağa yıldız taşları).
const horoscope = [Sign.moon, Sign.jupiter, Sign.mercury, Sign.mars];

void _drawSign(Canvas canvas, Sign s, Offset c, double r, Paint p) {
  switch (s) {
    case Sign.moon:
      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addOval(Rect.fromCircle(center: c, radius: r)),
          Path()..addOval(
            Rect.fromCircle(
              center: c.translate(r * 0.45, -r * 0.15),
              radius: r * 0.85,
            ),
          ),
        ),
        p,
      );
    case Sign.jupiter:
      canvas.drawCircle(c, r * 0.8, p);
      canvas.drawLine(
        c.translate(-r, 0),
        c.translate(r, 0),
        Paint()
          ..color = p.color
          ..strokeWidth = 1.4,
      );
    case Sign.mercury:
      canvas.drawCircle(c, r * 0.45, p);
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 2 + math.pi / 4;
        canvas.drawLine(
          c,
          c + Offset(math.cos(a), math.sin(a)) * r,
          Paint()
            ..color = p.color
            ..strokeWidth = 1.2,
        );
      }
    case Sign.mars:
      canvas.drawCircle(c.translate(-r * 0.2, r * 0.2), r * 0.55, p);
      canvas.drawLine(
        c.translate(r * 0.1, -r * 0.1),
        c.translate(r * 0.8, -r * 0.8),
        Paint()
          ..color = p.color
          ..strokeWidth = 1.6,
      );
    case Sign.star:
      final path = Path();
      for (var i = 0; i < 16; i++) {
        final a = i * math.pi / 8 - math.pi / 2;
        final rr = i.isEven ? r : r * 0.4;
        final pt = c + Offset(math.cos(a), math.sin(a)) * rr;
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path..close(), p);
  }
}

/// Döndürülebilen yıldız taşı: ↑ ile bir sonraki işarete döner. Bütün
/// taşlar Aslan Horoskobu'ndaki sırayı gösterince en yakın kapı açılır.
class StarStone extends PositionComponent
    with HasGameReference<GolgeGame>, Usable, Persistent {
  StarStone(Vector2 cell, this.index, {Sign start = Sign.star})
    : sign = start,
      super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile),
        priority: 18,
      );

  final int index;
  Sign sign;
  double _turn = 0;

  @override
  String get persistKind => 'star';

  @override
  Object? captureState() => sign.index;

  @override
  Iterable<Component> restoreState(Object? state, {required bool present}) {
    if (state is int && state >= 0 && state < Sign.values.length) {
      sign = Sign.values[state];
    }
    return [this];
  }

  bool get correct => index < horoscope.length && sign == horoscope[index];

  @override
  bool canUse(Vector2 p) =>
      (p - position).x.abs() < 26 && (p - position).y.abs() < 44;

  @override
  void use() {
    sign = Sign.values[(sign.index + 1) % Sign.values.length];
    _turn = 1;
    GameAudio.instance.play('grind', volume: 0.5);
    _check();
  }

  void _check() {
    final stones = game.world.children.whereType<StarStone>().toList();
    if (stones.every((s) => s.correct)) {
      GameAudio.instance.play('memory', volume: 0.7);
      game.once('horoscope', S.of('horoscope'));
      Gate? best;
      var bestD = double.infinity;
      for (final g in game.world.children.whereType<Gate>()) {
        final d = (g.position - position).length;
        if (d < bestD && !g.opening) {
          bestD = d;
          best = g;
        }
      }
      best?.opening = true;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _turn = math.max(0, _turn - dt * 3);
  }

  @override
  void render(Canvas canvas) {
    final stone = Paint()..color = const Color(0xFF2A2430);
    canvas.drawRect(const Rect.fromLTWH(-12, -10, 24, 10), stone);
    canvas.save();
    canvas.translate(0, -24);
    canvas.rotate(_turn * math.pi);
    canvas.drawCircle(Offset.zero, 13, stone);
    final ok = correct;
    final lit = Paint()
      ..color = ok ? const Color(0xFFFFE0A0) : const Color(0xFFC8C0D8);
    _drawSign(canvas, sign, Offset.zero, 8, lit);
    canvas.restore();
    if (ok) glowDot(canvas, const Offset(0, -24), 30, kWarmLight, 0.35);
  }
}

/// Aslan Horoskobu kabartması: gökteki doğru sırayı gösterir (süs ve ipucu).
class HoroscopeRelief extends PositionComponent
    with HasGameReference<GolgeGame> {
  HoroscopeRelief(Vector2 cell)
    : super(position: Vector2(cell.x, cell.y + kTile), priority: 2);

  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  /// Kalınlığı incelen parça (bacak, kuyruk).
  static Path _seg(Offset a, Offset b, double w0, double w1) {
    final d = b - a;
    final n = Offset(-d.dy, d.dx) / (d.distance == 0 ? 1 : d.distance);
    return Path()
      ..moveTo((a + n * w0 / 2).dx, (a + n * w0 / 2).dy)
      ..lineTo((b + n * w1 / 2).dx, (b + n * w1 / 2).dy)
      ..lineTo((b - n * w1 / 2).dx, (b - n * w1 / 2).dy)
      ..lineTo((a - n * w0 / 2).dx, (a - n * w0 / 2).dy)
      ..close()
      ..addOval(Rect.fromCircle(center: a, radius: w0 / 2))
      ..addOval(Rect.fromCircle(center: b, radius: w1 / 2));
  }

  /// Kalçadan çıkıp S çizerek yukarı kalkan kuyruk: eğri boyunca incelen
  /// kısa parçalar (ekler görünmez).
  static Path _tail() {
    Offset at(double u) {
      const p0 = Offset(38, -54);
      const p1 = Offset(14, -54);
      const p2 = Offset(12, -82);
      const p3 = Offset(24, -86);
      final v = 1 - u;
      return p0 * (v * v * v) +
          p1 * (3 * v * v * u) +
          p2 * (3 * v * u * u) +
          p3 * (u * u * u);
    }

    var out = Path();
    const n = 16;
    for (var i = 0; i < n; i++) {
      final w0 = 4.2 - 2.0 * i / n;
      final w1 = 4.2 - 2.0 * (i + 1) / n;
      out = Path.combine(
        PathOperation.union,
        out,
        _seg(at(i / n), at((i + 1) / n), w0, w1),
      );
    }
    return out;
  }

  /// Aslan: sağa yürür; yeleli baş, kıvrılıp kalkan püsküllü kuyruk.
  /// Antiochos'un Aslan Horoskobu'ndaki gibi (Nemrut, Batı Terası).
  static final Path _lion = () {
    final parts = <Path>[
      // Gövde: kalça, sırt, göğüs, karın.
      Path()
        ..moveTo(38, -50)
        ..cubicTo(36, -62, 46, -67, 60, -64)
        ..cubicTo(82, -61, 104, -63, 122, -69)
        ..cubicTo(132, -60, 134, -46, 128, -38)
        ..cubicTo(110, -33, 72, -34, 52, -37)
        ..cubicTo(42, -39, 38, -44, 38, -50)
        ..close(),
      // Arka bacaklar: but, diz, incik, pençe.
      _seg(const Offset(50, -50), const Offset(42, -30), 15, 8),
      _seg(const Offset(42, -30), const Offset(46, -10), 8, 6),
      _seg(const Offset(62, -44), const Offset(60, -26), 11, 7),
      _seg(const Offset(60, -26), const Offset(64, -10), 7, 6),
      // Ön bacaklar.
      _seg(const Offset(118, -44), const Offset(116, -10), 11, 7),
      _seg(const Offset(128, -44), const Offset(132, -10), 10, 7),
      // Kuyruk: kalçadan kıvrılıp yukarı kalkar (tek parça, incelen).
      _tail(),
      Path()..addOval(
        Rect.fromCenter(center: const Offset(24, -87), width: 7, height: 9),
      ),
      // Baş ve burun.
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(146, -66), radius: 10)),
      Path()..addOval(
        Rect.fromCenter(center: const Offset(157, -61), width: 13, height: 9),
      ),
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(141, -77), radius: 3)),
    ];
    // Pençeler.
    for (final x in [47.0, 65.0, 117.0, 133.0]) {
      parts.add(
        Path()..addOval(
          Rect.fromCenter(center: Offset(x + 2, -9), width: 10, height: 5),
        ),
      );
    }
    // Yele: başın ve boynun çevresinde dalgalı, sivri uçlu.
    final mane = Path();
    for (var i = 0; i <= 24; i++) {
      final a = math.pi * 0.35 + i / 24 * math.pi * 1.45;
      final r = i.isEven ? 21.0 : 15.5;
      final pt = Offset(140 + math.cos(a) * r, -62 - math.sin(a) * r * 0.95);
      i == 0 ? mane.moveTo(pt.dx, pt.dy) : mane.lineTo(pt.dx, pt.dy);
    }
    parts.add(mane..close());
    var out = parts.first;
    for (final p in parts.skip(1)) {
      out = Path.combine(PathOperation.union, out, p);
    }
    return out;
  }();

  /// Aslanın üstündeki 19 yıldız (kabartmadaki gibi gövdeye ve yeleye
  /// serpilmiş).
  static const _stars = [
    Offset(46, -54),
    Offset(58, -58),
    Offset(70, -52),
    Offset(84, -56),
    Offset(98, -50),
    Offset(110, -58),
    Offset(120, -50),
    Offset(76, -42),
    Offset(92, -40),
    Offset(106, -42),
    Offset(56, -44),
    Offset(130, -66),
    Offset(136, -78),
    Offset(148, -80),
    Offset(124, -60),
    Offset(44, -24),
    Offset(118, -24),
    Offset(26, -72),
    Offset(64, -24),
  ];

  @override
  void render(Canvas canvas) {
    const w = 6 * kTile;
    const h = 4 * kTile;
    // Taş levha: ince bir çerçeve, içi oyulmuş.
    canvas.drawRect(
      const Rect.fromLTWH(0, -h, w, h),
      Paint()..color = const Color(0xFF1C1822),
    );
    canvas.drawRect(
      const Rect.fromLTWH(5, -h + 5, w - 10, h - 10),
      Paint()..color = const Color(0xFF29232F),
    );
    canvas.drawRect(
      const Rect.fromLTWH(5, -h + 5, w - 10, h - 10),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF0E0B12),
    );
    // Kabartma: alt-sağa düşen gölge, gövde, üst-sola vuran ışık.
    canvas.save();
    canvas.translate(2, 2);
    canvas.drawPath(_lion, Paint()..color = const Color(0xFF110E15));
    canvas.restore();
    canvas.drawPath(
      _lion,
      Paint()
        ..shader = Gradient.linear(const Offset(0, -90), const Offset(0, -8), [
          const Color(0xFF5A5068),
          const Color(0xFF3C3448),
        ]),
    );
    canvas.save();
    canvas.clipPath(_lion);
    canvas.translate(1.2, 1.2);
    canvas.drawPath(
      _lion,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = const Color(0xFF8A80A0).withValues(alpha: 0.35),
    );
    canvas.restore();
    // Göz ve ağız çizgisi.
    final line = Paint()
      ..color = const Color(0xFF15111B)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(const Offset(150, -68), 1.3, line);
    canvas.drawLine(const Offset(156, -58), const Offset(162, -59), line);
    // Hilal aslanın boynunda, yıldızlar gövdesinde, gezegenler sırtının
    // üstünde (bulmacanın sırası).
    final glow = 0.55 + 0.25 * math.sin(_t * 1.3);
    final mark = Paint()
      ..color = const Color(0xFFE8D8B0).withValues(alpha: glow);
    _drawSign(canvas, Sign.moon, const Offset(134, -48), 8, mark);
    for (var i = 1; i < horoscope.length; i++) {
      _drawSign(canvas, horoscope[i], Offset(46.0 + i * 30, -100), 8, mark);
    }
    final star = Paint()
      ..color = const Color(0xFFE8D8B0).withValues(alpha: glow * 0.85);
    for (final p in _stars) {
      _drawSign(canvas, Sign.star, p, 2.6, star);
    }
    // Kenar ve kar.
    canvas.drawRect(
      const Rect.fromLTWH(0, -h - 3, w, 4),
      Paint()..color = const Color(0xFFC8D2E2),
    );
  }
}

// ================================================================ Deprem

/// Gevşek kaya: depremde ya da altından geçilince düşer.
class LooseBoulder extends PositionComponent with HasGameReference<GolgeGame> {
  LooseBoulder(Vector2 cell)
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile / 2),
        priority: 21,
      );

  double _shake = -1;
  double _vy = 0;
  bool _landed = false;
  double _gone = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (_landed) {
      _gone += dt;
      if (_gone > 1.2) removeFromParent();
      return;
    }
    if (_shake < 0) {
      final p = game.player;
      final under =
          p != null &&
          !p.isDead &&
          (p.center.x - position.x).abs() < 30 &&
          p.center.y > position.y;
      if (game.quake > 0.5 || under) _shake = 0;
      return;
    }
    _shake += dt;
    if (_shake < 0.35) return;
    _vy = math.min(_vy + 1900 * dt, 900);
    position.y += _vy * dt;
    final p = game.player;
    if (p != null &&
        !p.isDead &&
        p.toRect().inflate(4).contains(position.toOffset())) {
      p.die();
    }
    if (game.level.cellAt(position.x, position.y + 14) == '#' ||
        position.y > game.level.pixelHeight) {
      _landed = true;
      GameAudio.instance.play('crumble', volume: 0.6);
      game.shake(2);
    }
  }

  @override
  void render(Canvas canvas) {
    final j = _shake >= 0 && _shake < 0.35 ? math.sin(_shake * 70) * 2 : 0.0;
    final a = _landed ? (1 - _gone / 1.2).clamp(0.0, 1.0) : 1.0;
    final rock = Paint()..color = const Color(0xFF2A2430).withValues(alpha: a);
    canvas.drawPath(
      Path()
        ..moveTo(-13 + j, -6)
        ..lineTo(-4 + j, -14)
        ..lineTo(10 + j, -10)
        ..lineTo(14 + j, 4)
        ..lineTo(4 + j, 14)
        ..lineTo(-12 + j, 10)
        ..close(),
      rock,
    );
    canvas.drawLine(
      Offset(-8 + j, -10),
      Offset(8 + j, -12),
      Paint()
        ..color = const Color(0xFFC8D2E2).withValues(alpha: 0.7 * a)
        ..strokeWidth = 2,
    );
  }
}

// ============================================================== Heykeller

/// Arazinin arkasında duran dev taş tanrı (oturan) ya da yere düşmüş başı.
/// Tırmanılacak dizler, kucak ve omuzlar haritada ayrıca `#` ile verilir.
class Colossus extends PositionComponent with HasGameReference<GolgeGame> {
  Colossus(Vector2 cell, {required this.kind})
    : super(
        // Oturan tanrının işareti omuzlarının üstündedir; çizim 9 kare
        // aşağıdaki zemine oturur.
        position: Vector2(cell.x, cell.y + kTile + (kind <= 1 ? 9 * kTile : 0)),
        // Oturan tanrının tırmanılan kareleri arazidir: heykel arazinin
        // önünde çizilir (yoksa kaya onu örter).
        priority: kind <= 1 ? 1 : -1,
      );

  /// 0: oturan tanrı (başı yok), 1: oturan tanrı (başı yerinde),
  /// 2: düşmüş baş, 3: kartal, 4: aslan.
  final int kind;

  /// Düşmüş başın kimliği: sütuna göre değişir (terasta her baş başka bir
  /// tanrı).
  /// Görseli tabanı zeminde, [cx]te ortalanmış ve [height] boyunda çizer.
  void _sprite(
    Canvas canvas,
    String key,
    double height,
    double cx, {
    bool flip = false,
  }) {
    final r = nemrutSprites[key]!;
    final sc = height / r.height;
    canvas.save();
    canvas.translate(cx, 0);
    canvas.scale(flip ? -sc : sc, sc);
    canvas.translate(-r.center.dx, -r.bottom);
    NemrutImages.draw(canvas, key, game);
    canvas.restore();
  }

  NemrutHead get _headKind {
    // Çoğu uzun tiaralı (Nemrut'un tanınan başları), arada Apollon ve
    // Herakles.
    const order = [
      NemrutHead.zeus,
      NemrutHead.antiochos,
      NemrutHead.apollo,
      NemrutHead.antiochos,
      NemrutHead.herakles,
    ];
    return order[((position.x / kTile).round() ~/ 8) % order.length];
  }

  @override
  void render(Canvas canvas) {
    const t = kTile;
    switch (kind) {
      case 0:
        NemrutArt.seated(canvas);
      case 1:
        NemrutArt.seated(canvas, head: NemrutHead.antiochos);
      case 2 when NemrutImages.ready:
        // Yere dikilmiş duran dev baş: terasta her biri başka bir tanrı.
        const heads = [
          'zeus_head',
          'antiochos_head',
          'apollon_head',
          'herakles_head',
          'kommagene_head',
        ];
        final i = (position.x / kTile).round() ~/ 8;
        _sprite(
          canvas,
          heads[i % heads.length],
          5 * t,
          -0.7 * t,
          flip: i ~/ heads.length % 2 == 1,
        );
      case 3 when NemrutImages.ready:
        _sprite(canvas, 'eagle_head', 4.2 * t, 1.25 * t);
      case 4 when NemrutImages.ready:
        _sprite(canvas, 'lion_head', 3.6 * t, 1.5 * t);
      case 2:
        // Yere dikilmiş duran dev baş (gövdesinden kopup düşmüş); dibinde
        // moloz.
        canvas.save();
        // Dikili taşın (sağdaki saklanma yeri) yanında durur.
        canvas.translate(-0.7 * t, 0);
        canvas.rotate(-0.04);
        NemrutArt.head(canvas, _headKind, 5 * t);
        canvas.restore();
        final rubble = Paint()..color = const Color(0xFF2A2432);
        for (final (x, w) in const [(0.2, 0.7), (1.0, 0.5), (2.2, 0.8)]) {
          canvas.drawOval(
            Rect.fromLTWH(x * t, -0.3 * t, w * t, 0.4 * t),
            rubble,
          );
        }
      case 3:
        canvas.save();
        canvas.translate(1.25 * t, 0);
        NemrutArt.eagle(canvas, 4.6 * t);
        canvas.restore();
      default:
        // Aslan: alçak bir kaidenin üstünde, horoskobun aslanı gibi.
        NemrutArt._masonry(canvas, const Rect.fromLTRB(0, -0.8 * t, 3 * t, 0));
        canvas.save();
        canvas.translate(-0.15 * t, -0.8 * t);
        canvas.scale(0.6);
        final lion = HoroscopeRelief._lion;
        canvas.drawPath(
          lion.shift(const Offset(3, 2)),
          Paint()..color = const Color(0xFF07050A).withValues(alpha: 0.55),
        );
        canvas.drawPath(
          lion,
          Paint()
            ..shader = Gradient.linear(
              const Offset(0, -90),
              const Offset(0, 0),
              [_nStoneLit, _nStoneDark],
            ),
        );
        canvas.restore();
    }
  }
}

// ======================================================== Taş dev Nemrud

/// Nemrud'un taş devi: terasta ağır ağır yürür, adımları yeri sarsar,
/// ayaklarının dibinde kalanı ezer. Kulağına bir ateşböceği (sivrisinek
/// gibi) girerse sendeler; üçüncüsünde yıkılır ve gövdesi köprü olur.
class StoneGiant extends PositionComponent
    with HasGameReference<GolgeGame>, Persistent {
  StoneGiant(Vector2 cell)
    : _home = cell.x,
      super(
        position: Vector2(cell.x, cell.y + kTile),
        size: Vector2(5 * kTile, 9 * kTile),
        // Konum ayakların yeridir (kulak, ezme alanı ve köprü buna göre):
        // çizim de oradan yukarı uzanır. Önceden sol üst köşe sayıldığı için
        // dev toprağın içine çiziliyordu.
        anchor: Anchor.bottomLeft,
        priority: 16,
      );

  static const double span = 11 * kTile;
  static const int hitsToFall = 3;

  final double _home;
  double _t = 0;
  double _stagger = 0;
  int hits = 0;
  bool fallen = false;
  double _fallT = 0;
  int _dir = 1;

  /// Yürüyüş evresi: yalnızca yürürken ilerler. Bacaklar ve adım sesi aynı
  /// evreden çıkar; ayak yere bastığı anda gümbürtü duyulur.
  double _walk = 0;
  int _stepN = 0;
  static const double _stepRate = 2.9;

  /// Basan ayağın tozu (yerel x, yaş) ve yıkılışın yere çarpışı.
  final _dust = <(double, double)>[];
  bool _impact = false;

  /// Temasta başın kulaktan kaçışı (yay: çeker, geri gelir).
  final _flinch = Spring(stiffness: 55, damping: 5);

  @override
  String get persistKind => 'giant';

  @override
  Object? captureState() => hits == 0 ? null : [hits, fallen ? 1 : 0];

  @override
  Iterable<Component> restoreState(Object? state, {required bool present}) {
    final s = numbers(state, 2);
    if (s == null) return [this];
    hits = s[0].round().clamp(0, hitsToFall);
    if (s[1] != 1) return [this];
    // Yıkılmış dev yatar; gövdesi köprüdür.
    fallen = true;
    hits = hitsToFall;
    _fallT = 1;
    _impact = true;
    return [this, GiantBridge(_bridgeAt)];
  }

  Vector2 get _bridgeAt =>
      Vector2(position.x + size.x / 2, position.y - kTile * 1.2);

  /// Kulağın dünyadaki yeri.
  Vector2 get ear => NemrutImages.giantReady
      // Çizimdeki kulak (SVG 390,183): baş yürüyüş yönünün tersine bakan
      // yanda görünür.
      ? Vector2(
          position.x + size.x * 0.5 - _dir * (390 - 320) * _svgScale,
          position.y - (801 - 183) * _svgScale,
        )
      : Vector2(
          position.x + size.x * 0.5 + _dir * 22,
          position.y - size.y * 0.78,
        );

  /// SVG çiziminin (yer 801, tepe ~34) dev boyuna ölçeği.
  double get _svgScale => size.y / (801 - 34);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _flinch.update(0, dt);
    for (var i = _dust.length - 1; i >= 0; i--) {
      final (x, age) = _dust[i];
      if (age + dt > 1.4) {
        _dust.removeAt(i);
      } else {
        _dust[i] = (x, age + dt);
      }
    }
    if (fallen) {
      _fallT = math.min(1, _fallT + dt * 0.7);
      if (_fallT >= 1 && !_impact) {
        // Gövde yere çarpar: toz, sarsıntı, gümbürtü.
        _impact = true;
        game.shake(12);
        GameAudio.instance.play('land');
        for (var k = 0; k < 7; k++) {
          _dust.add((size.x * 0.5 + (k - 3) * 40.0, 0));
        }
      }
      return;
    }
    if (_stagger > 0) {
      _stagger -= dt;
      return;
    }
    // Ağır adımlar: iki nokta arasında gidip gelir.
    position.x += _dir * 26 * dt;
    _walk += dt;
    if (position.x > _home + span) _dir = -1;
    if (position.x < _home) _dir = 1;
    final p = game.player;
    // Bacak sin(evre) ile gidip gelir: uçlarda (her yarım dönüşte) ayak
    // yere oturur.
    final n = ((_walk * _stepRate + math.pi / 2) / math.pi).floor();
    if (n != _stepN) {
      _stepN = n;
      // Basan ayağın altında toz kalkar.
      _dust.add((size.x * (n.isOdd ? 0.36 : 0.64) + _dir * 14, 0));
      // Adımlar yakında duyulur ve sarsar; uzaktan yalnızca hafif bir gümbürtü.
      final near = p == null || p.isDead
          ? 0.0
          : (1 - (p.center - position).length / (24 * kTile)).clamp(0.0, 1.0);
      if (near > 0) {
        GameAudio.instance.play('land', volume: 0.9 * near);
        game.shake(4 * near);
        game.quake = math.max(game.quake, 0.6 * near);
      }
    }
    if (p != null && !p.isDead) {
      // Ayakların dibi ezer.
      final feet = Rect.fromLTWH(position.x, position.y - 28, size.x, 28);
      if (p.toRect().overlaps(feet)) p.die();
    }
    for (final l in game.world.children.whereType<FireflyLure>()) {
      if (l.glowing && (l.position - ear).length < 46) {
        l.removeFromParent();
        hits++;
        _stagger = 2.4;
        _flinch.kick(-_dir * 9);
        GameAudio.instance.play('grind');
        GameAudio.instance.play('growl', volume: 0.7);
        game.shake(6 + hits * 2.0);
        if (hits < hitsToFall) {
          // Kaç ışık kaldığını söyler (sol üstte kısa bir not).
          game.narration.hint(
            S.of(hits == 1 ? 'giantHit1' : 'giantHit2'),
            queue: true,
          );
        }
        if (hits >= hitsToFall) {
          fallen = true;
          GameAudio.instance.play('crumble');
          game.once('giantFell', S.of('giantFell'));
          // Yatan gövdenin üstü köprü olur (gövde sağa, ayaklarından uzanır).
          game.world.add(GiantBridge(_bridgeAt));
          // Devin düşüşü ilerideki (çıkışa doğru) kapıyı kırar.
          Gate? best;
          var bestD = double.infinity;
          for (final g in game.world.children.whereType<Gate>()) {
            final dd = (g.position - position).length;
            if (g.position.x > position.x && dd < bestD && !g.opening) {
              bestD = dd;
              best = g;
            }
          }
          best?.opening = true;
        }
      }
    }
  }

  static final _stone = Paint()..color = const Color(0xFF241E2C);
  static final _edge = Paint()
    ..color = const Color(0xFF4A4058)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final _seam = Paint()
    ..color = const Color(0xFF15111A)
    ..strokeWidth = 1.6
    ..style = PaintingStyle.stroke;

  /// [a]dan [b]ye uzanan, köşeleri kırık bir taş blok; üst kenarında soluk
  /// ışık, ortasında derz.
  void _block(
    Canvas canvas,
    Offset a,
    Offset b,
    double width, {
    double chip = 0.2,
  }) {
    final d = b - a;
    final len = d.distance;
    if (len < 0.01) return;
    final u = d / len;
    final n = Offset(-u.dy, u.dx) * (width / 2);
    final c = math.min(width, len) * chip;
    final p = Path()
      ..moveTo((a + n + u * c).dx, (a + n + u * c).dy)
      ..lineTo((b + n - u * c * 0.6).dx, (b + n - u * c * 0.6).dy)
      ..lineTo((b + n * 0.55).dx, (b + n * 0.55).dy)
      ..lineTo((b - n * 0.8).dx, (b - n * 0.8).dy)
      ..lineTo((b - n - u * c).dx, (b - n - u * c).dy)
      ..lineTo((a - n + u * c * 0.5).dx, (a - n + u * c * 0.5).dy)
      ..lineTo((a - n * 0.6).dx, (a - n * 0.6).dy)
      ..lineTo((a + n * 0.7).dx, (a + n * 0.7).dy)
      ..close();
    canvas.drawPath(p, _stone);
    // Işığa bakan kenar (sol üst) ve ortadaki derz.
    final lit = n.dx < 0 || n.dy < 0 ? n : -n;
    canvas.drawLine(a + lit * 0.85 + u * c, b + lit * 0.85 - u * c, _edge);
    canvas.drawLine(
      a + u * (len * 0.5) - n * 0.6,
      a + u * (len * 0.5) + n * 0.6,
      _seam,
    );
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    // Ayak dibindeki toz (devrilse de yerinde kalır).
    final dust = Paint();
    for (final (x, age) in _dust) {
      final k = age / 1.4;
      dust.color = const Color(0xFFB8A890).withValues(alpha: 0.35 * (1 - k));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, h - 4 - k * 10),
          width: 30 + k * 60,
          height: 8 + k * 14,
        ),
        dust,
      );
    }
    canvas.save();
    // Yıkılış: önce dizler çöker, sonra gövde öne devrilir ve ağırlaşarak
    // yere çarpar. Son hâli köprüyle aynı hizada yatan bir taş yığını.
    final buckle = fallen ? (_fallT / 0.3).clamp(0.0, 1.0) : 0.0;
    final topple = fallen ? ((_fallT - 0.2) / 0.8).clamp(0.0, 1.0) : 0.0;
    final f = topple * topple;
    if (fallen) {
      final k = 1 - 0.68 * f;
      canvas.translate(w / 2, h - w * k / 2 * f);
      canvas.rotate(f * math.pi / 2);
      canvas.scale(k, 1);
      canvas.translate(-w / 2, -h);
    }
    final stung = !fallen && _stagger > 0 ? (_stagger / 2.4) : 0.0;
    // Adım: ağırlık basan bacağa geçer, öbürü kalkıp öne gelir.
    final walking = !fallen && _stagger <= 0;
    final s =
        ((_walk * _stepRate - math.pi / 2) % (2 * math.pi) + 2 * math.pi) %
        (2 * math.pi);
    final swingA = s < math.pi;
    final half = (s % math.pi) / math.pi; // salınımın ne kadarı
    final lift = math.sin(half * math.pi);
    if (NemrutImages.giantReady) {
      _renderSprites(
        canvas,
        buckle: buckle,
        stung: stung,
        walking: walking,
        swingA: swingA,
        half: half,
        lift: lift,
      );
      if (hits > 0) _cracks(canvas, w, h);
      canvas.restore();
      if (!fallen) {
        final e = ear - position;
        glowDot(
          canvas,
          e.toOffset(),
          16,
          kWarmLight,
          0.25 + 0.15 * math.sin(_t * 4),
        );
      }
      return;
    }
    _renderDark(
      canvas,
      buckle: buckle,
      stung: stung,
      walking: walking,
      swingA: swingA,
      half: half,
      lift: lift,
    );
    if (hits > 0) _cracks(canvas, w, h);
    canvas.restore();
    if (!fallen) {
      final e = ear - position;
      glowDot(
        canvas,
        e.toOffset(),
        16,
        kWarmLight,
        0.25 + 0.15 * math.sin(_t * 4),
      );
    }
    return;
    // ignore: dead_code
    const reach = 15.0;
    // Kalça: basan ayağın üstüne kayar, basışta çöker.
    final sway = (swingA ? 1 : -1) * 5.0 * lift;
    final bob = -4 * lift + buckle * h * 0.14;
    final hipY = h * 0.68 + bob;
    final hipA = Offset(w * 0.36 + sway, hipY);
    final hipB = Offset(w * 0.64 + sway, hipY);
    double planted(double t) => _dir * reach * (1 - 2 * t);
    double swung(double t) =>
        _dir * reach * (-1 + 2 * (0.5 - math.cos(t * math.pi) / 2));
    final footA = Offset(
      w * 0.36 +
          (walking ? (swingA ? swung(half) : planted(half)) : 0) -
          buckle * 10,
      h - (walking && swingA ? lift * 16 : 0),
    );
    final footB = Offset(
      w * 0.64 +
          (walking ? (!swingA ? swung(half) : planted(half)) : 0) +
          buckle * 10,
      h - (walking && !swingA ? lift * 16 : 0),
    );
    // Dizler yürüme yönüne kırılır (yıkılırken öne çöker).
    final bend = _dir.toDouble();
    for (final (hip, foot) in [(hipA, footA), (hipB, footB)]) {
      final (knee, end) = solveLimb(
        hip,
        foot,
        h * 0.175,
        h * 0.175,
        bend: bend,
      );
      _block(canvas, hip, knee, w * 0.17);
      _block(canvas, knee, end.translate(0, -h * 0.03), w * 0.15);
      _block(
        canvas,
        end.translate(-w * 0.1, -h * 0.018),
        end.translate(w * 0.1, -h * 0.018),
        h * 0.036,
        chip: 0.1,
      );
    }
    // Leğen ve gövde: genişleyen göğüs, kırık omuz taşları.
    _block(
      canvas,
      Offset(w * 0.24 + sway, hipY),
      Offset(w * 0.76 + sway, hipY),
      h * 0.08,
    );
    final chest = h * 0.34 + bob * 0.8;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.22 + sway, hipY - h * 0.02)
        ..lineTo(w * 0.1 + sway * 0.7, chest)
        ..lineTo(w * 0.16 + sway * 0.7, chest - h * 0.03)
        ..lineTo(w * 0.84 + sway * 0.7, chest - h * 0.03)
        ..lineTo(w * 0.9 + sway * 0.7, chest)
        ..lineTo(w * 0.78 + sway, hipY - h * 0.02)
        ..close(),
      _stone,
    );
    canvas.drawLine(
      Offset(w * 0.16 + sway * 0.7, chest - h * 0.025),
      Offset(w * 0.84 + sway * 0.7, chest - h * 0.025),
      _edge,
    );
    // Göğüs taşlarının derzleri.
    for (final y in [0.43, 0.52, 0.6]) {
      canvas.drawLine(
        Offset(w * 0.2 + sway * 0.8, h * y + bob * 0.8),
        Offset(w * 0.8 + sway * 0.8, h * y + bob * 0.8),
        _seam,
      );
    }
    // Kollar: yürürken bacakların tersine sallanır; temas anında kulak
    // tarafındaki el kulağa gider, öbürü dengeyi toplar.
    final swat = stung > 0
        ? math.sin(math.min(1, (1 - stung) * 3) * math.pi / 2)
        : 0.0;
    final headC = Offset(
      w * 0.5 + _flinch.value + sway * 0.6,
      h * 0.22 + bob * 0.7,
    );
    for (final side in [-1.0, 1.0]) {
      final shoulder = Offset(
        w * (0.5 + side * 0.4) + sway * 0.7,
        chest + h * 0.01,
      );
      final armSwing = walking ? (swingA ? 1 : -1) * side * lift * 10 : 0.0;
      var hand = Offset(
        shoulder.dx + side * 6 + armSwing * _dir,
        h * 0.66 + bob * 0.5,
      );
      if (side == _dir && swat > 0) {
        hand = Offset.lerp(hand, headC + Offset(side * 30, 6), swat)!;
      } else if (stung > 0) {
        hand = hand.translate(side * 14 * stung, -12 * stung);
      }
      if (buckle > 0) {
        hand = hand.translate(side * 10 * buckle, -h * 0.05 * buckle);
      }
      final (elbow, end) = solveLimb(
        shoulder,
        hand,
        h * 0.17,
        h * 0.16,
        bend: side,
      );
      _block(canvas, shoulder, elbow, w * 0.15);
      _block(canvas, elbow, end, w * 0.13);
      _block(
        canvas,
        shoulder.translate(-w * 0.07, -h * 0.01),
        shoulder.translate(w * 0.07, -h * 0.01),
        h * 0.05,
        chip: 0.25,
      );
    }
    // Baş: kulaktan kaçar (temas), sonra yerine döner; Nemrut heykellerinin
    // sivri külahı.
    canvas.save();
    canvas.translate(headC.dx, headC.dy + h * 0.08);
    canvas.rotate(_flinch.value * 0.012 - _dir * swat * 0.12);
    canvas.translate(-headC.dx, -headC.dy - h * 0.08);
    final hx = headC.dx;
    final hy = headC.dy;
    // Nemrut'un dev başı: Antiochos'un uzun tiarası; çenesi boynun üstünde.
    final hh = h * 0.38;
    final chin = Offset(hx, hy + h * 0.1);
    canvas.save();
    canvas.translate(chin.dx, chin.dy);
    NemrutArt.head(canvas, NemrutHead.antiochos, hh);
    canvas.restore();
    // Gözler: kandil ateşi; her temasta söner, sendelerken titrer.
    final flicker = stung > 0 ? (0.5 + 0.5 * math.sin(_t * 30)) : 1.0;
    final glowA = fallen ? 0.0 : (0.85 - hits * 0.22).clamp(0.0, 1.0) * flicker;
    for (final sx in const [-1.0, 1.0]) {
      final e = chin + Offset(sx * 10 * hh / 100, -34 * hh / 100);
      canvas.drawOval(
        Rect.fromCenter(center: e, width: 16, height: 9),
        Paint()
          ..color = const Color(0xFFFF9A40).withValues(alpha: 0.35 * glowA)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawOval(
        Rect.fromCenter(center: e, width: 8, height: 3.2),
        Paint()..color = const Color(0xFFFFC080).withValues(alpha: glowA),
      );
    }
    canvas.restore();
    // Çatlaklar: her temasta yenisi açılır, içinden kor gibi ışık sızar.
    if (hits > 0) _cracks(canvas, w, h);
    canvas.restore();
    if (!fallen) {
      // Kulak: ateşböceğinin girmesi gereken yer, hafifçe parlar.
      final e = ear - position;
      glowDot(
        canvas,
        e.toOffset(),
        16,
        kWarmLight,
        0.25 + 0.15 * math.sin(_t * 4),
      );
    }
  }
}

/// Temas sayısına göre devin çatlakları (yerel koordinatta, oranla).
const _crackLines = [
  // 1. temas: başta ve omuzda
  [
    Offset(0.46, 0.14),
    Offset(0.5, 0.2),
    Offset(0.47, 0.26),
    Offset(0.52, 0.31),
  ],
  [Offset(0.2, 0.31), Offset(0.27, 0.38), Offset(0.24, 0.45)],
  // 2. temas: gövde boyunca
  [Offset(0.62, 0.33), Offset(0.56, 0.42), Offset(0.6, 0.5), Offset(0.54, 0.6)],
  [Offset(0.3, 0.45), Offset(0.38, 0.52), Offset(0.34, 0.62)],
  // 3. temas (yıkılırken): bacaklara iner
  [Offset(0.5, 0.6), Offset(0.45, 0.7), Offset(0.5, 0.8), Offset(0.46, 0.92)],
];

extension on StoneGiant {
  /// Karanlıkta yürüyen dev heykel: Antiochos tiaralı başı, kuşaklı Pers
  /// tuniği, kıvrımlı geniş pantolon, arkada pelerin. Gövde gecenin kendisi
  /// kadar koyu; yalnız arkasından vuran şafak kenarını çizer, gözleri kor.
  void _renderDark(
    Canvas canvas, {
    required double buckle,
    required double stung,
    required bool walking,
    required bool swingA,
    required double half,
    required double lift,
  }) {
    final w = size.x;
    final h = size.y;
    canvas.save();
    // Çizim sağa bakar; sola yürürken aynalanır.
    if (_dir < 0) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }
    const body = Color(0xFF0B0910);
    const rimCol = Color(0xFFD89A6E);
    final fill = Paint()..color = body;
    final rim = Paint()
      ..color = rimCol.withValues(alpha: 0.75)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    final fold = Paint()
      ..color = const Color(0xFF1E1826)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    // Parça: önce arkadan vuran ışığın kenarı (sola-yukarı kaydırılmış
    // kopya), üstüne koyu gövde.
    Path solid(List<Path> ps) {
      var out = ps.first;
      for (final q in ps.skip(1)) {
        out = Path.combine(PathOperation.union, out, q);
      }
      return out;
    }

    void part(Path p) {
      canvas.drawPath(p.shift(const Offset(-2.2, -1.6)), rim);
      canvas.drawPath(p, fill);
    }

    // Ayak dibinde sis.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h - 2), width: w * 1.6, height: 26),
      Paint()
        ..color = const Color(0xFFB8A8C0).withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Yürüyüş: ağırlık basan bacağa geçer, öbürü kalkıp öne gelir.
    const reach = 16.0;
    double planted(double t) => reach * (1 - 2 * t);
    double swung(double t) =>
        reach * (-1 + 2 * (0.5 - math.cos(t * math.pi) / 2));
    final bob = -4 * lift + buckle * h * 0.14;
    final hipY = h * 0.6 + bob;
    final cx = w * 0.5;
    final sway = (swingA ? 1 : -1) * 3.0 * lift;
    // Bacak: geniş Pers pantolonu, dizde bükülür; ayakkabı kalın.
    Path leg(Offset hip, Offset foot) {
      final (knee, end) = solveLimb(hip, foot, h * 0.2, h * 0.2, bend: 1);
      Path tube(Offset a, Offset b, double w0, double w1) {
        final d = b - a;
        final n = Offset(-d.dy, d.dx) / (d.distance + 1e-6);
        return solid([
          Path()
            ..moveTo((a + n * w0).dx, (a + n * w0).dy)
            ..lineTo((b + n * w1).dx, (b + n * w1).dy)
            ..lineTo((b - n * w1).dx, (b - n * w1).dy)
            ..lineTo((a - n * w0).dx, (a - n * w0).dy)
            ..close(),
          Path()..addOval(Rect.fromCircle(center: b, radius: w1)),
        ]);
      }

      return solid([
        tube(hip, knee, w * 0.13, w * 0.11),
        tube(knee, end.translate(0, -h * 0.04), w * 0.11, w * 0.085),
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              end.dx - w * 0.1,
              end.dy - h * 0.05,
              end.dx + w * 0.17,
              end.dy,
            ),
            Radius.circular(w * 0.04),
          ),
        ),
      ]);
    }

    Offset foot(bool swingLeg, double baseX) => Offset(
      baseX +
          (walking ? (swingLeg ? swung(half) : planted(half)) : 0) +
          (swingLeg ? 0 : 0),
      h - (walking && swingLeg ? lift * 16 : 0),
    );
    final backHip = Offset(cx - w * 0.08 + sway, hipY);
    final frontHip = Offset(cx + w * 0.08 + sway, hipY);
    // Arka bacak ve arka kol önce (koyu ama hafif soluk: derinlik).
    final backLeg = leg(
      backHip,
      foot(!swingA, cx - w * 0.12) - Offset(buckle * 10, 0),
    );
    canvas.drawPath(backLeg, Paint()..color = const Color(0xFF15121B));
    // Pelerin: omuzlardan arkaya, dizlere dek; yürürken dalgalanır.
    final chestY = h * 0.3 + bob * 0.8;
    final flap = math.sin(_t * 1.6) * 6 + (walking ? lift * 6 : 0);
    part(
      Path()
        ..moveTo(cx - w * 0.2 + sway, chestY)
        ..cubicTo(
          cx - w * 0.42,
          h * 0.45,
          cx - w * 0.46 - flap,
          h * 0.66,
          cx - w * 0.36 - flap,
          h * 0.8,
        )
        ..lineTo(cx - w * 0.1, h * 0.72)
        ..lineTo(cx - w * 0.05 + sway, chestY)
        ..close(),
    );
    final frontLeg = leg(
      frontHip,
      foot(swingA, cx + w * 0.12) + Offset(buckle * 10, 0),
    );
    part(frontLeg);
    // Pantolonun kıvrımları.
    for (final y in [0.68, 0.74, 0.8]) {
      canvas.drawLine(
        Offset(frontHip.dx - w * 0.06, h * y + bob * 0.5),
        Offset(frontHip.dx + w * 0.05, h * y + 4 + bob * 0.5),
        fold,
      );
    }
    // Tunik: omuzlar geniş, belde kuşak, eteği uyluğu örter ve açılır.
    final hem = h * 0.66 + bob;
    final tunic = Path()
      ..moveTo(cx - w * 0.22 + sway, chestY)
      ..quadraticBezierTo(
        cx + sway * 0.6,
        chestY - h * 0.03,
        cx + w * 0.24 + sway,
        chestY,
      )
      ..lineTo(cx + w * 0.2 + sway, h * 0.5 + bob)
      ..lineTo(cx + w * 0.3 + sway * 1.3, hem)
      ..quadraticBezierTo(
        cx + sway,
        hem + h * 0.025,
        cx - w * 0.3 + sway * 1.3,
        hem,
      )
      ..lineTo(cx - w * 0.2 + sway, h * 0.5 + bob)
      ..close();
    part(tunic);
    // Kuşak ve eteğin kıvrımları.
    canvas.drawLine(
      Offset(cx - w * 0.21 + sway, h * 0.5 + bob),
      Offset(cx + w * 0.21 + sway, h * 0.5 + bob),
      Paint()
        ..color = const Color(0xFF2A2030)
        ..strokeWidth = 4,
    );
    for (var i = -2; i <= 2; i++) {
      canvas.drawLine(
        Offset(cx + i * w * 0.08 + sway, h * 0.52 + bob),
        Offset(cx + i * w * 0.11 + sway * 1.2, hem - 2),
        fold,
      );
    }
    // Kollar: omuzdan sarkan geniş kollu giysi; yürürken sallanır, temasta
    // öndeki el kulağa gider.
    final swat = stung > 0
        ? math.sin(math.min(1, (1 - stung) * 3) * math.pi / 2)
        : 0.0;
    final headC = Offset(
      cx + _flinch.value * 0.6 + sway * 0.6,
      h * 0.17 + bob * 0.7,
    );
    for (final side in [-1.0, 1.0]) {
      final sh = Offset(cx + side * w * 0.22 + sway, chestY + h * 0.02);
      final swing = walking ? (swingA ? 1 : -1) * side * lift * 10 : 0.0;
      var hand = Offset(sh.dx + side * 4 + swing, h * 0.58 + bob * 0.5);
      if (side > 0 && swat > 0) {
        hand = Offset.lerp(hand, headC + Offset(w * 0.2, 4), swat)!;
      } else if (stung > 0) {
        hand = hand.translate(side * 12 * stung, -10 * stung);
      }
      if (buckle > 0) {
        hand = hand.translate(side * 10 * buckle, -h * 0.05 * buckle);
      }
      final (elbow, end) = solveLimb(sh, hand, h * 0.16, h * 0.15, bend: side);
      Path seg(Offset a, Offset b, double r0, double r1) {
        final d = b - a;
        final n = Offset(-d.dy, d.dx) / (d.distance + 1e-6);
        return solid([
          Path()
            ..moveTo((a + n * r0).dx, (a + n * r0).dy)
            ..lineTo((b + n * r1).dx, (b + n * r1).dy)
            ..lineTo((b - n * r1).dx, (b - n * r1).dy)
            ..lineTo((a - n * r0).dx, (a - n * r0).dy)
            ..close(),
          Path()..addOval(Rect.fromCircle(center: a, radius: r0)),
          Path()..addOval(Rect.fromCircle(center: b, radius: r1)),
        ]);
      }

      final arm = solid([
        seg(sh, elbow, w * 0.085, w * 0.07),
        seg(elbow, end, w * 0.07, w * 0.055),
        Path()..addOval(Rect.fromCircle(center: end, radius: w * 0.065)),
      ]);
      if (side < 0) {
        canvas.drawPath(arm, Paint()..color = const Color(0xFF15121B));
      } else {
        part(arm);
      }
    }
    // Baş: Nemrut tiarası; yüz koyu, kenarı şafakla çizilir.
    canvas.save();
    final chin = Offset(headC.dx, headC.dy + h * 0.1);
    canvas.translate(chin.dx, chin.dy);
    canvas.rotate(_flinch.value * 0.012 - swat * 0.12);
    final hh = h * 0.3;
    canvas.save();
    canvas.translate(-2.2, -1.6);
    NemrutArt.head(
      canvas,
      NemrutHead.antiochos,
      hh,
      flat: rimCol.withValues(alpha: 0.7),
    );
    canvas.restore();
    NemrutArt.head(canvas, NemrutHead.antiochos, hh, flat: body);
    // Gözler: kor; her temasta söner, sendelerken titrer.
    final flicker = stung > 0 ? (0.5 + 0.5 * math.sin(_t * 30)) : 1.0;
    final glowA = fallen ? 0.0 : (0.9 - hits * 0.22).clamp(0.0, 1.0) * flicker;
    for (final sx in const [-1.0, 1.0]) {
      final e = Offset(sx * 10 * hh / 100, -34 * hh / 100);
      canvas.drawOval(
        Rect.fromCenter(center: e, width: 18, height: 10),
        Paint()
          ..color = const Color(0xFFFF8A30).withValues(alpha: 0.45 * glowA)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawOval(
        Rect.fromCenter(center: e, width: 8, height: 3),
        Paint()..color = const Color(0xFFFFC080).withValues(alpha: glowA),
      );
    }
    canvas.restore();
    canvas.restore();
  }

  /// Kullanıcının çizdiği taş dev (tools/import_nemrut_svg.py): her uzuv
  /// rig.json'daki dönüş noktası etrafında çevrilir. Yürüyüş eski çizimle
  /// aynı evreden çıkar: basan ayak yerde kalır, öbürü kalkıp öne gelir,
  /// kalça basan ayağa kayar. Çizim sola bakar; sağa yürürken aynalanır.
  void _renderSprites(
    Canvas canvas, {
    required double buckle,
    required double stung,
    required bool walking,
    required bool swingA,
    required double half,
    required double lift,
  }) {
    final w = size.x;
    final h = size.y;
    final sc = _svgScale;
    canvas.save();
    canvas.translate(w / 2, h);
    canvas.scale(sc * (_dir > 0 ? -1 : 1), sc);
    canvas.translate(-320, -801);
    final tint = Paint()
      ..filterQuality = FilterQuality.medium
      ..colorFilter = ColorFilter.mode(
        NemrutImages.tint(game),
        BlendMode.modulate,
      );
    void img(String k, {Offset at = Offset.zero}) {
      final im = NemrutImages.get(k);
      final r = nemrutSprites[k];
      if (im == null || r == null) return;
      canvas.drawImageRect(
        im,
        Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()),
        r.shift(at),
        tint,
      );
    }

    // Bir uzvu [pivot0] çevresinde döndürüp [pivot]a taşıyarak çizer.
    void part(String k, Offset pivot0, Offset pivot, double rot) {
      canvas.save();
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(rot);
      canvas.translate(-pivot0.dx, -pivot0.dy);
      img(k);
      canvas.restore();
    }

    // Çizim bükülmez: adım atan bacak bütün hâlinde kalkıp öne gelir ve
    // basar (ağır taş adım); kollar omuzdan tek parça sallanır. İleri yön
    // çizimde -x.
    final bob = -3 * lift + buckle * 110;
    final body = Offset(0, bob);
    final upper = Offset(0, bob * 0.9);

    void leg(String side, bool swinging) {
      final up = walking && swinging ? lift * 26 : 0.0;
      // Kalkan ayak öne gider, basan ayak geriye kayar (gövde ilerler).
      final dx = walking
          ? (swinging ? -10 * math.sin(half * math.pi) : 0.0)
          : 0.0;
      final spread = buckle * (side == 'front' ? -26 : 26);
      final at = Offset(dx + spread, -up + bob * 0.3);
      for (final k in ['leg', 'shin', 'foot']) {
        img('giant_${k}_$side', at: at);
      }
    }

    // Kol: omuz çevresinde tek parça döner.
    void arm(String side, Offset sh0, double rot, {required bool plate}) {
      final sh = sh0 + upper;
      for (final k in ['arm', 'forearm', 'hand']) {
        part('giant_${k}_$side', sh0, sh, rot);
      }
      if (plate) part('giant_shoulder_$side', sh0, sh, rot * 0.4);
    }

    final armSwing = walking ? (swingA ? 1 : -1) * lift * 0.09 : 0.0;
    // Temasta kulak tarafındaki (arka) kol kulağa kalkar.
    final swat = stung > 0
        ? math.sin(math.min(1, (1 - stung) * 3) * math.pi / 2)
        : 0.0;
    final backRot = armSwing - swat * 2.3 - buckle * 0.5;
    final frontRot = -armSwing + stung * 0.25 + buckle * 0.5;

    // SVG belge sırası.
    leg('back', !swingA);
    arm('back', const Offset(452, 282), backRot, plate: false);
    img('giant_pelvis', at: body);
    leg('front', swingA);
    img('giant_torso', at: upper);
    img('giant_chest_carving', at: upper);
    // Baş: temasta kulaktan kaçar.
    final neck = const Offset(335, 239) + upper;
    canvas.save();
    canvas.translate(neck.dx, neck.dy);
    canvas.rotate(-_flinch.value * 0.012 + swat * 0.12);
    canvas.translate(-335, -239);
    canvas.translate(-_flinch.value / sc, 0);
    img('giant_head');
    // Gözler: kandil ateşi; her temasta söner, sendelerken titrer.
    final flicker = stung > 0 ? (0.5 + 0.5 * math.sin(_t * 30)) : 1.0;
    final glowA = fallen ? 0.0 : (0.85 - hits * 0.22).clamp(0.0, 1.0) * flicker;
    for (final e in const [Offset(306.7, 171.7), Offset(354.7, 171.7)]) {
      canvas.drawOval(
        Rect.fromCenter(center: e, width: 30, height: 16),
        Paint()
          ..color = const Color(0xFFFF9A40).withValues(alpha: 0.45 * glowA)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      if (glowA < 0.8) {
        // Sönen göz: kor kararır.
        canvas.drawOval(
          Rect.fromCenter(center: e, width: 22, height: 8),
          Paint()
            ..color = const Color(0xFF241E2C).withValues(alpha: 0.85 - glowA),
        );
      }
    }
    canvas.restore();
    arm('front', const Offset(207, 286), frontRot, plate: true);
    part(
      'giant_shoulder_back',
      const Offset(452, 282),
      const Offset(452, 282) + upper,
      0,
    );
    canvas.restore();
  }

  void _cracks(Canvas canvas, double w, double h) {
    final n = math.min(_crackLines.length, hits * 2 + (fallen ? 1 : 0));
    final glow = Paint()
      ..color = const Color(0xFFFF9A40).withValues(alpha: fallen ? 0.25 : 0.55)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final core = Paint()
      ..color = const Color(0xFFFFE0A0).withValues(alpha: fallen ? 0.3 : 0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < n; i++) {
      final pts = _crackLines[i];
      final path = Path()..moveTo(pts.first.dx * w, pts.first.dy * h);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx * w, p.dy * h);
      }
      canvas.drawPath(path, glow);
      canvas.drawPath(path, core);
    }
  }
}

/// Yıkılan devin gövdesi: üstünden geçilen bir köprü.
class GiantBridge extends Deck {
  GiantBridge(Vector2 at) : super(position: at, size: Vector2(9 * kTile, 16));

  @override
  void step(double dt) {}

  @override
  void render(Canvas canvas) {
    final stone = Paint()..color = const Color(0xFF241E2C);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, 22),
        const Radius.circular(8),
      ),
      stone,
    );
    canvas.drawLine(
      const Offset(4, 1.5),
      Offset(size.x - 4, 1.5),
      Paint()
        ..color = const Color(0xFFC8D2E2).withValues(alpha: 0.7)
        ..strokeWidth = 2,
    );
  }
}

/// Bölümün depremi: ara ara yer sarsılır, gevşek kayalar düşer.
class QuakeClock extends Component with HasGameReference<GolgeGame> {
  double _t = 5;

  @override
  void update(double dt) {
    game.quake = math.max(0, game.quake - dt * 0.7);
    _t -= dt;
    if (_t <= 0) {
      _t = 11 + math.sin(game.levelIndex * 3.0 + _t) * 2;
      game.quake = 1;
      game.shake(7);
      GameAudio.instance.play('grind', volume: 0.9);
      GameAudio.instance.play('crumble', volume: 0.6);
    }
  }
}
