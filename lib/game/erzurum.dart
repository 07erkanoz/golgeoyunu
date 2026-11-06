import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'golge_game.dart';
import 'level.dart';

// IX · Kar Yolu: Erzurum'un damları. Evliya Çelebi anlatır: Erzurum'da kış
// öyle sert gelir ki damdan dama atlayan kedi havada donar. Damların
// arasında, sıçrayışın tam ortasında donup kalmış bir kedi (küçük sürpriz).

class FrozenCat extends PositionComponent with HasGameReference<GolgeGame> {
  FrozenCat(Vector2 cell)
    : super(position: cell + Vector2(kTile / 2, kTile / 2), priority: 18);

  double _t = 0;
  bool _seen = false;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (_seen || p == null || p.isDead) return;
    if ((p.center - position).length < 3.2 * kTile) {
      _seen = true;
      GameAudio.instance.play('shatter', volume: 0.25);
      game.hint('frozenCat');
      if (!game.secretSeen('donmusKedi')) game.foundSecret('donmusKedi');
    }
  }

  @override
  void render(Canvas canvas) {
    // Sıçrayışın ortasında donmuş kedi: gövde uzanmış, ön ayaklar karşı
    // dama, arka ayaklar geride, kuyruk havada kıvrık. Ay ışığı üst
    // kenarına kırağı gibi vurur; burnunun ucunda nefesi donmuş.
    final body = Path()
      ..moveTo(17, -9)
      ..cubicTo(9, -12, -6, -12, -15, -8)
      ..quadraticBezierTo(-21, -5, -20, 0)
      ..quadraticBezierTo(-17, 4, -10, 3)
      ..cubicTo(-2, 4, 8, 3, 15, 1)
      ..quadraticBezierTo(20, -2, 17, -9)
      ..close();
    final head = Path()
      ..addOval(
        Rect.fromCenter(center: const Offset(23, -9), width: 12, height: 10),
      )
      ..moveTo(19, -12)
      ..lineTo(20.5, -19)
      ..lineTo(23.5, -13.5)
      ..close()
      ..moveTo(24.5, -13.5)
      ..lineTo(28, -18.5)
      ..lineTo(28.5, -11)
      ..close()
      // Burun ucu.
      ..moveTo(27, -10)
      ..lineTo(31, -8)
      ..lineTo(27.5, -6)
      ..close();
    final limbs = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.8;
    // Ayaklar: ön ikisi ileri uzanmış, arka ikisi geride gergin.
    final legs = Path()
      ..moveTo(14, 0)
      ..quadraticBezierTo(24, 1, 33, 3)
      ..moveTo(12, 1)
      ..quadraticBezierTo(21, 4, 30, 6)
      ..moveTo(-14, 1)
      ..quadraticBezierTo(-22, 2, -27, 7)
      ..lineTo(-33, 8)
      ..moveTo(-12, 2)
      ..quadraticBezierTo(-19, 5, -24, 10)
      ..lineTo(-30, 11.5);
    final tail = Path()
      ..moveTo(-19, -4)
      ..cubicTo(-28, -7, -27, -17, -33, -22)
      ..quadraticBezierTo(-36, -25, -33, -27);
    void silhouette(Paint fill, Offset at) {
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.drawPath(body, fill);
      canvas.drawPath(head, fill);
      canvas.drawPath(
        legs,
        Paint()
          ..color = fill.color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = limbs.strokeWidth,
      );
      canvas.drawPath(
        tail,
        Paint()
          ..color = fill.color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3.2,
      );
      canvas.restore();
    }

    // Kırağı: siluetin ardında, sol üstte ince ak bir kenar kalır.
    silhouette(
      Paint()..color = const Color(0xFFCFE2EE).withValues(alpha: 0.7),
      const Offset(-0.8, -1.1),
    );
    silhouette(Paint()..color = const Color(0xFF0B1016), Offset.zero);
    // Karnından sarkan küçük buz sarkıtları.
    final ice = Paint()
      ..color = const Color(0xFFD6EAF4).withValues(alpha: 0.75);
    for (final (x, len) in const [(-8.0, 4.0), (-1.0, 6.0), (6.0, 3.5)]) {
      canvas.drawPath(
        Path()
          ..moveTo(x - 1.2, 3.2)
          ..lineTo(x + 1.2, 3.2)
          ..lineTo(x, 3.2 + len),
        ice,
      );
    }
    // Gözü açık kalmış: ince ak bir yarık.
    canvas.drawLine(
      const Offset(24.2, -10.2),
      const Offset(26.4, -10.4),
      Paint()
        ..color = const Color(0xFFE8F6FA)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );
    // Burnunun ucunda donmuş nefes: üç küçük buz bulutçuğu.
    final breath = Paint()
      ..color = const Color(0xFFDDEEF6).withValues(alpha: 0.4);
    canvas.drawCircle(const Offset(34, -9), 1.8, breath);
    canvas.drawCircle(const Offset(37.5, -10.5), 1.4, breath);
    canvas.drawCircle(const Offset(40, -12.5), 1, breath);
    // Arada bir buzda pırıltı.
    final glint = (math.sin(_t * 1.7) + 1) / 2;
    if (glint > 0.85) {
      canvas.drawCircle(
        const Offset(2, -11),
        1.4 + (glint - 0.85) * 10,
        Paint()
          ..color = const Color(0xFFFFFFFF)
              .withValues(alpha: (glint - 0.85) * 5),
      );
    }
  }
}

/// Erzurum evi: yamaca yaslanmış moloz taş setin üstünde iki katlı taş ev;
/// ahşap hatıllar, gömme küçük pencereler (kimi yanık, kimi karanlık,
/// eşiklerinde kar), toprak dam ve damın kenarından çıkan ardıç direkleri,
/// üstünde kalın kar, saçaktan sarkan buzlar. Ay soldan vurur. Yalnızca
/// görünüş: ev haritadaki kaya bloğudur.
class ErzurumHouse extends PositionComponent with HasGameReference<GolgeGame> {
  ErzurumHouse(int c0, int c1, int roof)
    : super(
        position: Vector2(c0 * kTile.toDouble(), roof * kTile.toDouble()),
        size: Vector2(
          (c1 - c0 + 1) * kTile.toDouble(),
          (20 - roof) * kTile.toDouble(),
        ),
        priority: 2,
      );

  double _t = 0;
  Picture? _static;
  final _windows = <(Rect, bool)>[];

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void onRemove() {
    _static?.dispose();
    super.onRemove();
  }

  double _rnd(int i) {
    final v = math.sin(i * 12.9898 + position.x * 0.0781) * 43758.5453;
    return v - v.floorToDouble();
  }

  Picture _record() {
    final rec = PictureRecorder();
    final c = Canvas(rec);
    final w = size.x, h = size.y;
    // Evin kendisi üstte iki kat; altı yamaca yaslanmış moloz taş set.
    final house = math.min(h, 3.3 * kTile);
    c.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF0C1017),
    );
    // Set: düzensiz, iri moloz taşlar.
    final stone = Paint()..color = const Color(0xFF151B25);
    var k = 0;
    for (var y = house + 2; y < h; y += 11) {
      var x = -4 + _rnd(k++) * 8;
      while (x < w) {
        final sw = 10 + _rnd(k++) * 14;
        final sh = 7 + _rnd(k++) * 3;
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y + _rnd(k++) * 2, sw, sh),
            const Radius.circular(3),
          ),
          stone,
        );
        x += sw + 2;
      }
    }
    // Ev duvarı: kesme taş, sıraları yer yer kayık.
    c.drawRect(
      Rect.fromLTWH(0, 0, w, house),
      Paint()..color = const Color(0xFF171C26),
    );
    final joint = Paint()
      ..color = const Color(0xFF242C39)
      ..strokeWidth = 1;
    for (var y = 12.0; y < house - 4; y += 10) {
      c.drawLine(Offset(1, y), Offset(w - 1, y), joint);
      var x = _rnd(k++) * 16;
      while (x < w - 6) {
        c.drawLine(Offset(x, y), Offset(x, y + 10), joint);
        x += 14 + _rnd(k++) * 16;
      }
    }
    // Ahşap hatıllar: kat aralarında; uçları duvardan taşar.
    final wood = Paint()..color = const Color(0xFF2B2119);
    for (final y in [house * 0.5, house - 3]) {
      c.drawRect(Rect.fromLTWH(-2, y, w + 4, 3.5), wood);
    }
    // Pencereler: her katta düzensiz aralıklı, gömme.
    _windows.clear();
    final per = (w / 64).floor().clamp(1, 3);
    for (final floor in [0, 1]) {
      final fy = floor == 0 ? 16.0 : house * 0.5 + 10;
      for (var i = 0; i < per; i++) {
        if (floor == 1 && _rnd(k++) < 0.35) continue;
        final cx = (i + 0.5) * w / per + (_rnd(k++) - 0.5) * w / per * 0.4;
        final r = Rect.fromLTWH(cx - 6, fy + _rnd(k++) * 3, 12, 15);
        _windows.add((r, _rnd(k++) < 0.6));
        // Gömme: koyu oyuk, üstünde taş lento.
        c.drawRect(r.inflate(2), Paint()..color = const Color(0xFF0A0D13));
        c.drawRect(
          Rect.fromLTWH(r.left - 4, r.top - 5, r.width + 8, 3.5),
          Paint()..color = const Color(0xFF283141),
        );
      }
    }
    // Ahır kapısı: setin dibinde, kemerli, ahşap.
    final dx = w * (0.25 + 0.5 * _rnd(k++));
    final door = Path()
      ..moveTo(dx - 10, h)
      ..lineTo(dx - 10, h - 26)
      ..quadraticBezierTo(dx, h - 38, dx + 10, h - 26)
      ..lineTo(dx + 10, h)
      ..close();
    c.drawPath(door, Paint()..color = const Color(0xFF231A13));
    c.drawLine(
      Offset(dx, h - 32),
      Offset(dx, h),
      Paint()
        ..color = const Color(0xFF15100C)
        ..strokeWidth = 1,
    );
    // Ay soldan: sol kenarda dar ışık.
    c.drawLine(
      const Offset(0.7, 0),
      Offset(0.7, house),
      Paint()
        ..color = const Color(0x40DCE6FF)
        ..strokeWidth = 1,
    );
    // Toprak dam: kalın kiriş, önünden ardıç direklerinin yuvarlak uçları.
    c.drawRect(Rect.fromLTWH(-5, -2, w + 10, 6), wood);
    final pole = Paint()..color = const Color(0xFF3A2C20);
    for (var x = 2.0; x < w; x += 9 + _rnd(k++) * 3) {
      c.drawCircle(Offset(x, 1), 1.9, pole);
    }
    // Damın karı: kalın, tümsekli; kenarlardan taşıp kıvrılır.
    final snow = Path()..moveTo(-8, 2);
    snow.quadraticBezierTo(-10, -4, -4, -7);
    for (var x = -4.0; x <= w + 4; x += 8) {
      snow.lineTo(x, -8 - _rnd(k++) * 4);
    }
    snow
      ..quadraticBezierTo(w + 10, -4, w + 8, 2)
      ..lineTo(w + 6, -2)
      ..lineTo(-6, -2)
      ..close();
    c.drawPath(snow, Paint()..color = const Color(0xFF8C9AB0));
    final rim = Path()..moveTo(-8, 2);
    rim.quadraticBezierTo(-10, -4, -4, -7);
    c.drawPath(
      rim,
      Paint()
        ..color = const Color(0x99DCE6FF)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
    // Saçaktan sarkan buzlar.
    final ice = Paint()..color = const Color(0xCCB8CCDC);
    for (var x = 4.0; x < w - 2; x += 6 + _rnd(k++) * 10) {
      final len = 3 + _rnd(k++) * 9;
      c.drawPath(
        Path()
          ..moveTo(x - 1.4, 4)
          ..lineTo(x + 1.4, 4)
          ..lineTo(x, 4 + len)
          ..close(),
        ice,
      );
    }
    return rec.endRecording();
  }

  @override
  void render(Canvas canvas) {
    final pic = _static ??= _record();
    canvas.drawPicture(pic);
    // Pencereler: yanık olanlarda ocağın ışığı titrer; eşiklerde kar.
    final flick = 0.75 + 0.25 * math.sin(_t * 5.3 + position.x);
    final frame = Paint()
      ..color = const Color(0xFF2A1C12)
      ..strokeWidth = 1.6;
    final sill = Paint()..color = const Color(0xFF8C9AB0);
    for (final (r, lit) in _windows) {
      if (lit) {
        canvas.drawRect(
          r.inflate(5),
          Paint()
            ..color = const Color(0xFFE8A050).withValues(alpha: 0.08 * flick),
        );
        canvas.drawRect(
          r,
          Paint()
            ..color = const Color(0xFFE8A050).withValues(alpha: 0.6 * flick),
        );
        // Ahşap kafes: bir dikey, bir yatay kayıt.
        canvas.drawLine(r.topCenter, r.bottomCenter, frame);
        canvas.drawLine(r.centerLeft, r.centerRight, frame);
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(r.left - 3, r.bottom + 1, r.width + 6, 3),
          const Radius.circular(1.5),
        ),
        sill,
      );
    }
  }
}
