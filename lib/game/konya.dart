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

// ============================================================== Semâzen

/// Dönen semâzen: hem kendi çevresinde hem salonun çevresinde döner. Yandan
/// bakınca bir elips çizer; önden geçerken (büyük, parlak) eteğinin
/// gölgesinde saklanılır, arkadan dönerken (küçük, soluk) saklamaz.
/// Sağ eli göğe açık, sol eli yere dönük: Hak'tan alır, halka verir.
class Semazen extends PositionComponent with HasGameReference<GolgeGame> {
  Semazen(Vector2 cell, {required int index})
    : _cx = cell.x + kTile / 2,
      _floor = cell.y + kTile,
      // Komşu semâzenler zıt evrede başlar: biri önden geçerken öteki arkada.
      _phase = index.isEven ? 0 : math.pi,
      super(size: Vector2(44, 64), anchor: Anchor.bottomCenter, priority: 16);

  /// Salonun çevresindeki yörüngenin yarıçapı ve hızı. En hızlı anında bile
  /// parmak ucunda yürüyen Sâye yetişebilir.
  static const double radius = 5 * kTile;
  static const double omega = 0.34;

  final double _cx;
  final double _floor;
  final double _phase;
  double _t = 0;
  double _spin = 0;

  double get _angle => _phase + omega * _t;

  /// Önde mi (Sâye'yi örter)?
  bool get inFront => math.sin(_angle) > 0.15;

  /// Eteğinin altında saklanıyor mu?
  bool shades(Rect r) {
    if (!inFront) return false;
    final dx = (r.center.dx - position.x).abs();
    return dx < 18 && (r.bottom - _floor).abs() < 6;
  }

  @override
  void onMount() {
    super.onMount();
    _place();
  }

  void _place() {
    position.setValues(_cx - radius * math.cos(_angle), _floor);
    final front = inFront;
    final want = front ? 26 : 12;
    if (priority != want) priority = want;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _spin += dt * 5.5;
    _place();
  }

  @override
  void render(Canvas canvas) {
    // Arkadayken küçülür ve solar.
    final depth = (math.sin(_angle) + 1) / 2;
    final k = 0.72 + 0.28 * depth;
    final alpha = 0.45 + 0.55 * depth;
    canvas.save();
    canvas.translate(size.x / 2, size.y);
    canvas.scale(k);
    drawSemazen(canvas, _spin, alpha: alpha);
    canvas.restore();
  }
}

/// Semâzenin gölgesi (ayakları orijinde). Perde sahnelerinde de kullanılır.
/// Tennure (etek) dönerken çan gibi açılır, ucu dalgalanır; destegül
/// (ceket) ve elifî nemed (kuşak), başı sağ omzuna eğik, bal rengi keçe
/// sikke. Sağ el göğe açık, sol el yere dönük; beden döndükçe kollar
/// karşıdan uzun, yandan kısa görünür.
void drawSemazen(Canvas canvas, double spin, {double alpha = 1, Color? ink}) {
  Color a(Color c, [double k = 1]) => c.withValues(alpha: c.a * alpha * k);
  final inkC = ink ?? kInk;
  const lit = Color(0xFFF6F1E8);
  const shade = Color(0xFFB9B3AA);
  const deep = Color(0xFF8E877E);
  final turn = math.cos(spin);

  // ---------------------------------------------------------- tennure
  const waistY = -30.0;
  const hemY = -2.5;
  final flare = 21.5 + 2.2 * math.sin(spin * 2);
  final lean = math.sin(spin - 0.9) * 2.4; // etek dönüşün gerisinde kalır
  const ry = 3.6;
  // Etek ucu: önden görülen yarı elips, üstünde dalga.
  Offset hem(double th) {
    final ripple =
        math.sin(th * 7 + spin * 3) * 1.1 + math.sin(th * 3 - spin) * 0.6;
    return Offset(
      lean + flare * math.cos(th),
      hemY + ry * math.sin(th) + ripple - lean * 0.25 * math.cos(th),
    );
  }

  // Arkada kalan iç yüz (eteğin altı): koyu bir şerit.
  final back = Path()..moveTo(hem(0).dx, hem(0).dy);
  for (var i = 1; i <= 24; i++) {
    final p = hem(-i / 24 * math.pi);
    back.lineTo(p.dx, p.dy);
  }
  back.close();
  canvas.drawPath(back, Paint()..color = a(deep, 0.9));
  // Ayaklar (sol ayak dönüş ekseni).
  final foot = Paint()..color = a(inkC);
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(-1.5, -0.8), width: 6, height: 2.4),
    foot,
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(3 + turn * 1.5, -0.6),
      width: 5,
      height: 2.2,
    ),
    foot,
  );
  // Etek gövdesi: belden çan biçiminde açılır.
  final left = hem(math.pi);
  final right = hem(0);
  final skirt = Path()
    ..moveTo(-5, waistY)
    ..cubicTo(-7, waistY + 9, left.dx + 7, left.dy - 12, left.dx, left.dy);
  for (var i = 1; i < 32; i++) {
    final p = hem(math.pi - i / 32 * math.pi);
    skirt.lineTo(p.dx, p.dy);
  }
  skirt
    ..lineTo(right.dx, right.dy)
    ..cubicTo(right.dx - 7, right.dy - 12, 7, waistY + 9, 5, waistY)
    ..close();
  canvas.drawPath(
    skirt,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(left.dx, 0),
        Offset(right.dx, 0),
        [a(shade), a(lit), a(lit), a(shade)],
        const [0, 0.38, 0.6, 1],
      ),
  );
  // Dönen kıvrımlar: belden etek ucuna, dönüşle birlikte kayar; yalnız öne
  // bakanlar görünür.
  final fold = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8
    ..strokeCap = StrokeCap.round;
  for (var k = 0; k < 12; k++) {
    final th = k / 12 * 2 * math.pi + spin;
    final front = math.sin(th);
    if (front <= 0.05) continue;
    final end = hem(th);
    final start = Offset(4.6 * math.cos(th), waistY + 1);
    fold.color = a(deep, 0.25 + 0.4 * front);
    canvas.drawPath(
      Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          start.dx * 0.4 + end.dx * 0.6 + lean * 0.3,
          (start.dy + end.dy) / 2,
          end.dx,
          end.dy,
        ),
      fold,
    );
  }
  // Etek ucunun ince gölgesi.
  final rim = Path()..moveTo(left.dx, left.dy);
  for (var i = 1; i <= 32; i++) {
    final p = hem(math.pi - i / 32 * math.pi);
    rim.lineTo(p.dx, p.dy);
  }
  canvas.drawPath(
    rim,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = a(deep, 0.7),
  );

  // ------------------------------------------------- destegül ve kollar
  final half = 4.2 + 1.0 * turn.abs();
  final torso = Path()
    ..moveTo(-half, waistY)
    ..lineTo(-half - 0.6, -40)
    ..quadraticBezierTo(-half, -44.5, -2, -44.5)
    ..lineTo(2, -44.5)
    ..quadraticBezierTo(half, -44.5, half + 0.6, -40)
    ..lineTo(half, waistY)
    ..close();
  // Kol: omuzdan bileğe genişleyen beyaz yen, ucunda el.
  void arm(Offset sh, Offset el, Offset wr, {required bool up}) {
    // Yen: yumuşak, yuvarlak uçlu; ince bir gölge kenarıyla.
    final path = Path()
      ..moveTo(sh.dx, sh.dy)
      ..quadraticBezierTo(el.dx, el.dy, wr.dx, wr.dy);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4.4
        ..color = a(shade),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.3
        ..color = a(lit),
    );
    // El: avuç yukarı (sağ) ya da aşağı (sol).
    final d = wr - el;
    final u = d / (d.distance + 1e-6);
    final hand = wr + u * 2.2;
    canvas.drawOval(
      Rect.fromCenter(center: hand, width: 3.6, height: 2.2),
      Paint()..color = a(inkC),
    );
    canvas.drawLine(
      hand,
      hand + u * 2 + Offset(0, up ? -0.8 : 0.8),
      Paint()
        ..color = a(inkC)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  final shR = Offset(3.6 * turn, -42.5);
  final shL = Offset(-3.6 * turn, -42.5);
  // Arkada kalan kol önce.
  void rightArm() =>
      arm(shR, Offset(10 * turn, -48), Offset(15 * turn, -54.5), up: true);
  void leftArm() =>
      arm(shL, Offset(-11 * turn, -40), Offset(-18 * turn, -36.5), up: false);
  if (math.sin(spin) > 0) {
    leftArm();
  } else {
    rightArm();
  }
  canvas.drawPath(
    torso,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(-half, 0),
        Offset(half, 0),
        [a(shade), a(lit), a(shade)],
        const [0, 0.5, 1],
      ),
  );
  // Elifî nemed: belde kara kuşak.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(-half - 0.3, waistY - 2.4, half * 2 + 0.6, 2.2),
      const Radius.circular(1),
    ),
    Paint()..color = a(inkC),
  );
  // Destegülün önü (düğme sırası).
  canvas.drawLine(
    const Offset(0.4, -44),
    const Offset(0.4, waistY - 2.6),
    Paint()
      ..color = a(shade, 0.8)
      ..strokeWidth = 0.6,
  );
  if (math.sin(spin) > 0) {
    rightArm();
  } else {
    leftArm();
  }

  // -------------------------------------------------- baş ve sikke
  canvas.save();
  canvas.translate(0.6, -44.5);
  canvas.rotate(0.28); // baş sağ omuza eğik
  canvas.drawRect(
    const Rect.fromLTWH(-1.2, -2.2, 2.4, 2.6),
    Paint()..color = a(inkC),
  );
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(0, -5.4), width: 6.6, height: 7.4),
    Paint()..color = a(inkC),
  );
  // Sikke: bal rengi keçe, yukarı doğru hafif incelen, tepesi yuvarlak.
  final hat = Path()
    ..moveTo(-3.4, -7.6)
    ..lineTo(-2.9, -20)
    ..quadraticBezierTo(0, -21.6, 2.9, -20)
    ..lineTo(3.4, -7.6)
    ..quadraticBezierTo(0, -6.8, -3.4, -7.6)
    ..close();
  canvas.drawPath(
    hat,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(-3.4, 0),
        const Offset(3.4, 0),
        [
          a(const Color(0xFF7A5A3A)),
          a(const Color(0xFFB08A5E)),
          a(const Color(0xFF6A4C30)),
        ],
        const [0, 0.45, 1],
      ),
  );
  canvas.restore();
}

// ============================================================== Avize

/// Semâhanenin dev avizesi: kollarının ucundaki mum tablaları üstüne
/// basılır. Avize semâ gibi döner; tablalar hep yatay kalır.
class Chandelier extends PositionComponent with HasGameReference<GolgeGame> {
  Chandelier(Vector2 cell, {required int index, this.arms = 4})
    : _dir = index.isEven ? 1 : -1,
      super(position: cell + Vector2.all(kTile / 2), priority: 13) {
    for (var i = 0; i < arms; i++) {
      planks.add(CandleTray(this, i * 2 * math.pi / arms + index * 0.6));
    }
  }

  static const double radius = 4 * kTile;
  static const double speed = 0.5;

  final int arms;
  final int _dir;
  final planks = <CandleTray>[];
  double t = 0;

  double angleOf(CandleTray p) => p.offset + _dir * speed * t;

  @override
  void update(double dt) {
    super.update(dt);
    t += math.min(dt, 1 / 30);
  }

  @override
  void render(Canvas canvas) {
    final chain = Paint()
      ..color = kInk
      ..strokeWidth = 2;
    // Kubbeye uzanan zincir.
    canvas.drawLine(Offset.zero, const Offset(0, -900), chain);
    final rod = Paint()
      ..color = const Color(0xFF2A1C12)
      ..strokeWidth = 3;
    for (final p in planks) {
      final a = angleOf(p);
      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(a) * radius, math.sin(a) * radius),
        rod,
      );
    }
    // Halka ve göbek.
    canvas.drawCircle(
      Offset.zero,
      radius * 0.35,
      Paint()
        ..color = const Color(0xFF3A2818)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(Offset.zero, 9, Paint()..color = kInk);
    glowDot(canvas, Offset.zero, 26, kWarmLight, 0.25);
  }
}

/// Avizenin kolundaki mum tablası (tek yönlü tahta).
class CandleTray extends Deck {
  CandleTray(this.owner, this.offset)
    : super(position: Vector2.zero(), size: Vector2(kTile * 2, 8));

  final Chandelier owner;
  final double offset;
  double _flick = 0;

  Vector2 _target() {
    final a = owner.angleOf(this);
    return owner.position +
        Vector2(math.cos(a), math.sin(a)) * Chandelier.radius -
        Vector2(size.x / 2, 0);
  }

  @override
  void onMount() {
    super.onMount();
    position.setFrom(_target());
  }

  @override
  void step(double dt) {
    _flick += dt;
    moveTo(_target());
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, 6),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF2A1C12),
    );
    canvas.drawLine(
      const Offset(2, 0.8),
      Offset(size.x - 2, 0.8),
      Paint()
        ..color = const Color(0xFFD9A860).withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );
    // Üç mum.
    for (final x in [8.0, size.x / 2, size.x - 8]) {
      canvas.drawRect(
        Rect.fromLTWH(x - 1.5, -7, 3, 7),
        Paint()..color = const Color(0xFFE8DCC4),
      );
      final f = 1 + 0.25 * math.sin(_flick * 9 + x);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, -10), width: 3 * f, height: 6 * f),
        Paint()..color = kWarmLight,
      );
      glowDot(canvas, Offset(x, -10), 12, kWarmLight, 0.35);
    }
  }
}

// ============================================================ Büyük fener

/// Kandilcilerin büyük feneri: minarenin şerefesine asılmış, damları
/// tarar. Huzmesi duvarda, kubbede, bacada kesilir; arkasına saklanılır.
/// Huzmede kalan gölge birkaç an içinde silinir.
class GreatLamp extends PositionComponent with HasGameReference<GolgeGame> {
  GreatLamp(Vector2 cell, {required int index, this.gentle = false})
    : _phase = index * 1.7,
      super(position: cell + Vector2(kTile / 2, kTile / 2), priority: 22);

  /// Huzmenin uzunluğu, yarı açısı ve tarama.
  static const double reach = 26 * kTile;
  static const double halfWidth = 0.1;
  static const double mid = math.pi / 2;
  static const double sweep = 1.15;
  /// Konya'nın damları: saklanma yerleri (revaklar) yakın; huzme her
  /// geçişte siler, oyuncu ışığı uzaktayken revaktan revaka koşar.
  static const double period = 7.0;

  /// Yeşil Kubbe'nin kasnağı: fener daha uzak ve uzun (26 kare), saklanma
  /// yerleri seyrek. Huzmenin ucu koşudan kat kat hızlı geçer; her geçişte
  /// silince kaçmak imkânsızdı (ışığın değdiği her durak siliniyordu).
  /// Burada tarama daha ağır, hızla geçen huzme silmez; üstünde oyalanan,
  /// döndüğü uçta bekleyen silinir.
  final bool gentle;
  double get _period => gentle ? 9.5 : period;
  double get _limit => gentle ? 0.5 : exposureLimit;

  /// Huzmede bu kadar kalan gölge silinir.
  static const double exposureLimit = 0.2;

  final double _phase;
  double _t = 0;
  double exposure = 0;

  double get beamAngle =>
      mid + sweep * math.sin(_t * 2 * math.pi / _period + _phase);

  /// Huzmenin kenarlarını oluşturan ışınların ucu (duvarda kesilir).
  final rays = <Offset>[];

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _trace();
    final p = game.player;
    if (p == null || p.isDead) {
      exposure = 0;
      return;
    }
    if (_sees(p)) {
      if (exposure == 0) {
        GameAudio.instance.play('chain', volume: 0.5, minGapMs: 600);
      }
      exposure += dt;
      game.threat = math.max(game.threat, 0.9);
      // Huzmenin kenarına bir an değen kaçabilir (bkz. exposureLimit).
      if (exposure > _limit) {
        exposure = 0;
        p.die(cause: DeathCause.light);
      }
    } else {
      exposure = math.max(0, exposure - dt * (gentle ? 4 : 2));
    }
  }

  bool _sees(Player p) {
    if (p.hidden) return false;
    final target = p.center;
    final d = target - position;
    final dist = d.length;
    if (dist > reach || dist < 4) return false;
    var off = math.atan2(d.y, d.x) - beamAngle;
    off = (off + math.pi) % (2 * math.pi) - math.pi;
    // Çok yakında huzme daha geniş görünür (gövdenin kendisi).
    if (off.abs() > halfWidth + 10 / dist) return false;
    return _clear(position.toOffset(), target.toOffset());
  }

  /// İki nokta arasında kaya yok mu?
  bool _clear(Offset a, Offset b) {
    final len = (b - a).distance;
    final level = game.level;
    for (var s = 18.0; s < len; s += 8) {
      final q = Offset.lerp(a, b, s / len)!;
      if (level.cellAt(q.dx, q.dy) == '#') return false;
    }
    return true;
  }

  Offset _cast(double a) {
    final level = game.level;
    final dir = Offset(math.cos(a), math.sin(a));
    final o = position.toOffset();
    for (var s = 18.0; s < reach; s += 8) {
      final q = o + dir * s;
      if (level.cellAt(q.dx, q.dy) == '#') return q;
    }
    return o + dir * reach;
  }

  void _trace() {
    rays.clear();
    const n = 7;
    for (var i = 0; i < n; i++) {
      final a = beamAngle - halfWidth + 2 * halfWidth * i / (n - 1);
      rays.add(_cast(a));
    }
  }

  Path beamPath() {
    final o = Offset.zero;
    final path = Path()..moveTo(o.dx, o.dy);
    for (final r in rays) {
      final l = r - position.toOffset();
      path.lineTo(l.dx, l.dy);
    }
    return path..close();
  }

  @override
  void render(Canvas canvas) {
    if (rays.isEmpty) return;
    final far = rays[rays.length ~/ 2] - position.toOffset();
    canvas.drawPath(
      beamPath(),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, far, [
          kCold.withValues(alpha: 0.42 + exposure),
          kCold.withValues(alpha: 0.05),
        ]),
    );
    // Fenerin kendisi.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 22, height: 26),
        const Radius.circular(4),
      ),
      Paint()..color = kInk,
    );
    canvas.drawCircle(
      Offset(math.cos(beamAngle) * 6, math.sin(beamAngle) * 6),
      6,
      Paint()..color = const Color(0xFFE4FFF8),
    );
    glowDot(canvas, Offset.zero, 60, kCold, 0.5);
  }
}

// ============================================================ Işık seli

/// Kandilcilerin yüzyıllardır biriktirdiği ışık, ustanın kandili sönmeye
/// yüz tutunca taşar: aşağıdan yükselen soğuk bir ışık seli. Gölgeye değerse
/// siler. Sâye ancak tırmanarak kurtulur.
class LightFlood extends PositionComponent with HasGameReference<GolgeGame> {
  LightFlood(
    this.startX,
    this.topY, {
    this.dark = false,
    this.molten = false,
    this.wake,
    this.maxSpeed = 72,
  }) : super(priority: 30);

  /// Selin yükselme hızının üst sınırı (piksel/sn).
  final double maxSpeed;

  /// Ergenekon: eriyen demir dağdan akkor demir yükselir.
  final bool molten;

  final double startX;

  /// Erlik'in katında ışık değil karanlık yükselir (mor-kara, söndürür).
  final bool dark;

  /// Verilirse sel bu doğru olunca uyanır (yoksa Sâye [startX]'i geçince).
  final bool Function()? wake;

  /// Bu yüksekliğin üstüne çıkınca sel durur ve çekilir.
  final double topY;
  bool _awake = false;
  bool _done = false;
  double _speed = 0;
  double _t = 0;
  double _fade = 0;

  bool get awake => _awake && !_done;
  double get surface => position.y;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (p == null) return;
    if (_done) {
      _fade = math.max(0, _fade - dt * 0.5);
      position.y += 40 * dt;
      if (_fade <= 0) removeFromParent();
      return;
    }
    if (!_awake) {
      final w = wake;
      if ((w != null ? w() : p.center.x > startX) && !p.isDead) {
        _awake = true;
        position.y = p.position.y + Player.h + 7 * kTile;
        _speed = 40;
        GameAudio.instance.play('thunder', volume: 0.6);
        game.scare(0.8);
      }
      return;
    }
    _fade = math.min(1, _fade + dt);
    if (p.position.y + Player.h < topY) {
      _done = true;
      GameAudio.instance.dread(0);
      return;
    }
    if (p.isDead) return;
    _speed = math.min(maxSpeed, _speed + dt * 2.4);
    position.y -= _speed * dt;
    // Çok geride kalırsa yetişir.
    position.y = math.min(position.y, p.position.y + Player.h + 9 * kTile);
    final gap = position.y - (p.position.y + Player.h);
    game.threat = math.max(game.threat, (1 - gap / 300).clamp(0.0, 1.0));
    GameAudio.instance.dread(((400 - gap) / 360).clamp(0.2, 1.0));
    if (gap < 2) {
      p.die(
        cause: dark
            ? DeathCause.dark
            : molten
            ? DeathCause.hazard
            : DeathCause.light,
      );
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_awake) return;
    final view = game.camera.visibleWorldRect;
    final a = _fade;
    final left = view.left - position.x - 20;
    final width = view.width + 40;
    final depth = view.bottom - position.y + 40;
    if (depth <= 0) return;
    canvas.drawRect(
      Rect.fromLTWH(left, 0, width, depth),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(0, depth),
          dark
              ? [
                  const Color(0xFF2A1640).withValues(alpha: 0.95 * a),
                  const Color(0xFF05030A).withValues(alpha: a),
                ]
              : molten
              ? [
                  const Color(0xFFFFC060).withValues(alpha: 0.95 * a),
                  const Color(0xFFB8301A).withValues(alpha: a),
                ]
              : [
                  const Color(0xFFE4FFF8).withValues(alpha: 0.85 * a),
                  kCold.withValues(alpha: 0.55 * a),
                ],
        ),
    );
    // Dalgalanan yüzey ve yukarı uçuşan kıvılcımlar.
    final edge = Paint()
      ..color =
          (dark
                  ? const Color(0xFFB27AE8)
                  : molten
                  ? const Color(0xFFFFE8B0)
                  : const Color(0xFFFFFFFF))
              .withValues(alpha: 0.9 * a)
      ..strokeWidth = 3;
    final path = Path()..moveTo(left, 0);
    for (var x = 0.0; x <= width; x += 24) {
      path.lineTo(left + x, -3 * math.sin(_t * 3 + (left + x) / 40));
    }
    canvas.drawPath(path, edge..style = PaintingStyle.stroke);
    final spark = Paint()
      ..color =
          (dark
                  ? const Color(0xFFB27AE8)
                  : molten
                  ? const Color(0xFFFFB050)
                  : kCold)
              .withValues(alpha: 0.7 * a);
    for (var i = 0; i < 30; i++) {
      final k = (i * 0.37 + _t * 0.4) % 1.0;
      final x = left + ((i * 97.0) % width);
      canvas.drawCircle(Offset(x, -k * 90), 1.6 * (1 - k), spark);
    }
  }
}

/// İnce Minare'nin şerefeden yukarısı: ince gövde, külah ve alem (süs).
class MinaretCap extends PositionComponent {
  MinaretCap(Vector2 balcony) : super(position: balcony, priority: 4);

  @override
  void render(Canvas canvas) {
    final ink = Paint()..color = kInk;
    // Şerefe korkuluğu.
    canvas.drawRect(const Rect.fromLTWH(-110, 22, 220, 4), ink);
    for (var x = -104.0; x <= 104; x += 12) {
      canvas.drawRect(Rect.fromLTWH(x, 10, 3, 14), ink);
    }
    canvas.drawRect(const Rect.fromLTWH(-110, 8, 220, 3), ink);
    // Üst gövde ve külah.
    canvas.drawRect(const Rect.fromLTWH(-14, -96, 28, 106), ink);
    for (final y in [-80.0, -50.0, -20.0]) {
      canvas.drawLine(
        Offset(-14, y),
        Offset(14, y),
        Paint()
          ..color = const Color(0xFF2A3552)
          ..strokeWidth = 1.5,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(-17, -96)
        ..lineTo(0, -170)
        ..lineTo(17, -96)
        ..close(),
      ink,
    );
    // Alem: hilal.
    canvas.drawLine(
      const Offset(0, -170),
      const Offset(0, -184),
      Paint()
        ..color = const Color(0xFFD8B860)
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      const Offset(0, -190),
      6,
      Paint()..color = const Color(0xFFD8B860),
    );
    canvas.drawCircle(const Offset(2.5, -191), 5, Paint()..color = kInk);
  }
}
