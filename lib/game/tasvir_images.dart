import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;

/// Gerçek Karagöz ve Hacivat tasvirleri: British Museum koleksiyonundaki
/// eski bir çiftin fotoğrafından (Daderot, Wikimedia Commons, CC0) arka
/// planı ayrılarak çıkarıldı; oyma deliklerden perdenin ışığı geçer.
/// Hacivat sağa, Karagöz sola bakar. Yüklenene dek kod çizimine düşülür.
abstract final class TasvirImages {
  static Image? hacivat;
  static Image? karagoz;

  /// Son yükleme hatası (tanı için).
  static String? lastError;

  static bool get ready => hacivat != null && karagoz != null;

  static Future<void> load() async {
    Future<Image?> one(String name) async {
      try {
        final data = await rootBundle.load('assets/images/karagoz/$name.png');
        final codec = await instantiateImageCodec(data.buffer.asUint8List());
        return (await codec.getNextFrame()).image;
      } catch (e) {
        lastError = '$name: $e';
        return null;
      }
    }

    hacivat ??= await one('hacivat');
    karagoz ??= await one('karagoz');
  }

  /// Tasviri ayaklarının ortası [feet] olacak biçimde [height] boyunda
  /// çizer; [faceLeft] sola baksın mı, [rot] ayakların çevresinde eğilme.
  static void draw(
    Canvas c,
    Image img,
    Offset feet,
    double height, {
    required bool naturalLeft,
    required bool faceLeft,
    double rot = 0,
    double a = 1,
  }) {
    final s = height / img.height;
    final w = img.width * s;
    c.save();
    c.translate(feet.dx, feet.dy);
    if (rot != 0) c.rotate(rot);
    if (naturalLeft != faceLeft) c.scale(-1, 1);
    c.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromLTWH(-w / 2, -height, w, height),
      Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Color.fromRGBO(255, 255, 255, a.clamp(0.0, 1.0)),
    );
    c.restore();
  }
}
