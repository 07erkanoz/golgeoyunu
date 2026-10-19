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
      'Simurg\'un Ayna Salonu',
    ],
    areasEn: [
      'The Emerald Bridge',
      'The Lamplighters\' Sky Post',
      'The Shadow Bridge',
      'The Back of the Wind',
      'The Simurgh\'s Hall of Mirrors',
    ],
    whispers: [
      'Burası Kaf. Kuşlar bin yıl uçtu, otuzu vardı.',
      'Kandilciler göğe de nöbetçi dikmiş. Işığı kimseyle bölüşmezler.',
      'Gölgeden köprü ışığa dayanmaz. Ay ışığı da aynaya düşer.',
      'Rüzgâr da bir yolcudur. Ona yaslanan düşmez.',
      'Üç ayna, bir ışık. Aradığın, onun yolunun sonunda.',
    ],
    whispersEn: [
      'This is Qaf. The birds flew a thousand years, and thirty arrived.',
      'The Lamplighters set watchmen even in the sky. They share their light with no one.',
      'A bridge of shadow cannot bear the light. Moonlight, too, falls into mirrors.',
      'The wind is a traveler too. Whoever leans on it does not fall.',
      'Three mirrors, one light. What you seek waits at the end of its road.',
    ],
    memories: [
      'Hatıra · "Simurg diye bir kuş yoktur," derdi ustam. "Otuz kuş vardır. Ama bunu ancak varan bilir."',
      'Hatıra · Kandili yakarken hep aynı duayı mırıldanırdı. Sözlerini hiç anlamadım; ışığı anladım.',
      'Hatıra · "Aynaya bakan kendini gördüğünü sanır," derdi. "Oysa ayna ışığı gösterir."',
    ],
    memoriesEn: [
      'Memory · "There is no bird called the Simurgh," my master said. "There are thirty birds. But only those who arrive know it."',
      'Memory · He murmured the same prayer each time he lit the lamp. I never understood the words; I understood the light.',
      'Memory · "Whoever looks in a mirror thinks he sees himself," he said. "But a mirror shows the light."',
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
      'Tufanın Eşiği',
    ],
    areasEn: [
      'The Foot of the Mountain',
      'The Pass of Ropes',
      'The Abandoned Fold',
      'The Ice Cave',
      'The Threshold of the Flood',
    ],
    whispers: [
      'Bir keşiş zirveye çıkmak istemiş. Her sabah yeniden dağın eteğinde uyanmış.',
      'Rüzgâr kanatlarını geri iter. Burada ip, kanattan sadıktır.',
      'Çobanlar sürülerini bırakıp gitmiş. Kandilciler gelince kuzular bile susar.',
      'Bir gece keşişe bir melek görünmüş, eline gemiden bir tahta vermiş: "Daha yukarı çıkma," demiş.',
      'Yukarıda, buzun içinde, tahtadan bir gövde uyuyor.',
    ],
    whispersEn: [
      'A monk once set out for the summit. Every morning he woke again at the mountain\'s foot.',
      'The wind pushes your wings back. Here a rope is more faithful than wings.',
      'The shepherds left their flocks behind. When the Lamplighters come, even the lambs fall silent.',
      'One night an angel came to the monk and put a plank of the Ark in his hand: "Climb no higher," it said.',
      'Up above, inside the ice, a body made of wood is sleeping.',
    ],
    memories: [
      'Hatıra · Kışın ustam perdeye kar yağdırırdı: kandilin önüne un serperdi. Karı ilk orada gördüm.',
      'Hatıra · "Dağlar da yolcudur," derdi. "Yalnızca çok yavaş yürürler."',
      'Hatıra · Bir gece Nuh\'un gemisini oynattık. Hayvanları ikişer ikişer perdeye çıkardı; ben gölgelerini saydım.',
    ],
    memoriesEn: [
      'Memory · In winter my master made it snow on the screen: he sifted flour before the lamp. That was where I first saw snow.',
      'Memory · "Mountains are travelers too," he said. "They just walk very slowly."',
      'Memory · One night we played Noah\'s Ark. He brought the animals onto the screen two by two; I counted their shadows.',
    ],
    map: kMapAgri,
  ),
];
