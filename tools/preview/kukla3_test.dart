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
  test('kukla 3', () async {
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

    const k0 = 0.24;
    // Ölçülmüş açılarla bacak (tools/kukla/rig.py ile aynı): uyluk, baldır,
    // ayak dünyadaki açılarıyla.
    (Af, Af, Af) fkLeg(Af torsoM, V shift, double t, double kk, double a) {
      final hh = legH + shift, kn = legK + shift, an = legA + shift;
      final th = Af.bone(torsoM(hh), t, k0, hh);
      final sh = Af.bone(th(kn), t + kk, k0, kn);
      final ft = Af.bone(sh(an), t + kk + a, k0, an);
      return (th, sh, ft);
    }

    final dir = Directory('build/kukla/kare3')..createSync(recursive: true);
    for (final f in dir.listSync()) {
      f.deleteSync();
    }
    const fps = 60;
    const dt = 1 / fps;
    const k = 0.24;
    const ground = 560.0;
    const w = 720, h = 620;

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
      Map<String, double>? fk,
      double worldV = 0,
    }) async {
      // Fizik: kalçanın hızı ve ivmesi.
      final vel = frame == 0 ? V.zero : (hip - prevHip) / dt;
      final acc = frame == 0 ? V.zero : (vel - hipVel) / dt;
      prevHip = hip;
      hipVel = vel;
      if (fk != null) {
        lean = fk['lean']!;
        headA = fk['head']!;
        sf = fk['sf']!;
        ef = fk['ef']!;
        sb = fk['sb']!;
        eb = fk['eb']!;
      }
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
      final (tF, s2F, ftFm) = fk != null
          ? fkLeg(torsoM, nearLeg, fk['tf']!, fk['kf']!, fk['af']!)
          : solveLeg(torsoM, nearLeg, footF.$1, footF.$2, k);
      final (tB, s2B, ftBm) = fk != null
          ? fkLeg(torsoM, backLeg, fk['tb']!, fk['kb']!, fk['ab']!)
          : solveLeg(torsoM, backLeg, footB.$1, footB.$2, k);
      // Saç ve atkı: yerçekimi, yürürken ve koşarken karşıdan gelen rüzgâr
      // (gövdenin dünyadaki hızı).
      final wind = V(-(vel.dx + worldV) * 3.2, 0);
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
          hand + V(math.sin(jarA), math.cos(jarA)) * len + const V(0, 14);
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
        jar - const V(0, 13),
        ui.Paint()
          ..color = const ui.Color(0xFF2A1A10)
          ..strokeWidth = 1.4,
      );
      c.save();
      c.translate(jar.dx, jar.dy);
      c.rotate(jarA * 0.6);
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

    // Ölçülmüş pozlar (tools/kukla/esle.py): örnek resimlerden.
    List<Map<String, double>> keys(String name) => [
      for (final e in jsonDecode(
        File('build/kukla/esle/$name.json').readAsStringSync(),
      ) as List)
        {
          for (final m in ((e as Map)['pose'] as Map).entries)
            m.key as String: (m.value as num).toDouble(),
        },
    ];
    // İki bacak örnekte ayırt edilmez: kareler arası sıçrayan bacak takası
    // düzeltilir (hangisi öncekine yakınsa).
    List<Map<String, double>> tidy(List<Map<String, double>> ks) {
      for (var i = 1; i < ks.length; i++) {
        final a = ks[i - 1], b = ks[i];
        final same = (b['tf']! - a['tf']!).abs() + (b['tb']! - a['tb']!).abs();
        final swap = (b['tf']! - a['tb']!).abs() + (b['tb']! - a['tf']!).abs();
        if (swap < same) {
          for (final (x, y) in [('tf', 'tb'), ('kf', 'kb'), ('af', 'ab')]) {
            final t = b[x]!;
            b[x] = b[y]!;
            b[y] = t;
          }
        }
      }
      // Dikey salınım: örnek ölçeğinden kuklaya, ortalamaya göre.
      final my =
          ks.map((p) => p['y']! / p['k']!).reduce((a, b) => a + b) / ks.length;
      for (final p in ks) {
        p['bob'] = (p['y']! / p['k']! - my) * k;
      }
      return ks;
    }

    final walkKeys = tidy([...keys('yuru_a'), ...keys('yuru_b')]);
    final runKeys = tidy(keys('kosu'));
    final restKey = <String, double>{
      for (final n in walkKeys.first.keys) n: 0.0,
      'sb': 0.81,
      'eb': 0.6,
    };
    // Döngüde iki ölçülmüş pozun arası yumuşak eğriyle (Catmull-Rom).
    Map<String, double> sample(List<Map<String, double>> ks, double t) {
      final n = ks.length;
      final x = (t % 1.0) * n;
      final i = x.floor();
      final f = x - i;
      final p0 = ks[(i - 1 + n) % n], p1 = ks[i % n];
      final p2 = ks[(i + 1) % n], p3 = ks[(i + 2) % n];
      return {
        for (final key in p1.keys)
          key:
              0.5 *
              (2 * p1[key]! +
                  (-p0[key]! + p2[key]!) * f +
                  (2 * p0[key]! - 5 * p1[key]! + 4 * p2[key]! - p3[key]!) *
                      f *
                      f +
                  (-p0[key]! + 3 * p1[key]! - 3 * p2[key]! + p3[key]!) *
                      f *
                      f *
                      f),
      };
    }

    Map<String, double> mix(
      Map<String, double> a,
      Map<String, double> b,
      double t,
    ) => {for (final key in a.keys) key: a[key]! + (b[key]! - a[key]!) * t};

    // Ayakların en alt noktası (topuk ya da burun), verilen kalça ve pozla.
    (V, V) soles(V hip, Map<String, double> p) {
      final torsoM = Af.bone(hip, p['lean']!, k, hip0);
      V low(V shift, double t, double kk, double a) {
        final (_, _, ft) = fkLeg(torsoM, shift, t, kk, a);
        final h = ft(heel + shift), o = ft(toe + shift);
        return h.dy > o.dy ? h : o;
      }

      return (
        low(nearLeg, p['tf']!, p['kf']!, p['af']!),
        low(backLeg, p['tb']!, p['kb']!, p['ab']!),
      );
    }

    const hipX = 300.0;
    final standY = ground - (sole - hip0.dy) * k;
    int? stanceFoot;
    double? stanceX;
    var speed = 0.0;
    var phase = 0.0;
    // Bir karede: poz, ayak yere kilitlenir (yerdeki ayak kaymaz, zemine
    // oturur), gövde o ayağın gerisinde kalmayacak hızda ilerler.
    Future<void> play(Map<String, double> p, {required bool contact}) async {
      var hip = V(hipX, standY + (p['bob'] ?? 0));
      var (nf, nb) = soles(hip, p);
      final lowest = math.max(nf.dy, nb.dy);
      // Yürürken bir ayak hep yerde; koşuda havada kalınabilir, ama zemine
      // gömülmez.
      if (contact || lowest > ground) {
        hip = hip + V(0, ground - lowest);
        (nf, nb) = soles(hip, p);
      }
      final foot = nf.dy >= nb.dy ? 0 : 1;
      final fx = foot == 0 ? nf.dx : nb.dx;
      final onGround = math.max(nf.dy, nb.dy) > ground - 1.5;
      if (onGround && stanceFoot == foot && stanceX != null) {
        speed = speed * 0.6 + (stanceX! - fx) / dt * 0.4;
      }
      stanceFoot = onGround ? foot : null;
      stanceX = onGround ? fx : null;
      worldX += speed * dt;
      await render(
        hip: hip,
        lean: 0,
        footF: (V.zero, 0),
        footB: (V.zero, 0),
        fk: p,
        worldV: speed,
      );
    }

    // 1) Duruş.
    for (var i = 0; i < fps * 1.0; i++) {
      final t = i / fps;
      speed *= 0.9;
      await play(
        mix(restKey, {...restKey, 'sb': 0.81 + math.sin(t * 2.6) * 0.02}, 1),
        contact: true,
      );
    }
    // 2) Yürüyüş (döngü 1,0 sn), 3) koşu (0,56 sn); aralarında yumuşak geçiş.
    Future<void> cycle(
      double secs,
      List<Map<String, double>> from,
      List<Map<String, double>> to,
      double periodFrom,
      double periodTo, {
      double blend = 0.4,
      bool fromRest = false,
      required bool contact,
    }) async {
      for (var i = 0; i < fps * secs; i++) {
        final t = i / fps;
        final e = sm(t / blend);
        phase += dt / (periodFrom + (periodTo - periodFrom) * e);
        final a = fromRest ? restKey : sample(from, phase);
        final b = sample(to, phase);
        await play(mix(a, b, e), contact: contact || e < 0.5);
      }
    }

    await cycle(
      3.4,
      walkKeys,
      walkKeys,
      1.0,
      1.0,
      fromRest: true,
      contact: true,
    );
    await cycle(2.8, walkKeys, runKeys, 1.0, 0.56, contact: false);
    // 4) Durma.
    for (var i = 0; i < fps * 1.2; i++) {
      final t = i / fps;
      final e = sm(t / 0.5);
      phase += dt / 0.56 * (1 - e);
      speed *= 0.95;
      await play(mix(sample(runKeys, phase), restKey, e), contact: e > 0.5);
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
