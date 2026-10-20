// Bölüm haritaları ve hikâye metinleri.
//
// Harita gösterimi: lib/game/level.dart başındaki açıklamaya bakın.

import 'maps.dart';
import 'strings.dart';

/// Bölümün mekânı: gökyüzü, arazi süsleri, ışık, sis ve sesler buna göre.
enum LevelTheme {
  cistern,
  cave,
  cliffs,
  sky,

  /// Kaf Dağı: zümrüt kayalar, Simurg'un tüyleri.
  kaf,

  /// Ağrı ve Palandöken: kar, tipi, buz.
  snow,

  /// Nuh'un Gemisi: taşlaşmış ahşap gövdenin içi.
  ark,

  /// Nemrut: kışın taş tanrılar ve düşmüş dev başlar.
  nemrut,

  /// Kapadokya: peri bacaları.
  peri,

  /// Konya: karlı gece, dergâh.
  konya;

  /// Kapalı mekân: tavanın üstü kaya, uzaktan zincir sesleri.
  bool get indoor => this == cistern || this == cave || this == ark;

  /// Kar yağar, kayaların üstü karla örtülü.
  bool get snowy => this == snow || this == nemrut || this == konya;
}

class LevelDef {
  const LevelDef({
    required this.title,
    required this.subtitle,
    required this.theme,
    required this.map,
    this.whispers = const [],
    this.memories = const [],
    this.wings = false,
    this.variant = 0,
    this.headwind = 0,
    this.storm = false,
    this.quakes = false,
    this.skiSurface,
    this.magnet = const [],
    this.titleEn = '',
    this.subtitleEn = '',
    this.whispersEn = const [],
    this.memoriesEn = const [],
    this.place = '',
    this.placeEn = '',
    this.areas = const [],
    this.areasEn = const [],
  });

  /// Başlığın altında: yer ve zaman (ör. "Yerebatan Sarnıcı · İstanbul,
  /// Temmuz 1660").
  final String place;
  final String placeEn;

  /// Bölümün içindeki yerlerin adları: haritadaki `p` işaretleri ilerleyiş
  /// sırasıyla bunları gösterir.
  final List<String> areas;
  final List<String> areasEn;

  String get placeText => S.en && placeEn.isNotEmpty ? placeEn : place;
  List<String> get areaTexts => S.en && areasEn.isNotEmpty ? areasEn : areas;

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

  /// Tipi: süzülürken yüze esen rüzgâr (px/sn). Uzun uçurumlar ancak
  /// iple sallanarak geçilir.
  final double headwind;

  /// Ara ara tipi bastırır: ekran beyaza boğulur; Kandilciler az görür,
  /// hiç duymaz.
  final bool storm;

  /// Kayak bölümü: sütun başına kar yamacının yüksekliği (kare). Negatif
  /// değer uçurumdur. Verilirse oyuncu kayakla iner.
  final List<double>? skiSurface;

  /// Manyetik Tepe bölgeleri (sütun aralıkları): kar yokuş yukarı akar.
  final List<(int, int)> magnet;

  /// Ara ara deprem olur: yer sarsılır, gevşek kayalar düşer.
  final bool quakes;

  /// Aynı temanın farklı görünümü (ör. kar: 0 Ağrı, 1 Palandöken, 2 çığ;
  /// Nemrut: 0 taş tanrılar, 1 gün doğumu).
  final int variant;

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
  [],
  [
    'Kaf\'ın tepesinde bir ayna vardı. Kuşlar Simurg\'u aradı; aynada kendilerini gördüler.',
    'Sâye de baktı. Aynada bir çocuk yoktu. Bir gölge vardı.',
    'Sâye. Eski dilde gölge demektir.',
    'Ustanın kandili Kaf\'ta değildi. Kandilciler onu doğuya, tufandan beri sönmeyen ışığın yattığı dağa götürmüştü.',
    'İKİNCİ PERDE · DAĞ',
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
  [],
  [
    'At the summit of Qaf there was a mirror. The birds sought the Simurgh; in the mirror they saw themselves.',
    'Saye looked too. There was no child in the mirror. There was a shadow.',
    'Saye. In the old tongue, it means shadow.',
    'The master\'s lamp was not on Qaf. The Lamplighters had carried it east, to the mountain where a light has slept since the Flood.',
    'THE SECOND VEIL · THE MOUNTAIN',
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
      'Bazı yollar yalnızca ışığa görünür. Bazıları yalnızca karanlığa.',
      'Çürümüş tahta seni taşır. Senden ağır olanı taşımaz.',
      'Su da bir kapıdır: önce boşalır, sonra yükseltir.',
      'Medusa\'nın başlarını ters koymuşlar, kimse taşa dönmesin diye. Bu ikisini ters koymayı unutmuşlar.',
      'Perseus ona hiç doğrudan bakmadı. Cilalı kalkanında gördü ve yürüdü.',
      'Bu sular bin yıl şehre su taşıdı. Şimdi bir gölge taşıyor.',
    ],
    whispersEn: [
      'Saye… Is that the master\'s voice, or the water\'s?',
      'Whatever the lantern touches, it takes. Keep to the dark.',
      'They turned her head so no one would become stone. Learn to see without looking.',
      'Doors open to patience, not to force.',
      'Do not wake those who sleep above. Every sound is a confession.',
      'One must sink so the other may rise. So the scales of the world were set.',
      'Some paths show themselves only to the light. Some, only to the dark.',
      'Rotten wood will bear you. It will not bear one heavier.',
      'Water too is a door: first it empties, then it lifts.',
      'They laid Medusa\'s heads upside down so no one would turn to stone. These two, they forgot.',
      'Perseus never looked at her directly. He saw her in his polished shield, and walked.',
      'For a thousand years these waters carried water to the city. Now they carry a shadow.',
    ],
    memories: [
      'Hatıra · Perdeye ışık tutarken elleri hiç titremezdi. "Gölge, ışığın sözüdür Sâye," derdi.',
      'Hatıra · Gösteri bitince kandili hiç üflemezdi. "Gölgeler korkar," derdi.',
      'Hatıra · Bir gece perdenin arkasına geçmeme izin vermedi. "Gölge arkayı görmemeli," dedi.',
      'Hatıra · Perdenin önünde ilk adımımı attığımda gülmüştü: "Gölgen senden önce yürüyor."',
      'Hatıra · Ustam taş başları perdede hiç oynatmazdı. "Taşa dönen, gölge bile bırakmaz," derdi.',
      'Hatıra · Bir gece Haliç\'e sandalla açıldık. Suya düşmüş bir kandilin ışığını uzun uzun seyretti.',
    ],
    memoriesEn: [
      'Memory · His hands never trembled as he held the light to the screen. "A shadow is the light\'s word, Saye," he said.',
      'Memory · When the show ended, he never blew out the lamp. "The shadows would be afraid," he said.',
      'Memory · One night he would not let me behind the screen. "A shadow must not see what is behind it," he said.',
      'Memory · When I took my first step before the screen, he laughed: "Your shadow walks ahead of you."',
      'Memory · My master never played the stone heads on the screen. "Whoever turns to stone leaves not even a shadow," he said.',
      'Memory · One night we rowed out onto the Golden Horn. He watched the light of a fallen lamp under the water for a long time.',
    ],
    place: 'Yerebatan Sarnıcı · İstanbul, Temmuz 1660',
    placeEn: 'The Basilica Cistern · Istanbul, July 1660',
    areas: [
      'Sütunlar Ormanı',
      'Medusa\'nın Başları',
      'Paslı Kapı',
      'Yarasa Galerisi',
      'Terazi',
      'Yırtık Perde',
      'Işıkla Gölgenin Köprüsü',
      'Dar Geçit',
      'Su Haznesi',
      'Medusa Salonu',
      'Sal Kanalı',
      'Karanlık Kanallar',
    ],
    areasEn: [
      'The Forest of Columns',
      'The Heads of Medusa',
      'The Rusted Gate',
      'The Bat Gallery',
      'The Scales',
      'The Torn Veil',
      'The Bridge of Light and Shadow',
      'The Narrow Passage',
      'The Water Basin',
      'The Hall of Medusa',
      'The Raft Channel',
      'The Dark Channels',
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
      'Hezarfen\'in merceği ışığı toplar. Bir aynayla onu dilediğin göze çevir.',
      'Galata\'nın altında mahzenler yanıyor. Alevin de bir nefesi var; dinle.',
      'Bir sandık bir alevi susturur. Hangisini susturacağını iyi seç.',
      'Kulenin çanını rüzgâr çalar. Bir kez de sen çal; Kandilciler sese gelir.',
    ],
    whispersEn: [
      'The waters of the Horn remember everything, even those who fall.',
      'Some stones break beneath you. Nothing holds you for long.',
      'A Lamplighter walks the rooftops. The crows are his eyes.',
      'The wings were waiting here. Surrender to the wind.',
      'Hezarfen\'s lens gathers the light. With a mirror, turn it on any eye you choose.',
      'Beneath Galata the cellars are burning. Fire breathes too; listen.',
      'One crate can silence one flame. Choose well which.',
      'The wind rings the tower bell. Ring it once yourself; the Lamplighters come to its voice.',
    ],
    memories: [
      'Hatıra · "Haliç bir aynadır," derdi ustam. "Şehir kendine orada bakar."',
      'Hatıra · Kulenin tepesini gösterip "Bir gün oradan bütün perdeyi göreceksin," demişti.',
      'Hatıra · Gözcülerin ışığı soğuktur; çünkü onlar ışığı sevmez, sayar.',
      'Hatıra · Ustam Hezarfen\'i görmüş. "Kanatları vardı," derdi, "ama asıl cesareti vardı."',
      'Hatıra · Kuleden şehre bakarken sorardı: "Bunca ışığın gölgesi nereye düşer?"',
    ],
    memoriesEn: [
      'Memory · "The Horn is a mirror," he said. "The city looks at itself there."',
      'Memory · He pointed at the top of the tower: "One day you will see the whole screen from there."',
      'Memory · The Watchers\' light is cold, for they do not love the light; they count it.',
      'Memory · My master once saw Hezarfen. "He had wings," he said, "but what he really had was courage."',
      'Memory · Looking down at the city from the tower he would ask: "Where do the shadows of all these lights fall?"',
    ],
    place: 'Galata Kulesi · İstanbul, Temmuz 1660',
    placeEn: 'Galata Tower · Istanbul, July 1660',
    areas: [
      'Yanan Mahzen',
      'Haliç Kıyısı',
      'Kargaların Yuvası',
      'Kandilci Rafı',
      'Terazi Asansörü',
      'Gözcü Katı',
      'Hezarfen\'in Atölyesi',
      'Çan Katı',
      'Külahın Tepesi',
    ],
    areasEn: [
      'The Burning Cellar',
      'The Golden Horn Shore',
      'The Crows\' Nest',
      'The Lamplighter\'s Ledge',
      'The Balance Lift',
      'The Watcher\'s Floor',
      'Hezarfen\'s Workshop',
      'The Bell Floor',
      'The Top of the Cone',
    ],
    map: kMapKule,
  ),
  LevelDef(
    title: 'III · GÖKYOLU',
    subtitle: 'Kaf\'a giden yol buluttandır.',
    theme: LevelTheme.sky,
    wings: true,
    storm: true,
    titleEn: 'III · THE SKY ROAD',
    subtitleEn: 'The road to Qaf is made of cloud.',
    whispers: [
      'Kırık güneşin bir parçası… Sıcaklığı tanıdık.',
      'Burada da Kandilciler var. Gök bile onların.',
      'Gök sandığın kadar boş değil.',
      'Rüzgâr seni taşır; yeter ki bırakma.',
      'Kandilciler fenerlerini balonlara asmış. Gökte de gözleri var.',
      'Gölgeden bir köprü: ışık değerse dağılır. Karanlığını kolla.',
      'Şimşek çakınca her şey görünür; sen de.',
      'Kırık güneşin kapısı. Kandilciler onu kimseye açmaz.',
    ],
    whispersEn: [
      'A shard of the broken sun… Its warmth is familiar.',
      'Lamplighters here too. Even the sky is theirs.',
      'The sky is not as empty as you thought.',
      'The wind will carry you, so long as you do not let go.',
      'The Lamplighters hung their lanterns from balloons. They have eyes in the sky as well.',
      'A bridge made of shadow: touch it with light and it scatters. Guard its darkness.',
      'When the lightning strikes, everything is seen; you too.',
      'The gate of the broken sun. The Lamplighters open it for no one.',
    ],
    memories: [
      'Hatıra · Perdenin köşesine bir hüdhüd işlemişti. "Yol gösterene borçlusun," derdi.',
      'Hatıra · "Bir gün güneşi perdeye geri getireceğiz," demişti. O gün gölgemin ilk kez titrediğini gördüm.',
      'Hatıra · Fırtınalı gecelerde perdeyi hiç kapatmazdı. "Şimşek de bir kandildir," derdi.',
      'Hatıra · Bulutları perdede pamukla yapardı. Ben her seferinde birini çalıp cebime koyardım.',
    ],
    memoriesEn: [
      'Memory · He had stitched a hoopoe into the corner of the screen. "You owe the one who shows the way," he said.',
      'Memory · "One day we will bring the sun back to the screen," he said. That day I saw my shadow tremble for the first time.',
      'Memory · On stormy nights he never closed the screen. "Lightning is a lamp too," he said.',
      'Memory · He made clouds on the screen out of cotton. Each time, I stole one and kept it in my pocket.',
    ],
    place: 'Gökyolu · İstanbul\'un üstünde, Ağustos 1660',
    placeEn: 'The Sky Road · Above Istanbul, August 1660',
    areas: [
      'Bulutların Eşiği',
      'Kandilcilerin Bulut Kampı',
      'Gözcü Kayası',
      'Rüzgâr Yolu',
      'Kargaların Adası',
      'Kırık Güneşin Altında',
      'Balon Geçidi',
      'Gölgeden Köprü',
      'Fırtına Adaları',
      'Güneşin Kapısı',
    ],
    areasEn: [
      'The Threshold of Clouds',
      'The Lamplighters\' Cloud Camp',
      'The Watcher\'s Rock',
      'The Wind Road',
      'The Isle of Crows',
      'Beneath the Broken Sun',
      'The Balloon Pass',
      'The Bridge of Shadow',
      'The Storm Isles',
      'The Gate of the Sun',
    ],
    map: kMapGokyolu,
  ),
  LevelDef(
    title: 'IV · KAF',
    subtitle: 'Dünyanın kıyısında zümrüt bir dağ.',
    theme: LevelTheme.kaf,
    wings: true,
    titleEn: 'IV · QAF',
    subtitleEn: 'An emerald mountain at the edge of the world.',
    place: 'Kaf Dağı · Dünyanın kıyısı, Eylül 1660',
    placeEn: 'Mount Qaf · The edge of the world, September 1660',
    areas: [
      'Zümrüt Köprü',
      'Kandilcilerin Gök Karakolu',
      'Gölge Köprüsü',
      'Rüzgârın Sırtı',
      'Simurg\'un Tüyleri',
      'Simurg\'un Ayna Salonu',
    ],
    areasEn: [
      'The Emerald Bridge',
      'The Lamplighters\' Sky Post',
      'The Shadow Bridge',
      'The Back of the Wind',
      'The Feathers of the Simurgh',
      'The Simurgh\'s Hall of Mirrors',
    ],
    whispers: [
      'Burası Kaf. Kuşlar bin yıl uçtu, otuzu vardı.',
      'Kandilciler göğe de nöbetçi dikmiş. Işığı kimseyle bölüşmezler.',
      'Gölgeden köprü ışığa dayanmaz. Ay ışığı da aynaya düşer.',
      'Rüzgâr da bir yolcudur. Ona yaslanan düşmez.',
      'Üç ayna, bir ışık. Aradığın, onun yolunun sonunda.',
      'Simurg buraya üç tüy bırakmış. Üçünü bulmayan aynayı göremez.',
      'Gölgeden köprüyü iki göz bekler. Birinin baktığı yer, öbürünün kör noktası.',
      'Kayalar da nefes alır; inip kalkarlar. Onlarla birlikte yüksel.',
    ],
    whispersEn: [
      'This is Qaf. The birds flew a thousand years, and thirty arrived.',
      'The Lamplighters set watchmen even in the sky. They share their light with no one.',
      'A bridge of shadow cannot bear the light. Moonlight, too, falls into mirrors.',
      'The wind is a traveler too. Whoever leans on it does not fall.',
      'Three mirrors, one light. What you seek waits at the end of its road.',
      'The Simurgh left three feathers here. Whoever does not find all three will never see the mirror.',
      'Two eyes guard the bridge of shadow. Where one looks, the other is blind.',
      'Rocks breathe too; they rise and fall. Rise with them.',
    ],
    memories: [
      'Hatıra · "Simurg diye bir kuş yoktur," derdi ustam. "Otuz kuş vardır. Ama bunu ancak varan bilir."',
      'Hatıra · Kandili yakarken hep aynı duayı mırıldanırdı. Sözlerini hiç anlamadım; ışığı anladım.',
      'Hatıra · "Aynaya bakan kendini gördüğünü sanır," derdi. "Oysa ayna ışığı gösterir."',
      'Hatıra · Bir gün perdeye otuz kuş çizdi. Sonra hepsini tek bir tasvirde birleştirdi: "İşte Simurg."',
    ],
    memoriesEn: [
      'Memory · "There is no bird called the Simurgh," my master said. "There are thirty birds. But only those who arrive know it."',
      'Memory · He murmured the same prayer each time he lit the lamp. I never understood the words; I understood the light.',
      'Memory · "Whoever looks in a mirror thinks he sees himself," he said. "But a mirror shows the light."',
      'Memory · One day he drew thirty birds on the screen. Then he joined them all into a single figure: "There. The Simurgh."',
    ],
    map: kMapKaf,
  ),
  LevelDef(
    title: 'V · AĞRI',
    subtitle: 'Tufandan beri karla örtülü bir sır.',
    theme: LevelTheme.snow,
    wings: true,
    headwind: 140,
    storm: true,
    titleEn: 'V · ARARAT',
    subtitleEn: 'A secret wrapped in snow since the Flood.',
    place: 'Ağrı Dağı · Doğubayazıt, Ekim 1660',
    placeEn: 'Mount Ararat · Doğubayazıt, October 1660',
    areas: [
      'Dağın Eteği',
      'İplerin Geçidi',
      'Terk Edilmiş Ağıl',
      'Buz Mağarası',
      'Akori: Nuh\'un Bağı',
      'Aziz Hakob Manastırı',
      'Tufanın Eşiği',
    ],
    areasEn: [
      'The Foot of the Mountain',
      'The Pass of Ropes',
      'The Abandoned Fold',
      'The Ice Cave',
      'Akori: Noah\'s Vineyard',
      'The Monastery of Saint Hakob',
      'The Threshold of the Flood',
    ],
    whispers: [
      'Bir keşiş zirveye çıkmak istemiş. Her sabah yeniden dağın eteğinde uyanmış.',
      'Rüzgâr kanatlarını geri iter. Burada ip, kanattan sadıktır.',
      'Çobanlar sürülerini bırakıp gitmiş. Kandilciler gelince kuzular bile susar.',
      'Bir gece keşişe bir melek görünmüş, eline gemiden bir tahta vermiş: "Daha yukarı çıkma," demiş.',
      'Yukarıda, buzun içinde, tahtadan bir gövde uyuyor.',
      'Akori\'de derler ki Nuh gemiden inince ilk asmayı buraya dikmiş. Asmalar donmuş, kökleri hâlâ sıcak.',
      'Aziz Hakob\'un manastırı. Çanı rüzgârda kendi kendine çalar; Kandilciler sese gelir, sarkıtlar da düşer.',
    ],
    whispersEn: [
      'A monk once set out for the summit. Every morning he woke again at the mountain\'s foot.',
      'The wind pushes your wings back. Here a rope is more faithful than wings.',
      'The shepherds left their flocks behind. When the Lamplighters come, even the lambs fall silent.',
      'One night an angel came to the monk and put a plank of the Ark in his hand: "Climb no higher," it said.',
      'Up above, inside the ice, a body made of wood is sleeping.',
      'In Akori they say Noah, stepping from the Ark, planted the first vine here. The vines are frozen; their roots are still warm.',
      'The monastery of Saint Hakob. Its bell rings by itself in the wind; the Lamplighters come to its voice, and the icicles fall.',
    ],
    memories: [
      'Hatıra · Kışın ustam perdeye kar yağdırırdı: kandilin önüne un serperdi. Karı ilk orada gördüm.',
      'Hatıra · "Dağlar da yolcudur," derdi. "Yalnızca çok yavaş yürürler."',
      'Hatıra · Bir gece Nuh\'un gemisini oynattık. Hayvanları ikişer ikişer perdeye çıkardı; ben gölgelerini saydım.',
      'Hatıra · Ustam üzüm salkımı tasvirini hep sona saklardı. "Tufandan sonra ilk sevinç," derdi.',
      'Hatıra · Bir keşişin gölgesini perdeye çıkardığında sesini hep alçaltırdı. "Dua eden gölgeye saygı gerek," derdi.',
    ],
    memoriesEn: [
      'Memory · In winter my master made it snow on the screen: he sifted flour before the lamp. That was where I first saw snow.',
      'Memory · "Mountains are travelers too," he said. "They just walk very slowly."',
      'Memory · One night we played Noah\'s Ark. He brought the animals onto the screen two by two; I counted their shadows.',
      'Memory · My master always saved the bunch of grapes for the end. "The first joy after the Flood," he said.',
      'Memory · Whenever he brought a monk\'s shadow onto the screen, he lowered his voice. "A praying shadow deserves respect," he said.',
    ],
    map: kMapAgri,
  ),
  LevelDef(
    title: 'VI · NUH\'UN GEMİSİ',
    subtitle: 'Kırk gün kırk gece. Sonra bir dal, bir güvercin.',
    theme: LevelTheme.ark,
    wings: true,
    titleEn: 'VI · NOAH\'S ARK',
    subtitleEn: 'Forty days and forty nights. Then a branch, a dove.',
    place: 'Nuh\'un Gemisi · Ağrı Dağı, Ekim 1660',
    placeEn: 'Noah\'s Ark · Mount Ararat, October 1660',
    areas: [
      'Aslanların Ambarı',
      'Eşini Bekleyenler',
      'Kandillerin Ambarı',
      'Ambar Kuyusu',
      'Güverte',
    ],
    areasEn: [
      'The Lions\' Hold',
      'Those Who Wait for Their Mates',
      'The Hold of Lamps',
      'The Hold Shaft',
      'The Deck',
    ],
    whispers: [
      'Bu gemi kırk gün kırk gece karanlıkta yüzdü. İçinde hiç sönmeyen bir ışık vardı.',
      'Her canlı eşiyle bindi. Eşini yitirenin gölgesi hâlâ onu bekliyor.',
      'Önce yolu aç, sonra yürüt. Sırayı şaşıran geri dönemez.',
      'Kandiller burada asılıydı. Kandilciler onları da toplamış.',
      'Su hatırlar. Bir kere yükseldi; bir daha yükselir.',
      'Güvercin buradan uçtu, ağzında bir zeytin dalıyla döndü. Hüdhüd onu tanıdı.',
      'Işık burada değil. Kandilciler onu güneşin doğduğu dağa, Nemrut\'a taşımış.',
    ],
    whispersEn: [
      'This ship sailed forty days and nights in darkness. Inside it was a light that never went out.',
      'Every creature boarded with its mate. The shadow of one who lost its mate is still waiting.',
      'First open the way, then lead them on. Whoever confuses the order cannot turn back.',
      'The lamps hung here. The Lamplighters gathered them too.',
      'Water remembers. It rose once; it will rise again.',
      'The dove flew from here and came back with an olive branch in its beak. The Hoopoe knew it.',
      'The light is not here. The Lamplighters have carried it to the mountain where the sun rises: Nemrut.',
    ],
    memories: [
      'Hatıra · Tufan sahnesinde ustam perdeyi yavaşça sallardı. "Su da bir gölgedir," derdi, "en büyüğü."',
      'Hatıra · Geminin tasvirini hiç bitirmedi. "Kimse onun tamamını görmedi," derdi.',
      'Hatıra · "Işığı saklamak için kandil gerekmez," demişti bir gece. "Bir kalp yeter."',
    ],
    memoriesEn: [
      'Memory · In the Flood scene my master gently rocked the screen. "Water is a shadow too," he said, "the greatest one."',
      'Memory · He never finished the figure of the Ark. "No one has ever seen it whole," he said.',
      'Memory · "You do not need a lamp to keep a light," he said one night. "A heart is enough."',
    ],
    map: kMapGemi,
  ),
  LevelDef(
    title: 'VII · NEMRUT',
    subtitle: 'Tanrılarla yan yana oturmak isteyen bir kralın dağı.',
    theme: LevelTheme.nemrut,
    wings: true,
    headwind: 80,
    storm: true,
    quakes: true,
    titleEn: 'VII · NEMRUT',
    subtitleEn: 'The mountain of a king who wished to sit beside the gods.',
    place: 'Nemrut Dağı · Kommagene, Kasım 1660',
    placeEn: 'Mount Nemrut · Commagene, November 1660',
    areas: [
      'Bilinmeyen Dağ',
      'Batı Terası',
      'Deprem Yarığı',
      'Kartalın Gözü',
      'Tümülüs',
      'Doğuya Geçit',
    ],
    areasEn: [
      'The Unknown Mountain',
      'The West Terrace',
      'The Earthquake Rift',
      'The Eagle\'s Eye',
      'The Tumulus',
      'The Pass to the East',
    ],
    whispers: [
      'Bu dağı bugün kimse bilmiyor. Bir kartallar biliyor, bir de kar.',
      'Kral Antiochos tanrılarla yan yana oturmak için dağın tepesine taş tanrılar dikti.',
      'Tahtların ardına vasiyetini kazıttı: iki yüz otuz yedi satır. Taşa yazılan söz unutulmaz sandı.',
      'Depremler tanrıların başlarını yere indirdi. Dağ kibri hiç sevmez.',
      'Başlar hâlâ güneşin doğduğu yere bakar. Gözlerinin önünde saklanabilirsin.',
      'Halk bu dağa Nemrut der: göğe ok atıp Tanrı\'yla savaşmaya kalkan kralın adıyla.',
      'Tümülüsün altında bir kral uyur. Taşlarını oynatma; uyanmasın.',
      'Kandilciler ışığı doğu terasına taşıyor. Güneş doğunca yakacaklar.',
    ],
    whispersEn: [
      'No one knows this mountain today. Only the eagles know it, and the snow.',
      'King Antiochos raised stone gods on the summit so he could sit beside them.',
      'Behind the thrones he had his testament carved: two hundred and thirty-seven lines. He thought words cut in stone are never forgotten.',
      'Earthquakes brought the gods\' heads down to the ground. The mountain has never liked pride.',
      'The heads still face the rising sun. You can hide right before their eyes.',
      'The people call this mountain Nemrut, after the king who shot arrows at the sky to make war on God.',
      'Beneath the tumulus a king is sleeping. Do not shift its stones; let him not wake.',
      'The Lamplighters are carrying the light to the eastern terrace. They will kindle it when the sun rises.',
    ],
    memories: [
      'Hatıra · Ustam taş tasvirleri sevmezdi. "Gölge kımıldar," derdi, "taş kımıldamaz; o yüzden ölüdür."',
      'Hatıra · Bir gece bana yıldızları gösterdi: "Her biri bir kandil. Kimse onları toplayamaz."',
      'Hatıra · Nemrud\'un hikâyesini anlatırken hep gülerdi: "Koca kralı bir sivrisinek yendi. Küçük olan büyüğü hep şaşırtır."',
    ],
    memoriesEn: [
      'Memory · My master did not like stone figures. "A shadow moves," he said. "Stone does not; that is why it is dead."',
      'Memory · One night he showed me the stars: "Each one is a lamp. No one can gather them."',
      'Memory · Whenever he told the tale of Nemrud, he laughed: "The great king was beaten by a gnat. The small always surprise the great."',
    ],
    map: kMapNemrut,
  ),
  LevelDef(
    title: 'VIII · GÜN DOĞUMU',
    subtitle: 'Güneş doğarken taşlar da gölge düşürür.',
    theme: LevelTheme.nemrut,
    variant: 1,
    wings: true,
    quakes: true,
    titleEn: 'VIII · SUNRISE',
    subtitleEn: 'At sunrise even stones cast shadows.',
    place: 'Nemrut Dağı, Doğu Terası · Kasım 1660',
    placeEn: 'Mount Nemrut, the East Terrace · November 1660',
    areas: [
      'Tören Yolu',
      'Terasın Kapısı',
      'Doğu Terası',
      'Güneşin Doğduğu Yer',
    ],
    areasEn: [
      'The Processional Way',
      'The Terrace Gate',
      'The East Terrace',
      'Where the Sun Rises',
    ],
    whispers: [
      'Doğu terası. Kral burada tanrılarla el sıkışırken kazıttı kendini.',
      'Kandilcilerin fenerleri şafakta soluklaşır. Güneşten korkarlar.',
      'Tanrının omzundaki kolu çek. Kapı taşın sözünü dinler.',
      'Kandilciler taşa can vermiş: Nemrud gibi göğe başkaldıran bir dev.',
      'Nemrud\'u bir sivrisinek yendi. Senin de küçük bir ışığın var. Yoluna bırak, kulağı ona değsin.',
      'Işık orada, güneşin doğduğu yerde. Sâye, ona dokun.',
    ],
    whispersEn: [
      'The eastern terrace. Here the king had himself carved shaking hands with the gods.',
      'At dawn the Lamplighters\' lanterns grow pale. They fear the sun.',
      'Pull the lever on the god\'s shoulder. The gate listens to the stone.',
      'The Lamplighters have breathed life into stone: a giant who rebels against the sky, like Nemrud.',
      'Nemrud was beaten by a gnat. You too have a small light. Leave it in his path; let his ear touch it.',
      'The light is there, where the sun rises. Saye, touch it.',
    ],
    memories: [
      'Hatıra · Ustam el sıkışan iki tasviri hep yan yana koyardı. "Gölgeler de barışır," derdi.',
      'Hatıra · Güneş doğarken perdeyi indirirdik. "Artık gölge oyunu yok," derdi. "Şimdi asıl oyun başlıyor."',
    ],
    memoriesEn: [
      'Memory · My master always set two figures shaking hands side by side. "Shadows make peace too," he said.',
      'Memory · At sunrise we took down the screen. "No more shadow play," he said. "Now the real play begins."',
    ],
    map: kMapGunDogumu,
  ),
  LevelDef(
    title: 'IX · KAR YOLU',
    subtitle: 'Palanlarını döken kervanların yolu.',
    theme: LevelTheme.snow,
    variant: 1,
    wings: true,
    storm: true,
    headwind: 120,
    titleEn: 'IX · THE SNOW ROAD',
    subtitleEn: 'The road where caravans lost their saddles.',
    place: 'Palandöken\'in Eteği · Erzurum, Aralık 1660',
    placeEn: 'The Foot of Palandöken · Erzurum, December 1660',
    areas: [
      'Kervan Yolu',
      'Kurtların Ormanı',
      'Donmuş Göl',
      'Terk Edilmiş Han',
      'Ejder\'in Eteği',
    ],
    areasEn: [
      'The Caravan Road',
      'The Wolves\' Forest',
      'The Frozen Lake',
      'The Abandoned Inn',
      'The Foot of the Dragon',
    ],
    whispers: [
      'Bu dağa Palandöken derler: yokuşları öyle diktir ki kervanların palanları kayıp düşermiş.',
      'Evliya Çelebi yazmış: Erzurum\'da kış öyle sert gelir ki damdan dama atlayan kedi havada donar.',
      'Kurtlar seni gözle değil, kokuyla bulur. Saklanmak yetmez; yüksel ya da ışığını göster.',
      'Ağaçlar kurtların ulaşamadığı yerdir. Daldan dala, kardan uzak.',
      'Göl ince buzla örtülü. Hafif olan geçer, ağır olan düşer.',
      'Kervanlar burada geceyi geçirirdi. Şimdi hanın ocağı Kandilcilerin fenerleriyle yanıyor.',
      'Yukarıda iki tepe var: Büyük Ejder ve Küçük Ejder. Derler ki kışın zirvelerde ejderler uyur.',
      'Dağdan inmenin tek yolu kaymak. Rüzgâra değil, kara güven.',
    ],
    whispersEn: [
      'They call this mountain Palandöken: its slopes are so steep that the caravans\' pack saddles slipped off and fell.',
      'Evliya Çelebi wrote that winter in Erzurum is so harsh a cat leaping from roof to roof freezes in mid-air.',
      'Wolves find you not by sight but by scent. Hiding is not enough; climb high, or show them your light.',
      'Trees are where the wolves cannot reach. Branch to branch, away from the snow.',
      'The lake is sheathed in thin ice. The light cross over; the heavy fall through.',
      'Caravans once spent the night here. Now the inn\'s hearth burns with the Lamplighters\' lanterns.',
      'Above are two peaks: the Great Dragon and the Little Dragon. They say dragons sleep on the summits in winter.',
      'The only way down the mountain is to slide. Trust the snow, not the wind.',
    ],
    memories: [
      'Hatıra · Kışın ustam kervan tasvirlerini oynatırdı. Develerin boynundaki çanları ağzıyla çalardı.',
      'Hatıra · Bir gece kurt tasviri yapmıştı, korkup ağladım. Kurdu kırdı, bana bir kuzu yaptı.',
      'Hatıra · "Han yolcunun kalbidir," derdi. "Ocağı sönmüş hana, kapısı açık olsa da kimse girmez."',
    ],
    memoriesEn: [
      'Memory · In winter my master played the caravan figures. He made the bells on the camels\' necks ring with his own voice.',
      'Memory · One night he made a wolf figure and I cried in fear. He broke the wolf and made me a lamb.',
      'Memory · "An inn is the traveler\'s heart," he said. "No one enters an inn whose hearth is cold, even if the door is open."',
    ],
    map: kMapKarYolu,
  ),
  LevelDef(
    title: 'X · PALANDÖKEN',
    subtitle: 'Ejderlerin uyuduğu dağdan aşağı.',
    theme: LevelTheme.snow,
    variant: 1,
    skiSurface: kSkiPalandoken,
    magnet: [(203, 226)],
    titleEn: 'X · PALANDÖKEN',
    subtitleEn: 'Down from the mountain where the dragons sleep.',
    place: 'Palandöken Dağı · Erzurum, Aralık 1660',
    placeEn: 'Mount Palandöken · Erzurum, December 1660',
    areas: [
      'Çoban Kulübesi',
      'Ejder\'in Sırtı',
      'Kandil Balonları',
      'Manyetik Tepe',
      'Ejder\'in Sıçrayışı',
      'Erzurum\'a İniş',
    ],
    areasEn: [
      'The Shepherd\'s Hut',
      'The Dragon\'s Back',
      'The Lantern Balloons',
      'The Magnetic Hill',
      'The Dragon\'s Leap',
      'The Descent to Erzurum',
    ],
    whispers: [
      'Bu dağa Palandöken derler. Yokuşları öyle dikmiş ki kervanların sırtındaki palanlar kayıp dökülürmüş; adı da oradan kalmış.',
      'Kar seni taşımak ister. Sırtından havalan, dönerek in; ayakların yere doğru gelsin.',
      'İki zirvenin adı Büyük Ejder ile Küçük Ejder. Eski inanışta dağların doruğu kutsaldır; orada koruyucu ruhlar, dev ejderler yaşar. Fırtına onların nefesi, sis onların uykusudur.',
      'Kandilciler fenerlerini balonlara asmış, yamacı tarıyor. Işıklarında oyalanma; hız, gölgenin kalkanıdır.',
      'Burada kar yokuş yukarı akar. Çobanlar bunun bir göz aldanması mı, yoksa dağın seni geri çağırması mı olduğunu hiç bilememiş.',
      'Dağ çağırırsa direnme. Seni sırtına kadar taşır; oradan uçarsın.',
      'Ejder\'in Sıçrayışı. Buradan atlayan rüzgârın kanadına biner. Korkan düşer, inanan uçar.',
      'Aşağıda Erzurum\'un kandilleri titriyor. Dağın sırtında bir gürültü uyanıyor.',
    ],
    whispersEn: [
      'They call this mountain Palandöken. Its slopes were so steep that the pack saddles slid off the caravans\' backs and fell, and so it got its name.',
      'The snow wants to carry you. Lift off its ridges, land turning; let your feet come down to the ground.',
      'The two summits are the Great Dragon and the Little Dragon. In the old belief mountaintops are sacred; guardian spirits and giant dragons dwell there. The storm is their breath, the fog their sleep.',
      'The Lamplighters have hung their lanterns on balloons and sweep the slope. Do not linger in their light; speed is a shadow\'s shield.',
      'Here the snow flows uphill. The shepherds never knew whether it was a trick of the eye or the mountain calling you back.',
      'If the mountain calls, do not resist. It carries you up to its crest; from there you fly.',
      'The Dragon\'s Leap. Whoever jumps from here rides the wing of the wind. Those who fear fall; those who believe fly.',
      'Below, the lamps of Erzurum flicker. On the mountain\'s back, a rumbling wakes.',
    ],
    memories: [
      'Hatıra · Bir kış ustam bana tahtadan bir kızak yaptı. "Kaymayı bilen düşmeyi de bilir," dedi. Düşe kalka öğrendim.',
      'Hatıra · Perdeye bir ejder çizmişti; ağzından ateş değil, kar çıkıyordu. "Her ejder ateş püskürmez," dedi.',
    ],
    memoriesEn: [
      'Memory · One winter my master made me a wooden sled. "Whoever knows how to slide knows how to fall," he said. I learned by falling.',
      'Memory · He once drew a dragon on the screen that breathed snow, not fire. "Not every dragon breathes fire," he said.',
    ],
    map: kMapPalandoken,
  ),
  LevelDef(
    title: 'XI · ÇIĞ',
    subtitle: 'Ejder uyandı. Beyaz bir nefes peşinde.',
    theme: LevelTheme.snow,
    variant: 2,
    skiSurface: kSkiCig,
    titleEn: 'XI · THE AVALANCHE',
    subtitleEn: 'The dragon has woken. A white breath at your heels.',
    place: 'Küçük Ejder Yamacı · Erzurum, Aralık 1660',
    placeEn: 'The Slopes of the Little Dragon · Erzurum, December 1660',
    areas: [
      'Ejder Uyanıyor',
      'Beyaz Nefes',
      'Kırık Sırt',
      'Son Atlayış',
      'Sığınak',
    ],
    areasEn: [
      'The Dragon Wakes',
      'The White Breath',
      'The Broken Ridge',
      'The Last Leap',
      'The Shelter',
    ],
    whispers: [
      'Derler ki Küçük Ejder uyurken dağ susar; uyanınca kar akar. Bu gece Kandilcilerin fenerleri onu uyandırdı.',
      'Çığdan kaçılmaz, onunla yarışılır. Yavaşlayan kar olur.',
      'Erzurum\'un yaşlıları anlatır: bir kervan bir gece çığa yakalanmış. Baharda karlar eriyince develeri ayakta, donmuş bulmuşlar; boyunlarındaki çanlar rüzgârda hâlâ çalıyormuş.',
      'Kırık sırt. Kayalar çığdan önce düşer; gözünü yoldan ayırma.',
      'Son atlayış. Ejderin nefesi sırtında: ya uçarsın, ya kar olursun.',
      'Çığ dağın dibinde durdu, Ejder yeniden uykuya daldı. Batıda, peri bacalarının ülkesinde bir kandil yanıp sönüyor.',
    ],
    whispersEn: [
      'They say when the Little Dragon sleeps, the mountain is silent; when it wakes, the snow flows. Tonight the Lamplighters\' lanterns woke it.',
      'There is no fleeing an avalanche, only racing it. Whoever slows becomes snow.',
      'The elders of Erzurum tell of a caravan caught by an avalanche one night. When the snow melted in spring, they found the camels standing, frozen; the bells on their necks still rang in the wind.',
      'The broken ridge. The rocks fall before the snow; keep your eyes on the path.',
      'The last leap. The dragon\'s breath at your back: you fly, or you become snow.',
      'The avalanche stopped at the mountain\'s foot, and the dragon sank back into sleep. In the west, in the land of the fairy chimneys, a lamp flickers.',
    ],
    memories: [
      'Hatıra · Bir kış ustam perdeyi titreterek çığ yapmıştı. Sonra kandili kıstı: "Dağ da yorulur," dedi.',
      'Hatıra · "Korkudan kaçılmaz," derdi, "korkuyla birlikte koşulur. Bir gün önüne geçersin."',
    ],
    memoriesEn: [
      'Memory · One winter my master made an avalanche by shaking the screen. Then he dimmed the lamp: "Mountains get tired too," he said.',
      'Memory · "You cannot flee fear," he said. "You run alongside it. One day you get ahead of it."',
    ],
    map: kMapCig,
  ),
  LevelDef(
    title: 'XII · PERİ BACALARI',
    subtitle: 'İnsanlar aşağıda, periler yukarıda yaşardı.',
    theme: LevelTheme.peri,
    wings: true,
    titleEn: 'XII · THE FAIRY CHIMNEYS',
    subtitleEn: 'People lived below, fairies above.',
    place: 'Muşkara (bugünkü Nevşehir) · Kapadokya, Aralık 1660',
    placeEn: 'Muşkara (today\'s Nevşehir) · Cappadocia, December 1660',
    areas: [
      'Muşkara',
      'Peri Bacaları',
      'Güvercinlik Vadisi',
      'Kaya Kilisesi',
      'Perilerin Dansı',
      'Uçhisar',
    ],
    areasEn: [
      'Muşkara',
      'The Fairy Chimneys',
      'Pigeon Valley',
      'The Rock Church',
      'The Dance of the Fairies',
      'Uçhisar',
    ],
    whispers: [
      'Eskiler bu ülkeye Katpatuka derdi: güzel atlar ülkesi. Ama atlardan önce burada periler vardı.',
      'Bir zamanlar başları dağlara değen devler varmış. İnsanları ateş dalgalarıyla cezalandırırlarmış; Erciyes\'in, Hasan Dağı\'nın ağzından alevler akarmış.',
      'Peri Padişahı buna dayanamamış. Binlerce periyi toplamış; ellerinde kar ve buz, devlerin ateşli dağına yürümüşler.',
      'Ateş sönmüş, devler yeraltına sürülmüş. Küllerden bu bacalar yükselmiş. O günden beri insanlar bacaların dibinde, periler tepesinde yaşar.',
      'Güvercinlik Vadisi. Bağlar güvercinlerin bıraktığıyla yeşerir; bu yüzden onlara kayalara ev oyulmuştur. Ürkütürsen bütün vadi duyar.',
      'Anadolu\'da derler ki her insanla birlikte bir peri eşi doğar: hemzat. Sevdiğini sever, nefret ettiğinden nefret eder. Sâye, senin hemzatın kim?',
      'Bu kilise kayanın içine oyulmuş. Duvardaki tasvirlerin gözleri kazınmış: kimi bakışlarından korkulmuş der, kimi kazınan boyayı şifa diye içmişler der.',
      'Ay doğunca tepelerde ışıklar dolaşır. Çobanlar onlara peri halkası der; üstüne basan göğe çıkar, inip inmeyeceğini kimse bilmez.',
      'Uçhisar\'ın tepesinden bütün vadi görünür. Kandilciler yerin altına indi: Derinkuyu\'ya, devlerin sürüldüğü yere.',
    ],
    whispersEn: [
      'The ancients called this land Katpatuka: the land of beautiful horses. But before the horses, there were fairies.',
      'Once there were giants whose heads touched the mountains. They punished people with waves of fire; flames poured from the mouths of Erciyes and Hasan Dağı.',
      'The Fairy King could not bear it. He gathered thousands of fairies, and with snow and ice in their hands they marched on the giants\' burning mountain.',
      'The fire died, and the giants were driven underground. From the ashes these chimneys rose. Ever since, people live at the foot of the chimneys, and fairies at the top.',
      'Pigeon Valley. The vineyards grow green from what the pigeons leave, so homes were carved for them in the rocks. Startle them, and the whole valley hears.',
      'In Anatolia they say a fairy twin is born with every person: the hemzat. It loves whom you love and hates whom you hate. Saye, who is your hemzat?',
      'This church was carved inside the rock. The eyes of the figures on the walls have been scraped away: some say people feared their gaze, others that they drank the scraped paint as a cure.',
      'When the moon rises, lights wander on the summits. Shepherds call them fairy rings; whoever steps on one rises to the sky, and no one knows if they come down again.',
      'From the summit of Uçhisar the whole valley lies open. The Lamplighters have gone down beneath the earth: to Derinkuyu, where the giants were driven.',
    ],
    memories: [
      'Hatıra · Ustam perdeye peri çizmezdi. "Periler gölge bırakmaz," derdi, "o yüzden onları perdede göremezsin."',
      'Hatıra · Bir gece en yüksek tepeye çıktık. "Buradan bakınca dünya da bir perde," dedi. "Biz arkasındayız."',
      'Hatıra · Kandilini yakarken hep bir dua mırıldanırdı. Bir gün sordum, güldü: "Işığa teşekkür ediyorum."',
      'Hatıra · "Bir gün gideceğim," demişti. "O gün ağlama. Gölge ışığa kavuşunca ağlanmaz."',
    ],
    memoriesEn: [
      'Memory · My master never drew fairies on the screen. "Fairies leave no shadow," he said, "so you can never see them on a screen."',
      'Memory · One night we climbed the highest peak. "From up here the world is a screen too," he said. "And we are behind it."',
      'Memory · Whenever he lit his lamp he murmured a prayer. One day I asked; he laughed: "I am thanking the light."',
      'Memory · "One day I will go," he said. "Do not cry that day. No one weeps when a shadow reaches the light."',
    ],
    map: kMapPeri,
  ),
];
