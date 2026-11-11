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
    const font = 17.0;
    const ink = Color(0xFFFFE9C4);
    const capInk = Color(0xFFFFE9C4);
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
              fontSize: cap ? font - 2 : font,
              fontWeight: cap ? FontWeight.w500 : FontWeight.w300,
              letterSpacing: cap ? 0.2 : 0.6,
              color: cap ? capInk : ink,
              shadows: const [
                Shadow(color: Color(0xD9000000), offset: Offset(1, 1.4)),
              ],
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
    // Kutu yok: oyunun fısıltı yazıları gibi, perdenin üstünde süzülen
    // ince açık yazı. Okunsun diye ardında kenarlara doğru eriyen koyu bir
    // bant; altında ince bir çizgi.
    final band = Rect.fromLTWH(
      -size.width / 2 - 60,
      -h - 3,
      size.width + 120,
      h + 6,
    );
    c.drawRect(
      band,
      Paint()
        ..shader = ui.Gradient.linear(
          band.centerLeft,
          band.centerRight,
          const [
            Color(0x00000000),
            Color(0x8C0A0604),
            Color(0x8C0A0604),
            Color(0x00000000),
          ],
          const [0, 0.22, 0.78, 1],
        ),
    );
    c.drawLine(
      Offset(-size.width * 0.3, 4),
      Offset(size.width * 0.3, 4),
      Paint()
        ..strokeWidth = 0.8
        ..shader = ui.Gradient.linear(
          Offset(-size.width * 0.3, 0),
          Offset(size.width * 0.3, 0),
          const [Color(0x00E0A15F), Color(0x99E0A15F), Color(0x00E0A15F)],
          const [0, 0.5, 1],
        ),
    );
    var x = -size.width / 2 + padX;
    for (var i = 0; i < parts.length; i++) {
      final tp = painters[i];
      if (parts[i].$2) {
        x += gap;
        final pw = partW(i);
        final cap = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, -h + 6, pw + capPadX * 2, h - 12),
          const Radius.circular(5),
        );
        // Tuş: dolu kapak değil, ince çerçeve.
        c.drawRRect(cap, Paint()..color = const Color(0x33FFE9C4));
        c.drawRRect(
          cap,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = const Color(0xCCFFE9C4),
        );
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
    // Ekrana sabit: üstte ortada (eskiden Sâye'nin başının hemen üstünde,
    // dünyaya bağlıydı; oyun alanının ortasında duruyordu). Kamera
    // yakınlaşsa da aynı boyda kalır.
    final view = game.camera.visibleWorldRect;
    final zoom = game.camera.viewfinder.zoom;
    final vh = game.camera.viewport.size.y;
    final k = (vh / 720).clamp(0.8, 1.6) * Settings.textScale / zoom;
    canvas.save();
    canvas.translate(view.center.dx, view.top + view.height * 0.2);
    canvas.scale(k);
    canvas.saveLayer(
      Rect.fromLTWH(
        -size.width / 2 - 64,
        -size.height - 8,
        size.width + 128,
        size.height + 20,
      ),
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
