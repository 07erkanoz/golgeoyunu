import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'entities.dart';
import 'golge_game.dart';
import 'level.dart';
import 'levels.dart';
import 'myth_figures.dart';
import 'palette.dart';
import 'persist.dart';
import 'player.dart';
import 'puzzles.dart';

// XIV · Erlik'in Katı (docs/MITOLOJI.md §5): yerin altında ışık tehlikeli,
// karanlık güvenlidir.

/// Körmös: Erlik'in gölge hizmetkârı. Kandilcilerin tersine ışığa gelir:
/// açık kavanozu uzaktan görür ve ona süzülür; ateşböceği salınırsa ona
/// döner. Kavanoz örtülünce (çömelip saklanınca) iz kaybolur, yuvasına
/// döner. Dokunduğu çocuğun ışığını söndürür.
class Kormos extends PositionComponent with HasGameReference<GolgeGame> {
  Kormos(Vector2 cell)
    : _home = Vector2(cell.x + kTile / 2, cell.y + kTile / 2 - 6),
      super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile / 2 - 6),
        size: Vector2(22, 34),
        anchor: Anchor.center,
        priority: 17,
      );

  final Vector2 _home;

  /// Açık kavanozu bu kadar uzaktan görür (kavanoz parladıkça büyür).
  static const double sight = 6 * kTile;
  static const double lureSight = 9 * kTile;
  static const double drift = 46;
  static const double chase = 84;

  double _t = math.Random().nextDouble() * 6;
  double reach = 0;
  bool hunting = false;
  int facing = 1;

  /// Bu karede neye yöneldi (yoksa null).
  Vector2? _target;

  /// Işığı gözden kaybedince son gördüğü yere bir süre süzülür: kavanozu
  /// örtüp aynı yerde çömelmek yetmez, yer değiştirmek gerekir.
  Vector2? lastLight;
  double _search = 0;
  static const double searchTime = 2.6;

  /// Son görülen ışığı arıyor mu.
  bool get searching => _search > 0 && lastLight != null;

  Level get level => game.level;

  bool _blocked(double x, double y) {
    // Gövdenin dört köşesi kayaya girmesin.
    for (final (dx, dy) in const [(-8, -14), (8, -14), (-8, 14), (8, 14)]) {
      if (level.solid(((x + dx) / kTile).floor(), ((y + dy) / kTile).floor())) {
        return true;
      }
    }
    return false;
  }

  void _step(Vector2 to, double speed, double dt) {
    final d = to - position;
    final len = d.length;
    if (len < 1) return;
    final move = d / len * math.min(len, speed * dt);
    if (!_blocked(position.x + move.x, position.y + move.y)) {
      position.add(move);
    } else if (!_blocked(position.x + move.x, position.y)) {
      position.x += move.x;
    } else if (!_blocked(position.x, position.y + move.y)) {
      position.y += move.y;
    }
    if (move.x.abs() > 0.05) facing = move.x > 0 ? 1 : -1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    dt = math.min(dt, 1 / 30);
    _t += dt;
    final p = game.player;
    Vector2? target;
    var speed = drift;
    // Önce salınan ateşböceği: en yakın parlayan.
    var best = lureSight;
    for (final l in game.world.children.whereType<FireflyLure>()) {
      if (!l.glowing) continue;
      final d = (l.position - position).length;
      if (d < best && level.lineOfSight(position, l.position)) {
        best = d;
        target = l.position;
        speed = chase;
      }
    }
    // Sonra açık kavanoz.
    if (target == null && p != null && !p.isDead && !p.crouching && !p.hidden) {
      final r = sight * game.jarBoost;
      final d = p.center - position;
      if (d.length < r && level.lineOfSight(position, p.center)) {
        target = p.center;
        speed = chase;
      }
    }
    final wasHunting = hunting;
    hunting = target != null;
    if (hunting && !wasHunting && target == p?.center) {
      GameAudio.instance.play('suspect', volume: 0.45, minGapMs: 2500);
    }
    _target = target;
    if (target != null && target == p?.center) {
      lastLight = target.clone();
      _search = searchTime;
    } else if (target != null) {
      // Ateşböceğine dönen eski izi bırakır.
      _search = 0;
    }
    if (target != null) {
      _step(target, speed, dt);
    } else if (searching) {
      _search -= dt;
      _step(lastLight!, drift * 1.3, dt);
    } else {
      // Yuvasına döner, orada ağır ağır salınır.
      final home = _home + Vector2(math.sin(_t * 0.6) * 10, math.sin(_t) * 4);
      _step(home, drift * 0.7, dt);
    }
    reach += ((hunting ? 1.0 : 0.0) - reach) * math.min(1, dt * 3);
    if (p != null && !p.isDead && (p.center - position).length < 17) {
      p.die(cause: DeathCause.dark);
    }
  }

  /// Testler için: şu an neye yöneliyor.
  Vector2? get debugTarget => _target;

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y + 4 + math.sin(_t * 2) * 1.5);
    canvas.scale(facing * 0.36, 0.36);
    MythFigures.kormos(canvas, _t, reach: reach);
    canvas.restore();
  }
}

/// Hapsedilmiş kut: kafeste çırpınan bir can ışığı. ↑ ile açılır: kut
/// kavanoza girer (kavanoz parlar, Körmösler daha uzaktan görür), en yakın
/// kapı açılır.
class KutCage extends PositionComponent
    with HasGameReference<GolgeGame>, Persistent, Usable {
  KutCage(Vector2 cell)
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile),
        size: Vector2(26, 36),
        anchor: Anchor.bottomCenter,
        priority: 15,
      );

  bool freed = false;
  double _open = 0;
  double _t = math.Random().nextDouble() * 5;

  /// Kutun kavanoza uçuşu (0-1).
  double _fly = 1;

  Offset get glowCenter => Offset(position.x, position.y - 16);

  @override
  String get persistKind => 'kut';

  @override
  Object? captureState() => freed ? 1 : null;

  @override
  Iterable<Component> restoreState(Object? state, {required bool present}) {
    if (state == 1) {
      freed = true;
      _open = 1;
    }
    return [this];
  }

  @override
  bool canUse(Vector2 p) =>
      !freed && (p.x - position.x).abs() < 24 && (p.y - position.y).abs() < 44;

  @override
  void use() {
    if (freed) return;
    freed = true;
    _fly = 0;
    GameAudio.instance.play('memory', volume: 0.7);
    GameAudio.instance.play('gate', volume: 0.6);
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
    // Yeşil Kubbe'de kafesteki ışıklar Kandilcilerin topladıklarıdır, kut
    // değil.
    if (game.level.def.theme == LevelTheme.underworld) game.meetMyth('kut');
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (freed) _open = math.min(1, _open + dt * 2);
    if (_fly < 1) _fly = math.min(1, _fly + dt * 1.4);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y);
    canvas.scale(1.15);
    MythFigures.kutCage(canvas, _t, open: _open);
    canvas.restore();
    // Kut, kavanoza doğru uçar.
    final p = game.player;
    if (_fly < 1 && p != null) {
      final from = Offset(size.x / 2, size.y - 18);
      final jar = p.lightVisual;
      final to = Offset(
        jar.x - position.x + size.x / 2,
        jar.y - position.y + size.y,
      );
      final at = Offset.lerp(from, to, _fly * _fly)!;
      glowDot(canvas, at, 12, const Color(0xFFFFF2C8), 0.9 * (1 - _fly * 0.5));
    }
  }
}

/// Çalkuyruk: Er Töştük'ün konuşan atı. Bölümün sonunda kuyunun dibinde
/// bekler; Sâye dokununca sırtına alır: atla birlikte çok daha yükseğe
/// sıçranır, yükselen karanlıktan yukarı kaçılır.
class Calkuyruk extends PositionComponent with HasGameReference<GolgeGame> {
  Calkuyruk(Vector2 cell)
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile),
        size: Vector2(44, 38),
        anchor: Anchor.bottomCenter,
        priority: 19,
      );

  static const double drawScale = 0.38;

  // Koşu: adım döngüsü, yürüyüş miktarı, havada uzanma.
  double _phase = 0;
  double _gait = 0;
  double _leap = 0;

  /// Atın sırtı ayaklardan bu kadar yukarıda (Sâye burada oturur).
  static const double saddle = 21;

  double _t = 0;
  int facing = -1;
  double _tilt = 0;

  Offset get glowCenter => Offset(position.x, position.y - 20);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (p == null) return;
    if (!game.onHorse) {
      if (!p.isDead &&
          (p.center.x - position.x).abs() < 26 &&
          (p.position.y + Player.h - position.y).abs() < 20) {
        game.mountHorse();
      }
      return;
    }
    final nx = p.position.x + Player.w / 2;
    // Adım döngüsü yürünen yoldan (dörtnala ~70 piksel); havada uzanır.
    _phase = (_phase + (nx - position.x).abs() / 70) % 1.0;
    final speed = (p.velocity.x.abs() / 260).clamp(0.0, 1.0);
    _gait += (speed - _gait) * math.min(1, dt * 6);
    _leap += ((p.onGround ? 0.0 : 1.0) - _leap) * math.min(1, dt * 9);
    position.setValues(nx, p.position.y + Player.h);
    facing = p.facing;
    final want = p.onGround ? 0.0 : (p.velocity.y / 900).clamp(-0.5, 0.5);
    _tilt += (want - _tilt) * math.min(1, dt * 8);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y);
    canvas.rotate(-_tilt * facing * 0.6);
    canvas.scale(facing * drawScale, drawScale);
    MythFigures.calkuyruk(
      canvas,
      _t,
      shape: MythFigures.horseRun(_phase, weight: _gait, leap: _leap),
    );
    canvas.restore();
  }
}
