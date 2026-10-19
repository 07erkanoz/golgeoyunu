// Bölüm haritaları ve hikâye metinleri.
//
// Harita lejantı:
//   #  kaya (katı)            =  tek yönlü platform (raf / bulut / iskele)
//   |  sarmaşık (tırmanılır)  ^  diken (öldürür)
//   ~  uzun ot (gizlenme)     I  sütun (arkasında gizlenilir)
//   w  derin su (öldürür)     D  Medusa başı (süs)
//   P  oyuncu başlangıcı
//   G  fenerci (düşman)       E  çıkış (ışık kapısı)
//   B  ak kuş                 M  hatıra parçası (sırayla `memories`)
//   K  kontrol noktası        1-9 fısıltı tetikleyicisi (`whispers[n-1]`)

enum LevelTheme { cistern, cave, cliffs, sky }

class LevelDef {
  const LevelDef({
    required this.title,
    required this.subtitle,
    required this.theme,
    required this.map,
    this.whispers = const [],
    this.memories = const [],
  });

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
    theme: LevelTheme.cistern,
    whispers: [
      'Ustam derdi ki: "Bu sarnıçta sular İstanbul\'un bütün sırlarını saklar."',
      'Kandilci ışığını yola tutar. Sütunun ardında kavanozunu ört (Shift)… ya da uzağa bir ateşböceği sal (F).',
      'Medusa\'nın başları ters konmuş. Bakışı kimseyi taşa çeviremesin diye.',
    ],
    memories: [
      'Hatıra · Ustamın elleri perdeye ışık tutarken hiç titremezdi.',
      'Hatıra · Her gece perde kapanmadan önce son sözü Karagöz söylerdi.',
    ],
    map: [
      '################################################################',
      '################################################################',
      '#..............................................................#',
      '#..............................................................#',
      '#..............................................................#',
      '#..............................................................#',
      '#...........................................................BE.#',
      '#...........................................K.I.M..........#####',
      '#..........................................========........#####',
      '#.P..1.....I.B....2..I....I.M..I.G..I..............I.3..I..#####',
      '#####==========..========================..........========#####',
      '#####......................................................#####',
      '#####..............................................D....D..#####',
      '#####wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww#####',
      '#####wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww#####',
    ],
  ),
  LevelDef(
    title: 'II · KAYALIKLAR',
    subtitle: 'Yukarısı hep daha soğuk.',
    theme: LevelTheme.cliffs,
    whispers: [
      'Duvar ne kadar yüksek olursa olsun, bir tutamak bulunur.',
      'Aşağıdaki sesler artık duyulmuyor. Sadece rüzgâr.',
    ],
    memories: [
      'Hatıra · "Işık arkandayken korkma," derdi ustam. "Gölge en güzel o zaman görünür."',
      'Hatıra · Pencereden süzülen son gün ışığı.',
    ],
    map: [
      '##................##',
      '##................##',
      '##..........B..E..##',
      '##......############',
      '##.....|############',
      '##.....|.........###',
      '##.....|.........###',
      '##.....|.........###',
      '###....|.........###',
      '###....|.........###',
      '###....|.........###',
      '###....|..........##',
      '###....|..........##',
      '##.....|..........##',
      '##.....|...M......##',
      '##.....|..====....##',
      '##.....|..........##',
      '##.....|........####',
      '##..............####',
      '##................##',
      '##...........===..##',
      '##................##',
      '##...............###',
      '##.......===.....###',
      '##..2K...........###',
      '###########.|....###',
      '###########.|....###',
      '##..........|....###',
      '##..........|....###',
      '##..........|.....##',
      '###.........|.....##',
      '###.........|.....##',
      '###.........|.....##',
      '###.........|.....##',
      '###.........|.....##',
      '##..........|.....##',
      '##..........|.....##',
      '##.............BM.##',
      '##............######',
      '##............######',
      '##................##',
      '##......=====.....##',
      '##.P.1........^^^^##',
      '####################',
      '####################',
      '####################',
    ],
  ),
  LevelDef(
    title: 'III · GÖKYOLU',
    subtitle: 'Bulutlar, üstünde yürünecek kadar ağır.',
    theme: LevelTheme.sky,
    whispers: [
      'Kırık güneşin parçaları… burada bir yerde olmalı.',
      'Burada da kandilciler var. Demek gökyüzünü onlar kapattı.',
      'Gökyüzü sandığım kadar boş değilmiş.',
    ],
    memories: [
      'Hatıra · Ak kuş, ustamın perdesinin köşesine işlediği kuşa benziyordu.',
      'Hatıra · "Bir gün güneşi perdeye geri getireceğiz," demişti. Nasıl?',
    ],
    map: [
      '......................................................................',
      '......................................................................',
      '......................................................................',
      '..........................................................|...1.B.E...',
      '..........................................................|.##########',
      '..........................................................|.##########',
      '..........................................................|..########.',
      '..........................................................|....####...',
      '.................M.........................===.......===..|...........',
      '................===.........2K.~~~.G..~~.........M........|...........',
      '..P3.................====..##############.......===.......|...........',
      '########..====.............##############.............................',
      '########....................############..............................',
      '.######.......................#######.................................',
      '..####................................................................',
      '......................................................................',
    ],
  ),
];
