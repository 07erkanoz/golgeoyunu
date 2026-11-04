part of 'perde.dart';

// ======================================================= Açılış perdesi
//
// docs/oneri/ACILIS_PERDESI.md: olay önce gösterilir, Sâye'nin amacı
// söylenir, ardından oyun başlar. Sahneler satır satır ([u] 0, 1, 2...).
// Karagöz ile Hacivat gerçek tasvirler (British Museum), Sâye oyundaki
// Sâye'nin kendisi (TasvirImages).

abstract final class _Acilis {
  /// Seslendirmeyle eşleme: satırların gerçek süresi farklı (7-16 sn).
  /// Parça parça doğrusal: [pts] (gerçek, tasarım) çiftleri.
  static double _remap(double x, List<(double, double)> pts) {
    if (x <= pts.first.$1) return pts.first.$2 + x - pts.first.$1;
    for (var i = 1; i < pts.length; i++) {
      final (a, da) = pts[i - 1];
      final (b, db) = pts[i];
      if (x <= b) return da + (db - da) * (x - a) / (b - a);
    }
    return pts.last.$2 + x - pts.last.$1;
  }

  /// 1. satır: Karagöz ile Hacivat'ın saati, sesle eş: anlatıcı konuşurken
  /// girip selamlaşırlar; Hacivat satırın %57-71'inde konuşur ("Hay
  /// Hak!"), Karagöz %73'te söze girer, %83'te kafa atar.
  static double _khT(double u) {
    if (u < 0.14) return (u - 0.14) / 0.41 * 2.0;
    return _remap(u, const [
      (0.14, 0.0),
      (0.55, 2.0),
      (0.71, 3.38),
      (0.82, 3.4),
      (0.87, 3.9),
      (1.0, 5.6),
    ]);
  }

  /// 3. satır, sesle eş: kandil anlatıcı "söndürüp aldılar" derken alınır,
  /// usta "sürüklediler"de sürüklenmeye başlar; Usta %50-68'de fısıldar
  /// (sürüklenirken), Hacivat %71-88'de son sözünü söyler, sonra düşer.
  static double _d3(double u) => u < 2
      ? u
      : _remap(u, const [
          (2.0, 2.0),
          (2.22, 2.46),
          (2.34, 2.6),
          (2.36, 2.62),
          (2.707, 2.82),
          (2.88, 2.98),
          (3.0, 3.12),
        ]);

  /// [from] satırına girildiğinden beri geçen gerçek saniye (ses ne kadar
  /// sürerse sürsün düşüş, sıçrama ağır çekime dönmez); önce -1.
  static final _starts = <double, double>{};
  static double _secs(double u, double from) {
    final time = PerdePainter._time;
    if (u < from) {
      _starts.remove(from);
      return -1;
    }
    final t0 = _starts[from];
    if (t0 == null || time < t0) {
      // İlk karede satırın başı (önizlemede satır 8 sn).
      _starts[from] = time - (u - from) * 8;
      return (u - from) * 8;
    }
    return time - t0;
  }

  /// 6. sahnede sudaki bölümün (dalış, yüzüş, çıkış) setin üstündeki
  /// olayları ne kadar geciktirdiği (sn).
  static double get _wetShift {
    const gravity = 1100.0, top = -90.0, t0 = 0.25;
    final hit = t0 + math.sqrt(2 * (_water + 4 - top) / gravity);
    return hit + 0.45 + 1.7 + 0.3 + 1.1 - 3.35;
  }

  /// 7. sahnenin saniyesi: 7. satırla başlar, ama 6. sahne (sudan çıkış,
  /// fidan, kavanozun dolması) bitmeden başlamaz; satır erken geçse de
  /// Kandilci Sâye sudan çıkıp kavanozunu almadan gelmez.
  static double _secs7(double u) {
    final s = _secs(u, 6);
    if (s < 0) return -1;
    return math.min(s, _secs(u, 5) - (7.0 + _wetShift));
  }

  /// Açılışın bütün sahneleri: her sahne kendi satır aralığında çizilir,
  /// geçişlerde bir öncekiyle karışır. Ustanın perdesinin önündeki çocuklar,
  /// kenarda bekleyen Sâye ve kavanoz ustanın perdesindeki sahnelerde (1, 3)
  /// görünür; yangın (2) anlatılan olayın kendisidir, onlar orada yoktur.
  /// Ustanın perdesi görünür mü: 2. sahne (yangın) perdede oynanan bir şey
  /// değil, anlatılan olayın kendisi; seyirci, Sâye ve kavanoz o arada yok.
  static double _booth(double u) {
    if (u < 1 || u >= 2.1) return 1;
    return 1 -
        PerdePainter._span(u, 1.0, 1.1) +
        PerdePainter._span(u, 1.98, 2.08);
  }

  static void paint(Canvas canvas, double time, double u) {
    final booth = _booth(u);
    if (u < 1.15) scene1(canvas, time, u, 1 - PerdePainter._span(u, 1.0, 1.12));
    if (u >= 1.0 && u < 2.12) {
      final fade = 1 - PerdePainter._span(u, 2.0, 2.1);
      if (fade < 1) {
        canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, fade));
      }
      scene2(canvas, time, u);
      if (fade < 1) canvas.restore();
    }
    final d = _d3(u);
    if (u >= 2.0 && u < 3.0) scene3(canvas, time, d);
    if (u >= 5.0) {
      _cistern(canvas, time, ((_secs(u, 5) - 0.96) / 0.64).clamp(0.0, 1.0), u);
    }
    final fear = u < 2 ? 0.0 : PerdePainter._span(d, 2.14, 2.4);
    if (u < 3) {
      _sayeWaiting(
        canvas,
        time,
        PerdePainter._span(u, 0.16, 0.3) * booth,
        fear,
      );
    }
    // Önde, perdenin ışığına karşı: kandil yanınca kendiliğinden seçilir.
    // Karagöz kafa atınca kahkahayla sallanırlar; yangında susarlar;
    // Kandilcilerin gölgesi perdeye düşünce kaçışırlar.
    final laugh = u >= 1.0
        ? 0.0
        : _khT(u) < 3.45
        ? 0.15
        : 1.0;
    _children(canvas, time, laugh, u < 2 ? 0 : (d - 2.12) / 0.3, booth);
  }

  /// 1 · Perde yanar: kibrit çakılır, kandil perdenin ardında tutuşur;
  /// Karagöz ile Hacivat atışır, önde çocukların başları güler. Ustanın
  /// elinde, perdenin kenarında küçük bir tasvir bekler: Sâye.
  static void scene1(Canvas canvas, double time, double u, double a) {
    const g = PerdePainter._ground;
    // Kibrit: karanlıkta bir çakım, sonra kandilin alevi perdeyi ısıtır.
    final strike =
        PerdePainter._span(u, 0.03, 0.045) *
        (1 - PerdePainter._span(u, 0.05, 0.09));
    final flame = PerdePainter._span(u, 0.05, 0.16);
    const lampAt = Offset(390, 372);
    final hot = math.max(strike * 0.9, flame * 0.55);
    if (strike > 0) {
      // Kibritin çakımı perdenin ardında keskin bir ışık noktası.
      canvas.drawCircle(
        lampAt + const Offset(-14, -6),
        5 + 4 * strike,
        Paint()
          ..color = const Color(0xFFFFF8E0).withValues(alpha: strike)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    if (hot > 0) {
      canvas.drawCircle(
        lampAt,
        150 + 60 * flame,
        Paint()
          ..shader = ui.Gradient.radial(lampAt, 150 + 60 * flame, [
            const Color(0xFFFFF1C8).withValues(alpha: hot),
            const Color(0x00FFF1C8),
          ]),
      );
    }

    // Karagöz ile Hacivat: kandil yanınca yandan girer, selamlaşır;
    // Hacivat söze başlar ("Hay Hak!"), Karagöz kafa atar.
    final t = _khT(u);
    if (t > 0) {
      paintKaragozHacivat(
        canvas,
        const Offset(390, g + 6),
        232,
        t,
        a: PerdePainter._span(u, 0.12, 0.2) * a,
        rods: true,
      );
    }
  }

  /// Perdenin kenarında Sâye: ustanın elindeki çubukta, sırasını bekler.
  /// [fear]: Kandilciler gelince ustanın eli titrer.
  static void _sayeWaiting(
    Canvas canvas,
    double time,
    double a, [
    double fear = 0,
  ]) {
    if (a <= 0) return;
    final feet = Offset(742, 300 + math.sin(time * 1.3) * 1.5);
    if (!_sayeTasvir(
      canvas,
      feet,
      time,
      rot: math.sin(time * 0.9) * 0.04 + math.sin(time * 23) * 0.035 * fear,
      a: a,
    )) {
      return;
    }
    TasvirImages.rod(
      canvas,
      feet + const Offset(2, -52),
      feet + const Offset(30, 120),
      3.6,
      a,
    );
  }

  /// Şehrin pencereleri (Kandilciler ışıklarını toplar).
  static const _windows = [
    Offset(40, 262),
    Offset(70, 262),
    Offset(40, 286),
    Offset(70, 286),
    Offset(122, 274),
    Offset(146, 274),
    Offset(256, 238),
    Offset(300, 232),
    Offset(344, 238),
    Offset(452, 270),
    Offset(482, 270),
    Offset(452, 294),
    Offset(482, 294),
    Offset(586, 256),
    Offset(614, 256),
  ];

  /// 2 · Yangın ve Kandilciler: perde kızarır, alevlerin gölgesi dalgalanır;
  /// dumanın içinden Kandilciler çıkar, pencerelerin ışığı bir iplik gibi
  /// fenerlerine akar, pencereler birer birer söner.
  static void scene2(Canvas canvas, double time, double u) {
    final fire = PerdePainter._span(u, 1.02, 1.2);
    final cityA = PerdePainter._span(u, 1.06, 1.22);
    final flick =
        0.85 + 0.1 * math.sin(time * 6.1) + 0.05 * math.sin(time * 15.7);
    // Yangının ışığı perdeyi aşağıdan kızartır.
    if (fire > 0) {
      const at = Offset(390, 420);
      canvas.drawCircle(
        at,
        420,
        Paint()
          ..shader = ui.Gradient.radial(
            at,
            420,
            [
              const Color(0xFFE2512A).withValues(alpha: 0.55 * fire * flick),
              const Color(0xFFB8361C).withValues(alpha: 0.25 * fire * flick),
              const Color(0x00B8361C),
            ],
            const [0, 0.55, 1],
          ),
      );
      // Alevlerin gölgesi bezde dalgalanır.
      final tongue = Paint()
        ..color = const Color(0xFF3A0E05).withValues(alpha: 0.28 * fire)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      for (var i = 0; i < 9; i++) {
        final x = i * 96.0 - 10;
        final h = 150 + 60 * math.sin(time * 2.3 + i * 1.7);
        final sway = math.sin(time * 3.1 + i) * 26;
        canvas.drawPath(
          Path()
            ..moveTo(x - 46, 400)
            ..quadraticBezierTo(
              x - 30 + sway,
              400 - h * 0.6,
              x + sway * 1.6,
              400 - h,
            )
            ..quadraticBezierTo(x + 34 + sway, 400 - h * 0.5, x + 50, 400)
            ..close(),
          tongue,
        );
      }
    }
    if (cityA <= 0) return;

    // Kandilciler: dumanın içinden soldan çıkar, ev ev yürür.
    const s = 4.3;
    final k1 = -120 + 700 * PerdePainter._span(u, 1.3, 1.98);
    final k2 = k1 - 190;
    final walkers = [k1, k2];
    Offset lampOf(double x) {
      final phase = (x / s / 26) % 1.0;
      final art = guardLampArt(phase, 1, 0, 0, math.sin(time * 2 + x) * 0.15);
      return Offset(x, 330) + (art - guardArtFeet) * (guardArtScale * s);
    }

    // Evlerin damlarından alevler: perdede renkli, ışık geçiren tasvir gibi.
    _burning(
      canvas,
      time,
      cityA * (1 - PerdePainter._span(u, 1.85, 2.0) * 0.5),
    );
    // Şehir: kubbeler, minareler, cumbalı ahşap evler.
    _istanbul(canvas, cityA);
    final lamps = [for (final x in walkers) lampOf(x)];
    var gathered = 0.0;
    final threads = <(Offset, Offset, double)>[];
    for (final w in _windows) {
      // Önünden geçen ilk fener ışığını alır.
      var take = 0.0;
      Offset? to;
      for (final l in lamps) {
        final k = ((l.dx - w.dx + 80) / 110).clamp(0.0, 1.0);
        if (k > take) {
          take = k;
          to = l;
        }
      }
      gathered += take;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: w, width: 11, height: 14),
          const Radius.circular(5),
        ),
        Paint()
          ..color = const Color(0xFFFFD27A)
              .withValues(alpha: 0.95 * cityA * (1 - take)),
      );
      if (to != null && take > 0 && take < 1) threads.add((w, to, take));
    }

    // Duman perdeyi soldan örter; Kandilciler onun içinden çıkar.
    final smoke =
        PerdePainter._span(u, 1.15, 1.35) *
        (1 - PerdePainter._span(u, 1.7, 2.0));
    if (smoke > 0) {
      final puff = Paint()
        ..color = const Color(0xFF241008).withValues(alpha: 0.55 * smoke)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      for (var i = 0; i < 7; i++) {
        final drift = (time * 9 + i * 37) % 90;
        canvas.drawCircle(
          Offset(-20 + i * 34 + drift * 0.6, 300 - i * 26 - drift * 0.4),
          58 + (i % 3) * 14,
          puff,
        );
      }
    }

    // Kandilciler oyundaki gibi: koyu siluet, nane renkli fener ve gözler.
    final cold = Cartoon.danger;
    for (var i = 0; i < walkers.length; i++) {
      final x = walkers[i];
      final l = lamps[i];
      final glow = 0.35 + 0.45 * (gathered / _windows.length);
      canvas.drawCircle(
        l,
        80,
        Paint()
          ..shader = ui.Gradient.radial(l, 80, [
            cold.withValues(alpha: glow * cityA),
            cold.withValues(alpha: 0),
          ]),
      );
      canvas.save();
      canvas.translate(x, 330);
      canvas.scale(s);
      if (ShadowArt.ready) {
        drawShadowGuard(
          canvas,
          feet: Offset.zero,
          phase: (x / s / 26) % 1.0,
          weight: 1,
          run: 0,
          lean: 0,
          lampAngle: math.sin(time * 2 + x) * 0.15,
          doubt: 0,
          ink: PerdePainter._ink.withValues(alpha: cityA),
          rim: cold.withValues(alpha: 0.5 * cityA),
          eye: cold.withValues(alpha: 0.9 * cityA),
          lampGlass: cold.withValues(alpha: 0.95 * cityA),
        );
      }
      canvas.restore();
    }
    // Işık bir iplik gibi fenere akar (Kandilcinin önünden).
    for (final (w, to, take) in threads) {
      final mid = Offset.lerp(w, to, 0.5)! + const Offset(0, -46);
      for (var j = 0; j < 9; j++) {
        final q = (take * 1.6 - j * 0.07).clamp(0.0, 1.0);
        if (q <= 0 || q >= 1) continue;
        final pt = Offset.lerp(
          Offset.lerp(w, mid, q)!,
          Offset.lerp(mid, to, q)!,
          q,
        )!;
        canvas.drawCircle(
          pt,
          4.2 - j * 0.3,
          Paint()
            ..color = const Color(0xFFFFE2A0)
                .withValues(alpha: 0.9 * (1 - j / 9))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
        );
      }
    }
  }

  /// Yangın: damlardan yükselen alevler (dıştan kızıl, içten sarı; ışık
  /// geçen renkli deri gibi) ve üstlerinde kara duman sütunları.
  static void _burning(Canvas canvas, double time, double a) {
    if (a <= 0) return;
    const roofs = [
      (56.0, 232.0, 1.2),
      (134.0, 244.0, 1.0),
      (-10.0, 226.0, 0.9),
      (467.0, 240.0, 1.25),
      (531.0, 258.0, 0.8),
      (625.0, 200.0, 0.9),
      (762.0, 244.0, 1.1),
    ];
    final smoke = Paint()
      ..color = const Color(0xFF1E0A04).withValues(alpha: 0.38 * a)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    for (var i = 0; i < roofs.length; i++) {
      final (x, y, sz) = roofs[i];
      for (var j = 0; j < 4; j++) {
        final rise = (time * 14 + j * 38 + i * 17) % 150;
        canvas.drawCircle(
          Offset(
            x + math.sin(time * 0.7 + j + i) * 14 + rise * 0.25,
            y - 60 * sz - rise,
          ),
          (18 + rise * 0.22) * sz,
          smoke,
        );
      }
    }
    for (var i = 0; i < roofs.length; i++) {
      final (x, y, sz) = roofs[i];
      for (final (k, inner) in [(1.0, false), (0.55, true)]) {
        final h = (62 + 14 * math.sin(time * 7.3 + i * 2.1)) * sz * k;
        final w = 26 * sz * k;
        final f = math.sin(time * 9 + i * 1.3) * 7 * sz * k;
        final path = Path()
          ..moveTo(x - w, y + 6)
          ..quadraticBezierTo(
            x - w * 1.1,
            y - h * 0.45,
            x - w * 0.35 + f * 0.5,
            y - h * 0.6,
          )
          ..quadraticBezierTo(x - w * 0.2, y - h * 0.78, x + f, y - h)
          ..quadraticBezierTo(
            x + w * 0.35,
            y - h * 0.62,
            x + w * 0.45 + f * 0.3,
            y - h * 0.7,
          )
          ..quadraticBezierTo(x + w * 1.15, y - h * 0.4, x + w, y + 6)
          ..close();
        canvas.drawPath(
          path,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(x, y),
              Offset(x, y - h),
              inner
                  ? [
                      const Color(0xFFFFF0B0).withValues(alpha: 0.95 * a),
                      const Color(0xFFFFC24A).withValues(alpha: 0.85 * a),
                    ]
                  : [
                      const Color(0xFFFF9A2E).withValues(alpha: 0.9 * a),
                      const Color(0xFFC8321A).withValues(alpha: 0.8 * a),
                    ],
            ),
        );
      }
    }
  }

  /// Yanan İstanbul: büyük kubbeli cami ve minareleri, solda ve sağda
  /// cumbalı ahşap evler, uzakta ikinci bir cami.
  static void _istanbul(Canvas canvas, double a) {
    final ink = PerdePainter._inkPaint(a);
    const base = 330.0;
    // Uzaktaki cami (soluk).
    final far = PerdePainter._inkPaint(a * 0.55);
    canvas.drawRect(const Rect.fromLTRB(560, 262, 690, base), far);
    canvas.drawPath(
      Path()
        ..moveTo(572, 264)
        ..quadraticBezierTo(625, 196, 678, 264)
        ..close(),
      far,
    );
    canvas.drawRect(const Rect.fromLTRB(622, 196, 628, 206), far);
    for (final x in [548.0, 702.0]) {
      canvas.drawRect(Rect.fromLTRB(x - 4, 150, x + 4, base), far);
      canvas.drawPath(
        Path()
          ..moveTo(x - 5, 150)
          ..lineTo(x, 124)
          ..lineTo(x + 5, 150)
          ..close(),
        far,
      );
      canvas.drawRect(Rect.fromLTRB(x - 7, 196, x + 7, 201), far);
    }
    // Büyük cami: kasnaklı kubbe, yarım kubbeler, iki ince minare.
    canvas.drawRect(const Rect.fromLTRB(220, 250, 380, base), ink);
    canvas.drawPath(
      Path()
        ..moveTo(206, 262)
        ..quadraticBezierTo(234, 222, 262, 250)
        ..lineTo(338, 250)
        ..quadraticBezierTo(366, 222, 394, 262)
        ..close(),
      ink,
    );
    canvas.drawRect(const Rect.fromLTRB(246, 206, 354, 230), ink);
    canvas.drawPath(
      Path()
        ..moveTo(240, 210)
        ..quadraticBezierTo(300, 120, 360, 210)
        ..close(),
      ink,
    );
    canvas.drawRect(const Rect.fromLTRB(297, 132, 303, 148), ink);
    canvas.drawCircle(const Offset(300, 128), 4, ink);
    for (final x in [190.0, 410.0]) {
      canvas.drawRect(Rect.fromLTRB(x - 5, 96, x + 5, base), ink);
      canvas.drawPath(
        Path()
          ..moveTo(x - 6, 96)
          ..lineTo(x, 62)
          ..lineTo(x + 6, 96)
          ..close(),
        ink,
      );
      for (final y in [150.0, 210.0]) {
        canvas.drawRect(Rect.fromLTRB(x - 9, y, x + 9, y + 6), ink);
      }
    }
    // Cumbalı ahşap evler: üst kat taşar, çatısı kiremit.
    void house(double l, double r, double top) {
      canvas.drawRect(Rect.fromLTRB(l + 6, top + 30, r - 6, base), ink);
      canvas.drawRect(Rect.fromLTRB(l, top, r, top + 36), ink);
      canvas.drawPath(
        Path()
          ..moveTo(l - 8, top + 2)
          ..lineTo((l + r) / 2, top - 22)
          ..lineTo(r + 8, top + 2)
          ..close(),
        ink,
      );
    }

    house(22, 90, 250);
    house(104, 164, 262);
    house(432, 502, 258);
    house(-30, 10, 244);
    house(514, 548, 272);
    house(724, 800, 262);
  }

  /// 3 · Ustanın kapısı: perdede yine Karagöz ile Hacivat. Kandilcilerin
  /// gölgeleri iki yandan perdeye düşer (önce büyük ve soluk, yaklaştıkça
  /// koyulaşır); çocuklar kaçışır. Usta ayağa kalkar; bir Kandilci kandilin
  /// ışığını fenerine çeker, öbürü ustayı zincirle sürükler. Tasvirler
  /// düşer; Hacivat son sözünü söyleyip ardından düşer.
  static void scene3(Canvas canvas, double time, double u) {
    double span(double a, double b) => PerdePainter._span(u, a, b);
    final ease = PerdePainter._ease;
    const g = PerdePainter._ground;
    const lampAt = Offset(390, 372);
    final back = span(2.0, 2.1);
    final take = span(2.46, 2.6);

    // Kandilin ılık ışığı geri gelir; ışığı Kandilcinin fenerine akınca
    // perde soğur.
    final warm = back * (1 - take);
    if (warm > 0) {
      canvas.drawCircle(
        lampAt,
        210,
        Paint()
          ..shader = ui.Gradient.radial(lampAt, 210, [
            const Color(0xFFFFF1C8).withValues(alpha: 0.55 * warm),
            const Color(0x00FFF1C8),
          ]),
      );
    }

    // Kandilciler: kandili alan sağdan, ustayı götüren soldan gelir;
    // ikisi de sola çıkar, sağda Sâye ile kavanoz kalır. Kandile
    // yaklaştıkça gölgeleri küçülüp koyulaşır.
    final in1 = ease(span(2.1, 2.42));
    final in2 = ease(span(2.16, 2.46));
    final out1 = ease(span(2.66, 3.0));
    final drag = ease(span(2.62, 2.98));
    final k1 = 1040 - 400 * in1 - 960 * out1;
    final k2 = -260 + 420 * in2 - 580 * drag;
    final s1 = 7.2 - 1.8 * in1;
    final s2 = 7.2 - 1.8 * in2;
    final a1 = 0.35 + 0.65 * in1;
    final a2 = 0.35 + 0.65 * in2;
    final glow = 0.3 + 0.6 * take;
    final lantern1 = _guardShadow(
      canvas,
      time,
      k1,
      440,
      s1,
      faceLeft: true,
      a: a1,
      glow: glow,
    );
    _guardShadow(
      canvas,
      time,
      k2,
      440,
      s2,
      faceLeft: u > 2.6,
      a: a2,
      glow: 0.3,
    );

    // Usta perdenin ardında ayağa kalkar, soldaki Kandilciye döner.
    // Zincirle sola sürüklenirken geriye yaslanır, başını çevirip son kez
    // perdesine, çubuğundaki Sâye'ye bakar: "Sâye… Işığı bul, kızım."
    final rise = ease(span(2.3, 2.42));
    final dragged = u > 2.6;
    final mx = math.min(388.0, k2 + 230);
    final my = 560 - 130 * rise;
    if (rise > 0) {
      PerdePainter._c = canvas;
      canvas.save();
      canvas.translate(mx, my);
      canvas.rotate(0.14 * span(2.6, 2.68));
      canvas.translate(-mx, -my);
      // Oymasız: deliklerin ışığı düğme gibi görünmesin.
      canvas.translate(mx, my + math.sin(time * 1.7 + 2.9) * 1.2);
      canvas.scale(dragged ? 1.35 : -1.35, 1.35);
      PerdePainter.drawMaster(canvas, PerdePainter._inkPaint(rise));
      canvas.restore();
      // Zincir: ustanın arkada bağlı ellerinden Kandilcinin eline.
      final chain = span(2.56, 2.62);
      if (chain > 0) {
        final from = Offset(mx - 40, my - 80);
        final to = Offset(k2 + 34, 440 - 150);
        final mid = Offset.lerp(from, to, 0.5)! + const Offset(0, 16);
        final links = PerdePainter._inkPaint(chain)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4;
        for (var i = 0; i <= 12; i++) {
          final t = i / 12;
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.lerp(
                Offset.lerp(from, mid, t)!,
                Offset.lerp(mid, to, t)!,
                t,
              )!,
              width: 10,
              height: 6,
            ),
            links,
          );
        }
      }
    }

    // Karagöz ile Hacivat ustanın elinde titrer; usta götürülünce Karagöz
    // düşer. Hacivat son sözünü söyler ("Yıktın perdeyi…"), sonra o da.
    final hImg = TasvirImages.hacivat;
    final kImg = TasvirImages.karagoz;
    if (hImg != null && kImg != null && back > 0) {
      const h = 232.0;
      const base = Offset(390, g + 6);
      final shake = span(2.14, 2.4) * math.sin(time * 21) * 0.03;
      final kFall = ease(span(2.62, 2.8));
      final hDroop = span(2.62, 2.74);
      // Önce ustanın fısıltısı, ardından Hacivat'ın son sözü.
      final hFall = ease(span(2.98, 3.12));
      final speak = u > 2.82 && u < 2.98
          ? -(math.sin(time * 7)).abs() * 2.5
          : 0.0;
      final hFeet =
          base + Offset(-0.45 * h - 20 * hFall, speak + 280 * hFall * hFall);
      final kFeet = base + Offset(0.4 * h + 30 * kFall, 280 * kFall * kFall);
      final hRot = shake + 0.1 * hDroop - 1.2 * hFall;
      final kRot = -shake + 1.3 * kFall;
      TasvirImages.draw(
        canvas,
        hImg,
        hFeet,
        h * 1.08,
        naturalLeft: false,
        faceLeft: false,
        rot: hRot,
        a: back,
      );
      TasvirImages.draw(
        canvas,
        kImg,
        kFeet,
        h * 1.04,
        naturalLeft: true,
        faceLeft: true,
        rot: kRot,
        a: back,
      );
      // Çubukların gölgesi: usta bırakınca çubuk tasvirle birlikte düşer.
      Offset chest(Offset feet, double rot, double up) =>
          feet + Offset(math.sin(rot) * up, -math.cos(rot) * up);
      final hc = chest(hFeet, hRot, h * 0.62);
      final kc = chest(kFeet, kRot, h * 0.6);
      TasvirImages.rod(
        canvas,
        hc,
        hc + Offset(-h * 0.22, h * 1.1),
        h * 0.022,
        back,
      );
      TasvirImages.rod(
        canvas,
        kc,
        kc + Offset(h * 0.22, h * 1.1),
        h * 0.022,
        back,
      );
    }
    // Kandilin ışığı bir iplik gibi Kandilcinin fenerine akar (tasvirlerin
    // önünden, görünsün).
    if (take > 0 && take < 1) {
      final mid = Offset.lerp(lampAt, lantern1, 0.5)! + const Offset(0, -60);
      for (var j = 0; j < 12; j++) {
        final q = (take * 1.5 - j * 0.045).clamp(0.0, 1.0);
        if (q <= 0 || q >= 1) continue;
        canvas.drawCircle(
          Offset.lerp(
            Offset.lerp(lampAt, mid, q)!,
            Offset.lerp(mid, lantern1, q)!,
            q,
          )!,
          6 - j * 0.35,
          Paint()
            ..color = const Color(0xFFFFE2A0).withValues(alpha: 1 - j / 12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
    }
  }

  /// Perdenin kararmasının üstünde çizilenler: ustanın kavanozu ve
  /// ateşböcekleri, onların aydınlattığı.
  static void glow(Canvas canvas, double time, double u) {
    if (u < 3.04) {
      final fear = u < 2 ? 0.0 : PerdePainter._span(_d3(u), 2.14, 2.4);
      final swing =
          math.sin(time * 1.1) * 0.05 + math.sin(time * 17) * 0.1 * fear;
      _hangingJar(
        canvas,
        time,
        swing,
        PerdePainter._span(u, 0.16, 0.3) * _booth(u),
      );
    }
    if (u >= 3 && u < 4.1) scene4(canvas, time, u);
    if (u >= 4 && u < 5.05) scene5(canvas, time, u);
    if (u >= 5) scene6(canvas, time, u);
  }

  /// Oyunun adı (anlatım, dile göre atar).
  static String title = 'GÖLGE OYUNU';

  /// Başlığın yazı tipi: Rakkas (Zeynep Akay, SIL OFL; hat kaleminden
  /// esinli, gölge oyununun dünyasına uyar). null: sistemin kalın yazısı.
  static String? titleFont = 'Rakkas';

  /// 5 · Başlık: karanlıkta, Sâye'nin düştüğü yerden ateşböcekleri yükselir;
  /// oyunun adının üstünden geçtikçe harfler soldan sağa ışır (oyma
  /// deliklerden geçen ışık gibi). Bir an ad üstünde dolaşırlar, sonra
  /// Sâye'nin peşinden aşağı dalarlar.
  static void scene5(Canvas canvas, double time, double u) {
    double span(double a, double b) => PerdePainter._span(u, a, b);
    final ease = PerdePainter._ease;
    final out = 1 - span(4.86, 5.0);
    final p = ease(span(4.22, 4.72));
    var size = 46.0;
    TextPainter text(Paint paint) => TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          fontFamily: titleFont ?? PerdePainter.debugFontFamily,
          fontSize: size,
          fontWeight: titleFont == null ? FontWeight.w900 : FontWeight.normal,
          letterSpacing: size * (titleFont == null ? 0.2 : 0.08),
          foreground: paint,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    const cy = 175.0;
    // Işığın önü: harfler bu çizginin solunda yanar.
    var probe = text(Paint());
    // Yazı tipi ne olursa olsun ad perdenin ortasında aynı enle durur.
    size *= 470 / probe.width;
    probe = text(Paint());
    final w = probe.width;
    final origin = Offset(390 - w / 2, cy - probe.height / 2);
    final front = -30 + p * (w + 60);
    if (p > 0 && out > 0) {
      Shader lit(Color c) => ui.Gradient.linear(
        Offset(front - 40, 0),
        Offset(front, 0),
        [c.withValues(alpha: c.a * out), c.withValues(alpha: 0)],
      );
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      // Hale, sonra harfler.
      text(
        Paint()
          ..shader = lit(const Color(0xCCFFB24A))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      ).paint(canvas, Offset.zero);
      text(Paint()..shader = lit(const Color(0xFFFFD98A)))
          .paint(canvas, Offset.zero);
      canvas.restore();
    }

    for (var i = 0; i < 5; i++) {
      final rise = ease(span(4.02 + i * 0.03, 4.22 + i * 0.03));
      if (rise <= 0) continue;
      final start = Offset(372 + i * 14, 430);
      final lead = Offset(
        origin.dx + front + (i - 2) * 22 + math.sin(time * 3 + i) * 10,
        cy + math.sin(time * 2.6 + i * 1.7) * 34,
      );
      final settle = Offset(
        origin.dx + (i + 0.5) / 5 * w + math.sin(time * 1.8 + i) * 8,
        cy - 56 + math.sin(time * 2.2 + i * 1.3) * 10,
      );
      final dive = Offset(390 + (i - 2) * 30, 450);
      var at = Offset.lerp(start, lead, rise)!;
      at = Offset.lerp(at, settle, ease(span(4.68, 4.8)))!;
      at = Offset.lerp(at, dive, ease(span(4.86, 5.0)))!;
      _firefly(canvas, at, 1, time, i);
    }
  }

  /// Kavanozun asıldığı çivi ve ip boyu.
  static const _jarHook = Offset(716, -6);
  static const _jarString = 80.0;

  /// Kavanozun büyüklüğü (oyundaki çizimin katı).
  static const _jarScale = 3.4;

  /// Ustanın kavanozu: Sâye'nin yanında, perdenin kenarında bir ipte asılı;
  /// içinde ateşböcekleri.
  static void _hangingJar(Canvas canvas, double time, double swing, double a) {
    if (a <= 0) return;
    final c =
        _jarHook +
        Offset(math.sin(swing), math.cos(swing)) * _jarString +
        const Offset(0, 7.2 * _jarScale);
    canvas.drawLine(
      _jarHook,
      c + Offset(0, -6.6 * _jarScale),
      Paint()
        ..color = PerdePainter._ink.withValues(alpha: 0.85 * a)
        ..strokeWidth = 1.6,
    );
    _jar(canvas, c, -swing, 1, time, a);
  }

  /// Oyundaki kavanoz (Player._drawJar) [_jarScale] kat büyük: yuvarlak
  /// köşeli cam, kapak ve ip kulp; içinde [light] kadar ateşböceği ışığı.
  static void _jar(
    Canvas canvas,
    Offset c,
    double rot,
    double light,
    double time,
    double a,
  ) {
    const k = _jarScale;
    const jarLight = Color(0xFFFFC46B);
    if (light > 0.05) {
      canvas.drawCircle(
        c,
        60,
        Paint()
          ..shader = ui.Gradient.radial(c, 60, [
            jarLight.withValues(alpha: 0.45 * light * a),
            jarLight.withValues(alpha: 0),
          ]),
      );
    }
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rot);
    canvas.scale(k);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 6.4, height: 7.6),
      const Radius.circular(2.2),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..color = Color.lerp(
          kInk,
          jarLight,
          0.15 + 0.75 * light,
        )!.withValues(alpha: a),
    );
    if (light > 0.2) {
      final fly = Paint()
        ..color = const Color(0xFFFFF6D8).withValues(alpha: light * a);
      for (var i = 0; i < 3; i++) {
        final t = time * (1.6 + i * 0.7) + i * 2.1;
        canvas.drawCircle(
          Offset(math.sin(t) * 1.8, math.cos(t * 1.3) * 2.2),
          0.5,
          fly,
        );
      }
    }
    canvas.drawRRect(
      body,
      Paint()
        ..color = kInk.withValues(alpha: 0.8 * a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
    canvas.drawLine(
      const Offset(-1.9, -2.3),
      const Offset(-1.9, 1.4),
      Paint()
        ..color = const Color(0xFFFFF8E8)
            .withValues(alpha: (0.25 + 0.35 * light) * a)
        ..strokeWidth = 0.5
        ..strokeCap = StrokeCap.round,
    );
    final ink = Paint()..color = kInk.withValues(alpha: a);
    canvas.drawRect(
      Rect.fromCenter(center: const Offset(0, -4.4), width: 5.4, height: 1.8),
      ink,
    );
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(0, -5.4), width: 4.4, height: 3.6),
      math.pi,
      math.pi,
      false,
      ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
    canvas.restore();
  }

  /// Ateşböceği: oyundaki renkleriyle, çevresini ısıtan bir ışık halkası.
  static void _firefly(Canvas canvas, Offset at, double a, double time, int i) {
    final blink = 0.75 + 0.25 * math.sin(time * 5 + i * 2.1);
    canvas.drawCircle(
      at,
      78,
      Paint()
        ..shader = ui.Gradient.radial(at, 78, [
          const Color(0xFFFFC46B).withValues(alpha: 0.42 * a * blink),
          const Color(0x00FFC46B),
        ]),
    );
    canvas.drawCircle(
      at,
      10,
      Paint()
        ..color = const Color(0xFFFFC46B).withValues(alpha: 0.75 * a * blink)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      at,
      3.6,
      Paint()..color = const Color(0xFFFFF2C8).withValues(alpha: a * blink),
    );
  }

  /// 4 · Sâye düşer: neredeyse karanlık. Ustanın kavanozu ipinden kopar,
  /// devrilerek düşer; ağzından ateşböcekleri saçılır. Kandilin son
  /// ışığında Sâye çubuğundan ayrılır, yaprak gibi süzülerek perdenin altına
  /// düşer; ateşböcekleri onun çevresinde aşağı iner. Kavanoz da onunla
  /// birlikte düşer (6. sahnede Sâye onu yanı başında bulur).
  static void scene4(Canvas canvas, double time, double u) {
    double span(double a, double b) => PerdePainter._span(u, a, b);
    final ease = PerdePainter._ease;
    final out = 1 - span(3.95, 4.08);

    // Kavanoz: ip kopar, devrilerek düşer.
    final jf = span(3.04, 3.72);
    const jar0 = Offset(716, -6 + 80 + 7.2 * _jarScale);
    final jarAt = jar0 + Offset(-230 * jf, 340 * jf * jf);
    final jarRot = -2.4 * ease(math.min(1, jf * 2.2)) - 1.2 * jf;
    // Kopan ipin ucu bir an sallanır.
    final snap = 1 - span(3.04, 3.2);
    if (snap > 0) {
      final end = _jarHook + Offset(math.sin(time * 9) * 10 * snap, 120);
      canvas.drawLine(
        _jarHook,
        end,
        Paint()
          ..color = PerdePainter._ink.withValues(alpha: 0.85 * snap)
          ..strokeWidth = 1.6,
      );
    }
    // Ağız kavanozla birlikte döner.
    final mouth =
        jarAt + Offset(math.sin(jarRot), -math.cos(jarRot)) * (4.6 * _jarScale);

    final fall = ease(span(3.14, 3.94));
    final sway = math.sin(fall * math.pi * 3);
    final saye = Offset(
      742 - 330 * fall + sway * 34,
      300 + 180 * math.pow(fall, 1.6).toDouble(),
    );
    final sayeRot = sway * 0.45 + fall * 0.5;

    // Ateşböcekleri birer birer kavanozun ağzından saçılır, Sâye'nin
    // çevresinde döner, onunla birlikte iner.
    final flies = <Offset>[];
    var spilled = 0.0;
    for (var i = 0; i < 5; i++) {
      final at0 = 3.1 + i * 0.05;
      if (u < at0) continue;
      spilled += 0.2;
      final go = ease(span(at0, at0 + 0.24));
      final orbit = Offset(
        math.cos(time * 1.7 + i * 1.26) * (26 + i * 5),
        -40 + math.sin(time * 2.3 + i * 1.26) * (18 + i * 3),
      );
      // Önce ağızdan dışarı fırlar, sonra Sâye'ye döner.
      final burst =
          mouth + Offset(math.cos(i * 1.9) * 40, -30 + math.sin(i * 1.9) * 24);
      final p = Offset.lerp(
        Offset.lerp(mouth, burst, go)!,
        Offset.lerp(burst, saye + orbit, go)!,
        go,
      )!;
      flies.add(p);
    }

    if (jarAt.dy < 520) {
      _jar(canvas, jarAt, jarRot, 1 - 0.8 * spilled, time, out);
    }
    // Sâye'nin çubuğu: Sâye ayrılınca karanlıkta kalır.
    final rodA = 1 - span(3.3, 3.6);
    if (rodA > 0) {
      const feet = Offset(742, 300);
      TasvirImages.rod(
        canvas,
        feet + const Offset(2, -52),
        feet + const Offset(30, 120),
        3.6,
        0.6 * rodA,
      );
    }
    for (var i = 0; i < flies.length; i++) {
      _firefly(canvas, flies[i], out, time, i);
    }
    // Sâye: ateşböceklerinin ışığına karşı koyu bir siluet. Çubuktan
    // kopunca havada (oyundaki düşüş hâli): kolları açılır, çırpınır,
    // örgüleri ve atkısı savrulur.
    if (saye.dy < 520) {
      final falling = u >= 3.14;
      _sayeTasvir(
        canvas,
        saye,
        time,
        rot: sayeRot,
        a: out,
        mode: falling ? KuklaMode.air : null,
        vy: 1300 + 700 * math.sin(time * 5.3),
      );
    }
  }

  /// Perdedeki Sâye tasviri (sola bakar, boyu ~100, kavanozsuz): yeni
  /// Sâye kuklası; yüklenmemişse eski resim. Çizilemezse false.
  static bool _sayeTasvir(
    Canvas canvas,
    Offset feet,
    double time, {
    double rot = 0,
    double a = 1,
    KuklaMode? mode,
    double vy = 0,
  }) {
    if (PerdeSaye.ready) {
      PerdeSaye.draw(
        canvas,
        feet,
        100 / 36,
        time,
        mode: mode,
        vy: vy,
        jar: 0,
        faceLeft: true,
        rot: rot,
        a: a,
      );
      return true;
    }
    final img = TasvirImages.saye;
    if (img == null) return false;
    TasvirImages.draw(
      canvas,
      img,
      feet,
      100,
      naturalLeft: false,
      faceLeft: true,
      rot: rot,
      a: a,
    );
    return true;
  }

  /// Sarnıcın suyu.
  static const _water = 330.0;

  /// Sâye'nin sudan çıktığı taş set.
  static const _ledge = Rect.fromLTRB(440, _water - 8, 660, _water + 14);

  /// Perdedeki Sâye karelerinin ölçeği (oyundaki Sâye'yle aynı boy).
  static const _sayeK = 0.36;

  /// Yerebatan: sudan yükselen sütun ormanı ve kemerler (arka sıra soluk,
  /// ön sıra koyu); gövdesi gözyaşı oymalı, hep ıslak Ağlayan Sütun. Tavandan
  /// su damlar. Medusa başı ışık katmanında ([_medusa]).
  static void _cistern(Canvas canvas, double time, double a, double u) {
    if (a <= 0) return;
    for (var row = 0; row < 2; row++) {
      final back = row == 0;
      // Uzaktaki Kandilci iki sıranın arasından geçer.
      if (!back) {
        // Arka sıranın dibinde uzak bir taş yol: Kandilci oradan geçer.
        canvas.drawRect(
          const Rect.fromLTWH(0, _water - 30, 780, 4),
          PerdePainter._inkPaint(a * 0.4),
        );
        _farGuard(canvas, time, u, glow: false);
      }
      final spacing = back ? 74.0 : 150.0;
      final colW = back ? 14.0 : 26.0;
      final top = back ? 70.0 : 14.0;
      final ink = PerdePainter._inkPaint(a * (back ? 0.4 : 0.95));
      for (var x = back ? 20.0 : 30.0; x < 820; x += spacing) {
        // Ön sırada Sâye'nin düştüğü yer ve set açık kalır.
        if (!back && x > 300 && x < 520) continue;
        canvas.drawRect(
          Rect.fromLTWH(x - colW / 2, top, colW, _water - top),
          ink,
        );
        canvas.drawRect(
          Rect.fromLTWH(x - colW * 0.9, top, colW * 1.8, back ? 6 : 12),
          ink,
        );
        canvas.drawPath(
          Path()
            ..moveTo(x + colW * 0.9, top)
            ..quadraticBezierTo(
              x + spacing / 2,
              top + (back ? 26 : 46),
              x + spacing - colW * 0.9,
              top,
            )
            ..lineTo(x + spacing - colW * 0.9, top - 12)
            ..lineTo(x + colW * 0.9, top - 12)
            ..close(),
          ink,
        );
        if (!back) {
          // Sudaki yansıma kırık kırık titrer.
          for (var k = 0; k < 6; k++) {
            final off = math.sin(time * 2 + k + x * 0.05) * 3;
            canvas.drawRect(
              Rect.fromLTWH(x - colW / 2 + off, _water + 6 + k * 8.0, colW, 4),
              PerdePainter._inkPaint(a * 0.35 * (1 - k / 6)),
            );
          }
        }
      }
    }
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 780, 10),
      PerdePainter._inkPaint(a),
    );
    // Ağlayan Sütun: gövdesinde gözyaşı oymaları; bir damla hep süzülür.
    const weep = 630.0;
    final tear = PerdePainter._holePaint(0.32 * a);
    for (var y = 44.0, row = 0; y < _water - 16; y += 22, row++) {
      for (final k in const [-1.0, 1.0]) {
        final c = Offset(weep + k * 6 + (row.isOdd ? 3 : -3), y);
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy - 6)
            ..quadraticBezierTo(c.dx + 4, c.dy + 1, c.dx, c.dy + 4)
            ..quadraticBezierTo(c.dx - 4, c.dy + 1, c.dx, c.dy - 6)
            ..close(),
          tear,
        );
      }
    }
    final slide = (time * 0.18) % 1.0;
    canvas.drawCircle(
      Offset(weep - 9, 30 + slide * (_water - 30)),
      1.8,
      PerdePainter._holePaint(0.55 * a),
    );
    // Taş set.
    canvas.drawRRect(
      RRect.fromRectAndRadius(_ledge, const Radius.circular(4)),
      PerdePainter._inkPaint(a),
    );
    // Su yüzü: ince ışık çizgileri.
    final glint = PerdePainter._holePaint(0.3 * a)..strokeWidth = 1.4;
    for (var i = 0; i < 16; i++) {
      final x = (i * 53.0 + time * 10) % 800 - 10;
      if (x > _ledge.left - 10 && x < _ledge.right) continue;
      final y = _water + 3 + (i % 3) * 6;
      canvas.drawLine(Offset(x, y), Offset(x + 18, y), glint);
    }
    // Damla: tavandan düşer, suda halka açar.
    for (var i = 0; i < 2; i++) {
      final x = i == 0 ? 106.0 : 760.0;
      final t = (time * 0.45 + i * 0.5) % 1.0;
      if (t < 0.5) {
        canvas.drawCircle(
          Offset(x, 14 + (t / 0.5) * (_water - 14)),
          2,
          PerdePainter._holePaint(0.6 * a),
        );
      } else {
        final r = (t - 0.5) / 0.5 * 40;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, _water + 2),
            width: r * 2,
            height: r * 0.35,
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = PerdePainter._hole.withValues(
              alpha: 0.5 * a * (1 - r / 40),
            ),
        );
      }
    }
  }

  /// 7 · Uzakta, sütunların arasından bir Kandilci geçer (soldan sağa;
  /// küçük ve soluk). Fenerinin yerini döndürür; [glow] ise yalnız
  /// fenerin ışığını çizer (karanlığın üstünde).
  static Offset? _farGuard(
    Canvas canvas,
    double time,
    double u, {
    required bool glow,
  }) {
    final k = (_secs7(u) - 0.1) / 4.2;
    if (k <= 0 || k >= 1) return null;
    final x = -60 + k * 900;
    // Uzakta: arka sıradaki yolda, küçük ve soluk.
    const y = _water - 30;
    const sc = 1.15;
    final phase = (x / sc / 26) % 1.0;
    final swing = math.sin(time * 2) * 0.15;
    final art = guardLampArt(phase, 1, 0, 0, swing);
    final lantern = Offset(x, y) + (art - guardArtFeet) * (guardArtScale * sc);
    final cold = Cartoon.danger;
    if (glow) {
      canvas.drawCircle(
        lantern,
        44,
        Paint()
          ..shader = ui.Gradient.radial(lantern, 44, [
            cold.withValues(alpha: 0.3),
            cold.withValues(alpha: 0),
          ]),
      );
      canvas.drawCircle(lantern, 2.4, Paint()..color = cold);
      return lantern;
    }
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(sc);
    if (ShadowArt.ready) {
      drawShadowGuard(
        canvas,
        feet: Offset.zero,
        phase: phase,
        weight: 1,
        run: 0,
        lean: 0,
        lampAngle: swing,
        doubt: 0,
        ink: PerdePainter._ink.withValues(alpha: 0.55),
        rim: cold.withValues(alpha: 0.3),
        eye: cold.withValues(alpha: 0.9),
        lampGlass: cold,
      );
    }
    canvas.restore();
    return lantern;
  }

  /// Medusa başı: setin ucunda, sütunun dibinde yan yatmış, yarısı suda
  /// (Yerebatan'daki gibi); ateşböceklerinin ve fidanın ışığında seçilir.
  static void _medusa(Canvas canvas, double a) {
    final img = TasvirImages.medusa;
    if (img == null || a <= 0) return;
    // Suyun üstündeki yarısı; altı suda kaybolur, yüzeyde soluk yansıması.
    for (final reflect in [false, true]) {
      canvas.save();
      if (reflect) {
        canvas.clipRect(const Rect.fromLTRB(0, _water + 3, 780, _water + 40));
        canvas.translate(0, 2 * _water + 6);
        canvas.scale(1, -1);
      } else {
        canvas.clipRect(const Rect.fromLTRB(0, 0, 780, _water + 3));
      }
      TasvirImages.draw(
        canvas,
        img,
        const Offset(770, _water - 18),
        104,
        naturalLeft: false,
        faceLeft: false,
        rot: -math.pi / 2,
        a: (reflect ? 0.22 : 0.85) * a,
      );
      canvas.restore();
    }
  }

  /// Suya düşen bir şeyin sıçraması: halkalar ve havaya savrulup geri düşen
  /// damlalar (ateşböceklerinin ışığını yakalar). [since] saniye.
  static void _splash(Canvas canvas, Offset at, double since, double size) {
    if (since < 0 || since > 1.8) return;
    final fade = 1 - since / 1.8;
    for (var k = 0; k < 3; k++) {
      final r = (since * 70 + k * 16) * size;
      canvas.drawOval(
        Rect.fromCenter(center: at, width: r * 2, height: r * 0.32),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xFFFFE6B0)
              .withValues(alpha: fade * (k == 0 ? 0.7 : 0.4)),
      );
    }
    // Sıçrayan su: kısa bir taç.
    if (since < 0.3) {
      final k = since / 0.3;
      canvas.drawOval(
        Rect.fromCenter(
          center: at + Offset(0, -30 * size * math.sin(k * math.pi)),
          width: 14 * size,
          height: 60 * size * math.sin(k * math.pi),
        ),
        Paint()
          ..color = const Color(0xFFFFE6B0).withValues(alpha: 0.5 * (1 - k))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    final drop = Paint()
      ..color = const Color(0xFFFFE6B0).withValues(alpha: 0.85);
    for (var i = 0; i < 14; i++) {
      final ang = -math.pi / 2 + (i / 13 - 0.5) * 2.0;
      final v = (230 + (i * 37) % 110) * size;
      final p =
          at +
          Offset(
            math.cos(ang) * v * since,
            math.sin(ang) * v * since + 550 * since * since,
          );
      if (p.dy > _water + 2) continue;
      canvas.drawCircle(p, 2.2 * size, drop);
    }
  }

  /// 6 · Yerebatan: karanlıkta Sâye ile kavanoz yukarıdan düşer, ateşböcekleri
  /// peşlerinde. Su sıçrar; sütunlar, Medusa başı ve Ağlayan Sütun bir an
  /// seçilir. Sâye suyun altında kaybolur, ateşböcekleri halkaların üstünde
  /// onu arar. Setin dibinde çıkar, tutunup sete tırmanır, sendeler. Yanı
  /// başında Umay'ın kayın fidanı filizlenir; ateşböcekleri dibine sığınır.
  /// Sâye suda yüzen ustanın kavanozunu çekip alır, ateşböcekleri birer birer
  /// içine girer, kavanoz parlar: kavanoz ancak burada onun olur.
  static void scene6(Canvas canvas, double time, double u) {
    final ease = PerdePainter._ease;
    final w = _secs(u, 5); // sahnenin saniyesi
    double spw(double a, double b) => ((w - a) / (b - a)).clamp(0.0, 1.0);
    const gravity = 1100.0;
    // Sâye setten uzağa düşer: sete kadar yüzecek yolu olsun. Boş kavanoz
    // ondan önce, onun da soluna düşer (yüzerken yoluna çıkmaz).
    const fallX = 200.0;
    const jarX = 120.0;
    const top = -90.0;
    const t0 = 0.25;
    final tHit = math.sqrt(2 * (_water + 4 - top) / gravity);
    final hit = t0 + tHit;
    const jarDelay = -0.25;
    final jarHit =
        t0 + jarDelay + math.sqrt(2 * (_water - 4 - top - 30) / gravity);
    const tree = Offset(624, _water - 8);
    // Sudaki bölüm: suyun altı, yüzüş (üç kulaç), kenara uzanış, çıkış.
    final sw0 = hit + 0.45;
    final sw1 = sw0 + 1.7;
    final g1 = sw1 + 0.3;
    final c1 = g1 + 1.1;
    // Sonraki her şey (sendeleme, fidan, kavanoz) setin üstünde başlar:
    // eski zamanlamayla aynı sırada, sudaki bölüm kadar sonra.
    final d = _wetShift;
    final s = w <= 2.5 ? w : (w < 2.5 + d ? 2.5 : w - d);
    double sp(double a, double b) => ((s - a) / (b - a)).clamp(0.0, 1.0);

    _medusa(canvas, spw(1.1, 1.5));
    _splash(canvas, Offset(fallX + 18, _water + 2), w - hit, 1.2);
    _splash(canvas, const Offset(jarX + 6, _water + 2), w - jarHit, 0.6);

    // Sâye: düşüş, suyun altı, yüzüş, kenara tutunup çıkış (kuklanın oyundaki
    // hâlleriyle), sendeleme, kavanoz.
    var feet = Offset.zero;
    var frame = 'comel';
    var rot = 0.0;
    var faceLeft = false;
    var hidden = false;
    // 1: suyun altında (soluk), 2: yalnız suyun üstü, 3: üstü tam, altı soluk
    var clip = 0;
    KuklaMode? mode;
    var vy = 0.0;
    var grip = Offset.zero;
    var climb = 0.0;
    double? stroke;
    final edge = Offset(_ledge.left + 22, _ledge.top);
    final corner = Offset(_ledge.left, _ledge.top);
    // Kenara asılıyken ayak noktası: eller köşede, beden suyun içinde.
    final hangFeet = corner + const Offset(-10, 64);
    final fallEnd = Offset(fallX + tHit * 22, _water + 4);
    const swimY = _water + 62.0;
    final swimFrom = fallEnd + const Offset(10, 58);
    final swimTo = Offset(_ledge.left - 95, swimY);
    if (w < hit) {
      // Düşüş: kollar yukarıda, atkı ve örgüler savrulur, yavaşça döner.
      final tf = math.max(0.0, w - t0);
      feet = Offset(fallX + tf * 22, top + 0.5 * gravity * tf * tf);
      rot = tf * 1.6;
      mode = KuklaMode.air;
      vy = gravity * tf;
      frame = 'dur';
      hidden = w < t0;
    } else if (w < sw0) {
      // Suyun altında: batar, sonra yüzeye doğru döner.
      final k = ease(spw(hit, sw0));
      feet =
          Offset.lerp(fallEnd, swimFrom, k)! +
          Offset(0, 34 * math.sin(k * math.pi));
      rot = tHit * 1.6 + (0.75 - tHit * 1.6) * k;
      mode = KuklaMode.swim;
      stroke = 0;
      frame = 'dur';
      clip = 1;
    } else if (w < sw1) {
      // Yüzüş: başı suyun üstünde, üç kulaç; her kulaçta öne süzülür.
      final k = spw(sw0, sw1);
      const n = 3.0;
      final p = k - math.sin(2 * math.pi * n * k) / (2 * math.pi * n);
      feet =
          Offset.lerp(swimFrom, swimTo, p)! + Offset(0, math.sin(w * 4) * 1.5);
      rot = 0.75 + 0.05 * math.sin(2 * math.pi * n * k);
      mode = KuklaMode.swim;
      stroke = n * k;
      frame = 'dur';
      clip = 3;
    } else if (w < g1) {
      // Kenara uzanır: gövde doğrulur, elleri setin kenarını kavrar.
      // Yüzüş hâlinde kalır (başı yerinde, kolları öne uzanır); tutunuş
      // çıkışla başlar, yoksa beden bir an suya batıyordu.
      final k = ease(spw(sw1, g1));
      feet = Offset.lerp(swimTo, hangFeet, k)!;
      rot = 0.75 * (1 - k);
      mode = KuklaMode.swim;
      stroke = 3 + 0.25 * k;
      frame = 'dur';
      clip = 3;
    } else if (w < c1) {
      // Çıkış (oyundaki gibi): kollarla çekinir, dizini sete atar, üstüne
      // geçer; önce yükselir, sonra öne kayar.
      final t = spw(g1, c1);
      final v = 1 - math.pow(1 - (t / 0.65).clamp(0.0, 1.0), 2.2).toDouble();
      final hx = ease(((t - 0.45) / 0.55).clamp(0.0, 1.0));
      feet = Offset(
        hangFeet.dx + (edge.dx - hangFeet.dx) * hx,
        hangFeet.dy + (edge.dy - hangFeet.dy) * v,
      );
      mode = KuklaMode.climbUp;
      climb = t;
      grip = corner - feet;
      frame = 'dur';
      clip = 3;
    } else {
      feet = edge;
      frame = 'dur';
      // Sendeler, sonra fidan filizlenince ürker.
      rot = math.sin(s * 9) * 0.08 * (1 - sp(3.35, 3.9));
      final startle = sp(3.9, 4.05) * (1 - sp(4.25, 4.5));
      if (startle > 0) {
        frame = 'comel';
        feet += Offset(-8 * startle, 0);
      }
    }
    // Kavanozu almak: setin ucunda çömelir, sola uzanır.
    final reach = sp(4.6, 4.9);
    final hold = sp(4.9, 5.1);
    if (s >= 4.6) {
      faceLeft = true;
      frame = s < 5.15 ? 'comel' : 'dur';
    }
    final hand =
        feet + Offset(faceLeft ? -14 : 14, frame == 'comel' ? -12 : -19);

    // Kavanoz: düşer, suda yüzer, sete doğru sürüklenir; Sâye çeker alır.
    Offset jarAt;
    var jarRot = 0.0;
    final js = s - t0 - jarDelay;
    if (s < jarHit) {
      final tf = math.max(0.0, js);
      jarAt = Offset(jarX + tf * 8, top + 30 + 0.5 * gravity * tf * tf);
      jarRot = tf * -5;
    } else {
      // Suda yavaşça sete sürüklenir, Sâye'nin ardında kalır.
      final drift = ease(spw(jarHit, 4.6 + d));
      jarAt = Offset(
        jarX + 6 + (_ledge.left - 12 - jarX - 6) * drift,
        _water - 4 + math.sin(time * 3) * 2,
      );
      jarRot = 0.5 + math.sin(time * 2.3) * 0.25;
      jarAt = Offset.lerp(jarAt, hand, ease(math.max(reach, hold)))!;
      jarRot *= 1 - hold;
    }

    // Ateşböcekleri.
    var inJar = 0;
    final flies = <Offset>[];
    for (var i = 0; i < 5; i++) {
      final ph = time * (1.3 + i * 0.17) + i * 1.26;
      // Düşerken Sâye'nin çevresinde: onu karanlıkta seçtiren ışık.
      final trail =
          feet + Offset(math.cos(ph * 2) * 26, -34 + math.sin(ph * 2) * 22);
      final search = Offset(
        fallX + 30 + math.cos(ph) * (40 + i * 8),
        _water - 36 + math.sin(ph * 1.4) * 18,
      );
      final near =
          feet + Offset(math.cos(ph) * 30, -46 + math.sin(ph * 1.3) * 12);
      final shelter =
          tree +
          Offset(math.cos(ph) * (32 + i * 4), -26 + math.sin(ph * 1.6) * 12);
      var at = trail;
      at = Offset.lerp(at, search, ease(sp(hit, hit + 0.35)))!;
      at = Offset.lerp(at, near, ease(sp(2.6, 3.0)))!;
      at = Offset.lerp(at, shelter, ease(sp(3.9 + i * 0.05, 4.3 + i * 0.05)))!;
      final enter = ease(sp(5.15 + i * 0.16, 5.45 + i * 0.16));
      if (enter >= 1) {
        inJar++;
        continue;
      }
      if (enter > 0) {
        // Kavanozun çevresinde dönerek içine iner.
        final spin =
            Offset(math.cos(ph * 3), math.sin(ph * 3)) * 18 * (1 - enter);
        at = Offset.lerp(at, jarAt + spin, enter)!;
      }
      flies.add(at);
    }

    // Umay'ın fidanı: filizlenir, ışığı tacından yayılır, çaputlar kalkar.
    final grow = ease(sp(3.85, 4.5));
    if (grow > 0) {
      canvas.drawCircle(
        tree + const Offset(0, -40),
        120 * grow,
        Paint()
          ..shader = ui.Gradient.radial(
            tree + const Offset(0, -40),
            120 * grow,
            [
              const Color(0xFFFFF4D8).withValues(
                alpha: 0.35 * sp(3.85, 4.1) * (1 - 0.5 * sp(4.3, 5.0)),
              ),
              const Color(0x00FFF4D8),
            ],
          ),
      );
      canvas.save();
      canvas.translate(tree.dx, tree.dy);
      canvas.scale(0.2 + 0.7 * grow);
      MythFigures.umayTree(canvas, time, lit: sp(4.0, 4.6));
      canvas.restore();
    }

    // Kavanoz dolunca parlar.
    final full = inJar / 5;
    final flare = sp(5.95, 6.05) * (1 - sp(6.1, 6.9));
    if (flare > 0) {
      canvas.drawCircle(
        jarAt,
        260 * flare + 40,
        Paint()
          ..shader = ui.Gradient.radial(jarAt, 260 * flare + 40, [
            const Color(0xFFFFD98A).withValues(alpha: 0.45 * flare),
            const Color(0x00FFD98A),
          ]),
      );
    }
    final ownJar = s < 6.0;
    if (ownJar) {
      if (s >= jarHit && hold <= 0) {
        // Suda: altı suyun içinde.
        canvas.save();
        canvas.clipRect(const Rect.fromLTRB(0, 0, 780, _water + 2));
        _jar(canvas, jarAt, jarRot, 0.1 + 0.9 * full, time, 1);
        canvas.restore();
      } else if (s >= t0 + jarDelay) {
        _jar(canvas, jarAt, jarRot, 0.1 + 0.9 * full, time, 1);
      }
    }
    for (var i = 0; i < flies.length; i++) {
      _firefly(canvas, flies[i], 1, time, i);
    }

    // 7: uzaktaki Kandilcinin feneri; Sâye çömelip kavanozun ışığını
    // saklar, fener gidince doğrulur, onun gittiği yöne yürür.
    _farGuard(canvas, time, u, glow: true);
    final s7 = _secs7(u);
    if (s7 >= 0.6 && s7 < 4.1) frame = 'comel';
    final walk = s7 - 4.7;
    if (walk > 0) {
      // Fenerin gittiği yöne, setin ucuna dek yürür (oyundaki gibi gerçek
      // adımlarla; kukla adımını ilerleyişe göre atar). Eski karede sekme.
      feet += Offset(
        math.min(_ledge.right - 22 - feet.dx, walk * 62),
        PerdeSaye.ready ? 0 : -(math.sin(time * 12)).abs() * 1.5,
      );
      frame = 'yuru${(time * 16).floor() % TasvirImages.walkFrames}';
    }

    if (hidden) return;
    if (!ownJar) {
      frame = frame.startsWith('yuru')
          ? 'yuru_kavanoz${frame.substring(4)}'
          : '${frame}_kavanoz';
    }
    if (s >= 6.3) faceLeft = false;
    if (clip == 3) {
      // Yüzeyde yüzer: suyun üstü tam, altı soluk.
      canvas.save();
      canvas.clipRect(const Rect.fromLTRB(0, _water + 2, 780, 400));
      _P._sayeFrame(
        canvas,
        frame,
        feet,
        _sayeK,
        time,
        mode: mode,
        vy: vy,
        grip: grip,
        climb: climb,
        pull: 0.85,
        stroke: stroke,
        rot: rot,
        a: 0.35,
      );
      canvas.restore();
      canvas.save();
      canvas.clipRect(const Rect.fromLTRB(0, 0, 780, _water + 2));
      _P._sayeFrame(
        canvas,
        frame,
        feet,
        _sayeK,
        time,
        mode: mode,
        vy: vy,
        grip: grip,
        climb: climb,
        pull: 0.85,
        stroke: stroke,
        rot: rot,
      );
      canvas.restore();
      return;
    }
    if (clip == 1) {
      // Suyun altında: soluk bir gölge, kabarcıklar yükselir.
      canvas.save();
      canvas.clipRect(const Rect.fromLTRB(0, _water + 3, 780, 400));
      _P._sayeFrame(
        canvas,
        frame,
        feet,
        _sayeK,
        time,
        mode: mode,
        stroke: stroke,
        rot: rot,
        a: 0.7,
      );
      canvas.restore();
      final bubble = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFFFE6B0).withValues(alpha: 0.6);
      for (var i = 0; i < 4; i++) {
        final k = (s * 1.3 + i * 0.25) % 1.0;
        canvas.drawCircle(
          feet + Offset(math.sin(i * 2.0 + s * 3) * 6, -30 - k * 14),
          1.5 + i * 0.4,
          bubble,
        );
      }
      return;
    }
    if (clip == 2) {
      canvas.save();
      canvas.clipRect(const Rect.fromLTRB(0, 0, 780, _water + 2));
    }
    _P._sayeFrame(
      canvas,
      frame,
      feet,
      _sayeK,
      time,
      walk: PerdeSaye.ready ? 0 : 30,
      mode: mode,
      vy: vy,
      faceLeft: faceLeft,
      rot: rot,
    );
    if (clip == 2) canvas.restore();
    // Sudan çıkınca üstünden damlalar süzülür.
    final wet = sp(2.6, 3.0) * (1 - sp(3.6, 4.2));
    if (wet > 0) {
      for (var i = 0; i < 3; i++) {
        final k = (s * 1.6 + i / 3) % 1.0;
        canvas.drawCircle(
          feet + Offset(-8 + i * 8.0, -34 + k * 34),
          1.6,
          Paint()
            ..color = const Color(0xFFFFE6B0)
                .withValues(alpha: 0.7 * wet * (1 - k)),
        );
      }
    }
  }

  /// Oyundaki Kandilci perdeye düşen gölge olarak: ayakları [x],[y]'de,
  /// [s] kat büyük. Fenerinin perdedeki yerini döndürür.
  static Offset _guardShadow(
    Canvas canvas,
    double time,
    double x,
    double y,
    double s, {
    required bool faceLeft,
    double a = 1,
    double glow = 0.4,
  }) {
    final dir = faceLeft ? -1.0 : 1.0;
    final phase = (x / s / 26) % 1.0;
    final swing = math.sin(time * 2 + x * 0.01) * 0.15;
    final art = guardLampArt(phase, 1, 0, 0, swing);
    final k = guardArtScale * s;
    final lantern = Offset(
      x + dir * (art.dx - guardArtFeet.dx) * k,
      y + (art.dy - guardArtFeet.dy) * k,
    );
    final cold = Cartoon.danger;
    canvas.drawCircle(
      lantern,
      90,
      Paint()
        ..shader = ui.Gradient.radial(lantern, 90, [
          cold.withValues(alpha: glow * a),
          cold.withValues(alpha: 0),
        ]),
    );
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(dir * s, s);
    if (ShadowArt.ready) {
      drawShadowGuard(
        canvas,
        feet: Offset.zero,
        phase: phase,
        weight: 1,
        run: 0,
        lean: 0,
        lampAngle: swing,
        doubt: 0,
        ink: PerdePainter._ink.withValues(alpha: a),
        rim: cold.withValues(alpha: 0.5 * a),
        eye: cold.withValues(alpha: 0.9 * a),
        lampGlass: cold.withValues(alpha: 0.95 * a),
      );
    }
    canvas.restore();
    return lantern;
  }

  /// Açılışta kandil önce sönük; kibrit çakılınca yanar. Kandilciler gelince
  /// alevi titrer; ışığı alınınca perde kararır.
  static double lamp(double u) {
    // Sarnıç: karanlıktan loş bir ışık.
    if (u >= 5) {
      // Düşüş karanlıkta; sıçrayınca sarnıç seçilir, fidanla biraz açılır.
      final s = _secs(u, 5);
      final d = _wetShift;
      return 0.04 +
          0.16 * ((s - 1.04) / 0.56).clamp(0.0, 1.0) +
          0.12 * ((s - d - 3.85) / 0.8).clamp(0.0, 1.0);
    }
    if (u >= 3) {
      // Kandilin son ışığı bir an kabarır, sonra karanlık.
      return 0.15 +
          0.12 *
              PerdePainter._span(u, 3.05, 3.2) *
              (1 - PerdePainter._span(u, 3.4, 3.7)) -
          0.11 * PerdePainter._span(u, 3.6, 3.95);
    }
    u = _d3(u);
    if (u >= 2.44) {
      return 1 -
          0.65 * PerdePainter._ease(PerdePainter._span(u, 2.46, 2.66)) -
          0.2 * PerdePainter._span(u, 2.7, 3.0);
    }
    if (u >= 2) {
      final fear = PerdePainter._span(u, 2.14, 2.4);
      return 1 - 0.2 * fear * (0.5 + 0.5 * math.sin(u * 8 * 23));
    }
    if (u >= 1) return 1;
    final strike =
        PerdePainter._span(u, 0.03, 0.045) *
        (1 - PerdePainter._span(u, 0.05, 0.09));
    return math.max(
      0.05 + 0.95 * PerdePainter._span(u, 0.05, 0.18),
      0.5 * strike,
    );
  }

  /// Seyirci çocuklar: baş ve omuz, kimi takkeli, kimi fesli, bir kız
  /// başörtülü. Perdenin önünde oldukları için kenarları biraz bulanık.
  /// [flee] 0'dan 1'e: birer birer eğilip en yakın kenara kaçarlar.
  static void _children(
    Canvas canvas,
    double time,
    double laugh,
    double flee,
    double a,
  ) {
    if (flee >= 1.6 || a <= 0) return;
    final ink = Paint()
      ..color = const Color(0xFF0B0503).withValues(alpha: a)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);
    const kids = [
      // x, baş yarıçapı, başlık (0 yok, 1 takke, 2 fes, 3 başörtü)
      (70.0, 21.0, 1),
      (150.0, 18.0, 3),
      (228.0, 23.0, 0),
      (560.0, 20.0, 2),
      (636.0, 17.0, 3),
      (712.0, 22.0, 1),
    ];
    for (var i = 0; i < kids.length; i++) {
      final (x0, r, hat) = kids[i];
      // Ortaya yakın olanlar biraz geç davranır.
      final run = PerdePainter._ease(
        (flee - (x0 < 390 ? x0 : 780 - x0) / 228 * 0.45).clamp(0.0, 1.0),
      );
      if (run >= 1) continue;
      final side = x0 < 390 ? -1.0 : 1.0;
      final x = x0 + side * 330 * run;
      final bob =
          -(math.sin(time * 9 + i * 1.3)).abs() * 5 * laugh -
          (math.sin(time * 15 + i)).abs() * 6 * (run > 0 ? 1 : 0) +
          14 * run;
      final tilt =
          math.sin(time * 4.5 + i) * 0.08 * laugh -
          0.04 * laugh +
          side * 0.25 * math.min(1, run * 5);
      final head = Offset(x, 400 - r * 2.4 + bob);
      canvas.save();
      canvas.translate(head.dx, head.dy + r);
      canvas.rotate(tilt);
      canvas.translate(-head.dx, -head.dy - r);
      // Omuzlar perdenin altından taşar.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, head.dy + r * 2.3),
          width: r * 3.6,
          height: r * 2.6,
        ),
        ink,
      );
      canvas.drawRect(
        Rect.fromLTWH(x - r * 0.45, head.dy + r * 0.6, r * 0.9, r),
        ink,
      );
      switch (hat) {
        case 3:
          // Başörtü: başı ve omuzları saran yumuşak bir kubbe.
          canvas.drawPath(
            Path()
              ..moveTo(x - r * 1.25, head.dy + r * 1.9)
              ..quadraticBezierTo(
                x - r * 1.35,
                head.dy - r * 1.3,
                x,
                head.dy - r * 1.15,
              )
              ..quadraticBezierTo(
                x + r * 1.35,
                head.dy - r * 1.3,
                x + r * 1.25,
                head.dy + r * 1.9,
              )
              ..close(),
            ink,
          );
        default:
          canvas.drawCircle(head, r, ink);
          // Kulaklar.
          canvas.drawCircle(head + Offset(-r * 0.98, r * 0.1), r * 0.24, ink);
          canvas.drawCircle(head + Offset(r * 0.98, r * 0.1), r * 0.24, ink);
      }
      if (hat == 1) {
        canvas.drawPath(
          Path()..addArc(
            Rect.fromCenter(
              center: head + Offset(0, -r * 0.55),
              width: r * 1.7,
              height: r * 1.1,
            ),
            math.pi,
            math.pi,
          ),
          ink,
        );
      } else if (hat == 2) {
        // Fes: kesik koni ve sallanan püskül.
        canvas.drawPath(
          Path()
            ..moveTo(x - r * 0.78, head.dy - r * 0.6)
            ..lineTo(x - r * 0.6, head.dy - r * 1.55)
            ..lineTo(x + r * 0.6, head.dy - r * 1.55)
            ..lineTo(x + r * 0.78, head.dy - r * 0.6)
            ..close(),
          ink,
        );
        final swing = math.sin(time * 6 + i) * 0.5 * (0.3 + laugh);
        canvas.drawLine(
          Offset(x, head.dy - r * 1.55),
          Offset(x + r * 0.9 + swing * 3, head.dy - r * 1.1),
          Paint()
            ..color = ink.color
            ..strokeWidth = 2,
        );
      }
      canvas.restore();
    }
  }
}
