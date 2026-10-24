import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'ark_animals.dart';
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
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = const Color(0xFF8A5A3A).withValues(alpha: 0.5);
    for (final b in _bats) {
      if (!flown || _t - _flownAt < b.delay) {
        // Baş aşağı asılı yarasa: pençeler tavanda, kanatlar gövdeye sarılı,
        // aşağıda iki sivri kulak. Hafifçe sallanır, arada kanadını kıpırdatır.
        final sway = math.sin(_t * 1.5 + b.phase) * 0.06;
        final stir =
            math.max(0.0, math.sin(_t * 0.7 + b.phase * 3) - 0.92) * 12;
        canvas.save();
        canvas.translate(b.pos.dx, b.pos.dy);
        canvas.rotate(sway);
        final body = smoothClosed([
          const Offset(0, 0.4),
          Offset(-2.2 - stir * 0.2, 2.4),
          Offset(-3.6 - stir * 0.3, 5.6),
          const Offset(-3.0, 8.6),
          const Offset(-2.0, 10.0),
          const Offset(-2.6, 12.0),
          const Offset(-0.9, 10.8),
          const Offset(0, 11.2),
          const Offset(0.9, 10.8),
          const Offset(2.6, 12.0),
          const Offset(2.0, 10.0),
          const Offset(3.0, 8.6),
          Offset(3.6 + stir * 0.3, 5.6),
          Offset(2.2 + stir * 0.2, 2.4),
        ]);
        canvas.drawPath(body, ink);
        canvas.drawPath(body, rim);
        // Katlı kanadın kemik çizgileri.
        final fold = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.4
          ..color = const Color(0xFF3A2418);
        canvas.drawLine(const Offset(-1.6, 2), const Offset(-2.4, 8), fold);
        canvas.drawLine(const Offset(1.6, 2), const Offset(2.4, 8), fold);
        canvas.drawLine(
          const Offset(-0.6, -0.4),
          const Offset(0.6, -0.4),
          ink..strokeWidth = 1,
        );
        canvas.restore();
      } else {
        // Uçan yarasa: zar kanat dirsekten kırılır, uç gecikerek iner; arka
        // kenarı parmaklar arasında içe kıvrık (tarak gibi).
        final ph = _t * 30 + b.phase;
        final elbow = math.sin(ph) * 3;
        final tip = math.sin(ph - 0.7) * 5;
        final c = b.pos;
        final wing = Path()..moveTo(c.dx, c.dy);
        for (final s in [-1.0, 1.0]) {
          wing
            ..lineTo(c.dx + s * 3.5, c.dy - 0.6 - elbow)
            ..lineTo(c.dx + s * 9, c.dy - tip)
            ..quadraticBezierTo(
              c.dx + s * 7.4,
              c.dy,
              c.dx + s * 7.2,
              c.dy + 1.6 - elbow * 0.3,
            )
            ..quadraticBezierTo(
              c.dx + s * 6,
              c.dy + 0.6,
              c.dx + s * 5,
              c.dy + 2.2 - elbow * 0.3,
            )
            ..quadraticBezierTo(
              c.dx + s * 3.6,
              c.dy + 1,
              c.dx + s * 2.6,
              c.dy + 2,
            )
            ..lineTo(c.dx, c.dy + 1);
        }
        canvas.drawPath(wing..close(), ink);
        canvas.drawOval(
          Rect.fromCenter(center: c.translate(0, 1), width: 3, height: 4.6),
          ink,
        );
        // Kulaklar.
        for (final s in [-1.0, 1.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(c.dx + s * 0.4, c.dy - 1)
              ..lineTo(c.dx + s * 1.4, c.dy - 3.2)
              ..lineTo(c.dx + s * 1.5, c.dy - 0.6)
              ..close(),
            ink,
          );
        }
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
      // Karga: kalın gaga, yuvarlak kafa, kanadı sırtına katlı, uzun kuyruk;
      // gagalarken baş öne iner.
      canvas.save();
      canvas.translate(4, -9);
      canvas.rotate(peck * 0.12);
      canvas.translate(-4, 9);
      final crow = smoothClosed(const [
        Offset(-12, -5.4),
        Offset(-8, -6.4),
        Offset(-3, -9),
        Offset(2, -10.4),
        Offset(5, -12.2),
        Offset(7.4, -13.4),
        Offset(9.4, -12.8),
        Offset(12, -11.8),
        Offset(14.6, -10.8),
        Offset(11.6, -10.2),
        Offset(9, -9.6),
        Offset(7, -7.8),
        Offset(3, -4.6),
        Offset(-1, -4),
        Offset(-4, -4.8),
        Offset(-9, -3.6),
        Offset(-12.4, -4.2),
      ]);
      canvas.drawPath(crow, ink);
      // Katlı kanadın kenarı ve göz.
      canvas.drawPath(
        Path()
          ..moveTo(5, -9.6)
          ..quadraticBezierTo(0, -6.6, -7, -6.2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = const Color(0xFF6A5A6A).withValues(alpha: 0.6),
      );
      canvas.drawCircle(
        const Offset(8.6, -11.8),
        0.7,
        Paint()..color = const Color(0xFFD08A5A),
      );
      canvas.restore();
      // Bacaklar ve parmaklar.
      final leg = Paint()
        ..color = ink.color
        ..strokeWidth = 0.9
        ..strokeCap = StrokeCap.round;
      for (final x in [-0.5, 2.4]) {
        canvas.drawLine(Offset(x, -4.4), Offset(x - 0.4, 0), leg);
        canvas.drawLine(Offset(x - 0.4, 0), Offset(x + 1.8, 0), leg);
        canvas.drawLine(Offset(x - 0.4, 0), Offset(x - 2, 0.2), leg);
      }
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
  Watcher(Vector2 cell, {this.profile})
    : super(
        position: Level.standOn(cell, 22, 52),
        size: Vector2(22, 52),
        priority: 15,
      );

  static const double beamLength = 360;
  static const double beamHalf = 0.17;

  /// Bölüm verisinden tarama ayarı (yoksa eski düzen).
  final WatcherProfile? profile;

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
    // Yakında başka bir Gözcü varsa ona bakar: ikisi aradaki yolu sırayla
    // süpürür (Kaf'ın gölge köprüsü). Yoksa bölümün ortasına bakar.
    double? mate;
    for (final c in game.level.watcherCells) {
      final dx = c.x + kTile / 2 - position.x;
      if (dx.abs() < kTile || dx.abs() > 25 * kTile) continue;
      if (mate == null || dx.abs() < mate.abs()) mate = dx;
    }
    facing =
        profile?.facing ??
        (mate != null
            ? (mate > 0 ? 1 : -1)
            : (position.x < game.level.pixelWidth / 2 ? 1 : -1));
    final pr = profile;
    if (pr != null) {
      // Başlangıç anı dönemin kesri: ışın ilk karede ayarın yerinde.
      _t = pr.phase * 2 * math.pi / pr.speed;
      final a = pr.center + pr.sweep * math.sin(_t * pr.speed);
      _eye = a;
      _aim.value = a;
      _angle = a;
    }
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
      // Tarama: düzgün gidip gelir (uçlarda beklemek kayalardaki geçiş
      // aralığını daraltıyordu).
      final pr = profile;
      target = pr == null
          ? 0.6 + 0.55 * math.sin(_t * 0.7)
          : pr.center + pr.sweep * math.sin(_t * pr.speed);
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
    // Işıkta ~0,74 sn kalan yakalanır (geçerken bir anlık değmek affedilir).
    suspicion = sees
        ? math.min(1, suspicion + dt * 1.35)
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
  /// Projektör huzmesi; [k] yanlara açılışın oranı (yumuşak kenar
  /// katmanları için).
  Path beamPath([double k = 1]) {
    final o = lamp;
    final a1 = _angle - beamHalf * k;
    final a2 = _angle + beamHalf * k;
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
    SoftEdge.beam(
      canvas,
      beamPath,
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
    // Uzun, ağır cüppe: geniş omuzlar, kemer, yırtık etek; kenarı
    // projektörün soğuk ışığını yakalar.
    final robe = smoothClosed([
      const Offset(4, 21),
      const Offset(8, 17.5),
      const Offset(14, 17.5),
      const Offset(18.5, 20),
      const Offset(19.5, 32),
      Offset(21 + math.sin(_t * 1.3) * 0.6, 44),
      const Offset(21.5, 52),
      const Offset(18, 50.2),
      const Offset(15.6, 52),
      const Offset(12.6, 50),
      const Offset(9.6, 52),
      const Offset(6.6, 50.4),
      Offset(2 - math.sin(_t * 1.3) * 0.6, 52),
      const Offset(3, 40),
      const Offset(3.6, 30),
    ]);
    canvas.drawPath(robe, ink);
    canvas.drawPath(
      robe,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = kCold.withValues(alpha: 0.25 + 0.2 * suspicion),
    );
    canvas.drawRect(
      const Rect.fromLTWH(4.2, 31, 15, 1.8),
      Paint()..color = const Color(0xFF1C1418),
    );
    final fold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = const Color(0xFF241C20);
    for (final x in [8.0, 12.0, 16.0]) {
      canvas.drawLine(Offset(x, 34), Offset(x + 0.6, 49), fold);
    }
    // Baş ve sivri miğfer bakışın yarısı kadar döner; gözü kamaşınca başını
    // çevirir.
    final look = (_eye - 0.6) * 0.5 - dazed * 0.5;
    canvas.save();
    canvas.translate(11, 15);
    canvas.rotate(look);
    canvas.translate(-11, -15);
    // Sivri, arkaya kıvrık kukuleta; yüz karanlıkta.
    final hood = smoothClosed(const [
      Offset(5.4, 18),
      Offset(5.2, 10),
      Offset(7.6, 3),
      Offset(9.6, -3.4),
      Offset(8.4, -7),
      Offset(12.4, -2),
      Offset(16, 6),
      Offset(17.4, 13),
      Offset(16.4, 18),
    ]);
    canvas.drawPath(hood, ink);
    canvas.drawPath(
      hood,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = kCold.withValues(alpha: 0.3 + 0.2 * suspicion),
    );
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

  /// Yakınlık (0 uzak – 1 ensede): ekran kenarı ve zerreler buna göre.
  double menace = 0;

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
        game.once('chase${game.levelIndex}', S.of('chase'), story: false);
        game.scare(1.0, slow: true);
        game.meetMyth('karabasan');
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
    // Gerilim mesafeyle artar: ekranın onun yanı kararır, zerreler ona
    // çekilir (sürekli sarsıntı yerine; sarsıntı yalnız çok yakında, hafif).
    menace = ((420 - gap) / 340).clamp(0.0, 1.0);
    game.shake(((160 - gap) / 160).clamp(0.0, 1.0) * 2.5);
    GameAudio.instance.dread(((520 - gap) / 420).clamp(0.15, 1.0));
    if (gap < 46 && (p.center.y - position.y).abs() < 90) {
      p.die(cause: DeathCause.dark);
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_awake) return;
    final a = _fade;
    // Çevredeki ışık zerreleri ona doğru dönerek çekilir.
    for (var i = 0; i < 16; i++) {
      final k = ((_t * 0.45 + i / 16) % 1.0);
      final ang = i * 2.4 + k * 3.0;
      final r = 160 * (1 - k);
      canvas.drawCircle(
        Offset(math.cos(ang) * r, math.sin(ang) * r * 0.6),
        1.4 + 1.2 * k,
        Paint()
          ..color = const Color(0xFFFFC98A)
              .withValues(alpha: 0.5 * a * (1 - k) * (0.4 + 0.6 * menace)),
      );
    }
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

// ======================================================= Geciken ayak sesi

/// Sâye taş yolda yürüyüp durunca, bir an sonra arkasından bir adım daha
/// duyulur; Sâye dönüp bakar. İkinci kez iki adım gelir ve duvardaki gölgesi
/// geride kalır. Yalnızca sezdirir: oyuncunun hareketine, düşmanlara ya da
/// sese hiçbir etkisi yoktur. Kayıt başına bir kez.
class EchoSteps extends Component with HasGameReference<GolgeGame> {
  EchoSteps(this.from, this.to, {required this.stage});

  final int from;
  final int to;

  /// 0: yalnızca ses ve bakış; 1: iki adım ve geride kalan gölge.
  final int stage;

  double _walked = 0;
  double _t = -1;

  String get _key => 'echo:${game.levelIndex}:$from';

  @override
  void onMount() {
    super.onMount();
    if (game.eventSeen(_key)) removeFromParent();
  }

  String get _sound => game.level.def.theme.snowy
      ? 'step_snow'
      : (game.level.def.theme == LevelTheme.cistern ? 'step_wood' : 'step');

  @override
  void update(double dt) {
    super.update(dt);
    final p = game.player;
    if (p == null || p.isDead || game.cinematic) return;
    if (_t < 0) {
      final col = p.center.x / kTile;
      final inside = col >= from && col <= to;
      if (!inside || game.threat > 0.3) {
        _walked = 0;
        return;
      }
      final moving = p.onGround && p.velocity.x.abs() > 40;
      if (moving) {
        _walked += dt;
      } else if (_walked > 0.8 && p.onGround && p.velocity.x.abs() < 4) {
        _t = 0;
        game.markEvent(_key);
      }
      return;
    }
    final before = _t;
    _t += dt;
    bool at(double s) => before < s && _t >= s;
    // Durduktan bir an sonra: yankı değil, bir adım daha.
    if (at(0.45)) GameAudio.instance.play(_sound, volume: 0.32);
    if (at(0.62)) {
      p.lookBack(1.2);
      game.threat = math.max(game.threat, 0.28);
    }
    if (stage > 0 && at(0.95)) {
      GameAudio.instance.play(_sound, volume: 0.42);
      p.shadowFright(0.5);
    }
    if (_t > 2.2) removeFromParent();
  }
}
