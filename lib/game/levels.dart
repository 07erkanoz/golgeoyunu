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

import 'maps.dart';
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
  'İstanbul, Temmuz 1660. Şehir iki gündür yanıyordu.',
  'Kandilciler Loncası küllerin arasında dolaştı; her kandili, her mumu, her gözdeki ışığı topladı.',
  'Son olarak Hayali Usta\'nın perdesine geldiler. Kandili söndürdüler, ustayı götürdüler.',
  'Perde karardı. Ama bir gölge, ışık sönmeden önce perdeden düştü.',
  'GÖLGE OYUNU',
];

const prologueEn = [
  'Istanbul, July 1660. The city had been burning for two days.',
  'The Lamplighters\' Guild walked among the ashes, gathering every lamp, every candle, every light in every eye.',
  'Last, they came to Master Hayali\'s screen. They snuffed his lamp and took him away.',
  'The screen went dark. But one shadow fell from it before the light died.',
  'SHADOW PLAY',
];

List<String> get prologueText => S.en ? prologueEn : prologue;

const epilogue = [
  'Hüdhüd ışığın içinde kayboldu.',
  'Kırık güneşin ilk parçası, Sâye\'nin avuçlarında titriyordu.',
  'Uzakta, Kaf\'ın ardında, bir kandil cızırdadı.',
  'DEVAM EDECEK',
];

const epilogueEn = [
  'The Hoopoe vanished into the light.',
  'The first shard of the broken sun trembled in Saye\'s hands.',
  'Far away, beyond Qaf, a lamp sputtered.',
  'TO BE CONTINUED',
];

List<String> get epilogueText => S.en ? epilogueEn : epilogue;

/// Bölüm aralarında perdede oynanan gölge oyunu sahneleri: her bölümden
/// önce (indeks = bölüm). Satırlar sırayla, perdedeki tasvirlerle birlikte.
const interludes = <List<String>>[
  [],
  [
    'Sarnıçtan çıktığında şehir hâlâ yanıyordu.',
    'Galata\'nın tepesinde bir zamanlar bir adam kanat takmış, göğe atlamıştı.',
    'Onu alkışladılar. Sonra korktular. Sonra sürdüler.',
    'Uçanlar sürgün edilir, Sâye. Yine de uç.',
  ],
  [
    'Bulutların ardında, Kaf Dağı\'na giden bir yol vardır.',
    'Hüdhüd kuşları oraya, Simurg\'a götürdü. Çoğu yolda vazgeçti.',
    'Kandilciler topladıkları ışığı göğe astı; güneşi onlar kırdı.',
    'Ustanın kandili orada, Sâye. Ve sen her adımda ona biraz daha benziyorsun.',
  ],
];

const interludesEn = <List<String>>[
  [],
  [
    'When he left the cistern, the city was still burning.',
    'Once, atop Galata, a man strapped on wings and leapt into the sky.',
    'They cheered him. Then they feared him. Then they sent him away.',
    'Those who fly are exiled, Saye. Fly anyway.',
  ],
  [
    'Beyond the clouds there is a road to Mount Qaf.',
    'The Hoopoe led the birds there, to the Simurgh. Most gave up on the way.',
    'The Lamplighters hung their stolen light in the sky; it was they who broke the sun.',
    'Your master\'s lamp is there, Saye. And with every step, you look more like it.',
  ],
];

List<String> interludeText(int level) {
  final all = S.en ? interludesEn : interludes;
  return level < all.length ? all[level] : const [];
}

const levels = <LevelDef>[
  LevelDef(
    title: 'I · YEREBATAN',
    subtitle: 'Suyun altında bir şehir uyur.',
    theme: LevelTheme.cistern,
    titleEn: 'I · THE CISTERN',
    subtitleEn: 'Beneath the water, a city sleeps.',
    whispers: [
      'Sâye… Bu ustanın sesi mi, suyun mu?',
      'Fener neye değerse onu alır. Karanlıkta kal.',
      'Taşa dönmesin diye başını çevirmişler. Bakmadan görmeyi öğren.',
      'Kapılar zorla değil, sabırla açılır.',
      'Tavanda uyuyanları uyandırma. Her ses bir ihbardır.',
      'Biri iner ki öbürü yükselsin. Âlemin terazisi böyle kurulmuş.',
    ],
    whispersEn: [
      'Saye… Is that the master\'s voice, or the water\'s?',
      'Whatever the lantern touches, it takes. Keep to the dark.',
      'They turned her head so no one would become stone. Learn to see without looking.',
      'Doors open to patience, not to force.',
      'Do not wake those who sleep above. Every sound is a confession.',
      'One must sink so the other may rise. So the scales of the world were set.',
    ],
    memories: [
      'Hatıra · Perdeye ışık tutarken elleri hiç titremezdi. "Gölge, ışığın sözüdür Sâye," derdi.',
      'Hatıra · Gösteri bitince kandili hiç üflemezdi. "Gölgeler korkar," derdi.',
      'Hatıra · Bir gece perdenin arkasına geçmeme izin vermedi. "Gölge arkayı görmemeli," dedi.',
    ],
    memoriesEn: [
      'Memory · His hands never trembled as he held the light to the screen. "A shadow is the light\'s word, Saye," he said.',
      'Memory · When the show ended, he never blew out the lamp. "The shadows would be afraid," he said.',
      'Memory · One night he would not let me behind the screen. "A shadow must not see what is behind it," he said.',
    ],
    map: kMapYerebatan,
  ),
  LevelDef(
    title: 'II · KULE',
    subtitle: 'Yükseldikçe ışık soğur.',
    theme: LevelTheme.cliffs,
    titleEn: 'II · THE TOWER',
    subtitleEn: 'The higher you climb, the colder the light.',
    whispers: [
      'Haliç\'in suları her şeyi hatırlar; düşenleri de.',
      'Basınca kopan taşlar var. Hiçbir yer seni uzun süre taşımaz.',
      'Damlarda bir Kandilci dolaşıyor. Kargalar onun gözleridir.',
      'Kanatlar burada bekliyordu. Rüzgâra teslim ol.',
    ],
    whispersEn: [
      'The waters of the Horn remember everything, even those who fall.',
      'Some stones break beneath you. Nothing holds you for long.',
      'A Lamplighter walks the rooftops. The crows are his eyes.',
      'The wings were waiting here. Surrender to the wind.',
    ],
    memories: [
      'Hatıra · "Haliç bir aynadır," derdi ustam. "Şehir kendine orada bakar."',
      'Hatıra · Kulenin tepesini gösterip "Bir gün oradan bütün perdeyi göreceksin," demişti.',
      'Hatıra · Gözcülerin ışığı soğuktur; çünkü onlar ışığı sevmez, sayar.',
    ],
    memoriesEn: [
      'Memory · "The Horn is a mirror," he said. "The city looks at itself there."',
      'Memory · He pointed at the top of the tower: "One day you will see the whole screen from there."',
      'Memory · The Watchers\' light is cold, for they do not love the light; they count it.',
    ],
    map: kMapKule,
  ),
  LevelDef(
    title: 'III · GÖKYOLU',
    subtitle: 'Kaf\'a giden yol buluttandır.',
    theme: LevelTheme.sky,
    wings: true,
    titleEn: 'III · THE SKY ROAD',
    subtitleEn: 'The road to Qaf is made of cloud.',
    whispers: [
      'Kırık güneşin bir parçası… Sıcaklığı tanıdık.',
      'Burada da Kandilciler var. Gök bile onların.',
      'Gök sandığın kadar boş değil.',
      'Rüzgâr seni taşır; yeter ki bırakma.',
    ],
    whispersEn: [
      'A shard of the broken sun… Its warmth is familiar.',
      'Lamplighters here too. Even the sky is theirs.',
      'The sky is not as empty as you thought.',
      'The wind will carry you, so long as you do not let go.',
    ],
    memories: [
      'Hatıra · Perdenin köşesine bir hüdhüd işlemişti. "Yol gösterene borçlusun," derdi.',
      'Hatıra · "Bir gün güneşi perdeye geri getireceğiz," demişti. O gün gölgemin ilk kez titrediğini gördüm.',
    ],
    memoriesEn: [
      'Memory · He had stitched a hoopoe into the corner of the screen. "You owe the one who shows the way," he said.',
      'Memory · "One day we will bring the sun back to the screen," he said. That day I saw my shadow tremble for the first time.',
    ],
    map: kMapGokyolu,
  ),
];
