import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'audio.dart';
import 'golge_game.dart';
import 'level.dart';
import 'palette.dart';

// ====================================================== küçük sürprizler
//
// Dünya oyuncuya karşılık verir: birkaç saniyelik, gülümseten anlar. Eşya
// vermezler; bir kez olurlar (bkz. docs/SIRLAR_PLANI.md, S1).

/// S1b · Taş bekçi (Nemrut): kaidesinde küçük bir taş figür. Sâye sırtını
/// dönünce, görmediği bir anda poz değiştirir; üçüncü kez dönüp bakınca
/// Sâye'nin kendi duruşunu taklit eder (kavanozu kaldırmış).
class TasBekci extends PositionComponent with HasGameReference<GolgeGame> {
  TasBekci(Vector2 cell)
    : super(
        position: Vector2(cell.x + kTile / 2, cell.y + kTile),
        priority: 5,
      );

  /// 0 eller yanda, 1 el alında (uzağa bakar), 2 eller belde, 3 Sâye.
  int pose = 0;
  bool _changed = false;
  double _unseen = 0;
  double _t = 0;

  static const _name = 'tasBekci';

  @override
  void onMount() {
    super.onMount();
    if (game.secretSeen(_name)) pose = 3;
  }

  /// Sâye ona bakıyor mu (yüzü ona dönük ve görecek kadar yakın).
  bool get watched {
    final p = game.player;
    if (p == null) return false;
    final dx = position.x - p.center.x;
    final close = dx.abs() < 1.5 * kTile;
    return close || (dx * p.facing > 0 && dx.abs() < 11 * kTile);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = game.player;
    if (p == null || pose >= 3 && game.secretSeen(_name)) return;
    final near = (position.x - p.center.x).abs() < 14 * kTile &&
        (position.y - p.position.y).abs() < 6 * kTile;
    if (!near) return;
    if (watched) {
      _unseen = 0;
      if (_changed) {
        _changed = false;
        // Taklidi ilk görüşte: sır bulundu.
        if (pose == 3) game.foundSecret(_name);
      }
      return;
    }
    if (!game.calmMoment || _changed || pose >= 3) return;
    _unseen += dt;
    if (_unseen > 0.6) {
      pose++;
      _changed = true;
      GameAudio.instance.play('grind', volume: 0.12, minGapMs: 2000);
    }
  }

  @override
  void render(Canvas canvas) {
    // Sâye boyunda: pozlar uzaktan da seçilsin.
    canvas.save();
    canvas.scale(1.45);
    _draw(canvas);
    canvas.restore();
  }

  void _draw(Canvas canvas) {
    const stone = Color(0xFF6E6068);
    const dark = Color(0xFF3A3038);
    final body = Paint()..color = stone;
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = const Color(0xFFD8C8D0).withValues(alpha: 0.75);
    // Kaide.
    final base = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-11, -9, 22, 9),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(base, Paint()..color = dark);
    canvas.drawRRect(base, rim);
    canvas.save();
    canvas.translate(0, -9);
    // Gövde (kısa entari) ve baş.
    final torso = Path()
      ..moveTo(-5, 0)
      ..lineTo(-4, -18)
      ..lineTo(4, -18)
      ..lineTo(5, 0)
      ..close();
    canvas.drawPath(torso, body);
    canvas.drawPath(torso, rim);
    final head = const Offset(0, -23);
    canvas.drawCircle(head, 4.5, body);
    canvas.drawCircle(head, 4.5, rim);
    if (pose < 3) {
      // Kommagene'nin sivri başlığı.
      final hat = Path()
        ..moveTo(-4.5, -25)
        ..quadraticBezierTo(-3, -33, 1.5, -35)
        ..quadraticBezierTo(0.5, -30, 4.5, -25)
        ..close();
      canvas.drawPath(hat, body);
      canvas.drawPath(hat, rim);
    } else {
      // Sâye'nin kirpi saçı.
      final hair = Path()
        ..moveTo(-5, -24)
        ..lineTo(-7, -30)
        ..lineTo(-2, -27)
        ..lineTo(0, -32)
        ..lineTo(2, -27)
        ..lineTo(6, -29)
        ..lineTo(4.5, -23)
        ..close();
      canvas.drawPath(hair, body);
      canvas.drawPath(hair, rim);
    }
    final arm = Paint()
      ..color = stone
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    void limb(Offset a, Offset b) {
      canvas.drawLine(a, b, arm);
    }

    const sl = Offset(-4, -16);
    const sr = Offset(4, -16);
    switch (pose) {
      case 0:
        limb(sl, const Offset(-6, -5));
        limb(sr, const Offset(6, -5));
      case 1:
        // El alında, uzağa bakar.
        limb(sl, const Offset(-6, -5));
        limb(sr, const Offset(6, -20));
        limb(const Offset(6, -20), const Offset(1, -24));
      case 2:
        // Eller belde.
        limb(sl, const Offset(-8, -10));
        limb(const Offset(-8, -10), const Offset(-4, -7));
        limb(sr, const Offset(8, -10));
        limb(const Offset(8, -10), const Offset(4, -7));
      default:
        // Sâye gibi: kavanozu öne kaldırmış.
        limb(sl, const Offset(-6, -5));
        limb(sr, const Offset(9, -13));
        final jar = Rect.fromCenter(
          center: const Offset(10, -10),
          width: 5,
          height: 6,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(jar, const Radius.circular(1.5)),
          body,
        );
        // Taş kavanozda belli belirsiz bir ışık: kim yaktı?
        final f = 0.5 + 0.5 * math.sin(_t * 2.3);
        glowDot(canvas, jar.center, 9, kWarmLight, 0.25 * f);
    }
    canvas.restore();
  }
}
