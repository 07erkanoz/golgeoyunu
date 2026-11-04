// Yeni Sâye (A1) eklemli kukla denemesi: Gemini'nin dağıtılmış görünümünden
// potrace ile çıkarılan parçalar (build/kukla/parcalar.json, bkz.
// docs/konsept/saye_A1_dagitik.jpg) bir iskelete bağlanır, duruş, yürüyüş,
// koşu, zıplama ve kavanozu saklayarak çömelme oynatılır.
// `flutter test tools/preview/kukla_test.dart` → build/kukla/kare/%04d.png
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// 2B dönüşüm: x' = a·x + c·y + tx, y' = b·x + d·y + ty.
class Af {
  const Af(this.a, this.b, this.c, this.d, this.tx, this.ty);
  static const id = Af(1, 0, 0, 1, 0, 0);
  final double a, b, c, d, tx, ty;
  Af operator *(Af o) => Af(
    a * o.a + c * o.b,
    b * o.a + d * o.b,
    a * o.c + c * o.d,
    b * o.c + d * o.d,
    a * o.tx + c * o.ty + tx,
    b * o.tx + d * o.ty + ty,
  );
  static Af t(double x, double y) => Af(1, 0, 0, 1, x, y);
  static Af r(double th) =>
      Af(math.cos(th), math.sin(th), -math.sin(th), math.cos(th), 0, 0);

  /// [at] noktasından bağlanır, [th] kadar döner, kendi [pivot]u oraya gelir.
  static Af joint(ui.Offset at, double th, ui.Offset pivot) =>
      t(at.dx, at.dy) * r(th) * t(-pivot.dx, -pivot.dy);
  ui.Offset apply(ui.Offset p) =>
      ui.Offset(a * p.dx + c * p.dy + tx, b * p.dx + d * p.dy + ty);
  List<double> get m4 => [a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1];
}

/// Pozun açıları (A1'in ayakta duruşundan farkı, saat yönü artı) ve kalçanın
/// yeri.
class Pose {
  double x = 0, y = 0, lean = 0, head = 0, braid = 0, knot = 0, scarf = 0;
  double sb = 0, eb = 0, sf = 0, ef = 0; // omuz/dirsek arka, ön
  double hb = 0, kb = 0, ab = 0, hf = 0, kf = 0, af = 0; // kalça/diz/bilek
  double squash = 1;

  /// Kavanoz göğse saklanınca ışığı kısılır.
  double hide = 0;
}

const o = ui.Offset.new;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('kukla', () async {
    final data = jsonDecode(
      File('build/kukla/parcalar.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final paths = <String, ui.Path>{};
    final colors = <String, ui.Color>{};
    for (final e in data.entries) {
      final p = ui.Path()..fillType = ui.PathFillType.evenOdd;
      for (final ring in (e.value['rings'] as List)) {
        final pts = [
          for (final q in ring as List)
            o((q[0] as num).toDouble(), (q[1] as num).toDouble()),
        ];
        p.addPolygon(pts, true);
      }
      paths[e.key] = p;
      colors[e.key] = e.value['color'] == 'red'
          ? const ui.Color(0xFFC2402E)
          : const ui.Color(0xFF07050F);
    }
    final dir = Directory('build/kukla/kare')..createSync(recursive: true);
    for (final f in dir.listSync()) {
      f.deleteSync();
    }

    // Eklem yerleri (dağıtılmış görünümün koordinatlarında).
    const hip = ui.Offset(830, 1330);
    const neck = ui.Offset(813, 705);
    const headPivot = ui.Offset(835, 640);

    void draw(ui.Canvas c, Pose p, double s) {
      final root =
          Af.t(p.x, p.y) *
          Af(s, 0, 0, s * p.squash, 0, 0) *
          Af.joint(ui.Offset.zero, p.lean, hip);
      final head = root * Af.joint(neck, p.head, headPivot);
      final braid = head * Af.joint(o(640, 470), p.braid, o(590, 470));
      final knot = root * Af.joint(o(800, 712), p.knot, o(700, 632));
      final scarf = knot * Af.joint(o(600, 632), p.scarf, o(440, 700));
      final ub = root * Af.joint(o(735, 770), p.sb, o(635, 745));
      final fb = ub * Af.joint(o(480, 945), p.eb, o(470, 1000));
      final uf = root * Af.joint(o(905, 770), p.sf, o(1015, 745));
      final ff = uf * Af.joint(o(1195, 935), p.ef, o(1245, 1005));
      final tb = root * Af.joint(o(770, 1330), p.hb, o(637, 1500));
      final sbk = tb * Af.joint(o(619, 1800), p.kb, o(619, 1800));
      final bb = sbk * Af.joint(o(550, 2075), p.ab, o(510, 2105));
      final tf = root * Af.joint(o(900, 1330), p.hf, o(1033, 1500));
      final sfk = tf * Af.joint(o(1054, 1800), p.kf, o(1054, 1800));
      final bf = sfk * Af.joint(o(1090, 2075), p.af, o(1104, 2125));

      void part(
        String name,
        Af m, {
        ui.Rect? clip,
        double? knee,
        ui.Offset? kneeAt,
      }) {
        c.save();
        c.transform(Float64List.fromList(m.m4));
        if (clip != null) c.clipRect(clip);
        c.drawPath(paths[name]!, ui.Paint()..color = colors[name]!);
        if (kneeAt != null) {
          c.drawCircle(kneeAt, knee!, ui.Paint()..color = colors[name]!);
        }
        c.restore();
      }

      // Bacak dizden yuvarlak bir kesikle ikiye bölünür: iki parça da
      // dizin çevresindeki daireyi taşır, diz bükülünce şalvar pürüzsüz kalır.
      void leg(String name, Af thigh, Af shin, double r, ui.Offset knee) {
        void piece(Af m, ui.Rect half) {
          c.save();
          c.transform(Float64List.fromList(m.m4));
          c.clipPath(
            ui.Path()
              ..addRect(half)
              ..addOval(ui.Rect.fromCircle(center: knee, radius: r)),
          );
          c.drawPath(paths[name]!, ui.Paint()..color = colors[name]!);
          c.restore();
        }

        piece(thigh, ui.Rect.fromLTRB(0, 0, 2000, knee.dy));
        piece(shin, ui.Rect.fromLTRB(0, knee.dy, 2000, 2400));
      }

      // Arkadan öne.
      part('ust_kol_arka', ub);
      part('on_kol_arka', fb);
      part('atki_uclar', scarf);
      leg('bacak_arka', tb, sbk, 148, o(619, 1800));
      part('cizme_arka', bb);
      leg('bacak_on', tf, sfk, 143, o(1054, 1800));
      part('cizme_on', bf);
      part('orgu', braid);
      part('kurdele', braid);
      part('govde', root);
      part('bas', head);
      part('atki_dugum', knot);
      part('ust_kol_on', uf);
      part('on_kol_on', ff);
      // Kavanoz: elden sarkan ipte.
      final hand = ff.apply(o(1580, 1000));
      final jar = hand + o(0, 130 * s);
      c.drawLine(
        hand,
        jar - o(0, 40 * s),
        ui.Paint()
          ..color = const ui.Color(0xFF3A2A1A)
          ..strokeWidth = 6 * s,
      );
      c.drawCircle(
        jar,
        170 * s,
        ui.Paint()
          ..shader = ui.Gradient.radial(jar, 170 * s, [
            ui.Color.fromRGBO(255, 196, 107, 0.53 * (1 - 0.8 * p.hide)),
            const ui.Color(0x00FFC46B),
          ]),
      );
      c.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromCenter(center: jar, width: 110 * s, height: 140 * s),
          ui.Radius.circular(26 * s),
        ),
        ui.Paint()
          ..color = ui.Color.lerp(
            const ui.Color(0xFFE8A341),
            const ui.Color(0xFF5A3A1A),
            0.7 * p.hide,
          )!,
      );
      c.drawRect(
        ui.Rect.fromCenter(
          center: jar - o(0, 76 * s),
          width: 90 * s,
          height: 22 * s,
        ),
        ui.Paint()..color = const ui.Color(0xFF3A2A1A),
      );
      // Oyma gözün ardındaki ışık.
      final eye = head.apply(o(965, 400));
      c.drawCircle(
        eye,
        38 * s,
        ui.Paint()
          ..color = const ui.Color(0x66FFE6B0)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8),
      );
    }

    // Hareketler (her biri saniyeler boyunca).
    const fps = 30;
    const s = 0.24;
    const ground = 560.0;
    var frame = 0;
    var x = 0.0;
    Future<void> shot(Pose p) async {
      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec);
      c.drawRect(
        const ui.Rect.fromLTWH(0, 0, 720, 620),
        ui.Paint()..color = const ui.Color(0xFFE8D5A4),
      );
      // Zeminde dünyayla kayan çentikler.
      final tick = ui.Paint()
        ..color = const ui.Color(0xFF8A6A40)
        ..strokeWidth = 2;
      c.drawLine(
        const ui.Offset(0, ground),
        const ui.Offset(720, ground),
        tick,
      );
      for (var tx = -(x % 60); tx < 720; tx += 60) {
        c.drawLine(ui.Offset(tx, ground), ui.Offset(tx, ground + 12), tick);
      }
      draw(c, p, s);
      final img = await rec.endRecording().toImage(720, 620);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('${dir.path}/${(frame++).toString().padLeft(4, '0')}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }

    double sm(double v) {
      final c = v.clamp(0.0, 1.0);
      return c * c * (3 - 2 * c);
    }

    // Bacaklar ayağın yerine göre çözülür (iki kemik): ayak yerdeki noktaya
    // konur, kalça ve diz kendiliğinden bükülür; çizme yere düz basar.
    // Kemikler: kalça çivisi → diz → bilek (dağıtılmış görünümde).
    const legB = (
      pivot: ui.Offset(637, 1500),
      knee: ui.Offset(619, 1800),
      ankle: ui.Offset(550, 2075),
      attach: ui.Offset(770, 1330),
      sole: 198.0,
    );
    const legF = (
      pivot: ui.Offset(1033, 1500),
      knee: ui.Offset(1054, 1800),
      ankle: ui.Offset(1090, 2075),
      attach: ui.Offset(900, 1330),
      sole: 160.0,
    );
    double ang(ui.Offset v) => math.atan2(v.dy, v.dx);
    Af rootOf(Pose p) =>
        Af.t(p.x, p.y) *
        Af(s, 0, 0, s * p.squash, 0, 0) *
        Af.joint(ui.Offset.zero, p.lean, hip);
    (double, double, double) solve(
      Pose p,
      ({
        ui.Offset pivot,
        ui.Offset knee,
        ui.Offset ankle,
        ui.Offset attach,
        double sole,
      })
      l,
      ui.Offset foot,
      double pitch,
    ) {
      final h = rootOf(p).apply(l.attach);
      final lt = (l.knee - l.pivot).distance * s;
      final ls = (l.ankle - l.knee).distance * s;
      var d = foot - h;
      final dist = d.distance.clamp((lt - ls).abs() + 0.01, lt + ls - 0.01);
      d = d / d.distance * dist;
      final a0 = ang(d);
      final alpha = math.acos(
        ((lt * lt + dist * dist - ls * ls) / (2 * lt * dist)).clamp(-1.0, 1.0),
      );
      final thigh = a0 - alpha; // diz öne
      final k = h + ui.Offset(math.cos(thigh), math.sin(thigh)) * lt;
      final shin = ang(h + d - k);
      final hb = thigh - ang(l.knee - l.pivot) - p.lean;
      final kb = shin - ang(l.ankle - l.knee) - p.lean - hb;
      final ab = pitch - p.lean - hb - kb;
      return (hb, kb, ab);
    }

    void legs(
      Pose p,
      ui.Offset fb,
      ui.Offset ff, {
      double pb = 0,
      double pf = 0,
    }) {
      final b = solve(p, legB, fb, pb);
      p
        ..hb = b.$1
        ..kb = b.$2
        ..ab = b.$3;
      final f = solve(p, legF, ff, pf);
      p
        ..hf = f.$1
        ..kf = f.$2
        ..af = f.$3;
    }

    // Bileklerin yerden yüksekliği; kalça ayaktayken bacak hafif kırık.
    final legLen =
        ((legB.knee - legB.pivot).distance +
            (legB.ankle - legB.knee).distance) *
        s;
    final standY = ground - legB.sole * s - legLen * 0.97;
    Pose base(double t) => Pose()
      ..x = 300
      ..y = standY
      ..braid = math.sin(t * 2) * 0.04
      ..scarf = math.sin(t * 1.6) * 0.05
      ..head = math.sin(t * 1.1) * 0.02;
    ui.Offset restFoot(
      ({
        ui.Offset pivot,
        ui.Offset knee,
        ui.Offset ankle,
        ui.Offset attach,
        double sole,
      })
      l,
      Pose p,
      double dx,
    ) => ui.Offset(rootOf(p).apply(l.attach).dx + dx, ground - l.sole * s);

    // 1) Duruş: nefes.
    for (var i = 0; i < fps * 1.5; i++) {
      final t = i / fps;
      final p = base(t)..y = standY - math.sin(t * 3) * 1.2;
      legs(p, restFoot(legB, p, -4), restFoot(legF, p, 6));
      await shot(p);
    }
    // 2) Yürüyüş ve 3) koşu: basan ayak yerde gövdeyle aynı hızda geri
    // gider (kaymaz), öbürü havada öne savrulur.
    Future<void> gait(double secs, double run) async {
      final step = legLen * (0.55 + 0.5 * run);
      const stance = 0.6;
      final speed = 105 + 165 * run;
      final period = step / (stance * speed);
      var ph = 0.0;
      for (var i = 0; i < fps * secs; i++) {
        final t = i / fps;
        x += speed / fps;
        ph = (ph + 1 / fps / period) % 1.0;
        ui.Offset footAt(double q, ui.Offset rest) {
          if (q < stance) {
            return rest + ui.Offset(step / 2 - step * q / stance, 0);
          }
          final u = (q - stance) / (1 - stance);
          return rest +
              ui.Offset(
                -step / 2 + step * sm(u),
                -math.sin(u * math.pi) * legLen * (0.16 + 0.18 * run),
              );
        }

        double pitch(double q) {
          if (q < stance) {
            return q > stance * 0.8 ? 0.35 * sm((q / stance - 0.8) / 0.2) : 0;
          }
          final u = (q - stance) / (1 - stance);
          return 0.35 + (-0.25 - 0.35) * sm(u);
        }

        final q2 = ph * 2 % 1.0;
        final p = base(t)
          ..lean = 0.04 + 0.12 * run
          ..y = standY + math.cos(q2 * 2 * math.pi) * (2.5 + 3 * run) - 6 * run
          ..sb = 0.45 * (0.7 + run) * math.sin(ph * 2 * math.pi)
          ..eb = -0.2 - 0.4 * run
          ..sf = 0.12 * math.sin(ph * 2 * math.pi + math.pi) - 0.15 * run
          ..ef = 0.05 * math.sin(ph * 2 * math.pi)
          ..braid =
              0.12 +
              0.35 * run +
              math.sin(q2 * 2 * math.pi - 1) * (0.07 + 0.1 * run)
          ..scarf =
              -0.15 -
              0.45 * run +
              math.sin(q2 * 2 * math.pi - 1.3) * (0.06 + 0.1 * run)
          ..knot = -0.05 * run
          ..head = math.sin(q2 * 2 * math.pi + 0.8) * 0.02;
        final qb = (ph + 0.5) % 1.0;
        legs(
          p,
          footAt(qb, restFoot(legB, p, 0)),
          footAt(ph, restFoot(legF, p, 0)),
          pb: pitch(qb),
          pf: pitch(ph),
        );
        await shot(p);
      }
    }

    await gait(2.5, 0);
    await gait(2.0, 1);
    // 4) Zıplama: hazırlık, kalkış, havada toplanma, iniş, toparlanma.
    const jumpT = 1.6;
    for (var i = 0; i < fps * jumpT; i++) {
      final t = i / fps;
      final crouch =
          sm(t / 0.15) * (1 - sm((t - 0.15) / 0.08)) +
          sm((t - 1.0) / 0.05) * (1 - sm((t - 1.12) / 0.3));
      final air = t > 0.23 && t < 1.0 ? (t - 0.23) / 0.77 : 0.0;
      final h = air > 0 ? 4 * air * (1 - air) * 150 : 0.0;
      final tuck = air > 0 ? math.sin(air * math.pi) : 0.0;
      x += (air > 0 ? 160 : 40) / fps;
      final p = base(t)
        ..y = standY + crouch * 30 - h
        ..lean = 0.05 + 0.18 * crouch - 0.03 * tuck
        ..sb =
            0.5 * crouch -
            1.6 *
                (air > 0 && air < 0.5
                    ? sm(air / 0.15)
                    : (air > 0 ? 1 - sm((air - 0.5) / 0.5) : 0))
        ..eb = -0.4 * tuck
        ..sf = -0.35 * tuck
        ..braid = 0.35 * tuck - (air > 0.5 ? 0.3 * (air - 0.5) * 2 : 0) + 0.1
        ..scarf = -0.45 * tuck - 0.2
        ..squash = 1 - 0.04 * crouch;
      if (air > 0) {
        // Havada: ayaklar toplanır, inişe doğru açılır.
        final hipW = rootOf(p).apply(legF.attach);
        final reach = legLen * (0.98 - 0.42 * tuck);
        legs(
          p,
          ui.Offset(
            hipW.dx - 10 + 14 * tuck,
            math.min(hipW.dy + reach, ground - legB.sole * s),
          ),
          ui.Offset(
            hipW.dx + 6 + 26 * tuck,
            math.min(hipW.dy + reach * 0.95, ground - legF.sole * s),
          ),
          pb: 0.3 * tuck,
          pf: -0.2 * tuck,
        );
      } else {
        legs(p, restFoot(legB, p, -6), restFoot(legF, p, 8));
      }
      await shot(p);
    }
    // 5) Çömelip kavanozu göğsüne saklar, sonra kalkar.
    for (var i = 0; i < fps * 2.2; i++) {
      final t = i / fps;
      final k = sm(t / 0.35) * (1 - sm((t - 1.6) / 0.4));
      final p0 = base(0);
      final fb = restFoot(legB, p0, -10);
      final ff = restFoot(legF, p0, 22);
      // Derin çömelme: uyluklar yere paralel, sırt hafif kambur, baş
      // kavanoza eğik, kavanoz iki eliyle göğsünde.
      final p = base(t)
        ..y = standY + k * legLen * 0.56
        ..x = 300 - 16 * k
        ..lean = 0.3 * k
        ..sf = 0.55 * k
        ..ef = -2.25 * k
        ..sb = -0.9 * k
        ..eb = -1.4 * k
        ..head = 0.3 * k
        ..braid = 0.15 * k
        ..scarf = 0.1 * k
        ..hide = k;
      legs(p, fb, ff, pf: 0, pb: 0);
      await shot(p);
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}
