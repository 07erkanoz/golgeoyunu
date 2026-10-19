/// Oyunun dilleri ve arayüz metinleri.
enum Lang { tr, en }

class S {
  S._();

  static Lang lang = Lang.tr;

  static bool get en => lang == Lang.en;

  static String of(String key) => (en ? _en : _tr)[key] ?? _tr[key] ?? key;

  static const _tr = {
    'gameTitle': 'GÖLGE OYUNU',
    'menuSubtitle': 'İstanbul, 1660',
    'continue': 'Kaldığın yerden devam et',
    'newGame': 'Yeni oyun',
    'confirmNew': 'Emin misin? Kayıt silinecek',
    'settings': 'Ayarlar',
    'quit': 'Çıkış',
    'settingsTitle': 'AYARLAR',
    'ambience': 'Ortam sesi',
    'music': 'Müzik',
    'effects': 'Efekt sesleri',
    'fullscreen': 'Tam ekran  (F11)',
    'language': 'Dil',
    'retry': 'Yeniden dene',
    'resume': 'Devam',
    'close': 'Kapat',
    'mainMenu': 'Ana menü',
    'controls':
        'Esc: menü · ← → yürü · Boşluk zıpla · ↑ tırman / kol çek\n'
        '↓ çömel · Shift parmak ucu · F ateşböceği · R yeniden dene',
    'memoryCounter': 'hatıra',
    'skipHint': 'boşluk / dokun',
    'chase': 'Arkanda bir şey var. KOŞ.',
    'wings':
        'Hezarfen\'in kanatları! Havadayken zıplamayı basılı tut: süzülürsün.',
    'memoriesFound': 'Toplanan hatıralar',
    'musicCredit': 'Menü müziği: vjgalaxy · Pixabay',
  };

  static const _en = {
    'gameTitle': 'SHADOW PLAY',
    'menuSubtitle': 'Istanbul, 1660',
    'continue': 'Continue',
    'newGame': 'New game',
    'confirmNew': 'Are you sure? Your save will be erased',
    'settings': 'Settings',
    'quit': 'Quit',
    'settingsTitle': 'SETTINGS',
    'ambience': 'Ambience',
    'music': 'Music',
    'effects': 'Sound effects',
    'fullscreen': 'Fullscreen  (F11)',
    'language': 'Language',
    'retry': 'Retry',
    'resume': 'Resume',
    'close': 'Close',
    'mainMenu': 'Main menu',
    'controls':
        'Esc: menu · ← → walk · Space jump · ↑ climb / pull lever\n'
        '↓ crouch · Shift tiptoe · F firefly · R retry',
    'memoryCounter': 'memories',
    'skipHint': 'space / tap',
    'chase': 'Something is behind you. RUN.',
    'wings': 'Hezarfen\'s wings! Hold jump in the air to glide.',
    'memoriesFound': 'Memories found',
    'musicCredit': 'Menu music: vjgalaxy · Pixabay',
  };
}
