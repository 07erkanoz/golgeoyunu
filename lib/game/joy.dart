import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'golge_game.dart';
import 'level.dart';
import 'levels.dart';
import 'palette.dart';
import 'perde.dart';
import 'player.dart';
import 'rig.dart';

// ================================================================ Neşe parkuru
//
// Gerilimin arasında bir soluk: bölümün sakin, açık bir yerinde iki zıpzıp
// (temaya göre davul, perde bezi, mantar ya da bulut) ve üstlerinde bir
// ışık dizisi. Dizi zıplayışın yolunu çizer: ilk zıpzıpta havalanıp ikinciye
// konan, oradan daha yükseğe sıçrayan oyuncu ışıkları toplar. İlk ışığa
// dokununca dizi süreyle yanar; hepsi toplanırsa perdenin ardındaki seyirci
// alkışlar, ışıklar Sâye'nin üstüne yağar (bir sır). Toplanamazsa ışıklar
// birazdan yeniden belirir. Yolu kapatmaz, zorunlu değildir.
//
// Yer haritaya elle konmaz: bölüm kurulurken düz, geniş, üstü açık ve
// tehlikesiz bir zemin aranır (bölüm başına en çok iki).

/// Zıpzıpın görünüşü.
enum BouncerLook { drum, cloth, mushroom, cloud }

BouncerLook bouncerLookFor(LevelTheme t) => switch (t) {
  LevelTheme.cistern ||
  LevelTheme.cave ||
  LevelTheme.ark ||
  LevelTheme.underworld => BouncerLook.cloth,
  LevelTheme.forest => BouncerLook.mushroom,
  LevelTheme.sky || LevelTheme.kaf || LevelTheme.heavens => BouncerLook.cloud,
  _ => BouncerLook.drum,
};

/// Bir parkur yeri: sütun, Sâye'nin durduğu satır, üstteki açıklık (kare).
typedef JoySpot = ({int c, int r, int air});

/// Zıpzıpın gücü: normal zıplamanın yaklaşık 1,45 katı (ikincisi daha da
/// yüksek); tavan alçaksa Sâye'nin başı değmeyecek kadar.
double bouncePower(int air, {bool second = false}) {
  final room = air * kTile - Player.h - 12;
  final fit = math.sqrt(2 * Player.gravity * room);
  return math.min(second ? 960.0 : 840.0, fit);
}

/// Koşarak bir sıçrayışta gidilen yol (kare).
int hopTiles(double v) =>
    (Player.runSpeed * 2 * v / Player.gravity / kTile).round();

/// Ölçüm için: neşe paketini kapatır (parkur, perde, kuşlar).
bool joyEnabled = true;

/// Bölümdeki neşe parkurları (yer bulunamazsa boş).
List<Component> joyPlaces(Level lv) {
  if (!joyEnabled) return const [];
  final def = lv.def;
  if (def.skiMarks != null) return const [];
  final spots = findJoySpots(lv);
  final look = bouncerLookFor(def.theme);
  final stage = findKaragozSpot(lv, spots);
  return [
    for (var i = 0; i < spots.length; i++) ..._course(i, spots[i], look),
    if (stage != null)
      KaragozSahne(
        // Elle konan perde hücre sınırında durur (sarnıçta iki sütunun
        // tam ortası).
        _feet(stage.$1, stage.$2) - Vector2(stage.$4 ? kTile / 2 : 0, 0),
        stage.$3,
      ),
  ];
}

/// Karagöz perdesinin yeri ve gösterecekleri yer: Gölgehane'si olan bölümde
/// gizli oda, yoksa ilerideki neşe parkuru. Düz ve tavanı yeterince yüksek
/// bir zemin; başlangıçtan biraz sonra, hedefine yakın olanı.
(int, int, Vector2?, bool)? findKaragozSpot(Level lv, List<JoySpot> courses) {
  final far = _farTest(lv);
  Vector2? secret;
  (int, int)? fixed;
  for (final (name, c, r) in lv.def.surprises) {
    if (name == 'golgehane') {
      secret = Vector2((c + 0.5) * kTile, (r + 0.5) * kTile.toDouble());
    } else if (name == 'karagoz') {
      fixed = (c, r);
    }
  }
  // Haritada elle konmuş perde (Yerebatan: gizli odanın tam üstünde).
  if (fixed != null) return (fixed.$1, fixed.$2, secret, true);
  final start = lv.playerStart.x / kTile;
  (int, int, Vector2?, bool)? best;
  var bestScore = double.infinity;
  for (var r = 3; r < lv.height - 1; r++) {
    for (var c = 6; c < lv.width - 6; c++) {
      var ok = true;
      for (var dc = -3; dc <= 3 && ok; dc++) {
        if (lv.cell(c + dc, r) != '.' || !_floor(lv.cell(c + dc, r + 1))) {
          ok = false;
        }
        for (var dr = 1; dr <= 4 && ok; dr++) {
          if (lv.cell(c + dc, r - dr) != '.' || r - dr < 1) ok = false;
        }
      }
      if (!ok || !far(c, r)) continue;
      if (courses.any((s) => (s.c - c).abs() < 14 && (s.r - r).abs() < 8)) {
        continue;
      }
      final from = (c - start).abs();
      if (from < 20) continue;
      // Gösterecekleri yer: gizli oda ya da önündeki ilk parkur.
      var target = secret;
      if (target == null) {
        for (final s in courses) {
          if (s.c > c + 10) {
            target = _feet(s.c + 2, s.r) - Vector2(0, 2 * kTile.toDouble());
            break;
          }
        }
      }
      final toTarget = target == null
          ? 140.0
          : (target.x / kTile - c).abs().toDouble();
      final score = from * 0.3 + toTarget;
      if (score < bestScore) {
        bestScore = score;
        best = (c, r, target, false);
      }
    }
  }
  return best;
}

List<Component> _course(int i, JoySpot s, BouncerLook look) {
  final v1 = bouncePower(s.air);
  final v2 = bouncePower(s.air, second: true);
  final first = _feet(s.c, s.r);
  final one = Bouncer(first, look, power: v1);
  // İkinci zıpzıp tam ilk sıçrayışın (koşarak) indiği yerde.
  final second = first + Vector2(_reach(v1), 0);
  return [
    one,
    Bouncer(second, look, power: v2),
    JoyLights(i, [
      ..._hop(first, one.top, v1, 5),
      ..._hop(second, one.top, v2, 6),
    ]),
  ];
}

Vector2 _feet(int c, int r) => Vector2((c + 0.5) * kTile, (r + 1) * kTile);

/// Koşarak bir sıçrayışta gidilen yol (piksel).
double _reach(double v) => Player.runSpeed * 2 * v / Player.gravity;

/// Bir sıçrayışın yolundaki [n] ışık: Sâye'nin göğsü hizasında, zıpzıpın
/// üstünden ([top]) kalkıp aynı yüksekliğe inen yay.
List<Vector2> _hop(Vector2 feet, double top, double v, int n) {
  final total = 2 * v / Player.gravity;
  return [
    for (var i = 1; i <= n; i++)
      () {
        final t = total * i / (n + 1);
        final rise = v * t - Player.gravity * t * t / 2;
        return Vector2(
          feet.x + Player.runSpeed * t,
          feet.y - top - Player.h / 2 - rise,
        );
      }(),
  ];
}

bool _floor(String ch) => ch == '#' || ch == '=';

/// Düzeneklerden, canlılardan, kayıt noktalarından uzak mı (sütun, satır).
bool Function(int c, int r) _farTest(Level lv) {
  final busy = <Vector2>[
    lv.playerStart,
    lv.exitCell,
    ...lv.guardCells,
    ...lv.watcherCells,
    ...lv.checkpointCells,
    ...lv.crateCells,
    ...lv.fireflyCells,
    ...lv.crumbleCells,
    ...lv.leverCells,
    ...lv.floatCells,
    ...lv.beamCells,
    ...lv.lockCells,
    ...lv.perdeCells,
    ...lv.eyeStoneCells,
    ...lv.starCells,
    ...lv.giantCells,
    ...lv.medusaCells,
    ...lv.ringCells,
    ...lv.raftCells,
    ...lv.ventCells,
    ...lv.icicleCells,
    ...lv.thinIceCells,
    ...lv.floodCells,
    ...lv.animalCells,
    ...lv.pedestalCells,
    ...lv.semazenCells,
    ...lv.chandelierCells,
    ...lv.lampCells,
    ...lv.kutCells,
    ...lv.deerCells,
    ...lv.deerPlateCells,
    ...lv.boulderCells,
    ...lv.batCells,
    ...lv.crowCells,
    ...lv.wingsCells,
    ...lv.balloonCells,
    ...lv.featherCells,
    ...lv.altarCells,
    ...lv.bellCells,
    ...lv.memoryCells,
    ...lv.shieldCells,
    ...lv.yadaCells,
    ...lv.reliefCells,
    ...lv.glimpseCells,
    ...lv.gladeBeamCells,
    ...lv.liftA,
    ...lv.liftB,
    for (final (c, _) in lv.movingCells) c,
  ];
  for (final (c, r, _) in lv.gates) {
    busy.add(Vector2(c * kTile.toDouble(), r * kTile.toDouble()));
  }
  bool far(int c, int r) {
    for (final b in busy) {
      final dc = (b.x / kTile - c).abs();
      final dr = (b.y / kTile - r).abs();
      // Kandilci ve Gözcü uzaktan görür: onlardan daha uzak.
      if (dc < 7 && dr < 6) return false;
    }
    final at = Vector2((c + 0.5) * kTile, r * kTile.toDouble());
    for (final g in [...lv.guardCells, ...lv.watcherCells]) {
      if ((g - at).length < 14 * kTile) return false;
    }
    if (lv.inDarkZone(at)) return false;
    return true;
  }

  return far;
}

/// Parkur yerleri: (sütun, Sâye'nin durduğu satır, açıklık). En çok iki,
/// birbirinden uzak; başlangıçtan, düzeneklerden, Kandilcilerden ve kayıt
/// noktalarından uzak.
List<JoySpot> findJoySpots(Level lv) {
  final far = _farTest(lv);
  final cands = <JoySpot>[];
  for (var r = 3; r < lv.height - 1; r++) {
    for (var c = 4; c < lv.width - 14; c++) {
      if (lv.cell(c, r) != '.' || !_floor(lv.cell(c, r + 1))) continue;
      // Üstü açık mı (en çok sekiz kare): zıpzıpın gücü buna göre.
      var air = 0;
      for (var dr = 1; dr <= 8 && r - dr >= 1; dr++) {
        var row = true;
        for (var dc = -1; dc <= 10 && row; dc++) {
          final ch = lv.cell(c + dc, r - dr);
          if (ch != '.' && ch != 'r') row = false;
        }
        if (!row) break;
        air = dr;
      }
      if (air < 5) continue;
      final span =
          hopTiles(bouncePower(air)) + hopTiles(bouncePower(air, second: true));
      // Düz, kesintisiz zemin: başından ikinci sıçrayışın indiği yere dek.
      var ok = true;
      for (var dc = -2; dc <= span + 1 && ok; dc++) {
        if (lv.cell(c + dc, r) != '.' || !_floor(lv.cell(c + dc, r + 1))) {
          ok = false;
        }
      }
      // Diken, su, saklanılan gölge yok.
      for (var dr = -air; dr <= 2 && ok; dr++) {
        for (var dc = -4; dc <= span + 3 && ok; dc++) {
          final ch = lv.cell(c + dc, r + dr);
          if (ch == '^' || ch == 'w' || ch == '~' || ch == 'I') ok = false;
        }
      }
      if (!ok || !far(c, r) || !far(c + span, r)) continue;
      cands.add((c: c, r: r, air: air));
    }
  }
  // Önce en açık yerler (en yüksek sıçrayış), sonra bölümün ortasına
  // yakın olanlar; birbirinden en az 40 kare uzak.
  final mid = lv.width / 2;
  cands.sort((a, b) {
    final h = b.air.compareTo(a.air);
    if (h != 0) return h;
    return (a.c - mid).abs().compareTo((b.c - mid).abs());
  });
  final out = <JoySpot>[];
  for (final s in cands) {
    if (out.any((o) => (o.c - s.c).abs() < 40 && (o.r - s.r).abs() < 20)) {
      continue;
    }
    out.add(s);
    if (out.length == 2) break;
  }
  out.sort((a, b) => a.c.compareTo(b.c));
  return out;
}

// ------------------------------------------------------------------ zıpzıp

/// Üstüne düşeni yükseğe fırlatır; zıplama basılıysa daha da yükseğe.
class Bouncer extends PositionComponent with HasGameReference<GolgeGame> {
  Bouncer(Vector2 feet, this.look, {this.power = 840})
    : super(position: feet, anchor: Anchor.bottomCenter, priority: 18) {
    size = Vector2(36, top);
  }

  final BouncerLook look;

  /// Fırlatma hızı (yerin açıklığına göre; bkz. [bouncePower]).
  final double power;
  double _t = 0;

  /// Ezilme (vurulunca 1, yaylanarak söner).
  double _squash = 0;
  double _squashV = 0;
  double? _prevFeet;

  /// Üst yüzünün yerden yüksekliği.
  double get top => switch (look) {
    BouncerLook.drum => 20,
    BouncerLook.cloth => 14,
    BouncerLook.mushroom => 22,
    BouncerLook.cloud => 14,
  };

  /// Karanlıkta yeri seçilsin diye: üst yüzün ortası (dünya).
  Offset get glowCenter => Offset(position.x, position.y - top);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    // Yay: ezilme sönümlü salınımla geri gelir.
    _squashV += (-_squash * 260 - _squashV * 9) * dt;
    _squash += _squashV * dt;
    final p = game.player;
    if (p == null || p.isDead) {
      _prevFeet = null;
      return;
    }
    final feet = p.position.y + Player.h;
    final surface = position.y - top;
    final prev = _prevFeet;
    _prevFeet = feet;
    if ((p.center.x - position.x).abs() > 20) return;
    if (p.velocity.y < 0 || prev == null) return;
    if (prev <= surface + 3 && feet >= surface - 2) {
      p.position.y = surface - Player.h;
      p.bounce(power);
      _squash = 1;
      _squashV = 0;
      final a = GameAudio.instance;
      if (look == BouncerLook.drum) {
        a.play('drum', volume: 0.5, minGapMs: 150);
      } else {
        a.play('jump', volume: 0.5, minGapMs: 150);
        a.play('glide', volume: 0.3, minGapMs: 150);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y);
    final sq = _squash.clamp(-0.6, 1.0);
    // Ezilince yassılır, yana açılır.
    canvas.scale(1 + 0.14 * sq, 1 - 0.3 * sq);
    switch (look) {
      case BouncerLook.drum:
        _drum(canvas);
      case BouncerLook.cloth:
        _cloth(canvas, sq);
      case BouncerLook.mushroom:
        _mushroom(canvas);
      case BouncerLook.cloud:
        _cloud(canvas);
    }
    canvas.restore();
  }

  /// Davul: kızıl gövde, zikzak ip, açık deri.
  void _drum(Canvas c) {
    const w = 30.0, h = 20.0;
    final body = Rect.fromLTWH(-w / 2, -h, w, h);
    c.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(3)),
      Paint()
        ..shader = Gradient.linear(
          body.centerLeft,
          body.centerRight,
          const [Color(0xFF5A1C14), Color(0xFFA03A24), Color(0xFF4A1610)],
          const [0, 0.45, 1],
        ),
    );
    final rope = Paint()
      ..color = const Color(0xFFE8D2A0)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    final z = Path()..moveTo(-w / 2 + 1, -h + 3);
    for (var i = 0; i < 6; i++) {
      final x = -w / 2 + 1 + (i + 1) * (w - 2) / 6;
      z.lineTo(x, i.isEven ? -3 : -h + 3);
    }
    c.drawPath(z, rope);
    for (final y in [-h + 1.5, -1.5]) {
      c.drawLine(Offset(-w / 2, y), Offset(w / 2, y), rope..strokeWidth = 2);
    }
    c.drawOval(
      Rect.fromCenter(center: const Offset(0, -h), width: w, height: 7),
      Paint()..color = const Color(0xFFF2DEB0),
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(0, -h), width: w, height: 7),
      Paint()
        ..color = const Color(0xFF6A3A1C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  /// Perde bezi: iki kısa direğe gerili, kandille ışıyan ak bez.
  void _cloth(Canvas c, double sq) {
    const w = 34.0, h = 14.0;
    final post = Paint()..color = const Color(0xFF3A2414);
    c.drawRect(const Rect.fromLTWH(-w / 2 - 2, -h - 3, 3.5, h + 3), post);
    c.drawRect(const Rect.fromLTWH(w / 2 - 1.5, -h - 3, 3.5, h + 3), post);
    // Bez: ortası basılınca çöker.
    final sag = 3 + 5 * sq.clamp(0.0, 1.0);
    final cloth = Path()
      ..moveTo(-w / 2, -h)
      ..quadraticBezierTo(0, -h + sag * 2, w / 2, -h)
      ..lineTo(w / 2, -h + 4)
      ..quadraticBezierTo(0, -h + sag * 2 + 4, -w / 2, -h + 4)
      ..close();
    final glow = 0.75 + 0.25 * math.sin(_t * 2.3);
    c.drawPath(
      cloth,
      Paint()
        ..color = Color.lerp(
          const Color(0xFFE8C890),
          const Color(0xFFFFF0C8),
          glow,
        )!,
    );
    // Bezin üstündeki küçük tasvir: el ele iki gölge.
    final ink = Paint()..color = const Color(0x55301808);
    for (final x in [-5.0, 5.0]) {
      c.drawCircle(Offset(x, -h + sag + 0.4), 1.1, ink);
    }
  }

  /// Mantar: yosunlu sapın üstünde benekli, şişkin şapka.
  void _mushroom(Canvas c) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-5, -14, 10, 14),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFE6D8B8),
    );
    final cap = Path()
      ..moveTo(-18, -12)
      ..cubicTo(-18, -26, 18, -26, 18, -12)
      ..quadraticBezierTo(0, -9, -18, -12)
      ..close();
    c.drawPath(cap, Paint()..color = const Color(0xFFB0462E));
    final dot = Paint()..color = const Color(0xFFFFF0D8);
    for (final (x, y, r) in const [
      (-9.0, -17.0, 2.4),
      (2.0, -20.5, 2.0),
      (10.0, -15.5, 2.2),
      (-2.0, -14.0, 1.4),
    ]) {
      c.drawCircle(Offset(x, y), r, dot);
    }
  }

  /// Bulut: üç yumuşak yumak.
  void _cloud(Canvas c) {
    final p = Paint()..color = const Color(0xFFF2F4FF).withValues(alpha: 0.92);
    for (final (x, y, r) in const [
      (-10.0, -6.0, 8.0),
      (0.0, -9.0, 9.5),
      (10.0, -6.0, 8.0),
    ]) {
      c.drawCircle(Offset(x, y), r, p);
    }
    c.drawRect(const Rect.fromLTWH(-12, -6, 24, 6), p);
  }
}

// --------------------------------------------------------------- ışık dizisi

/// Zıplayışın yolunu çizen ışıklar. İlk ışığa dokununca dizi [window]
/// saniye yanar; hepsi toplanırsa alkış ve ışık yağmuru, sır sayacına
/// eklenir.
class JoyLights extends PositionComponent with HasGameReference<GolgeGame> {
  JoyLights(this.index, this.points) : super(priority: 20);

  final int index;
  final List<Vector2> points;

  /// Dizinin yanık kalma süresi (ilk ışıktan sonra).
  static const double window = 6;

  late final List<bool> taken = List.filled(points.length, false);
  final _pop = <int, double>{};
  double _t = 0;

  /// İlk ışık alındıktan beri geçen süre (null: başlamadı).
  double? _run;

  /// Toplanamadı: ışıklar kısa bir süre sonra yeniden belirir.
  double _rest = 0;
  bool done = false;

  String get secret => 'parkur$index';

  // Eşzamanlı: beklenen bir yükleme, ölüp yeniden doğunca ardından gelen
  // parçaların (kaide, hazne...) dünyaya girişini bekletiyordu.
  @override
  void onLoad() {
    // Bu oyunda (ya da kayıtta) daha önce toplandıysa dizi sönük durur.
    done = game.secretSeen(secret);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    for (final k in _pop.keys.toList()) {
      final v = _pop[k]! + dt;
      if (v > 0.6) {
        _pop.remove(k);
      } else {
        _pop[k] = v;
      }
    }
    if (done) return;
    if (_rest > 0) {
      _rest -= dt;
      if (_rest <= 0) taken.fillRange(0, taken.length, false);
      return;
    }
    final p = game.player;
    if (p == null || p.isDead) return;
    final c = p.center;
    for (var i = 0; i < points.length; i++) {
      if (taken[i]) continue;
      if ((points[i] - c).length < 22) {
        taken[i] = true;
        _pop[i] = 0;
        _run ??= 0;
        final n = taken.where((t) => t).length;
        GameAudio.instance.play(
          'firefly',
          volume: 0.35 + 0.4 * n / points.length,
          minGapMs: 30,
        );
      }
    }
    final run = _run;
    if (run == null) return;
    _run = run + dt;
    if (taken.every((t) => t)) {
      done = true;
      _run = null;
      game.foundSecret(secret);
      GameAudio.instance.play('clap', volume: 0.7);
      GameAudio.instance.play('bell', volume: 0.35);
      game.world.add(JoyRain(p.center.clone()));
    } else if (_run! > window) {
      // Süre doldu: kalanlar söner, hepsi birazdan yeniden belirir.
      _run = null;
      _rest = 1.6;
      GameAudio.instance.play('fizzle', volume: 0.3);
    }
  }

  /// Dizinin parlaklığı: yanarken süre azaldıkça titrer.
  double get _bright {
    final run = _run;
    if (run == null) return 1;
    final left = window - run;
    return left > 2 ? 1 : 0.55 + 0.45 * (0.5 + 0.5 * math.sin(_t * 18));
  }

  @override
  void render(Canvas canvas) {
    final b = _bright;
    for (var i = 0; i < points.length; i++) {
      final at = points[i].toOffset();
      final pop = _pop[i];
      if (pop != null) {
        // Alınan ışık: genişleyen bir halka.
        final k = pop / 0.6;
        canvas.drawCircle(
          at,
          6 + 16 * k,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = kWarmLight.withValues(alpha: 0.8 * (1 - k)),
        );
      }
      if (taken[i] && !_resting) continue;
      final faded = done || _resting;
      final bob = math.sin(_t * 2.6 + i * 0.7) * 2.5;
      final o = at.translate(0, bob);
      final a = (faded ? 0.18 : 0.9) * b;
      glowDot(canvas, o, 14, kWarmLight, 0.5 * a);
      // Dört köşeli küçük yıldız.
      final s = 4.0 + 0.8 * math.sin(_t * 5 + i);
      final star = Path()
        ..moveTo(o.dx, o.dy - s)
        ..quadraticBezierTo(o.dx, o.dy, o.dx + s, o.dy)
        ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + s)
        ..quadraticBezierTo(o.dx, o.dy, o.dx - s, o.dy)
        ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - s)
        ..close();
      canvas.drawPath(
        star,
        Paint()..color = const Color(0xFFFFF4D0).withValues(alpha: a),
      );
    }
  }

  bool get _resting => _rest > 0;
}

/// Parkur tamamlandı: Sâye'nin üstüne ılık ışıklar yağar.
class JoyRain extends PositionComponent {
  JoyRain(Vector2 at) : super(position: at, priority: 31);

  double _t = 0;
  static const double life = 2.4;
  final _bits = [
    for (var i = 0; i < 28; i++)
      (
        (math.Random(i * 7 + 3).nextDouble() - 0.5) * 220,
        -60 - math.Random(i * 13 + 1).nextDouble() * 80,
        math.Random(i * 5 + 2).nextDouble(),
      ),
  ];

  @override
  void update(double dt) {
    _t += dt;
    if (_t > life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final fade = math.min(1.0, (life - _t) / 0.6);
    final colors = [
      kWarmLight,
      const Color(0xFFFFF4D0),
      const Color(0xFFE88A5A),
      const Color(0xFFB8E0FF),
    ];
    for (var i = 0; i < _bits.length; i++) {
      final (x0, y0, k) = _bits[i];
      // Önce yukarı saçılır, sonra yavaşça süzülerek iner, sallanır.
      final t = _t;
      final x = x0 * math.min(1, t * 2.5) + math.sin(t * 4 + i) * 6;
      final y = y0 * math.min(1, t * 3) + 60 * t * t * (0.6 + k * 0.4);
      final p = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 0.9 * fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * (3 + k * 4) + i);
      canvas.drawRect(const Rect.fromLTWH(-2, -1.2, 4, 2.4), p);
      canvas.restore();
    }
  }
}

// ------------------------------------------------------- Umay'ın kuşları (N2)

/// Umay ağacının yanında kıpırdamadan duran Sâye'ye dallardan kuşlar iner:
/// biri başına, biri kavanozunun kenarına konar; gagalar, başını çevirir,
/// cıvıldar. Sâye kıpırdayınca ürküp uçarlar; birazdan yine gelirler.
class UmayBirds extends PositionComponent with HasGameReference<GolgeGame> {
  UmayBirds(Vector2 cell)
    : crown = Vector2(cell.x + kTile / 2, cell.y + kTile - 60),
      super(priority: 21);

  /// Kuşların bekleyip döndüğü yer: ağacın tacı.
  final Vector2 crown;

  /// Durduktan kaç saniye sonra inerler.
  static const double settle = 2.5;

  final _birds = [_Bird(0), _Bird(1)];
  double _still = 0;
  double _wait = 0;

  /// Testler için: Sâye'nin üstüne konmuş kuş sayısı.
  int get perched => _birds.where((b) => b.state == 2).length;

  @override
  void update(double dt) {
    super.update(dt);
    _wait = math.max(0, _wait - dt);
    final p = game.player;
    if (p == null) return;
    final near =
        (p.center.x - crown.x).abs() < 3 * kTile &&
        (p.center.y - crown.y).abs() < 4 * kTile;
    final moving =
        p.velocity.x.abs() > 20 || !p.onGround || p.isDead || p.crouching;
    _still = near && !moving && game.calmMoment ? _still + dt : 0;
    final head = Vector2(p.center.x - p.facing * 1.5, p.position.y + 2);
    final jar = p.lightVisual - Vector2(0, 6);
    for (final b in _birds) {
      b.t += dt;
      switch (b.state) {
        case 0:
          if (_still > settle + b.id * 0.9 && _wait <= 0) {
            b.start(b.pos..setFrom(crown + Vector2(b.id * 14 - 7, 0)), 1);
            GameAudio.instance.play('bird', volume: 0.3, minGapMs: 400);
          }
        case 1:
          // İniş: tacından konacağı yere bir yay.
          final to = b.id == 0 ? head : jar;
          final k = (b.t / 1.1).clamp(0.0, 1.0);
          final e = k * k * (3 - 2 * k);
          b.pos
            ..setFrom(b.from + (to - b.from) * e)
            ..y -= math.sin(k * math.pi) * 26;
          b.face = to.x >= b.from.x ? 1 : -1;
          if (k >= 1) b.start(to, 2);
        case 2:
          b.pos.setFrom(b.id == 0 ? head : jar);
          // Arada bir yön değiştirir, gagalar.
          if (b.t > 1.3 + b.id * 0.4) {
            b.t = 0;
            b.face = -b.face;
            if (_rnd.nextDouble() < 0.35) {
              GameAudio.instance.play('bird', volume: 0.22, minGapMs: 700);
            }
          }
        case 3:
          // Ürküp uçar: yukarı ve yana, sonra tacına döner.
          b.pos
            ..x += b.face * 120 * dt
            ..y -= 150 * dt;
          if (b.t > 1.4) b.state = 0;
      }
      if ((b.state == 1 || b.state == 2) && (moving || !near)) {
        b.start(b.pos, 3);
        b.face = _rnd.nextBool() ? 1 : -1;
        _wait = 8;
        GameAudio.instance.play('bird', volume: 0.4, minGapMs: 150);
      }
    }
  }

  static final _rnd = math.Random();

  @override
  void render(Canvas canvas) {
    for (final b in _birds) {
      if (b.state == 0) continue;
      canvas.save();
      canvas.translate(b.pos.x, b.pos.y);
      canvas.scale(b.face * 1.35, 1.35);
      if (b.state == 2) {
        _perchedBird(canvas, b.t, b.id);
      } else {
        _flyingBird(canvas, b.t);
      }
      canvas.restore();
    }
  }

  static final _ink = Paint()..color = const Color(0xFF1A1410);
  static final _breast = Paint()..color = const Color(0xFFC8643A);

  /// Konmuş kuş: ayakları (0, 0), sağa bakar; gagalarken başı iner.
  static void _perchedBird(Canvas c, double t, int id) {
    final peck = t > 0.8 && t < 1.05 ? math.sin((t - 0.8) / 0.25 * math.pi) : 0;
    c.drawPath(
      Path()
        ..moveTo(-3, -3)
        ..lineTo(-8, -1)
        ..lineTo(-7.5, -3.6)
        ..close(),
      _ink,
    );
    c.drawOval(const Rect.fromLTWH(-4.5, -6.5, 8.5, 5.5), _ink);
    if (id == 0) {
      c.drawOval(const Rect.fromLTWH(0, -5, 3.6, 3.4), _breast);
    }
    final hx = 3.0 + peck * 1.5;
    final hy = -7.0 + peck * 3;
    c.drawCircle(Offset(hx, hy), 2.4, _ink);
    c.drawPath(
      Path()
        ..moveTo(hx + 2, hy - 0.6)
        ..lineTo(hx + 4.6, hy + 0.3)
        ..lineTo(hx + 2, hy + 0.9)
        ..close(),
      Paint()..color = const Color(0xFFE0A040),
    );
    c.drawCircle(
      Offset(hx + 0.8, hy - 0.6),
      0.55,
      Paint()..color = const Color(0xFFFFF4D0),
    );
    c.drawLine(
      const Offset(-0.5, -1.2),
      const Offset(-0.5, 0),
      Paint()
        ..color = const Color(0xFF1A1410)
        ..strokeWidth = 0.7,
    );
  }

  /// Uçan kuş: kanat çırpar.
  static void _flyingBird(Canvas c, double t) {
    final flap = math.sin(t * 28);
    c.drawOval(const Rect.fromLTWH(-4, -2.5, 8, 4.5), _ink);
    c.drawCircle(const Offset(4, -2), 2.1, _ink);
    final wing = Path()
      ..moveTo(-1.5, -1)
      ..quadraticBezierTo(-3, -6 * flap - 1, -7, -8 * flap)
      ..lineTo(1.5, -1)
      ..close();
    c.drawPath(wing, _ink);
  }
}

class _Bird {
  _Bird(this.id);

  final int id;

  /// 0 tacında, 1 iniyor, 2 konmuş, 3 uçup gidiyor.
  int state = 0;
  double t = 0;
  int face = 1;
  final pos = Vector2.zero();
  final from = Vector2.zero();

  void start(Vector2 at, int s) {
    from.setFrom(at);
    pos.setFrom(at);
    state = s;
    t = 0;
  }
}

// ------------------------------------------------- Karagöz ile Hacivat (N4)

/// Bölümde küçük bir Karagöz perdesi: önünde durunca kandil parlar,
/// Karagöz ile Hacivat sözsüz bir güldürü oynar, sonunda ikisi birden bir
/// yeri gösterir (kamera oraya bakar): gizli oda ya da neşe parkuru.
class KaragozSahne extends PositionComponent with HasGameReference<GolgeGame> {
  KaragozSahne(Vector2 feet, this.target) : super(position: feet, priority: 3);

  /// Gösterdikleri yer (dünya); yoksa bölümün ilerisini gösterirler.
  final Vector2? target;

  static const double screenW = 130;
  static const double screenH = 96;
  static const double lift = 22;

  double _t = 0;
  double? _show;
  double _still = 0;
  double _wait = 0;
  double _lamp = 0;

  /// Gösteri oynuyor mu.
  bool get playing => _show != null;

  int get _point {
    final t = target;
    if (t == null) return 1;
    return t.x >= position.x ? 1 : -1;
  }

  /// Perde ve çerçevesi (dünya): öndeki süs şekilleri onu örtmesin.
  Rect get screenRect => Rect.fromLTWH(
    position.x - screenW / 2 - 8,
    position.y - lift - screenH - 9,
    screenW + 16,
    screenH + lift + 9,
  );

  /// Karanlıkta perde seçilsin: perdenin ortası.
  Offset get glowCenter => Offset(position.x, position.y - lift - screenH / 2);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _wait = math.max(0, _wait - dt);
    final p = game.player;
    final show = _show;
    final near =
        p != null &&
        !p.isDead &&
        (p.center.x - position.x).abs() < 4 * kTile &&
        (p.center.y - position.y).abs() < 3 * kTile;
    _lamp = approach(_lamp, near || show != null ? 1 : 0, dt, 0.4);
    if (show == null) {
      final still = near && p.velocity.x.abs() < 20 && p.onGround;
      _still = still && game.calmMoment ? _still + dt : 0;
      if (_still > 0.8 && _wait <= 0) {
        _show = 0;
        GameAudio.instance.play('match', volume: 0.35);
      }
      return;
    }
    final prev = show;
    final now = show + dt;
    _show = now;
    bool at(double s) => prev < s && now >= s;
    if (at(0.3)) GameAudio.instance.play('clap', volume: 0.25);
    if (at(3.9)) GameAudio.instance.play('drum', volume: 0.55);
    if (at(4.0)) GameAudio.instance.play('creak', volume: 0.3);
    if (at(6.5)) {
      final t = target;
      if (t != null) {
        final view = game.camera.visibleWorldRect.deflate(kTile * 2);
        if (!view.contains(t.toOffset())) game.focus(t, hold: 1.6);
        game.world.add(_PointMark(t));
      }
    }
    if (now >= karagozLength) {
      _show = null;
      _wait = 25;
      _still = 0;
      GameAudio.instance.play('clap', volume: 0.6);
      if (!game.secretSeen('karagoz')) game.foundSecret('karagoz');
    }
  }

  @override
  void render(Canvas canvas) {
    final screen = Rect.fromLTWH(
      -screenW / 2,
      -lift - screenH,
      screenW,
      screenH,
    );
    final wood = Paint()..color = const Color(0xFF3A2414);
    // Ayaklar ve üst kiriş.
    for (final x in [-screenW / 2 - 4, screenW / 2]) {
      canvas.drawRect(
        Rect.fromLTWH(x, -lift - screenH - 6, 4, screenH + lift + 6),
        wood,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(-screenW / 2 - 8, -lift - screenH - 9, screenW + 16, 5),
      wood,
    );
    // Perde (ayna): arkadan kandille aydınlanan ak bez.
    final flick = 0.9 + 0.1 * math.sin(_t * 9) * math.sin(_t * 3.3);
    final lit = (0.35 + 0.65 * _lamp) * flick;
    canvas.drawRect(
      screen,
      Paint()
        ..shader = Gradient.radial(
          screen.center.translate(0, screenH * 0.2),
          screenW * 0.7,
          [
            Color.lerp(const Color(0xFF6A4A2A), const Color(0xFFF6DDA8), lit)!,
            Color.lerp(const Color(0xFF3A2818), const Color(0xFFD69A58), lit)!,
          ],
        ),
    );
    // Perdenin altındaki pervaz (tasvirler buna basar).
    canvas.drawRect(
      Rect.fromLTWH(-screenW / 2, -lift - 6, screenW, 6),
      Paint()..color = const Color(0xFF5A3A20),
    );
    canvas.save();
    canvas.clipRect(screen);
    final show = _show;
    // Beklerken iki tasvir perdenin iki ucunda durur.
    paintKaragozHacivat(
      canvas,
      Offset(0, -lift - 6),
      68,
      show ?? 1.0,
      point: _point,
      a: show == null ? 0.55 + 0.35 * _lamp : 1,
    );
    canvas.restore();
    canvas.drawRect(
      screen,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF2A180C),
    );
  }
}

/// Karagöz ile Hacivat'ın gösterdiği yerde ılık, genişleyen halkalar.
class _PointMark extends PositionComponent {
  _PointMark(Vector2 at) : super(position: at.clone(), priority: 30);

  double _t = 0;
  static const double life = 4;

  @override
  void update(double dt) {
    _t += dt;
    if (_t > life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final fade = math.min(1.0, _t / 0.3) * math.min(1.0, (life - _t) / 0.8);
    glowDot(canvas, Offset.zero, 40, kWarmLight, 0.3 * fade);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 2; i++) {
      final k = (_t * 0.8 + i * 0.5) % 1.0;
      ring.color = kWarmLight.withValues(alpha: 0.7 * (1 - k) * fade);
      canvas.drawCircle(Offset.zero, 12 + 28 * k, ring);
    }
  }
}
