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
    'chapters': 'Bölümler',
    'chaptersHint': 'Açtığın bir bölümü baştan oyna',
    'allUnlocked': 'Bütün bölümler açıldı',
    'trickFlip': 'Takla',
    'trickFlip2': 'Çifte takla',
    'trickFlipN': '{n} kat takla',
    'trickAir': 'Uzun uçuş',
    'trickRail': 'Kütük',
    'cameo_suIyesi': 'Sudan, ak giysili, başında kanat gibi boynuzları olan bir kadın yükseldi; çevresinde ışıltılı mavi balıklar yüzüyordu: Su İyesi. Eski inanışta her suyun bir sahibi vardır; saygıyla bekleyene yolu gösterir. Balıklarından biri vanaya yüzdü.',
    'cameo_tulpar':
        'Bulutların ardında kanatlı bir at: Tulpar, yiğidin yoldaşı.',
    'cameo_ayazAta': 'Tipinin içinde ak sakallı bir ihtiyar: Ayaz Ata geçti.',
    'cameo_akAna': 'İlk su da böyle kıpırdadı: Ak Ana yükseldi, "yarat" dedi.',
    'cameo_basat': 'Ozan der ki: Tepegöz de böyle yıkıldı, aslanlar arasında büyüyen Basat\'ın elinde.',
    'cameo_albasti':
        'Işığın neden çekiliyor? Ardında kızıl bir gölge. Kıpırda.',
    'cameo_erlik': 'Yerin dibinden boğuk bir ses: "Aşağı gel..." Erlik\'in katı daha da aşağıda.',
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
    'calmEffects': 'Sarsıntı ve parlamayı azalt',
    'touchScale': 'Düğme boyutu',
    'leftHanded': 'Sol elle oyna',
    'touchControls': 'Dokunmatik',
    'touchButtons': 'Düğmeler',
    'touchGestures': 'Hareket',
    'touchOpacity': 'Düğme görünürlüğü',
    'touchHelpGestures':
        'Sol yarı: sürükle → yürü, yukarı → tırman/kol, aşağı → çömel\n'
        'Sağ yarı: dokun → zıpla (basılı tut: süzül) · ✨ → ateşböceği',
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
    'giantFell': 'Bir sivrisinek bir kralı yıktı; üç ateşböceği de bir devi.',
    'giantHit1': 'Dev sendeledi · iki ışık daha',
    'giantHit2': 'Taş çatırdıyor · son bir ışık',
    'chase': 'Arkanda bir şey nefes alıyor. KOŞ.',
    'wings': 'Hezarfen\'in kanatları. Rüzgâra güvenen düşmez.',
    'memoriesFound': 'Toplanan hatıralar',
    'musicCredit': 'Menü müziği: vjgalaxy · Pixabay',
    'story': 'Hikâye',
    'book': 'Defter',
    'bookTitle': 'HATIRA DEFTERİ',
    'legendsTitle': 'EFSANELER',
    'recentTitle': 'AZ ÖNCE',
    'recentEmpty': 'Bu bölümde henüz bir şey anlatılmadı.',
    'recentTitleKind': 'Bölüm',
    'recentPlace': 'Yer',
    'recentStory': 'Hikâye',
    'recentHint': 'İpucu',
    'recentLegend': 'Efsane',
    'legendsWaiting': '· · ·  {n} efsane daha yolda seni bekliyor.',
    'bookTally': 'Hatıralar {m} / {mt}  ·  Efsaneler {e} / {et}',
    'legendsIntro': 'Yolda karşılaştığın varlıklar ve onların eski hikâyeleri.',
    'mythNoted': 'Defter\'e yazıldı · Efsaneler',
    'tulparMount':
        'Tulpar diz çöktü: "Bin, çocuk. Erlik\'in fırtınası geliyor; uç!"',
    'cameo_kam': 'Bulutun üstünde bir kam davulunu çalıyor: "Davul benim atımdır; her vuruşta göğe bir basamak."',
    'cameo_gokKat': 'Ay katı: ışık soğuk ve yumuşak. Kimi anlatılarda Ay Ata\'dır, Güneş ise Gün Ana.',
    'cameo_ulgen': 'Ülgen\'in kapısı. Kimse konuşmuyor; ışık kendini anlatıyor: "Işık bölünmeye razı olur, sahiplenilmeye razı olmaz."',
    'forgeCold': 'Ocak sönük. Kandilciler buradaki ateşi de toplamış; bir ateşböceği onu yeniden yakar.',
    'forgeLit': 'Közler tutuştu. Şimdi körükler: çentik sayısı sırasıyla.',
    'cameo_demirci': 'Demirci örsün başında: "Körükleri çekicime uydur, çocuk. Yetmiş körük bir ağızdan üflerse dağın demiri erir."',
    'nevruzStruck': 'Demir örste üç kez çınladı. Bu güne Nevruz derler: vadiden çıkış günü. Önündeki kapı açıldı.',
    'nevruzHint': 'Örsün başında ↑ ile demire üç kez vur.',
    'ventCrateBurn':
        'Sandık ateşin üstünde tutuştu: tıkamak ancak bir süre yeter.',
    'forgeFuel': 'Ocak boş. Efsanede dağın dibine odun ve kömür yığılır: kömür sandıklarını ocağın önündeki çukura it.',
    'forgeLitBeat': 'Közler tutuştu. Körüğü çekicin örse indiği anda bas; basılan körük dolana dek bekle, öbürüne koş.',
    'cameo_asena': 'Mağaranın ağzında ak boz bir dişi kurt yatıyor: Asena. Burada sana dokunamazlar.',
    'calkuyrukMount': 'Çalkuyruk konuştu: "Sırtıma bin, çocuk. Karanlık yükseliyor; yukarı, ışığa!"',
    'cameo_erTostuk': 'Duvarda bir atlının gölgesi: Er Töştük. Burada ışık yolu siler, karanlık yol açar.',
    'perdeSolved': 'Gölgen perdedeki gözü buldu, ışığın taştakini uyandırdı. Perde iki yüzünü de gördü: kapı aralandı.',
    'bookIntro': 'Yolda bulduğun her hatıra buraya yazılır. Boş satırlar, o bölümde hâlâ karanlıkta bekleyenlerdir.',
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
    'storyAct5': 'Beşinci Perde · Ötüken',
    'storyAct5Text': 'Derinkuyu\'nun dibinde su sesi: başlangıçtaki ilk su. Kandilcilerin çaldığı ışık yerin altına, Erlik\'in katına akar. Sâye Er Töştük\'ün atıyla karanlıktan çıkar, Ergenekon\'un demir dağını eritir, Kam\'ın davuluyla göğün katlarına yükselir; Ülgen\'in kapısında kırık güneşin bir parçası bekler.',
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
        'Efektler ve ortam sesleri: Kenney, OpenGameArt ve Wikimedia Commons\'taki kamu malı (CC0) kayıtlar. '
        'Efsane varlıklarının siluetleri PhyloPic\'teki kamu malı çizimlerden uyarlanmıştır. '
        'Nemrut heykel başları Wikimedia Commons\'taki Dosseman, Bernard Gagnon, Carole Raddato ve Vincent Vega fotoğraflarından yeniden çizilmiştir (CC BY-SA 4.0). '
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
    'chapters': 'Chapters',
    'chaptersHint': 'Replay a chapter you have reached',
    'allUnlocked': 'All chapters unlocked',
    'trickFlip': 'Flip',
    'trickFlip2': 'Double flip',
    'trickFlipN': '{n}× flip',
    'trickAir': 'Big air',
    'trickRail': 'Grind',
    'cameo_suIyesi': 'A woman in white rose from the water, wing-like horns on her head, glowing blue fish swimming around her: the Su İyesi, the water\'s keeper. In old belief every water has its owner; to one who waits with respect, it shows the way. One of her fish swam to the valve.',
    'cameo_tulpar':
        'A winged horse beyond the clouds: Tulpar, the hero\'s companion.',
    'cameo_ayazAta':
        'A white-bearded old man in the blizzard: Ayaz Ata passed by.',
    'cameo_akAna':
        'The first water stirred like this: Ak Ana rose and said, "Create."',
    'cameo_basat': 'The bard says: so fell Tepegöz too, at the hand of Basat, who grew up among lions.',
    'cameo_albasti': 'Why is your light fading? A red shadow behind you. Move.',
    'cameo_erlik': 'A muffled voice from deep below: "Come down..." Erlik\'s realm lies deeper still.',
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
    'calmEffects': 'Reduce shake and flashes',
    'touchScale': 'Button size',
    'leftHanded': 'Left-handed',
    'touchControls': 'Touch',
    'touchButtons': 'Buttons',
    'touchGestures': 'Gestures',
    'touchOpacity': 'Button visibility',
    'touchHelpGestures':
        'Left half: drag → walk, up → climb/lever, down → crouch\n'
        'Right half: tap → jump (hold: glide) · ✨ → firefly',
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
    'giantFell': 'A gnat brought down a king; three fireflies, a giant.',
    'giantHit1': 'The giant staggers · two more lights',
    'giantHit2': 'The stone cracks · one last light',
    'chase': 'Something breathes behind you. RUN.',
    'wings': 'Hezarfen\'s wings. Whoever trusts the wind does not fall.',
    'memoriesFound': 'Memories found',
    'musicCredit': 'Menu music: vjgalaxy · Pixabay',
    'story': 'Story',
    'book': 'Book',
    'bookTitle': 'BOOK OF MEMORIES',
    'legendsTitle': 'LEGENDS',
    'recentTitle': 'JUST NOW',
    'recentEmpty': 'Nothing has been told in this chapter yet.',
    'recentTitleKind': 'Chapter',
    'recentPlace': 'Place',
    'recentStory': 'Story',
    'recentHint': 'Hint',
    'recentLegend': 'Legend',
    'legendsWaiting': '· · ·  {n} more legends wait for you on the road.',
    'bookTally': 'Memories {m} / {mt}  ·  Legends {e} / {et}',
    'legendsIntro': 'The beings you met on the road, and their old stories.',
    'mythNoted': 'Written in the journal · Legends',
    'tulparMount':
        'Tulpar knelt: "Climb on, child. Erlik\'s storm is coming; fly!"',
    'cameo_kam': 'Above the cloud a shaman beats his drum: "The drum is my horse; each beat is a step into the sky."',
    'cameo_gokKat': 'The moon layer: the light is cold and soft. In some tellings the Moon is Ay Ata, and the Sun is Gün Ana.',
    'cameo_ulgen': 'Ülgen\'s gate. No one speaks; the light speaks for itself: "Light agrees to be shared; it never agrees to be owned."',
    'forgeCold': 'The forge is cold. The Lamplighters took this fire too; a firefly will light it again.',
    'forgeLit':
        'The coals caught. Now the bellows: in the order of their notches.',
    'cameo_demirci': 'The smith stands at the anvil: "Keep the bellows to my hammer, child. When seventy bellows blow as one, the mountain\'s iron melts."',
    'nevruzStruck': 'The iron rang three times on the anvil. They call this day Nevruz: the day of leaving the valley. The gate ahead opened.',
    'nevruzHint': 'At the anvil, strike the iron three times with ↑.',
    'ventCrateBurn': 'The crate caught fire over the flames: plugging only holds for a while.',
    'forgeFuel': 'The forge is empty. In the legend wood and charcoal are heaped at the mountain\'s foot: push the charcoal crates into the pit before the forge.',
    'forgeLitBeat': 'The embers caught. Pump a bellows just as the hammer strikes the anvil; wait for a pumped bellows to refill, run to the next.',
    'cameo_asena': 'A pale grey she-wolf lies at the mouth of the cave: Asena. Here nothing can touch you.',
    'calkuyrukMount': 'Çalkuyruk spoke: "Climb on, child. The dark is rising; up, to the light!"',
    'cameo_erTostuk': 'A rider\'s shadow on the wall: Er Töştük. Here light erases the path, and darkness opens it.',
    'perdeSolved': 'Your shadow found the eye on the screen, your light woke the one in the stone. The screen saw both its faces: the gate opens.',
    'bookIntro': 'Every memory you find on the road is written here. The empty lines are those still waiting in the dark of that chapter.',
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
    'storyAct5': 'The Fifth Veil · Ötüken',
    'storyAct5Text': 'At the bottom of Derinkuyu, the sound of water: the first water of the beginning. The light the Lamplighters stole flows beneath the earth, into Erlik\'s realm. Saye escapes the dark on Er Töştük\'s horse, melts the iron mountain of Ergenekon, and rises to the layers of the sky on the shaman\'s drum; at Ülgen\'s gate a piece of the broken sun is waiting.',
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
        'Effects and ambiences: public-domain (CC0) recordings from Kenney, OpenGameArt and Wikimedia Commons. '
        'The silhouettes of the legendary beings are adapted from public-domain drawings on PhyloPic. '
        'The Nemrut statue heads are redrawn from photos by Dosseman, Bernard Gagnon, Carole Raddato and Vincent Vega on Wikimedia Commons (CC BY-SA 4.0). '
        'Other sounds were synthesized for this game.',
  };
}
