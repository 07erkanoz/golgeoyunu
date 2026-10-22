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

  /// Sarnıcın tonu: 0 = bugünkü kadar karanlık (ayrıntılar kalır),
  /// 1 = konseptteki kadar aydınlık. Geliştirici ayarından kaydırılır;
  /// arazi bu değer 0,05'lik adımla değişince yeniden çizilir.
  static double tone = 0.35;

  static double get toneStep => (tone * 20).round() / 20;

  static Color _mix(int dark, int bright) =>
      Color.lerp(Color(dark), Color(bright), toneStep)!;
  static double _num(double dark, double bright) =>
      dark + (bright - dark) * toneStep;

  // Arka plan: koyu kiremitten patlıcan morusuna.
  static Color get skyTop => _mix(0xFF0E0807, 0xFF241521);
  static Color get skyMid => _mix(0xFF22110F, 0xFF3E2430);
  static Color get skyLow => _mix(0xFF32180E, 0xFF5A3428);
  static Color get farCol => _mix(0xFF2A1515, 0xFF52303A);
  static Color get archRim => _mix(0xFF552E20, 0xFF7A4A40);
  static double get windowGlow => _num(0.09, 0.18);

  // Taş: koyu gövde, ışık alan üst dudak.
  static Color get stone => _mix(0xFF170D09, 0xFF34211E);
  static Color get stoneDeep => _mix(0xFF0B0605, 0xFF221513);
  static Color get stoneBottom => _mix(0xFF080504, 0xFF1A1016);
  static Color get lip => _mix(0xFF8E5634, 0xFFC08458);
  static Color get lipHot => _mix(0xFFBE7C4A, 0xFFF0B57A);
  static Color get seam => _mix(0xFF080504, 0xFF1A100F);
  static Color get backCol => _mix(0xFF160B0D, 0xFF2E1A22);
  static List<Color> get colGrad => [
    _mix(0xFF3A2218, 0xFF6E4636),
    _mix(0xFF22140E, 0xFF4A2E26),
    _mix(0xFF0E0806, 0xFF2A1A17),
  ];

  // Su.
  static Color get water => _mix(0xFF160C0E, 0xFF1C1220);
  static Color get waterDeep => _mix(0xFF060404, 0xFF0B0710);
  static const glint = Color(0xFFE8A060);

  // Aydınlık ve ekran etkileri.
  static double get darkness => _num(0.46, 0.2);
  static double get vignette => _num(0.95, 0.45);
  static double get fog => _num(0.05, 0.02);
  static double get beam => _num(1.15, 1.6);

  // Karakterler: kömür, ışık tarafında ikinci ton.
  static const char = Color(0xFF161011);
  static const charLit = Color(0xFF3C2A28);
  static const scarf = Color(0xFFB0402E);

  // Işıklar: güvenli kehribar, tehlikeli nane-camgöbeği.
  static const amber = Color(0xFFFFB648);
  static const danger = Color(0xFF6AEAD6);
}

/// Görsel deneme: ışık ve derinlik (Yerebatan). Işığa bakan taş kenarları
/// parlar, ışıklar çevresine taşar, su sahneyi dalgalı yansıtır; arka plan
/// pusla ve bulanıklıkla geriye çekilir, kameranın önünden koyu bir ön plan
/// katmanı daha hızlı kayar. Deneme yapısında açık başlar; ayarlar panelinden
/// ya da L tuşuyla açılıp kapanır. Düşük grafikte kapalıdır.
class Realism {
  Realism._();

  static bool on = Cartoon.trialBuild;
}
