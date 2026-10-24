import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

/// "Kızıl kül" paleti: kömür siluetler, pas tonlu dünya. Sıcak ışık güvenli,
/// fenercilerin soğuk camgöbeği ışığı tehlike demek.
const kInk = Color(0xFF0A0706);
const kCloud = Color(0xFF24161A);
const kLight = Color(0xFFF7EEE2);
const kText = Color(0xFFEBDDCB);
const kEmber = Color(0xFFE0703A);
const kWarmLight = Color(0xFFFFD9A0);
const kCold = Color(0xFF7FE6D2);

/// Gözcü'nün projektörü: Kandilci fenerinin nane yeşilinden ayrı, soluk mor
/// (ikisi farklı düzenek; renkten seçilsin).
const kWatch = Color(0xFFB9A2FF);

/// Işık kenarı yumuşaklığı: huzmelerin yanı ve kayada kesildiği yer cetvel
/// gibi değil, ışık gibi dağılsın. Bulanıklık filtresi yok (pahalı ve
/// cihazdan cihaza farklı): huzme giderek daralan katmanlarla, kayadaki
/// gölge birkaç komşu noktadan gelen ışıkla (yarı gölge) çizilir. Düşük
/// grafikte tek katman.
class SoftEdge {
  static bool on = true;

  /// Önizleme ve testler için zorla aç/kapat.
  static bool? force;

  /// Huzme katmanlarının genişliği (tam huzmeye oranla).
  static List<double> get widths =>
      on ? const [1.0, 0.84, 0.68, 0.52] : const [1.0];

  /// Huzmeyi katman katman çizer: [shape] verilen genişlik oranında şekli
  /// kurar; [paint]'in saydamlığı katmanlara bölünür, toplamı aynı kalır.
  static void beam(Canvas canvas, Path Function(double k) shape, Paint paint) {
    final ws = widths;
    final a = paint.color.a;
    // Katmanlar üst üste bindikçe saydamlık birikir: ortada tek katmanlı
    // eski huzmeye yakın, kenara doğru kademe kademe söner.
    final each = math.min(1.0, a * 1.3 / ws.length);
    paint.color = paint.color.withValues(alpha: each);
    for (final k in ws) {
      canvas.drawPath(shape(k), paint);
    }
    paint.color = paint.color.withValues(alpha: a);
  }

  /// [beam] gibi, ama katmanların yolları hazır (ör. kayada kesilmiş).
  /// [antiAlias] false: kenar yumuşatmasız (katmanların kenarı zaten
  /// degradeyle söner; Skia'da girintili yolu yumuşatmak pahalı).
  static void paths(
    Canvas canvas,
    List<Path> layers,
    Paint paint, {
    bool antiAlias = true,
  }) {
    if (layers.isEmpty) return;
    final a = paint.color.a;
    final aa = paint.isAntiAlias;
    paint.isAntiAlias = antiAlias;
    paint.color = paint.color.withValues(
      alpha: math.min(1.0, a * 1.3 / layers.length),
    );
    for (final p in layers) {
      canvas.drawPath(p, paint);
    }
    paint.color = paint.color.withValues(alpha: a);
    paint.isAntiAlias = aa;
  }
}

Color lerpColor(int a, int b, double t) =>
    Color.lerp(Color(a), Color(b), t.clamp(0.0, 1.0))!;

/// Yumuşak ışık lekesi. Bulanıklık filtresi yerine radyal degrade kullanır:
/// görüntü aynı, ama dahili ekran kartlarında çok daha ucuz.
void glowDot(
  Canvas canvas,
  Offset c,
  double radius,
  Color color,
  double alpha,
) {
  if (alpha <= 0 || radius <= 0) return;
  canvas.drawCircle(
    c,
    radius,
    Paint()
      ..shader = ui.Gradient.radial(
        c,
        radius,
        [
          color.withValues(alpha: alpha),
          color.withValues(alpha: alpha * 0.45),
          color.withValues(alpha: 0),
        ],
        const [0, 0.4, 1],
      ),
  );
}

/// Görsel yön denemesi: karikatürize hayal perdesi (konsept:
/// docs/konsept/karikaturize-yerebatan-v1.png). Şimdilik yalnız Yerebatan'da
/// ve yalnız önizleme/geliştirici anahtarıyla açılır; oyunun görünümü değişmez.
class Cartoon {
  Cartoon._();

  /// `--dart-define=CARTOON=true` ile açık başlar; deneme yapısında K tuşu.
  static bool on = const bool.fromEnvironment('CARTOON');

  /// Deneme yapısı mı (CARTOON ya da DEV tanımlı): ayarlar panelinde
  /// denemeyi açıp kapatan anahtar ve ton kaydırıcısı görünür (dokunmatikte
  /// K tuşu yok).
  static const bool trialBuild =
      bool.fromEnvironment('CARTOON') || bool.fromEnvironment('DEV');

  /// Sâye'nin karikatürize görünüşü: bütün bölümlerde açık.
  static bool saye = true;

  /// Sarnıcın tonu: 0 = oyunun orijinal renkleri (denemenin taş sıraları,
  /// ışık alan kenarları, oymalı sütunları ve kemerleriyle), 1 = konseptteki
  /// kadar aydınlık. Varsayılan 0,35 (ayarlarda "Renk tonu"); arazi bu değer
  /// 0,05'lik adımla değişince yeniden çizilir.
  static double tone = 0.35;

  static double get toneStep => (tone * 20).round() / 20;

  static Color _mix(int dark, int bright) =>
      Color.lerp(Color(dark), Color(bright), toneStep)!;
  static double _num(double dark, double bright) =>
      dark + (bright - dark) * toneStep;

  // Arka plan: koyu kiremitten patlıcan morusuna.
  static Color get skyTop => _mix(0xFF0E0807, 0xFF241521);
  static Color get skyMid => _mix(0xFF2A140D, 0xFF3E2430);
  static Color get skyLow => _mix(0xFF3A1A10, 0xFF5A3428);
  static Color get farCol => _mix(0xFF3A1E14, 0xFF52303A);
  static Color get archRim => _mix(0xFF5A3020, 0xFF7A4A40);
  static double get windowGlow => _num(0.09, 0.18);

  // Taş: koyu gövde, ışık alan üst dudak.
  static Color get stone => _mix(0xFF140B08, 0xFF34211E);
  static Color get stoneDeep => _mix(0xFF0A0706, 0xFF221513);
  static Color get stoneBottom => _mix(0xFF0A0706, 0xFF1A1016);
  static Color get lip => _mix(0xFF925E35, 0xFFC08458);
  static Color get lipHot => _mix(0xFFC07A44, 0xFFF0B57A);
  static Color get seam => _mix(0xFF050302, 0xFF1A100F);
  static Color get backCol => _mix(0xFF1C100B, 0xFF2E1A22);
  static List<Color> get colGrad => [
    _mix(0xFF3A2216, 0xFF6E4636),
    _mix(0xFF1E110B, 0xFF4A2E26),
    _mix(0xFF0C0605, 0xFF2A1A17),
  ];

  // Su.
  static Color get water => _mix(0xFF381A10, 0xFF1C1220);
  static Color get waterDeep => _mix(0xFF0A0504, 0xFF0B0710);
  static const glint = Color(0xFFE8A060);

  // Aydınlık ve ekran etkileri.
  static double get darkness => _num(0.48, 0.2);
  static double get vignette => _num(1.0, 0.45);
  static double get fog => _num(0.05, 0.02);
  static double get beam => _num(1.0, 1.6);

  // Karakterler: kömür, ışık tarafında ikinci ton.
  static const char = Color(0xFF161011);
  static const charLit = Color(0xFF3C2A28);
  static const scarf = Color(0xFFB0402E);

  // Işıklar: güvenli kehribar, tehlikeli nane-camgöbeği.
  static const amber = Color(0xFFFFB648);
  static Color get danger => _mix(0xFF7FE6D2, 0xFF6AEAD6);
}

/// Görsel deneme: ışık ve derinlik (Yerebatan). Işığa bakan taş kenarları
/// parlar, ışıklar çevresine taşar, su sahneyi dalgalı yansıtır; arka plan
/// pusla ve bulanıklıkla geriye çekilir, kameranın önünden koyu bir ön plan
/// katmanı daha hızlı kayar. Deneme yapısında açık başlar; ayarlar panelinden
/// ya da L tuşuyla açılıp kapanır. Düşük grafikte kapalıdır.
class Realism {
  Realism._();

  static bool on = Cartoon.trialBuild;

  /// Ölçüm için parça parça kapatma (yalnız araçlar kullanır).
  static bool debugNoFar = false;
  static bool debugNoLight = false;
  static bool debugNoNear = false;
  static bool debugNoReflect = false;
}
