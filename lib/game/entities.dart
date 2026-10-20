import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'audio.dart';
import 'golge_game.dart';
import 'level.dart';
import 'mechanics.dart';
import 'palette.dart';
import 'player.dart';

// ================================================================ Fenerci

enum GuardState { patrol, pause, alert, chase, investigate }

/// Elinde fenerle devriye gezen Kandilci.
///
/// Oyuncuyu ışık konisinde görünce hemen saldırmaz: önce şüphelenir ("?"),
/// durup bakar. Şüphe dolarsa "!" ile kovalar. Ses ve ateşböceği ışığı onu
/// o yöne çeker.
class Guard extends PositionComponent with HasGameReference<GolgeGame> {
  Guard(Vector2 cell)
    : super(
        position: Level.standOn(cell, gw, gh),
        size: Vector2(gw, gh),
        priority: 15,
      );

  static const double gw = 24;
  static const double gh = 50;
  static const double patrolSpeed = 45;
  static const double chaseSpeed = 130;
  static const double viewDistance = 240;

  GuardState state = GuardState.patrol;
  int facing = -1;
  double suspicion = 0;
  double _t = 0;
  double _anim = 0;
  double _lost = 0;
  double _lastSeenX = 0;
  double? _investigateX;
  FireflyLure? _lure;

  Level get level => game.level;

  void _setState(GuardState s) {
    state = s;
    _t = 0;
  }

  bool get _calmPatrol =>
      state == GuardState.patrol || state == GuardState.pause;

  bool get _calm =>
      state == GuardState.patrol ||
      state == GuardState.pause ||
      state == GuardState.investigate;

  /// Çöken tahtayla düşüyor: feneri suda söner, bir daha görünmez.
  bool falling = false;
  double _vy = 0;

  void fall() {
    if (falling) return;
    falling = true;
    _vy = -60;
    suspicion = 0;
  }

  void _updateFall(double dt) {
    _vy = math.min(_vy + 1100 * dt, 700);
    position.y += _vy * dt;
    final feet = position.y + gh;
    final ch = level.cellAt(center.x, feet);
    if (ch == 'w' || feet > level.pixelHeight + 60) {
      GameAudio.instance.play('splash');
      GameAudio.instance.play('fizzle', volume: 0.8);
      removeFromParent();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (falling) {
      _updateFall(dt);
      return;
    }
    final p = game.player;
    if (p == null) return;
    // Ateşböceği ışığı her şeyden önce gelir: kovalarken bile dikkati dağılır.
    if (state != GuardState.alert && !distracted) _noticeLure();
    final sees = !game.cinematic && !distracted && _canSee(p);
    if (sees) _lastSeenX = p.center.x;

    // Şüphe: görünür kaldıkça dolar, gözden kaybolunca yavaşça söner.
    if (sees && suspicion == 0 && _calm) {
      GameAudio.instance.play('suspect', volume: 0.7, minGapMs: 1500);
    }
    if (sees) {
      final near = (p.center.x - center.x).abs() < 110;
      suspicion = math.min(1, suspicion + dt * (near ? 2.4 : 1.15));
    } else {
      suspicion = math.max(0, suspicion - dt * 0.55);
    }
    if (_calm && suspicion >= 1) {
      _setState(GuardState.alert);
      GameAudio.instance.play('alert', minGapMs: 1200);
      game.scare(0.3, sting: false);
    }

    // Şüphelenen Kandilci durur ve oyuncunun olduğu yere bakar.
    final staring = _calm && sees;
    if (staring) facing = _lastSeenX >= center.x ? 1 : -1;

    switch (state) {
      case GuardState.patrol:
        if (!staring) {
          _anim += dt;
          if (!_walk(patrolSpeed * dt)) _setState(GuardState.pause);
        }
      case GuardState.pause:
        if (!staring && _t > 1.4) {
          facing = -facing;
          _setState(GuardState.patrol);
        }
      case GuardState.investigate:
        if (staring) break;
        final lure = _lure;
        final targetX = (lure != null && lure.isMounted)
            ? lure.position.x
            : _investigateX;
        if (targetX != null) {
          final dx = targetX - center.x;
          if (dx.abs() > 3) facing = dx > 0 ? 1 : -1;
          if (dx.abs() > (lure != null ? 40 : 12) &&
              _walk(math.min(patrolSpeed * 1.4 * dt, dx.abs()))) {
            _anim += dt * 1.3;
            _t = 0;
          } else if (lure == null || !lure.isMounted) {
            // Sesin geldiği yere vardı: bir süre bakınır.
            _investigateX = null;
            _t = 0;
          } else {
            _t = 0;
          }
        } else if (_t > 2.2) {
          _lure = null;
          _setState(GuardState.pause);
        } else {
          // Etrafa bakınır.
          if ((_t * 1.2).floor().isOdd != (facing > 0)) facing = -facing;
        }
      case GuardState.alert:
        facing = _lastSeenX >= center.x ? 1 : -1;
        if (_t > 0.4) {
          _lost = 0;
          _setState(GuardState.chase);
        }
      case GuardState.chase:
        if (p.isDead) {
          suspicion = 0;
          _setState(GuardState.pause);
          break;
        }
        // Gördüğü son yere koşar; saklanan oyuncunun yerini bilemez.
        final dx = _lastSeenX - center.x;
        if (dx.abs() > 4) facing = dx > 0 ? 1 : -1;
        if (dx.abs() > 6) {
          _anim += dt * 2;
          _walk(math.min(chaseSpeed * dt, dx.abs()));
        }
        _lost = sees ? 0 : _lost + dt;
        if (_lost > 1.6) {
          suspicion = 0.5;
          _investigateX = _lastSeenX;
          _setState(GuardState.investigate);
        }
    }

    // Saklanan oyuncunun önünden geçip gider; yalnızca onu az önce görmüşse
    // ya da oyuncu açıktaysa yakalar.
    final justSaw = state == GuardState.chase && _lost < 0.4;
    if (!p.isDead &&
        !distracted &&
        (!p.hidden || justSaw) &&
        p.toRect().deflate(2).overlaps(toRect().deflate(4))) {
      p.die(cause: DeathCause.light);
      suspicion = 0;
      _setState(GuardState.pause);
    }
  }

  /// Oyuncunun çıkardığı sesler: yakındaysa Kandilci o yöne gider.
  void hear(Vector2 from, double radius) {
    if (!_calm) return;
    // Tipide kar bütün sesleri yutar.
    if (game.blizzard > 0.5) return;
    final d = from - center;
    if (d.x.abs() > radius || d.y.abs() > 220) return;
    _lure = null;
    _investigateX = from.x;
    suspicion = math.max(suspicion, 0.35);
    _setState(GuardState.investigate);
  }

  /// Bir ateşböceğinin ışığına dalmış: bu sırada çocuğu görmez, ona değse
  /// bile yakalamaz.
  bool get distracted =>
      state == GuardState.investigate &&
      _lure != null &&
      _lure!.isMounted &&
      _lure!.glowing;

  void _noticeLure() {
    final range = state == GuardState.chase ? 260.0 : 380.0;
    for (final lure in game.world.children.whereType<FireflyLure>()) {
      if (!lure.glowing) continue;
      final d = lure.position - center;
      if (d.length > range || d.y.abs() > 160) continue;
      _lure = lure;
      _investigateX = null;
      suspicion = 0;
      _setState(GuardState.investigate);
      return;
    }
  }

  /// Yürüyebildiyse true; duvar ya da uçurum varsa false.
  bool _walk(double dist) {
    final front = facing > 0 ? position.x + gw + dist : position.x - dist;
    final c = (front / kTile).floor();
    final r0 = ((position.y + 1) / kTile).floor();
    final r1 = ((position.y + gh - 1) / kTile).floor();
    for (var r = r0; r <= r1; r++) {
      if (level.solid(c, r)) return false;
    }
    // Sandıklar ve sürgü taşları geçişi keser.
    final ahead = Rect.fromLTWH(
      facing > 0 ? position.x + gw : position.x - dist,
      position.y + 4,
      dist,
      gh - 8,
    );
    if (game.world.children.whereType<Crate>().any(
      (k) => k.toRect().overlaps(ahead),
    )) {
      return false;
    }
    final below = level.cell(c, ((position.y + gh + 1) / kTile).floor());
    // Çürük tahtaya devriyede basmaz; bir şeyin peşine düşünce basar.
    final rotten = below == 'u' && !_calmPatrol;
    if (below != '#' && below != '=' && !rotten) return false;
    position.x += facing * dist;
    return true;
  }

  Vector2 get lanternWorld => _lantern;
  double get coneRange =>
      state == GuardState.chase ? viewDistance * 1.4 : viewDistance;

  /// Asanın ucunda sallanan fener.
  Vector2 get _lantern =>
      Vector2(position.x + gw / 2 + facing * 19, position.y + 14);

  bool _canSee(Player p) {
    if (p.isDead || p.hidden) return false;
    final eye = _lantern;
    final target = p.center;
    final dx = target.x - eye.x;
    final dy = target.y - eye.y;
    var range = state == GuardState.chase ? viewDistance * 1.4 : viewDistance;
    // Çömelip kavanozunu örten ya da parmak ucunda yürüyen çocuk zor seçilir.
    if (state != GuardState.chase) {
      if (p.crouching) {
        range *= 0.5;
      } else if (p.sneaking) {
        range *= 0.7;
      }
    }
    // Tipide fener ışığı karda boğulur.
    range *= 1 - 0.55 * game.blizzard;
    if (dx * facing < -8) return false;
    if (dx.abs() > range) return false;
    if (dy.abs() > dx.abs() * 0.5 + 34) return false;
    // Otların içinde ama hareket ediyorsa: sadece yakından fark edilir.
    if (p.inShadow && dx.abs() > range * 0.45) return false;
    return level.lineOfSight(eye, target);
  }

  static final _ink = Paint()..color = kInk;
  static final _stroke = Paint()
    ..color = kInk
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void render(Canvas canvas) {
    final alert = state == GuardState.alert || state == GuardState.chase;
    canvas.save();
    if (facing < 0) {
      canvas.translate(gw, 0);
      canvas.scale(-1, 1);
    }
    final sway = math.sin(_anim * 3 + 1) * 1.2;
    final lantern = Offset(gw / 2 + 19 + sway, 14);

    // Fener konuşur: şüphe arttıkça ışık beyazlaşır ve sertleşir; görünce
    // titreşerek parlar. ("?" ve "!" işaretleri yok.)
    final doubt = state == GuardState.investigate ? 0.6 : suspicion;
    final flicker = alert
        ? 0.88 + 0.12 * math.sin(_t * 31) * math.sin(_t * 7)
        : 1.0;
    final beam = Color.lerp(
      kCold,
      const Color(0xFFF2FFFC),
      alert ? 0.8 : doubt * 0.6,
    )!;
    final beamAlpha =
        (alert ? 0.42 : (distracted ? 0.07 : 0.14 + doubt * 0.16)) * flicker;

    // Işık konisi.
    final range = state == GuardState.chase ? viewDistance * 1.4 : viewDistance;
    final cone = Path()
      ..moveTo(lantern.dx, lantern.dy - 3)
      ..lineTo(lantern.dx + range, lantern.dy - range * 0.5 - 34)
      ..lineTo(lantern.dx + range, lantern.dy + range * 0.5 + 34)
      ..lineTo(lantern.dx, lantern.dy + 3)
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..shader = ui.Gradient.linear(lantern, lantern + Offset(range, 0), [
          beam.withValues(alpha: beamAlpha),
          beam.withValues(alpha: 0),
        ]),
    );
    final halo = 30 + doubt * 14 + (alert ? 22 : 0);
    canvas.drawCircle(
      lantern,
      halo,
      Paint()
        ..shader = ui.Gradient.radial(lantern, halo, [
          beam.withValues(alpha: 0.55 * flicker),
          beam.withValues(alpha: 0),
        ]),
    );

    // Bacaklar ve çizmeler: uzun paltonun altından görünür.
    final step = math.sin(_anim * 7);
    _stroke.strokeWidth = 3;
    final f1 = Offset(9 + step * 3, gh);
    final f2 = Offset(14 - step * 3, gh);
    canvas.drawLine(const Offset(9, 40), f1, _stroke);
    canvas.drawLine(const Offset(14, 40), f2, _stroke);
    canvas.drawOval(
      Rect.fromCenter(center: f1.translate(1.5, -1), width: 6, height: 3),
      _ink,
    );
    canvas.drawOval(
      Rect.fromCenter(center: f2.translate(1.5, -1), width: 6, height: 3),
      _ink,
    );

    // Kambur sırtlı, etekleri yırtık uzun palto; yürürken etek salınır.
    final hem = math.sin(_anim * 7) * 1.2;
    canvas.drawPath(
      Path()
        ..moveTo(6, 17)
        ..quadraticBezierTo(-1, 20, 1.5, 31)
        ..lineTo(0.5 - hem, 44)
        ..lineTo(4, 41)
        ..lineTo(7 - hem * 0.5, 45)
        ..lineTo(10, 41)
        ..lineTo(13 + hem * 0.5, 45)
        ..lineTo(16, 41)
        ..lineTo(19 + hem, 45)
        ..lineTo(22, 42)
        ..lineTo(21, 27)
        ..quadraticBezierTo(22, 18, 16, 15)
        ..close(),
      _ink,
    );
    // Kemer ve sallanan anahtarlar.
    canvas.drawRect(
      const Rect.fromLTWH(2, 29, 19, 2),
      Paint()..color = const Color(0xFF1C1418),
    );
    final keys = Paint()..color = const Color(0xFF4A4A52);
    canvas.drawCircle(Offset(6 + step * 0.6, 33), 1.3, keys);
    canvas.drawCircle(Offset(8 + step * 0.4, 34.2), 1.1, keys);

    // Sivri, arkaya bükülen başlık; yüzün karanlığında iki soğuk göz.
    canvas.drawPath(
      Path()
        ..moveTo(8, 18)
        ..quadraticBezierTo(5, 7, -1, -4)
        ..quadraticBezierTo(11, -1, 18, 6)
        ..quadraticBezierTo(22, 12, 17, 17)
        ..close(),
      _ink,
    );
    final eye = Paint()
      ..color = beam.withValues(
        alpha: alert ? flicker : (distracted ? 0.35 : 0.6 + doubt * 0.4),
      );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(15.4, 9.6), width: 2.6, height: 1.2),
      eye,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(18.2, 10), width: 2.2, height: 1.1),
      eye,
    );

    // Asa: ucundaki kancada fener sallanır.
    _stroke.strokeWidth = 1.8;
    canvas.drawLine(const Offset(17, 46), const Offset(29, 2), _stroke);
    canvas.drawArc(
      const Rect.fromLTWH(28, 1, 5, 5),
      math.pi,
      math.pi * 0.9,
      false,
      _stroke..strokeWidth = 1.4,
    );
    _stroke.strokeWidth = 3;
    canvas.drawLine(const Offset(15, 19), const Offset(23, 25), _stroke);
    canvas.drawCircle(const Offset(23.5, 25), 2, _ink);
    canvas.drawLine(
      const Offset(32.5, 4),
      lantern.translate(0, -5),
      _stroke..strokeWidth = 1,
    );
    canvas.drawPath(
      Path()
        ..moveTo(lantern.dx - 4, lantern.dy - 4)
        ..lineTo(lantern.dx, lantern.dy - 7)
        ..lineTo(lantern.dx + 4, lantern.dy - 4)
        ..close(),
      _ink,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: lantern, width: 7, height: 9),
        const Radius.circular(2),
      ),
      Paint()..color = beam.withValues(alpha: 0.95 * flicker),
    );
    canvas.drawLine(
      lantern.translate(0, -4.5),
      lantern.translate(0, 4.5),
      _stroke..strokeWidth = 0.8,
    );
    canvas.restore();
  }
}

// ================================================================= Hüdhüd

/// Sâye'ye yol gösteren Hüdhüd (Attar'ın Mantıku't-Tayr'ındaki rehber kuş):
/// soluk tüyler, yelpaze tepelik, ince uzun gaga. Bölümdeki konaklarını sırayla dolaşır: bir
/// konakta oturup çocuğu bekler, yaklaşınca dönüp ona bakar ve bir sonraki
/// önemli yere (zincir, sandık, kol…) sakince uçar. Son konaktan sonra ışık
/// kapısına girip kaybolur.
class Bird extends PositionComponent with HasGameReference<GolgeGame> {
  Bird(this.stops, this.exit, {int start = 0})
    : _index = start,
      super(position: stops[start].clone(), priority: 18);

  static const double scaleArt = 0.7;
  static const double speed = 95;

  /// Konakların "ayak" noktaları, ilerleme sırasına göre.
  final List<Vector2> stops;
  final Vector2 exit;
  int _index;
  bool _flying = false;
  bool _leaving = false;
  final _from = Vector2.zero();
  final _to = Vector2.zero();
  double _flyT = 0;
  double _flyDur = 1;
  double _t = math.Random().nextDouble() * 5;
  double _alpha = 1;
  int _look = 1;

  /// Oyuncunun yeniden doğduğu yere göre ilk konağı seçer.
  static int startFor(
    List<Vector2> stops,
    Vector2 player,
    double Function(Vector2) progress,
  ) {
    final p = progress(player);
    for (var i = 0; i < stops.length; i++) {
      if (progress(stops[i]) >= p - 10) return i;
    }
    return stops.length - 1;
  }

  void _flyTo(Vector2 target) {
    _from.setFrom(position);
    _to.setFrom(target);
    _flyT = 0;
    _flyDur = ((target - position).length / speed).clamp(0.8, 4.5);
    _flying = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (_flying) {
      _flyT += dt;
      final k = (_flyT / _flyDur).clamp(0.0, 1.0);
      final eased = k * k * (3 - 2 * k);
      final d = _to - _from;
      final arc = math.min(70.0, d.length * 0.3);
      position
        ..setFrom(_from + d * eased)
        ..y -= math.sin(k * math.pi) * arc;
      _look = d.x >= 0 ? 1 : -1;
      if (k >= 1) {
        _flying = false;
        if (_leaving) _alpha = 0.999;
      }
      return;
    }
    if (_leaving) {
      _alpha -= dt * 1.2;
      if (_alpha <= 0) removeFromParent();
      return;
    }
    if (p == null || p.isDead) return;
    // Konakta: çocuğa bakar, o yaklaşınca ya da geçince bir sonrakine uçar.
    _look = p.center.x >= position.x ? 1 : -1;
    final near = (p.center - position).length < 120;
    final passed =
        game.level.progressOf(p.center) > game.level.progressOf(position) + 24;
    if (near || passed) {
      if (_index + 1 < stops.length) {
        _index++;
        _flyTo(stops[_index]);
      } else {
        _leaving = true;
        _flyTo(exit);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final a = _alpha.clamp(0.0, 1.0);
    final pale = Paint()..color = _pale.withValues(alpha: a);
    final band = Paint()..color = _band.withValues(alpha: a);
    canvas.save();
    canvas.scale(scaleArt);
    glowDot(canvas, const Offset(0, -8), 24, kLight, 0.26 * a);
    if (_look < 0) canvas.scale(-1, 1);
    final bob = _flying ? 0.0 : math.sin(_t * 2) * 0.6;
    canvas.translate(0, bob);

    // Kuyruk: uzun, ucunda koyu bir bant.
    canvas.drawPath(
      Path()
        ..moveTo(-5, -8)
        ..lineTo(-14, -6)
        ..lineTo(-13, -3)
        ..lineTo(-5, -5)
        ..close(),
      pale,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-11.5, -6.4)
        ..lineTo(-14, -6)
        ..lineTo(-13, -3)
        ..lineTo(-11, -3.6)
        ..close(),
      band,
    );
    // Gövde.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -6.5), width: 13, height: 8),
      pale,
    );

    // Baş: hafifçe eğilir; tepelik konakta yelpaze gibi açılıp kapanır.
    final nod = _flying ? 0.0 : math.max(0.0, math.sin(_t * 1.3)) * 1.4;
    final head = Offset(5.5, -10.5 + nod);
    final open = _flying
        ? 0.15
        : (0.35 + 0.65 * math.max(0.0, math.sin(_t * 0.7 + 1))).clamp(0.0, 1.0);
    for (var i = 0; i < 5; i++) {
      // Arkaya yatık (kapalı) ile dikilmiş (açık) arasında.
      final rest = math.pi * (1.05 + i * 0.04);
      final up = math.pi * (1.15 + i * 0.13);
      final ang = rest + (up - rest) * open;
      final len = 5.5 + (i == 2 ? 1.2 : 0) + open * 1.5;
      final tip = head + Offset(math.cos(ang), math.sin(ang)) * len;
      final side = Offset(-math.sin(ang), math.cos(ang)) * 0.9;
      canvas.drawPath(
        Path()
          ..moveTo(head.dx + side.dx, head.dy + side.dy - 1)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(head.dx - side.dx, head.dy - side.dy - 1)
          ..close(),
        pale,
      );
      canvas.drawCircle(tip, 0.8, band);
    }
    canvas.drawCircle(head, 3.2, pale);
    // İnce, uzun, hafif kıvrık gaga.
    canvas.drawPath(
      Path()
        ..moveTo(head.dx + 2.6, head.dy - 0.9)
        ..quadraticBezierTo(
          head.dx + 7,
          head.dy - 0.4,
          head.dx + 10,
          head.dy + 1.6,
        )
        ..quadraticBezierTo(
          head.dx + 6.5,
          head.dy + 0.7,
          head.dx + 2.6,
          head.dy + 0.8,
        )
        ..close(),
      pale,
    );
    canvas.drawCircle(head + const Offset(1.1, -0.6), 0.65, band);

    if (_flying) {
      // Geniş, yuvarlak kanatlar; üstünde çizgili bantlar.
      final flap = math.sin(_t * 12) * 9;
      for (final sc in [1.0, 0.7]) {
        final wing = Path()
          ..moveTo(-4, -7)
          ..quadraticBezierTo(-6, -13 - flap * sc, -2, -18 - flap * sc)
          ..quadraticBezierTo(4, -15 - flap * sc, 4, -7)
          ..close();
        canvas.drawPath(wing, pale);
        for (var k = 0; k < 3; k++) {
          final f = 0.45 + k * 0.18;
          canvas.drawLine(
            Offset(-4 + 2 * f, -7 - (11 + flap * sc) * f),
            Offset(4 - 1.5 * f, -7 - (8 + flap * sc) * f),
            band..strokeWidth = 1,
          );
        }
      }
    } else {
      // Kapalı kanat: sırtta zebra çizgileri.
      canvas.drawPath(
        Path()
          ..moveTo(-5, -8)
          ..quadraticBezierTo(0, -10.5, 3.5, -6.5)
          ..lineTo(-5, -5)
          ..close(),
        Paint()..color = _shade.withValues(alpha: a),
      );
      for (final x in [-3.6, -1.6, 0.4]) {
        canvas.drawLine(
          Offset(x, -8.6),
          Offset(x - 0.8, -5.4),
          band..strokeWidth = 1.1,
        );
      }
      final leg = Paint()
        ..color = _pale.withValues(alpha: a * 0.8)
        ..strokeWidth = 0.9;
      canvas.drawLine(const Offset(-1, -2.5), const Offset(-1.5, 1), leg);
      canvas.drawLine(const Offset(2, -2.5), const Offset(2, 1), leg);
    }
    canvas.restore();
  }

  static const _pale = Color(0xFFF1E6D2);
  static const _shade = Color(0xFFC9B9A0);
  static const _band = Color(0xFF3A2A20);
}

// ======================================================= Ateşböceği sürüsü

/// Karanlıkta dans eden küçük bir ateşböceği sürüsü: yanından geçen çocuk
/// kavanozuna bir tane alır.
class FireflySwarm extends PositionComponent with HasGameReference<GolgeGame> {
  FireflySwarm(Vector2 cell)
    : super(position: cell + Vector2(kTile / 2, kTile / 2), priority: 19);

  double _t = math.Random().nextDouble() * 9;
  bool _taken = false;
  double _gone = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_taken) {
      _gone += dt;
      if (_gone > 0.8) removeFromParent();
      return;
    }
    final p = game.player;
    if (p == null || p.isDead) return;
    if ((p.center - position).length < 26 &&
        game.fireflies < GolgeGame.maxFireflies) {
      _taken = true;
      game.gainFirefly();
    }
  }

  double get strength => _taken ? (1 - _gone / 0.8).clamp(0.0, 1.0) : 1;

  @override
  void render(Canvas canvas) {
    final a = strength;
    for (var i = 0; i < 5; i++) {
      final ph = _t * (0.9 + i * 0.23) + i * 1.7;
      final o = _taken
          ? Offset(math.sin(ph) * 6, -_gone * 40 - i * 3)
          : Offset(math.sin(ph) * 9, math.cos(ph * 1.3) * 7);
      final blink = 0.5 + 0.5 * math.sin(_t * 6 + i * 2.3);
      glowDot(canvas, o, 5.5, const Color(0xFFFFC46B), 0.45 * blink * a);
      canvas.drawCircle(
        o,
        1,
        Paint()
          ..color = const Color(0xFFFFF2C8)
              .withValues(alpha: (0.4 + 0.6 * blink) * a),
      );
    }
  }
}

// ========================================================== Hatıra parçası

class MemoryShard extends PositionComponent with HasGameReference<GolgeGame> {
  MemoryShard(Vector2 cell, this.index)
    : super(position: cell + Vector2.all(kTile / 2), priority: 18);

  final int index;
  double _t = math.Random().nextDouble() * 6;
  bool _taken = false;
  double _burst = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_taken) {
      _burst += dt;
      if (_burst > 0.9) removeFromParent();
      return;
    }
    final p = game.player;
    if (p != null && !p.isDead && (p.center - position).length < 24) {
      _taken = true;
      game.collectMemory(index);
    }
  }

  @override
  void render(Canvas canvas) {
    if (_taken) {
      final k = _burst / 0.9;
      canvas.drawCircle(
        Offset.zero,
        6 + k * 70,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * (1 - k) + 0.5
          ..color = kWarmLight.withValues(alpha: (1 - k) * 0.8),
      );
      return;
    }
    final y = math.sin(_t * 2) * 4;
    final c = Offset(0, y);
    final pulse = 0.75 + math.sin(_t * 3.3) * 0.25;
    canvas.drawCircle(
      c,
      22,
      Paint()
        ..shader = ui.Gradient.radial(c, 22, [
          kWarmLight.withValues(alpha: 0.45 * pulse),
          kWarmLight.withValues(alpha: 0),
        ]),
    );
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(_t * 0.8);
    canvas.drawPath(
      Path()
        ..moveTo(0, -6)
        ..lineTo(4, 0)
        ..lineTo(0, 6)
        ..lineTo(-4, 0)
        ..close(),
      Paint()..color = kWarmLight,
    );
    canvas.restore();
  }
}

// ============================================================ Işık kapısı

class ExitPortal extends PositionComponent with HasGameReference<GolgeGame> {
  ExitPortal(Vector2 cell)
    : super(
        position: Vector2(cell.x, cell.y - kTile),
        size: Vector2(kTile, kTile * 2),
        priority: 5,
      );

  double _t = 0;
  bool _done = false;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (_done || p == null || p.isDead) return;
    final door = Rect.fromLTWH(
      position.x + 8,
      position.y,
      kTile - 16,
      kTile * 2,
    );
    if (door.overlaps(p.toRect())) {
      _done = true;
      game.onExitReached();
    }
  }

  @override
  void render(Canvas canvas) {
    const c = Offset(kTile / 2, kTile);
    final pulse = 0.85 + math.sin(_t * 1.7) * 0.15;
    canvas.drawCircle(
      c,
      130,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          130,
          [
            kWarmLight.withValues(alpha: 0.42 * pulse),
            kWarmLight.withValues(alpha: 0.10 * pulse),
            kWarmLight.withValues(alpha: 0),
          ],
          [0, 0.35, 1],
        ),
    );
    final door = RRect.fromLTRBAndCorners(
      3,
      0,
      kTile - 3,
      kTile * 2,
      topLeft: const Radius.circular(13),
      topRight: const Radius.circular(13),
    );
    canvas.drawRRect(
      door,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, kTile * 2), [
          kWarmLight,
          kWarmLight.withValues(alpha: 0.75),
        ]),
    );
    final mote = Paint()..color = kWarmLight.withValues(alpha: 0.8);
    for (var i = 0; i < 7; i++) {
      final k = ((_t * 0.25 + i / 7) % 1.0);
      final x = kTile / 2 + math.sin(i * 2.1 + _t) * 22;
      canvas.drawCircle(
        Offset(x, kTile * 2 - k * 110),
        1.4 * (1 - k) + 0.3,
        mote,
      );
    }
  }
}

// ======================================================== Ateşböceği yemi

/// Kavanozdan salınan ateşböceği: ileri uçar, bir süre havada süzülüp parlar.
/// Kandilciler ışığını görünce ona yönelir.
class FireflyLure extends PositionComponent with HasGameReference<GolgeGame> {
  FireflyLure(Vector2 from, int direction)
    : _vel = Vector2(direction * 380.0, -80),
      super(position: from.clone(), priority: 22);

  static const double life = 5.5;
  final Vector2 _vel;
  double _t = 0;

  bool get glowing => _t < life - 0.6;
  double get strength =>
      (1 - ((_t - (life - 1.2)) / 1.2).clamp(0.0, 1.0)) *
      (0.85 + 0.15 * math.sin(_t * 13));

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t < 0.9) {
      final next = position + _vel * dt;
      if (game.level.cellAt(next.x, next.y) == '#') {
        _vel.setZero();
      } else {
        position.setFrom(next);
      }
      _vel.scale(math.pow(0.3, dt).toDouble());
    } else {
      position.y += math.sin(_t * 2.4) * 8 * dt;
      position.x += math.cos(_t * 1.7) * 6 * dt;
    }
    if (_t > life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = strength.clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset.zero,
      26,
      Paint()
        ..shader = ui.Gradient.radial(Offset.zero, 26, [
          kWarmLight.withValues(alpha: 0.5 * a),
          kWarmLight.withValues(alpha: 0),
        ]),
    );
    canvas.drawCircle(
      Offset.zero,
      2.2,
      Paint()..color = const Color(0xFFFFF6D8).withValues(alpha: a),
    );
  }
}

// ================================================================== Sandık

/// İtilebilir ahşap sandık: üstüne çıkılır, yüksek yerlere basamak olur.
class Crate extends PositionComponent with HasGameReference<GolgeGame> {
  Crate(Vector2 cell)
    : super(
        position: Vector2(cell.x + 1, cell.y + kTile - side),
        size: Vector2.all(side),
        priority: 17,
      );

  static const double side = 30;
  double _vy = 0;
  Deck? _riding;

  /// Üstünde durduğu hareketli zemin (asansör ağırlığı için).
  Deck? get riding => _riding;

  Level get level => game.level;

  /// [dir] yönünde ilerlerken [r] alanı engelli mi? Geride kalan (ya da
  /// iç içe geçmiş ama uzaklaşılan) sandık engel sayılmaz: iki sandık bir
  /// kez değince bir daha hiç ayrılamıyordu.
  bool _blockedAt(Rect r, {double dir = 0}) {
    if (level.rectSolid(r.left, r.top, r.right, r.bottom)) return true;
    for (final g in game.world.children.whereType<Gate>()) {
      if (g.solid && g.toRect().overlaps(r)) return true;
    }
    for (final c in game.world.children.whereType<Crate>()) {
      if (c == this || !c.toRect().overlaps(r)) continue;
      if (dir != 0 && (c.center.x - center.x) * dir <= 0) continue;
      return true;
    }
    return false;
  }

  /// İtilmeye çalışılır; gerçekte ne kadar kaydığını döndürür. Önündeki
  /// sandığı da (en çok üç sandık) birlikte iter.
  double push(double dx, {int depth = 0}) {
    if (_vy.abs() > 1 || dx == 0) return 0;
    final target = toRect().shift(Offset(dx, 0)).deflate(0.5);
    if (depth < 3) {
      for (final c in game.world.children.whereType<Crate>().toList()) {
        if (c == this || !c.toRect().overlaps(target)) continue;
        if ((c.center.x - center.x) * dx <= 0) continue;
        // Öndeki sandık, bu sandığın varacağı yerin dışına kadar itilir
        // (iç içe geçmiş kalmasın).
        final r = c.toRect();
        final need = dx > 0 ? target.right - r.left : target.left - r.right;
        c.push(need, depth: depth + 1);
      }
    }
    if (_blockedAt(target, dir: dx)) {
      // Küçük bir basamağı (çukura oturmuş sandığın kenarı) aşar.
      final up = target.shift(const Offset(0, -3));
      if (_blockedAt(up, dir: dx)) return 0;
      position.y -= 3;
    }
    position.x += dx;
    return dx;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Uzun bir kare (ör. yükleme) sandığı zeminin içinden geçirmesin.
    dt = math.min(dt, 1 / 30);
    final deck = _riding;
    if (deck != null && deck.isMounted && deck.active) position.add(deck.delta);
    _riding = null;
    final prevBottom = position.y + side;
    _vy = math.min(_vy + 1900 * dt, 900);
    position.y += _vy * dt;
    final bottom = position.y + side;
    // Değilen yüzeylerden en yüksekteki seçilir (büyük adımda hareketli
    // tahtayı geçip altındaki zemine gömülmesin).
    double? best;
    Deck? bestDeck;
    final r = ((bottom - 0.001) / kTile).floor();
    final c0 = ((position.x + 1) / kTile).floor();
    final c1 = ((position.x + side - 1) / kTile).floor();
    for (var c = c0; c <= c1; c++) {
      final ch = level.cell(c, r);
      if (ch == '#' || (ch == '=' && prevBottom <= r * kTile + 0.5)) {
        best = r * kTile.toDouble();
        break;
      }
    }
    // Başka bir sandığın üstüne oturur (çukuru dolduran sandık köprü olur).
    for (final c in game.world.children.whereType<Crate>()) {
      if (c == this) continue;
      final rect = c.toRect();
      // Birazcık örtüşse de üstüne konar (yanından kayıp iç içe geçmesin).
      if (position.x + side - 1 <= rect.left || position.x + 1 >= rect.right) {
        continue;
      }
      if (prevBottom <= rect.top + 1 &&
          position.y + side >= rect.top &&
          (best == null || rect.top < best)) {
        best = rect.top;
        bestDeck = null;
      }
    }
    for (final d in game.world.children.whereType<Deck>()) {
      if (!d.active) continue;
      final rect = d.toRect();
      if (position.x + side - 2 <= rect.left || position.x + 2 >= rect.right) {
        continue;
      }
      if (d.catches(prevBottom, position.y + side) &&
          (best == null || rect.top < best)) {
        best = rect.top;
        bestDeck = d;
      }
    }
    if (best != null) {
      position.y = best - side;
      _vy = 0;
      _riding = bestDeck;
      if (bestDeck is CrumbleRock) bestDeck.stoodOn = true;
      return;
    }
    if (position.y > level.pixelHeight + 200) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final box = Rect.fromLTWH(0, 0, side, side);
    canvas.drawRect(box, Paint()..color = const Color(0xFF2E1A10));
    // Üst ve ön kenara vuran sıcak ışık: karanlıkta da seçilsin.
    final rim = Paint()
      ..color = const Color(0xFFD08A5A).withValues(alpha: 0.55)
      ..strokeWidth = 1.6;
    canvas.drawLine(const Offset(0, 0.8), const Offset(side, 0.8), rim);
    canvas.drawLine(const Offset(0.8, 0), const Offset(0.8, side), rim);
    final plank = Paint()
      ..color = const Color(0xFF9A5A30).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRect(box.deflate(1.5), plank);
    canvas.drawLine(
      const Offset(2, 2),
      const Offset(side - 2, side - 2),
      plank,
    );
    canvas.drawLine(
      const Offset(2, side / 2),
      const Offset(side - 2, side / 2),
      plank,
    );
  }
}

// ==================================================================== Kapı

/// Demir parmaklıklı kapı: kol çekilince yukarı kalkar.
class Gate extends PositionComponent with HasGameReference<GolgeGame> {
  Gate(int col, int top, int bottom)
    : _height = (bottom - top + 1) * kTile,
      super(
        position: Vector2(col * kTile + 8, top * kTile.toDouble()),
        size: Vector2(16, (bottom - top + 1) * kTile),
        priority: 16,
      );

  final double _height;
  bool opening = false;
  double _lift = 0;

  bool get solid => _lift < _height * 0.75;

  @override
  Rect toRect() =>
      Rect.fromLTWH(position.x, position.y - _lift, size.x, size.y);

  @override
  void update(double dt) {
    super.update(dt);
    if (opening && _lift < _height) _lift = math.min(_height, _lift + dt * 70);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(0, -_lift);
    final bar = Paint()..color = const Color(0xFF0E0806);
    for (var x = 0.0; x <= 14; x += 4.6) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 2.6, _height), bar);
    }
    for (var y = 6.0; y < _height; y += 24) {
      canvas.drawRect(Rect.fromLTWH(-1, y, 18, 3), bar);
    }
    canvas.drawLine(
      const Offset(0.5, 0),
      Offset(0.5, _height),
      Paint()
        ..color = const Color(0xFF8A4A2A).withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );
    for (var x = 1.3; x <= 15; x += 4.6) {
      canvas.drawPath(
        Path()
          ..moveTo(x - 1.6, _height)
          ..lineTo(x + 1.3, _height + 5)
          ..lineTo(x + 4, _height),
        bar,
      );
    }
    canvas.restore();
  }
}

// ===================================================================== Kol

/// Duvardaki kol: oyuncu yanındayken ↑ ile çekilir, bölümdeki kapıları açar.
class Lever extends PositionComponent with HasGameReference<GolgeGame> {
  Lever(Vector2 cell)
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile),
        priority: 18,
      );

  bool pulled = false;
  double _swing = 0;
  double _t = 0;

  bool near(Vector2 p) =>
      (p - position).x.abs() < 22 && (p - position).y.abs() < 40;

  void pull() {
    if (pulled) return;
    pulled = true;
    GameAudio.instance.play('lever');
    GameAudio.instance.play('gate', volume: 0.7);
    // En yakın kapı açılır (bir bölümde birden çok kol ve kapı olabilir).
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

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (pulled) _swing = math.min(1, _swing + dt * 4);
  }

  @override
  void render(Canvas canvas) {
    final ink = Paint()..color = kInk;
    canvas.drawRect(const Rect.fromLTWH(-7, -5, 14, 5), ink);
    canvas.save();
    canvas.translate(0, -3);
    canvas.rotate(-0.7 + _swing * 1.4);
    canvas.drawRect(const Rect.fromLTWH(-1.5, -17, 3, 17), ink);
    canvas.drawCircle(const Offset(0, -17), 3, ink);
    canvas.drawCircle(
      const Offset(-0.8, -17.8),
      1.6,
      Paint()..color = const Color(0xFFD08A5A).withValues(alpha: 0.7),
    );
    canvas.restore();
    final p = game.player;
    if (!pulled && p != null && near(p.center)) {
      final a = 0.55 + 0.45 * math.sin(_t * 5);
      final arrow = Paint()
        ..color = kWarmLight.withValues(alpha: a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(0, -26), const Offset(0, -38), arrow);
      canvas.drawLine(const Offset(-4, -33), const Offset(0, -38), arrow);
      canvas.drawLine(const Offset(4, -33), const Offset(0, -38), arrow);
    }
  }
}

// ============================================================ Ses halkası

/// Oyuncunun çıkardığı sesin görsel ipucu: ayakların altında açılan halka.
class NoiseRing extends PositionComponent {
  NoiseRing(Vector2 at, this.radius)
    : super(position: at.clone(), priority: 21);

  final double radius;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > 0.5) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = _t / 0.5;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 0.5 * k,
        height: radius * 0.12 * k,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = kText.withValues(alpha: 0.35 * (1 - k)),
    );
  }
}
