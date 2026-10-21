import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'audio.dart';
import 'entities.dart';
import 'golge_game.dart';
import 'level.dart';
import 'levels.dart';
import 'palette.dart';
import 'player.dart';
import 'rig.dart';
import 'strings.dart';

// =============================================================== Yarasalar

/// Tavanda baş aşağı uyuyan yarasalar. Yakında koşan, gürültü yapan ya da
/// açık ışıkla yaklaşan çocuk onları ürkütür: çığlıkla uçuşurlar ve bu
/// gürültü Kandilcileri o yöne çeker.
class BatRoost extends PositionComponent with HasGameReference<GolgeGame> {
  BatRoost(Vector2 cell)
    : super(position: Vector2(cell.x + kTile / 2, cell.y + 2), priority: 23);

  final _rnd = math.Random();
  late final List<_Bat> _bats = List.generate(6, (i) {
    return _Bat(
      Offset((i - 2.5) * 6 + _rnd.nextDouble() * 3, _rnd.nextDouble() * 4),
      _rnd.nextDouble() * 6,
    );
  });
  bool flown = false;
  double _t = 0;
  double _flownAt = 0;

  void disturb() {
    if (flown) return;
    flown = true;
    _flownAt = _t;
    GameAudio.instance.play('bats');
    for (final b in _bats) {
      final a = -math.pi / 2 + (_rnd.nextDouble() - 0.5) * 2.4;
      b.vel = Offset(math.cos(a), math.sin(a)) * (120 + _rnd.nextDouble() * 80);
      // Sürü tek kütle değil: her yarasa biraz farklı anda bırakır.
      b.delay = _rnd.nextDouble() * 0.45;
    }
    game.makeNoise(position + Vector2(0, 20), 380, source: this);
  }

  void hear(Vector2 from, double radius) {
    final d = from - position;
    if (d.x.abs() < radius * 0.8 && d.y.abs() < 280) disturb();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (!flown) {
      final p = game.player;
      if (p == null || p.isDead) return;
      final dx = (p.center.x - position.x).abs();
      final dy = (p.center.y - position.y).abs();
      if (dy > 260) return;
      final loud = p.onGround && p.velocity.x.abs() > 105 && !p.covering;
      if ((dx < 150 && loud) || (dx < 60 && !p.covering)) disturb();
      return;
    }
    for (final b in _bats) {
      if (_t - _flownAt < b.delay) continue;
      b.pos += b.vel * dt;
      b.vel =
          b.vel.scale(1, 0.985) +
          Offset(math.sin(_t * 9 + b.phase) * 40 * dt, -10 * dt);
    }
    if (_t > 8) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final ink = Paint()..color = const Color(0xFF0C0706);
    for (final b in _bats) {
      if (!flown || _t - _flownAt < b.delay) {
        // Baş aşağı asılı, hafifçe sallanan damla gövdeler.
        final sway = math.sin(_t * 1.5 + b.phase) * 0.8;
        canvas.drawOval(
          Rect.fromCenter(
            center: b.pos.translate(sway, 6),
            width: 5,
            height: 9,
          ),
          ink,
        );
        canvas.drawLine(
          b.pos.translate(sway, 1.5),
          b.pos.translate(0, -1),
          ink..strokeWidth = 1,
        );
      } else {
        // Kanat: omuz, dirsek, uç. Uç dirsekten gecikerek iner (zar kanat
        // kırbaç gibi çırpar).
        final ph = _t * 30 + b.phase;
        final elbow = math.sin(ph) * 3;
        final tip = math.sin(ph - 0.7) * 5;
        final c = b.pos;
        final wing = Path()..moveTo(c.dx, c.dy);
        for (final s in [-1.0, 1.0]) {
          wing
            ..lineTo(c.dx + s * 3.5, c.dy - elbow)
            ..lineTo(c.dx + s * 8, c.dy - tip)
            ..lineTo(c.dx + s * 5.5, c.dy + 1 - elbow * 0.4)
            ..lineTo(c.dx + s * 3, c.dy + 0.5)
            ..lineTo(c.dx, c.dy);
        }
        canvas.drawPath(wing..close(), ink);
        canvas.drawOval(
          Rect.fromCenter(center: c.translate(0, 0.8), width: 3, height: 4.4),
          ink,
        );
      }
    }
  }
}

class _Bat {
  _Bat(this.pos, this.phase);
  Offset pos;
  final double phase;
  Offset vel = Offset.zero;
  double delay = 0;
}

// ================================================================= Karga

/// Çatılarda ve kayalıklarda tüneyen karga: yanından koşan çocuğu görünce
/// bağırarak havalanır ve yakındaki bekçileri uyarır.
class Crow extends PositionComponent with HasGameReference<GolgeGame> {
  Crow(Vector2 cell)
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile - 1),
        priority: 19,
      );

  bool _flying = false;
  double _t = math.Random().nextDouble() * 4;
  double _flyT = 0;
  int _look = -1;
  Offset _vel = Offset.zero;

  void scare(Vector2 from) {
    if (_flying) return;
    _flying = true;
    GameAudio.instance.play('crow');
    final dir = position.x >= from.x ? 1.0 : -1.0;
    _look = dir > 0 ? 1 : -1;
    _vel = Offset(dir * 110, -150);
    game.makeNoise(position.clone(), 260, source: this);
  }

  void hear(Vector2 from, double radius) {
    if ((from - position).length < radius * 0.6) scare(from);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_flying) {
      _flyT += dt;
      position += Vector2(_vel.dx, _vel.dy) * dt;
      _vel = _vel.translate(0, -20 * dt);
      if (_flyT > 4) removeFromParent();
      return;
    }
    final p = game.player;
    if (p == null || p.isDead) return;
    _look = p.center.x >= position.x ? 1 : -1;
    final d = (p.center - position).length;
    final loud = p.velocity.x.abs() > 105 && !p.covering;
    if ((d < 140 && loud) || d < 45) scare(p.center);
  }

  @override
  void render(Canvas canvas) {
    // Kapadokya'da kargalar değil, güvercinlik güvercinleri.
    final ink = Paint()
      ..color = game.level.def.theme == LevelTheme.peri
          ? const Color(0xFFCFC6BC)
          : kInk;
    canvas.save();
    if (_look < 0) canvas.scale(-1, 1);
    if (!_flying) {
      final peck = math.max(0.0, math.sin(_t * 1.1)) > 0.9 ? 2.0 : 0.0;
      canvas.drawOval(const Rect.fromLTWH(-6, -9, 12, 7), ink);
      canvas.drawCircle(Offset(5, -10 + peck), 2.8, ink);
      canvas.drawPath(
        Path()
          ..moveTo(7, -11 + peck)
          ..lineTo(11, -9.5 + peck)
          ..lineTo(7, -9 + peck)
          ..close(),
        ink,
      );
      canvas.drawPath(
        Path()
          ..moveTo(-5, -7)
          ..lineTo(-11, -4)
          ..lineTo(-5, -4)
          ..close(),
        ink,
      );
      canvas.drawLine(
        const Offset(-1, -2.5),
        const Offset(-1, 0),
        ink..strokeWidth = 1,
      );
      canvas.drawLine(const Offset(2, -2.5), const Offset(2, 0), ink);
      canvas.drawCircle(
        Offset(5.8, -10.8 + peck),
        0.6,
        Paint()..color = const Color(0xFFD08A5A),
      );
    } else {
      // Kalkışta ilk vuruşlar sık ve derin; aşağı vuruşta kanat açık ve
      // geniş, yukarı kalkarken dirsekten katlanır. Arada kısa süzülmeler.
      final rush = (1 - _flyT / 0.6).clamp(0.0, 1.0);
      final glide = math.max(0.0, math.sin(_flyT * 2.2)) * (1 - rush) * 0.7;
      final ph = _t * (22 + 10 * rush);
      final flap = math.sin(ph) * 7 * (1 - glide);
      final down = math.cos(ph) < 0;
      final fold = down ? 1.0 : 0.6;
      canvas.drawOval(const Rect.fromLTWH(-6, -8, 12, 6), ink);
      canvas.drawCircle(const Offset(6, -6), 2.6, ink);
      // Kuyruk tüyleri yelpaze.
      canvas.drawPath(
        Path()
          ..moveTo(-5, -6)
          ..lineTo(-11, -8 + rush * 2)
          ..lineTo(-11, -3)
          ..close(),
        ink,
      );
      canvas.drawPath(
        Path()
          ..moveTo(-3, -6)
          ..lineTo(-6 * fold, -11 - flap * 0.6)
          ..quadraticBezierTo(-9 * fold, -15 - flap, -13 * fold, -12 - flap)
          ..lineTo(-4 * fold, -8 - flap * 0.3)
          ..lineTo(3, -6)
          ..close(),
        ink,
      );
    }
    canvas.restore();
  }
}

// ================================================================== Gözcü

/// Yüksekte durup projektör ışığıyla aşağıyı tarayan Gözcü. Yürümez; ama
/// ışığında uzun kalan çocuğu yakalatır. Ateşböceği salınırsa ışığını ona
/// kilitler.
class Watcher extends PositionComponent with HasGameReference<GolgeGame> {
  Watcher(Vector2 cell)
    : super(
        position: Level.standOn(cell, 22, 52),
        size: Vector2(22, 52),
        priority: 15,
      );

  static const double beamLength = 360;
  static const double beamHalf = 0.17;

  int facing = 1;
  double suspicion = 0;
  double _t = 0;
  double _angle = 0.6;

  /// Göz önce hedefe kayar; baş ve projektör ağır ağır yetişir (ışın
  /// projektörün açısıdır).
  double _eye = 0.6;
  final _aim = Spring(stiffness: 20, damping: 7.5)..value = 0.6;

  Vector2 get lamp =>
      Vector2(position.x + size.x / 2 + facing * 10, position.y + 14);

  bool get alarmed => suspicion >= 1;

  /// Güneş huzmesi gözüne girince bir süre kör kalır.
  double dazzled = 0;

  void dazzle() {
    if (dazzled <= 0) GameAudio.instance.play('suspect', volume: 0.5);
    dazzled = 5;
    suspicion = 0;
  }

  @override
  void onMount() {
    super.onMount();
    // Bölümün ortasına bakar.
    facing = position.x < game.level.pixelWidth / 2 ? 1 : -1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;

    // Ateşböceği varsa ışığını ona kilitler.
    FireflyLure? lure;
    for (final l in game.world.children.whereType<FireflyLure>()) {
      if (l.glowing && (l.position - lamp).length < beamLength) lure = l;
    }
    double target;
    if (lure != null) {
      final d = lure.position - lamp;
      target = math.atan2(d.y, d.x * facing);
    } else {
      // Tarama: uçlarda bir an bekler (sinüs düzleştirilir), sonra döner.
      final s = math.sin(_t * 0.7);
      target = 0.6 + 0.55 * s.sign * math.pow(s.abs(), 0.55);
    }
    _eye = approach(_eye, target, dt, 0.08);
    _aim.update(target, dt);
    _angle = _aim.value;

    if (dazzled > 0) dazzled -= dt;
    if (p == null || p.isDead || game.cinematic || dazzled > 0) {
      suspicion = math.max(0, suspicion - dt);
      return;
    }
    final sees = lure == null && _inBeam(p.center) && !p.hidden;
    if (sees && suspicion == 0) {
      GameAudio.instance.play('suspect', volume: 0.7, minGapMs: 1500);
    }
    suspicion = sees
        ? math.min(1, suspicion + dt * 1.6)
        : math.max(0, suspicion - dt * 0.6);
    if (suspicion >= 1) {
      p.die(cause: DeathCause.light);
      suspicion = 0;
    }
  }

  bool _inBeam(Vector2 target) {
    final d = target - lamp;
    final dist = d.length;
    if (dist > beamLength || d.x * facing < 0) return false;
    final a = math.atan2(d.y, d.x * facing);
    if ((a - _angle).abs() > beamHalf + 8 / math.max(dist, 1)) return false;
    // Işık Gözcü'nün durduğu taşın kenarından başlar.
    final start = lamp + d.normalized() * math.min(12, dist);
    return game.level.lineOfSight(start, target);
  }

  /// Aydınlatma katmanı ve çizim için ışık üçgeni (dünya koordinatlarında).
  Path beamPath() {
    final o = lamp;
    final a1 = _angle - beamHalf;
    final a2 = _angle + beamHalf;
    return Path()
      ..moveTo(o.x, o.y)
      ..lineTo(
        o.x + facing * math.cos(a1) * beamLength,
        o.y + math.sin(a1) * beamLength,
      )
      ..lineTo(
        o.x + facing * math.cos(a2) * beamLength,
        o.y + math.sin(a2) * beamLength,
      )
      ..close();
  }

  @override
  void render(Canvas canvas) {
    // Işık hüzmesi (yerel koordinatlara çevrilerek).
    canvas.save();
    canvas.translate(-position.x, -position.y);
    final o = lamp;
    final far = Offset(
      o.x + facing * math.cos(_angle) * beamLength,
      o.y + math.sin(_angle) * beamLength,
    );
    canvas.drawPath(
      beamPath(),
      Paint()
        ..shader = ui.Gradient.linear(o.toOffset(), far, [
          Color.lerp(kCold, const Color(0xFFF2FFFC), suspicion)!.withValues(
            alpha:
                (0.26 + 0.3 * suspicion) *
                (suspicion > 0.6 ? 0.8 + 0.2 * math.sin(_t * 29) : 1) *
                // Gözü kamaşınca projektörünü kapatıp yüzünü siper eder.
                (dazzled > 0 ? 0.12 : 1),
          ),
          kCold.withValues(alpha: 0),
        ]),
    );
    canvas.restore();

    canvas.save();
    if (facing < 0) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }
    final ink = Paint()..color = kInk;
    final dazed = dazzled > 0 ? math.min(1.0, dazzled) : 0.0;
    // Uzun cüppe, geniş omuzlar.
    canvas.drawPath(
      Path()
        ..moveTo(3, 52)
        ..lineTo(5, 20)
        ..quadraticBezierTo(11, 14, 18, 20)
        ..lineTo(20, 52)
        ..close(),
      ink,
    );
    // Baş ve sivri miğfer bakışın yarısı kadar döner; gözü kamaşınca başını
    // çevirir.
    final look = (_eye - 0.6) * 0.5 - dazed * 0.5;
    canvas.save();
    canvas.translate(11, 15);
    canvas.rotate(look);
    canvas.translate(-11, -15);
    canvas.drawPath(
      Path()
        ..moveTo(6, 16)
        ..lineTo(11, -2)
        ..lineTo(16, 16)
        ..close(),
      ink,
    );
    canvas.drawCircle(const Offset(11, 12), 5.5, ink);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(13.5, 12 + (_eye - _angle).clamp(-0.4, 0.4) * 3),
        width: 3,
        height: 1.2 * (1 - dazed * 0.8),
      ),
      Paint()..color = kCold.withValues(alpha: 0.6 + 0.4 * suspicion),
    );
    canvas.restore();
    // Projektör: ışının çıktığı yerden döner (gövdesi arkada, camı önde).
    const pivot = Offset(21, 14);
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(_angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-9, -4.5, 9, 9),
        const Radius.circular(1.5),
      ),
      ink,
    );
    canvas.drawRect(
      const Rect.fromLTWH(-1, -3.5, 2.6, 7),
      Paint()..color = kCold.withValues(alpha: dazed > 0 ? 0.3 : 0.95),
    );
    canvas.restore();
    // Kol projektörün sapını tutar; gözü kamaşınca öbür el yüzünü siper eder.
    final grip =
        pivot + Offset(math.cos(_angle) * -6, math.sin(_angle) * -6 + 4);
    final (elbow, _) = solveLimb(const Offset(15, 21), grip, 5, 5, bend: -1);
    final arm = Paint()
      ..color = kInk
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(15, 21), elbow, arm);
    canvas.drawLine(elbow, grip, arm..strokeWidth = 2.4);
    if (dazed > 0) {
      final hand = Offset.lerp(
        const Offset(9, 30),
        const Offset(16, 11),
        dazed,
      )!;
      final (e2, _) = solveLimb(const Offset(8, 21), hand, 5.5, 5.5, bend: -1);
      canvas.drawLine(const Offset(8, 21), e2, arm..strokeWidth = 3);
      canvas.drawLine(e2, hand, arm..strokeWidth = 2.4);
      canvas.drawCircle(hand, 2, ink);
    }
    canvas.restore();
  }
}

// =============================================================== Karabasan

/// Sarnıç kanallarının karanlığından çıkan dev gölge. Çocuk başlangıç
/// çizgisini geçince arkasından gelir; yakalarsa ölüm. Ateşböceği ışığı onu
/// bir anlığına geri iter. Bitiş çizgisinde dağılır.
class Karabasan extends PositionComponent with HasGameReference<GolgeGame> {
  Karabasan(this.startX, this.endX) : super(priority: 24);

  final double startX;
  final double endX;
  bool _awake = false;
  bool _gone = false;
  double _speed = 0;
  double _recoil = 0;
  double _t = 0;
  double _fade = 0;

  /// Uzantılar gövdenin hızına gecikerek uyar: hızlanınca geride savrulur,
  /// geri tepince öne fırlar.
  final _drag = Spring(stiffness: 14, damping: 4);

  bool get awake => _awake && !_gone;

  @override
  void update(double dt) {
    super.update(dt);
    dt = math.min(dt, 1 / 30);
    _t += dt;
    final p = game.player;
    if (p == null) return;
    if (_gone) {
      _fade = math.max(0, _fade - dt * 0.8);
      if (_fade <= 0) removeFromParent();
      return;
    }
    if (!_awake) {
      if (p.center.x > startX && !p.isDead) {
        _awake = true;
        position.setValues(p.center.x - 360, p.center.y);
        _speed = 60;
        game.once('chase${game.levelIndex}', S.of('chase'));
        game.scare(1.0, slow: true);
      }
      return;
    }
    _fade = math.min(1, _fade + dt * 1.5);
    if (p.center.x > endX) {
      _gone = true;
      GameAudio.instance.dread(0);
      return;
    }
    if (p.isDead) return;

    for (final l in game.world.children.whereType<FireflyLure>()) {
      if (l.glowing && (l.position.x - position.x).abs() < 170) _recoil = 1.3;
    }
    if (_recoil > 0) {
      _recoil -= dt;
      _speed = -50;
    } else {
      _speed = math.min(128, _speed + dt * 90);
    }
    position.x += _speed * dt;
    _drag.update(_speed * 0.35, dt);
    // Oyuncunun çok gerisinde kalmasın: gerilim sürsün.
    position.x = math.max(position.x, p.center.x - 420);
    position.y += (p.center.y - position.y) * math.min(1, dt * 1.5);

    final gap = p.center.x - position.x;
    game.shake(((260 - gap) / 260).clamp(0.0, 1.0) * 5);
    GameAudio.instance.dread(((520 - gap) / 420).clamp(0.15, 1.0));
    if (gap < 46 && (p.center.y - position.y).abs() < 90) {
      p.die(cause: DeathCause.dark);
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_awake) return;
    final a = _fade;
    final ink = Paint()
      ..color = const Color(0xFF020101).withValues(alpha: 0.96 * a);
    // Kaynayan gövde: tek parça, kenarları nefes alan bir karanlık. Sırtı
    // kambur, önü sarkık; kenar noktaları ayrı ritimlerle kabarır.
    const n = 18;
    final pts = <Offset>[];
    for (var i = 0; i < n; i++) {
      final ang = i / n * math.pi * 2;
      final front = math.max(0.0, math.cos(ang));
      final r =
          88 +
          16 * math.sin(_t * 2.6 + i * 1.9) +
          10 * math.sin(_t * 4.1 - i * 0.8) -
          front * 14;
      pts.add(
        Offset(
          math.cos(ang) * r * 0.85 - 36,
          math.sin(ang) * r * (ang > math.pi ? 0.95 : 0.78),
        ),
      );
    }
    final body = Path()
      ..moveTo(
        (pts.last.dx + pts.first.dx) / 2,
        (pts.last.dy + pts.first.dy) / 2,
      );
    for (var i = 0; i < n; i++) {
      final p = pts[i];
      final q = pts[(i + 1) % n];
      body.quadraticBezierTo(p.dx, p.dy, (p.dx + q.dx) / 2, (p.dy + q.dy) / 2);
    }
    canvas.drawPath(body..close(), ink);
    // Öne uzanan pençe gibi dokunaçlar.
    final arm = Paint()
      ..color = const Color(0xFF020101).withValues(alpha: 0.96 * a)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final drag = _drag.value;
    for (var i = 0; i < 6; i++) {
      final y0 = -60.0 + i * 24;
      final reach =
          60 + 25 * math.sin(_t * 4 + i * 1.3) - drag * (0.4 + i * 0.08);
      // Kökte kalın, uca incelen; dalga kökten uca gecikir.
      for (var seg = 0; seg < 3; seg++) {
        final k0 = seg / 3;
        final k1 = (seg + 1) / 3;
        Offset at(double k) => Offset(
          10 + reach * k,
          y0 * (0.6 + 0.4 * k) +
              14 * math.sin(_t * 5 + i - k * 2.4) * k -
              drag * 0.2 * k * k,
        );
        arm.strokeWidth = (8 - i % 3 * 1.5) * (1 - k0 * 0.6);
        canvas.drawLine(at(k0), at(k1), arm);
      }
    }
    // Soluk, bakan iki göz.
    final eye = Paint()
      ..color = const Color(0xFFE8DCC8).withValues(alpha: 0.8 * a);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-6, -18), width: 9, height: 4),
      eye,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(10, -16), width: 8, height: 3.5),
      eye,
    );
  }
}

// ====================================================== Karanlıktaki gözler

/// Karabasan saldırmadan önce yalnızca sezilir: Sâye yaklaşınca karanlıkta
/// iki soluk göz açılır, bir kez yavaşça kırpılır, ağır bir nefes duyulur ve
/// gözler kapanır. Bir kez olur.
class KarabasanGlimpse extends PositionComponent
    with HasGameReference<GolgeGame> {
  KarabasanGlimpse(Vector2 cell)
    : super(position: cell + Vector2(kTile / 2, kTile / 2), priority: 45);

  static const double triggerDistance = 330;
  static const double duration = 3.4;

  double _t = -1;

  String get _key => 'glimpse:${game.levelIndex}:${position.x.round()}';

  @override
  void onMount() {
    super.onMount();
    // Bir kez görülür: ölüp yeniden doğunca tekrar belirmez.
    if (game.eventSeen(_key)) removeFromParent();
  }

  bool get seen => _t >= 0;

  @override
  void update(double dt) {
    super.update(dt);
    final p = game.player;
    if (_t < 0) {
      if (p == null || p.isDead || game.cinematic) return;
      final d = p.center - position;
      if (d.x.abs() < triggerDistance && d.y.abs() < 220) {
        _t = 0;
        game.markEvent(_key);
        GameAudio.instance.play('growl', volume: 0.8);
        game.scare(0.45, sting: false);
      }
      return;
    }
    _t += dt;
    if (_t > duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_t < 0) return;
    // Açılır, bakar, bir kez kırpar, kapanır.
    final open = _t < 0.7
        ? _t / 0.7
        : (_t > duration - 0.9 ? (duration - _t) / 0.9 : 1.0);
    final blink = (_t > 1.7 && _t < 1.95) ? 0.1 : 1.0;
    final a = open.clamp(0.0, 1.0);
    final h = 3.6 * a * blink;
    if (h <= 0.05) return;
    // Gözlerin ardında zar zor seçilen, nefes alan bir karartı.
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, 6),
        width: 150 + math.sin(_t * 2) * 8,
        height: 90,
      ),
      Paint()
        ..shader = ui.Gradient.radial(const Offset(0, 6), 80, [
          const Color(0xFF000000).withValues(alpha: 0.55 * a),
          const Color(0xFF000000).withValues(alpha: 0),
        ]),
    );
    final eye = Paint()
      ..color = const Color(0xFFE8DCC8).withValues(alpha: 0.85 * a);
    final drift = math.sin(_t * 1.3) * 2;
    for (final (x, w) in [(-11.0, 9.0), (11.0, 8.0)]) {
      glowDot(
        canvas,
        Offset(x + drift, 0),
        14,
        const Color(0xFFE8DCC8),
        0.12 * a,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x + drift, 0), width: w, height: h),
        eye,
      );
    }
  }
}
