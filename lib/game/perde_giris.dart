part of 'perde.dart';

// ================================================================ Giriş
//
// Oyunun ilk açılışı (yaklaşık 14 saniye, sözsüz):
//  0. Karanlıkta Karagöz geleneğindeki gibi perdeyi oynatan anılır: hayalî.
//  1. Karanlık. Kibrit çakılır, perdenin ardında kandil yanar; deri dokulu
//     perde belirir.
//  2. Sâye'nin tasviri ışığa yaklaşır, gölgesi büyür. Sâye durur; gölgesi
//     bir adım daha atar (bu oyunda gölgelerin kendi iradesi var).
//  3. Perdenin kenarından Kandilci'nin uzun gölgesi geçer: alev eğilir,
//     Sâye'nin gölgesi korkup ona sığınır.
//  4. Kandil söner; kavanozdan tek bir ateşböceği kalır, uçuşuyla oyunun
//     adını aydınlatır.
//  5. Ateşböceği kandile iner, kandil yeniden yanar; perde ana menünün
//     perdesine dönüşür.

/// Girişin başında karanlıkta hayalînin adı (saniye): kibrit ondan sonra.
const introCredit = 1.8;

/// Girişin süresi (saniye): bundan sonra menü kalır.
const introLength = introCredit + 12.2;

/// Girişin anları (saniye): oynatıcı sesleri bunlara göre çalar.
abstract final class IntroBeats {
  static const strike = introCredit + 0.5;
  static const lampUp = introCredit + 1.3;
  static const sayeIn = introCredit + 2.3;
  static const sayeStop = introCredit + 4.6;
  static const shadowStep = introCredit + 4.7;
  static const lamplighter = introCredit + 5.6;
  static const lampOut = introCredit + 7.7;
  static const firefly = introCredit + 8.3;
  static const title = introCredit + 8.9;
  static const relight = introCredit + 10.3;
  static const toMenu = introCredit + 10.9;
  static const morph = introCredit + 11.2;
}

double _sayeX(double t) {
  final k = PerdePainter._span(t, IntroBeats.sayeIn, IntroBeats.sayeStop);
  return -60 + 390 * k;
}

/// Sâye'nin ölçeği: kandile (perdenin ortası) yaklaştıkça büyür.
double _sayeScale(double x) => 0.95 + 0.4 * (x / 330).clamp(0.0, 1.0);

/// Sâye'nin kavanozunun (ateşböceğinin çıktığı yer) sahnedeki yeri.
Offset _jarAt(double t) {
  final x = _sayeX(t);
  final s = _sayeScale(x) * 1.25;
  return Offset(x + 26 * s, 440 - 26 * s);
}

/// Ateşböceğinin yolu: kavanozdan çıkar, başlığın üstünden geçer, kandile
/// iner.
Offset _fireflyAt(double t) {
  final jar = _jarAt(t);
  const lamp = Offset(390, 330);
  if (t < IntroBeats.title) {
    final k = PerdePainter._span(t, IntroBeats.firefly, IntroBeats.title);
    return Offset.lerp(jar, const Offset(170, 150), k)! +
        Offset(math.sin(t * 9) * 3, math.cos(t * 7) * 3);
  }
  if (t < IntroBeats.relight) {
    final k = ((t - IntroBeats.title) / (IntroBeats.relight - IntroBeats.title))
        .clamp(0.0, 1.0);
    return Offset(
      170 + 450 * k,
      140 - math.sin(k * math.pi) * 34 + math.sin(t * 8) * 3,
    );
  }
  final k = PerdePainter._span(t, IntroBeats.relight, IntroBeats.toMenu);
  return Offset.lerp(const Offset(620, 140), lamp, k)!;
}

/// Kandilin gücü: 0 karanlık, 1 tam yanık.
double _lampLevel(double t) {
  if (t < IntroBeats.strike + 0.4) return 0;
  final up = PerdePainter._span(t, IntroBeats.lampUp - 0.3, IntroBeats.sayeIn);
  final out =
      1 - 0.94 * PerdePainter._span(t, IntroBeats.lampOut, IntroBeats.firefly);
  final again = PerdePainter._span(t, IntroBeats.relight, IntroBeats.toMenu);
  // Kandilci geçerken alev titrer, söner gibi olur.
  final dread = PerdePainter._shown(
    t,
    IntroBeats.lamplighter + 0.3,
    IntroBeats.lampOut,
    0.6,
  );
  final shiver = 1 - dread * (0.18 + 0.12 * math.sin(t * 23).abs());
  return math.max(up * out * shiver, again);
}

void _paintIntro(
  Canvas canvas,
  Size size,
  double t,
  String title,
  String tagline, {
  Rect? target,
  double? menuTime,
  String? creditLabel,
  String? creditName,
}) {
  final p = PerdePainter._span;
  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF050302));

  // Perde: ekranın ortasında; sonda menüdeki yerine kayar.
  var w = size.height * 0.74 * 780 / 484;
  if (w > size.width * 0.84) w = size.width * 0.84;
  final mid = Rect.fromCenter(
    center: size.center(Offset.zero).translate(0, size.height * 0.03),
    width: w,
    height: w * 484 / 780,
  );
  final r = Rect.lerp(
    mid,
    target ?? mid,
    p(t, IntroBeats.morph, introLength - 0.2),
  )!;
  final k = r.width / 780;
  Offset scr(Offset v) => r.topLeft + v * k;

  final lamp = _lampLevel(t);
  // Kandilci geçerken alev eğilir: ışığın ortası kayar.
  final lean = PerdePainter._shown(
    t,
    IntroBeats.lamplighter,
    IntroBeats.lampOut + 0.3,
    0.7,
  );
  final glowC = scr(Offset(390 - 46 * lean + math.sin(t * 6) * 4 * lean, 330));

  // Perdenin ışığı çevreye vurur.
  if (lamp > 0.01) {
    canvas.drawCircle(
      r.center,
      r.width * 0.8,
      Paint()
        ..shader = ui.Gradient.radial(r.center, r.width * 0.8, [
          const Color(0xFF3A1A0B).withValues(alpha: 0.75 * lamp),
          const Color(0xFF3A1A0B).withValues(alpha: 0),
        ]),
    );
  }
  canvas.save();
  canvas.clipRect(r);
  // Bez: kandilin ışığı arkadan vurur.
  Color lit(int c) => Color.lerp(const Color(0xFF0A0503), Color(c), lamp)!;
  canvas.drawRect(
    r,
    Paint()
      ..shader = ui.Gradient.radial(
        glowC,
        r.width * (0.45 + 0.3 * lamp),
        [lit(0xFFFFE2B0), lit(0xFFF2B46A), lit(0xFFB8692F), lit(0xFF4A2210)],
        const [0, 0.2, 0.58, 1],
      ),
  );
  final weave = Paint()
    ..color = const Color(0xFF000000).withValues(alpha: 0.05 + 0.04 * lamp)
    ..strokeWidth = 1;
  for (var y = r.top + 1.5; y < r.bottom; y += 3) {
    canvas.drawLine(Offset(r.left, y), Offset(r.right, y), weave);
  }

  // Tasvirler 780×484'lük sanal perdede.
  canvas.save();
  canvas.translate(r.left, r.top);
  canvas.scale(k, k);
  PerdePainter._c = canvas;
  PerdePainter._time = t;
  final figures = (lamp * 1.15).clamp(0.0, 1.0);

  // Kandilci'nin uzun gölgesi: sağdan girer, perdeyi boydan boya geçer.
  final kt = p(t, IntroBeats.lamplighter, IntroBeats.lampOut + 0.5);
  if (kt > 0 && kt < 1) {
    final kx = 900 - 1080 * kt;
    PerdePainter._puppet(
      canvas,
      Offset(kx, 500),
      t,
      2.3,
      0.55 * figures,
      (ink, hole) => PerdePainter._lamplighter(ink, PerdePainter._noHole),
      scale: 2.3,
      flip: true,
      rod: false,
    );
  }

  // Sâye ve gölgesi.
  final sx = _sayeX(t);
  final ss = _sayeScale(sx) * 1.25;
  // Kandil yeniden yanarken Sâye menüdeki yerine ve boyuna geçer, gölgesi
  // ona karışır: menüye dönüşte iki Sâye görünmesin.
  final home = p(t, IntroBeats.relight, IntroBeats.toMenu);
  // Gölge Sâye'yi biraz geriden izler; Sâye durunca bir adım daha atar,
  // Kandilci yaklaşınca korkup ona sığınır.
  final step =
      64 *
      p(t, IntroBeats.shadowStep, IntroBeats.shadowStep + 0.55) *
      (1 - p(t, IntroBeats.lamplighter + 0.4, IntroBeats.lamplighter + 0.9));
  // Kandil perdenin ortasında: gölge ondan uzağa, iri düşer.
  final lag = t < IntroBeats.sayeStop ? -10.0 : 0.0;
  final shadowX = 390 + (sx - 390) * 1.25 + lag + step;
  // Fazladan adımda gölge kendi başına yürür: hafifçe inip kalkar.
  final walking = step > 0.5 && step < 63.5;
  final bob = walking ? -(math.sin(t * 14).abs()) * 4 : 0.0;
  PerdePainter._puppet(
    canvas,
    Offset(shadowX, 452 + bob),
    t,
    0.4,
    0.34 * figures * (1 - home),
    (ink, hole) => PerdePainter._saye(ink, PerdePainter._noHole, t, jar: 0),
    scale: ss * 1.6,
    rod: false,
  );
  final sayeBob = t < IntroBeats.sayeStop ? -(math.sin(t * 9).abs()) * 3 : 0.0;
  PerdePainter._puppet(
    canvas,
    Offset(sx + (200 - sx) * home, 440 + sayeBob + 30 * home),
    t,
    0.7,
    figures,
    (ink, hole) => PerdePainter._saye(
      ink,
      hole,
      t,
      jar: t < IntroBeats.firefly ? 1 : home,
    ),
    scale: ss + (1.25 - ss) * home,
  );

  // Başlık: menüdekiyle aynı çizim (aynı yer, yazı, renk ve ışık). Kandil
  // sönükken ateşböceği geçtikçe ardında bezde ılık bir iz kalır; koyu
  // harfler o ışığın önünde belirir. Kandil yeniden yanınca iz söner, başlık
  // menüdekiyle birebir kalır.
  final reveal = t < IntroBeats.title
      ? -1.0
      : (t < IntroBeats.relight ? _fireflyAt(t).dx : 900.0);
  if (reveal > 0) {
    final trail = 1 - p(t, IntroBeats.relight, IntroBeats.toMenu);
    if (trail > 0) {
      // Yumuşak iz: ateşböceğinin geçtiği yol boyunca üst üste ışık lekeleri.
      for (var x = 150.0; x <= math.min(reveal, 660); x += 34) {
        glowDot(
          canvas,
          Offset(x, 130),
          120,
          const Color(0xFFF2B46A),
          0.2 * trail,
        );
      }
    }
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, reveal + 8, 484));
    PerdePainter._menuHeading(
      canvas,
      0.9 + 0.06 * math.sin(t * 7.3) + 0.04 * math.sin(t * 13.1 + 1.7),
      title,
      tagline,
    );
    canvas.restore();
  }
  canvas.restore();

  // Kibrit: perdenin ardında çakılan kıvılcım, sonra küçük alev.
  final strike = t - IntroBeats.strike;
  if (strike > 0 && strike < 1.2) {
    final lampAt = scr(const Offset(390, 330));
    final flare = strike < 0.25 ? strike / 0.25 : 1.0;
    glowDot(canvas, lampAt, 40 * k * (0.5 + flare), kWarmLight, 0.5 * flare);
    if (strike < 0.35) {
      final spark = Paint()..color = const Color(0xFFFFF0C8);
      for (var i = 0; i < 6; i++) {
        final a = i * 1.1 + 0.4;
        final d = strike * 120 * k * (0.6 + (i % 3) * 0.25);
        canvas.drawCircle(
          lampAt + Offset(math.cos(a), -math.sin(a).abs()) * d,
          1.4,
          spark,
        );
      }
    }
  }

  // Kandilin perdeden sızan alev lekesi.
  if (lamp > 0.02) {
    glowDot(
      canvas,
      glowC,
      r.width * 0.12,
      const Color(0xFFFFF0C8),
      0.35 * lamp,
    );
  }
  // Ateşböceği: kavanozdan çıkar, başlığı aydınlatır, kandile iner.
  if (t > IntroBeats.firefly && t < IntroBeats.toMenu + 0.2) {
    final f = scr(_fireflyAt(t));
    final a =
        p(t, IntroBeats.firefly, IntroBeats.firefly + 0.3) *
        (1 - p(t, IntroBeats.toMenu - 0.2, IntroBeats.toMenu + 0.2));
    final pulse = 0.75 + 0.25 * math.sin(t * 11);
    glowDot(canvas, f, 46 * k, const Color(0xFFFFE08A), 0.55 * a * pulse);
    canvas.drawCircle(
      f,
      2.6 * k + 1,
      Paint()..color = const Color(0xFFFFF6D8).withValues(alpha: a),
    );
  }
  // Kenarlar gölgede.
  canvas.drawRect(
    r,
    Paint()
      ..shader = ui.Gradient.radial(
        r.center,
        r.width * 0.62,
        [
          const Color(0xFF2A1208).withValues(alpha: 0),
          const Color(0xFF2A1208).withValues(alpha: 0.55),
        ],
        const [0.6, 1],
      ),
  );
  canvas.restore();
  PerdePainter._frame(canvas, r, lamp);

  // Menüye dönüş: menünün perdesi aynı yerde belirir.
  final menu = p(t, IntroBeats.toMenu, IntroBeats.morph + 0.3);
  if (menu > 0) {
    // paintMenu perdeyi tuvalin genişliğine göre yerleştirir: perde
    // dikdörtgeni r'ye otursun diye tuval kaydırılıp ölçeklenir.
    final mw = r.width / 0.88;
    canvas.saveLayer(
      r.inflate(r.width * 0.12),
      Paint()..color = Color.fromRGBO(0, 0, 0, menu),
    );
    canvas.translate(r.left - mw * 0.06, r.top - mw * 0.11);
    PerdePainter.paintMenu(
      canvas,
      Size(mw, mw * 0.8),
      menuTime ?? t,
      title,
      tagline,
    );
    canvas.restore();
  }
  // Hayalînin adı: perdenin önünde, karanlıkta.
  if (creditName != null && t < introCredit) {
    _paintCredit(canvas, size, t, creditLabel ?? '', creditName);
  }
}

/// Hayalînin adı: karanlıkta, perdenin çerçevesine vuran kor ışığı renginde,
/// küçük ve soluk; belirir, durur, söner.
void _paintCredit(
  Canvas canvas,
  Size size,
  double t,
  String label,
  String name,
) {
  final a = math.min(
    PerdePainter._span(t, 0.2, 0.7),
    1 - PerdePainter._span(t, introCredit - 0.55, introCredit - 0.1),
  );
  if (a <= 0) return;
  final k = (size.height / 400).clamp(0.7, 1.6);
  const ember = Color(0xFFE0A15F);
  final top = TextPainter(
    text: TextSpan(
      text: label.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 11 * k,
        letterSpacing: 5 * k,
        color: ember.withValues(alpha: 0.6 * a),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  // Ad, oyunun adıyla aynı yazı biçiminde (kalın, aralıklı büyük harfler);
  // karanlıkta harflerin oyuklarından kandil ışığı sızıyormuş gibi.
  final big = TextPainter(
    text: TextSpan(
      text: name.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 34 * k,
        fontWeight: FontWeight.w900,
        letterSpacing: 7 * k,
        color: const Color(0xFFFFE6B8).withValues(alpha: 0.85 * a),
        shadows: [
          Shadow(
            color: const Color(0xFFFFB46A).withValues(alpha: 0.6 * a),
            blurRadius: 14 * k,
          ),
        ],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final c = size.center(Offset.zero);
  final gap = 8 * k;
  final h = top.height + gap + big.height;
  top.paint(canvas, Offset(c.dx - top.width / 2, c.dy - h / 2));
  big.paint(
    canvas,
    Offset(c.dx - big.width / 2, c.dy - h / 2 + top.height + gap),
  );
}
