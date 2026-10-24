import 'dart:convert';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game/levels.dart';
import 'game/palette.dart';
import 'game/strings.dart';

/// Oyuncu ayarları: ses seviyeleri, dil ve tam ekran. Cihazda saklanır.
class Settings {
  Settings._();

  static double ambience = 0.7;
  static double music = 0.6;
  static double effects = 0.8;
  static bool fullscreen = false;

  /// Düşük grafik: sis, film greni, titreme ve ağır ışık katmanı kapalı;
  /// dahili ekran kartları için. Varsayılan yüksek.
  static bool lowGraphics = false;

  /// Düşük grafiği otomatik kalite açtı (oyuncu seçmedi): o oturuma özgüdür,
  /// kaydedilmez; bir sonraki açılışta oyuncunun seçimi geri gelir.
  static bool autoLowered = false;

  /// Yüksek yenileme hızı (Android, 90/120 Hz ve üstü ekranlarda): açıkken
  /// telefonun en yüksek hızı istenir (daha akıcı, pil biraz daha çabuk
  /// biter). Oyunun fiziği 120 ve 144 Hz'de de sınanır.
  static bool highRefresh = false;

  /// Otomatik kalite: cihaz zorlanırsa ağır görseller kendiliğinden kapanır.
  /// Varsayılan kapalı: oyuncunun seçtiği ışık ve grafik kendiliğinden
  /// değişmesin; ayarlardan açılabilir.
  static bool autoQuality = false;

  /// Dokunmatik kontrol: düğmeler ya da hareket (sürükle / dokun).
  static bool touchGestures = true;

  /// Parlaklık (0.6 – 1.6): karanlık örtüyü ve ekranın genel ışığını ayarlar.
  static double brightness = defaultBrightness;
  static const defaultBrightness = 0.85;

  /// Hikâye fısıltıları ekranda (kapalıyken yalnız "Az önce" panelinde;
  /// oynanışı anlatan sözler yine söylenir). İkinci oynayış için.
  static bool storyWhispers = true;

  /// Anlatım sesi: fısıltılar, hatıralar ve perde seslendirilir (sesi
  /// olan satırlar). Kapalıyken yalnız yazı.
  static bool voice = true;

  /// Altyazı: seslendirilen satırın yazısı da görünür (varsayılan kapalı:
  /// ses varken yazı gösterilmez; sesi olmayan satırlar hep yazıdır).
  static bool subtitles = false;

  /// Anlatım sesinin düzeyi (0 – 1).
  static double voiceVolume = 0.9;

  /// İpuçları ekranda (kapalıyken yalnız "Az önce" panelinde).
  static bool hints = true;

  /// İpucu simgesinin yeri bir kez gösterildi (ilk yanışta balon).
  static bool hintIntroSeen = false;

  /// Daha önce izlenen perdeler atlanır (ilk kez izlenen yine oynar).
  static bool skipSeenPerde = false;

  /// İzlenmiş perdeler: "prologue" ya da perdenin ardındaki bölümün sırası.
  static final seenPerde = <String>{};

  /// Bulunan sırlar ve sürprizler ("bölüm:ad"): oyundan oyuna kalır;
  /// Defter'de kaç tanesinin bulunduğu görünür (yerleri söylenmez).
  static final secrets = <String>{};

  /// Yazı büyüklüğü (0.8 – 1.6): fısıltı, ipucu, efsane kartı ve perde
  /// satırları bununla büyür.
  static double textScale = 1.0;

  /// Ulaşılan en ileri bölüm: bölüm listesinde buraya kadarı açıktır.
  static int unlocked = 0;

  /// Oyun sonuna dek oynandı mı (son perde izlendi). Son bölüme ulaşmak
  /// yetmez: Hikâye tiyatrosu sonu ancak bu doğruysa oynar.
  static bool finished = false;

  /// Gizli dokunuşla her şey açıldı: bütün bölümler, Hikâye'nin bütün
  /// perdeleri (son dahil) ve Defter'in bütün hatıraları ve efsaneleri.
  static bool allOpen = false;

  /// Deneme ayarları (kaydedilir): renk ve doku, ışık ve derinlik, ölçüm
  /// göstergesi, renk tonu. Otomatik kalitenin oyun sırasında ışığı
  /// kapatması tercih sayılmaz (kaydedilmez).
  static bool texture = Cartoon.trialBuild;
  static bool realism = Cartoon.trialBuild;
  static bool perf = false;
  static double tone = defaultTone;
  static const defaultTone = 0.35;

  /// Kayıtlı ayarların sürümü: varsayılanlar değişince eski kayıttaki
  /// görüntü ayarları bir kez yeni varsayılana çekilir.
  static const _version = 2;

  /// Dokunmatik düğmelerin görünürlüğü (0.1 – 1).
  static double touchOpacity = 0.7;

  /// Dokunmatik düğmelerin boyutu (0.75 – 1.4).
  static double touchScale = 1.0;

  /// Sol elle oynama: yürüme sağda, zıplama ve eylemler solda.
  static bool leftHanded = false;

  /// Erişilebilirlik: ekran sarsıntısı ve ani beyaz parlamalar (şimşek,
  /// korku anı, yakalanma) büyük ölçüde azaltılır.
  static bool calmEffects = false;

  /// Sarsıntı ve parlamaların çarpanı.
  static double get flashScale => calmEffects ? 0.25 : 1;

  static SharedPreferences? _prefs;

  /// Testler için: ayar deposu yeniden açılır (sahte değerler okunsun).
  static void debugReopen() => _prefs = null;

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

  static Future<void> load() async {
    S.lang = deviceLang();
    final p = await _open();
    // Sayı değeri: sonlu ve aralıkta değilse varsayılan kalır.
    double num(String key, double fallback, double lo, double hi) {
      final v = p == null ? null : _read(() => p.getDouble(key));
      if (v == null || !v.isFinite) return fallback;
      return v.clamp(lo, hi);
    }

    ambience = num('ambience', ambience, 0, 1);
    music = num('music', music, 0, 1);
    effects = num('effects', effects, 0, 1);
    touchOpacity = num('touch_opacity', touchOpacity, 0.1, 1);
    brightness = num('brightness', brightness, 0.6, 1.6);
    textScale = num('text_scale', textScale, 0.8, 1.6);
    voiceVolume = num('voice_volume', voiceVolume, 0, 1);
    touchScale = num('touch_scale', touchScale, 0.75, 1.4);
    tone = num('tone', tone, 0, 1);
    if (p != null) {
      fullscreen = _read(() => p.getBool('fullscreen')) ?? fullscreen;
      lowGraphics = _read(() => p.getBool('low_graphics')) ?? lowGraphics;
      touchGestures = _read(() => p.getBool('touch_gestures')) ?? touchGestures;
      calmEffects = _read(() => p.getBool('calm_effects')) ?? calmEffects;
      leftHanded = _read(() => p.getBool('left_handed')) ?? leftHanded;
      highRefresh = _read(() => p.getBool('high_refresh')) ?? highRefresh;
      autoQuality = _read(() => p.getBool('auto_quality')) ?? autoQuality;
      finished = _read(() => p.getBool('finished')) ?? finished;
      allOpen = _read(() => p.getBool('all_open')) ?? allOpen;
      texture = _read(() => p.getBool('texture')) ?? texture;
      realism = _read(() => p.getBool('realism')) ?? realism;
      perf = _read(() => p.getBool('perf')) ?? perf;
      storyWhispers = _read(() => p.getBool('story_whispers')) ?? storyWhispers;
      hints = _read(() => p.getBool('hints')) ?? hints;
      voice = _read(() => p.getBool('voice')) ?? voice;
      subtitles = _read(() => p.getBool('subtitles')) ?? subtitles;
      hintIntroSeen =
          _read(() => p.getBool('hint_intro_seen')) ?? hintIntroSeen;
      skipSeenPerde =
          _read(() => p.getBool('skip_seen_perde')) ?? skipSeenPerde;
      seenPerde
        ..clear()
        ..addAll(_read(() => p.getStringList('seen_perde')) ?? const []);
      secrets
        ..clear()
        ..addAll(_read(() => p.getStringList('secrets')) ?? const []);
      // Kayıtlı bir tercih yoksa cihazın dili: Türkçe değilse İngilizce.
      final lang = _read(() => p.getString('lang'));
      S.lang = switch (lang) {
        'en' => Lang.en,
        'tr' => Lang.tr,
        _ => deviceLang(),
      };
    }
    // Kayıt iki yerde tutulur (ayar deposu ve uygulamanın kendi dosyası).
    // Ayar deposu açılamasa da dosya mutlaka okunur; ikisi de varsa en yenisi.
    final fromPrefs = p == null
        ? null
        : SaveData.decode(_read(() => p.getString('save')));
    final fromFile = SaveData.decode(await SaveGame._readFile());
    SaveGame.current = SaveData.newer(fromPrefs, fromFile);
    // Eski kayıt: görüntü ayarları yeni varsayılanlara (renk tonu 35,
    // parlaklık 85, ışık ve derinlik açık, grafik yüksek, otomatik kalite
    // kapalı) bir kez çekilir.
    final version = p == null ? null : _read(() => p.getInt('settings_v'));
    if ((version ?? 0) < _version) {
      tone = defaultTone;
      brightness = defaultBrightness;
      lowGraphics = false;
      autoQuality = false;
      texture = Cartoon.trialBuild;
      realism = Cartoon.trialBuild;
    }
    // "unlocked": oynanış sırasındaki en ileri yer. Sıra değiştiyse (yeni
    // bölümler araya girdiyse) eski yer yeni sıraya çevrilir.
    final u = p == null ? null : _read(() => p.getInt('unlocked'));
    final v = p == null ? null : _read(() => p.getInt('unlockedOrder'));
    unlocked = migrateOrderPosition(
      (u ?? 0).clamp(0, 99),
      v ?? 1,
    ).clamp(0, levelOrder.length - 1);
    final reached = orderOf(SaveGame.current?.level ?? 0);
    if (reached > unlocked) unlocked = reached;
    if (allOpen) unlocked = levelOrder.length - 1;
    // Deneme ayarları yalnızca deneme yapısında uygulanır.
    if (Cartoon.trialBuild) {
      Cartoon.on = texture;
      Realism.on = realism;
      Cartoon.tone = tone;
    }
    if ((version ?? 0) < _version) await save();
  }

  static Future<void> save() async {
    final p = await _open();
    if (p == null) return;
    try {
      await p.setDouble('ambience', ambience);
      await p.setDouble('music', music);
      await p.setDouble('effects', effects);
      await p.setBool('fullscreen', fullscreen);
      await p.setBool('low_graphics', lowGraphics && !autoLowered);
      await p.setBool('touch_gestures', touchGestures);
      await p.setBool('calm_effects', calmEffects);
      await p.setBool('left_handed', leftHanded);
      await p.setBool('high_refresh', highRefresh);
      await p.setBool('auto_quality', autoQuality);
      await p.setDouble('touch_scale', touchScale);
      await p.setDouble('touch_opacity', touchOpacity);
      await p.setDouble('brightness', brightness);
      await p.setDouble('text_scale', textScale);
      await p.setString('lang', S.en ? 'en' : 'tr');
      await p.setInt('unlocked', unlocked);
      await p.setBool('finished', finished);
      await p.setBool('all_open', allOpen);
      await p.setBool('texture', texture);
      await p.setBool('realism', realism);
      await p.setBool('perf', perf);
      await p.setDouble('tone', tone);
      await p.setBool('story_whispers', storyWhispers);
      await p.setBool('hints', hints);
      await p.setBool('voice', voice);
      await p.setBool('subtitles', subtitles);
      await p.setDouble('voice_volume', voiceVolume);
      await p.setBool('hint_intro_seen', hintIntroSeen);
      await p.setBool('skip_seen_perde', skipSeenPerde);
      await p.setStringList('seen_perde', seenPerde.toList());
      await p.setStringList('secrets', secrets.toList());
      await p.setInt('unlockedOrder', levelOrderVersion);
      await p.setInt('settings_v', _version);
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
    this.puzzle = const {},
    int? time,
  }) : time = time ?? DateTime.now().millisecondsSinceEpoch;

  final int level;
  final double x;
  final double y;
  final List<String> memories;
  final List<String> whispers;
  final int fireflies;
  final bool wings;

  /// Kontrol noktasındaki bulmaca durumu (açılan kapılar, çekilen kollar,
  /// alınan tüyler, sürülen sandıklar...): devam edince dünya böyle kurulur.
  final Map<String, Object?> puzzle;

  /// Yazıldığı an: iki kopyadan yenisini seçmek için.
  final int time;

  /// Bozuk ya da anlamsız değerli kayıt yok sayılır (oyun açılabilsin).
  SaveData? _valid() {
    if (level < 0 || level > 99) return null;
    if (!x.isFinite || !y.isFinite || x.abs() > 1e6 || y.abs() > 1e6) {
      return null;
    }
    if (fireflies < 0 || fireflies > 99) return null;
    return this;
  }

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
    'puzzle': puzzle,
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
        // Eski kayıtlarda yok; bozuksa bulmacalar baştan kurulur.
        puzzle: m['puzzle'] is Map
            ? Map<String, Object?>.from(m['puzzle'] as Map)
            : const {},
        time: (m['time'] as num?)?.toInt() ?? 0,
      )._valid();
    } catch (_) {
      return null;
    }
  }
}

class SaveGame {
  SaveGame._();

  static SaveData? current;

  /// Bütün kayıt işlemleri (yazma ve silme) tek sırada, geldiği düzende
  /// çalışır: "Yeni oyun"un eski kaydı silmesi yeni kaydı silemez; iki
  /// yazma aynı geçici dosyayı aynı anda kullanamaz.
  static Future<void> _queue = Future.value();

  static Future<void> _enqueue(Future<void> Function() op) {
    final next = _queue.then((_) => op()).catchError((_) {});
    _queue = next;
    return next;
  }

  /// Sıradaki bütün işlemler bitene kadar bekler (kapanışta).
  static Future<void> flush() => _queue;

  static Future<void> write(SaveData data) {
    // Sayı olmayan bir konum kaydın tamamını düşürmesin.
    if (!data.x.isFinite || !data.y.isFinite) return _queue;
    current = data;
    final json = data.encode();
    return _enqueue(() => _write(json));
  }

  static Future<void> _write(String json) async {
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

  static Future<void> clear() {
    current = null;
    return _enqueue(_clear);
  }

  static Future<void> _clear() async {
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
