// Bölüm haritaları ve hikâye metinleri.
//
// Harita lejantı:
//   #  kaya (katı)            =  tek yönlü platform (raf / bulut / iskele)
//   |  sarmaşık (tırmanılır)  ^  diken (öldürür)
//   ~  uzun ot (gizlenme)     I  sütun (arkasında gizlenilir)
//   w  derin su (öldürür)     D  Medusa başı (süs)
//   C  itilebilir sandık      L  kol (↑ ile çekilir, kapıları açar)
//   H  demir kapı (kol açana kadar geçilmez)
//   F  ateşböceği sürüsü (kavanoza +1 ateşböceği)
//   B  ak kuşun konakları: kuş bunları sırayla dolaşıp yol gösterir
//   R  yatay gidip gelen kaya   V  dikey gidip gelen kaya   (2 kare geniş)
//   O  üstüne basınca kopan kaya (2 kare geniş)
//   A  asansörün sol kefesi     Y  sağ kefesi (ağır olan iner)
//   r  rüzgâr akımı (yukarı iter)  W  Hezarfen'in kanatları
//   b  yarasa yuvası (tavanda)  k  karga   g  Gözcü (projektörlü bekçi)
//   z  Karabasan'ın uyandığı sütun   Z  dağıldığı sütun
//   P  oyuncu başlangıcı
//   G  fenerci (düşman)       E  çıkış (ışık kapısı)
//   M  hatıra parçası (sırayla `memories`)
//   K  kontrol noktası        1-9 fısıltı tetikleyicisi (`whispers[n-1]`)

import 'strings.dart';

enum LevelTheme { cistern, cave, cliffs, sky }

class LevelDef {
  const LevelDef({
    required this.title,
    required this.subtitle,
    required this.theme,
    required this.map,
    this.whispers = const [],
    this.memories = const [],
    this.wings = false,
    this.titleEn = '',
    this.subtitleEn = '',
    this.whispersEn = const [],
    this.memoriesEn = const [],
  });

  final String titleEn;
  final String subtitleEn;
  final List<String> whispersEn;
  final List<String> memoriesEn;

  /// Seçili dildeki metinler.
  String get titleText => S.en && titleEn.isNotEmpty ? titleEn : title;
  String get subtitleText =>
      S.en && subtitleEn.isNotEmpty ? subtitleEn : subtitle;
  List<String> get whisperTexts =>
      S.en && whispersEn.isNotEmpty ? whispersEn : whispers;
  List<String> get memoryTexts =>
      S.en && memoriesEn.isNotEmpty ? memoriesEn : memories;

  /// Bölüm kanatlarla başlar (süzülme açık).
  final bool wings;

  final String title;
  final String subtitle;
  final LevelTheme theme;
  final List<String> map;

  /// Rakam tetikleyicilerinde gösterilen anlatım satırları.
  final List<String> whispers;

  /// Haritada yukarıdan aşağıya, soldan sağa okunan `M` sırasına göre.
  final List<String> memories;
}

const prologue = [
  'GÖLGE OYUNU',
  'İstanbul, 1660. Şehir üç gündür yanıyordu.',
  'Kandilciler Loncası küllerin arasından şehrin bütün ışığını topladı…',
  '…ve perdeye ışık tutan Hayali Usta\'yı da götürdüler.',
  'Perde boş kaldı. Ama gölgelerden biri ustasını aramaya çıktı.',
];

const prologueEn = [
  'SHADOW PLAY',
  'Istanbul, 1660. The city had been burning for three days.',
  'The Lamplighters\' Guild gathered every light from the ashes…',
  '…and took Master Hayali, who held the light behind the shadow screen.',
  'The screen fell empty. But one of the shadows set out to find its master.',
];

List<String> get prologueText => S.en ? prologueEn : prologue;

const epilogueEn = [
  'The white bird vanished into the light.',
  'The first shard of the broken sun trembled in the little shadow\'s hands.',
  'Somewhere, the master was still waiting.',
  'TO BE CONTINUED',
];

List<String> get epilogueText => S.en ? epilogueEn : epilogue;

const epilogue = [
  'Ak kuş ışığın içinde kayboldu.',
  'Kırık güneşin ilk parçası, küçük gölgenin elinde titriyordu.',
  'Ustası hâlâ bir yerlerde bekliyordu.',
  'DEVAM EDECEK',
];

const levels = <LevelDef>[
  LevelDef(
    title: 'I · YEREBATAN',
    subtitle: 'Şehrin altında, suyun hafızasında.',
    titleEn: 'I · BASILICA CISTERN',
    subtitleEn: 'Beneath the city, in the memory of water.',
    whispersEn: [
      'My master used to say: "The waters of this cistern keep all of Istanbul\'s secrets."',
      'The planks creak. Hold Shift to tiptoe… or climb the chain and cross above the arches.',
      'Medusa\'s heads were set upside down, so her gaze could turn no one to stone.',
      'The gate\'s lever is stuck up high. Push the crate, climb it, pull the lever with ↑.',
      'Bats are sleeping on the ceiling. Run, and they wake… and everyone hears.',
      'The pulleys creak. The heavy side sinks, the light side rises.',
    ],
    memoriesEn: [
      'Memory · My master\'s hands never trembled while he held the light to the screen.',
      'Memory · Every night, before the curtain fell, Karagöz had the last word.',
      'Memory · My master always hummed the same folk song while setting up the screen.',
    ],
    theme: LevelTheme.cistern,
    whispers: [
      'Ustam derdi ki: "Bu sarnıçta sular İstanbul\'un bütün sırlarını saklar."',
      'Tahtalar gıcırdar. Shift ile parmak uçlarında yürü… ya da zincire tırman, kemerlerin üstünden geç.',
      'Medusa\'nın başları ters konmuş. Bakışı kimseyi taşa çeviremesin diye.',
      'Kapının kolu yukarıda kalmış. Sandığı it, üstüne çık, kolu ↑ ile çek.',
      'Tavanda yarasalar uyuyor. Koşarsan uyanırlar… ve herkes duyar.',
      'Makaralar gıcırdıyor. Ağır olan iner, hafif olan yükselir.',
    ],
    memories: [
      'Hatıra · Ustamın elleri perdeye ışık tutarken hiç titremezdi.',
      'Hatıra · Her gece perde kapanmadan önce son sözü Karagöz söylerdi.',
      'Hatıra · Ustam perdeyi kurarken hep aynı türküyü mırıldanırdı.',
    ],
    map: [
      '##################################################################################################################################',
      '##################################################################################################################################',
      '#...................................................................#########################....................................#',
      '#...................................................................#########################....................................#',
      '#...................................................................#########################....................................#',
      '#...................................................................#########################....................................#',
      '#..................KB...F....3....BM................................#########################....................................#',
      '#.................######..#####..#####..#######.....................#########################...............................B.ZE.#',
      '#................|......................................................b......b......b...................................########',
      '#................|....................................MLB.........................................C.B........Kz.F.........########',
      '#................|...................................####.......B................................#####......######..###O.........#',
      '#................|..........................................H..####........................B.....#####......######..###..........#',
      '#................|.............................#............H..####...#....................#...##...........######...............#',
      '#.P.1..F.B.I......2..I....I....I.G..I....I.....#.CK4B.....F.H..####.5F#.....I....IG...I.M..#.K6##...........######...............#',
      '######========..=============================..##################################################.....A..Y..######...............#',
      '######.........................................##################################################...........######...............#',
      '######.........................................##################################################...........######...............#',
      '######.........................D....D..........##################################################...........######...............#',
      '######wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww##################################################wwwwwwwwwww######wwwwwwwwwwwwwww#',
      '######wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww##################################################wwwwwwwwwww######wwwwwwwwwwwwwww#',
    ],
  ),
  LevelDef(
    title: 'II · KULE',
    subtitle: 'Haliç\'in kayalıklarından Galata\'ya, oradan göğe.',
    titleEn: 'II · THE TOWER',
    subtitleEn:
        'From the cliffs of the Golden Horn to Galata, and on to the sky.',
    whispersEn: [
      'The rocks are wet. Some break when you step on them; don\'t linger.',
      'Crows see everything. Run past them and the whole city will hear.',
      'The city is burning up there. A Lamplighter walks the rooftops.',
      'Hezarfen flew from here. Take the wings, leap into the wind, hold jump.',
    ],
    memoriesEn: [
      'Memory · The waters of the Golden Horn were my master\'s favourite mirror.',
      'Memory · "One day we\'ll see the whole city from the tower," he said.',
      'Memory · The Watchers\' light is cold; my master\'s lantern was always warm.',
    ],
    theme: LevelTheme.cliffs,
    whispers: [
      'Kayalar ıslak. Bazıları basınca kopuyor; üstlerinde uzun durma.',
      'Kargalar her şeyi görür. Yanlarından koşarsan bütün şehir duyar.',
      'Yukarıda şehir yanıyor. Çatıların üstünde bir Kandilci dolaşıyor.',
      'Hezarfen buradan uçmuş. Kanatları al, rüzgâra atla, zıplamayı basılı tut.',
    ],
    memories: [
      'Hatıra · Haliç\'in suları ustamın en sevdiği aynaydı.',
      'Hatıra · "Bir gün kuleden bütün şehri göreceğiz," demişti.',
      'Hatıra · Gözcülerin ışığı soğuktur; ustamın feneri ise hep sıcaktı.',
    ],
    map: [
      '##..........................##',
      '##..........................##',
      '##............rrr...........##',
      '##............rrr....E......##',
      '##............rrr..=====....##',
      '##............rrr...........##',
      '##............rrr...........##',
      '##............rrr...........##',
      '##............rrr...........##',
      '##............rrr...........##',
      '##.....B.4KW..rrr...........##',
      '##..#########.rrr...........##',
      '##..#########...............##',
      '##...........|..............##',
      '##...........|..............##',
      '##...........|..............##',
      '##...........|..............##',
      '##...........|..............##',
      '##...........|..............##',
      '##...........|..............##',
      '##...........|..............##',
      '##...........|..............##',
      '##...........|..............##',
      '##..........====........g...##',
      '##...............M....####..##',
      '##..............====..####..##',
      '##.........B.F..............##',
      '##.......======.............##',
      '##..........................##',
      '##..........................##',
      '##..........................##',
      '##..........................##',
      '##..........................##',
      '##....V.....................##',
      '##.K........................##',
      '##====......................##',
      '##..........................##',
      '##............BC............##',
      '##..........======..........##',
      '##..........|....k...k..F...##',
      '##..........|=============.|##',
      '##....Y...A.|..............|##',
      '##..........|..............|##',
      '##..........|..............|##',
      '##..........|..............|##',
      '##..........|..............|##',
      '############...............|##',
      '############...............|##',
      '##.........................|##',
      '##.........................|##',
      '##................B.~~.G...|##',
      '##................=========.##',
      '##..........K...............##',
      '##.........======...........##',
      '##...B3.M...................##',
      '##|.######..................##',
      '##|.######..................##',
      '##|.........................##',
      '##|.........................##',
      '##|.........................##',
      '##|.........................##',
      '##|.........................##',
      '##|.........................##',
      '##|.........................##',
      '##|.........................##',
      '##|.........................##',
      '##.R........................##',
      '##.......k.F................##',
      '##......######..............##',
      '##......######..............##',
      '##.............O............##',
      '##..........................##',
      '##................O.........##',
      '##...................2KB....##',
      '##...................####.|.##',
      '##...................####.|.##',
      '##........................|.##',
      '##........................|.##',
      '##........................|.##',
      '##........................|.##',
      '##........................|.##',
      '##........................|.##',
      '##........................|.##',
      '##.....................kM.|.##',
      '##..................#####...##',
      '##..................#####...##',
      '##...............O..........##',
      '##...........B..............##',
      '##..........####............##',
      '##..........####............##',
      '##..........................##',
      '##.P.1BF....................##',
      '########.V..................##',
      '########....................##',
      '########wwwwwwwwwwwwwwwwwwww##',
      '########wwwwwwwwwwwwwwwwwwww##',
    ],
  ),
  LevelDef(
    title: 'III · GÖKYOLU',
    subtitle: 'Bulutlar, üstünde yürünecek kadar ağır.',
    titleEn: 'III · SKY ROAD',
    subtitleEn: 'Clouds heavy enough to walk on.',
    whispersEn: [
      'Shards of the broken sun… they must be somewhere here.',
      'Lamplighters here too. So it was they who closed the sky.',
      'The sky is not as empty as I thought.',
      'The wind will carry you. Don\'t let go of jump.',
    ],
    memoriesEn: [
      'Memory · The white bird looked like the one my master stitched in the corner of his screen.',
      'Memory · "One day we\'ll bring the sun back to the screen," he said. How?',
    ],
    theme: LevelTheme.sky,
    wings: true,
    whispers: [
      'Kırık güneşin parçaları… burada bir yerde olmalı.',
      'Burada da kandilciler var. Demek gökyüzünü onlar kapattı.',
      'Gökyüzü sandığım kadar boş değilmiş.',
      'Rüzgâr seni taşır. Zıplamayı bırakma.',
    ],
    memories: [
      'Hatıra · Ak kuş, ustamın perdesinin köşesine işlediği kuşa benziyordu.',
      'Hatıra · "Bir gün güneşi perdeye geri getireceğiz," demişti. Nasıl?',
    ],
    map: [
      '......................................................................................................................................................',
      '......................................................................................................................................................',
      '......................................................................................................................................................',
      '..................rr..................................................................................................................................',
      '..................rr................................................................rr...KMB..........................................................',
      '..................rr....MB.....................................g....................rr..======........................................................',
      '..................rr..=====..................................###....................rr................................................................',
      '..................rr.........................................###....................rr................................................................',
      '..................rr.........................................###....................rr..............................................K..B....1..B.E....',
      '..................rr.........R......................................................rr.............................................###################',
      '..................rr..................O....K2FB~~.G..~~.................====........rr........................................O....###################',
      '..................rr......................###############..........B................rr...................KkBF.k..........O.........###################',
      '..................rr......................###############..==.....====..............rr..................#########...O................###############..',
      '..................rr........................###########.............................rr..................#########.....................................',
      '..P.3B............rr...........................#####...........................V....rr....................#####.......................................',
      '########......KB4.rr................................................................rr................................................................',
      '########.....====...................................................................rr................................................................',
      '########..............................................................................................................................................',
      '.######...............................................................................................................................................',
      '..####................................................................................................................................................',
      '......................................................................................................................................................',
      '......................................................................................................................................................',
    ],
  ),
];
