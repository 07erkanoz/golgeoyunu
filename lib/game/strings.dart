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
    'graphics': 'Grafik',
    'brightness': 'Parlaklık',
    'gfxHigh': 'Yüksek',
    'gfxLow': 'Düşük',
    'touchControls': 'Dokunmatik',
    'touchButtons': 'Düğmeler',
    'touchGestures': 'Hareket',
    'touchOpacity': 'Düğme görünürlüğü',
    'touchHelpGestures':
        'Sol yarı: sürükle → yürü, yukarı → tırman/kol, aşağı → çömel\n'
        'Sağ yarı: dokun → zıpla (basılı tut: süzül) · iki parmak → ateşböceği',
    'hintMove': 'sürükle: yürü',
    'hintJump': 'dokun: zıpla',
    'retry': 'Yeniden dene',
    'resume': 'Devam',
    'close': 'Kapat',
    'mainMenu': 'Ana menü',
    'controls':
        'Esc: menü · ← → yürü · Boşluk zıpla · ↑ tırman / kol çek\n'
        '↓ çömel · Shift parmak ucu · F ateşböceği · R yeniden dene',
    'memoryCounter': 'hatıra',
    'skipHint': 'boşluk / dokun · esc: atla',
    'memoriesGathered': 'Toplanan hatıralar',
    'darkZone': 'Burada karanlık aç. Işığını yiyor.',
    'shadowLooked': 'Gölgen sana baktı. Yoksa sen mi onun gölgesisin?',
    'blizzard': 'Tipi geliyor. Kar her sesi yutar; fenerler bile körleşir.',
    'medusaSealed': 'Kendi bakışına yakalandı. Perseus\'un kalkanı gibi.',
    'feather': 'Simurg\'un tüyü',
    'feathersAll': 'Tüyler tamam. Sunak seni bekliyor.',
    'horoscope': 'Gök, aslanın sırtındaki gibi dizildi. Taşlar yol veriyor.',
    'giantFell': 'Bir sivrisinek bir kralı yıktı; bir ateşböceği de bir devi.',
    'chase': 'Arkanda bir şey nefes alıyor. KOŞ.',
    'wings': 'Hezarfen\'in kanatları. Rüzgâra güvenen düşmez.',
    'memoriesFound': 'Toplanan hatıralar',
    'musicCredit': 'Menü müziği: vjgalaxy · Pixabay',
    'credits': 'Emeği geçenler',
    'musicLicense':
        'Menü müziği: "Turkish Maqam Soundscape", vjgalaxy (Pixabay). '
        'Pixabay İçerik Lisansı ile kullanılmaktadır.\n'
        'Oyun içi sesler ve efektler bu oyun için sentezlenmiştir.',
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
    'graphics': 'Graphics',
    'brightness': 'Brightness',
    'gfxHigh': 'High',
    'gfxLow': 'Low',
    'touchControls': 'Touch',
    'touchButtons': 'Buttons',
    'touchGestures': 'Gestures',
    'touchOpacity': 'Button visibility',
    'touchHelpGestures':
        'Left half: drag → walk, up → climb/lever, down → crouch\n'
        'Right half: tap → jump (hold: glide) · two fingers → firefly',
    'hintMove': 'drag: walk',
    'hintJump': 'tap: jump',
    'retry': 'Retry',
    'resume': 'Resume',
    'close': 'Close',
    'mainMenu': 'Main menu',
    'controls':
        'Esc: menu · ← → walk · Space jump · ↑ climb / pull lever\n'
        '↓ crouch · Shift tiptoe · F firefly · R retry',
    'memoryCounter': 'memories',
    'skipHint': 'space / tap · esc: skip',
    'memoriesGathered': 'Memories gathered',
    'darkZone': 'The dark is hungry here. It feeds on your light.',
    'shadowLooked': 'Your shadow looked at you. Or are you its shadow?',
    'blizzard': 'A blizzard is coming. The snow swallows every sound; even lanterns go blind.',
    'medusaSealed': 'Caught in her own gaze. Like Perseus\'s shield.',
    'feather': 'A feather of the Simurgh',
    'feathersAll': 'The feathers are whole. The altar is waiting.',
    'horoscope':
        'The sky is arranged as on the lion\'s back. The stones give way.',
    'giantFell': 'A gnat brought down a king; a firefly, a giant.',
    'chase': 'Something breathes behind you. RUN.',
    'wings': 'Hezarfen\'s wings. Whoever trusts the wind does not fall.',
    'memoriesFound': 'Memories found',
    'musicCredit': 'Menu music: vjgalaxy · Pixabay',
    'credits': 'Credits',
    'musicLicense':
        'Menu music: "Turkish Maqam Soundscape" by vjgalaxy (Pixabay), '
        'used under the Pixabay Content License.\n'
        'In-game ambience and sound effects were synthesized for this game.',
  };
}
