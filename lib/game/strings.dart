/// Oyunun dilleri ve arayüz metinleri.
enum Lang { tr, en }

class S {
  S._();

  static Lang lang = Lang.tr;

  static bool get en => lang == Lang.en;

  static String of(String key) => (en ? _en : _tr)[key] ?? _tr[key] ?? key;

  /// Dile göre büyük harf: Türkçede i → İ, ı → I.
  static String upper(String s) => en
      ? s.toUpperCase()
      : s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

  static const _tr = {
    'gameTitle': 'GÖLGE OYUNU',
    'menuSubtitle': 'İstanbul, 1660',
    'menuTagline': 'Hayal perdesinde bir gölgenin yolculuğu',
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
    'guardStone':
        'Fener taşıyan taşa döndü: göz açıkken adım attı.\n'
        'Sen göz kapanınca yürü, açılınca dur.\n'
        'Şimdi o taş, senin basamağın.',
    'feather': 'Simurg\'un tüyü',
    'feathersAll': 'Tüyler tamam. Sunak seni bekliyor.',
    'horoscope': 'Gök, aslanın sırtındaki gibi dizildi. Taşlar yol veriyor.',
    'giantFell': 'Bir sivrisinek bir kralı yıktı; bir ateşböceği de bir devi.',
    'chase': 'Arkanda bir şey nefes alıyor. KOŞ.',
    'wings': 'Hezarfen\'in kanatları. Rüzgâra güvenen düşmez.',
    'memoriesFound': 'Toplanan hatıralar',
    'musicCredit': 'Menü müziği: vjgalaxy · Pixabay',
    'highRefresh': 'Yüksek yenileme hızı (90/120 Hz)',
    'showFps': 'Kare hızını göster (FPS)',
    'displayHz': 'Ekran {hz} Hz · oyun bu hızda çizilir',
    'story': 'Hikâye',
    'about': 'Hakkında',
    'back': 'Geri',
    'storyTitle': 'HİKÂYE',
    'storyIntro':
        'Temmuz 1660. İstanbul iki gündür yanıyor. Kandilciler Loncası küllerin arasında dolaşıp her kandili, her mumu, her gözdeki ışığı topluyor.\n\n'
        'Son olarak Hayali Usta\'nın perdesine gelirler; kandilini söndürür, ustayı götürürler. Işık sönmeden önce perdeden bir gölge düşer: Sâye.\n\n'
        'Sâye ustasını aramak için yola çıkar. Yanında bir kavanoz ateşböceği ve yolu bilen bir kuş vardır: Hüdhüd.',
    'storyAct0': 'Birinci Perde · Işığın Çalındığı Şehir',
    'storyAct0Text': 'Yerebatan\'ın karanlık suları, Galata\'nın kulesi, Hezarfen\'in kanatları, buluttan bir yol ve dünyanın kıyısında Kaf Dağı. Simurg\'un aynasında Sâye kim olduğunu görür.',
    'storyAct1': 'İkinci Perde · Dağ',
    'storyAct1Text': 'Kandilciler ustanın kandilini doğuya taşıdı. Ağrı\'nın buzulları, Nuh\'un taşa dönmüş gemisi, Nemrut\'un başı düşmüş tanrıları. Sâye her adımda bir ışığa yetişir; Kandilciler hep bir adım öndedir.',
    'storyAct2': 'Üçüncü Perde · Kar',
    'storyAct2Text': 'Sâye bir an ustasını görür: karların içinde, zincirli, kandili bir mum kadar kalmış. Palandöken\'de ejderler uyurken kervanın peşinden kayar; Ejder uyanınca çığla yarışır.',
    'storyAct3': 'Dördüncü Perde · Periler',
    'storyAct3Text': 'Kapadokya\'da bacaların tepesinde periler, yerin altında devler uyur. Kandilciler Derinkuyu\'nun dibine iner; Sâye de iner.',
    'storyAct4': 'Son Perde · Düğün',
    'storyAct4Text': 'Konya, 17 Aralık 1660: Şeb-i Arûs. Kandilciler ustayı Mevlânâ\'nın düğün gecesine getirdi. Düğün gecesinde ışığın ölmeyeceğine inanıyorlar.',
    'storyLocked': 'Bu perde henüz açılmadı.',
    'aboutTitle': 'HAKKINDA',
    'aboutGame': 'Gölge Oyunu, hayal perdesinin ardında geçen bir yolculuk: bir kandil, bir gölge ve Anadolu\'nun gün yüzüne çıkmayı bekleyen efsaneleri.',
    'aboutRole': 'Tasarım ve geliştirme',
    'aboutDev':
        'Erkan Öz avukat ve arabulucudur. Gündüzleri insanların hikâyelerini dinler, geceleri onları anlatacak araçlar yapar. '
        'Gölge Oyunu, çocukluğundaki Karagöz perdesine ve Anadolu\'nun yarım bırakılmış efsanelerine bir selamdır: bir gölgenin, bir kandilin ve uzun bir yolun hikâyesi.',
    'aboutSite': 'Kişisel sayfa',
    'aboutGamePage': 'Oyunun sayfası · LifeOS ailesinin bir parçası',
    'aboutMusic': 'Müzik ve sesler',
    'musicLicense':
        'Menü müziği: "Turkish Maqam Soundscape", vjgalaxy (Pixabay). '
        'Pixabay İçerik Lisansı ile kullanılmaktadır.\n'
        'Gerçek kayıtlı efektler ve ortam sesleri: Kenney (kenney.nl); OpenGameArt\'ta rubberduck, JaggedStone, AntumDeluge, SketchMan3, psychhead_, pauliuw, techiew ve congusbongus (CC0). '
        'Diğer sesler bu oyun için sentezlenmiştir.',
  };

  static const _en = {
    'gameTitle': 'SHADOW PLAY',
    'menuSubtitle': 'Istanbul, 1660',
    'menuTagline': 'A shadow\'s journey behind the screen',
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
    'guardStone':
        'The lantern-bearer turned to stone: he took a step while her eye was open.\n'
        'Walk when the eye closes; stop when it opens.\n'
        'Now that stone is your stair.',
    'feather': 'A feather of the Simurgh',
    'feathersAll': 'The feathers are whole. The altar is waiting.',
    'horoscope':
        'The sky is arranged as on the lion\'s back. The stones give way.',
    'giantFell': 'A gnat brought down a king; a firefly, a giant.',
    'chase': 'Something breathes behind you. RUN.',
    'wings': 'Hezarfen\'s wings. Whoever trusts the wind does not fall.',
    'memoriesFound': 'Memories found',
    'musicCredit': 'Menu music: vjgalaxy · Pixabay',
    'highRefresh': 'High refresh rate (90/120 Hz)',
    'showFps': 'Show frame rate (FPS)',
    'displayHz': 'Display {hz} Hz · the game draws at this rate',
    'story': 'Story',
    'about': 'About',
    'back': 'Back',
    'storyTitle': 'STORY',
    'storyIntro':
        'July 1660. Istanbul has been burning for two days. The Lamplighters\' Guild walks among the ashes, gathering every lamp, every candle, every light in every eye.\n\n'
        'Last, they come to Master Hayali\'s screen; they snuff his lamp and take him away. Before the light dies, a shadow falls from the screen: Saye.\n\n'
        'Saye sets out to find his master, with only a jar of fireflies and a bird who knows the way: the Hoopoe.',
    'storyAct0': 'The First Veil · The City Whose Light Was Stolen',
    'storyAct0Text': 'The dark waters of the cistern, the tower of Galata, Hezarfen\'s wings, a road of clouds, and Mount Qaf at the edge of the world. In the Simurgh\'s mirror, Saye sees what he is.',
    'storyAct1': 'The Second Veil · The Mountain',
    'storyAct1Text': 'The Lamplighters carried the master\'s lamp east. The glaciers of Ararat, Noah\'s ship turned to stone, the fallen gods of Nemrut. At every step Saye reaches a light; the Lamplighters are always one step ahead.',
    'storyAct2': 'The Third Veil · Snow',
    'storyAct2Text': 'For a moment Saye sees his master: in the snow, in chains, his lamp shrunk to a candle\'s flame. While the dragons of Palandoken sleep he skis after the caravan; when the Dragon wakes, he races the avalanche.',
    'storyAct3': 'The Fourth Veil · The Fairies',
    'storyAct3Text': 'In Cappadocia, fairies sleep atop the chimneys and giants beneath the earth. The Lamplighters go down to the depths of Derinkuyu; so does Saye.',
    'storyAct4': 'The Last Veil · The Wedding',
    'storyAct4Text': 'Konya, 17 December 1660: Sheb-i Arus. The Lamplighters have brought the master to Mevlana\'s wedding night. They believe that on the wedding night, light cannot die.',
    'storyLocked': 'This veil has not opened yet.',
    'aboutTitle': 'ABOUT',
    'aboutGame': 'Shadow Play is a journey behind the shadow-play screen: a lamp, a shadow, and the legends of Anatolia waiting to come to light.',
    'aboutRole': 'Design and development',
    'aboutDev':
        'Erkan Öz is a lawyer and mediator. By day he listens to people\'s stories; by night he builds tools to tell them. '
        'Shadow Play is a greeting to the Karagöz screen of his childhood and to the half-told legends of Anatolia: the story of a shadow, a lamp, and a long road.',
    'aboutSite': 'Personal site',
    'aboutGamePage': 'The game\'s page · part of the LifeOS family',
    'aboutMusic': 'Music and sound',
    'musicLicense':
        'Menu music: "Turkish Maqam Soundscape" by vjgalaxy (Pixabay), '
        'used under the Pixabay Content License.\n'
        'Recorded effects and ambiences: Kenney (kenney.nl); rubberduck, JaggedStone, AntumDeluge, SketchMan3, psychhead_, pauliuw, techiew and congusbongus on OpenGameArt (CC0). '
        'Other sounds were synthesized for this game.',
  };
}
