import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'golge_game.dart';
import 'level.dart';
import 'myth_figures.dart';
import 'ski.dart';
import 'winter.dart';

/// İnce buz hücreleri (haritada boş görünür, ince buz bileşeni taşır).
final _iceCache = Expando<Set<int>>();

Set<int> _thinIce(Level level) => _iceCache[level] ??= {
  for (final v in level.thinIceCells)
    (v.y / kTile).floor() * 100000 + (v.x / kTile).floor(),
};

bool _isThinIce(Level level, int c, int r) =>
    _thinIce(level).contains(r * 100000 + c);

/// Gökbörü'nün basabileceği zemin (ince buz da taşır: o bir ışıktır).
bool _ground(Level level, int c, int r) {
  final s = level.cell(c, r);
  return s == '#' || s == '=' || _isThinIce(level, c, r);
}

/// [col] sütununda, [row] yakınında üstünde durulabilecek ilk boş hücrenin
/// satırı (altı zemin); yoksa null.
int? standRow(Level level, int col, int row, {int up = 3, int down = 6}) {
  for (var r = row - up; r <= row + down; r++) {
    if (r < 0 || r + 1 >= level.height) continue;
    if (!_ground(level, col, r) && _ground(level, col, r + 1)) return r;
  }
  return null;
}

/// Gökbörü: gök tüylü, gök yeleli ışıktan kurt (docs/MITOLOJI.md §3).
/// Belirir, isterse uluyup ([onHowl]) yolun ilerisine yürür ([leadTo]),
/// Sâye yaklaşınca ya da süre dolunca söner. Saldırmaz, yakalanmaz,
/// oyuncuyu taşımaz.
class GokboruSpirit extends PositionComponent with HasGameReference<GolgeGame> {
  GokboruSpirit(
    Vector2 feet, {
    this.facing = 1,
    this.howlFirst = true,
    this.leadTo,
    this.linger = 4,
    this.onHowl,
  }) : super(
         position: feet,
         size: Vector2(52, 42),
         anchor: Anchor.bottomCenter,
         priority: 16,
       );

  /// 1 sağa, -1 sola bakar.
  int facing;
  final bool howlFirst;

  /// Yürüyerek gideceği x (dünya); null ise yerinde bekler.
  final double? leadTo;

  /// Beklerken kaç saniye sonra söner.
  final double linger;

  /// Uluduğu an (kurtları kovmak, Defter'e yazmak için).
  final void Function()? onHowl;

  static const double drawScale = 0.4;
  static const double walkSpeed = 118;

  _State _state = _State.appear;
  double _stateT = 0;
  double _t = 0;
  double alpha = 0;
  WolfPose _pose = WolfPose.stand;

  WolfPose get pose => _pose;
  bool get howling => _state == _State.howl;
  bool get vanishing => _state == _State.vanish;

  Offset get glowCenter => Offset(position.x, position.y - 20);

  void _go(_State s) {
    _state = s;
    _stateT = 0;
  }

  /// Sâye'nin önünden gider gibi yapıp onu bekler; yaklaşınca söner.
  void vanish() {
    if (_state != _State.vanish) _go(_State.vanish);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _stateT += dt;
    final p = game.player;
    final near =
        p != null &&
        (p.center.x - position.x).abs() < 3 * kTile &&
        (p.center.y - position.y).abs() < 3 * kTile;
    switch (_state) {
      case _State.appear:
        alpha = math.min(1, _stateT / 0.7);
        _pose = WolfPose.stand;
        if (_stateT >= 0.7) {
          if (howlFirst) {
            _go(_State.howl);
            GameAudio.instance.play('howl', volume: 0.75, minGapMs: 2500);
            onHowl?.call();
          } else {
            _go(leadTo != null ? _State.walk : _State.wait);
          }
        }
      case _State.howl:
        _pose = WolfPose.howl;
        if (_stateT >= 1.9) _go(leadTo != null ? _State.walk : _State.wait);
      case _State.walk:
        final target = leadTo!;
        final dx = target - position.x;
        facing = dx >= 0 ? 1 : -1;
        // Sâye'den çok uzaklaşırsa durup bekler.
        final ahead = p == null ? 0.0 : (position.x - p.center.x) * facing;
        if (ahead > 8 * kTile) {
          _pose = WolfPose.stand;
          break;
        }
        _pose = WolfPose.walk;
        final step = math.min(dx.abs(), walkSpeed * dt);
        position.x += step * facing;
        _followGround(dt);
        if (dx.abs() < 2) _go(_State.wait);
      case _State.wait:
        _pose = WolfPose.stand;
        if (p != null) facing = p.center.x >= position.x ? 1 : -1;
        if ((near && _stateT > 0.6) || _stateT > linger) _go(_State.vanish);
      case _State.vanish:
        alpha = math.max(0, 1 - _stateT / 1.1);
        if (_stateT >= 1.1) removeFromParent();
    }
  }

  /// Yürürken zemine oturur; zemin yoksa (uçurum, çukur) havada süzülür.
  void _followGround(double dt) {
    final level = game.level;
    final col = (position.x / kTile).floor();
    final row = (position.y / kTile).floor() - 1;
    final r = standRow(level, col, row, up: 2, down: 3);
    if (r == null) return;
    final y = (r + 1) * kTile.toDouble();
    position.y += (y - position.y) * math.min(1, dt * 10);
  }

  @override
  void render(Canvas canvas) {
    if (alpha <= 0) return;
    canvas.save();
    // Yürürken hafifçe iner kalkar.
    final bob = _pose == WolfPose.walk ? math.sin(_t * 9) * 0.8 : 0.0;
    canvas.translate(size.x / 2, size.y + bob);
    canvas.scale(facing * drawScale, drawScale);
    MythFigures.gokboru(canvas, _t, pose: _pose, alpha: alpha);
    canvas.restore();
  }
}

enum _State { appear, howl, walk, wait, vanish }

/// Gökbörü'nün pençe izleri: yalnızca Sâye kavanozunu örtünce (çömelip
/// saklanınca) ya da karanlıkta parlar. İnce buza ve dikene iz düşmez:
/// izler güvenli yolu gösterir.
class PawTrail extends PositionComponent with HasGameReference<GolgeGame> {
  PawTrail(this.prints, this.dark)
    : super(
        position: _min(prints),
        size: _max(prints) - _min(prints) + Vector2.all(1),
        // Sisin (18) üstünde parlar.
        priority: 19,
      );

  /// İzlerin dünya konumları (zeminin hemen üstü).
  final List<Vector2> prints;

  /// İz karanlık bölgede mi (orada her zaman parlar).
  final List<bool> dark;

  double _cover = 0;
  double _t = 0;

  /// Kavanoz örtülüyken görünürlük (0-1).
  double get cover => _cover;

  static Vector2 _min(List<Vector2> ps) => Vector2(
    ps.map((p) => p.x).reduce(math.min) - 8,
    ps.map((p) => p.y).reduce(math.min) - 8,
  );
  static Vector2 _max(List<Vector2> ps) => Vector2(
    ps.map((p) => p.x).reduce(math.max) + 8,
    ps.map((p) => p.y).reduce(math.max) + 8,
  );

  /// [c0]–[c1] sütunları boyunca, [row] yakınındaki zemine izler.
  static PawTrail? build(Level level, int c0, int c1, int row) {
    final prints = <Vector2>[];
    final dark = <bool>[];
    for (var c = c0; c <= c1; c++) {
      final r = standRow(level, c, row, up: 2, down: 3);
      if (r == null) continue;
      if (_isThinIce(level, c, r + 1) ||
          level.cell(c, r) == '^' ||
          level.cell(c, r + 1) == '^') {
        continue;
      }
      final p = Vector2(
        c * kTile + kTile / 2 + (c.isEven ? -6 : 6),
        (r + 1) * kTile - 4.0,
      );
      prints.add(p);
      dark.add(level.inDarkZone(p));
    }
    if (prints.isEmpty) return null;
    return PawTrail(prints, dark);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    final covered = p != null && !p.isDead && (p.crouching || p.hidden);
    final target = covered ? 1.0 : 0.0;
    _cover += (target - _cover) * math.min(1, dt * (covered ? 3 : 2));
  }

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect.inflate(40);
    for (var i = 0; i < prints.length; i++) {
      final base = dark[i] ? 0.85 : _cover;
      if (base < 0.02) continue;
      final w = prints[i];
      if (!view.contains(Offset(w.x, w.y))) continue;
      // İzler sırayla, yürüyen bir kurt gibi nabız atar.
      final pulse = 0.75 + 0.25 * math.sin(_t * 2.4 - i * 0.6);
      canvas.save();
      canvas.translate(w.x - position.x, w.y - position.y);
      canvas.scale(0.62);
      MythFigures.pawPrint(canvas, base * pulse);
      canvas.restore();
    }
  }
}

/// Bölümdeki Gökbörü düzeni: kurtlar Sâye'yi köşeye sıkıştırınca bir kez
/// araya girer, uzun süre ilerlenemezse yolun ilerisinde uluyup yönü
/// gösterir, bölümün belli yerlerinde uzaktan bir an belirir.
class GokboruWarden extends Component with HasGameReference<GolgeGame> {
  GokboruWarden({
    required this.guard,
    required this.help,
    required this.watch,
    this.leadTo,
  });

  /// Kurtlara karşı araya girer (bölümde bir kez).
  final bool guard;

  /// Takılınca yol gösterir.
  final bool help;

  /// Uzaktan bir an belirdiği hücreler.
  final List<(int, int)> watch;

  /// Araya girdikten sonra yürüyüp beklediği sütun.
  final int? leadTo;

  /// Bu kadar saniye ilerlenemezse uluyup yönü gösterir.
  static const double stuckAfter = 80;

  double _best = -1;
  double _still = 0;
  double _helpCd = 0;
  double _scan = 0;

  GokboruSpirit? get _active {
    for (final c in game.world.children) {
      if (c is GokboruSpirit && !c.vanishing) return c;
    }
    return null;
  }

  String get _guardKey => 'gokboru:guard:${game.levelIndex}';

  @override
  void update(double dt) {
    super.update(dt);
    final p = game.player;
    if (p == null || p.isDead || game.cinematic) return;
    final level = game.level;
    _helpCd = math.max(0, _helpCd - dt);
    // İlerleme: en iyisi aşılmadıkça "takılı" süre birikir.
    final prog = level.progressOf(p.center);
    if (prog > _best + 2 * kTile) {
      _best = prog;
      _still = 0;
    } else {
      _still += dt;
    }
    _scan += dt;
    if (_scan < 0.1) return;
    _scan = 0;

    if (guard && !game.eventSeen(_guardKey)) {
      for (final w in game.world.children.whereType<Wolf>()) {
        final d = w.center - p.center;
        if (w.hunting &&
            !w.falling &&
            d.x.abs() < 5.5 * kTile &&
            d.y.abs() < 2 * kTile) {
          _intervene(w);
          break;
        }
      }
    }

    for (var i = 0; i < watch.length; i++) {
      final key = 'gokboru:watch:${game.levelIndex}:$i';
      if (game.eventSeen(key)) continue;
      final (c, r) = watch[i];
      final at = Vector2((c + 0.5) * kTile, (r + 1) * kTile.toDouble());
      if ((at.x - p.center.x).abs() < 13 * kTile &&
          (at.y - p.center.y).abs() < 12 * kTile &&
          _active == null) {
        game.markEvent(key);
        final row = standRow(level, c, r) ?? r;
        game.world.add(
          GokboruSpirit(
            Vector2(at.x, (row + 1) * kTile.toDouble()),
            facing: p.center.x < at.x ? -1 : 1,
            linger: 2.5,
          ),
        );
      }
    }

    if (help && _still > stuckAfter && _helpCd <= 0 && _active == null) {
      final ahead = _ahead(prog);
      if (ahead != null) {
        _helpCd = 120;
        _still = stuckAfter * 0.5;
        game.world.add(
          GokboruSpirit(
            ahead,
            facing: ahead.x >= p.center.x ? 1 : -1,
            linger: 6,
          ),
        );
      }
    }
  }

  /// Yolun ilerisinde Gökbörü'nün belireceği yer: sıradaki Hüdhüd konağının
  /// ya da kontrol noktasının zemini (yoksa çıkış).
  Vector2? _ahead(double prog) {
    final level = game.level;
    // Hüdhüd'ün giremediği yerlerde (yerin altı) kontrol noktaları da konak.
    final stops = [...level.birdCells, ...level.checkpointCells, level.exitCell]
      ..sort((a, b) => level.progressOf(a).compareTo(level.progressOf(b)));
    for (final s in stops) {
      if (level.progressOf(s) < prog + 3 * kTile) continue;
      final c = (s.x / kTile).floor();
      final r = standRow(level, c, (s.y / kTile).floor());
      if (r == null) continue;
      return Vector2((c + 0.5) * kTile, (r + 1) * kTile.toDouble());
    }
    return null;
  }

  /// Kurtlar Sâye'ye atılmak üzere: Gökbörü araya girer, ulur, kurtlar
  /// kaçar; ardından yolun ilerisine yürüyüp bekler.
  void _intervene(Wolf wolf) {
    final p = game.player!;
    game.markEvent(_guardKey);
    final level = game.level;
    final x = (wolf.center.x + p.center.x) / 2;
    final c = (x / kTile).floor();
    final r =
        standRow(level, c, (p.center.y / kTile).floor()) ??
        (p.position.y + p.size.y) ~/ kTile - 1;
    void scare() {
      for (final w in game.world.children.whereType<Wolf>()) {
        if ((w.center - p.center).length < 16 * kTile) w.scare(6);
      }
    }

    scare();
    final lead = leadTo;
    game.world.add(
      GokboruSpirit(
        Vector2(x, (r + 1) * kTile.toDouble()),
        facing: wolf.center.x >= x ? 1 : -1,
        leadTo: lead == null ? null : (lead + 0.5) * kTile,
        linger: 20,
        onHowl: () {
          scare();
          game.meetMyth('gokboru');
        },
      ),
    );
  }
}

/// Çığ bölümünde Gökbörü: çığ uyanınca kayan Sâye'nin önünde yamaçta koşar;
/// uçurumların üstünden önce o sıçrar, kayaların üstünden önce o atlar:
/// güvenli hattı gösterir. Oynanışa dokunmaz; çığ dağılınca söner.
class SkiGuide extends PositionComponent with HasGameReference<GolgeGame> {
  SkiGuide() : super(anchor: Anchor.bottomCenter, priority: 17);

  /// Sâye'nin ne kadar önünde koşar.
  static const double lead = 6 * kTile;
  static const double drawScale = 0.4;

  double _t = 0;
  double alpha = 0;
  bool _shown = false;

  /// Zemin (uçurumda null): o x'te kurt nerede durur.
  double? _ground(double x) => game.skiSurface?.at(x);

  /// Uçurumun üstünde: kenarlar arasında bir sıçrayış yayı.
  double _arc(double x) {
    var a = x;
    var b = x;
    for (var i = 0; i < 40 && _ground(a) == null; i++) {
      a -= kTile / 2;
    }
    for (var i = 0; i < 40 && _ground(b) == null; i++) {
      b += kTile / 2;
    }
    final ya = _ground(a) ?? position.y;
    final yb = _ground(b) ?? ya;
    final u = b > a ? ((x - a) / (b - a)).clamp(0.0, 1.0) : 0.0;
    final span = b - a;
    return ya + (yb - ya) * u - math.sin(u * math.pi) * (span * 0.35 + 30);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    Avalanche? av;
    for (final c in game.world.children) {
      if (c is Avalanche) av = c;
    }
    final running = av != null && av.awake && p != null && !p.isDead;
    if (running && !_shown) {
      _shown = true;
      position.setValues(
        p.center.x + lead,
        _ground(p.center.x + lead) ?? p.center.y,
      );
      game.meetMyth('gokboru');
      GameAudio.instance.play('howl', volume: 0.5, minGapMs: 4000);
    }
    alpha = running
        ? math.min(1, alpha + dt * 1.5)
        : math.max(0, alpha - dt * 0.8);
    if (!running) return;
    // Önde koşar; çok açılırsa ya da geride kalırsa yumuşakça yetişir.
    final want = p.center.x + lead;
    position.x += (want - position.x) * math.min(1, dt * 12);
    final g = _ground(position.x);
    var y = g ?? _arc(position.x);
    // Kayanın üstünden atlar.
    for (final r in game.world.children.whereType<SkiRock>()) {
      final d = position.x - (r.position.x + r.size.x / 2);
      if (d.abs() < 40) y -= math.cos(d / 40 * math.pi / 2) * 34;
    }
    position.y = y;
  }

  @override
  void render(Canvas canvas) {
    if (alpha <= 0) return;
    canvas.save();
    canvas.translate(0, math.sin(_t * 14) * 1.2);
    canvas.scale(drawScale);
    MythFigures.gokboru(canvas, _t, pose: WolfPose.walk, alpha: alpha);
    canvas.restore();
  }
}
