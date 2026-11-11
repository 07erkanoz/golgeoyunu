part of 'perde.dart';

// ================================================ Yerebatan köprüsü (yeni)
//
// docs/oneri/YEREBATAN_KOPRUSU.md: açılış perdesinin tarifiyle sıfırdan.
// Dekor perdeye boyanmış sarnıç (üretilmiş görsel), su iyesi renkli bir
// tasvir (üretilmiş görsel), Medusa başı oyundaki çizim, Sâye oyundaki
// kukla. Sâye hep bir zemine basar: önde düz taş set, sal, basamak.
// Satırlar 0, 1, 2; her satırda hareketler satırın oranına bağlı (ses
// süresi satırın boyudur; iki dilde de oturur).

const _ybGround = 350.0; // setin üstü (Sâye'nin bastığı yer)
const _ybWater = 357.0; // suyun yüzü
const _ybLedgeEnd = 478.0; // setin bittiği yer
const _ybK = 0.34; // Sâye'nin ölçeği (açılıştakine yakın)

/// Yeni köprü çizilebilir mi (görseller ve kukla yüklü).
bool get _ybReady =>
    TasvirImages.kopru0Sarnic != null &&
    TasvirImages.suIyesi != null &&
    PerdeSaye.ready;

void _ybCistern(Canvas c, double time, double u) {
  final line = u.floor().clamp(0, 2);
  final f = (u - line).clamp(0.0, 1.0);

  // Dekor: perdeye boyanmış sarnıç; puppetler seçilsin diye bir ton koyu.
  final bg = TasvirImages.kopru0Sarnic!;
  final bh = 780 * bg.height / bg.width;
  c.drawImageRect(
    bg,
    Rect.fromLTWH(0, 0, bg.width.toDouble(), bg.height.toDouble()),
    Rect.fromLTWH(0, 400 - bh + 14, 780, bh),
    Paint()..filterQuality = FilterQuality.medium,
  );
  c.drawRect(
    const Rect.fromLTWH(0, 0, 780, 400),
    Paint()..color = const Color(0x300A0402),
  );

  // Su: kıpırtısız kara su, yüzünde ince ışık çizgileri.
  c.drawRect(
    const Rect.fromLTRB(0, _ybWater, 780, 400),
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, _ybWater),
        const Offset(0, 400),
        const [Color(0xCC120A06), Color(0xF0050302)],
      ),
  );
  final glint = Paint()
    ..color = const Color(0xFFE8B070).withValues(alpha: 0.18)
    ..strokeWidth = 1;
  for (var i = 0; i < 9; i++) {
    final x = _ybLedgeEnd + 12 + (i * 37.0 + time * 6) % 300;
    final y = _ybWater + 6 + (i % 3) * 9;
    c.drawLine(Offset(x, y), Offset(x + 14 + i % 4 * 4, y), glint);
  }

  // Satır 1: su iyesi; satır 2'nin başında suya geri iner.
  final rise = line == 0 ? _span(f, 0.12, 0.36) : 1.0;
  final sink = line == 1 ? 1 - _span(f, 0.0, 0.16) : (line == 0 ? 1.0 : 0.0);
  final spirit = rise * sink;
  if (line == 0) _ybRipples(c, const Offset(612, _ybWater), f, time);
  if (spirit > 0) _ybSpirit(c, spirit, time);

  // Sal (satır 3) ve merdiven.
  final raftX = line == 2 ? 545 + 150 * _span(f, 0.52, 0.8) : 545.0;
  if (line == 2) {
    _ybStairs(c, time, _span(f, 0.66, 0.85));
    _ybRaft(c, raftX, time);
  }

  // Karabasan (satır 3'ün başı): Sâye'nin ardındaki karanlıkta.
  if (line == 2) {
    final kb = _span(f, 0.02, 0.12) * (1 - _span(f, 0.24, 0.32));
    if (kb > 0) {
      _karabasan(
        c,
        const Offset(170, 300),
        58,
        0.85 * kb,
        time,
        dir: 1,
        reach: 0.4 + 0.6 * kb,
      );
    }
  }

  // Taş set ve vana (önde, düz: gölge oyununun zemini).
  _ybLedge(c);
  final valveGlow = line == 0 ? _span(f, 0.62, 0.72) : 0.0;
  _ybValve(c, const Offset(150, _ybGround - 26), valveGlow, time);

  // Medusa başları (satır 2): biri setin ardında, biri önünde.
  final heads = line == 1 ? _span(f, 0.08, 0.3) : (line == 2 ? 1.0 : 0.0);
  final ring = line == 1 ? _shown(f, 0.42, 0.78, 0.08) : 0.0;
  if (heads > 0)
    _ybMedusa(c, const Offset(360, _ybGround), heads, ring, flip: true);

  _ybSaye(c, line, f, time, raftX);

  if (heads > 0) _ybMedusa(c, const Offset(452, _ybGround), heads, ring);
}

/// Sâye: satıra göre yeri ve hâli.
void _ybSaye(Canvas c, int line, double f, double time, double raftX) {
  var feet = const Offset(292, _ybGround);
  var frame = 'dur_kavanoz';
  var faceLeft = false;
  KuklaMode? mode;
  var vy = 0.0;
  switch (line) {
    case 0:
      // Suya bakar; "Önce suyu aç." deyince vanaya döner.
      faceLeft = f > 0.86;
    case 1:
      // Başlara bakar; "gözlerini yumup aralarından geçti": çömelip
      // kavanozunu saklar, başların arasından geçer.
      if (f > 0.7) {
        frame = 'comel_kavanoz';
        final go = _span(f, 0.74, 0.98);
        feet = Offset(292 + 178 * go, _ybGround);
      }
    case _:
      feet = const Offset(470, _ybGround);
      // "nefes aldı ... döndü; kimse yoktu."
      faceLeft = f > 0.2 && f < 0.36;
      if (f > 0.4) {
        // Sala sıçrar, salda süzülür, basamağa geçer.
        final j = _span(f, 0.4, 0.5);
        final onRaft = Offset(raftX, _ybGround + 1);
        if (f < 0.5) {
          final x = 470 + (onRaft.dx - 470) * j;
          final y = _ybGround - math.sin(j * math.pi) * 34;
          feet = Offset(x, y);
          mode = KuklaMode.air;
          vy = -math.cos(j * math.pi) * 200;
        } else {
          feet = onRaft;
          final step = _span(f, 0.84, 0.94);
          if (step > 0) {
            // Saldan ilk basamağa (merdivenin dibi, suyun hemen üstü).
            final x = raftX + (712 - raftX) * step;
            final y = _ybGround + 1 - 14 * step - math.sin(step * math.pi) * 16;
            feet = Offset(x, y);
            if (step < 1) {
              mode = KuklaMode.air;
              vy = -math.cos(step * math.pi) * 160;
            }
          }
        }
      }
  }
  _P._sayeFrame(
    c,
    frame,
    feet,
    _ybK,
    time,
    mode: mode,
    vy: vy,
    faceLeft: faceLeft,
  );
}

/// Önde düz taş set: kâğıt oyma, taş derzleri, üstünde sıcak kenar.
void _ybLedge(Canvas c) {
  final r = const Rect.fromLTRB(-10, _ybGround, _ybLedgeEnd, 400);
  c.drawRect(r, _ink(0.95));
  final joint = Paint()
    ..color = const Color(0xFF3A2216)
    ..strokeWidth = 1.2;
  for (var x = 30.0; x < _ybLedgeEnd; x += 64) {
    c.drawLine(Offset(x, _ybGround + 4), Offset(x, _ybGround + 18), joint);
  }
  c.drawLine(
    const Offset(-10, _ybGround + 19),
    const Offset(_ybLedgeEnd, _ybGround + 19),
    joint,
  );
  c.drawLine(
    const Offset(-10, _ybGround + 0.8),
    const Offset(_ybLedgeEnd, _ybGround + 0.8),
    Paint()
      ..color = const Color(0xFFE8A060).withValues(alpha: 0.55)
      ..strokeWidth = 1.4,
  );
}

/// Paslı vana: sütunun dibinde boru ve çark; gösterilince parlar.
void _ybValve(Canvas c, Offset at, double glow, double time) {
  if (glow > 0) {
    final g = glow * (0.75 + 0.25 * math.sin(time * 6));
    c.drawCircle(
      at,
      30,
      Paint()
        ..shader = ui.Gradient.radial(at, 30, [
          const Color(0xFFBFF0E0).withValues(alpha: 0.55 * g),
          const Color(0x00BFF0E0),
        ]),
    );
  }
  final ink = _ink(1);
  c.drawRect(Rect.fromLTWH(at.dx - 3, at.dy, 6, _ybGround - at.dy), ink);
  final wheel = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = ink.color;
  c.drawCircle(at, 10, wheel);
  for (var k = 0; k < 4; k++) {
    final a = k * math.pi / 4 + 0.3;
    c.drawLine(
      at + Offset(math.cos(a) * 10, math.sin(a) * 10),
      at - Offset(math.cos(a) * 10, math.sin(a) * 10),
      Paint()
        ..strokeWidth = 2
        ..color = ink.color,
    );
  }
  c.drawCircle(at, 3, ink);
  // Pas: kenarda kızıl bir ışık değil, soluk bir halka.
  c.drawCircle(
    at,
    10,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFB0602A).withValues(alpha: 0.5 + 0.5 * glow),
  );
}

/// Suyun yüzünde açılan halkalar (su kıpırdar).
void _ybRipples(Canvas c, Offset at, double f, double time) {
  final a = _shown(f, 0.0, 0.4, 0.1);
  if (a <= 0) return;
  for (var i = 0; i < 3; i++) {
    final k = ((f * 3 + i / 3) % 1.0);
    c.drawOval(
      Rect.fromCenter(center: at, width: 30 + k * 120, height: 5 + k * 12),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFE8C090).withValues(alpha: 0.45 * a * (1 - k)),
    );
  }
}

/// Su iyesi: sudan yükselir, belden aşağısı suyun içinde kalır; ağır ağır
/// salınır. Tasvir sola bakar, parmağıyla gösterir.
void _ybSpirit(Canvas c, double rise, double time) {
  final img = TasvirImages.suIyesi!;
  const h = 196.0;
  final w = h * img.width / img.height;
  final top = _ybWater - h * 0.62 * rise;
  final sway = math.sin(time * 1.1) * 0.025;
  c.save();
  c.clipRect(const Rect.fromLTRB(0, 0, 780, _ybWater + 1));
  // Arkasında soğuk bir parıltı (sudan gelen ışık).
  final center = Offset(612, top + h * 0.3);
  c.drawCircle(
    center,
    90,
    Paint()
      ..shader = ui.Gradient.radial(center, 90, [
        const Color(0xFF7FD8C8).withValues(alpha: 0.28 * rise),
        const Color(0x007FD8C8),
      ]),
  );
  c.translate(612, top + h);
  c.rotate(sway);
  c.drawImageRect(
    img,
    Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
    Rect.fromLTWH(-w * 0.45, -h + math.sin(time * 0.9) * 2, w, h),
    Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Color.fromRGBO(255, 255, 255, (0.3 + 0.7 * rise).clamp(0, 1)),
  );
  c.restore();
}

/// Medusa başı (oyundaki çizim): Yerebatan'daki gibi biri yan, biri baş
/// aşağı sütunun dibine yaslanmış iri bir taş baş. [ring] gölgenin
/// değmemesi gereken yeri gösteren soluk halka.
void _ybMedusa(
  Canvas c,
  Offset base,
  double a,
  double ring, {
  bool flip = false,
}) {
  final img = TasvirImages.medusa;
  if (img == null) return;
  const h = 78.0;
  final w = h * img.width / img.height;
  // Yan yatan başın boyu genişliği kadar; baş aşağı olanınki boyu kadar.
  final rest = flip ? w / 2 : h / 2;
  if (ring > 0) {
    c.drawOval(
      Rect.fromCenter(
        center: base + const Offset(0, -3),
        width: h * 1.5,
        height: 18,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFFE8D0A0).withValues(alpha: 0.55 * ring * a),
    );
  }
  c.save();
  c.translate(base.dx, base.dy - rest);
  c.rotate(flip ? math.pi / 2 : math.pi);
  c.drawImageRect(
    img,
    Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
    Rect.fromCenter(center: Offset.zero, width: w, height: h),
    Paint()
      ..filterQuality = FilterQuality.medium
      ..colorFilter = const ColorFilter.mode(
        Color(0xFFB09070),
        BlendMode.modulate,
      )
      ..color = Color.fromRGBO(255, 255, 255, a),
  );
  c.restore();
}

/// Sal: üç kalas, iple bağlı; suyun üstünde hafifçe iner kalkar.
void _ybRaft(Canvas c, double x, double time) {
  final bob = math.sin(time * 1.6) * 1.2;
  final y = _ybGround + 2 + bob;
  final ink = _ink(1);
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(x - 40, y, 80, 10),
      const Radius.circular(2),
    ),
    ink,
  );
  final rope = Paint()
    ..color = const Color(0xFF6A4026)
    ..strokeWidth = 1.2;
  for (final dx in const [-22.0, 0.0, 22.0]) {
    c.drawLine(Offset(x + dx, y), Offset(x + dx, y + 8), rope);
  }
  c.drawLine(
    Offset(x - 40, y + 0.6),
    Offset(x + 40, y + 0.6),
    Paint()
      ..color = const Color(0xFFE8A060).withValues(alpha: 0.7)
      ..strokeWidth = 1.4,
  );
}

/// Kanalın sonundaki merdiven: sağ kenardan yukarı çıkar; tepesinden yanan
/// şehrin kızıl ışığı sızar ([glow] satırın sonunda büyür).
void _ybStairs(Canvas c, double time, double glow) {
  final top = const Offset(790, 120);
  final g = (0.35 + 0.65 * glow) * (0.85 + 0.15 * math.sin(time * 5));
  c.drawCircle(
    top,
    170,
    Paint()
      ..shader = ui.Gradient.radial(top, 170, [
        const Color(0xFFFF7A3A).withValues(alpha: 0.5 * g),
        const Color(0x00FF7A3A),
      ]),
  );
  final steps = Path()..moveTo(700, 400);
  var x = 700.0, y = _ybGround - 12;
  steps.lineTo(x, y);
  while (x < 790) {
    x += 14;
    steps.lineTo(x, y);
    y -= 12;
    steps.lineTo(x, y);
  }
  steps
    ..lineTo(790, 400)
    ..close();
  c.drawPath(steps, _ink(1));
  // Basamakların ağzı yukarıdaki ateşin ışığını yakalar.
  final lip = Paint()
    ..color = const Color(0xFFFF9A5A).withValues(alpha: 0.35 + 0.4 * g)
    ..strokeWidth = 1.4;
  var sx = 700.0, sy = _ybGround - 12;
  while (sx < 790) {
    c.drawLine(Offset(sx, sy + 0.8), Offset(sx + 14, sy + 0.8), lip);
    sx += 14;
    sy -= 12;
  }
}
