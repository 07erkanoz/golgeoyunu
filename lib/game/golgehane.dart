import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'audio.dart';
import 'golge_game.dart';
import 'hints.dart';
import 'level.dart';
import 'myth_shapes.dart';
import 'palette.dart';
import 'perde.dart';
import 'player.dart';
import 'puzzles.dart' show Usable;
import 'strings.dart';

// ================================================ S2a · Unutulmuş Gölgehane
//
// Yerebatan'da yürüme yolunun sonundaki boşluğun dibi taş değil, taş gibi
// boyanmış bir perde. Su yansıması ele verir: suda, gerçekte olmayan bir
// kemer ve ardından sızan ılık ışık görünür. Perdenin önüne inince perde
// aralanır; ardında ustanın eski çalışma odası: küçük bir hayal perdesi,
// itilen bir kandil, rafta üç küçük tasvir (kuş, at, ejder). Üçü de perdede
// oynatılınca ustanın tasvirinden bir parça belirir (bkz. docs/SIRLAR_PLANI.md).

const _ink = Color(0xFF2A1208);

/// Taş gibi boyanmış perde ve suyun ele veren yansıması. [cell] sahanlığın
/// üstündeki gizli hücrelerin sol üstü (iki hücre genişliğinde, bir yüksek).
class GolgehaneKapi extends PositionComponent with HasGameReference<GolgeGame> {
  GolgehaneKapi(Vector2 cell)
    : super(
        position: cell,
        size: Vector2(2 * kTile, kTile.toDouble()),
        priority: 27,
      );

  static const _key = 'golgehane:acik';

  /// 0 kapalı, 1 tam aralanmış.
  double open = 0;
  bool get opened => _opened;
  bool _opened = false;
  double _t = 0;

  /// Yaklaşana içeriden kısık bir çağrı: çan ve dikişte bir parıltı.
  double _callCool = 0;
  double _call = 0;

  /// Çağrı kaç kez çaldı (testler için).
  int debugCalled = 0;

  /// Su yüzü (yerel y): sahanlığın iki hücre altı.
  static const _water = 3 * kTile;

  @override
  void onMount() {
    super.onMount();
    if (game.eventSeen(_key)) {
      _opened = true;
      open = 1;
    }
  }

  /// Yansımadaki kemerin ortası (dünya): ışık katmanı için.
  Offset get glowCenter =>
      Offset(position.x + size.x / 2, position.y + _water + 22);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_opened) {
      open = math.min(1, open + dt / 0.9);
      return;
    }
    _call = math.max(0, _call - dt / 2.2);
    _callCool = math.max(0, _callCool - dt);
    final p = game.player;
    if (p == null || p.isDead) return;
    // Yaklaşınca odanın içinden kısık bir çan: en çok 15 saniyede bir,
    // tehlike yokken.
    final mid = position + size / 2;
    if (_callCool <= 0 &&
        (p.center - mid).length < 4.5 * kTile &&
        game.calmMoment) {
      _callCool = 15;
      _call = 1;
      debugCalled++;
      GameAudio.instance.play('bell', volume: 0.1);
    }
    // Perdenin önüne (sahanlığa ya da geçide) inince aralanır.
    final gap = Rect.fromLTWH(
      position.x - 4,
      position.y - 10,
      size.x + kTile + 8,
      size.y + 14,
    );
    if (gap.contains(p.center.toOffset())) {
      _opened = true;
      game.markEvent(_key);
      GameAudio.instance.play('glide', volume: 0.35);
      GameAudio.instance.play('breath', volume: 0.25);
    }
  }

  @override
  void render(Canvas canvas) {
    _drawReflection(canvas);
    if (open < 1) {
      _drawMask(canvas);
      _drawCurtain(canvas);
    }
  }

  /// Taş gibi boyanmış perde: iki kanat; aralanınca kenarlara toplanır,
  /// kıvrılır. Kapalıyken taşın sırası ve ışık alan üst dudağı boyalı;
  /// yakından bakan ince bir dikiş ve alttan sızan ışık fark eder.
  void _drawCurtain(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final k = open * open * (3 - 2 * open);
    final stone = Cartoon.on ? Cartoon.stone : kInk;
    final deep = Cartoon.on ? Cartoon.stoneDeep : kInk;
    final lip = Cartoon.on ? Cartoon.lip : const Color(0xFF6A4026);
    for (final side in [-1, 1]) {
      // Kanadın genişliği: kapalıyken yarı, açılınca bir şerit.
      final half = w / 2;
      final width = half * (1 - 0.82 * k);
      final x0 = side < 0 ? 0.0 : w - width;
      final x1 = x0 + width;
      final cloth = Path();
      // Kıvrımlar: açılırken alt kenar dalgalanır.
      final wave = 2.5 * k * math.sin(_t * 5 + side);
      cloth
        ..moveTo(x0, 0)
        ..lineTo(x1, 0)
        ..lineTo(x1 + side * -wave, h)
        ..lineTo(x0 + side * -wave, h)
        ..close();
      canvas.drawPath(
        cloth,
        Paint()
          ..shader = ui.Gradient.linear(Offset.zero, Offset(0, h), [
            stone,
            deep,
          ]),
      );
      // Boyalı taş sırası (kanat toplandıkça sıkışır).
      final course = Paint()
        ..color = deep.withValues(alpha: 0.9)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(x0, h * 0.55), Offset(x1, h * 0.55), course);
      final joint = x0 + width * (side < 0 ? 0.6 : 0.35);
      canvas.drawLine(Offset(joint, 0), Offset(joint, h * 0.55), course);
      // Boyalı üst dudak.
      canvas.drawLine(
        Offset(x0, 1),
        Offset(x1, 1),
        Paint()
          ..color = lip.withValues(alpha: 0.85)
          ..strokeWidth = 2,
      );
      if (k > 0) {
        // Toplanan kumaşın kıvrım gölgeleri.
        final fold = Paint()
          ..color = _ink.withValues(alpha: 0.5 * k)
          ..strokeWidth = 1;
        for (var i = 1; i < 4; i++) {
          final fx = x0 + width * i / 4;
          canvas.drawLine(Offset(fx, 2), Offset(fx - side * wave, h), fold);
        }
      }
    }
    // İki kanadın birleştiği ince dikiş: alttan ılık ışık sızar; çan
    // çalınca bir an parlar.
    if (k < 0.05) {
      final pulse = 0.5 + 0.5 * math.sin(_t * 1.7);
      canvas.drawLine(
        Offset(w / 2, 3),
        Offset(w / 2, h),
        Paint()
          ..color = kWarmLight.withValues(
            alpha: math.min(1, 0.18 + 0.12 * pulse + 0.6 * _call),
          )
          ..strokeWidth = 1 + _call,
      );
      if (_call > 0) {
        glowDot(canvas, Offset(w / 2, h - 4), 18, kWarmLight, 0.35 * _call);
      }
    }
  }

  /// Oda aralanana dek dışarıdan taş görünür: geçit, basamak ve odanın
  /// boşluğu taş dokusuyla örtülür (odanın ışığı da sızmaz).
  void _drawMask(Canvas canvas) {
    final a = 1 - open * open * (3 - 2 * open);
    if (a <= 0) return;
    final stone = Cartoon.on ? Cartoon.stone : kInk;
    final deep = Cartoon.on ? Cartoon.stoneDeep : kInk;
    final r = Rect.fromLTWH(
      size.x,
      0,
      16 * kTile.toDouble(),
      4 * kTile.toDouble(),
    );
    canvas.drawRect(r, Paint()..color = stone.withValues(alpha: a));
    final joint = Paint()
      ..color = deep.withValues(alpha: 0.7 * a)
      ..strokeWidth = 1;
    for (var row = 0; row < 8; row++) {
      final y = r.top + row * 16.0;
      canvas.drawLine(Offset(r.left, y), Offset(r.right, y), joint);
      for (var x = r.left + (row.isEven ? 0 : 16); x < r.right; x += 32) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 16), joint);
      }
    }
  }

  /// Suda, gerçekte olmayan kemer: ters dönmüş, dalgayla titreyen bir
  /// açıklık; içinden ılık ışık. Gerçekçilik kapalıyken de çizilir (sır
  /// herkes için adil kalsın).
  void _drawReflection(Canvas canvas) {
    final w = size.x;
    final top = _water.toDouble();
    const depth = 62.0;
    final pulse = 0.85 + 0.15 * math.sin(_t * 1.3);
    // Kemer (yansımada ters: yayı aşağıda): dış halka taş, iç açıklık ılık;
    // ortada kandilin yansıyan alevi.
    Path arch(double inset) => Path()
      ..moveTo(inset, top)
      ..lineTo(inset, top + 22)
      ..arcToPoint(
        Offset(w - inset, top + 22),
        radius: Radius.circular(w / 2 - inset),
        clockwise: false,
      )
      ..lineTo(w - inset, top)
      ..close();
    final inner = arch(10);
    final ring = Path.combine(PathOperation.difference, arch(3), inner);
    final rim = Cartoon.on ? Cartoon.lip : const Color(0xFF8A5A34);
    final light = Paint()
      ..shader = ui.Gradient.radial(Offset(w / 2, top + 26), 30, [
        const Color(0xFFFFD59A).withValues(alpha: (0.6 + 0.3 * _call) * pulse),
        const Color(0xFF6A2A12).withValues(alpha: 0.75),
      ]);
    final joint = Paint()
      ..color = _ink.withValues(alpha: 0.7)
      ..strokeWidth = 1.2;
    final c = Offset(w / 2, top + 22);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(-8, top, w + 16, depth));
    // Dalga: her yatay şerit kendi payında kayar, derinde biraz söner.
    for (var y = 0.0; y < depth; y += 3) {
      final dx = math.sin(_t * 2.1 + y * 0.35) * (1 + y * 0.05);
      final fade = 1 - 0.55 * y / depth;
      canvas.saveLayer(
        Rect.fromLTWH(-8, top + y, w + 16, 3.2),
        Paint()..color = Color.fromRGBO(0, 0, 0, fade),
      );
      canvas.clipRect(Rect.fromLTWH(-8, top + y, w + 16, 3.2));
      canvas.translate(dx, 0);
      canvas.drawPath(inner, light);
      canvas.drawPath(ring, Paint()..color = rim.withValues(alpha: 0.85));
      // Kemer taşlarının derzleri.
      for (var i = 0; i <= 6; i++) {
        final ang = math.pi * i / 6;
        final d = Offset(math.cos(ang), math.sin(ang));
        canvas.drawLine(c + d * (w / 2 - 10), c + d * (w / 2 - 3), joint);
      }
      canvas.restore();
    }
    canvas.restore();
    glowDot(canvas, Offset(w / 2, top + 26), 30, kWarmLight, 0.16 * pulse);
  }
}

/// Ustanın odası: küçük perde, itilen kandil, raftaki tasvirler ve ödül.
/// [room] odanın sol üst köşesi (dünya), boyutu [size].
class GolgehaneSahne extends PositionComponent
    with HasGameReference<GolgeGame> {
  GolgehaneSahne(Vector2 room, Vector2 size)
    : super(position: room, size: size, priority: 3);

  static const _name = 'golgehane';

  /// Perde (yerel): kandil ve gölge bu dikdörtgene düşer.
  Rect get screen => Rect.fromLTWH(2.5 * kTile, 12, 8 * kTile, 86);

  /// Kandilin yerel x'i (zeminde, rayda kayar).
  double lampX = 1.6 * kTile;
  double get _railMin => 0.9 * kTile;
  double get _railMax => size.x - 4.2 * kTile;

  /// Kandilin alevi (dünya): ışık katmanı için.
  Offset get lampAt => Offset(position.x + lampX, position.y + size.y - 30);

  /// Bağlı taş perde: aralanmadan oda ışık vermez, tasvirlere dokunulmaz.
  GolgehaneKapi? kapi;
  bool get lit => kapi?.opened ?? true;

  /// Oynayan tasvir (0 kuş, 1 at, 2 ejder) ve süresi.
  int playing = -1;
  double playT = 0;
  static const playLen = 4.2;
  final played = <int>{};

  /// Ödül: üç tasvir de oynayınca beliren parça (yerel). -1: yok.
  double pieceT = -1;
  bool _taken = false;
  bool _hinted = false;
  double _t = 0;
  double _pushSound = 0;

  Offset get _pieceAt => Offset(screen.center.dx, size.y - 18);

  @override
  void onMount() {
    super.onMount();
    _taken = game.secretSeen(_name);
  }

  /// Raftaki tasvirin yerel x'i.
  double shelfX(int i) => size.x - 2.6 * kTile + i * 26;

  void play(int i) {
    playing = i;
    playT = 0;
    GameAudio.instance.play(i == 0 ? 'bird_2' : 'creak', volume: 0.4);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _pushSound = math.max(0, _pushSound - dt);
    final p = game.player;
    if (p == null || p.isDead) return;
    final inside = toRect().inflate(4).contains(p.center.toOffset());
    if (inside && !_hinted) {
      _hinted = true;
      game.once('golgehaneHint', Hints.text('golgehane'), hint: true);
    }
    // Kandili itmek: yerde, kandile doğru yürürken önüne düşer.
    final lx = position.x + lampX;
    final floorY = position.y + size.y;
    if (p.onGround && (p.position.y + Player.h - floorY).abs() < 6) {
      final dx = lx - p.center.x;
      final reach = Player.w / 2 + 7;
      final moving = p.velocity.x;
      if (dx.abs() < reach && moving.abs() > 5 && dx.sign == moving.sign) {
        final next = (p.center.x + moving.sign * reach - position.x).clamp(
          _railMin,
          _railMax,
        );
        if ((next - lampX).abs() > 0.1 && _pushSound <= 0) {
          GameAudio.instance.play('grind', volume: 0.08);
          _pushSound = 0.7;
        }
        lampX = next;
      }
    }
    if (playing >= 0) {
      playT += dt;
      if (playT >= playLen) {
        played.add(playing);
        playing = -1;
        if (played.length == 3 && !_taken && pieceT < 0) {
          pieceT = 0;
          GameAudio.instance.play('solve', volume: 0.5);
        }
      }
    }
    if (pieceT >= 0 && !_taken) {
      pieceT += dt;
      final at = position.toOffset() + _pieceAt;
      if (pieceT > 0.8 && (p.center.toOffset() - at).distance < 24) {
        _taken = true;
        pieceT = -1;
        game.foundSecret(_name);
        GameAudio.instance.play('memory', volume: 0.7);
        game.once('golgehane', S.of('golgehaneMemory'), story: false);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    _drawRoom(canvas);
    _drawScreen(canvas);
    _drawLamp(canvas);
    _drawShelf(canvas);
    if (pieceT >= 0 && !_taken) _drawPiece(canvas);
  }

  /// Duvardaki eski izler: çivi, asılı ip, yerde kırpıntılar.
  void _drawRoom(Canvas canvas) {
    final floor = size.y;
    final scrap = Paint()..color = _ink.withValues(alpha: 0.55);
    for (var i = 0; i < 7; i++) {
      final x = 30.0 + i * 57 % (size.x - 60);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, floor - 1.5), width: 7, height: 2.5),
        scrap,
      );
    }
    // Kandilin rayı.
    canvas.drawLine(
      Offset(_railMin - 6, floor - 2),
      Offset(_railMax + 6, floor - 2),
      Paint()
        ..color = const Color(0xFF6A4026)
        ..strokeWidth = 1.6,
    );
  }

  /// Küçük hayal perdesi: kandil yanında ılık, uzağında koyu. Sâye'nin
  /// gölgesi kandile yaklaştıkça devleşir; oynatılan tasvir perdede canlanır.
  void _drawScreen(Canvas canvas) {
    final r = screen;
    // Ayaklar ve çerçeve.
    final wood = Paint()
      ..color = const Color(0xFF4A2A16)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(r.left + 6, r.bottom),
      Offset(r.left + 2, size.y),
      wood,
    );
    canvas.drawLine(
      Offset(r.right - 6, r.bottom),
      Offset(r.right - 2, size.y),
      wood,
    );
    final flick = 0.9 + 0.06 * math.sin(_t * 7.3) + 0.04 * math.sin(_t * 11.9);
    final lamp = Offset(lampX, r.center.dy);
    canvas.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          lamp,
          r.width * 0.75,
          [
            const Color(0xFFFFD59A).withValues(alpha: 0.9 * flick),
            const Color(0xFFB8692F).withValues(alpha: 0.8 * flick),
            const Color(0xFF3A180A).withValues(alpha: 0.92),
          ],
          const [0, 0.45, 1],
        ),
    );
    canvas.save();
    canvas.clipRect(r);
    _drawSayeShadow(canvas, r);
    if (playing >= 0) _drawPlay(canvas, r);
    canvas.restore();
    canvas.drawRect(
      r.inflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xFF4A2A16),
    );
  }

  /// Kandilden uzaklık → gölgenin büyüklüğü (yakın: dev, uzak: küçük).
  static double shadowScale(double distance) =>
      (0.5 + 34 / (distance.abs() + 12)).clamp(0.55, 1.75);

  void _drawSayeShadow(Canvas canvas, Rect r) {
    final p = game.player;
    if (p == null || p.isDead) return;
    final px = p.center.x - position.x;
    if (!toRect().inflate(8).contains(p.center.toOffset())) return;
    final d = px - lampX;
    final s = shadowScale(d);
    final sx = lampX + d * 1.15;
    final feet = r.bottom - 2 + (p.position.y + Player.h - position.y - size.y);
    canvas.save();
    canvas.translate(sx, feet);
    canvas.scale(p.facing * s, s);
    PerdePainter.drawSaye(
      canvas,
      Paint()..color = const Color(0xFF1A0A04).withValues(alpha: 0.78),
      Paint()..color = const Color(0x00000000),
      _t,
      jar: 0,
    );
    canvas.restore();
  }

  /// Oynayan tasvir: kuş perdeyi uçarak geçer, at dörtnala koşar, ejder
  /// kendi kuyruğunu kovalar (sonunda başı döner).
  void _drawPlay(Canvas canvas, Rect r) {
    final u = (playT / playLen).clamp(0.0, 1.0);
    final a =
        math.min(1.0, playT / 0.3) * math.min(1.0, (playLen - playT) / 0.4);
    final ink = Paint()..color = _ink.withValues(alpha: 0.85 * a);
    void cut(Path shape, Offset feet, double h, {bool flip = false}) {
      canvas.save();
      canvas.translate(feet.dx, feet.dy);
      canvas.scale(flip ? -h / 100 : h / 100, h / 100);
      canvas.drawPath(shape, ink);
      canvas.restore();
    }

    switch (playing) {
      case 0:
        final x = r.left - 20 + (r.width + 40) * u;
        final y = r.top + 34 + math.sin(u * math.pi * 3) * 12;
        final flap = (playT * 6).floor().isEven;
        cut(
          flap ? MythShapes.birdFlap : MythShapes.birdGlide,
          Offset(x, y),
          26,
        );
      case 1:
        final x = r.right + 30 - (r.width + 60) * u;
        final bob = (math.sin(playT * 14)).abs() * 5;
        cut(MythShapes.horse, Offset(x, r.bottom - 6 - bob), 46, flip: true);
      default:
        _drawEjder(canvas, r, u, ink);
    }
  }

  /// Kendi kuyruğunu kovalayan küçük ejder: halka biçimli gövde döner;
  /// sonda yetişemeyip başı döner, bir an sendeler.
  void _drawEjder(Canvas canvas, Rect r, double u, Paint ink) {
    final c = Offset(r.center.dx, r.center.dy + 8);
    final spin = u < 0.8 ? u / 0.8 * math.pi * 5 : math.pi * 5;
    final dizzy = u < 0.8 ? 0.0 : math.sin((u - 0.8) * 40) * 0.25;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(spin + dizzy);
    const radius = 22.0;
    // Gövde: başın ardından halka boyunca incelir, kuyruk başa yetişmez.
    for (var i = 0; i < 18; i++) {
      final ang = -i * 0.3;
      final at = Offset(math.cos(ang) * radius, math.sin(ang) * radius);
      canvas.drawCircle(at, math.max(2.2, 7 - i * 0.28), ink);
      if (i.isEven && i > 1 && i < 16) {
        final out = Offset(math.cos(ang), math.sin(ang));
        canvas.drawPath(
          Path()
            ..moveTo(
              at.dx + out.dx * 4 - out.dy * 3,
              at.dy + out.dy * 4 + out.dx * 3,
            )
            ..lineTo(at.dx + out.dx * 11, at.dy + out.dy * 11)
            ..lineTo(
              at.dx + out.dx * 4 + out.dy * 3,
              at.dy + out.dy * 4 - out.dx * 3,
            )
            ..close(),
          ink,
        );
      }
    }
    // Baş: halkanın ucunda, kuyruğa dönük; ağzı açık.
    canvas.save();
    canvas.translate(radius, 0);
    canvas.rotate(math.pi / 2);
    canvas.drawPath(
      Path()
        ..moveTo(-7, 2)
        ..quadraticBezierTo(0, -6, 13, -2)
        ..lineTo(12, 1)
        ..lineTo(3, 2)
        ..lineTo(13, 6)
        ..lineTo(-6, 7)
        ..close(),
      ink,
    );
    for (final bx in [-4.0, 0.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(bx - 2, -2)
          ..quadraticBezierTo(bx - 4, -10, bx - 9, -13)
          ..quadraticBezierTo(bx - 1, -9, bx + 2, -2)
          ..close(),
        ink,
      );
    }
    canvas.restore();
    canvas.restore();
  }

  /// Rayda kayan pirinç kandil: tekerlekli kısa ayak, alev.
  void _drawLamp(Canvas canvas) {
    final x = lampX;
    final floor = size.y;
    final brass = Paint()..color = const Color(0xFF8A5A30);
    final dark = Paint()..color = const Color(0xFF3A2414);
    canvas.drawCircle(Offset(x - 5, floor - 3), 2.6, dark);
    canvas.drawCircle(Offset(x + 5, floor - 3), 2.6, dark);
    canvas.drawRect(Rect.fromLTWH(x - 1.5, floor - 22, 3, 18), brass);
    final bowl = Path()
      ..moveTo(x - 9, floor - 24)
      ..quadraticBezierTo(x, floor - 16, x + 9, floor - 24)
      ..lineTo(x + 12, floor - 27)
      ..lineTo(x - 7, floor - 27)
      ..close();
    canvas.drawPath(bowl, brass);
    final flick = math.sin(_t * 9) * 1.2;
    glowDot(canvas, Offset(x + 9, floor - 32), 26, kWarmLight, 0.55);
    canvas.drawPath(
      Path()
        ..moveTo(x + 6.5, floor - 27)
        ..quadraticBezierTo(x + 8 + flick, floor - 38, x + 10, floor - 40)
        ..quadraticBezierTo(x + 11.5, floor - 32, x + 11.5, floor - 27)
        ..close(),
      Paint()..color = const Color(0xFFFFE6B0),
    );
  }

  /// Raf ve üç küçük tasvir; oynamış olanın kenarı ılık. Oynayan tasvir
  /// rafta değil, perdede.
  void _drawShelf(Canvas canvas) {
    final floor = size.y;
    final x0 = shelfX(0) - 14;
    final x1 = shelfX(2) + 14;
    final wood = Paint()..color = const Color(0xFF4A2A16);
    canvas.drawRect(Rect.fromLTRB(x0, floor - 20, x1, floor - 16), wood);
    canvas.drawRect(Rect.fromLTRB(x0 + 2, floor - 16, x0 + 5, floor), wood);
    canvas.drawRect(Rect.fromLTRB(x1 - 5, floor - 16, x1 - 2, floor), wood);
    for (var i = 0; i < 3; i++) {
      if (i == playing) continue;
      final at = Offset(shelfX(i), floor - 20);
      final done = played.contains(i);
      // Deri tasvir: renkli, yarı saydam; sapı rafa dayalı.
      canvas.drawLine(
        at,
        at.translate(-2, -22),
        Paint()
          ..color = const Color(0xFF6A4026)
          ..strokeWidth = 1.2,
      );
      final leather = Paint()
        ..color = [
          const Color(0xFFB8692F),
          const Color(0xFF8A3A24),
          const Color(0xFF5A6A30),
        ][i].withValues(alpha: 0.9);
      canvas.save();
      canvas.translate(at.dx, at.dy - 4);
      switch (i) {
        case 0:
          canvas.scale(0.16);
          canvas.drawPath(MythShapes.birdGlide, leather);
        case 1:
          canvas.scale(-0.2, 0.2);
          canvas.drawPath(MythShapes.horse, leather);
        default:
          canvas.translate(0, -9);
          for (var k = 0; k < 9; k++) {
            final ang = -k * 0.6;
            canvas.drawCircle(
              Offset(math.cos(ang) * 6, math.sin(ang) * 6),
              math.max(1.2, 3 - k * 0.2),
              leather,
            );
          }
      }
      canvas.restore();
      if (done) {
        glowDot(canvas, at.translate(0, -10), 14, kWarmLight, 0.3);
      } else if (played.isEmpty) {
        final pulse = 0.5 + 0.5 * math.sin(_t * 2.4 + i);
        glowDot(canvas, at.translate(0, -10), 12, kWarmLight, 0.15 * pulse);
      }
    }
  }

  /// Ustanın tasvirinden bir parça: kavuklu baş, havada döner.
  void _drawPiece(Canvas canvas) {
    final k = math.min(1.0, pieceT / 0.8);
    final at = _pieceAt.translate(0, -8 * k + math.sin(_t * 2) * 2);
    glowDot(canvas, at, 34, kWarmLight, 0.5 * k);
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(math.cos(_t * 1.6), 1);
    final leather = Paint()
      ..color = const Color(0xFFC08458).withValues(alpha: k);
    canvas.drawCircle(Offset.zero, 6, leather);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -7), width: 13, height: 8),
      leather,
    );
    canvas.drawCircle(
      const Offset(2, -1),
      1.2,
      Paint()..color = kWarmLight.withValues(alpha: k),
    );
    canvas.restore();
  }
}

/// Raftaki tasvirlerden biri: ↑ ile perdede oynatılır.
class GolgehaneTasvir extends PositionComponent
    with HasGameReference<GolgeGame>, Usable {
  GolgehaneTasvir(this.sahne, this.index)
    : super(
        position:
            sahne.position + Vector2(sahne.shelfX(index), sahne.size.y - 12),
      );

  final GolgehaneSahne sahne;
  final int index;

  @override
  bool canUse(Vector2 p) =>
      sahne.playing < 0 &&
      sahne.lit &&
      (p.x - position.x).abs() < 12 &&
      (p.y - position.y).abs() < 30;

  @override
  void use() => sahne.play(index);
}
