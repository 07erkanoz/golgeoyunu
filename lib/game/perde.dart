import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'myth_figures.dart';
import 'myth_shapes.dart';
import 'palette.dart';

part 'perde_east.dart';

/// Perde sahneleri: prologda, bölüm aralarında ve finalde oynanan gölge oyunu.
enum PerdeScene {
  prologue,
  galata,
  kaf,

  /// Kaf'ın sırrı: aynadaki gölge, kandil doğuya taşınır.
  mirror,

  /// Tufan: gemi Ağrı'ya oturur, güvercin zeytin dalıyla döner.
  flood,

  /// Nemrut'un taş tanrıları; depremde başları düşer.
  gods,

  /// Nemrut'ta gün doğumu: kırık güneş tanrıların yüzüne vurur.
  dawn,

  /// Palandöken: karda kervan, palanlar dökülür, doruklarda ejderler.
  caravan,

  /// Ejder uyanır, çığ iner.
  avalanche,

  /// Periler devlerin ateşini söndürür, küllerden bacalar yükselir.
  fairies,

  /// Derinkuyu'nun kesiti: inen fenerler, uyuyan dev.
  underground,

  /// Ötüken açılışı: ilk su, sudan yükselen Ak Ana, çamurdan kalkan dünya,
  /// yerin altına sürülen Erlik.
  akAna,

  /// Ergenekon: dağlarla çevrili vadi, demirci ve yetmiş körük, eriyen dağ,
  /// yolu gösteren kurt, örste dövülen kızgın demir.
  ergenekon,

  /// Göğün katları: kam davulu, Ülgen'in ışığı, ay ve güneş, Hüma ve
  /// Tulpar, kırık güneşin parçası.
  gok,

  /// Konya: düğün gecesi, semâzenler, neyzen.
  sema,

  /// Son: Yeşil Kubbe'de kandil söner, gölge ışığa karışır.
  epilogue,
}

/// Bölümden önce oynanan perde sahnesi (yoksa düz geçiş).
PerdeScene? interludeScene(int level) => switch (level) {
  1 => PerdeScene.galata,
  2 || 3 => PerdeScene.kaf,
  4 => PerdeScene.mirror,
  5 => PerdeScene.flood,
  6 => PerdeScene.gods,
  7 => PerdeScene.dawn,
  8 || 9 => PerdeScene.caravan,
  10 => PerdeScene.avalanche,
  11 => PerdeScene.fairies,
  12 => PerdeScene.underground,
  13 => PerdeScene.sema,
  14 => PerdeScene.akAna,
  15 => PerdeScene.ergenekon,
  16 => PerdeScene.gok,
  _ => null,
};

/// Arkadan kandille aydınlanan bez perde ve üstündeki çubuklu tasvirler.
///
/// Tasvirler 780×400'lük sanal bir sahnede çizilir (zemin y=350) ve perdenin
/// boyuna ölçeklenir. Konumlar satır ilerleyişine ([progress]: 0, 1, 2…
/// satır başları; aradaki değerler satırın içi) göre hesaplanır.
class PerdePainter {
  PerdePainter._();

  static const _vw = 780.0;
  static const _vh = 400.0;
  static const _ground = 350.0;

  static const _ink = Color(0xFF1A0B05);
  static const _hole = kWarmLight;

  /// Perdenin ekrandaki yeri (yazı altında kalır).
  static Rect screenRect(Size size) {
    final sw = math.min(size.width * 0.78, size.height * 1.35);
    final sh = sw * 0.5;
    return Rect.fromLTWH((size.width - sw) / 2, size.height * 0.1, sw, sh);
  }

  static void paint(
    Canvas canvas,
    Size size,
    PerdeScene scene,
    double time,
    double progress,
    double alpha,
  ) {
    if (alpha <= 0) return;
    _time = time;
    final r = screenRect(size);
    final layered = alpha < 0.999;
    if (layered) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Color.fromRGBO(0, 0, 0, alpha),
      );
    }

    // Kandilin titreşimi ve sahneye göre perdenin aydınlığı.
    final flicker =
        0.92 + 0.05 * math.sin(time * 7.3) + 0.03 * math.sin(time * 13.1 + 1.7);
    final lamp = _lampFor(scene, progress) * flicker;

    // Oda: perdenin ışığı yere ve tavana vurur.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050302),
    );
    canvas.drawCircle(
      r.center,
      r.width * 0.75,
      Paint()
        ..shader = ui.Gradient.radial(r.center, r.width * 0.75, [
          const Color(0xFF2A140B).withValues(alpha: 0.9 * lamp),
          const Color(0xFF2A140B).withValues(alpha: 0),
        ]),
    );

    // Bez.
    canvas.save();
    canvas.clipRect(r);
    final c = Offset(r.left + r.width * 0.52, r.top + r.height * 0.62);
    canvas.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          r.width * 0.7,
          const [
            Color(0xFFFFD9A0),
            Color(0xFFF2B46A),
            Color(0xFFB8692F),
            Color(0xFF4A2210),
          ],
          const [0, 0.18, 0.55, 1],
        ),
    );
    // Bezin dokusu: ince yatay iplikler.
    final weave = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (var y = r.top + 1.5; y < r.bottom; y += 3) {
      canvas.drawLine(Offset(r.left, y), Offset(r.right, y), weave);
    }

    // Tasvirler sanal sahnede.
    canvas.save();
    canvas.translate(r.left, r.top);
    final k = r.width / _vw;
    canvas.scale(k, r.height / _vh);
    switch (scene) {
      case PerdeScene.prologue:
        _prologue(canvas, time, progress);
      case PerdeScene.galata:
        _galata(canvas, time, progress);
      case PerdeScene.kaf:
        _kaf(canvas, time, progress);
      case PerdeScene.mirror:
        _mirror(canvas, time, progress);
      case PerdeScene.flood:
        _floodScene(canvas, time, progress);
      case PerdeScene.gods:
        _godsScene(canvas, time, progress);
      case PerdeScene.dawn:
        _godsScene(canvas, time, progress, dawn: true);
      case PerdeScene.caravan:
        _caravanScene(canvas, time, progress);
      case PerdeScene.avalanche:
        _caravanScene(canvas, time, progress, avalanche: true);
      case PerdeScene.fairies:
        _fairiesScene(canvas, time, progress);
      case PerdeScene.underground:
        _fairiesScene(canvas, time, progress, underground: true);
      case PerdeScene.akAna:
        _akAnaScene(canvas, time, progress);
      case PerdeScene.ergenekon:
        _ergenekonScene(canvas, time, progress);
      case PerdeScene.gok:
        _gokScene(canvas, time, progress);
      case PerdeScene.sema:
        _semaScene(canvas, time, progress);
      case PerdeScene.epilogue:
        _endingScene(canvas, time, progress);
    }
    // Bölümün efsane kahramanları ve varlıkları, kendi satırlarında.
    _mythOverlay(canvas, scene, time, progress);
    canvas.restore();

    // Kandil kısıldıkça perde kararır; kenarlar hep biraz gölgede.
    canvas.drawRect(
      r,
      Paint()
        ..color = const Color(0xFF050302).withValues(alpha: (1 - lamp) * 0.92),
    );
    canvas.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          r.width * 0.62,
          [
            const Color(0xFF2A1208).withValues(alpha: 0),
            const Color(0xFF2A1208).withValues(alpha: 0.55),
          ],
          const [0.6, 1],
        ),
    );
    canvas.restore();

    _frame(canvas, r, lamp);
    if (layered) canvas.restore();
  }

  static double _lampFor(PerdeScene scene, double u) {
    if (scene == PerdeScene.epilogue) return _endingLamp(u);
    if (scene != PerdeScene.prologue) return 1;
    // Kandili söndürdüler: perde kararır, sonra bir gölge düşer.
    if (u < 2.7) return 1;
    if (u < 3.0) return 1 - 0.85 * _ease((u - 2.7) / 0.3);
    if (u < 4.0) return 0.15 + 0.2 * _ease((u - 3.0) / 1.0);
    return 0.35 + 0.35 * _ease((u - 4.0) / 0.6);
  }

  static void _frame(Canvas canvas, Rect r, double lamp) {
    final wood = Paint()..color = const Color(0xFF0B0503);
    final t = r.width * 0.023;
    canvas.drawRect(
      Rect.fromLTRB(r.left - t, r.top - t, r.right + t, r.top),
      wood,
    );
    canvas.drawRect(
      Rect.fromLTRB(r.left - t, r.bottom, r.right + t, r.bottom + t * 1.2),
      wood,
    );
    canvas.drawRect(
      Rect.fromLTRB(r.left - t, r.top - t, r.left, r.bottom),
      wood,
    );
    canvas.drawRect(
      Rect.fromLTRB(r.right, r.top - t, r.right + t, r.bottom),
      wood,
    );
    // Üstte kemer ve hilal.
    final mid = r.center.dx;
    final archW = r.width * 0.3;
    canvas.drawPath(
      Path()
        ..moveTo(mid - archW / 2, r.top - t + 1)
        ..quadraticBezierTo(
          mid,
          r.top - t - archW * 0.4,
          mid + archW / 2,
          r.top - t + 1,
        )
        ..close(),
      wood,
    );
    final moonC = Offset(mid, r.top - t - archW * 0.07);
    final mr = r.width * 0.014;
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: moonC, radius: mr)),
        Path()..addOval(
          Rect.fromCircle(
            center: moonC + Offset(mr * 0.45, -mr * 0.2),
            radius: mr * 0.85,
          ),
        ),
      ),
      Paint()
        ..color = const Color(0xFFA8622E).withValues(alpha: 0.5 + 0.3 * lamp),
    );
    // Saçaklar.
    final fringe = Paint()
      ..color = const Color(0xFF0B0503)
      ..strokeWidth = 1.5;
    for (var i = 0; i < 5; i++) {
      for (final x in [r.left + 8 + i * 12.0, r.right - 8 - i * 12.0]) {
        canvas.drawLine(
          Offset(x, r.bottom + t * 1.2),
          Offset(x, r.bottom + t * 1.2 + (i.isEven ? 12 : 8)),
          fringe,
        );
      }
    }
    // Çerçeveye vuran ışık.
    canvas.drawRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFFFB46A).withValues(alpha: 0.18 * lamp),
    );
  }

  // ------------------------------------------------------------- yardımcılar

  static double _ease(double x) {
    final t = x.clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  /// [a, b] aralığında 0→1 yumuşak geçiş.
  static double _span(double u, double a, double b) => _ease((u - a) / (b - a));

  /// Görünürlük: [a]'da belirir, [b]'de kaybolur.
  static double _shown(double u, double a, double b, [double fade = 0.25]) =>
      math.min(_span(u, a, a + fade), 1 - _span(u, b - fade, b));

  static Paint _inkPaint(double a) =>
      Paint()..color = _ink.withValues(alpha: 0.92 * a);

  static Paint _holePaint(double a) =>
      Paint()..color = _hole.withValues(alpha: 0.95 * a);

  /// Tasvirin tutulduğu çubuk ve hafif sallantısı: [draw] ayak noktasına göre.
  static void _puppet(
    Canvas canvas,
    Offset feet,
    double time,
    double seed,
    double a,
    void Function(Paint ink, Paint hole) draw, {
    double scale = 1,
    bool flip = false,
    bool rod = true,
  }) {
    if (a <= 0.01) return;
    final ink = _inkPaint(a);
    canvas.save();
    canvas.translate(feet.dx, feet.dy + math.sin(time * 1.7 + seed) * 1.2);
    canvas.rotate(math.sin(time * 1.1 + seed * 2) * 0.025);
    canvas.scale(flip ? -scale : scale, scale);
    draw(ink, _holePaint(a));
    if (rod) {
      canvas.drawLine(
        const Offset(0, 0),
        const Offset(3, 120),
        ink..strokeWidth = 2.5,
      );
    }
    canvas.restore();
  }

  // ------------------------------------------------------------- tasvirler

  /// Kubbeler ve minareler: tasvir kesimi gibi delikli şehir zemini.
  static void _city(Canvas canvas, double a) {
    final ink = _inkPaint(a);
    canvas.drawPath(
      Path()
        ..moveTo(0, 385)
        ..lineTo(0, _ground)
        ..quadraticBezierTo(50, _ground, 62, 320)
        ..quadraticBezierTo(80, 280, 110, 320)
        ..quadraticBezierTo(122, _ground, 170, _ground)
        ..lineTo(170, 310)
        ..lineTo(178, 260)
        ..lineTo(186, 310)
        ..lineTo(186, _ground)
        ..lineTo(310, _ground)
        ..quadraticBezierTo(350, 300, 390, 300)
        ..quadraticBezierTo(430, 300, 470, _ground)
        ..lineTo(610, _ground)
        ..lineTo(610, 310)
        ..lineTo(618, 252)
        ..lineTo(626, 310)
        ..lineTo(626, _ground)
        ..quadraticBezierTo(680, _ground, 700, 325)
        ..quadraticBezierTo(725, 290, 750, 325)
        ..quadraticBezierTo(765, _ground, 780, _ground)
        ..lineTo(780, 400)
        ..lineTo(0, 400)
        ..close(),
      ink,
    );
    // Kubbe pencereleri: ışık delikleri.
    final hole = _holePaint(a * 0.8);
    for (final x in [370.0, 390.0, 410.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 3, 322, 6, 10),
          const Radius.circular(3),
        ),
        hole,
      );
    }
    canvas.drawCircle(const Offset(86, 318), 2.5, hole);
    canvas.drawCircle(const Offset(725, 322), 2.5, hole);
  }

  static void _flames(Canvas canvas, double time, double a) {
    if (a <= 0) return;
    final ink = _inkPaint(a);
    for (final (x, base, s) in [
      (86.0, 290.0, 1.0),
      (390.0, 300.0, 1.4),
      (618.0, 258.0, 0.7),
      (725.0, 296.0, 1.1),
      (240.0, _ground, 1.2),
    ]) {
      final f = math.sin(time * 9 + x) * 4 * s;
      canvas.drawPath(
        Path()
          ..moveTo(x - 14 * s, base)
          ..quadraticBezierTo(x - 12 * s, base - 22 * s, x + f, base - 44 * s)
          ..quadraticBezierTo(
            x + 4 * s,
            base - 22 * s,
            x + 2 * s,
            base - 30 * s,
          )
          ..quadraticBezierTo(x + 14 * s, base - 18 * s, x + 14 * s, base)
          ..close(),
        ink,
      );
      // Duman.
      canvas.drawCircle(
        Offset(x + f * 2, base - 70 * s - (time * 12 + x) % 40),
        9 * s,
        _inkPaint(a * 0.35),
      );
    }
  }

  static final _noHole = Paint()..color = const Color(0x00000000);

  /// Sâye tasviri (ayak noktası orijinde, boyu ~84).
  static void drawSaye(
    Canvas canvas,
    Paint ink,
    Paint hole,
    double time, {
    double jar = 1,
  }) {
    _c = canvas;
    _saye(ink, hole, time, jar: jar);
  }

  /// Hayali Usta tasviri (ayak noktası orijinde).
  static void drawMaster(Canvas canvas, Paint ink) {
    _c = canvas;
    _master(ink, _noHole);
  }

  /// Kandilci tasviri (ayak noktası orijinde).
  static void drawLamplighter(Canvas canvas, Paint ink) {
    _c = canvas;
    _lamplighter(ink, _noHole);
  }

  /// Tasvirlerin çizildiği tuval (her sahnenin başında atanır).
  static late Canvas _c;

  /// Sahnenin zamanı: eklemli parçalar (baş, kol) buna göre oynar.
  static double _time = 0;

  /// Karagöz tasviri gibi: [draw] parçası [pin] çivisinden [angle] kadar
  /// döner; çivi perdede ışık geçen küçük bir delik olarak görünür.
  static void _hinge(
    Offset pin,
    double angle,
    Paint hole,
    void Function() draw,
  ) {
    final c = _c;
    c.save();
    c.translate(pin.dx, pin.dy);
    c.rotate(angle);
    c.translate(-pin.dx, -pin.dy);
    draw();
    c.restore();
    c.drawCircle(pin, 1.8, hole);
  }

  /// Kandilci: kukuletalı, kambur, asasında fener (ayak noktası orijinde).
  static void _lamplighter(Paint ink, Paint hole, {double lanternLift = 0}) {
    final c = _c;
    final lift = lanternLift;
    c.drawPath(
      Path()
        ..moveTo(-5, -150)
        ..quadraticBezierTo(-23, -146, -27, -120)
        ..lineTo(-35, 0)
        ..lineTo(35, 0)
        ..lineTo(27, -90)
        ..quadraticBezierTo(25, -130, 11, -144)
        ..close(),
      ink,
    );
    // Sivri kukulete: boyun çivisinden hafifçe başını eğip kaldırır.
    _hinge(const Offset(3, -147), math.sin(_time * 0.8 + 1) * 0.06, hole, () {
      c.drawPath(
        Path()
          ..moveTo(-5, -150)
          ..lineTo(-11, -176)
          ..quadraticBezierTo(1, -164, 11, -144)
          ..close(),
        ink,
      );
    });
    // Kol ve asa: omuz çivisinden döner; fener hafifçe sallanır.
    final armAngle = math.sin(_time * 1.1) * 0.04;
    c.save();
    c.translate(29, -86);
    c.rotate(armAngle);
    c.translate(-29, 86);
    c.drawPath(
      Path()
        ..moveTo(27, -90)
        ..lineTo(80, -118 - lift * 0.5)
        ..lineTo(84, -112 - lift * 0.5)
        ..lineTo(31, -80)
        ..close(),
      ink,
    );
    c.drawPath(
      Path()
        ..moveTo(84, -190 - lift)
        ..lineTo(88, -190 - lift)
        ..lineTo(92, 0)
        ..lineTo(88, 0)
        ..close(),
      ink,
    );
    // Fener: içi ışık deliği.
    c.drawPath(
      Path()
        ..moveTo(74, -198 - lift)
        ..lineTo(102, -198 - lift)
        ..lineTo(98, -178 - lift)
        ..lineTo(78, -178 - lift)
        ..close(),
      ink,
    );
    c.drawRect(Rect.fromLTWH(82, -194 - lift, 12, 12), hole);
    c.restore();
    c.drawCircle(const Offset(29, -86), 1.8, hole);
    // Oymalar.
    c.drawCircle(const Offset(3, -72), 2.5, hole);
    c.drawCircle(const Offset(-5, -54), 2, hole);
  }

  /// Hayali Usta: uzun kavuklu yaşlı adam, elleri arkada bağlı.
  static void _master(Paint ink, Paint hole) {
    final c = _c;
    c.drawPath(
      Path()
        ..moveTo(2, -176)
        ..quadraticBezierTo(-16, -180, -20, -158)
        ..quadraticBezierTo(-22, -142, -8, -136)
        ..lineTo(-10, -124)
        ..quadraticBezierTo(-34, -116, -36, -80)
        ..lineTo(-42, 0)
        ..lineTo(42, 0)
        ..lineTo(36, -80)
        ..quadraticBezierTo(34, -114, 12, -124)
        ..lineTo(14, -136)
        ..quadraticBezierTo(28, -144, 24, -162)
        ..quadraticBezierTo(20, -178, 2, -176)
        ..close(),
      ink,
    );
    // Kavuk, sakal ve burun boyun çivisinden ağır ağır sallanır: yaşlı bir
    // başın yorgun eğilişi.
    _hinge(
      const Offset(2, -150),
      math.sin(_time * 0.7) * 0.05 - 0.02,
      hole,
      () {
        // Uzun kavuk.
        c.drawPath(
          Path()
            ..moveTo(-14, -172)
            ..quadraticBezierTo(-12, -222, 4, -228)
            ..quadraticBezierTo(20, -222, 20, -170)
            ..close(),
          ink,
        );
        // Uzun, sivri sakal: göğsüne iner.
        c.drawPath(
          Path()
            ..moveTo(6, -146)
            ..quadraticBezierTo(24, -146, 22, -134)
            ..quadraticBezierTo(20, -116, 10, -100)
            ..quadraticBezierTo(8, -118, 2, -134)
            ..close(),
          ink,
        );
        // Burun.
        c.drawPath(
          Path()
            ..moveTo(21, -162)
            ..lineTo(29, -152)
            ..lineTo(22, -150)
            ..close(),
          ink,
        );
      },
    );
    // Arkada bağlı kollar: omuz çivisinden zincire çekilir gibi kıpırdar.
    _hinge(const Offset(-24, -102), math.sin(_time * 1.3 + 2) * 0.07, hole, () {
      c.drawPath(
        Path()
          ..moveTo(-28, -106)
          ..quadraticBezierTo(-50, -80, -36, -56)
          ..lineTo(-28, -60)
          ..quadraticBezierTo(-38, -78, -20, -98)
          ..close(),
        ink,
      );
    });
    // Eklem çivileri ve oymalar.
    c.drawCircle(const Offset(-2, -80), 3, hole);
    c.drawCircle(const Offset(10, -66), 2.2, hole);
    c.drawCircle(const Offset(-12, -58), 2.2, hole);
    c.drawPath(
      Path()
        ..moveTo(-4, -44)
        ..quadraticBezierTo(0, -54, 4, -44)
        ..quadraticBezierTo(0, -38, -4, -44)
        ..close(),
      hole,
    );
  }

  /// Sâye: küçük gölge, dağınık saç, uzun atkı, kavanozun ışığı.
  static void _saye(Paint ink, Paint hole, double time, {double jar = 1}) {
    final c = _c;
    // Baş ve saç boyun çivisinden: bakınır, hafifçe başını kaldırır.
    _hinge(const Offset(0, -56), math.sin(time * 0.9 + 0.4) * 0.07, hole, () {
      c.drawCircle(const Offset(0, -66), 11, ink);
      // Dağınık saç: tutamlar rüzgârla arkaya yatar.
      final sway = math.sin(time * 2.1) * 2;
      c.drawPath(
        Path()
          ..moveTo(10, -70)
          ..quadraticBezierTo(6, -80, -2, -78)
          ..quadraticBezierTo(-12, -84 + sway, -22, -80 + sway)
          ..quadraticBezierTo(-14, -77, -13, -74)
          ..quadraticBezierTo(-22, -72 + sway, -26, -66 + sway)
          ..quadraticBezierTo(-16, -66, -10, -64)
          ..close(),
        ink,
      );
    });
    c.drawPath(
      Path()
        ..moveTo(-8, -56)
        ..lineTo(-11, 0)
        ..lineTo(13, 0)
        ..lineTo(9, -56)
        ..close(),
      ink,
    );
    // Uzun atkı rüzgârda.
    final w = math.sin(time * 2.4) * 3;
    c.drawPath(
      Path()
        ..moveTo(-6, -55)
        ..quadraticBezierTo(-22, -52 + w, -36, -44 + w)
        ..lineTo(-34, -40 + w)
        ..quadraticBezierTo(-20, -46 + w, -4, -49)
        ..close(),
      ink,
    );
    // Kavanozu tutan kol: omuz çivisinden, kavanozla birlikte sallanır.
    final jarHole = Paint()
      ..color = _hole.withValues(alpha: hole.color.a * jar);
    _hinge(const Offset(8, -46), math.sin(time * 1.5 + 0.8) * 0.12, hole, () {
      c.drawPath(
        Path()
          ..moveTo(8, -46)
          ..lineTo(24, -34)
          ..lineTo(21, -30)
          ..lineTo(6, -40)
          ..close(),
        ink,
      );
      if (jar > 0) {
        c.drawCircle(
          const Offset(26, -26),
          5 + 1.2 * math.sin(time * 5),
          jarHole,
        );
      }
    });
  }

  /// Hüdhüd: tepelikli, ince uzun gagalı kuş.
  static void _hoopoe(Paint ink, double time, {bool flying = false}) {
    final c = _c;
    c.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 26, height: 16),
      ink,
    );
    c.drawCircle(const Offset(11, -7), 5.5, ink);
    c.drawPath(
      Path()
        ..moveTo(15, -9)
        ..quadraticBezierTo(24, -8, 31, -3)
        ..lineTo(15, -5)
        ..close(),
      ink,
    );
    c.drawPath(
      Path()
        ..moveTo(6, -10)
        ..lineTo(2, -26)
        ..lineTo(9, -14)
        ..lineTo(10, -29)
        ..lineTo(14, -14)
        ..lineTo(19, -25)
        ..lineTo(16, -10)
        ..close(),
      ink,
    );
    c.drawPath(
      Path()
        ..moveTo(-12, -2)
        ..lineTo(-26, 2)
        ..lineTo(-12, 4)
        ..close(),
      ink,
    );
    if (flying) {
      final f = math.sin(time * 9) * 14;
      c.drawPath(
        Path()
          ..moveTo(-6, -3)
          ..quadraticBezierTo(-10, -18 - f, 2, -30 - f)
          ..quadraticBezierTo(8, -16 - f, 6, -3)
          ..close(),
        ink,
      );
    }
  }

  static void _bird(
    Canvas canvas,
    Offset p,
    double time,
    double a,
    double seed,
  ) {
    final f = math.sin(time * 8 + seed) * 5;
    canvas.drawPath(
      Path()
        ..moveTo(p.dx - 10, p.dy - f)
        ..quadraticBezierTo(p.dx - 4, p.dy - 3, p.dx, p.dy + 1)
        ..quadraticBezierTo(p.dx + 4, p.dy - 3, p.dx + 10, p.dy - f)
        ..quadraticBezierTo(p.dx + 4, p.dy + 1, p.dx, p.dy + 4)
        ..quadraticBezierTo(p.dx - 4, p.dy + 1, p.dx - 10, p.dy - f)
        ..close(),
      _inkPaint(a),
    );
  }

  // ------------------------------------------------------------- sahneler

  static void _prologue(Canvas canvas, double time, double u) {
    _c = canvas;
    _city(canvas, 1);
    // Şehir yanıyor; kandil sönerken alevler de çekilir.
    _flames(canvas, time, 1 - _span(u, 2.6, 3.0));

    // Kandilciler gelir, ustayı alıp götürür.
    final march = _span(u, 2.0, 3.0) * 300;
    final la = _shown(u, 0.8, 3.0);
    final lx = -120 + _span(u, 0.8, 1.9) * 330 + march;
    _puppet(canvas, Offset(lx, _ground), time, 0.3, la, (ink, hole) {
      _lamplighter(ink, hole, lanternLift: 10 * math.sin(time * 1.3));
    });
    final rx = 900 - _span(u, 1.2, 2.2) * 330 + march;
    _puppet(canvas, Offset(rx, _ground), time, 1.7, la, (ink, hole) {
      _lamplighter(ink, hole);
    }, flip: true);
    final ma = _shown(u, 1.8, 3.0);
    _puppet(canvas, Offset(390 + march, _ground), time, 2.9, ma, _master);

    // Gölgenin düşeceği yerde külden bir kayın fidanı yükselir: Umay ağacı,
    // dalında tek bir ak çaput.
    final grow = _span(u, 3.5, 4.3);
    if (grow > 0) _umaySapling(canvas, time, const Offset(470, _ground), grow);

    // Perde karardı: bir gölge düşer.
    final fall = _span(u, 3.15, 3.55);
    if (u > 3.1) {
      final y = -80 + fall * fall * (_ground + 80);
      _puppet(
        canvas,
        Offset(560, y),
        time,
        4.1,
        1,
        (ink, hole) => _saye(ink, hole, time, jar: _span(u, 3.6, 4.2)),
        rod: fall >= 1,
      );
    }
  }

  /// Umay ağacı fidanı: perdede kara bir kayın silueti (gerçek ağaç
  /// çiziminden), dalında rüzgârda dalgalanan tek bir ak çaput (perdede
  /// ışık sızan bir yarık gibi).
  static void _umaySapling(
    Canvas canvas,
    double time,
    Offset ground,
    double grow,
  ) {
    const s = 1.7;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(ground.dx - 120, 0, 240, ground.dy));
    canvas.translate(ground.dx, ground.dy + (30 + (1 - grow) * 70) * s);
    canvas.scale(s);
    canvas.drawPath(MythShapes.umayTree, _inkPaint(grow));
    canvas.restore();
    if (grow < 0.6) return;
    // Çaput: alt dallardan sarkan ince bir şerit.
    final a = (grow - 0.6) / 0.4;
    final knot = Offset(ground.dx - 16, ground.dy - 44);
    final cloth = Path()..moveTo(knot.dx, knot.dy);
    for (var i = 1; i <= 6; i++) {
      final k = i / 6;
      cloth.lineTo(
        knot.dx - k * 6 + math.sin(time * 2.4 - k * 3) * 3 * k,
        knot.dy + k * 22,
      );
    }
    canvas.drawPath(
      cloth,
      _holePaint(a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  static void _galata(Canvas canvas, double time, double u) {
    _c = canvas;
    // Tepeler, Galata Kulesi ve çevresi.
    final ink = _inkPaint(1);
    canvas.drawPath(
      Path()
        ..moveTo(0, 400)
        ..lineTo(0, 352)
        ..quadraticBezierTo(300, 320, 520, 300)
        ..quadraticBezierTo(650, 290, 780, 330)
        ..lineTo(780, 400)
        ..close(),
      ink,
    );
    const tx = 600.0;
    canvas.drawPath(
      Path()
        ..moveTo(tx - 34, 300)
        ..lineTo(tx - 30, 132)
        ..lineTo(tx - 38, 132)
        ..lineTo(tx - 38, 120)
        ..lineTo(tx + 38, 120)
        ..lineTo(tx + 38, 132)
        ..lineTo(tx + 30, 132)
        ..lineTo(tx + 34, 300)
        ..close(),
      ink,
    );
    canvas.drawPath(
      Path()
        ..moveTo(tx - 32, 120)
        ..lineTo(tx, 52)
        ..lineTo(tx + 32, 120)
        ..close(),
      ink,
    );
    final hole = _holePaint(1);
    for (var row = 0; row < 3; row++) {
      for (final dx in [-14.0, 0.0, 14.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(tx + dx - 3, 160 + row * 42.0, 6, 14),
            const Radius.circular(3),
          ),
          hole,
        );
      }
    }

    // Hezarfen: kuleden atlar, kanatlarıyla süzülür.
    final glide = _span(u, 3.1, 3.95);
    final ha = _shown(u, 0.9, 4.3, 0.4);
    if (ha > 0) {
      final hx = tx - glide * 720;
      final hy = 118 + math.sin(glide * math.pi) * -40 + glide * 150;
      canvas.save();
      canvas.translate(hx, hy + math.sin(time * 1.7) * 1.5);
      canvas.rotate(-0.1 * glide);
      final pi = _inkPaint(ha);
      // Gövde ve kavuk.
      canvas.drawPath(
        Path()
          ..moveTo(-8, -50)
          ..lineTo(-10, 0)
          ..lineTo(10, 0)
          ..lineTo(8, -50)
          ..close(),
        pi,
      );
      canvas.drawCircle(const Offset(0, -58), 8, pi);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -68), width: 18, height: 10),
        pi,
      );
      // Kanatlar: tüy yarıkları ışık deliği.
      final flap = glide > 0 && glide < 1 ? math.sin(time * 5) * 10 : 0.0;
      for (final side in [-1.0, 1.0]) {
        final wing = Path()
          ..moveTo(0, -44)
          ..quadraticBezierTo(side * 50, -70 - flap, side * 96, -58 - flap)
          ..lineTo(side * 86, -46 - flap * 0.6)
          ..lineTo(side * 74, -40 - flap * 0.5)
          ..lineTo(side * 60, -34 - flap * 0.4)
          ..quadraticBezierTo(side * 30, -34, 0, -32)
          ..close();
        canvas.drawPath(wing, pi);
        for (var f = 0; f < 3; f++) {
          canvas.drawLine(
            Offset(side * (30 + f * 18), -48 - flap * 0.3),
            Offset(side * (40 + f * 18), -40 - flap * 0.3),
            _holePaint(ha * 0.8)..strokeWidth = 1.6,
          );
        }
      }
      canvas.restore();
    }

    // Kalabalık: tepenin yamacında toplanmış İstanbullular. Hezarfen
    // süzülürken başlarını kaldırıp onu gösterirler; sultanın sözünden sonra
    // ağır ağır dağılırlar.
    final ca = _shown(u, 2.6, 5.0, 0.35);
    if (ca > 0) {
      // Yamaç: (0,352) → (520,300) ikinci dereceden eğri.
      double groundAt(double x) {
        var lo = 0.0, hi = 1.0;
        for (var k = 0; k < 18; k++) {
          final t = (lo + hi) / 2;
          final bx = 2 * (1 - t) * t * 300 + t * t * 520;
          if (bx < x) {
            lo = t;
          } else {
            hi = t;
          }
        }
        final t = lo;
        return (1 - t) * (1 - t) * 352 + 2 * (1 - t) * t * 320 + t * t * 300;
      }

      final hzX = tx - glide * 720;
      final scatter = _span(u, 4.3, 4.95);
      // (x, boy, tür: 0 erkek, 1 kadın, 2 çocuk, ters mi)
      const people = [
        (58.0, 70.0, 0, false),
        (84.0, 62.0, 1, false),
        (103.0, 40.0, 2, false),
        (138.0, 72.0, 0, true),
        (166.0, 60.0, 1, false),
        (205.0, 68.0, 0, false),
        (228.0, 38.0, 2, true),
        (262.0, 64.0, 1, true),
        (296.0, 74.0, 0, false),
        (330.0, 61.0, 1, false),
        (352.0, 66.0, 0, true),
      ];
      for (var i = 0; i < people.length; i++) {
        final (x0, hgt, kind, flipped) = people[i];
        // Dağılırken iki yana yürürler, sönerler.
        final dir = i.isEven ? -1.0 : 1.0;
        final x = x0 + dir * scatter * (40 + i * 6);
        final a = ca * (1 - scatter * 0.9);
        if (a <= 0.02) continue;
        final g = groundAt(x) + 2;
        final sway = math.sin(time * 1.3 + i * 1.7) * 0.03;
        final look = hzX < x ? 1.0 : -1.0;
        final facesRight = scatter > 0.05
            ? dir > 0
            : (flipped ? look < 0 : look > 0);
        final ink = _inkPaint(a);
        canvas.save();
        canvas.translate(x, g);
        canvas.rotate(sway);
        final sx = (facesRight ? 1.0 : -1.0) * hgt / 100;
        canvas.scale(sx, hgt / 100);
        if (kind == 1) {
          canvas.drawPath(MythFigures.akAnaSilhouette, ink);
          // Başörtüsü: başı ve omuzları saran yumuşak örtü.
          canvas.drawPath(
            Path()
              ..moveTo(-8, -86)
              ..cubicTo(-9, -104, 9, -104, 8, -86)
              ..cubicTo(10, -80, 11, -76, 12, -72)
              ..lineTo(-12, -72)
              ..cubicTo(-11, -76, -10, -80, -8, -86)
              ..close(),
            ink,
          );
        } else if (kind == 0) {
          canvas.drawPath(MythFigures.manSilhouette, ink);
        } else {
          canvas.drawPath(MythShapes.kam, ink);
        }
        canvas.restore();
        // Hezarfen süzülürken gösteren kol: omuzdan ona doğru.
        if (glide > 0.05 && scatter < 0.3 && i % 3 != 1) {
          final shoulder = Offset(
            x + (facesRight ? 4 : -4) * hgt / 70,
            g - hgt * 0.78,
          );
          final toward = Offset(hzX, 118 + glide * 150) - shoulder;
          final arm = toward / toward.distance * hgt * 0.42;
          canvas.drawLine(
            shoulder,
            shoulder + arm,
            ink
              ..strokeWidth = math.max(2.0, hgt * 0.06)
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }

    // Sâye kuleye bakar; Hüdhüd kulenin tepesinde.
    final sa = _span(u, 5.0, 5.4);
    _puppet(canvas, const Offset(260, 344), time, 0.9, sa, (ink, hole) {
      _saye(ink, hole, time);
    });
    if (sa > 0) {
      canvas.save();
      canvas.translate(tx + 2, 46 - sa * 0);
      canvas.scale(0.9);
      _hoopoe(_inkPaint(sa), time);
      canvas.restore();
    }
  }

  static void _cloud(Canvas canvas, double x, double y, double s, double a) {
    final p = _inkPaint(a);
    canvas.drawPath(
      Path()
        ..moveTo(x - 90 * s, y)
        ..quadraticBezierTo(x - 80 * s, y - 30 * s, x - 45 * s, y - 24 * s)
        ..quadraticBezierTo(x - 25 * s, y - 56 * s, x + 10 * s, y - 36 * s)
        ..quadraticBezierTo(x + 45 * s, y - 52 * s, x + 60 * s, y - 22 * s)
        ..quadraticBezierTo(x + 90 * s, y - 24 * s, x + 95 * s, y)
        ..close(),
      p,
    );
  }

  static void _kaf(Canvas canvas, double time, double u) {
    _c = canvas;
    // Uzakta Kaf Dağı: soluk, perdeden uzak tutulmuş tasvir.
    canvas.drawPath(
      Path()
        ..moveTo(420, 400)
        ..lineTo(560, 150)
        ..lineTo(585, 170)
        ..lineTo(620, 96)
        ..lineTo(650, 140)
        ..lineTo(672, 120)
        ..lineTo(780, 300)
        ..lineTo(780, 400)
        ..close(),
      _inkPaint(0.45),
    );
    // Dağın tepesinde ustanın kandili.
    final lampA = 0.55 + 0.45 * math.sin(time * 3.1) * math.sin(time * 1.3);
    canvas.drawCircle(
      const Offset(620, 92),
      3.5,
      _holePaint(_span(u, 2.9, 3.3) * lampA),
    );

    // Kırık güneş.
    final sun = _span(u, 1.9, 2.4);
    if (sun > 0) {
      const sc = Offset(300, 100);
      canvas.drawCircle(
        sc,
        90,
        Paint()
          ..shader = ui.Gradient.radial(sc, 90, [
            const Color(0xFFFFE6B8).withValues(alpha: 0.6 * sun),
            const Color(0xFFFFB060).withValues(alpha: 0),
          ]),
      );
      canvas.drawCircle(sc, 38, _holePaint(sun));
      // Eksik parça: Kandilcilerin kopardığı dilim.
      canvas.drawPath(
        Path()
          ..moveTo(sc.dx, sc.dy)
          ..lineTo(sc.dx + 40, sc.dy - 14)
          ..lineTo(sc.dx + 30, sc.dy + 30)
          ..close(),
        Paint()..color = const Color(0xFFB8692F).withValues(alpha: 0.9 * sun),
      );
      final crack = _inkPaint(sun)..strokeWidth = 2;
      canvas.drawLine(
        sc + const Offset(-27, -27),
        sc + const Offset(-4, -2),
        crack,
      );
      canvas.drawLine(
        sc + const Offset(-4, -2),
        sc + const Offset(-14, 36),
        crack,
      );
      canvas.drawLine(sc + const Offset(-4, -2), sc, crack);
      canvas.drawLine(
        sc + const Offset(-38, 8),
        sc + const Offset(-10, 14),
        crack,
      );
    }

    // Bulut denizi.
    for (final (x, y, s) in [
      (60.0, 400.0, 1.3),
      (250.0, 404.0, 1.1),
      (450.0, 398.0, 1.4),
      (690.0, 404.0, 1.2),
    ]) {
      _cloud(canvas, x + math.sin(time * 0.3 + x) * 6, y, s, 1);
    }

    // Kandilciler bulutun üstünde, fenerlerini göğe asar.
    final la = _shown(u, 1.9, 3.1, 0.3);
    _cloud(canvas, 150, 300, 0.8, la);
    _puppet(canvas, const Offset(120, 284), time, 0.4, la, (ink, hole) {
      _lamplighter(ink, hole, lanternLift: 60 + 6 * math.sin(time));
    }, scale: 0.5);
    _puppet(
      canvas,
      const Offset(190, 284),
      time,
      2.2,
      la,
      (ink, hole) {
        _lamplighter(ink, hole, lanternLift: 40);
      },
      scale: 0.45,
      flip: true,
    );

    // Hüdhüd kuşları Kaf'a götürür; çoğu yolda vazgeçer.
    final fly = _span(u, 0.8, 2.4);
    final fa = _shown(u, 0.8, 2.6, 0.3);
    if (fa > 0) {
      final lead = Offset(-40 + fly * 640, 220 - fly * 90);
      canvas.save();
      canvas.translate(lead.dx, lead.dy);
      canvas.scale(0.8);
      _hoopoe(_inkPaint(fa), time, flying: true);
      canvas.restore();
      for (var i = 0; i < 9; i++) {
        final row = i ~/ 2 + 1;
        final side = i.isEven ? -1 : 1;
        final p = lead + Offset(-row * 26.0, side * row * 13.0);
        // Vazgeçenler geride kalıp kaybolur.
        final quit = i % 3 != 0
            ? _span(fly, 0.35 + i * 0.05, 0.6 + i * 0.05)
            : 0.0;
        _bird(
          canvas,
          p + Offset(-quit * 120, quit * 40),
          time,
          fa * (1 - quit),
          i * 1.3,
        );
      }
    }

    // Sâye bir bulutun üstünde, dağa bakar.
    final sa = _span(u, 2.9, 3.3);
    _cloud(canvas, 330, 330, 0.7, sa);
    _puppet(canvas, const Offset(330, 312), time, 3.3, sa, (ink, hole) {
      _saye(ink, hole, time);
    }, scale: 0.85);
  }

  static void _mirror(Canvas canvas, double time, double u) {
    _c = canvas;
    // Zirve ve dev ayna: ışıktan bir oval, çevresi oymalı çerçeve.
    canvas.drawPath(
      Path()
        ..moveTo(0, 400)
        ..lineTo(0, 360)
        ..lineTo(240, 330)
        ..lineTo(390, 300)
        ..lineTo(540, 330)
        ..lineTo(780, 360)
        ..lineTo(780, 400)
        ..close(),
      _inkPaint(1),
    );
    final away = _span(u, 2.0, 2.4);
    const mc = Offset(390, 170);
    final mirrorA = 1 - away * 0.85;
    canvas.drawOval(
      Rect.fromCenter(center: mc, width: 170, height: 230),
      Paint()..color = _ink.withValues(alpha: 0.92 * mirrorA),
    );
    canvas.drawOval(
      Rect.fromCenter(center: mc, width: 140, height: 200),
      Paint()
        ..shader = ui.Gradient.radial(mc, 110, [
          const Color(0xFFFFF3D6).withValues(alpha: 0.95 * mirrorA),
          const Color(0xFFE8B070).withValues(alpha: 0.6 * mirrorA),
        ]),
    );
    // Otuz kuş: aynanın önüne konarlar.
    final land = _span(u, 0, 0.9);
    for (var i = 0; i < 30; i++) {
      final row = i ~/ 10;
      final tx = 120.0 + (i % 10) * 58 + row * 14;
      final ty = 352.0 - row * 9;
      final sx = -60.0 + i * 3;
      final sy = 60.0 + (i % 7) * 12;
      final p = Offset.lerp(Offset(sx, sy), Offset(tx, ty), land)!;
      if (land < 1) {
        _bird(canvas, p, time, 1 - away, i * 0.7);
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: p.translate(0, -5), width: 14, height: 9),
          _inkPaint(1 - away),
        );
      }
    }
    // Sâye ve aynadaki gölgesi: yansımada kavanozun ışığı yok.
    final sa = _shown(u, 0.9, 2.3, 0.3);
    _puppet(canvas, const Offset(300, 330), time, 0.6, sa, (ink, hole) {
      _saye(ink, hole, time);
    });
    if (sa > 0) {
      canvas.save();
      canvas.translate(mc.dx + 30, mc.dy + 80);
      canvas.scale(-1.1, 1.1);
      // Gölge bir an başını çevirir.
      final turn = u > 1.3 && u < 1.9 ? 1.0 : 0.0;
      if (turn > 0) canvas.scale(-1, 1);
      _saye(
        _inkPaint(sa * 0.9),
        Paint()..color = const Color(0x00000000),
        time,
        jar: 0,
      );
      canvas.restore();
    }
    // Kandilciler kandili doğuya taşır.
    final carry = _span(u, 2.1, 3.1);
    final ca = _shown(u, 2.05, 3.15, 0.25);
    for (var i = 0; i < 3; i++) {
      final x = 80 + i * 70 + carry * 520;
      _puppet(canvas, Offset(x, 352), time, i * 1.3, ca, (ink, hole) {
        _lamplighter(ink, hole, lanternLift: i == 1 ? 30 : 0);
      }, scale: 0.5);
    }
    if (ca > 0) {
      final lx = 80 + 70 + carry * 520 + 44;
      canvas.drawCircle(Offset(lx, 245), 6, _holePaint(ca));
    }
    // Doğuda Ağrı'nın iki doruğu belirir: Büyük ve Küçük.
    final agri = _span(u, 3.0, 3.6);
    if (agri > 0) {
      canvas.drawPath(
        Path()
          ..moveTo(60, 352)
          ..lineTo(300, 120)
          ..lineTo(360, 160)
          ..lineTo(470, 250)
          ..lineTo(560, 200)
          ..lineTo(700, 352)
          ..close(),
        _inkPaint(0.55 * agri),
      );
      canvas.drawPath(
        Path()
          ..moveTo(300, 120)
          ..lineTo(326, 142)
          ..lineTo(310, 146)
          ..lineTo(286, 136)
          ..close(),
        _holePaint(0.5 * agri),
      );
    }
  }

  /// Ana menünün perdesi: kandille aydınlanan bez, oymalı çerçeve, gölge
  /// harflerle oyunun adı, önünde Sâye ve Hüdhüd.
  static void paintMenu(
    Canvas canvas,
    Size size,
    double time,
    String title,
    String tagline,
  ) {
    final w = size.width;
    final r = Rect.fromLTWH(w * 0.06, w * 0.11, w * 0.88, w * 0.88 * 0.62);
    final flicker =
        0.9 + 0.06 * math.sin(time * 7.3) + 0.04 * math.sin(time * 13.1 + 1.7);
    // Perdenin ışığı çevreye vurur.
    canvas.drawCircle(
      r.center,
      r.width * 0.8,
      Paint()
        ..shader = ui.Gradient.radial(r.center, r.width * 0.8, [
          const Color(0xFF3A1A0B).withValues(alpha: 0.75 * flicker),
          const Color(0xFF3A1A0B).withValues(alpha: 0),
        ]),
    );
    canvas.save();
    canvas.clipRect(r);
    final c = Offset(r.left + r.width * 0.5, r.top + r.height * 0.55);
    canvas.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          r.width * 0.75,
          const [
            Color(0xFFFFE2B0),
            Color(0xFFF2B46A),
            Color(0xFFB8692F),
            Color(0xFF4A2210),
          ],
          const [0, 0.2, 0.58, 1],
        ),
    );
    final weave = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (var y = r.top + 1.5; y < r.bottom; y += 3) {
      canvas.drawLine(Offset(r.left, y), Offset(r.right, y), weave);
    }
    // Tasvirler 780×400'lük sanal sahnede (perde bezi 780×484).
    canvas.save();
    canvas.translate(r.left, r.top);
    final k = r.width / _vw;
    canvas.scale(k, k);
    _c = canvas;
    canvas.save();
    canvas.translate(0, 84);
    _city(canvas, 0.55);
    canvas.restore();
    // Oyunun adı: gölge harfler, kenarlarında kandilin sızan ışığı.
    final titleTp = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 70,
          fontWeight: FontWeight.w900,
          letterSpacing: 12,
          color: _ink.withValues(alpha: 0.95),
          shadows: [
            Shadow(
              color: const Color(0xFFFFF0C8).withValues(alpha: 0.5 * flicker),
              blurRadius: 18,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titleTp.paint(canvas, Offset(390 - titleTp.width / 2, 70));
    // Süs çizgisi: ortada bir lale.
    final line = _inkPaint(0.8)..strokeWidth = 2;
    canvas.drawLine(const Offset(210, 172), const Offset(370, 172), line);
    canvas.drawLine(const Offset(410, 172), const Offset(570, 172), line);
    canvas.drawPath(
      Path()
        ..moveTo(390, 160)
        ..quadraticBezierTo(380, 168, 384, 180)
        ..lineTo(390, 174)
        ..lineTo(396, 180)
        ..quadraticBezierTo(400, 168, 390, 160)
        ..close(),
      _inkPaint(0.9),
    );
    final tagTp = TextPainter(
      text: TextSpan(
        text: tagline,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 22,
          fontStyle: FontStyle.italic,
          letterSpacing: 1.5,
          color: _ink.withValues(alpha: 0.85),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 680);
    tagTp.paint(canvas, Offset(390 - tagTp.width / 2, 192));
    // Sâye ve Hüdhüd.
    _puppet(canvas, const Offset(200, 470), time, 0.7, 1, (ink, hole) {
      _saye(ink, hole, time);
    }, scale: 1.25);
    canvas.save();
    canvas.translate(
      600 + math.sin(time * 0.6) * 40,
      300 + math.sin(time * 1.1) * 14,
    );
    _hoopoe(_inkPaint(1), time, flying: true);
    canvas.restore();
    canvas.restore();
    // Kandil titrer; kenarlar gölgede.
    canvas.drawRect(
      r,
      Paint()
        ..color = const Color(0xFF050302)
            .withValues(alpha: (1 - flicker) * 0.9),
    );
    canvas.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          r.width * 0.62,
          [
            const Color(0xFF2A1208).withValues(alpha: 0),
            const Color(0xFF2A1208).withValues(alpha: 0.55),
          ],
          const [0.6, 1],
        ),
    );
    canvas.restore();
    _frame(canvas, r, flicker);
  }
}
