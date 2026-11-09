import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';

/// Blender'da düzenlenen düşüş eğrisi ve su teması.
abstract final class YerebatanPerdeArt {
  static const _frameWidth = 320.0, _frameHeight = 144.0;
  static const _columns = 6, _frameCount = 18, _fps = 12;
  static const _assetDir = 'assets/art/yerebatan';
  static Image? _water;
  static Image? _stage;
  static Map<String, List<(double, double, double)>> _tracks = {};
  static bool get ready => _water != null && _tracks.isNotEmpty;

  static Future<void> load() async {
    if (ready) return;
    try {
      final raw = jsonDecode(
        await rootBundle.loadString('$_assetDir/dusus.json'),
      ) as Map<String, dynamic>;
      final tracks = {
        for (final name in ['fall', 'swim', 'climb', 'walk'])
          name: [
            for (final List<dynamic> row in raw[name] as List)
              (
                (row[0] as num).toDouble(),
                (row[1] as num).toDouble(),
                (row[2] as num).toDouble(),
              ),
          ],
      };
      if (tracks.values.any((track) => track.length < 2)) return;
      _water = await _image('su');
      _tracks = tracks;
      _stage = await _image('zemin');
    } catch (_) {
      // Varlık okunamazsa açılışın önceki hareketi ve su çizimi kullanılır.
    }
  }

  static Future<Image> _image(String name) async {
    final bytes = await rootBundle.load('$_assetDir/$name.png');
    final codec = await instantiateImageCodec(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  static bool stage(Canvas canvas, Rect bounds, double opacity) {
    final img = _stage;
    if (img == null) return false;
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      bounds,
      Paint()
        ..color = Color.fromRGBO(255, 255, 255, opacity)
        ..filterQuality = FilterQuality.medium,
    );
    return true;
  }

  static (double, double, double) sample(String track, double progress) {
    final t = progress.clamp(0.0, 1.0);
    final frames = _tracks[track];
    if (frames == null) {
      return switch (track) {
        'fall' => (t, t * t, t * .52),
        'climb' => (t, t, t),
        _ => (t, 0, 0),
      };
    }
    final frame = t * (frames.length - 1);
    final i = frame.floor().clamp(0, frames.length - 2);
    final (x0, y0, r0) = frames[i];
    final (x1, y1, r1) = frames[i + 1];
    final f = frame - i;
    return (x0 + (x1 - x0) * f, y0 + (y1 - y0) * f, r0 + (r1 - r0) * f);
  }

  static final _paint = Paint()..filterQuality = FilterQuality.low;

  static void splash(
    Canvas canvas,
    Offset contact,
    double seconds,
    double size,
  ) {
    final frame = (seconds * _fps).floor();
    if (frame < 0 || frame >= _frameCount) return;
    canvas.drawImageRect(
      _water!,
      Rect.fromLTWH(
        (frame % _columns) * _frameWidth,
        (frame ~/ _columns) * _frameHeight,
        _frameWidth,
        _frameHeight,
      ),
      Rect.fromLTWH(
        contact.dx - _frameWidth * .5 * size,
        contact.dy - 108 * size,
        _frameWidth * size,
        _frameHeight * size,
      ),
      _paint,
    );
  }
}
