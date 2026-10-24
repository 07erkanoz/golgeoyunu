import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'audio.dart';
import 'entities.dart';
import 'giant_puppet.dart';
import 'golge_game.dart';
import 'level.dart';
import 'mechanics.dart';
import 'myth_shapes.dart';
import 'nemrut_sprites.dart';
import 'palette.dart';
import 'persist.dart';
import 'player.dart';
import 'puzzles.dart';
import 'rig.dart';
import 'strings.dart';

part 'nemrut_art.dart';

// ======================================================== Aslan Horoskobu

/// Gökteki işaretler: Aslan Horoskobu'ndaki hilal, üç gezegen ve yıldız.
enum Sign { moon, jupiter, mercury, mars, star }

/// Horoskobun istediği sıra (soldan sağa yıldız taşları).
const horoscope = [Sign.moon, Sign.jupiter, Sign.mercury, Sign.mars];

void _drawSign(Canvas canvas, Sign s, Offset c, double r, Paint p) {
  switch (s) {
    case Sign.moon:
      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addOval(Rect.fromCircle(center: c, radius: r)),
          Path()..addOval(
            Rect.fromCircle(
              center: c.translate(r * 0.45, -r * 0.15),
              radius: r * 0.85,
            ),
          ),
        ),
        p,
      );
    case Sign.jupiter:
      canvas.drawCircle(c, r * 0.8, p);
      canvas.drawLine(
        c.translate(-r, 0),
        c.translate(r, 0),
        Paint()
          ..color = p.color
          ..strokeWidth = 1.4,
      );
    case Sign.mercury:
      canvas.drawCircle(c, r * 0.45, p);
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 2 + math.pi / 4;
        canvas.drawLine(
          c,
          c + Offset(math.cos(a), math.sin(a)) * r,
          Paint()
            ..color = p.color
            ..strokeWidth = 1.2,
        );
      }
    case Sign.mars:
      canvas.drawCircle(c.translate(-r * 0.2, r * 0.2), r * 0.55, p);
      canvas.drawLine(
        c.translate(r * 0.1, -r * 0.1),
        c.translate(r * 0.8, -r * 0.8),
        Paint()
          ..color = p.color
          ..strokeWidth = 1.6,
      );
    case Sign.star:
      final path = Path();
      for (var i = 0; i < 16; i++) {
        final a = i * math.pi / 8 - math.pi / 2;
        final rr = i.isEven ? r : r * 0.4;
        final pt = c + Offset(math.cos(a), math.sin(a)) * rr;
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path..close(), p);
  }
}

/// Döndürülebilen yıldız taşı: ↑ ile bir sonraki işarete döner. Bütün
/// taşlar Aslan Horoskobu'ndaki sırayı gösterince en yakın kapı açılır.
class StarStone extends PositionComponent
    with HasGameReference<GolgeGame>, Usable, Persistent {
  StarStone(Vector2 cell, this.index, {Sign start = Sign.star})
    : sign = start,
      super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile),
        priority: 18,
      );

  final int index;
  Sign sign;
  double _turn = 0;

  @override
  String get persistKind => 'star';

  @override
  Object? captureState() => sign.index;

  @override
  Iterable<Component> restoreState(Object? state, {required bool present}) {
    if (state is int && state >= 0 && state < Sign.values.length) {
      sign = Sign.values[state];
    }
    return [this];
  }

  bool get correct => index < horoscope.length && sign == horoscope[index];

  /// Taş tanrının omuzlarında durulan her yerden çevrilir (eskiden taşın
  /// tam dibinde durmak gerekiyordu; nereden tutulacağı anlaşılmıyordu).
  /// Aşağıdaki oturaktan çevrilmez.
  @override
  bool canUse(Vector2 p) =>
      (p.x - position.x).abs() < 2.2 * kTile &&
      (p.y - (position.y - Player.h / 2)).abs() < 20;

  /// Oyuncu omuzlardayken taş belli olsun: ılık halka ve tutamak.
  bool _near = false;

  @override
  void use() {
    sign = Sign.values[(sign.index + 1) % Sign.values.length];
    _turn = 1;
    GameAudio.instance.play('grind', volume: 0.5);
    _check();
  }

  void _check() {
    final stones = game.world.children.whereType<StarStone>().toList();
    if (stones.every((s) => s.correct)) {
      GameAudio.instance.play('memory', volume: 0.7);
      game.once('horoscope', S.of('horoscope'), story: false);
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
  }

  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _turn = math.max(0, _turn - dt * 3);
    final p = game.player;
    _near =
        p != null &&
        !p.isDead &&
        (p.center.x - position.x).abs() < 4 * kTile &&
        (p.center.y - position.y).abs() < 3 * kTile;
    _show = math.max(0, _show - dt);
    if (p != null && index == 0) _showRoute(p);
  }

  /// Taşlar gösterilirken hepsi nabız atar (kamera onlara bakarken).
  double _show = 0;

  /// Batı Terası'na ilk gelişte kamera omuzlardaki yıldız taşlarını gösterip
  /// geri döner: nereye tırmanılacağı görünsün. Bir kez (tehlike varsa
  /// sonraya kalır).
  void _showRoute(Player p) {
    final key = 'yildizYolu:${game.levelIndex}';
    if (game.eventSeen(key) || !p.onGround) return;
    final dx = position.x - p.center.x;
    if (dx < 2 * kTile || dx > 9 * kTile) return;
    if (p.center.y < position.y + 2 * kTile) return; // zaten yukarıda
    final stones = game.world.children.whereType<StarStone>().toList();
    if (stones.isEmpty) return;
    var x = 0.0;
    for (final s in stones) {
      x += s.position.x;
    }
    x /= stones.length;
    final at = Vector2(math.min(x, position.x + 6 * kTile), position.y - kTile);
    if (!game.focus(at, hold: 2.4)) return;
    game.markEvent(key);
    for (final s in stones) {
      s._show = 3.6;
    }
  }

  @override
  void render(Canvas canvas) {
    final stone = Paint()..color = const Color(0xFF2A2430);
    canvas.drawRect(const Rect.fromLTWH(-12, -10, 24, 10), stone);
    // Yaklaşınca taş çağırır: kenarında ılık, yavaş nabız atan bir halka.
    if ((_near || _show > 0) && !correct) {
      final pulse = 0.5 + 0.5 * math.sin(_t * 3);
      canvas.drawCircle(
        const Offset(0, -24),
        17 + 2 * pulse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = kWarmLight.withValues(alpha: 0.35 + 0.35 * pulse),
      );
    }
    canvas.save();
    canvas.translate(0, -24);
    canvas.rotate(_turn * math.pi);
    canvas.drawCircle(Offset.zero, 13, stone);
    // Tutamaklar: çarkın kenarında iki çıkıntı, çevrilen bir taş olduğu
    // görünsün.
    final knob = Paint()..color = const Color(0xFF4A4256);
    for (final a in [0.0, math.pi]) {
      canvas.drawCircle(Offset(math.cos(a) * 14, math.sin(a) * 14), 3.2, knob);
    }
    final ok = correct;
    final lit = Paint()
      ..color = ok ? const Color(0xFFFFE0A0) : const Color(0xFFC8C0D8);
    _drawSign(canvas, sign, Offset.zero, 8, lit);
    canvas.restore();
    if (ok) glowDot(canvas, const Offset(0, -24), 30, kWarmLight, 0.35);
  }
}

/// Aslan Horoskobu kabartması: gökteki doğru sırayı gösterir (süs ve ipucu).
class HoroscopeRelief extends PositionComponent
    with HasGameReference<GolgeGame> {
  HoroscopeRelief(Vector2 cell)
    : super(position: Vector2(cell.x, cell.y + kTile), priority: 2);

  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  /// Aslanın kabartmadaki yeri: ayakların ortası ve ölçeği (siluet
  /// MythShapes.lion, boyu 100 birim).
  static const Offset _lionAt = Offset(98, -9);
  static const double _lionK = 0.86;

  /// Aslan: PhyloPic'teki kamu malı yürüyen aslan silueti (Margot Michaud);
  /// sağa yürür, Antiochos'un Aslan Horoskobu'ndaki gibi (Nemrut, Batı
  /// Terası). Kabartmanın yerel biriminde.
  static final Path _lion = MythShapes.lion.transform(
    Float64List.fromList([
      _lionK, 0, 0, 0, //
      0, _lionK, 0, 0, //
      0, 0, 1, 0, //
      _lionAt.dx, _lionAt.dy, 0, 1,
    ]),
  );

  /// Gövdeye serpilmiş 19 yıldız: siluetin içinde, kenardan uzak noktalar
  /// (kabartmadaki gibi gövde, yele ve bacaklarda).
  static final List<Offset> _stars = () {
    final b = _lion.getBounds();
    bool deep(Offset p) => [
      Offset.zero,
      const Offset(4, 0),
      const Offset(-4, 0),
      const Offset(0, 4),
      const Offset(0, -4),
    ].every((d) => _lion.contains(p + d));
    final out = <Offset>[];
    // Seyrek, düzenli olmayan bir ızgara (her sırada yarım adım kayar).
    for (var row = 0; row < 9; row++) {
      for (var col = 0; col < 14; col++) {
        final p = Offset(
          b.left + (col + (row.isOdd ? 0.5 : 0) + 0.5) * b.width / 14,
          b.top + (row + 0.5) * b.height / 9,
        );
        if (deep(p) && (col * 7 + row * 3) % 4 != 0) out.add(p);
      }
    }
    // 19 tane: eşit aralıkla seçilir.
    if (out.length <= 19) return out;
    return [for (var k = 0; k < 19; k++) out[k * out.length ~/ 19]];
  }();

  /// Hilal: boynun altında, göğüste (siluetin içinde en sağdaki derin nokta
  /// göğüs hizasında).
  static final Offset _moon = () {
    final b = _lion.getBounds();
    final y = b.top + b.height * 0.55;
    for (var x = b.right - 6; x > b.left; x -= 1) {
      final p = Offset(x - 14, y);
      if (_lion.contains(p) &&
          _lion.contains(p + const Offset(8, 0)) &&
          _lion.contains(p + const Offset(-8, 0))) {
        return p;
      }
    }
    return b.center;
  }();

  @override
  void render(Canvas canvas) {
    const w = 6 * kTile;
    const h = 4 * kTile;
    // Kum taşı levha (Nemrut'un aslan başı çizimiyle aynı taş): kalın
    // çerçeve, içi oyulmuş; aslan ondan kabarık ve açık.
    canvas.drawRect(
      const Rect.fromLTWH(0, -h, w, h),
      Paint()..color = const Color(0xFF6E5A46),
    );
    canvas.drawRect(
      const Rect.fromLTWH(5, -h + 5, w - 10, h - 10),
      Paint()
        ..shader = Gradient.linear(const Offset(0, -h), const Offset(0, 0), [
          const Color(0xFF8C7458),
          const Color(0xFF6A5642),
        ]),
    );
    canvas.drawRect(
      const Rect.fromLTWH(5, -h + 5, w - 10, h - 10),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF3E3024),
    );
    // Kabartma: alt-sağa düşen gölge, gövde, üst-sola vuran ışık.
    canvas.save();
    canvas.translate(2.4, 2.4);
    canvas.drawPath(_lion, Paint()..color = const Color(0xFF3A2C20));
    canvas.restore();
    canvas.drawPath(
      _lion,
      Paint()
        ..shader = Gradient.linear(const Offset(0, -98), const Offset(0, -8), [
          const Color(0xFFE2C79C),
          const Color(0xFFAE906A),
        ]),
    );
    canvas.save();
    canvas.clipPath(_lion);
    canvas.translate(1.4, 1.4);
    canvas.drawPath(
      _lion,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..color = const Color(0xFFFFF2D8).withValues(alpha: 0.45),
    );
    canvas.restore();
    final glow = 0.55 + 0.25 * math.sin(_t * 1.3);
    // Gezegenler sırtın üstünde, levhada: ılık parlar (bulmacanın sırası).
    final mark = Paint()
      ..color = const Color(0xFFFFEFC8).withValues(alpha: 0.6 + 0.3 * glow);
    for (var i = 1; i < horoscope.length; i++) {
      final at = Offset(46.0 + i * 30, -110);
      glowDot(canvas, at, 12, kWarmLight, 0.25 * glow);
      _drawSign(canvas, horoscope[i], at, 8, mark);
    }
    // Hilal boynun altında, yıldızlar gövdede: taşa oyulmuş, koyu; hilal
    // bulmacanın ilk işareti olduğu için hafifçe ışır.
    final carved = Paint()..color = const Color(0xFF5A4030);
    glowDot(canvas, _moon, 11, kWarmLight, 0.22 * glow);
    _drawSign(canvas, Sign.moon, _moon, 7, carved);
    for (final p in _stars) {
      if ((p - _moon).distance < 11) continue;
      _drawSign(canvas, Sign.star, p, 2.4, carved);
    }
    // Kenar ve kar.
    canvas.drawRect(
      const Rect.fromLTWH(0, -h - 3, w, 4),
      Paint()..color = const Color(0xFFC8D2E2),
    );
  }
}

// ================================================================ Deprem

/// Gevşek kaya: depremde ya da altından geçilince düşer.
class LooseBoulder extends PositionComponent with HasGameReference<GolgeGame> {
  LooseBoulder(Vector2 cell)
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile / 2),
        priority: 21,
      );

  double _shake = -1;
  double _vy = 0;
  bool _landed = false;
  double _gone = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (_landed) {
      _gone += dt;
      if (_gone > 1.2) removeFromParent();
      return;
    }
    if (_shake < 0) {
      final p = game.player;
      final under =
          p != null &&
          !p.isDead &&
          (p.center.x - position.x).abs() < 30 &&
          p.center.y > position.y;
      // Deprem yalnızca oyuncunun yakınındaki kayaları düşürür: yoksa
      // bölümün ilk depreminde haritanın bütün kayaları birden düşüyor,
      // oyuncu oraya vardığında tepede taş kalmıyordu.
      final near =
          p != null &&
          (p.center.x - position.x).abs() < 12 * kTile &&
          (p.center.y - position.y).abs() < 10 * kTile;
      if ((game.quake > 0.5 && near) || under) _shake = 0;
      return;
    }
    _shake += dt;
    if (_shake < 0.35) return;
    _vy = math.min(_vy + 1900 * dt, 900);
    position.y += _vy * dt;
    final p = game.player;
    if (p != null &&
        !p.isDead &&
        p.toRect().inflate(4).contains(position.toOffset())) {
      p.die();
    }
    if (game.level.cellAt(position.x, position.y + 14) == '#' ||
        position.y > game.level.pixelHeight) {
      _landed = true;
      GameAudio.instance.play('crumble', volume: 0.6);
      game.shake(2);
    }
  }

  @override
  void render(Canvas canvas) {
    final j = _shake >= 0 && _shake < 0.35 ? math.sin(_shake * 70) * 2 : 0.0;
    final a = _landed ? (1 - _gone / 1.2).clamp(0.0, 1.0) : 1.0;
    final rock = Paint()..color = const Color(0xFF2A2430).withValues(alpha: a);
    canvas.drawPath(
      Path()
        ..moveTo(-13 + j, -6)
        ..lineTo(-4 + j, -14)
        ..lineTo(10 + j, -10)
        ..lineTo(14 + j, 4)
        ..lineTo(4 + j, 14)
        ..lineTo(-12 + j, 10)
        ..close(),
      rock,
    );
    canvas.drawLine(
      Offset(-8 + j, -10),
      Offset(8 + j, -12),
      Paint()
        ..color = const Color(0xFFC8D2E2).withValues(alpha: 0.7 * a)
        ..strokeWidth = 2,
    );
  }
}

// ============================================================== Heykeller

/// Arazinin arkasında duran dev taş tanrı (oturan) ya da yere düşmüş başı.
/// Tırmanılacak dizler, kucak ve omuzlar haritada ayrıca `#` ile verilir.
class Colossus extends PositionComponent with HasGameReference<GolgeGame> {
  Colossus(Vector2 cell, {required this.kind})
    : super(
        // Oturan tanrının işareti omuzlarının üstündedir; çizim 9 kare
        // aşağıdaki zemine oturur.
        position: Vector2(cell.x, cell.y + kTile + (kind <= 1 ? 9 * kTile : 0)),
        // Oturan tanrının tırmanılan kareleri arazidir: heykel arazinin
        // önünde çizilir (yoksa kaya onu örter).
        priority: kind <= 1 ? 1 : -1,
      );

  /// 0: oturan tanrı (başı yok), 1: oturan tanrı (başı yerinde),
  /// 2: düşmüş baş, 3: kartal, 4: aslan.
  final int kind;

  /// Düşmüş başın kimliği: sütuna göre değişir (terasta her baş başka bir
  /// tanrı).
  /// Görseli tabanı zeminde, [cx]te ortalanmış ve [height] boyunda çizer.
  void _sprite(
    Canvas canvas,
    String key,
    double height,
    double cx, {
    bool flip = false,
  }) {
    final r = nemrutSprites[key]!;
    final sc = height / r.height;
    canvas.save();
    canvas.translate(cx, 0);
    canvas.scale(flip ? -sc : sc, sc);
    canvas.translate(-r.center.dx, -r.bottom);
    NemrutImages.draw(canvas, key, game);
    canvas.restore();
  }

  NemrutHead get _headKind {
    // Çoğu uzun tiaralı (Nemrut'un tanınan başları), arada Apollon ve
    // Herakles.
    const order = [
      NemrutHead.zeus,
      NemrutHead.antiochos,
      NemrutHead.apollo,
      NemrutHead.antiochos,
      NemrutHead.herakles,
    ];
    return order[((position.x / kTile).round() ~/ 8) % order.length];
  }

  @override
  void render(Canvas canvas) {
    const t = kTile;
    switch (kind) {
      case 0:
        NemrutArt.seated(canvas);
      case 1:
        NemrutArt.seated(canvas, head: NemrutHead.antiochos);
      case 2 when NemrutImages.ready:
        // Yere dikilmiş duran dev baş: terasta her biri başka bir tanrı.
        const heads = [
          'zeus_head',
          'antiochos_head',
          'apollon_head',
          'herakles_head',
          'kommagene_head',
        ];
        final i = (position.x / kTile).round() ~/ 8;
        _sprite(
          canvas,
          heads[i % heads.length],
          5 * t,
          -0.7 * t,
          flip: i ~/ heads.length % 2 == 1,
        );
      case 3 when NemrutImages.ready:
        _sprite(canvas, 'eagle_head', 4.2 * t, 1.25 * t);
      case 4 when NemrutImages.ready:
        _sprite(canvas, 'lion_head', 3.6 * t, 1.5 * t);
      case 2:
        // Yere dikilmiş duran dev baş (gövdesinden kopup düşmüş); dibinde
        // moloz.
        canvas.save();
        // Dikili taşın (sağdaki saklanma yeri) yanında durur.
        canvas.translate(-0.7 * t, 0);
        canvas.rotate(-0.04);
        NemrutArt.head(canvas, _headKind, 5 * t);
        canvas.restore();
        final rubble = Paint()..color = const Color(0xFF2A2432);
        for (final (x, w) in const [(0.2, 0.7), (1.0, 0.5), (2.2, 0.8)]) {
          canvas.drawOval(
            Rect.fromLTWH(x * t, -0.3 * t, w * t, 0.4 * t),
            rubble,
          );
        }
      case 3:
        canvas.save();
        canvas.translate(1.25 * t, 0);
        NemrutArt.eagle(canvas, 4.6 * t);
        canvas.restore();
      default:
        // Aslan: alçak bir kaidenin üstünde, horoskobun aslanı gibi.
        NemrutArt._masonry(canvas, const Rect.fromLTRB(0, -0.8 * t, 3 * t, 0));
        canvas.save();
        canvas.translate(-0.15 * t, -0.8 * t);
        canvas.scale(0.6);
        final lion = HoroscopeRelief._lion;
        canvas.drawPath(
          lion.shift(const Offset(3, 2)),
          Paint()..color = const Color(0xFF07050A).withValues(alpha: 0.55),
        );
        canvas.drawPath(
          lion,
          Paint()
            ..shader = Gradient.linear(
              const Offset(0, -90),
              const Offset(0, 0),
              [_nStoneLit, _nStoneDark],
            ),
        );
        canvas.restore();
    }
  }
}

// ======================================================== Taş dev Nemrud

/// Nemrud'un taş devi: terasta ağır ağır yürür, adımları yeri sarsar,
/// ayaklarının dibinde kalanı ezer. Kulağına bir ateşböceği (sivrisinek
/// gibi) girerse sendeler; üçüncüsünde yıkılır ve gövdesi köprü olur.
class StoneGiant extends PositionComponent
    with HasGameReference<GolgeGame>, Persistent {
  StoneGiant(Vector2 cell)
    : _home = cell.x,
      super(
        position: Vector2(cell.x, cell.y + kTile),
        size: Vector2(5 * kTile, 9 * kTile),
        // Konum ayakların yeridir (kulak, ezme alanı ve köprü buna göre):
        // çizim de oradan yukarı uzanır. Önceden sol üst köşe sayıldığı için
        // dev toprağın içine çiziliyordu.
        anchor: Anchor.bottomLeft,
        priority: 16,
      );

  static const double span = 11 * kTile;
  static const int hitsToFall = 3;

  final double _home;
  double _t = 0;
  double _stagger = 0;
  int hits = 0;
  bool fallen = false;
  double _fallT = 0;
  int _dir = 1;

  /// Yürüyüş evresi: yalnızca yürürken ilerler. Bacaklar ve adım sesi aynı
  /// evreden çıkar; ayak yere bastığı anda gümbürtü duyulur.
  double _walk = 0;
  int _stepN = 0;
  static const double _stepRate = 2.9;

  /// Basan ayağın tozu (yerel x, yaş) ve yıkılışın yere çarpışı.
  final _dust = <(double, double)>[];
  bool _impact = false;

  /// Temasta başın kulaktan kaçışı (yay: çeker, geri gelir).
  final _flinch = Spring(stiffness: 55, damping: 5);

  /// Taş atma döngüsü: oyuncuyu görünce durur, taşı başının yanına kaldırır
  /// (kulağını korur), düşeceği yeri işaretler, atar, sonra toparlanır. Hedef
  /// atıştan önce sabitlenir: taş oyuncunun sonraki yerini izlemez.
  bool throws = true;
  _Throw _throw = _Throw.none;
  double _throwT = 0;
  double _cool = 1.5;
  int thrown = 0;
  static const double recoverTime = 2.2;

  /// Yolun sonunda soluklanma: döner, bir an durur; kulağı açıktır.
  static const double restTime = 1.8;
  double _rest = 0;

  /// Yürürken kulağına yaklaşan ışığı eliyle savurur (kalan sn).
  double _swat = 0;
  static const double swatTime = 0.45;
  static const double cooldown = 2.2;
  static const double flightTime = 0.9;
  double get windupTime => thrown == 0 ? 1.4 : 1.05;

  /// Kulak açık mı: yalnız taşı attıktan sonra toparlanırken ve yolun
  /// sonunda soluklanırken. Yürürken kulağını korur, taşı kaldırıp atarken
  /// kolu kulağını örter (ateşböceği her fırsatta değil, zamanında girer).
  bool get earOpen =>
      _throw == _Throw.recover || (_throw == _Throw.none && _rest > 0);

  @override
  String get persistKind => 'giant';

  @override
  Object? captureState() => hits == 0 ? null : [hits, fallen ? 1 : 0];

  @override
  Iterable<Component> restoreState(Object? state, {required bool present}) {
    final s = numbers(state, 2);
    if (s == null) return [this];
    hits = s[0].round().clamp(0, hitsToFall);
    if (s[1] != 1) return [this];
    // Yıkılmış dev yatar; gövdesi köprüdür.
    fallen = true;
    hits = hitsToFall;
    _fallT = 1;
    _impact = true;
    _afterImpact = 5;
    return [this, GiantBridge(_bridgeAt)];
  }

  /// Köprü: yatan gövdenin üstü (gövde sağdaki ayak ucundan uzanır).
  Vector2 get _bridgeAt =>
      Vector2(position.x + size.x / 2 + 40, position.y - kTile * 1.2);

  /// Kulağın dünyadaki yeri (kuklanın başıyla birlikte oynar).
  Vector2 get ear {
    final pp = _puppet;
    final p = _pose;
    if (pp == null || p == null) {
      return Vector2(position.x + size.x * 0.5, position.y - size.y * 0.78);
    }
    return _toWorld(pp.earOf(p));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _flinch.update(0, dt);
    _tick(dt);
    _refreshPose();
  }

  void _tick(double dt) {
    for (var i = _dust.length - 1; i >= 0; i--) {
      final (x, age) = _dust[i];
      if (age + dt > 1.4) {
        _dust.removeAt(i);
      } else {
        _dust[i] = (x, age + dt);
      }
    }
    if (fallen) {
      if (_impact) _afterImpact += dt;
      _fallT = math.min(1, _fallT + dt * 0.7);
      if (_fallT >= 1 && !_impact) {
        // Gövde yere çarpar: toz, sarsıntı, gümbürtü.
        _impact = true;
        game.shake(12);
        GameAudio.instance.play('land');
        // Yatan gövde boyunca toz kalkar.
        for (var k = 0; k < 8; k++) {
          _dust.add((size.x * 0.5 + 40 + k * 40.0, 0));
        }
      }
      return;
    }
    if (_stagger > 0) {
      _stagger -= dt;
      // Sendelerken kulağını korur: yanına gelen ışıkları savurur. Yoksa
      // bekleyen ışıklar sendeleme biter bitmez hep birden giriyordu.
      for (final l in game.world.children.whereType<FireflyLure>().toList()) {
        if (l.glowing && (l.position - ear).length < 46) l.absorb();
      }
      return;
    }
    final pl = game.player;
    if (_throw != _Throw.none) {
      _throwT += dt;
      switch (_throw) {
        case _Throw.windup:
          _shieldEar();
          if (_throwT >= windupTime) _launch();
        case _Throw.release:
          _shieldEar();
          if (_throwT >= 0.35) {
            _throw = _Throw.recover;
            _throwT = 0;
            // Ağır kolun ardından öne sendeler: kulak açıktır.
            _flinch.kick(_dir * 6);
            GameAudio.instance.play('grind', volume: 0.5);
          }
        case _Throw.recover:
          if (_throwT >= recoverTime) {
            _throw = _Throw.none;
            _cool = cooldown;
          }
        case _Throw.none:
          break;
      }
      _crush(pl);
      if (earOpen) _checkLures();
      return;
    }
    _swat = math.max(0, _swat - dt);
    if (_rest > 0) {
      // Soluklanırken kulak açıktır.
      _rest -= dt;
      _crush(pl);
      _checkLures();
      return;
    }
    _cool -= dt;
    if (throws && _cool <= 0 && pl != null && _canTarget(pl)) {
      _startThrow(pl);
      return;
    }
    // Ağır adımlar: iki nokta arasında gidip gelir; uçta döner, soluklanır.
    position.x += _dir * 26 * dt;
    _walk += dt;
    _puppet?.walk(26 * dt / GiantPuppet.scale);
    if (position.x > _home + span && _dir > 0) {
      _dir = -1;
      _rest = restTime;
    }
    if (position.x < _home && _dir < 0) {
      _dir = 1;
      _rest = restTime;
    }
    final p = game.player;
    // Bacak sin(evre) ile gidip gelir: uçlarda (her yarım dönüşte) ayak
    // yere oturur.
    final n = ((_walk * _stepRate + math.pi / 2) / math.pi).floor();
    if (n != _stepN) {
      _stepN = n;
      // Basan ayağın altında toz kalkar.
      _dust.add((size.x * (n.isOdd ? 0.36 : 0.64) + _dir * 14, 0));
      // Adımlar yakında duyulur ve sarsar; uzaktan yalnızca hafif bir gümbürtü.
      final near = p == null || p.isDead
          ? 0.0
          : (1 - (p.center - position).length / (24 * kTile)).clamp(0.0, 1.0);
      if (near > 0) {
        GameAudio.instance.play('land', volume: 0.9 * near);
        game.shake(4 * near);
        game.quake = math.max(game.quake, 0.6 * near);
      }
    }
    _crush(p);
    _guardEar();
  }

  /// Yürürken kulağına yaklaşan ışığı eliyle savurup söndürür.
  void _guardEar() {
    for (final l in game.world.children.whereType<FireflyLure>().toList()) {
      if (l.glowing && (l.position - ear).length < 62) {
        l.absorb();
        _swat = swatTime;
        GameAudio.instance.play('fizzle', volume: 0.7);
        game.once('giantGuard', S.of('giantGuard'), hint: true);
      }
    }
  }

  /// Ayakların dibi ezer.
  void _crush(Player? p) {
    if (p == null || p.isDead) return;
    final feet = Rect.fromLTWH(position.x, position.y - 28, size.x, 28);
    if (p.toRect().overlaps(feet)) p.die();
  }

  /// Taşı kaldırırken kolu kulağını örter: gelen ışık kola çarpıp söner.
  void _shieldEar() {
    for (final l in game.world.children.whereType<FireflyLure>().toList()) {
      if (l.glowing && (l.position - ear).length < 54) {
        l.absorb();
        GameAudio.instance.play('fizzle', volume: 0.6);
      }
    }
  }

  /// Oyuncuyu görüyor ve taş ona yetişir mi?
  bool _canTarget(Player p) {
    if (p.isDead || p.hidden || game.cinematic) return false;
    final cx = position.x + size.x / 2;
    final dx = (p.center.x - cx).abs();
    return dx > 2.5 * kTile &&
        dx < 20 * kTile &&
        (p.center.y - position.y).abs() < 9 * kTile;
  }

  /// Taşı kaldırır; hedef şimdi sabitlenir ve yere işaretlenir. İlk taş
  /// bilerek kısa düşer (oyuncu işareti öğrenir).
  void _startThrow(Player p) {
    final cx = position.x + size.x / 2;
    var tx = p.center.x;
    if (thrown == 0) tx += (tx > cx ? -1 : 1) * 3 * kTile;
    final ty = _groundBelow(tx, p.position.y + Player.h - 4);
    _target = Vector2(tx, ty);
    _dir = tx > cx ? 1 : -1;
    _throw = _Throw.windup;
    _throwT = 0;
    game.world.add(ThrowMark(_target!, windupTime + flightTime));
    GameAudio.instance.play('grind', volume: 0.8);
    game.once('giantThrow', S.of('giantThrow'), hint: true);
  }

  Vector2? _target;

  /// Taşın düşeceği zemin: [x] sütununda [y]'den aşağı ilk dolu kare.
  double _groundBelow(double x, double y) {
    final lv = game.level;
    final c = (x / kTile).floor();
    for (var r = (y / kTile).floor(); r < lv.height; r++) {
      if (lv.solid(c, r)) return r * kTile.toDouble();
    }
    return lv.pixelHeight.toDouble();
  }

  /// Elin yeri (taş buradan kalkar): başının üstünde tuttuğu kaya.
  Vector2 get hand {
    final pp = _puppet;
    if (pp == null) {
      return Vector2(position.x + size.x / 2, position.y - size.y - 26);
    }
    final p = pp.pose(throwStage: 1, throwK: 1);
    final b = pp.boulder(p, 1, 1);
    return b == null ? _toWorld(pp.earOf(p)) : _toWorld(b);
  }

  void _launch() {
    final t = _target;
    _throw = _Throw.release;
    _throwT = 0;
    thrown++;
    if (t == null) return;
    game.world.add(ThrownStone(hand, t, flightTime));
    GameAudio.instance.play('throw');
  }

  void _checkLures() {
    for (final l in game.world.children.whereType<FireflyLure>().toList()) {
      if (l.glowing && (l.position - ear).length < 46) {
        l.absorb();
        hits++;
        _stagger = 2.4;
        _flinch.kick(-_dir * 9);
        GameAudio.instance.play('grind');
        GameAudio.instance.play('growl', volume: 0.7);
        game.shake(6 + hits * 2.0);
        if (hits < hitsToFall) {
          // Kaç ışık kaldığını söyler (sol üstte kısa bir not).
          game.narration.hint(
            S.of(hits == 1 ? 'giantHit1' : 'giantHit2'),
            queue: true,
          );
        }
        if (hits >= hitsToFall) {
          final pose = _pose;
          if (pose != null) _puppet?.freezeForFall(pose);
          fallen = true;
          GameAudio.instance.play('crumble');
          game.once('giantFell', S.of('giantFell'));
          // Yatan gövdenin üstü köprü olur (gövde sağa, ayaklarından uzanır).
          game.world.add(GiantBridge(_bridgeAt));
          // Devin düşüşü ilerideki (çıkışa doğru) kapıyı kırar.
          Gate? best;
          var bestD = double.infinity;
          for (final g in game.world.children.whereType<Gate>()) {
            final dd = (g.position - position).length;
            if (g.position.x > position.x && dd < bestD && !g.opening) {
              bestD = dd;
              best = g;
            }
          }
          best?.opening = true;
        }
        // Bir karede tek vuruş: aynı anda gelen ikinci ışık sayılmaz (çift
        // köprü kurulmaz).
        _throw = _Throw.none;
        _cool = cooldown;
        break;
      }
    }
  }

  // ------------------------------------------------------------ görünüş

  /// Yeni taş dev kuklası (yürüyüş, kaya kaldırma, sendeleme, devrilme).
  GiantPuppet? _puppet;
  GiantPose? _pose;

  /// Çarpmadan sonra geçen süre (devrilmenin sekmesi için).
  double _afterImpact = 0;

  @override
  FutureOr<void> onLoad() {
    // Veri yüklüyse bekletmeden: ölünce bölüm yeniden kurulurken dev aynı
    // karede yerini alır (düzen kaydı onu kaçırmaz).
    final ready = GiantPuppet.cached();
    if (ready != null) {
      _puppet = ready;
      _refreshPose();
      return null;
    }
    return GiantPuppet.load().then((p) {
      _puppet = p;
      _refreshPose();
    });
  }

  @override
  void onMount() {
    super.onMount();
    // Devin alanında ateşböceği bitmez: alınanın yerine başka yerde yenisi.
    if (!fallen &&
        !game.world.children.whereType<GiantFireflies>().any(
          (f) => f.giant == this,
        )) {
      game.world.add(GiantFireflies(this));
    }
  }

  int get _throwStage => switch (_throw) {
    _Throw.none => 0,
    _Throw.windup => 1,
    _Throw.release => 2,
    _Throw.recover => 3,
  };

  double get _throwK => switch (_throw) {
    _Throw.windup => _throwT / windupTime,
    _Throw.release => _throwT / 0.35,
    _Throw.recover => _throwT / recoverTime,
    _Throw.none => 0,
  };

  /// O anki duruşu kurar (kulak ve elin yeri de buradan okunur).
  void _refreshPose() {
    final pp = _puppet;
    if (pp == null || fallen) return;
    _pose = pp.pose(
      stagger: math.max(0, _stagger),
      throwStage: _throwStage,
      throwK: _throwK,
      flinch: -_flinch.value.abs() * 0.02,
      swat: _swat / swatTime,
      rest: _rest > 0
          ? math.min(1, math.min(_rest, restTime - _rest) / 0.4)
          : 0,
      time: _t,
    );
  }

  /// Kuklanın yerel noktasının dünyadaki yeri.
  Vector2 _toWorld(Offset q) => Vector2(
    position.x + size.x / 2 + _dir * q.dx * GiantPuppet.scale,
    position.y + q.dy * GiantPuppet.scale,
  );

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    // Ayak dibindeki toz (devrilse de yerinde kalır).
    final dust = Paint();
    for (final (x, age) in _dust) {
      final k = age / 1.4;
      dust.color = const Color(0xFFB8A890).withValues(alpha: 0.35 * (1 - k));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, h - 4 - k * 10),
          width: 30 + k * 60,
          height: 8 + k * 14,
        ),
        dust,
      );
    }
    final pp = _puppet;
    if (pp == null) return;
    const s = GiantPuppet.scale;
    canvas.save();
    if (fallen) {
      // Devrilme: tek parça taş olarak sağdaki ayak ucundan döner, yere
      // çarpıp seker; yatan gövde biraz gömülür (üstü köprüyle aynı hizada).
      final a = GiantPuppet.fallAngle(_fallT, _impact ? _afterImpact : 0);
      final sink = _sink * (a / (math.pi / 2)).clamp(0.0, 1.0);
      const px = GiantPuppet.pivotX * s;
      canvas.translate(w / 2 + px, h + sink);
      canvas.rotate(a);
      canvas.translate(-px, 0);
      canvas.scale(_dir * s, s);
      pp.drawPose(canvas, pp.fallPose);
    } else {
      final p = _pose ?? pp.pose();
      canvas.translate(w / 2, h);
      canvas.scale(_dir * s, s);
      pp.drawPose(canvas, p, boulderAt: pp.boulder(p, _throwStage, _throwK));
    }
    canvas.restore();
    if (!fallen && _stagger <= 0) {
      // Kulak: açıkken (atıştan sonra, soluklanırken) belirgin parlar;
      // kapalıyken yalnız sönük bir iz.
      final e = ear - (position - Vector2(0, h));
      final open = earOpen;
      glowDot(
        canvas,
        e.toOffset(),
        open ? 24 : 12,
        kWarmLight,
        open ? 0.6 + 0.25 * math.sin(_t * 8) : 0.12,
      );
    }
  }

  /// Yatan gövdenin gömülmesi: üstü köprünün üstüyle aynı hizaya iner.
  static const double _sink = 32;
}

enum _Throw { none, windup, release, recover }

/// Taşın düşeceği yer: zeminde nabız gibi atan halka ve üstüne dökülen
/// çakıl. Dev taşı kaldırdığı anda belirir; taş düşünce söner.
class ThrowMark extends PositionComponent {
  ThrowMark(Vector2 at, this.life) : super(position: at.clone(), priority: 13);

  final double life;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    if (_t > life + 0.2) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = (_t / life).clamp(0.0, 1.0);
    final pulse = 0.5 + 0.5 * math.sin(_t * (6 + 10 * k));
    final a = (0.35 + 0.5 * k) * (0.7 + 0.3 * pulse);
    final w = 2.4 * kTile;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -2), width: w, height: 12),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFFE8A060).withValues(alpha: a),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, -2),
        width: w * (0.3 + 0.6 * k),
        height: 5 + 5 * k,
      ),
      Paint()
        ..color = const Color(0xFF0A0706).withValues(alpha: 0.35 + 0.4 * k),
    );
    // Yukarıdan dökülen çakıl: taşın geleceği yeri gökten de söyler.
    final grit = Paint()..color = const Color(0xFFB8A890).withValues(alpha: a);
    for (var i = 0; i < 5; i++) {
      final fx = (i - 2) * 9.0 + math.sin(i * 2.3) * 4;
      final fy = -((_t * 140 + i * 37) % 120);
      canvas.drawCircle(Offset(fx, fy), 1.6, grit);
    }
  }
}

/// Devin attığı taş: sabit hedefe yay çizerek düşer; düştüğü yerde ezer,
/// sonra bir süre basamak olarak kalır.
class ThrownStone extends PositionComponent with HasGameReference<GolgeGame> {
  ThrownStone(Vector2 from, this.to, this.flight)
    : _from = from.clone(),
      super(position: from.clone(), priority: 22);

  final Vector2 _from;
  final Vector2 to;
  final double flight;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    final k = (_t / flight).clamp(0.0, 1.0);
    final arc = 4 * k * (1 - k) * 3.5 * kTile;
    position.setValues(
      _from.x + (to.x - _from.x) * k,
      _from.y + (to.y - 18 - _from.y) * k - arc,
    );
    angle += dt * 6;
    if (k < 1) return;
    game.shake(7);
    GameAudio.instance.play('crumble');
    GameAudio.instance.play('land', volume: 0.8);
    final p = game.player;
    final zone = Rect.fromCenter(
      center: Offset(to.x, to.y - 22),
      width: 2.4 * kTile,
      height: 48,
    );
    if (p != null && !p.isDead && p.toRect().overlaps(zone)) {
      p.die();
    }
    game.world.add(StoneStep(Vector2(to.x - 26, to.y - 26)));
    removeFromParent();
  }

  @override
  void render(Canvas canvas) => _drawBoulder(canvas, 24);
}

/// Taşın kalıntısı: birkaç saniye basamaktır (yüksek rafa, kulağa
/// uzanmak için), sonra ufalanıp söner.
class StoneStep extends Deck {
  StoneStep(Vector2 at) : super(position: at, size: Vector2(52, 26));

  static const double life = 7;
  double _t = 0;

  @override
  bool get active => _t < life - 0.8;

  @override
  void step(double dt) {
    _t += dt;
    if (_t > life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final fade = ((life - _t) / 0.8).clamp(0.0, 1.0);
    final crack = _t > life - 1.6 ? math.sin(_t * 60) * 1.2 : 0.0;
    canvas.save();
    canvas.translate(26 + crack, 14);
    _drawBoulder(canvas, 27, alpha: fade, flat: true);
    canvas.restore();
  }
}

void _drawBoulder(
  Canvas canvas,
  double r, {
  double alpha = 1,
  bool flat = false,
}) {
  final rock = Paint()
    ..color = const Color(0xFF2A2430).withValues(alpha: alpha);
  final top = flat ? -0.5 : -1.0;
  canvas.drawPath(
    Path()
      ..moveTo(-r, -r * 0.4)
      ..lineTo(-r * 0.35, r * top)
      ..lineTo(r * 0.7, r * top * 0.8)
      ..lineTo(r, r * 0.25)
      ..lineTo(r * 0.35, r)
      ..lineTo(-r * 0.85, r * 0.75)
      ..close(),
    rock,
  );
  canvas.drawLine(
    Offset(-r * 0.6, r * top * 0.7),
    Offset(r * 0.55, r * top * 0.75),
    Paint()
      ..color = const Color(0xFFC8D2E2).withValues(alpha: 0.6 * alpha)
      ..strokeWidth = 2,
  );
}

/// Temas sayısına göre devin çatlakları (yerel koordinatta, oranla).
/// Devin alanındaki ateşböcekleri: alınan sürünün yerine birkaç saniye
/// sonra yenisi çıkar, oyuncunun bulunduğu yanda (devi geçmeden varılacak
/// yerde); elinde hiç kalmadıysa beklemeden. Dev devrilince durur.
class GiantFireflies extends Component with HasGameReference<GolgeGame> {
  GiantFireflies(this.giant);

  final StoneGiant giant;

  /// En çok bu kadar sürü aynı anda.
  static const int alive = 2;

  /// Bir yer boşaldıktan sonra yeniden dolması için en az süre.
  static const double regrow = 3.5;

  /// İki yeni sürü arası.
  static const double gap = 2.5;

  late final List<Vector2> _spots;
  final _swarms = <int, FireflySwarm>{};
  final _emptyFor = <int, double>{};
  double _cool = 0;

  @override
  void onLoad() {
    final lo = giant._home - 20 * kTile;
    final hi = giant._home + StoneGiant.span + 25 * kTile;
    _spots = [
      for (final c in game.level.fireflyCells)
        if (c.x >= lo && c.x <= hi) c.clone(),
    ];
    // Bölümün kendi sürüleri bu yerlerdeyse sahiplenilir.
    for (final s in game.world.children.whereType<FireflySwarm>()) {
      for (var i = 0; i < _spots.length; i++) {
        final at = _spots[i] + Vector2(kTile / 2, kTile / 2);
        if ((s.position - at).length < 4) _swarms[i] = s;
      }
    }
  }

  @override
  void update(double dt) {
    if (giant.fallen || !giant.isMounted) {
      removeFromParent();
      return;
    }
    _cool -= dt;
    final p = game.player;
    final gx = giant.position.x + giant.size.x / 2;
    // Oyuncunun tarafı: devin öbür yanındaki sürü ona yaramaz (yanına
    // ancak devi geçerek varılır). Eskiden yeni sürü hep devden en uzak
    // yere, çoğu kez öbür yana konuyordu; oyuncu ateşböceksiz kalıyordu.
    final side = p == null ? 0 : (p.center.x < gx ? -1 : 1);
    bool mine(Vector2 spot) =>
        side == 0 || ((spot.x + kTile / 2 - gx).sign == side);
    var count = 0;
    var near = 0;
    for (var i = 0; i < _spots.length; i++) {
      final s = _swarms[i];
      if (s != null && s.isMounted && s.strength >= 1) {
        count++;
        if (mine(_spots[i])) near++;
        _emptyFor[i] = 0;
      } else {
        _emptyFor[i] = (_emptyFor[i] ?? 0) + dt;
      }
    }
    // Oyuncunun yanında en az bir sürü olsun; elinde hiç kalmadıysa beklemeden.
    final starving = near == 0 && game.fireflies == 0;
    if (_spots.isEmpty || (near > 0 && count >= alive)) return;
    if (_cool > 0 && !starving) return;
    int? best;
    var bestD = double.infinity;
    for (var i = 0; i < _spots.length; i++) {
      final s = _swarms[i];
      if (s != null && s.isMounted && s.strength >= 1) continue;
      if (!starving && (_emptyFor[i] ?? 0) < regrow) continue;
      if (!mine(_spots[i])) continue;
      final at = _spots[i] + Vector2(kTile / 2, kTile / 2);
      final d = p == null ? 0.0 : (p.center - at).length;
      // Oyuncunun dibinde belirmesin (toplaması bir adım sürsün).
      if (d < 3 * kTile) continue;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    if (best == null) return;
    final s = FireflySwarm(_spots[best]);
    _swarms[best] = s;
    _emptyFor[best] = 0;
    _cool = gap;
    game.world.add(s);
  }
}

/// Devrilen devin gövdesi: üstü yürünebilir köprüdür. Görünen taş,
/// devin kendi yatan gövdesidir; burada yalnız basılacak sırtın ince ışığı
/// çizilir.
class GiantBridge extends Deck {
  GiantBridge(Vector2 at) : super(position: at, size: Vector2(9 * kTile, 16));

  @override
  void step(double dt) {}

  @override
  void render(Canvas canvas) {
    canvas.drawLine(
      const Offset(6, 1.5),
      Offset(size.x - 10, 1.5),
      Paint()
        ..color = const Color(0xFFC8D2E2).withValues(alpha: 0.35)
        ..strokeWidth = 2,
    );
  }
}

/// Bölümün depremi: ara ara yer sarsılır, gevşek kayalar düşer.
class QuakeClock extends Component with HasGameReference<GolgeGame> {
  double _t = 5;

  @override
  void update(double dt) {
    game.quake = math.max(0, game.quake - dt * 0.7);
    _t -= dt;
    if (_t <= 0) {
      _t = 11 + math.sin(game.levelIndex * 3.0 + _t) * 2;
      game.quake = 1;
      game.shake(7);
      GameAudio.instance.play('grind', volume: 0.9);
      GameAudio.instance.play('crumble', volume: 0.6);
    }
  }
}
