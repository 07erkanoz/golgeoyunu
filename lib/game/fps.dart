import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../settings.dart';

/// Köşede küçük bir kare hızı göstergesi (ayarlardan açılır). Gerçek saatle
/// sayar: korku anındaki ağır çekim onu yanıltmaz.
class FpsCounter extends PositionComponent with HasGameReference {
  FpsCounter() : super(priority: 100);

  final _clock = Stopwatch()..start();
  int _frames = 0;
  int _shown = 0;
  TextPainter? _text;

  @override
  void render(Canvas canvas) {
    if (!Settings.showFps) return;
    _frames++;
    final ms = _clock.elapsedMilliseconds;
    if (ms >= 500 || _text == null) {
      _shown = ms == 0 ? 0 : (_frames * 1000 / ms).round();
      _frames = 0;
      _clock.reset();
      _text = TextPainter(
        text: TextSpan(
          text: '$_shown FPS',
          style: const TextStyle(
            color: Color(0xCCEBDDCB),
            fontSize: 11,
            fontFamily: 'Roboto',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    final size = game.camera.viewport.size;
    final t = _text!;
    final at = Offset(size.x - t.width - 14, size.y - t.height - 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(at.dx - 6, at.dy - 3, t.width + 12, t.height + 6),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0x66000000),
    );
    t.paint(canvas, at);
  }
}
