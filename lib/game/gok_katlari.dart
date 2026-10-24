import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'audio.dart';
import 'golge_game.dart';
import 'level.dart';
import 'mechanics.dart';
import 'myth_shapes.dart';
import 'player.dart';
import 'palette.dart';
import 'puzzles.dart' show Usable;

// Göğün Katları'nın yeni katları (docs/UZATMA_PLANI.md): Yıldız Katı'nda
// Demir Kazık'ın çevresinde dönen yıldızlar ve Yedi Karakçı.

/// Bir kazığın çevresinde dönen yıldız: üstüne basılır, Sâye'yi taşır.
/// Yanındaki yıldızlarla aynı çarkın parçasıdır (eşit aralıklı evre).
/// [horse] verilirse Demir Kazık'a bağlı atlardan biridir (Ak Boz At ya da
/// Kök Boz At): üstünde küçük bir at durur, kazığa bir iple bağlıdır.
class StarPlatform extends Deck {
  StarPlatform({
    required this.pivot,
    required this.radius,
    required this.period,
    required this.phase,
    this.horse,
  }) : super(position: Vector2.zero(), size: Vector2(2 * kTile, 12)) {
    position.setFrom(_at(0));
  }

  /// Çarkın merkezi (dünya).
  final Vector2 pivot;

  /// Merkezden uzaklık (piksel).
  final double radius;

  /// Bir tur (saniye); eksi ise saat yönünün tersine döner.
  final double period;

  /// Başlangıç açısı (radyan).
  final double phase;

  /// null: yıldız; 0: Ak Boz At; 1: Kök Boz At.
  final int? horse;

  double _t = 0;

  double get turn => phase + 2 * math.pi * _t / period;

  /// [ahead] saniye sonra yıldızın ortası (dünya).
  Vector2 centerIn(double ahead) {
    final a = phase + 2 * math.pi * (_t + ahead) / period;
    return Vector2(
      pivot.x + math.cos(a) * radius,
      pivot.y + math.sin(a) * radius,
    );
  }

  /// Platformun sol üstü: yıldızın ortası çemberin üstünde.
  Vector2 _at(double t) {
    final a = phase + 2 * math.pi * t / period;
    return Vector2(
      pivot.x + math.cos(a) * radius - size.x / 2,
      pivot.y + math.sin(a) * radius - size.y / 2,
    );
  }

  @override
  void step(double dt) {
    _t += dt;
    moveTo(_at(_t));
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    final white = horse == null || horse == 0;
    final tone = white ? const Color(0xFFF2F6FF) : const Color(0xFF9EB8E8);
    // Işıltı.
    canvas.drawCircle(
      c,
      30,
      Paint()
        ..shader = ui.Gradient.radial(c, 30, [
          tone.withValues(alpha: 0.45),
          tone.withValues(alpha: 0),
        ]),
    );
    // Basılan yer: yıldız tozundan ince bir bulut.
    final plate = Paint()..color = tone.withValues(alpha: 0.85);
    for (var x = 5.0; x < size.x; x += 9) {
      canvas.drawCircle(Offset(x, 6 + math.sin(x + _t * 2) * 0.8), 6, plate);
    }
    // Ortada dört köşeli yıldız.
    final star = Path();
    for (var i = 0; i < 8; i++) {
      final r = i.isEven ? 11.0 : 3.5;
      final a = i * math.pi / 4 + _t * 0.6;
      final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(star..close(), Paint()..color = const Color(0xFFFFFFFF));
    if (horse != null) {
      // Kazığa bağlı at: küçük at silueti platformun üstünde.
      canvas.save();
      canvas.translate(size.x / 2, 0);
      canvas.scale(0.26 * (horse == 0 ? 1 : -1), 0.26);
      canvas.drawPath(MythShapes.horse, Paint()..color = tone);
      canvas.restore();
    }
  }
}

/// Çarkın merkezindeki kazık yıldızı; büyüğü Demir Kazık. Atlar varsa
/// onlara uzanan ipler de buradan çizilir.
class StarPivot extends PositionComponent with HasGameReference<GolgeGame> {
  StarPivot(Vector2 at, {this.great = false})
    : super(position: at, priority: 13);

  /// Demir Kazık (göğün direği): büyük ve ışınlı.
  final bool great;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    // Çarkın yıldızlarına uzanan ince takımyıldız çizgileri.
    final line = Paint()
      ..color = const Color(0xFFBFD0FF).withValues(alpha: great ? 0.35 : 0.18)
      ..strokeWidth = great ? 1.6 : 1;
    for (final s in game.world.children.whereType<StarPlatform>()) {
      if (s.pivot != position) continue;
      final to = s.center - position;
      canvas.drawLine(Offset.zero, Offset(to.x, to.y), line);
    }
    final r = great ? 16.0 : 8.0;
    final pulse = 0.85 + 0.15 * math.sin(_t * 2.2);
    canvas.drawCircle(
      Offset.zero,
      r * 4,
      Paint()
        ..shader = ui.Gradient.radial(Offset.zero, r * 4, [
          const Color(0xFFFFF4D0).withValues(alpha: 0.55 * pulse),
          const Color(0x00FFF4D0),
        ]),
    );
    if (great) {
      final ray = Paint()
        ..color = const Color(0xFFFFF4D0).withValues(alpha: 0.5 * pulse)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + _t * 0.15;
        final len = i.isEven ? 46.0 : 26.0;
        canvas.drawLine(
          Offset(math.cos(a), math.sin(a)) * r,
          Offset(math.cos(a), math.sin(a)) * len,
          ray,
        );
      }
    }
    canvas.drawCircle(
      Offset.zero,
      r * 0.6,
      Paint()..color = const Color(0xFFFFFFFF),
    );
  }
}

/// Yedi Karakçı: Büyük Ayı'nın yedi yıldızı, Demir Kazık'a bağlı atları
/// çalmak için çevresinde döner. Kepçenin ağzındaki iki yıldız hep kazığı
/// gösterir (gökte de öyledir). Kara yıldızlardan birine değen düşer.
class YediKarakci extends Component with HasGameReference<GolgeGame> {
  YediKarakci({required this.pivot, required this.radius, required this.period})
    : super(priority: 23);

  final Vector2 pivot;

  /// Kepçenin ağzındaki yıldızın (Dubhe) kazığa uzaklığı (piksel).
  final double radius;

  /// Bir tur (saniye).
  final double period;

  double _t = 0;

  /// Değme yarıçapı.
  static const double reach = 20;

  /// Kepçenin büyüklüğü (kare ölçüsüne göre): dönerken adaları süpürmesin.
  static const double scale = 0.55;

  /// Kepçenin biçimi: (radyal, yanal) kare cinsinden; ilk ikisi ağız
  /// (kazığı gösteren işaretçiler), sonra kepçe, en sonda sap.
  static const _shape = [
    (0.0, 0.0), // Dubhe
    (1.6, 0.0), // Merak
    (1.8, 1.8), // Phecda
    (0.4, 2.0), // Megrez
    (0.1, 3.6), // Alioth
    (0.3, 5.1), // Mizar
    (1.0, 6.5), // Alkaid
  ];

  /// Yedi yıldızın şimdiki yerleri (dünya).
  List<Vector2> get stars {
    final a = 2 * math.pi * _t / period;
    final radial = Vector2(math.cos(a), math.sin(a));
    final side = Vector2(-math.sin(a), math.cos(a));
    return [
      for (final (r, s) in _shape)
        pivot +
            radial * (radius + r * scale * kTile) +
            side * (s * scale * kTile),
    ];
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (p == null || p.isDead) return;
    for (final s in stars) {
      if ((s - p.center).length < reach) {
        GameAudio.instance.play('growl', volume: 0.6);
        p.die(cause: DeathCause.dark);
        return;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final pts = stars;
    final line = Paint()
      ..color = const Color(0xFF0A0A18).withValues(alpha: 0.55)
      ..strokeWidth = 2;
    for (var i = 0; i < pts.length; i++) {
      // Kepçe kapalı (0-1-2-3-0), sap 3-4-5-6.
      final j = i == 3 ? 0 : i + 1;
      if (i == 6) break;
      canvas.drawLine(pts[i].toOffset(), pts[j].toOffset(), line);
      if (i == 3) {
        canvas.drawLine(pts[3].toOffset(), pts[4].toOffset(), line);
      }
    }
    for (var i = 0; i < pts.length; i++) {
      final c = pts[i].toOffset();
      canvas.drawCircle(
        c,
        26,
        Paint()
          ..shader = ui.Gradient.radial(
            c,
            26,
            const [Color(0xAA9A4A8A), Color(0x449A4A8A), Color(0x009A4A8A)],
            const [0, 0.55, 1],
          ),
      );
      final spike = Path();
      for (var k = 0; k < 10; k++) {
        final r = k.isEven ? 15.0 : 5.0;
        final a = k * math.pi / 5 - _t * 1.2 + i;
        final q = c + Offset(math.cos(a) * r, math.sin(a) * r);
        k == 0 ? spike.moveTo(q.dx, q.dy) : spike.lineTo(q.dx, q.dy);
      }
      canvas.drawPath(spike..close(), Paint()..color = const Color(0xFF05050C));
      // Soluk iki göz: atlara bakar.
      final eye = Paint()..color = const Color(0xFFFFD8E8);
      canvas.drawCircle(c + const Offset(-3, -1), 1.6, eye);
      canvas.drawCircle(c + const Offset(3, -1), 1.6, eye);
    }
  }
}

// ================================================================ Yel Katı

/// Yel Ana'nın soluğu: alanın içinde ritimle eser. Önce göğü ince çizgiler
/// keser ve uğultu yükselir (uyarı), sonra soluk gelir: arkadan eserse
/// süzülüş uzar, önden eserse yerde çömelmeyeni sürükler.
class YelZone extends PositionComponent with HasGameReference<GolgeGame> {
  YelZone(this.area, {required this.dir}) : super(priority: 22);

  final Rect area;

  /// Esiş yönü (+1 sağa, -1 sola); yada taşı çevirir.
  int dir;

  double _t = 0;
  bool _awake = false;
  int _lastPhase = -1;

  static const double calm = 2.4;
  static const double warn = 1.0;
  static const double blow = 1.8;
  static const double period = calm + warn + blow;

  /// Soluğun hızı (px/sn).
  static const double force = 230;

  double get _ph => _t % period;
  bool get warning => _awake && _ph >= calm && _ph < calm + warn;
  bool get blowing => _awake && _ph >= calm + warn;

  /// Soluğun gücü (0-1): yumuşak başlar, yumuşak biter.
  double get strength {
    if (!blowing) return 0;
    final k = (_ph - calm - warn) / blow;
    return math.sin(math.pi * k.clamp(0.0, 1.0)).clamp(0.0, 1.0) * 0.4 +
        (k > 0.08 && k < 0.92 ? 0.6 : 0.0);
  }

  void flip() {
    dir = -dir;
    // Çevrilince soluk hemen uyarıyla yeniden başlar.
    _t = calm - 0.2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final p = game.player;
    if (!_awake &&
        p != null &&
        area.inflate(6 * kTile).contains(Offset(p.center.x, p.center.y))) {
      _awake = true;
    }
    if (!_awake) return;
    _t += dt;
    final phase = warning ? 1 : (blowing ? 2 : 0);
    final near =
        p != null &&
        area.inflate(4 * kTile).contains(Offset(p.center.x, p.center.y));
    if (phase != _lastPhase && near) {
      if (phase == 1) GameAudio.instance.play('gust', volume: 0.35);
      if (phase == 2) GameAudio.instance.play('gust', volume: 0.9);
    }
    _lastPhase = phase;
    if (p == null || p.isDead) return;
    if (blowing && area.contains(Offset(p.center.x, p.center.y))) {
      p.windX += dir * force * strength;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_awake) return;
    final view = game.camera.visibleWorldRect;
    if (!view.overlaps(area)) return;
    _bendGrass(canvas, view);
    final k = warning ? 0.35 : (blowing ? 0.4 + 0.6 * strength : 0.08);
    final n = warning ? 14 : (blowing ? 40 : 6);
    final speed = blowing ? 900.0 : 380.0;
    final line = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = blowing ? 2.2 : 1.2;
    for (var i = 0; i < n; i++) {
      final h = (i * 2654435761) & 0xffff;
      final y = area.top + (h % 1000) / 1000 * area.height;
      final len = 40.0 + (h % 7) * 18;
      final span = area.width + len * 2;
      final run = (_t * speed * (0.7 + (h % 5) * 0.12) + h) % span;
      final x = dir > 0 ? area.left - len + run : area.right + len - run;
      line.color = const Color(0xFFF4F8FF)
          .withValues(alpha: k * (0.4 + (h % 3) * 0.2));
      canvas.drawLine(Offset(x, y), Offset(x - dir * len, y), line);
    }
  }
}

/// Yel'in otları: alanın içindeki zeminlerde ince ot öbekleri. Durgunda
/// hafifçe salınır; uyarıda soluğun geleceği yöne eğilmeye başlar (soluk
/// gelmeden okunur), eserken yatar ve titrer.
extension on YelZone {
  void _bendGrass(Canvas canvas, Rect view) {
    final lv = game.level;
    final r = area.intersect(view.inflate(kTile));
    if (r.isEmpty) return;
    final double bend;
    if (warning) {
      final k = (_ph - YelZone.calm) / YelZone.warn;
      bend = 0.2 + 0.5 * k;
    } else if (blowing) {
      bend = 0.75 + 0.35 * strength + 0.08 * math.sin(_t * 23);
    } else {
      bend = 0.08 * math.sin(_t * 1.7);
    }
    final blade = Paint()
      ..color = kInk
      ..strokeCap = StrokeCap.round;
    final c0 = (r.left / kTile).floor();
    final c1 = (r.right / kTile).ceil();
    final r0 = math.max(1, (r.top / kTile).floor());
    final r1 = (r.bottom / kTile).ceil();
    for (var c = c0; c <= c1; c++) {
      for (var row = r0; row <= r1; row++) {
        if (!lv.solid(c, row) || lv.solid(c, row - 1)) continue;
        final y = row * kTile.toDouble();
        for (var i = 0; i < 4; i++) {
          final h = ((c * 73856093) ^ (row * 19349663) ^ (i * 83492791)) & 0xffff;
          final x = c * kTile + 2 + (h % 28).toDouble();
          final len = 10 + (h % 6).toDouble();
          // Her ot biraz gecikmeyle eğilir: dalga gibi geçer.
          final lag = math.sin(_t * 3 + x * 0.05) * 0.06;
          final a = dir * (bend + lag) * (0.8 + (h % 3) * 0.1);
          blade.strokeWidth = 1.2 + (h % 2) * 0.5;
          final tip = Offset(x + math.sin(a) * len, y - math.cos(a) * len);
          canvas.drawPath(
            Path()
              ..moveTo(x, y + 1)
              ..quadraticBezierTo(x, y - len * 0.5, tip.dx, tip.dy),
            blade..style = PaintingStyle.stroke,
          );
        }
      }
    }
  }
}

/// Yada taşı: kamların havayı yönettiği taş. Dokununca Yel Ana'nın soluğu
/// yön değiştirir.
class YadaStone extends PositionComponent
    with HasGameReference<GolgeGame>, Usable {
  YadaStone(Vector2 cell)
    : super(position: cell + Vector2(kTile / 2, kTile), priority: 15);

  double _t = 0;
  double _flash = 0;

  YelZone? get _zone {
    YelZone? best;
    var bestD = double.infinity;
    for (final z in game.world.children.whereType<YelZone>()) {
      final d = (z.area.center - Offset(position.x, position.y)).distance;
      if (z.area.inflate(3 * kTile).contains(Offset(position.x, position.y)) &&
          d < bestD) {
        bestD = d;
        best = z;
      }
    }
    return best;
  }

  @override
  bool canUse(Vector2 p) =>
      (p - position).x.abs() < 28 && (p - position).y.abs() < 48;

  @override
  void use() {
    final z = _zone;
    if (z == null) return;
    z.flip();
    _flash = 1;
    GameAudio.instance.play('bell', volume: 0.6);
    GameAudio.instance.play('gust', volume: 0.5);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _flash = math.max(0, _flash - dt * 1.5);
  }

  @override
  void render(Canvas canvas) {
    // Pürüzsüz, koyu bir taş; üstünde soluğun yönünü gösteren ışıklı ok.
    final stone = Path()
      ..moveTo(-12, 0)
      ..quadraticBezierTo(-14, -18, -4, -24)
      ..quadraticBezierTo(8, -27, 12, -14)
      ..quadraticBezierTo(14, -4, 12, 0)
      ..close();
    canvas.drawPath(stone, Paint()..color = const Color(0xFF2A3044));
    final d = _zone?.dir ?? 1;
    final glow = 0.55 + 0.25 * math.sin(_t * 2) + 0.4 * _flash;
    final rune = Paint()
      ..color = const Color(0xFFB8E0FF).withValues(alpha: glow.clamp(0.0, 1.0))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-6.0 * d, -12), Offset(6.0 * d, -12), rune);
    canvas.drawLine(Offset(6.0 * d, -12), Offset(1.0 * d, -16), rune);
    canvas.drawLine(Offset(6.0 * d, -12), Offset(1.0 * d, -8), rune);
    if (_flash > 0) {
      canvas.drawCircle(
        const Offset(0, -12),
        40 * _flash + 10,
        Paint()
          ..color = const Color(0xFFB8E0FF).withValues(alpha: 0.35 * _flash),
      );
    }
  }
}

// ============================================================== Şimşek Katı

/// Şimşek Katı'nın göğü: her yıldırım göğü aydınlatır; ışığı yavaşça söner.
/// Kara bulut basamakları yalnızca bu ışıkta görünür.
class StormSky extends Component with HasGameReference<GolgeGame> {
  StormSky() : super(priority: 2);

  double _glow = 0;

  /// Göğün aydınlığı (0-1).
  double get glow => _glow;

  void flash() => _glow = 1;

  @override
  void update(double dt) {
    super.update(dt);
    // Işık önce hızlı, sonra yavaş söner: ezberlemeye bir an kalır.
    _glow = math.max(0, _glow - dt * (_glow > 0.5 ? 1.4 : 0.6));
  }

  @override
  void render(Canvas canvas) {
    if (_glow <= 0.01) return;
    final view = game.camera.visibleWorldRect;
    canvas.drawRect(
      view,
      Paint()..color = const Color(0xFFE8E4FF).withValues(alpha: 0.22 * _glow),
    );
  }
}

/// Kara bulut basamağı: hep katıdır ama yalnızca şimşek çakınca görünür.
class StormStep extends Deck {
  StormStep(Vector2 cell, int tiles)
    : super(
        position: Vector2(cell.x, cell.y),
        size: Vector2(tiles * kTile, 12),
      );

  StormSky? _sky;

  @override
  void step(double dt) {}

  @override
  void render(Canvas canvas) {
    _sky ??= game.world.children.whereType<StormSky>().firstOrNull;
    final g = _sky?.glow ?? 1;
    final a = math.max(0.06, g);
    final body = Paint()
      ..color = const Color(0xFF1A1830).withValues(alpha: 0.9 * a);
    final rim = Paint()
      ..color = const Color(0xFFD8D4FF).withValues(alpha: 0.85 * a)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final w = size.x;
    final path = Path()..moveTo(0, 8);
    for (var x = 0.0; x <= w; x += 10) {
      path.lineTo(x, 2 + math.sin(x * 0.4) * 2);
    }
    path
      ..lineTo(w, 10)
      ..lineTo(0, 10)
      ..close();
    canvas.drawPath(path, body);
    canvas.drawLine(const Offset(0, 3), Offset(w, 3), rim);
  }
}

/// Yıldırım: düşeceği yer önce kızarır ve çatırdar, sonra gökten iner;
/// altında kalan yanar. İndiği an göğü aydınlatır (bulut basamakları
/// görünür).
class LightningStrike extends PositionComponent
    with HasGameReference<GolgeGame> {
  LightningStrike(Vector2 cell, {required double phase})
    : _t = phase,
      super(position: cell + Vector2(kTile / 2, kTile), priority: 24);

  double _t;
  int _cycle = -1;

  static const double period = 4.6;
  static const double warn = 1.3;
  static const double hit = 0.25;

  double get _ph => _t % period;

  /// Uyarı (0-1): yer kızarır.
  double get warning {
    final s = period - warn - hit;
    final ph = _ph;
    if (ph < s || ph >= s + warn) return 0;
    return (ph - s) / warn;
  }

  bool get striking => _ph >= period - hit;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final cycle = (_t / period).floor();
    final p = game.player;
    final near = p != null && (p.center.x - position.x).abs() < 20 * kTile;
    if (striking && cycle != _cycle) {
      _cycle = cycle;
      if (near) {
        GameAudio.instance.play('thunder', volume: 0.8, minGapMs: 400);
        game.world.children.whereType<StormSky>().firstOrNull?.flash();
        game.shake(3);
      }
    }
    if (striking && p != null && !p.isDead) {
      final dx = (p.center.x - position.x).abs();
      final dy = position.y - p.center.y;
      if (dx < 0.9 * kTile && dy > -kTile && dy < 4 * kTile) {
        p.die(cause: DeathCause.light);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final w = warning;
    if (w > 0) {
      // Yer kızarır, kıvılcımlar çatırdar.
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 60, height: 14),
        Paint()
          ..shader = ui.Gradient.radial(Offset.zero, 30, [
            const Color(0xFFFF6A4A).withValues(alpha: 0.7 * w),
            const Color(0x00FF6A4A),
          ]),
      );
      final spark = Paint()
        ..color = const Color(0xFFFFD0A0).withValues(alpha: w)
        ..strokeWidth = 1.2;
      for (var i = 0; i < 5; i++) {
        final a = _t * 9 + i * 1.3;
        final r = 6 + (i * 5) % 14.0;
        canvas.drawLine(
          Offset(math.cos(a) * r, -2),
          Offset(math.cos(a) * r + math.sin(a * 3) * 4, -6 - w * 8),
          spark,
        );
      }
    }
    if (striking) {
      final view = game.camera.visibleWorldRect;
      final top = view.top - position.y;
      final bolt = Path()..moveTo(0, top);
      var y = top;
      var x = 0.0;
      final rnd = math.Random((_t / period).floor());
      while (y < 0) {
        y = math.min(0, y + 28 + rnd.nextDouble() * 20);
        x = (rnd.nextDouble() - 0.5) * 30;
        bolt.lineTo(x, y);
      }
      canvas.drawPath(
        bolt,
        Paint()
          ..color = const Color(0xFFB8B0FF)
          ..strokeWidth = 9
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawPath(
        bolt,
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke,
      );
    }
  }
}
