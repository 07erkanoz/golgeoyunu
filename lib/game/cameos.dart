import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'audio.dart';
import 'gokboru.dart' show standRow;
import 'golge_game.dart';
import 'level.dart';
import 'myth_figures.dart';
import 'nemrut.dart';
import 'puzzles.dart';
import 'strings.dart';

/// Mevcut bölümlere serpiştirilen kısa, bir kezlik görünüşler
/// (docs/MITOLOJI.md §4). Hiçbiri oynanışı zorlaştırmaz; ilk görülünce
/// Defter > Efsaneler'de kartı açılır.
///
/// Türler ve (sütun, satır) anlamı:
/// - `suIyesi`: su haznesinin başında kıpırdamadan bekleyene Su İyesi
///   sudan yükselir, vanayı gösterir (konum kullanılmaz: en yakın hazne).
/// - `tulpar`: Sâye bu sütunu geçince gökte kanatlı bir at geçer.
/// - `ayazAta`: hücrenin yakınına gelince tipide bir an belirir.
/// - `akAna`: tufan başlayınca bu sütunda sudan yükselir, yolu aydınlatır.
/// - `basat`: taş dev yıkılınca ozan dizesi (konum kullanılmaz).
/// - `albasti`: bu hücreden başlayan mağarada uzun kıpırdamayanın ardında
///   kızıl bir gölge belirir, ışığını çeker; hücrenin solundaki demir nalın
///   yanına yaklaşamaz.
/// - `erlik`: hücrenin yakınında yerin dibinden boğuk bir ses.
/// - `erTostuk`: hücrenin duvarında Er Töştük'ün atlı gölgesi belirir.
/// - `demirci`: ocağın başında örsünü döven Demirci.
/// - `asena`: mağaranın ağzında yatan ak boz dişi kurt (sığınak).
class CameoWarden extends Component with HasGameReference<GolgeGame> {
  CameoWarden(this.cameos);

  final List<(String, int, int)> cameos;

  double _still = 0;
  Vector2? _stillAt;

  String _key(String kind) => 'cameo:${game.levelIndex}:$kind';

  void _say(String key) {
    game.once('cameo:$key', S.of('cameo_$key'));
  }

  @override
  void update(double dt) {
    super.update(dt);
    final p = game.player;
    if (p == null || p.isDead || game.cinematic) return;
    // Kıpırdamadan bekleme süresi (Su İyesi, Albastı).
    final at = _stillAt;
    if (at == null || (p.center - at).length > 6 || !p.onGround) {
      _stillAt = p.center.clone();
      _still = 0;
    } else {
      _still += dt;
    }
    for (final (kind, c, r) in cameos) {
      if (game.eventSeen(_key(kind))) continue;
      final cell = Vector2((c + 0.5) * kTile, (r + 0.5) * kTile);
      final d = p.center - cell;
      switch (kind) {
        case 'suIyesi':
          final basin = _nearestBasin(p.center);
          if (basin == null || _still < 2.5) break;
          final zone = basin.area.inflate(5 * kTile);
          if (!zone.contains(Offset(p.center.x, p.center.y))) break;
          // Boş haznenin dibinden ya da ekranın dışından yükselmez: su
          // olmalı ve su yüzü görünmeli (yoksa yalnızca yazı çıkıyordu).
          if (basin.surface > basin.area.bottom - 2 * kTile) break;
          final face = Offset(basin.area.center.dx, basin.surface - 30);
          if (!game.camera.visibleWorldRect.deflate(kTile).contains(face)) {
            break;
          }
          game.markEvent(_key(kind));
          game.world.add(WaterFace(basin));
          _say(kind);
          game.meetMyth(kind);
        case 'tulpar':
          if (p.center.x < cell.x) break;
          game.markEvent(_key(kind));
          game.world.add(TulparFlight());
          _say(kind);
          game.meetMyth(kind);
        case 'ayazAta':
          if (d.x.abs() > 10 * kTile || d.y.abs() > 5 * kTile) break;
          game.markEvent(_key(kind));
          final row = standRow(game.level, c, r) ?? r;
          game.world.add(
            Apparition(
              Vector2((c + 0.5) * kTile, (row + 1) * kTile.toDouble()),
              draw: MythFigures.ayazAta,
              drawScale: 0.55,
              facing: p.center.x < cell.x ? -1 : 1,
              glow: const Color(0xFFBFE0F4),
              hold: 3.5,
            ),
          );
          GameAudio.instance.play('gust', volume: 0.6, minGapMs: 2000);
          _say(kind);
          game.meetMyth(kind);
        case 'akAna':
          WaterBasin? flood;
          for (final b in game.world.children.whereType<WaterBasin>()) {
            if (b.flooding) flood = b;
          }
          if (flood == null) break;
          game.markEvent(_key(kind));
          game.world.add(AkAnaRise(flood, cell.x));
          _say(kind);
          game.meetMyth(kind);
        case 'basat':
          final fell = game.world.children.whereType<StoneGiant>().any(
            (g) => g.fallen,
          );
          if (!fell) break;
          game.markEvent(_key(kind));
          _say(kind);
          game.meetMyth(kind);
        case 'albasti':
          final shoe = Vector2((c - 5 + 0.5) * kTile, (r - 1.5) * kTile);
          final inCave =
              p.center.x > (c - 6) * kTile &&
              p.center.x < (c + 27) * kTile &&
              (p.center.y - cell.y).abs() < 3 * kTile;
          if (!inCave) break;
          if (game.world.children.whereType<Horseshoe>().isEmpty) {
            game.world.add(Horseshoe(shoe));
          }
          // Demir nalın yanına yaklaşamaz.
          if ((p.center - shoe).length < 5 * kTile) break;
          if (_still < 4) break;
          game.markEvent(_key(kind));
          game.world.add(AlbastiShade());
          _say(kind);
          game.meetMyth(kind);
        case 'kam' || 'ulgen':
          if (d.x.abs() > 9 * kTile || d.y.abs() > 5 * kTile) break;
          game.markEvent(_key(kind));
          final row = standRow(game.level, c, r) ?? r;
          game.world.add(
            Apparition(
              Vector2((c + 0.5) * kTile, (row + 1) * kTile.toDouble()),
              draw: kind == 'kam' ? MythFigures.kam : MythFigures.ulgenLight,
              drawScale: kind == 'kam' ? 0.36 : 1,
              facing: p.center.x < cell.x ? -1 : 1,
              glow: kind == 'kam'
                  ? const Color(0xFFFF9A3A)
                  : const Color(0xFFFFF4D0),
              hold: kind == 'kam' ? 600 : 12,
            ),
          );
          _say(kind);
          game.meetMyth(kind);
        case 'gokKat':
          if (d.x.abs() > 6 * kTile || d.y.abs() > 6 * kTile) break;
          game.markEvent(_key(kind));
          _say(kind);
          game.meetMyth('ayAtaGunAna');
        case 'demirci' || 'asena':
          if (d.x.abs() > 9 * kTile || d.y.abs() > 4 * kTile) break;
          game.markEvent(_key(kind));
          final row = standRow(game.level, c, r) ?? r;
          game.world.add(
            Apparition(
              Vector2((c + 0.5) * kTile, (row + 1) * kTile.toDouble()),
              draw: kind == 'asena' ? MythFigures.asena : MythFigures.demirci,
              drawScale: kind == 'asena' ? 0.42 : 0.36,
              facing: p.center.x < cell.x ? -1 : 1,
              glow: kind == 'asena'
                  ? const Color(0xFFF0E0B8)
                  : const Color(0xFFFF8A3A),
              hold: kind == 'asena' ? 600 : 14,
            ),
          );
          _say(kind);
          game.meetMyth(kind);
        case 'erTostuk':
          if (d.x.abs() > 8 * kTile || d.y.abs() > 4 * kTile) break;
          game.markEvent(_key(kind));
          game.world.add(
            Apparition(
              Vector2(cell.x, cell.y + kTile / 2),
              draw: MythFigures.erTostukShadow,
              drawScale: 0.9,
              facing: p.center.x < cell.x ? -1 : 1,
              glow: const Color(0xFFFFE0A0),
              hold: 5,
              fadeIn: 2,
              fadeOut: 2.5,
            ),
          );
          _say(kind);
          game.meetMyth('erTostuk');
        case 'erlik':
          if (d.x.abs() > 3 * kTile || d.y.abs() > 3 * kTile) break;
          game.markEvent(_key(kind));
          GameAudio.instance.play('growl', volume: 0.35);
          GameAudio.instance.play('murmur', volume: 0.5);
          _say(kind);
          game.meetMyth(kind);
      }
    }
  }

  WaterBasin? _nearestBasin(Vector2 at) {
    WaterBasin? best;
    var bestD = double.infinity;
    for (final b in game.world.children.whereType<WaterBasin>()) {
      final d = (b.area.center.dx - at.x).abs();
      if (d < bestD) {
        bestD = d;
        best = b;
      }
    }
    return best;
  }
}

/// Bir efsane varlığının kısa görünüşü: belirir, bekler, söner.
class Apparition extends PositionComponent with HasGameReference<GolgeGame> {
  Apparition(
    Vector2 feet, {
    required this.draw,
    required this.drawScale,
    required this.glow,
    this.facing = 1,
    this.fadeIn = 1.4,
    this.hold = 3,
    this.fadeOut = 2,
  }) : super(position: feet, anchor: Anchor.bottomCenter, priority: 16);

  final void Function(Canvas, double) draw;
  final double drawScale;
  final Color glow;
  final int facing;
  final double fadeIn;
  final double hold;
  final double fadeOut;

  double _t = 0;
  double alpha = 0;

  Offset get glowCenter => Offset(position.x, position.y - 45 * drawScale);
  double get glowRadius => 110 * drawScale + 40;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t < fadeIn) {
      alpha = _t / fadeIn;
    } else if (_t < fadeIn + hold) {
      alpha = 1;
    } else {
      alpha = math.max(0, 1 - (_t - fadeIn - hold) / fadeOut);
      if (alpha <= 0) removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (alpha <= 0) return;
    // Saydamlık tek katmanda: varlığın kendi çizimi değişmeden söner.
    canvas.saveLayer(
      Rect.fromCenter(center: Offset.zero, width: 400, height: 400),
      Paint()..color = Color.fromRGBO(0, 0, 0, alpha * 0.85),
    );
    canvas.scale(facing * drawScale, drawScale);
    draw(canvas, _t);
    canvas.restore();
  }
}

/// Su İyesi: haznenin ortasında sudan beline kadar yükselen, ak giysili,
/// mavimsi ışık saçan bir kadın (Hakas, Altay ve Tatar anlatılarındaki
/// gibi). Başında kanat biçimli boynuzlar, omuzlarından dalga kıvrımları
/// iner; belden aşağısı suyun içinde seçilen bir balık kuyruğudur. Çevresinde
/// ışıldayan mavi balıklar yüzer. Bir kolunu açar, öbürüyle vanayı gösterir;
/// balıklardan biri vanaya yüzer, vana ışır; sonra yeniden suya çekilir.
class WaterFace extends Component with HasGameReference<GolgeGame> {
  WaterFace(this.basin) : super(priority: 27);

  final WaterBasin basin;
  double _t = 0;

  static const double rise = 1.6;
  static const double stay = 7.5;
  static const double sink = 1.8;
  static const double drawScale = 0.66;

  /// Sudan çıkış (0: suyun altında, 1: belden yukarısı dışarıda).
  double get _up {
    if (_t < rise) {
      final u = _t / rise;
      return u * u * (3 - 2 * u);
    }
    if (_t < rise + stay) return 1;
    final u = ((_t - rise - stay) / sink).clamp(0.0, 1.0);
    return 1 - u * u * (3 - 2 * u);
  }

  double get alpha => _up;

  /// Vanaya doğru eğilme (-1 sola, 1 sağa), sudan çıktıkça.
  double get _lean {
    final v = _valve;
    if (v == null) return 0;
    return (v.position.x < _at.dx ? -1.0 : 1.0) * _up;
  }

  Offset get _at => Offset(basin.area.center.dx, basin.surface);

  /// Gösterdiği vana: önce boşaltan (bulmaca onunla başlar), en yakını.
  Valve? get _valve {
    Valve? best;
    var bestD = double.infinity;
    for (final v in game.world.children.whereType<Valve>()) {
      final d = (v.position.x - _at.dx).abs() + (v.fill ? 2000 : 0);
      if (d < bestD) {
        bestD = d;
        best = v;
      }
    }
    return best;
  }

  // ------------------------------------------------------------ biçim
  // Beden koordinatları: bel su yüzünde (0, 0), yukarı -y. Gösteren kol +x
  // yanındadır (vana soldaysa bütün beden aynalanır).

  /// Kalınlığı değişen şerit: orta çizgi ve her noktadaki yarı genişlik.
  static Path _tube(List<Offset> pts, List<double> w) {
    final left = <Offset>[];
    final right = <Offset>[];
    for (var j = 0; j < pts.length; j++) {
      final dd = pts[math.min(j + 1, pts.length - 1)] - pts[math.max(j - 1, 0)];
      final n = Offset(-dd.dy, dd.dx) / (dd.distance + 1e-6);
      left.add(pts[j] + n * w[j]);
      right.add(pts[j] - n * w[j]);
    }
    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (final q in left.skip(1)) {
      path.lineTo(q.dx, q.dy);
    }
    for (final q in right.reversed) {
      path.lineTo(q.dx, q.dy);
    }
    return path..close();
  }

  /// Gövde: bel, göğüs, omuzlar, boyun.
  static final Path _torso = Path()
    ..moveTo(-6.5, 1)
    ..cubicTo(-7.5, -6, -6.8, -12, -7.6, -18)
    ..cubicTo(-8.6, -23, -10.5, -26, -11, -29)
    ..cubicTo(-11, -31.5, -8, -32.5, -4, -33)
    ..lineTo(-2.3, -34)
    ..lineTo(-2.3, -38)
    ..lineTo(2.3, -38)
    ..lineTo(2.3, -34)
    ..lineTo(4, -33)
    ..cubicTo(8, -32.5, 11, -31.5, 11, -29)
    ..cubicTo(10.5, -26, 8.6, -23, 7.6, -18)
    ..cubicTo(6.8, -12, 7.5, -6, 6.5, 1)
    ..close();

  static final Path _head = Path()
    ..addOval(
      Rect.fromCenter(center: const Offset(0, -43), width: 9.5, height: 11.5),
    );

  /// Ak giysi: kalp yakalı, belden göğse; gövdeyle kesişen kısım.
  static final Path _dress = Path.combine(
    PathOperation.intersect,
    _torso,
    Path()
      ..moveTo(-12, -22)
      ..quadraticBezierTo(-4, -24, 0, -19.5)
      ..quadraticBezierTo(4, -24, 12, -22)
      ..lineTo(12, 2)
      ..lineTo(-12, 2)
      ..close(),
  );

  /// Balık kuyruğu: belden suyun içine iner, gösteren kolun karşı yanına
  /// kıvrılır; ucunda çatal yüzgeç.
  static const _tailLine = [
    Offset(0, 0),
    Offset(-0.5, 8),
    Offset(-1.5, 16),
    Offset(-3.5, 23),
    Offset(-7, 28),
    Offset(-11.5, 29.5),
    Offset(-14.5, 27),
  ];
  static final Path _tail = Path.combine(
    PathOperation.union,
    _tube(_tailLine, const [6.6, 8, 6.8, 5, 3.6, 2.6, 1.8]),
    Path()
      ..moveTo(-14, 27)
      ..quadraticBezierTo(-16, 19, -21, 15)
      ..quadraticBezierTo(-20, 22, -21.5, 25)
      ..quadraticBezierTo(-23.5, 25, -27, 22.5)
      ..quadraticBezierTo(-22, 29, -15.5, 30)
      ..close(),
  );

  /// x'i aynalayan dönüşüm.
  static final _mirror = Float64List.fromList(const [
    -1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
  ]);

  /// Kanat biçimli boynuzlar (sağ; sol aynası).
  static final Path _wing = Path()
    ..moveTo(2, -48)
    ..cubicTo(5, -50, 8, -54, 9, -60)
    ..cubicTo(9.5, -64, 13, -67.5, 17.5, -66.5)
    ..lineTo(15, -63.8)
    ..lineTo(17, -62)
    ..lineTo(13.8, -59.6)
    ..lineTo(15.4, -57.4)
    ..lineTo(12.2, -55)
    ..lineTo(13, -52.8)
    ..lineTo(8.5, -50.6)
    ..lineTo(5, -47)
    ..close();
  static final Path _wings = Path.combine(
    PathOperation.union,
    _wing,
    _wing.transform(_mirror),
  );

  /// Omuz eklemi (gösteren yan; öbür kol aynasıdır).
  static const _sh = Offset(9.2, -29.5);
  static const double _upper = 15;
  static const double _fore = 13;

  /// Son çizilen gösteren kolun parmak ucu (beden koordinatları).
  Offset _tip = _sh;

  /// İki kemikli kol: omuzdan [target] yönüne uzanır, dirsek aşağı bükülür.
  /// [lift] 0: yanda sarkık, 1: hedefe uzanır. [point] işaret parmağıyla
  /// gösterir; değilse avuç açıktır.
  Path _arm(Offset target, double lift, double sway, {required bool point}) {
    const rest = math.pi / 2 - 0.22;
    final want = math.atan2(target.dy - _sh.dy, target.dx - _sh.dx);
    final ang = rest + (want - rest) * lift + sway;
    final reach = (_upper + _fore) * 0.92;
    final t = _sh + Offset(math.cos(ang), math.sin(ang)) * reach;
    final dist = (t - _sh).distance;
    final cosA =
        ((_upper * _upper + dist * dist - _fore * _fore) / (2 * _upper * dist))
            .clamp(-1.0, 1.0);
    final ua = ang + math.acos(cosA);
    final e = _sh + Offset(math.cos(ua), math.sin(ua)) * _upper;
    final dir = (t - e) / (t - e).distance;
    final pts = <Offset>[];
    final widths = <double>[];
    for (var i = 0; i <= 6; i++) {
      final u = i / 6;
      pts.add(Offset.lerp(_sh, e, u)!);
      widths.add(3.3 - 1.2 * u + 0.4 * math.sin(u * math.pi));
    }
    for (var i = 1; i <= 6; i++) {
      final u = i / 6;
      pts.add(Offset.lerp(e, t, u)!);
      widths.add(2.15 - 0.75 * u + 0.35 * math.sin(u * math.pi));
    }
    var path = Path.combine(
      PathOperation.union,
      _tube(pts, widths),
      Path()..addOval(Rect.fromCircle(center: _sh, radius: 3.1)),
    );
    final nrm = Offset(-dir.dy, dir.dx);
    final palm = t + dir * 2.2;
    Path finger(Offset from, Offset d, double len, double w) {
      final tip = from + d * len;
      final n = Offset(-d.dy, d.dx);
      return Path()
        ..moveTo(from.dx + n.dx * w, from.dy + n.dy * w)
        ..lineTo(tip.dx + n.dx * w * 0.7, tip.dy + n.dy * w * 0.7)
        ..quadraticBezierTo(
          tip.dx + d.dx * w,
          tip.dy + d.dy * w,
          tip.dx - n.dx * w * 0.7,
          tip.dy - n.dy * w * 0.7,
        )
        ..lineTo(from.dx - n.dx * w, from.dy - n.dy * w)
        ..close();
    }

    final parts = <Path>[
      Path()..addOval(Rect.fromCenter(center: palm, width: 5.0, height: 4.0)),
      if (point) ...[
        // Kıvrık parmaklar, uzanan işaret parmağı, başparmak.
        Path()..addOval(
          Rect.fromCenter(
            center: palm + dir * 2.0 + nrm * 0.8,
            width: 3.0,
            height: 2.6,
          ),
        ),
        finger(palm + dir * 1.8 - nrm * 0.8, dir, 4.6, 0.56),
        finger(palm - nrm * 1.5, (dir * 0.6 - nrm) / 1.17, 2.1, 0.5),
      ] else ...[
        // Açık avuç: bitişik parmaklar ve açılan başparmak.
        finger(palm + dir * 1.6, dir, 3.4, 1.3),
        finger(palm - nrm * 1.4, (dir * 0.5 - nrm) / 1.12, 2.4, 0.5),
      ],
    ];
    for (final part in parts) {
      path = Path.combine(PathOperation.union, path, part);
    }
    if (point) _tip = palm + dir * 1.8 - nrm * 0.8 + dir * 4.6;
    return path;
  }

  /// Bedeni (beden koordinatlarında) çizer; [a] saydamlık.
  void _figure(Canvas c, double a, Path arm, Path open) {
    final glow = Paint()
      ..color = const Color(0xFF9EE8F0).withValues(alpha: 0.5 * a)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final openM = open.transform(_mirror);
    for (final p in [_tail, _torso, _head, _wings, arm, openM]) {
      c.drawPath(p, glow);
    }
    // Kuyruk: mavi-yeşil pullar.
    c.drawPath(
      _tail,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          const Offset(-14, 30),
          [
            const Color(0xFF7FD6DE).withValues(alpha: 0.95 * a),
            const Color(0xFF2E8FA8).withValues(alpha: 0.95 * a),
          ],
        ),
    );
    final scale = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.45
      ..color = const Color(0xFFD8FBFF).withValues(alpha: 0.55 * a);
    for (var j = 1; j < _tailLine.length - 2; j++) {
      final p = _tailLine[j];
      for (var k = -1; k <= 1; k++) {
        final q = p + Offset(k * 2.6 + (j.isEven ? 1.3 : 0), 0);
        c.drawArc(
          Rect.fromCircle(center: q, radius: 1.3),
          0,
          math.pi,
          false,
          scale,
        );
      }
    }
    // Arkada toplanmış saç.
    c.drawOval(
      Rect.fromCenter(center: const Offset(0, -45), width: 12, height: 11),
      Paint()..color = const Color(0xFF3E8C98).withValues(alpha: 0.95 * a),
    );
    final skin = Paint()
      ..shader = ui.Gradient.linear(const Offset(0, -50), const Offset(0, 0), [
        const Color(0xFFF2FFFD).withValues(alpha: 0.97 * a),
        const Color(0xFFBFEFF0).withValues(alpha: 0.95 * a),
      ]);
    // Omuzlardan inen dalga kıvrımları (kolların arkasında).
    final curl = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..color = const Color(0xFFAEEFF4).withValues(alpha: 0.85 * a);
    for (final side in const [-1.0, 1.0]) {
      for (var i = 0; i < 7; i++) {
        final u = i / 6;
        final p0 = Offset(side * 8.5, -49);
        final p1 = Offset(side * 21, -45);
        final p2 = Offset(side * 17, -17);
        final q = Offset.lerp(
          Offset.lerp(p0, p1, u)!,
          Offset.lerp(p1, p2, u)!,
          u,
        )!;
        final r = 2.0 - u * 0.7;
        c.drawCircle(q, r, curl);
        c.drawArc(
          Rect.fromCircle(
            center: q + Offset(side * r * 0.25, 0),
            radius: r * 0.45,
          ),
          0,
          math.pi * 1.4,
          false,
          curl,
        );
      }
    }
    c.drawPath(_torso, skin);
    c.drawPath(_head, skin);
    c.drawPath(
      _dress,
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * a),
    );
    // Belde pullu kuşak.
    final belt = Paint()
      ..color = const Color(0xFF4FB0C0).withValues(alpha: 0.95 * a);
    for (var bx = -6.0; bx <= 6.01; bx += 2.4) {
      c.drawCircle(Offset(bx, -1.2), 1.3, belt);
    }
    // Boynuzlar: gök mavisi, içleri ak tüylü.
    c.drawPath(
      _wings,
      Paint()..color = const Color(0xFF7CCDEB).withValues(alpha: 0.97 * a),
    );
    final feather = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = const Color(0xFFF2FFFF).withValues(alpha: 0.8 * a);
    for (final side in const [-1.0, 1.0]) {
      for (final (double x0, double y0, double x1, double y1) in const [
        (9.6, -61.5, 14.6, -63.6),
        (9.4, -58, 13.6, -59.4),
        (8.4, -54.4, 12.0, -55.2),
        (6.0, -50.6, 8.6, -50.8),
      ]) {
        c.drawLine(Offset(side * x0, y0), Offset(side * x1, y1), feather);
      }
    }
    // Saç: başı saran, iki yanda omuza inen.
    c.drawPath(
      Path()
        ..moveTo(-4.9, -42)
        ..cubicTo(-6, -48, -3, -50, 0, -50)
        ..cubicTo(3, -50, 6, -48, 4.9, -42)
        ..cubicTo(5.6, -39, 6.6, -36, 6.2, -33.5)
        ..lineTo(4.2, -34.5)
        ..cubicTo(4.4, -38, 3.6, -44, 0, -46)
        ..cubicTo(-3.6, -44, -4.4, -38, -4.2, -34.5)
        ..lineTo(-6.2, -33.5)
        ..cubicTo(-6.6, -36, -5.6, -39, -4.9, -42)
        ..close(),
      Paint()..color = const Color(0xFF3E8C98).withValues(alpha: 0.95 * a),
    );
    // Yüz: kapalı, dingin gözler; alında küçük bir nişan.
    final eye = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.45
      ..color = const Color(0xFF4E8088).withValues(alpha: 0.8 * a);
    for (final side in const [-1.0, 1.0]) {
      c.drawArc(
        Rect.fromCenter(
          center: Offset(side * 2.1, -43.6),
          width: 2.4,
          height: 1.4,
        ),
        0,
        math.pi,
        false,
        eye,
      );
    }
    c.drawPath(
      Path()
        ..moveTo(0, -48.6)
        ..lineTo(0.8, -47.6)
        ..lineTo(0, -46.6)
        ..lineTo(-0.8, -47.6)
        ..close(),
      Paint()..color = const Color(0xFF3A9ED0).withValues(alpha: a),
    );
    // Kollar: açık avuçlu kol aynada, gösteren kol önde.
    c.drawPath(openM, skin);
    c.drawPath(arm, skin);
  }

  /// Işıldayan mavi balık; [ang] yüzdüğü yön.
  static void _fish(Canvas c, Offset p, double ang, double size, double a) {
    c.save();
    c.translate(p.dx, p.dy);
    c.rotate(ang);
    c.scale(size / 10);
    c.drawOval(
      Rect.fromCenter(center: const Offset(-1, 0), width: 18, height: 9),
      Paint()
        ..color = const Color(0xFF7FD8FF).withValues(alpha: 0.35 * a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    c.drawPath(
      Path()
        ..moveTo(6, 0)
        ..quadraticBezierTo(2, -3.4, -4, -1.2)
        ..lineTo(-8, -4)
        ..quadraticBezierTo(-6.5, 0, -8, 4)
        ..lineTo(-4, 1.2)
        ..quadraticBezierTo(2, 3.4, 6, 0)
        ..close(),
      Paint()..color = const Color(0xFFA8E8FF).withValues(alpha: 0.92 * a),
    );
    c.drawCircle(
      const Offset(3.4, -0.6),
      0.6,
      Paint()..color = const Color(0xFF1A3A4A).withValues(alpha: a),
    );
    c.restore();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > rise + stay + sink) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final up = _up;
    if (up <= 0) return;
    final s = basin.surface;
    final x = _at.dx;
    const sc = drawScale;
    // Bel su yüzünde; çıkarken aşağıdan yükselir.
    final originY = s + (1 - up) * 58 * sc;
    const water = Color(0xFF9EE8DC);
    // Çevresine saçtığı ışık.
    canvas.drawCircle(
      Offset(x, s - 14),
      80,
      Paint()
        ..shader = ui.Gradient.radial(Offset(x, s - 14), 80, [
          water.withValues(alpha: 0.4 * up),
          water.withValues(alpha: 0),
        ]),
    );
    final v = _valve;
    final flip = v != null && v.position.x < x ? -1.0 : 1.0;
    final theta = _lean * 0.08;
    // Kollar sudan çıkarken ağır ağır kalkar; sonra hafifçe salınır.
    final lift = ((_t - rise * 0.6) / 1.2).clamp(0.0, 1.0);
    var target = _sh + const Offset(30, -14);
    if (v != null) {
      var d = Offset(v.position.x, v.position.y - 8) - Offset(x, originY);
      d =
          Offset(
            d.dx * math.cos(-theta) - d.dy * math.sin(-theta),
            d.dx * math.sin(-theta) + d.dy * math.cos(-theta),
          ) /
          sc;
      target = Offset(d.dx * flip, d.dy);
    }
    final arm = _arm(target, lift, math.sin(_t * 1.4) * 0.05, point: true);
    final open = _arm(
      _sh + const Offset(28, 12),
      lift,
      math.sin(_t * 1.1 + 1) * 0.06,
      point: false,
    );
    void body(Rect clip, double a) {
      canvas.save();
      canvas.clipRect(clip);
      canvas.translate(x, originY);
      canvas.rotate(theta);
      canvas.scale(sc * flip, sc);
      _figure(canvas, a, arm, open);
      canvas.restore();
    }

    // Suyun içinde soluk (kuyruk), üstünde parlak.
    body(Rect.fromLTRB(x - 90, s + 0.5, x + 90, s + 70), 0.38 * up);
    body(Rect.fromLTRB(x - 90, s - 120, x + 90, s + 0.5), up);
    // Suyun altındaki yansıma.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, s + 8), width: 30, height: 10),
      Paint()..color = water.withValues(alpha: 0.2 * up),
    );
    // Halkalar.
    for (var i = 0; i < 3; i++) {
      final u = (_t * 0.35 + i / 3) % 1;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, s),
          width: 24 + u * 110,
          height: 3 + u * 6,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = const Color(0xFFCFF4F0)
              .withValues(alpha: 0.6 * up * (1 - u)),
      );
    }
    // Çevresinde yüzen ışıldayan balıklar; suyun içindekiler soluk.
    for (var i = 0; i < 6; i++) {
      final dirn = i.isEven ? 1.0 : -1.0;
      final a = _t * (0.55 + 0.08 * i) * dirn + i * 1.05;
      final rx = 34.0 + (i % 3) * 7;
      final ry = 9.0 + (i % 2) * 4;
      final p = Offset(
        x + math.cos(a) * rx,
        s - 6 - (i % 3) * 5 + math.sin(a) * ry,
      );
      final vel = Offset(-math.sin(a) * rx, math.cos(a) * ry) * dirn;
      final under = p.dy > s;
      _fish(
        canvas,
        p,
        math.atan2(vel.dy, vel.dx) + math.sin(_t * 9 + i) * 0.12,
        5.0 + (i % 3),
        up * (under ? 0.45 : 1),
      );
    }
    // Gösteren elin ucundan bir balık vanaya yüzer, çevresinde döner; vana
    // ışır.
    if (v == null) return;
    final go = ((_t - 2.2) / 2.6).clamp(0.0, 1.0);
    if (_t < 2.2) return;
    final tl = Offset(_tip.dx * sc * flip, _tip.dy * sc);
    final from = Offset(
      x + tl.dx * math.cos(theta) - tl.dy * math.sin(theta),
      originY + tl.dx * math.sin(theta) + tl.dy * math.cos(theta),
    );
    final to = Offset(v.position.x, v.position.y - 8);
    final mid = Offset((from.dx + to.dx) / 2, math.min(from.dy, to.dy) - 40);
    Offset at(double u) =>
        Offset.lerp(Offset.lerp(from, mid, u)!, Offset.lerp(mid, to, u)!, u)!;
    final e = go * go * (3 - 2 * go);
    final spark = Paint();
    for (var j = 1; j <= 8; j++) {
      final u = e - j * 0.025;
      if (u <= 0) break;
      spark.color = const Color(0xFFCFF4FF)
          .withValues(alpha: 0.6 * up * (1 - j / 9));
      canvas.drawCircle(at(u), 1.1, spark);
    }
    if (go < 1) {
      final d = at(math.min(1, e + 0.01)) - at(e);
      _fish(canvas, at(e), math.atan2(d.dy, d.dx), 7, up);
    } else {
      final k = _t * 3;
      final p = to + Offset(math.cos(k) * 12, math.sin(k) * 6);
      _fish(canvas, p, k + math.pi / 2, 7, up);
      final pulse = 0.6 + 0.4 * math.sin(_t * 4);
      canvas.drawCircle(
        to,
        18,
        Paint()
          ..shader = ui.Gradient.radial(to, 18, [
            const Color(0xFFCFF4FF).withValues(alpha: 0.5 * up * pulse),
            const Color(0x00CFF4FF),
          ]),
      );
    }
  }
}

/// Tulpar: fırtınalı göğün yüksek bir yerinden dörtnala, kanat çırparak
/// geçen kanatlı at (önsezi). Kameraya göre konumlanır.
class TulparFlight extends Component with HasGameReference<GolgeGame> {
  TulparFlight() : super(priority: 1);

  static const double duration = 5;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect;
    final u = _t / duration;
    final x = view.right + 70 - (view.width + 140) * u;
    final y = view.top + view.height * 0.24 + math.sin(u * math.pi * 3) * 10;
    final a = math.min(1.0, math.min(u * 4, (1 - u) * 4)) * 0.8;
    canvas.saveLayer(
      Rect.fromCenter(center: Offset(x, y), width: 200, height: 160),
      Paint()..color = Color.fromRGBO(0, 0, 0, a),
    );
    canvas.translate(x, y + 30);
    canvas.scale(-0.5, 0.5);
    MythFigures.tulpar(canvas, _t * 2.2);
    canvas.restore();
  }
}

/// Ak Ana: tufan suyu yükselirken suyun içinden yükselen ak ışık; yükselen
/// suyla birlikte çıkar, çevresini aydınlatır.
class AkAnaRise extends PositionComponent with HasGameReference<GolgeGame> {
  AkAnaRise(this.basin, double x)
    : super(position: Vector2(x, basin.surface), priority: 27);

  final WaterBasin basin;
  static const double drawScale = 0.5;
  double _t = 0;
  double alpha = 0;

  Offset get glowCenter => Offset(position.x, position.y - 40 * drawScale);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    alpha = _t < 2 ? _t / 2 : (_t < 10 ? 1 : math.max(0, 1 - (_t - 10) / 2));
    if (_t > 12) removeFromParent();
    // Su çizgisi Ak Ana'nın belinde (çizimde -30): yükselen suyla gelir;
    // ilk iki saniyede sudan çıkar.
    final rise = (1 - math.min(1, _t / 2)) * 40;
    position.y = basin.surface + 30 * drawScale + rise;
  }

  @override
  void render(Canvas canvas) {
    if (alpha <= 0) return;
    canvas.saveLayer(
      Rect.fromCenter(center: Offset.zero, width: 200, height: 200),
      Paint()..color = Color.fromRGBO(0, 0, 0, alpha),
    );
    canvas.scale(drawScale);
    MythFigures.akAna(canvas, _t);
    canvas.restore();
  }
}

/// Albastı: uzun süre kıpırdamayan Sâye'nin ardında beliren kızıl gölge;
/// kavanozun ışığını çeker. Sâye birkaç adım uzaklaşınca dağılır.
class AlbastiShade extends PositionComponent with HasGameReference<GolgeGame> {
  AlbastiShade() : super(anchor: Anchor.bottomCenter, priority: 19);

  static const double drawScale = 0.42;
  Vector2? _anchor;
  double _t = 0;
  double alpha = 0;
  bool _leaving = false;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (p == null) return;
    _anchor ??= p.center.clone();
    if (!_leaving) {
      position.setValues(p.center.x - p.facing * 24, p.position.y + p.size.y);
      if ((p.center - _anchor!).length > 2.5 * kTile || p.isDead || _t > 14) {
        _leaving = true;
        GameAudio.instance.play('fizzle', volume: 0.5);
      }
    }
    alpha = _leaving
        ? math.max(0, alpha - dt * 1.6)
        : math.min(0.8, alpha + dt * 0.45);
    // Işığı çeker.
    game.jarSteal = alpha / 0.8;
    if (_leaving && alpha <= 0) {
      game.jarSteal = 0;
      removeFromParent();
    }
  }

  @override
  void onRemove() {
    game.jarSteal = 0;
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    if (alpha <= 0) return;
    canvas.saveLayer(
      Rect.fromLTWH(-40, -60, 80 + size.x, 80),
      Paint()..color = Color.fromRGBO(0, 0, 0, alpha),
    );
    final f = (game.player?.facing ?? 1).toDouble();
    canvas.translate(0, math.sin(_t * 1.3) * 1.2);
    canvas.scale(f * drawScale, drawScale);
    MythFigures.albasti(canvas, _t);
    canvas.restore();
  }
}

/// Mağara girişinde duvara çakılmış demir nal: Albastı yanına yaklaşamaz.
class Horseshoe extends PositionComponent {
  Horseshoe(Vector2 at) : super(position: at, priority: 6);

  @override
  void render(Canvas canvas) {
    final iron = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF5A5A5E);
    canvas.drawArc(
      const Rect.fromLTRB(-7, -6, 7, 9),
      math.pi * 0.1,
      -math.pi * 1.2,
      false,
      iron,
    );
    canvas.drawArc(
      const Rect.fromLTRB(-7, -6, 7, 9),
      math.pi * 0.1,
      -math.pi * 1.2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0xFFB8B8C0).withValues(alpha: 0.6),
    );
    final nail = Paint()..color = const Color(0xFF2A2A2E);
    for (final a in [-0.6, -1.6, -2.6, -3.6]) {
      canvas.drawCircle(
        Offset(math.cos(a + 0.4) * 7, 1.5 + math.sin(a + 0.4) * 7.5),
        0.7,
        nail,
      );
    }
    // Asıldığı çivi.
    canvas.drawCircle(const Offset(0, -9), 1.1, nail);
  }
}
