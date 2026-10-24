import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/golge_game.dart';
import '../game/strings.dart';
import '../settings.dart';

/// İpucu simgesi: Sâye ipucu gerektiren bir yere gelince yanar ve ara sıra
/// "ben buradayım" der (büyüyüp kıpırdar, çevresine bir halka yayılır).
/// Dokununca ipucu kısa bir süre üstte görünür; yanık değilken dokunmak son
/// ipucunu yeniden gösterir. İlk kez yandığında altında, yerini gösteren
/// küçük bir balon çıkar (bir kez).
class HintButton extends StatefulWidget {
  const HintButton({super.key, required this.game, required this.touch});

  final GolgeGame game;

  /// Dokunmatik mi (balonun yazısı: "dokun" ya da "H").
  final bool touch;

  @override
  State<HintButton> createState() => _HintButtonState();
}

class _HintButtonState extends State<HintButton>
    with SingleTickerProviderStateMixin {
  static const _warm = Color(0xFFE0A15F);

  /// Bir "ben buradayım" döngüsü: başında kıpırdar, sonra sakin parlar.
  late final _beat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  );

  /// Yerini gösteren balon açık mı (ilk yanışta).
  bool _intro = false;

  @override
  void initState() {
    super.initState();
    widget.game.narration.hintReady.addListener(_changed);
    _changed();
  }

  @override
  void dispose() {
    widget.game.narration.hintReady.removeListener(_changed);
    _beat.dispose();
    super.dispose();
  }

  void _changed() {
    final ready = widget.game.narration.hintReady.value;
    if (ready) {
      if (!_beat.isAnimating) _beat.repeat();
      if (!Settings.hintIntroSeen) {
        Settings.hintIntroSeen = true;
        Settings.save();
        _intro = true;
        Future.delayed(const Duration(seconds: 9), () {
          if (mounted) setState(() => _intro = false);
        });
      }
    } else {
      _beat.stop();
      _beat.value = 0;
    }
    if (mounted) setState(() {});
  }

  void _tap() {
    setState(() => _intro = false);
    widget.game.narration.revealHint();
  }

  @override
  Widget build(BuildContext context) {
    final ready = widget.game.narration.hintReady.value;
    // Balon simgenin altına taşar; simgenin yerini oynatmaz.
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _tap(),
            child: AnimatedBuilder(
              animation: _beat,
              builder: (context, _) {
                final t = _beat.value;
                // Döngünün başında "ben buradayım": büyür, sağa sola kıpırdar.
                final nudge = ready && t < 0.16
                    ? math.sin(t / 0.16 * math.pi)
                    : 0.0;
                final glow = ready
                    ? 0.55 + 0.45 * (0.5 + 0.5 * math.sin(t * math.pi * 6))
                    : 0.0;
                final wiggle = ready && t < 0.16
                    ? math.sin(t / 0.16 * math.pi * 4) * 0.22 * nudge
                    : 0.0;
                // Kıpırdayışla birlikte dışa yayılan halka.
                final ring = ready && t < 0.3 ? t / 0.3 : 1.0;
                return SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (ring < 1)
                        Container(
                          width: 32 + ring * 16,
                          height: 32 + ring * 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _warm.withValues(alpha: 0.6 * (1 - ring)),
                              width: 2,
                            ),
                          ),
                        ),
                      Transform.rotate(
                        angle: wiggle,
                        child: Transform.scale(
                          scale: 1 + 0.12 * nudge,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ready
                                  ? _warm.withValues(alpha: 0.18 + 0.12 * glow)
                                  : Colors.transparent,
                              border: Border.all(
                                color: ready
                                    ? _warm.withValues(alpha: 0.5 + 0.4 * glow)
                                    : Colors.white.withValues(alpha: 0.18),
                                width: 1.5,
                              ),
                              boxShadow: [
                                if (ready)
                                  BoxShadow(
                                    color: _warm.withValues(alpha: 0.45 * glow),
                                    blurRadius: 6 + 5 * glow,
                                  ),
                              ],
                            ),
                            child: Icon(
                              ready ? Icons.lightbulb : Icons.lightbulb_outline,
                              size: 18,
                              color: ready
                                  ? const Color(0xFFFFE2B0)
                                  : Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // İlk yanışta: ipucunun yeri gösterilir (ok simgeyi gösterir).
          Positioned(
            top: 44,
            right: -8,
            child: AnimatedOpacity(
              opacity: _intro && ready ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: IgnorePointer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: CustomPaint(
                        size: const Size(16, 8),
                        painter: _Arrow(),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xE6140C09),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _warm.withValues(alpha: 0.7)),
                      ),
                      child: Text(
                        S.of(widget.touch ? 'hintHereTouch' : 'hintHereKey'),
                        style: const TextStyle(
                          color: Color(0xFFFFE9C4),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Balonun simgeyi gösteren ucu.
class _Arrow extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = const Color(0xFFE0A15F).withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_Arrow old) => false;
}
