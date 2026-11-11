import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;

/// Gerçek Karagöz ve Hacivat tasvirleri: British Museum koleksiyonundaki
/// eski bir çiftin fotoğrafından (Daderot, Wikimedia Commons, CC0) arka
/// planı ayrılarak çıkarıldı; oyma deliklerden perdenin ışığı geçer.
/// Hacivat sağa, Karagöz sola bakar. Yüklenene dek kod çizimine düşülür.
abstract final class TasvirImages {
  static Image? hacivat;
  static Image? karagoz;

  /// Oyundaki Sâye'nin kendisi (tools/preview/saye_tasvir_cikar_test.dart
  /// çizer): perdede de oyundaki gibi görünsün. Sağa bakar.
  static Image? saye;

  /// Oyundaki Sâye'nin hareket kareleri (duruş, çömelme, yürüyüş; kavanozlu
  /// ve kavanozsuz): perdede oyundaki gibi oynar. Hepsi aynı kadrajda, sağa
  /// bakar; ayak noktası [_frameFeet].
  static final frames = <String, Image>{};

  /// Yerebatan'ın Medusa başı (oyundaki çizim, gözleri kapalı).
  static Image? medusa;

  /// Yerebatan köprüsü: perdeye boyanmış sarnıç ve su iyesi tasviri
  /// (docs/oneri/YEREBATAN_KOPRUSU.md).
  static Image? kopru0Sarnic;
  static Image? suIyesi;

  static const _frameFeet = Offset(126.75, 284.25);

  /// Karelerde gövdenin (oyundaki çarpışma kutusunun) boyu, piksel.
  static const frameBody = 252.0;

  static const walkFrames = 12;

  static final _frameNames = [
    'dur',
    'comel',
    'dur_kavanoz',
    'comel_kavanoz',
    for (var i = 0; i < walkFrames; i++) 'yuru$i',
    for (var i = 0; i < walkFrames; i++) 'yuru_kavanoz$i',
  ];

  /// Son yükleme hatası (tanı için).
  static String? lastError;

  static bool get ready => hacivat != null && karagoz != null;

  static Future<void> load() async {
    Future<Image?> one(
      String name, {
      String dir = 'karagoz',
      String ext = 'png',
    }) async {
      try {
        final data = await rootBundle.load('assets/images/$dir/$name.$ext');
        final codec = await instantiateImageCodec(data.buffer.asUint8List());
        return (await codec.getNextFrame()).image;
      } catch (e) {
        lastError = '$name: $e';
        return null;
      }
    }

    hacivat ??= await one('hacivat');
    karagoz ??= await one('karagoz');
    saye ??= await one('saye');
    medusa ??= await one('medusa', dir: 'perde');
    suIyesi ??= await one('su_iyesi', dir: 'perde');
    kopru0Sarnic ??= await one('kopru0_sarnic', dir: 'perde', ext: 'jpg');
    for (final n in _frameNames) {
      if (frames.containsKey(n)) continue;
      final img = await one('saye_$n', dir: 'perde');
      if (img != null) frames[n] = img;
    }
  }

  /// Sâye'nin [name] karesi: ayakları [feet]'te, [k] ölçekte (gövde boyu
  /// [frameBody] · k); [rot] ayakların çevresinde döner.
  static void frame(
    Canvas c,
    String name,
    Offset feet,
    double k, {
    bool faceLeft = false,
    double rot = 0,
    double a = 1,
  }) {
    final img = frames[name];
    if (img == null || a <= 0) return;
    c.save();
    c.translate(feet.dx, feet.dy);
    if (rot != 0) c.rotate(rot);
    c.scale(faceLeft ? -k : k, k);
    c.drawImage(
      img,
      -_frameFeet,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Color.fromRGBO(255, 255, 255, a.clamp(0.0, 1.0)),
    );
    c.restore();
  }

  /// Tasviri tutan çubuğun perdeye düşen gölgesi: usta çubuğu perdeye dik
  /// tutar, gölgesi tasvirin göğsünden aşağı, perdenin dışına iner.
  static void rod(Canvas c, Offset from, Offset to, double width, double a) {
    c.drawLine(
      from,
      to,
      Paint()
        ..color = Color.fromRGBO(20, 9, 4, 0.75 * a.clamp(0.0, 1.0))
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.6),
    );
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
