import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'game/strings.dart';

/// Oyuncu ayarları: ses seviyeleri, dil ve tam ekran. Cihazda saklanır.
class Settings {
  Settings._();

  static double ambience = 0.7;
  static double music = 0.6;
  static double effects = 0.8;
  static bool fullscreen = false;

  /// Düşük grafik: sis, film greni, titreme ve ağır ışık katmanı kapalı;
  /// dahili ekran kartları için.
  static bool lowGraphics = false;

  /// Dokunmatik kontrol: düğmeler ya da hareket (sürükle / dokun).
  static bool touchGestures = true;

  /// Parlaklık (0.8 – 1.3): atmosferi bozmayacak dar bir aralık.
  static double brightness = 1.0;

  /// Dokunmatik düğmelerin görünürlüğü (0.1 – 1).
  static double touchOpacity = 0.7;

  static SharedPreferences? _prefs;

  static Future<void> load({bool lowGraphicsByDefault = false}) async {
    lowGraphics = lowGraphicsByDefault;
    try {
      final p = _prefs = await SharedPreferences.getInstance();
      ambience = p.getDouble('ambience') ?? ambience;
      music = p.getDouble('music') ?? music;
      effects = p.getDouble('effects') ?? effects;
      fullscreen = p.getBool('fullscreen') ?? fullscreen;
      lowGraphics = p.getBool('low_graphics') ?? lowGraphics;
      touchGestures = p.getBool('touch_gestures') ?? touchGestures;
      touchOpacity = p.getDouble('touch_opacity') ?? touchOpacity;
      brightness = (p.getDouble('brightness') ?? brightness).clamp(0.8, 1.3);
      S.lang = p.getString('lang') == 'en' ? Lang.en : Lang.tr;
      SaveGame.current = SaveData.decode(p.getString('save'));
    } catch (_) {
      // Ayarlar okunamazsa varsayılanlarla devam edilir.
    }
  }

  static Future<void> save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setDouble('ambience', ambience);
    await p.setDouble('music', music);
    await p.setDouble('effects', effects);
    await p.setBool('fullscreen', fullscreen);
    await p.setBool('low_graphics', lowGraphics);
    await p.setBool('touch_gestures', touchGestures);
    await p.setDouble('touch_opacity', touchOpacity);
    await p.setDouble('brightness', brightness);
    await p.setString('lang', S.en ? 'en' : 'tr');
  }
}

/// Kaldığın yer: bölüm, son kontrol noktası, toplananlar.
class SaveData {
  SaveData({
    required this.level,
    required this.x,
    required this.y,
    required this.memories,
    required this.whispers,
    required this.fireflies,
    required this.wings,
  });

  final int level;
  final double x;
  final double y;
  final List<String> memories;
  final List<String> whispers;
  final int fireflies;
  final bool wings;

  String encode() => jsonEncode({
    'level': level,
    'x': x,
    'y': y,
    'memories': memories,
    'whispers': whispers,
    'fireflies': fireflies,
    'wings': wings,
  });

  static SaveData? decode(String? raw) {
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return SaveData(
        level: m['level'] as int,
        x: (m['x'] as num).toDouble(),
        y: (m['y'] as num).toDouble(),
        memories: [...(m['memories'] as List).cast<String>()],
        whispers: [...(m['whispers'] as List).cast<String>()],
        fireflies: m['fireflies'] as int,
        wings: m['wings'] as bool,
      );
    } catch (_) {
      return null;
    }
  }
}

class SaveGame {
  SaveGame._();

  static SaveData? current;

  static Future<void> write(SaveData data) async {
    current = data;
    await Settings._prefs?.setString('save', data.encode());
  }

  static Future<void> clear() async {
    current = null;
    await Settings._prefs?.remove('save');
  }
}
