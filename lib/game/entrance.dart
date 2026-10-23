import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'audio.dart';
import 'golge_game.dart';
import 'level.dart';
import 'player.dart';

/// Bölüme giriş: perdeden (ya da Yeni oyun'dan, bölüm listesinden) ilk
/// girişte kısa bir an. Yeniden doğarken ve "Devam" ile girerken oynamaz.
enum EntranceKind {
  /// Yerebatan: Sâye sarnıcın ızgarasından düşer; ışık sütunu, toz, sarsıntı.
  fall,

  /// Kaf: Hüdhüd onu bırakır; tüyler arasında süzülerek iner.
  glide,

  /// Göğün katları: göğün ışığı onu yavaşça katın üstüne indirir.
  descend,

  /// Ötüken: ormanın gölgesinden belirir (karanlık iplikler toplanır).
  emerge,
}

/// Dönüm noktası bölümlerinin girişi (yoksa düz başlangıç).
EntranceKind? entranceFor(int level) => switch (level) {
  0 => EntranceKind.fall,
  3 => EntranceKind.glide,
  16 || 18 => EntranceKind.descend,
  17 => EntranceKind.emerge,
  _ => null,
};

/// Girişi oynatan bileşen: oyuncudan sonra güncellenir, onun düşüşünü
/// yönetir; bitince denetimi oyuncuya verir ve ışığı söndürüp kalkar.
class Entrance extends Component with HasGameReference<GolgeGame> {
  Entrance(this.kind, this.ground) : super(priority: 25);

  final EntranceKind kind;

  /// Sâye'nin varacağı yer (bölümün başı, ayakta).
  final Vector2 ground;

  /// Başladığı yükseklik (piksel; ground'un üstünde).
  double _lift = 0;
  double _t = 0;

  /// Yere değdi mi; değdikten sonra geçen süre.
  bool _landed = false;
  double _afterLand = 0;

  /// Denetim oyuncuya verildi mi (ışık ve toz bir süre daha söner).
  bool _released = false;

  final _bits = <_Bit>[];
  final _rng = math.Random(7);

  /// Bitti mi (testler için).
  bool get released => _released;

  /// En çok bu kadar sürer; takılırsa denetim yine verilir.
  static const double _maxTime = 6;

  Player? get _p {
    final p = game.player;
    return p != null && p.isMounted ? p : null;
  }

  @override
  void onMount() {
    super.onMount();
    final p = _p;
    if (p == null) {
      _released = true;
      removeFromParent();
      return;
    }
    game.cinematic = true;
    final want = switch (kind) {
      EntranceKind.fall => 9,
      EntranceKind.glide => 7,
      EntranceKind.descend => 6,
      EntranceKind.emerge => 0,
    };
    _lift = _freeAbove(want) * kTile;
    p.position.setFrom(ground - Vector2(0, _lift));
    p.velocity.setZero();
    if (kind == EntranceKind.emerge) {
      p.entranceAlpha = 0;
      // Karanlık iplikler dört bir yandan Sâye'nin yerine toplanır.
      for (var i = 0; i < 34; i++) {
        final a = _rng.nextDouble() * math.pi * 2;
        final d = 60 + _rng.nextDouble() * 90;
        _bits.add(
          _Bit(
            Offset(math.cos(a) * d, math.sin(a) * d * 0.6 - 14),
            Offset.zero,
            1.2 + _rng.nextDouble() * 0.3,
            dark: true,
          ),
        );
      }
    }
    if (kind == EntranceKind.glide) {
      GameAudio.instance.play('glide', volume: 0.6);
    }
  }

  /// Başlangıcın üstünde kaç boş kare var (en çok [want]; tavana çarpmasın
  /// diye ikisi pay bırakılır).
  int _freeAbove(int want) {
    if (want == 0) return 0;
    final level = game.level;
    final c0 = (ground.x / kTile).floor();
    final c1 = ((ground.x + Player.w) / kTile).floor();
    final r0 = (ground.y / kTile).floor();
    var free = 0;
    for (var r = r0 - 1; r >= 0 && free < want + 2; r--) {
      if (level.solid(c0, r) || level.solid(c1, r)) break;
      free++;
    }
    return math.max(0, math.min(want, free - 2));
  }

  @override
  void update(double dt) {
    _t += dt;
    final p = _p;
    for (final b in _bits) {
      b.age += dt;
    }
    _bits.removeWhere((b) => b.age > b.life);
    if (p == null) {
      _release();
      if (_bits.isEmpty) removeFromParent();
      return;
    }
    if (!_released) {
      switch (kind) {
        case EntranceKind.fall:
          _fall(p, dt);
        case EntranceKind.glide:
          _glide(p, dt);
        case EntranceKind.descend:
          _descend(p, dt);
        case EntranceKind.emerge:
          _emerge(p, dt);
      }
      if (_t > _maxTime || p.isDead) _release();
    }
    // Işık ve toz söndükten sonra kalkar.
    if (_released && _bits.isEmpty && _glow <= 0.01) removeFromParent();
    if (_released) _glow = math.max(0, _glow - dt / 1.2);
  }

  /// Işık sütununun gücü (0 – 1).
  double _glow = 1;

  void _fall(Player p, double dt) {
    if (!_landed && (p.onGround && _t > 0.05 || _lift == 0)) {
      _landed = true;
      if (_lift > 0) {
        game.shake(7);
        GameAudio.instance.play('land', volume: 0.9);
        _dust(p, 22);
      }
    }
    if (_landed) {
      // Sert iniş: bir an çömelir, sonra doğrulur.
      _afterLand += dt;
      p.crouching = _afterLand < 0.55;
      if (_afterLand > 0.75) _release();
    }
  }

  void _glide(Player p, double dt) {
    if (!p.onGround) {
      // Rüzgâra yaslanmış gibi ağır iniş; kanatlar açık.
      p.velocity.y = math.min(p.velocity.y, 75);
      p.gliding = p.hasWings;
      if (_rng.nextDouble() < dt * 7) _feather(p);
    } else if (!_landed) {
      _landed = true;
      p.gliding = false;
      _dust(p, 8);
    }
    if (_landed) {
      _afterLand += dt;
      if (_afterLand > 0.35) _release();
    }
  }

  void _descend(Player p, double dt) {
    if (!p.onGround) {
      // Göğün ışığı taşır: sabit, yavaş bir iniş.
      p.velocity.y = 55;
      if (_rng.nextDouble() < dt * 14) _spark(p);
    } else if (!_landed) {
      _landed = true;
      for (var i = 0; i < 10; i++) {
        _spark(p);
      }
    }
    if (_landed) {
      _afterLand += dt;
      if (_afterLand > 0.4) _release();
    }
  }

  void _emerge(Player p, double dt) {
    final k = (_t / 1.3).clamp(0.0, 1.0);
    p.entranceAlpha = k * k;
    if (k >= 1) _release();
  }

  void _release() {
    if (_released) return;
    _released = true;
    final p = _p;
    if (p != null) {
      p.entranceAlpha = 1;
      p.crouching = false;
    }
    game.cinematic = false;
  }

  void _dust(Player p, int n) {
    final foot =
        Offset(p.center.x, p.position.y + Player.h) -
        Offset(ground.x + Player.w / 2, ground.y);
    for (var i = 0; i < n; i++) {
      final side = i.isEven ? 1 : -1;
      _bits.add(
        _Bit(
          foot + Offset(side * _rng.nextDouble() * 6, 0),
          Offset(
            side * (40 + _rng.nextDouble() * 90),
            -(10 + _rng.nextDouble() * 40),
          ),
          0.7 + _rng.nextDouble() * 0.5,
        ),
      );
    }
  }

  void _feather(Player p) {
    final at =
        Offset(p.center.x, p.center.y) -
        Offset(ground.x + Player.w / 2, ground.y);
    _bits.add(
      _Bit(
        at + Offset((_rng.nextDouble() - 0.5) * 40, -20),
        Offset((_rng.nextDouble() - 0.5) * 30, 25 + _rng.nextDouble() * 20),
        2.2,
        feather: true,
      ),
    );
  }

  void _spark(Player p) {
    final at =
        Offset(p.center.x, p.center.y) -
        Offset(ground.x + Player.w / 2, ground.y);
    _bits.add(
      _Bit(
        at + Offset((_rng.nextDouble() - 0.5) * 36, (_rng.nextDouble()) * 20),
        Offset((_rng.nextDouble() - 0.5) * 12, -20 - _rng.nextDouble() * 25),
        1.0 + _rng.nextDouble() * 0.6,
        spark: true,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    // Bileşen dünyada: çizimler varış yerine göre.
    canvas.save();
    canvas.translate(ground.x + Player.w / 2, ground.y);
    _renderLight(canvas);
    for (final b in _bits) {
      b.render(canvas);
    }
    canvas.restore();
  }

  /// Yukarıdan inen ışık sütunu: sarnıcın ızgarasından süzülen gün ışığı,
  /// göğün ışığı. Süzülüşte ve belirişte yok.
  void _renderLight(Canvas canvas) {
    if (kind != EntranceKind.fall && kind != EntranceKind.descend) return;
    final a = _glow * math.min(1, _t / 0.4);
    if (a <= 0.01) return;
    final top = -_lift - 14 * kTile;
    final warm = kind == EntranceKind.fall
        ? const Color(0xFFFFE2A8)
        : const Color(0xFFE8F0FF);
    final halfTop = kTile * 0.9;
    final halfBottom = kTile * 1.8;
    final beam = Path()
      ..moveTo(-halfTop, top)
      ..lineTo(halfTop, top)
      ..lineTo(halfBottom, 0)
      ..lineTo(-halfBottom, 0)
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, top),
          Offset.zero,
          [
            warm.withValues(alpha: 0.05 * a),
            warm.withValues(alpha: 0.28 * a),
            warm.withValues(alpha: 0.12 * a),
          ],
          const [0, 0.75, 1],
        ),
    );
    // Yerde ışığın düştüğü leke.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: halfBottom * 2.6,
        height: kTile * 0.5,
      ),
      Paint()
        ..color = warm.withValues(alpha: 0.18 * a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }
}

/// Girişin küçük parçaları: toz, tüy, ışık kıvılcımı, karanlık iplik.
class _Bit {
  _Bit(
    this.at,
    this.vel,
    this.life, {
    this.feather = false,
    this.spark = false,
    this.dark = false,
  });

  final Offset at;
  final Offset vel;
  final double life;
  final bool feather;
  final bool spark;
  final bool dark;
  double age = 0;

  void render(Canvas canvas) {
    final k = (age / life).clamp(0.0, 1.0);
    if (dark) {
      // Gölge bulutçukları Sâye'nin çevresinde dönerek yerine toplanır,
      // vardıkça küçülüp söner.
      final e = 1 - math.pow(1 - k, 2).toDouble();
      final a0 = math.atan2(at.dy + 14, at.dx);
      final d0 = (at + const Offset(0, 14)).distance;
      final a = a0 + e * 1.8;
      final d = d0 * (1 - e);
      final p = Offset(math.cos(a) * d, math.sin(a) * d * 0.7 - 14);
      canvas.drawCircle(
        p,
        3 + 7 * (1 - e),
        Paint()
          ..color = const Color(0xFF0A0605)
              .withValues(alpha: 0.55 * (1 - k * k))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      return;
    }
    if (feather) {
      // Sallanarak süzülen tüy.
      final p = at + vel * age + Offset(math.sin(age * 4) * 10, 0);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(math.sin(age * 4) * 0.6);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 4, height: 11),
        Paint()
          ..color = const Color(0xFFE9C79A).withValues(alpha: 0.8 * (1 - k)),
      );
      canvas.restore();
      return;
    }
    if (spark) {
      final p = at + vel * age;
      canvas.drawCircle(
        p,
        1.6 + (1 - k) * 1.2,
        Paint()
          ..color = const Color(0xFFF4F7FF).withValues(alpha: 0.85 * (1 - k)),
      );
      return;
    }
    // Toz: yana savrulur, yavaşlar, söner.
    final slow = 1 - math.exp(-age * 3);
    final p = at + vel * (slow / 3) + Offset(0, age * age * 30);
    canvas.drawCircle(
      p,
      3 + k * 7,
      Paint()
        ..color = const Color(0xFF8C7A66).withValues(alpha: 0.35 * (1 - k)),
    );
  }
}
