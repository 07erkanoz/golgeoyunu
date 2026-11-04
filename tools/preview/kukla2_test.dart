// Yeni Sâye (A1) kuklası, ikinci deneme: parçalar tek bir duruş koordinatında
// (build/kukla/kukla2.json), kol, bacak, etek ve örgü "deri giydirme" ile
// eklemde yumuşakça bükülür (dikiş yok); örgü, atkı uçları, etek ve kavanozun
// ipi yaylı fizikle oynar; bacaklar ayağın yerine göre çözülür (topuk basar,
// ağırlık ayağa biner, parmak iter).
// `flutter test tools/preview/kukla2_test.dart` → build/kukla/kare2/%04d.png
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'kukla_ortak.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('kukla 2', () async {
    final data = jsonDecode(
      File('build/kukla/kukla2.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    List<List<V>> ringsOf(dynamic j, [V shift = V.zero]) => [
      for (final r in j as List)
        [
          for (final q in r as List)
            V((q[0] as num).toDouble(), (q[1] as num).toDouble()) + shift,
        ],
    ];
    final L = data['layers'] as Map<String, dynamic>;
    List<V> pts(dynamic j) => [
      for (final q in j as List)
        V((q[0] as num).toDouble(), (q[1] as num).toDouble()),
    ];
    const ink = ui.Color(0xFF07050F);
    const red = ui.Color(0xFFC2402E);
    // Uzaktaki kol ve bacak bir ton açık: iki bacak birbirine karışmaz.
    const far = ui.Color(0xFF1F1829);

    // Kemikler.
    const torso = 0, skirt = 1, head = 2;
    const upF = 3, foF = 4, upB = 5, foB = 6;
    const thF = 7, shF = 8, ftF = 9, thB = 10, shB = 11, ftB = 12;
    const braid0 = 13, scarf0 = 18;
    // Duruştaki eklem yerleri.
    const hip0 = V(830, 1330);
    const neck = V(813, 705);
    const waist = V(845, 1050);
    const sF = V(905, 770), eF = V(1085, 960), hF = V(1420, 955);
    // Uzaktaki kol ve bacak öndekinin hemen ardında (yandan bakınca iki kalça
    // aynı hizada; küçük fark derinlik verir).
    // Bacaklar başın altında: A1'deki gibi baş ayakların üstünde (gövdenin ön
    // yarısına bağlanınca çocuk geriye yaslanmış görünüyordu).
    const backArm = V(-55, 0), nearLeg = V(-100, 0), backLeg = V(-122, 0);
    const legH = V(900, 1330), legK = V(921, 1540), legA = V(957, 1732.5);
    // Tabanın yere değen iki ucu: topuğun dibi ve burnun altı (taban hizası).
    const toe = V(1110, 1892.5), heel = V(925, 1892.5);
    const sole = 1892.5;
    final braidLine = pts(data['braid']);
    final scarfLine = pts(data['scarf']);

    Layer layer(
      List<List<V>> rings,
      ui.Color color,
      List<(int, double)> Function(V) w,
    ) => Layer(rings, color, [
      for (final r in rings) [for (final v in r) w(v)],
    ]);

    List<(int, double)> limb(V v, List<V> line, int a, int b, double band) {
      final u = along(line, v);
      final j = (line[1] - line[0]).distance;
      final k = sm((u - (j - band)) / (2 * band));
      return [if (k < 1) (a, 1 - k), if (k > 0) (b, k)];
    }

    List<(int, double)> leg(V v, V shift, int th, int sh, int ft) {
      final h = legH + shift, k = legK + shift, a = legA + shift;
      final foot = sm((v.dy - (a.dy - 25)) / 50);
      // Diz geniş bir alanda bükülür (kumaş gibi): bacağın boyu boyunca.
      final u = along([h, k, a], v);
      final j = (k - h).distance;
      final kn = sm((u - (j - 120)) / 240);
      final out = <(int, double)>[];
      if ((1 - foot) * (1 - kn) > 0) out.add((th, (1 - foot) * (1 - kn)));
      if ((1 - foot) * kn > 0) out.add((sh, (1 - foot) * kn));
      if (foot > 0) out.add((ft, foot));
      return out;
    }

    final armRings = ringsOf(L['kol']);
    final legRings = ringsOf(L['bacak'], nearLeg);
    final layers = <String, Layer>{
      'kolB': layer(
        ringsOf(L['kol'], backArm),
        far,
        (v) =>
            limb(v, [sF + backArm, eF + backArm, hF + backArm], upB, foB, 40),
      ),
      'bacakB': layer(
        ringsOf(L['bacak'], backLeg),
        far,
        (v) => leg(v, backLeg, thB, shB, ftB),
      ),
      'atki': layer(
        ringsOf(L['atki_uclar']),
        red,
        (v) => chainWeights(scarfLine, v, scarf0, 30),
      ),
      'orgu': layer(
        ringsOf(L['orgu']),
        ink,
        (v) => chainWeights(braidLine, v, braid0, 25),
      ),
      'kurdele': layer(
        ringsOf(L['kurdele']),
        red,
        (v) => chainWeights(braidLine, v, braid0, 25),
      ),
      'bacakF': layer(legRings, ink, (v) => leg(v, nearLeg, thF, shF, ftF)),
      'govde': layer(ringsOf(L['govde']), ink, (v) {
        final k = sm((v.dy - 1000) / 160);
        return [if (k < 1) (torso, 1 - k), if (k > 0) (skirt, k)];
      }),
      'bas': layer(ringsOf(L['bas']), ink, (v) => [(head, 1)]),
      'goz': layer(
        ringsOf(data['eye']),
        const ui.Color(0xFFFFF1CF),
        (v) => [(head, 1)],
      ),
      'dugum': layer(ringsOf(L['atki_dugum']), red, (v) => [(torso, 1)]),
      'kolF': layer(armRings, ink, (v) => limb(v, [sF, eF, hF], upF, foF, 40)),
    };
    final braid = Chain(braidLine, [0, 0.5, 0.32, 0.22, 0.16, 0.12]);
    final scarf = Chain(scarfLine, [0, 0.35, 0.22, 0.14]);

    // Bacak çözümü (iki kemik, diz öne).
    final lt = (legK - legH).distance, ls = (legA - legK).distance;
    (Af, Af, Af) solveLeg(Af torsoM, V shift, V ankle, double pitch, double k) {
      final h = torsoM(legH + shift);
      final l1 = lt * k, l2 = ls * k;
      var d = ankle - h;
      final dist = d.distance.clamp((l1 - l2).abs() + 0.01, l1 + l2 - 0.01);
      d = d / d.distance * dist;
      final alpha = math.acos(
        ((l1 * l1 + dist * dist - l2 * l2) / (2 * l1 * dist)).clamp(-1.0, 1.0),
      );
      final th = ang(d) - alpha;
      final knee = h + V(math.cos(th), math.sin(th)) * l1;
      final sh = ang(h + d - knee);
      return (
        Af.bone(h, th - ang(legK - legH), k, legH + shift),
        Af.bone(knee, sh - ang(legA - legK), k, legK + shift),
        Af.bone(h + d, pitch, k, legA + shift),
      );
    }

    // Ayak: yerdeki nokta ve eğim → bilek. Topuk değerken topuk çevresinde,
    // parmak iterken parmak ucunun çevresinde döner.
    V ankleFor(V contact, double pitch, bool onHeel, double k) {
      final pivot = onHeel ? heel : toe;
      return contact + rot(legA - pivot, pitch) * k;
    }

    final dir = Directory('build/kukla/kare2')..createSync(recursive: true);
    for (final f in dir.listSync()) {
      f.deleteSync();
    }
    const fps = 60;
    const dt = 1 / fps;
    const k = 0.24;
    const ground = 560.0;
    const w = 720, h = 620;
    final legLen = (lt + ls) * k;

    /// Parmak ucu yerdeki [contact]'ta duran ayak: bilek ve eğim.
    (V, double) toeFoot(V contact, double pitch) =>
        (ankleFor(contact, pitch, false, k), pitch);
    var frame = 0;
    var worldX = 0.0;
    var prevHip = V.zero;
    var hipVel = V.zero;
    var skirtA = 0.0, skirtV = 0.0;
    var jarA = 0.0, jarV = 0.0;
    var prevHand = V.zero;
    var handVel = V.zero;

    Future<void> render({
      required V hip,
      required double lean,
      double headA = 0,
      required (V, double) footF,
      required (V, double) footB,
      double sf = 0,
      double ef = 0,
      double sb = 0.81,
      double eb = 0.6,
      double hide = 0,
    }) async {
      // Fizik: kalçanın hızı ve ivmesi.
      final vel = frame == 0 ? V.zero : (hip - prevHip) / dt;
      final acc = frame == 0 ? V.zero : (vel - hipVel) / dt;
      prevHip = hip;
      hipVel = vel;
      final torsoM = Af.bone(hip, lean, k, hip0);
      // Etek: ivmeye geç tepki verir, gövdenin ardında salınır.
      final skirtTarget = (-acc.dx * 0.00012 - vel.dx * 0.00018).clamp(
        -0.25,
        0.25,
      );
      skirtV += ((skirtTarget - skirtA) * 140 - skirtV * 9) * dt;
      skirtA += skirtV * dt;
      final skirtM = Af.bone(torsoM(waist), lean + skirtA, k, waist);
      final headM = Af.bone(torsoM(neck), lean + headA, k, neck);
      final uF = Af.bone(torsoM(sF), lean + sf, k, sF);
      final fF = Af.bone(uF(eF), lean + sf + ef, k, eF);
      final uB = Af.bone(torsoM(sF + backArm), lean + sb, k, sF + backArm);
      final fB = Af.bone(uB(eF + backArm), lean + sb + eb, k, eF + backArm);
      final (tF, s2F, ftFm) = solveLeg(torsoM, nearLeg, footF.$1, footF.$2, k);
      final (tB, s2B, ftBm) = solveLeg(torsoM, backLeg, footB.$1, footB.$2, k);
      // Saç ve atkı: yerçekimi, koşunca karşıdan gelen rüzgâr.
      final wind = V(-vel.dx * 3.2, 0);
      braid.step(headM, k, dt, const V(0, 900), wind);
      scarf.step(torsoM, k, dt, const V(0, 700), wind * 1.3);
      final bones = <Af>[
        torsoM,
        skirtM,
        headM,
        uF,
        fF,
        uB,
        fB,
        tF,
        s2F,
        ftFm,
        tB,
        s2B,
        ftBm,
        ...braid.bones(k),
        ...scarf.bones(k),
      ];

      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec);
      c.drawRect(
        ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        ui.Paint()..color = const ui.Color(0xFFE8D5A4),
      );
      final tick = ui.Paint()
        ..color = const ui.Color(0xFF8A6A40)
        ..strokeWidth = 2;
      c.drawLine(const V(0, ground), V(w.toDouble(), ground), tick);
      for (var x = -(worldX % 60); x < w; x += 60) {
        c.drawLine(V(x, ground), V(x, ground + 12), tick);
      }
      // Kukla bir resme çizilir; ardında ılık hale (A1'deki arka ışık).
      final figRec = ui.PictureRecorder();
      final f = ui.Canvas(figRec);
      void draw(String n) => f.drawPath(
        layers[n]!.path(bones),
        ui.Paint()..color = layers[n]!.color,
      );
      draw('kolB');
      draw('bacakB');
      draw('atki');
      draw('orgu');
      draw('kurdele');
      draw('bacakF');
      draw('govde');
      draw('bas');
      draw('dugum');
      draw('kolF');
      final fig = figRec.endRecording();
      c.saveLayer(
        null,
        ui.Paint()
          ..imageFilter = ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9)
          ..colorFilter = const ui.ColorFilter.mode(
            ui.Color(0xAAFFE9B8),
            ui.BlendMode.srcIn,
          ),
      );
      c.drawPicture(fig);
      c.restore();
      c.drawPicture(fig);
      // Göz: ışıyan hilal ve parıltı beneği, çevresinde ılık parıltı.
      final eyeC = headM(const V(940, 465));
      c.drawCircle(
        eyeC,
        26,
        ui.Paint()
          ..shader = ui.Gradient.radial(eyeC, 26, [
            const ui.Color(0x88FFD98A),
            const ui.Color(0x00FFD98A),
          ]),
      );
      c.drawPath(
        layers['goz']!.path(bones),
        ui.Paint()..color = layers['goz']!.color,
      );
      // Kavanoz: elden sarkan ipte, sarkaç gibi.
      final hand = fF(hF + const V(-10, 10));
      final hv = frame == 0 ? V.zero : (hand - prevHand) / dt;
      final ha = frame == 0 ? V.zero : (hv - handVel) / dt;
      prevHand = hand;
      handVel = hv;
      jarV +=
          (-math.sin(jarA) * 60 - ha.dx * 0.03 * math.cos(jarA) - jarV * 4) *
          dt;
      jarA += jarV * dt;
      final len = 28.0 * (1 - 0.7 * hide);
      final jar =
          hand + V(math.sin(jarA), math.cos(jarA)) * len + const V(0, 22);
      final glow = 1 - 0.85 * hide;
      c.drawCircle(
        jar,
        70,
        ui.Paint()
          ..shader = ui.Gradient.radial(jar, 70, [
            ui.Color.fromRGBO(255, 200, 110, 0.55 * glow),
            const ui.Color(0x00FFC46B),
          ]),
      );
      c.drawLine(
        hand,
        jar - const V(0, 21),
        ui.Paint()
          ..color = const ui.Color(0xFF2A1A10)
          ..strokeWidth = 1.4,
      );
      c.save();
      c.translate(jar.dx, jar.dy);
      c.rotate(jarA * 0.6);
      // A1'deki gibi iri kavanoz.
      c.scale(1.5);
      final body = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(-11, -12, 22, 26),
        const ui.Radius.circular(6),
      );
      c.drawRRect(
        body,
        ui.Paint()
          ..shader = ui.Gradient.radial(V.zero, 18, [
            ui.Color.lerp(
              const ui.Color(0xFFFFE08A),
              const ui.Color(0xFF6A4A20),
              hide,
            )!,
            ui.Color.lerp(
              const ui.Color(0xFFD9832A),
              const ui.Color(0xFF3A2410),
              hide,
            )!,
          ]),
      );
      c.drawRRect(
        body,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const ui.Color(0xFF6A3A14),
      );
      c.drawRect(
        const ui.Rect.fromLTWH(-9, -16, 18, 5),
        ui.Paint()..color = const ui.Color(0xFF5A3A1A),
      );
      for (var i = 0; i < 3; i++) {
        final t = frame / fps * (1.4 + i * 0.5) + i * 2.1;
        c.drawCircle(
          V(math.sin(t) * 5, math.cos(t * 1.3) * 6),
          1.6,
          ui.Paint()..color = ui.Color.fromRGBO(255, 248, 220, glow),
        );
      }
      c.restore();
      final img = await rec.endRecording().toImage(w, h);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('${dir.path}/${(frame++).toString().padLeft(4, '0')}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    // Ayakta: kalça, bacak hafif kırık olacak yükseklikte.
    // Dizler hafif kırık: adımın iki ucunda da bacak ayağa yetişir.
    final standY = ground - (sole - legA.dy) * k - legLen * 0.955;
    const hipX = 300.0;
    V groundAt(double x) => V(x, ground);
    // Ayağın yerdeki noktası: duruşta parmak ucu ve topuk zeminde.
    double footX(V shift) => hipX + (toe.dx - hip0.dx + shift.dx) * k;

    // 1) Duruş: nefes, örgü durulur.
    for (var i = 0; i < fps * 1.2; i++) {
      final t = i / fps;
      await render(
        hip: V(hipX, standY - math.sin(t * 2.6) * 1.2),
        lean: 0.02,
        headA: math.sin(t * 1.1) * 0.02,
        footF: toeFoot(groundAt(footX(nearLeg) - 6), 0),
        footB: toeFoot(groundAt(footX(backLeg) + 4), 0),
        sb: 0.81 + math.sin(t * 2.6) * 0.02,
      );
    }

    // 2) Yürüyüş, 3) koşu. Ayak yerdeyken dünyayla aynı yerde durur (kaymaz);
    // topuk değer, ayak düzleşir, topuk kalkar, parmak iter; havada diz
    // bükülür, ayak öne savrulur. Kalça adımda iki kez yükselir.
    V? lastA, lastB;
    var maxStep = 0.0;
    Future<void> gait(double secs, double run, {double fadeIn = 0.4}) async {
      lastA = null;
      maxStep = 0;
      final stance = 0.62 - 0.24 * run;
      // Örneklerdeki gibi geniş adım (eşlemeden: kalçada ~45° açılır).
      final step = legLen * (0.6 + 0.25 * run);
      final speed = step / ((stance) * (0.55 - 0.17 * run)) / 2;
      final period = 0.55 - 0.17 * run; // bir adım (yarım döngü) süresi
      var q = 0.0;
      for (var i = 0; i < fps * secs; i++) {
        final t = i / fps;
        final e = sm(t / fadeIn);
        final v = speed * e;
        worldX += v * dt;
        q = (q + dt / (2 * period) * e) % 1.0;
        // Topuk değer (burun yukarıda), ayak düzleşir, sonda topuk kalkar,
        // parmak iter. Yerdeki nokta adım boyunca aynı yerde durur: önce
        // topuk, sonra parmak ucu. Havada bilek, parmağın kalktığı yerden
        // topuğun değeceği yere kesintisiz bir yay çizer.
        final heelBack = (toe.dx - heel.dx) * k;
        V onToe(double xt, double p) => V(xt, ground) + rot(legA - toe, p) * k;
        V onHeel(double xh, double p) =>
            V(xh, ground) + rot(legA - heel, p) * k;
        (V, double) foot(double ph, V shift) {
          final base = footX(shift) - 4;
          if (ph < stance) {
            final u = ph / stance;
            final xt = base + step / 2 - step * u;
            if (u < 0.12) {
              final p = -0.22 * (1 - sm(u / 0.12)) * e;
              return (onHeel(xt - heelBack, p), p);
            }
            final p = 0.55 * sm((u - 0.62) / 0.38) * e;
            return (onToe(xt, p), p);
          }
          final u = (ph - stance) / (1 - stance);
          final from = onToe(base - step / 2, 0.55 * e);
          final to = onHeel(base + step / 2 - heelBack, -0.22 * e);
          // Koşuda arka bacak topuğunu erken ve yukarı teper (örnekteki gibi).
          final lift =
              math
                  .pow(math.sin(math.pi * math.pow(u, 1 - 0.3 * run)), 1.2)
                  .toDouble() *
              legLen *
              (0.11 + 0.25 * run);
          final p = (0.55 * (1 - sm(u / 0.5)) - 0.22 * sm((u - 0.5) / 0.5)) * e;
          return (V.lerp(from, to, sm(u))! - V(0, lift * e), p);
        }

        final qB = (q + 0.5) % 1.0;
        // Denetim: bileğin kareden kareye yer değiştirmesi (dünyada).
        final fa = foot(q, nearLeg).$1 + V(worldX, 0);
        final fbk = foot(qB, backLeg).$1 + V(worldX, 0);
        if (lastA != null) {
          maxStep = math.max(maxStep, (fa - lastA!).distance);
          maxStep = math.max(maxStep, (fbk - lastB!).distance);
        }
        lastA = fa;
        lastB = fbk;
        // Kalça: ayak tam altındayken en yüksek (yürüyüş), koşuda basışta
        // çöker.
        final two = math.cos(4 * math.pi * (q - stance / 2));
        final bob = run < 0.5 ? two * 4.5 : -two * 5.5;
        final hipY = standY - bob * e + legLen * 0.04 * run * e;
        // Boştaki kol, yandaki bacağın tersine, biraz geriden gelir.
        final farForward = math.sin(2 * math.pi * (q - 0.07));
        final nearForward = -math.sin(2 * math.pi * (q - 0.05));
        await render(
          hip: V(hipX, hipY),
          // Çocuk dik yürür; koşuda biraz öne eğilir.
          lean: (0.02 + 0.13 * run + 0.008 * two) * e + 0.025,
          headA: (-0.035 - 0.012 * two + 0.03 * run) * e,
          footF: foot(q, nearLeg),
          footB: foot(qB, backLeg),
          // Uzaktaki kol öne az, geriye daha çok salınır: gövdenin ardında
          // kalır, eteğin önünde üçüncü bir el gibi belirmez.
          // Eşlemeden: uzaktaki kol geride (yürüyüşte omuz ~1,6, koşuda
          // ~1,4), dirsek yürürken ~0,9, koşarken bükük.
          sb:
              0.81 +
              (0.75 - 0.15 * run) * e -
              (farForward > 0 ? 0.15 + 0.2 * run : 0.3 + 0.2 * run) *
                  farForward *
                  e,
          eb: 0.6 + (0.3 - 0.9 * run) * e - 0.2 * math.max(0, farForward) * e,
          // Kavanozlu kol yürürken aşağı sarkar, kavanoz kalça hizasında
          // adımla sallanır (A1'deki gibi); koşuda dirsek bükülür.
          // Eşlemeden: kavanozlu kol dirsekten bükülü, kavanoz kalçanın önünde
          // alçakta (yürüyüş omuz ~-0,2, dirsek ~1,3; koşu omuz ~0,3,
          // dirsek ~0,2).
          sf: (-0.2 + 0.5 * run) * e - (0.08 + 0.2 * run) * nearForward * e,
          ef: (1.3 - 1.1 * run) * e,
        );
      }
    }

    await gait(3.0, 0);
    // ignore: avoid_print
    print('yürüyüş: bileğin kareden kareye en büyük yer değiştirmesi $maxStep');
    await gait(2.6, 1, fadeIn: 0.6);
    // ignore: avoid_print
    print('koşu: bileğin kareden kareye en büyük yer değiştirmesi $maxStep');
    // Koşudan duruşa: birkaç kısa adımla yavaşlar.
    for (var i = 0; i < fps * 0.8; i++) {
      final t = i / fps;
      final e = 1 - sm(t / 0.5);
      worldX += 260 * e * dt;
      await render(
        hip: V(hipX, standY + 6 * e),
        lean: 0.02 + 0.2 * e - 0.06 * math.sin(t * 9) * (1 - e) * (1 - t),
        footF: toeFoot(groundAt(footX(nearLeg) + 10 * e), 0),
        footB: toeFoot(groundAt(footX(backLeg) - 14 * e), 0.3 * e),
        sb: 0.81 - 0.3 * e,
        eb: 0.6 - 0.6 * e,
      );
    }
    // 4) Zıplama: hazırlık çökmesi, kalkış, havada toplanma, iniş, toparlanma.
    for (var i = 0; i < fps * 1.7; i++) {
      final t = i / fps;
      final pre = sm(t / 0.14) * (1 - sm((t - 0.14) / 0.07));
      const t0 = 0.21, t1 = 0.98;
      final air = t > t0 && t < t1 ? (t - t0) / (t1 - t0) : 0.0;
      final land = sm((t - t1) / 0.05) * (1 - sm((t - t1 - 0.06) / 0.3));
      final rise = air > 0 ? 4 * air * (1 - air) * 110 : 0.0;
      final tuck = air > 0 ? math.sin(air * math.pi) : 0.0;
      worldX += (air > 0 ? 150 : 20) * dt;
      final hipY = standY + pre * 34 + land * 40 - rise;
      final reach = legLen * (0.97 - 0.32 * tuck);
      (V, double) foot(V shift, double fwd, double p) {
        if (air <= 0) return toeFoot(groundAt(footX(shift) - 4), 0);
        final hx = hipX + (legH.dx - hip0.dx + shift.dx) * k;
        return toeFoot(
          V(hx + fwd * tuck, math.min(hipY + reach, ground)),
          p * tuck,
        );
      }

      await render(
        hip: V(hipX, hipY),
        lean: 0.03 + 0.22 * pre + 0.25 * land - 0.04 * tuck,
        headA: -0.1 * pre + 0.06 * tuck,
        footF: foot(nearLeg, 22, -0.2),
        footB: foot(backLeg, 6, 0.35),
        sb:
            0.81 +
            0.5 * pre -
            2.2 * sm(air / 0.25) * (1 - sm((air - 0.55) / 0.45)) +
            0.4 * land,
        eb: 0.6 - 0.5 * tuck,
        sf: -0.4 * tuck + 0.15 * pre,
        ef: 0.1 * tuck,
      );
    }
    // 5) Çömelip kavanozu göğsüne saklar, bir süre bekler, kalkar.
    for (var i = 0; i < fps * 2.4; i++) {
      final t = i / fps;
      final kk = sm(t / 0.4) * (1 - sm((t - 1.8) / 0.45));
      await render(
        hip: V(hipX - 14 * kk, standY + kk * legLen * 0.55),
        lean: 0.02 + 0.32 * kk,
        headA: 0.32 * kk,
        footF: toeFoot(groundAt(footX(nearLeg) + 18 * kk - 4), 0),
        footB: toeFoot(groundAt(footX(backLeg) - 8 * kk), 0.15 * kk),
        sf: 0.55 * kk,
        ef: -2.25 * kk,
        sb: 0.81 - 1.7 * kk,
        eb: 0.6 - 1.5 * kk,
        hide: kk,
      );
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
