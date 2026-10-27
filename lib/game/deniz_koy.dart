import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'deniz.dart';
import 'entities.dart';
import 'golge_game.dart';
import 'level.dart';

// ================================================================ Yunus Koyu
//
// Ak Ana'nın Denizi'nin açık koyu: gökyüzü açık, geniş ve derin. Burası
// serbest yüzüşün tadı ve küçük sürprizler içindir; tehlike yok. Yunuslar
// yanlarında yüzeni hızlandırır, inci midyeleri nefes verir, batık geminin
// sandığı ateşböceği saklar, bir balık sürüsü Sâye'nin ardına takılır,
// uzakta bir balina geçer; sudan sıçrayan Sâye gökte Kayra Han'ın kara
// kazını görür (Altay yaratılışında Kayra Han ilk suyun üstünde kara bir kaz
// gibi uçar).
//
// Çizim hayal perdesinin diliyle: mürekkep siluetler, ince açık çizgiler.

const _ink = Color(0xFF071312);
const _line = Color(0xFF2E5450);
const _eye = Color(0xFFE8D9A8);

/// Bir sütunda, verilen satırdan aşağı ilk kayanın üstü (dünya y).
double seaFloorBelow(Level lv, int col, int fromRow) {
  for (var r = fromRow; r < lv.height; r++) {
    if (lv.solid(col, r)) return r * kTile.toDouble();
  }
  return lv.height * kTile.toDouble();
}

// ---------------------------------------------------------------- yunuslar

/// Üç yunusluk sürü: koyun bir ucundan öbürüne gidip gelir, ara ara
/// sırayla sudan sıçrar. Yanlarında yüzen Sâye hızlanır.
class DolphinPod extends Component with HasGameReference<GolgeGame> {
  DolphinPod(this.c0, this.c1, this.row, this.surface, {this.seed = 0})
    : super(priority: 18);

  final int c0, c1, row;
  final double surface;
  final int seed;

  final _dolphins = <_Dolphin>[];
  double _t = 0;
  double _x = 0;
  int _dir = 1;
  double _leapIn = 3;
  int _leaper = 0;

  @override
  void onLoad() {
    _x = (c0 + 2) * kTile.toDouble();
    for (var i = 0; i < 3; i++) {
      _dolphins.add(_Dolphin(i * 1.9 + seed, 0.85 + i * 0.12));
    }
  }

  @override
  void update(double dt) {
    _t += dt;
    const speed = 150.0;
    _x += _dir * speed * dt;
    if (_x > (c1 - 1) * kTile) _dir = -1;
    if (_x < (c0 + 1) * kTile) _dir = 1;
    final base = (row + 0.5) * kTile;
    _leapIn -= dt;
    if (_leapIn <= 0) {
      _dolphins[_leaper].leap = 0;
      _leaper = (_leaper + 1) % _dolphins.length;
      _leapIn = _leaper == 0 ? 4.5 : 0.7;
    }
    final p = game.player;
    for (final (i, d) in _dolphins.indexed) {
      final lag = i * 44.0;
      final x = _x - _dir * lag;
      var y = base + math.sin(_t * 1.6 + d.phase) * 14 + i * 18;
      // Sıçrayış: yüzeye koşar, havada bir yay çizer, suya döner.
      if (d.leap >= 0) {
        d.leap += dt;
        const up = 0.5, air = 0.9, down = 0.5;
        final top = surface - 70;
        if (d.leap < up) {
          y = y + (surface + 10 - y) * _ease(d.leap / up);
        } else if (d.leap < up + air) {
          final k = (d.leap - up) / air;
          y = surface + 10 - (surface + 10 - top) * math.sin(k * math.pi);
          if (!d.splashed && k > 0.05) {
            d.splashed = true;
            _splash(x, 0.25);
          }
        } else if (d.leap < up + air + down) {
          y =
              surface +
              10 +
              (y - surface - 10) * _ease((d.leap - up - air) / down);
          if (d.splashed) {
            d.splashed = false;
            _splash(x, 0.3);
          }
        } else {
          d.leap = -1;
        }
      }
      final prev = d.pos;
      d.pos = Offset(x, y);
      final v = d.pos - prev;
      if (v.distance > 0.01) d.angle = math.atan2(v.dy, v.dx.abs());
      d.dir = _dir;
      if (p != null &&
          !p.isDead &&
          p.swimming &&
          (p.center.toOffset() - d.pos).distance < 64) {
        if (p.dolphinBoost <= 0) {
          GameAudio.instance.play('glide', volume: 0.45, minGapMs: 900);
          game.hint('dolphin');
        }
        p.dolphinBoost = 1.4;
      }
    }
  }

  void _splash(double x, double volume) {
    final p = game.player;
    if (p != null && (p.center.x - x).abs() < 700) {
      GameAudio.instance.play('splash', volume: volume, minGapMs: 250);
    }
  }

  static double _ease(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  @override
  void render(Canvas canvas) {
    for (final d in _dolphins) {
      canvas.save();
      canvas.translate(d.pos.dx, d.pos.dy);
      if (d.dir < 0) canvas.scale(-1, 1);
      canvas.rotate(d.angle.clamp(-1.2, 1.2));
      canvas.scale(d.size, d.size);
      _drawDolphin(canvas, _t * 6 + d.phase);
      canvas.restore();
    }
  }

  static void _drawDolphin(Canvas canvas, double t) {
    final ink = Paint()..color = _ink;
    final body = Path()
      ..moveTo(40, 1)
      ..quadraticBezierTo(34, -3, 24, -4) // gaga
      ..quadraticBezierTo(22, -12, 12, -13) // yuvarlak alın
      ..quadraticBezierTo(2, -13, -6, -11)
      ..quadraticBezierTo(-24, -8, -34, -2)
      ..quadraticBezierTo(-24, 6, -4, 8)
      ..quadraticBezierTo(16, 8, 24, 2)
      ..close();
    canvas.drawPath(body, ink);
    // Sırt yüzgeci.
    canvas.drawPath(
      Path()
        ..moveTo(-2, -11)
        ..quadraticBezierTo(-6, -17, -12, -18)
        ..quadraticBezierTo(-9, -13, -11, -10)
        ..close(),
      ink,
    );
    // Kuyruk: inip kalkar.
    final f = math.sin(t) * 5;
    canvas.drawPath(
      Path()
        ..moveTo(-32, -2)
        ..lineTo(-44, -10 + f)
        ..quadraticBezierTo(-40, -2 + f * 0.5, -46, 6 + f)
        ..close(),
      ink,
    );
    // Yan yüzgeç ve göz.
    canvas.drawPath(
      Path()
        ..moveTo(8, 4)
        ..quadraticBezierTo(2, 14, -4, 14)
        ..quadraticBezierTo(0, 8, 2, 4)
        ..close(),
      ink,
    );
    canvas.drawLine(
      const Offset(20, -2),
      const Offset(-20, -4),
      Paint()
        ..color = _line
        ..strokeWidth = 1,
    );
    canvas.drawCircle(const Offset(19, -5), 1.4, Paint()..color = _eye);
    canvas.drawPath(
      Path()
        ..moveTo(38, 1)
        ..quadraticBezierTo(31, 4, 24, 1),
      Paint()
        ..color = _line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}

class _Dolphin {
  _Dolphin(this.phase, this.size);
  final double phase;
  final double size;
  Offset pos = Offset.zero;
  double angle = 0;
  int dir = 1;

  /// Sıçrayışın süresi (yoksa negatif).
  double leap = -1;
  bool splashed = false;
}

// ---------------------------------------------------------------- inci midyesi

/// Dipte bir midye: ağır ağır açılıp kapanır. Açıkken içindeki inciye
/// dokunan Sâye'nin nefesi dolar; kapanırken içindeyse midye onu dışarı
/// püskürtür. İnci bir süre sonra yeniden büyür.
class PearlClam extends PositionComponent
    with SeaLight, HasGameReference<GolgeGame> {
  PearlClam(Level lv, int col, int row, {this.index = 0})
    : super(
        position: Vector2((col + 0.5) * kTile, seaFloorBelow(lv, col, row)),
        priority: 17,
      ) {
    _t = index * 1.7;
  }

  final int index;
  static const total = 5;
  double _t = 0;
  double _gone = -1;
  double _spit = 0;
  final _sparks = <(Offset, double)>[];

  /// 0 kapalı, 1 açık.
  double get open {
    final k = _t % 6.0;
    if (k < 2.5) return 0;
    if (k < 3.0) return (k - 2.5) / 0.5;
    if (k < 5.2) return 1;
    if (k < 5.6) return 1 - (k - 5.2) / 0.4;
    return 0;
  }

  bool get hasPearl => _gone < 0;
  Offset get _pearl => position.toOffset().translate(0, -13);

  @override
  Offset get glowCenter => _pearl;
  @override
  double get glowRadius => 70;
  @override
  double get glowStrength => hasPearl ? 0.25 + 0.4 * open : 0;

  @override
  void update(double dt) {
    super.update(dt);
    final was = open;
    _t += dt;
    _spit = math.max(0, _spit - dt);
    if (_gone >= 0) {
      _gone += dt;
      if (_gone > 20) _gone = -1;
    }
    for (var i = _sparks.length - 1; i >= 0; i--) {
      final (o, a) = _sparks[i];
      if (a + dt > 1.2) {
        _sparks.removeAt(i);
      } else {
        _sparks[i] = (o.translate(0, -30 * dt), a + dt);
      }
    }
    final p = game.player;
    if (p == null || p.isDead || !p.swimming) return;
    final d = (p.center.toOffset() - _pearl).distance;
    if (hasPearl && open > 0.7 && d < 26) {
      _gone = 0;
      game.breathe(1);
      GameAudio.instance.play('pickup', volume: 0.55);
      for (var i = 0; i < 10; i++) {
        _sparks.add((
          _pearl.translate(math.cos(i * 0.63) * 8, math.sin(i * 0.63) * 6),
          i * 0.03,
        ));
      }
      game.hint('clam');
      game.foundPearl(index);
    }
    // Kapanan midye içindekini dışarı püskürtür (zarar vermez).
    if (was > 0.3 && open < was && d < 22 && _spit <= 0) {
      _spit = 1;
      p.velocity.y = -260;
      GameAudio.instance.play('splash', volume: 0.3, minGapMs: 300);
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.scale(1.5, 1.5);
    final o = open;
    final ink = Paint()..color = _ink;
    final rim = Paint()
      ..color = _line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    // Alt kabuk.
    final lower = Path()
      ..moveTo(-16, -4)
      ..quadraticBezierTo(0, 6, 16, -4)
      ..lineTo(14, 0)
      ..quadraticBezierTo(0, 4, -14, 0)
      ..close();
    canvas.drawPath(lower, ink);
    // İnci.
    if (hasPearl && o > 0.05) {
      canvas.drawCircle(
        const Offset(0, -9),
        4.2,
        Paint()..color = Color.lerp(_line, const Color(0xFFF4F1E6), o)!,
      );
      canvas.drawCircle(
        const Offset(-1.3, -10.3),
        1.2,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.8 * o),
      );
    }
    // Üst kabuk: arkadan menteşeli açılır.
    canvas.save();
    canvas.translate(-15, -4);
    canvas.rotate(-0.95 * o);
    final upper = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(15, -14, 31, 0)
      ..quadraticBezierTo(15, -6, 0, 0)
      ..close();
    canvas.drawPath(upper, ink);
    for (var i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(15.0, -2),
        Offset(4.0 + i * 6, -8 + (i - 2).abs() * 2.0),
        rim,
      );
    }
    canvas.restore();
    for (final (s, a) in _sparks) {
      if (a < 0) continue;
      canvas.drawCircle(
        (s - position.toOffset()) / 1.5,
        1.6 * (1.2 - a),
        Paint()..color = const Color(0xFFF4F1E6).withValues(alpha: 1 - a / 1.2),
      );
    }
  }
}

// ---------------------------------------------------------------- batık gemi

/// Dipte yan yatmış eski bir gemi (süs; içinden geçilir) ve güvertesinin
/// dibinde bir sandık: dokunan Sâye'ye kabarcıklarla birlikte ateşböceği
/// verir, içinden küçük bir denizatı fırlar.
class Wreck extends PositionComponent with HasGameReference<GolgeGame> {
  Wreck(Level lv, int col, int row)
    : super(
        position: Vector2((col + 0.5) * kTile, seaFloorBelow(lv, col, row)),
        priority: -3,
      );

  @override
  void render(Canvas canvas) {
    final ink = Paint()..color = const Color(0xFF0B1D1E);
    final plank = Paint()
      ..color = const Color(0xFF1C3836)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.save();
    canvas.rotate(-0.12);
    // Gövde: kıçı kumda, burnu hafif kalkık.
    final hull = Path()
      ..moveTo(-250, -10)
      ..lineTo(-236, -96)
      ..lineTo(150, -100)
      ..quadraticBezierTo(232, -104, 262, -150)
      ..lineTo(270, -136)
      ..quadraticBezierTo(240, -40, 150, 0)
      ..lineTo(-200, 8)
      ..close();
    canvas.drawPath(hull, ink);
    for (var i = 1; i < 5; i++) {
      final y = -96.0 + i * 20;
      canvas.drawLine(
        Offset(-236 + i * 2.0, y),
        Offset(170 - i * 10.0, y + 2),
        plank,
      );
    }
    // Kırık delik: içi daha koyu.
    canvas.drawPath(
      Path()
        ..moveTo(-60, -70)
        ..lineTo(-20, -86)
        ..lineTo(10, -60)
        ..lineTo(-14, -30)
        ..lineTo(-52, -38)
        ..close(),
      Paint()..color = const Color(0xFF030A0B),
    );
    // Kırık direk ve sarkan halat.
    canvas.drawRect(const Rect.fromLTWH(-30, -230, 10, 134), ink);
    canvas.drawLine(
      const Offset(-25, -200),
      const Offset(60, -228),
      ink..strokeWidth = 4,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-25, -170)
        ..quadraticBezierTo(40, -120, 120, -104),
      plank,
    );
    canvas.restore();
  }
}

class TreasureChest extends PositionComponent
    with SeaLight, HasGameReference<GolgeGame> {
  TreasureChest(Level lv, int col, int row)
    : super(
        position: Vector2((col + 0.5) * kTile, seaFloorBelow(lv, col, row)),
        priority: 17,
      );

  double _open = 0;
  bool opened = false;
  double _t = 0;
  final _coins = <(Offset, Offset, double)>[];
  Offset? _seahorse;

  @override
  Offset get glowCenter => position.toOffset().translate(0, -14);
  @override
  double get glowRadius => 120;
  @override
  double get glowStrength =>
      opened ? 0.5 * (1 - (_t / 8).clamp(0.0, 1.0)) + 0.12 : 0.08;

  @override
  void update(double dt) {
    super.update(dt);
    if (opened) {
      _t += dt;
      _open = math.min(1, _open + dt * 2.5);
    }
    for (var i = _coins.length - 1; i >= 0; i--) {
      final (o, v, a) = _coins[i];
      if (a + dt > 2.4) {
        _coins.removeAt(i);
      } else {
        _coins[i] = (o + v * dt, v * 0.985 + const Offset(0, -6) * dt, a + dt);
      }
    }
    if (_seahorse case final s?) {
      _seahorse = s.translate(math.sin(_t * 3) * 20 * dt, -38 * dt);
      if (_t > 9) _seahorse = null;
    }
    if (opened) return;
    final p = game.player;
    if (p == null || p.isDead) return;
    if ((p.center - position).length > 34) return;
    opened = true;
    GameAudio.instance.play('solve', volume: 0.6);
    final rnd = math.Random(7);
    final at = position.toOffset().translate(0, -14);
    for (var i = 0; i < 26; i++) {
      final a = -math.pi / 2 + (rnd.nextDouble() - 0.5) * 1.6;
      final v = 40 + rnd.nextDouble() * 70;
      _coins.add((at, Offset(math.cos(a) * v, math.sin(a) * v), -i * 0.02));
    }
    _seahorse = at.translate(10, -6);
    // Kabarcıklarla yükselen üç ateşböceği.
    for (var i = 0; i < 3; i++) {
      game.world.add(
        FireflySwarm(
          position +
              Vector2(-kTile / 2 + (i - 1) * 26, -(2.4 + i * 0.8) * kTile),
        ),
      );
    }
    game.hint('chest');
    game.foundSecret('sandik');
  }

  @override
  void render(Canvas canvas) {
    final ink = Paint()..color = _ink;
    final band = Paint()
      ..color = const Color(0xFF6E5A2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRect(const Rect.fromLTWH(-16, -16, 32, 16), ink);
    canvas.drawRect(const Rect.fromLTWH(-16, -16, 32, 16), band);
    canvas.drawLine(const Offset(-6, -16), const Offset(-6, 0), band);
    canvas.drawLine(const Offset(6, -16), const Offset(6, 0), band);
    // İçi parlar.
    if (_open > 0) {
      canvas.drawRect(
        const Rect.fromLTWH(-14, -18, 28, 4),
        Paint()..color = const Color(0xFFF2D27A).withValues(alpha: 0.8 * _open),
      );
    }
    // Kapak arkadan açılır.
    canvas.save();
    canvas.translate(16, -16);
    canvas.rotate(_open * 1.9);
    final lid = Path()
      ..moveTo(0, 0)
      ..lineTo(-32, 0)
      ..quadraticBezierTo(-16, -12, 0, 0)
      ..close();
    canvas.drawPath(lid, ink);
    canvas.drawPath(lid, band);
    canvas.restore();
    final o = position.toOffset();
    for (final (c, _, a) in _coins) {
      if (a < 0) continue;
      final k = 1 - a / 2.4;
      canvas.drawCircle(
        c - o,
        2.2,
        Paint()..color = const Color(0xFFF2D27A).withValues(alpha: k),
      );
    }
    if (_seahorse case final s?) {
      canvas.save();
      canvas.translate(s.dx - o.dx, s.dy - o.dy);
      _drawSeahorse(canvas, _t);
      canvas.restore();
    }
  }

  static void _drawSeahorse(Canvas canvas, double t) {
    final ink = Paint()..color = _ink;
    final p = Path()
      ..moveTo(0, -10)
      ..quadraticBezierTo(6, -12, 7, -8) // burun
      ..lineTo(3, -6)
      ..quadraticBezierTo(5, 0, 2, 6)
      ..quadraticBezierTo(-2, 12, 2, 14)
      ..quadraticBezierTo(-4, 15, -3, 9)
      ..quadraticBezierTo(-5, 2, -3, -6)
      ..quadraticBezierTo(-3, -10, 0, -10)
      ..close();
    canvas.drawPath(p, ink);
    canvas.drawCircle(const Offset(1, -8), 0.9, Paint()..color = _eye);
    // Sırt yüzgeci çırpınır.
    canvas.drawLine(
      const Offset(-3, 0),
      Offset(-7 + math.sin(t * 20) * 1.5, 1),
      Paint()
        ..color = _line
        ..strokeWidth = 1.4,
    );
  }
}

// ---------------------------------------------------------------- balık sürüsü

/// Küçük bir balık sürüsü: Sâye yanından geçince ardına takılır, durunca
/// çevresinde döner ("Tek balık kaybolur, sürü yolu bilir"). Koydan
/// çıkınca evine döner.
class FriendlyShoal extends Component with HasGameReference<GolgeGame> {
  FriendlyShoal(Vector2 home, this.bayLeft, this.bayRight, this.surface)
    : home = home.clone(),
      super(priority: 21);

  final Vector2 home;
  final double bayLeft, bayRight;

  /// Balıklar suyun içinde kalır: Sâye sudan çıkınca altında beklerler.
  final double surface;
  final _fish = <(Vector2, Vector2, double)>[];
  bool following = false;
  double _t = 0;

  @override
  void onLoad() {
    for (var i = 0; i < 11; i++) {
      final a = i * 0.57;
      _fish.add((
        home + Vector2(math.cos(a) * 30, math.sin(a) * 18),
        Vector2.zero(),
        i.toDouble(),
      ));
    }
  }

  @override
  void update(double dt) {
    _t += dt;
    final p = game.player;
    final inBay = p != null && p.center.x > bayLeft && p.center.x < bayRight;
    if (p != null && !p.isDead && p.swimming && inBay) {
      if (!following && (p.center - _centroid).length < 70) {
        following = true;
        GameAudio.instance.play('firefly', volume: 0.35);
        game.hint('shoal');
      }
    }
    if (following && !inBay) following = false;
    final moving = p != null && p.velocity.length > 40;
    for (var i = 0; i < _fish.length; i++) {
      final (pos, vel, ph) = _fish[i];
      final Vector2 target;
      if (following && p != null) {
        if (moving) {
          // Ardında bir kuyruk.
          final back = p.velocity.normalized() * -(26.0 + i * 7);
          target = p.center + back + Vector2(0, math.sin(_t * 3 + ph) * 8);
        } else {
          // Durunca çevresinde halka.
          final a = _t * 1.4 + ph * (2 * math.pi / _fish.length);
          target = p.center + Vector2(math.cos(a) * 34, math.sin(a) * 22);
        }
      } else {
        final a = _t * 0.6 + ph * 0.57;
        target = home + Vector2(math.cos(a) * 34, math.sin(a * 1.3) * 18);
      }
      target.y = math.max(target.y, surface + 14 + (ph % 4) * 5);
      final acc = (target - pos) * 9 - vel * 3.2;
      vel.add(acc * dt);
      pos.add(vel * dt);
      _fish[i] = (pos, vel, ph);
    }
  }

  Vector2 get _centroid {
    final c = Vector2.zero();
    for (final (pos, _, _) in _fish) {
      c.add(pos);
    }
    return c / _fish.length.toDouble();
  }

  @override
  void render(Canvas canvas) {
    final ink = Paint()..color = _ink;
    for (final (pos, vel, ph) in _fish) {
      canvas.save();
      canvas.translate(pos.x, pos.y);
      final dir = vel.x < 0 ? -1.0 : 1.0;
      canvas.scale(dir, 1);
      final wag = math.sin(_t * 14 + ph) * 2;
      canvas.drawPath(
        Path()
          ..moveTo(6, 0)
          ..quadraticBezierTo(2, -4, -4, -1)
          ..lineTo(-8, -4 + wag)
          ..lineTo(-7, 0)
          ..lineTo(-8, 4 + wag)
          ..lineTo(-4, 1)
          ..quadraticBezierTo(2, 4, 6, 0)
          ..close(),
        ink,
      );
      canvas.restore();
    }
  }
}

// ---------------------------------------------------------------- balina

/// Koyun derininden, uzakta, ağır ağır bir balina geçer (bir kez). Sesi
/// suyun içinde uzun ve alçaktır.
class PassingWhale extends Component with HasGameReference<GolgeGame> {
  PassingWhale(this.trigger, this.fromX, this.toX, this.y)
    : super(priority: -4);

  final double trigger, fromX, toX, y;
  double _x = 0;
  double _t = -1;

  @override
  void update(double dt) {
    final p = game.player;
    if (_t < 0) {
      if (p == null || p.isDead || !p.swimming) return;
      if (p.center.x < trigger || game.secretSeen('balina')) return;
      _t = 0;
      _x = fromX;
      game.foundSecret('balina');
      GameAudio.instance.play('whale', volume: 0.7);
      return;
    }
    _t += dt;
    _x += (toX - fromX).sign * 95 * dt;
    if ((toX - fromX).sign * (_x - toX) > 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_t < 0) return;
    final fade = math.min(1.0, _t / 3) * 0.55;
    final paint = Paint()
      ..color = const Color(0xFF041012).withValues(alpha: fade);
    canvas.save();
    canvas.translate(_x, y + math.sin(_t * 0.4) * 12);
    if (toX < fromX) canvas.scale(-1, 1);
    canvas.scale(1.6, 1.6);
    final body = Path()
      ..moveTo(160, 6)
      ..quadraticBezierTo(150, -34, 60, -40)
      ..quadraticBezierTo(-60, -44, -150, -10)
      ..quadraticBezierTo(-60, 30, 60, 30)
      ..quadraticBezierTo(140, 30, 160, 6)
      ..close();
    canvas.drawPath(body, paint);
    final f = math.sin(_t * 1.1) * 14;
    canvas.drawPath(
      Path()
        ..moveTo(-140, -8)
        ..lineTo(-196, -40 + f)
        ..quadraticBezierTo(-180, -8 + f * 0.4, -200, 22 + f)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(70, 22)
        ..quadraticBezierTo(50, 60, 20, 66)
        ..quadraticBezierTo(36, 40, 40, 24)
        ..close(),
      paint,
    );
    canvas.restore();
  }
}

// ---------------------------------------------------------------- kara kaz

/// Sudan ilk sıçrayışta koyun göğünde kara bir kaz süzülür: Altay
/// yaratılışında Kayra Han ilk suyun üstünde kara bir kaz gibi uçar (bir kez).
class BlackGoose extends Component with HasGameReference<GolgeGame> {
  BlackGoose(this.left, this.right, this.surface) : super(priority: 15);

  final double left, right, surface;
  double _t = -1;
  double _x = 0, _y = 0;

  @override
  void update(double dt) {
    final p = game.player;
    if (_t < 0) {
      if (p == null || p.isDead || p.swimming) return;
      if (p.center.x < left || p.center.x > right) return;
      if (p.center.y > surface - kTile || game.secretSeen('karaKaz')) return;
      _t = 0;
      _x = p.center.x - 620;
      _y = surface - 4.2 * kTile;
      game.foundSecret('karaKaz');
      GameAudio.instance.play('bird_3', volume: 0.5);
      return;
    }
    _t += dt;
    _x += 230 * dt;
    _y -= 8 * dt;
    if (_t > 9) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_t < 0) return;
    final a = math.min(1.0, _t * 2) * math.min(1.0, (9 - _t) / 1.5);
    final ink = Paint()..color = const Color(0xFF05090A).withValues(alpha: a);
    canvas.save();
    canvas.translate(_x, _y);
    final flap = math.sin(_t * 7);
    // Gövde ve uzun boyun.
    canvas.drawOval(const Rect.fromLTWH(-16, -5, 30, 11), ink);
    canvas.drawPath(
      Path()
        ..moveTo(12, -2)
        ..quadraticBezierTo(22, -4, 30, -3)
        ..lineTo(36, -1)
        ..lineTo(30, 1)
        ..quadraticBezierTo(22, 2, 12, 3)
        ..close(),
      ink,
    );
    // Kanatlar.
    for (final s in const [1.0, -1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(-4, 0)
          ..quadraticBezierTo(-10, -24 * flap * s, -26, -30 * flap * s)
          ..quadraticBezierTo(-14, -10 * flap * s, 6, 0)
          ..close(),
        ink,
      );
    }
    canvas.restore();
  }
}
