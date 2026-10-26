import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart';

import 'deer_rig.dart';
import 'myth_figures.dart';
import 'myth_shapes.dart';
import 'palette.dart';

part 'perde_east.dart';
part 'perde_giris.dart';
part 'perde_tasvir.dart';
part 'perde_kisi.dart';
part 'perde_kopru.dart';

/// Perde sahneleri: prologda, bölüm aralarında ve finalde oynanan gölge oyunu.
enum PerdeScene {
  prologue,
  galata,

  /// Gökyolu: Kaf sahnesinin çizimi, kendi kahramanları (Lagari, Tulpar).
  skyroad,
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

  /// Palandöken: kervan sahnesinin çizimi, kendi kahramanları (ejderler,
  /// derviş).
  dragons,

  /// Ejder uyanır, çığ iner.
  avalanche,

  /// Periler devlerin ateşini söndürür, küllerden bacalar yükselir.
  fairies,

  /// Derinkuyu'nun kesiti: inen fenerler, uyuyan dev.
  underground,

  /// Ötüken ormanı: köklerden yukarı, yeşil orman, Hayat Ağacı ve Umay'ın
  /// kuşları, peşteki Karabasan, yapraktan süzülen ışık.
  otuken,

  /// Ak Ana'nın Denizi: ilk su, sudan yükselen Ak Ana, çamurdan kalkan
  /// dünya, yerin altına sürülen Erlik.
  akAna,

  /// Erlik'in katı: Ak Ana sahnesinin devamı (Kişi'nin sürülüşünden
  /// başlar): Erlik, akan ışıklar, Er Töştük, Körmösler.
  erlik,

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
  2 => PerdeScene.skyroad,
  3 => PerdeScene.kaf,
  4 => PerdeScene.mirror,
  5 => PerdeScene.flood,
  6 => PerdeScene.gods,
  7 => PerdeScene.dawn,
  8 => PerdeScene.caravan,
  9 => PerdeScene.dragons,
  10 => PerdeScene.avalanche,
  11 => PerdeScene.fairies,
  12 => PerdeScene.underground,
  13 => PerdeScene.sema,
  14 => PerdeScene.erlik,
  15 => PerdeScene.ergenekon,
  16 => PerdeScene.gok,
  17 => PerdeScene.otuken,
  18 => PerdeScene.gok,
  19 => PerdeScene.sema,
  20 => PerdeScene.akAna,
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

  /// Göstermelik: Karagöz'de oyundan önce perdeye konan süslü deri levha.
  /// Perdenin ve bölümün adı böyle görünür: koyu levhanın içinde harfler
  /// oyuktur, kandilin ışığı onlardan geçer; kenarı zımbayla delinmiştir;
  /// Tasviri perdenin ortasını dolduran sahnelerde ([_asideScenes]) levha
  /// boş göğün bir yanına asılır. [k] 0 iken levha perdeden uzaktadır
  /// (bulanık, iri), 1 iken perdeye dayanmıştır (keskin).
  /// Başlık " · " ile ikiye bölünür: üstte küçük satır, altta büyük ad.
  /// Önizleme araçları için yazı tipi ailesi (oyunda sistemin yazı tipi).
  static String? debugFontFamily;

  /// En son çizilen sahne: göstermelik onun tasvirine göre yer seçer.
  static PerdeScene? _lastScene;
  static const _asideScenes = {PerdeScene.mirror};

  static void gostermelik(
    Canvas canvas,
    Rect screen,
    String title,
    double time,
    double k, {
    double? centerY,
    double scale = 1,
  }) {
    if (k <= 0.01) return;
    // Kandil biraz kısılır: sahne geride kalır, levha öne çıkar.
    if (centerY == null) {
      canvas.drawRect(
        screen,
        Paint()..color = const Color(0xFF1A0B05).withValues(alpha: 0.42 * k),
      );
    }
    final parts = title.split(' · ');
    final top = parts.length > 1 ? parts.first : '';
    final main = parts.length > 1 ? parts.sublist(1).join(' · ') : parts.first;
    final h = screen.height * scale;
    TextPainter cut(String t, double size, double spacing) => TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          color: const Color(0xFF000000),
          fontFamily: debugFontFamily,
          fontSize: size,
          fontWeight: FontWeight.w900,
          letterSpacing: spacing,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: screen.width * 0.8);
    var mainSize = h * 0.07;
    var big = cut(main, mainSize, mainSize * 0.18);
    if (big.width > screen.width * 0.45) {
      mainSize *= screen.width * 0.45 / big.width;
      big = cut(main, mainSize, mainSize * 0.18);
    }
    final small = top.isEmpty ? null : cut(top, h * 0.036, h * 0.014);
    // Kısa adlarda bile levha dar kalmaz (altındaki tasvirle karışmasın).
    final aside = _asideScenes.contains(_lastScene);
    final pw = math.max(
      math.max(big.width, small?.width ?? 0) + h * 0.16,
      screen.width * (aside ? 0.26 : 0.42),
    );
    final ph = big.height + (small?.height ?? 0) + h * 0.1;
    // Yaklaşırken iri ve bulanık, perdeye dayanınca keskin; çubukta sallanır.
    final grow = 1 + (1 - k) * 0.18;
    final blur = (1 - k) * 9;
    final sway = math.sin(time * 1.1) * 0.012;
    // Perdenin üst kısmında: sahne altta görünür kalır.
    final c = Offset(
      aside ? screen.left + screen.width * 0.8 : screen.center.dx,
      (centerY ?? screen.top + h * (aside ? 0.12 : 0.025) + ph / 2) +
          math.sin(time * 1.7) * 1.5,
    );
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(sway);
    canvas.scale(grow);
    final plate = Rect.fromCenter(center: Offset.zero, width: pw, height: ph);
    final layerPaint = Paint()
      ..color = Color.fromRGBO(0, 0, 0, (0.15 + 0.85 * k).clamp(0.0, 1.0));
    if (blur > 0.3) {
      layerPaint.imageFilter = ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur);
    }
    canvas.saveLayer(plate.inflate(h * 0.3), layerPaint);
    // Levha: üstü kemerli, kenarları dalgalı deri.
    final arch = h * 0.06;
    final body = Path()
      ..moveTo(plate.left, plate.bottom)
      ..lineTo(plate.left, plate.top + arch)
      ..quadraticBezierTo(
        plate.left,
        plate.top,
        plate.left + arch * 2,
        plate.top,
      )
      ..lineTo(-arch * 1.6, plate.top)
      ..quadraticBezierTo(0, plate.top - arch * 1.4, arch * 1.6, plate.top)
      ..lineTo(plate.right - arch * 2, plate.top)
      ..quadraticBezierTo(plate.right, plate.top, plate.right, plate.top + arch)
      ..lineTo(plate.right, plate.bottom)
      ..close();
    // Kenarından sızan kandil ışığı: levha arkadaki tasvirden ayrılır.
    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0xFFF2B46A).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2, h * 0.008)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.006),
    );
    canvas.drawPath(body, Paint()..color = _ink);
    final hole = Paint()..blendMode = BlendMode.clear;
    // Zımba delikleri: kenarı izleyen nokta dizisi ve tepedeki yıldız.
    final inset = plate.deflate(h * 0.025);
    final step = h * 0.03;
    for (var x = inset.left; x <= inset.right; x += step) {
      canvas.drawCircle(Offset(x, inset.top), h * 0.007, hole);
      canvas.drawCircle(Offset(x, inset.bottom), h * 0.007, hole);
    }
    for (var y = inset.top + step; y < inset.bottom; y += step) {
      canvas.drawCircle(Offset(inset.left, y), h * 0.007, hole);
      canvas.drawCircle(Offset(inset.right, y), h * 0.007, hole);
    }
    final star = Path();
    for (var i = 0; i < 16; i++) {
      final r = i.isEven ? arch * 0.55 : arch * 0.22;
      final a = i * math.pi / 8;
      final p = Offset(
        math.cos(a) * r,
        plate.top - arch * 0.35 + math.sin(a) * r,
      );
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(star..close(), hole);
    // İnce oyma çizgi: harflerin çevresinde ışıklı çerçeve.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        plate.deflate(h * 0.045),
        Radius.circular(h * 0.02),
      ),
      Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, h * 0.004),
    );
    // Oyuk harfler: içlerinden kandilin sıcak ışığı geçer (arkadaki sahne
    // harflerin içine girmez, ad okunur).
    final light = Paint()
      ..shader = ui.Gradient.radial(Offset.zero, plate.width * 0.6, const [
        Color(0xFFFFE2B0),
        Color(0xFFF2B46A),
      ]);
    var y = plate.top + h * 0.05;
    void glow(TextPainter tp, double at) {
      canvas.saveLayer(null, Paint());
      tp.paint(canvas, Offset(-tp.width / 2, at));
      canvas.drawRect(
        plate,
        Paint()
          ..shader = light.shader
          ..blendMode = BlendMode.srcIn,
      );
      canvas.restore();
    }

    if (small != null) {
      glow(small, y);
      y += small.height + h * 0.005;
    }
    glow(big, y);
    canvas.restore();
    canvas.restore();
  }

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
    double alpha, {
    int? bridge,
    int bridgeLines = 3,
  }) {
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
    final lamp = (bridge != null ? 1.0 : _lampFor(scene, progress)) * flicker;

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
    _lastScene = bridge == null ? scene : null;
    if (bridge != null) {
      // Köprü: Sâye'nin bölümde yürüdüğü yol (Hikâye tiyatrosu).
      _bridgeStage(canvas, bridge, time, progress, bridgeLines);
    } else {
      switch (scene) {
        case PerdeScene.prologue:
          _prologue(canvas, time, progress);
        case PerdeScene.galata:
          _galata(canvas, time, progress);
        case PerdeScene.skyroad:
          _skyroad(canvas, time, progress);
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
        case PerdeScene.caravan || PerdeScene.dragons:
          _caravanScene(canvas, time, progress);
        case PerdeScene.avalanche:
          _caravanScene(canvas, time, progress, avalanche: true);
        case PerdeScene.fairies:
          _fairiesScene(canvas, time, progress);
        case PerdeScene.underground:
          _fairiesScene(canvas, time, progress, underground: true);
        case PerdeScene.otuken:
          _otukenScene(canvas, time, progress);
        case PerdeScene.akAna:
          _akAnaScene(canvas, time, progress);
        case PerdeScene.erlik:
          _akAnaScene(canvas, time, progress + 3);
        case PerdeScene.ergenekon:
          _ergenekonScene(canvas, time, progress);
        case PerdeScene.gok:
          _gokScene(canvas, time, progress);
        case PerdeScene.sema:
          _semaScene(canvas, time, progress);
        case PerdeScene.epilogue:
          _endingScene(canvas, time, progress);
      }
      // Bölümün efsane kahramanları kendi satırlarında perdeyi doldurur;
      // Kandilcilerden, ustadan söz eden satırda ana iplik (kovalama).
      _heroOverlay(canvas, scene, time, progress);
      _heroExtra(canvas, scene, time, progress);
    }
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
    // Kandili söndürdüler: perde kararır (gölgenin düşüşü seçilecek kadar
    // ışık kalır), sonra fidanla biraz aydınlanır.
    if (u < 2.7) return 1;
    if (u < 3.0) return 1 - 0.6 * _ease((u - 2.7) / 0.3);
    if (u < 4.0) return 0.4;
    return 0.4 + 0.3 * _ease((u - 4.0) / 0.6);
  }

  /// Menünün başlığı: oyunun adı (gölge harfler, kenarlarında kandilin
  /// sızan ışığı), süs çizgisi ve alt yazı; 780×484'lük sanal perdede.
  /// Giriş de aynısını çizer (geçişte fark olmasın).
  static void _menuHeading(
    Canvas canvas,
    double flicker,
    String title,
    String tagline,
  ) {
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
      // İki kanat: yakındaki ve biraz gecikmeli uzaktaki.
      for (final (lag, dx) in [(0.7, -5.0), (0.0, 0.0)]) {
        final f = math.sin(time * 9 - lag) * 14;
        c.drawPath(
          Path()
            ..moveTo(-6 + dx, -3)
            ..quadraticBezierTo(-12 + dx, -18 - f, 0 + dx, -30 - f)
            ..quadraticBezierTo(8 + dx, -16 - f, 6 + dx, -3)
            ..close(),
          ink,
        );
      }
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
    // Başlıktan sonra şehir söner; perde sarnıcın içine iner.
    final cityA = 1 - _span(u, 5.55, 6.05);
    if (cityA <= 0) {
      _cistern(canvas, time, u);
      return;
    }
    // 0-1: duman göğü örter; ardında güneş mi ay mı belli olmayan soluk bir
    // teker (gece ile gündüz karışmış).
    final smokeA = cityA * (1 - _span(u, 2.6, 3.2));
    if (smokeA > 0) {
      canvas.drawCircle(const Offset(560, 96), 24, _holePaint(0.4 * smokeA));
      for (var i = 0; i < 4; i++) {
        final y = 36.0 + i * 36;
        final x0 = (i * 260.0 + time * (5 + i * 2)) % 1040 - 130;
        final bank = Path();
        for (var k = 0; k < 7; k++) {
          final px = x0 - 150 + k * 50.0;
          bank.addOval(
            Rect.fromCenter(
              center: Offset(px, y + math.sin(k * 1.7 + i) * 6),
              width: 70 + (k % 3) * 16,
              height: 30 + (k % 2) * 12,
            ),
          );
        }
        canvas.drawPath(bank, _inkPaint(0.2 * smokeA));
      }
    }
    _city(canvas, cityA);
    // Şehir yanıyor; kandil sönerken alevler de çekilir.
    _flames(canvas, time, cityA * (1 - _span(u, 2.5, 2.7)));

    const g = _ground;
    // 1: Kandilciler soldan gelir, ev ev dolaşır: önünden geçtikleri her
    // pencerenin ışığı fenerlerine akar.
    final ka = cityA * _span(u, 0.95, 1.12);
    final walkA = _span(u, 1.05, 1.95);
    final walkB = _span(u, 1.1, 1.95);
    // 2: B kandili alıp önden çıkar; A ustayı zincirle sürükler.
    final turnB = u > 2.45;
    final turnA = u > 2.5;
    final ax =
        45 +
        walkA * 125 -
        50 * _span(u, 2.55, 2.88) -
        270 * _span(u, 2.88, 3.15);
    final bx = 160 + walkB * 140 - 450 * _span(u, 2.45, 2.85);
    final lanternA = Offset(ax + 88, g - 188);
    final lanternB = Offset(bx + (turnB ? -88 : 88), g - 188);
    final houseA = cityA;
    if (houseA > 0) {
      final ink = _inkPaint(houseA);
      for (final hx in [205.0, 310.0]) {
        canvas.drawRect(Rect.fromLTWH(hx - 30, 306, 60, 46), ink);
        canvas.drawPath(
          Path()
            ..moveTo(hx - 38, 308)
            ..lineTo(hx, 282)
            ..lineTo(hx + 38, 308)
            ..close(),
          ink,
        );
        // Fener geçince pencerenin ışığı söner, kıvılcımı fenere uçar.
        final lantern = hx < 250 ? lanternA : lanternB;
        final gone = u >= 1.95
            ? 1.0
            : (ka <= 0 ? 0.0 : _ease((lantern.dx - hx + 10) / 34));
        final win = Rect.fromLTWH(hx - 8, 318, 16, 16);
        canvas.drawRect(win, _holePaint(houseA * (1 - gone)));
        if (gone > 0.02 && gone < 0.98) {
          canvas.drawCircle(
            Offset.lerp(win.center, lantern, gone)!,
            4,
            _holePaint(houseA),
          );
        }
      }
      // Kubbenin pencereleri de kararır.
      final dome = _inkPaint(cityA * _span(u, 1.6, 1.95));
      for (final x in [370.0, 390.0, 410.0]) {
        canvas.drawRect(Rect.fromLTWH(x - 3.5, 321, 7, 12), dome);
      }
      canvas.drawCircle(const Offset(86, 318), 3.5, _inkPaint(ka));
      canvas.drawCircle(
        const Offset(725, 322),
        3.5,
        _inkPaint(cityA * _span(u, 2.6, 3)),
      );
    }

    // 2: ustanın perdesi (iki direk, ışıklı bez, altında kandil).
    final boothA = cityA * _span(u, 1.85, 2.1);
    final lampOn = 1 - _span(u, 2.2, 2.42);
    // 3: kandilin son ışığı perdede bir an daha titrer.
    final lastLight =
        0.4 *
        _span(u, 2.5, 2.9) *
        (1 - _span(u, 3.3, 3.75)) *
        (0.8 + 0.2 * math.sin(time * 9));
    const screen = Rect.fromLTRB(495, 192, 581, 262);
    if (boothA > 0) {
      final lit = math.max(lampOn, lastLight);
      canvas.drawCircle(
        screen.center,
        90,
        Paint()
          ..shader = ui.Gradient.radial(screen.center, 90, [
            const Color(0xFFFFE6B0).withValues(alpha: 0.5 * lit * boothA),
            const Color(0x00FFE6B0),
          ]),
      );
      canvas.drawRect(
        screen,
        Paint()
          ..color = const Color(0xFFFFE8BC)
              .withValues(alpha: boothA * (0.12 + 0.85 * lit)),
      );
      final wood = _inkPaint(boothA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      canvas.drawRect(screen, wood);
      canvas.drawLine(const Offset(491, 186), const Offset(491, g), wood);
      canvas.drawLine(const Offset(585, 186), const Offset(585, g), wood);
      wood.strokeWidth = 2;
      // Kandil: perdenin altında bir rafta; alevi ışık deliği.
      canvas.drawLine(const Offset(512, 284), const Offset(566, 284), wood);
      canvas.drawPath(
        Path()
          ..moveTo(526, 276)
          ..quadraticBezierTo(538, 288, 552, 276)
          ..lineTo(548, 272)
          ..lineTo(530, 272)
          ..close(),
        _inkPaint(boothA),
      );
      if (lampOn > 0) {
        canvas.drawPath(
          Path()
            ..moveTo(539, 272)
            ..quadraticBezierTo(533, 266, 539 + math.sin(time * 9) * 1.5, 258)
            ..quadraticBezierTo(545, 266, 539, 272)
            ..close(),
          _holePaint(boothA * lampOn),
        );
      }
      // Kandilin ışığı Kandilcinin fenerine akar.
      final take = _span(u, 2.2, 2.45);
      if (take > 0 && take < 1) {
        canvas.drawCircle(
          Offset.lerp(const Offset(539, 264), lanternB, take)!,
          5,
          _holePaint(boothA),
        );
      }
    }

    // Usta: önce Kandilcilere döner; sürüklenirken başını çevirip perdesine
    // bakar.
    final ma = cityA * _span(u, 1.9, 2.1) * (1 - _span(u, 3.88, 4.0));
    final dragged = u > 2.55;
    final mx = 440 - 110 * _span(u, 2.55, 2.88) - 230 * _span(u, 2.88, 3.85);
    if (ma > 0) {
      canvas.save();
      canvas.translate(mx, g);
      canvas.rotate(dragged ? 0.1 : 0);
      canvas.translate(-mx, -g);
      _puppet(canvas, Offset(mx, g), time, 2.9, ma, _master, flip: !dragged);
      canvas.restore();
    }
    // Zincir: ustanın arkada bağlı ellerinden Kandilcinin eline (o perdeden
    // çıkınca perdenin dışına).
    final chainA = ma * _span(u, 2.5, 2.6);
    if (chainA > 0) {
      final from = Offset(mx - 30, g - 60);
      final to = u < 3.1 ? Offset(ax + 26, g - 88) : const Offset(-20, g - 96);
      final mid = Offset.lerp(from, to, 0.5)! + const Offset(0, 14);
      final links = _inkPaint(chainA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (var i = 0; i <= 14; i++) {
        final t = i / 14;
        final p = Offset.lerp(
          Offset.lerp(from, mid, t)!,
          Offset.lerp(mid, to, t)!,
          t,
        )!;
        canvas.drawOval(Rect.fromCenter(center: p, width: 8, height: 5), links);
      }
    }
    // Kandilciler (kandili alan B önden çıkar).
    final aA = ka * (1 - _span(u, 3.05, 3.15));
    _puppet(canvas, Offset(ax, g), time, 0.3, aA, (ink, hole) {
      _lamplighter(ink, hole);
    }, flip: turnA);
    final aB = ka * (1 - _span(u, 2.75, 2.85));
    if (aB > 0) {
      // B'nin feneri topladığı ışıkla parlar.
      final glow = 0.25 + 0.5 * _span(u, 2.3, 2.45);
      canvas.drawCircle(
        lanternB,
        34,
        Paint()
          ..shader = ui.Gradient.radial(lanternB, 34, [
            const Color(0xFFFFE0A0).withValues(alpha: glow * aB),
            const Color(0x00FFE0A0),
          ]),
      );
    }
    _puppet(canvas, Offset(bx, g), time, 1.7, aB, (ink, hole) {
      _lamplighter(ink, hole);
    }, flip: turnB);

    // 3: perde karardı; kandilin son ışığında perdedeki küçük gölge
    // perdeden ayrılır (büyüyerek bize doğru), yere düşer ve yatar.
    if (boothA > 0) {
      final peel = _span(u, 3.05, 3.3);
      final fall = _span(u, 3.3, 3.62);
      final s = 0.42 + 0.68 * peel;
      final feet = fall > 0
          ? Offset.lerp(
              const Offset(552, 250),
              const Offset(548, 339),
              fall * fall,
            )!
          : Offset.lerp(const Offset(556, 258), const Offset(552, 250), peel)!;
      // Kandilin son ışığı düştüğü yerde bir süre daha onu seçik kılar.
      final glowA = boothA * _span(u, 3.3, 3.5) * (1 - _span(u, 4.5, 5.0));
      if (glowA > 0) {
        const at = Offset(510, 336);
        canvas.drawCircle(
          at,
          70,
          Paint()
            ..shader = ui.Gradient.radial(at, 70, [
              const Color(0xFFFFE6B0).withValues(alpha: 0.45 * glowA),
              const Color(0x00FFE6B0),
            ]),
        );
      }
      canvas.save();
      canvas.translate(feet.dx, feet.dy);
      canvas.rotate(-math.pi / 2 * fall);
      _puppet(
        canvas,
        Offset.zero,
        time,
        4.1,
        boothA,
        (ink, hole) => _saye(ink, hole, time, jar: _span(u, 4.3, 4.8)),
        scale: s,
        rod: false,
      );
      canvas.restore();
    }

    // 4: düştüğü yerde küller yarılır, bir kayın fidanı filizlenir; dalında
    // tek bir ak çaput (Umay'ın işareti).
    final ash = cityA * _span(u, 3.55, 3.7);
    if (ash > 0) {
      final split = _span(u, 4.0, 4.3) * 9;
      for (final side in [-1.0, 1.0]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(566 + side * (8 + split), g + 2),
            width: 20,
            height: 14,
          ),
          _inkPaint(ash),
        );
      }
    }
    final grow = _span(u, 4.05, 4.75);
    if (grow > 0) {
      _birchShoot(canvas, time, const Offset(566, g), grow, cityA);
    }
  }

  /// Kayın fidanı: incecik bir gövde (ak kabuğu ışık çentikleriyle), birkaç
  /// dal ve yaprak; [grow] 0→1 boy atar. Alt dalda rüzgârda dalgalanan tek
  /// bir ak çaput (perdede ışık sızan bir şerit).
  static void _birchShoot(
    Canvas canvas,
    double time,
    Offset base,
    double grow,
    double a,
  ) {
    final h = 165 * grow;
    final sway = math.sin(time * 1.3) * 3 * grow;
    Offset at(double t) =>
        base + Offset(sway * t * t + math.sin(t * 3) * 3, -h * t);
    final ink = _inkPaint(a);
    final trunk = Path()..moveTo(base.dx - 3, base.dy);
    for (var i = 1; i <= 8; i++) {
      final p = at(i / 8);
      trunk.lineTo(p.dx - 3 * (1 - i / 8) - 0.6, p.dy);
    }
    for (var i = 8; i >= 0; i--) {
      final p = at(i / 8);
      trunk.lineTo(p.dx + 3 * (1 - i / 8) + 0.6, p.dy);
    }
    canvas.drawPath(trunk..close(), ink);
    // Kayının ak kabuğu: gövdede ince ışık çentikleri.
    final mark = _holePaint(0.55 * a)..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final p = at(i / 7);
      canvas.drawLine(
        p + const Offset(-1.5, 0),
        p + const Offset(1.5, -1),
        mark,
      );
    }
    // Dallar ve yapraklar: boy attıkça birer birer çıkar.
    const branches = [(0.42, -1.0), (0.58, 1.0), (0.74, -1.0), (0.86, 1.0)];
    Offset? ragKnot;
    for (final (t, side) in branches) {
      final out = _ease((grow - t) / 0.25);
      if (out <= 0) continue;
      final p0 = at(t);
      final len = 26 * out * (1.1 - t * 0.5);
      final p1 = p0 + Offset(side * len, -len * 0.55);
      canvas.drawLine(
        p0,
        p1,
        _inkPaint(a)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
      for (var k = 0; k < 3; k++) {
        final q = Offset.lerp(p0, p1, 0.45 + k * 0.27)!;
        final leaf = 3.2 * out;
        canvas.save();
        canvas.translate(q.dx, q.dy);
        canvas.rotate(side * 0.6 + math.sin(time * 2 + k + t * 9) * 0.25);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, k.isEven ? -leaf : leaf),
            width: leaf * 1.4,
            height: leaf * 2.2,
          ),
          ink,
        );
        canvas.restore();
      }
      ragKnot ??= Offset.lerp(p0, p1, 0.75);
    }
    final top = at(1);
    canvas.drawOval(
      Rect.fromCenter(center: top + const Offset(0, -3), width: 5, height: 9),
      ink,
    );
    // Çaput: alt daldan sarkan ak şerit.
    final ra = a * _ease((grow - 0.6) / 0.3);
    if (ra <= 0 || ragKnot == null) return;
    final cloth = Path()..moveTo(ragKnot.dx, ragKnot.dy);
    for (var i = 1; i <= 6; i++) {
      final k = i / 6;
      cloth.lineTo(
        ragKnot.dx - k * 10 + math.sin(time * 2.4 - k * 3) * 4 * k,
        ragKnot.dy + k * 24,
      );
    }
    canvas.drawPath(
      cloth,
      _holePaint(ra)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(ragKnot, 2.5, _holePaint(ra));
  }

  /// Galata perdesi: her satırın kendi tasviri (bkz. satırlar). Hezarfen'in
  /// gölgesi kulenin duvarından Sâye'yle konuşur; arada kendi hikâyesi.
  static void _galata(Canvas canvas, double time, double u) {
    _c = canvas;
    const g = _ground;
    final c = canvas;

    // 0: Sâye merdivenden çıkar; İstanbul hâlâ tüter, dumanın içinden
    // Galata yükselir, pencerelerinde Kandilcilerin fenerleri dolaşır.
    final a0 = _heroA(u, 0);
    if (a0 > 0) {
      _smokePlumes(c, time, a0);
      _city(c, a0);
      _galataTower(c, const Offset(560, g), 310, time, a0, lanterns: true);
      // Yerdeki ağız: sarnıçtan çıkan merdiven.
      c.drawPath(
        Path()
          ..moveTo(224, g)
          ..lineTo(232, g - 10)
          ..lineTo(292, g - 10)
          ..lineTo(300, g)
          ..close(),
        _inkPaint(a0),
      );
      final up = _span(u, 0.08, 0.6);
      c.save();
      c.clipRect(const Rect.fromLTWH(0, 0, 780, g - 8));
      _tasvirSaye(c, Offset(262, g - 8 + 100 * (1 - up)), 1.3, time, a0);
      c.restore();
    }

    // 1: kulenin içi; duvarda bir gölge kıpırdar: sırtında kartal kanatları
    // olan bir adam. "Hoş geldin, kardeş gölge."
    final a1 = _heroA(u, 1);
    if (a1 > 0) {
      _towerWall(c, time, a1, 0);
      _hezarfenShadow(
        c,
        const Offset(500, g),
        290,
        time,
        a1 * _span(u, 1.05, 1.4),
        spread: 0.15 + 0.3 * _span(u, 1.3, 1.8),
      );
      _tasvirSaye(
        c,
        Offset(170 + 40 * _span(u, 1.05, 1.4), g + 10),
        1.8,
        time,
        a1,
      );
    }

    // 2: bayırda: düşer, kalkar; dokuzuncu kez rüzgâr onu tutar.
    final a2 = _heroA(u, 2);
    if (a2 > 0) _hezarfenSlope(c, time, u, a2);

    // 3: kulenin tepesinden Boğaz'ın üstünden Üsküdar'a süzülür; bütün
    // İstanbul seyreder.
    final a3 = _heroA(u, 3);
    if (a3 > 0) _hezarfenFlight(c, time, u, a3);

    // 4: padişah bir kese altın verir; sonra korkar, sürgün gemisi.
    final a4 = _heroA(u, 4);
    if (a4 > 0) {
      final ink = _inkPaint(a4);
      c.drawRect(const Rect.fromLTWH(0, g, 470, 60), ink);
      c.drawRect(
        const Rect.fromLTWH(470, g - 18, 310, 80),
        _inkPaint(a4 * 0.6),
      );
      for (var i = 0; i < 8; i++) {
        final x = 480 + ((i * 47.0 + time * 10) % 300);
        c.drawLine(
          Offset(x, g - 10 + (i % 3) * 8),
          Offset(x + 18, g - 10 + (i % 3) * 8),
          _holePaint(0.3 * a4)..strokeWidth = 1.4,
        );
      }
      final scared = _span(u, 4.4, 4.55);
      // Padişah önce keseyi uzatır, sonra korkup sırtını döner.
      _sultan(c, const Offset(200, g + 10), 240, a4, flip: scared > 0.5);
      final stay = 1 - _span(u, 4.45, 4.6);
      _person(
        c,
        const Offset(350, g + 10),
        180,
        a4 * stay,
        _hezarfenFly,
        flip: true,
        rot: 0.15,
        arm: -1.1,
      );
      // Sürgün: gemide küçücük Hezarfen, gemi uzaklaşır.
      final sail = _span(u, 4.5, 4.97);
      final ship = Offset(560 + 110 * sail, g - 22);
      final sa = a4 * _span(u, 4.45, 4.6);
      if (sa > 0) {
        _person(
          c,
          ship + const Offset(-24, 0),
          70,
          sa,
          _hezarfenFly,
          flip: true,
        );
        _ship(c, ship, 1.5, sa);
      }
    }

    // 5: duvardaki gölge Sâye'ye eğilir: "Uçanlar sürgün edilir, Sâye. Yine
    // de uç." Kanatlar kulenin tepesinde saklı: merdivenin ucunda bir ışık.
    final a5 = _heroA(u, 5);
    if (a5 > 0) {
      _towerWall(c, time, a5, 1);
      _hezarfenShadow(
        c,
        const Offset(500, g),
        290,
        time,
        a5,
        spread: 0.35,
        lean: -0.32 * _span(u, 5.3, 5.75),
      );
      _tasvirSaye(c, const Offset(230, g + 10), 1.8, time, a5);
    }
  }

  /// Galata Kulesi: silindir gövde, taş konsollu seyir yeri, külah. Ayağı
  /// [base]'de, boyu [h]. [lanterns]: pencerelerde dolaşan fener ışıkları.
  static void _galataTower(
    Canvas c,
    Offset base,
    double h,
    double time,
    double a, {
    bool lanterns = false,
  }) {
    final ink = _inkPaint(a);
    final w = h * 0.13;
    final bodyTop = base.dy - h * 0.7;
    c.drawPath(
      Path()
        ..moveTo(base.dx - w, base.dy)
        ..lineTo(base.dx - w * 0.9, bodyTop)
        ..lineTo(base.dx + w * 0.9, bodyTop)
        ..lineTo(base.dx + w, base.dy)
        ..close(),
      ink,
    );
    // Seyir yeri: taşan konsollar, kemerli açıklıklar.
    final gal = Rect.fromLTRB(
      base.dx - w * 1.12,
      bodyTop - h * 0.08,
      base.dx + w * 1.12,
      bodyTop,
    );
    c.drawRect(gal, ink);
    for (var i = 0; i < 7; i++) {
      c.drawRect(
        Rect.fromLTWH(gal.left + i * gal.width / 6.5, gal.bottom, 4, 7),
        ink,
      );
    }
    for (var i = 0; i < 5; i++) {
      final x = gal.left + 6 + i * (gal.width - 12) / 4.5;
      c.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, gal.top + h * 0.022, 5, h * 0.04),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        _holePaint(0.7 * a),
      );
    }
    // Külah.
    c.drawPath(
      Path()
        ..moveTo(gal.left + 2, gal.top)
        ..lineTo(base.dx, base.dy - h)
        ..lineTo(gal.right - 2, gal.top)
        ..close(),
      ink,
    );
    // Pencereler: yalnız fenerin dolaştığı pencere ışır.
    for (var row = 0; row < 4; row++) {
      final y = base.dy - h * (0.16 + row * 0.15);
      final at = lanterns ? ((time * 0.35 + row * 0.41) % 1) * 4 - 0.5 : -9.0;
      for (var col = 0; col < 3; col++) {
        final glow = math.max(0.0, 1 - (at - col).abs() * 1.6);
        final r = Rect.fromCenter(
          center: Offset(base.dx + (col - 1) * w * 0.55, y),
          width: 6,
          height: 14,
        );
        if (glow > 0.05) {
          c.drawCircle(
            r.center,
            16,
            Paint()
              ..shader = ui.Gradient.radial(r.center, 16, [
                const Color(0xFFFFE0A0).withValues(alpha: 0.6 * glow * a),
                const Color(0x00FFE0A0),
              ]),
          );
        }
        c.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(3)),
          _holePaint(a * (0.12 + 0.88 * glow)),
        );
      }
    }
  }

  /// Şehirden yükselen duman sütunları.
  static void _smokePlumes(Canvas c, double time, double a) {
    for (var i = 0; i < 14; i++) {
      final x0 = 40 + (i * 131.0) % 700;
      final k = ((time * 0.06 + i * 0.37) % 1);
      final p = Offset(x0 + k * 40 + math.sin(time + i) * 8, 340 - k * 300);
      c.drawCircle(p, 14 + k * 30, _inkPaint(0.18 * a * (1 - k)));
    }
  }

  /// Kulenin içi: ışıklı taş duvar, kemerli tavan, köşede yukarı çıkan
  /// merdiven. [top] > 0: merdivenin ucunda saklı kanatların ışığı.
  static void _towerWall(Canvas c, double time, double a, double top) {
    final ink = _inkPaint(a);
    final joint = _inkPaint(0.12 * a)..strokeWidth = 1.2;
    for (var row = 0; row < 9; row++) {
      final y = 40.0 + row * 34;
      c.drawLine(Offset(0, y), Offset(780, y), joint);
      for (var x = (row.isEven ? 0.0 : 40.0); x < 780; x += 80) {
        c.drawLine(Offset(x, y), Offset(x, y + 34), joint);
      }
    }
    c.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(780, 0)
        ..lineTo(780, 60)
        ..quadraticBezierTo(390, -10, 0, 60)
        ..close(),
      ink,
    );
    c.drawRect(const Rect.fromLTWH(0, _ground, 780, 60), ink);
    // Dar mazgal: dışarıda dumanlı gök.
    c.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(92, 110, 22, 70),
        topLeft: const Radius.circular(11),
        topRight: const Radius.circular(11),
      ),
      _holePaint(0.7 * a),
    );
    // Döne döne yukarı çıkan merdiven.
    final steps = Path()..moveTo(640, _ground);
    for (var i = 0; i < 10; i++) {
      steps
        ..lineTo(640 + i * 13.0, _ground - i * 27.0 - 27)
        ..lineTo(653 + i * 13.0, _ground - i * 27.0 - 27);
    }
    steps
      ..lineTo(780, _ground - 270)
      ..lineTo(780, _ground)
      ..close();
    c.drawPath(steps, ink);
    if (top > 0) {
      final p = const Offset(738, 78);
      c.drawCircle(
        p,
        40,
        Paint()
          ..shader = ui.Gradient.radial(p, 40, [
            const Color(0xFFFFE6B0).withValues(alpha: 0.6 * a * top),
            const Color(0x00FFE6B0),
          ]),
      );
      // Kapağın aralığından görünen bir kanat ucu.
      c.save();
      c.translate(p.dx, p.dy + 6);
      c.scale(0.5, 0.5);
      c.rotate(-0.3 + math.sin(time * 1.5) * 0.05);
      c.drawPath(MythFigures.wingSilhouette, _inkPaint(a * top));
      c.restore();
    }
  }

  /// Hezarfen'in duvardaki gölgesi: düz, deliksiz, yarı saydam; sırtında
  /// kartal kanatları. [lean]: ayaklarından öne (sola) eğilir.
  static void _hezarfenShadow(
    Canvas c,
    Offset feet,
    double h,
    double time,
    double a, {
    double spread = 0.3,
    double lean = 0,
  }) {
    if (a <= 0) return;
    final s = h / 112;
    c.saveLayer(
      const Rect.fromLTWH(0, 0, 780, 400),
      Paint()..color = Color.fromRGBO(0, 0, 0, 0.55 * a),
    );
    c.save();
    c.translate(feet.dx, feet.dy);
    c.rotate(lean);
    c.translate(-feet.dx, -feet.dy);
    final sh = feet + Offset(0, -h * 0.72);
    _wings(c, sh, h * 0.5, spread + math.sin(time * 1.2) * 0.04, 1);
    c.save();
    c.translate(feet.dx, feet.dy);
    c.scale(-s, s);
    c.drawPath(MythFigures.manSilhouette, _inkPaint(1));
    c.restore();
    c.restore();
    c.restore();
  }

  /// Bayırda deneme: koşar, sıçrar, yüzüstü düşer, kalkar (sekiz kez);
  /// dokuzuncuda rüzgâr onu tutar. Sağ altta dokuz çentik sayılır.
  static void _hezarfenSlope(Canvas c, double time, double u, double a) {
    double slopeY(double x) => 190 + x * 0.19 + (x / 780) * (x / 780) * 20;
    c.drawPath(
      Path()
        ..moveTo(0, slopeY(0))
        ..lineTo(260, slopeY(260))
        ..lineTo(520, slopeY(520))
        ..lineTo(780, slopeY(780))
        ..lineTo(780, 400)
        ..lineTo(0, 400)
        ..close(),
      _inkPaint(a),
    );
    final p = ((u - 2.085) / (2.72 - 2.085)).clamp(0.0, 1.0) * 8;
    final fly = _span(u, 2.72, 2.98);
    final i = math.min(p.floor(), 7);
    final f = p >= 8 ? 1.0 : p - p.floor();
    const h = 140.0;
    double x;
    double y;
    var rot = 0.0;
    var flap = 0.15;
    if (fly > 0) {
      x = 520 + fly * 150;
      y = slopeY(520) - fly * 150;
      rot = -0.25 * fly;
      flap = 0.45 + math.sin(time * 5) * 0.15;
      // Rüzgâr çizgileri: onu kaldıran esinti.
      for (var k = 0; k < 5; k++) {
        final wx = (k * 97.0 + time * 160) % 700 + 20;
        final wy = 90.0 + k * 36;
        c.drawLine(
          Offset(wx, wy),
          Offset(wx + 50, wy - 8),
          _holePaint(0.5 * a * fly)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
    } else {
      final x0 = 80.0 + i * 55;
      final run = _ease(f / 0.35);
      x = x0 + run * 40 + _ease((f - 0.35) / 0.15) * 25;
      y = slopeY(x);
      final hopUp = f > 0.35 && f < 0.5
          ? math.sin((f - 0.35) / 0.15 * math.pi) * 30
          : 0.0;
      y -= hopUp;
      rot = 1.75 * _ease((f - 0.38) / 0.12) * (1 - _ease((f - 0.75) / 0.25));
      flap = 0.15 + 0.2 * math.sin(time * 9) * (f < 0.5 ? 1 : 0);
    }
    c.save();
    c.translate(x, y);
    c.rotate(rot);
    _wings(c, const Offset(2, -h * 0.8), 80, flap, a);
    _person(c, Offset.zero, h, a, _hezarfenFly, arm: -2.5);
    c.restore();
    // Dokuz deneme: dokuz çentik.
    final tries = fly > 0 ? 9 : i + 1;
    for (var k = 0; k < 9; k++) {
      c.drawCircle(
        Offset(560 + k * 22.0, 372),
        k < tries ? 5 : 3,
        _holePaint(a * (k < tries ? 0.9 : 0.3)),
      );
    }
  }

  /// Kulenin tepesinden Boğaz'ın üstünden Üsküdar'a süzülüş; Galata
  /// yakasında halk başını kaldırıp onu gösterir.
  static void _hezarfenFlight(Canvas c, double time, double u, double a) {
    const g = _ground;
    final ink = _inkPaint(a);
    // Galata yakası, Boğaz, Üsküdar.
    c.drawPath(
      Path()
        ..moveTo(0, g - 20)
        ..quadraticBezierTo(200, g - 26, 330, g - 6)
        ..lineTo(330, 400)
        ..lineTo(0, 400)
        ..close(),
      ink,
    );
    c.drawRect(Rect.fromLTWH(330, g - 4, 290, 60), _inkPaint(a * 0.55));
    for (var i = 0; i < 9; i++) {
      final x = 340 + ((i * 53.0 + time * 14) % 270);
      c.drawLine(
        Offset(x, g + 4 + (i % 3) * 9),
        Offset(x + 20, g + 4 + (i % 3) * 9),
        _holePaint(0.4 * a)..strokeWidth = 1.4,
      );
    }
    c.drawPath(
      Path()
        ..moveTo(620, g)
        ..quadraticBezierTo(680, g - 30, 780, g - 26)
        ..lineTo(780, 400)
        ..lineTo(620, 400)
        ..close(),
      ink,
    );
    // Üsküdar'da bir cami: kubbe ve iki minare.
    c.drawCircle(const Offset(715, g - 30), 22, ink);
    for (final mx in [680.0, 752.0]) {
      c.drawPath(
        Path()
          ..moveTo(mx - 4, g - 26)
          ..lineTo(mx - 4, g - 82)
          ..lineTo(mx, g - 100)
          ..lineTo(mx + 4, g - 82)
          ..lineTo(mx + 4, g - 26)
          ..close(),
        ink,
      );
    }
    _galataTower(c, const Offset(100, g - 22), 270, time, a);
    // Hezarfen: tepeden atlar, süzülür, karşıya iner.
    final k = _span(u, 3.05, 3.92);
    final hp = Offset(
      140 + k * 500,
      90 + k * 170 + math.sin(k * math.pi) * -30,
    );
    _wings(
      c,
      hp + const Offset(0, -10),
      100,
      0.55 + math.sin(time * 1.5) * 0.06,
      a,
    );
    _person(
      c,
      hp + const Offset(-50, 14),
      100,
      a,
      _hezarfenFly,
      rot: 1.45,
      arm: -1.5,
    );
    // Halk: başlar kalkar, kollar onu gösterir.
    const people = [
      (160.0, 56.0, 0),
      (186.0, 48.0, 1),
      (208.0, 34.0, 2),
      (232.0, 58.0, 0),
      (258.0, 50.0, 1),
      (282.0, 54.0, 0),
      (306.0, 36.0, 2),
    ];
    for (var i = 0; i < people.length; i++) {
      final (x, hgt, kind) = people[i];
      final gy = g - 20 + (x / 330) * (x / 330) * 14;
      final look = _Look(
        hat: kind == 1 ? _Hat.veil : (kind == 2 ? _Hat.hair : _Hat.sarik),
        garb: kind == 1 ? _Garb.dress : _Garb.kaftan,
      );
      _person(c, Offset(x, gy), hgt, a, look, flip: hp.dx < x);
      if (i.isEven) {
        final shoulder = Offset(x + (hp.dx < x ? -2 : 2), gy - hgt * 0.76);
        final to = hp - shoulder;
        c.drawLine(
          shoulder,
          shoulder + to / to.distance * hgt * 0.4,
          _inkPaint(a)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      }
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

  /// Bulut denizi: perdenin dibinde ağır ağır kayan bulutlar.
  static void _cloudSea(Canvas c, double time, double a, {double y = 400}) {
    for (final (x, dy, s) in [
      (60.0, 0.0, 1.3),
      (250.0, 4.0, 1.1),
      (450.0, -2.0, 1.4),
      (690.0, 4.0, 1.2),
    ]) {
      _cloud(c, x + math.sin(time * 0.3 + x) * 6, y + dy, s, a);
    }
  }

  /// Gökyolu perdesi: Sâye kanatlarıyla uçar; Lagari'nin fişeği, kuşların
  /// köprüsü, Hüdhüd ve Tulpar.
  static void _skyroad(Canvas canvas, double time, double u) {
    _c = canvas;
    final c = canvas;
    const g = _ground;

    // 0: Sâye uçuyor; yanan şehir ayaklarının altında küçülür, dumanı
    // aşağıda kalır.
    final a0 = _heroA(u, 0);
    if (a0 > 0) {
      final k = _span(u, 0.02, 0.98);
      c.save();
      c.translate(390, 400);
      c.scale(1 - 0.5 * k);
      c.translate(-390, -400);
      for (var i = 0; i < 8; i++) {
        final p = Offset(80 + i * 90.0, 300 - ((time * 12 + i * 31) % 90));
        c.drawCircle(p, 18, _inkPaint(0.18 * a0));
      }
      // Şehir yan yana üç kez: küçülünce de perdenin iki yanına uzansın.
      for (final dx in [-780.0, 0.0, 780.0]) {
        c.save();
        c.translate(dx, 0);
        _city(c, a0);
        _flames(c, time, a0);
        c.restore();
      }
      c.restore();
      _cloudSea(c, time, a0 * 0.6, y: 420);
      final at = Offset(230 + 230 * k, 250 - 110 * k);
      _wingedSaye(c, at, 1.4, time, a0, spread: 0.5, flap: 0.18, rot: 0.1);
    }

    // 1: bulutlardan bir gürültü: kuyruğu ateş saçan yedi kollu fişek
    // yanından vınlayıp geçer; üstünde sarıklı Lagari bağırır.
    final a1 = _heroA(u, 1);
    if (a1 > 0) {
      _cloudSea(c, time, a1);
      _cloud(c, 640, 120, 0.8, a1 * 0.6);
      final k = _span(u, 1.05, 1.92);
      final startle = _span(u, 1.3, 1.45);
      _wingedSaye(
        c,
        Offset(250 - 20 * startle, 190 - 10 * startle),
        1.3,
        time,
        a1,
        spread: 0.5 + 0.25 * startle,
        flap: 0.2,
        rot: -0.15 * startle,
      );
      final rp = Offset(130 + k * 450, 330 - k * 180);
      // Duman izi.
      for (var i = 1; i < 7; i++) {
        final back = rp - Offset(i * 26.0, -i * 13.0);
        c.drawCircle(back, 6.0 + i * 3, _inkPaint(0.16 * a1 * (1 - i / 7)));
      }
      c.save();
      c.translate(rp.dx, rp.dy);
      c.rotate(-0.46);
      _rocket(c, time, a1, fire: 1);
      // Lagari: fişeğin sırtında, kolunu kaldırmış bağırır.
      _person(c, const Offset(4, -24), 82, a1, _lagari, arm: -2.6);
      final shout = _holePaint(0.8 * a1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      for (var i = 0; i < 3; i++) {
        c.drawArc(
          Rect.fromCenter(
            center: const Offset(14, -99),
            width: 14.0 + i * 9,
            height: 12.0 + i * 8,
          ),
          -0.7,
          1.4,
          false,
          shout,
        );
      }
      c.restore();
    }

    // 2: ateş söner, adam denize düşer; şapır şupur yüzüp sarayın önüne
    // çıkar, padişaha eğilip güler. Sâye gülmekten kanatlarını unutur.
    final a2 = _heroA(u, 2);
    if (a2 > 0) {
      const sea = 318.0;
      // Saray: kubbeler, kuleler (uzak), kıyı.
      final far = _inkPaint(0.5 * a2);
      c.drawRect(const Rect.fromLTWH(560, 200, 220, 120), far);
      for (final (x, r) in [(610.0, 34.0), (700.0, 46.0)]) {
        c.drawCircle(Offset(x, 200), r, far);
      }
      for (final x in [574.0, 760.0]) {
        c.drawRect(Rect.fromLTWH(x - 5, 110, 10, 100), far);
        c.drawPath(
          Path()
            ..moveTo(x - 5, 110)
            ..lineTo(x, 90)
            ..lineTo(x + 5, 110)
            ..close(),
          far,
        );
      }
      c.drawRect(const Rect.fromLTWH(520, g, 260, 60), _inkPaint(a2));
      final wave = Path()..moveTo(0, 400);
      for (var x = 0.0; x <= 520; x += 20) {
        wave.lineTo(x, sea + math.sin(x / 30 + time * 2) * 5);
      }
      wave
        ..lineTo(520, 400)
        ..close();
      c.drawPath(wave, _inkPaint(0.75 * a2));
      _sultan(c, const Offset(690, g + 10), 210, a2, flip: true);
      // Lagari: düşer, sıçratır, yüzer, kıyıya çıkar, eğilir.
      final fall = _span(u, 2.02, 2.2);
      final swim = _span(u, 2.32, 2.62);
      final out = _span(u, 2.62, 2.72);
      final bow = _span(u, 2.72, 2.82);
      if (fall < 1) {
        // Sönmüş fişek de düşer.
        c.save();
        c.translate(180 + 30 * fall, 60 + 250 * fall * fall);
        c.rotate(-0.4 + 2 * fall);
        _person(c, Offset.zero, 110, a2, _lagari, arm: -2.8);
        c.restore();
      } else {
        final x = 210 + 300 * swim + 40 * out;
        final y = out > 0 ? g + 10 - (1 - out) * 30 : sea + 62;
        c.save();
        if (out <= 0) c.clipRect(Rect.fromLTWH(0, 0, 780, sea + 2));
        c.translate(x, y);
        c.rotate(0.55 * bow);
        _person(
          c,
          Offset.zero,
          110,
          a2,
          _lagari,
          arm: out > 0 ? -0.8 : -2.6 + math.sin(time * 9) * 0.8,
        );
        c.restore();
        if (bow > 0) {
          // Kahkaha: ağzından taşan ışık kıvrımları.
          final ha = _holePaint(0.8 * a2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6;
          for (var i = 0; i < 3; i++) {
            c.drawArc(
              Rect.fromCenter(
                center: Offset(x + 70 + i * 10, y - 95 + i * 3),
                width: 10,
                height: 10,
              ),
              -1.2 + i,
              2,
              false,
              ha,
            );
          }
        }
      }
      // Sıçrayan su.
      final splash = _span(u, 2.18, 2.22) * (1 - _span(u, 2.3, 2.42));
      if (splash > 0) {
        for (var i = 0; i < 9; i++) {
          final ang = -math.pi + i * math.pi / 8;
          final r = 20 + 34 * _span(u, 2.18, 2.34);
          c.drawCircle(
            Offset(210 + math.cos(ang) * r, sea - math.sin(ang).abs() * r),
            3,
            _holePaint(splash * a2),
          );
        }
      }
      // Sâye gülmekten sallanır.
      _wingedSaye(
        c,
        const Offset(330, 170),
        1.1,
        time,
        a2,
        spread: 0.35,
        flap: 0.1,
        rot: math.sin(time * 11) * 0.12,
      );
    }

    // 3: duman dağılınca bulutların arasında ince bir yol parlar: kuşların
    // köprüsü, dünyanın kıyısına, Kaf'a gider.
    final a3 = _heroA(u, 3);
    if (a3 > 0) {
      _qafMountain(c, const Offset(650, 330), 0.42, a3 * 0.85);
      _cloudSea(c, time, a3);
      final shine = _span(u, 3.05, 3.6);
      final road = Path()
        ..moveTo(150, 290)
        ..quadraticBezierTo(400, 120, 660, 220);
      c.drawPath(
        road,
        _holePaint(a3 * (0.25 + 0.7 * shine))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      for (final m in road.computeMetrics()) {
        for (var i = 0; i < 6; i++) {
          final t = ((time * 0.05 + i / 6) % 1);
          final p = m.getTangentForOffset(m.length * t)!.position;
          _bird(c, p + const Offset(0, -12), time, a3 * shine, i * 1.7);
        }
        for (var i = 0; i < 18; i++) {
          final p = m.getTangentForOffset(m.length * i / 18)!.position;
          c.drawCircle(p, 2.4, _holePaint(a3 * shine));
        }
      }
      // Dağılan duman.
      for (var i = 0; i < 5; i++) {
        c.drawCircle(
          Offset(300 + i * 70.0 + 60 * shine, 140 + (i % 2) * 30),
          26 + 20 * shine,
          _inkPaint(0.12 * a3 * (1 - shine)),
        );
      }
      _wingedSaye(
        c,
        const Offset(130, 250),
        1.3,
        time,
        a3,
        spread: 0.45,
        flap: 0.15,
      );
    }

    // 4: yanına tepeli, alaca kanatlı bir kuş konar: "Ben Hüdhüd'üm."
    // Gökte kırık güneş.
    final a4 = _heroA(u, 4);
    if (a4 > 0) {
      _brokenSun(c, const Offset(600, 110), 44, a4);
      _cloudSea(c, time, a4);
      _cloud(c, 330, g + 12, 1.5, a4);
      _wingedSaye(
        c,
        const Offset(270, g - 22),
        1.7,
        time,
        a4,
        spread: 0.95,
        size: 0.72,
        flap: 0.03,
      );
      final land = _span(u, 4.04, 4.4);
      if (land < 1) {
        _tasvirHudhud(
          c,
          Offset.lerp(const Offset(680, 150), const Offset(410, g - 50), land)!,
          1.3,
          time,
          a4 * (1 - _span(u, 4.34, 4.42)),
        );
      }
      _hudhudPerch(
        c,
        const Offset(410, g - 24),
        2.3,
        time,
        a4 * _span(u, 4.34, 4.42),
        flip: true,
      );
    }

    // 5: bulutların ardından bembeyaz kanatlı bir at dörtnala geçer, bir an
    // durup Sâye'ye bakar, sonra kaybolur. "Tulpar!" dedi Hüdhüd.
    final a5 = _heroA(u, 5);
    if (a5 > 0) {
      final run = _span(u, 5.02, 5.45);
      final gone = _span(u, 5.88, 5.98);
      final gallop = run > 0 && run < 1 ? 1.0 : 0.0;
      final hx = 760 - 250 * run;
      final hy = 270 - gallop * math.sin(time * 9).abs() * 10;
      _whiteHorse(
        c,
        Offset(hx, hy),
        150,
        time,
        a5 * (1 - gone),
        flip: true,
        flap: math.sin(time * (gallop > 0 ? 7 : 2)) * 0.15,
      );
      _cloud(c, 560, 300, 1.6, a5);
      _cloud(c, 720, 306, 1.2, a5);
      _cloudSea(c, time, a5);
      _cloud(c, 230, g + 12, 1.5, a5);
      _wingedSaye(
        c,
        const Offset(170, g - 22),
        1.7,
        time,
        a5,
        spread: 0.95,
        size: 0.72,
        flap: 0.03,
      );
      _hudhudPerch(c, const Offset(300, g - 24), 2.3, time, a5);
    }
  }

  /// Seven-kollu fişek: yedi boru demeti, ucunda külahlar, ardında ateş.
  static void _rocket(Canvas c, double time, double a, {double fire = 1}) {
    final ink = _inkPaint(a);
    for (var i = 0; i < 7; i++) {
      final y = -26 + i * 7.5;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-56, y, 100, 6.5),
          const Radius.circular(3),
        ),
        ink,
      );
      c.drawPath(
        Path()
          ..moveTo(44, y)
          ..lineTo(56, y + 3.2)
          ..lineTo(44, y + 6.5)
          ..close(),
        ink,
      );
      if (fire > 0) {
        final f = 22 + 12 * math.sin(time * 19 + i * 1.7);
        c.drawPath(
          Path()
            ..moveTo(-56, y)
            ..lineTo(-56 - f, y + 3.2)
            ..lineTo(-56, y + 6.5)
            ..close(),
          _holePaint(0.9 * a * fire),
        );
      }
    }
    c.drawRect(const Rect.fromLTWH(-20, -28, 5, 56), _holePaint(0.5 * a));
    c.drawRect(const Rect.fromLTWH(20, -28, 5, 56), _holePaint(0.5 * a));
  }

  /// Kırık güneş: ışık deliği bir teker, bir dilimi kopuk, çatlaklı.
  static void _brokenSun(Canvas canvas, Offset sc, double r, double a) {
    canvas.drawCircle(
      sc,
      r * 2.2,
      Paint()
        ..shader = ui.Gradient.radial(sc, r * 2.2, [
          const Color(0xFFFFE6B8).withValues(alpha: 0.55 * a),
          const Color(0x00FFE6B8),
        ]),
    );
    canvas.drawCircle(sc, r, _holePaint(a));
    canvas.drawPath(
      Path()
        ..moveTo(sc.dx, sc.dy)
        ..lineTo(sc.dx + r * 1.1, sc.dy - r * 0.4)
        ..lineTo(sc.dx + r * 0.8, sc.dy + r * 0.8)
        ..close(),
      Paint()..color = const Color(0xFFB8692F).withValues(alpha: 0.9 * a),
    );
    final crack = _inkPaint(a)..strokeWidth = 2;
    canvas.drawLine(
      sc + Offset(-r * 0.7, -r * 0.7),
      sc + Offset(-r * 0.1, 0),
      crack,
    );
    canvas.drawLine(
      sc + Offset(-r * 0.1, 0),
      sc + Offset(-r * 0.35, r * 0.95),
      crack,
    );
    canvas.drawLine(sc + Offset(-r * 0.1, 0), sc, crack);
    canvas.drawLine(
      sc + Offset(-r, r * 0.2),
      sc + Offset(-r * 0.25, r * 0.37),
      crack,
    );
    // Kopan parça: biraz ötede.
    canvas.drawPath(
      Path()
        ..moveTo(sc.dx + r * 1.5, sc.dy - r * 0.5)
        ..lineTo(sc.dx + r * 2.0, sc.dy - r * 0.2)
        ..lineTo(sc.dx + r * 1.6, sc.dy + r * 0.3)
        ..close(),
      _holePaint(0.6 * a),
    );
  }

  /// Kaf perdesi: zümrüt dağ, yüzük gibi saran Kaf, Hüdhüd'ün kuşları, yedi
  /// vadi, Hüdhüd'ün sözü.
  static void _kaf(Canvas canvas, double time, double u) {
    _c = canvas;
    final c = canvas;
    const g = _ground;

    // 0: bulutlar çekilir, zümrüt kayalardan bir dağ yükselir; dünya orada
    // biter. Sâye'nin kanatları titrer.
    final a0 = _heroA(u, 0);
    if (a0 > 0) {
      final part = _span(u, 0.05, 0.6);
      _qafMountain(c, Offset(500, 420 - 70 * part), 1.05, a0);
      _cloud(c, 260 - 300 * part, 330, 2.6, a0 * (1 - part * 0.6));
      _cloud(c, 620 + 300 * part, 320, 2.6, a0 * (1 - part * 0.6));
      _cloudSea(c, time, a0);
      _wingedSaye(
        c,
        const Offset(170, 250),
        1.4,
        time * 3,
        a0,
        spread: 0.4,
        flap: 0.08,
      );
      _tasvirHudhud(c, const Offset(290, 165), 1.0, time, a0);
    }

    // 1: "Kaf dünyayı bir yüzük gibi sarar; ardında ne gece ne gündüz;
    // tepesinde Simurg." Hüdhüd anlatır.
    final a1 = _heroA(u, 1);
    if (a1 > 0) {
      const wc = Offset(420, 225);
      // Dünya: yassı bir teker; ardında yarısı gece yarısı gündüz değil,
      // boşluk.
      c.drawOval(
        Rect.fromCenter(center: wc, width: 360, height: 120),
        _holePaint(0.35 * a1),
      );
      // Kaf: tekeri saran dağ halkası.
      final ring = _span(u, 1.05, 1.5);
      for (var i = 0; i < 26; i++) {
        final t = i / 26 * math.pi * 2;
        if (i / 26 > ring) continue;
        final p = wc + Offset(math.cos(t) * 205, math.sin(t) * 74);
        final back = math.sin(t) < 0;
        c.drawPath(
          Path()
            ..moveTo(p.dx - 18, p.dy + 8)
            ..lineTo(p.dx - 4, p.dy - 34)
            ..lineTo(p.dx + 3, p.dy - 26)
            ..lineTo(p.dx + 10, p.dy - 40)
            ..lineTo(p.dx + 20, p.dy + 8)
            ..close(),
          _inkPaint(a1 * (back ? 0.6 : 1)),
        );
      }
      // Tepede Simurg.
      final simA = a1 * _span(u, 1.45, 1.7);
      c.save();
      c.translate(420, 140 + math.sin(time * 1.4) * 4);
      c.scale(1.5);
      c.drawPath(MythShapes.birdGlide, _inkPaint(simA));
      c.restore();
      _hudhudPerch(c, const Offset(110, g), 2.2, time, a1);
    }

    // 2: "Bütün kuşlar Simurg'u bulmak için yola düştü; yolu onlara ben
    // gösterdim." Önde tepesi kabarmış Hüdhüd, ardında kuş kolu.
    final a2 = _heroA(u, 2);
    if (a2 > 0) {
      _cloudSea(c, time, a2);
      final k = _span(u, 2.02, 2.98);
      final lead = Offset(470 + 160 * k, 150 + 20 * math.sin(k * 3));
      for (var i = 0; i < 16; i++) {
        final d = 40.0 + i * 30;
        final p =
            lead + Offset(-d, d * 0.42 + math.sin(time * 2 + i * 0.7) * 10);
        if (p.dx < 20) continue;
        _bird(c, p, time, a2, i * 1.3);
      }
      _tasvirHudhud(c, lead, 1.5, time, a2);
      // Kabaran tepelik: başının üstünde ışık halkası (Süleyman'ın
      // habercisi).
      final pride = _span(u, 2.4, 2.7);
      c.drawCircle(
        lead + const Offset(30, -40),
        18 + 6 * pride,
        _holePaint(0.35 * a2 * pride)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // 3: yedi vadi; kimi korkar, kimi yorulur, kimi bir dala konar; dağa
    // otuz kuş varır. Hüdhüd susar, gözü dolar.
    final a3 = _heroA(u, 3);
    if (a3 > 0) {
      _qafMountain(c, const Offset(700, g), 0.55, a3);
      for (var i = 0; i < 7; i++) {
        final x = 60 + i * 86.0;
        c.drawPath(
          Path()
            ..moveTo(x - 50, g + 12)
            ..quadraticBezierTo(x, g - 120 - (i % 2) * 30, x + 50, g + 12)
            ..close(),
          _inkPaint(a3 * (0.45 + i * 0.06)),
        );
      }
      // Dala konup kalkmayan kuş.
      final branch = _inkPaint(a3)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      c.drawLine(const Offset(318, g - 90), const Offset(318, g - 170), branch);
      c.drawLine(
        const Offset(318, g - 140),
        const Offset(352, g - 160),
        branch,
      );
      c.drawOval(
        Rect.fromCenter(
          center: const Offset(344, g - 162),
          width: 14,
          height: 9,
        ),
        _inkPaint(a3 * _span(u, 3.3, 3.45)),
      );
      final k = _span(u, 3.05, 3.9);
      for (var i = 0; i < 36; i++) {
        // Kimi geride kalır, kimi düşer: otuzu varır.
        final quit = i % 6 == 5;
        final drop = quit
            ? _span(k, 0.2 + (i % 4) * 0.12, 0.45 + (i % 4) * 0.12)
            : 0.0;
        final bx = 60 + k * 520 + (i % 9) * 14.0 - drop * 60;
        final by =
            90 + (i ~/ 9) * 18.0 + math.sin(time * 4 + i) * 4 + drop * 120;
        _bird(c, Offset(bx, by), time, a3 * (1 - drop), i * 0.9);
      }
      _hudhudPerch(
        c,
        const Offset(110, g),
        2.2,
        time,
        a3,
        tear: _span(u, 3.6, 3.85),
        crest: 0.6,
      );
    }

    // 4: "Simurg'un üç tüyü bu dağda saklı; tepedeki aynaya varırsın."
    // Hüdhüd Sâye'nin gözlerinin içine bakar.
    final a4 = _heroA(u, 4);
    if (a4 > 0) {
      _qafMountain(c, const Offset(560, g + 10), 0.95, a4 * 0.75);
      // Üç tüy ve doruktaki ayna.
      for (final p in [
        const Offset(470, 230),
        const Offset(640, 180),
        const Offset(560, 110),
      ]) {
        c.drawCircle(p, 14, _holePaint(0.35 * a4));
        c.drawLine(
          p + const Offset(-5, 9),
          p + const Offset(5, -9),
          _holePaint(0.9 * a4)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      }
      c.drawOval(
        Rect.fromCenter(center: const Offset(598, 54), width: 18, height: 26),
        _holePaint(a4 * (0.6 + 0.3 * math.sin(time * 3))),
      );
      // Kaya çıkıntısı: Sâye ve karşısında, göz hizasında Hüdhüd.
      c.drawPath(
        Path()
          ..moveTo(0, g)
          ..lineTo(330, g)
          ..lineTo(356, g - 70)
          ..lineTo(412, g - 76)
          ..lineTo(430, g + 50)
          ..lineTo(0, g + 50)
          ..close(),
        _inkPaint(a4),
      );
      _wingedSaye(
        c,
        const Offset(250, g),
        1.9,
        time,
        a4,
        spread: 0.95,
        size: 0.72,
        flap: 0.02,
      );
      _hudhudPerch(c, const Offset(386, g - 74), 1.9, time, a4, flip: true);
    }
  }

  /// Kaf'ın aynası, Ağrı'nın eteği, tipi (perde_east.dart).
  static void _mirror(Canvas canvas, double time, double u) {
    _c = canvas;
    _mirrorTale(canvas, time, u);
  }

  /// Ana menünün perdesi: kandille aydınlanan bez, oymalı çerçeve, gölge
  /// harflerle oyunun adı, önünde Sâye ve Hüdhüd.
  /// Oyunun ilk açılışındaki giriş (bkz. perde_giris.dart): [t] saniye;
  /// [target] menüdeki perdenin ekrandaki yeri (sonda oraya kayar).
  static void paintIntro(
    Canvas canvas,
    Size size,
    double t,
    String title,
    String tagline, {
    Rect? target,
    double? menuTime,
    String? creditLabel,
    String? creditName,
  }) => _paintIntro(
    canvas,
    size,
    t,
    title,
    tagline,
    target: target,
    menuTime: menuTime,
    creditLabel: creditLabel,
    creditName: creditName,
  );

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
    _menuHeading(canvas, flicker, title, tagline);
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
