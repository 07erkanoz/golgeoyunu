import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'entities.dart';
import 'ergenekon.dart';
import 'golgehane.dart';
import 'golge_game.dart';
import 'hints.dart';
import 'level.dart';
import 'nemrut.dart';
import 'palette.dart';
import 'puzzles.dart';
import 'shadow_decoy.dart';

// ================================================================ Yol gösterme
//
// Bulmacada takılan oyuncuya yazıyla anlatmak yerine gösterilir:
//  1. Bir düzeneğin başında bir süre ilerleyemeyince (ya da orada iki kez
//     ölünce) kamera sıradaki adıma (çekilecek kol, çevrilecek taş, ip,
//     vana…) kayıp gösterir, orada ılık bir halka belirir, ipucu yazısı
//     yeniden söylenir; kamera geri döner.
//  2. Yine olmazsa Sâye'nin gölgesi ondan ayrılır, o yere yürür (gerekirse
//     duvarda yukarı süzülür), orada iki kez zıplar: "burası". Sonra döner.
//  3. Takılma sürerse gölge arada bir yeniden gösterir.
// Ayrıca kapalı bir kapıya ilk yaklaşışta kamera kapıyı bir an gösterir.
//
// Sâye ölünce bölüm yeniden kurulur (dünyadaki her şey yeniden yaratılır);
// bu yüzden takılma bilgisi oyunun kendisinde tutulur, düzenekler konumlarıyla
// tanınır.

/// Sıradaki adım: dünyadaki yeri, oyuncunun duracağı yer ve ipucu anahtarı.
class GuideTarget {
  GuideTarget(this.key, this.at, this.stand, this.hint);

  /// Konumla kimlik (yeniden kurulan bölümde de aynı).
  final String key;
  final Vector2 at;
  final Vector2 stand;
  final String? hint;
}

class Guide {
  Guide(this.game);

  final GolgeGame game;

  /// İlk gösterme (kamera) ve gölgenin yola çıkması için takılma süreleri.
  static const double showAfter = 30;
  static const double walkAfter = 55;

  /// Gölge yeniden gösterene dek geçen süre (takılma sürerse).
  static const double again = 40;

  /// Ölüm sayısıyla erkenden: iki ölümde kamera, üçte gölge.
  static const int showDeaths = 2;
  static const int walkDeaths = 3;

  int _level = -1;
  GuideTarget? current;
  double stuck = 0;
  int deaths = 0;

  /// 0 hiçbir şey, 1 kamera gösterdi, 2 gölge gösterdi.
  int stage = 0;
  double _since = 0;
  double _scan = 0;

  /// Kullanılmış düzenekler (konum anahtarıyla): bir kez çekilen kol, açılan
  /// vana artık "sıradaki adım" değildir.
  final used = <String>{};

  /// Testler için: sıradaki adımı şimdi hesaplar.
  GuideTarget? debugNext() => _next();

  void reset() {
    current = null;
    stuck = 0;
    deaths = 0;
    stage = 0;
    _since = 0;
    used.clear();
  }

  /// Oyuncu bir düzeneği kullandı (kol, ↑ ile kullanılan her şey).
  void markUsed(PositionComponent c) => used.add(_keyOf(c));

  void onDeath(Vector2 at) {
    final cur = current;
    if (cur == null) return;
    if ((cur.at - at).length < 20 * kTile) deaths++;
  }

  void update(double dt) {
    if (game.levelIndex != _level) {
      _level = game.levelIndex;
      reset();
    }
    final p = game.player;
    if (p == null || p.isDead || game.cinematic) return;
    _showGates(p.center);
    _scan += dt;
    if (_scan > 0.5) {
      _scan = 0;
      final next = _next();
      if (next?.key != current?.key) {
        current = next;
        stuck = 0;
        deaths = 0;
        stage = 0;
        _since = 0;
      } else if (next != null) {
        current = next;
      }
    }
    final cur = current;
    if (cur == null) return;
    final d = cur.at - p.center;
    if (d.x.abs() < 16 * kTile && d.y.abs() < 10 * kTile) stuck += dt;
    _since += dt;
    if (!game.calmMoment) return;
    if (stage < 1 && (stuck > showAfter || deaths >= showDeaths)) {
      _show(cur);
    } else if (stage < 2 && (stuck > walkAfter || deaths >= walkDeaths)) {
      _walk(cur);
    } else if (stage >= 2 && _since > again && stuck > walkAfter) {
      _walk(cur);
    }
  }

  /// 1. Kamera sıradaki adımı gösterir, orada ılık bir halka, ipucu yeniden.
  void _show(GuideTarget t) {
    if (!game.focus(t.at, hold: 2.0)) return;
    stage = 1;
    _since = 0;
    game.world.add(GuideMark(t.at));
    final hint = t.hint;
    if (hint != null) game.narration.hint(Hints.text(hint), queue: true);
  }

  /// 2. Gölge o yere yürür, zıplayıp gösterir, döner.
  void _walk(GuideTarget t) {
    final p = game.player;
    if (p == null || !p.guideShadow(t.stand)) return;
    stage = 2;
    _since = 0;
    game.world.add(GuideMark(t.at, life: 7));
    GameAudio.instance.play('breath', volume: 0.3, minGapMs: 3000);
  }

  /// Kapalı bir kapıya ilk yaklaşışta kamera kapıyı bir an gösterir (kapı
  /// ekranın dışındaysa; bölüm başına kapı başına bir kez).
  void _showGates(Vector2 p) {
    final view = game.camera.visibleWorldRect;
    for (final g in game.world.children.whereType<Gate>()) {
      if (g.opening || !g.solid) continue;
      final dx = g.position.x - p.x;
      if (dx < 0 || dx > 13 * kTile) continue;
      if ((g.position.y + g.size.y / 2 - p.y).abs() > 12 * kTile) continue;
      final key = 'kapiGoster:${game.levelIndex}:${g.position.x.round()}';
      if (game.eventSeen(key)) continue;
      final c = g.position + g.size / 2;
      if (view.deflate(kTile).contains(Offset(c.x, c.y))) {
        game.markEvent(key); // zaten görünüyor
        continue;
      }
      if (!game.calmMoment) return;
      if (game.focus(c, hold: 1.2)) game.markEvent(key);
      return;
    }
  }

  static String _keyOf(PositionComponent c) =>
      '${c.runtimeType}:${(c.position.x / 8).round()}:${(c.position.y / 8).round()}';

  /// Sıradaki adım: oyuncunun yakınındaki, henüz yapılmamış düzenek; öne
  /// (oyuncunun gittiği yöne) olanlar yeğlenir.
  GuideTarget? _next() {
    final p = game.player;
    if (p == null) return null;
    final giant = game.world.children.whereType<StoneGiant>().any(
      (g) => !g.fallen && (g.position.x - p.center.x).abs() < 20 * kTile,
    );
    GuideTarget? best;
    var bestScore = double.infinity;
    void consider(PositionComponent c, String? hint, Vector2 at) {
      final d = at - p.center;
      if (d.x.abs() > 18 * kTile || d.y.abs() > 12 * kTile) return;
      final behind = d.x < -4 * kTile ? 6 * kTile : 0.0;
      final score = d.length + behind;
      if (score < bestScore) {
        bestScore = score;
        best = GuideTarget(_keyOf(c), at, _standUnder(at), hint);
      }
    }

    for (final c in game.world.children) {
      switch (c) {
        case Lever l when !l.pulled:
          consider(l, 'lever', l.position + Vector2(0, -kTile / 2));
        case StarStone s when !s.correct:
          consider(s, 'star', s.position + Vector2(0, -kTile / 2));
        case PerdeCord k when !_perdeSolved(k):
          consider(k, 'cord', k.position + Vector2(0, -kTile / 2));
        case FireflySwarm f when giant && game.fireflies == 0:
          consider(f, 'fireflyPickup', f.position.clone());
        // Körükler sırayla basılır: yalnız sıradaki körük gösterilir (en
        // yakın körük yanlış sıra olabilir).
        case Bellows b:
          final v = b.vein;
          if (v != null &&
              v.lit &&
              !v.opening &&
              b.order > 0 &&
              (v.rhythm ? identical(b, v.activeBellows) : b.order == v.next)) {
            consider(b, 'bellows', b.position + Vector2(0, -kTile / 2));
          }
        case Mirror m when !used.contains(_keyOf(m)):
          consider(m, 'mirror', m.position.clone());
        case Valve v when !used.contains(_keyOf(v)):
          consider(v, 'valve', v.position + Vector2(0, -kTile / 2));
        case ShadowStone k when !used.contains(_keyOf(k)):
          consider(k, 'shadowStone', k.position + Vector2(0, -kTile / 2));
        // Gizli odanın tasvirleri yol değildir.
        case Usable u
            when !used.contains(_keyOf(u)) &&
                u is! StarStone &&
                u is! GolgehaneTasvir:
          consider(u, null, u.position + Vector2(0, -kTile / 2));
      }
    }
    return best;
  }

  bool _perdeSolved(PerdeCord k) {
    final perdes = game.world.children.whereType<GiantPerde>();
    if (perdes.isEmpty) return true;
    final g = perdes.reduce(
      (a, b) =>
          (a.position - k.position).length < (b.position - k.position).length
          ? a
          : b,
    );
    return g.solved;
  }

  /// Düzeneğin altındaki zemin: gölgenin ayaklarını basacağı yer.
  Vector2 _standUnder(Vector2 at) {
    final lv = game.level;
    final c = (at.x / kTile).floor();
    final r0 = (at.y / kTile).floor();
    for (var r = r0; r < math.min(lv.height, r0 + 8); r++) {
      final ch = lv.cell(c, r);
      if (ch == '#' || ch == '=' || ch == '-') {
        return Vector2(at.x, r * kTile.toDouble());
      }
    }
    return Vector2(at.x, at.y + kTile / 2);
  }
}

/// Gösterilen yerde ılık, genişleyip sönen halkalar (birkaç saniye).
class GuideMark extends PositionComponent with HasGameReference<GolgeGame> {
  GuideMark(Vector2 at, {this.life = 4.5})
    : super(position: at.clone(), priority: 30);

  final double life;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    if (_t > life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final fade = math.min(1.0, _t / 0.4) * math.min(1.0, (life - _t) / 0.8);
    if (fade <= 0) return;
    glowDot(canvas, Offset.zero, 46, kWarmLight, 0.35 * fade);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 2; i++) {
      final k = ((_t * 0.8 + i * 0.5) % 1.0);
      ring.color = kWarmLight.withValues(alpha: 0.7 * (1 - k) * fade);
      canvas.drawCircle(Offset.zero, 14 + 30 * k, ring);
    }
  }
}
