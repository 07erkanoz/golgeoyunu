import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../settings.dart';
import 'golge_game.dart';
import 'hints.dart';
import 'level.dart';
import 'rig.dart' show approach;
import 'strings.dart';

// ===================================================== Öğretim levhaları
//
// İpuçları ekrana kendiliğinden yazılmaz (simgeye dokunulunca okunur); ilk
// bölümün başında bu yetmez: oyuncu nasıl oynanacağını bilmez. Öğretim
// alanında her durağın üstünde, Sâye o durağa gelince kendiliğinden bir levha
// belirir: tuş kapakları ve tek satır. Sâye durağı geçince söner. İpuçları
// kapalıysa levha da çıkmaz.

/// Bir ders: levhanın göründüğü sütun aralığı [from, to), Sâye'nin en çok
/// hangi satırda olduğu ([maxRow]; yukarıdaki raflar için) ve levhanın yeri.
typedef Lesson = ({
  String key,
  int from,
  int to,
  int col,
  int row,
  int? minRow,
  int? maxRow,
});

/// Levha metinleri: {tuş} yer tutucuları tuş kapağı olarak çizilir.
const _lessonTr = {
  'move': '{left} {right}  yürü',
  'pickup': 'Ateşböceğine dokun · kavanoza girer',
  'jump': '{jump}  zıpla',
  'climb': '{up}  zincire tırman',
  'umay': 'Umay ağacına dokun · düşersen buradan başlarsın',
  'crate': 'Sandığı it  {right}',
  'ledge': 'Sandıktan zıpla, kenara tutun · {up}  çık',
  'lever': '{up}  kolu çek · kapı açılır',
  'hide': 'Kandilci ışıkta görür · gölgede dur ya da {down}  çömel',
  'throw': '{firefly}  ateşböceği sal · Kandilci ışığa gider',
  'help': 'Takılırsan  {hint}  ipucu',
};

const _lessonEn = {
  'move': '{left} {right}  walk',
  'pickup': 'Touch the firefly · it flies into the jar',
  'jump': '{jump}  jump',
  'climb': '{up}  climb the chain',
  'umay': 'Touch the Umay tree · if you fall, you start here',
  'crate': 'Push the crate  {right}',
  'ledge': 'Jump from the crate, grab the edge · {up}  climb up',
  'lever': '{up}  pull the lever · the gate opens',
  'hide':
      'Lamplighters see you in the light · stand in shadow or {down}  crouch',
  'throw': '{firefly}  release a firefly · the Lamplighter goes to the light',
  'help': 'If you are stuck  {hint}  hint',
};

class LessonSigns extends Component with HasGameReference<GolgeGame> {
  LessonSigns(this.lessons) : super(priority: 60);

  final List<Lesson> lessons;
  Lesson? _shown;
  double _alpha = 0;
  double _t = 0;
  final _cache = <String, ui.Picture>{};
  final _sizes = <String, Size>{};

  /// Şu an görünen ders (testler için).
  String? get activeKey => _alpha > 0.05 ? _shown?.key : null;

  Lesson? _want() {
    final p = game.player;
    if (p == null || p.isDead || !Settings.hints || game.cinematic) {
      return null;
    }
    final c = (p.center.x / kTile).floor();
    final r = (p.center.y / kTile).floor();
    for (final l in lessons) {
      if (c < l.from || c >= l.to) continue;
      if (l.minRow != null && r < l.minRow!) continue;
      if (l.maxRow != null && r > l.maxRow!) continue;
      return l;
    }
    return null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final want = _want();
    if (want != _shown) {
      // Önce eskisi söner, sonra yenisi belirir.
      _alpha = approach(_alpha, 0, dt, 0.08);
      if (_alpha < 0.03) _shown = want;
    } else {
      _alpha = approach(_alpha, want == null ? 0 : 1, dt, 0.15);
    }
  }

  static String _control(String token) => switch (token) {
    'hint' => Hints.touch ? (S.en ? 'the hint icon' : 'ipucu simgesi') : 'H',
    _ => Hints.control(token),
  };

  String _id(String key) => '${S.en ? 'en' : 'tr'}:${Hints.touch}:$key';

  /// Levha bir kez çizilip saklanır (her karede metin dizilmez).
  ui.Picture _picture(String key) {
    final id = _id(key);
    final hit = _cache[id];
    if (hit != null) return hit;
    final template = (S.en ? _lessonEn : _lessonTr)[key] ?? key;
    const font = 16.0;
    const ink = Color(0xFFF4E2C2);
    const capInk = Color(0xFF2A1810);
    final parts = <(String, bool)>[];
    final re = RegExp(r'\{(\w+)\}');
    var at = 0;
    for (final m in re.allMatches(template)) {
      if (m.start > at) parts.add((template.substring(at, m.start), false));
      parts.add((_control(m.group(1)!), true));
      at = m.end;
    }
    if (at < template.length) parts.add((template.substring(at), false));
    final painters = [
      for (final (s, cap) in parts)
        TextPainter(
          text: TextSpan(
            text: s,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: cap ? font - 1 : font,
              fontWeight: cap ? FontWeight.w700 : FontWeight.w500,
              color: cap ? capInk : ink,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
    // Ok tuşları yazı değil, çizilmiş ok (her yazı tipinde ok işareti yok).
    double? arrow(String s) => switch (s) {
      '←' || '◀' => math.pi,
      '→' || '▶' => 0,
      '↑' => -math.pi / 2,
      '↓' => math.pi / 2,
      _ => null,
    };
    const arrowW = 12.0;
    double partW(int i) {
      final (s, cap) = parts[i];
      if (cap && arrow(s) != null) return arrowW;
      return painters[i].width;
    }

    const capPadX = 6.0;
    const gap = 2.0;
    var w = 0.0;
    for (var i = 0; i < parts.length; i++) {
      w += partW(i) + (parts[i].$2 ? capPadX * 2 + gap * 2 : 0);
    }
    const padX = 12.0;
    const h = 32.0;
    final size = Size(w + padX * 2, h);
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final plate = RRect.fromRectAndRadius(
      Rect.fromLTWH(-size.width / 2, -h, size.width, h),
      const Radius.circular(8),
    );
    c.drawRRect(plate, Paint()..color = const Color(0xE01A100A));
    c.drawRRect(
      plate,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xCCD9A866),
    );
    // Levhanın altında durağı gösteren küçük bir uç.
    c.drawPath(
      Path()
        ..moveTo(-6, 0)
        ..lineTo(0, 7)
        ..lineTo(6, 0)
        ..close(),
      Paint()..color = const Color(0xE01A100A),
    );
    var x = -size.width / 2 + padX;
    for (var i = 0; i < parts.length; i++) {
      final tp = painters[i];
      if (parts[i].$2) {
        x += gap;
        final pw = partW(i);
        final cap = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, -h + 5, pw + capPadX * 2, h - 10),
          const Radius.circular(4),
        );
        c.drawRRect(
          cap.shift(const Offset(0, 1.5)),
          Paint()..color = const Color(0xFF8A6440),
        );
        c.drawRRect(cap, Paint()..color = const Color(0xFFF2DDB4));
        final a = arrow(parts[i].$1);
        if (a != null) {
          c.save();
          c.translate(x + capPadX + pw / 2, -h / 2);
          c.rotate(a);
          final ink = Paint()..color = capInk;
          c.drawRect(const Rect.fromLTWH(-5, -1.3, 6, 2.6), ink);
          c.drawPath(
            Path()
              ..moveTo(6, 0)
              ..lineTo(0, -5)
              ..lineTo(0, 5)
              ..close(),
            ink,
          );
          c.restore();
        } else {
          tp.paint(c, Offset(x + capPadX, -h / 2 - tp.height / 2));
        }
        x += pw + capPadX * 2 + gap;
      } else {
        tp.paint(c, Offset(x, -h / 2 - tp.height / 2));
        x += tp.width;
      }
    }
    final pic = rec.endRecording();
    _cache[id] = pic;
    _sizes[id] = size;
    return pic;
  }

  @override
  void render(Canvas canvas) {
    final l = _shown;
    if (l == null || _alpha < 0.02) return;
    final pic = _picture(l.key);
    final size = _sizes[_id(l.key)]!;
    // Levha durağın üstünde hafifçe süzülür; ekranın kenarından taşmaz
    // (bölümün başında kamera duvara dayalıyken).
    final bob = math.sin(_t * 2.2) * 2;
    final view = game.camera.visibleWorldRect;
    final half = size.width / 2 + 8;
    var x = (l.col + 0.5) * kTile;
    if (view.width > half * 2) {
      x = x.clamp(view.left + half, view.right - half);
    }
    canvas.save();
    canvas.translate(x, l.row * kTile + bob);
    canvas.saveLayer(
      null,
      Paint()..color = Color.fromRGBO(0, 0, 0, _alpha.clamp(0.0, 1.0)),
    );
    canvas.drawPicture(pic);
    canvas.restore();
    canvas.restore();
  }

  @override
  void onRemove() {
    for (final p in _cache.values) {
      p.dispose();
    }
    _cache.clear();
    super.onRemove();
  }
}
