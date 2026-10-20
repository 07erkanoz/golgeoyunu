import 'dart:convert';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
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

  /// Parlaklık (0.6 – 1.6): karanlık örtüyü ve ekranın genel ışığını ayarlar.
  static double brightness = 1.0;

  /// Dokunmatik düğmelerin görünürlüğü (0.1 – 1).
  static double touchOpacity = 0.7;


  static SharedPreferences? _prefs;

  /// Ayar deposu: açılamazsa bir sonraki kayıtta yeniden denenir.
  static Future<SharedPreferences?> _open() async {
    try {
      return _prefs ??= await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  /// Tek bir değeri okur; bozuk bir kayıt ötekileri götürmez.
  static T? _read<T>(T? Function() get) {
    try {
      return get();
    } catch (_) {
      return null;
    }
  }

  /// Cihazın dili Türkçeyse Türkçe, değilse İngilizce.
  static Lang deviceLang() {
    try {
      final locales = PlatformDispatcher.instance.locales;
      final code = locales.isEmpty ? '' : locales.first.languageCode;
      return code.toLowerCase() == 'tr' ? Lang.tr : Lang.en;
    } catch (_) {
      return Lang.tr;
    }
  }

  static Future<void> load({bool lowGraphicsByDefault = false}) async {
    lowGraphics = lowGraphicsByDefault;
    S.lang = deviceLang();
    final p = await _open();
    if (p == null) return;
    ambience = _read(() => p.getDouble('ambience')) ?? ambience;
    music = _read(() => p.getDouble('music')) ?? music;
    effects = _read(() => p.getDouble('effects')) ?? effects;
    fullscreen = _read(() => p.getBool('fullscreen')) ?? fullscreen;
    lowGraphics = _read(() => p.getBool('low_graphics')) ?? lowGraphics;
    touchGestures = _read(() => p.getBool('touch_gestures')) ?? touchGestures;
    touchOpacity = _read(() => p.getDouble('touch_opacity')) ?? touchOpacity;
    brightness = (_read(() => p.getDouble('brightness')) ?? brightness).clamp(
      0.6,
      1.6,
    );
    // Kayıtlı bir tercih yoksa cihazın dili: Türkçe değilse İngilizce.
    final lang = _read(() => p.getString('lang'));
    S.lang = switch (lang) {
      'en' => Lang.en,
      'tr' => Lang.tr,
      _ => deviceLang(),
    };
    // Kayıt iki yerde tutulur (ayar deposu ve uygulamanın kendi dosyası):
    // biri kaybolursa ya da bozulursa öteki; ikisi de varsa en yenisi.
    final fromPrefs = SaveData.decode(_read(() => p.getString('save')));
    final fromFile = SaveData.decode(await SaveGame._readFile());
    SaveGame.current = SaveData.newer(fromPrefs, fromFile);
  }

  static Future<void> save() async {
    final p = await _open();
    if (p == null) return;
    try {
      await p.setDouble('ambience', ambience);
      await p.setDouble('music', music);
      await p.setDouble('effects', effects);
      await p.setBool('fullscreen', fullscreen);
      await p.setBool('low_graphics', lowGraphics);
      await p.setBool('touch_gestures', touchGestures);
      await p.setDouble('touch_opacity', touchOpacity);
      await p.setDouble('brightness', brightness);
      await p.setString('lang', S.en ? 'en' : 'tr');
    } catch (_) {
      // Yazılamazsa bir sonraki değişiklikte yeniden denenir.
    }
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
    int? time,
  }) : time = time ?? DateTime.now().millisecondsSinceEpoch;

  final int level;
  final double x;
  final double y;
  final List<String> memories;
  final List<String> whispers;
  final int fireflies;
  final bool wings;

  /// Yazıldığı an: iki kopyadan yenisini seçmek için.
  final int time;

  static SaveData? newer(SaveData? a, SaveData? b) {
    if (a == null) return b;
    if (b == null) return a;
    return b.time > a.time ? b : a;
  }

  String encode() => jsonEncode({
    'time': time,
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
        time: (m['time'] as num?)?.toInt() ?? 0,
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
    // Sayı olmayan bir konum kaydın tamamını düşürmesin.
    if (!data.x.isFinite || !data.y.isFinite) return;
    current = data;
    final json = data.encode();
    try {
      await (await Settings._open())?.setString('save', json);
    } catch (_) {
      // Bir sonraki kontrol noktasında yeniden denenir.
    }
    try {
      final f = await _file();
      if (f != null) {
        // Önce geçici dosyaya, sonra adını değiştirerek: yarım yazılmış bir
        // kayıt eskisini bozmasın.
        final tmp = File('${f.path}.tmp');
        await tmp.writeAsString(json, flush: true);
        await tmp.rename(f.path);
      }
    } catch (_) {}
  }

  static Future<void> clear() async {
    current = null;
    try {
      await (await Settings._open())?.remove('save');
    } catch (_) {}
    try {
      final f = await _file();
      if (f != null && await f.exists()) await f.delete();
    } catch (_) {}
  }

  static Future<File?> _file() async {
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationSupportDirectory();
      await dir.create(recursive: true);
      return File('${dir.path}/kayit.json');
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _readFile() async {
    try {
      final f = await _file();
      if (f == null || !await f.exists()) return null;
      return await f.readAsString();
    } catch (_) {
      return null;
    }
  }
}
