// Yeni Sâye (A1): A1 çiziminin kendi parçalarından kesik kâğıt kukla.
// Parçalar tek bir duruş koordinatında (assets/kukla/saye_a1.json); kol,
// bacak, etek ve örgü "deri giydirme" ile eklemde yumuşakça bükülür (dikiş
// yok); örgü, atkı uçları, etek ve kavanozun ipi yaylı fizikle oynar;
// bacaklar ayağın yerine göre çözülür (topuk basar, ağırlık ayağa biner,
// parmak iter). Önizleme araçları (tools/preview/kukla*_test.dart) da
// buradaki parçaları kullanır.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;

typedef V = ui.Offset;

/// 2B dönüşüm: x' = a·x + c·y + tx, y' = b·x + d·y + ty.
class Af {
  const Af(this.a, this.b, this.c, this.d, this.tx, this.ty);
  final double a, b, c, d, tx, ty;
  Af operator *(Af o) => Af(
    a * o.a + c * o.b,
    b * o.a + d * o.b,
    a * o.c + c * o.d,
    b * o.c + d * o.d,
    a * o.tx + c * o.ty + tx,
    b * o.tx + d * o.ty + ty,
  );
  static Af t(V p) => Af(1, 0, 0, 1, p.dx, p.dy);
  static Af r(double th) =>
      Af(math.cos(th), math.sin(th), -math.sin(th), math.cos(th), 0, 0);
  static Af s(double k) => Af(k, 0, 0, k, 0, 0);

  /// Duruştaki [rest] noktası dünyada [at]'a gelir, [th] kadar döner.
  static Af bone(V at, double th, double k, V rest) =>
      t(at) * r(th) * s(k) * t(-rest);
  V call(V p) => V(a * p.dx + c * p.dy + tx, b * p.dx + d * p.dy + ty);
}

double sm(double v) {
  final c = v.clamp(0.0, 1.0);
  return c * c * (3 - 2 * c);
}

double ang(V v) => math.atan2(v.dy, v.dx);
V rot(V v, double th) => V(
  v.dx * math.cos(th) - v.dy * math.sin(th),
  v.dx * math.sin(th) + v.dy * math.cos(th),
);

/// Bir katman: halkaları ve her köşenin kemik ağırlıkları.
class Layer {
  Layer(this.rings, this.color, this.weights);
  final List<List<V>> rings;
  final ui.Color color;
  final List<List<List<(int, double)>>> weights;

  ui.Path path(List<Af> bones) {
    // Deliği olan parçalar (etek oymaları) çift-tek kuralıyla; ötekiler
    // kendi üstüne katlanınca delik açılmasın diye sıfır-olmayan kuralla.
    final p = ui.Path()
      ..fillType = rings.length > 1
          ? ui.PathFillType.evenOdd
          : ui.PathFillType.nonZero;
    for (var r = 0; r < rings.length; r++) {
      final pts = <V>[];
      for (var i = 0; i < rings[r].length; i++) {
        var x = 0.0, y = 0.0;
        for (final (b, w) in weights[r][i]) {
          final q = bones[b](rings[r][i]);
          x += q.dx * w;
          y += q.dy * w;
        }
        pts.add(V(x, y));
      }
      p.addPolygon(pts, true);
    }
    return p;
  }
}

/// Zincirin (örgü, atkı) yaylı fiziği: uçlar ağırlıkla sarkar, köke geç
/// tepki verir; duruştaki biçimine doğru yumuşakça çekilir.
class Chain {
  Chain(this.rest, this.stiff);
  final List<V> rest;
  final List<double> stiff;
  List<V>? p, prev;

  void step(Af parent, double k, double dt, V gravity, V wind) {
    final target = [for (final r in rest) parent(r)];
    p ??= List.of(target);
    prev ??= List.of(target);
    final pp = p!, pv = prev!;
    pp[0] = target[0];
    pv[0] = target[0];
    for (var i = 1; i < pp.length; i++) {
      final v = (pp[i] - pv[i]) * 0.9;
      pv[i] = pp[i];
      pp[i] = pp[i] + v + (gravity + wind) * (dt * dt);
    }
    for (var it = 0; it < 4; it++) {
      for (var i = 1; i < pp.length; i++) {
        // Biçimine dön: kendi kolunun duruştaki yönüne göre.
        final restDir = rest[i] - rest[i - 1];
        final parentRot = i == 1
            ? ang(target[1] - target[0]) - ang(rest[1] - rest[0])
            : ang(pp[i - 1] - pp[i - 2]) - ang(rest[i - 1] - rest[i - 2]);
        final want = pp[i - 1] + rot(restDir, parentRot) * k;
        pp[i] = pp[i] + (want - pp[i]) * stiff[i];
        // Boyu sabit.
        final d = pp[i] - pp[i - 1];
        final len = restDir.distance * k;
        pp[i] = pp[i - 1] + d / d.distance * len;
      }
    }
  }

  /// Her kolun dönüşümü.
  List<Af> bones(double k) => [
    for (var i = 0; i + 1 < rest.length; i++)
      Af.bone(
        p![i],
        ang(p![i + 1] - p![i]) - ang(rest[i + 1] - rest[i]),
        k,
        rest[i],
      ),
  ];
}

/// Çoklu çizgi üzerinde en yakın noktanın baştan uzaklığı.
double along(List<V> line, V v) {
  var best = double.infinity, at = 0.0, acc = 0.0;
  for (var i = 0; i + 1 < line.length; i++) {
    final a = line[i], b = line[i + 1];
    final ab = b - a;
    final t =
        (((v - a).dx * ab.dx + (v - a).dy * ab.dy) /
                (ab.dx * ab.dx + ab.dy * ab.dy))
            .clamp(0.0, 1.0);
    final q = a + ab * t;
    final d = (v - q).distance;
    if (d < best) {
      best = d;
      at = acc + ab.distance * t;
    }
    acc += ab.distance;
  }
  return at;
}

/// Zincir boyunca ağırlık: köşe hangi kolun üstündeyse onun, eklemlerde
/// komşusuyla karışık.
List<(int, double)> chainWeights(List<V> line, V v, int first, double band) {
  final u = along(line, v);
  var acc = 0.0;
  final joints = <double>[];
  for (var i = 0; i + 1 < line.length; i++) {
    acc += (line[i + 1] - line[i]).distance;
    joints.add(acc);
  }
  final n = line.length - 1;
  final w = List.filled(n, 0.0);
  var seg = 0;
  while (seg < n - 1 && u > joints[seg]) {
    seg++;
  }
  w[seg] = 1;
  // Eklemin iki yanında yumuşak geçiş.
  if (seg > 0) {
    final k = sm((u - (joints[seg - 1] - band)) / (2 * band));
    w[seg] = k;
    w[seg - 1] = 1 - k;
  }
  if (seg < n - 1 && u > joints[seg] - band) {
    final k = sm((u - (joints[seg] - band)) / (2 * band));
    final base = w[seg];
    w[seg] = base * (1 - k);
    w[seg + 1] = base * k;
  }
  return [
    for (var i = 0; i < n; i++)
      if (w[i] > 1e-4) (first + i, w[i]),
  ];
}

// ------------------------------------------------------------ oyundaki Sâye

/// Kuklayı süren oyuncu durumu (her karede Player doldurur).
class KuklaInput {
  /// Yerde mi, havada mı, tutunuyor mu, zincirde mi: [KuklaMode].
  KuklaMode mode = KuklaMode.ground;

  /// İleri doğru hız (bakış yönünde +) ve düşey hız, dünya birimi/sn.
  double forward = 0;
  double vy = 0;

  /// Çömelme (1), parmak ucu (0..1 arası hafif çöküş), itme.
  bool crouching = false;
  bool sneaking = false;
  bool pushing = false;

  /// Dizlerin kırılması (0..1; kayakta), çömelmeden ayrı: kavanoz saklanmaz.
  double bend = 0;

  /// Kavanozun örtülmesi (0..1): çömelince, saklanınca.
  double shield = 0;

  /// İniş çöküşü (sn, geri sayar) ve en büyük değeri.
  double landDip = 0;

  /// Tutunulan kenarın köşesi (ayak merkezine göre, bakış yönünde +x).
  V grip = V.zero;

  /// Kenara çıkışın ilerlemesi (0..1).
  double climb = 0;

  /// Tutunurken kendini ne kadar yukarı çekmiş (0: kollar gergin asılı, 1:
  /// dirsekler bükük, göğsü kenarda; alçak kenarlarda başı yukarıda kalsın).
  double pull = 0;

  /// Ayak merkezinin dünyadaki yüksekliği (zincirde el el üstüne tırmanış).
  double worldY = 0;

  /// Kavanozun ışığı (0..1) ve titreşim.
  double light = 1;

  /// Yüzüşte kulaç evresi (tam sayı = bir kulaç); boşsa kendi zamanıyla.
  double? stroke;
}

enum KuklaMode { ground, air, hang, climbUp, vine, swim }

class _Pose {
  _Pose({
    required this.hip,
    required this.lean,
    this.headA = 0,
    required this.fF,
    this.pF = 0,
    required this.fB,
    this.pB = 0,
    this.sf = 0,
    this.ef = 0,
    this.sb = 0.81,
    this.eb = 0.6,
  });
  V hip;
  double lean, headA;
  V fF;
  double pF;
  V fB;
  double pB;
  double sf, ef, sb, eb;

  _Pose lerp(_Pose o, double t) {
    double l(double a, double b) => a + (b - a) * t;
    return _Pose(
      hip: V.lerp(hip, o.hip, t)!,
      lean: l(lean, o.lean),
      headA: l(headA, o.headA),
      fF: V.lerp(fF, o.fF, t)!,
      pF: l(pF, o.pF),
      fB: V.lerp(fB, o.fB, t)!,
      pB: l(pB, o.pB),
      sf: l(sf, o.sf),
      ef: l(ef, o.ef),
      sb: l(sb, o.sb),
      eb: l(eb, o.eb),
    );
  }
}

/// Oyundaki Sâye kuklası: her oyuncunun kendi fiziği (örgü, atkı, etek,
/// kavanoz) ve adım evresi; parçalar bütün kuklalarda ortak.
class SayeKukla {
  // ------------------------------------------------------ ortak parçalar
  static const ink = ui.Color(0xFF07050F);
  static const red = ui.Color(0xFFC2402E);
  // Uzaktaki kol ve bacak bir ton açık: iki bacak birbirine karışmaz.
  static const far = ui.Color(0xFF1F1829);

  // Kemikler.
  static const _torso = 0, _skirt = 1, _head = 2;
  static const _upF = 3, _foF = 4, _upB = 5, _foB = 6;
  static const _thF = 7, _shF = 8, _ftF = 9, _thB = 10, _shB = 11, _ftB = 12;
  static const _braid0 = 13, _scarf0 = 18;
  // Duruştaki eklem yerleri.
  static const _hip0 = V(830, 1330);
  static const _neck = V(813, 705);
  static const _waist = V(845, 1050);
  static const _sF = V(905, 770), _eF = V(1085, 960), _hF = V(1420, 955);
  // Uzaktaki kol ve bacak öndekinin hemen ardında; bacaklar başın altında.
  static const _backArm = V(-55, 0),
      _nearLeg = V(-100, 0),
      _backLeg = V(-122, 0);
  static const _legH = V(900, 1330),
      _legK = V(921, 1540),
      _legA = V(957, 1732.5);
  // Tabanın yere değen iki ucu: topuğun dibi ve burnun altı.
  static const _toe = V(1110, 1892.5), _heel = V(925, 1892.5);
  static const _sole = 1892.5;

  /// Duruş çiziminden dünya birimine ölçek: Sâye ~36 birim boyunda (çarpışma
  /// kutusu 28; baş ve örgüler kutunun üstüne taşar).
  static const k = 0.021;

  /// Önizleme araçlarındaki (k = 0,24) piksel ölçüleri buraya: 1 px.
  static const _px = k / 0.24;

  static final Map<String, Layer> _layers = {};
  static List<V> _braidLine = const [];
  static List<V> _scarfLine = const [];
  static bool get ready => _layers.isNotEmpty;

  /// Son yükleme hatası (tanı için).
  static String? lastError;

  static final _lt = (_legK - _legH).distance, _ls = (_legA - _legK).distance;
  static final double _legLen = (_lt + _ls) * k;
  static final _upper = (_eF - _sF).distance, _fore = (_hF - _eF).distance;

  /// Ayakta kalçanın yüksekliği (ayak merkezine göre): dizler hafif kırık.
  static final double _standY = -(_sole - _legA.dy) * k - _legLen * 0.955;

  /// Kalçanın yatay yeri: ayaklar ayak merkezinin (kutunun ortasının)
  /// altında.
  static final double _hipX =
      -((_toe.dx + _heel.dx) / 2 - _hip0.dx + _nearLeg.dx) * k;

  static Future<void> load() async {
    if (ready) return;
    try {
      final data = jsonDecode(
        await rootBundle.loadString('assets/kukla/saye_a1.json'),
      ) as Map<String, dynamic>;
      _build(data);
    } catch (e) {
      lastError = '$e';
      _layers.clear();
    }
  }

  static void _build(Map<String, dynamic> data) {
    List<List<V>> ringsOf(dynamic j, [V shift = V.zero]) => [
      for (final r in j as List)
        [
          for (final q in r as List)
            V((q[0] as num).toDouble(), (q[1] as num).toDouble()) + shift,
        ],
    ];
    List<V> pts(dynamic j) => [
      for (final q in j as List)
        V((q[0] as num).toDouble(), (q[1] as num).toDouble()),
    ];
    final L = data['layers'] as Map<String, dynamic>;
    _braidLine = pts(data['braid']);
    _scarfLine = pts(data['scarf']);

    Layer layer(
      List<List<V>> rings,
      ui.Color color,
      List<(int, double)> Function(V) w,
    ) => Layer(rings, color, [
      for (final r in rings) [for (final v in r) w(v)],
    ]);

    List<(int, double)> limb(V v, List<V> line, int a, int b, double band) {
      final u = along(line, v);
      final j = (line[1] - line[0]).distance;
      final kk = sm((u - (j - band)) / (2 * band));
      return [if (kk < 1) (a, 1 - kk), if (kk > 0) (b, kk)];
    }

    List<(int, double)> leg(V v, V shift, int th, int sh, int ft) {
      final h = _legH + shift, kn0 = _legK + shift, a = _legA + shift;
      final foot = sm((v.dy - (a.dy - 25)) / 50);
      // Diz geniş bir alanda bükülür (kumaş gibi): bacağın boyu boyunca.
      final u = along([h, kn0, a], v);
      final j = (kn0 - h).distance;
      final kn = sm((u - (j - 120)) / 240);
      final out = <(int, double)>[];
      if ((1 - foot) * (1 - kn) > 0) out.add((th, (1 - foot) * (1 - kn)));
      if ((1 - foot) * kn > 0) out.add((sh, (1 - foot) * kn));
      if (foot > 0) out.add((ft, foot));
      return out;
    }

    _layers
      ..clear()
      ..addAll({
        'kolB': layer(
          ringsOf(L['kol'], _backArm),
          far,
          (v) => limb(
            v,
            [_sF + _backArm, _eF + _backArm, _hF + _backArm],
            _upB,
            _foB,
            40,
          ),
        ),
        'bacakB': layer(
          ringsOf(L['bacak'], _backLeg),
          far,
          (v) => leg(v, _backLeg, _thB, _shB, _ftB),
        ),
        'atki': layer(
          ringsOf(L['atki_uclar']),
          red,
          (v) => chainWeights(_scarfLine, v, _scarf0, 30),
        ),
        'orgu': layer(
          ringsOf(L['orgu']),
          ink,
          (v) => chainWeights(_braidLine, v, _braid0, 25),
        ),
        'kurdele': layer(
          ringsOf(L['kurdele']),
          red,
          (v) => chainWeights(_braidLine, v, _braid0, 25),
        ),
        'bacakF': layer(
          ringsOf(L['bacak'], _nearLeg),
          ink,
          (v) => leg(v, _nearLeg, _thF, _shF, _ftF),
        ),
        'govde': layer(ringsOf(L['govde']), ink, (v) {
          final kk = sm((v.dy - 1000) / 160);
          return [if (kk < 1) (_torso, 1 - kk), if (kk > 0) (_skirt, kk)];
        }),
        'bas': layer(ringsOf(L['bas']), ink, (v) => [(_head, 1)]),
        'goz': layer(
          ringsOf(data['eye']),
          const ui.Color(0xFFFFF1CF),
          (v) => [(_head, 1)],
        ),
        'dugum': layer(ringsOf(L['atki_dugum']), red, (v) => [(_torso, 1)]),
        'kolF': layer(
          ringsOf(L['kol']),
          ink,
          (v) => limb(v, [_sF, _eF, _hF], _upF, _foF, 40),
        ),
      });
  }

  static const _order = [
    'kolB',
    'bacakB',
    'atki',
    'orgu',
    'kurdele',
    'bacakF',
    'govde',
    'bas',
    'dugum',
    'kolF',
  ];

  // ------------------------------------------------------ kuklanın kendisi
  Chain? _braid, _scarf;
  double _skirtA = 0, _skirtV = 0;
  double _jarA = 0, _jarV = 0;
  V _prevHand = V.zero;
  V _handVel = V.zero;
  double _walked = 0;
  double _prevForward = 0;
  bool _fresh = true;
  double _time = 0;

  // Adım evresi, adımın genliği (durunca ayaklar birleşir), koşu payı.
  double _q = 0;
  double _amp = 0;
  double _run = 0;
  double _crouch = 0;
  double _hideArm = 0;
  double _push = 0;
  double _climbed = 0;
  double? _prevWorldY;

  // Hâller arası geçiş.
  KuklaMode? _mode;
  _Pose? _from;
  _Pose? _shown;
  double _blendT = 1;
  double _blendDur = 0.1;

  // Son karenin kemikleri, kavanozu, ışığı.
  List<Af> _bones = const [];
  V _jar = V.zero;
  double _light = 1;
  double _hide = 0;

  /// Kavanozun yeri (ayak merkezine göre, bakış yönünde +x).
  V get jar => _jar;

  /// Omuz (ayak merkezine göre, bakış yönünde +x): kanatlar buraya takılır.
  V get shoulder => _bones.isEmpty ? V(0, _standY - 11) : _bones[_torso](_sF);

  /// Ayakların topuğu ve parmak ucu (ayak merkezine göre): yere basan uç
  /// kaymaz (testler).
  List<V> get soles => _bones.length > _ftB
      ? [
          _bones[_ftF](_heel + _nearLeg),
          _bones[_ftF](_toe + _nearLeg),
          _bones[_ftB](_heel + _backLeg),
          _bones[_ftB](_toe + _backLeg),
        ]
      : const [];

  static double _approach(double v, double to, double dt, double secs) =>
      v + (to - v) * (1 - math.exp(-dt / secs));

  // Ayağın yerdeki noktası: duruşta parmak ucu ve topuk zeminde.
  static double _footX(V shift) => _hipX + (_toe.dx - _hip0.dx + shift.dx) * k;
  static V _onToe(double xt, double y, double p) =>
      V(xt, y) + rot(_legA - _toe, p) * k;
  static V _onHeel(double xh, double y, double p) =>
      V(xh, y) + rot(_legA - _heel, p) * k;

  /// Adımın [ph] evresinde ayak (bilek ve eğim): yerdeyken dünyayla aynı
  /// yerde durur (topuk değer, düzleşir, parmak iter); havada parmağın
  /// kalktığı yerden topuğun değeceği yere kesintisiz bir yay çizer.
  (V, double) _gaitFoot(
    double ph,
    V shift,
    double g,
    double stance,
    double e,
    double run,
    double rest, [
    double liftK = 1,
  ]) {
    final heelBack = (_toe.dx - _heel.dx) * k;
    final base = _footX(shift) - 4 * _px + rest;
    if (ph < stance) {
      final u = ph / stance;
      final xt = base + g / 2 - g * u;
      if (u < 0.12) {
        final p = -0.22 * (1 - sm(u / 0.12)) * e;
        return (_onHeel(xt - heelBack, 0, p), p);
      }
      final p = 0.55 * sm((u - 0.62) / 0.38) * e;
      return (_onToe(xt, 0, p), p);
    }
    final u = (ph - stance) / (1 - stance);
    // Koşuda arka bacak topuğunu erken ve yukarı teper.
    final lift =
        math.pow(math.sin(math.pi * math.pow(u, 1 - 0.3 * run)), 0.8) *
        _legLen *
        (0.11 + 0.25 * run) *
        liftK *
        e;
    final p = (0.55 * (1 - sm(u / 0.5)) - 0.22 * sm((u - 0.5) / 0.5)) * e;
    // Yay dünyada ve basan uçtan çizilir: kalkışta parmak ucu yerinde kalır,
    // topuk onun çevresinde döner, ayak önce kalkar sonra ilerler; inişte
    // önce yerine gelir, topuk dikine basar. Ayak yere göre durur, gövdeye
    // göre geri akar (yoksa basmadan önce ileri kayar, kalkarken sürtünür).
    final travel = g * (1 - stance) / stance;
    final c0 = base - g / 2, c1 = base + g / 2 - heelBack;
    final h = sm((u - 0.12) / 0.62);
    final cx = c0 + (c1 + travel - c0) * h - travel * u;
    final ankle = V.lerp(
      _onToe(cx, -lift, p),
      _onHeel(cx, -lift, p),
      sm((u - 0.3) / 0.6),
    )!;
    return (ankle, p);
  }

  _Pose _ground(KuklaInput i, double dt) {
    final v = i.forward.abs();
    // Yavaş giderken de belirgin yürüyüş (perdede ağır yürüyüş): adım
    // kısalır ama saniyede iki adımın altına inmez, kollar yine sallanır.
    _amp = _approach(_amp, (v / 4).clamp(0.0, 1.0), dt, 0.06);
    _run = _approach(_run, ((v - 60) / 80).clamp(0.0, 1.0), dt, 0.15);
    _crouch = _approach(
      _crouch,
      i.crouching ? 1 : math.max(i.bend, i.sneaking ? 0.22 : 0),
      dt,
      0.08,
    );
    _hideArm = _approach(_hideArm, i.crouching ? 1 : 0, dt, 0.08);
    _push = _approach(_push, i.pushing ? 1 : 0, dt, 0.1);
    final e = _amp, run = _run, kk = _crouch;
    // Yerdeki ayak menzili; küçük çocuk hızlı ve kısa adımlarla gider.
    final gBase = _legLen * (0.85 + 0.2 * run - 0.3 * kk - 0.1 * _push);
    final st0 = 0.58 - 0.36 * run;
    final g = math.min(gBase, v * st0 / 0.9) * e;
    // Kısa adımda ayak da az kalkar.
    final size = gBase > 0 ? (g / gBase).clamp(0.0, 1.0) : 0.0;
    var cad = 0.0;
    var stance = st0;
    if (v > 1 && g > 0.05) {
      cad = math.min(4.4, v * st0 / g);
      stance = (g * cad / v).clamp(0.14, 0.7);
    }
    // Geri geri yürüyüşte evre tersine akar.
    _q = (_q + cad * dt * (i.forward < 0 ? -1 : 1)) % 1.0;
    final q = _q, qB = (q + 0.5) % 1.0;
    final fF = _gaitFoot(
      q,
      _nearLeg,
      g,
      stance,
      e,
      run,
      -6 * _px * (1 - e),
      0.45 + 0.55 * size,
    );
    final fB = _gaitFoot(
      qB,
      _backLeg,
      g,
      stance,
      e,
      run,
      4 * _px * (1 - e),
      0.45 + 0.55 * size,
    );
    final two = math.cos(4 * math.pi * (q - stance / 2));
    final bob = (run < 0.5 ? two * 4.5 : -two * 5.5) * _px;
    final breath = math.sin(_time * 2.6) * 1.2 * _px * (1 - e);
    final dip = sm(i.landDip / 0.16);
    final farFwd = math.sin(2 * math.pi * (q - 0.07));
    final nearFwd = -math.sin(2 * math.pi * (q - 0.05));
    // Gövde dik; koşuda biraz öne eğilir; çömelince ve iterken öne.
    final lean =
        (0.02 + 0.13 * run + 0.008 * two) * e +
        0.025 +
        0.3 * kk +
        0.3 * _push +
        0.25 * dip;
    final hipY =
        _standY -
        bob * e +
        _legLen * 0.04 * run * e -
        breath +
        kk * _legLen * 0.5 +
        dip * 40 * _px;
    // Bacak basan ayağa yetişmeli (yetişmezse ayak kayar, havada kalır):
    // adım açıldıkça kalça alçalır, gerçek yürüyüşteki gibi.
    final hipX = _hipX - 14 * _px * kk;
    var y = hipY;
    for (final (f, shift) in [(fF.$1, _nearLeg), (fB.$1, _backLeg)]) {
      final legHip = V(hipX, 0) + rot(_legH + shift - _hip0, lean) * k;
      final dx = f.dx - legHip.dx;
      final reach = _legLen * 0.985;
      if (dx.abs() < reach) {
        y = math.max(y, f.dy - legHip.dy - math.sqrt(reach * reach - dx * dx));
      }
    }
    var pose = _Pose(
      hip: V(hipX, y),
      lean: lean,
      headA:
          (-0.035 - 0.012 * two + 0.03 * run) * e +
          math.sin(_time * 1.1) * 0.02 * (1 - e) +
          0.28 * kk -
          0.2 * _push,
      fF: fF.$1 + V(14 * _px * kk, 0),
      pF: fF.$2,
      fB: fB.$1 - V(8 * _px * kk, 0),
      pB: fB.$2 + 0.15 * kk * (1 - e),
      // Uzaktaki kol geride, adımla salınır; kavanozlu kol dirsekten
      // bükülü, kavanoz kalçanın önünde alçakta.
      sb:
          0.81 +
          (0.75 - 0.15 * run) * e -
          (farFwd > 0 ? 0.15 + 0.2 * run : 0.3 + 0.2 * run) * farFwd * e +
          math.sin(_time * 2.6) * 0.02 * (1 - e),
      eb: 0.6 + (0.3 - 0.9 * run) * e - 0.2 * math.max(0, farFwd) * e,
      sf: (-0.2 + 0.5 * run) * e - (0.08 + 0.2 * run) * nearFwd * e,
      ef: (1.3 - 1.1 * run) * e,
    );
    // Çömelince kavanozu göğsüne saklar.
    if (_hideArm > 0.001) {
      final hide = sm(_hideArm / 0.8);
      pose
        ..sf += (0.55 - pose.sf) * hide
        ..ef += (-2.25 - pose.ef) * hide
        ..sb += (0.81 - 1.7 - pose.sb) * hide
        ..eb += (0.6 - 1.5 - pose.eb) * hide;
    }
    // İterken iki el sandıkta.
    if (_push > 0) {
      final p = _push;
      pose
        ..sf += (-0.35 - pose.sf) * p
        ..ef += (0.55 - pose.ef) * p
        ..sb += (-0.25 - pose.sb) * p
        ..eb += (0.5 - pose.eb) * p;
    }
    return pose;
  }

  _Pose _air(KuklaInput i) {
    // Kalkışta bacaklar uzanır, tepede toplanır, düşerken inişe açılır.
    final tuck = 1 - (i.vy.abs() / 700).clamp(0.0, 1.0);
    final rise = (-i.vy / 580).clamp(0.0, 1.0);
    final fall = (i.vy / 700).clamp(0.0, 1.0);
    final reach = _legLen * (0.97 - 0.36 * tuck);
    final hipY = -(_sole - _legA.dy) * k - reach;
    final fwd = (i.forward.abs() / 160).clamp(0.0, 1.0);
    // Bilek: uzanınca taban kutunun dibinde.
    V foot(V shift, double ahead) {
      final hx = _hipX + (_legH.dx - _hip0.dx + shift.dx) * k;
      return V(hx + (ahead * tuck + 6) * _px, hipY + reach);
    }

    final aF = foot(_nearLeg, 26 + 10 * fwd);
    final aB = foot(_backLeg, -4 - 10 * fwd);
    return _Pose(
      hip: V(_hipX, hipY),
      lean: 0.03 - 0.04 * tuck + 0.08 * fwd,
      headA: 0.06 * tuck - 0.05 * fall,
      fF: aF,
      pF: -0.2 * tuck + 0.15 * fall,
      fB: aB,
      pB: 0.35 * tuck + 0.2 * fall,
      sb: 0.81 - 2.0 * sm(rise * 1.6) - 0.9 * fall,
      eb: 0.6 - 0.5 * tuck,
      sf: -0.4 * tuck - 0.5 * fall,
      ef: 0.1 * tuck + 0.3 * fall,
    );
  }

  /// İki kemikli kolun açıları: el [hand]a uzanır (dirsek [elbow] yönüne).
  (double, double) _armTo(V shoulder, V hand, double lean, double elbow) {
    final l1 = _upper * k, l2 = _fore * k;
    var d = hand - shoulder;
    final dist = d.distance.clamp((l1 - l2).abs() + 0.01, l1 + l2 - 0.01);
    d = d / d.distance * dist;
    final alpha = math.acos(
      ((l1 * l1 + dist * dist - l2 * l2) / (2 * l1 * dist)).clamp(-1.0, 1.0),
    );
    final th = ang(d) + elbow * alpha;
    final elbowAt = shoulder + V(math.cos(th), math.sin(th)) * l1;
    final th2 = ang(shoulder + d - elbowAt);
    final sf = th - ang(_eF - _sF) - lean;
    final ef = th2 - ang(_hF - _eF) - lean - sf;
    return (sf, ef);
  }

  V _shoulder(V hip, double lean, V off) =>
      hip + rot(_sF + off - _hip0, lean) * k;

  _Pose _hang(KuklaInput i) {
    // Kenara asılı: eller köşede, gövde altında sarkar, bacaklar sallanır.
    final grip = i.grip + const V(0.6, 0.3);
    const lean = -0.06;
    final reach = (_upper + _fore) * k * 0.94;
    final shoulder =
        grip + V(-1.6 - 1.2 * i.pull, reach * 0.98 * (1 - 0.7 * i.pull));
    final hip = shoulder - rot(_sF - _hip0, lean) * k;
    final (sf, ef) = _armTo(_shoulder(hip, lean, V.zero), grip, lean, -1);
    final (sb, eb) = _armTo(
      _shoulder(hip, lean, _backArm),
      grip - const V(0.8, 0),
      lean,
      -1,
    );
    final sway = math.sin(_time * 2.4) * 1.2;
    final hx = hip.dx + (_legH.dx - _hip0.dx) * k;
    final drop = hip.dy + _legLen * 0.9;
    return _Pose(
      hip: hip,
      lean: lean,
      headA: -0.12,
      fF: V(hx + 1.2 + sway, drop),
      pF: 0.5,
      fB: V(hx - 0.4 - sway * 0.7, drop - 0.8),
      pB: 0.6,
      sf: sf,
      ef: ef,
      sb: sb,
      eb: eb,
    );
  }

  _Pose _climbUp(KuklaInput i, double dt) {
    // Önce kollarla çekinir, sonra dizini kenara atıp üstüne çıkar: eller
    // köşede kalır, gövde yükselip öne geçer.
    final c = i.climb;
    final over = sm((c - 0.4) / 0.5);
    final hang = _hang(i);
    final up = _ground(KuklaInput()..crouching = true, dt);
    final pose = hang.lerp(up, over);
    final grip = i.grip + const V(0.6, 0.3);
    final (sf, ef) = _armTo(
      _shoulder(pose.hip, pose.lean, V.zero),
      grip,
      pose.lean,
      over > 0.3 ? 1 : -1,
    );
    final (sb, eb) = _armTo(
      _shoulder(pose.hip, pose.lean, _backArm),
      grip - const V(0.8, 0),
      pose.lean,
      over > 0.3 ? 1 : -1,
    );
    final let = sm((c - 0.8) / 0.2);
    pose
      ..sf = sf + (pose.sf - sf) * let
      ..ef = ef + (pose.ef - ef) * let
      ..sb = sb + (pose.sb - sb) * let
      ..eb = eb + (pose.eb - eb) * let;
    return pose;
  }

  _Pose _vine(KuklaInput i) {
    // Zincirde el el üstüne: tutan el zincirle birlikte aşağı iner, öteki
    // yukarı uzanıp yeniden tutar; ayaklar da yarım adım geriden.
    const reach = 4.6;
    final s = _climbed / reach;
    double grip(double ph, double top) {
      final u = ph % 2;
      return u < 1 ? top + u * reach : top + reach - sm(u - 1) * reach;
    }

    const lean = -0.04;
    final hip = V(-4.8, _standY - 2.4);
    final hA = V(0.2, grip(s, -32));
    final hB = V(-0.4, grip(s + 1, -32));
    final (sf, ef) = _armTo(_shoulder(hip, lean, V.zero), hA, lean, -1);
    final (sb, eb) = _armTo(_shoulder(hip, lean, _backArm), hB, lean, -1);
    return _Pose(
      hip: hip,
      lean: lean,
      headA: -0.08,
      fF: _onToe(0.6, grip(s + 0.5, -6.5), 0.35),
      pF: 0.35,
      fB: _onToe(-0.2, grip(s + 1.5, -6.5), 0.45),
      pB: 0.45,
      sf: sf,
      ef: ef,
      sb: sb,
      eb: eb,
    );
  }

  _Pose _swim(KuklaInput i) {
    // Poz dik gövdeye göre (gövde sonra yüzüş yönüne yatar: yukarısı ileri).
    // Kavanozlu kol ileri uzanır, öteki kol kürek çeker; ayaklar çırpar.
    final pace = (i.forward.abs() / 145).clamp(0.0, 1.0);
    final st = i.stroke;
    // Kulaç verilirse kollar ve ayaklar ona göre: kollar öne uzanıp geri
    // çekilirken ayaklar iki kez çırpar.
    final kick = st != null
        ? math.sin(4 * math.pi * st) * 1.1
        : math.sin(_time * (5 + 6 * pace)) * (0.6 + 1.6 * pace);
    final row = st != null
        ? math.sin(2 * math.pi * st)
        : math.sin(_time * (2.2 + 2.5 * pace));
    final hip = V(_hipX, _standY);
    final hx = hip.dx + (_legH.dx - _hip0.dx) * k;
    final drop = hip.dy + _legLen * 0.93;
    return _Pose(
      hip: hip,
      lean: 0,
      headA: -0.15,
      fF: V(hx + 0.8 + kick, drop),
      pF: 0.9,
      fB: V(hx - 0.6 - kick, drop - 0.3),
      pB: 0.9,
      sf: -1.75 + 0.25 * row,
      ef: 0.25,
      sb: 0.81 + 0.4 + 0.5 * row,
      eb: 0.3,
    );
  }

  // İki kemik bacak (diz öne).
  (Af, Af, Af) _leg(Af torsoM, V shift, V ankle, double pitch) {
    final h = torsoM(_legH + shift);
    final l1 = _lt * k, l2 = _ls * k;
    var d = ankle - h;
    final dist = d.distance.clamp((l1 - l2).abs() + 0.01, l1 + l2 - 0.01);
    d = d / d.distance * dist;
    final alpha = math.acos(
      ((l1 * l1 + dist * dist - l2 * l2) / (2 * l1 * dist)).clamp(-1.0, 1.0),
    );
    final th = ang(d) - alpha;
    final knee = h + V(math.cos(th), math.sin(th)) * l1;
    final sh = ang(h + d - knee);
    return (
      Af.bone(h, th - ang(_legK - _legH), k, _legH + shift),
      Af.bone(knee, sh - ang(_legA - _legK), k, _legK + shift),
      Af.bone(h + d, pitch, k, _legA + shift),
    );
  }

  /// Bir kare ilerler: pozu seçer, hâl değişince eskisinden yumuşakça geçer,
  /// yaylı parçaları oynatır.
  void step(double dt, KuklaInput i) {
    if (!ready || dt <= 0) return;
    _time += dt;
    if (_prevWorldY != null && i.mode == KuklaMode.vine) {
      _climbed += _prevWorldY! - i.worldY;
    }
    _prevWorldY = i.worldY;
    final target = switch (i.mode) {
      KuklaMode.ground => _ground(i, dt),
      KuklaMode.air => _air(i),
      KuklaMode.hang => _hang(i),
      KuklaMode.climbUp => _climbUp(i, dt),
      KuklaMode.vine => _vine(i),
      KuklaMode.swim => _swim(i),
    };
    if (i.mode != _mode) {
      if (_shown != null) {
        _from = _shown;
        _blendT = 0;
        _blendDur = switch (i.mode) {
          KuklaMode.hang => 0.08,
          KuklaMode.climbUp => 0.05,
          KuklaMode.air => 0.1,
          KuklaMode.vine => 0.12,
          KuklaMode.swim => 0.25,
          KuklaMode.ground => _mode == KuklaMode.climbUp ? 0.12 : 0.07,
        };
      }
      _mode = i.mode;
    }
    _blendT += dt;
    final pose = _from == null || _blendT >= _blendDur
        ? target
        : _from!.lerp(target, sm(_blendT / _blendDur));
    _shown = pose;

    // Fizik: ileri hız ve ivme (dünyada; kukla yerinde durur, dünya akar).
    final vel = V(i.forward, i.vy);
    final acc = _fresh ? 0.0 : (i.forward - _prevForward) / dt;
    _prevForward = i.forward;
    _walked += i.forward * dt;
    final torsoM = Af.bone(pose.hip, pose.lean, k, _hip0);
    // Etek: ivmeye geç tepki verir, gövdenin ardında salınır.
    final skirtTarget = (-acc * 0.00008 - vel.dx * 0.0003).clamp(-0.25, 0.25);
    _skirtV += ((skirtTarget - _skirtA) * 140 - _skirtV * 9) * dt;
    _skirtA += _skirtV * dt;
    final skirtM = Af.bone(torsoM(_waist), pose.lean + _skirtA, k, _waist);
    final headM = Af.bone(torsoM(_neck), pose.lean + pose.headA, k, _neck);
    final uF = Af.bone(torsoM(_sF), pose.lean + pose.sf, k, _sF);
    final fFm = Af.bone(uF(_eF), pose.lean + pose.sf + pose.ef, k, _eF);
    final uB = Af.bone(
      torsoM(_sF + _backArm),
      pose.lean + pose.sb,
      k,
      _sF + _backArm,
    );
    final fBm = Af.bone(
      uB(_eF + _backArm),
      pose.lean + pose.sb + pose.eb,
      k,
      _eF + _backArm,
    );
    final (tF, s2F, ftFm) = _leg(torsoM, _nearLeg, pose.fF, pose.pF);
    final (tB, s2B, ftBm) = _leg(torsoM, _backLeg, pose.fB, pose.pB);
    // Saç ve atkı: yerçekimi, koşunca ve düşerken karşıdan gelen rüzgâr.
    _braid ??= Chain(_braidLine, [0, 0.5, 0.32, 0.22, 0.16, 0.12]);
    _scarf ??= Chain(_scarfLine, [0, 0.35, 0.22, 0.14]);
    final wind = V(
      (-vel.dx * 0.55).clamp(-110.0, 110.0),
      (-vel.dy * 0.12).clamp(-60.0, 60.0),
    );
    _braid!.step(headM, k, dt, const V(0, 900 * _px), wind);
    _scarf!.step(torsoM, k, dt, const V(0, 700 * _px), wind * 1.3);
    _bones = [
      torsoM,
      skirtM,
      headM,
      uF,
      fFm,
      uB,
      fBm,
      tF,
      s2F,
      ftFm,
      tB,
      s2B,
      ftBm,
      ..._braid!.bones(k),
      ..._scarf!.bones(k),
    ];
    // Kavanoz: elden sarkan ipte, sarkaç gibi; el dünyada nereye giderse.
    final hand = fFm(_hF + const V(-10, 10));
    final handW = hand + V(_walked, 0);
    final hv = _fresh ? V.zero : (handW - _prevHand) / dt;
    final ha = _fresh ? V.zero : (hv - _handVel) / dt;
    _prevHand = handW;
    _handVel = hv;
    _jarV +=
        (-math.sin(_jarA) * 60 -
            (ha.dx * 0.06).clamp(-90.0, 90.0) * math.cos(_jarA) -
            _jarV * 4) *
        dt;
    _jarA = (_jarA + _jarV * dt).clamp(-1.1, 1.1);
    _hide = i.shield;
    _light = i.light;
    final len = 28 * _px * (1 - 0.7 * _hide);
    _jar = hand + V(math.sin(_jarA), math.cos(_jarA)) * len + V(0, 22 * _px);
    _hand = hand;
    _fresh = false;
  }

  V _hand = V.zero;

  /// Ayak merkezinde, sağa bakan kukla: kenar ışığı, gövde, göz, kavanoz.
  /// [rim] kavanozun ılık ışığının siluetin kenarını yalaması.
  void paint(ui.Canvas c, {double rim = 0.4, bool jar = true}) {
    if (_bones.isEmpty) return;
    final paths = {for (final n in _order) n: _layers[n]!.path(_bones)};
    if (rim > 0) {
      // Ilık hale: siluet ışık renginde, dört yana biraz kaydırılarak önce
      // çizilir; mürekkep üstüne gelince kenarda ince bir ışık kalır
      // (bulanıklık yok: her karede bulanıklık telefonda pahalı).
      final all = ui.Path();
      for (final p in paths.values) {
        all.addPath(p, V.zero);
      }
      final paint = ui.Paint()
        ..color = const ui.Color(0xFFFFC46B).withValues(alpha: rim * 0.5);
      for (final o in const [V(0.45, -0.3), V(-0.3, -0.45), V(0.3, 0.25)]) {
        c.save();
        c.translate(o.dx, o.dy);
        c.drawPath(all, paint);
        c.restore();
      }
    }
    for (final n in _order) {
      c.drawPath(paths[n]!, ui.Paint()..color = _layers[n]!.color);
    }
    // Göz: ışıyan hilal ve parıltı beneği, çevresinde ılık parıltı.
    final eyeC = _bones[_head](const V(940, 465));
    c.drawCircle(
      eyeC,
      26 * _px,
      ui.Paint()
        ..shader = ui.Gradient.radial(eyeC, 26 * _px, [
          ui.Color.fromRGBO(255, 217, 138, 0.53 * (1 - 0.6 * _hide)),
          const ui.Color(0x00FFD98A),
        ]),
    );
    c.drawPath(
      _layers['goz']!.path(_bones),
      ui.Paint()..color = _layers['goz']!.color,
    );
    if (jar) _paintJar(c);
  }

  /// Düz tek renk siluet (duvardaki gölge).
  void paintSolid(ui.Canvas c, ui.Color color) {
    if (_bones.isEmpty) return;
    final paint = ui.Paint()..color = color;
    for (final n in _order) {
      final p = _layers[n]!.path(_bones)..fillType = ui.PathFillType.nonZero;
      c.drawPath(p, paint);
    }
  }

  void _paintJar(ui.Canvas c) {
    final glow = _light * (1 - 0.85 * _hide);
    final jar = _jar;
    if (glow > 0) {
      c.drawCircle(
        jar,
        36,
        ui.Paint()
          ..shader = ui.Gradient.radial(
            jar,
            36,
            [
              ui.Color.fromRGBO(255, 196, 107, 0.24 * glow),
              ui.Color.fromRGBO(255, 196, 107, 0.07 * glow),
              const ui.Color(0x00FFC46B),
            ],
            const [0, 0.35, 1],
          ),
      );
      c.drawCircle(
        jar,
        70 * _px,
        ui.Paint()
          ..shader = ui.Gradient.radial(jar, 70 * _px, [
            ui.Color.fromRGBO(255, 200, 110, 0.55 * glow),
            const ui.Color(0x00FFC46B),
          ]),
      );
    }
    c.drawLine(
      _hand,
      jar - V(0, 21 * _px * 1.5),
      ui.Paint()
        ..color = const ui.Color(0xFF2A1A10)
        ..strokeWidth = 0.35,
    );
    c.save();
    c.translate(jar.dx, jar.dy);
    c.rotate(_jarA * 0.6);
    // A1'deki gibi iri kavanoz.
    c.scale(1.5 * _px);
    final body = ui.RRect.fromRectAndRadius(
      const ui.Rect.fromLTWH(-11, -12, 22, 26),
      const ui.Radius.circular(6),
    );
    c.drawRRect(
      body,
      ui.Paint()
        ..shader = ui.Gradient.radial(V.zero, 18, [
          ui.Color.lerp(
            const ui.Color(0xFFFFE08A),
            const ui.Color(0xFF6A4A20),
            _hide,
          )!,
          ui.Color.lerp(
            const ui.Color(0xFFD9832A),
            const ui.Color(0xFF3A2410),
            _hide,
          )!,
        ]),
    );
    c.drawRRect(
      body,
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const ui.Color(0xFF6A3A14),
    );
    c.drawRect(
      const ui.Rect.fromLTWH(-9, -16, 18, 5),
      ui.Paint()..color = const ui.Color(0xFF5A3A1A),
    );
    final bright = 1 - 0.85 * _hide;
    for (var j = 0; j < 3; j++) {
      final t = _time * (1.4 + j * 0.5) + j * 2.1;
      c.drawCircle(
        V(math.sin(t) * 5, math.cos(t * 1.3) * 6),
        2.2,
        ui.Paint()..color = ui.Color.fromRGBO(255, 248, 220, bright),
      );
    }
    c.restore();
  }
}

/// Perdedeki Sâye: oyundaki kuklanın kendisi, perdenin zamanıyla oynar
/// (duruş ve nefes, yürüyüş, çömelip kavanozu saklama). Bir perdede tek
/// Sâye olur; aynı karede bir daha çizilirse (gölgesi, ışıyan kopyası) aynı
/// poz kullanılır.
abstract final class PerdeSaye {
  static var _k = SayeKukla();
  static final _in = KuklaInput();
  static double? _last;

  // Perdedeki gerçek ilerleyiş: ayak noktasının ekrandaki yeri ve hızı
  // (birim/sn; kukla yürütülünce adımı bu hıza göre atar, ayak kaymaz).
  static double _lastX = 0;
  static double _lastY = 0;
  static double _vx = 0;
  static double _vy = 0;

  // Perde Sâye'yi çoğu yerde oyundaki en yavaş yürüyüşünden kat kat yavaş
  // kaydırır; o hızda adım kısacık kalır, kayıyor gibi görünür. Kukla
  // perdenin istediği yerin biraz ardında kalır, sonra gerçek bir
  // yürüyüşle yetişir, durur (birkaç adım, bir soluk). [_off]: çizildiği
  // yerin istenen yerden farkı (ekran pikseli), [_gx]: kendi hızı.
  static double _off = 0;
  static double _gx = 0;
  static bool _going = false;

  /// Perdede taşınırken (sal, kızak, at, kaplumbağa, kanatla uçuş) Sâye
  /// yürümez; çizimden önce açılıp sonra kapatılır.
  static bool riding = false;

  /// Kanatla uçarken: havada süzülür (bacaklar yürümez).
  static bool flying = false;

  static bool get ready => SayeKukla.ready;

  /// Ayakları [feet]'te, [scale] perde pikseli = 1 oyun birimi (Sâye ~36
  /// birim boyunda). [walk] perde pikseli/sn ile yürür; [crouch] çömelir,
  /// kavanozu saklar; [jar] 0 ise kavanozsuz, arada ışığı kısık. [tint]
  /// verilirse o renkte düz siluet (ışıyan gölge, soluk anı).
  static void draw(
    ui.Canvas c,
    ui.Offset feet,
    double scale,
    double time, {
    double walk = 0,
    bool crouch = false,
    bool swim = false,
    KuklaMode? mode,
    double vy = 0,
    ui.Offset grip = ui.Offset.zero,
    double climb = 0,
    double pull = 0,
    double? stroke,
    double jar = 1,
    bool faceLeft = false,
    double rot = 0,
    double a = 1,
    ui.Color? tint,
  }) {
    if (!ready || a <= 0) return;
    final last = _last;
    final m = c.getTransform();
    final sx = math.sqrt(m[0] * m[0] + m[1] * m[1]);
    final screenX = m[0] * feet.dx + m[4] * feet.dy + m[12];
    final screenY = m[1] * feet.dx + m[5] * feet.dy + m[13];
    final unit = scale * (sx > 0 ? sx : 1); // ekran pikseli / oyun birimi
    // Ekranda yüzü hangi yana: perdenin aynalaması ile [faceLeft].
    final facing = (m[0] < 0 ? -1.0 : 1.0) * (faceLeft ? -1 : 1);
    if (last == null || time < last - 0.001 || time - last > 2) {
      // Yeni perde: kukla baştan (yaylı parçalar yerine otursun).
      _k = SayeKukla();
      _last = time;
      _lastX = screenX;
      _lastY = screenY;
      _vx = 0;
      _vy = 0;
      _off = 0;
      _gx = 0;
      _going = false;
      _in
        ..mode = KuklaMode.ground
        ..forward = 0
        ..crouching = crouch;
      for (var i = 0; i < 30; i++) {
        _k.step(1 / 60, _in);
      }
    } else if (time > last) {
      // [mode] verilirse oyundaki hâller: havada düşüş ([vy] perde
      // pikseli/sn), kenara tutunma ve çıkış ([grip]: tutunulan köşe, ayağa
      // göre perde pikseli; [climb] çıkışın ilerlemesi), yüzüş ([stroke]).
      final dt0 = time - last;
      final movedX = (screenX - _lastX) / unit;
      final movedY = (screenY - _lastY) / unit;
      _lastX = screenX;
      _lastY = screenY;
      final ease = 1 - math.exp(-dt0 / 0.08);
      _vx += (movedX / dt0 - _vx) * ease;
      _vy += (movedY / dt0 - _vy) * ease;
      // Kendi başına mı: perde bir hâl vermemiş, taşınmıyor, yatık değil.
      final free =
          mode == null &&
          !swim &&
          walk == 0 &&
          !riding &&
          !flying &&
          rot.abs() < 0.25;
      // Havada (sıçrayış, düşüş, yükseliş, uçuş): bacaklar yürümez.
      final airborne = (free && _vy.abs() > 18) || (flying && mode == null);
      if ((movedX / dt0).abs() > 400) {
        // Perde atladı (satır geçildi): olduğu yere geçer.
        _off = 0;
        _gx = 0;
        _going = false;
      } else if (free && !airborne && !crouch) {
        // Yavaşsa ardında kalır, birkaç adımla yetişir; hızlıysa onunla
        // yürür (oyundaki gibi gerçek bir yürüyüş, ayak kaymaz).
        const pace = 24.0, gap = 12.0, follow = 16.0;
        final e = -_off / unit; // istenen yer - çizildiği yer (birim)
        var want = 0.0;
        if (_vx.abs() >= follow) {
          want = _vx + e * 3;
          _going = true;
        } else {
          if (!_going &&
              (e.abs() > gap || (_vx.abs() < 0.5 && e.abs() > 1.5))) {
            _going = true;
          }
          if (_going && e.abs() < 1) _going = false;
          if (_going) {
            want = e.sign * math.min(pace, math.sqrt(2 * 90 * e.abs()));
          }
        }
        _gx += (want - _gx).clamp(-180 * dt0, 180 * dt0);
        _off += (_gx * dt0 - movedX) * unit;
      } else {
        // Perde bir hâl verdi: istenen yere yumuşakça oturur.
        _off *= math.exp(-dt0 / 0.2);
        _gx = 0;
        _going = false;
      }
      final ahead = facing *
          (free && !airborne && !crouch
              ? _gx
              : (riding ? 0.0 : _vx));
      _in
        ..mode =
            mode ??
            (swim
                ? KuklaMode.swim
                : (airborne ? KuklaMode.air : KuklaMode.ground))
        ..forward = swim || mode == KuklaMode.swim
            ? 70
            : (walk != 0 ? walk / scale : ahead)
        ..vy = airborne ? (flying ? math.max(_vy, 160.0) : _vy) : vy / scale
        ..grip = ui.Offset(faceLeft ? -grip.dx : grip.dx, grip.dy) / scale
        ..climb = climb
        ..pull = pull
        ..stroke = stroke
        ..crouching = crouch
        ..shield = crouch ? 1 : 0
        ..light = jar.clamp(0.0, 1.0);
      final dt = math.min(time - last, 1 / 20);
      _k.step(dt, _in);
      _last = time;
    }
    c.save();
    // Yürüyerek yetişirken istenen yerin biraz ardında çizilir.
    c.translate(feet.dx + (m[0].abs() > 1e-6 ? _off / m[0] : 0), feet.dy);
    if (rot != 0) c.rotate(rot);
    c.scale(faceLeft ? -scale : scale, scale);
    final layer = a < 1;
    if (layer) {
      c.saveLayer(
        null,
        ui.Paint()..color = ui.Color.fromRGBO(255, 255, 255, a.clamp(0, 1)),
      );
    }
    if (tint != null) {
      _k.paintSolid(c, tint);
    } else {
      _k.paint(c, rim: 0.35, jar: jar > 0.05);
    }
    if (layer) c.restore();
    c.restore();
  }
}
